local Loader = {}

function Loader.LoadAndStart(container: Instance): { [string]: any }
	local loaded = {}

	for _, child in container:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, moduleOrError = pcall(require, child)
			if not ok then
				warn(("[Loader] Failed to require %s: %s"):format(child:GetFullName(), moduleOrError))
			else
				loaded[child.Name] = moduleOrError
			end
		end
	end

	for name, module in loaded do
		if type(module) == "table" and typeof(module.Init) == "function" then
			local ok, err = pcall(module.Init, module)
			if not ok then
				warn(("[Loader] %s:Init() failed: %s"):format(name, err))
			end
		end
	end

	for name, module in loaded do
		if type(module) == "table" and typeof(module.Start) == "function" then
			task.spawn(function()
				local ok, err = pcall(module.Start, module)
				if not ok then
					warn(("[Loader] %s:Start() failed: %s"):format(name, err))
				end
			end)
		end
	end

	return loaded
end

return Loader
