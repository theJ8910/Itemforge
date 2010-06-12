--[[
item_crate
SHARED

A small wooden supply crate.
This uses the Ammunition Crate model.
]]--

include("inv_crate.lua");

if SERVER then

AddCSLuaFile("shared.lua");
AddCSLuaFile("inv_crate.lua")

end

ITEM.Name="Crate";
ITEM.Description="A small wooden supply crate.\n";
ITEM.Base="base_container";
ITEM.WorldModel="models/Items/item_item_crate.mdl";
ITEM.Size=27;					--This is the bounding radius of the box's model.
ITEM.Weight=15000;				--Somewhat arbitrary weight.
ITEM.MaxHealth=20;				--Based upon the :MaxHealth() of a prop with this model.

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.HoldType="slam";

if CLIENT then

ITEM.WorldModelNudge=Vector(5,0,0);
ITEM.WorldModelRotate=Angle(0,-10,90);

end

--Overridden Base Container stuff
ITEM.InvTemplate="inv_crate";