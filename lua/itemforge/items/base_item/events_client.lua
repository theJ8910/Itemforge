--[[
events_client
CLIENT

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/events_client.lua, so this item's type is "base_item")

This specific file deals with events that are present on the client.
]]--

local mWhite=Material("white_outline");
local oneVector=Vector(1,1,1);

--[[
ENTITY SPECIFIC EVENTS
]]--

--[[
Whenever an item is dropped into the world, an entity is created to represent it.
This function runs when the entity sets it's item to us clientside.

NOTE: It is impossible for me to run this event when the entity is initialized clientside.
	Serverside, a networked int with this Item's ID is set on the entity.
	This function runs when the entity "acquires" this item's ID clientside and sets it's item to this item.
	It may take a short period of time (usually a fraction of a second) after the entity is created serverside and then arrives clientside for the item it is supposed to use to be set.
	However, this is assuming the player can see this entity. Due to PVS optimization, the entity may not exist until the player sees it clientside.
	When that occurs, this function will run; keep this in mind.
ENT is the SENT table - it's "ENT".
eEntity is the SENT that is created to hold the object. It's "ENT.Entity".
]]--
function ITEM:OnEntityInit(ENT,eEntity)
	return true;
end

--[[
SWEP SPECIFIC EVENTS
]]--

--[[
Whenever an item is held as a weapon, an SWEP is created to represent it. This function will be run while SetItem is being run on the SWEP.
SWEP is the SWEP table - it's "SWEP".
eWeapon is the weapon entity - it's "SWEP.Weapon".
]]--
function ITEM:OnSWEPInit(SWEP,eWeapon)
	--We'll grab and set the world model and view models of the SWEP first
	SWEP.WorldModel	=	self:GetWorldModel();
	SWEP.ViewModel	=	self:GetViewModel();
	
	--TODO use hooks
	SWEP.Primary.Automatic=self.PrimaryAuto;
	SWEP.Secondary.Automatic=self.SecondaryAuto;
	SWEP.PrintName=self:Event("GetName","Itemforge Item");
	
	return true;
end

--[[
This hook is called when this item needs it's weapon menu graphics drawn.

The weapon menu graphics are drawn inside of a black box.
x and y describe where the top-left corner of the black box is.
w and h describe how wide and tall (respectively) the black box is.
a is a number between 0 and 255 that describes how opaque the weapon menu graphics should be.
	This is 255 when the menu is open.
	The weapons menu slowly fades out if it is left open for too long;
	While this is happening, "a" will slowly change from 255 to 0.
]]--
function ITEM:OnSWEPDrawMenu(x,y,w,h,a)
	local icon,s=self:Event("GetIcon");
	if !s then return false end
	
	local c=self:GetColor();
	surface.SetMaterial(icon);
	surface.SetDrawColor(c.r,c.g,c.b,a-(255-c.a));
	surface.DrawTexturedRect(x + (w-64)*.5,
							 y + (h-64)*.5 + math.sin(CurTime()*5)*16
							 ,64,64);
end

--This function is run when it comes time to draw a viewmodel. This will only happen while a player is holding an item
function ITEM:OnSWEPDrawViewmodel()
end

--This function is run when it comes time to draw something on the player's HUD. This will only happen while a player is holding an item as a weapon and has it out.
function ITEM:OnSWEPDrawHUD()	
end

--[[
You receive the player's current FOV here and are allowed to change it while this item is held as a weapon and is out.
This is useful for items with scopes.
]]--
function ITEM:OnSWEPTranslateFOV(current_fov)
	return current_fov;
end

--[[
This event determines if we should freeze the view (stop the player from rotating his view) of the player holding this item as a weapon.
Returning true prevents the player holding this item.
Returning anything else (or nothing at all).
]]--
function ITEM:OnSWEPFreezeView()
	return false;
end

--[[
This event can be used to adjust the mouse sensitivity while holding the weapon.
You may return a multiplier to change how sensitive the mouse is (such as 2 for double the mouse sensitivity, 3 for triple the sensitivity, 0 for no mouse movement at all).
You may also return nil or 1 for no change in mouse sensitivity.
]]--
function ITEM:OnSWEPAdjustMouseSensitivity()
	return nil;
end

--[[
This is run when a player is holding the item as a weapon and presses the left mouse button (primary attack).
]]--
function ITEM:OnPrimaryAttack()
end

--[[
This is run when a player is holding the item as a weapon and presses the right mouse button (secondary attack).
]]--
function ITEM:OnSecondaryAttack()
end

--[[
This is run when a player is holding the item as a weapon and presses the reload button (usually the "R" key).
]]--
function ITEM:OnReload()
end

--[[
This is run when a player is holding the item as a weapon and swaps from a different weapon to this weapon.
]]--
function ITEM:OnDeploy()
	--DEBUG
	Msg("Itemforge Items: Deploying "..tostring(self).."!\n");
	
	if self.WMAttach then self.WMAttach:Show(); end
	if self.ItemSlot then self.ItemSlot:SetVisible(true); end
	
	return true;
