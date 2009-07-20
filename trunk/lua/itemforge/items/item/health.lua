--[[
Itemforge Item Health
SHARED

This file contains functions related to the health of items.
]]--

ITEM.MaxHealth=100;									--How much health does a single item in the stack have when at full health (by default - this can be changed with SetMaxHealth())?

--[[
Get HP of the top item in stack (the items beneath it are assumed to be at full health)
]]--
function ITEM:GetHealth()
	return self:GetNWInt("Health");
end
IF.Items:ProtectKey("GetHealth");

--[[
Get the max HP of an item in the stack (they all have the same Max HP)
]]--
function ITEM:GetMaxHealth()
	return self:GetNWInt("MaxHealth");
end
IF.Items:ProtectKey("GetMaxHealth");

--[[
Hurt the top item on the stack however many points you want.
Serverside, this will actually damage the item (reduce it's health), but it can be used clientside for prediction if you want.
who is an optional entity that will be credited with causing damage to this item.

ITEM.Damage is the same thing as ITEM.Hurt
]]--
function ITEM:Hurt(pts,who)
	if !pts then ErrorNoHalt("Itemforge Items: Couldn't hurt/damage item, hitpoints to remove from item not given!\n") end
	if pts<0 then pts=0 end
	self:SetHealth(self:GetHealth()-pts,who);
end
IF.Items:ProtectKey("Hurt");
ITEM.Damage=ITEM.Hurt;
IF.Items:ProtectKey("Damage");

--[[
Heals the top item on the stack however many points you want.
Serverside, this will actually heal the item, but clientside it can be used for prediction.
who is an optional entity that will be credited with healing the item.
]]--
function ITEM:Heal(pts,who)
	if !pts then ErrorNoHalt("Itemforge Items: Couldn't heal/repair "..tostring(self)..", hitpoints to restore item not given!\n") end
	if pts<0 then pts=0 end
	self:SetHealth(self:GetHealth()+pts,who);
end
IF.Items:ProtectKey("Heal");
ITEM.Repair=ITEM.Heal;
IF.Items:ProtectKey("Repair");

if SERVER then




--[[
Set HP of top item in stack
who is the player or entity who changed the HP (who damaged or repaired it)
TODO optimize
]]--
function ITEM:SetHealth(hp,who)
	local shouldUp=true;
	if hp<=0 then		--If HP falls below 0, subtract from the stack.
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
		
		local SubtractHowMany=math.floor(hp/self:GetMaxHealth())-1;
		local Remainder=(-(SubtractHowMany*self:GetMaxHealth()))+hp;
		
		hp=Remainder;
		
		local totalLoss=-SubtractHowMany;
		if totalLoss > self:GetAmount() then
			totalLoss=self:GetAmount();
		end
		
		--TODO this old code needs to be reworked slightly
		self:Event("OnBreak",nil,totalLoss,(totalLoss==self:GetAmount()),who);
		
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
Set max health of all items in the stack.
]]--
function ITEM:SetMaxHealth(maxhp)
	self:SetNWInt("MaxHealth",maxhp);
end
IF.Items:ProtectKey("SetMaxHealth");




else




--Set HP of top item in stack
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