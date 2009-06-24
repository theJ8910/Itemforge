--[[
Itemforge Item Stacks
SHARED

This file contains functions related to stacks of items.
]]--

ITEM.StartAmount=1;									--When we spawn this item, how many items will be in the stack by default? This shouldn't be larger than MaxAmount.
ITEM.MaxAmount=1;									--How many items of this type will fit in a stack (by default - this can be changed with SetMaxAmount())? Set this to 0 to allow an unlimited amount of items of this type to be stored in a stack. Should 1000 shuriken be able to occupy a single slot in an inventory, or should 30 shuriken occupy one slot?

--[[
Returns true if the item is stackable (It's MaxAmount isn't 1)
]]--
function ITEM:IsStack()
	return (self:GetMaxAmount()!=1);
end
IF.Items:ProtectKey("IsStack");

--[[
Get the number of items in the stack.
]]--
function ITEM:GetAmount()
	return self:GetNWInt("Amount");
end
IF.Items:ProtectKey("GetAmount");

--[[
Get the max number of items of the same type that can be in this stack.
]]--
function ITEM:GetMaxAmount()
	return self:GetNWInt("MaxAmount");
end
IF.Items:ProtectKey("GetMaxAmount");

--[[
Adds onto the number of items in this stack.
Returns true if the given number of items were subtracted, and false othewise.
]]--
function ITEM:AddAmount(amt)
	return self:SetAmount(self:GetAmount()+amt);
end
IF.Items:ProtectKey("AddAmount");

--[[
Subtracts from the number of items in this stack.
Returns true if the given number of items were subtracted, and false otherwise.
]]--
function ITEM:SubAmount(amt)
	return self:SetAmount(self:GetAmount()-amt)
end
IF.Items:ProtectKey("SubAmount");

--[[
This function moves items from this stack to another stack.
amt is the number of items to transfer to the stack.
	This should be between 1 and the number of items in this stack (you can get that with self:GetAmount())
otherStack is expected to be a valid stack of items of items that are the same type as this item.
Returns true if we transferred that many items to otherStack.
Returns false otherwise.
TODO get rid of split/merge and make Transfer all purpose
	amt given but otherStack not: Transfers amt items to a new stack and returns the stack
	amt given and otherStack given: Transfers amt items to the given stack;
	amt is all items and otherStack given: Merges this stack with the given stack entirely.
]]--
function ITEM:Transfer(amt,otherStack)
	if !otherStack || !otherStack:IsValid() then ErrorNoHalt("Itemforge Items: Can't transfer items from "..tostring(self).."; a valid stack of items to transfer to was not given.\n"); return false end
	if !amt then ErrorNoHalt("Itemforge Items: Can't transfer items from "..tostring(self).." to "..tostring(otherStack).."; the number of items to transfer wasn't given!\n"); return false end
	if amt<1 then ErrorNoHalt("Itemforge Items: Can't transfer "..amt.." items from "..tostring(self).." to "..tostring(otherStack).."; At least one item must be transferred!\n"); return false end
	if amt>self:GetAmount() then ErrorNoHalt("Itemforge Items: Can't transfer "..amt.." items from "..tostring(self).." to "..tostring(otherStack).."; This stack only has "..self:GetAmount().." items.\n"); return false end
	
	if !otherStack:AddAmount(amt) then return false end
	self:SubAmount(amt);
	
	return true;
end
IF.Items:ProtectKey("Transfer");




if SERVER then




--[[
This function Sets the number of items in the stack.
If happening on the server, the clients are updated with the amount as well.
If the amount is set to 0 or below, the item is removed.
True is returned if the stack's amount was successfully changed to the given number.
False is returned in three cases:
	The stack has run out of items and has been removed (amt was 0 or less)
	The stack has a max amount and couldn't be changed because the new amount would have exceeded the max.
	The stack was in an inventory, and the weight cap would have been exceeded if we had changed the size.
]]--
function ITEM:SetAmount(amt)
	local max=self:GetMaxAmount();
	if amt<=0 then
		self:Remove();
		return false;
	elseif max!=0 && amt>max then
		return false;
	end
	
	local container=self:GetContainer();
	if container then
		local weightCap=container:GetWeightCapacity();
		if weightCap>0 && container:GetWeightStored()-self:GetStackWeight()+(self:GetWeight()*amt)>weightCap then
			return false;
		end
	end
	
	return self:SetNWInt("Amount",amt);
end
IF.Items:ProtectKey("SetAmount");

