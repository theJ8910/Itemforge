--[[
Itemforge Item Weight
SHARED

This file contains functions related to item weight.
]]--

ITEM.Weight=1;										--Default weight of one item in this stack, in grams. By default, I mean that the weight can be changed after the item is created. Note: this doesn't affect the physics weight when the item is on the ground, just the weight of the item in an inventory.

--[[
* SHARED
* Protected

This sets the weight of each individual item in the stack.
For example:
	If there are 5 items in the stack, and you set the weight to 5kg, the stack now weighs 25kg (because 5kg*5 items = 25kg)
	If there is only one item in the stack, and you set the weight to 20kg, the item now weighs 20kg (20kg * 1 item = 20kg).
]]--
function ITEM:SetWeight(kg)
	self:SetNWInt("Weight",kg);
end
IF.Items:ProtectKey("SetWeight");

--[[
* SHARED
* Protected

Get the weight of an item in the stack (they all weigh the same).
]]--
function ITEM:GetWeight()
	return self:GetNWInt("Weight");
end
IF.Items:ProtectKey("GetWeight");

--[[
* SHARED
* Protected

Get the weight of all the items in the stack. This is the weight of an individual item times the amount.
]]--
function ITEM:GetStackWeight()
	return self:GetWeight()*self:GetAmount();
end
IF.Items:ProtectKey("GetStackWeight");