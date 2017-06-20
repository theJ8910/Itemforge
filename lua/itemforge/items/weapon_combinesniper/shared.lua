--[[
weapon_combinesniper
SHARED

Combine sniper?

Original Episode 2 Sniper Rifle world model, materials, and sounds by Valve.
Modified Episode 2 Sniper Rifle world model, view model, materials and sounds and by Jaanus.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

--TODO there are a lot of things to fix. hxrmn suggested fixing the laser while zoomed in.
if SERVER then
	
	--These are some resources related to this weapon that clients need to download
	resource.AddFile( "materials/jaanus/ep2snip_parascope.vmt" );
	resource.AddFile( "materials/jaanus/ep2snip_parascope.vtf" );
	resource.AddFile( "materials/jaanus/sniper_corner.vmt" );
	resource.AddFile( "materials/jaanus/sniper_corner.vtf" );
	
	--Download view model files
	resource.AddFile( "models/weapons/v_combinesniper_e2.mdl" );
	resource.AddFile( "models/weapons/v_combinesniper_e2.dx80.vtx" );
	resource.AddFile( "models/weapons/v_combinesniper_e2.dx90.vtx" );
	resource.AddFile( "models/weapons/v_combinesniper_e2.sw.vtx" );
	resource.AddFile( "models/weapons/v_combinesniper_e2.xbox.vtx" );
	resource.AddFile( "models/weapons/v_combinesniper_e2.vvd" );
	
	--Download world model files
	resource.AddFile( "models/weapons/w_combinesniper_e2.mdl" );
	resource.AddFile( "models/weapons/w_combinesniper_e2.phy" );
	resource.AddFile( "models/weapons/w_combinesniper_e2.dx80.vtx" );
	resource.AddFile( "models/weapons/w_combinesniper_e2.dx90.vtx" );
	resource.AddFile( "models/weapons/w_combinesniper_e2.sw.vtx" );
	resource.AddFile( "models/weapons/w_combinesniper_e2.xbox.vtx" );
	resource.AddFile( "models/weapons/w_combinesniper_e2.vvd" );
	
	--Download sounds
	resource.AddFile( "sound/jaanus/ep2sniper_empty.wav" );
	resource.AddFile( "sound/jaanus/ep2sniper_fire.wav" );
	resource.AddFile( "sound/jaanus/ep2sniper_reload.wav" );
end

ITEM.Name					= "Combine Sniper Rifle";
ITEM.Description			= "A high-powered Sniper Rifle created by the Combine.\n Uses pulse ammunition.";
ITEM.Base					= "base_firearm";
ITEM.WorldModel				= "models/weapons/w_combinesniper_e2.mdl";
ITEM.ViewModel				= "models/weapons/v_combinesniper_e2.mdl";
ITEM.Weight					= 14000;	--14 kg
ITEM.Size					= 34;

ITEM.Spawnable				= true;
ITEM.AdminSpawnable			= true;

if SERVER then




ITEM.GibEffect				= "metal";




end

ITEM.SWEPSecondaryAuto		= false;

ITEM.SWEPHoldType			= "shotgun";

--Overridden Base Weapon stuff
ITEM.HasPrimary				= true;
ITEM.PrimaryDelay			= 1.25;
ITEM.PrimarySounds			= Sound( "jaanus/ep2sniper_fire.wav" );		--Sound( "npc/sniper/echo1.wav" ),

ITEM.HasSecondary			= true;
ITEM.SecondaryDelay			= 0.1;

--Overridden Base Ranged Weapon stuff
ITEM.Clips					= {};
ITEM.Clips[1]				= { Type = "ammo_ar2", Size = 30 };

ITEM.PrimaryClip			= 1;
ITEM.PrimaryTakes			= 3;
ITEM.PrimaryFiresUnderwater = false;

ITEM.ReloadDelay			= 2.6666667461395;
ITEM.ReloadSounds			= {
	--Sound( "npc/sniper/reload1.wav" ),
	Sound( "jaanus/ep2sniper_reload.wav" )
};

ITEM.DryFireDelay			= 1;
ITEM.DryFireSounds			= {
	Sound( "jaanus/ep2sniper_empty.wav" );
}

--Overridden Base Firearm stuff
ITEM.BulletDamage			= 100;
ITEM.BulletSpread			= Vector( 0, 0, 0 );
ITEM.BulletTracer			= "AR2Tracer";
ITEM.BulletForce			= 100;
ITEM.ViewKickMin			= Angle( -2, -1, -1 );
ITEM.ViewKickMax			= Angle( -5, 1, 1 );

--Combine Sniper
ITEM.ZoomInSound			= Sound( "weapons/sniper/sniper_zoomin.wav" );
ITEM.ZoomOutSound			= Sound( "weapons/sniper/sniper_zoomout.wav" );

if CLIENT then




ITEM.ZoomTime				= 70;			--We zoom in/out these many degrees in one second
ITEM.CurrentZoom			= 0;			--How many degrees are we currently zoomed in at
ITEM.TargetZoom				= 0;			--What do we want to zoom in at
ITEM.LastThinkAt			= nil;			--What was the last time the item thought at
ITEM.ZoomLevels				= { 0, 40, 50, 60, 70 };

--Laser related
ITEM.LaserMat				= Material( "sprites/bluelaser1" );
ITEM.LaserSize				= 2;

--Laser hit sprite related
ITEM.LaserHitMat			= Material( "sprites/gmdm_pickups/light" );
ITEM.LaserHitSize			= 8;

--Color of laser and hit sprite
ITEM.LaserColor				= Color( 255, 255, 255, 255 );

--Attachment point IDs
ITEM.LaserWorldAP			= 0;		--For world model
ITEM.LaserVMAP				= 0;		--For view model

--Scope related
ITEM.ScopeMat				= Material( "jaanus/sniper_corner" );
ITEM.ParabolicSightsMat		= Material( "jaanus/ep2snip_parascope" );

--[[
I'm assuming ScrH() would be the min, but who knows, maybe someone has some weird resolution
where the screen height is larger than it's width, such as in a cell phone... Not that
people would be playing GMod on a cellphone, I'm just acknowledging there are wierd resolutions.
In any case, we need the smallest dimension here for our scope.
]]--
local m						= math.min( ScrW(), ScrH() );
local sx					= 0.5 * ( ScrW() - m );
local sy					= 0.5 * ( ScrH() - m );

ITEM.ScopeMin				= m;
ITEM.ScopeX					= sx;
ITEM.ScopeY					= sy;

ITEM.ScopePolies			= {
	--[1] Top Left Corner
	{
		{ x = sx,			y = sy,				u = 0,	v = 0 },
		{ x = sx + 0.5 * m,	y = sy,				u = 1,	v = 0 },
		{ x = sx + 0.5 * m,	y = sy + 0.5 * m,	u = 1,	v = 1 },
		{ x = sx,			y = sy + 0.5 * m,	u = 0,	v = 1 },
	},
	--[2] Top Right Corner
	{
		{ x = sx + 0.5 * m,	y = sy,				u = 1,	v = 0 },
		{ x = sx + m,		y = sy,				u = 0,	v = 0 },
		{ x = sx + m,		y = sy + 0.5 * m,	u = 0,	v = 1 },
		{ x = sx + 0.5 * m,	y = sy + 0.5 * m,	u = 1,	v = 1 },
	},
	--[3] Bottom Left Corner
	{
		{ x = sx,			y = sy + 0.5 * m,	u = 0,	v = 1 },
		{ x = sx + 0.5 * m,	y = sy + 0.5 * m,	u = 1,	v = 1 },
		{ x = sx + 0.5 * m,	y = sy + m,			u = 1,	v = 0 },
		{ x = sx,			y = sy + m,			u = 0,	v = 0 },
	},
	--[4] Bottom Right Corner
	{
		{ x = sx + 0.5 * m,	y = sy + 0.5 * m,	u = 1,	v = 1 },
		{ x = sx + m,		y = sy + 0.5 * m,	u = 0,	v = 1 },
		{ x = sx + m,		y = sy + m,			u = 0,	v = 0 },
		{ x = sx + 0.5 * m,	y = sy + m,			u = 1,	v = 0 },
	},
	--[5] Covers whole scope
	{
		{ x = sx,			y = sy,				u = 0,	v = 0 },
		{ x = sx + m,		y = sy,				u = 1,	v = 0 },
		{ x = sx + m,		y = sy + m,			u = 1,	v = 1 },
		{ x = sx,			y = sy + m,			u = 0,	v = 1 },
	}
}




end

--[[
* SHARED
* Event

Secondary attack controls the laser / scope zoom
]]--
function ITEM:OnSecondaryAttack()
	self:InheritedEvent( "OnSecondaryAttack", "base_weapon" );
	self:SetNextSecondary( CurTime() + 0.1 );

	--TODO prediction errors are killing the scope code, this is a temporary solution to help deal with that.
	if CLIENT then return end

	--Zoom in
	local iZL = self:GetNWInt( "ZoomLevel" );
	if iZL == 4 then
		--self:EmitSound( self.ZoomOutSound, true );
		self:EmitSound( self.ZoomOutSound );

		self:SetNWInt( "ZoomLevel", 0 );
	else
		--if iZL == 0 then self:EmitSound( self.ZoomInSound, true ); end
		if iZL == 0 then self:EmitSound( self.ZoomInSound ); end

		self:SetNWInt( "ZoomLevel", iZL + 1 );
	end
	
	return true;
end

--[[
* SHARED
* Event

This is a big weapon size-wise. Items of size 30 or greater can't be held by default, so we make an exception here.
]]--
function ITEM:CanHold( pl )
	return true;
end

if CLIENT then





--[[
* CLIENT

Returns true if the local player is in thirdperson, or false otherwise.
]]--
function ITEM:IsOwnerThirdperson()
	return GetViewEntity() != LocalPlayer();
end

--[[
* CLIENT

Draws a laser beam from one point to another. Draws a hit sprite at vTo.
]]--
function ITEM:DrawBeam( eEnt, vFrom, vTo )
	local fTexCoord = CurTime() + 0.0078125 * vFrom:Distance( vTo );		--0.0078125 = 1/128
	render.SetMaterial( self.LaserMat );
	render.DrawBeam( vFrom, vTo, 2, 0, fTexCoord, self.LaserColor );
	
	render.SetMaterial( self.LaserHitMat );
	render.DrawSprite( vTo, self.LaserHitSize, self.LaserHitSize, self.LaserColor );
	
	if eEnt != nil then eEnt:SetRenderBoundsWS( vFrom, vTo ); end
end

--[[
* CLIENT

Returns the position of the laser attachment point on the sniper's world model
]]--
function ITEM:GetLaserWorldAP( eEnt )
	if self.LaserWorldAP == 0 then	self.LaserWorldAP = eEnt:LookupAttachment( "laser" ); end
	if self.LaserWorldAP != 0 then	return eEnt:GetAttachment( self.LaserWorldAP );
	else							return { Pos = eEnt:GetPos(), Ang = eEnt:GetAngles() };
	end
end

--[[
* CLIENT

Returns the position of the laser attachment point on the sniper's view model
]]--
function ITEM:GetLaserVMAP( eEnt )
	if self.LaserVMAP == 0 then	self.LaserVMAP = eEnt:LookupAttachment( "laser" ); end
	if self.LaserVMAP != 0 then	return eEnt:GetAttachment( self.LaserVMAP );
	else						return { Pos = eEnt:GetPos(), Ang = eEnt:GetAngles() };
	end
end

--[[
* CLIENT
* Event

If the laser is on, then in addition to drawing the sniper rifle, we draw a laser beam coming out of it.
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent )
	self:BaseEvent( "OnDraw3D", nil, eEntity, bTranslucent );
	if self:GetNWInt( "ZoomLevel" ) < 1 then return end
	
	local ap	 = self:GetLaserWorldAP( eEntity );
	local muzzle = self:GetMuzzle( eEntity );
	
	if eEntity == self:GetEntity() then
		--We're drawing from the rifle when it's on the ground. We draw in a straight line from the laser attachment point.
		local tr  = {};
		tr.start  = ap.Pos;
		tr.endpos = ap.Pos + ( 16384 * muzzle.Ang:Forward() );			--The model is messed up a bit. The laser attachment point is not facing the same direction as the muzzle.
		tr.filter = eEntity;
		tr.mask   = MASK_SHOT;
		
		local traceRes = util.TraceLine( tr );
		self:DrawBeam( eEntity, ap.Pos, traceRes.HitPos );
	elseif self.WMAttach && eEntity == self.WMAttach.ent then
		--We're drawing from a player's weapon world model
		local pl	= self:GetWOwner();
		local eyes	= pl:EyePos();
		
		--We draw to where the player is looking
		local tr  = {};
		tr.start  = eyes;
		tr.endpos = eyes + ( 16384 * pl:EyeAngles():Forward() );
		tr.filter = { pl, eEntity };
		tr.mask   = MASK_SHOT;
		
		local traceRes = util.TraceLine( tr );
		self:DrawBeam( eEntity, ap.Pos, traceRes.HitPos );
	else
		--Don't bother doing any traces at all if we're drawing for an item slot, just draw a laser going straight out from the laser attachment point
		self:DrawBeam( nil, ap.Pos, ap.Pos + ( 16384 * muzzle.Ang:Forward() ) );
	end
end

--[[
* CLIENT

Sets the target zoom level (in degrees) to the given number.
The camera's FoV will approach this over time.
]]--
function ITEM:ZoomTo( ZoomLevel )
	self.TargetZoom = ZoomLevel;
end

--[[
* CLIENT
* Event

In addition to doing regular base_ranged OnSWEPThink stuff,
makes the scope's actual zoom level get closer to the target zoom level.
]]--
function ITEM:OnSWEPThink()
	self:BaseEvent( "OnSWEPThink" );
	if self:GetNWInt( "ZoomLevel" ) < 2 then return false end
	
	if !self.LastThinkAt then self.LastThinkAt = CurTime() end
	
	local delta = CurTime() - self.LastThinkAt;
	if		self.CurrentZoom < self.TargetZoom then		self.CurrentZoom = math.Clamp( self.CurrentZoom + ( self.ZoomTime * delta ), 0,					self.TargetZoom	);
	elseif	self.CurrentZoom > self.TargetZoom then		self.CurrentZoom = math.Clamp( self.CurrentZoom - ( self.ZoomTime * delta ), self.TargetZoom,	75				);
	end
	
	self.LastThinkAt = CurTime();
end

--[[
* CLIENT
* Event

If the laser is on, then in addition to drawing the sniper rifle, we draw a laser beam coming out of it.
]]--
function ITEM:OnSWEPDrawViewmodel()
	self:BaseEvent( "OnSWEPDrawViewmodel" );
	if self:GetNWInt( "ZoomLevel" ) == 0 then return end
	
	local pl	= LocalPlayer();
	local vm	= pl:GetViewModel();
	local ap	= self:GetLaserVMAP( vm );
	local eyes	= pl:EyePos();
	
	local ang;
	if vm:GetSequence() == 0 then	ang = pl:EyeAngles();
	else							ang = ap.Ang;
	end
	
	local tr  = {};
	tr.start  = eyes;
	tr.endpos = eyes + ( 16384 * ang:Forward() );
	tr.filter = { pl, vm };
	tr.mask   = MASK_SHOT;
	local traceRes = util.TraceLine( tr );
	
	self:DrawBeam( nil, ap.Pos, traceRes.HitPos );
end

--[[
* CLIENT
* Event

Draws the parabolic sights / scope overlay on the screen.
This will only happen while the local player is holding an item and has the weapon out.
]]--
function ITEM:OnSWEPDrawHUD()
	if self:GetNWInt( "ZoomLevel" ) < 2 || self:IsOwnerThirdperson() then return end
	
	surface.SetDrawColor( 0, 0, 0, 255);
	--Draw black bars to the left & right of scope if necessary
	if self.ScopeX > 0 then
		surface.DrawRect( 0,								0,									self.ScopeX + 1,	ScrH() );
		surface.DrawRect( self.ScopeX + self.ScopeMin - 1,	0,									self.ScopeX + 2,	ScrH() );
	end
	--Draw black bars above & below of scope if necessary
	if self.ScopeY > 0 then
		surface.DrawRect( 0,								0,									ScrW(),				self.ScopeY + 1 );
		surface.DrawRect( self.ScopeX,						self.ScopeY + self.ScopeMin - 1,		ScrW(),				self.ScopeY + 2 );
	end
	
	--Draw scope corner by corner
	surface.SetMaterial( self.ScopeMat );
	surface.DrawPoly( self.ScopePolies[1] );
	surface.DrawPoly( self.ScopePolies[2] );
	surface.DrawPoly( self.ScopePolies[3] );
	surface.DrawPoly( self.ScopePolies[4] );
	
	--Draw parabolic sights, flicker
	surface.SetDrawColor( 0, 0, 0, 240 + 10 * math.sin( 60 * CurTime() ) );
	surface.SetMaterial( self.ParabolicSightsMat );
	surface.DrawPoly( self.ScopePolies[5] );
end

--[[
* CLIENT
* Event

If the sniper rifle's scope is being used, and the player is in first person, zooms the player's view to the current zoom level
]]--
function ITEM:OnSWEPTranslateFOV( fCurrentFOV )
	--We don't want to perform a zoom if the owner is thirdperson
	return ( self:IsOwnerThirdperson() && fCurrentFOV ) || ( fCurrentFOV - self.CurrentZoom );
end

--[[
* CLIENT
* Event

Modifies the mouse sensitivity when zoomed in
]]--
function ITEM:OnSWEPAdjustMouseSensitivity()
	return 1 - self.CurrentZoom / 80;
end

--[[
* CLIENT
* Event

Whenever the zoom level is set, sets the target zoom accordingly.
]]--
function ITEM:OnSetNWVar( strKey, vVal )
	self:BaseEvent( "OnSetNWVar", nil, strKey, vVal );
	if strKey == "ZoomLevel" then
		if vVal == 0 then self.CurrentZoom = 0 end

		self:ZoomTo( self.ZoomLevels[vVal + 1] );
	end
end




end

IF.Items:CreateNWVar( ITEM, "ZoomLevel", "int", 0, nil, true );