export type QuestObjectiveType = "DefeatDummy" | "ReachMageLevel"

export type QuestDefinition = {
	Id: string,
	Name: string,
	Description: string,
	ObjectiveType: QuestObjectiveType,
	TargetCount: number,
	RewardSilver: number,
	RewardGold: number,
	RewardCharacterXP: number,
	IsStory: boolean,
	StoryOrder: number?,
}

local QuestDefinitions: { [string]: QuestDefinition } = {
	SideDefeatDummies = {
		Id = "SideDefeatDummies",
		Name = "Pest Control",
		Description = "Defeat 3 training dummies.",
		ObjectiveType = "DefeatDummy",
		TargetCount = 3,
		RewardSilver = 20,
		RewardGold = 0,
		RewardCharacterXP = 15,
		IsStory = false,
	},

	StoryChapter1 = {
		Id = "StoryChapter1",
		Name = "Chapter 1: The Awakening",
		Description = "Prove your magical potential: reach Mage Level 2.",
		ObjectiveType = "ReachMageLevel",
		TargetCount = 2,
		RewardSilver = 50,
		RewardGold = 1,
		RewardCharacterXP = 30,
		IsStory = true,
		StoryOrder = 1,
	},
	StoryChapter2 = {
		Id = "StoryChapter2",
		Name = "Chapter 2: Trial by Combat",
		Description = "Defeat 5 training dummies to prove your combat skill.",
		ObjectiveType = "DefeatDummy",
		TargetCount = 5,
		RewardSilver = 100,
		RewardGold = 2,
		RewardCharacterXP = 50,
		IsStory = true,
		StoryOrder = 2,
	},
}

return QuestDefinitions
