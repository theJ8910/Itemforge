--[[
base_ranged
SHARED

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ranged has two purposes:
	It's designed to help you create ranged weapons easier. You just have to change/override some variables or replace some stuff with your own code.
	You can tell if an item is a ranged weapon (like a pistol or RPG) by checking to see if it inherits from base_ranged.
Some features the base_ranged has:
	Ammunition:
		You can load base_ranged weapons with other items
		The primary/secondary attack consumes ammo from a clip you set (you can also set primary/secondary not to consume ammo)
		You can set how much ammo the primary/secondary consumes per shot
		You can specify how many clips you want your weapon to have (including none).
		You can specify what type of ammo goes in a clip and how much can be loaded into it at a given time (including no limit)
		If ammo is drag-dropped onto the item, it loads it with that ammo; if two or more clips use the same kind of ammo, then it will load whichever clip is empty first.
		A list of reload functions let you set up where the item looks for ammo when it reloads.
	Cooldowns:
		This is based off of base_weapon so you can set primary/secondary delay and auto delay
		You can set a reload delay
		You can set a "dry delay" for when the gun is out of ammo or underwater (for example, the SMG's primary has a 0.08 second cooldown, but if you're out of ammo, it has a 0.5 second cooldown instead)
	Other:
		The item's right click menu has several functions for dealing with ranged weapons; you can fire it's primary/secondary, unload clips, reload, etc, all from the menu.
		Wiremod can fire the gun's primary/secondary attack. It can also reload the gun, if there is ammo nearby.
		You can set whether or not you want the gun's primary/secondary to work underwater

TODO the base_ranged ammo will not be known to a connecting client; have it send that OnFullUpdate() or whatever
TODO non-singly reloading weapons must stop reloads when holstering during one
]]--

include( "clips.lua" );
include( "ammo.lua" );
include( "findammo.lua" );

ITEM.Name						= "Base Ranged Weapon";
ITEM.Description				= "This item is the base ranged weapon.\nItems used as ranged weapons, such as firearms, rocket launchers, etc, can inherit from this\nto make their creation easier.\n\nThis is not supposed to be spawned.";
ITEM.Base						= "base_weapon";

