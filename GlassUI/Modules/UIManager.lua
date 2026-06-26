local Core, _, Utils = unpack(select(2, ...))
local UIManager = Core:GetModule("UIManager")

local CreateChatTab = Core.Components.CreateChatTab
local CreateEditBox = Core.Components.CreateEditBox
local CreateMoverDialog = Core.Components.CreateMoverDialog
local CreateWindow = Core.Components.CreateWindow

-- luacheck: push ignore 113
local BNToastFrame = BNToastFrame
local ChatAlertFrame = ChatAlertFrame
local CreateFrame = CreateFrame
local GetCVar = GetCVar
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local SetCVar = SetCVar
local UIParent = UIParent
-- luacheck: pop

----
-- UIManager Module
function UIManager:OnInitialize()
  self.state = {
    frames = {},
    tabs = {},
    temporaryFrames = {},
    temporaryTabs = {}
  }
  -- Registry of all Glass windows. Each window is keyed by its id (e.g. "Main").
  -- Multi-window support: other parts of the addon can iterate self.windows.
  self.windows = {}
end

function UIManager:OnEnable()
  self.tickerFrame = CreateFrame("Frame", "GlassUpdaterFrame", UIParent)

  -- Watch for Blizzard_CombatLog loading to hide its quick-button bar
  local addonWatcher = CreateFrame("Frame")
  addonWatcher:RegisterEvent("ADDON_LOADED")
  addonWatcher:SetScript("OnEvent", function(_, event, addon)
    if addon == "Blizzard_CombatLog" then
      local combatLogButtons = _G["CombatLogQuickButtonFrame"]
      if combatLogButtons then
        combatLogButtons:Hide()
        combatLogButtons:SetAlpha(0)
        -- Replace Show to prevent it from ever appearing
        combatLogButtons.Show = function() end
      end
    end
  end)
  -- Also check if it's already loaded
  if IsAddOnLoaded("Blizzard_CombatLog") then
    local combatLogButtons = _G["CombatLogQuickButtonFrame"]
    if combatLogButtons then
      combatLogButtons:Hide()
      combatLogButtons:SetAlpha(0)
      combatLogButtons.Show = function() end
    end
  end

  -- Shared "unlock to move" dialog (one for the whole UI).
  self.moverDialog = CreateMoverDialog("GlassMoverDialog", UIParent)

  -- Main window. CleanerChat renders into this single window today; grouping its
  -- pieces (mover, container, dock, message-frame pool) behind a Window object is
  -- the foundation for supporting multiple separate windows. The main window keeps
  -- the original frame names ("GlassMoverFrame"/"GlassFrame"/"GlassChatDock") so
  -- existing references and saved positions are unchanged.
  self.mainWindow = CreateWindow({
    id = "Main",
    parent = UIParent,
    moverName = "GlassMoverFrame",
    containerName = "GlassFrame",
    dockName = "GlassChatDock",
    primaryChatFrame = _G.ChatFrame1,
  })
  self.windows["Main"] = self.mainWindow

  -- Restore additional windows from saved profile (multi-window persistence)
  if Core.db.profile.windows then
    local nextNum = 2
    for windowId, windowProfile in pairs(Core.db.profile.windows) do
      if windowId ~= "Main" and type(windowProfile) == "table" then
        -- Determine the numeric suffix for frame names
        local num = tonumber(windowId:match("%d+")) or nextNum
        nextNum = math.max(nextNum, num + 1)

        local window = CreateWindow({
          id = windowId,
          parent = UIParent,
          moverName = "GlassMoverFrame" .. num,
          containerName = "GlassFrame" .. num,
          dockName = "GlassChatDock" .. num,
          primaryChatFrame = nil, -- Will be assigned by SetupTabs
        })
        if window then
          self.windows[windowId] = window
          -- Apply saved position
          if windowProfile.positionAnchor then
            window.moverFrame:ClearAllPoints()
            window.moverFrame:SetPoint(
              windowProfile.positionAnchor.point or "BOTTOMLEFT",
              UIParent,
              windowProfile.positionAnchor.point or "BOTTOMLEFT",
              windowProfile.positionAnchor.xOfs or 50,
              windowProfile.positionAnchor.yOfs or 200
            )
          end
        end
      end
    end
  end

  -- Backwards-compatible aliases so the rest of UIManager and the components keep
  -- working unchanged while the per-window migration proceeds.
  self.moverFrame = self.mainWindow.moverFrame
  self.container = self.mainWindow.container
  self.dock = self.mainWindow.dock
  self.slidingMessageFramePool = self.mainWindow.pool

  -- Back the shared render state with the main window's frame/tab tables so the
  -- existing SetupTabs/render loop (which uses self.state.frames) drives it.
  self.state.frames = self.mainWindow.frames
  self.state.tabs = self.mainWindow.tabs

  -- Helper function to check if a chat frame is actually in use
  local function IsChatFrameActive(index)
    local chatFrame = _G["ChatFrame"..index]
    local chatTab = _G["ChatFrame"..index.."Tab"]
    
    if not chatFrame or not chatTab then 
      return false 
    end
    
    -- ChatFrame1 (General) and ChatFrame2 (Combat Log) are always active
    if index <= 2 then 
      return true 
    end
    
    -- For frames 3+, check if they're docked
    if chatFrame.isDocked then
      return true
    end
    
    return false
  end

  -- Create tabs for active chat windows
  -- Use a small delay to ensure Blizzard chat system is fully ready
  local function SetupTabs(reveal)
    -- Hide native Combat Log initially (will be shown when its tab is selected)
    local combatLogFrame = _G.ChatFrame2
    if combatLogFrame then
      combatLogFrame:Hide()
      combatLogFrame:SetAlpha(0)
    end
    
    local activeTabs = {}
    for i=1, NUM_CHAT_WINDOWS do
      local chatFrame = _G["ChatFrame"..i]
      local chatTab = _G["ChatFrame"..i.."Tab"]
      
      if chatFrame then
        -- Skip Combat Log (ChatFrame2) - let it use native Blizzard rendering
        -- We still create a tab for it, but don't hide the native frame here
        local isCombatLog = (chatFrame == _G.ChatFrame2)
        
        -- Create or get the sliding message frame
        if not self.state.frames[i] then
          local smf = self.slidingMessageFramePool:Acquire()
          smf:Init(chatFrame)
          self.state.frames[i] = smf
        end
        
        local smf = self.state.frames[i]
        local isActive = IsChatFrameActive(i)
        
        if isActive then
          local tab = CreateChatTab(smf)
          self.state.tabs[i] = tab
          if tab then
            table.insert(activeTabs, tab)
          end
          
          -- Hide the original Blizzard chat frame visuals so Glass renders
          -- them. Skip Combat Log - it handles its own visibility via SelectChatTab.
          if not isCombatLog then
            chatFrame:SetAlpha(0)
          end
        else
          -- Hide unused chat frame and tab, and drop any stale tab reference so
          -- a closed window's tab is not re-shown later by SelectChatTab.
          if chatTab then
            chatTab:Hide()
          end
          self.state.tabs[i] = nil
        end
      end
    end

    -- Position all active tabs in the dock
    local UpdateTabPositions = Core.Components.UpdateTabPositions
    if UpdateTabPositions then
      UpdateTabPositions(activeTabs)
    end
    
    -- Don't auto-select - just show all frames for now
    -- Tab switching will be handled by click

    -- Only reveal the dock on an explicit initial setup. Re-asserts triggered by
    -- Blizzard's FCF_DockUpdate fire constantly while the combat log streams
    -- during combat; if those forced the dock visible, the idle-faded tabs would
    -- pop back up and then never fade again. On a real reveal we also re-arm the
    -- idle fade-out so the tabs always disappear again when left alone.
    if reveal and self.dock then
      self.dock:Show()
      if self.dock.FadeOutTabs then
        self.dock:FadeOutTabs()
      end
    end

    -- Show exactly one tab's messages. Every active chat frame gets its own
    -- SlidingMessageFrame anchored at the same spot, so without an explicit
    -- selection they all render together and different chats appear merged onto
    -- the first tab. Only (re)assert this on an explicit reveal, so the
    -- combat-driven re-asserts don't override the user's current tab.
    if reveal then
      local SelectChatTab = Core.Components.SelectChatTab
      if SelectChatTab then
        local tabToSelect = Core.Components.selectedTab or self.state.tabs[1]
        if tabToSelect then
          SelectChatTab(tabToSelect)
        end
      end
    end
  end
  
  -- Run setup now, then re-assert it. The Blizzard chat dock
  -- (GeneralDockManager / FCFDock) finishes initializing after login and can
  -- re-dock the tabs, pulling them back into the now-hidden dock manager so
  -- they appear to vanish. Re-running SetupTabs re-parents the tabs into the
  -- Glass dock and shows them; it is idempotent (frames and tabs are reused).
  SetupTabs(true)

  -- Move chat frames to their saved windows (multi-window persistence)
  local function MoveChatFramesToWindows()
    if not Core.db.profile.windows then return end
    for windowId, windowProfile in pairs(Core.db.profile.windows) do
      local window = self.windows[windowId]
      if window and windowProfile.chatFrames then
        for _, chatFrameIndex in ipairs(windowProfile.chatFrames) do
          local smf = self.state.frames[chatFrameIndex]
          if smf then
            -- Move SMF to this window
            smf.window = window
            smf.profile = window.profile
            if smf.tab then
              smf.tab.glassDock = window.dock
            end
            -- Transfer from main frames to this window's frames
            self.state.frames[chatFrameIndex] = nil
            window.frames[chatFrameIndex] = smf
          end
        end
      end
    end
  end

  if (C_Timer and C_Timer.After) then
    C_Timer.After(0.5, function () SetupTabs(true) end)
    C_Timer.After(2, function ()
      SetupTabs(true)
      MoveChatFramesToWindows()
    end)
  end

  -- Keep the tabs in the Glass dock whenever Blizzard re-lays out its chat dock.
  if (not self.dockUpdateHooked) then
    self.dockUpdateHooked = true

    -- Defer + debounce. Re-running the tab setup synchronously from inside
    -- Blizzard's dock update can re-enter its dock code and trip an assert in
    -- FrameXML\ChatFrame.lua, so schedule it for the next frame instead. We
    -- only hook the high-level FCF_DockUpdate (which already drives
    -- FCFDock_UpdateTabs) to avoid reacting to every internal call.
    local reassertScheduled = false
    local function ReassertTabs()
      if (reassertScheduled) then return end
      reassertScheduled = true
      if (C_Timer and C_Timer.After) then
        C_Timer.After(0, function ()
          reassertScheduled = false
          SetupTabs(false)
        end)
      else
        reassertScheduled = false
        SetupTabs(false)
      end
    end

    if (_G.hooksecurefunc and _G.FCF_DockUpdate) then
      _G.hooksecurefunc("FCF_DockUpdate", ReassertTabs)
    end
  end

  -- Edit box
  self.editBox = CreateEditBox(self.container, self.mainWindow.profile)

  -- Fix Battle.net Toast frame position (if it exists)
  if BNToastFrame and ChatAlertFrame then
    BNToastFrame:ClearAllPoints()
    BNToastFrame:SetPoint("BOTTOMLEFT", ChatAlertFrame, "BOTTOMLEFT", 0, 0)

    ChatAlertFrame:ClearAllPoints()
    ChatAlertFrame:SetPoint("BOTTOMLEFT", self.container, "TOPLEFT", 15, 10)
  end

  -- Hide the native chat buttons (chat menu "speech bubble", channel button and
  -- the voice mute/deafen mic buttons). Blizzard re-shows some of these on chat
  -- updates, so pin them hidden with a Show hook (installed once).
  -- Note: QuickJoinToastButton doesn't exist in WotLK 3.3.5
  if (not self.chatButtonsHidden) then
    self.chatButtonsHidden = true
    for _, buttonName in ipairs({
      "ChatFrameChannelButton",
      "ChatFrameMenuButton",
      "ChatFrameToggleVoiceDeafenButton",
      "ChatFrameToggleVoiceMuteButton",
    }) do
      local button = _G[buttonName]
      if button then
        button:Hide()
        if _G.hooksecurefunc then
          _G.hooksecurefunc(button, "Show", function (b) b:Hide() end)
        end
      end
    end
  end
  
  -- Hide Blizzard chat frame backgrounds and scroll buttons
  for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame"..i]
    if chatFrame then
      -- Hide background textures
      local bg = _G["ChatFrame"..i.."Background"]
      if bg then bg:Hide() end
      
      -- Hide resize button
      local resize = _G["ChatFrame"..i.."ResizeButton"]
      if resize then resize:Hide() end
      
      -- Hide scroll buttons (bottom/up/down)
      local bottomButton = _G["ChatFrame"..i.."BottomButton"]
      if bottomButton then bottomButton:Hide() end
      
      local upButton = _G["ChatFrame"..i.."UpButton"] 
      if upButton then upButton:Hide() end
      
      local downButton = _G["ChatFrame"..i.."DownButton"]
      if downButton then downButton:Hide() end
    end
  end
  
  -- Hide the GeneralDockManager if it exists (retail feature, may not exist in WotLK)
  if GeneralDockManager then
    GeneralDockManager:Hide()
  end
  
  -- Hide ChatFrame tab holder/container if it exists
  if ChatFrame1TabHolder then
    ChatFrame1TabHolder:Hide()
  end
  
  -- Hide any dock backgrounds
  if ChatFrame1Background then
    ChatFrame1Background:Hide()
  end

  -- Force classic chat style (if CVar exists in WotLK)
  local chatStyleCVar = GetCVar("chatStyle")
  if chatStyleCVar and chatStyleCVar ~= "classic" then
    SetCVar("chatStyle", "classic")
    Utils.notify('Chat Style set to "Classic Style"')

    -- Resets the background that IM style causes
    self.editBox:SetFocus()
    self.editBox:ClearFocus()
  end

  -- Handle temporary chat frames (whisper popout, pet battle)
  self:RawHook("FCF_OpenTemporaryWindow", function (...)
    local chatFrame = self.hooks["FCF_OpenTemporaryWindow"](...)
    local smf = self.slidingMessageFramePool:Acquire()
    smf:Init(chatFrame)

    self.state.temporaryFrames[chatFrame:GetName()] = smf
    self.state.temporaryTabs[chatFrame:GetName()] = CreateChatTab(smf)
    return chatFrame
  end, true)

  -- Hook FCF_GetCurrentChatFrame to return a sensible fallback when it would return nil
  -- This is the root cause of many dropdown callback errors - Glass doesn't keep
  -- UIDROPDOWNMENU_INIT_MENU in sync, so this function returns nil.
  -- Use direct function replacement for guaranteed interception.
  if _G.FCF_GetCurrentChatFrame and not self.fcfGetCurrentHooked then
    self.fcfGetCurrentHooked = true
    local origFCF_GetCurrentChatFrame = _G.FCF_GetCurrentChatFrame
    _G.FCF_GetCurrentChatFrame = function ()
      local result = origFCF_GetCurrentChatFrame()
      if not result then
        -- Fallback: use our tracked selection, or SELECTED_CHAT_FRAME, or ChatFrame1
        if Core.Components.selectedTab and Core.Components.selectedTab.chatFrame then
          result = Core.Components.selectedTab.chatFrame
        else
          result = _G.SELECTED_CHAT_FRAME or _G.DEFAULT_CHAT_FRAME or _G.ChatFrame1
        end
      end
      return result
    end
  end

  -- Guard FCF_CopyChatSettings against nil copyFrom
  -- When Glass tabs are selected, the Blizzard selection state may not be in sync,
  -- causing "Move to new window" to pass nil as the source frame. Default to
  -- DEFAULT_CHAT_FRAME (ChatFrame1) which always exists.
  if _G.FCF_CopyChatSettings then
    self:RawHook("FCF_CopyChatSettings", function (copyTo, copyFrom)
      if not copyFrom then
        copyFrom = _G.DEFAULT_CHAT_FRAME or _G.ChatFrame1
      end
      return self.hooks["FCF_CopyChatSettings"](copyTo, copyFrom)
    end, true)
  end

  -- Guard ChatFrame_RemoveChannel against nil chatFrame
  -- Dropdown callbacks use FCF_GetCurrentChatFrame() which may return nil
  if _G.ChatFrame_RemoveChannel then
    self:RawHook("ChatFrame_RemoveChannel", function (chatFrame, channel)
      if not chatFrame then
        chatFrame = _G.SELECTED_CHAT_FRAME or _G.DEFAULT_CHAT_FRAME or _G.ChatFrame1
      end
      return self.hooks["ChatFrame_RemoveChannel"](chatFrame, channel)
    end, true)
  end

  -- Guard ChatFrame_AddChannel against nil chatFrame (same pattern)
  if _G.ChatFrame_AddChannel then
    self:RawHook("ChatFrame_AddChannel", function (chatFrame, channel)
      if not chatFrame then
        chatFrame = _G.SELECTED_CHAT_FRAME or _G.DEFAULT_CHAT_FRAME or _G.ChatFrame1
      end
      return self.hooks["ChatFrame_AddChannel"](chatFrame, channel)
    end, true)
  end

  -- Close window
  self:RawHook("FCF_Close", function (chatFrame)
    self.hooks["FCF_Close"](chatFrame)

    local name = chatFrame:GetName()

    -- Temporary (whisper/popout) frame cleanup, only if this was one. The old
    -- code called Release() unconditionally, which passed nil for user-created
    -- windows.
    local tempSMF = self.state.temporaryFrames[name]
    if tempSMF then
      self.slidingMessageFramePool:Release(tempSMF)
      self.state.temporaryFrames[name] = nil
      self.state.temporaryTabs[name] = nil
    end

    -- If the closed window was the selected tab, drop the stale selection so the
    -- re-assert below falls back to the default (General) tab.
    if Core.Components.selectedTab and Core.Components.selectedTab.chatFrame == chatFrame then
      Core.Components.selectedTab = nil
    end

    -- Closing a window re-docks the remaining frames through Blizzard's dock
    -- (FCFDock_UpdateTabs), which re-parents EVERY tab into the hidden native
    -- GeneralDockManager -- and that path does not call FCF_DockUpdate, so our
    -- normal re-assert hook never fires. Without this, all tabs vanish until a
    -- /reload. Re-assert now to pull the remaining tabs back into the Glass dock.
    if SetupTabs then
      SetupTabs(true)
    end
  end, true)

  -- Start rendering
  self.timeElapsed = 0
  self.tickerFrame:SetScript("OnUpdate", function (_, elapsed)
    self.timeElapsed = self.timeElapsed + elapsed

    while (self.timeElapsed > 0.01) do
      self.timeElapsed = self.timeElapsed - 0.01

      self.container:OnFrame()

      -- Use pairs instead of ipairs to handle sparse arrays
      for _, smf in pairs(self.state.frames) do
        if smf and smf.OnFrame then
          smf:OnFrame()
        end
      end

      for _, smf in pairs(self.state.temporaryFrames) do
        if smf and smf.OnFrame then
          smf:OnFrame()
        end
      end
    end
  end)
