local Core, Constants = unpack(select(2, ...))
local C = Core:GetModule("Config")

local AceDBOptions = Core.Libs.AceDBOptions
local LSM = Core.Libs.LSM

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("CleanerChat")

local UnlockMover = Constants.ACTIONS.UnlockMover
local LockMover = Constants.ACTIONS.LockMover
local UpdateConfig = Constants.ACTIONS.UpdateConfig

local SAVE_FRAME_POSITION = Constants.EVENTS.SAVE_FRAME_POSITION

-- Multi-window: track which window's settings are being edited
C.selectedWindowId = "Main"

-- Helper to get the profile for the currently selected window in options
local function GetConfigProfile()
  return Core:GetWindowProfile(C.selectedWindowId)
end

-- Helper to get window names for the dropdown
local function GetWindowChoices()
  local choices = { Main = "Main" }
  local UIManager = Core:GetModule("UIManager", true)
  if UIManager and UIManager.windows then
    for windowId in pairs(UIManager.windows) do
      if windowId ~= "Main" then
        choices[windowId] = windowId
      end
    end
  end
  return choices
end

local ANCHORS = {
  ["TOPLEFT"] = L["Top left"],
  ["TOPRIGHT"] = L["Top right"],
  ["BOTTOMLEFT"] = L["Bottom left"],
  ["BOTTOMRIGHT"] = L["Bottom right"]
}
local FLAGS = {
  [""] = L["None"],
  ["OUTLINE"] = L["Outline"],
  ["THICKOUTLINE"] = L["Thick Outline"],
  ["MONOCHROME"] = L["Monochrome"],
  ["MONOCHROME, OUTLINE"] = L["Monochrome Outline"],
  ["MONOCHROME, THICKOUTLINE"] = L["Monochrome Thick Outline"],
  ["OUTLINE, MONOCHROME"] = L["Outline Monochrome"],
}

