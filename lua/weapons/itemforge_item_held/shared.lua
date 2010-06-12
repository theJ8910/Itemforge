--[[
itemforge_item_held
SHARED

This SWEP is an 'avatar' of an item. When an item is held, this weapon represents that item.
]]--
SWEP.Author			= "theJ89"
SWEP.Contact		= "theJ89@charter.net"
SWEP.Purpose		= "This SWEP is a part of Itemforge. When an item is held, this weapon turns into the item you're holding."
SWEP.Instructions	= "This will be spawned by the game when an item is held by a player. You can interact with the item by switching to this weapon then using left mouse, right mouse, etc."

SWEP.Spawnable = false;
SWEP.AdminSpawnable = false;

SWEP.ViewModel		= "models/weapons/v_crowbar.mdl";
SWEP.WorldModel		= "models/weapons/w_crowbar.mdl";

SWEP.Primary.ClipSize		= 0;
SWEP.Primary.DefaultClip	= 0;
SWEP.Primary.Automatic		= false;
SWEP.Primary.Ammo			= "none";

SWEP.Secondary.ClipSize		= 0;
SWEP.Secondary.DefaultClip	= 0;
SWEP.Secondary.Automatic	= false;
SWEP.Secondary.Ammo			= "none";

--May change
SWEP.ViewModelFOV	= 62;
SWEP.ViewModelFlip	= false;

SWEP.BeingRemoved=false;

--[[
* SHARED

Set up the first DT int to be the item ID.
This is good because when the weapon gets created the item ID goes with it!
This pretty much fixes the HUD reporting a pickup of "Itemforge Item" whenever you hold the
weapon, although it's still possible (e.g. given the weapon before the item is created on
the client, in the case that an item is created held by a player).
]]--
function SWEP:SetupDataTables()
	self:DTVar("Int",0,"i");
end

--[[
* SHARED

Set item this is associated with
]]--
function SWEP:SetItem(item)
	if self.BeingRemoved || !item then return false end
	self.Item=item;
	
	--Initialize the SWEP - take care of some basic things like setting the world+view models, whether or not the weapon is automatic, setting the display name, etc
	item:Event("OnSWEPInit",nil,self,self.Weapon);
	
	if SERVER then
		--Inform this entity what item ID to look for when pairing clientside
		self.Weapon:SetDTInt("i",item:GetID());
	else
		item:Hold(self.Owner,nil,self.Weapon,false);
		self:UpdateViewmodel();
	end
	return true;
end

--[[
* SHARED

Returns the item that is piloting this SWEP.
]]--
function SWEP:GetItem()
	--Don't have an item yet, lets try to acquire it
	if !self.Item then	
		if CLIENT then
			local item=IF.Items:Get(self.Weapon:GetDTInt("i"));
			if self:HasOwner() && !self:IsBeingRemoved() && !self:SetItem(item) then
				return nil;
			elseif item then
				--Proper initialization requires that the weapon already has been picked up,
				--but in order for the name to appear correctly we can set the item's
				--name here.
				self.PrintName = item:Event("GetName","Itemforge Item");
			end
		end
	
	--We had an item set but it's not valid any more
	elseif !self.Item:IsValid() then
		self.Item=nil;
	end
	
	return self.Item;
end

--[[
* SHARED

Returns true if the SWEP has a valid owner, false otherwise
If the item hasn't been picked up yet this is nil
]]--
function SWEP:HasOwner()
	return self.Owner && self.Owner:IsValid();
end

--[[
* SHARED

Is the entity being removed right now?
]]--
function SWEP:IsBeingRemoved()
	return self.BeingRemoved;
end

--[[
* SHARED

Updates the viewmodel to the one the item says the weapon should use
]]--
function SWEP:UpdateViewmodel()
	local pl=self.Owner;
	if !pl || self.Weapon!=pl:GetActiveWeapon() then return false end
	
	if SERVER || pl==LocalPlayer() then
		local vm=pl:GetViewModel();
		vm:SetModel(self.ViewModel);
		vm:ResetSequenceInfo();
	end
	
	return true;
end

--[[
* SHARED

Weapon initilization is carried out at link time
]]--
function SWEP:Initialize()
	--HACK
	self:Register();
	
	--Attempt to acquire at initialization time
	self:GetItem();
