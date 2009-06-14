--[[
events_client
CLIENT

item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is item/events_client.lua, so this item's type is "item")

This specific file deals with events that are present on the client.
]]--

--[[
ENTITY SPECIFIC EVENTS
]]--

--[[
Whenever an item is dropped into the world, an entity is created to represent it.
This function runs when the entity sets it's item to us clientside.

NOTE: It is impossible for me to run this event when the entity is initialized clientside.
	Serverside, a networked int with this Item's ID is set on the entity.
	This function runs when the entity "acquires" this item's ID clientside and sets it's item to this item.
	It may take a short period of time (maybe a few seconds) after the entity arrives clientside for the ID of the item it's supposed to use to arrive and be set.
	When that occurs, this function will run; keep this in mind.
ENT is the SENT table - it's "ENT".
eEntity is the SENT that is created to hold the object. It's "ENT.Entity".
]]--
function ITEM:OnEntityInit(ENT,eEntity)
	return true;
end

--[[
This function runs when it comes time to draw the model of an item in the world.
eEntity is the entity that needs to draw a model. This would be the itemforge_item entity. This is basically the same thing as self.Entity in an entity.
ENT is ENT table. It's the same thing as eEntity:GetTable().
if bTranslucent is true, then the entity called DrawWorldModelTranslucent instead of DrawWorldModel.
	DrawTranslucent deals with transparent entities, so if bTranslucent is true, the entity is somewhat see-through.
]]--
function ITEM:OnEntityDraw(eEntity,ENT,bTranslucent)
	local c=self:GetNWColor("Color");
	render.SetColorModulation(c.r/255,c.g/255,c.b/255);
	render.SetBlend(c.a/255);
	
	eEntity:DrawModel();
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
	
	--Grab the item's name; if it can't be grabbed the SWEP's name is Itemforge Item by default
	local s,r=pcall(self.GetName,self)
	if !s then	ErrorNoHalt(r.."\n")
	elseif type(r)=="string" then SWEP.PrintName=r
	end
	
	return true;
end

