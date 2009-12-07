--[[
item_battery
SHARED

An energy storage device. Powers various electrical devices. 
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Battery";
ITEM.Description="An energy storage device. Powers various electrical devices.";
ITEM.MaxPower=100;

ITEM.WorldModel="models/Items/battery.mdl";