local _, ns = ...

-- GLOBALS: GetBuildInfo

-- WoW client interface version
------------------------------------------------------
local _, _, _, interfaceVersion = GetBuildInfo()

-- 3.3.5 specific detection (private server)
-- Interface 30300 is 3.3.5a, Classic Wrath uses 30400+
ns.Private.Is335 = (interfaceVersion >= 30300) and (interfaceVersion < 30400)
