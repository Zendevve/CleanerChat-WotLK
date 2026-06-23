--[[
	CleanerChat - Ascension WoW Compatibility
	
	This module provides compatibility patches for Ascension WoW (https://ascension.gg/).
	
	Ascension characteristics:
	- Retail-backported APIs (C_Spell, C_ClassTalents, etc.)
	- Custom content systems (Talent Essence, Dungeon Guide, etc.)
	- Modified game mechanics
	- BackdropTemplate and modern frame APIs available
]]

local Compat = _G.CleanerChat_Compatibility
if not Compat then return end

Compat:RegisterServer("Ascension", {
	-- Display name
	name = "Ascension WoW",
	
	-- High priority - Ascension is the primary development target
	priority = 200,
	
	-- Description
	description = "Compatibility patches for Ascension WoW private server (ascension.gg).",
	
	-- Detection: Check for Ascension-specific APIs
	detect = function()
		-- Ascension has retail-backported APIs that native 3.3.5 doesn't have
		-- Check for multiple to be sure (any one of these indicates Ascension/custom)
		
		-- C_Spell is a strong indicator of Ascension
		if _G.C_Spell then
			return true
		end
		
		-- C_ClassTalents is Ascension-specific (custom talent system)
		if _G.C_ClassTalents then
			return true
		end
		
		-- GetSpecialization doesn't exist in native 3.3.5
		if _G.GetSpecialization then
			return true
		end
		
		-- These backdrop constants exist on Ascension but not native
		if _G.BACKDROP_DIALOG_32_32 or _G.BACKDROP_TOOLTIP_16_16_5555 then
			return true
		end
		
		-- C_CurrencyInfo is another Ascension indicator
		if _G.C_CurrencyInfo then
			return true
		end
		
		return false
	end,
	
	-- Apply: Ascension-specific patches and configurations
	Apply = function(ns)
		-- Ascension is the primary development target, so most code already
		-- works correctly. This section is for any Ascension-specific overrides.
		
		-- Mark that we're on Ascension (other modules can check this)
		ns.isAscension = true
		
		-- Ascension-specific features that CleanerChat already handles:
		-- - Talent Essence messages (Components/Experience.lua)
		-- - Dungeon Guide channel "DG" (Components/Channels.lua, Locale/*.lua)
		-- - PvP currency outputs (Core/API/Output.lua)
		-- - BackdropTemplate (GlassUI/compat.lua - but not needed on Ascension)
		
		-- Future Ascension-specific patches can be added here.
		-- Examples:
		-- - Custom currency formatting
		-- - Ascension-specific chat channels
		-- - Custom achievement systems
		-- - Season-specific content
		
		-- Debug message (only shown if rawDebug is enabled)
		if ns.db and ns.db.rawDebug then
			print("|cff00ff00CleanerChat:|r Running in Ascension WoW mode")
		end
	end,
})