--[[
Set max number of items in the stack.
Give 0 for maxamount to allow an unlimited number of items in the stack.
Give 1 for maxamount to indicate that this item is not a stack
]]--
function ITEM:SetMaxAmount(maxamount)
	return self:SetNWInt("MaxAmount",maxamount);
end
IF.Items:ProtectKey("SetMaxAmount");

--[[
Merge this pile of items with another pile of items.

bPartialMerge can be used to allow or disallow partial merges.
	A partial merge is where some, but not all, of the items in a stack given to this function were moved.
	If bPartialMerge is:
		true, partial merges will be allowed. If a partial merge occurs, whatever is left of the stack will not removed. -1 will be returned instead of true or false. False will only be returned if none of the items were merged at all.
		false, partial merges will NOT be allowed. It will return true if it merged all of the items in the stack given to it and then removed the stack, or false if this did not happen.

You can give as many items as you want to this function. Ex:
	myItem:Merge(true,otherItem);								--Merge otherStack with this stack
	myItem:Merge(true,otherItem,anotherItem);					--Merge otherStack and anotherStack with this stack
	myItem:Merge(true,otherItem,anotherItem,yetAnotherItem);	--Merge otherStack, anotherStack, and yetAnotherStack with this stack
	myItem:Merge(false,otherItem);								--Merge otherStack with this stack; fails if it doesn't move EVERY item in that stack to this one
The items given will be removed and their amounts added to this item's amount.
This item's OnMerge or the other item's OnMerge can stop each individual merge.
Items have to be the same type as this item.

This function returns a series of trues and falses, based on the success of merges asked. Ex:
	Lets say we want to merge this item with three items:
		myItem:Merge(true,otherItem,anotherItem,yetAnotherItem);
	If this function returns:
						    true,      true,         true
	It means, otherItem's whole stack merged, anotherItem's whole stack merged, and yetAnotherItem's whole stack merged. They all merged successfully.
	
	Another example...
	Lets say we want to merge this item with three items:
		myItem:Merge(true,otherItem,anotherItem,yetAnotherItem);
	If this function returns:
						    true,      -1,          false
	It means, otherItem's whole stack merged, anotherItem PARTIALLY merged, and yetAnotherItem DIDN'T merge.
	
	Another example...
	Lets say we want to merge this item with a complete stack:
		myItem:Merge(false,otherItem,anotherItem);
	If this function returns:
							  true      false
	It means, the whole stack of otherItem merged, but anotherItem's whole stack couldn't merge unfortunately.
So, how do you put these values in vars?
	local first,second,third=item:Merge(true,firstItem,secondItem,thirdItem);
Hope this is an adequate explanation of how this works.
]]--
function ITEM:Merge(bPartialMerge,...)
	
	if !arg[1] then ErrorNoHalt("Itemforge Items: Couldn't merge "..tostring(self).." with another item. No item was given!\n"); return false end
	
	local SuccessTable={};
	local max=self:GetMaxAmount();
	local i=1;
	while arg[i]!=nil do
		if arg[i]:IsValid() then
			if self!=arg[i] then
				if self:GetType()==arg[i]:GetType() then
					--Give merge events on both items a chance to stop the merge
					local s,r1=pcall(self.OnMerge,self,arg[i]);
					if !s then ErrorNoHalt(r1.."\n"); r1=false end
					local s,r2=pcall(arg[i].OnMerge,arg[i],self);
					if !s then ErrorNoHalt(r2.."\n"); r2=false end
					
					if r1 && r2 then
						local fit=self:GetMaxAmount()-self:GetAmount();
						
						if self:SetAmount(self:GetAmount()+arg[i]:GetAmount()) then
							arg[i]:Remove();
							SuccessTable[i]=true;
						elseif bPartialMerge && fit > 0 && arg[i]:GetAmount()>fit then
							if self:SetAmount(self:GetMaxAmount()) then
								arg[i]:SetAmount(arg[i]:GetAmount()-fit);
								SuccessTable[i]=-1;
							else
								SuccessTable[i]=false;
							end
						else
							SuccessTable[i]=false;
						end
					else
						SuccessTable[i]=false;
					end
				else
					ErrorNoHalt("Itemforge Items: Couldn't merge "..tostring(self).." with "..tostring(arg[i])..". These items are not the same type.\n");
					SuccessTable[i]=false;
				end
			else
				ErrorNoHalt("Itemforge Items: Couldn't merge "..tostring(self).." with "..tostring(arg[i]).." - can't merge an item with itself!\n");
				SuccessTable[i]=false;
			end
		else
			ErrorNoHalt("Itemforge Items: Couldn't merge "..tostring(self).." with an item. Item given was invalid!\n");
			SuccessTable[i]=false;
		end
		
		i=i+1;
	end
	return unpack(SuccessTable);
