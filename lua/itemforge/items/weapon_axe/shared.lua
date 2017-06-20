--[[
weapon_axe
SHARED

A hatchet! For chopping wood or as a general purpose melee weapon?
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Axe";
ITEM.Description		= "A steel hatchet with a sturdy wooden handle.\nNot only is it good for chopping wood, it looks like it could serve as a decent weapon!";
ITEM.Base				= "base_melee";
ITEM.Weight				= 1400;			--Googling for steel axes produces weights between 1.3 and 1.5 kg... 
ITEM.Size				= 16;

--There are actually two copies of this axe's world model; one belongs to Counter-Strike: Source, the other belongs to Half-Life 2: Episode 2. I chose CS:S because I figured more people had that game.
ITEM.WorldModel			= "models/props/CS_militia/axe.mdl";
ITEM.Spawnable			= true;
ITEM.AdminSpawnable		= true;

if SERVER then




ITEM.GibEffect			= "wood";




else




ITEM.WorldModelNudge	= Vector( 0, 0, 7 );
ITEM.WorldModelRotate	= Angle( 90, 0, -90 );




end

--Overridden Base Weapon stuff
ITEM.HasPrimary			= true;
ITEM.PrimaryDelay		= 0.8;
ITEM.ViewKickMin		= Angle( 3.0, -3.0, 0 );
ITEM.ViewKickMax		= Angle( 4.0, -2.0, 0 );

--Overridden Base Melee stuff
ITEM.HitRange			= 75;
ITEM.HitForce			= 1.5;
ITEM.HitDamage			= 50;

ITEM.HitSounds		= {
	Sound( "Weapon_Crowbar.Melee_Hit" )
};
ITEM.MissSounds		= {
	Sound( "Weapon_Crowbar.Single" )
};


--Axe Weapon
ITEM.FleshyImpactSounds = {
	Sound( "d1_town.Slicer" )
}

--[[
If a trace result says we hit one of these materials, then we "hit flesh" and play
the appropriate sound.
]]--
ITEM.FleshyMatTypes = {
	[MAT_FLESH]			= true,
	[MAT_BLOODYFLESH]	= true,
	[MAT_ALIENFLESH]	= true,
	[MAT_ANTLION]		= true
};

--[[
* SHARED
* Event

Probably could add some wood-chopping function here
]]--
--[[
function ITEM:OnHit( traceRes )
	return self:BaseEvent( "OnHit", nil, traceRes );
end
]]--

--[[
* SHARED
* Event

Play a fleshy hit sound if we chopped into flesh, or the standard sound if we didn't
]]--
function ITEM:GetHitSound()
	if self.FleshyMatTypes[self:GetLastTraceResults().MatType] == true then
		return self.FleshyImpactSounds;
	end
	return self.HitSounds;
end