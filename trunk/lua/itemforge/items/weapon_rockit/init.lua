--[[
weapon_rockit
SERVER

A gun that fires random crap from it's inventory.
]]--

AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("inv_rockit.lua")

include("shared.lua");

ITEM.GibEffect = "metal";

--Rock-It Launcher
ITEM.AutoUnloadDelay=0.3;
ITEM.EjectFrom=Vector(9.2274,0.3052,5.4279);
ITEM.Spindown=nil;

--[[
* SERVER
* Event

Create an inventory for our gun
]]--
function ITEM:OnInit()
	--Do everything the base ranged does on init too
	self:BaseEvent("OnInit");
	
	--Create an inventory or stop here if we couldn't
	local inv=IF.Inv:Create("inv_rockit");
	if !inv || !inv:IsValid() then return false end
	
	--Connect the inventory to this item	 
	inv:ConnectItem(self);
	
	self.Inventory=inv;
end

--[[
* SERVER
* Event

We have an auto-unload feature.
]]--
function ITEM:OnThink()
	self:BaseEvent("OnThink");
	
	if self:GetNWBool("Unloading") then self:UnloadLoop() end
	
	--[[
	local pl=self:GetWOwner();
	if pl && pl:GetActiveWeapon()==self:GetWeapon() && pl:KeyDown(IN_RELOAD) then
		self:Suction(pl:EyePos(),pl:EyeAngles():Forward());
	end
	]]--
end

--[[
* SERVER

Overridden from base_ranged.
When this function is called, instead of instantly unloading an item, we turn on auto-unloading.
]]--
function ITEM:Unload(clip)
	if self:GetNWBool("Unloading")==true then return false end
	
	self:SetNWBool("Unloading",true);
	self:LoopingSound(self.UnloadSound,"UnloadSound");
	
	return true;
end

--[[
* SERVER

This function is called every frame that we are auto-unloading.
It will unload one item and cool the weapon down for a short time.
It can't unload while the weapon is cooling down.
When all items are unloaded, this function will turn off auto-unloading.

TODO this is broke... try reloading while unloading and hilarity ensues.
]]--
function ITEM:UnloadLoop()
	if !self:CanPrimaryAttack() || !self:CanSecondaryAttack() then return false end
	
	--Unload an item from the inventory, or stop if the inventory is empty (or doesn't exist)
	local inv=self:GetInventory();
	if !inv || inv:IsEmpty() then
		if self.Spindown==nil then
			self.Spindown=CurTime()+5;
		elseif CurTime()<self.Spindown then
			self:SetLoopingSoundPitch("UnloadSound",(70+6*(self.Spindown-CurTime() )));
		else
			self.Spindown=nil;
			self:SetNWBool("Unloading",false);
			self:StopLoopingSound("UnloadSound");
		end
		return false;
	elseif inv then
		if self.Spindown==nil then
			self.Spindown=CurTime()+2;
		elseif CurTime()<self.Spindown then
			self:SetLoopingSoundPitch("UnloadSound",(100-15*(self.Spindown-CurTime() )));
		else
			inv:GetLast():ToSameLocationAs(self,true);
			self:EmitSound(self.ReloadSounds,true);
			self:SetNextBoth(CurTime()+self.AutoUnloadDelay);
			if inv:IsEmpty() then self.Spindown=nil; end
		end
	end
	
	return true;
end

--[[
* SERVER
* Event

Overridden from base_ranged. We don't use clips so don't remove ammo from them.
When the rock-it launcher is removed, items in it's inventory will be removed automatically.
]]--
function ITEM:OnRemove()
end

--[[
* SERVER
* Event

Overridden from base_ranged. Instead of having "Clip 1", "Clip 2", etc, we only have the "Items" output.
Tells Wiremod that our gun can report how much ammo we have.
]]--
function ITEM:GetWireOutputs(entity)
	return Wire_CreateOutputs(entity,{"Items"});
end

--[[
* SERVER

Overridden from base_ranged. Instead of grabbing the amount of ammo from the clip we grab the number of items from the inventory.
Triggers the ammo-in-clip wire outputs; updates them with the correct ammo counts
]]--
function ITEM:UpdateWireAmmoCount()
	local inv=self:GetInventory();
	
	if inv then		self:WireOutput("Items",inv:GetCount());
	else			self:WireOutput("Items",0);
	end
end