--[[
Itemforge UI Module
CLIENT

This implements a clientside User-Interface for Itemforge.
Binds related to UI lead here. Dragdrops are facilitated here.
]]--
MODULE.Name="UI";											--Our module will be stored at IF.UI
MODULE.Disabled=false;										--Our module will be loaded
MODULE.DragPanel=nil;										--While a drag operation is in process, DragPanel is the panel that the drag started on.
MODULE.DragImage=nil;										--Drag image is a picture of the item being dragged.
MODULE.DragOffsetX=0;
MODULE.DragOffsetY=0;
MODULE.DropPanel=nil;										--While a drag operation is in progress, DropPanel is the panel that DragPanel will be 'dropped' onto.

--Initializes the UI here
function MODULE:Initialize()
end

--Gets rid of anything related to the Itemforge UI
function MODULE:Cleanup()
	hook.Remove("Think","itemforge_ui_think");
	hook.Remove("GUIMouseReleased","itemforge_ui_screenclick");
end



--Returns the current panel being drag-dropped or nil if no drag-drop is occuring.
function MODULE:GetDragPanel()
	if self.DragPanel && !self.DragPanel:IsValid() then
		self.DragPanel=nil;
	end
	return self.DragPanel;
end

--Returns true if a drag-drop operation is currently happening, false otherwise
function MODULE:IsDragging()
	return (self:GetDragPanel()!=nil);
end

function MODULE:GetDragImage()
	if self.DragImage && !self.DragImage:IsValid() then
		self.DragImage=nil;
	end
	return self.DragImage;
end

function MODULE:SetDropzone(panel)
	self.DropPanel=panel;
end

function MODULE:ClearDropzone(panel)
	if self.DropPanel==panel then
		self.DropPanel=nil;
		return true;
	end
	return false;
end

--[[
If a drag-drop is occuring, this returns the panel that the dragged panel will be dropped onto.
If a drag-drop isn't occuring, or if there is no panel to drag-drop to, this returns nil.
]]--
function MODULE:GetDropzone()
	if self.DropPanel && !self.DropPanel:IsValid() then
		self.DropPanel=nil;
	end
	return self.DropPanel;
end

--[[
This function is called by a panel when it wants to start a drag operation.
panel is the panel that will be dragged.
	NOTE: Itemforge does not actually "drag" the panel on screen;
	It will ask the panel create a drag image; to do this, your panel needs a :MakeDragPanel function that returns a Panel.
offsetX and offsetY are optional numbers. These are the coordinates _on the panel_ where you're dragging from (this is usually where your cursor was when you pressed down)
	These numbers are used to position the drag image your panel creates underneath your cursor correctly. If they aren't provided, they're assumed to be 0.
]]--
function MODULE:Drag(panel,offsetX,offsetY)
	if !panel || !panel:IsValid() then ErrorNoHalt("Itemforge UI: Couldn't start drag operation; The given panel was invalid.\n"); return false end
	
	--We can't drag if we're already dragging
	if self:IsDragging() then return false end
	
	self.DragPanel=panel;
	self.DragOffsetX=offsetX or 0;
	self.DragOffsetY=offsetY or 0;
	
	--We ask the panel being dragged to make us a drag panel to display
	if self.DragPanel.MakeDragPanel then
		local s,r=pcall(panel.MakeDragPanel,panel);
		if !s then
			ErrorNoHalt(r.."\n");
		else
			self.DragImage=r;
			self.DragImage:SetPos(gui.MouseX()-offsetX,gui.MouseY()-offsetY);
		end
	end
	
	return true;
end

--[[
This function is called when the panel being dragged is dropped.
]]--
function MODULE:Drop()
	local p=self:GetDropzone();
	
	--Panel was dropped onto another panel (dropzone)
	if p && p:IsValid() && p.OnDrop then
		local s,r=pcall(p.OnDrop,p,self.DragPanel);
		if !s then ErrorNoHalt(r.."\n") end
	
	--Panel was dropped while hovering the game world
	elseif vgui.IsHoveringWorld() then
		--We dropped in world
		--TODO this is hardcoded; it needs to be adapted
		local traceRes=util.QuickTrace(LocalPlayer():GetShootPos(),(gui.ScreenToVector(gui.MousePos())*64),LocalPlayer());
		
		local droppedItem=self.DragPanel:GetItem();
		if droppedItem then
			--If we dropped onto an item in the world
			local item=IF.Items:GetEntItem(traceRes.Entity);
			if item && item:Event("OnDragDropHere",false,droppedItem) then
				droppedItem:Event("OnDragDropToItem",nil,item);
			else
				droppedItem:Event("OnDragDropToWorld",nil,traceRes);
			end
		end
	end
	
	self:CancelDrag();
	return true;
end

--[[
CancelDrag will stop a drag-drop operation. This will:
	Get rid of 
	Clear the current dropzone.
whatPanel is optional. If it's provided it will cancel the drag only if the given panel is the one being dragged
]]--
function MODULE:CancelDrag(whatPanel)
	--If a specific panel to stop dragging was given, check it first to make sure we're stopping the right one
	if !whatPanel || whatPanel==self.DragPanel then
		local p=self:GetDragPanel();
		if p && p.OnCancelDrag then
			local s,r=pcall(p.OnCancelDrag,p);
			if !s then ErrorNoHalt(r.."\n") end
		end
		self.DragPanel=nil;
		
		local p=self:GetDragImage();
		if p then p:Remove(); end
		self.DragImage=nil;
		
		self.DragOffsetX=0;
		self.DragOffsetY=0;
		
		self:ClearDropzone(self.DropPanel);
	end
end

--[[
This function is called every frame (it's a clientside think), regardless of whether or not a drag-drop is occuring or not.
This event has two purposes:
	If there is a drag image (or in other words, a drag-drop is probably occuring), then it will move the drag image to where the cursor is
	If there is a drag-drop occuring and the mouse isn't down, then the player has released his mouse. We'll drop from here.
]]--
function MODULE:Think()
	local p=self:GetDragImage();
	
	--Move our drag image every frame
	if p then p:SetPos(gui.MouseX()-self.DragOffsetX,gui.MouseY()-self.DragOffsetY) end
	
	--Detect when it's time to drop
	if self:IsDragging() && !input.IsMouseDown(MOUSE_LEFT) then self:Drop() end
end

--[[
This function is called when the mouse is released over the game screen.
This event is only really valid during a right-mouse click, to open a menu.
]]--
function MODULE:ScreenClick(mc)
	if mc!=MOUSE_RIGHT then return false end
	--TODO range is hardcoded (this could possibly be determined with an event like "CanShowPlayerMenu" or "GetInteractRange" or something)
	local traceRes=util.QuickTrace(LocalPlayer():GetShootPos(),(gui.ScreenToVector(gui.MousePos())*128),LocalPlayer());
	
	if traceRes.Entity && traceRes.Entity:IsValid() && traceRes.Entity:GetClass()=="itemforge_item" then
		local item=traceRes.Entity:GetItem();
		if item then
			return item:ShowMenu(gui.MousePos());
		end
	end
	
	return false;
end

hook.Add("Think","itemforge_ui_think",function(...) IF.UI:Think(...) end);
hook.Add("GUIMouseReleased","itemforge_ui_screenclick",function(...) IF.UI:ScreenClick(...) end);