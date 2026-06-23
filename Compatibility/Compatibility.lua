--[[
	CleanerChat Server Compatibility System
	
	This module provides a framework for server-specific patches.
	Custom servers can register their own compatibility modules to override
	or extend CleanerChat behavior.
	
	Usage:
	1. Create a new file in Compatibility/Servers/ (see _Template.lua)
	2. Call CleanerChat_Compatibility:RegisterServer() with your server config
	3. The system will auto-detect and apply the appropriate patches
	
	Detection order (first match wins):
	1. Custom globals (server-specific APIs)
	2. Realm name patterns
	3. Falls back to "Native" if nothing matches
]]

local _, ns = ...

-- Create the compatibility system
local Compat = {}
_G.CleanerChat_Compatibility = Compat

-- Registered servers (populated by server files)
Compat.servers = {}

-- The detected/active server module
Compat.activeServer = nil
Compat.activeServerName = nil

-- Detection state
Compat.detected = false

--[[
	Register a server compatibility module.
	
	@param name (string) - Unique identifier for this server (e.g., "Ascension", "TrueWoW")
	@param config (table) - Server configuration:
		- priority (number, optional) - Higher = checked first. Default: 100. Native uses 0.
		- detect (function) - Returns true if this server is detected.
		                      Receives no arguments.
		                      Should check for server-specific globals, realm names, etc.
		- Apply (function) - Called when this server is detected.
		                     Receives (CleanerChat_namespace) as argument.
		                     Use this to apply patches, hooks, or overrides.
		- name (string, optional) - Display name for the server. Defaults to `name`.
		- description (string, optional) - Description of what this module does.
	
	Example:
		CleanerChat_Compatibility:RegisterServer("MyServer", {
			priority = 200,
			detect = function()
				return _G.MyServerAPI ~= nil
			end,
			Apply = function(ns)
				-- Override/patch CleanerChat functions here
				ns.SomeFunction = function() ... end
			end,
			name = "My Custom Server",
			description = "Patches for MyServer private server",
		})
]]
function Compat:RegisterServer(name, config)
	if not name or type(name) ~= "string" then
		error("CleanerChat_Compatibility:RegisterServer() - name must be a string", 2)
	end
	if not config or type(config) ~= "table" then
		error("CleanerChat_Compatibility:RegisterServer() - config must be a table", 2)
	end
	if not config.detect or type(config.detect) ~= "function" then
		error("CleanerChat_Compatibility:RegisterServer() - config.detect must be a function", 2)
	end
	
	self.servers[name] = {
		name = config.name or name,
		priority = config.priority or 100,
		detect = config.detect,
		Apply = config.Apply,
		description = config.description,
	}
end

--[[
	Detect which server we're running on.
	Called automatically during addon initialization.
	
	@return (string) - The name of the detected server, or "Native" as fallback.
]]
function Compat:Detect()
	if self.detected then
		return self.activeServerName
	end
	
	-- Sort servers by priority (highest first)
	local sorted = {}
	for name, config in pairs(self.servers) do
		table.insert(sorted, { name = name, config = config })
	end
	table.sort(sorted, function(a, b)
		return (a.config.priority or 100) > (b.config.priority or 100)
	end)
	
	-- Check each server's detection function
	for _, entry in ipairs(sorted) do
		local success, result = pcall(entry.config.detect)
		if success and result then
			self.activeServer = entry.config
			self.activeServerName = entry.name
			self.detected = true
			return entry.name
		end
	end
	
	-- Fallback to Native if registered
	if self.servers["Native"] then
		self.activeServer = self.servers["Native"]
		self.activeServerName = "Native"
		self.detected = true
		return "Native"
	end
	
	self.detected = true
	return nil
end

--[[
	Apply the detected server's patches.
	Called after CleanerChat is fully initialized.
	
	@param namespace (table) - The CleanerChat addon namespace (ns)
]]
function Compat:Apply(namespace)
	if not self.detected then
		self:Detect()
	end
	
	if self.activeServer and self.activeServer.Apply then
		local success, err = pcall(self.activeServer.Apply, namespace)
		if not success then
			-- Print error but don't break the addon
			print("|cffff6666CleanerChat:|r Server compatibility error for " .. 
			      (self.activeServerName or "Unknown") .. ": " .. tostring(err))
		end
	end
end

--[[
	Get the name of the currently active server.
	
	@return (string or nil) - Server name, or nil if not detected yet.
]]
function Compat:GetActiveServer()
	if not self.detected then
		self:Detect()
	end
	return self.activeServerName
end

--[[
	Check if a specific server is currently active.
	
	@param name (string) - Server name to check
	@return (boolean) - True if this server is active
]]
function Compat:IsServer(name)
	if not self.detected then
		self:Detect()
	end
	return self.activeServerName == name
end

--[[
	Get information about a registered server.
	
	@param name (string) - Server name
	@return (table or nil) - Server config, or nil if not registered
]]
function Compat:GetServerInfo(name)
	return self.servers[name]
end

--[[
	List all registered servers.
	
	@return (table) - Array of server names
]]
function Compat:GetRegisteredServers()
	local list = {}
	for name in pairs(self.servers) do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

-- Expose to the CleanerChat namespace for internal use
ns.Compatibility = Compat
