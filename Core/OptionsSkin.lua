--[[

	OptionsSkin.lua

	Re-skins the /cc options window (a stock AceConfigDialog "Frame" + "TreeGroup")
	into a dark, translucent "Glass" panel with the gold CleanerChat accent
	(#DFBA69), so the configuration UI matches the addon's own identity instead
	of looking like a generic Ace3 backport.

	IMPORTANT: This skin must be cleaned up when the window closes to prevent
	polluting AceGUI's shared widget pool and bleeding into other addons.

	Everything here is purely cosmetic and fully defensive: each step is guarded
	so a missing sub-frame (e.g. on a future Ace3 update) is simply skipped and
	never breaks the actual options. The underlying options table is untouched.

--]]
local _, ns = ...

-- Palette ------------------------------------------------------------------

-- Gold accent, matches the |cffDFBA69CleanerChat|r title in the .toc.
local GOLD = { r = 223 / 255, g = 186 / 255, b = 105 / 255 }

-- Near-black translucent glass.
local PANEL = { r = 0.035, g = 0.035, b = 0.045, a = 0.95 }
local INNER = { r = 0.065, g = 0.065, b = 0.080, a = 0.88 }
local BTN_BG = { r = 0.12, g = 0.12, b = 0.14, a = 0.90 }

local SOLID = "Interface\\Buttons\\WHITE8x8"

-- Layout constants
local EDGE_INSET = 8 -- Main content inset from window edge
local TITLE_HEIGHT = 32 -- Title bar height
local STATUS_HEIGHT = 24 -- Status bar height at bottom

-- Default AceGUI Frame backdrop (to restore on cleanup)
local DefaultFrameBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 },
}

-- Default AceGUI Pane backdrop (for tree/border)
local DefaultPaneBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 },
}

-- A clean 1px-bordered flat backdrop.
local GlassBackdrop = {
	bgFile = SOLID,
	edgeFile = SOLID,
	tile = false,
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- Lua/WoW API locals
local ipairs = ipairs
local type = type
local CLOSE = CLOSE or "Close"

-- Helpers ------------------------------------------------------------------

local function applyGlass(frame, bg, borderAlpha)
	if (not frame) or not frame.SetBackdrop then
		return
	end
	frame:SetBackdrop(GlassBackdrop)
	frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
	frame:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, borderAlpha or 0.35)
end

-- Hide a button's default template textures (guarded individually).
local function stripButtonTextures(btn)
	local getters = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }
	for _, getter in ipairs(getters) do
		if btn[getter] then
			local tex = btn[getter](btn)
			if tex and tex.SetTexture then
				tex:SetTexture(nil)
			end
		end
	end
end

-- Flat dark button with a gold hover + gold label (used for Close).
local function styleButton(btn)
	if not btn then
		return
	end

	-- If already skinned, just make sure our textures are visible
	if btn.ccSkinned then
		if btn.ccBg then
			btn.ccBg:Show()
		end
		if btn.ccBorder then
			btn.ccBorder:Show()
		end
		local label = btn.GetFontString and btn:GetFontString()
		if label then
			label:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
		end
		return
	end
	btn.ccSkinned = true

	stripButtonTextures(btn)

	if not btn.ccBg then
		-- Gold edge underneath (full cover), dark fill on top inset by 1px so
		-- only a 1px gold frame shows around the edges.
		local border = btn:CreateTexture(nil, "BACKGROUND")
		border:SetTexture(SOLID)
		border:SetAllPoints()
		border:SetVertexColor(GOLD.r, GOLD.g, GOLD.b, 0.40)
		btn.ccBorder = border

		local bg = btn:CreateTexture(nil, "BORDER")
		bg:SetTexture(SOLID)
		bg:SetPoint("TOPLEFT", 1, -1)
		bg:SetPoint("BOTTOMRIGHT", -1, 1)
		bg:SetVertexColor(BTN_BG.r, BTN_BG.g, BTN_BG.b, BTN_BG.a)
		btn.ccBg = bg
	end

	local label = btn.GetFontString and btn:GetFontString()
	if label then
		label:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
	end

	btn:HookScript("OnEnter", function(self)
		if self.ccBg then
			self.ccBg:SetVertexColor(GOLD.r * 0.30, GOLD.g * 0.28, GOLD.b * 0.20, 0.95)
		end
		if self.ccBorder then
			self.ccBorder:SetVertexColor(GOLD.r, GOLD.g, GOLD.b, 0.85)
		end
	end)
	btn:HookScript("OnLeave", function(self)
		if self.ccBg then
			self.ccBg:SetVertexColor(BTN_BG.r, BTN_BG.g, BTN_BG.b, BTN_BG.a)
		end
		if self.ccBorder then
			self.ccBorder:SetVertexColor(GOLD.r, GOLD.g, GOLD.b, 0.40)
		end
	end)
