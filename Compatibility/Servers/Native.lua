--[[
	CleanerChat - Native 3.3.5a Compatibility
	
	This is the fallback compatibility module for standard/vanilla 3.3.5a servers.
	It has the lowest priority (0) and will only be used if no other server matches.
	
	Native 3.3.5a characteristics:
	- No retail-backported APIs (C_Spell, C_ClassTalents, etc.)
	- Standard WotLK API set
	- No custom content systems
]]

local Compat = _G.CleanerChat_Compatibility
if not Compat then return end

Compat:RegisterServer("Native", {
	-- Display name
	name = "Native 3.3.5a",
	
	-- Lowest priority - this is the fallback
	priority = 0,
	
	-- Description
	description = "Standard WotLK 3.3.5a client with no custom server modifications.",
	
	-- Detection: This is the fallback, so it always matches
	-- (but due to low priority, other servers are checked first)
	detect = function()
		-- Check that we DON'T have custom server APIs
		-- If we have none of the known custom APIs, we're probably native
		local hasCustomAPIs = _G.C_ClassTalents or 
		                      _G.C_Spell or 
		                      _G.GetSpecialization or
		                      _G.C_CurrencyInfo or
		                      _G.C_MythicPlus or
		                      _G.C_AzeriteEmpoweredItem or
		                      _G.BACKDROP_DIALOG_32_32 or
		                      _G.BACKDROP_TOOLTIP_16_16_5555
		
		return not hasCustomAPIs
	end,
	
	-- Apply: No special patches needed for native 3.3.5a
	-- The base CleanerChat code handles native compatibility via polyfills
	Apply = function(ns)
		-- Native 3.3.5a uses the standard CleanerChat behavior
		-- No overrides needed - the polyfills in Core/Common/Compatibility.lua
		-- and GlassUI/compat.lua handle everything
		
		-- Debug message (only shown if rawDebug is enabled)
		if ns.db and ns.db.rawDebug then
			print("|cff00ff00CleanerChat:|r Running in Native 3.3.5a mode")
		end
	end,
})
