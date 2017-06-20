--[[
itemforge_item_held
SHARED

This SWEP is an 'avatar' of an item. When an item is held, this weapon represents that item.
]]--

--[[
SWEPs need a lot of reworking.
	Rather than using a polling model (GetItem in everything) lets control the state a little more efficiently.
	Have two tables of SWEP events. One containing events for when no item is loaded, another containing events for when an item is loaded.
	Have the weapon register itself as itemless if it doesn't have an item (first time initialization, removal). This will make the entity use the itemless events.
	Each Think, have it try to acquire the items for Itemless weapons.
	Have the weapon unregister itself as itemless when it acquires the item.
	Lets apply this same model to itemforge_item entity.

	We need to come up with a better way of handling failed SWEP pickups.
	Current idea is to implement a delayed hold. Calling :Hold() creates an itemforge_item_held, registers it as a potential failed pickup,
	and keeps trying to make the intended owner pick it up.
	When the weapon is picked up, it compares the owner to the intended owner.
	If it matches, THEN the item is bound to the weapon.
	If not, the weapon is removed.
	This will require a significant rewrite of the weapon model will take a lot of time, so we'll save this for later.
]]--

SWEP.Author					= "theJ89"
SWEP.Contact				= "theJ89@charter.net"
SWEP.Purpose				= "This SWEP is a part of Itemforge. When an item is held, this weapon turns into the item you're holding."
SWEP.Instructions			= "This will be spawned by the game when an item is held by a player. You can interact with the item by switching to this weapon then using left mouse, right mouse, etc."

SWEP.Spawnable				= false;
SWEP.AdminSpawnable			= false;

SWEP.ViewModel				= "models/weapons/v_crowbar.mdl";
SWEP.WorldModel				= "models/weapons/w_crowbar.mdl";

SWEP.Primary.ClipSize		= 0;
SWEP.Primary.DefaultClip	= 0;
SWEP.Primary.Automatic		= false;
SWEP.Primary.Ammo			= "none";

SWEP.Secondary.ClipSize		= 0;
SWEP.Secondary.DefaultClip	= 0;
SWEP.Secondary.Automatic	= false;
SWEP.Secondary.Ammo			= "none";

SWEP.BeingRemoved			= false;

--[[
* SHARED
* Event

Set up the first DT int to be the item ID.

This is good because when the weapon gets created the item ID goes with it!
This pretty much fixes the HUD reporting a pickup of "Itemforge Item" whenever you hold the
weapon, although it's still possible (e.g. given the weapon before the item is created on
the client, in the case that an item is created held by a player).
]]--
function SWEP:SetupDataTables()
	self:DTVar( "Int", 0, "i" );
end

--[[
* SHARED

Sets the item this weapon is associated with.
]]--
function SWEP:SetItem( item )
	if item then
		self.Item = item;
	
		--Serverside, SetItem is only called once, when the weapon is created.
		if SERVER then
		
			item:Event( "OnSWEPInit", nil, self.Weapon );

			--Inform this entity what item ID to look for when pairing clientside
			self.Weapon:SetDTInt( "i", item:GetID() );

		--Clientside, SetItem is called after it is acquired by a player. It may also be called after a lag spike to reconnect the item.
		else

			--If the item already initialized clientside, this is an indication of a lag spike reconnect.
			if self.HasInitialized then
				self.BeingRemoved = false;
			else
				item:Event( "OnSWEPInit", nil, self.Weapon );
				self.HasInitialized = true;
			end
		
			item:Hold( self.Owner, nil, self.Weapon, false );
			self:UnregisterAsItemless();
			self:SwapToItemEvents();

		end
	
		--HACK
		self:Register();
	else
		self.Item = nil;
		if CLIENT then
			self:RegisterAsItemless();
			self:SwapToItemlessEvents();
		end
	end
end

--[[
* SHARED

Returns the item that is piloting this SWEP.
]]--
function SWEP:GetItem()
	--We had an item set but it's not valid any more
	if self.Item && !self.Item:IsValid() then
		self.Item = nil;
	end
	
	return self.Item;
end

--[[
* SHARED

Returns true if the SWEP has a valid owner, false otherwise
If the item hasn't been picked up yet this is nil
]]--
function SWEP:HasOwner()
	return self.Owner:IsValid();
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
* Event

Weapon initilization is carried out at link time
]]--
function SWEP:Initialize()
	if CLIENT then self:RegisterAsItemless() end

	--Attempt to acquire at initialization time
	--self:GetItem();
end

--[[
* SHARED
* Event

Itemforge-based holster event
A different weapon is being swapped to
]]--
function SWEP:IFHolster()
	local item = self:GetItem();
	if !item then return true end
		
	return item:Event( "OnSWEPHolsterIF", true );
end

--[[
* SHARED
* Event

Source-based holster event
A different weapon is being swapped to
]]--
function SWEP:Holster()
	local item = self:GetItem();
	if !item then return true end
	
	return item:Event( "OnSWEPHolster", true );
end

--[[
* SHARED
* Event

Itemforge-based deploy event
This weapon is being swapped to
]]--
function SWEP:IFDeploy()
	local item = self:GetItem();
	if !item then return true end
	
	return item:Event( "OnSWEPDeployIF", true );
end

--[[
* SHARED
* Event

Source-based deploy event
This weapon is being deployed
]]--
function SWEP:Deploy()
	local item = self:GetItem();
	if !item then return true end
	
	item:Event( "OnSWEPDeploy", true );
end

--[[
* SHARED
* Event

Do we need to precache anything?
]]--
function SWEP:Precache()
end