function C:OnEnable()
  local options = {
      name = L["Glass"],
      handler = C,
      type = "group",
      args = {
        general = {
          name = L["General"],
          type = "group",
          order = 1,
          args = {
            windowSelector = {
              name = "Configure Window",
              desc = "Select which CleanerChat window to configure",
              type = "select",
              order = 1,
              values = GetWindowChoices,
              get = function() return C.selectedWindowId end,
              set = function(_, value) C.selectedWindowId = value end,
            },
            section1 = {
              name = L["Frame Position"],
              type = "group",
              inline = true,
              order = 2,
              args = {
                unlockFrame = {
                  name = function()
                    local UIManager = Core:GetModule("UIManager", true)
                    if UIManager and UIManager.moverDialog and UIManager.moverDialog:IsShown() then
                      return L["Lock frame"]
                    end
                    return L["Unlock frame"]
                  end,
                  type = "execute",
                  func = function()
                    local UIManager = Core:GetModule("UIManager", true)
                    if UIManager and UIManager.moverDialog and UIManager.moverDialog:IsShown() then
                      Core:Dispatch(LockMover())
                    else
                      Core:Dispatch(UnlockMover())
                    end
                  end,
                  order = 2.1,
                },
              }
            },
            section3 = {
              name = L["Frame"],
              type = "group",
              inline = true,
              order = 4,
              args = {
                frameXOfs = {
                  name = L["X offset"],
                  desc = "Default: "..Core.defaults.profile.positionAnchor.xOfs,
                  type = "range",
                  order = 4.1,
                  min = -9999,
                  max = 9999,
                  softMin = -2000,
                  softMax = 2000,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().positionAnchor.xOfs
                  end,
                  set = function (_, input)
                    GetConfigProfile().positionAnchor.xOfs = input
                    Core:Dispatch(UpdateConfig("framePosition"))
                  end
                },
                frameWidth = {
                  name = L["Width"],
                  desc = "Default: "..Core.defaults.profile.frameWidth..
                    "\nMin: 100",
                  type = "range",
                  order = 4.2,
                  min = 100,
                  max = 9999,
                  softMin = 300,
                  softMax = 800,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().frameWidth
                  end,
                  set = function (info, input)
                    GetConfigProfile().frameWidth = input
                    Core:Dispatch(UpdateConfig("frameWidth"))
                  end
                },
                frameYOfs = {
                  name = L["Y offset"],
                  desc = "Default: "..Core.defaults.profile.positionAnchor.yOfs,
                  type = "range",
                  order = 4.4,
                  min = -9999,
                  max = 9999,
                  softMin = -2000,
                  softMax = 2000,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().positionAnchor.yOfs
                  end,
                  set = function (_, input)
                    GetConfigProfile().positionAnchor.yOfs = input
                    Core:Dispatch(UpdateConfig("framePosition"))
                  end
                },
                frameHeight = {
                  name = L["Height"],
                  desc = "Default: "..Core.defaults.profile.frameHeight,
                  type = "range",
                  order = 4.5,
                  min = 1,
                  max = 9999,
                  softMin = 200,
                  softMax = 800,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().frameHeight
                  end,
                  set = function (info, input)
                    GetConfigProfile().frameHeight = input
                    Core:Dispatch(UpdateConfig("frameHeight"))
                  end
                },
                frameAnchor = {
                  name = L["Anchor"],
                  desc = "Default: "..GetConfigProfile().positionAnchor.point,
                  type = "select",
                  order = 4.3,
                  values = ANCHORS,
                  get = function ()
                    return GetConfigProfile().positionAnchor.point
                  end,
                  set = function (_, input)
                    GetConfigProfile().positionAnchor.point = input
                    Core:Dispatch(UpdateConfig("framePosition"))
                  end
                },
              }
            }
          }
        },
        editBox = {
          name = L["Edit box"],
          type = "group",
          order = 2,
          args = {
            section1 = {
              name = L["Appearance"],
              type = "group",
              inline = true,
              order = 1,
              args = {
                editBoxFont = {
                  name = L["Font"],
                  desc = L["Font to use for the edit box text."],
                  type = "select",
                  order = 1.0,
                  dialogControl = "LSM30_Font",
                  values = LSM:HashTable("font"),
                  get = function ()
                    return GetConfigProfile().editBoxFont
                  end,
                  set = function (_, input)
                    GetConfigProfile().editBoxFont = input
                    Core:Dispatch(UpdateConfig("editBoxFont"))
                  end,
                },
                editBoxFontSize = {
                  name = L["Font size"],
                  desc = "Default: "..Core.defaults.profile.editBoxFontSize.."\nMin: 1\nMax: 100",
                  type = "range",
                  min = 1,
                  max = 100,
                  softMin = 6,
                  softMax = 24,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().editBoxFontSize
                  end,
                  set = function (info, input)
                    GetConfigProfile().editBoxFontSize = input
                    Core:Dispatch(UpdateConfig("editBoxFontSize"))
                  end,
                  order = 1.1,
                },
                editBoxFontFlags = {
                  name = L["Font style"],
                  desc = L["Add an outline to the edit box text so it stands out instead of looking flat."],
                  type = "select",
                  order = 1.3,
                  values = FLAGS,
                  get = function ()
                    return GetConfigProfile().editBoxFontFlags
                  end,
                  set = function (_, input)
                    GetConfigProfile().editBoxFontFlags = input
                    Core:Dispatch(UpdateConfig("editBoxFontFlags"))
                  end,
                },
                editBoxBackgroundOpacity = {
                  name = L["Background opacity"],
                  desc = "Default: "..Core.defaults.profile.editBoxBackgroundOpacity,
                  type = "range",
                  order = 1.2,
                  min = 0,
                  max = 1,
                  softMin = 0,
                  softMax = 1,
                  step = 0.01,
                  get = function ()
                    return GetConfigProfile().editBoxBackgroundOpacity
                  end,
                  set = function (info, input)
                    GetConfigProfile().editBoxBackgroundOpacity = input
                    Core:Dispatch(UpdateConfig("editBoxBackgroundOpacity"))
                  end,
                },
                editBoxBackgroundColor = {
                  name = L["Background color"],
                  desc = L["The colour of the edit box background."],
                  type = "color",
                  hasAlpha = false,
                  order = 1.4,
                  get = function ()
                    local c = GetConfigProfile().editBoxBackgroundColor
                    return c.r, c.g, c.b
                  end,
                  set = function (info, r, g, b)
                    local c = GetConfigProfile().editBoxBackgroundColor
                    c.r, c.g, c.b = r, g, b
                    Core:Dispatch(UpdateConfig("editBoxBackgroundColor"))
                  end,
                },
              }
            },
            section2 = {
              name = L["Position"],
              type = "group",
              inline = true,
              order = 2,
              args = {
                editBoxAnchorPosition = {
                  name = L["Position"],
                  desc = "Default: "..Core.defaults.profile.editBoxAnchor.position,
                  type = "select",
                  order = 2.2,
                  values = {
                    ABOVE = L["Above"],
                    BELOW = L["Below"],
                  },
                  get = function ()
                    return GetConfigProfile().editBoxAnchor.position
                  end,
                  set = function (_, input)
                    GetConfigProfile().editBoxAnchor.position = input
                    if input == "ABOVE" then
                      GetConfigProfile().editBoxAnchor.yOfs = 5
                    else
                      GetConfigProfile().editBoxAnchor.yOfs = -5
                    end
                    Core:Dispatch(UpdateConfig("editBoxAnchor"))
                  end
                },
                editBoxAnchorYOfs = {
                  name = L["Vertical offset"],
                  desc = "Default: 5 or -5",
                  type = "range",
                  order = 2.1,
                  min = -9999,
                  max = 9999,
                  softMin = -10,
                  softMax = 10,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().editBoxAnchor.yOfs
                  end,
                  set = function (info, input)
                    GetConfigProfile().editBoxAnchor.yOfs = input
                    Core:Dispatch(UpdateConfig("editBoxAnchor"))
                  end
                }
              },
            },
            section3 = {
              name = L["Behavior"],
              type = "group",
              inline = true,
              order = 3,
              args = {
                showOnEditFocus = {
                  name = L["Show chat on focus"],
                  desc = L["When enabled, opening the edit box (pressing Enter or clicking) reveals the chat messages."],
                  type = "toggle",
                  order = 3.1,
                  get = function ()
                    return GetConfigProfile().showOnEditFocus
                  end,
                  set = function (info, input)
                    GetConfigProfile().showOnEditFocus = input
                  end,
                },
              },
            }
          },
        },
        messages = {
          name = L["Messages"],
          type = "group",
          order = 3,
          args = {
            section1 = {
              name = L["Appearance"],
              type = "group",
              inline = true,
              order = 1,
              args = {
                messageFont = {
                  name = L["Font"],
                  desc = L["Font to use for chat messages."],
                  type = "select",
                  order = 1.0,
                  dialogControl = "LSM30_Font",
                  values = LSM:HashTable("font"),
                  get = function ()
                    return GetConfigProfile().messageFont
                  end,
                  set = function (_, input)
                    GetConfigProfile().messageFont = input
                    Core:Dispatch(UpdateConfig("messageFont"))
                  end,
                },
                messageFontSize = {
                  name = L["Font size"],
                  desc = "Default: "..Core.defaults.profile.messageFontSize.."\nMin: 1\nMax: 100",
                  type = "range",
                  min = 1,
                  max = 100,
                  softMin = 6,
                  softMax = 24,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().messageFontSize
                  end,
                  set = function (info, input)
                    GetConfigProfile().messageFontSize = input
                    Core:Dispatch(UpdateConfig("messageFontSize"))
                  end,
                  order = 1.2,
                },
                messageFontFlags = {
                  name = L["Font style"],
                  desc = L["Add an outline to chat message text so it stands out instead of looking flat."],
                  type = "select",
                  order = 1.6,
                  values = FLAGS,
                  get = function ()
                    return GetConfigProfile().messageFontFlags
                  end,
                  set = function (_, input)
                    GetConfigProfile().messageFontFlags = input
                    Core:Dispatch(UpdateConfig("messageFontFlags"))
                  end,
                },
                chatBackgroundOpacity = {
                  name = L["Background opacity"],
                  desc = "Default: "..Core.defaults.profile.chatBackgroundOpacity,
                  type = "range",
                  order = 1.2,
                  min = 0,
                  max = 1,
                  softMin = 0,
                  softMax = 1,
                  step = 0.01,
                  get = function ()
                    return GetConfigProfile().chatBackgroundOpacity
                  end,
                  set = function (info, input)
                    GetConfigProfile().chatBackgroundOpacity = input
                    Core:Dispatch(UpdateConfig("chatBackgroundOpacity"))
                  end,
                },
                chatBackgroundColor = {
                  name = L["Background color"],
                  desc = L["The colour of the chat message background."],
                  type = "color",
                  hasAlpha = false,
                  order = 1.7,
                  get = function ()
                    local c = GetConfigProfile().chatBackgroundColor
                    return c.r, c.g, c.b
                  end,
                  set = function (info, r, g, b)
                    local c = GetConfigProfile().chatBackgroundColor
                    c.r, c.g, c.b = r, g, b
                    Core:Dispatch(UpdateConfig("chatBackgroundColor"))
                  end,
                },
                messageLeading = {
                  name = L["Leading"],
                  desc = "Default: "..Core.defaults.profile.messageLeading.."\nMin: 0\nMax: 10",
                  type = "range",
                  min = 0,
                  max = 10,
                  softMin = 0,
                  softMax = 5,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().messageLeading
                  end,
                  set = function (info, input)
                    GetConfigProfile().messageLeading = input
                    Core:Dispatch(UpdateConfig("messageLeading"))
                  end,
                  order = 1.3,
                },
                messageLinePadding = {
                  name = L["Line padding"],
                  desc = "Default: "..Core.defaults.profile.messageLinePadding.."\nMin: 0\nMax: 5",
                  type = "range",
                  min = 0,
                  max = 5,
                  softMin = 0,
                  softMax = 1,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().messageLinePadding
                  end,
                  set = function (info, input)
                    GetConfigProfile().messageLinePadding = input
                    Core:Dispatch(UpdateConfig("messageLinePadding"))
                  end,
                  order = 1.4,
                },
                messageLeftPadding = {
                  name = L["Left padding"],
                  desc = "Default: "..Core.defaults.profile.messageLeftPadding.."\nMin: 0\nMax: 50\n\n"..L["Controls the blank space on the left side of messages."],
                  type = "range",
                  min = 0,
                  max = 50,
                  softMin = 0,
                  softMax = 30,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().messageLeftPadding
                  end,
                  set = function (info, input)
                    GetConfigProfile().messageLeftPadding = input
                    Core:Dispatch(UpdateConfig("messageLeftPadding"))
                  end,
                  order = 1.5,
                },
                messageHistoryLimit = {
                  name = L["Message history"],
                  desc = "Default: "..Core.defaults.profile.messageHistoryLimit.."\nMin: 128\nMax: 2048\n\n"..L["Maximum number of messages to keep in memory per chat window. Higher values use more memory."],
                  type = "range",
                  min = 128,
                  max = 2048,
                  softMin = 128,
                  softMax = 1024,
                  step = 64,
                  get = function ()
                    return GetConfigProfile().messageHistoryLimit
                  end,
                  set = function (info, input)
                    GetConfigProfile().messageHistoryLimit = input
                  end,
                  order = 1.6,
                },
              },
            },
            section2 = {
              name = L["Animations"],
              type = "group",
              inline = true,
              order = 2,
              args = {
                disableAnimations = {
                  name = L["Disable animations"],
                  desc = L["Show messages instantly with no slide or fade -- the chat becomes static. The timing sliders below have no effect while this is on."],
                  type = "toggle",
                  order = 2.0,
                  get = function ()
                    return GetConfigProfile().messageAnimations == false
                  end,
                  set = function (_, input)
                    GetConfigProfile().messageAnimations = not input
                    Core:Dispatch(UpdateConfig("messageAnimations"))
                  end,
                },
                messagesAlwaysVisible = {
                  name = L["Keep messages visible"],
                  desc = L["Messages never fade out -- they stay on screen permanently. Overrides the fade out delay and duration below."],
                  type = "toggle",
                  order = 2.01,
                  get = function ()
                    return GetConfigProfile().messagesAlwaysVisible
                  end,
                  set = function (_, input)
                    GetConfigProfile().messagesAlwaysVisible = input
                    Core:Dispatch(UpdateConfig("messagesAlwaysVisible"))
                  end,
                },
                animationsSpacer = {
                  name = "",
                  type = "description",
                  order = 2.05,
                  width = "full",
                },
                chatHoldTime = {
                  name = L["Fade out delay"],
                  desc = "Default: "..Core.defaults.profile.chatHoldTime..
                    "\nMin: 1\nMax: 180",
                  type = "range",
                  order = 2.1,
                  min = 1,
                  max = 180,
                  softMin = 1,
                  softMax = 20,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().chatHoldTime
                  end,
                  set = function (info, input)
                    GetConfigProfile().chatHoldTime = input
                  end,
                },
                fadeInDuration = {
                  name = L["Fade in duration"],
                  desc = "Default: "..Core.defaults.profile.chatFadeInDuration..
                    "\nMin: 0\nMax:30",
                  type = "range",
                  order = 2.3,
                  min = 0,
                  max = 30,
                  softMin = 0,
                  softMax = 10,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().chatFadeInDuration
                  end,
                  set = function (_, input)
                    GetConfigProfile().chatFadeInDuration = input
                    Core:Dispatch(UpdateConfig("chatFadeInDuration"))
                  end
                },
                fadeOutDuration = {
                  name = L["Fade out duration"],
                  desc = "Default: "..Core.defaults.profile.chatFadeOutDuration..
                    "\nMin: 0\nMax:30",
                  type = "range",
                  order = 2.4,
                  min = 0,
                  max = 30,
                  softMin = 0,
                  softMax = 10,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().chatFadeOutDuration
                  end,
                  set = function (_, input)
                    GetConfigProfile().chatFadeOutDuration = input
                    Core:Dispatch(UpdateConfig("chatFadeOutDuration"))
                  end
                },
                slideInDuration = {
                  name = L["Slide in duration"],
                  desc = "Default: "..Core.defaults.profile.chatSlideInDuration,
                  type = "range",
                  order = 2.3,
                  min = 0,
                  max = 30,
                  softMin = 0,
                  softMax = 5,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().chatSlideInDuration
                  end,
                  set = function (_, input)
                    GetConfigProfile().chatSlideInDuration = input
                  end
                }
              }
            },
            section3 = {
              name = L["Misc"],
              type = "group",
              inline = true,
              order = 3,
              args = {
                indentWordWrap = {
                  name = L["Indent on line wrap"],
                  desc = L["Adds an indent when a message wraps beyond a single line."],
                  type = "toggle",
                  order = 3.1,
                  get = function ()
                    return GetConfigProfile().indentWordWrap
                  end,
                  set = function (info, input)
                    GetConfigProfile().indentWordWrap = input
                    Core:Dispatch(UpdateConfig("indentWordWrap"))
                  end,
                },
                mouseOverTooltips = {
                  name = L["Mouse over tooltips"],
                  desc = L["Should tooltips appear when hovering over chat links."],
                  type = "toggle",
                  order = 3.2,
                  get = function ()
                    return GetConfigProfile().mouseOverTooltips
                  end,
                  set = function (info, input)
                    GetConfigProfile().mouseOverTooltips = input
                  end,
                },
                iconTextureYOffset = {
                  type = "range",
                  name = L["Text icons Y offset"],
                  desc = "Default: "..Core.defaults.profile.iconTextureYOffset..
                    "\n"..L["Adjust this if text icons aren't centered."],
                  order = 3.4,
                  min = 0,
                  max = 12,
                  softMin = 0,
                  softMax = 12,
                  step = 3.1,
                  get = function ()
                    return GetConfigProfile().iconTextureYOffset
                  end,
                  set = function (info, input)
                    -- TODO: Update messages dynamically
                    GetConfigProfile().iconTextureYOffset = input
                  end,
                },
                messagesOnHover = {
                  name = L["Show messages on hover"],
                  desc = L["When enabled, hovering over the chat reveals faded messages. When disabled, only scrolling reveals them."],
                  type = "toggle",
                  order = 3.3,
                  get = function ()
                    return GetConfigProfile().messagesOnHover
                  end,
                  set = function (info, input)
                    GetConfigProfile().messagesOnHover = input
                    Core:Dispatch(UpdateConfig("messagesOnHover"))
                  end,
                },
                showTimestamps = {
                  name = L["Show timestamps"],
                  desc = L["Prepend each message with a timestamp in [HH:MM] format."],
                  type = "toggle",
                  order = 3.35,
                  get = function ()
                    return GetConfigProfile().showTimestamps
                  end,
                  set = function (info, input)
                    GetConfigProfile().showTimestamps = input
                  end,
                },
                scrollIndicatorHeader = {
                  name = L["Scroll Indicator"],
                  type = "header",
                  order = 3.5,
                },
                hideScrollIndicator = {
                  name = L["Hide scroll indicator"],
                  desc = L["Hide the \"Unread messages\" and \"Bring me to the present\" indicator completely."],
                  type = "toggle",
                  width = "full",
                  order = 3.55,
                  get = function ()
                    return GetConfigProfile().hideScrollIndicator
                  end,
                  set = function (info, input)
                    GetConfigProfile().hideScrollIndicator = input
                    Core:Dispatch(UpdateConfig("hideScrollIndicator"))
                  end,
                },
                scrollIndicatorColor = {
                  name = L["Indicator text color"],
                  desc = L["Color of the \"Unread messages\" and \"Bring me to the present\" text."],
                  type = "color",
                  hasAlpha = false,
                  width = 1,
                  order = 3.6,
                  disabled = function () return GetConfigProfile().hideScrollIndicator end,
                  get = function ()
                    local c = GetConfigProfile().scrollIndicatorColor
                    return c.r, c.g, c.b
                  end,
                  set = function (info, r, g, b)
                    local c = GetConfigProfile().scrollIndicatorColor
                    c.r, c.g, c.b = r, g, b
                    Core:Dispatch(UpdateConfig("scrollIndicatorColor"))
                  end,
                },
                scrollIndicatorOpacity = {
                  name = L["Indicator text opacity"],
                  desc = "Default: "..Core.defaults.profile.scrollIndicatorOpacity.."\n"..L["Opacity of the scroll indicator text."],
                  type = "range",
                  width = 1.5,
                  order = 3.65,
                  disabled = function () return GetConfigProfile().hideScrollIndicator end,
                  min = 0,
                  max = 1,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().scrollIndicatorOpacity
                  end,
                  set = function (info, input)
                    GetConfigProfile().scrollIndicatorOpacity = input
                    Core:Dispatch(UpdateConfig("scrollIndicatorOpacity"))
                  end,
                },
                scrollIndicatorBgColor = {
                  name = L["Indicator background color"],
                  desc = L["Background color behind the scroll indicator text."],
                  type = "color",
                  hasAlpha = false,
                  width = 1,
                  order = 3.7,
                  disabled = function () return GetConfigProfile().hideScrollIndicator end,
                  get = function ()
                    local c = GetConfigProfile().scrollIndicatorBgColor
                    return c.r, c.g, c.b
                  end,
                  set = function (info, r, g, b)
                    local c = GetConfigProfile().scrollIndicatorBgColor
                    c.r, c.g, c.b = r, g, b
                    Core:Dispatch(UpdateConfig("scrollIndicatorBgColor"))
                  end,
                },
                scrollIndicatorBgOpacity = {
                  name = L["Indicator background opacity"],
                  desc = "Default: "..Core.defaults.profile.scrollIndicatorBgOpacity.."\n"..L["Opacity of the scroll indicator background."],
                  type = "range",
                  width = 1.5,
                  order = 3.75,
                  disabled = function () return GetConfigProfile().hideScrollIndicator end,
                  min = 0,
                  max = 1,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().scrollIndicatorBgOpacity
                  end,
                  set = function (info, input)
                    GetConfigProfile().scrollIndicatorBgOpacity = input
                    Core:Dispatch(UpdateConfig("scrollIndicatorBgOpacity"))
                  end,
                },
              }
            },
          },
        },
        topBar = {
          name = L["Top bar"],
          type = "group",
          order = 4,
          args = {
            section1 = {
              name = L["Appearance"],
              type = "group",
              inline = true,
              order = 1,
              args = {
                dockFont = {
                  name = L["Font"],
                  desc = L["Font to use for the chat tab text."],
                  type = "select",
                  order = 1.0,
                  dialogControl = "LSM30_Font",
                  values = LSM:HashTable("font"),
                  get = function ()
                    return GetConfigProfile().dockFont
                  end,
                  set = function (_, input)
                    GetConfigProfile().dockFont = input
                    Core:Dispatch(UpdateConfig("dockFont"))
                  end,
                },
                dockFontSize = {
                  name = L["Font size"],
                  desc = "Default: "..Core.defaults.profile.dockFontSize.."\nMin: 1\nMax: 100"..
                    "\n"..L["Tab widths refit on /reload."],
                  type = "range",
                  order = 1.1,
                  min = 1,
                  max = 100,
                  softMin = 6,
                  softMax = 24,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().dockFontSize
                  end,
                  set = function (info, input)
                    GetConfigProfile().dockFontSize = input
                    Core:Dispatch(UpdateConfig("dockFontSize"))
                  end,
                },
                dockFontFlags = {
                  name = L["Font style"],
                  desc = L["Add an outline to the chat tab text so it stands out instead of looking flat."],
                  type = "select",
                  order = 1.15,
                  values = FLAGS,
                  get = function ()
                    return GetConfigProfile().dockFontFlags
                  end,
                  set = function (_, input)
                    GetConfigProfile().dockFontFlags = input
                    Core:Dispatch(UpdateConfig("dockFontFlags"))
                  end,
                },
                dockBackgroundOpacity = {
                  name = L["Background opacity"],
                  desc = "Default: "..Core.defaults.profile.dockBackgroundOpacity,
                  type = "range",
                  order = 1.2,
                  min = 0,
                  max = 1,
                  softMin = 0,
                  softMax = 1,
                  step = 0.01,
                  get = function ()
                    return GetConfigProfile().dockBackgroundOpacity
                  end,
                  set = function (info, input)
                    GetConfigProfile().dockBackgroundOpacity = input
                    Core:Dispatch(UpdateConfig("dockBackgroundOpacity"))
                  end,
                },
                dockBackgroundColor = {
                  name = L["Background color"],
                  desc = L["The colour of the top bar background."],
                  type = "color",
                  hasAlpha = false,
                  order = 1.3,
                  get = function ()
                    local c = GetConfigProfile().dockBackgroundColor
                    return c.r, c.g, c.b
                  end,
                  set = function (info, r, g, b)
                    local c = GetConfigProfile().dockBackgroundColor
                    c.r, c.g, c.b = r, g, b
                    Core:Dispatch(UpdateConfig("dockBackgroundColor"))
                  end,
                },
              },
            },
            section2 = {
              name = L["Animations"],
              type = "group",
              inline = true,
              order = 2,
              args = {
                disableAnimations = {
                  name = L["Disable animations"],
                  desc = L["Show and hide the top bar instantly with no fade -- the tabs become static. The timing sliders below have no effect while this is on."],
                  type = "toggle",
                  order = 2.0,
                  get = function ()
                    return GetConfigProfile().dockAnimations == false
                  end,
                  set = function (_, input)
                    GetConfigProfile().dockAnimations = not input
                    Core:Dispatch(UpdateConfig("dockAnimations"))
                  end,
                },
                tabsAlwaysVisible = {
                  name = L["Keep tabs visible"],
                  desc = L["Chat tabs never fade out -- they stay on screen permanently. Overrides the fade out delay and duration below."],
                  type = "toggle",
                  order = 2.01,
                  get = function ()
                    return GetConfigProfile().tabsAlwaysVisible
                  end,
                  set = function (_, input)
                    GetConfigProfile().tabsAlwaysVisible = input
                    Core:Dispatch(UpdateConfig("tabsAlwaysVisible"))
                  end,
                },
                topBarAnimationsSpacer = {
                  name = "",
                  type = "description",
                  order = 2.05,
                  width = "full",
                },
                dockHoldTime = {
                  name = L["Fade out delay"],
                  desc = "Default: "..Core.defaults.profile.dockHoldTime.."\nMin: 1\nMax: 180",
                  type = "range",
                  order = 2.1,
                  min = 1,
                  max = 180,
                  softMin = 1,
                  softMax = 20,
                  step = 1,
                  get = function ()
                    return GetConfigProfile().dockHoldTime
                  end,
                  set = function (info, input)
                    GetConfigProfile().dockHoldTime = input
                  end,
                },
                dockFadeOutDuration = {
                  name = L["Fade out duration"],
                  desc = "Default: "..Core.defaults.profile.dockFadeOutDuration.."\nMin: 0\nMax: 30",
                  type = "range",
                  order = 2.2,
                  min = 0,
                  max = 30,
                  softMin = 0,
                  softMax = 10,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().dockFadeOutDuration
                  end,
                  set = function (_, input)
                    GetConfigProfile().dockFadeOutDuration = input
                  end,
                },
                dockFadeInDuration = {
                  name = L["Slide in duration"],
                  desc = "Default: "..Core.defaults.profile.dockFadeInDuration.."\nMin: 0\nMax: 30",
                  type = "range",
                  order = 2.3,
                  min = 0,
                  max = 30,
                  softMin = 0,
                  softMax = 5,
                  step = 0.05,
                  get = function ()
                    return GetConfigProfile().dockFadeInDuration
                  end,
                  set = function (_, input)
                    GetConfigProfile().dockFadeInDuration = input
                  end,
                },
                tabsOnHover = {
                  name = L["Show tabs on hover"],
                  desc = L["When enabled, chat tabs fade out when idle and reappear on mouse hover. When disabled, tabs are always visible."],
                  type = "toggle",
                  order = 2.02,
                  get = function ()
                    return GetConfigProfile().tabsOnHover
                  end,
                  set = function (info, input)
                    GetConfigProfile().tabsOnHover = input
                    Core:Dispatch(UpdateConfig("tabsOnHover"))
                  end,
                },
              },
            },
          },
        },
        profile = AceDBOptions:GetOptionsTable(Core.db)
      }
  }

  -- Glass no longer owns its own options window or slash command -- its
  -- settings are embedded as categories in CleanerChat's /cc window. Expose the
  -- config groups for that, plus a helper so "/cc lock" can unlock the frame.
  Core.configGroups = options.args
  function Core.UnlockFrame()
    Core:Dispatch(UnlockMover())
  end

  Core.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")

  Core:Subscribe(SAVE_FRAME_POSITION, function (position)
    GetConfigProfile().positionAnchor = position
  end)
