--[[
base_ranged
CLIENT

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ranged has two purposes:
	It's designed to help you create ranged weapons easier. You just have to change/override some variables or replace some stuff with your own code.
	You can tell if an item is a ranged weapon (like a pistol or RPG) by checking to see if it inherits from base_ranged.
Some features the base_ranged has:
	Ammunition: 
		You can load base_ranged weapons with other items
		The primary/secondary attack consumes ammo from a clip you set (you can also set primary/secondary not to consume ammo)
		You can specify how many clips you want your weapon to have (including none).
		You can specify what type of ammo goes in a clip and how much can be loaded into it at a given time (including no limit)
		If ammo is drag-dropped onto the item, it loads it with that ammo; if two or more clips use the same kind of ammo, then it will load whichever clip is empty first.
		A list of reload functions let you set up where the item looks for ammo when it reloads.
	Cooldowns:
		This is based off of base_weapon so you can set primary/secondary delay and auto delay
		You can set a reload delay
		You can set "out of ammo" delays for primary/secondary (for example, the SMG's primary has a 0.08 second cooldown, but if you're out of ammo, it has a 0.5 second cooldown instead)
	Other:
		The item's right click menu has several functions for dealing with ranged weapons; you can fire it's primary/secondary, unload clips, reload, etc, all from the menu.
		Wiremod can fire the gun's primary/secondary attack. It can also reload the gun, if there is ammo nearby.
]]--

include("shared.lua");

local cDefaultBack=Color(200,150,0,255);
local cDefaultBar =Color(255,204,0,255);
local cDefaultLow =Color(255,0,0,255);

function ITEM:OnThink()
	if self:GetNWBool("InReload")==true then
		self:Reload();
	end
end

--Sets the ammo in the given clip to the given item no questions asked
function ITEM:SetClip(item,clip)
	self.Clip[clip]=item;
	
	return true;
end

--Unloads the ammo in the given clip.
function ITEM:Unload(clip)
	self.Clip[clip]=nil;
	
	return true;
end

--Clientside this does not take ammo; it's just so you can have TakeAmmo in a shared function without it generating errors clientside.
function ITEM:TakeAmmo(amt,clip)
	return true;
end

--[[
Runs when a player wants to load this weapon with the given ammo (currently this is used when ammo is drag-dropped here).
It doesn't actually load the ammo clientside; it requests the server to load the given ammo.
There are a few checks here that can stop un-necessary requests from being sent:
	We can make sure the player can interact with the gun
	We can check if the given ammo is loadable into any clips clientside
pl is the player who wants to load ammo; if this isn't the same as LocalPlayer() we fail (because it's this player who wants to load ammo, right?)
ammo is the item we want to load.
]]--
function ITEM:PlayerLoadAmmo(pl,ammo)
	if !self:CanPlayerInteract(pl) then return false end
	for i=1,table.getn(self.Clips) do
		if self:CanLoadClipWith(ammo,i) then return self:SendNWCommand("PlayerLoadAmmo",ammo); end
	end
end

--We have a nice menu for ranged weapons!
function ITEM:OnPopulateMenu(pMenu)
	--We've got everything the base weapon has and more!
	self["base_weapon"].OnPopulateMenu(self,pMenu);
	
	--Options to fire gun
	pMenu:AddOption("Fire Primary",		function(panel)	self:SendNWCommand("PlayerFirePrimary")		end);
	pMenu:AddOption("Fire Secondary",	function(panel)	self:SendNWCommand("PlayerFireSecondary")	end);
	
	--Options to unload ammo
	local hasEmptyClip=false;
	for i=1,table.getn(self.Clips) do
		local ammo=self:GetAmmo(i);
		if ammo then
			local amt=ammo:GetAmount();
			if amt<self.Clips[i].Size then hasEmptyClip=true end
			
			--Who says that gun ammo has to be a stack (e.g. bullets)? It could be a single item as far as we know (e.g. a battery, in the case of energy weapons)
			local ammoStr=ammo:GetName();
			if ammo:GetMaxAmount()!=1 then ammoStr=ammoStr.." x "..amt; end
			
			pMenu:AddOption("Unload "..ammoStr,function(panel)	self:SendNWCommand("PlayerUnloadAmmo",i)	end);
		else
			hasEmptyClip=true;
		end
	end
	
	--If we're holding ammo, we can load it on the right click menu
	--TODO more than one clip
	local wep=LocalPlayer():GetActiveWeapon();
	if wep:IsValid() then
		local ammo=IF.Items:GetWeaponItem(wep);
		if self:CanLoadClipWith(ammo,1) then
			local ammoStr=ammo:GetName();
			if ammo:IsStack() then ammoStr=ammoStr.." x "..ammo:GetAmount(); end
			
			pMenu:AddOption("Load "..ammoStr,function(panel) return self:SendNWCommand("PlayerLoadAmmo",ammo); end);
		end
	end
	
	--Option to reload an empty clip
	if hasEmptyClip then pMenu:AddOption("Reload",	function(panel)	self:SendNWCommand("PlayerReload")			end); end
