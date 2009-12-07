--[[
Itemforge UI Module
CLIENT

This implements a clientside User-Interface for Itemforge.
Binds related to UI lead here. Dragdrops are facilitated here.
]]--
MODULE.Name="UI";											--Our module will be stored at IF.UI
MODULE.Disabled=false;										--Our module will be loaded
MODULE.DragPanel=nil;										--While a drag operation is in process, DragPanel is the panel that the drag started on.
MODULE.DragOffsetX=0;
MODULE.DragOffsetY=0;
MODULE.DropPanel=nil;										--While a drag operation is in progress, DropPanel is the panel that DragPanel will be 'dropped' onto.
MODULE.DropEntity=nil;										--While a drag operation is in progress, DropEntity is the entity that DragPanel will be 'dropped' onto.

MODULE.LastHoverEntity=nil;									--What entity was the user hoving his mouse over last frame? This is nil if the player was not hovering his mouse over the world.

MODULE.MouseCaptureEntity=nil;								--If mouse events are being captured by an entity, this is the entity capturing mouse events.

--Initializes the UI here
function MODULE:Initialize()
	hook.Add("Think","itemforge_ui_think",function(...) self:Think(...) end);
	hook.Add("GUIMousePressed","itemforge_ui_screenpress",function(...) self:ScreenPress(...) end);
	hook.Add("GUIMouseReleased","itemforge_ui_screenrelease",function(...) self:ScreenRelease(...) end);
end

--Gets rid of anything related to the Itemforge UI
function MODULE:Cleanup()
	hook.Remove("Think","itemforge_ui_think");
	hook.Remove("GUIMousePressed","itemforge_ui_screenpress");
	hook.Remove("GUIMouseReleased","itemforge_ui_screenrelease");
end


--Sets the dropzone.
function MODULE:SetDropzone(panel)
	self.DropPanel=panel;
end

--Clears the dropzone. If a panel is given, the dropzone must be equal to the given panel.
function MODULE:ClearDropzone(panel)
	if panel && self.DropPanel!=panel then return false end
	
	self.DropPanel=nil;
	return true;
end

--[[
If a drag-drop is occuring, this returns the drop-zone.
If a drag-drop isn't occuring, or if there is no panel to drag-drop to, this returns nil.
]]--
function MODULE:GetDropzone()
	if self.DropPanel && !self.DropPanel:IsValid() then
		self.DropPanel=nil;
	end
	return self.DropPanel;
end

function MODULE:SetDropEntity(ent)
	self.DropEntity=ent;
end

function MODULE:ClearDropEntity(ent)
	if ent && self.DropEntity!=ent then return false end
	self.DropEntity=nil;
	return true;
end

function MODULE:GetDropEntity()
	if self.DropEntity && !self.DropEntity:IsValid() then
		self.DropEntity=nil;
	end
	return self.DropEntity;
end




--Returns the current panel being drag-dropped or nil if no drag-drop is occuring.
function MODULE:GetDragPanel()
	if self.DragPanel && !self.DragPanel:IsValid() then
		self.DragPanel=nil;
	end
	return self.DragPanel;
end

--Returns true if a drag-drop operation is currently happening, false otherwise
function MODULE:IsDragging(panel)
	if panel && self:GetDragPanel()!=panel then
		return false;
	end
	return (self:GetDragPanel()!=nil);
end

--[[
This function is called when a panel needs to be dragged with Itemforge UI's Drag/Drop system.
While dragging, Itemforge UI's Drag/Drop system will move the panel according to where the user moves his mouse onscreen.
When you release the mouse, Itemforge UI's Drag/Drop system will stop dragging the panel and will call the panel's :Drop() function.

panel is the panel that will be dragged.
offsetX and offsetY are optional numbers. These are the coordinates _on the panel_ where you're dragging from (this is usually where your cursor was when you pressed down)
	These numbers are used to position the panel underneath your cursor correctly. If they aren't provided, they're assumed to be 0.
]]--
function MODULE:Drag(panel,offsetX,offsetY)
	if !panel || !panel:IsValid() then ErrorNoHalt("Itemforge UI: Couldn't start drag operation; The given panel was invalid.\n"); return false end
	
	--We can't drag if we're already dragging
	if self:IsDragging() then return false end
	
	self.DragPanel=panel;
	self.DragOffsetX=offsetX or 0;
	self.DragOffsetY=offsetY or 0;
	
	--Move the panel to the correct position
	self.DragPanel:SetPos(gui.MouseX()-self.DragOffsetX,gui.MouseY()-self.DragOffsetY);
	
	return true;
