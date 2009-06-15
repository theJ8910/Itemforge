--[[
itemforge_item_held
CLIENT

This SWEP is an 'avatar' of an item. When an item is held, this weapon represents that item.
]]--
include("shared.lua")

language.Add("itemforge_item_held","Item (held)");

SWEP.PrintName			= "Itemforge Item";
SWEP.Slot				= 5;
SWEP.SlotPos			= 0;
SWEP.DrawAmmo			= false;
SWEP.DrawCrosshair		= true;
SWEP.DrawWeaponInfoBox	= false;
SWEP.BounceWeaponIcon   = false;
SWEP.SwayScale			= 1.0;
SWEP.BobScale			= 1.0;
SWEP.RenderGroup 		= RENDERGROUP_OPAQUE;

SWEP.WM			= nil;							--World Model attachment.

--Panels
SWEP.ItemPanel=nil;

--[[
Can't change the SWEP's world model dynamically, so I made this function to create an imitation world model.
If the item hasn't been acquired yet we'll keep trying to do that until we get it.
This creates a prop_physics clientside and moves it to the player's right hand. I may change it to allow left hand too.
]]--

--[[
If an item hasn't been received clientside, 
This is run any time acquiring an item is necessary. 
Right now, items are acquired if they don't exist on think or on world model creation.
The item is returned if it was acquired.
False is returned if acquiring was not possible at the moment.
]]--
function SWEP:AcquireItem()
	if !self:HasOwner() || self:IsBeingRemoved() then return false end
	
	local i=self.Weapon:GetNWInt("i");
	if i==nil || i==0 then return false end
	
	local item=IF.Items:Get(i);
	if item && item:IsValid() then
		self:SetItem(item);
		return item;
	else
		return false;
	end
end

function SWEP:ShowWorldModel()
	if self.WM || self.WM==false then return true end
	
	--Assert that we have an item set. If not, try to acquire
	local item=self:GetItem();
	if !item then
		item=self:AcquireItem();
		if !item then return false end
	end
	
	--What world model does our item want?
	self.WM=IF.GearAttach:ToBone(self.Owner,item:GetWorldModel(),"ValveBiped.Bip01_R_Hand");
	if !self.WM then
		self.WM=IF.GearAttach:ToAP(self.Owner,item:GetWorldModel(),"anim_attachment_RH",item.WorldModelNudge,item.WorldModelRotate);
	end
	
	return true;
end

function SWEP:HideWorldModel()
	if self.WM then self.WM=nil end
	return true;
end

function SWEP:MakePanel()
	if !self.ItemPanel then
		local slot=vgui.Create("ItemforgeItemSlot");
		
		slot:SetSize(64,64);
		slot:SetPos(2,2);
		slot:SetDraggable(true);
		slot:SetDroppable(false);
		
		local item=self:GetItem();
		if !item then item=self:AcquireItem(); end
		if item then slot:SetItem(item) end
		
		self.ItemPanel=slot;
	end
end

function SWEP:RemovePanel()
	if self.ItemPanel then
		if self.ItemPanel:IsValid() then self.ItemPanel:Remove(); end
		self.ItemPanel=nil;
	end
end

--The item this entity is supposed to be representing may not be known or exist clientside when the item is created. We'll search for it until we find it.
function SWEP:Think()
	if !self:HasOwner() then return true end
	
	local item=self:GetItem();
	if !item then
		item=self:AcquireItem()
		if !item then return true end
	end
	
	--If this player is wielding this weapon in first person, we hide the world model if it exists
	if LocalPlayer()==GetViewEntity() && self.eWM!=nil then
		self:HideWorldModel();
	end 
end

