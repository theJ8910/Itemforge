--[[
Itemforge UI Module
CLIENT

This module implements Itemforge's clientside user interface.
Binds related to UI lead here. Dragdrops and mouse interactions with entities are facilitated here.
]]--

MODULE.Name					= "UI";								--Our module will be stored at IF.UI
MODULE.Disabled				= false;							--Our module will be loaded

MODULE.InteractRange		= 128;								--The interact range is how close a player must be to an object in order for mouse events to it.

MODULE.DragObject			= nil;								--While a drag operation is in progress, DragObject is the object that the drag started on.
MODULE.DropObject			= nil;								--While a drag operation is in progress, DropObject is the object that DragObject will be 'dropped' onto if a drop occurs.

MODULE.DragImage			= nil;								--While a drag operation is in progress, DragImage is the panel that is displayed underneath the user's cursor.
MODULE.DragOffsetX			= 0;								--The drag image is centered underneath the cursor at this x, y position
MODULE.DragOffsetY			= 0;

MODULE.HoverEntity			= nil;								--What entity was the user hoving his mouse over last frame? This is nil if the player was not hovering his mouse over the world.

MODULE.MouseCaptureEntity	= nil;								--If mouse events are being captured by an entity, this is the entity capturing mouse events.

--Itemforge UI selection enums (used to control selection in ItemforgeInventorySlots panel)
IFUI_SELECT_NONE				= 0;							--Cannot select any items
IFUI_SELECT_SINGLE				= 1;							--Can only select one item at a time
IFUI_SELECT_MULTI				= 2;							--Can select several items at once

--[[
* CLIENT

Initializes UI module.
UI-related hooks are added here.
]]--
function MODULE:Initialize()
	hook.Add( "Think",				"itemforge_ui_think",			function( ... ) self:Think( ... )			end );
	hook.Add( "GUIMousePressed",	"itemforge_ui_screenpress",		function( ... ) self:ScreenPress( ... )		end );
	hook.Add( "GUIMouseReleased",	"itemforge_ui_screenrelease",	function( ... ) self:ScreenRelease( ... )	end );
end

--[[
* CLIENT

Gets rid of anything related to the Itemforge UI.
UI-related hooks are removed here.
]]--
function MODULE:Cleanup()
	hook.Remove( "Think",				"itemforge_ui_think"			);
	hook.Remove( "GUIMousePressed",		"itemforge_ui_screenpress"		);
	hook.Remove( "GUIMouseReleased",	"itemforge_ui_screenrelease"	);
end

