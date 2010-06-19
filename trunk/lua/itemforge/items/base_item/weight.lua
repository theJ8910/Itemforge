--[[
Itemforge Item Weight
SHARED

This file contains functions related to item weight.
]]--

ITEM.Weight=1;										--Default weight of one item in this stack, in grams. By default, I mean that the weight can be changed after the item is created. Note: this doesn't affect the physics weight when the item is on the ground, just the weight of the item in an inventory.

--[[
* SHARED
* Protected

This sets the weight of each individual item in the stack, in grams.

Because Itemforge treats weight as an integer, if the number of grams given
has a decimal point then it is ignored (e.g. 900.5 becomes 900).

iGrams can be 0 to indicate the items have no weight, but negative values will result in an error.

For example:
	If there are 5 items in the stack, and you set the weight to 5000 grams, the stack now weighs 25000 grams (because 5000 grams * 5 items = 25000 grams)
	If there is only one item in the stack, and you set the weight to 20000 grams, the item now weighs 20000 (20000 grams * 1 item = 20000 grams).

TODO Stranded 2 supports negative weights (eg butterflies) so it might not be a bad idea
	 to add support for that
]]--
function ITEM:SetWeight(iGrams)
	if iGrams < 0 then return self:Error("Couldn't set weight. Weight cannot be negative value ("..iGrams..")."); end
	self:SetNWInt("Weight",iGrams);
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