--[[
When we remove the SWEP, we check to see if our item in question still exists.
If it does, we make sure that the item is still inside of the SWEP.
If it is, we remove the item along with the SWEP.
]]--
function SWEP:OnRemove()
	--Don't re-acquire an item.
	self.Weapon:SetNWInt("i",0);
	self.BeingRemoved=true;
	
	--We get rid of the world model and item panel when we get rid of the weapon.
	self:HideWorldModel();
	self:RemovePanel();
	
	--Clear the weapon's connection to the item (this weapon "forgets" this item was inside of it)
	local item=self:GetItem();
	if !item then return true end
	self.Item=nil;
	
	--Clear the item's connection to the weapon (the item "forgets" that this was it's weapon)
	if item:GetWeapon()==self.Weapon then item:ClearWeapon() end
	
	return true;
end

--Weapon is being put away
function SWEP:Holster(wep)
	Msg("Holstering weapon!\n");
	
	--Hide the world model, holstering the weapon.
	self:HideWorldModel();
	self:RemovePanel();
	
	return true;
end

--Weapon is being swapped to
function SWEP:Deploy()
	Msg("Deploying weapon!\n");
	
	
	--Whenever the owner swaps to this weapon, we change his viewmodel to the item's viewmodel.
	if LocalPlayer()==self.Owner then self.Owner:GetViewModel():SetModel(self.ViewModel); end
	
	self:MakePanel();
	
	return true;
end

--Draw weapon selection menu stuff, hooks into item's OnDrawWeaponSelection hook
function SWEP:DrawWeaponSelection(x,y,width,height,alpha)
	local item=self:GetItem();
	if !item then
		item=self:AcquireItem();
		if !item then return true end
	end
	
	local s,r=pcall(item.OnSWEPDrawMenu,item,x,y,width,height,alpha);
	if !s then ErrorNoHalt(r.."\n") end;
	return true;
end

--Draw view model, hooks into item's OnDrawViewmodel hook
function SWEP:ViewModelDrawn()
	local item=self:GetItem();
	if !item then
		item=self:AcquireItem();
		if !item then return true end
	end
	
	local s,r=pcall(item.OnSWEPDrawViewmodel,item);
	if !s then ErrorNoHalt(r.."\n") end;
	return true;
end

--Draw world model, hooks into item's Draw3D hook
function SWEP:DrawWorldModel()
	if !self.WM then	self:ShowWorldModel();	end
	if self.WM then		self.WM:Draw();			end
	
	local item=self:GetItem();
	if !item then
		item=self:AcquireItem();
		if !item then return true end
	end
	
	local s,r=pcall(item.OnSWEPDraw,item,self.Weapon,self,false);
	if !s then ErrorNoHalt(r.."\n") end;
	return true;
end

--Draw world model, hooks into item's Draw3D hook
function SWEP:DrawWorldModelTranslucent()
	if !self.WM then	self:ShowWorldModel();	end
	if self.WM then		self.WM:Draw();			end
	
	local item=self:GetItem();
	if !item then
		item=self:AcquireItem();
		if !item then return true end
	end
	
	local s,r=pcall(item.OnSWEPDraw,item,self.Weapon,self,true);
	if !s then ErrorNoHalt(r.."\n") end;
	return true;
end

--May allow items to take advantage of this later
function SWEP:CustomAmmoDisplay()
end

--May allow items to take advantage of this later
function SWEP:DrawHUD()
end

--[[
May allow items to take advantage of this later
Use GetNetworked* functions (entity) to restore data from a save-game
]]--
function SWEP:OnRestore()
end

--May allow items to take advantage of this later
function SWEP:FreezeMovement()
	return false;
end

--May allow items to take advantage of this later
function SWEP:GetViewModelPosition(pos,ang)
	return pos,ang;
end


--May allow items to take advantage of this later
function SWEP:TranslateFOV(current_fov)
	return current_fov;
end

--May allow items to take advantage of this later
function SWEP:AdjustMouseSensitivity()
	return nil;
end


--A lot of notes, code snippets, and console dumps here for my research on rotating angles


