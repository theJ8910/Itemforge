--[[
item_footlocker
SHARED

This particular file registers the footlocker's inventory template.
All footlockers use this kind of inventory.
]]--
local INV			= {};

INV.SizeLimit		= 29;			--Footlocker's size-1; this stops other footlockers and items bigger than footlockers from being placed in here
INV.WeightCapacity	= 50000;		--Holds 50kg
INV.MaxSlots		= 20;			--20 unique stacks of items can be stored here.

if CLIENT then




--[[
* CLIENT
* Event

When the footlocker locks, clientside we hide any inventory windows opened by the footlocker
]]--
function INV:OnLock()	
	local attachedItem = self:GetConnectedItems()[1];
	if !attachedItem then return false end
	
	attachedItem:HideInventory();
end




end

IF.Inv:RegisterType( INV, "inv_footlocker" );