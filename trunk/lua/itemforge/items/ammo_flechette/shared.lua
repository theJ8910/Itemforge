--[[
ammo_flechette
SHARED

This is ammunition for the Flechette Gun.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Flechette";
ITEM.Description="Explosive, dagger-like hunter flechettes.";
ITEM.Base="base_ammo";
ITEM.Weight=20;			--The flechettes are pretty big, eh? Seems appropriate.
ITEM.Size=11;
ITEM.StartAmount=30;

ITEM.WorldModel="models/weapons/hunter_flechette.mdl";

ITEM.HoldType="melee";

--[[
* SHARED

Creates and fires a flechette at the given location, direction, and speed.
Doesn't consume ammo from the stack, just fires a flechette.

Clientside, this function does nothing; flechettes must be created on the server.

vPos should be the position that the flechette is being fired from.
ang should be the angle that the fired flechettes are heading off towards
speed should be the speed of the fired flechettes.
eKillCredit is an optional entity. If something is killed by the flechette, the kill is credited to this entity.

speed should be the speed to fire the flechette.
maxspread should be a number indicating the radius of a cone at a distance of 1 game unit from it's tip.

This returns true if a flechette was created and fired.
false is returned otherwise.
]]--
function ITEM:ShootFlechette(vPos,ang,speed,maxspread,eKillCredit)
	if CLIENT then return false end
	
	local fTheta = math.Rand(0,2*math.pi);
	local fSpread = math.Rand(0, maxspread);
	local fwd = ang:Forward() + fSpread*math.cos(fTheta)*ang:Right() + fSpread*math.sin(fTheta)*ang:Up();
	fwd:Normalize();

	local ent=ents.Create("hunter_flechette");
	if !ent || !ent:IsValid() then return false end
	ent:SetPos(vPos+fwd*32);
	ent:SetAngles(ang);
	ent:SetVelocity(fwd*speed);
	ent:SetOwner(eKillCredit);
	ent:Spawn();
	return true;
end

if SERVER then






--[[
* SERVER
* Event

If flechettes are launched from a Rock-It launcher,
the whole stack is fired shotgun style.

iRockitLauncher is the rock-it launcher the stack of flechettes was fired from.
pl is the player who fired it.
]]--
function ITEM:OnRockItLaunch(iRockitLauncher,pl)
	local pos;
	local ang;
	local eKillCredit;
	if iRockitLauncher:IsHeld() then
		eKillCredit = pl;
		pos=pl:GetShootPos();
		ang=pl:EyeAngles();
	elseif iRockitLauncher:InWorld() then
		eKillCredit  = iRockitLauncher:GetEntity();
		local posang = iRockitLauncher:GetMuzzle( eKillCredit );
		pos=posang.Pos;
		ang=posang.Ang;
	else
		return;
	end

	for i=1,self:GetAmount() do
		self:ShootFlechette(pos, Angle( ang.p+math.Rand(-5,5), ang.y+math.Rand(-5,5), ang.r), 2000, 0.0874886635, eKillCredit);
	end

	self:Remove();
end




else




	ITEM.WorldModelNudge=Vector(3,0,7);
	ITEM.WorldModelRotate=Angle(90,0,0);




end