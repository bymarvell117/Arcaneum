local StatFormulas = {}

function StatFormulas.MaxManaForLevel(mageLevel: number): number
	return 100 + (mageLevel - 1) * 20
end

function StatFormulas.MaxHealthForLevel(characterLevel: number): number
	return 100 + (characterLevel - 1) * 15
end

function StatFormulas.XPToNextLevel(level: number): number
	return math.floor(50 * level ^ 1.5)
end

function StatFormulas.LevelFromXP(totalXP: number): number
	local level = 1
	local remaining = totalXP
	while remaining >= StatFormulas.XPToNextLevel(level) do
		remaining -= StatFormulas.XPToNextLevel(level)
		level += 1
	end
	return level
end

function StatFormulas.XPForLevel(level: number): number
	local total = 0
	for l = 1, level - 1 do
		total += StatFormulas.XPToNextLevel(l)
	end
	return total
end

return StatFormulas
