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
ITEM.WorldModel="models/props_junk/wood_crate001a.mdl";

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;

--Base Container
ITEM.InvTemplate=nil;							--This can be the name of an inventory template your containers use
ITEM.Inventory=nil;								--This is the inventory attached to this item

if CLIENT then
	ITEM.InvPanelType = "ItemforgeInventory";	--This is the type of panel created to display the inventory.
	ITEM.InventoryPanel = nil;					--This is the currently displayed panel, if there is one.
end

--[[
* SHARED
* Event

If this function is used clientside, this creates an inventory window for the player.
If this function is used serverside, this tells the given player's client to show him the inventory.
]]--
function ITEM:ShowInventory(pl)
	if SERVER then
		self:SendNWCommand("ShowInventory",pl);
	else
		--If this item doesn't know what it's inventory is clientside, we return false
		if self.Inventory==nil then return false end
		
		--If this item is already showing us it's inventory then don't show another one
		if self:GetInventoryPanel() then return false end
		
		--Create an inventory panel...
		self.InventoryPanel=vgui.Create(self.InvPanelType);
		
		--And then display our inventory on it
		self.InventoryPanel:SetInventory(self.Inventory);
	end
	return true;
end

--[[
* SHARED

Returns the inventory, or nil if one is not available.
]]--
function ITEM:GetInventory()
	if self.Inventory && !self.Inventory:IsValid() then
		self.Inventory = nil;
		return nil;
	end
	return self.Inventory;
end

--[[
* SERVER
* Event

Show the container's inventory to whoever used it
]]--
function ITEM:OnUse(pl)
	self:Event("ShowInventory",nil,pl);
	
	return SERVER;
end

if SERVER then

--[[
* SERVER
* Event

Whenever this item is created we need to make an inventory for it and connect it.
]]--
function ITEM:OnInit()
	local inv=IF.Inv:Create(self.InvTemplate);
	if !inv || !inv:IsValid() then return false end
	
	inv:ConnectItem(self);
	self.Inventory=inv;
	
	return true;
end

--[[
* SERVER
* Event

Automatically take items that touch the container
]]--
function ITEM:OnStartTouch(ent,activator)
	local touchItem=IF.Items:GetEntItem(activator);
	if touchItem && self.Inventory && self.Inventory:IsValid() then touchItem:ToInventory(self.Inventory); end
end

IF.Items:CreateNWCommand(ITEM,"ShowInventory");




else




--[[
* CLIENT

Returns the inventory panel displaying this to the player, or nil if one is not available.
]]--
function ITEM:GetInventoryPanel()
	if self.InventoryPanel && !self.InventoryPanel:IsValid() then
		self.InventoryPanel = nil;
		return nil;
	end
	return self.InventoryPanel;
end

--[[
* CLIENT

If an inventory panel is currently visible then it deletes it.
]]--
function ITEM:HideInventory()
	local pInv=self:GetInventoryPanel();
	if !pInv then return false end
	
	pInv:Remove();
	self.InventoryPanel=nil;
end

--[[
* CLIENT
* Event

If an item is drag-dropped onto this container we try to add it to the container.
]]--
function ITEM:OnDragDropHere(otherItem)
	local inv=self:GetInventory();
	
	--Predict whether or not the container can take the other item
	if !otherItem:ToInv(self.Inventory) then return true end
	
	otherItem:PlayerSendToInventory(LocalPlayer(),inv);
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

function ITEM:OnPopulateMenu(pMenu)
	self:BaseEvent("OnPopulateMenu",nil,pMenu);
	pMenu:AddOption("Check Contents",function(panel) self:Event("ShowInventory",nil,LocalPlayer()) end);
end

IF.Items:CreateNWCommand(ITEM,"ShowInventory",function(self,...) self:ShowInventory(...) end);




end
