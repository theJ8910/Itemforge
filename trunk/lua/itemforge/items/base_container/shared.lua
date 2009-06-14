--[[
base_container
SHARED

The base container item is a template for the creation of simple containers.

This item creates a public inventory and ties it to this item shortly after it's created.
When the item is used, a window is opened that displays the inventory to the player who used it.
Whenever another item comes into contact with this container (while in the world), the container tries to place the item inside of it's inventory.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Base Container";
ITEM.Description="This item is the base container.\nItems that can store other items can inherit from this to make their creation easier.\n\nThis is not supposed to be spawned.";
ITEM.Base="item";
ITEM.WorldModel="models/props_junk/wood_crate001a.mdl";

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;

--Base Container
ITEM.Inventory=nil;

if SERVER then

--Whenever this item is created we need to make an inventory for it and connect it.
function ITEM:OnInit()
	local inv=IF.Inv:Create();
	if !inv || !inv:IsValid() then return false end
	 
	inv:ConnectItem(self);
	self.Inventory=inv;
end

--Containers can't be held like weapons.
function ITEM:OnHold(pl)
	return false;
end

--Automatically take items that touch the container
function ITEM:OnStartTouch(ent,activator)
	if activator:GetClass()=="itemforge_item" then
		local touchItem=activator:GetItem();
		if touchItem && touchItem:IsValid() then
			if self.Inventory && self.Inventory:IsValid() then touchItem:ToInventory(self.Inventory); end
		end
	end
end

--Show the container's inventory to whoever used it
function ITEM:OnUse(pl)
	self:SendNWCommand("ShowInventory",pl);
	return true;
end




else




--If someone uses it clientside, show it to them
function ITEM:OnUse(pl)
	self:ShowInventory();
	return false;
end

--When the item is used serverside, this function is called clientside
function ITEM:ShowInventory()
	--If this item doesn't know what it's inventory is clientside, we return false
	if self.Inventory==nil then return false end
	
	--If this item is already showing us it's inventory then don't show another one
	if self.InventoryPanel && self.InventoryPanel:IsValid() then return false end
	
	--Create an inventory panel...
	self.InventoryPanel=vgui.Create("ItemforgeInventory");
	
	--And then display our inventory on it
	self.InventoryPanel:SetInventory(self.Inventory);
end

function ITEM:HideInventory()
	if !self.InventoryPanel || !self.InventoryPanel:IsValid() then return false end
	
	self.InventoryPanel:Remove();
	self.InventoryPanel=nil;
end

function ITEM:OnDragDropHere(otherItem)
	otherItem:SendNWCommand("PlayerSendToInventory",self.Inventory,0);
	return false;
end

function ITEM:OnConnectInventory(inv,conslot)
	if !self.Inventory then self.Inventory=inv; return true end
	return false;
end

function ITEM:OnSeverInventory(inv)
	if self.Inventory==inv then self.Inventory=nil; return true end
	return false;
end




end

IF.Items:CreateNWCommand(ITEM,"ShowInventory",ITEM.ShowInventory);
