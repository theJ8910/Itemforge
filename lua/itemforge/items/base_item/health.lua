--[[
Itemforge Item Health
SHARED

This file contains functions related to the health of items.
]]--

ITEM.MaxHealth		= 100;								--How much health does a single item in the stack have when at full health (by default - this can be changed with SetMaxHealth())?

--[[
* SHARED
* Protected

Get the health of the top item in stack (the items beneath it are assumed to be at full health)
]]--
function ITEM:GetHealth()
	return self:GetNWInt( "Health" );
end
IF.Items:ProtectKey( "GetHealth" );

--[[
* SHARED
* Protected

Get the max health of an item in the stack (they all have the same max health)
If the max health is 0, the item(s) are invincible
]]--
function ITEM:GetMaxHealth()
	return self:GetNWInt( "MaxHealth" );
end
IF.Items:ProtectKey( "GetMaxHealth" );

--[[
* SHARED
* Protected

Returns whether or not the item is invincible (does not take damage, doesn't use health).
]]--
function ITEM:IsInvincible()
	return self:GetMaxHealth() == 0;
end
IF.Items:ProtectKey( "IsInvincible" );

--[[
* SHARED
* Protected

Hurt the top item on the stack however many points you want.
Serverside, this will actually damage the item (reduce it's health), but it can be used clientside for prediction if you want.

iPts is the amount of health to subtract from the item.
eWho is an optional entity that will be credited with causing damage to this item.

ITEM.Damage is the same thing as ITEM.Hurt
]]--
function ITEM:Hurt( iPts, eWho )
	if !iPts then return self:Error( "Couldn't hurt/damage item, health to remove from item not given!\n" ) end
	if iPts < 0 then iPts = 0 end

	self:SetHealth( self:GetHealth() - iPts, eWho );
end
IF.Items:ProtectKey( "Hurt" );
ITEM.Damage = ITEM.Hurt;
IF.Items:ProtectKey( "Damage" );

--[[
* SHARED
* Protected

Heals the top item on the stack however many points you want.
Serverside, this will actually heal the item, but clientside it can be used for prediction.

iPts is the amount of health to add to the item.
eWho is an optional entity that will be credited with healing the item.
]]--
function ITEM:Heal( iPts, eWho )
	if !iPts then self:Error( "Couldn't heal/repair item, health to restore to the item not given!\n" ) end
	if iPts < 0 then iPts = 0 end
	self:SetHealth( self:GetHealth() + iPts, eWho );
end
IF.Items:ProtectKey( "Heal" );
ITEM.Repair = ITEM.Heal;
IF.Items:ProtectKey( "Repair" );

if SERVER then




--[[
* SERVER
* Protected

Sets the health of the top item in the stack.

This function will call the "OnBreak" event if items are subtracted. (The code assumes the item has been destroyed by something if zero or negative health is given).

iHealth is the health to set the item to. If this value exceeds the max health, it is clamped down to the max health.
	A value of -maxhealth * i will subtract i + 1 items, where i is a number from 0 to infinity.
	e.g. Lets say the max health of each item in a stack is 100.
	Setting the health to 0 subtracts 1 item,
	Setting health to -100 subtracts 2 items,
	Setting health to -125 subtracts 2 items and subtracts 25 health from the next item in the stack.

eWho is the player or entity who changed the HP (who damaged or repaired the item).

TODO optimize
]]--
function ITEM:SetHealth( iHealth, eWho )
	local iMaxHealth = self:GetMaxHealth();
	
	if iHealth <= 0 && iMaxHealth != 0 then				--If health falls at or below 0, subtract from the stack. Unless the item is invincible, of course.

		--[[
		To determine how many items will be subtracted, first we divide the new health by the max health of the top item to get an idea
		how the new health differs from the normal health of a single item. Because we know the new health is negative or zero, we'll get a negative or zero ratio.

		Since a value of 1 indicates the top item is 100% healthy, a value of 0 indicates the top item lost all of it's health.
		Negative values indicate that not only was the top item blown away but the items beneath it suffered damage as well.
		For instance, -0.5 indicates the top item lost all it's health, and then the item beneath it lost half of it's health.
		Or, it could be -1, indicating that the top two items in the stack lost their all of their health.

		We need to come up with some way of turning this ratio into an actual number of items to be removed.
		Luckily, there is a way.
		
		math.ceil returns 0 for the range [0, -1), returns -1 for [-1, -2), and so on.
		By taking 1, then subtracting the ceil of the ratio we found earlier,
		we can get the proper number of items that should be subtracted.

		For instance, -1, when math.ceil()ed, produces -1. Taking 1, then subtracting -1, produces 2; the correct # of items to be removed. 
		Or, -0.5, when math.ceil()ed, produces 0. Taking 1 and subtracting 0 produces 1, again the correct # of items to be removed.
		]]--
		local iSubtractHowMany = 1 - math.ceil( iHealth / iMaxHealth );
		iHealth = iHealth + iSubtractHowMany * iMaxHealth;
		
		local iCurrentAmount = self:GetAmount();
		if iSubtractHowMany > iCurrentAmount then
			iSubtractHowMany = iCurrentAmount;
		end
		
		--TODO this old code needs to be reworked slightly
		local r, s = self:Event( "OnBreak", nil, iSubtractHowMany, ( iSubtractHowMany == iCurrentAmount ), eWho );

		if !self:IsValid() then return end

		self:SetAmount( iCurrentAmount - iSubtractHowMany );
		if !self:IsValid() then return end

	elseif iHealth > iMaxHealth then

		iHealth = iMaxHealth;

	end
	
	self:SetNWInt( "Health", iHealth );
end
IF.Items:ProtectKey( "SetHealth" );

--[[
* SERVER
* Protected

Set max health of all items in the stack.

iMaxHealth is the amount to set the max health to.
	If this is 0, the item becomes invincible.

If the new max health is lower than the current health of the item, the item's health is brought down to the max health.
Likewise, if the item was formerly invincible, the health is set to the max health.
]]--
function ITEM:SetMaxHealth( iMaxHealth )
	local iHealth = self:GetHealth();
	local iOldMax = self:GetMaxHealth();
	
	self:SetNWInt( "MaxHealth", iMaxHealth );
	
	if iOldMax == 0 || iMaxHealth < iHealth then self:SetHealth( iMaxHealth ) end
end
IF.Items:ProtectKey( "SetMaxHealth" );




else




--[[
* CLIENT
* Protected

Sets the health of the top item in the stack.
Cannot subtract items clientside.

iHealth is the health to set the item to.
	If this value exceeds the max health, it is clamped down to the max health.
	Likewise, if it's less than 0, it's set to 0.
]]--
function ITEM:SetHealth( iHealth )
	local iMaxHealth = self:GetMaxHealth();

	if iHealth < 0 then						iHP = 0;
	elseif iHealth > iMaxHealth then		iHP = iMaxHealth;
	end
	
	self:SetNWInt( "Health", iHealth );
end
IF.Items:ProtectKey( "SetHealth" );




end