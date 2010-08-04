--[[
weapon_rockit
SHARED

This file defines the inventory that the rock-it launcher guns use.
]]--
local INV={};

INV.SizeLimit=30;			--The Rock-It-Launcher can actually hold objects bigger than itself... but that's fine with me. Lets just pretend the RIL uses space-age apocalypse technology that shrinks the items.
INV.WeightCapacity=25000;	--Holds 25kg (a little more than 50 pounds)
INV.MaxSlots=15;			--15 unique stacks of items can be stored here.

INV.RemovalAction=IFINV_RMVACT_REMOVEITEMS;	--The default removal action is to remove stored items when the inventory gets removed.

IF.Inv:RegisterType(INV,"inv_rockit");