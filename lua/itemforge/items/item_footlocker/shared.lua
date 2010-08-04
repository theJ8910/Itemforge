--[[
item_footlocker
SHARED

A lockable container.
]]--

include("inv_footlocker.lua");

if SERVER then

AddCSLuaFile("shared.lua");
AddCSLuaFile("inv_footlocker.lua")

end

ITEM.Name="Footlocker";
ITEM.Description="A sturdy wooden box. It's ";
ITEM.Base="base_container";

ITEM.WorldModelOpen = "models/props/CS_militia/footlocker01_open.mdl";
if SERVER then umsg.PoolString(ITEM.WorldModelOpen); end

ITEM.WorldModelClosed = "models/props/CS_militia/footlocker01_closed.mdl";
if SERVER then umsg.PoolString(ITEM.WorldModelClosed); end

ITEM.WorldModel=ITEM.WorldModelOpen;

if SERVER then
	ITEM.GibEffect = "wood";
end

ITEM.Size=30;					--This is the bounding radius of the footlocker model.
ITEM.Weight=15513;				--Weighs 15.5kg (around 34.2 pounds)
ITEM.MaxHealth=500;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Container stuff
ITEM.InvTemplate="inv_footlocker";

--Footlocker
ITEM.OpenSound=Sound("doors/latchunlocked1.wav");
ITEM.CloseSound=Sound("doors/handle_pushbar_locked1.wav");
ITEM.LockedSound=Sound("doors/latchlocked2.wav");

--[[
* SHARED
* Event

Is basically the same as Base Container's OnUse,
except if the footlocker is locked, we use the lock item instead.
]]--
function ITEM:OnUse(pl)
	--View contents of open footlockers (default behavior)
	if self:IsOpen() then
		return self:BaseEvent("OnUse",false,pl);
	end
	
	--[[
	Since we've established it's not open, there's a good chance it's also locked.
	The next action we take depends on if the footlocker is locked or not.
	
	Locking, unlocking, opening and closing are serverside actions, so we only
	bother to take them if the item is being used on the server. In the case
	it's being used on the client we tell the client to run it on the server instead
	by returning true.
	]]--
	if SERVER then
		--Unlock closed, locked footlockers
		if self:IsLocked() then
			local l=self:GetLock();
			if l then l:Use(pl); end
		--Open closed footlockers
		else
			self:PlayerOpen(pl);
		end
	end
	
	return true;
end

--[[
* SHARED
* Event

Dynamic item description. In addition to the "sturdy wooden box" text (self.Description),
we also tell whether or not the box is locked or not.
If a lock is attached, we include the name of the lock in the description.
]]--
function ITEM:GetDescription()
	local d=self.Description;
	if self:IsOpen() then	d=d.."open."
	else					d=d.."closed."
	end
	
	local l=self:GetLock();
	if l then
		if self:IsLocked() then	d=d.."\nA locked ";
		else					d=d.."\nAn unlocked ";
		end
		
		d=d..l:Event("GetName","unknown lock").." is attached.";
	else
		d=d.."\nThere is a place for a lock to secure possessions."
	end
	return d;
end

--[[
* SHARED

If the footlocker has a lock item, this function returns it.
]]--
function ITEM:GetLock()
	return self:GetNWItem("LockItem");
end

--[[
* SHARED

If the footlocker is locked, returns true. False is returned otherwise.
]]--
function ITEM:IsLocked()
	return self:GetNWBool("Locked");
end

--[[
* SHAREd

If the footlocker is open, this function returns true.
False is returned otherwise.
]]--
function ITEM:IsOpen()
	--If the inventory is locked that means the footlocker is closed
	local inv=self:GetInventory();
	if !inv then return true end
	
	return !inv:IsLocked();
end

--[[
* SHARED

Opens the footlocker.
This unlocks the inventory, allowing players to interact with it's contents.
]]--
function ITEM:PlayerOpen(pl)
	if !self:Event("CanPlayerInteract",nil,pl) then return false end
	if self:IsLocked() then self:EmitSound(self.LockedSound); return false end
	
	if SERVER then
		self:EmitSound(self.OpenSound);
		self:SetWorldModel(self.WorldModelOpen);
		local inv=self:GetInventory();
		if inv then inv:Unlock(); end
	else
		self:SendNWCommand("PlayerOpen");
	end
end

