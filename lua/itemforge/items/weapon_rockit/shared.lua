--[[
weapon_rockit
SHARED

A gun that fires random crap from it's inventory.
]]--

include( "inv_rockit.lua" );

ITEM.Name				= "Rock-It Launcher";
ITEM.Description		= "An odd device that propels ordinary objects at deadly speed.\nThe words \"Vault Dweller\" are etched into the stock. You're not sure who that is.";
ITEM.Base				= "base_ranged";
ITEM.Weight				= 6000;				--This thing easily weighs 6kg / over 12 pounds, unloaded.
ITEM.Size				= 20;
ITEM.ViewModel			= "models/weapons/v_physcannon.mdl";
ITEM.WorldModel			= "models/weapons/w_physics.mdl";
ITEM.Spawnable			= true;
ITEM.AdminSpawnable		= true;

ITEM.SWEPHoldType		= "physgun";

--Overridden Base Weapon stuff
ITEM.HasPrimary			= true;
ITEM.PrimaryDelay		= 0.4;
ITEM.PrimarySounds		= {
	Sound( "weapons/physcannon/superphys_launch1.wav" ),
	Sound( "weapons/physcannon/superphys_launch2.wav" ),
	Sound( "weapons/physcannon/superphys_launch3.wav" ),
	Sound( "weapons/physcannon/superphys_launch4.wav" ),
};

ITEM.HasSecondary		= true;
ITEM.SecondaryDelay		= 0.4;

--Overridden Base Ranged stuff
ITEM.PrimaryClip		= 1;				--This gun doesn't use clips, but if PrimaryClip is 0, base_ranged thinks the primary doesn't use ammo. We override :GetAmmo so it looks in the clip instead.
ITEM.PrimaryTakes		= 0;				--This gun doesn't require the item to have any amount

ITEM.DryFireSounds		= Sound( "weapons/physcannon/physcannon_dryfire.wav" );

ITEM.ReloadDelay		= 0.5;
ITEM.ReloadSounds		= {
	Sound( "npc/dog/dog_pneumatic1.wav" ),
	Sound( "npc/dog/dog_pneumatic2.wav" )
};

ITEM.MuzzleName			= "core";			--The gravity gun model has "core" instead of "muzzle"

--Rock-It Launcher
ITEM.UnloadSound		= Sound( "weapons/physcannon/superphys_hold_loop.wav" );

--[[
* SHARED
* Event

Runs when fired; tries to chuck an item in the rock-it-launcher
]]--
function ITEM:OnPrimaryAttack()
	self:Chuck( 2000 );
end

--[[
* SHARED
* Event

TODO rightclick loads
]]--
function ITEM:OnSecondaryAttack()
end

--[[
* SHARED
* Event

Loads nearby ammo when you reload the Rock-It-Launcher
]]--
function ITEM:OnSWEPReload()
	if !self:CanReload() then return false end

	return self:FindAmmo( function( self, item )
		return self:FillClip( item, i, nil, true );
	end );
end

--[[
* SHARED

Overridden from base_ranged.
When this function is called we load items into the gun's inventory instead of the clip.
]]--
function ITEM:FillClip( item, iClip, iAmt, bPredicted )
	if !self:CanReload() then return false end
	
	local pl = item:GetWOwner();
	
	--TODO when clientside prediction comes the item==self check won't be necessary since the inv will deny it
	if !item || !item:IsValid() || ( pl && pl == item:GetWOwner() ) || item == self then return false end
	
	--Can't load items into a non-existent inventory
	local inv = self:GetInventory();
	if !inv then return false end
	
	if bPredicted == nil then bPredicted = false end
	
	--If we don't insert the item successfully we fail.
	if SERVER then
		if !item:ToInv( inv ) && item:IsValid() then return false end
		self:UpdateWireAmmoCount();
	end
	
	self:ReloadEffects( bPredicted );
	self:SetNextBoth( CurTime() + self:GetReloadDelay() );
	
	return true;
end

--[[
* SHARED

Returns the gun's inventory.
]]--
function ITEM:GetInventory()
	if self.Inventory && !self.Inventory:IsValid() then
		self.Inventory = nil;
	end
	return self.Inventory;
end

--[[
* SHARED

Override so we look in the inventory instead of clips
]]--
function ITEM:GetAmmoSource( iClip )
	local inv = self:GetInventory();
	if !inv then return nil end
	
	return inv:GetFirst();
end

--[[
* SHARED

Overridden from base_ranged since we don't use clips. Just returns true if there is ammo.
]]--
function ITEM:TakeAmmo( iAmt, iClip )
	return self:GetAmmoSource( iClip ) != nil;
end

