--[[
Itemforge Item Stacks
SHARED

This file contains functions related to stacks of items.
]]--

ITEM.StartAmount=1;									--When we spawn this item, how many items will be in the stack by default? This shouldn't be larger than MaxAmount.
ITEM.MaxAmount=1;									--How many items of this type will fit in a stack (by default - this can be changed with SetMaxAmount())? Set this to 0 to allow an unlimited amount of items of this type to be stored in a stack. EX: Should 1000 shuriken be able to occupy a single slot in an inventory, or should 30 shuriken occupy one slot?

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
This function sets the number of items in the stack.
If a new amount is set on the server, the clients are updated with the new amount as well.
If this item is in an inventory with a weight cap, we'll check to see if the new stack weight breaks the weight cap. If it does, false is returned.
amt is the new number of items you want this stack to have.
	amt must be between 0 and the item's max amount (if it has one), otherwise the function will return false.
	If amt is 0, the item is removed.
bIgnoreWeightCap is an optional true/false. If this item's new stack weight is too much for the weight cap of the inventory it's in, and bIgnoreWeightCap is:
	true, then we'll set the amount to whatever was given anyway. 
	false or not given, we'll stop the amount from being changed and return false.
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredicted is:
	true, then we won't actually change the amount, we'll just return true if the amount can be changed to the given amount.
	false, then we will change the amount.
True is returned if the stack's amount was changed/is changeable to the given number.
False is returned in four cases:
	TODO true should be returned if :SetAmount() to 0; after all, you CAN set the amt to 0 can't you?
	The stack has/would run out of items and has/would be removed
	The stack can't have it's amount set below 0.
	The stack has a max amount and can't be changed because the new amount would have exceeded the max.
	The stack was in an inventory, and the weight cap would have/would be been exceeded if we had changed the size.
]]--
function ITEM:SetAmount(amt,bIgnoreWeightCap,bPredict)
	if bIgnoreWeightCap==nil then bIgnoreWeightCap=false end
	if bPredict==nil then bPredict=CLIENT end
	
	if self:GetAmount()==amt then return true end
	
	local max=self:GetMaxAmount();
	if SERVER && amt==0 then
		if !bPredict then self:Remove(); end
		return false;
	elseif amt<0 || (max!=0 && amt>max) then
		return false;
	end
	
	if !bIgnoreWeightCap && IF.Inv:DoWeightCapsBreak(self,amt) then return false end
	
	if !bPredict then self:SetNWInt("Amount",amt); end
	return true;
end
IF.Items:ProtectKey("SetAmount");

--[[
Adds onto the number of items in this stack.
bPredict is an optional true/false. If this is true, we won't change the amount, we'll just return true if it can be changed.
Returns true if the given number of items were subtracted, and false otherwise.
]]--
function ITEM:AddAmount(amt,bIgnoreWeightCap,bPredict)
	return self:SetAmount(self:GetAmount()+amt,bIgnoreWeightCap,bPredict);
end
IF.Items:ProtectKey("AddAmount");

--[[
Subtracts from the number of items in this stack.
bPredict is an optional true/false. If this is true, we won't change the amount, we'll just return true if it can be changed.
Returns true if the given number of items were subtracted, and false otherwise.
]]--
function ITEM:SubAmount(amt,bIgnoreWeightCap,bPredict)
	return self:SetAmount(self:GetAmount()-amt,bIgnoreWeightCap,bPredict);
end
IF.Items:ProtectKey("SubAmount");

--[[
This function moves items from this stack to another stack.
amt is the number of items to transfer to the stack.
	This should be between 1 and the number of items in this stack (you can get that with self:GetAmount())
otherStack is expected to be a valid stack of items of items that are the same type as this item.
Returns true if we transferred that many items to otherStack.
Returns false otherwise.

TODO this function sucks; will improve it when repurposing it
TODO get rid of (or repurpose) split/merge and make Transfer all purpose
	amt given but otherStack not: Transfers amt items to a new stack and returns the stack
	amt given and otherStack given: Transfers amt items to the given stack;
	amt is all items and otherStack given: Merges this stack with the given stack entirely.
]]--
function ITEM:Transfer(amt,otherStack)
	if !otherStack || !otherStack:IsValid()	then self:Error("Can't transfer items from this stack; a valid stack of items to transfer to was not given.\n"); return false end
	if !amt									then self:Error("Can't transfer items from this stack to "..tostring(otherStack).."; the number of items to transfer wasn't given!\n"); return false end
	if amt<1								then self:Error("Can't transfer "..amt.." items from this stack to "..tostring(otherStack).."; At least one item must be transferred!\n"); return false end
	if amt>self:GetAmount()					then self:Error("Can't transfer "..amt.." items from this stack to "..tostring(otherStack).."; This stack only has "..self:GetAmount().." items.\n"); return false end
	
	if !otherStack:AddAmount(amt) then return false end
	self:SubAmount(amt);
	
	return true;
