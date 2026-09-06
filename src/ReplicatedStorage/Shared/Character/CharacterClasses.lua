export type CharacterClassId = "FireMage" | "IceMage" | "StormMage" | "WitchSlayer"

export type CharacterClassDefinition = {
	Id: CharacterClassId,
	Name: string,
	Description: string,
	IsMage: boolean,
	Word: string?,
}

-- Each mage class is now locked to exactly one SpellWord (Shared/Spells/SpellWords.lua)
-- for the whole spell-customization system: your magic type determines the element
-- every spell you build uses. Witch Slayer has no Word (no magic at all — SpellService
-- rejects casting server-side, not just the client UI).
local CharacterClasses: { [string]: CharacterClassDefinition } = {
	FireMage = {
		Id = "FireMage",
		Name = "Fire Mage",
		Description = "Wields Ignis flame magic. Aggressive, high burst damage.",
		IsMage = true,
		Word = "Ignis",
	},
	IceMage = {
		Id = "IceMage",
		Name = "Ice Mage",
		Description = "Wields Glacies frost magic. Controls and slows enemies.",
		IsMage = true,
		Word = "Glacies",
	},
	StormMage = {
		Id = "StormMage",
		Name = "Storm Mage",
		Description = "Wields Fulgur lightning magic. Fast, precise strikes.",
		IsMage = true,
		Word = "Fulgur",
	},
	WitchSlayer = {
		Id = "WitchSlayer",
		Name = "Witch Slayer",
		Description = "No magic. Boosted stamina, bonus damage against mages, faster weapon "
			.. "mastery, and access to special anti-mage weapons.",
		IsMage = false,
		Word = nil,
	},
}

return CharacterClasses
