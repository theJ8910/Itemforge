--[[
weapon_rockit
CLIENT

A gun that fires random crap from it's inventory.
]]--

include("shared.lua");

ITEM.BlinkMat=Material("sprites/gmdm_pickups/light");
ITEM.BlinkColor=Color(255,0,0,255);
ITEM.BlinkOffset=Vector(3.1624,4.3433,1.5108);

ITEM.DrawAmmoNextMat=Material("sprites/yellowflare")
ITEM.DrawAmmoCount=4;
ITEM.DrawAmmoSize=1/ITEM.DrawAmmoCount;

--[[
* CLIENT
* Event

This overrides base_ranged's OnDragDropHere event.
Since we don't use clips, any item the player can interact with can be drag-dropped here.
]]--
function ITEM:OnDragDropHere(otherItem)
	if !self:Event("CanPlayerInteract",false,LocalPlayer()) || !otherItem:Event("CanPlayerInteract",false,LocalPlayer()) then return false end
	return self:SendNWCommand("PlayerLoadAmmo",otherItem);
end

--[[
* CLIENT
* Event

Overridden from base_ranged;
Like the base_ranged, we have everything the base weapon has.
Unlike the base_ranged:
	We only one mode of fire
	We have an option to open the rock-it's inventory,
	If we have anything loaded it says how many items to unload (or if only one item, the option to unload it)
]]--
function ITEM:OnPopulateMenu(pMenu)
	--We've got everything the base weapon has and more!
	self:InheritedEvent("OnPopulateMenu","base_weapon",nil,pMenu);
	
	--Options to fire gun
	pMenu:AddOption("Fire Primary",		function(panel)	self:SendNWCommand("PlayerFirePrimary")		end);
	
	--Options to unload ammo
	local inv=self:GetInventory();
	if inv then
		local ammoCount=inv:GetCount();
		if ammoCount>0 then
			local ammoStr;
			if ammoCount>1 then ammoStr=ammoCount.." items";
			else
				local firstItem=inv:GetFirst();
				ammoStr=firstItem:GetName();
				if firstItem:IsStack() then ammoStr=ammoStr.." x "..firstItem:GetAmount(); end
			end
			
			pMenu:AddOption("Unload "..ammoStr,function(panel)	self:SendNWCommand("PlayerUnloadAmmo",1)	end);
		end
	end
	
	--Option to load ammo
	pMenu:AddOption("Reload",			function(panel)	self:SendNWCommand("PlayerReload")			end);
	
	--Option to check inventory
	pMenu:AddOption("Check Inventory",	function(panel)	self:ShowInventory() end);
end

--[[
* CLIENT
* Event

If someone uses it clientside, show the inventory to them
]]--
function ITEM:OnUse(pl)
	self:ShowInventory();
	return false;
end

--[[
* CLIENT
* Event

Wait for our inventory to arrive clientside; when it does, record that it's our inventory
]]--
function ITEM:OnConnectInventory(inv,conslot)
	if !self.Inventory then
		self.Inventory=inv;
		return true;
	end
	return false;
end

--[[
* CLIENT
* Event

If for some reason the inventory unlinks from us, we'll forget about it
]]--
function ITEM:OnSeverInventory(inv)
	if self.Inventory==inv then self.Inventory=nil; return true end
	return false;
end

--[[
* CLIENT
* Event

Called when a model associated with this item needs to be drawn
]]--
function ITEM:OnDraw3D(eEntity,bTranslucent)
	self:BaseEvent("OnDraw3D",nil,eEntity,bTranslucent);
	self:DrawUnloadBlink(eEntity);
end

--[[
* CLIENT
* Event

Draws icons of upcoming ammo
]]--
function ITEM:OnDraw2D(width,height)
	local inv=self:GetInventory();
	if !inv then return false end
	
	local items=inv:GetItems();
	local x=(height-4)*self.DrawAmmoSize;
	local c=1;
	for i=1,table.maxn(items) do
		if items[i] then
			if c==1 then
				surface.SetMaterial(self.DrawAmmoNextMat);
				surface.DrawTexturedRect(width-2-x,height-2-x,x,x);
			end
			
			local icon=items[i]:Event("GetIcon");
			if icon then
				local color=items[i]:GetColor();
				surface.SetMaterial(icon);
				surface.SetDrawColor(color.r,color.g,color.b,color.a);
				surface.DrawTexturedRect(width-2-x,height-2-(c*x),x,x);
			end
			
			c=c+1;
			if c>self.DrawAmmoCount then break end
		end
	end
	
	self:BaseEvent("OnDraw2D",nil,width,height);
end

--[[
* CLIENT

Shows the gun's inventory to the local player
]]--
function ITEM:ShowInventory()
	local inv=self:GetInventory();
	if !inv || (self.InventoryPanel && self.InventoryPanel:IsValid()) then return false end	
	self.InventoryPanel=vgui.Create("ItemforgeInventory");
	self.InventoryPanel:SetInventory(inv);
end

--[[
* CLIENT

Draws a blinking sprite while the item is unloading.
The entity varies depending on what is drawing.
]]--
function ITEM:DrawUnloadBlink(ent)
	if self:GetNWBool("Unloading") && math.sin(CurTime()*30)>=0 then
		render.SetMaterial(self.BlinkMat);
		render.DrawSprite(ent:LocalToWorld(self.BlinkOffset),8,8,self.BlinkColor);
	end
end