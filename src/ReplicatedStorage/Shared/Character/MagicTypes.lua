export type MagicTypeDefinition = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	Implemented: boolean,
	ClassId: string?, -- CharacterClasses key; only set when Implemented
}

-- The full catalog of magic types shown on the "Choose a Magic" screen. Only the ones
-- with a real CharacterClass/SpellWord behind them (Fire, Ice, Lightning, Earth) are
-- actually pickable right now; the rest are listed so the screen shows the intended
-- final scope, same as SpellTypes.lua does for spell types.
local MagicTypes: { [string]: MagicTypeDefinition } = {
	Acid = {
		Id = "Acid",
		DisplayName = "Acid",
		Color = Color3.fromRGB(150, 210, 60),
		Implemented = false,
	},
	Ash = {
		Id = "Ash",
		DisplayName = "Ash",
		Color = Color3.fromRGB(120, 120, 120),
		Implemented = false,
	},
	Crystal = {
		Id = "Crystal",
		DisplayName = "Crystal",
		Color = Color3.fromRGB(180, 220, 255),
		Implemented = false,
	},
	Earth = {
		Id = "Earth",
		DisplayName = "Earth",
		Color = Color3.fromRGB(120, 90, 60),
		Implemented = true,
		ClassId = "EarthMage",
	},
	Explosion = {
		Id = "Explosion",
		DisplayName = "Explosion",
		Color = Color3.fromRGB(255, 140, 40),
		Implemented = false,
	},
	Fire = {
		Id = "Fire",
		DisplayName = "Fire",
		Color = Color3.fromRGB(255, 106, 0),
		Implemented = true,
		ClassId = "FireMage",
	},
	Glass = {
		Id = "Glass",
		DisplayName = "Glass",
		Color = Color3.fromRGB(200, 230, 240),
		Implemented = false,
	},
	Gold = {
		Id = "Gold",
		DisplayName = "Gold",
		Color = Color3.fromRGB(230, 190, 60),
		Implemented = false,
	},
	Ice = {
		Id = "Ice",
		DisplayName = "Ice",
		Color = Color3.fromRGB(120, 210, 255),
		Implemented = true,
		ClassId = "IceMage",
	},
	Ink = {
		Id = "Ink",
		DisplayName = "Ink",
		Color = Color3.fromRGB(45, 45, 65),
		Implemented = false,
	},
	Iron = {
		Id = "Iron",
		DisplayName = "Iron",
		Color = Color3.fromRGB(130, 130, 140),
		Implemented = false,
	},
	Light = {
		Id = "Light",
		DisplayName = "Light",
		Color = Color3.fromRGB(255, 250, 210),
		Implemented = false,
	},
	Lightning = {
		Id = "Lightning",
		DisplayName = "Lightning",
		Color = Color3.fromRGB(255, 240, 120),
		Implemented = true,
		ClassId = "StormMage",
	},
	Magma = {
		Id = "Magma",
		DisplayName = "Magma",
		Color = Color3.fromRGB(200, 60, 30),
		Implemented = false,
	},
	Paper = {
		Id = "Paper",
		DisplayName = "Paper",
		Color = Color3.fromRGB(240, 235, 220),
		Implemented = false,
	},
	Plasma = {
		Id = "Plasma",
		DisplayName = "Plasma",
		Color = Color3.fromRGB(255, 80, 200),
		Implemented = false,
	},
	Poison = {
		Id = "Poison",
		DisplayName = "Poison",
		Color = Color3.fromRGB(120, 200, 80),
		Implemented = false,
	},
	Sand = {
		Id = "Sand",
		DisplayName = "Sand",
		Color = Color3.fromRGB(210, 180, 120),
		Implemented = false,
	},
	Shadow = {
		Id = "Shadow",
		DisplayName = "Shadow",
		Color = Color3.fromRGB(60, 50, 80),
		Implemented = false,
	},
	Snow = {
		Id = "Snow",
		DisplayName = "Snow",
		Color = Color3.fromRGB(235, 245, 255),
		Implemented = false,
	},
	Water = {
		Id = "Water",
		DisplayName = "Water",
		Color = Color3.fromRGB(60, 140, 220),
		Implemented = false,
	},
	Wind = {
		Id = "Wind",
		DisplayName = "Wind",
		Color = Color3.fromRGB(200, 255, 230),
		Implemented = false,
	},
	Wood = {
		Id = "Wood",
		DisplayName = "Wood",
		Color = Color3.fromRGB(110, 70, 40),
		Implemented = false,
	},
}

local MagicTypeOrder = {
	"Acid",
	"Ash",
	"Crystal",
	"Earth",
	"Explosion",
	"Fire",
	"Glass",
	"Gold",
	"Ice",
	"Ink",
	"Iron",
	"Light",
	"Lightning",
	"Magma",
	"Paper",
	"Plasma",
	"Poison",
	"Sand",
	"Shadow",
	"Snow",
	"Water",
	"Wind",
	"Wood",
}

return {
	Definitions = MagicTypes,
	Order = MagicTypeOrder,
}
