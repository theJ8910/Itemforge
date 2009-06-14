--[[
Itemforge Clientside Init
CLIENT

Runs the Itemforge shared.lua.
]]--
include("itemforge/shared.lua")

--Initialize itemforge clientside. This runs AFTER IF:Initialize() in shared.lua (so it's safe to reference itemforge modules here)
function IF:ClientInitialize()
end