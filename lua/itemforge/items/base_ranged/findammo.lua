--[[
base_ranged
SHARED

This specific file contains functions used to locate ammo for weapons.
Whenever a gun needs to be reloaded, it needs to be loaded with an ammo item. But where does this ammo item come from? Nearby the weapon? From the holding player's inventory? Where?
Functions in the "Itemforge_BaseRanged_FindAmmo" list are called to solve this problem.
You could make a function to search the holding player's inventory for a type of ammo, for example.
Or maybe you could make a function that converts HL2 ammo the player is holding into an ammo item, then return the item. Sky's the limit!

FindAmmo functions have two arguments:
	self is the weapon that is trying to find ammo.
	fCallback is the function given to :FindAmmo(). It's arguments are fCallback(self,foundAmmo).
A FindAmmo function should return false if ammo couldn't be found with that function for some reason, or true if true if fCallback returns true. 
See the example FindAmmo function below for more information:
]]--

--[[
I made an example FindAmmo function for you.
This searches a holding player's inventory for ammo (lets pretend that pOwner.Inventory is his inventory).
Copy/paste this to make your own ammo-finding functions; this should go in a serverside script that autoruns


list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local pOwner=self:GetWOwner();
	if !pOwner then return false end		--We can't find any ammo if the weapon isn't being held!
	
	--Lets look at all the items in the player's inventory... (v is an item in his inventory)
	for k,v in pairs(pOwner.Inventory:GetItems()) do
		
		--Is this item what you were looking for?
		if fCallback(self,v) then
		
			--SWEET! It was! We're done here!
			return true;
		end
	end
	
	--Crap!! None of the items in the player's inventory worked! Lets see if we can't find ammo some other way...
	return false;
end)




]]--

--[[
Uses the functions in the Itemforge_BaseRanged_FindAmmo list to find ammo for the weapon.
fCallback should be a function(self,ammo).
	self will be this item.
	ammo will be the ammo we found for this item
		NOTE: ammo can be any kind of item! Make sure fCallback checks that the ammo is usable.
	fCallback should return false if you want to keep searching for ammo, or true to stop searching.
This returns true if usable ammo was located (fCallback returned true)
This returns false if usable ammo wasn't located (fCallback never returned true)
]]--
function ITEM:FindAmmo(fCallback)
	local l=list.Get("Itemforge_BaseRanged_FindAmmo");
	for k,v in pairs(l) do
		if v(self,fCallback) then return true end
	end
	return false;
end






--[[
If the weapon is in an inventory, this function returns any ammo in the same inventory as it
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local inv=self:GetContainer();
	if !inv then return false end
	
	for k,v in pairs(inv:GetItems()) do
		if fCallback(self,v) then return true end
	end
	
	return false;
end);

--[[
If the player is looking directly at some ammo, we'll try to load that first before searching the nearby ammo.
If the player is holding ammo (in his weapon menu), we'll try to load that.
If both of those fail, we'll try searching the area around the player instead.
TODO: THIS IS CRAP, REDO IT
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local pOwner=self:GetWOwner();
	if !pOwner then return false end
	
	--Is the player looking directly at an item?
	local i=IF.Items:GetEntItem(v);
	local tr={};
	tr.start=pOwner:GetShootPos();
	tr.endpos=tr.start+(pOwner:EyeAngles():Forward()*64);
	tr.filter=pOwner;
	local traceRes=util.TraceLine(tr);
	local i=IF.Items:GetEntItem(traceRes.Entity);
	if i && fCallback(self,i) then return true end
	
	if SERVER then
		for i=1,IF.Items.MaxHeldItems do
			local heldWeapon=pOwner:GetWeapon("itemforge_item_held_"..i);
			if heldWeapon && heldWeapon:IsValid() then
				local item=heldWeapon:GetItem();
				if item && fCallback(self,item) then return true end
			end
		end
	else
		for k,v in pairs(pOwner:GetWeapons()) do
			if string.find(v:GetClass(),"itemforge_item_held_[1-"..IF.Items.MaxHeldItems.."]") then
				local item=v:GetItem();
				if item && fCallback(self,item) then return true end
			end
		end
	end
	
	--TODO use IF.Items:GetWorldItems() instead of this
	for k,v in pairs(ents.FindByClass("itemforge_item")) do
		local i=IF.Items:GetEntItem(v);
		if i then
			local tr={};
			tr.start=pOwner:GetShootPos();
			tr.endpos=tr.start+((v:LocalToWorld(v:OBBCenter())-tr.start):GetNormal()*64);
			tr.filter=pOwner;
			local traceRes=util.TraceLine(tr);
			if traceRes.Entity==v && fCallback(self,i) then return true end
		end
	end
	
	return false;
end);

--[[
This function searches the area around the weapon for nearby ammo.
TODO: THIS IS CRAP, REDO IT
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local eEnt=self:GetEntity();
	if !eEnt then return false end
	
	--TODO use IF.Items:GetWorldItems() instead of this
	for k,v in pairs(ents.FindByClass("itemforge_item")) do
		local i=IF.Items:GetEntItem(v);
		if i then
			local tr={};
			tr.start=eEnt:LocalToWorld(eEnt:OBBCenter());
			tr.endpos=tr.start+((v:LocalToWorld(v:OBBCenter())-tr.start):GetNormal()*64);
			tr.filter=eEnt;
			local traceRes=util.TraceLine(tr);
			if traceRes.Entity==v && fCallback(self,i) then return true end
		end
	end
	
	return false;
end);