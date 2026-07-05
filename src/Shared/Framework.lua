local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Framework = {
	_services = {},
	_controllers = {},
}

function Framework:GetService(name)
	local service = self._services[name]
	if not service then
		warn("Service not found: " .. name)
	end
	return service
end

function Framework:RegisterService(name, service)
	self._services[name] = service
end

function Framework:GetServices()
	return self._services
end

function Framework:GetController(name)
	local controller = self._controllers[name]
	if not controller then
		warn("Controller not found: " .. name)
	end
	return controller
end

function Framework:RegisterController(name, controller)
	self._controllers[name] = controller
end

function Framework:GetControllers()
	return self._controllers
end

function Framework:GetRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		if RunService:IsServer() then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		else
			folder = ReplicatedStorage:WaitForChild("Remotes")
		end
	end
	return folder
end

function Framework:GetRemote(name)
	local folder = self:GetRemotesFolder()
	local remote = folder:FindFirstChild(name)
	if not remote then
		if RunService:IsServer() then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		else
			remote = folder:WaitForChild(name)
		end
	end
	return remote
end

return Framework
