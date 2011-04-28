--[[
base_thrown
SHARED

base_thrown is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_thrown has two purposes:
	You can tell if an item is a thrown weapon by checking to see if it inherits from base_thrown.
	It's designed to help you create weapons easier. You just have to change/override some variables or replace some stuff with your own code.
]]--
if SERVER then AddCSLuaFile("shared.lua") end

local zero_vector=Vector(0,0,0);
local zero_angle=Angle(0,0,0);
local default_speed=1000;

ITEM.Name="Base Thrown Weapon";
ITEM.Description="This item is the base thrown weapon.\nThrown weapons inherit from this.\n\nThis is not supposed to be spawned.";
ITEM.Base="base_weapon";
ITEM.WorldModel="models/props_junk/Rock001a.mdl";
ITEM.ViewModel="models/weapons/v_hands.mdl";
ITEM.MaxAmount=0;								--Thrown weapons are usually stacks of items

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;


ITEM.HoldType="grenade";




--Base Thrown
ITEM.ThrowSounds={};

--How fast is the given object going to be thrown? The speed will be a random number between the given numbers.
ITEM.ThrowSpeedMin=1300;
ITEM.ThrowSpeedMax=1400;

--When the item is thrown, what will it's initial angle be? For instance, you don't throw a frisbee rotated vertically do you?
--Pitch/yaw/roll angle will be random numbers between the given numbers.
ITEM.ThrowAngleMin=Angle(0,0,0);
ITEM.ThrowAngleMax=Angle(360,360,360);

--How much do thrown items deviate from their path?
ITEM.ThrowSpread=Vector(0,0,0);

--How much does the thrown object spin? These angles represent the rotation speed (in degrees/sec?) of pitch, yaw, roll respectively.
--Pitch/yaw/roll rotation will be random numbers between the given numbers.
ITEM.ThrowSpinMin=Angle(-50,-50,-50);
ITEM.ThrowSpinMax=Angle(50,50,50)

--This is how long it takes to actually throw the weapon after an attack is issued
ITEM.ThrowDelay=0;

--After a player throws an item, kills from this item are credited towards this player for this many seconds
ITEM.KillCreditTime = 5;

if SERVER then
	ITEM.KillCredit=nil;
end

--[[
* SHARED
* Event

Throws the item.
]]--
function ITEM:OnSWEPPrimaryAttack()
	if !self:BaseEvent("OnSWEPPrimaryAttack",false) then return false end
	self:BeginThrow(self:GetWOwner());
	
	return true;
end

--[[
* SHARED

Begins a throw (throw effects, throw timer if there is a delay).
Any arguments that should be passed to Throw should be given to this function.
]]--
function ITEM:BeginThrow(...)
	self:ThrowEffects();
	if self.ThrowDelay then
		self:CreateTimer("ThrowTimer",self.ThrowDelay,1,self.Throw,...);
	else
		self:Throw(...);
	end
end

--[[
* SHARED
* Event

Immediately after an item is thrown, this event is called on the thrown item.

To clarify, if you called Throw() on a stack of items, it splits off 1 item,
and then this event runs on the 1 item that was split off - NOT the stack it was originally from.

pl should be the player who threw the item.
]]--
function ITEM:OnThrow(pl)
	
end

--[[
* SHARED
* Event

This event is called by Throw() to determine how fast to throw the item.
]]--
function ITEM:GetThrowSpeed()
	return math.Rand(self.ThrowSpeedMin,self.ThrowSpeedMax);
end

--[[
* SHARED
* Event

This event is called by Throw() to determine the initial angle the thrown item is at.
]]--
function ITEM:GetThrowAngle()
	return Angle(math.Rand(self.ThrowAngleMin.p,self.ThrowAngleMax.p),math.Rand(self.ThrowAngleMin.y,self.ThrowAngleMax.y),math.Rand(self.ThrowAngleMin.r,self.ThrowAngleMax.r));
end

--[[
* SHARED
* Event

This event is called by Throw() to determine the deviation of the thrown item's path.
]]--
function ITEM:GetThrowSpread()
	return self.ThrowSpread;
end

--[[
* SHARED
* Event

This event is called by Throw() to determine how fast the thrown item's pitch/yaw/roll spins.
]]--
function ITEM:GetThrowSpin()
	return Angle(math.Rand(self.ThrowSpinMin.p,self.ThrowSpinMax.p),math.Rand(self.ThrowSpinMin.y,self.ThrowSpinMax.y),math.Rand(self.ThrowSpinMin.r,self.ThrowSpinMax.r));
end

