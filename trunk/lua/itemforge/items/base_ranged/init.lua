--[[
base_ranged
SERVER

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ranged has two purposes:
	It's designed to help you create ranged weapons easier. You just have to change/override some variables or replace some stuff with your own code.
	You can tell if an item is a ranged weapon (like a pistol or RPG) by checking to see if it inherits from base_ranged.
Some features the base_ranged has:
	Ammunition: 
		You can load base_ranged weapons with other items
		The primary/secondary attack consumes ammo from a clip you set (you can also set primary/secondary not to consume ammo)
		You can specify how many clips you want your weapon to have (including none).
		You can specify what type of ammo goes in a clip and how much can be loaded into it at a given time (including no limit)
		If ammo is drag-dropped onto the item, it loads it with that ammo; if two or more clips use the same kind of ammo, then it will load whichever clip is empty first.
		A list of reload functions let you set up where the item looks for ammo when it reloads.
	Cooldowns:
		This is based off of base_weapon so you can set primary/secondary delay and auto delay
		You can set a reload delay
		You can set "out of ammo" delays for primary/secondary (for example, the SMG's primary has a 0.08 second cooldown, but if you're out of ammo, it has a 0.5 second cooldown instead)
	Other:
		The item's right click menu has several functions for dealing with ranged weapons; you can fire it's primary/secondary, unload clips, reload, etc, all from the menu.
		Wiremod can fire the gun's primary/secondary attack. It can also reload the gun, if there is ammo nearby.
]]--
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("findammo.lua");

include("shared.lua");

ITEM.PrimaryFiring=false;
ITEM.SecondaryFiring=false;

--[[
Consumes the given amount of ammo from the given clip.
One reason this could fail is if we're trying to take too much ammo.
	For example, what if we have one shotgun shell and try to take two?
Returns true if ammo was consumed, false otherwise
]]--
function ITEM:TakeAmmo(amt,clip)
	local ammo=self:GetAmmo(clip);
	if !ammo then return false end
	
	local currentAmt=ammo:GetAmount();
	if currentAmt<amt then return false end
	
	local s=ammo:SubAmount(amt);
	self:UpdateWireAmmoCount();
	return s;
end

--Unloads the ammo in the given clip. Sends the ammo to the same location as the weapon.
function ITEM:Unload(clip)
	local ammo=self:GetAmmo(clip);
	if !ammo then return false end
	
	if !ammo:ToSameLocationAs(self) then return false end
	
	--TODO this needs to be the old max
	ammo:SetMaxAmount(0);
	
	self.Clip[clip]=nil;
	self:SendNWCommand("Unload",nil,clip);
	
	return true;
end

--[[
This function runs serverside after a player chooses "reload" from the menu.
]]--
function ITEM:PlayerReload(pl)
	if !self:CanPlayerInteract(pl) then return false end
	return self:OnReload();
end

--[[
This function runs serverside after a player drag-drops some ammo to this gun clientside.
Returns true if the ammo was loaded somewhere, false otherwise.
]]--
function ITEM:PlayerLoadAmmo(pl,item)
	if !self:CanPlayerInteract(pl) || !item:CanPlayerInteract(pl) then return false end
	return self:Load(item);
end

--[[
This function runs serverside after a player chooses "Unload" from the item's right click menu clientside.
Returns true if the ammo was unloaded, false otherwise.
]]--
function ITEM:PlayerUnloadAmmo(pl,clip)
	if !self:CanPlayerInteract(pl) then return false end
	return self:Unload(clip);
end

--When the gun gets removed, also remove any loaded ammo
function ITEM:OnRemove()
	for i=1,table.getn(self.Clips) do
		local ammo=self:GetAmmo(i);
		if ammo then ammo:Remove(); end
	end
end

--Auto-attack if Wiremod has told us to
function ITEM:OnThink()
	if self.PrimaryFiring==true		&& self:CanPrimaryAttackAuto()			then
		self:OnPrimaryAttack();
	elseif self.SecondaryFiring==true	&& self:CanSecondaryAttackAuto()	then
		self:OnSecondaryAttack();
	elseif self:GetNWBool("InReload")==true									then
		self:Reload();
	end
end

--If the gun was firing on it's own it won't be any more; this only works while the item is in the world
function ITEM:OnWorldExit(ent,forced)
	if !self["item"].OnWorldExit(self,ent,forced) then return false end
	self.PrimaryFiring=false;
	self.SecondaryFiring=false;
	return true;
end

--Tells Wiremod that our gun can do these things
function ITEM:GetWireInputs(entity)
	return Wire_CreateInputs(entity,{"Fire Primary","Fire Secondary","Reload"});
end

--Tells Wiremod that our gun can report how much ammo is in it's clip(s)
function ITEM:GetWireOutputs(entity)
	local t={};
	for i=1,table.getn(self.Clips) do
		table.insert(t,"Clip "..i);
	end
	return Wire_CreateOutputs(entity,t);
end

--This function handles the wiremod requests to fire/reload the gun
--TODO auto reloading
function ITEM:OnWireInput(entity,inputName,value)
	if inputName=="Fire Primary" then
		if value==0 then	self.PrimaryFiring=false;
		else				self.PrimaryFiring=true;
		end
	elseif inputName=="Fire Secondary" then
		if value==0 then	self.SecondaryFiring=false;
		else				self.SecondaryFiring=true;
		end
	elseif inputName=="Reload" && value!=0 then
		self:OnReload();
	end
end

--Triggers the ammo-in-clip wire outputs; updates them with the correct ammo counts
function ITEM:UpdateWireAmmoCount()
	for i=1,table.getn(self.Clips) do
		local ammo=self:GetAmmo(i);
		if ammo then	self:WireOutput("Clip "..i,ammo:GetAmount());
		else			self:WireOutput("Clip "..i,0);
		end
	end
end

IF.Items:CreateNWCommand(ITEM,"SetClip",nil,{"item","int"});
IF.Items:CreateNWCommand(ITEM,"Unload",nil,{"int"});
IF.Items:CreateNWCommand(ITEM,"PlayerFirePrimary",	function(self,...) self:OnPrimaryAttack(...)	end,{});
IF.Items:CreateNWCommand(ITEM,"PlayerFireSecondary",function(self,...) self:OnSecondaryAttack(...)	end,{});
IF.Items:CreateNWCommand(ITEM,"PlayerReload",		function(self,...) self:PlayerReload(...)		end,{});
IF.Items:CreateNWCommand(ITEM,"PlayerLoadAmmo",		function(self,...) self:PlayerLoadAmmo(...)		end,{"item"});
IF.Items:CreateNWCommand(ITEM,"PlayerUnloadAmmo",	function(self,...) self:PlayerUnloadAmmo(...)	end,{"int"});