end

function C:RefreshConfig()
  -- General
  Core:Dispatch(UpdateConfig("frameHeight"))
  Core:Dispatch(UpdateConfig("frameWidth"))
  Core:Dispatch(UpdateConfig("framePosition"))

  -- Edit box
  Core:Dispatch(UpdateConfig("editBoxFont"))
  Core:Dispatch(UpdateConfig("editBoxFontSize"))
  Core:Dispatch(UpdateConfig("editBoxFontFlags"))
  Core:Dispatch(UpdateConfig("editBoxBackgroundOpacity"))
  Core:Dispatch(UpdateConfig("editBoxBackgroundColor"))
  Core:Dispatch(UpdateConfig("editBoxAnchor"))

  -- Messages
  Core:Dispatch(UpdateConfig("messageFont"))
  Core:Dispatch(UpdateConfig("messageFontSize"))
  Core:Dispatch(UpdateConfig("messageFontFlags"))
  Core:Dispatch(UpdateConfig("messageAnimations"))
  Core:Dispatch(UpdateConfig("messagesAlwaysVisible"))
  Core:Dispatch(UpdateConfig("chatBackgroundOpacity"))
  Core:Dispatch(UpdateConfig("chatBackgroundColor"))
  Core:Dispatch(UpdateConfig("chatFadeInDuration"))
  Core:Dispatch(UpdateConfig("chatFadeOutDuration"))
  Core:Dispatch(UpdateConfig("scrollIndicatorColor"))
  Core:Dispatch(UpdateConfig("scrollIndicatorOpacity"))
  Core:Dispatch(UpdateConfig("scrollIndicatorBgColor"))
  Core:Dispatch(UpdateConfig("scrollIndicatorBgOpacity"))
  Core:Dispatch(UpdateConfig("hideScrollIndicator"))

  -- Top bar (dock)
  Core:Dispatch(UpdateConfig("dockFont"))
  Core:Dispatch(UpdateConfig("dockFontSize"))
  Core:Dispatch(UpdateConfig("dockFontFlags"))
  Core:Dispatch(UpdateConfig("dockAnimations"))
  Core:Dispatch(UpdateConfig("tabsAlwaysVisible"))
  Core:Dispatch(UpdateConfig("dockBackgroundOpacity"))
  Core:Dispatch(UpdateConfig("dockBackgroundColor"))
  Core:Dispatch(UpdateConfig("tabsOnHover"))
end

function C:OnProfileReset()
  -- Also reset CleanerChat filter settings
  local CleanerChat = LibStub("AceAddon-3.0"):GetAddon("CleanerChat", true)
  if CleanerChat and CleanerChat.ResetCleanerChatSettings then
    CleanerChat:ResetCleanerChatSettings()
  end
  -- Refresh Glass UI config
  self:RefreshConfig()
end