--[[
Creates a world model clientside.
This is called whenever a world model needs to be drawn and a world model hasn't been created yet.
In the case the SWEP hasn't associated with the correct item yet, we'll try to acquire it. Failing that, no world model will be created and false will be returned.
On success though, a world model will be created, self.eWM will be set to it, and the new entity returned.
]]--
--[[
function SWEP:CreateWorldModel()
	--Assert that we have an item set - if not, try to acquire
	local item=self:GetItem();
	if !item && !self:AcquireItem() then return false end
	
	--Create the world model
	local ent=ClientsideModel(item:GetWorldModel(),RENDER_GROUP_OPAQUE_ENTITY);
	
	--Fail if there was some reason it couldn't be created.
	if !ent || !ent:IsValid() then
		ErrorNoHalt("Itemforge Item SWEP (Ent ID "..self.Weapon:EntIndex().."): Tried to create a world model, but couldn't for some reason!\n");
		return false;
	end
	
	--Initial positioning of ent
	ent:SetPos(Vector(0,0,0));
	ent:SetAngles(Angle(0,0,0));
	
	--Set world model to this ent
	self.eWM=ent;
	return true;
end
]]--

--[[
Returns the world position of the SWEP Owner's right hand.
Sets self.OwnerAP - the index of the owner's right hand - if it isn't already set.
Returns position,angle (of the Owner's right hand) if successful, or nil if not.
]]--
--[[
function SWEP:GetOwnerRH()
	if !self.OwnerAP then
		self.OwnerAP=self.Owner:LookupBone("ValveBiped.Bip01_R_Hand");
		if !self.OwnerAP then return nil end
	end
	
	return self.Owner:GetBonePosition(self.OwnerAP);
end
]]--

--[[
Returns the local position of the Weapon's right hand (it's a bone on some weapons that determines where the weapon is placed in relation to the owner's hand).
Sets self.WeaponAP - the index of the weapon's right hand - if it isn't already set. Also sets self.WeaponAPPos and self.WeaponAPAng.
Returns position,angle (of the Weapon's right hand) local to the weapon if successful, or nil if not.
]]--
--[[
function SWEP:GetWeaponRH()
	if !self.WeaponAP then
		self.WeaponAP=self.eWM:LookupBone("ValveBiped.Bip01_R_Hand");
		if !self.WeaponAP then return nil end
		
		self.WeaponAPPos,self.WeaponAPAng=self.eWM:GetBonePosition(self.WeaponAP);
	end
	
	
	return self.WeaponAPPos*1,self.WeaponAPAng*1;
	
	
	--if !self.WeaponAPPos || !self.WeaponAPAng then
	--	
	--end
	
	
	--local pos,ang=self.eWM:GetBonePosition(self.WeaponAP);
	--pos=self.eWM:WorldToLocal(pos);
	--ang=self.eWM:WorldToLocalAngles(ang);
	
	--return pos,ang;
end
]]--

--[[
This is run when the SWEP needs a world model drawn. It moves an existing model into the right place.
If the world model doesn't exist yet we'll create it.
This will not be run on the client of the owner unless he switches to third person.
Our think function below will remove the world model if it's out while in first person.
]]--
--[[
function SWEP:MoveWorldModel()
	--This function should only be called while being held (for a brief period of time this weapon may be in the world, outside of a player's hands)
	if !self:HasOwner() then return false end
	
	--If we haven't created the world model yet we need to do that first
	if !self.eWM then return self:CreateWorldModel(); end
	
	local pos,a=self:GetOwnerRH();
	local pos2,b=self:GetWeaponRH();
	if pos2 then
		--C is our "working angle"; this angle rotates while we rotate b into position. We set the entity's angle to this after the rotations have finished.
		local c=Angle(0,0,0);
		
		--Get offset of reference angles(b) from hand angles(a)
		local offset=a-b;
		
		--Rotate to match hand's roll
		c:RotateAroundAxis(b:Forward(),offset.r);
		
		--Rotate to match hand's yaw
		c:RotateAroundAxis(Up,offset.y);
		
		
		--Rotate to match hand's pitch (pitch is reversed because it actually rotates around the left axis, not the right; the only difference makes is the direction it rotates around the axis)
		b.y=a.y;
		b.p=0;
		b.r=0;
		c:RotateAroundAxis(b:Right(),-offset.p);
		
		self.eWM:SetAngles(c);
		self.eWM:SetPos(pos-(    self.eWM:LocalToWorld(pos2) - self.eWM:GetPos()    ));
		
		return true;
	else
		--TODO use attachment instead of bones for stuff with no reference point (?)
		--a:RotateAroundAxis(a:Forward(),180);
		--a:RotateAroundAxis(a:Up(),180);
		
		--self.eWM:SetPos(pos);
		--self.eWM:SetAngles(a);
		return true;
	end
end
]]--
--[[

--This is run when holstering the weapon, removing it, or when going from third-person to first person
function SWEP:RemoveWorldModel()
	if self.eWM && self.eWM:IsValid() then self.eWM:Remove(); end
	self.eWM=nil;
end

]]--

--NOTE: CBaseCombatWeapon::Equip, basecombatweapon_shared.cpp

--Angle(pitch,yaw,roll)
--[[
AXIS|      ROTATION AROUND AXIS CALLED
----+---------------------------------
x   |      ROLL
y   |      PITCH
z   |      YAW
]]--
--[[
if self.WeaponAP==nil then
	self.WeaponAP=self.Owner:LookupAttachment("anim_attachment_RH");
end

local item=self:GetItem();
if !item then return false end

--Move the model into position
local ap=self:GetRHAttachment();

--Copy this attachment point's angle
local newAng=Angle(ap.Ang.p,ap.Ang.y,ap.Ang.r);




--TODO probably need to find a more efficent way of doing this

newAng:RotateAroundAxis(newAng:Forward(),item.WorldModelRotate.r);
newAng:RotateAroundAxis(newAng:Right(),item.WorldModelRotate.p);
newAng:RotateAroundAxis(newAng:Up(),item.WorldModelRotate.y);

local xNudge=(ap.Ang:Forward()*item.WorldModelNudge.x);
local yNudge=(ap.Ang:Right()*item.WorldModelNudge.y);
local zNudge=(ap.Ang:Up()*item.WorldModelNudge.z);

self.eWM:SetPos(ap.Pos+xNudge+yNudge+zNudge);
self.eWM:SetAngles(newAng);
]]--

--[[
> offset=BOX:GetAngles()-BOX2:GetAngles()...
> ang=BOX2:GetAngles()...
> ang:RotateAroundAxis(Vector(0,0,1),offset.y)...
> BOX2:SetAngles(ang)...
> ang=BOX2:GetAngles()...
> ang:RotateAroundAxis(BOX2:GetForward(),offset.r)...
> BOX2:SetAngles(ang)...
> print(BOX:GetAngles(),BOX2:GetAngles())...
26.748 10.221 21.321	3.997 10.221 21.321
> print(BOX:GetAngles(),BOX2:GetAngles())...
26.748 10.221 21.321	3.997 10.221 21.321
> BOX3:SetAngles(Angle(0,10.221,0))...
> ang=BOX2:GetAngles()...
> ang:RotateAroundAxis(BOX3:GetRight(),-offset.p)...
> BOX2:SetAngles(ang)...
> print(BOX:GetAngles(),BOX2:GetAngles())...
26.748 10.221 21.321	26.748 10.221 21.321
]]--

--[[
--The DrawAngle function is here to help me visualize angles. This draws three lines representing the local axes of an angle, at a given point.
function SWEP:DrawAngle(pos,angle)
	local c=pos:ToScreen();
	if !c.visible then return false end
	local f=(pos+(angle:Forward()*4)):ToScreen();
	if !f.visible then return false end
	local r=(pos+(angle:Right()*4)):ToScreen();
	if !r.visible then return false end
	local u=(pos+(angle:Up()*4)):ToScreen();
	if !u.visible then return false end
	
	surface.SetDrawColor(255,0,0,255);
	surface.DrawLine(c.x,c.y,f.x,f.y);
	surface.SetDrawColor(0,255,0,255);
	surface.DrawLine(c.x,c.y,r.x,r.y);
	surface.SetDrawColor(0,0,255,255);
	surface.DrawLine(c.x,c.y,u.x,u.y);
end
]]--