--[[
* SHARED

Closes the footlocker.
This locks the inventory, stopping players from interacting with it's contents.
]]--
function ITEM:PlayerClose(pl)
	if !self:Event("CanPlayerInteract",nil,pl) then return false end
	if self:IsLocked() then self:EmitSound(self.LockedSound); return false end
	
	if SERVER then
		self:EmitSound(self.CloseSound);
		self:SetWorldModel(self.WorldModelClosed);
		local inv=self:GetInventory();
		if inv then inv:Lock(); end
	else
		self:SendNWCommand("PlayerClose");
	end
end

if SERVER then




--[[
* SERVER
* Event

When you try to attach a lock if this function returns false the attachment is denied.
]]--
function ITEM:CanAttachLock(lockItem)
	return self:GetLock()==nil;
end

--[[
* SERVER
* Event

Runs when a lock item is attached.
Returning false denies the lock from being attached.
]]--
function ITEM:OnAttachLock(lockItem)
	if self:Event("CanAttachLock",false,lockItem)==false then return false end
	
	lockItem:ToVoid();
	self:SetNWItem("LockItem",lockItem);
	
	return true;
end

--[[
* SERVER
* Event

Runs when the attached lock is taken off.
]]--
function ITEM:OnDetachLock(item)
	if self:GetNWItem("LockItem")!=item then return false end
	self:SetNWItem("LockItem",nil);
end

--[[
* SERVER

Locks the footlocker. This stops the footlocker from being opened/closed.
]]--
function ITEM:Lock()
	self:SetNWBool("Locked",true);
end

--[[
* SERVER

Unlocks the footlocker. This allows the footlocker to be opened/closed.
]]--
function ITEM:Unlock()
	self:SetNWBool("Locked",false);
end

--[[
* SERVER
* Event

The lock can take damage.
]]--
function ITEM:OnEntTakeDamage(entity,dmgInfo)
	local lock=self:GetLock();
	
	if lock then
		local totalDamage=dmgInfo:GetDamage();
		local footlockerDamage=totalDamage*.60;
		
		self:Hurt(footlockerDamage,dmgInfo:GetAttacker());
		lock:Hurt(totalDamage-footlockerDamage,dmgInfo:GetAttacker());
	else
		self:Hurt(dmgInfo:GetDamage(),dmgInfo:GetAttacker());
	end
	
	--GetWeaponItem(eWep)
	entity:TakePhysicsDamage(dmgInfo);
end

--[[
* SERVER
* Event

Remove any attached lock items
]]--
function ITEM:OnRemove()
	local l=self:GetLock();
	if l then l:Remove() end
end

IF.Items:CreateNWCommand(ITEM,"PlayerOpen",function(self,...) self:PlayerOpen(...) end);
IF.Items:CreateNWCommand(ITEM,"PlayerClose",function(self,...) self:PlayerClose(...) end);




else



--[[
* CLIENT
* Event

If there's a lock attached we add a submenu to the footlocker's menu where you can interact with it.
]]--
function ITEM:OnPopulateMenu(pMenu)
	self:InheritedEvent("OnPopulateMenu","base_item",nil,pMenu);
	
	if self:IsOpen() then
		pMenu:AddOption("Close",		 function(panel) self:Event("PlayerClose",nil,LocalPlayer()) end);
		pMenu:AddOption("Check Contents",function(panel) self:Event("ShowInventory",nil,LocalPlayer()) end);
	else
		pMenu:AddOption("Open",			 function(panel) self:Event("PlayerOpen",nil,LocalPlayer()) end);
	end
	
	--If we have a lock attached, we'll create a submenu that contains everything on it's menu
	local l=self:GetLock();
	if l then
		local name=l:Event("GetName","Unknown Lock");
		local sub=pMenu:AddSubMenu(name);
		l:Event("OnPopulateMenu",nil,sub);
	end
end

--[[
* CLIENT
* Event

The footlocker is posed strangely when it's open, so I force it to always
be posed upright.
]]--
function ITEM:OnPose3D(eEntity,panel)
	self:PoseUprightRotate(eEntity);
end

IF.Items:CreateNWCommand(ITEM,"PlayerOpen");
IF.Items:CreateNWCommand(ITEM,"PlayerClose");




end

IF.Items:CreateNWVar(ITEM,"LockItem","item");
IF.Items:CreateNWVar(ITEM,"Locked","bool");