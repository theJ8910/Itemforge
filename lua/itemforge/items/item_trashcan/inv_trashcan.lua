--[[
item_trashcan
SHARED

This particular file registers the trash can's inventory type.
All trash cans use this kind of inventory.
]]--
local INV = {};

INV.SizeLimit = 14;			
INV.WeightCapacity = 20000;							--Holds 20kg
INV.MaxSlots = 30;									--30 unique stacks of items can be stored here.
INV.RemovalAction = IFINV_RMVACT_REMOVEITEMS;		--Items stored by this inventory are removed if this inventory is removed

IF.Inv:RegisterType( INV, "inv_trashcan" );