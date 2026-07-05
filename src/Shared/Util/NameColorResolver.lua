local KarmaConfig = require(script.Parent.Parent.Config.Karma)

local NameColorResolver = {}

function NameColorResolver.Resolve(karmaState, pvpMode)
	if karmaState == KarmaConfig.STATE_CHAOTIC then
		return KarmaConfig.CHAOTIC_COLOR
	elseif pvpMode == "Hostile" then
		return KarmaConfig.HOSTILE_COLOR
	else
		return KarmaConfig.PEACEFUL_COLOR
	end
end

return NameColorResolver