end

-- Give a tree nav button a gold hover/selected highlight.
local function skinTreeButton(button)
	if (not button) or button.ccSkinned then
		return
	end
	button.ccSkinned = true
	local hl = button.GetHighlightTexture and button:GetHighlightTexture()
	if hl then
		hl:SetTexture(SOLID)
		hl:SetVertexColor(GOLD.r, GOLD.g, GOLD.b, 0.22)
	end
end

-- Skin the left category tree + its content border.
local function skinTree(tree, mainFrame)
	if not tree then
		return
	end

	-- Apply glass styling to tree frame (left category list)
	if tree.treeframe then
		applyGlass(tree.treeframe, INNER, 0.50)
	end

	-- Apply glass styling to content border (right content area)
	if tree.border then
		applyGlass(tree.border, INNER, 0.50)
	end

	-- New buttons are pooled/created lazily; skin them as they appear.
	if (not tree.ccButtonHook) and tree.CreateButton then
		tree.ccButtonHook = true
		local orig = tree.CreateButton
		tree.CreateButton = function(self)
			local b = orig(self)
			skinTreeButton(b)
			return b
		end
	end
	if tree.buttons then
		for _, b in ipairs(tree.buttons) do
			skinTreeButton(b)
		end
	end
end

-- Find the TreeGroup child of the window (defensive scan).
local function findTree(widget)
	if (not widget) or not widget.children then
		return nil
	end
	for _, child in ipairs(widget.children) do
		if (type(child) == "table") and child.treeframe then
			return child
		end
	end
	return nil
end

