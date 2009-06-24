--[[
weapon_rockit
CLIENT

A gun that fires random crap from it's inventory.
]]--

include("shared.lua");

ITEM.BlinkMat=Material("sprites/gmdm_pickups/light");
ITEM.BlinkColor=Color(255,0,0,255);
ITEM.BlinkOffset=Vector(3.1624,4.3433,1.5108);

--This overrides base_ranged's OnDragDropHere; since we don't use clips, any item the player can interact with can be drag-dropped here.
function ITEM:OnDragDropHere(otherItem)
	if !self:CanPlayerInteract(LocalPlayer()) || !otherItem:CanPlayerInteract(LocalPlayer()) then return false end
	return self:SendNWCommand("PlayerLoadAmmo",otherItem);
end

--[[
Overridden from base_ranged;
Like the base_ranged, we have everything the base weapon has.
Ulike the base_ranged:
	We only one mode of fire
	We have an option to open the rock-it's inventory,
	If we have anything loaded it says how many items to unload (or if only one item, the option to unload it)
]]--
function ITEM:OnPopulateMenu(pMenu)
	--We've got everything the base weapon has and more!
	self["base_weapon"].OnPopulateMenu(self,pMenu);
	
	--Options to fire gun
	pMenu:AddOption("Fire Primary",		function(panel)	self:SendNWCommand("PlayerFirePrimary")		end);
	
	--Options to unload ammo
	local inv=self:GetInventory(i);
	if inv then
		local ammoCount=inv:GetCount()
		if ammoCount>0 then
			local ammoStr;
			if ammoCount>1 then ammoStr=ammoCount.." items";
			else
				local firstItem=inv:GetFirst();
				ammoStr=firstItem:GetName();
				if firstItem:GetMaxAmount()!=1 then
					ammoStr=ammoStr.." x "..firstItem:GetAmount();
				end
			end
			
			pMenu:AddOption("Unload "..ammoStr,function(panel)	self:SendNWCommand("PlayerUnloadAmmo",i)	end);
		end
	end
	
	--Option to load ammo
	pMenu:AddOption("Reload",	function(panel)	self:SendNWCommand("PlayerReload")			end);
	
	--Option to check inventory
	pMenu:AddOption("Check Inventory",	function(panel)	self:ShowInventory() end);
end

--If someone uses it clientside, show the inventory to them
function ITEM:OnUse(pl)
	self:ShowInventory();
	return false;
end

--Wait for our inventory to arrive clientside; when it does, record that it's our inventory
function ITEM:OnConnectInventory(inv,conslot)
	if !self.Inventory then self.Inventory=inv; self.Inventory.RemovalAction=IFINV_RMVACT_REMOVEITEMS; return true end
	return false;
end
--If for some reason the inventory unlinks from us, we'll forget about it
function ITEM:OnSeverInventory(inv)
	if self.Inventory==inv then self.Inventory=nil; return true end
	return false;
end

function ITEM:ShowInventory()
	local inv=self:GetInventory();
	if !inv || (self.InventoryPanel && self.InventoryPanel:IsValid()) then return false end	
	self.InventoryPanel=vgui.Create("ItemforgeInventory");
	self.InventoryPanel:SetInventory(inv);
end

--[[
Draws a blinking sprite while the item is unloading.
The entity varies depending on what is drawing.
]]--
function ITEM:DrawUnloadBlink(ent)
	if self:GetNWBool("Unloading") && math.sin(CurTime()*30)>=0 then
		render.SetMaterial(self.BlinkMat);
		render.DrawSprite(ent:LocalToWorld(self.BlinkOffset),8,8,self.BlinkColor);
	end
end

--Draw entity
function ITEM:OnEntityDraw(eEntity,ENT,bTranslucent)
	self["base_ranged"].OnEntityDraw(self,eEntity,ENT,bTranslucent);
	self:DrawUnloadBlink(eEntity);
end

--Draw SWEP world model
function ITEM:OnSWEPDraw(eEntity,SWEP,bTranslucent)
	self["base_ranged"].OnSWEPDraw(self,eEntity,SWEP,bTranslucent);
	
	--TODO need to GetWorldModel() or something
	if SWEP.WM!=nil then
		self:DrawUnloadBlink(SWEP.WM.ent);
	end
end

--Draw model in inventory
function ITEM:OnDraw3D(eEntity,PANEL,bTranslucent)
	self["base_ranged"].OnDraw3D(self,eEntity,PANEL,bTranslucent);
	self:DrawUnloadBlink(eEntity);
end