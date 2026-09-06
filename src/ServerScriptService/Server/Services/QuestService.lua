local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local QuestDefinitions = require(ReplicatedStorage.Shared.Quests.QuestDefinitions)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)

local STORY_CHECK_INTERVAL = 3

type PlayerQuestState = {
	ActiveSideQuestId: string?,
	SideProgress: number,
	StoryOrder: number,
	StoryProgress: number,
}

local QuestService = {}

local questUpdatedEvent = Net.GetEvent("QuestUpdated")

local playerQuestState: { [Player]: PlayerQuestState } = {}

local storyQuestsInOrder: { QuestDefinitions.QuestDefinition } = {}
for _, quest in QuestDefinitions do
	if quest.IsStory then
		table.insert(storyQuestsInOrder, quest)
	end
end
table.sort(storyQuestsInOrder, function(a, b)
	return (a.StoryOrder or 0) < (b.StoryOrder or 0)
end)

local function getCurrentStoryQuest(state: PlayerQuestState): QuestDefinitions.QuestDefinition?
	return storyQuestsInOrder[state.StoryOrder]
end

local function grantRewards(player: Player, quest: QuestDefinitions.QuestDefinition)
	if quest.RewardSilver > 0 then
		PlayerDataService:AddCurrency(player, "Silver", quest.RewardSilver)
	end
	if quest.RewardGold > 0 then
		PlayerDataService:AddCurrency(player, "Gold", quest.RewardGold)
	end
	if quest.RewardCharacterXP > 0 then
		PlayerDataService:AddXP(player, "Character", quest.RewardCharacterXP)
	end
end

local function sendQuestUpdate(player: Player, state: PlayerQuestState)
	local sideQuest = state.ActiveSideQuestId and QuestDefinitions[state.ActiveSideQuestId]
	local storyQuest = getCurrentStoryQuest(state)

	questUpdatedEvent:FireClient(player, {
		Side = sideQuest and {
			Name = sideQuest.Name,
			Progress = state.SideProgress,
			Target = sideQuest.TargetCount,
		} or nil,
		Story = storyQuest and {
			Name = storyQuest.Name,
			Description = storyQuest.Description,
			Progress = if storyQuest.ObjectiveType == "ReachMageLevel"
				then PlayerDataService:GetMageLevel(player)
				else state.StoryProgress,
			Target = storyQuest.TargetCount,
		} or nil,
	})
end

local function checkStoryLevelObjective(player: Player, state: PlayerQuestState)
	local quest = getCurrentStoryQuest(state)
	if not quest or quest.ObjectiveType ~= "ReachMageLevel" then
		return
	end
	if PlayerDataService:GetMageLevel(player) >= quest.TargetCount then
		grantRewards(player, quest)
		state.StoryOrder += 1
		state.StoryProgress = 0
		sendQuestUpdate(player, state)
	end
end

function QuestService:TryAcceptSideQuest(player: Player, questId: string)
	local quest = QuestDefinitions[questId]
	local state = playerQuestState[player]
	if not quest or quest.IsStory or not state or state.ActiveSideQuestId then
		return
	end
	state.ActiveSideQuestId = questId
	state.SideProgress = 0
	sendQuestUpdate(player, state)
end

function QuestService:ReportDummyDefeated(player: Player)
	local state = playerQuestState[player]
	if not state then
		return
	end

	if state.ActiveSideQuestId then
		local quest = QuestDefinitions[state.ActiveSideQuestId]
		if quest and quest.ObjectiveType == "DefeatDummy" then
			state.SideProgress += 1
			if state.SideProgress >= quest.TargetCount then
				grantRewards(player, quest)
				state.ActiveSideQuestId = nil
				state.SideProgress = 0
			end
		end
	end

	local storyQuest = getCurrentStoryQuest(state)
	if storyQuest and storyQuest.ObjectiveType == "DefeatDummy" then
		state.StoryProgress += 1
		if state.StoryProgress >= storyQuest.TargetCount then
			grantRewards(player, storyQuest)
			state.StoryOrder += 1
			state.StoryProgress = 0
		end
	end

	sendQuestUpdate(player, state)
end

function QuestService:Start()
	Players.PlayerAdded:Connect(function(player)
		local state: PlayerQuestState = {
			ActiveSideQuestId = nil,
			SideProgress = 0,
			StoryOrder = 1,
			StoryProgress = 0,
		}
		playerQuestState[player] = state
		sendQuestUpdate(player, state)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerQuestState[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(STORY_CHECK_INTERVAL)
			for player, state in playerQuestState do
				checkStoryLevelObjective(player, state)
			end
		end
	end)
end

return QuestService
