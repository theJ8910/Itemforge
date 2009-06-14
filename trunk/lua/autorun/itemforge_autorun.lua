--[[
Itemforge Autorun
SHARED

Automatically runs the appropriate script clientside or serverside on init.
]]--
AddCSLuaFile("autorun/itemforge_autorun.lua");

if SERVER then
	include("itemforge/init.lua");
else
	include("itemforge/cl_init.lua");
end