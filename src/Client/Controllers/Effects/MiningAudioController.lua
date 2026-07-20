local Controller = {}

function Controller:Start()
	local Players = game:GetService("Players")
	local CollectionService = game:GetService("CollectionService")
	local MusicController = require(script.Parent.Parent.Effects.MusicController)
	
	local player = Players.LocalPlayer
	local activeMiningSound = nil -- currently looping Sound instance
	
	local function onMiningByChanged(part)
		local miningBy = part:GetAttribute("MiningBy")
		
		if miningBy == player.UserId then
			-- Player started mining this node
			if not activeMiningSound then
				activeMiningSound = MusicController:PlayLooped8DASMR("Mining")
			end
		else
			-- Player stopped mining (or someone else is mining)
			if activeMiningSound then
				activeMiningSound:Stop()
				activeMiningSound:Destroy()
				activeMiningSound = nil
			end
		end
	end
	
	local function bindNode(part)
		-- Listen for the MiningBy attribute changing
		part:GetAttributeChangedSignal("MiningBy"):Connect(function()
			onMiningByChanged(part)
		end)
	end
	
	-- Bind all existing MiningNode-tagged parts
	for _, part in CollectionService:GetTagged("MiningNode") do
		bindNode(part)
	end
	
	-- Bind future MiningNode-tagged parts
	CollectionService:GetInstanceAddedSignal("MiningNode"):Connect(bindNode)
	
	-- Clean up if the node gets destroyed while mining
	CollectionService:GetInstanceRemovedSignal("MiningNode"):Connect(function(part)
		if activeMiningSound and part:GetAttribute("MiningBy") == player.UserId then
			activeMiningSound:Stop()
			activeMiningSound:Destroy()
			activeMiningSound = nil
		end
	end)
end

return Controller
