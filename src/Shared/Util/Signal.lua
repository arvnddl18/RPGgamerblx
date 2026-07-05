local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({
		_connections = {},
	}, Signal)
	return self
end

function Signal:Connect(callback)
	local connection = { callback = callback, connected = true }
	table.insert(self._connections, connection)
	return {
		Disconnect = function()
			connection.connected = false
		end,
	}
end

function Signal:Fire(...)
	for _, connection in self._connections do
		if connection.connected then
			connection.callback(...)
		end
	end
end

return Signal