end
IF.Items:ProtectKey("Merge");

--[[
Split this pile of items into two or more piles.

This function can be used to split an item into:
	Two stacks:		self:Split(true,5);			(make a new stack with 5 items from this stack)
	Three stacks:	self:Split(true,5,7);		(make two new stacks: one with 5 items, another with 7)
	Four stacks:	self:Split(true,5,7,12);	(make three new stacks: one with 5 items, another with 7, and another with 12)

Really, however many stacks you want!
The numbers in the examples above are how many items to transfer to new stacks.
Each number you give this function tells it to split the stack into a new stack with that many items from the original stack.

bSameLocation is an argument that determines where the item is placed.
	If this is false, the new stack will be created in the void.
	If this is true, the new stack will be created in:
		the same container that this stack is in, if in a container.
		the new stack will be created nearby this stack, if in the world.
		dropped from where the player is looking.

TODO return false if a stack can't be broken
]]--
function ITEM:Split(bSameLocation,...)
	--Forgot to tell us how many items to split
	if !arg[1] then ErrorNoHalt("Itemforge Items: Couldn't split "..tostring(self).." - number of items to transfer to a new stack into wasn't given!\n"); return false end
	bSameLocation=bSameLocation or false;
	
	--Count how many items are trying to be taken out of the stack and sent to new stacks
	local i=1;
	local totalCount=0;
	while type(arg[i])=="number" do
		local howMany=math.floor(arg[i]);
		
		--And make sure we're not asking to split something impossible
		if howMany<=0 then ErrorNoHalt("Itemforge Items: Couldn't split "..tostring(self).." - was trying to transfer 0 or less items to a new stack...\n"); return false end
		
		totalCount=totalCount+howMany;
		i=i+1;
	end
	
	--Total numbers of items possibly being transferred in range?
	if totalCount<=0 then ErrorNoHalt("Itemforge Items: Couldn't split "..tostring(self).." - was trying to transfer 0 or less items to the new stack...\n"); return false end
	local amt=self:GetAmount();
	if totalCount>=amt then ErrorNoHalt("Itemforge Items: Couldn't split "..tostring(self).." - was trying to transfer all or too many ("..totalCount..") items total to new stacks. This stack only has "..amt.." items.\n"); return false end
	
	local i=1;
	local newStacks={};
	local totalAmountTransferred=0;
	
	while type(arg[i])=="number" do
		local howMany=math.floor(arg[i]);
		
		--Will the event let the split happen (we run the event for each split)
		local s,r=pcall(self.OnSplit,self,howMany);
		if !s then ErrorNoHalt(r.."\n")
		elseif r then
			--Split the item. We'll create in same location as this stack if told to, or in the void if not told to.
			local newStack=0;
			if bSameLocation then
				newStack=IF.Items:CreateSameLocation(self:GetType(),self);
			else
				newStack=IF.Items:Create(self:GetType());
			end
			
			if newStack && newStack:IsValid() then
				
				--Adjust amounts
				totalAmountTransferred=totalAmountTransferred+howMany;
				newStack:SetAmount(howMany);
				
				--New stack created, call it's hook so it can decide what to do next.
				local s,r=pcall(newStack.OnSplitFromStack,newStack,self,howMany);
				if !s then ErrorNoHalt(r.."\n") end
				
				table.insert(newStacks,newStack);
			end
		end
		
		i=i+1;
	end
	
	self:SetAmount(amt-totalAmountTransferred);
	return unpack(newStacks);
end
IF.Items:ProtectKey("Split");




else




--[[
Sets the number of items in this stack.
Clientside, this is only good for predicition purposes.
amt is how many items you want this stack to have.
	If amt is less than 1, amt will be changed to 1.
	If this item has a max amount set, and amt is greater than that, amt will be set to the max amount.
Returns true if the amount was changed successfully, or false otherwise.
]]--
function ITEM:SetAmount(amt)
	local max=self:GetMaxAmount();
	
	if amt<1 then					amt=1;
	elseif max!=0 && amt>max then	amt=max;
	end
	
	return self:SetNWInt("Amount",amt);
end
IF.Items:ProtectKey("SetAmount");




end