--[[
* SHARED

Chucks an item in the inventory at the given speed.
Clientside, this function does nothing; items have to be sent to world on the server.
If something is killed by the flying object...
	If this gun is held, kill credit goes to the player holding this gun.
	If this gun is in the world, kill credit goes to the gun entity.

This function calls the OnRockItLaunch event on the chucked item (if the event even exists on the item).
You can write an OnRockItLaunch event in your items to control what happens to an item after it's been fired from a Rock-It Launcher.
e.g. you can activate grenades, you could make ammo fire as bullets, a spray of fletchettes could get fired as if from a shotgun, etc.

This returns true if an item was sent to world and fired.
false is returned otherwise.
]]--
function ITEM:Chuck( fSpeed )
	if CLIENT then return false end
	
	local item = self:GetAmmoSource( self.PrimaryClip );
	if !item then return false end
	
	local iClump = item:GetStartAmount();
	if item:GetAmount() > iClump then
		item = item:Split( iClump, false );
		if !item then return false end
	end
	
	if self:IsHeld() then
		local plOwner	= self:GetWOwner();
		
		local pos	= plOwner:GetShootPos();
		local ang	= plOwner:EyeAngles();
		local fwd	= ang:Forward();
		
		local ent	= item:ToWorld( pos, ang );
		
		local phys	= ent:GetPhysicsObject();
		if phys && phys:IsValid() then
			phys:SetVelocity( fwd * fSpeed );
			phys:AddAngleVelocity( Angle( math.Rand( -200, 200 ), math.Rand( -200, 200 ), math.Rand( -200, 200 ) ) );
		end
		ent:SetPhysicsAttacker( plOwner );

		if IF.Util:IsFunction( item.OnRockItLaunch ) then item:Event( "OnRockItLaunch", nil, self, plOwner ); end
		
		return true;
	elseif self:InWorld() then
		local eEnt		= self:GetEntity();
		local posang	= self:GetMuzzle( self:GetEntity() );
		local fwd		= posang.Ang:Forward();
		
		local ent		= item:ToWorld(posang.Pos,posang.Ang);
		
		local phys		= ent:GetPhysicsObject();
		if phys && phys:IsValid() then
			phys:SetVelocity( fwd * fSpeed );
			phys:AddAngleVelocity( Angle( math.Rand( -200, 200 ), math.Rand( -200, 200 ), math.Rand( -200, 200 ) ) );
		end
		ent:SetPhysicsAttacker( eEnt );

		if IF.Util:IsFunction( item.OnRockItLaunch ) then item:Event( "OnRockItLaunch", nil, self ); end
		
		return true;
	elseif self:InInventory() then
		local inv = self:GetContainer();
		item:ToInv( inv );

		if IF.Util:IsFunction( item.OnRockItLaunch ) then item:Event( "OnRockItLaunch", nil, self ); end

		return true;
	end

end

--[[
Applies suction force to objects in a funnel positioned at a given origin at given angles.

vOrigin is the origin of the funnel. 
vDir is a vector describing the direction the funnel is facing.

When the funnel is facing Vector( 1, 0, 0 ) the funnel opens to the right like so (where o is the origin):

         :
       _.
    __`
 ```
o
 ```--._
        `
         :
]]--

local aZero				= Angle( 0, 0, 0 );
local vZero				= Vector( 0, 0, 0 );
local fSuctionPower		= 300;
--The funnel begins at x = 0, ends at x = fFunnelLength. At it's origin (x = 0) it has a radius of fInnerRadius + 1 units. At it's wide end, it has a radius of fFunnelWideRadius units.
local fFunnelLength		= 1000;
local fFunnelLengthInv	= 1 / fFunnelLength;
local fInnerRadius		= 10;
local fFunnelWideRadius	= 3000;
--The equation we use to generate the funnel: y = fInnerRadius + fA^x. "fA" must be this number if we want y = fFunnelWideRadius when x = fFunnelLength.
local fA				= math.pow( fFunnelWideRadius - fInnerRadius, fFunnelLengthInv );
local BoxBounds			= Vector( fFunnelWideRadius, fFunnelWideRadius, fFunnelWideRadius );

--[[
* SHARED

Applies a suction force to the area in a cone in front of the Rock-It-Launcher
]]--
function ITEM:Suction( vOrigin, vDir )
	--[[
	--We'll start by eliminating any entities that definitely aren't in the funnel by detecting entities in a box around the funnel
	local vEnd = vOrigin + vDir * fFunnelLength;
	
	local ents = ents.FindInBox( vEnd - BoxBounds, vEnd + BoxBounds );
	local aAng = vDir:Angle();
	local p, e, r, m, phys;
	
		
	for k, v in ipairs( ents ) do
		for i = 0, v:GetPhysicsObjectCount() - 1 do
			phys = v:GetPhysicsObjectNum( i );
			
			
			if phys && phys:IsValid() then
				p = WorldToLocal( phys:GetPos(), aZero, vOrigin, aAng );
				e = math.pow( fA, p.x );
				r = math.sqrt( p.y * p.y + p.z * p.z );
				
				--The radius of the funnel, y, at a given x value from the start, is y=fInnerRadius + fA^x.
				if p.x >= 0 && p.x <= 400 && r <= fInnerRadius + e then
					if r > fInnerRadius then	m = e * math.log( fA ) * ( r / e );
					else						m = 0;
					end
					phys:ApplyForceCenter( fSuctionPower * ( ( fFunnelLength - p.x ) * fFunnelLengthInv ) * LocalToWorld( Vector( -1, 0, -m ):Normalize(), aZero, vZero, aAng ) );
				end
			end
		end
	end
	
	return true;
	]]--
end

IF.Items:CreateNWVar( ITEM, "Unloading", "bool", false );