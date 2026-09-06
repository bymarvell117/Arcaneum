-- Color-only customization for now (skin/shirt/pants tint via HumanoidDescription's
-- Head/Torso/Arm/Leg colors) — no hair/face accessories yet, since those need real
-- Roblox catalog asset IDs we can't verify without live catalog access. Once real
-- character art direction exists, this is where accessory options would be added.
local AppearancePalette = {}

AppearancePalette.SkinColors = {
	Color3.fromRGB(141, 85, 36),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(224, 172, 105),
	Color3.fromRGB(233, 197, 153),
	Color3.fromRGB(241, 214, 178),
	Color3.fromRGB(255, 224, 189),
	Color3.fromRGB(252, 232, 214),
}

AppearancePalette.OutfitColors = {
	Color3.fromRGB(30, 30, 30),
	Color3.fromRGB(90, 90, 90),
	Color3.fromRGB(190, 190, 190),
	Color3.fromRGB(255, 192, 203),
	Color3.fromRGB(200, 40, 40),
	Color3.fromRGB(230, 120, 30),
	Color3.fromRGB(230, 200, 40),
	Color3.fromRGB(90, 180, 90),
	Color3.fromRGB(40, 170, 170),
	Color3.fromRGB(60, 110, 220),
	Color3.fromRGB(140, 80, 200),
	Color3.fromRGB(150, 100, 60),
	Color3.fromRGB(210, 180, 140),
}

return AppearancePalette
