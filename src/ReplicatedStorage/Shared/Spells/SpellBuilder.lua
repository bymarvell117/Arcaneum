local SpellWords = require(script.Parent.SpellWords)
local StatFormulas = require(script.Parent.Parent.Combat.StatFormulas)

export type CustomSpellData = {
	TypeId: string,
	Amount: number,
	BlastSize: number, -- 0.2 - 1.0 (20% - 100%)
	ExplosionSize: number, -- 0.2 - 10.0 (20% - 1000%) — the "power" number, typed in directly
	UltimateArt: boolean,
	CastingStyle: string,
	Name: string,
	Duration: number, -- seconds, BeamAttack only
	Thickness: number, -- 0.2 - 1.0 (20% - 100%), BeamAttack only
}

export type ResolvedSpell = {
	Word: SpellWords.SpellWord,
	Spell: CustomSpellData,
	TypeId: string,
	Amount: number,
	DamagePerProjectile: number,
	ManaCostPerCast: number,
	Cooldown: number,
	ProjectileScale: number,
	Duration: number,
	ThicknessStuds: number,
	DamagePerSecond: number,
	ManaCostPerSecond: number,
}

local MIN_AMOUNT = 1
local MAX_AMOUNT = 5
local MIN_SIZE_FRACTION = 0.2
local MAX_SIZE_FRACTION = 1.0
-- Power (ExplosionSize) is a direct damage/mana-cost multiplier: 100% (1.0) casts at
-- your level's base damage for its base mana cost, 20% is a cheap-but-weak cast, and
-- 1000% is a deliberately "super powerful" cast that costs 10x as much mana. It gets a
-- much wider ceiling than the other sliders and is entered as a typed number rather
-- than picked from a handful of preset buttons — an extreme value is naturally gated
-- by how much mana you actually have, not by an artificial UI cap.
local MIN_EXPLOSION_FRACTION = 0.2
local MAX_EXPLOSION_FRACTION = 10.0
local ULTIMATE_ART_MULTIPLIER = 2
local MIN_DURATION = 1
local MAX_DURATION = 6
local MIN_THICKNESS_STUDS = 0.4
local THICKNESS_STUDS_RANGE = 1.6

local SpellBuilder = {}

local function clampAmount(value: number): number
	return math.clamp(math.floor(value), MIN_AMOUNT, MAX_AMOUNT)
end

local function clampSizeFraction(value: number): number
	return math.clamp(value, MIN_SIZE_FRACTION, MAX_SIZE_FRACTION)
end

local function clampExplosionFraction(value: number): number
	return math.clamp(value, MIN_EXPLOSION_FRACTION, MAX_EXPLOSION_FRACTION)
end

local function clampDuration(value: number): number
	return math.clamp(value, MIN_DURATION, MAX_DURATION)
end

-- Turns a player's saved custom spell into concrete numbers. Both the instant-cast
-- fields (BlastAttack: Amount/DamagePerProjectile/ManaCostPerCast) and the channeled
-- fields (BeamAttack: Duration/ThicknessStuds/DamagePerSecond/ManaCostPerSecond) are
-- always computed regardless of TypeId — SpellService picks whichever set applies.
-- Damage is driven by the caster's mage level (StatFormulas.SpellDamageForLevel), not
-- the Word, so leveling up your magic skill makes every spell hit harder; Power
-- (ExplosionSize) then multiplies that base damage up or down, at a proportional mana
-- cost, letting the same base spell be cast cheap-and-weak or expensive-and-devastating.
function SpellBuilder.Resolve(wordId: string, spell: CustomSpellData, mageLevel: number): ResolvedSpell?
	local word = SpellWords[wordId]
	if not word then
		return nil
	end

	local amount = clampAmount(spell.Amount)
	local blastSize = clampSizeFraction(spell.BlastSize)
	local powerMultiplier = clampExplosionFraction(spell.ExplosionSize)
	local ultimateMultiplier = spell.UltimateArt and ULTIMATE_ART_MULTIPLIER or 1

	local baseDamage = StatFormulas.SpellDamageForLevel(mageLevel)
	local blastFactor = 0.5 + blastSize

	local duration = clampDuration(spell.Duration or MIN_DURATION)
	local thicknessFraction = clampSizeFraction(spell.Thickness or MIN_SIZE_FRACTION)

	return {
		Word = word,
		Spell = spell,
		TypeId = spell.TypeId,
		Amount = amount,
		DamagePerProjectile = baseDamage * powerMultiplier * ultimateMultiplier,
		ManaCostPerCast = word.BaseManaCost * amount * powerMultiplier * blastFactor * ultimateMultiplier,
		Cooldown = word.Cooldown * ultimateMultiplier,
		ProjectileScale = blastFactor,
		Duration = duration,
		ThicknessStuds = MIN_THICKNESS_STUDS + thicknessFraction * THICKNESS_STUDS_RANGE,
		DamagePerSecond = baseDamage * powerMultiplier * ultimateMultiplier,
		ManaCostPerSecond = word.BaseManaCost * powerMultiplier * ultimateMultiplier,
	}
end

return SpellBuilder
