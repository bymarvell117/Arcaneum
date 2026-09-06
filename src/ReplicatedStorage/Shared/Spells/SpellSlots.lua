-- Slot 1 (Q) is always available (and gets an auto-created starter spell so a fresh
-- mage is never stuck with nothing to cast); the rest unlock progressively with mage
-- level, matching the reference's "Progress further to unlock" empty slots.
local SpellSlots = {
	Order = { "Q", "E", "R", "F", "V" },
	UnlockLevel = {
		Q = 1,
		E = 10,
		R = 20,
		F = 30,
		V = 40,
	},
}

function SpellSlots.IsUnlocked(slot: string, mageLevel: number): boolean
	local requiredLevel = SpellSlots.UnlockLevel[slot]
	return requiredLevel ~= nil and mageLevel >= requiredLevel
end

return SpellSlots