-- Find specific child frames
local function findCloseButton(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.GetObjectType and (child:GetObjectType() == "Button") then
			if child.GetText and (child:GetText() == CLOSE) then
				return child
			end
		end
	end
	return nil
end

local function findSizerButton(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.GetObjectType and (child:GetObjectType() == "Button") then
			-- Sizer button usually has no text and is small
			if (not child.GetText) or (child:GetText() == nil) or (child:GetText() == "") then
				local w, h = child:GetSize()
				if w and w < 20 and h and h < 20 then
					return child
				end
			end
		end
	end
	return nil
end

-- Main entry ---------------------------------------------------------------

-- Re-skin the AceConfigDialog window widget. Safe to call on every open.
function ns.SkinOptionsWindow(widget)
	if not widget then
		return
	end
	local f = widget.frame
	if not f then
		return
	end

	-- Main window: dark glass + gold border.
	applyGlass(f, PANEL, 0.85)

	-- Hide the default parchment header (centre + side caps).
	-- Do this every time we skin, in case cleanup showed them
	if widget.titlebg then
		widget.titlebg:Hide()
	end
	for _, region in ipairs({ f:GetRegions() }) do
		if region.GetObjectType and (region:GetObjectType() == "Texture") then
			local tex = region.GetTexture and region:GetTexture()
			if (type(tex) == "string") and (tex:find("UI%-DialogBox%-Header")) then
				region:Hide()
			end
		end
	end
	f.ccHeaderHidden = true

	-- Custom gold title bar + accent line.
	if not f.ccTitleBar then
		local bar = f:CreateTexture(nil, "ARTWORK")
		bar:SetTexture(SOLID)
		bar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
		bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
		bar:SetHeight(TITLE_HEIGHT)
		bar:SetVertexColor(GOLD.r * 0.16, GOLD.g * 0.14, GOLD.b * 0.09, 0.95)
		f.ccTitleBar = bar

		local line = f:CreateTexture(nil, "OVERLAY")
		line:SetTexture(SOLID)
		line:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
		line:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
		line:SetHeight(1)
		line:SetVertexColor(GOLD.r, GOLD.g, GOLD.b, 0.90)
		f.ccTitleLine = line
	else
		-- Show existing elements (may have been hidden by cleanup)
		f.ccTitleBar:Show()
		f.ccTitleLine:Show()
	end

	-- Title text: gold, larger, sitting on the bar.
	if widget.titletext then
		local tt = widget.titletext
		tt:SetParent(f)
		tt:ClearAllPoints()
		tt:SetPoint("CENTER", f.ccTitleBar, "CENTER", 0, 0)
		tt:SetDrawLayer("OVERLAY")
		tt:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
		if tt.GetFont and tt.SetFont then
			local font = tt:GetFont()
			if font then
				tt:SetFont(font, 16, "OUTLINE")
			end
		end
	end

	-- Create custom status bar at the bottom
	if not f.ccStatusBar then
		-- Status bar background
		local statusBar = CreateFrame("Frame", nil, f)
		statusBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
		statusBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
		statusBar:SetHeight(STATUS_HEIGHT)
		applyGlass(statusBar, INNER, 0.50)
		f.ccStatusBar = statusBar

		-- Horizontal divider line above status bar
		local statusLine = f:CreateTexture(nil, "OVERLAY")
		statusLine:SetTexture(SOLID)
		statusLine:SetPoint("BOTTOMLEFT", statusBar, "TOPLEFT", 0, 0)
		statusLine:SetPoint("BOTTOMRIGHT", statusBar, "TOPRIGHT", 0, 0)
		statusLine:SetHeight(1)
		statusLine:SetVertexColor(GOLD.r, GOLD.g, GOLD.b, 0.50)
		f.ccStatusLine = statusLine
	else
		-- Show existing elements (may have been hidden by cleanup)
		f.ccStatusBar:Show()
		f.ccStatusLine:Show()
	end

	-- Handle status text positioning
	if widget.statustext then
		widget.statustext:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
		widget.statustext:ClearAllPoints()
		widget.statustext:SetPoint("LEFT", f.ccStatusBar, "LEFT", 10, 0)
		widget.statustext:SetPoint("RIGHT", f.ccStatusBar, "RIGHT", -80, 0)

		-- Hide the original status background if it exists
		local origStatusBg = widget.statustext:GetParent()
		if origStatusBg and (origStatusBg ~= f) and (origStatusBg ~= f.ccStatusBar) then
			if origStatusBg.SetBackdrop then
				origStatusBg:SetBackdrop(nil)
			end
			if origStatusBg.Hide then
				-- Don't hide, just make it invisible
				origStatusBg:SetAlpha(0)
			end
		end
		-- Re-parent status text to our status bar
		widget.statustext:SetParent(f.ccStatusBar)
	end

	-- Find and style the close button
	local closeBtn = findCloseButton(f)
	if closeBtn then
		styleButton(closeBtn)
		-- Reposition close button to bottom right of status bar
		closeBtn:ClearAllPoints()
		closeBtn:SetPoint("RIGHT", f.ccStatusBar, "RIGHT", -6, 0)
		closeBtn:SetSize(60, STATUS_HEIGHT - 6)
	end

	-- Find and reposition the sizer/resize button
	local sizerBtn = findSizerButton(f)
	if sizerBtn and not f.ccSizerMoved then
		f.ccSizerMoved = true
		sizerBtn:ClearAllPoints()
		sizerBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
		-- Make sure sizer is on top
		sizerBtn:SetFrameLevel(f:GetFrameLevel() + 10)
	end

	-- Left category tree + content border.
	local tree = findTree(widget)
	if tree then
		skinTree(tree, f)

		-- Adjust tree frame positioning to align with our custom elements
		if tree.treeframe then
			tree.treeframe:ClearAllPoints()
			tree.treeframe:SetPoint("TOPLEFT", f, "TOPLEFT", EDGE_INSET, -(TITLE_HEIGHT + EDGE_INSET))
			tree.treeframe:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", EDGE_INSET, STATUS_HEIGHT + EDGE_INSET)
		end

		-- Adjust content border positioning
		if tree.border then
			tree.border:ClearAllPoints()
			tree.border:SetPoint("TOPLEFT", tree.treeframe, "TOPRIGHT", 4, 0)
			tree.border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -EDGE_INSET, STATUS_HEIGHT + EDGE_INSET)
		end
	end

	-- Hook cleanup to run when window closes (before widget returns to pool)
	if not f.ccCleanupHooked then
		f.ccCleanupHooked = true
		f:HookScript("OnHide", function()
			ns.CleanupOptionsWindow(widget)
		end)
	end
end

-- Cleanup function: restore original AceGUI styling before widget returns to pool
-- This prevents CleanerChat's theme from bleeding into other addons
function ns.CleanupOptionsWindow(widget)
	if not widget then
		return
	end
	local f = widget.frame
	if not f then
		return
	end

	-- Restore main frame backdrop to default
	if f.SetBackdrop then
		f:SetBackdrop(DefaultFrameBackdrop)
		f:SetBackdropColor(0, 0, 0, 1)
		f:SetBackdropBorderColor(1, 1, 1, 1)
	end

	-- Hide our custom elements (don't destroy, just hide in case window reopens)
	if f.ccTitleBar then
		f.ccTitleBar:Hide()
	end
	if f.ccTitleLine then
		f.ccTitleLine:Hide()
	end
	if f.ccStatusBar then
		f.ccStatusBar:Hide()
	end
	if f.ccStatusLine then
		f.ccStatusLine:Hide()
	end

	-- Show the original header textures
	if widget.titlebg then
		widget.titlebg:Show()
	end
	if f.ccHeaderHidden then
		for _, region in ipairs({ f:GetRegions() }) do
			if region.GetObjectType and (region:GetObjectType() == "Texture") then
				local tex = region.GetTexture and region:GetTexture()
				if (type(tex) == "string") and (tex:find("UI%-DialogBox%-Header")) then
					region:Show()
				end
			end
		end
	end

	-- Restore title text to default
	if widget.titletext then
		local tt = widget.titletext
		tt:SetTextColor(1, 0.82, 0) -- Default gold
		if tt.GetFont and tt.SetFont then
			local font = tt:GetFont()
			if font then
				tt:SetFont(font, 14, "") -- Default size, no outline
			end
		end
	end

	-- Restore status text
	if widget.statustext then
		widget.statustext:SetTextColor(1, 1, 1)
	end

	-- Restore close button
	local closeBtn = findCloseButton(f)
	if closeBtn then
		-- Hide our custom textures
		if closeBtn.ccBg then
			closeBtn.ccBg:Hide()
		end
		if closeBtn.ccBorder then
			closeBtn.ccBorder:Hide()
		end
		-- Restore font color
		local label = closeBtn.GetFontString and closeBtn:GetFontString()
		if label then
			label:SetTextColor(1, 0.82, 0) -- Default gold
		end
	end

	-- Restore tree styling
	local tree = findTree(widget)
	if tree then
		if tree.treeframe and tree.treeframe.SetBackdrop then
			tree.treeframe:SetBackdrop(DefaultPaneBackdrop)
			tree.treeframe:SetBackdropColor(0.1, 0.1, 0.1)
			tree.treeframe:SetBackdropBorderColor(0.4, 0.4, 0.4)
		end
		if tree.border and tree.border.SetBackdrop then
			tree.border:SetBackdrop(DefaultPaneBackdrop)
			tree.border:SetBackdropColor(0.1, 0.1, 0.1)
			tree.border:SetBackdropBorderColor(0.4, 0.4, 0.4)
		end
	end

	-- Clear skinned flags so next open re-applies our skin
	f.ccHeaderHidden = nil
end