--[[
Whenever the item is being held as a weapon, it will appear in the weapons menu.
The weapons menu will want to draw an icon for the weapon. The weapon icon will be drawn
inside of a black box whose top-left corner is at x,y and who is "width" pixels wide and "height" pixels high.
Alpha is how opaque the icon should be drawn (because the menu will fade out if it's left open for too long)
]]--
function ITEM:OnSWEPDrawMenu(x,y,width,height,alpha)
	local s,r=pcall(self.GetIcon,self);
	if !s then ErrorNoHalt(r.."\n") end
	
	local c=self:GetNWColor("Color");
	surface.SetMaterial(r);
	surface.SetDrawColor(c.r,c.g,c.b,alpha-(255-c.a));
	surface.DrawTexturedRect(x+((width-64)*.5),y+((height-64)*.5)+(math.sin(CurTime()*5)*16),64,64);
end

--[[
This function runs when drawing the world model of a held item.
eEntity is the weapon entity. This would be the itemforge_item_held entity. This is basically the same thing as self.Weapon in an SWEP.
SWEP is SWEP table. It's the same thing as eEntity:GetTable().
if bTranslucent is true, then the entity called DrawWorldModelTranslucent instead of DrawWorldModel.
	DrawTranslucent deals with transparent entities, so if bTranslucent is true, the entity is somewhat see-through.
TODO item color
]]--
function ITEM:OnSWEPDraw(eEntity,SWEP,bTranslucent)
	
end

--This function is run when it comes time to draw a viewmodel. This will only happen while a player is holding an item
function ITEM:OnSWEPDrawViewmodel()
end

--[[
This is run when a player is holding the item as an SWEP and presses the left mouse button (primary attack).
]]--
function ITEM:OnPrimaryAttack()
end

--[[
This is run when a player is holding the item as an SWEP and presses the right mouse button (secondary attack).
]]--
function ITEM:OnSecondaryAttack()
end

--[[
This is run when a player is holding the item as an SWEP and presses the reload button (usually the "R" key).
]]--
function ITEM:OnReload()
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
	--Grab the item's name.
	local s,r=pcall(self.GetName,self)
	if !s then
		ErrorNoHalt(r.."\n");
		r="Itemforge Item";
	end
	
	--Header code; this panel is the yellow background of the header
	local p=vgui.Create("DPanel");
	p:SetTall(20);
	p.Paint=function(self)
		surface.SetDrawColor(255,201,0,255);
		surface.DrawRect(0,0,self:GetSize());
		return true;
	end
	
	--Header code; this panel is the black text on the header
	local l=Label(r,p)
	l:SetTextColor(Color(0,0,0,255));
	l:SetContentAlignment(4);
	l:SetTextInset(5);
	l:SizeToContents();
	l:SetPos(0,3);
	
	--Add header
	pMenu:AddPanel(p);
	pMenu:AddOption("Use",function(panel) self:Use(LocalPlayer()) end);
	pMenu:AddOption("Hold",function(panel) self:Hold(LocalPlayer()) end);
	
	if self:GetMaxAmount()!=1 && self:GetAmount()>1 then
		--We can split stacks, as long as there are enough items to split (at least 2)
		--TODO
		pMenu:AddOption("Split",function(panel) end);
	end
end

--[[
While an inventory is opened, this item can be dragged somewhere on screen.
If this item is drag-dropped to an empty slot in an inventory this function runs.
]]--
function ITEM:OnDragDropToInventory(inv,invSlot)
	self:SendNWCommand("PlayerSendToInventory",inv,invSlot);
end

--[[
While an inventory is opened, this item can be dragged somewhere on screen.
If this item is drag-dropped onto another item, this function runs.
This function will not run if the other item's OnDragDropHere function returns false.
]]--
function ITEM:OnDragDropToItem(item)
end

--[[
While an inventory is opened, an item can be dragged somewhere on screen.
If an item is drag-dropped on top of this item (either dropped on a panel this item is being displayed on, or dropped onto this item in the world) this function runs.
A few examples of what this could be used for... You could:
	Merge a pile of items
	Transfer the item to this item's inventory
	Load a gun with ammo

Return true if you want otherItem's OnDragDropToItem to run.
]]--
function ITEM:OnDragDropHere(otherItem)
	self:SendNWCommand("PlayerMerge",otherItem);
	return true;
end

--[[
While an inventory is opened, an item can be dragged somewhere on screen.
If an item is drag-dropped to somewhere in the world, this function will run.
traceRes is a full trace results table.
]]--
function ITEM:OnDragDropToWorld(traceRes)
	self:SendNWCommand("PlayerSendToWorld",traceRes.HitPos);
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
	if !self.Rand then self.Rand=math.random()*100 end
	local r=(RealTime()+self.Rand)*20;
	
	local min,max=eEntity:GetRenderBounds();
	local v=max-min;					--relative position, where min is at 0,0,0 and max is v
	local m=math.min(v.x,v.y,v.z);		--mINOR axe, or the axe of the bounding box that's smallest, used to determine side with most surface area
	local center=max-(v*.5);			--Center, used to position 
	
	--Orientation depends on which side of the bounding box has the most surface area
	if m==v.z then
		eEntity:SetAngles(Angle(0,r,0));
	elseif m==v.y then
		eEntity:SetAngles(Angle(0,r,90));
	elseif m==v.x then
		eEntity:SetAngles(Angle(90,r,0));
	end
	eEntity:SetPos(     Vector(0,0,0)-(   eEntity:LocalToWorld(center)-eEntity:GetPos()   )        );
end

--[[
This function is run when an item slot (most likely the ItemforgeItemSlot VGUI control) is displaying this item and needs to draw this item's model.
eEntity is the ClientsideModel() belonging to the model panel using this item's world model.
PANEL is the DModelPanel on the slot displaying eEntity.
If bTranslucent is true, the entity is partially see-through (it has an alpha of less than 255).
]]--
function ITEM:OnDraw3D(eEntity,PANEL,bTranslucent)
	local c=self:GetNWColor("Color");
	render.SetColorModulation(c.r/255,c.g/255,c.b/255);
	render.SetBlend(c.a/255);
	
	eEntity:DrawModel();
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
	local s,r=pcall(self.GetIcon,self);
	if !s then ErrorNoHalt(r.."\n") end
	local c=self:GetNWColor("Color");
	surface.SetMaterial(r);
	surface.SetDrawColor(c.r,c.g,c.b,c.a);
	surface.DrawTexturedRect(0,0,width,height);
	]]--
	
	--Stackable items have amount drawn
	if self:GetMaxAmount()!=1 then
		surface.SetFont("ItemforgeInventoryFontBold");
		surface.SetTextColor(255,255,0,255);			--255,255,0 is bright yellow
		surface.SetTextPos(2,height-16);
		surface.DrawText(tostring(self:GetAmount()));
	end
end

--[[
This function is called when the item leaves the world (when it's world entity is being removed clientside).
ent is the item's world entity. It should be the same as self:GetEntity().
Clientside, we don't have any real way to know if a removal was forced or not.
Additionally, clientside returning true or false cannot stop the item from leaving the world.
]]--
function ITEM:OnWorldExit(ent)
end

function ITEM:OnRelease(pl,forced)
	return true;
end

function ITEM:OnMove(OldInv,OldSlot,NewInv,NewSlot,forced)
end

--This function is run prior to an item being removed. It cannot cancel the item from being removed.
function ITEM:OnRemove()
	
end

--This runs when a networked var is set on this item (with SetNW* or received from the server).
function ITEM:OnSetNWVar(sName,vValue)
	--Changing the weight or amount of an item affects the weight stored in the inventory so update it
	--If the world model changes we need to update the inventory so it refreshes the model displayed
	if sName=="Amount" || sName=="Weight" || sName=="WorldModel" then
		local container=self:GetContainer();
		if container then container:Update() end
	end
	return true;
end