end

--If usable ammo is dragged here we ask the server to load it
function ITEM:OnDragDropHere(otherItem)
	self:PlayerLoadAmmo(LocalPlayer(),otherItem);
	return false;
end

--Draw ammo bar(s)
function ITEM:OnDraw2D(width,height)
	self["base_weapon"].OnDraw2D(self,width,height);
	local c=0;
	
	for i=table.getn(self.Clips),1,-1 do
		local ammo=self:GetAmmo(i);
		if self:DrawAmmoMeter(width-5-(2*c),4,2,height-8,((ammo&&ammo:GetAmount())||0),self.Clips[i].Size,self.Clips[i].BackColor||cDefaultBack,self.Clips[i].BarColor||cDefaultBar,self.Clips[i].LowColor||cDefaultLow) then
			c=c+1;
		end
	end
end

--[[
Draws an ammo meter whose top-left corner is at <x,y> and whose width/height is w,h respectively.
This ammo meter "drains" from top to bottom.
This function is intended for use in Draw2D but it probably works in any 2D drawing cycle
iAmmo is how much ammo is in the clip.
iMaxAmmo is the total ammo that can be stored in the clip.
cBack is the color of the bar's background (the "empty" part of the bar).
cBar is the color of the bar itself (the "full" part of the bar).
cBarLow is the color of the bar when we're low on ammo.
	We'll flash between barColor and lowBarColor if we're at 20% ammo or less.

Returns true if an ammo meter was drawn.
Returns false if an ammo meter couldn't be drawn (probably because iMaxAmmo was 0; with unlimited ammo, how do you expect me to draw a bar showing how much has been used?)
]]--
function ITEM:DrawAmmoMeter(x,y,w,h,iAmmo,iMaxAmmo,cBack,cBar,cBarLow)
	--Ammo bars show how full a clip is; if a clip can hold limitless ammo don't bother drawing
	if iMaxAmmo==0 then return false end
	
	--Draw the background for an ammo bar
	surface.SetDrawColor(cBack.r,cBack.g,cBack.b,cBack.a);
	surface.DrawRect(x,y,w,h);
	
	--If we don't have any ammo, don't draw an ammo bar; all we'll see is the background indicating the clip is empty
	if iAmmo==0 then return true end
	
	local r=(iAmmo/iMaxAmmo);
	local f=math.Clamp(r*h,0,h);
	
	--Blink like crazy if we're running low on ammo
	if r<=0.2 then
		local br=(math.sin(CurTime()*10)+1)*.5;
		surface.SetDrawColor(cBar.r+((cBarLow.r-cBar.r)*br),cBar.g+((cBarLow.g-cBar.g)*br),cBar.b+((cBarLow.b-cBar.b)*br),cBar.a+((cBarLow.a-cBar.a)*br));
	else
		surface.SetDrawColor(cBar.r,cBar.g,cBar.b,cBar.a);
	end
	
	--Draw the ammo bar
	surface.DrawRect(x,y+h-f,w,f);
	
	return true;
end

IF.Items:CreateNWCommand(ITEM,"SetClip",function(self,...) self:SetClip(...) end,{"item","int"});
IF.Items:CreateNWCommand(ITEM,"Unload",function(self,...) self:Unload(...) end,{"int"});
IF.Items:CreateNWCommand(ITEM,"PlayerFirePrimary",nil,{});
IF.Items:CreateNWCommand(ITEM,"PlayerFireSecondary",nil,{});
IF.Items:CreateNWCommand(ITEM,"PlayerReload",nil,{});
IF.Items:CreateNWCommand(ITEM,"PlayerLoadAmmo",nil,{"item"});
IF.Items:CreateNWCommand(ITEM,"PlayerUnloadAmmo",nil,{"int"});