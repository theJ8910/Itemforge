--[[
base_weapon
SHARED

base_weapon is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_weapon has two purposes:
	You can tell if an item is a weapon by checking to see if it inherits from base_weapon.
	It's designed to help you create weapons easier. You just have to change/override some variables or replace some stuff with your own code.

TODO need to optimize the networking of Primary/SecondaryNext[Auto] vars
]]--
if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Base Weapon";
ITEM.Description="This item is the base weapon.\nWeapons inherit from this.\n\nThis is not supposed to be spawned.";
ITEM.Base="item";
ITEM.WorldModel="models/weapons/w_pistol.mdl";
ITEM.ViewModel="models/weapons/v_pistol.mdl";

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;

if SERVER then
	ITEM.HoldType="pistol";
end

--Base Weapon
--[[
Be aware of how delay works!
PrimaryDelay/SecondaryDelay:
	After attacking with primary or secondary, the weapon can't attack again until it cools down for this long.
PrimaryDelayAuto/SecondaryDelayAuto:
	Whenever a player is holding down his primary/secondary attack button, the weapon will try to attack this often.
	For example, the HL2 pistol can be fired up to 10 times a second if you click fast enough,
	but if you hold down attack, it only attacks twice per second.
	This should be greater than or equal to PrimaryDelay/SecondaryDelay.
	If this is -1, it will be the same as PrimaryDelay/SecondaryDelay.
]]--
ITEM.PrimaryDelay=.5;
ITEM.SecondaryDelay=.5;
ITEM.PrimaryDelayAuto=-1;
ITEM.SecondaryDelayAuto=-1;

--Don't modify/override these. They're set automatically.
ITEM.PrimaryAuto=true;
ITEM.SecondaryAuto=true;

--This weapon doesn't do anything when you attack, except make you wait until you can attack again
function ITEM:OnPrimaryAttack()
	if !self:CanPrimaryAttack() || (self:IsHeld() && self:GetWOwner():KeyDownLast(IN_ATTACK) && !self:CanPrimaryAttackAuto()) then return false; end
	self:SetNextPrimary(CurTime()+self:GetPrimaryDelay(),CurTime()+self:GetPrimaryDelayAuto());
	
	return true;
end

function ITEM:OnSecondaryAttack()
	if !self:CanSecondaryAttack() || (self:IsHeld() && self:GetWOwner():KeyDownLast(IN_ATTACK2) && !self:CanSecondaryAttackAuto()) then return false; end
	self:SetNextSecondary(CurTime()+self:GetSecondaryDelay(),CurTime()+self:GetSecondaryDelayAuto());
	
	return true;
end





--[[
Stop the weapon's primary from attacking until [fNext], which is usually CurTime() + some delay.
If this function is run serverside, it will also sync the next primary attack clientside.

fNext is the next time the weapon's primary can attack, period.
fNextAuto is optional (defaults to fNext). This is the next time the weapon's primary can auto-attack.
bNet is an optional true/false (that defaults to true).
	If we're running this function on the server and this is false, we'll only set the next attack time on the server.
]]--
function ITEM:SetNextPrimary(fNext,fNextAuto,bNet)
	if bNet!=false then bNet=nil; end
	self:SetNWFloat("PrimaryNext",fNext,bNet);
	
	if fNextAuto==nil || fNext==fNextAuto then	self:SetNWFloat("PrimaryNextAuto",nil,bNet);
	else										self:SetNWFloat("PrimaryNextAuto",fNextAuto,bNet);
	end
end

--[[
Can we attack with primary, or is the weapon cooling down right now?
]]--
function ITEM:CanPrimaryAttack()
	return (CurTime()>=self:GetNWFloat("PrimaryNext"));
end

--[[
Can we auto-attack with primary yet?
Returns false if we can't auto-attack with primary yet.
]]--
function ITEM:CanPrimaryAttackAuto()
	return (CurTime()>=self:GetNWFloat("PrimaryNextAuto"));
