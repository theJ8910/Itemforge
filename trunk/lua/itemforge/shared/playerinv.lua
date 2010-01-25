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

--This is more or less the example function from base_ranged/findammo.lua used for locating items in player inventories
list.Add("Itemforge_BaseRanged_FindAmmo",function(self,fCallback)
	local pOwner=self:GetWOwner();
	if !pOwner then return false end
	local pInv=IF.PlayerInv:GetPlayerInventory(pOwner);
	if !pInv then return false end
	
	for k,v in pairs(pInv:GetItems()) do
		if fCallback(self,v) then
			return true;
		end
	end
	
	return false;
end)

if SERVER then




function MODULE:GivePlayerInventory(pl)
	if !pl || !pl:IsValid() then return false end
	if pl.Inventory then return false end
	
	local inv=IF.Inv:Create();
	inv.RemovalAction=IFINV_RMVACT_REMOVEITEMS;
	inv:ConnectEntity(pl);
	pl.Inventory=inv;
	pl:SetNWInt("itemforge_inventory_id",inv:GetID());
	
	return true;
end

function MODULE:GetPlayerInventory(pl)
	if !pl || !pl:IsValid() then return nil end
	if pl.Inventory && !pl.Inventory:IsValid() then pl.Inventory=nil; end
	return pl.Inventory;
end




else




function MODULE:GetPlayerInventory(pl)
	if !pl || !pl:IsValid() then return nil end
	
	if pl.Inventory && pl.Inventory:IsValid() then
		return pl.Inventory;
	else
		local id=pl:GetNWInt("itemforge_inventory_id")
		if id==0 then return nil end
		
		local inv=IF.Inv:Get(id);
		if !inv || !inv:IsValid() then return nil end
		
		pl.Inventory=inv;
	end
	return inv;
end

function MODULE:ShowLocalPlayerInventory()
	local pl=LocalPlayer();
	local inv=self:GetPlayerInventory(pl);
	if !inv then return false end
	
	pl.InventoryPanel=vgui.Create("ItemforgeInventory");
	pl.InventoryPanel:SetInventory(inv);
	
	return true;
end

concommand.Add("show_inventory",function(pl,command,args) return IF.PlayerInv:ShowLocalPlayerInventory() end);




end