--[[
* CLIENT

This function is called when an object needs to be dragged with Itemforge UI's Drag/Drop system.

Running this function will ask the given object to create a "drag image" (a temporary panel that appears underneath the player's cursor).
While dragging, the drag image moves according to where the user moves his mouse onscreen.
When you release the mouse, the drag image is removed.

vDragObject is the object that will be dragged.
	This is usually a panel or entity, but can be any object, so long as it has the appropriate events.
	Drag objects need the following functions:
		obj:IsValid()			- Must return true if the object hasn't been deleted
		obj:CreateDragImage()	- Must create and return a panel
		obj:OnDragStart()		- Called if Itemforge starts a drag successfully
		obj:OnDragEnd()			- Called if Itemforge ends a drag
		obj:OnDragCancel()		- Called if the drag was cancelled (won't call on a successful drop)
		obj:OnDropInWorld()		- Called if the panel was dropped in the world

iOffsetX and iOffsetY are optional numbers.
	These are the coordinates _on the panel_ where you're dragging from (this is usually where your cursor was when you pressed down)
	These numbers are used to position the drag image underneath your cursor correctly.
	If they aren't provided, they're assumed to be 0.

Returns true if a drag operation was started successfully.
Otherwise, returns false.
]]--
function MODULE:Drag( vDragObject, iOffsetX, iOffsetY )
	if self:IsDragging() then return false end
	if !IsValid( vDragObject ) then ErrorNoHalt( "Itemforge UI: Couldn't start drag operation; a valid drag object was not given.\n" ); return false end

	local fnCreateDragImage = vDragObject.CreateDragImage;
	if !IF.Util:IsFunction( fnCreateDragImage ) then ErrorNoHalt( "Itemforge UI: Couldn't start drag operation; "..tostring( vDragObject ).." doesn't have a valid \"CreateDragImage\" function." ); return false end

	local fnOnDragStart = vDragObject.OnDragStart;
	if !IF.Util:IsFunction( fnOnDragStart ) then ErrorNoHalt( "Itemforge UI: Couldn't start drag operation; "..tostring( vDragObject ).." doesn't have a valid \"OnDragStart\" function." ); return false end

	--We can't drag if we're already dragging
	if self:IsDragging() then return false end
	
	local s, r = pcall( fnCreateDragImage, vDragObject );
	if !s then ErrorNoHalt( "Itemforge UI: Couldn't start drag operation; error calling CreateDragImage on "..tostring( vDragObject )..": "..r ); return false end

	self.DragObject	 = vDragObject;

	self.DragImage	 = r;
	self.DragOffsetX = iOffsetX or 0;
	self.DragOffsetY = iOffsetY or 0;
	
	--Move the drag image to the correct position
	self.DragImage:SetPos( self:GetDragImagePosition( gui.MousePos() ) );
	
	--Inform object of successful drag
	local s, r = pcall( fnOnDragStart, vDragObject );
	if !s then ErrorNoHalt( "Itemforge UI: Error calling \"OnDragStart\" on "..tostring( vDragObject )..": "..r ) end

	return true;
end

--[[
* CLIENT
* Internal

There should be no reason for a scripter to call this directly.

This function is called to clean up after a drag has ended (drop and cancel call this function).
Calls the drag object's OnDragEnd event.
]]--
function MODULE:EndDrag()
	local vDragObject = self:GetDragObject();
	if !vDragObject then return end

	--Inform object that drag is ending
	local fnOnDragEnd = vDragObject.OnDragEnd;
	if IF.Util:IsFunction( fnOnDragEnd ) then
		local s, r = pcall( fnOnDragEnd, vDragObject );
		if !s then ErrorNoHalt( "Itemforge UI: Error calling \"OnDragEnd\" on "..tostring( vDragObject )..": "..r ) end
	else
		ErrorNoHalt( "Itemforge UI: "..tostring( vDragObject ).." doesn't have a valid \"OnDragEnd\" function." );
	end
	
	self.DragObject = nil;
	self:RemoveDragImage();
end

--[[
* CLIENT

Returns the current panel being drag-dropped or nil if no drag-drop is occuring.
]]--
function MODULE:GetDragObject()
	if self.DragObject && !self.DragObject:IsValid() then
		self.DragObject = nil;
		
		--If the drag object was unexpectedly removed, the drag image needs to be removed too or it will stay onscreen.
		self:RemoveDragImage();
	end
	return self.DragObject;
end

--[[
* CLIENT

If a drag is in progress, returns the drag image (the panel displayed beneath the cursor).
If a drag isn't in progress, or there is no drag image / it has been removed, returns nil.
]]--
function MODULE:GetDragImage()
	if self.DragImage && !self.DragImage:IsValid() then
		self.DragImage = nil;
	end
	return self.DragImage;
end

--[[
* CLIENT
* Internal

There should be no reason for a scripter to call this directly.

Removes the drag image.
]]--
function MODULE:RemoveDragImage()
	local pnlDragImage = self.DragImage;
	if !IsValid( pnlDragImage ) then return end
		
	--If the drag image panel has a RemoveAndCleanUp function we prefer to call that (this allows the panel to unregister itself from it's item for instance).
	local fnRemoveAndCleanUp = pnlDragImage.RemoveAndCleanUp;
	if IF.Util:IsFunction( fnRemoveAndCleanUp ) then
		local s, r = pcall( fnRemoveAndCleanUp, pnlDragImage );
		if		!s						then	ErrorNoHalt( "Itemforge UI: Error calling \"RemoveAndCleanUp\" on "..tostring( pnlDragImage ).."; standard removal will be performed instead. Error was: "..r );
		else									return;
		end
	end

	--Default removal in case RemoveAndCleanUp is nonexistant or fails in some way
	pnlDragImage:Remove();
	self.DragImage = nil;
end

--[[
* CLIENT

Returns true if a drag-drop operation is in progress.
	If pnl is given, true is only returned if the given panel is the panel being dragged.
Otherwise, returns false.
]]--
function MODULE:IsDragging( vDragObject )
	if vDragObject then
		return self:GetDragObject() == vDragObject;
	end
	return ( self:GetDragObject() != nil );
end

--[[
* CLIENT

Sets the current drop object.

Drop objects are objects capable of having drag objects dropped upon them.

Whenever a drag object is dropped onto the drop object, the drop object's OnDropHere event is called,
and the dropped drag object is passed to the event. From there, the drop object can react to this however it pleases.

Drop objects are responsible for setting themselves as the current drop object,
and for clearing themselves as the current drop object.
Typically, a drop object should set itself as the current drop object on mouse over,
and clear itself as the current drop object on mouse out (or when otherwise being rendered
incapable of receiving dropped drag objects, such as when the panel is removed, or in the case of item slots,
when an item slot is closed / has droppability turned off).

vDropObject is the object that will receive dropped drag objects.
	This is usually a panel or entity, but can be any object, so long as it has the appropriate events.
	Drop objects need the following functions:
		obj:IsValid()					- Must return true if the object hasn't been deleted
		obj:OnDropHere( vDragObject )	- Called if a drag object object is dropped on the drop object.
										  This function should return true if the drop can be handled,
										  or false if the drop cannot be handled. If the drop object is an entity,
										  and it's OnDropHere returns false, the panel will get dropped in the world instead.
										  
										  (e.g. dragging an item slot containing a big item, and dropping it on a small container
										  item's entity should return false since the container can't hold it).
]]--
function MODULE:SetDropObject( vDropObject )
	if !vDropObject || !vDropObject:IsValid() then ErrorNoHalt( "Itemforge UI: Couldn't set current drop object; a valid drop object was not given.\n" ); return false end
	self.DropObject = vDropObject;
end

--[[
* CLIENT

Clears the drop object.
If vDropObject is given, the drop object is only cleared if it matches the given object.

Returns true if the drop object was successfully cleared.
Returns false otherwise.
]]--
function MODULE:ClearDropObject( vDropObject )
	if vDropObject && self.DropObject != vDropObject then return false end
	
	self.DropObject = nil;
	return true;
end

--[[
* CLIENT

Returns the current drop object (nil if there is no drop object).
This can return an object even if no drag operation is currently occuring.
]]--
function MODULE:GetDropObject()
	if self.DropObject && !self.DropObject:IsValid() then
		self.DropObject = nil;
	end
	return self.DropObject;
end

--[[
* CLIENT
* Internal

There should be no reason for a scripter to call this directly.

This function is called when the panel being dragged is dropped.
]]--
function MODULE:Drop()
	local vDragObject = self:GetDragObject();
	local vDropObject = self:GetDropObject();
	local bDroppedInWorld;

	--Panel was dropped onto a drop object
	if vDropObject then
		bDroppedInWorld = false;

		local fnDropHere = vDropObject.OnDropHere;
		if IF.Util:IsFunction( fnDropHere ) then
			local s, r = pcall( fnDropHere, vDropObject, vDragObject );
			if		!s												then
				ErrorNoHalt( "Itemforge UI: Error calling  \"OnDropHere\" on "..tostring( vDropObject )..": "..r.."\n" )

			--If our drop object was actually an entity, and it didn't handle this particular drop object, then we count it as a "drop in world" instead
			elseif	IF.Util:IsEntity( vDropObject ) && r == false	then
				bDroppedInWorld = true;
			end
		else
			ErrorNoHalt( "Itemforge UI: "..tostring( vDropObject ).." does not have an \"OnDropHere\" function.\n" );
		end
	
	--If we didn't drag-drop onto an entity and the dragged panel is equipped to handle a drop-in-world, we'll do that instead.
	elseif vgui.CursorVisible() && vgui.IsHoveringWorld() then
		bDroppedInWorld = true;
	end
	
	if bDroppedInWorld then
		local fnOnDropInWorld = vDragObject.OnDropInWorld;
		if IF.Util:IsFunction( fnOnDropInWorld ) then
			--NOTE: There was a reason I reduced this to 64... I seem to remember 128 seemed too far. Is interacting with stuff at 128 okay, but dropping it at 128 isn't?
			--Can always switch this over to self:GetInteractRange() and scale it down if necessary...

			local traceRes = self:ScreenTrace( 64, gui.MousePos() );
			local s, r = pcall( fnOnDropInWorld, vDragObject, traceRes );
			if !s then ErrorNoHalt( "Itemforge UI: Error calling \"OnDropInWorld\" on "..tostring( vDragObject )..": "..r.."\n" ); end
		end
	end

	self:EndDrag();
end

--[[
* CLIENT

CancelDrag will stop a drag-drop operation in progress. This will:
	Tell the panel being dragged that the drag was cancelled (if the panel has an OnDragCancel(self) function
	Clear the current drop object.
vThisDragObject is an optional drag object.
	If it's provided, the drag will only be cancelled if vThisDragObject is the one being dragged.

Returns true if the drag in progress was cancelled.
Returns false if no drag was in progress, or if the given object didn't match the currently dragged object.
]]--
function MODULE:CancelDrag( vThisDragObject )
	local vDragObject = self:GetDragObject();
	if !vDragObject then return false end

	--If a specific object to stop dragging was given, check it first to make sure we're stopping the right one
	if vThisDragObject && vThisDragObject != vDragObject then return false end
	
	local fn = vDragObject.OnDragCancel;
	if IF.Util:IsFunction( fn ) then
		local s, r = pcall( fn, vDragObject );
		if !s then ErrorNoHalt( "Itemforge UI: Error calling \"OnDragCancel\" on "..tostring( vDragObject )..": "..r ) end
	else
		ErrorNoHalt( "Itemforge UI: "..tostring( vDragObject ).." doesn't have a valid \"OnDragCancel\" function." );
	end
	
	self:EndDrag();

	return true;
end

--[[
* CLIENT

Returns the position on the screen the drag panel should be positioned
if the mouse is at iMouseX, iMouseY.

Returns two values: iX, iY
	These are the x and y coordinates (respectively) that the panel's position should be set to.
]]--
function MODULE:GetDragImagePosition( iMouseX, iMouseY )
	return iMouseX - self.DragOffsetX, iMouseY - self.DragOffsetY;
end

--[[
* CLIENT
* Internal

There should be no reason for a scripter to call this directly.
Sets the entity the mouse is hovering over.
]]--
function MODULE:SetHoverEntity( eEntity )
	self.HoverEntity = eEntity;
end

--[[
* CLIENT
* Internal

Returns the entity the mouse was last know to be hovering over.
]]--
function MODULE:GetHoverEntity()
	if self.HoverEntity && !self.HoverEntity:IsValid() then
		self.HoverEntity = nil;
	end

	return self.HoverEntity;
end

--[[
* CLIENT

Sets the interact range.
]]--
function MODULE:SetInteractRange( fRange )
	self.InteractRange = fRange;
end

--[[
* CLIENT

Returns the interact range.
]]--
function MODULE:GetInteractRange()
	return self.InteractRange;
end

--[[
* CLIENT

This function allows an entity to capture / stop capturing mouse events.
This means that whenever a mouse press or release occurs, the given
entity receives the event, regardless of whether or not the mouse was overhead
at the time or not.

Only one entity can mouse capture at a time.
If one entity is mouse capturing, and a second one starts mousecapturing,
the first stops mousecapturing and the second starts mousecapturing instead.

eEntity should be the entity that you want to capture mouse events with.
bCapture is a true/false. If bCapture is:
	true, then this entity will capture mouse events.
	false, then this entity stops capturing mouse events (if it was mouse capturing at the time).
]]--
function MODULE:MouseCapture( eEntity, bCapture )
	if !IsValid( eEntity ) then ErrorNoHalt( "Itemforge UI: Couldn't turn mouse capture on/off. The given entity wasn't valid.\n" ); return end
	if bCapture == true then
		self.MouseCaptureEntity = eEntity;
		vgui.GetWorldPanel():MouseCapture( true );
	elseif eEntity == self:GetMouseCaptureEntity() then
		self:ClearMouseCaptureEntity();
	end
end

--[[
* CLIENT

Stops mouse capturing an entity if we are currently doing that
]]--
function MODULE:ClearMouseCaptureEntity()
	self.MouseCaptureEntity = nil;
	vgui.GetWorldPanel():MouseCapture( false );
end

--[[
* CLIENT

Returns the current entity capturing mouse events.
Returns nil if no particular entity is capturing mouse events.
]]--
function MODULE:GetMouseCaptureEntity( eEntity )
	if self.MouseCaptureEntity && !self.MouseCaptureEntity:IsValid() then
		self:ClearMouseCaptureEntity();
	end
	return self.MouseCaptureEntity;
end

--[[
* CLIENT

Traces a line from where-ever the local client is looking from (the local player's eyes or a camera).
iX and iY are screen positions that determine the angle of the trace.
	If iX, iY is the center of the screen, the trace's direction is the same as the direction of the player's eyes/camera.
	If iX is the right side of the screen ( ScrW() - 1 ), the trace's angle is shifted FOV / 2 degrees to the player / camera's right,
	if iX is the left side of the screen ( 0 ), the trace's angle is shifted FOV / 2 degrees to the player / camera's left,
	etc.
fDist is how far to trace away from the camera (in game units).
]]--
function MODULE:ScreenTrace( fDist, iX, iY )
	--If we're in first person get the player's eye pos. Otherwise we're looking through a camera or something, get the camera's position.
	local vEyes;
	local eView = GetViewEntity();
	if eView == LocalPlayer() then	vEyes = LocalPlayer():EyePos();
	else							vEyes = eView:GetPos();
	end
	
	return util.QuickTrace( vEyes, fDist * gui.ScreenToVector( iX, iY ), eView );
end

--[[
* CLIENT
* Event

This function is called every frame (it's a clientside think), regardless of whether or not a drag-drop is occuring or not.
This event has many purposes:
	Itemforge's UI enables entities to be moused-oved, moused-out, etc. This function drives that process.
	If a drag-drop is occuring, then it will move the dragged panel to where the cursor is
	If there is a drag-drop occuring and the mouse isn't down, then the player has released his mouse. We'll drop from here.
]]--
function MODULE:Think()
	local iX, iY = gui.MousePos();
	
	local eOldHover = self:GetHoverEntity();
	
	--See if we're hovering over an entity this frame
	local eNewHover = nil;
	if vgui.CursorVisible() && vgui.IsHoveringWorld() then
		local traceRes = self:ScreenTrace( self:GetInteractRange(), iX, iY );
		if IsValid( traceRes.Entity ) then
			eNewHover = traceRes.Entity;
		end
	end
	
	--Are we hovering a different entity than before?
	--This includes if we were hovering but now aren't, or if we weren't hoving but now are.
	if eNewHover != eOldHover then
	
		--If we were hovering over an entity before, we call it's OnCursorExited event (if it has one).
		if eOldHover then
			local fn = eOldHover.OnCursorExited;
			if IF.Util:IsFunction( fn ) then
				local s, r = pcall( fn, eOldHover );
				if !s then ErrorNoHalt( "Itemforge UI: Error calling \"OnCursorExited\" event on "..tostring( eOldHover )..": "..r ) end
			end
		end
		
		--If we're hovering over an entity now then we call it's OnCursorEntered event (if it has one)
		if eNewHover then
			local fn = eNewHover.OnCursorEntered;
			if IF.Util:IsFunction( fn ) then
				local s, r = pcall( fn, eNewHover );
				if !s then ErrorNoHalt( "Itemforge UI: Error calling \"OnCursorEntered\" event on "..tostring( eNewHover )..": "..r ) end
			end
		end
	end
	
	--The new hover entity becomes the current hover entity in preparation for the next frame
	self:SetHoverEntity( eNewHover );
	
	--Were we dragging something?
	if self:IsDragging() then
		
		--Are we still dragging?
		if vgui.CursorVisible() && input.IsMouseDown( MOUSE_LEFT ) then
			
			--If so, move the dragged panel every frame
			self:GetDragImage():SetPos( self:GetDragImagePosition( iX, iY ) );
		
		--If not, drop the panel we're dragging.
		else
			self:Drop();
		end
		
	end
end

--[[
* CLIENT
* Event

This function is called when the mouse is pressed over the game screen.
It traces a line to find entities underneath the cursor.
If it hits an entity with an OnMousePressed event, runs the event and passes the button that was pressed, position of the cursor, and info from the trace that hit the entity.

NOTE: Appears that this hook only calls if the mouse is released over the world (contrary to wiki description).
]]--
function MODULE:ScreenPress( eMC )
	local iX, iY = gui.MousePos();
	local traceRes = self:ScreenTrace( self:GetInteractRange(), iX, iY );
	
	local eHit = self:GetMouseCaptureEntity() or traceRes.Entity;
	if !IsValid( eHit ) then return end

	local fn = eHit.OnMousePressed;
	if !IF.Util:IsFunction( fn ) then return end
	
	local s, r = pcall( fn, eHit, eMC, iX, iY, traceRes );
	if !s then ErrorNoHalt( "Itemforge UI: Calling \"OnMousePressed\" on "..tostring( eHit ).." failed: "..r.."\n" ) end
end

--[[
* CLIENT
* Event

This function is called when the mouse is released over the game screen.
It traces a line to find entities underneath the cursor.
If it hits an entity with an OnMouseReleased event, runs the event and passes the button that was released, position of the cursor, and info from the trace that hit the entity.

NOTE: Appears that this hook only calls if the mouse is released over the world (contrary to wiki description).
]]--
function MODULE:ScreenRelease( eMC )
	local iX, iY = gui.MousePos();
	local traceRes = self:ScreenTrace( self:GetInteractRange(), iX, iY );
	
	local eHit = self:GetMouseCaptureEntity() or traceRes.Entity;
	if !IsValid( eHit ) then return end

	local fn = eHit.OnMouseReleased;
	if !IF.Util:IsFunction( fn ) then return end

	local s, r = pcall( fn, eHit, eMC, iX, iY, traceRes );
	if !s then ErrorNoHalt( "Itemforge UI: Calling \"OnMouseReleased\" on "..tostring( eHit ).." failed: "..r.."\n" ) end

	--TODO: I know that source's mouse captures automatically expire on a mouse release, but do they expire only when all buttons have been released?
end