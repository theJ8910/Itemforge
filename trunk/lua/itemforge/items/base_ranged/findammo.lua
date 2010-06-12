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
A FindAmmo function should return nil if ammo couldn't be found with that function for some reason, or the found item if true if fCallback returns true. 
See the example FindAmmo function below for more information:
]]--

--[[
I made an example FindAmmo function for you.
This searches a holding player's inventory for ammo (lets pretend that pOwner.Inventory is his inventory).
Copy/paste this to make your own ammo-finding functions; this should go in a shared script that autoruns


list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local pOwner=self:GetWOwner();
	if !pOwner then return false end		--We can't find any ammo this way if the weapon isn't being held!
	
	--Lets look at all the items in the player's inventory... (v is an item in his inventory)
	for k,v in pairs(pOwner.Inventory:GetItems()) do
		
		--Is this item what you were looking for?
		if fCallback(self,v) then
		
			--SWEET! It was! Let's return the item that was approved!
			return v;
		end
	end
	
	--Crap!! None of the items in the player's inventory worked! Lets see if we can't find ammo some other way...
	return nil;
end)




]]--

--[[
Uses the functions in the Itemforge_BaseRanged_FindAmmo list to find ammo for the weapon.
fCallback should be a function(self,foundAmmo).
	self will be the item you're finding ammo for.
	ammo will be the item the ammo-finding functions found
		NOTE: ammo can be any kind of item! Make sure fCallback checks that the ammo is usable.
	fCallback should return false if you want to keep searching for ammo, or true to stop searching.
This returns the approved item (fCallback returned true) if usable ammo was located 
This returns nil (fCallback never returned true) if usable ammo wasn't located 
]]--
function ITEM:FindAmmo(fCallback)
	local l=list.Get("Itemforge_BaseRanged_FindAmmo");
	for k,v in pairs(l) do
		local s,r=pcall(v,self,fCallback);
		if !s then self:Error("While finding ammo, A function in the \"Itemforge_BaseRanged_FindAmmo\" list encountered a problem: "..r);
		elseif r then return r end
	end
	return nil;
end






--[[
If the weapon is in an inventory, this function returns any ammo in the same inventory as it
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local inv=self:GetContainer();
	if !inv then return false end
	
	for k,v in pairs(inv:GetItems()) do
		if fCallback(self,v) then return v end
	end
	
	return nil;
end);

--[[
This function deals with finding ammo for an item held (as a weapon) by a player.

First, if the player is looking directly at some ammo, we'll give that to the callback first before searching the nearby ammo.
If the player is holding ammo (in his weapon menu), we'll try to load that.
If both of those fail, we'll try searching the area around the player instead.
TODO: THIS IS CRAP, REDO IT
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local pOwner=self:GetWOwner();
	if !pOwner then return nil end
	
	--Is the player looking directly at an item?
	local i=IF.Items:GetEntItem(v);
	local tr={};
	tr.start=pOwner:GetShootPos();
	tr.endpos=tr.start+(pOwner:EyeAngles():Forward()*64);
	tr.filter=pOwner;
	local traceRes=util.TraceLine(tr);
	local i=IF.Items:GetEntItem(traceRes.Entity);
	if i && fCallback(self,i) then return i end
	
	if SERVER then
		for k,v in pairs(pOwner:GetWeapons()) do
			local item=IF.Items:GetWeaponItem(v);
			if item && fCallback(self,item) then
				return item
			end
		end
	end
	
	--TODO use IF.Items:GetWorldItems() instead of this
	for k,v in pairs(ents.FindByClass(IF.Items.BaseEntityClassName)) do
		local i=IF.Items:GetEntItem(v);
		if i then
			local tr={};
			tr.start=pOwner:GetShootPos();
			tr.endpos=tr.start+((v:LocalToWorld(v:OBBCenter())-tr.start):GetNormal()*64);
			tr.filter=pOwner;
			local traceRes=util.TraceLine(tr);
			if traceRes.Entity==v && fCallback(self,i) then return i end
		end
	end
	
	return nil;
end);

--[[
This function searches the area around the weapon for nearby ammo.
TODO: THIS IS CRAP, REDO IT
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local eEnt=self:GetEntity();
	if !eEnt then return false end
	
	--TODO use IF.Items:GetWorldItems() instead of this
	for k,v in pairs(ents.FindByClass(IF.Items.BaseEntityClassName)) do
		local i=IF.Items:GetEntItem(v);
		if i then
			local tr={};
			tr.start=eEnt:LocalToWorld(eEnt:OBBCenter());
			tr.endpos=tr.start+((v:LocalToWorld(v:OBBCenter())-tr.start):GetNormal()*64);
			tr.filter=eEnt;
			local traceRes=util.TraceLine(tr);
			if traceRes.Entity==v && fCallback(self,i) then return i end
		end
	end
	
	return nil;
end);