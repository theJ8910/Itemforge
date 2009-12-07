--[[
item_pumpkin
SHARED

A pumpkin. Completely unremarkable.

You are absolutely certain this is the most unremarkable pumpkin you have ever laid eyes upon.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

local Up=Vector(0,0,1);
local Down=Vector(0,0,-1000);
local Offset=Vector(0,0,23);
local Slope=.5235987756;	--30 degrees to radians

ITEM.Name="Pumpkin";
ITEM.Description="What pumpkin?";
ITEM.MaxHealth=50;
ITEM.Size=17;
ITEM.Weight=6800;			--The average weight of a pumpkin is between 10-20 pounds (http://wiki.answers.com/Q/How_much_does_the_average_pumpkin_weigh)
ITEM.ThinkRate=0;

ITEM.WorldModel="models/props_outland/pumpkin01.mdl";

if SERVER then




ITEM.DisappearAfter=0;					--The pumpkin disappears after a player has looked this many seconds (set to a random number for each pumpkin; check Init)
ITEM.ReappearAfter=0;					--The pumpkin reappears after these many seconds have passed (set to a random number for each pumpkin; check Init)
ITEM.PlayerWatching=nil;				--The player who is watching this pumpkin, if any.
ITEM.AppearanceEventAt=0;				--This will be set to a future time for the pumpkin to disappear (in the case the player is looking at it) or reappear (in the case the pumpkin has disappeared and is waiting to reappear)
ITEM.ReappearLocation=Vector(0,0,0);	--The pumpkin reappears at this location in the world

function ITEM:OnInit()
	self:StartThink();
	self.DisappearAfter=math.Rand(2,5);
	self.ReappearAfter=math.Rand(4,30);
end

--*burp*
function ITEM:OnUse(pl)
	local h=pl:Health();
	if h>=100 then return false; end
	
	pl:SetHealth(math.Clamp(h+10,0,100));
	self:Hurt(self:GetMaxHealth(),pl);
	
	return true;
end

--The item makes decisions on a frame by frame basis
function ITEM:OnThink()
	local ent=self:GetEntity();
	local pl=self:GetPlayerWatching();
	if ent then
		if pl then
			--Watching player has lost sight of the pumpkin
			if !self:CanPlayerSee(pl,ent:GetPos()) then
				self:SetPlayerWatching(nil);
			
			--I will be ogled no further! Take flight! Ride the winds to oblivion!
			elseif CurTime()>=self.AppearanceEventAt then
				self:Disappear();
			end
		else
			-->> Pumpkin: Scan for potential threats.
			for k,v in pairs(player.GetAll()) do
				if self:CanPlayerSee(v,ent:GetPos()) then
					self:SetPlayerWatching(v);
					return;
				end
			end
		end
	else
	
		--The player that was watching the pumpkin is gone. It's safe now.
		if !pl then
			self:Reappear();
		
		--While we're waiting to reappear, lets find a nice spot to reappear at.
		elseif CurTime()<self.AppearanceEventAt then
			local tr={};
			local eye=pl:EyePos();
			tr.start		=	eye;
			tr.endpos		=	eye+(pl:EyeAngles():Forward()*3000);
			tr.filter		=	pl;
			traceRes		=	util.TraceLine(tr); 
			
			--Surface slope where 0 is a flat surface and 90/-90 is a wall and 180/-180 is a ceiling
			local hitAngle=math.acos(Up:Dot(traceRes.HitNormal));
			
			if hitAngle>=-Slope && hitAngle<=Slope then
				self.ReappearLocation=traceRes.HitPos;
			end
			
		--Quick! While he's not looking!
		elseif !self:CanPlayerSee(pl,self.ReappearLocation) then
			self:Reappear();
		end
	end
end

--Set the player currently looking at us.
function ITEM:SetPlayerWatching(pl)
	self.PlayerWatching=pl;
	
	if pl!=nil then
		self.AppearanceEventAt=CurTime()+self.DisappearAfter;
	end
end

--What player is currently watching me?
function ITEM:GetPlayerWatching()
	if self.PlayerWatching && !self.PlayerWatching:IsValid() then
		self:SetPlayerWatching(nil);
	end
	return self.PlayerWatching;
end

--Can the player see this point?
function ITEM:CanPlayerSee(pl,vPoint)
	if !pl:Alive() then return false end
	
	--Is the player looking in the direction of this point?
	local eyes=pl:EyePos();
	local fov=math.Deg2Rad(pl:GetFOV())*.55;
	local ViewAngle=math.acos(  pl:EyeAngles():Forward():Dot( (vPoint-eyes):Normalize() )  );
	
	if ViewAngle<-fov || ViewAngle>fov then return false end
	
	--About how close is the player to seeing this point? Are there significant obstacles in the way?
	local tr={};
	tr.start		=	eyes;
	tr.endpos		=	vPoint;
	tr.filter		=	pl;
	traceRes		=	util.TraceLine(tr); 
	
	return (traceRes.HitPos:Distance(vPoint)<300 || traceRes.HitPos:Distance(pl:GetPos())<100);
end

--Disappear from view. Reappear later, at this same spot if necessary.
function ITEM:Disappear()
	self.ReappearLocation=self:GetPos();
	self.AppearanceEventAt=CurTime()+self.ReappearAfter;
	self:ToVoid();
end

--Reappear at the reappear location.
function ITEM:Reappear()
	ent=self:ToWorld(self.ReappearLocation,Angle(0,math.Rand(0,360),0));
	if !ent then return false end
	
	ent:SetPos(self.ReappearLocation-Vector(0,0,ent:OBBMins().z))
end

--[[
function ITEM:Teleport()
	local ent=self:GetEntity();
	if !ent then return false end
	
	local tr={};
	local traceRes;
	
	for i=1,20 do
		tr.start		=	ent:GetPos()+(Up*20);
		tr.endpos		=	ent:GetPos()+Angle(math.Rand(0,360),math.Rand(0,360),math.Rand(0,360)):Forward()*3000;
		tr.filter		=	ent;
		traceRes		=	util.TraceEntity(tr,ent);
		
		if traceRes.Fraction>0.01 then
			
			--Surface slope where 0 is a flat surface and 90/-90 is a wall and 180/-180 is a ceiling
			local hitAngle=math.acos(Up:Dot(traceRes.HitNormal));
			
			if hitAngle>=-Slope && hitAngle<=Slope then
				self:ToWorld(traceRes.HitPos,Angle(0,math.Rand(0,360),0));
				--DoPropSpawnedEffect(ent);
				break;
			else
				tr.start		=	traceRes.HitPos;
				tr.endpos		=	traceRes.HitPos+Down;
				tr.filter		=	ent;
				traceRes		=	util.TraceEntity(tr,ent);
				
				if traceRes.Fraction>0.01 then
				
					if hitAngle>=-Slope && hitAngle<=Slope then
						self:ToWorld(traceRes.HitPos,Angle(0,math.Rand(0,360),0));
						--DoPropSpawnedEffect(ent);
						break;
					end
					
				end
			end
		end
	end
end
]]--


end