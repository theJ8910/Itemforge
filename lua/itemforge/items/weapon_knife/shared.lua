--[[
weapon_knife
SHARED

Kind of sharp.
When the combination stuff comes in the knife could be a useful tool for things like
cutting rope, slicing fruit, etc.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Combat Knife";
ITEM.Description="A combat knife. It's blade may also prove useful for other purposes.";
ITEM.Base="base_melee";
ITEM.Size=10;
ITEM.Weight=238;		--Weight from http://www.crkt.com/Ultima-5in-Black-Blade-Veff-Combo-Edge

ITEM.WorldModel = "models/weapons/w_knife_t.mdl";
ITEM.ViewModel = "models/weapons/v_knife_t.mdl";

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.4;

--Overridden Base Melee stuff
ITEM.HitRange=75;
ITEM.HitForce=1;
ITEM.HitDamage=10;
ITEM.ViewKickMin=Angle(0.5,1.0,0);
ITEM.ViewKickMax=Angle(0.-5,-1.0,0);