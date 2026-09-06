export type SpellTypeDefinition = {
	Id: string,
	Name: string,
	Description: string,
	MinMageLevel: number,
	Implemented: boolean,
}

-- Only BlastAttack has real gameplay behavior right now (it reuses the existing
-- projectile/damage pipeline from Phase 1-4). The rest are listed with their intended
-- level gates so the spell-creation menu shows the full planned catalog, but they're
-- not selectable yet — each is really its own mechanic to build (an AoE burst, a jump,
-- a channelled beam, a buff, a movement ability) rather than a variant of the same
-- projectile logic.
local SpellTypes: { [string]: SpellTypeDefinition } = {
	BlastAttack = {
		Id = "BlastAttack",
		Name = "Blast Attack",
		Description = "Fire one or more ranged blasts of your magic at the target.",
		MinMageLevel = 1,
		Implemented = true,
	},
	Explosion = {
		Id = "Explosion",
		Name = "Explosion",
		Description = "Deal damage in a large area using a burst of your magic.",
		MinMageLevel = 25,
		Implemented = false,
	},
	HighJump = {
		Id = "HighJump",
		Name = "High Jump",
		Description = "Create a burst of your magic that launches you into the sky.",
		MinMageLevel = 50,
		Implemented = false,
	},
	BeamAttack = {
		Id = "BeamAttack",
		Name = "Beam Attack",
		Description = "Hold to channel a continuous beam of your magic. Drains mana per "
			.. "second and stops when you run out or let go.",
		MinMageLevel = 75,
		Implemented = true,
	},
	Hover = {
		Id = "Hover",
		Name = "Hover",
		Description = "Use lots of magic energy in order to hover in the air.",
		MinMageLevel = 100,
		Implemented = false,
	},
	Mode = {
		Id = "Mode",
		Name = "Mode",
		Description = "Surround yourself in magic in order to gain special buffs.",
		MinMageLevel = 125,
		Implemented = false,
	},
	Flight = {
		Id = "Flight",
		Name = "Flight",
		Description = "Focus your magic energy in order to fly really fast. If you take "
			.. "damage while focusing, the spell will stop.",
		MinMageLevel = 150,
		Implemented = false,
	},
}

local SpellTypeOrder = {
	"BlastAttack",
	"Explosion",
	"HighJump",
	"BeamAttack",
	"Hover",
	"Mode",
	"Flight",
}

return {
	Definitions = SpellTypes,
	Order = SpellTypeOrder,
}