--[[
* SHARED
* Event

Reroute to item's OnSWEPPrimaryAttack
]]--
function SWEP:PrimaryAttack()
	return self:GetItem():Event( "OnSWEPPrimaryAttack" );
end

--[[
* SHARED
* Event

Reroute to item's OnSWEPSecondaryAttack
]]--
function SWEP:SecondaryAttack()
	return self:GetItem():Event( "OnSWEPSecondaryAttack" );
end

--[[
* SHARED
* Event

?? Can reload?
]]--
function SWEP:CheckReload()
	return self:GetItem():Event( "OnSWEPCheckReload" );
end

--[[
* SHARED
* Event

Being reloaded
TODO: This has no way to know if the weapon is done reloading since we don't do
DefaultReload like most SWEPs do; need to figure out a solution for this
]]--
function SWEP:Reload()
	return self:GetItem():Event( "OnSWEPReload" );
end

--[[
* SHARED
* Event

Being reloaded
TODO: This has no way to know if the weapon is done reloading since we don't do
DefaultReload like most SWEPs do; need to figure out a solution for this
]]--
function SWEP:Think()
	return self:GetItem():Event( "OnSWEPThink" );
end

--[[
* SHARED
* Event

Runs when the player clicks the screen while holding c with this weapon out 
]]--
function SWEP:ContextScreenClick( vAimVec, eMouseCode, bPressed, pl )
	return self:GetItem():Event( "OnSWEPContextScreenClick", nil, vAimVec, eMouseCode, bPressed, pl );
end

--[[
* SHARED

Is the SWEP being removed right now?
]]--
function SWEP:IsBeingRemoved()
	return self.BeingRemoved;
end


--RegWeapons is a table of all current Itemforge SWEPs.
local RegWeapons = {};


--[[
* SHARED
* HACK

Registers the weapon with Itemforge
]]--
function SWEP:Register()
	RegWeapons[self] = self;
end

--[[
* SHARED
* HACK

Unregisters the weapon with Itemforge
]]--
function SWEP:Unregister()
	RegWeapons[self] = nil;
end

local FailedPickupWeapons;
local ItemlessWeapons;

if SERVER then




--FailedPickupWeapons is a table of Itemforge SWEPs that haven't been picked up yet.
FailedPickupWeapons = {};

--[[
* SHARED
* HACK

Registers this weapon as a potential failed pickup.

pl should be the player who was intended to pick it up.
]]--
function SWEP:RegisterFailedPickup( pl )
	FailedPickupWeapons[self] = self;
	self.IntendedOwner = pl;
end

--[[
* SHARED
* HACK

The weapon is no longer considered a potential failed pickup.
Should be called when it's confirmed the intended player has picked it up.
]]--
function SWEP:UnregisterFailedPickup()
	self.IntendedOwner = nil;
	FailedPickupWeapons[self] = nil;
end




else




--ItemlessWeapons is a table of Itemforge SWEPs that haven't been bound to an item clientside yet.
ItemlessWeapons = {};

--[[
* SHARED

Registers this weapon as having no item.
]]--
function SWEP:RegisterAsItemless()
	ItemlessWeapons[self] = self;
end

--[[
* SHARED

Unregisters the weapon as having no item.
]]--
function SWEP:UnregisterAsItemless()
	ItemlessWeapons[self] = nil;
end




end

--[[
* HACK

I hate hate HATE having to do this!
This hook checks the active weapons of each player every frame.

If the player has changed weapons we check to see if his old weapon was an Itemforge weapon.
If it was, we IFHolster it.

Then, we check to see if his new weapon is an Itemforge weapon.
If it is, we IFDeploy it.

Additionally, serverside potential failed pickups are moved to the respective intended players.
Clientside, the hook searches for any Itemless SWEP's items.
]]--
hook.Add( "Think", "itemforge_swep_think", function()
	local eNewWep, eOldWep;
	for k, v in pairs( player.GetAll() ) do
		eNewWep = v:GetActiveWeapon();
		eOldWep = v.ItemforgeLastWeapon;
		
		if eNewWep != eOldWep then
			if IsValid( eOldWep ) && RegWeapons[eOldWep] then		eOldWep:IFHolster()		end
			if IsValid( eNewWep ) && RegWeapons[eNewWep] then		eNewWep:IFDeploy()		end
		end
		
		v.ItemforgeLastWeapon = eNewWep;
	end
	
	if SERVER then

		for k, v in pairs( FailedPickupWeapons ) do
			if IsValid( v.IntendedOwner ) then
				if		v.Owner == v.IntendedOwner	then	v:UnregisterFailedPickup();
				elseif	v.Owner:IsValid() 			then	v:GetItem():HoldFailed();				--Owner doesn't match intended owner
				else										v:SetPos( IF.Util:RandomVectorInAABB( v.IntendedOwner:WorldSpaceAABB() ) );
				end
			else
				v:GetItem():HoldFailed();	--Intended owner is no longer valid (player left)
			end
		
		end

	else
		local item;
		for k, v in pairs( ItemlessWeapons ) do
			
			if k:IsValid() then
				item = IF.Items:Get( v:GetDTInt( "i" ) );
				if item then
					if v:HasOwner() then
						v:SetItem( item )
					else

						--[[
						Proper initialization requires that the weapon already has been picked up,
						but in order for the name to appear correctly on pickup we have to set the weapon's
						printname here.
						]]--
						v.PrintName = item:Event( "GetName", "Itemforge Item" );
					end
				end

			--This is a necessary cleanup check because unfortunately SWEP:Remove() does not indicate the final removal of a weapon.
			--SWEPs become Itemless on removal, and unintentionally remain in the ItemlessWeapons table in the event of real removal.
			else
				ItemlessWeapons[k] = nil;
			end

			
		end

	end
end );