--Base Ranged Weapon
--[[
Ammo clips
Ranged Weapons almost always have ammunition that they're loaded with and use up.
The weapon holds the ammo in what we call a "clip". Itemforge loads it's guns with stacks of other items.
	Type determines what type of items can be loaded into this clip. Any item based off of this type of item will also work.
	Size determines how many "bullets" (or whatever type of ammo you're using) can fit inside of it at any time. If this is 0, the clip can hold as much ammo as you want.

So you might be wondering, "How do I make clips for my weapon?"
Luckily, I've taken the time to make some examples for you.

Most weapons, like the HL2 Pistol for example, only have one clip for bullets:
	ITEM.Clips			= {};
	ITEM.Clips[1]		= { Type = "ammo_pistol",		Size = 18 };
	ITEM.PrimaryClip	= 1;

Some weapons, like the HL2 SMG for example, have two clips; one for bullets, and another for grenades:
	ITEM.Clips			= {};
	ITEM.Clips[1]		= { Type = "ammo_smg",			Size = 45 };
	ITEM.Clips[2]		= { Type = "ammo_smggrenade",	Size = 3 };
	ITEM.PrimaryClip	= 1;
	ITEM.SecondaryClip	= 2;

Other weapons, like the HL2 Shotgun, only have one clip (for shotgun shells), but both the primary and secondary attack take shells from that clip.
Since it's the HL2 shotgun, the primary takes one 'bullet', but the secondary takes two 'bullets'.
	ITEM.Clips			= {};
	ITEM.Clips[1]		= { Type = "ammo_buckshot",		Size = 6 };
	ITEM.PrimaryClip	= 1;
	ITEM.PrimaryTakes	= 1;
	ITEM.SecondaryClip	= 1;
	ITEM.SecondaryTakes	= 2;

A few weapons don't use clips at all.
	ITEM.Clips			= {};
	ITEM.PrimaryClip	= 0;
	ITEM.SecondaryClip	= 0;
]]--
ITEM.Clips						= {};

ITEM.PrimaryClip				= 0;						--What clip does the primary draw ammo from? If this is 0, the primary doesn't use ammo.
ITEM.PrimaryTakes				= 1;						--How much ammo does the primary take per attack?
ITEM.PrimaryFiresUnderwater		= true;						--Does the primary fire underwater?


ITEM.SecondaryClip				= 0;						--What clip does the secondary draw ammo from? If this is 0, the secondary doesn't use ammo.
ITEM.SecondaryTakes				= 1;						--How much ammo does the secondary take per attack?
ITEM.SecondaryFiresUnderwater	= true;						--Does the secondary fire underwater?


ITEM.ReloadsSingly				= false;					--Do we reload like a shotgun (one 'bullet' at a time)?
ITEM.ReloadDelay				= 1.4333332777023;			--The gun pauses for this long after loading a fresh clip of ammo. If we ReloadSingly, the gun pauses for this long after each "bullet" is loaded.
ITEM.ReloadStartDelay			= 1;						--If we ReloadSingly, the gun pauses for this long before the first "bullet" is loaded.
ITEM.ReloadFinishDelay			= 1;						--If we ReloadSingly, the gun pauses for this long after the last "bullet" has been loaded.
ITEM.ReloadActivity				= ACT_VM_RELOAD;			--What viewmodel animation (i.e. first person) does the reload play?
ITEM.ReloadPlayerAnim			= PLAYER_RELOAD;			--What player animation (i.e. third person) does the reload play?
ITEM.ReloadSounds				= nil;						--When ammo is loaded into any clip, a random sound here plays

ITEM.DryFireDelay				= 0.5;						--If we try to fire and can't (out of ammo/underwater), when is the next time we can attack?
ITEM.DryFireActivity			= ACT_VM_DRYFIRE;			--What viewmodel animation (i.e. first person) is played if we try to fire and can't?
ITEM.DryFireSounds				= nil;						--If we try to fire and can't (out of ammo/underwater), a random sound here plays

ITEM.MuzzleName					= "muzzle";					--What's the name of the muzzle attachment point on the gun? If we're in the world, we'll shoot things from the muzzle (special effects, bullets, grenades, flechettes, whatever)

--Don't modify; these are set automatically
ITEM.MuzzleAP					= nil;						--What attachment ID does the muzzle on the gun use (if any?)
ITEM.ReloadSource				= nil;						--If we ReloadSingly, we have selected this stack to reload from.
ITEM.ReloadClip					= nil;						--If we ReloadSingly, we are currently reloading this clip.

--[[
* SHARED
* Event

Runs when the item is created.
It has it's clip table created and it starts thinking.
]]--
function ITEM:OnInit( plOwner )
	self.Clip = {};
end

--[[
* SHARED
* Event

Runs when the weapon's primary attack is triggered (by a player or by other means).
]]--
function ITEM:OnSWEPPrimaryAttack()
	if !self.HasPrimary || !self:CanPrimaryAttack() || ( self:Event( "IsPrimaryAttacking", false ) && !self:CanPrimaryAttackAuto() ) then return false end
	
	--Dry fire if we're underwater or, if the primary uses ammo, doesn't have enough
	if ( !self.PrimaryFiresUnderwater && self:GetWaterLevel() == 3 ) || ( self.PrimaryClip != 0 && !self:HaveAmmo( self.PrimaryTakes, self.PrimaryClip ) ) then
		self:DryFire();
		
		return false;
	end
	
	self:Event( "OnPrimaryAttack" );

	self:DoPrimaryCooldownBoth();
	self:PrimaryEffects();
	self:TakeAmmo( self.PrimaryTakes, self.PrimaryClip );
	
	return true;
end

--[[
* SHARED
* Event

Runs when the weapon's secondary attack is triggered (by a player or by other means).
]]--
function ITEM:OnSWEPSecondaryAttack()
	if !self.HasSecondary || !self:CanSecondaryAttack() || ( self:Event( "IsSecondaryAttacking", false ) && !self:CanSecondaryAttackAuto() ) then return false end
	
	--Dry fire if we're underwater or, if the secondary uses ammo, doesn't have enough
	if ( !self.SecondaryFiresUnderwater && self:GetWaterLevel() == 3 ) || ( self.SecondaryClip != 0 && !self:HaveAmmo( self.SecondaryTakes, self.SecondaryClip ) ) then
		self:DryFire();
		
		return false;
	end
	
	self:Event( "OnSecondaryAttack" );

	self:DoSecondaryCooldownBoth();
	self:SecondaryEffects();
	self:TakeAmmo( self.SecondaryTakes, self.SecondaryClip );

	return true;
end

--[[
* SHARED
* Event

Reroutes the SWEP's reload to the item's PlayerReload.
Whoever is holding the waepon is the player responsible for reloading.
]]--
function ITEM:OnSWEPReload()
	local plOwner = self:GetWOwner();
	if !plOwner then return end

	self:PlayerReload( plOwner, true );
end

--[[
* SHARED
* Event

If a player [USE]s this gun while holding some ammo (an item based off of base_ammo), we'll try to load this gun with it.
If the gun is used clientside, we won't actually load the gun, we'll just return true to indiciate we want the server to load the gun.
TODO check clips instead of checking for base_ammo
]]--
function ITEM:OnUse( pl )
	local item = IF.Items:GetWeaponItem( pl:GetActiveWeapon() );
	if self:PlayerLoadAmmo( pl, item ) then
		return SERVER;
	end

	--We couldn't load the gun with whatever the player was carrying, so just do the default OnUse
	return self:BaseEvent( "OnUse", false, pl );
end

--[[
* SHARED
* Event

Dynamic item description. In addition to the weapon's normal description (self.Description),
if ammo is loaded, we include the name of the ammo in the description.
]]--
function ITEM:GetDescription()
	local d = self.Description;

	for i = 0, #self.Clips do
		local itemCurAmmo = self:GetAmmoSource( i );
		--TODO: Ammo needs to indicate appropriate grammar ("It's loaded with buckshot." "It's loaded with an SMG grenade." "It's loaded with Flechettes." etc)
		if itemCurAmmo then	d = d.."\nIt's loaded with "..itemCurAmmo:Event( "GetName", "Unknown Ammo" ).."." end
	end

	return d;
end

--[[
* SHARED

Call this to make a player reload the item.
Searches and tries nearby ammo
]]--
function ITEM:PlayerReload( pl, bPredicted )
	if !self:Event( "CanReload", false ) || !self:Event( "CanPlayerInteract", false, pl ) then return false end
	self:FindAmmo(
		function( self, item )
			return self:PlayerLoadAmmo( pl, item, iClip, bPredicted );
		end
	);
end

--[[
* SHARED

Calling this function reloads the item.
]]--
function ITEM:ItemReload( itemReloader )
	if !self:Event( "CanReload", false ) || !self:Event( "CanPlayerInteract", false, pl ) then return false end
end

--[[
* SHARED

Run this function to make a player load the given clip with the given ammo.

pl is the player who wants to load ammo.
itemAmmo is the item we want to load.
iClip is an optional clip # to load the ammo in.
	If this is nil / not given, we find an empty clip that can take the given ammo.
bPredicted is an optional true/false that mostly relates to prediction issues with sounds / animations played during a reload.
	bPredicted should only be true if it is being called in a predicted SWEP event (such as OnSWEPPrimaryAttack, OnSWEPSecondaryAttack, OnSWEPReload, etc).
	If bPredicted is:
		false, nil, or not given, the client asks the server to run this function. The server plays unpredicted reload effects.
		true, then we expect the server and client to both call this function at roughly the same time. Both the client and server play predicted reload effects.
]]--
function ITEM:PlayerLoadAmmo( pl, itemAmmo, iClip, bPredicted )
	if !self:Event( "CanReload", false ) || !IF.Util:IsItem( itemAmmo ) || !self:Event( "CanPlayerInteract", false, pl ) || !itemAmmo:Event( "CanPlayerInteract", false, pl ) then return false end
	
	if		iClip == nil							 then
		--If a clip is not given, find a non-full clip that can take the given ammo.
		--Prioritize chosen clip by fullness. Partially full clips have priority over less full / empty clips.
		for i = 1, #self.Clips do
			local iClipAmt;
			if !self:IsClipFull( i ) && self:CanLoadClipWith( i, itemAmmo ) && ( iClip == nil || ( self:GetAmmoSourceAmount( i ) > iClipAmt ) )  then
				iClip = i;
				iClipAmt = self:GetAmmoSourceAmount( i );
			end
		end

		if iClip == nil then return false end

	elseif	!self:IsClipFull( iClip ) && !self:CanLoadClipWith( iClip, itemAmmo ) then
		return false;
	end
	
	if SERVER || bPredicted then
		if self.ReloadsSingly then return self:Event( "StartReload", false, itemAmmo, iClip, self:GetWOwner() ); end

		self:SetAmmoSource( iClip, itemAmmo );
		self:ReloadEffects( bPredicted );
		self:DoReloadCooldown();
	else
		self:SendNWCommand( "PlayerLoadAmmo", itemAmmo, iClip );
	end
	
	return true;
end

--[[
* SHARED

Call this function to unload the ammo item in the given clip.
]]--
function ITEM:PlayerUnloadAmmo( pl, iClip )
	if !self:Event( "CanPlayerInteract", false, pl ) then return false end
	
	if SERVER then		self:Unload();
	else				self:SendNWCommand( "PlayerUnloadAmmo", pl, iClip );
	end

	return true;
end

--[[
* SHARED

Run this function to make an item load this weapon with the given ammo.
By default, the item can reload itself.
]]--
function ITEM:ItemLoadAmmo( itemLoader, itemAmmo, iClip )
	if !self:Event( "CanReload", false ) || !self:CanLoadClipWith( itemAmmo, iClip ) || !self:Event( "CanItemInteract", false, itemLoader ) || !itemAmmo:Event( "CanItemInteract", false, itemLoader ) then return false end

	--TODO

	return true;
end

--[[
* SHARED


]]--
function ITEM:ItemUnloadAmmo( itemUnloader, iClip )
	if !self:Event( "CanItemInteract", false, itemLoader ) || !itemAmmo:Event( "CanItemInteract", false, itemLoader ) then return false end

	--TODO

	return true;
end

--[[
* SHARED
* Internal

Unloads the item in the given clip.
Don't call directly. Call PlayerUnloadAmmo or ItemUnloadAmmo instead.
]]--
function ITEM:Unload( iClip )
	self:SetAmmoSource( iClip, nil );
end

--[[
* SHARED
* Event

Returns true if we can reload right now, and false otherwise.

The only time we can't reload is if we're already reloading, or if the primary / secondary is cooling down.
]]--
function ITEM:CanReload()
	return self:CanPrimaryAttack() && self:CanSecondaryAttack() && !self:GetNWBool( "InReload" );
end

--[[
* SHARED

Shortcut for performing standard reload delay.
Sets both delay and auto-delay to whatever is returned by GetPrimaryDelay / GetPrimaryDelayAuto.
]]--
function ITEM:DoReloadCooldown()
	self:SetNextBoth( CurTime() + self:Event( "GetReloadDelay", 1 ) );
end

--[[
* SHARED
* Event

Plays a reload sound and plays the reload animation (both on the weapon and player himself).
]]--
function ITEM:ReloadEffects( bPredicted )
	self:EmitSound( self:Event( "GetReloadSound", nil ), bPredicted );
	
	local eWep = self:GetWeapon();
	if !eWep then return false end
	
	self:SendWeaponAnim(			self:Event( "GetReloadActivity",	ACT_VM_RELOAD	) );
	self:GetWOwner():SetAnimation(	self:Event( "GetReloadPlayerAnim",	PLAYER_RELOAD	) );
end

--[[
* SHARED
* Event

This event determines what sound should be played when the weapon's secondary is successfully activated.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetReloadSound()
	return self.ReloadSounds;
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when ammo is loaded
]]--
function ITEM:GetReloadActivity()
	return self.ReloadActivity;
end

--[[
* SHARED
* Event

Returns the animation played when the weapon is reloaded.
]]--
function ITEM:GetReloadPlayerAnim()
	return self.ReloadPlayerAnim;
end

--[[
* SHARED
* Event

Returns the reload start delay (this is how long it takes for a ReloadsSingly weapon to start reloading, before we load the first bullet / shell)
]]--
function ITEM:GetReloadStartDelay()
	return self.ReloadStartDelay;
end

--[[
* SHARED
* Event

Returns the reload delay (this is how long it takes to reload a weapon).
In the case of a ReloadsSingly weapon, this is how long it takes to load a single shell.
The weapon cannot attack while reloading.
]]--
function ITEM:GetReloadDelay()
	return self.ReloadDelay;
end

--[[
* SHARED
* Event

Returns the reload finish delay (this is how long it takes for a ReloadsSingly weapon to finish reloading after we've loaded the final bullet / shell).
The weapon cannot attack during this time.
]]--
function ITEM:GetReloadFinishDelay()
	return self.ReloadFinishDelay;
end


--[[
* SHARED

This function runs when the player tries to fire, but the gun doesn't fire anything.
Typically, this runs when the gun is out of ammo or tries to fire underwater
It plays the weapon's dry-fire sound and plays the dry-fire viewmodel animation.
It also cools the weapon down; the length of the cooldown is determined by the dry-fire delay.
]]--
function ITEM:DryFire()
	self:EmitSound( self:Event( "GetDryFireSound" ), true );

	local eWep = self:GetWeapon();
	if !eWep then return false end

	self:SendWeaponAnim(		  self:Event( "GetDryFireActivity", ACT_VM_DRYFIRE	) );
	self:SetNextBoth( CurTime() + self:Event( "GetDryDelay",		1				) );
end

--[[
* SHARED
* Event

This event determines what sound should be played when the weapon dry fires.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetDryFireSound()
	return self.DryFireSounds;
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when a dry-fire occurs
]]--
function ITEM:GetDryFireActivity()
	return self.DryFireActivity;
end

--[[
* SHARED
* Event

Returns the dry-fire delay.
]]--
function ITEM:GetDryDelay()
	return self.DryFireDelay;
end








--[[
* SHARED

Gets the fire position, angles, and the kill-credit entity.

Before a gun can fire bullets or projectiles, we usually need to know where the bullets/projectiles are coming from,
where they are going, and what entity is firing them. Getting these three things has to be done in different ways, depending
on the state of the gun, i.e. whether or not the gun is held by a player, dropped in the world, or stored in an inventory.
This function automatically finds the correct position/direction/owner based on the state it's in, so you don't have to write code to figure it out yourself.

This function returns three pieces of data: vPos, aAng, eOwner (in that order).
	vPos is the fire position (the bullets/projectile will be fired from here).
	aAng is the fire angles (the bullets/projectile will be fired in the angle's "forward" direction)
	eOwner is the entity that should be credited when fired bullets/projectiles kill something.
		If this item is held by a player, it will be this player.
		if this item is in the world, it will be the item's world entity.

If the item is in an inventory / in the void, this returns nil for all three values.
]]--
function ITEM:GetFireOriginAngles()
	local vPos;
	local aAng;
	local eOwner;

	if self:IsHeld() then
		eOwner		= self:GetWOwner();
		vPos		= eOwner:GetShootPos();
		aAng		= eOwner:EyeAngles();
	elseif self:InWorld() then
		eOwner		= self:GetEntity();
		local pa	= self:GetMuzzle( eOwner );
		vPos		= pa.Pos;
		aAng		= pa.Ang;
	else
		return nil, nil, nil;
	end
	
	return vPos, aAng, eOwner;
end

--[[
* SHARED

Gets the fire position, aim direction, and the kill-credit entity.

This is more or less the same function as above, except instead of returning a full set of angles describing the way the gun is oriented,
in it's place it returns a vector representing the aim direction.

This function returns three pieces of data: vPos, vDir, eOwner (in that order).
	vPos is the fire position (the bullets/projectile will be fired from here).
	vDir is the aim direction (the bullets/projectile will be fired in this direction)
	eOwner is the entity that should be credited when fired bullets/projectiles kill something.
		If this item is held by a player, it will be this player.
		if this item is in the world, it will be the item's world entity.

If the item is in an inventory / in the void, this returns nil for all three values.
]]--
function ITEM:GetFireOriginDir()
	local vPos;
	local vDir;
	local eOwner;

	if self:IsHeld() then
		eOwner		= self:GetWOwner();
		vPos		= eOwner:GetShootPos();
		vDir		= eOwner:GetAimVector();
	elseif self:InWorld() then
		eOwner		= self:GetEntity();
		local pa	= self:GetMuzzle( eOwner );
		vPos		= pa.Pos;
		vDir		= pa.Ang:Forward();
	else
		return nil, nil, nil;
	end
	
	return vPos, vDir, eOwner;
end

--[[
* SHARED

Performs a trace-line from the fire origin and in the direction the gun is pointed.

Works both for when the gun is in the world and held by a player.
If the gun is in an inventory / in the void, returns nil.

fMaxDist is an optional number that defaults to 16384.
	This should be the furthest distance away from the start of the trace (in game units) the traceline can hit.
vFilteredEntities is an optional value. If this is:
	nil: The trace will not hit the player holding the weapon / the weapon's world entity.
	a table of entities: Same as above, and in addition will not hit any of the entities in this table.
mask is an optional MASK_* enum, or OR'd combination of MASK_ enums for the trace. It defaults to nil.

Returns a traceRes table if successful.
Returns nil otherwise.
]]--
function ITEM:Trace( fMaxDist, vFilteredEntities, mask )
	if fMaxDist == nil then fMaxDist = 16384 end

	local vPos, vDir, eOwner = self:GetFireOriginDir();
	if vPos == nil then return nil end

	local tr  = {};
	tr.start  = vPos;
	tr.endpos = vPos + ( fMaxDist * vDir );
	tr.filter = eOwner;
	if IF.Util:IsTable( vFilteredEntities ) then
		tr.filter = table.Copy( vFilteredEntities );
		table.Insert( tr.filter, eOwner );
	end
	tr.mask   = mask;

	return util.TraceLine( tr );
end

--[[
* SHARED

Returns the muzzle position.
If the muzzle attachment point (defined by ITEM.MuzzleName) doesn't exist on the model, returns the position and angles of the given entity instead.

eEnt should the the entity you want to get the muzzle position on.
	This is normally the world entity ( self:GetEntity() ), but perhaps you would want to get the muzzle position
	of the world model a player is holding, or the model displayed in an item slot?

Returns a table containing two elements, Pos and Ang:
	Pos is a Vector() indicating the world position of the attachment point)
	Ang is an Angle() describing how the muzzle is oriented)
]]--
function ITEM:GetMuzzle( eEnt )
	if !self.MuzzleAP		then	self.MuzzleAP = eEnt:LookupAttachment( self.MuzzleName ) end
	if self.MuzzleAP != 0	then	return eEnt:GetAttachment( self.MuzzleAP );
	else							return { Pos = eEnt:GetPos(), Ang = eEnt:GetAngles() };
	end
end

IF.Items:CreateNWVar( ITEM, "InReload", "bool", false, nil, true, true );