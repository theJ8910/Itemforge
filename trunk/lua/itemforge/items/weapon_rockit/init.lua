--[[
weapon_rockit
SERVER

A gun that fires random crap from it's inventory.
]]--

AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");

include("shared.lua");

ITEM.AutoUnloading=false;
ITEM.AutoUnloadDelay=0.3;
ITEM.LoopingSound=nil;

--[[
Create an inventory for our gun
]]--
function ITEM:OnInit()
	--Do everything the base ranged does on init too
	self["base_ranged"].OnInit(self);
	
	--Create an inventory or stop here if we couldn't
	local inv=IF.Inv:Create();
	if !inv || !inv:IsValid() then return false end
	
	--Mark that we want to remove any items in the inventory when this inventory gets removed
	inv.RemovalAction=IFINV_RMVACT_REMOVEITEMS;
	
	--Connect the inventory to this item	 
	inv:ConnectItem(self);
	
	self.Inventory=inv;
end

--[[
We have an auto-unload feature.
]]--
function ITEM:OnThink()
	self["base_ranged"].OnThink(self);
	if self.AutoUnloading then self:UnloadLoop() end
end

--[[
Overridden from base_ranged.
When this function is called we load items into the gun's inventory instead of the clip.
]]--
function ITEM:Load(clip,item,amt)
	if !self:CanReload() then return false end
	
	--Even though we don't use clips, the rock-it launcher does hvae a clip that says what items we can load. This is what it's good for.
	if !self:CanLoadClipWith(1,item) then return false end
	
	--Can't load items into a non-existent inventory
	local inv=self:GetInventory();
	if !inv then return false end
	
	--If we don't insert the item successfully we fail.
	if item:ToInv(inv) then return false end
	
	self:ReloadEffects();
	self:SetNextBoth(CurTime()+self:GetReloadDelay());
	self:UpdateWireAmmoCount();
	
	return true;
end



--[[
Overridden from base_ranged.
When this function is called, instead of instantly unloading the item in a clip, we turn on auto-unloading.
]]--
function ITEM:Unload(clip)
	self.AutoUnloading=true;
	
	if self:InWorld() && !self.LoopingSound then
		self.LoopingSound=CreateSound(self:GetEntity(),self.UnloadSound);
		self.LoopingSound:Play();
	end
	
	return true;
end

--[[
This function is called every frame that we are auto-unloading.
It will unload one item and cool the weapon down for a short time.
It can't unload while the weapon is cooling down.
When all items are unloaded, this function will turn off auto-unloading.
]]--
function ITEM:UnloadLoop()
	if !self:CanPrimaryAttack() || !self:CanSecondaryAttack() then return false end
	
	--Can't unload items from a non-existant inventory
	local inv=self:GetInventory();
	if !inv then
		self.AutoUnloading=false;
		return false;
	end
	
	--Unload an item from the inventory, or stop if the inventory is empty
	local item=inv:GetLast();
	if !item then
		self.AutoUnloading=false;
		if self.LoopingSound then
			self.LoopingSound:Stop();
			self.LoopingSound=nil;
		end
	else
		item:ToSameLocationAs(self,true);
		self:SetNextBoth(CurTime()+self.AutoUnloadDelay);
	end
	
	return true;
end

function ITEM:OnWorldExit(ent,forced)
	if self.LoopingSound then
		self.LoopingSound:Stop();
		self.LoopingSound=nil;
	end
	return true;
end

--[[
Overridden from base_ranged.
We don't use clips, which means we don't subtract ammo from them.
This function does nothing.
]]--
function ITEM:TakeAmmo(clip,amt)
end

--[[
Overridden from base_ranged. We don't use clips so don't remove ammo from them.
When the rock-it launcher is removed, items in it's inventory will be removed automatically.
]]--
function ITEM:OnRemove()
end

--[[
Overridden from base_ranged. Instead of having "Clip 1", "Clip 2", etc, we only have the "Items" output.
Tells Wiremod that our gun can report how much ammo we have.
]]--
function ITEM:GetWireOutputs(entity)
	return Wire_CreateOutputs(entity,{"Items"});
end

--[[
Overridden from base_ranged. Instead of grabbing the amount of ammo from the clip we grab the number of items from the inventory.
Triggers the ammo-in-clip wire outputs; updates them with the correct ammo counts
]]--
function ITEM:UpdateWireAmmoCount()
	local inv=self:GetInventory();
	
	if inv then		self:WireOutput("Items",inv:GetCount());
	else			self:WireOutput("Items",0);
	end
end