end

--[[
This is run when a player is holding the item as a weapon and swaps from this weapon to a different weapon.
]]--
function ITEM:OnHolster()
	--DEBUG
	Msg("Itemforge Items: Holstering "..tostring(self).."!\n");
	
	if self.WMAttach then self.WMAttach:Hide(); end
	if self.ItemSlot then self.ItemSlot:SetVisible(false); end
	
	return true;
end








--[[
ITEM EVENTS
]]--

function ITEM:OnInit()
	
end

--[[
Returns the icon this item displays.
]]--
function ITEM:GetIcon()
	return self.Icon;
end

--[[
This is run when you 'use' an item. An item can be used in the inventory with the use button, or if on the ground, by looking at the item's model and pressing E.
The default action for when it's on the ground is to pick it up.
Return false to tell the player the item cannot be used
]]--
function ITEM:OnUse(pl)
	return true;
end

--[[
This runs after a right click menu has been created.
pMenu is the created menu. You can add menu entries here.
These methods might be of some use:
	pMenu:AddOption(strText, funcFunction)
	pMenu:AddSpacer()
	pMenu:AddSubMenu(strText, funcFunction)
	pMenu:AddPanel(pnl);
]]--
function ITEM:OnPopulateMenu(pMenu)
	--Add basic "Use" and "Hold" options
	pMenu:AddOption("Use",function(panel) self:Use(LocalPlayer()) end);
	if !self:IsHeld() then pMenu:AddOption("Hold",function(panel) self:PlayerHold(LocalPlayer()) end); end
	pMenu:AddOption("Examine",function(panel) self:PlayerExamine(LocalPlayer()) end)
	--Add "Split" option; as long as there are enough items to split (at least 2); also, the CanPlayerSplit event must indicate it's possible
	if self:IsStack() && self:GetAmount()>1 && self:Event("CanPlayerSplit",true,LocalPlayer()) then
		pMenu:AddOption("Split",function(panel) self:PlayerSplit(LocalPlayer()); end);
	end
end

--[[
While an inventory is opened, this item can be dragged somewhere on screen.
If this item is drag-dropped to an empty slot in an inventory this function runs.
]]--
function ITEM:OnDragDropToInventory(inv,invSlot)
	if !self:Event("CanPlayerInteract",false,LocalPlayer()) then return false end
	self:SendNWCommand("PlayerSendToInventory",inv,invSlot);
end

--[[
While an inventory is opened, this item can be dragged somewhere on screen.
If this item is drag-dropped onto another item, this function runs.
This function will not run if the other item's OnDragDropHere function returns false.
]]--
function ITEM:OnDragDropToItem(item)
	if !self:Event("CanPlayerInteract",false,LocalPlayer()) then return false end
end

--[[
While an inventory is opened, an item can be dragged somewhere on screen.
If an item is drag-dropped on top of this item (either dropped on a panel this item is being displayed on, or dropped onto this item in the world) this function runs.
A few examples of what this could be used for... You could:
	Merge a pile of items
	Transfer the item to this item's inventory
	Load a gun with ammo

Return true if you want otherItem's OnDragDropToItem to run.
TODO if client determines merge is impossible return false
]]--
function ITEM:OnDragDropHere(otherItem)
	--Don't even bother telling the server to merge if we know we can't interact with the two
	if !self:Event("CanPlayerInteract",false,LocalPlayer()) || !otherItem:Event("CanPlayerInteract",false,LocalPlayer()) then return true end
	
	--Predict if we can merge, fail if prediction says we can't
	if !self:Merge(otherItem) then return true end
	
	self:SendNWCommand("PlayerMerge",otherItem);
	return false;
end

--[[
While an inventory is opened, an item can be dragged somewhere on screen.
If an item is drag-dropped to somewhere in the world, this function will run.
traceRes is a full trace results table.
]]--
function ITEM:OnDragDropToWorld(traceRes)
	if !self:Event("CanPlayerInteract",false,LocalPlayer()) then return false end
	self:SendNWCommand("PlayerSendToWorld",traceRes.StartPos,traceRes.HitPos);
end

--[[
This function is run periodically (when the client ticks).
]]--
function ITEM:OnTick()

end

--[[
This function is run periodically.
You can set how often it runs by setting the think rate at the top of the script, or with self:SetThinkRate().
You need to tell the item to self:StartThink() to start the item thinking.
]]--
function ITEM:OnThink()
	
end

--[[
If this function returns true, a model panel is displayed in an ItemforgeItemSlot control, with this item's world model.
]]--
function ITEM:ShouldUseModelFor2D()
	return self.UseModelFor2D;
end

