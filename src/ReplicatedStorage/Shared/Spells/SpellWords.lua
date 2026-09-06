export type SpellWord = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	BaseDamage: number,
	BaseManaCost: number,
	Cooldown: number,
	ProjectileSpeed: number,
	MinMageLevel: number,
}

local SpellWords: { [string]: SpellWord } = {
	Ignis = {
		Id = "Ignis",
		DisplayName = "Ignis",
		Color = Color3.fromRGB(255, 106, 0),
		BaseDamage = 12,
		BaseManaCost = 10,
		Cooldown = 0.6,
		ProjectileSpeed = 90,
		MinMageLevel = 1,
	},
	Glacies = {
		Id = "Glacies",
		DisplayName = "Glacies",
		Color = Color3.fromRGB(120, 210, 255),
		BaseDamage = 8,
		BaseManaCost = 12,
		Cooldown = 0.8,
		ProjectileSpeed = 75,
		MinMageLevel = 1,
	},
	Fulgur = {
		Id = "Fulgur",
		DisplayName = "Fulgur",
		Color = Color3.fromRGB(255, 240, 120),
		BaseDamage = 18,
		BaseManaCost = 16,
		Cooldown = 1.1,
		ProjectileSpeed = 160,
		MinMageLevel = 1,
	},
	Terra = {
		Id = "Terra",
		DisplayName = "Terra",
		Color = Color3.fromRGB(120, 90, 60),
		BaseDamage = 20,
		BaseManaCost = 18,
		Cooldown = 1.4,
		ProjectileSpeed = 55,
		MinMageLevel = 5,
	},
}

return SpellWords