end

--[[
This function is called when the panel being dragged is dropped.
]]--
function MODULE:Drop()
	local p=self:GetDropzone();
	local e=self:GetDropEntity();
	
	--Panel was dropped onto another panel (dropzone)
	if p && p.OnDragDropHere then
		local s,r=pcall(p.OnDragDropHere,p,self.DragPanel);
		if !s then ErrorNoHalt(r.."\n") end
	
	--Panel was dropped onto an entity (drop entity)
	elseif e && e.OnDragDropHere then
		local bDroppedInWorld=true;
		local s,r=pcall(e.OnDragDropHere,e,self.DragPanel);
		if !s then		ErrorNoHalt(r.."\n");
		elseif r then	bDroppedInWorld=false;
		end
		
		--If the entity can handle drag-dropped panels but refuses to do anything with this panel, then we count it as a "drop in world" instead
		if bDroppedInWorld && self.DragPanel.OnDragDropToWorld then
			--TODO streamline this
			local traceRes=self:ScreenTrace(64,gui.MousePos());
			local s,r=pcall(self.DragPanel.OnDragDropToWorld,self.DragPanel,traceRes);
			if !s then ErrorNoHalt(r.."\n"); end
		end
		
	--If we didn't drag-drop onto an entity and the dragged panel is equipped to handle a drop-in-world, we'll do that instead.
	elseif vgui.CursorVisible() && vgui.IsHoveringWorld() && self.DragPanel.OnDragDropToWorld then
			--TODO streamline this
			local traceRes=self:ScreenTrace(64,gui.MousePos());
			local s,r=pcall(self.DragPanel.OnDragDropToWorld,self.DragPanel,traceRes);
			if !s then ErrorNoHalt(r.."\n"); end
	end
	
	self:CancelDrag();
	return true;
end

--[[
CancelDrag will stop a drag-drop operation in progress. This will:
	Tell the panel being dragged that the drag was cancelled (if the panel has an OnCancelDrag(self) function)
	Clear the current dropzone.
whatPanel is optional. If it's provided it will cancel the drag only if the given panel is the one being dragged.
]]--
function MODULE:CancelDrag(whatPanel)
	--If a specific panel to stop dragging was given, check it first to make sure we're stopping the right one
	if whatPanel && whatPanel!=self.DragPanel then return false end
		
	local p=self:GetDragPanel();
	if p && p.OnCancelDrag then
		local s,r=pcall(p.OnCancelDrag,p);
		if !s then ErrorNoHalt(r.."\n") end
	end
	
	self.DragPanel=nil;
	self.DragOffsetX=0;
	self.DragOffsetY=0;
	
	self:ClearDropzone(self.DropPanel);
	self:ClearDropEntity();
	
	return true;
end

