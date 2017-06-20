--[[
base_item
CLIENT

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/cl_init.lua, so this item's type is "base_item")
]]--

include( "shared.lua" );
include( "events_client.lua" );

local DefaultIcon = Material( "editor/env_cubemap" );

ITEM.Icon					= DefaultIcon;				--This used to be displayed in item slots (and probably still could) but for now it's only used in the weapon selection menu by default.
ITEM.UseModelFor2D			= true;						--If this is true, when displaying the item in an item slot, we'll create a model panel and display this item's world model in it. If this is false, no model panel is created.
ITEM.WorldModelNudge		= Vector( 0, 0, 0 );		--The item's world model is shifted by this amount relative to the player's right hand. This is only used if this item's world model is a non-standard weapon model (doesn't have a "ValveBiped.Bip01_R_Hand" bone like the HL2 pistol, crowbar, smg, etc).
ITEM.WorldModelRotate		= Angle( 0, 0, 0 );			--The item's world model is rotated by this amount relative to the player's right hand. This is only used if this item's world model is a non-standard weapon model (doesn't have a "ValveBiped.Bip01_R_Hand" bone like the HL2 pistol, crowbar, smg, etc).

--Don't modify/override these. They're either set automatically or don't need to be changed.
ITEM.RCMenu					= nil;						--Our right click menu (a DMenu).
ITEM.ItemSlot				= nil;						--When the item is held, this will be a panel displaying this item.
ITEM.WMAttach				= nil;						--When the item is held, this will be an attached model (a GearAttach object specifically) attached to the player's right hand.
ITEM.OverrideMaterialMat	= nil;						--On the client this is a Material() whose path is the item's override material (item:GetOverrideMaterial()). Use item:GetOverrideMaterialMat() to get this.
ITEM.ObserverPanels			= nil;						--A panel that displays information about this item can observe this item. Whenever the item updates itself, the panel's Update() function is called.

local vZero					= Vector( 0, 0, 0 );
local vOne					= Vector( 1, 1, 1 );
local mWhite				= Material( "white_outline" );
local NIL					= "%%00";					--If a command isn't given, this is substituted. It means we want to send nil (nothing).
local SPACE					= "%%20";					--If a space is given in a string, this is substituted. It means " ".

--[[
* CLIENT
* Protected

You can use this in an OnDraw3D event to draw a 'glowing' outline around the model.
This is more or less the same code used by Garry's Mod entities that makes the outline appear around them when you look at them.

NOTE:
You should call DrawOutline before calling Draw, so the outline draws behind the model.

eEntity should be the entity whose model we are drawing an outline around, taken from OnDraw3D.
fThickness should be the thickness of the outline you want to draw.
cColor should be the color that you want to draw the outline.
]]--
function ITEM:DrawOutline( eEntity, fThickness, cColor )
	render.SuppressEngineLighting( true );
	render.SetAmbientLight( 1, 1, 1 );
	render.SetColorModulation( cColor.r / 255, cColor.g / 255, cColor.b / 255 );
	SetMaterialOverride( mWhite );
	eEntity:SetModelScale( Vector( fThickness, fThickness, fThickness ) );
	
	eEntity:DrawModel();
	
	eEntity:SetModelScale( vOne );
	SetMaterialOverride( nil );
	render.SuppressEngineLighting( false );
end
IF.Items:ProtectKey( "DrawOutline" );

--[[
* CLIENT
* Protected

You can use this in an OnDraw3D event to draw the item's model.

NOTE:
You should use this function instead of calling eEntity:Draw() in OnDraw3D.

In addition to drawing the model, this function automatically colorizes
and/or changes the material of the model if a custom color/material is set.

eEntity should be the entity whose model we are drawing, taken from OnDraw3D.
]]--
function ITEM:Draw( eEntity )
	--The color/transparency of the drawn model changes if the item has a custom color
	local c = self:GetColor();
	render.SetColorModulation( c.r / 255, c.g / 255, c.b / 255 );
	render.SetBlend( c.a / 255 );

	--The material of the model changes if the item has a custom material
	SetMaterialOverride( self:GetOverrideMaterialMat() );

	eEntity:DrawModel();

	SetMaterialOverride( nil );
