-- DataStores can't store Color3 values directly, so appearance colors round-trip
-- through plain {R,G,B} tables instead.
local DEFAULT_COLOR = Color3.fromRGB(163, 162, 165)

export type SerializedColor = { R: number, G: number, B: number }

local ColorSerialization = {}

function ColorSerialization.ToTable(color: Color3): SerializedColor
	return { R = color.R, G = color.G, B = color.B }
end

function ColorSerialization.FromTable(data: SerializedColor?): Color3
	if not data then
		return DEFAULT_COLOR
	end
	return Color3.new(data.R, data.G, data.B)
end

return ColorSerialization
