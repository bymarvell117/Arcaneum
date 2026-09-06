local SpellWords = require(script.Parent.SpellWords)

export type SpellLoadout = {
	WordId: string,
	Intensity: number,
	Quantity: number,
	ProjectileCount: number,
}

export type ResolvedSpell = {
	Word: SpellWords.SpellWord,
	Intensity: number,
	Quantity: number,
	ProjectileCount: number,
	DamagePerProjectile: number,
	ManaCostPerCast: number,
	TotalManaCost: number,
}

local MIN_PARAM = 1
local MAX_PARAM = 5

local SpellBuilder = {}

local function clampParam(value: number): number
	return math.clamp(math.floor(value), MIN_PARAM, MAX_PARAM)
end

function SpellBuilder.Resolve(loadout: SpellLoadout): ResolvedSpell?
	local word = SpellWords[loadout.WordId]
	if not word then
		return nil
	end

	local intensity = clampParam(loadout.Intensity)
	local quantity = clampParam(loadout.Quantity)
	local projectileCount = clampParam(loadout.ProjectileCount)

	local intensityFactor = intensity ^ 1.15
	local damagePerProjectile = word.BaseDamage * intensityFactor
	local manaCostPerCast = word.BaseManaCost * intensityFactor * projectileCount

	return {
		Word = word,
		Intensity = intensity,
		Quantity = quantity,
		ProjectileCount = projectileCount,
		DamagePerProjectile = damagePerProjectile,
		ManaCostPerCast = manaCostPerCast,
		TotalManaCost = manaCostPerCast * quantity,
	}
end

return SpellBuilder
