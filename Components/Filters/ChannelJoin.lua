local _, ns = ...

local Module = ns:NewModule("Channeljoin")

-- Lua API
local string_find = string.find

-- Filter channel join/leave messages on login
Module.OnAddMessage = function(_, _, msg)
	if not msg then
		return
	end

	-- Filter "Joined Channel:" messages (handles both full names and abbreviated like [G])
	if string_find(msg, "Joined Channel") then
		return true
	end
	if string_find(msg, "Left Channel") then
		return true
	end
	if string_find(msg, "Changed Channel") then
		return true
	end
end

local onAddMessageProxy = function(...)
	return Module:OnAddMessage(...)
end

-- Filter the actual CHAT_MSG_CHANNEL_NOTICE event
-- In WotLK 3.3.5, message is the notice type like "YOU_JOINED", "YOU_LEFT", "YOU_CHANGED"
Module.OnChatEvent = function(self, chatFrame, event, message, ...)
	-- Filter all channel join/leave/change notices
	if message == "YOU_JOINED" or message == "YOU_LEFT" or message == "YOU_CHANGED" then
		return true
	end
end

local onChatEventProxy = function(...)
	return Module:OnChatEvent(...)
end

Module.OnEnable = function(self)
	self:RegisterBlacklistFilter(onAddMessageProxy)
	-- CHAT_MSG_CHANNEL_NOTICE fires with notice type as first arg
	self:RegisterMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", onChatEventProxy)
end

Module.OnDisable = function(self)
	self:UnregisterBlacklistFilter(onAddMessageProxy)
	self:UnregisterMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", onChatEventProxy)
end
