--[[
Itemforge Item Health
SHARED

This file contains functions related to the health of items.
]]--

ITEM.MaxHealth=100;									--How much health does a single item in the stack have when at full health (by default - this can be changed with SetMaxHealth())?

--[[
* SHARED
* Protected

Get HP of the top item in stack (the items beneath it are assumed to be at full health)
]]--
function ITEM:GetHealth()
	return self:GetNWInt("Health");
end
IF.Items:ProtectKey("GetHealth");

--[[
* SHARED
* Protected

Get the max HP of an item in the stack (they all have the same Max HP)
If the max HP is 0, the item(s) are invincible
]]--
function ITEM:GetMaxHealth()
	return self:GetNWInt("MaxHealth");
end
IF.Items:ProtectKey("GetMaxHealth");

--[[
* SHARED
* Protected

Returns whether or not the item is invincible (does not take damage, doesn't use HP).
]]--
function ITEM:IsInvincible()
	return self:GetMaxHealth()==0;
end
IF.Items:ProtectKey("IsInvincible")

--[[
* SHARED
* Protected

Hurt the top item on the stack however many points you want.
Serverside, this will actually damage the item (reduce it's health), but it can be used clientside for prediction if you want.
who is an optional entity that will be credited with causing damage to this item.

ITEM.Damage is the same thing as ITEM.Hurt
]]--
function ITEM:Hurt(pts,who)
	if !pts then return self:Error("Couldn't hurt/damage item, hitpoints to remove from item not given!\n") end
	if pts<0 then pts=0 end
	self:SetHealth(self:GetHealth()-pts,who);
end
IF.Items:ProtectKey("Hurt");
ITEM.Damage=ITEM.Hurt;
IF.Items:ProtectKey("Damage");

--[[
* SHARED
* Protected

Heals the top item on the stack however many points you want.
Serverside, this will actually heal the item, but clientside it can be used for prediction.
who is an optional entity that will be credited with healing the item.
]]--
function ITEM:Heal(pts,who)
	if !pts then self:Error("Couldn't heal/repair item, hitpoints to restore item not given!\n") end
	if pts<0 then pts=0 end
	self:SetHealth(self:GetHealth()+pts,who);
end
IF.Items:ProtectKey("Heal");
ITEM.Repair=ITEM.Heal;
IF.Items:ProtectKey("Repair");

if SERVER then




--[[
* SHARED
* Protected

Set HP of top item in stack
hp is the health to set the item to. If this value exceeds the max HP, it is clamped down to the max HP.
	A value of -maxhp*i will subtract i+1 items, where i is a number from 0 to infinity.
	e.g. Lets say the max health of each item in a stack is 100.
	Setting the health to 0 subtracts 1 item,
	Setting health to -100 subtracts 2 items,
	Setting health to -125 subtracts 2 items and subtracts 25 health from the next item in the stack.

who is the player or entity who changed the HP (who damaged or repaired it).

This function will call the "OnBreak" event if items are subtracted (assumed the item is destroyed by something).

TODO optimize
]]--
function ITEM:SetHealth(hp,who)
	local maxhp=self:GetMaxHealth();
	if hp>maxhp then hp=maxhp end	--HP can't exceed the max health, but it 
	
	local shouldUp=true;
	
	if hp<=0 && maxhp!=0 then		--If HP falls at or below 0, subtract from the stack. Unless the item is invincible, of course.
		--[[
		If maxhealth is 100
		and hp is set to -92
		
		-92/100 = -.92
		floored to 0
		1 subtracted
		-1
		
		1 item will be removed
		
		(1*100)-92
		New HP will be 8
		
		hp is set to -100?
		-100/100 = -1
		floored to -1
		1 subtracted
		-2
		
		2 items will be removed
		-(-2*100)-100 = 100
		
		New HP will be 100
		]]--
		
		local SubtractHowMany=math.floor(hp/maxhp)-1;
		local Remainder=(-(SubtractHowMany*maxhp))+hp;
		
		hp=Remainder;
		
		local totalLoss=-SubtractHowMany;
		if totalLoss > self:GetAmount() then
			totalLoss=self:GetAmount();
		end
		
		--TODO this old code needs to be reworked slightly
		self:Event("OnBreak",nil,totalLoss,(totalLoss==self:GetAmount()),who);
		
		if !self:IsValid() then return end

		shouldUp=self:SetAmount(math.max(0,self:GetAmount()+SubtractHowMany));
	elseif hp>self:GetMaxHealth() then
		hp=self:GetMaxHealth();
	end
	
	--Update the client with this item's health - if there are no items left (all destroyed) don't bother.
	if shouldUp==true then
		self:SetNWInt("Health",hp);
	end
end
IF.Items:ProtectKey("SetHealth");

--[[
* SHARED
* Protected

Set max health of all items in the stack.

maxhp is the amount to set the HP to. If maxhp is 0, the item becomes invincible.

If the health of the item is greater than the given max health, it is brought down to the max health.
Likewise, if the item was formerly invincible, the hp is set to the maxhealth.
]]--
function ITEM:SetMaxHealth(maxhp)
	local hp=self:GetHealth();
	local oldmax=self:GetMaxHealth();
	
	self:SetNWInt("MaxHealth",maxhp);
	
	if oldmax==0 || hp > maxhp then self:SetHealth(maxhp) end
end
IF.Items:ProtectKey("SetMaxHealth");




else




--[[
* SHARED
* Protected

Set HP of top item in stack
]]--
function ITEM:SetHealth(hp)
	if hp<0 then		--Keep health in range clientside
		hp=0;
	elseif hp>self:GetMaxHealth() then
		hp=self:GetMaxHealth();
	end
	
	self:SetNWInt("Health",hp);
end
IF.Items:ProtectKey("SetHealth");




end