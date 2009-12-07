--[[
item_bag
SHARED

A small container.
]]--

include("inv_bag.lua");

if SERVER then

AddCSLuaFile("shared.lua");
AddCSLuaFile("inv_bag.lua")

end

ITEM.Name="Paper Bag";
ITEM.Description="A small, flimsy paper bag from a multinational fast-food chain.\n";
ITEM.Base="base_container";
ITEM.WorldModel="models/props_junk/garbage_bag001a.mdl";
ITEM.Size=13;					--This is the bounding radius of the bag's model.
ITEM.Weight=50;					--Weighs 50 grams (about 1/10 of a pound - in fact this may even be too heavy... too bad I don't have accurate weight measurement at my disposal)
ITEM.MaxHealth=10;				--Paper bags are pathetically weak.

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

if SERVER then

ITEM.HoldType="normal";

else

ITEM.WorldModelNudge=Vector(5,0,0);
ITEM.WorldModelRotate=Angle(0,-10,90);

end

--Overridden Base Container stuff
ITEM.InvTemplate="inv_bag";