--[[
This function is run when an item slot (most likely the ItemforgeItemSlot VGUI control) is displaying this item and needs to pose this model before drawing.
Right before drawing, this event is called to pose the model (rotate, position, animate, whatever).
Since some models are orientated strangedly (for example, the pickaxe faces straight up, the keypad faces backwards, etc),
I have tried to automatically orientate it so that most models are facing acceptable angles.
	The model is posed so that:
		A. It rotates.
		B. The end with the most surface area is facing upwards
		C. The center of the model's bounding box is at 0,0,0
eEntity is a ClientsideModel() belonging to the model panel using this item's world model.
PANEL is the DModelPanel on the slot displaying eEntity.
]]--
function ITEM:OnPose3D(eEntity,PANEL)
	local min,max=eEntity:GetRenderBounds();
	local v=max-min;					--relative position, where min is at 0,0,0 and max is v
	local center=max-(v*.5);			--Center, used to position 
	
	--Orientation depends on which side of the bounding box has the most surface area
	local m=math.min(v.x,v.y,v.z);		--mINOR axe, or the axe of the bounding box that's smallest, used to determine side with most surface area
	if m==v.z then
		eEntity:SetAngles(Angle(0,(RealTime()+self:GetRand())*20,0));
	elseif m==v.y then
		eEntity:SetAngles(Angle(0,(RealTime()+self:GetRand())*20,90));
	elseif m==v.x then
		eEntity:SetAngles(Angle(90,(RealTime()+self:GetRand())*20,0));
	end
	
	eEntity:SetPos(     Vector(0,0,0)-(   eEntity:LocalToWorld(center)-eEntity:GetPos()   )        );
end

--[[
This function is called when a model associated with this item needs to be drawn. This usually happens in three cases:
	The item is in the world and it's world entity needs to draw.
	The item is being held as a weapon and it's world model attachment needs to draw
	An item slot (most likely the ItemforgeItemSlot VGUI control) is displaying this item and needs to draw this item's model.
eEntity is the entity that needs to draw.
	If this item is in the world, eEntity will be an itemforge_item entity (a SENT).
	If this item is held or is drawing in an item slot, eEntity will be a ClientsideModel().
If bTranslucent is true, this means that the entity is in the Translucent rendergroup.
	Or in other words, the entity is most likely partially see-through (has an alpha of less than 255).
]]--
function ITEM:OnDraw3D(eEntity,bTranslucent)
	if IF.UI:GetDropEntity()==eEntity then
		render.SuppressEngineLighting(true);
		render.SetAmbientLight(1,1,1);
		render.SetColorModulation(1,0.7,0);
		SetMaterialOverride(mWhite);
		local f=1 + math.abs(-1+2*math.fmod(CurTime()*5,1))*0.1;
		eEntity:SetModelScale(Vector(f,f,f));
		
		eEntity:DrawModel();
		
		eEntity:SetModelScale(oneVector);
		SetMaterialOverride(nil);
		render.SuppressEngineLighting(false);
	end
	
	local c=self:GetColor();
	render.SetColorModulation(c.r/255,c.g/255,c.b/255);
	render.SetBlend(c.a/255);
	SetMaterialOverride(self:GetOverrideMaterialMat());
	eEntity:DrawModel();
	SetMaterialOverride(nil);
end

--[[
This function is run when an item slot (most likely the ItemforgeItemSlot VGUI control) is displaying this item and needs to draw.
This function runs AFTER OnDraw3D, so any 2D overlays can be carried out here (ammo meters, item amounts, etc)
Width is the size of the slot the item is being drawn in,
and height is the height of the slot the item is being drawn in.
]]--
function ITEM:OnDraw2D(width,height)
	--If you would rather use the icon instead of a spinning 3D model
	--Here's the code to draw the item's icon in 2D
	
	--[[
	local icon,s=self:Event("GetIcon");
	if !s then return false end
	
	local c=self:GetColor();
	surface.SetMaterial(icon);
	surface.SetDrawColor(c.r,c.g,c.b,c.a);
	surface.DrawTexturedRect(0,0,width,height);
	]]--
	
	--Stackable items have amount drawn
	if self:IsStack() then
		surface.SetFont("ItemforgeInventoryFontBold");
		surface.SetTextColor(255,255,0,255);			--255,255,0 is bright yellow
		surface.SetTextPos(2,height-16);
		surface.DrawText(tostring(self:GetAmount()));
	end
end

--This function is run prior to an item being removed. It cannot cancel the item from being removed.
function ITEM:OnRemove()
	
end

--This runs when a networked var is set on this item (with SetNW* or received from the server).
function ITEM:OnSetNWVar(sName,vValue)
	--Changing the weight or amount of an item affects the weight stored in the inventory so update it
	--If the world model changes we need to update the inventory so it refreshes the model displayed
	if sName=="Amount" || sName=="Weight" || sName=="WorldModel" || sName=="OverrideMaterial" then
		local container=self:GetContainer();
		if container then container:Update() end
	end
	
	if sName=="OverrideMaterial" then
		if vValue!=nil then self.OverrideMaterialMat=Material(vValue);
		else				self.OverrideMaterialMat=nil;
		end
	end
	return true;
end