--[[
item_bag
SHARED

This particular file registers the paper bag's inventory template.
All paper bags use this kind of inventory.
]]--
local INV			= {};

INV.SizeLimit		= 12;			--Bag's size-1; this stops other bags and items bigger than paper bags from being placed in here
INV.WeightCapacity	= 1000;			--Holds 1kg
INV.MaxSlots		= 5;			--5 unique stacks of items can be stored here - Couple of burger boxes, couple of boxes of fries, and some napkins?

IF.Inv:RegisterType( INV, "inv_bag" );