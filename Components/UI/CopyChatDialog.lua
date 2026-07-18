local Core = unpack(select(2, ...))

local L = LibStub("AceLocale-3.0"):GetLocale("CleanerChat")

-- luacheck: push ignore 113
local ChatFontNormal = ChatFontNormal
local CreateFrame = CreateFrame
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local Mixin = Mixin
local UIParent = UIParent
local UISpecialFrames = UISpecialFrames
-- luacheck: pop

----
-- CopyChatDialog
--
-- A simple "select all, ctrl+C" popup for grabbing chat text, ported from
-- Chatter's Copy Chat module (Modules/CopyChat.lua).
--
-- Glass hides the native ChatFrameN objects (alpha 0 + :Hide()) and renders
-- its own sliding messages on top of them, but every filtered message still
-- flows through the real chat frame's AddMessage first -- Glass only adds a
-- safe-hook to *also* mirror it into the Glass display (see
-- SlidingMessageFrame.lua), it doesn't stop the original call. That means
-- the native frame's FontString regions still hold the exact same scrollback
-- text Glass shows, invisible but fully intact, which is what this dialog
-- reads from.
local CopyChatDialogMixin = {}

-- Reused scratch buffer for the scraped lines, avoids a fresh table per open.
local lineBuffer = {}

-- Chat frames only create FontString regions for the lines they're currently
-- laying out. Briefly shrinking the font forces Blizzard to lay out (and
-- thus create regions for) the whole scrollback instead of just what fits at
-- the normal size, then the font is restored. Same trick Chatter uses.
local function CaptureChatFrameText(chatFrame)
	local _, fontSize = chatFrame:GetFont()
	FCF_SetChatWindowFontSize(chatFrame, chatFrame, 0.01)

	local regions = { chatFrame:GetRegions() }
	local count = 0
	for i = #regions, 1, -1 do
		local region = regions[i]
		if region:GetObjectType() == "FontString" then
			count = count + 1
			lineBuffer[count] = region:GetText() or ""
		end
	end

	FCF_SetChatWindowFontSize(chatFrame, chatFrame, fontSize)

	return table.concat(lineBuffer, "\n", 1, count)
end

function CopyChatDialogMixin:Init()
	self:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetWidth(500)
	self:SetHeight(400)
	self:SetPoint("CENTER", UIParent, "CENTER")
	self:SetFrameStrata("DIALOG")
	self:SetToplevel(true)
	self:SetClampedToScreen(true)
	self:EnableMouse(true)
	self:Hide()

	-- Let Escape close it, like any other special game frame.
	table.insert(UISpecialFrames, self:GetName())

	self.title = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	self.title:SetPoint("TOP", 0, -12)
	self.title:SetText(L["Copy Chat Text"])

	local scrollArea = CreateFrame("ScrollFrame", self:GetName() .. "ScrollFrame", self, "UIPanelScrollFrameTemplate")
	scrollArea:SetPoint("TOPLEFT", self, "TOPLEFT", 16, -36)
	scrollArea:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -32, 16)
	self.scrollArea = scrollArea

	local editBox = CreateFrame("EditBox", nil, self)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(99999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetWidth(400)
	editBox:SetHeight(270)
	editBox:SetScript("OnEscapePressed", function()
		self:Hide()
	end)
	self.editBox = editBox

	scrollArea:SetScrollChild(editBox)

	local close = CreateFrame("Button", nil, self, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", self, "TOPRIGHT")
end

-- Show the dialog filled with the scrollback of the given native chat frame
-- (_G.ChatFrame1..N, including temporary/whisper windows -- anything with a
-- real FCF chat frame works).
function CopyChatDialogMixin:Populate(chatFrame)
	if not chatFrame then
		return
	end

	self:Show()
	self:Raise()
	self.editBox:SetText(CaptureChatFrameText(chatFrame))
	self.editBox:SetFocus()
	self.editBox:HighlightText(0)
end

Core.Components.CreateCopyChatDialog = function(name, parent)
	local frame = CreateFrame("Frame", name, parent)
	local object = Mixin(frame, CopyChatDialogMixin)
	object:Init()
	return object
end
