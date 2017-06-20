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
		You can set how much ammo the primary/secondary consumes per shot
		You can specify how many clips you want your weapon to have (including none).
		You can specify what type of ammo goes in a clip and how much can be loaded into it at a given time (including no limit)
		If ammo is drag-dropped onto the item, it loads it with that ammo; if two or more clips use the same kind of ammo, then it will load whichever clip is empty first.
		A list of reload functions let you set up where the item looks for ammo when it reloads.
	Cooldowns:
		This is based off of base_weapon so you can set primary/secondary delay and auto delay
		You can set a reload delay
		You can set a "dry delay" for when the gun is out of ammo or underwater (for example, the SMG's primary has a 0.08 second cooldown, but if you're out of ammo, it has a 0.5 second cooldown instead)
	Other:
		The item's right click menu has several functions for dealing with ranged weapons; you can fire it's primary/secondary, unload clips, reload, etc, all from the menu.
		Wiremod can fire the gun's primary/secondary attack. It can also reload the gun, if there is ammo nearby.
		You can set whether or not you want the gun's primary/secondary to work underwater
]]--

include( "shared.lua" );

--[[
* CLIENT
* Event

We have a nice menu for ranged weapons!
]]--
function ITEM:OnPopulateMenu( pnlMenu )
	--We've got everything the base weapon has and more!
	self:BaseEvent( "OnPopulateMenu", nil, pnlMenu );
	

	--Options to fire gun
								pnlMenu:AddOption( "Fire Primary",		function( pnl )	self:SendNWCommand( "PlayerFirePrimary" )	end );
								pnlMenu:AddOption( "Fire Secondary",	function( pnl )	self:SendNWCommand( "PlayerFireSecondary" )	end );
	

	--Options to unload ammo
	local bHasEmptyClip = false;
	for i = 1, #self.Clips do
		local itemCurAmmo = self:GetAmmoSource( i );
		if itemCurAmmo then
			local iAmt = itemCurAmmo:GetAmount();
			if iAmt < self.Clips[i].Size then bHasEmptyClip = true end
			
			--Who says that gun ammo has to be a stack (e.g. bullets)? It could be a single item as far as we know (e.g. a battery, in the case of energy weapons)
			local strAmmo = itemCurAmmo:Event( "GetName", "Unknown Ammo" );
			if itemCurAmmo:IsStack() then strAmmo = strAmmo.." x "..iAmt end
			
								pnlMenu:AddOption( "Unload "..strAmmo,	function( pnl )	self:PlayerUnloadAmmo( LocalPlayer(), i )	end );
		else
			bHasEmptyClip = true;
		end
	end
	
	--If we're holding ammo, we can load it on the right click menu
	--TODO more than one clip
	local itemHeldAmmo = IF.Items:GetWeaponItem( LocalPlayer():GetActiveWeapon() );
	if self:CanLoadClipWith( itemHeldAmmo, 1 ) then
		local strAmmo = IF.Util:LabelSanitize( itemHeldAmmo:Event( "GetName", "Unknown Ammo" ) );
		if itemHeldAmmo:IsStack() then strAmmo = strAmmo.." x "..itemHeldAmmo:GetAmount() end
			
								pnlMenu:AddOption( "Load "..strAmmo,	function( pnl ) self:PlayerLoadAmmo( LocalPlayer(), itemHeldAmmo, 1 ) end );
	end
	
	--Option to reload an empty clip
	if bHasEmptyClip then		pnlMenu:AddOption( "Reload",			function( pnl )	self:PlayerReload( LocalPlayer() )		end ); end
end

--[[
* CLIENT
* Event

If usable ammo is dragged here we ask the server to load it
]]--
function ITEM:OnDragDropHere( otherItem )
	return !self:PlayerLoadAmmo( LocalPlayer(), otherItem );
end

--[[
* CLIENT
* Event

Draw ammo bar(s)
]]--
function ITEM:OnDraw2D( fWidth, fHeight )
	self:BaseEvent( "OnDraw2D", nil, fWidth, fHeight );
	local c = 0;
	
	if self.PrimaryClip != 0 then

		local itemCurAmmo = self:GetAmmoSource( self.PrimaryClip );
		if itemCurAmmo != nil then
			itemCurAmmo:DrawIcon( fWidth - 26, fHeight - 20, 16, 16 );

			surface.SetFont( "ConsoleText" );
			local strAmt = tostring( self:GetAmmo( 1 ) );
			
			local c = self:GetClipBarColor( self.PrimaryClip );
			surface.SetTextColor( c.r, c.g, c.b, c.a );
			surface.SetTextPos( fWidth - 2 - surface.GetTextSize( strAmt ), fHeight - 12 );
			surface.DrawText( strAmt );
		end

	end

	for i = #self.Clips, 1, -1 do
		local itemCurAmmo = self:GetAmmoSource( i );
		--4, 2, h-8
		if self:DrawAmmoMeter( fWidth - 5 - ( 2 * c ), 4, 2, fHeight - 16, self:GetAmmo( i ), self:GetMaxAmmo( i ), self:GetClipBackgroundColor( i ), self:GetClipBarColor( i ), self:GetClipLowColor( i ) ) then
			c = c + 1;
		end
	end
end

--[[
* CLIENT

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
function ITEM:DrawAmmoMeter( x, y, w, h, iAmmo, iMaxAmmo, cBack, cBar, cBarLow )
	--Ammo bars show how full a clip is; if a clip can hold limitless ammo don't bother drawing
	if iMaxAmmo == 0 then return false end
	
	--Draw the background for an ammo bar
	surface.SetDrawColor( cBack.r, cBack.g, cBack.b, cBack.a );
	surface.DrawRect( x, y, w, h );
	
	--If we don't have any ammo, don't draw an ammo bar; all we'll see is the background indicating the clip is empty
	if iAmmo == 0 then return true end
	
	local r = iAmmo / iMaxAmmo;
	local f = math.Clamp( r * h, 0, h );
	
	--Blink like crazy if we're running low on ammo
	if r <= 0.2 then
		local br = 0.5 * ( 1 + math.sin( 10 * CurTime() ) );
		surface.SetDrawColor( cBar.r + br * ( cBarLow.r - cBar.r ),
							  cBar.g + br * ( cBarLow.g - cBar.g ),
							  cBar.b + br * ( cBarLow.b - cBar.b ),
							  cBar.a + br * ( cBarLow.a - cBar.a )
							);
	else
		surface.SetDrawColor( cBar.r, cBar.g, cBar.b, cBar.a );
	end
	
	--Draw the ammo bar
	surface.DrawRect( x, y + h - f, w, f );
	
	return true;
end

IF.Items:CreateNWCommand( ITEM, "SetAmmoSource",		function( self, ... ) self:SetAmmoSource( ... ) end,	{ "int", "item" }	);
IF.Items:CreateNWCommand( ITEM, "Unload",				function( self, ... ) self:Unload( ... ) end,			{ "int" }			);
IF.Items:CreateNWCommand( ITEM, "PlayerFirePrimary",	nil,													{}					);
IF.Items:CreateNWCommand( ITEM, "PlayerFireSecondary",	nil,													{}					);
IF.Items:CreateNWCommand( ITEM, "PlayerReload",			nil,													{}					);
IF.Items:CreateNWCommand( ITEM, "PlayerLoadAmmo",		nil,													{ "int", "item" }	);
IF.Items:CreateNWCommand( ITEM, "PlayerUnloadAmmo",		nil,													{ "int" }			);