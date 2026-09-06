export type CharacterClassId = "FireMage" | "IceMage" | "StormMage" | "WitchSlayer"

export type CharacterClassDefinition = {
	Id: CharacterClassId,
	Name: string,
	Description: string,
	IsMage: boolean,
}

-- The Fire/Ice/Storm split is identity/flavor for now — it doesn't yet restrict which
-- spell words a player can cast (that comes with the real spell-customization system
-- next). Witch Slayer is the one distinction actually enforced today: no spellcasting
-- at all (SpellService checks this server-side, not just the client hotbar).
local CharacterClasses: { [string]: CharacterClassDefinition } = {
	FireMage = {
		Id = "FireMage",
		Name = "Fire Mage",
		Description = "Wields Ignis flame magic. Aggressive, high burst damage.",
		IsMage = true,
	},
	IceMage = {
		Id = "IceMage",
		Name = "Ice Mage",
		Description = "Wields Glacies frost magic. Controls and slows enemies.",
		IsMage = true,
	},
	StormMage = {
		Id = "StormMage",
		Name = "Storm Mage",
		Description = "Wields Fulgur lightning magic. Fast, precise strikes.",
		IsMage = true,
	},
	WitchSlayer = {
		Id = "WitchSlayer",
		Name = "Witch Slayer",
		Description = "No magic. Boosted stamina, bonus damage against mages, faster weapon "
			.. "mastery, and access to special anti-mage weapons.",
		IsMage = false,
	},
}

return CharacterClasses
