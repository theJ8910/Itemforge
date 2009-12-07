--[[
Itemforge Player Inventory module
SERVER

This module begrudgingly gives players inventories.
]]--

MODULE.Name="PlayerInv";										--Our module will be stored at IF.PlayerInv
MODULE.Disabled=false;											--Our module will be loaded

--Initilize player inventory module
function MODULE:Initialize()
	if SERVER && IF.Inv then
		hook.Add("PlayerSpawn","itemforge_playerinv_give",function(pl) timer.Simple(5,IF.PlayerInv.GivePlayerInventory,IF.PlayerInv,pl) end)
	end
end

--[[
Cleanup player inventory module
]]--
function MODULE:Cleanup()
	if SERVER then
		hook.Remove("PlayerSpawn","itemforge_playerinv_give")
	end
end

if SERVER then




function MODULE:GivePlayerInventory(pl)
	if pl.Inventory then return false end
	
	local inv=IF.Inv:Create();
	inv.RemovalAction=IFINV_RMVACT_REMOVEITEMS;
	inv:ConnectEntity(pl);
	pl.Inventory=inv;
	pl:SetNWInt("itemforge_inventory_id",inv:GetID());
end




else




function MODULE:ShowLocalPlayerInventory()
	local pl=LocalPlayer();
	if pl.InventoryPanel && pl.InventoryPanel:IsValid() then return false end
	
	local id=pl:GetNWInt("itemforge_inventory_id")
	if id==0 then return false end
	
	local inv=IF.Inv:Get(id);
	if !inv || !inv:IsValid() then return false end
	
	pl.InventoryPanel=vgui.Create("ItemforgeInventory");
	pl.InventoryPanel:SetInventory(inv);
	
	return true;
end

concommand.Add("show_inventory",function(pl,command,args) return IF.PlayerInv:ShowLocalPlayerInventory() end);




end