--[[
This function is called every frame (it's a clientside think), regardless of whether or not a drag-drop is occuring or not.
This event has many purposes:
	Itemforge's UI enables entities to be moused-oved, moused-out, etc. This function drives that process.
	If a drag-drop is occuring, then it will move the dragged panel to where the cursor is
	If there is a drag-drop occuring and the mouse isn't down, then the player has released his mouse. We'll drop from here.
]]--
function MODULE:Think()
	local x,y=gui.MousePos();
	
	--Make sure last frame's hover entity is still valid
	if self.LastHoverEntity && !self.LastHoverEntity:IsValid() then self.LastHoverEntity=nil; end
	
	--See if we're hovering over an entity this frame
	ThisHoverEntity=nil;
	if vgui.CursorVisible() && vgui.IsHoveringWorld() then
		local traceRes=self:ScreenTrace(128,x,y);
		if traceRes.Entity && traceRes.Entity:IsValid() then
			ThisHoverEntity=traceRes.Entity;
		end
	end
	
	--Are we hovering a different entity than before?
	--This includes if we were hovering but now aren't, or if we weren't hoving but now are.
	if ThisHoverEntity!=self.LastHoverEntity then
	
		--If we were hovering over an entity before, we call it's OnCursorExited event (if it has one).
		if self.LastHoverEntity && self.LastHoverEntity.OnCursorExited then
			local s,r=pcall(self.LastHoverEntity.OnCursorExited,self.LastHoverEntity);
			if !s then ErrorNoHalt(r.."\n") end
		end
		
		--If we're hovering over an entity now then we call it's OnCursorEntered event (if it has one)
		if ThisHoverEntity && ThisHoverEntity.OnCursorEntered then
			local s,r=pcall(ThisHoverEntity.OnCursorEntered,ThisHoverEntity);
			if !s then ErrorNoHalt(r.."\n") end
		end
	end
	
	--The last hover entity becomes the current hover entity in preperation for the next frame
	self.LastHoverEntity=ThisHoverEntity;
	
	
	local p=self:GetDragPanel();
	
	--Were we dragging a panel?
	if p then
		
		--Are we still dragging?
		if vgui.CursorVisible() && input.IsMouseDown(MOUSE_LEFT) then
			
			--If so, move the dragged panel every frame
			p:SetPos(x-self.DragOffsetX,y-self.DragOffsetY);
		
		--If not, drop the panel we're dragging.
		else
			self:Drop();
		end
		
	end
end

--[[
This function is called when the mouse is pressed over the game screen.
]]--
function MODULE:ScreenPress(mc)
	local x,y=gui.MousePos();
	
	--TODO range is hardcoded (this could possibly be determined with an event like "GetInteractRange" or something)
	local traceRes=self:ScreenTrace(128,x,y);
		
	if traceRes.Entity && traceRes.Entity:IsValid() && traceRes.Entity.OnMousePressed then
		local s,r=pcall(traceRes.Entity.OnMousePressed,traceRes.Entity,mc,x,y,traceRes);
		if !s then ErrorNoHalt(r.."\n") end
	end
	
	return false;
end

--[[
This function is called when the mouse is released over the game screen.
This event is only really valid during a right-mouse click, to open a menu.
]]--
function MODULE:ScreenRelease(mc)
	--TODO range is hardcoded (this could possibly be determined with an event like "CanShowPlayerMenu" or "GetInteractRange" or something)
	local traceRes=self:ScreenTrace(128,gui.MousePos());
		
	if traceRes.Entity && traceRes.Entity:IsValid() && traceRes.Entity.OnMouseReleased then
		local s,r=pcall(traceRes.Entity.OnMouseReleased,traceRes.Entity,mc,x,y,traceRes);
		if !s then ErrorNoHalt(r.."\n") end
	end
	
	return false;
end

--[[
Traces a line from where-ever the local client is looking from (the local player's eyes or a camera).
x and y are screen positions that determine the angle of the trace.
	If x,y is the center of the screen, the trace's direction is the same as the direction of the player's eyes/camera.
	If x is the right side of the screen (ScrW()-1), the trace's angle is shifted FOV/2 degrees to the player/camera's right,
	if x is the left side of the screen (0), the trace's angle is shifted FOV/2 degrees to the player/camera's left,
	etc.
dist is how far to trace away from the camera (in game units).
]]--
function MODULE:ScreenTrace(dist,x,y)
	--If we're in first person get the player's eye pos. Otherwise we're looking through a camera or something, get the camera's position.
	local eyes;
	local viewEnt=GetViewEntity();
	if viewEnt==LocalPlayer() then	eyes=LocalPlayer():EyePos();
	else							eyes=viewEnt:GetPos();
	end
	
	return util.QuickTrace(eyes,gui.ScreenToVector(x,y)*dist,viewEnt);
end