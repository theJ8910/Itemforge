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
]]--
function ITEM:SetNextPrimary(fNext,fNextAuto)
	self:SetNWFloat("PrimaryNext",fNext);
	self:SetNWFloat("LastPrimaryDelay",fNext-CurTime());
	
	if fNextAuto==nil || fNext==fNextAuto then	self:SetNWFloat("PrimaryNextAuto",nil);
	else										self:SetNWFloat("PrimaryNextAuto",fNextAuto);
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
]]--
function ITEM:SetNextSecondary(fNext,fNextAuto)
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
Also stops the primary and secondary from auto attacking until [fNextAuto] or, if not given, [fNext]. 
]]--
function ITEM:SetNextBoth(fNext,fNextAuto)
	self:SetNextPrimary(fNext,fNextAuto);
	self:SetNextSecondary(fNext,fNextAuto);
end

function ITEM:OnDraw2D(width,height)
	self["item"].OnDraw2D(self,width,height);
	
	local remaining=self:GetNWFloat("PrimaryNext")-CurTime();
	local delay=self:GetNWFloat("LastPrimaryDelay");
	if remaining<=0 || delay==0 then return end	
	
	surface.SetDrawColor(255,0,0,(remaining/delay)*255);
	--Vertical lines
	surface.DrawRect(2,2,		1,height-4);
	surface.DrawRect(width-3,2,	1,height-4);
	
	--Horizontal lines
	surface.DrawRect(3,2		,width-6,1);
	surface.DrawRect(3,height-3	,width-6,1);
end

IF.Items:CreateNWVar(ITEM,"PrimaryNext","float",0,true,true);
IF.Items:CreateNWVar(ITEM,"PrimaryNextAuto","float",	function(self) return self:GetNWFloat("PrimaryNext") end,true,true);
IF.Items:CreateNWVar(ITEM,"SecondaryNext","float",0,true,true);
IF.Items:CreateNWVar(ITEM,"SecondaryNextAuto","float",	function(self) return self:GetNWFloat("SecondaryNext") end,true,true);

IF.Items:CreateNWVar(ITEM,"LastPrimaryDelay","float",0,true,true);