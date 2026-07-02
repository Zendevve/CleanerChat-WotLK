local _, ns = ...

local Module = ns:NewModule("MiscInfo")

-- Lua API
local string_find = string.find
local string_match = string.match

-- WoW Globals - Miscellaneous combat/info messages
local G = {
	-- Combo point messages
	COMBO_POINTS = COMBATLOG_COMBOPOINTGAIN or "You gain %d combo point",
	-- Energy/rage/mana messages
	POWER_GAIN = POWERGAIN or "You gain %d %s.",
}

-- Search Pattern Cache (self-populating via ns.MakePattern on first lookup).
local P = ns.MakePatternCache()

-- Safe pattern match that tolerates a nil pattern (shared helper).
local safeMatch = ns.SafeMatch

-- Filter out misc combat info spam
Module.OnAddMessage = function(self, chatFrame, msg, r, g, b, chatID, ...)
	if not msg then return end
	
	-- Filter combo point messages
	if string_find(msg, "combo point") then
		return true
	end
	
	-- Filter "You gain X energy/rage/mana" type spam messages
	-- These are typically redundant with the UI indicators
	local amount, power = safeMatch(msg, P[G.POWER_GAIN])
	if amount and power then
		-- Only filter small/spam gains, not significant ones
		local n = tonumber(amount)
		if n and n <= 30 then
			return true
		end
	end
end

local onAddMessageProxy = function(...)
	return Module:OnAddMessage(...)
end

Module.OnChatEvent = function(self, chatFrame, event, message, author, ...)
	-- Filter power gain event messages
	if event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_COMBAT_PET_HITS" then
		-- Let the OnAddMessage handle filtering
		return
	end
end

Module.OnEnable = function(self)
	self:RegisterBlacklistFilter(onAddMessageProxy)
end

Module.OnDisable = function(self)
	self:UnregisterBlacklistFilter(onAddMessageProxy)
end