end
IF.Items:ProtectKey("Transfer");

--[[
Merge this stack of items with another/several stacks of items.

The stacks given will be removed and their amounts added to this stack's amount.
This stack or the other stack's CanMerge can stop each individual merge from happening.
The stacks given have to have the same type of items as this stack.

It's arguments are like this:
self:Merge(stack1,stack2,...,bPartialMerge,bPredict)

stack1,stack2,...
	You can give an many stacks as you want.

bPartialMerge is an optional true/false. If we can't fit all the items from a given stack, and bPartialMerge is:
	true or not given, we'll try to move as many as possible. We'll return -1 to indicate a partial merge.
	false, we won't move any at all. We'll return false.

bPredict is an optional true/false. This defaults to false on the server, and true on the client. If bPredict is:
	false, items will actually be merged, and we'll return whether or not a merge was successful.
	true, a merge won't be performed; instead we'll predict what will be returned if we do merge.
	NOTE:
	You should NEVER set bPredict to false on the client. Clientside merges are used internally by Itemforge and are not intended to be used by scripters.

This function returns a true, false, or -1 for each stack you asked it to merge.
	true is returned if all of the items from a given stack were merged.
	false is returned if none of the items from a given stack were merged.
	-1 is returned if some of the items from a given stack were merged.

Here are a few examples of how the function can be used:
	On the:							Server
	We do:					stack1:Merge(stack2)
	This is returned:					  true
	What this means:		stack1 received all of stack2's items.
	
	On the:							Server
	We do:					stack1:Merge(stack2)
	This is returned:					  false
	What this means:		stack1 didn't receive any items from stack2.
	
	On the:							Server
	We do:					stack1:Merge(stack2)
	This is returned:					   -1
	What this means:		stack1 received some items from stack2, but not all of them.
	
	On the:							Server
	We do:					stack1:Merge(stack2,false)
	This is returned:					  true
	What this means:		We tried to move _all_ the items from stack2 to stack1, and did!
	
	On the:							Server
	We do:					stack1:Merge(stack2,false)
	This is returned:					 false
	What this means:		We tried to move _all_ the items from stack2 to stack1, but couldn't (it may have been possible to move some, but we wanted to move them all)
	
	On the:							Server
	We do:					stack1:Merge(stack2,stack3,stack4);
	This is returned:					  true,  true,  true
	What this means:		stack1 received all the items from stack2, stack3, and stack4.
	
	On the:							Server
	We do:					stack1:Merge(stack2,stack3,stack4);
	This function returns:				  true,   -1,   false
	What this means:		stack1 received all of stack2's items, some of stack3's items, and none of stack4's items.
	
	On the:							Server
	We do:					stack1:Merge(stack2,stack3,false);
	This function returns:				  true, false
	What this means:		We tried to move _all_ the items from stack2 and stack3 to stack1. stack1 received all of stack2's items and none of stack3's.

	On the:							Client
	We do:					stack1:Merge(stack2)
	This function returns:				  true
	What this means:		Since this is called on the client, we're predicting instead of actually merging. If a merge is performed, stack1 should receive all of stack2's items.
	
	On the:							Client
	We do:					stack1:Merge(stack2)
	This function returns:				  false
	What this means:		Since this is called on the client, we're predicting instead of actually merging. If a merge is performed, stack1 shouldn't receive any of stack2's items.
	
	On the:							Client
	We do:					stack1:Merge(stack2)
	This function returns:				   -1
	What this means:		Since this is called on the client, we're predicting instead of actually merging. If a merge is performed, stack1 should receive some, but not all, of stack2's items.
	
	On the:							Client
	We do:					stack1:Merge(stack2,false)
	This function returns:				 false
	What this means:		Since this is called on the client, we're predicting instead of actually merging. If we try to move all of stack2's items to stack1, it shouldn't work.
	
	On the:							Server
	We do:					stack1:Merge(stack2,false,true)
	This function returns:					false
	What this means:		For some reason we want to predict if we can merge _all_ of stack2's items into stack1 on the server. If we try to move all of stack2's items to stack 1, it shouldn't work.
	
If you are merging several stacks, you can store the values :Merge() returns like this:
	local merged2,merged3,merged4=stack1:Merge(stack2,stack3,stack4);
Hope this is an adequate explanation of how this works.
]]--
function ITEM:Merge(...)
	if type(arg[1])!="table" then self:Error("Couldn't merge this stack with another stack. No item was given!\n"); return false end
	
	local bPartialMerge=true;
	local bPredict=CLIENT;
	
	local args=#arg;
	local last=arg[args];
	if type(last)=="boolean" then
		local sec2last=arg[args-1];
		
		--A second bool was given
		if sec2last==nil || type(sec2last)=="boolean" then
			if sec2last!=nil then bPartialMerge=sec2last end
			bPredict=last;
		
		--Only one bool was given
		else
			bPartialMerge=last;
		end
	end
	
	local SuccessTable={};
	local total=self:GetAmount();
	local i=1;
	while type(arg[i])=="table" do
		SuccessTable[i]=false;
		
		--[[
		Can't merge with self, invalid items, different item types, or if CanMerge events on either item deny it
		Additionally, a stack must have enough free space (determined by the stack's MaxAmount, if there is one) to take all items (or some, if partial merges are allowed) from another stack.
		Lastly, if either stack is in a container, weight caps in these inventories must not be broken as a result of the merge.
		]]--
		if self!=arg[i] && arg[i]:IsValid() && self:GetType()==arg[i]:GetType() && self:Event("CanMerge",false,arg[i],true) && arg[i]:Event("CanMerge",false,self,false) then
			local newAmt=total+arg[i]:GetAmount();
			
			if self:SetAmount(newAmt,true,true) && !IF.Inv:DoWeightCapsBreak(self,newAmt,arg[i],0) then
				
				if !bPredict then
					arg[i]:Remove();
				
					self:Event("OnMerge",nil,nil,false);
				end
				
				total=newAmt;
				SuccessTable[i]=true;
			
			elseif bPartialMerge then
				local fit=self:GetMaxAmount()-self:GetAmount();
				
				newAmt=total+fit;
				local newAmt2=arg[i]:GetAmount()-fit;
				
				if fit > 0 && self:SetAmount(newAmt,true,true) && !IF.Inv:DoWeightCapsBreak(self,newAmt,arg[i],newAmt2) then
					
					if !bPredict then
						arg[i]:SetAmount(newAmt2,true,false);
						self:Event("OnMerge",nil,arg[i],true);
					end
					
					total=newAmt;
					SuccessTable[i]=-1;
				end
			end
		end
		i=i+1;
	end
	
	if !bPredict then self:SetAmount(total,true,false) end
	return unpack(SuccessTable);
end
IF.Items:ProtectKey("Merge");

--[[
Split this pile of items into two or more piles.

The arguments for this function are like so:
self:Split(split1,split2,...,bSameLocation,bPredict)

split1,split2,...
	For each split# you give, this will transfer the given number of items to a new stack.
	You can split the item into as many stacks as you want.

bSameLocation is an optional true/false. If bSameLocation is:
	true or not given, the new stacks are created at the same location as this stack.
	false, the new stacks are created in the void
	See the ToSameLocation function for more details on where an item is placed when sent to the "Same Location" as another item.

bPredict is an optional true/false. This defaults to false on the server and true on the client. If bPredict is:
	false, a split will actually be performed, and [NEW ITEM]/nil will be returned if the split was/wasn't successful.
	true, we'll predict if splits are possible. [TEMP ITEM]/nil will be returned if the split should work/shouldn't be successful.

Here are a few examples of how the function can be used.
	On the:					Server
	We do:					stack1:Split(5);
	This is returned:		[NEW ITEM]
	What this means:		5 items from stack1 were split off into a new stack. The new stack has been returned.
	
	On the:					Server
	We do:					stack1:Split(10);
	This is returned:		nil
	What this means:		We tried to split off 10 items from stack1 but couldn't.
	
	On the:					Server
	We do:					stack1:Split(10,20,30);
	This is returned:		[NEW ITEM],[NEW ITEM],nil
	What this means:		We tried to split off 60 total items into stacks of 10, 20, and 30 from stack1. The stack of 10 and the stack of 20 were split off successfully, but the stack of 30 couldn't be split.
	
	On the:					Client
	We do:					stack1:Split(7);
	This is returned:		[TEMP ITEM]
	What this means:		Since this is called on the client, we're predicting what will be returned if we split. We got a [TEMP ITEM], which can be used to carry out further predictions. The fact that we got a temp item means that a split should work.

	On the:					Client
	We do:					stack1:Split(24);
	This is returned:		nil
	What this means:		Since this is called on the client, we're predicting what will be returned if we split. We got nil, meaning we shouldn't be able to split off 24 items from stack1.
	
	On the:					Client
	We do:					stack1:Split(1,5,7);
	This is returned:		nil,[TEMP ITEM],nil
	What this means:		Since this is called on the client, we're predicting what will be returned if we split. We predict that the stack of 1 won't split, the stack of 5 will split, and the stack of 7 won't.

If you are splitting several stacks, you can store the values :Split() returns like this:
	local stack2,stack3,stack4=stack1:Split(4,12,8);

TODO return false if a stack can't be broken
]]--
function ITEM:Split(...)
	--Forgot to tell us how many items to split
	if type(arg[1])!="number" then self:Error("Couldn't split this stack - number of items to transfer to a new stack into wasn't given!\n"); return false end
	
	local bSameLocation=true;
	local bPredict=CLIENT;
	
	local args=#arg;
	local last=arg[args];
	if type(last)=="boolean" then
		local sec2last=arg[args-1];
		
		--A second bool was given
		if sec2last==nil || type(sec2last)=="boolean" then
			if sec2last!=nil then bSameLocation=sec2last end
			bPredict=last;
		
		--Only one bool was given
		else
			bSameLocation=last;
		end
	end
	
	local newStacks={};
	local total=0;
	local i=1;
	while type(arg[i])=="number" do
		arg[i]=math.floor(arg[i]);
		newStacks[i]=nil;
		
		--[[
		Can we split off the given number of items? We need to have at least 1 and need to be able to subtract that much from the stack.
		The CanSplit event will have the final say in wheter a split can happen
		]]--
		if arg[i]>0 && self:SubAmount(total+arg[i],nil,true) && self:Event("CanSplit",true,howMany) then
			
			--Split the item. We'll create in same location as this stack if told to, or in the void if not told to.
			if bSameLocation then	newStacks[i]=IF.Items:CreateSameLocation(self:GetType(),self,nil,bPredict);
			else					newStacks[i]=IF.Items:Create(self:GetType(),nil,false,nil,bPredict);
			end
			
			if newStacks[i] then
				--TODO this method of dealing with failed SetAmounts sucks, redo it
				if !newStacks[i]:SetAmount(arg[i],nil,bPredict) && !bPredict then
					newStacks[i]:Remove();
				else
					--Update the total amount of items to subtract
					total=total+arg[i];
					
					if !bPredict then
						--New stack created, call our hook to indicate it was successful.
						self:Event("OnSplit",nil,newStacks[i],howMany);
						
						--New stack created, call it's hook so it can decide what to do next.
						newStacks[i]:Event("OnSplitFromStack",nil,self,howMany);
					end
				end
			end
		end
		
		i=i+1;
	end
	
	--Subtract the total number of items moved from the master stack (doing it here rather than for each thing saves bandwidth)
	self:SubAmount(total,nil,bPredict);
	
	return unpack(newStacks);
end
IF.Items:ProtectKey("Split");




if SERVER then




--[[
Set max number of items in the stack.
Give 0 for maxamount to allow an unlimited number of items in the stack.
Give 1 for maxamount to indicate that this item is not a stack
]]--
function ITEM:SetMaxAmount(maxamount)
	return self:SetNWInt("MaxAmount",maxamount);
end
IF.Items:ProtectKey("SetMaxAmount");




end