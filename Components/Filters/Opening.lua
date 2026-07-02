local _, ns = ...

local Module = ns:NewModule("Opening")

-- Lua API
local string_match = string.match

-- WoW Globals - Opening messages for lockpicking, chests, etc.
-- In 3.3.5 these appear in CHAT_MSG_OPENING or via AddMessage
local G = {
	-- "Opening..."
	OPENING = OPENING or "Opening...",
	-- "Unlocking..."  
	UNLOCKING = UNLOCKING or "Unlocking...",
}

-- Search Pattern Cache (self-populating via ns.MakePattern on first lookup).
local P = ns.MakePatternCache()

-- Safe pattern match that tolerates a nil pattern (shared helper).
local safeMatch = ns.SafeMatch

-- Filter out opening/unlocking spam messages
Module.OnAddMessage = function(self, chatFrame, msg, r, g, b, chatID, ...)
	if msg == G.OPENING or msg == G.UNLOCKING then
		return true -- Suppress the message
	end
	
	-- Check for partial matches
	if msg and (string_match(msg, "^Opening") or string_match(msg, "^Unlocking")) then
		return true
	end
end

local onAddMessageProxy = function(...)
	return Module:OnAddMessage(...)
end

Module.OnEnable = function(self)
	self:RegisterBlacklistFilter(onAddMessageProxy)
end

Module.OnDisable = function(self)
	self:UnregisterBlacklistFilter(onAddMessageProxy)
end