end

-- Create a new CleanerChat window and move a chat frame's tab to it.
-- Returns the new window object, or nil if creation failed.
function UIManager:CreateNewWindow(chatFrameIndex)
  if not chatFrameIndex then return nil end

  -- Generate a unique window id
  local nextId = 2
  while self.windows["Window" .. nextId] do
    nextId = nextId + 1
  end
  local windowId = "Window" .. nextId

  -- Create profile for the new window (copy from main)
  local profile = Core:CreateWindowProfile(windowId, "Main")
  if not profile then return nil end

  -- Create the window frames
  local CreateWindow = Core.Components.CreateWindow
  local newWindow = CreateWindow({
    id = windowId,
    parent = UIParent,
    moverName = "GlassMoverFrame" .. nextId,
    containerName = "GlassFrame" .. nextId,
    dockName = "GlassChatDock" .. nextId,
    primaryChatFrame = _G["ChatFrame" .. chatFrameIndex],
  })
  if not newWindow then
    Core:DeleteWindowProfile(windowId)
    return nil
  end

  -- Register in windows table
  self.windows[windowId] = newWindow

  -- Offset the new window slightly from main so it's visible
  local mainPos = self.mainWindow.profile.positionAnchor
  profile.positionAnchor = {
    point = mainPos.point,
    xOfs = (mainPos.xOfs or 0) + 30,
    yOfs = (mainPos.yOfs or 0) - 30,
  }
  newWindow.moverFrame:ClearAllPoints()
  newWindow.moverFrame:SetPoint(
    profile.positionAnchor.point,
    UIParent,
    profile.positionAnchor.point,
    profile.positionAnchor.xOfs,
    profile.positionAnchor.yOfs
  )

  -- Store which chat frames belong to this window
  profile.chatFrames = profile.chatFrames or {}
  table.insert(profile.chatFrames, chatFrameIndex)

  -- Move the SMF from mainWindow to newWindow
  local smf = self.state.frames[chatFrameIndex]
  if smf then
    -- Re-parent to new window's container and pool
    smf.window = newWindow
    smf.profile = newWindow.profile
    -- Update the dock reference for the tab
    if smf.tab then
      smf.tab.glassDock = newWindow.dock
    end
    -- Move from main frames to new window frames
    self.state.frames[chatFrameIndex] = nil
    newWindow.frames[chatFrameIndex] = smf
  end

  -- Refresh tabs in both windows
  local UpdateTabPositions = Core.Components.UpdateTabPositions
  if UpdateTabPositions then
    local mainTabs = {}
    for _, tab in pairs(self.state.tabs) do
      if tab then table.insert(mainTabs, tab) end
    end
    UpdateTabPositions(mainTabs)

    local newTabs = {}
    for _, tab in pairs(newWindow.tabs) do
      if tab then table.insert(newTabs, tab) end
    end
    UpdateTabPositions(newTabs)
  end

  -- Show the new window
  newWindow.moverFrame:Show()
  newWindow.container:Show()
  newWindow.dock:Show()

  return newWindow
