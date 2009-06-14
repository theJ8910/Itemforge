--[[
base_ranged
SERVER

This specific file contains functions used to locate ammo for weapons.
Whenever a gun needs to be reloaded, it needs to be loaded with an ammo item. But where does this ammo item come from? Nearby the weapon? From the holding player's inventory? Where?
Functions in the "Itemforge_BaseRanged_FindAmmo" list are called to solve this problem.
You could make a function to search the holding player's inventory for a type of ammo, for example.
Or maybe you could make a function that converts HL2 ammo the player is holding into an ammo item, then return the item. Sky's the limit!

These functions have two arguments:
self is the weapon that is trying to find ammo.
clip is the clip # on this weapon we're trying to find ammo for.
A function in this list should return an item or nil.
]]--

--[[
--Copy/paste this to make your own ammo-finding functions; this should go in a serverside script that autoruns
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,clip)
	return someItem;
end)
]]--

--[[
Uses the functions in the Itemforge_BaseRanged_FindAmmo list to find ammo for the given clip.
clip should be a clip number.
Returns a table of items found for the given clip. This may be empty.
]]--
function ITEM:FindAmmo(clip)
	local items={};
	local l=list.Get("Itemforge_BaseRanged_FindAmmo");
	for k,v in pairs(l) do
		local item=v(self,clip);
		if items then table.insert(items,item) end
	end
	return items;
end

--[[
If the weapon is in an inventory, this function returns any ammo in the same inventory as it
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,clip)
	local inv=self:GetContainer();
	if inv then
		local items=inv:GetItems();
		for k,v in pairs(items) do
			if self:CanLoadClipWith(v,clip) then
				return v;
			end
		end
	end
end);

--[[
This function searches the area around the weapon for nearby ammo.
TODO: THIS IS CRAP, REDO IT
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,clip)
	local ents=ents.FindByClass("itemforge_item");
	
	if !self:IsHeld() then return nil end
	local pOwner=self:GetWOwner();
	
	for k,v in pairs(ents) do
		local i=v:GetItem();
		if i&&i:IsValid()&&self:CanLoadClipWith(i,clip) then
			local tr={};
			tr.start=pOwner:GetShootPos();
			tr.endpos=tr.start+((v:LocalToWorld(v:OBBCenter())-tr.start):GetNormal()*64);
			tr.filter=pOwner;
			local traceRes=util.TraceLine(tr);
			if traceRes.Entity==v then
				return i;
			end
		end
	end
end);

--[[
This function searches the area around the weapon for nearby ammo.
TODO: THIS IS CRAP, REDO IT
]]--
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,clip)
	local ents=ents.FindByClass("itemforge_item");
	
	if !self:InWorld() then return nil end
	local eEnt=self:GetEntity();
	
	for k,v in pairs(ents) do
		local i=v:GetItem();
		if i&&i:IsValid()&&self:CanLoadClipWith(i,clip) then
			local tr={};
			tr.start=eEnt:LocalToWorld(eEnt:OBBCenter());
			tr.endpos=tr.start+((v:LocalToWorld(v:OBBCenter())-tr.start):GetNormal()*64);
			tr.filter=eEnt;
			local traceRes=util.TraceLine(tr);
			if traceRes.Entity==v then
				return i;
			end
		end
	end
end);