end

--[[
* SHARED

Itemforge-based holster event
A different weapon is being swapped to
]]--
function SWEP:IFHolster(wep)
	local item=self:GetItem();
	if !item then return true end
		
	return item:Event("OnSWEPHolsterIF",true);
end

--[[
* SHARED

Source-based holster event
This weapon is being swapped to
]]--
function SWEP:Holster()
	local item=self:GetItem();
	if !item then return true end
	
	return item:Event("OnSWEPHolster",true);
end

--[[
* SHARED

Source-based deploy event
This weapon is being deployed
]]--
function SWEP:Deploy()
	if SERVER then
		self:UpdateViewmodel();
		--self.Owner:DrawViewModel(false);
	end
	
	local item=self:GetItem();
	if !item then return true end
	
	item:Event("OnSWEPDeploy",true);
end

--[[
* SHARED

Itemforge-based deploy event
This weapon is being swapped to
]]--
function SWEP:IFDeploy()
	if SERVER then
		--self.Owner:DrawViewModel(false);
	end
	
	local item=self:GetItem();
	if !item then return true end
	
	return item:Event("OnSWEPDeployIF",true);
end

--[[
* SHARED

Do we need to precache anything?
]]--
function SWEP:Precache()
end

--[[
* SHARED

Reroute to item's OnSWEPPrimaryAttack
]]--
function SWEP:PrimaryAttack()
	local item=self:GetItem();
	if !item then return false end
	
	return item:Event("OnSWEPPrimaryAttack");
end

--[[
* SHARED

Reroute to item's OnSWEPSecondaryAttack
]]--
function SWEP:SecondaryAttack()
	local item=self:GetItem();
	if !item then return false end
	
	return item:Event("OnSWEPSecondaryAttack");
end

--[[
* SHARED

?? Can reload?
]]--
function SWEP:CheckReload()
	local item=self:GetItem();
	if !item then return false end
	
	return item:Event("OnSWEPCheckReload");
end

--[[
* SHARED

Being reloaded
TODO: This has no way to know if the weapon is done reloading since we don't do
DefaultReload like most SWEPs do; need to figure out a solution for this
]]--
function SWEP:Reload()
	local item=self:GetItem();
	if !item then return false end
	
	return item:Event("OnSWEPReload");
end

--[[
* SHARED

May allow items to override later
]]--
function SWEP:ContextScreenClick( aimvec, mousecode, pressed, ply )
	local item=self:GetItem();
	if !item then return false end
	
	return item:Event("OnSWEPContextScreenClick",nil,aimvec,mousecode,pressed,ply);
end

--[[
* SHARED

Is the SWEP being removed right now?
]]--
function SWEP:IsBeingRemoved()
	return self.BeingRemoved;
end

--[[
* HACK

I hate hate HATE having to do this!
This hook checks the active weapons of each player every frame.

If the player has changed weapons we check to see if his new weapon was an itemforge weapon.
If it is, we IFDeploy it.

Then, we check to see if his old weapon was an itemforge weapon.
If it was, we IFHolster it.

RegWeapons is a table of all current Itemforge SWEPs deployed.

EntityRemoved removes the player from the PlayerWeapons registry when the player leaves.
]]--
local RegWeapons={};

--[[
* SHARED
* HACK

Registers the weapon with Itemforge
]]--
function SWEP:Register()
	RegWeapons[self]=self;
end

--[[
* SHARED
* HACK

Unregisters the weapon with Itemforge
]]--
function SWEP:Unregister()
	RegWeapons[self]=nil;
end

hook.Add("Think","itemforge_holster_deploy_think",function()
	local players = player.GetAll();
	local wep, oldwep;
	for k,v in pairs(players) do
		newwep=v:GetActiveWeapon();
		oldwep=v.ItemforgeLastWeapon;
		
		if newwep!=oldwep then
			if IsValid(oldwep) && RegWeapons[oldwep] then
				oldwep:IFHolster();
			end
			if IsValid(newwep) && RegWeapons[newwep] then
				newwep:IFDeploy();
			end			
		end
		
		v.ItemforgeLastWeapon=newwep;
	end
end);