end

--[[
Returns the primary delay.
]]--
function ITEM:GetPrimaryDelay()
	return self.PrimaryDelay;
end

--[[
Returns the auto-primary delay.
]]--
function ITEM:GetPrimaryDelayAuto()
	return ((self.PrimaryDelayAuto!=-1 && self.PrimaryDelayAuto) || self:GetPrimaryDelay());
end







--[[
Stop the weapon's secondary from attacking until [fNext], which is usually CurTime() + some delay.
If this function is run serverside, it will also sync the next secondary attack clientside.

fNext is the next time the weapon's secondary can attack, period.
fNextAuto is optional (defaults to fNext). This is the next time the weapon's secondary can auto-attack.
bNet is an optional true/false (that defaults to true).
	If we're running this function on the server and this is false, we'll only set the next attack time on the server.
]]--
function ITEM:SetNextSecondary(fNext,fNextAuto,bNet)
	if bNet!=false then bNet=nil; end
	self:SetNWFloat("SecondaryNext",fNext,bNet);
	
	if fNextAuto==nil || fNext==fNextAuto then		self:SetNWFloat("SecondaryNextAuto",nil,bNet);
	else											self:SetNWFloat("SecondaryNextAuto",fNextAuto,bNet);
	end
end

--[[
Can we attack with secondary, or is the weapon cooling down right now?
]]--
function ITEM:CanSecondaryAttack()
	return (CurTime()>=self:GetNWInt("SecondaryNext"));
end

--[[
Can we auto-attack with secondary yet?
Returns false if we can't auto-attack with secondary yet.
]]--
function ITEM:CanSecondaryAttackAuto()
	return (CurTime()>=self:GetNWInt("SecondaryNextAuto"));
end

--[[
Returns the secondary delay.
]]--
function ITEM:GetSecondaryDelay()
	return self.SecondaryDelay;
end

--[[
Returns the auto-secondary delay.
]]--
function ITEM:GetSecondaryDelayAuto()
	return ((self.SecondaryDelayAuto!=-1 && self.SecondaryDelayAuto) || self:GetSecondaryDelay());
end

--[[
Stops the primary and secondary from attacking until [fNext].
Use this function if you are need to stop all attacks until the given time instead of SetNextPrimary/SetNextSecondary;
This function uses network macros, so it is less laggy than setting the cooldown of primary and secondary seperately.
]]--
function ITEM:SetNextBoth(fNext,fNextAuto)
	self:SetNextPrimary(fNext,fNextAuto,false);
	self:SetNextSecondary(fNext,fNextAuto,false);
	
	if CLIENT then return true end
	
	if fNextAuto==nil || fNextAuto==fNext then		self:SendNWCommand("SetNextBothCheap",nil,fNext);
	else											self:SendNWCommand("SetNextBoth",nil,fNext,fNextAuto);
	end
	
	return true;
end


if SERVER then


IF.Items:CreateNWCommand(ITEM,"SetNextBothCheap",nil,{"float"});
IF.Items:CreateNWCommand(ITEM,"SetNextBoth",nil,{"float","float"});


else


IF.Items:CreateNWCommand(ITEM,"SetNextBothCheap", function(self,...) self:SetNextBoth(...) end,{"float"});
IF.Items:CreateNWCommand(ITEM,"SetNextBoth", function(self,...) self:SetNextBoth(...) end,{"float","float"});


end

IF.Items:CreateNWVar(ITEM,"PrimaryNext","float",0);
IF.Items:CreateNWVar(ITEM,"PrimaryNextAuto","float",	function(self) return self:GetNWFloat("PrimaryNext") end);
IF.Items:CreateNWVar(ITEM,"SecondaryNext","float",0);
IF.Items:CreateNWVar(ITEM,"SecondaryNextAuto","float",	function(self) return self:GetNWFloat("SecondaryNext") end);