end

-- Delete a CleanerChat window and move its chat frames back to main.
function UIManager:DeleteWindow(windowId)
  if not windowId or windowId == "Main" then return end

  local window = self.windows[windowId]
  if not window then return end

  -- Move all SMFs back to mainWindow
  for chatFrameIndex, smf in pairs(window.frames) do
    smf.window = self.mainWindow
    smf.profile = self.mainWindow.profile
    if smf.tab then
      smf.tab.glassDock = self.mainWindow.dock
    end
    self.state.frames[chatFrameIndex] = smf
    window.frames[chatFrameIndex] = nil
  end

  -- Hide and destroy the window's frames
  if window.dock then window.dock:Hide() end
  if window.container then window.container:Hide() end
  if window.moverFrame then window.moverFrame:Hide() end

  -- Remove from registry
  self.windows[windowId] = nil

  -- Delete profile
  Core:DeleteWindowProfile(windowId)

  -- Refresh main window tabs
  local UpdateTabPositions = Core.Components.UpdateTabPositions
  if UpdateTabPositions then
    local mainTabs = {}
    for _, tab in pairs(self.state.tabs) do
      if tab then table.insert(mainTabs, tab) end
    end
    UpdateTabPositions(mainTabs)
  end
end

-- Get the window that owns a specific chat frame index
function UIManager:GetWindowForChatFrame(chatFrameIndex)
  for windowId, window in pairs(self.windows) do
    if window.frames[chatFrameIndex] then
      return window, windowId
    end
  end
  -- Default: main window owns it
  return self.mainWindow, "Main"
end
