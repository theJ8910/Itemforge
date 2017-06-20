--[[
item_crate
SHARED

This particular file registers the supply crate's inventory template.
All supply crates use this kind of inventory.
]]--
local INV = {};

INV.SizeLimit		= 26;			--Crate's size - 1; this stops other crates and items bigger than crates from being placed in here
INV.WeightCapacity	= 40000;		--Holds 40kg
INV.MaxSlots		= 15;			--15 unique stacks of items can be stored here.

IF.Inv:RegisterType( INV, "inv_crate" );