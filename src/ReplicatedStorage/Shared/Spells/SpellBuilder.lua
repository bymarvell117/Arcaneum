local SpellWords = require(script.Parent.SpellWords)

export type CustomSpellData = {
	TypeId: string,
	Amount: number,
	BlastSize: number, -- 0.2 - 1.0 (20% - 100%)
	ExplosionSize: number, -- 0.2 - 1.0 (20% - 100%)
	UltimateArt: boolean,
	CastingStyle: string,
	Name: string,
}

export type ResolvedSpell = {
	Word: SpellWords.SpellWord,
	Spell: CustomSpellData,
	Amount: number,
	DamagePerProjectile: number,
	ManaCostPerCast: number,
	Cooldown: number,
	ProjectileScale: number,
}

local MIN_AMOUNT = 1
local MAX_AMOUNT = 5
local MIN_SIZE_FRACTION = 0.2
local MAX_SIZE_FRACTION = 1.0
local ULTIMATE_ART_MULTIPLIER = 2

local SpellBuilder = {}

local function clampAmount(value: number): number
	return math.clamp(math.floor(value), MIN_AMOUNT, MAX_AMOUNT)
end

local function clampSizeFraction(value: number): number
	return math.clamp(value, MIN_SIZE_FRACTION, MAX_SIZE_FRACTION)
end

-- Turns a player's saved custom spell (word + amount + the two size sliders + Ultimate
-- Art) into concrete damage/mana/cooldown numbers. Blast Size mainly affects the
-- projectile's visual scale; Explosion Size is the "power" slider, driving damage and
-- mana cost; Ultimate Art doubles power, cost, and cast time (cooldown) together.
function SpellBuilder.Resolve(wordId: string, spell: CustomSpellData): ResolvedSpell?
	local word = SpellWords[wordId]
	if not word then
		return nil
	end

	local amount = clampAmount(spell.Amount)
	local blastSize = clampSizeFraction(spell.BlastSize)
	local explosionSize = clampSizeFraction(spell.ExplosionSize)
	local ultimateMultiplier = spell.UltimateArt and ULTIMATE_ART_MULTIPLIER or 1

	local explosionFactor = 0.5 + explosionSize
	local blastFactor = 0.5 + blastSize

	local damagePerProjectile = word.BaseDamage * explosionFactor * ultimateMultiplier
	local manaCostPerCast = word.BaseManaCost * amount * explosionFactor * blastFactor * ultimateMultiplier
	local cooldown = word.Cooldown * ultimateMultiplier

	return {
		Word = word,
		Spell = spell,
		Amount = amount,
		DamagePerProjectile = damagePerProjectile,
		ManaCostPerCast = manaCostPerCast,
		Cooldown = cooldown,
		ProjectileScale = blastFactor,
	}
end

return SpellBuilder