end
IF.Items:ProtectKey( "Draw" );

--[[
* CLIENT
* Protected

You can use this in a 2D drawing event (like the item's OnDraw2D) to draw the item's icon.

If the item has a custom color, this draws the item's icon in that color (including transparency).

fX and fY should be the position to draw the icon.
fWidth and fHeight should be the size to draw the icon.
fBaseAlpha is an optional number between 0-255 that defaults to 255.
	This will be how opaque the icon is drawn when the item's custom color is 100% opaque, i.e. when it has an alpha of 255.
	If the item's custom color has transparency, the transparency is subtracted from this number.
	For instance, if we set BaseAlpha to 200, and the item's color has an alpha of 245, the final
	alpha will be 190 (because 200 - (255 - 245) = 200 - 10 = 190).
]]--
function ITEM:DrawIcon( fX, fY, fWidth, fHeight, fBaseAlpha )
	if fBaseAlpha == nil then fBaseAlpha = 255 end

	local icon = self:Event( "GetIcon", DefaultIcon );

	local c = self:GetColor();
	surface.SetMaterial( icon );
	surface.SetDrawColor( c.r, c.g, c.b, fBaseAlpha - (255 - c.a) );
	surface.DrawTexturedRect( fX, fY, fWidth, fHeight );
end
IF.Items:ProtectKey( "DrawIcon" );

--[[
* CLIENT
* Protected

This is /more or less/ the same as DrawIcon above (there are some exceptions).
Only use this if you HAVE to rotate the icon; it tends to be less efficient than the regular DrawIcon.

fX and fY should be the position to draw the icon
	NOTE: Unlike DrawIcon, the icon's CENTER will be drawn here, rather than the upper-left corner.
fWidth and fHeight should be the size to draw the icon.
fRotationInDegrees should be the amount of (counter-clockwise) rotation you want to apply to the icon, in degrees.
fBaseAlpha is an optional number between 0 - 255 that defaults to 255.
	See the above function for additional details on this parameter.
]]--
function ITEM:DrawIconRotated( fX, fY, fWidth, fHeight, fRotationInDegrees, fBaseAlpha )
	if fBaseAlpha == nil then fBaseAlpha = 255 end

	local icon = self:Event( "GetIcon", DefaultIcon );

	local c = self:GetColor();
	surface.SetMaterial( icon );
	surface.SetDrawColor( c.r, c.g, c.b, fBaseAlpha - (255 - c.a) );
	surface.DrawTexturedRectRotated( fX, fY, fWidth, fHeight, fRotationInDegrees );

end
IF.Items:ProtectKey( "DrawIconRotated" );

--[[
* CLIENT
* Protected
* Internal

Creates gear to display the item's world model in the player's hands after the item is held.
]]--
function ITEM:CreateSWEPWorldModel( pl, eWeapon )

	--If the weapon isn't out when OnHold gets called, we need to hide the world model and item slot
	local bNotOut = ( pl:GetActiveWeapon() != eWeapon );
	
	--Create world model
	if !self.WMAttach then

		--First we create the gear, attached to the holding player
		self.WMAttach = IF.GearAttach:Create( self:GetWOwner(), self:GetWorldModel() );
		if self.WMAttach then
			self.WMAttach:SetOffset( self.WorldModelNudge );
			self.WMAttach:SetOffsetAngles( self.WorldModelRotate );
			self.WMAttach:SetDrawFunction( function( eEnt ) return self:Event( "OnDraw3D", nil, eEnt, false ) end );
			
			--Hide if we're not out
			if bNotOut then self.WMAttach:Hide() end
			
			--We try to bone-merge first and if that fails we try to attach to the right-hand attachment point instead
			if !self.WMAttach:BoneMerge( "ValveBiped.Bip01_R_Hand" ) && !self.WMAttach:ToAP( "anim_attachment_RH" ) then
				--Otherwise we need to remove it since it can't be attached to anything
				self.WMAttach:Remove();
				self.WMAttach = nil;
			end
		else
			self.WMAttach = nil;
		end

	end
	
end
IF.Items:ProtectKey( "CreateSWEPWorldModel" );

--[[
* CLIENT
* Event

This is the default slot drop function for a held weapon's item slot

self is the item slot.
vDragObject is the dropped drag object.
]]--
local function SlotDrop( self, vDragObject )
	local item = self:GetItem();
	if !item then return false end
	
	--Can the dropped panel hold an item?
	local fnGetItem = vDragObject.GetItem;
	if !IF.Util:IsFunction( fnGetItem ) then return false end

	--Does the dropped panel have an item set, and is it different from this panel's item?
	local s, r = pcall( fnGetItem, vDragObject );
	if		!s				then ErrorNoHalt( ""..r.."\n" ); return false;
	elseif	!r || r == item then return false end
	
	--Call the dragdrop events.
	if item:Event( "OnDragDropHere", true, r ) then
		r:Event( "OnDragDropToItem", nil, item );
	end
	return true;
end

--[[
* CLIENT
* Protected
* Internal

Creates an item slot displayed in the upper-left corner after the item is held.
]]--
function ITEM:CreateItemSlot( pl, eWeapon )

	--If the weapon isn't out when OnHold gets called, we need to hide the world model and item slot
	local bNotOut = ( pl:GetActiveWeapon() != eWeapon );

	--Create item slot
	if !self.ItemSlot && pl == LocalPlayer() then
		local slot = vgui.Create( "ItemforgeItemSlot" );
		
		slot:SetSize( 64, 64 );
		slot:SetPos( 2, 2 );
		slot:SetDraggable( true );
		slot:SetDroppable( true );
		slot:SetItem( self );
		slot.OnDropHere = SlotDrop;
		
		if bNotOut then slot:SetVisible( false ); end
		
		self.ItemSlot = slot;
	end

end
IF.Items:ProtectKey( "CreateItemSlot" );

--[[
* CLIENT
* Protected

If a panel that is displaying the inventory this item is in
should be updated because of a change in this item, call this function.

For example, the ItemforgeInventory panel displays the total weight of items stored in an inventory.
If this item was stored in that inventory, and this item's weight or amount changed,
that would change the total weight stored in the inventory, and the panel displaying the inventory
would need to updated with the new weight.
]]--
function ITEM:UpdateContainer()
	local invContainer = self:GetContainer();
	if invContainer then invContainer:Update() end
end
IF.Items:ProtectKey( "UpdateContainer" );

--[[
* CLIENT
* Protected
* Internal

Transfer this item from one inventory to another.
This function is designed to save bandwidth.
Instead of sending two NWCommands, one to remove from an inventory, another to add to an inventory, only one NWCommand is run.
This function merely voids an item from the old inventory and inserts it into the new inventory.

invOld is the inventory the item is currently in.
invNew is the inventory the item is moving to.
iNewSlot is the new slot in the inventory the item is moving to.

true is returned if these operations were successful.
false is returned otherwise.
]]--
function ITEM:TransInventory( invOld, invNew, iNewSlot )
	if !IF.Util:IsInventory( invOld )	then return self:Error( "Could not transfer from one inventory to another clientside, old inventory given is not valid.\n" ) end
	if !IF.Util:IsInventory( invNew )	then return self:Error( "Could not transfer from "..tostring( invOld ).." to another inventory clientside, 'new' inventory given is not valid.\n" ) end
	if !IF.Util:IsNumber( iNewSlot )	then return self:Error( "Could not transfer item from "..tostring( invOld ).." to "..tostring( invNew ).." clientside! iNewSlot was not a valid number!\n" ) end
	
	if invOld != invNew && !self:ToVoid( false, invOld, nil, false ) then end
	if !self:ToInventory( invNew, iNewSlot, nil, nil, false ) then return false end
end
IF.Items:ProtectKey( "TransInventory" );

--[[
* CLIENT
* Protected
* Internal

Transfer from one slot to another.
This function is designed to save bandwidth.

inv should be the inventory the item is in.
iOldSlot should be the slot the item is currently in.
iNewSlot should be the slot the item is moving to.

true is returned if the move was successful.
false is returned otherwise.
]]--
function ITEM:TransSlot( inv, iOldSlot, iNewSlot )
	if !IF.Util:IsInventory( inv )						then return self:Error( "Could not transfer item from one slot to another clientside, inventory given is not valid.\n" ) end
	if !inv:MoveItem( self, iOldSlot, iNewSlot, false )	then return false end
end
IF.Items:ProtectKey( "TransSlot" );

--[[
* CLIENT
* Protected

Run this function to use the item.
It will trigger the OnUse event in the item.

NOTE: If OnUse returns false clientside, "I can't use this!" does not appear, it simply stops the item from being used serverside.
TODO: Possibly have the item used by something other than a player

If this function is run on the client, the OnUse event can stop it clientside. If it isn't stopped, it requests to Use the item on the server.

false is returned in three cases:
	The given player is invalid
	The given player is currently unable to use this item (CanPlayerInteract returned false)
	The item cannot be used or does not need to contact the server to be used (OnUse returned false).
Otherwise, true is returned.
]]--
function ITEM:Use( pl )
	if !IF.Util:IsPlayer( pl ) || !self:Event( "CanPlayerInteract", false, pl ) || !self:Event( "OnUse", true, pl ) then return false end
	
	--After the event allows the item to be used clientside, ask the server to use the item.
	self:SendNWCommand( "PlayerUse" );
	
	return true;
end
IF.Items:ProtectKey( "Use" );

--[[
* CLIENT
* Protected

Run this function to hold the item.
It requests to "Hold" the item on the server.

false is returned in two cases:
	The given player is invalid
	The given player is currently unable to use this item (CanPlayerInteract returned false)
Otherwise, true is returned.
]]--
function ITEM:PlayerHold( pl )
	if !IF.Util:IsPlayer( pl ) || !self:Event( "CanPlayerInteract", false, pl ) then return false end
	
	self:SendNWCommand( "PlayerHold" );
	
	return true;
end
IF.Items:ProtectKey( "PlayerHold" );

--[[
* CLIENT
* Protected

This is run when the player chooses "Examine" from his menu.
Prints some info about the item (name, amount, weight, health, and description) to the local player's chat.
]]--
function ITEM:PlayerExamine()
	
	local strAmt = "";
	if self:IsStack() then strAmt = " x "..self:GetAmount(); end
	
	local w = self:GetStackWeight();
	local strWeight;
	if w >= 1000 then	strWeight = ( w * 0.001 ).." kg"
	else				strWeight = w.." grams"
	end
	
	LocalPlayer():PrintMessage( HUD_PRINTTALK, self:Event( "GetName", "Error" )..strAmt );
	LocalPlayer():PrintMessage( HUD_PRINTTALK, "Total Weight: "..strWeight );
	local m = self:GetMaxHealth();
	if m != 0 then
		local h = self:GetHealth();
		LocalPlayer():PrintMessage( HUD_PRINTTALK, "Condition: "..math.Round( 100 * ( h / m ) ).."% ("..h.."/"..m..")" );
	end
	LocalPlayer():PrintMessage( HUD_PRINTTALK, self:Event( "GetDescription", "[Error getting description]" ) );
end
IF.Items:ProtectKey( "PlayerExamine" );

--[[
* CLIENT
* Protected

Returns this item's override material as a Material() (as opposed to GetOverrideMaterial() which returns the material as a string).
]]--
function ITEM:GetOverrideMaterialMat()
	return self.OverrideMaterialMat;
end
IF.Items:ProtectKey( "GetOverrideMaterialMat" );

--[[
* CLIENT
* Protected

Returns this item's right click menu if one is currently open.
]]--
function ITEM:GetMenu()
	if self.RCMenu && !self.RCMenu:IsValid() then
		self.RCMenu = nil;
	end
	return self.RCMenu;
end
IF.Items:ProtectKey( "GetMenu" );

--[[
* CLIENT
* Protected

Displays this item's right click menu, positioning one of the menu's corners at iX, iY.

true is returned if the menu is opened successfully.
false is returned if the menu could not be opened. One possible reason this may happen is if the
item's OnPopulateMenu event fails.
]]--
function ITEM:ShowMenu( iX, iY )
	self.RCMenu = DermaMenu();
	
	local strName = IF.Util:LabelSanitize( self:Event( "GetName", "Itemforge Item" ) );
	if self:IsStack() then strName = strName.." x "..self:GetAmount() end
	
	--Add header
	local h = vgui.Create( "ItemforgeMenuHeader" );
	h:SetText( strName );
	self.RCMenu:AddPanel( h );
	
	local r, s = self:Event( "OnPopulateMenu", nil, self.RCMenu );
	if !s then
		self.RCMenu:Remove();
		return false;
	end
	
	return self.RCMenu:Open( iX, iY );
end
IF.Items:ProtectKey( "ShowMenu" );

--[[
* CLIENT
* Protected

Removes the menu if it is open.

Returns true if the menu was open and was closed,
or false if there wasn't a menu open.
]]--
function ITEM:KillMenu()
	local menu = self:GetMenu();
	if !menu then return false end
	
	menu:Remove();
	self.RCMenu = nil;
	return true;
end
IF.Items:ProtectKey( "KillMenu" );

--[[
* CLIENT
* Protected

Opens a dialog window asking the player how evenly to split a stack of items.

pl should be LocalPlayer().

Returns false if the player cannot interact with the item (or splitting this item is otherwise impossible).
]]--
function ITEM:PlayerSplit( pl )
	if !self:Event( "CanPlayerInteract", false, pl ) || !self:Event( "CanPlayerSplit", true, pl ) then return false end
	
	--Can't split 1 item
	local amt = self:GetAmount();
	if amt == 1 then return false end
	
	local name = self:Event( "GetName", "Itemforge Item" );
	
	local Window = vgui.Create( "DFrame" );
		  Window:SetTitle( "Split "..name );
		  Window:SetDraggable( false );
		  Window:ShowCloseButton( false );
		  Window:SetBackgroundBlur( true );
		  Window:SetDrawOnTop( true );
	
	--The inner panel contains the following controls:
	local InnerPanel = vgui.Create( "DPanel", Window );
		  InnerPanel:SetPos( 0, 25 );
		
		--Instructions for how to use this window.
		local Text = Label( "Drag the slider to choose how even the split is:", InnerPanel );
			  Text:SizeToContents();
			  Text:SetWide( Text:GetWide() + 100 );
			  Text:SetContentAlignment( 5 );
			  Text:SetTextColor( Color( 255, 255, 255, 255 ) );
			  Text:SetPos( 0, 5 );
		
		--Text that displays a fraction like "50/50" or "25/75" that says how "even" the split is
		local Fraction = Label( "", InnerPanel );
			  Fraction:SizeToContents();
			  Fraction:SetContentAlignment( 5 );
			  Fraction:SetPos( 0, Text:GetTall() + 5 )
			  Fraction:SetWide( Text:GetWide() );
		
		--Text that displays the number of items that will stay in the original stack
		local Value1 = Label( "", InnerPanel );
			  Value1:SetFont( "ItemforgeInventoryFontBold" );
			  Value1:SetTextColor( Color( 255, 255, 0, 255 ) );
			  Value1:SetContentAlignment( 6 );
			  Value1:SetPos( 0, Text:GetTall() + Fraction:GetTall() + 10 )
			  Value1:SetWide( 50 );
		
		--Text that displays the number of items that will be split off into the new stack
		local Value2 = Label( "", InnerPanel );
			  Value2:SetFont( "ItemforgeInventoryFontBold" );
			  Value2:SetTextColor( Color( 255, 255, 0, 255 ) );
			  Value2:SetContentAlignment( 4 );
			  Value2:SetPos( 0, Text:GetTall() + Fraction:GetTall() + 10 )
			  Value2:SetWide( 50 );
		
		--Slider that controls how many items will be split.
		local Slider = vgui.Create( "DSlider", InnerPanel );
			  Slider:SetTrapInside( true );
			  Slider:SetImage( "vgui/slider" );
			  Slider:SetLockY( 0.5 );
			  Slider:SetSize( Text:GetWide() - 100, 13 );
			  Slider:SetPos( 0, Text:GetTall() + Fraction:GetTall() + 15 );
			  Derma_Hook( Slider, "Paint", "Paint", "NumSlider" );
			  
			  --Whenever the slider is moved, the Fraction and Stack Numbers will be updated with the correct numbers.
			  Slider.TranslateValues = function( self, x, y )
				local firstHalf		= math.ceil( amt * x );
				local secondHalf	= amt - firstHalf;
				local firstFrac		= math.ceil( x * 100 );
				local secondFrac	= 100 - firstFrac;
				
				Fraction:SetText( firstFrac.."/"..secondFrac );
				Value1:SetText( firstHalf );
				Value2:SetText( secondHalf );
				return x, y;
			end

	--The button panel contains the OK and Cancel buttons. The panel itself is mostly an organizational aid.
	local ButtonPanel = vgui.Create( "DPanel", Window )
		  local Button = vgui.Create( "DButton", ButtonPanel )
				Button:SetText( "OK" );
				Button:SizeToContents();
				Button:SetSize( Button:GetWide() + 20, 20 );		--Make the button a little wider than it's text
				Button:SetPos( 5, 5 )
				Button.DoClick = function( panel ) Window:Close(); self:SendNWCommand( "PlayerSplit", amt - math.ceil( amt * Slider:GetSlideX() ) ) end
		  local Button2 = vgui.Create( "DButton", ButtonPanel )
				Button2:SetText( "Cancel" );
				Button2:SizeToContents();
				Button2:SetSize( Button2:GetWide() + 20, 20 );		--Make the button a little wider than it's text
				Button2:SetPos( 10 + Button:GetWide(), 5 );
				Button2.DoClick = function( panel ) Window:Close(); end
		  ButtonPanel:SetSize( Button:GetWide() + Button2:GetWide() + 15, 30 );
	
	InnerPanel:SetSize( Text:GetWide(), Text:GetTall() + Fraction:GetTall() + Slider:GetTall() + 20 );
	
	Slider:CenterHorizontal();
	Slider:TranslateValues( 0.5, 0.5 );
	Value1:MoveLeftOf( Slider );
	Value2:MoveRightOf( Slider );
	
	Window:SetSize( InnerPanel:GetWide() + 10, InnerPanel:GetTall() + ButtonPanel:GetTall() + 38 );
	Window:Center();
	
	InnerPanel:CenterHorizontal();
	
	ButtonPanel:CenterHorizontal();
	ButtonPanel:AlignBottom( 8 );
	
	Window:MakePopup();
	Window:DoModal();
end
IF.Items:ProtectKey( "PlayerSplit" );

--[[
* CLIENT
* Protected
* Internal

Runs every time the client ticks.
]]--
function ITEM:Tick()
	--Set predicted network vars.
	if self.NWVarsThisTick then
		for k, v in pairs( self.NWVarsThisTick ) do
			self:SetNWVar( k, v );
		end
		self.NWVarsThisTick = nil;
	end
	
	self:Event( "OnTick" );
end
IF.Items:ProtectKey( "Tick" );

--[[
* CLIENT

Pose function.

You can run this in an item's Pose3D function to pose the item's model in an
item slot a certain way. Makes the model spin, and orients it such that it's local Z axis is always facing upwards.

eEntity is the ClientsideModel to rotate (should be passed from the event).
fSpeed is the speed that the model rotates (defaults to 20 degrees per second).
	Negative values make the item rotate in the opposite direction.
]]--
function ITEM:PoseUprightRotate( eEntity, fSpeed )
	if fSpeed == nil then fSpeed = 20 end
	
	local vMin, vMax = eEntity:GetRenderBounds();
	local vCenter = vMax - ( 0.5 * ( vMax - vMin ) );			--Center, used to position 
	eEntity:SetAngles( Angle( 0, fSpeed * ( RealTime() + self:GetRand() ), 0 ) );
	eEntity:SetPos( vZero - ( eEntity:LocalToWorld( vCenter ) - eEntity:GetPos() ) );
end

--[[
* CLIENT
* Protected

Sends a networked command by name with the supplied arguments
Clientside, this runs console commands (sending data to the server in the process)
]]--
function ITEM:SendNWCommand( strName, ... )
	local command = self.NWCommandsByName[strName];
	if command == nil			then return self:Error( "Couldn't send command \""..strName.."\", there is no NWCommand with this name on this item!\n" ) end
	if command.Hook != nil		then return self:Error( "Command \""..command.Name.."\" can't be sent clientside. It has a hook, meaning this command is recieved clientside, not sent.\n" ) end
	
	local arglist = {};
	
	--If our command sends data, then we need to send the appropriate type of data. It needs to be converted to string form though because we're using console commands.
	for i = 1, table.maxn( command.Datatypes ) do
		local v = command.Datatypes[i];
		if v == 1 || v == 2 || v == 3 || v == 4 || v == 12 || v == 13 || v == 14 then
			--numerical datatypes
			if arg[i] != nil then							arglist[i] = tostring( arg[i] );
			else											arglist[i] = NIL;
			end
		elseif v == 5 then
			--bool
			if arg[i]	  == true  then						arglist[i] = "t";
			elseif arg[i] == false then						arglist[i] = "f";
			else											arglist[i] = NIL;
			end
		elseif v == 6 then
			--str - We replace spaces in a string argument with %20 before sending them because we use spaces to seperate arguments
			if arg[i] != nil then							arglist[i] = string.gsub( arg[i], " ", SPACE );
			else											arglist[i] = NIL;
			end
		elseif v == 7 then
			--Entity
			if arg[i] != nil then							arglist[i] = tostring( arg[i]:EntIndex() );
			else											arglist[i] = NIL;
			end
		elseif v == 8 then
			--Vector
			if arg[i] != nil then							arglist[i] = arg[i].x..","..arg[i].y..","..arg[i].z;
			else											arglist[i] = NIL;
			end
		elseif v == 9 then
			--Angle
			if arg[i] != nil then							arglist[i] = arg[i].p..","..arg[i].y..","..arg[i].r;
			else											arglist[i] = NIL;
			end
		elseif v == 10 || v == 11 then
			--Item or inventory
			if arg[i] != nil && arg[i]:IsValid() then		arglist[i] = tostring( arg[i]:GetID() );
			else											arglist[i] = NIL;
			end
		elseif v == 0 then									arglist[i] = NIL;
		end
	end
	
	local argstring = string.Implode( " ", arglist );
	
	--DEBUG
	Msg( "OUT: Message Type: "..IFI_MSG_CL2SVCOMMAND.." ("..strName..") - Item: "..self:GetID().."\n" );
	
	RunConsoleCommand( "ifi", IFI_MSG_CL2SVCOMMAND, self:GetID() - 32768, self.NWCommandsByName[strName].ID - 128, argstring );
end
IF.Items:ProtectKey( "SendNWCommand" );

--[[
* CLIENT
* Protected

This function is called automatically, whenever a networked command from the server is received.
Clientside, msg will be a bf_read (a usermessage received from the server).
There's no need to override this, we'll call the hook the command is associated if there is one.
]]--
function ITEM:ReceiveNWCommand( msg )
	local commandid = msg:ReadChar() + 128;
	local command   = self.NWCommandsByID[commandid];
	
	if command == nil		then return self:Error( "Couldn't find a NWCommand with ID "..commandid..". Make sure commands are created in the same order BOTH serverside and clientside.\n" ) end
	if command.Hook == nil	then return self:Error( "Command \""..command.Name.."\" was received, but there is no Hook to run!\n" ) end
	
	--If our command sends data, then we need to receive the appropriate type of data.
	--We'll pass this onto the hook function.
	local hookArgs = {};
	if command.Datatypes then
		for i = 1, table.maxn( command.Datatypes ) do
			local v = command.Datatypes[i];
			
			if v == 1 then
				hookArgs[i] = msg:ReadLong();
			elseif v == 2 then
				hookArgs[i] = msg:ReadChar();
			elseif v == 3 then
				hookArgs[i] = msg:ReadShort();
			elseif v == 4 then
				hookArgs[i] = msg:ReadFloat();
			elseif v == 5 then
				hookArgs[i] = msg:ReadBool();
			elseif v == 6 then
				hookArgs[i] = msg:ReadString();
			elseif v == 7 then
				hookArgs[i] = msg:ReadEntity();
				if hookArgs[i] == nil then
					hookArgs[i] = NullEntity();
				end
			elseif v == 8 then
				hookArgs[i] = msg:ReadVector();
			elseif v == 9 then
				hookArgs[i] = msg:ReadAngle();
			elseif v == 10 then
				local id = msg:ReadShort() + 32768;
				hookArgs[i] = IF.Items:Get( id );
			elseif v == 11 then
				local id = msg:ReadShort() + 32768;
				hookArgs[i] = IF.Inv:Get(id);
			elseif v == 12 then
				hookArgs[i] = msg:ReadChar() + 128;
			elseif v == 13 then
				hookArgs[i] = msg:ReadLong() + 2147483648;
			elseif v == 14 then
				hookArgs[i] = msg:ReadShort() + 32768;
			end
		end
	end
	command.Hook( self, unpack( hookArgs ) );
end
IF.Items:ProtectKey( "ReceiveNWCommand" );




--Place networked commands here in the same order as in init.lua.
IF.Items:CreateNWCommand( ITEM, "ToInventory",				function( self, inv, iSlot )		self:ToInventory( inv, iSlot, nil, nil, false )	end,	{ "inventory", "short" }				);
IF.Items:CreateNWCommand( ITEM, "RemoveFromInventory",		function( self, bForced, inv )		self:ToVoid( bForced, inv, nil, false )			end,	{ "bool", "inventory" }					);
IF.Items:CreateNWCommand( ITEM, "TransferInventory",		function( self, ... )				self:TransInventory( ... )	end,						{ "inventory", "inventory", "short" }	);
IF.Items:CreateNWCommand( ITEM, "TransferSlot",				function( self, ... )				self:TransSlot( ... )	end,							{ "inventory", "short", "short" }		);
IF.Items:CreateNWCommand( ITEM, "PlayerUse"																																						);
IF.Items:CreateNWCommand( ITEM, "PlayerHold"																																					);
IF.Items:CreateNWCommand( ITEM, "PlayerSendToInventory",	nil,																						{ "inventory", "short" }				);
IF.Items:CreateNWCommand( ITEM, "PlayerSendToWorld",		nil,																						{ "vector", "vector" }					);
IF.Items:CreateNWCommand( ITEM, "PlayerMerge",				nil,																						{ "item" }								);
IF.Items:CreateNWCommand( ITEM, "PlayerSplit",				nil,																						{ "int" }								);