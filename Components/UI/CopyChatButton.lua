local Core, Constants = unpack(select(2, ...))

local L = LibStub("AceLocale-3.0"):GetLocale("CleanerChat")

local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local Mixin = Mixin
-- luacheck: pop

----
-- CopyChatButton
--
-- Small opt-in corner button that opens the Copy Chat dialog for whichever
-- tab is currently selected in its window, ported from Chatter's optional
-- "copyIcon" (off by default there too -- see Modules/CopyChat.lua). One of
-- these is created per Glass window and anchored to the window's container
-- (the chat message area), bottom-right, mirroring where Chatter anchors its
-- own button on the native chat frame.
--
-- The container's bottom-right corner is clear of everything else Glass
-- draws: the tab dock sits at the container's *top*, the scroll/"unread
-- messages" indicator is anchored *outside* the container's bottom edge (in
-- the gap before the edit box), and the mover's resize grips only exist on
-- the (normally hidden) mover overlay, which fully covers the chat area
-- whenever it's shown -- so there's never a moment where both it and this
-- button are meant to be clicked at once.
local CopyChatButtonMixin = {}

local ICON_IDLE_SIZE = 12
local ICON_HOVER_SIZE = 28

function CopyChatButtonMixin:Init(window)
	self.window = window

	self:SetWidth(ICON_IDLE_SIZE)
	self:SetHeight(ICON_IDLE_SIZE)
	self:SetPoint("BOTTOMRIGHT", self:GetParent(), "BOTTOMRIGHT", -4, 4)
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 10)

	-- Plain paper/note icon -- reads as "copy text" without pulling in a
	-- spell icon the way Chatter does, and it's sized for small UI buttons
	-- rather than a full spell-icon border.
	self:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
	self:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
	self:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

	self:SetScript("OnClick", function()
		local chatFrame = (self.window.selectedTab and self.window.selectedTab.chatFrame) or self.window.primaryChatFrame
		if not chatFrame then
			return
		end
		local UIManager = Core:GetModule("UIManager", true)
		if UIManager then
			UIManager:ShowCopyChatDialog(chatFrame)
		end
	end)

	self:SetScript("OnEnter", function(btn)
		btn:SetWidth(ICON_HOVER_SIZE)
		btn:SetHeight(ICON_HOVER_SIZE)
		GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(L["Copy Chat Text"])
		GameTooltip:AddLine(L["Copy text from this window."], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	self:SetScript("OnLeave", function(btn)
		btn:SetWidth(ICON_IDLE_SIZE)
		btn:SetHeight(ICON_IDLE_SIZE)
		GameTooltip:Hide()
	end)

	if Core.db.profile.showCopyIcon then
		self:Show()
	else
		self:Hide()
	end

	if self.subscription == nil then
		self.subscription = Core:Subscribe(UPDATE_CONFIG, function(payload)
			local key = Core:ResolveConfigKey(payload)
			if key == "showCopyIcon" then
				if Core.db.profile.showCopyIcon then
					self:Show()
				else
					self:Hide()
				end
			end
		end)
	end
end

function CopyChatButtonMixin:Destroy()
	if self.subscription then
		self.subscription()
		self.subscription = nil
	end
	self:Hide()
end

Core.Components.CreateCopyChatButton = function(parent, window)
	local button = CreateFrame("Button", nil, parent)
	local object = Mixin(button, CopyChatButtonMixin)
	object:Init(window)
	return object
end
