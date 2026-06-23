--[[
	CleanerChat - Server Compatibility Template
	
	Copy this file to create compatibility patches for a new server.
	
	Instructions:
	1. Copy this file and rename it to your server name (e.g., "TrueWoW.lua")
	2. Update the RegisterServer call below with your server's details
	3. Implement the detect() function to identify your server
	4. Implement the Apply() function with your server's patches
	5. Add your file to Compatibility.xml (or it won't be loaded!)
	6. Test thoroughly on your server
	
	Adding to Compatibility.xml:
	  <Script file="Servers\YourServer.lua"/>
	
	Tips:
	- Detection should be fast and reliable (checked on every login)
	- Use server-specific globals, realm names, or unique APIs
	- The Apply() function receives the CleanerChat namespace
	- You can override any function in the namespace
	- Keep patches minimal - only change what's necessary
	- Test with /ccdebug to see raw chat events
	
	Questions? Open an issue: https://github.com/migwynkriid/CleanerChat-WotLK/issues
]]

--[[
	IMPORTANT: This template file is NOT loaded by default.
	It exists only as a reference for contributors.
	To create a new server module:
	1. Copy this file
	2. Rename it (remove the underscore prefix)
	3. Add it to Compatibility.xml
]]

local Compat = _G.CleanerChat_Compatibility
if not Compat then return end

--[[
	Uncomment and modify the code below for your server.
	Replace "YourServer" with your server's identifier.
]]

--[=[

Compat:RegisterServer("YourServer", {
	-- Display name (shown in debug output)
	name = "Your Server Name",
	
	-- Priority: Higher numbers are checked first
	-- Recommended ranges:
	--   0       = Fallback (Native)
	--   50-99   = Low confidence detection
	--   100-149 = Normal servers
	--   150-199 = Servers with unique APIs
	--   200+    = Primary targets (Ascension uses 200)
	priority = 100,
	
	-- Description of what this module does
	description = "Compatibility patches for Your Server (yourserver.com).",
	
	-- Detection function
	-- Return true if we're running on this server
	-- Tips:
	--   - Check for server-specific global variables
	--   - Check realm name with GetRealmName()
	--   - Check for custom APIs unique to your server
	--   - Be specific to avoid false positives
	detect = function()
		-- Example: Check for a server-specific global
		if _G.YourServerAPI then
			return true
		end
		
		-- Example: Check realm name pattern
		local realm = GetRealmName()
		if realm and realm:match("YourServer") then
			return true
		end
		
		-- Example: Check for a specific addon that only exists on your server
		if IsAddOnLoaded("YourServerAddon") then
			return true
		end
		
		return false
	end,
	
	-- Apply function
	-- Called after CleanerChat is initialized if this server is detected
	-- Use this to override/patch CleanerChat behavior
	-- 
	-- @param ns - The CleanerChat addon namespace
	--             Contains: db, filters, modules, and all addon functions
	Apply = function(ns)
		-- Mark that we're on this server (for other code to check)
		ns.isYourServer = true
		
		-- Example: Override a filter function
		-- local originalFilter = ns.SomeFilterFunction
		-- ns.SomeFilterFunction = function(msg, ...)
		--     -- Your custom logic here
		--     msg = msg:gsub("OldPattern", "NewPattern")
		--     return originalFilter(msg, ...)
		-- end
		
		-- Example: Add a new chat pattern to the blacklist
		-- local Blacklist = ns:GetModule("Blacklist", true)
		-- if Blacklist then
		--     Blacklist:AddPattern("Your Server Message Pattern")
		-- end
		
		-- Example: Modify default settings for this server
		-- if ns.defaults then
		--     ns.defaults.someOption = true
		-- end
		
		-- Debug message (only shown if rawDebug is enabled)
		if ns.db and ns.db.rawDebug then
			print("|cff00ff00CleanerChat:|r Running in YourServer mode")
		end
	end,
})

]=]