--[[
* SHARED

Throws an item from this stack.

iCount items are split off from this stack, sent to the world nearby the player, and then thrown.
If there are not that many items in the stack, the rest of the stack is thrown instead.

pl should be the player who threw the item.
iCount is the optional number of items to use in the thrown stack.
	If this is nil/not given it defaults to 1.
fSpeed is an optional speed to throw the items at.
	If this is nil/not given it defaults to whatever item:GetThrowSpeed() returns.
aThrowAng is an optional angle the thrown item is at when first thrown.
	If this is nil/not given it defaults to whatever item:GetThrowAngle() returns.
vSpread is an optional vector that describes how much the thrown item should deviate from it's thrown path.
	If this is nil/not given it defaults to whatever item:GetThrowSpread() returns.
aSpin is an optional angle that describes the spin of the thrown object (pitch, yaw, roll).
	If this is nil/not given it defaults to whatever item:GetThrowSpin() returns.
vOffset is an optional vector that describes how much to offset the initial position of the object relative to the player's shoot position.
	If this is nil/not given it defaults to Vector(20,0,0).
	
Serverside, the item is actually thrown. The item that was thrown is returned.
Clientside it just predicts whether or not the item can be thrown. A temporary item is returned if the item can be thrown.
nil is returned otherwise.
]]--
function ITEM:Throw(pl,iCount,fSpeed,aThrowAng,vSpread,aSpin,vOffset)
	if !pl || !pl:IsValid() then return nil end
	
	local wep=self:GetWeapon();
	if (wep && pl:GetActiveWeapon()!=wep) || !self:Event("CanPlayerInteract",false,pl) then return nil end
	
	if iCount==nil then iCount=1 end
	
	local itemToThrow;
	if self:GetAmount()>iCount then
		itemToThrow=self:Split(iCount,false);
		if !itemToThrow || !itemToThrow:IsValid() then return nil end
	else
		itemToThrow=self;
	end
	
	local eyeAng=pl:EyeAngles();
	local eyeNorm=eyeAng:Forward();
	
	if aThrowAng==nil then aThrowAng=self:Event("GetThrowAngle",zero_angle); end
	
	eyeAng:RotateAroundAxis(eyeAng:Right(),-aThrowAng.p);
	eyeAng:RotateAroundAxis(eyeAng:Up(),aThrowAng.y);
	eyeAng:RotateAroundAxis(eyeAng:Forward(),aThrowAng.r);
	
	--TODO offset
	local ent=itemToThrow:ToWorld(pl:EyePos()+(eyeNorm*20),eyeAng);
	if !ent then return nil end
	
	if SERVER then
		if !ent:IsValid() then return nil end
		local phys=ent:GetPhysicsObject();
		if !phys || !phys:IsValid() then return nil end
		
		--TODO deviation of path
		--local path=self:Event("GetThrowSpread",zero_vector);
		if fSpeed==nil then fSpeed=self:Event("GetThrowSpeed",default_speed); end
		
		phys:SetVelocity((eyeNorm*fSpeed)+pl:GetVelocity());
		
		if aSpin==nil then aSpin=self:Event("GetThrowSpin",zero_angle) end
		phys:AddAngleVelocity(aSpin);
		
		self:SetKillCredit(pl,self.KillCreditTime);
	end
	
	itemToThrow:Event("OnThrow",nil,pl);
	return itemToThrow;
end

--[[
* SHARED

Plays a random sound when the item is thrown.
Also plays the attack animation, both on the weapon and player himself
]]--
function ITEM:ThrowEffects()
	if #self.ThrowSounds>0 then self:EmitSound(self.ThrowSounds,true); end
	
	local pl=self:GetWOwner();
	if pl then
						pl:SetAnimation(PLAYER_ATTACK1);
		  self:GetWeapon():SendWeaponAnim(self:Event("GetThrowActivity"));
	end
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when the item is thrown
]]--
function ITEM:GetThrowActivity()
	return ACT_VM_THROW;
end

if SERVER then




--[[
* SERVER

This function credits kills the item is responsible for to the given player for
"time" seconds.

If the player is nil, the kill credits are cleared.
]]--
function ITEM:SetKillCredit(pl,time)
	self.KillCredit=pl;
	if pl==nil then return end
	self:CreateTimer("BaseThrownRemoveKillCredit",time,1,self.SetKillCredit,nil);
end

--[[
* SERVER

Returns the player who should be credited with kills this item is responsible for.
This can be a player or nil.
]]--
function ITEM:GetKillCredit()
	return self.KillCredit;
end




end