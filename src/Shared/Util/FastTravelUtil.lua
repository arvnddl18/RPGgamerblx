local FastTravelUtil = {}

function FastTravelUtil.GetLocation(config, id)
	if not config or not config.Locations or type(id) ~= "string" then
		return nil
	end
	return config.Locations[id]
end

function FastTravelUtil.GetEnabledLocations(config)
	local list = {}
	if not config or not config.Locations then
		return list
	end
	for id, location in config.Locations do
		if location.enabled ~= false then
			list[id] = location
		end
	end
	return list
end

function FastTravelUtil.IsUnlocked(location, snapshot)
	if not location or location.enabled == false then
		return false
	end

	local req = location.unlockRequirement or { type = "default" }
	local reqType = req.type or "default"

	if reqType == "default" then
		return true
	end

	if not snapshot then
		return false
	end

	local visited = snapshot.visited or {}
	local level = snapshot.level or 1
	local quest = snapshot.quest or {}

	if reqType == "visit" then
		return visited[location.id] == true
	end

	if reqType == "level" then
		return level >= (req.level or location.levelRequirement or 1)
	end

	if reqType == "quest" then
		if req.requireCompleted then
			return quest.id == req.questId and quest.completed == true
		end
		return quest.id == req.questId and quest.accepted == true
	end

	if reqType == "boss" then
		local defeated = snapshot.defeatedBosses or {}
		return defeated[req.bossId] == true
	end

	if reqType == "region" then
		local regions = snapshot.discoveredRegions or {}
		return regions[req.regionId] == true
	end

	return false
end

function FastTravelUtil.GetUnlockHint(location)
	if not location then
		return "Unknown destination"
	end

	local req = location.unlockRequirement or { type = "default" }
	local reqType = req.type or "default"

	if reqType == "default" then
		return ""
	end

	if reqType == "visit" then
		return "Visit this location to unlock"
	end

	if reqType == "level" then
		return "Requires Level " .. tostring(req.level or location.levelRequirement or 1)
	end

	if reqType == "quest" then
		if req.requireCompleted then
			return "Complete quest: " .. tostring(req.questId)
		end
		return "Accept quest: " .. tostring(req.questId)
	end

	if reqType == "boss" then
		return "Defeat boss: " .. tostring(req.bossId)
	end

	if reqType == "region" then
		return "Discover region: " .. tostring(req.regionId)
	end

	return "Locked"
end

function FastTravelUtil.WorldToMapPercent(pos, mapBounds)
	if not pos or not mapBounds then
		return 0.5, 0.5
	end

	local xRange = mapBounds.maxX - mapBounds.minX
	local zRange = mapBounds.maxZ - mapBounds.minZ
	if xRange == 0 or zRange == 0 then
		return 0.5, 0.5
	end

	local xPercent = (pos.X - mapBounds.minX) / xRange
	local zPercent = (pos.Z - mapBounds.minZ) / zRange
	return math.clamp(xPercent, 0, 1), math.clamp(zPercent, 0, 1)
end

function FastTravelUtil.BuildSnapshotFromData(data)
	if not data then
		return { visited = {}, level = 1, quest = {} }
	end

	return {
		visited = (data.fastTravel and data.fastTravel.visited) or {},
		level = data.level or 1,
		quest = data.quest or {},
		defeatedBosses = data.defeatedBosses or {},
		discoveredRegions = data.discoveredRegions or {},
	}
end

return FastTravelUtil
