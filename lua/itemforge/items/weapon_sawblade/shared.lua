--[[
weapon_sawblade
SHARED

A sawblade. It sticks in things if it hits it fast enough.
The math for this was a little irritating but I think I've got it down now.

The sawblade is a throwable, stackable weapon.

View Model by NeoDement
]]--

if SERVER then
	AddCSLuaFile("shared.lua");
	
	--We also need to send the viewmodel
	resource.AddFile("models/weapons/v_sawblade.mdl");
	resource.AddFile("models/weapons/V_sawblade.dx80.vtx");
	resource.AddFile("models/weapons/V_sawblade.dx90.vtx");
	resource.AddFile("models/weapons/V_sawblade.sw.vtx");
	resource.AddFile("models/weapons/v_sawblade.vvd");
end

ITEM.Name="Sawblade";
ITEM.Description="A circular steel sawblade with razor-sharp teeth.\nThese types of blades are often a part of woodworking machinery.";
ITEM.Base="base_thrown";
ITEM.MaxAmount=10;
ITEM.Size=26;
ITEM.Weight=35856;				--Weighs approximately 36 kg or around 72 pounds (YEESH - the sawblade is about 2 feet in diameter though, and made out of steel. It's not that surprising is it?). Calculated using density of steel #1 (http://hypertextbook.com/facts/2004/KarenSutherland.shtml) multiplied by the volume in cubic centimeters (converted from game units) of an inner cylinder subtracted from an outer cylinder. The thickness and radii were calculated by getting the distance between trace .HitPos itions on the sawblade model.
ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.WorldModel="models/props_junk/sawblade001a.mdl";
ITEM.ViewModel="models/weapons/v_sawblade.mdl";

if SERVER then
	ITEM.HoldType="slam";
else
	ITEM.Icon=Material("itemforge/items/item_sawblade");
	ITEM.WorldModelNudge=Vector(18,0,0);
	ITEM.WorldModelRotate=Angle(0,45,0);
end

--Overridden base weapon stuff
ITEM.PrimaryDelay=1.5;
ITEM.SecondaryDelay=1.5;

--Overridden base thrown stuff
ITEM.ThrowDelay=0.2;
ITEM.ThrowAngleMin=Angle(0,0,0);
ITEM.ThrowAngleMax=Angle(0,0,0);
ITEM.ThrowSpinMin=Angle(0,0,-2000);
ITEM.ThrowSpinMax=Angle(0,0,-500);


--Sawblade
ITEM.StickSpeed=500;			--The sawblade has to be going at least this fast to stick into something
ITEM.StickBy=9;					--The sawblade will dig in this far (in units) when it hits something
ITEM.StickStrength=30000;		--When the sawblade welds to another prop it takes this much force to break the weld.
ITEM.MinAngle=math.pi*.25;		--This is the minimum angle the sawblade must hit an object "head on" to stick into. It is 45 degrees in radians:	PI * .25 = PI/4  = 45 degrees
ITEM.MaxAngle=math.pi*.75;		--This is the maximum angle the sawblade must hit an object "head on" to stick into. It is 135 degrees in radians:	PI * .75 = 3PI/4 = 135 degrees

ITEM.StickSounds={				--A random sound here plays whenever the sawblade sticks in something
	Sound("physics/metal/sawblade_stick1.wav"),
	Sound("physics/metal/sawblade_stick2.wav"),
	Sound("physics/metal/sawblade_stick3.wav")
}

ITEM.UnstickSounds={
	Sound("npc/roller/blade_out.wav")
};
ITEM.BloodyTypes={
["player"]=true,
["npc_monk"]=true,
["npc_crow"]=true,
["npc_pigeon"]=true,
["npc_seagull"]=true,
["npc_combine_s"]=true,
["npc_hunter"]=true,
["npc_alyx"]=true,
["npc_barney"]=true,
["npc_citizen"]=true,
["npc_kleiner"]=true,
["npc_kleiner"]=true,
["npc_magnusson"]=true,
["npc_eli"]=true,
["npc_gman"]=true,
["npc_mossman"]=true,
["npc_breen"]=true,
["npc_vortigaunt"]=true,
["npc_metropolice"]=true,
["npc_antlion"]=true,
["npc_antlion_worker"]=true,
["npc_antlion_grub"]=true,
["npc_antlionguard"]=true,
["npc_barnacle"]=true,
["npc_zombie_torso"]=true,
["npc_fastzombie_torso"]=true,
["npc_zombie"]=true,
["npc_fastzombie"]=true,
["npc_poisonzombie"]=true,
["npc_zombine"]=true,
["npc_headcrab"]=true,
["npc_headcrab_fast"]=true,
["npc_headcrab_black"]=true,
}

--Don't modify/override these; they're set automatically.
ITEM.StickingTo=nil;

--[[
* SHARED

Throws the item oriented horizontally.
This override is necessary because base_thrown only cooldowns the primary attack. This cooldowns the secondary too.
]]--
function ITEM:OnPrimaryAttack()
	if !self["base_thrown"].OnPrimaryAttack(self) then return false end
	self:SetNextSecondary(CurTime()+self:GetPrimaryDelay(),CurTime()+self:GetPrimaryDelayAuto());
	
	return true;
end


--[[
* SHARED

Throws the item oriented vertically.
]]--
function ITEM:OnSecondaryAttack()
	if !self["base_weapon"].OnSecondaryAttack(self) then return false end
	self:SetNextPrimary(CurTime()+self:GetSecondaryDelay(),CurTime()+self:GetSecondaryDelayAuto());
	
	self:ThrowEffects();
	if self.ThrowDelay then
		self:CreateTimer("ThrowTimer",self.ThrowDelay,1,self.Throw,self:GetWOwner(),nil,nil,Angle(0,0,90));
	else
		self:Throw(self:GetWOwner(),nil,nil,Angle(0,0,90));
	end
	
	return true;
end


if SERVER then




function ITEM:OnUse(pl)
	if self:IsStuck() then
		self:UnstickSound();
		self:Unstick(pl);
		return true;
	end
	return self["base_thrown"].OnUse(self,pl);
end

--Unstick without sounds when we leave the world
function ITEM:OnExitWorld(forced)
	self:Unstick();
end

--[[
We use this function for the sawblade's awesome stick-in stuff.
If the sawblade is going fast enough, and hits something head on, we can stick in it.

We can determine if it hit "head on" like so:
Lets say that...

A sawblade, broad side facing directly up...   ...Collides with a surface facing this way
 ^                                
 |                                             |
(o)              ~~~~WOOSH~~~~>             <--|
                                               |

Compare the sawblade facing angle and wall angle:
    ^
    |  90 degrees
 <--o

If angle falls between 45 degrees and 135 degrees it means the saw blade hit the surface "Head On", so it can stick/kill things/whatever.
]]--
function ITEM:OnPhysicsCollide(entity,CollisionData,HitPhysObj)
	if (CollisionData.Speed < self.StickSpeed) then return false end
	
	local ent=self:GetEntity();
	local ent2=CollisionData.HitEntity;
	
	local killCredit=self:GetKillCredit() or ent;
	
	local sawUp=ent:GetAngles():Up();
	local hitDir=CollisionData.HitNormal;
	
	local angMeasure=math.acos(sawUp:Dot(hitDir));
	
	--We only damage or stick in things we hit head on
	if angMeasure<self.MinAngle || angMeasure>self.MaxAngle then return false end
	
	--Kill (or at least really mess up) players and NPCs
	if self.BloodyTypes[ent2:GetClass()] then
		ent2:TakeDamage(100,killCredit,ent);
		
		local effectdata = EffectData();
		effectdata:SetOrigin(ent:GetPos());
		effectdata:SetEntity(ent);
		effectdata:SetAngle(( CollisionData.HitPos-ent:GetPos() ):Angle() );
		util.Effect("BladeBlood",effectdata,true,true);
		
		local phys=ent:GetPhysicsObject();
		if phys && phys:IsValid() then
			phys:SetVelocity(CollisionData.OurOldVelocity);
		end
		
	--Otherwise, stick in whatever we hit
	else
		self:EmitSound(self.StickSounds);
		ent:SetPos(CollisionData.HitPos+(hitDir*-self.StickBy));
		
		if ent2:IsWorld() then
			local phys=ent:GetPhysicsObject();
			if phys && phys:IsValid() then
				phys:EnableMotion(false);
			end
		else
			--Whatever we hit takes a little bit of damage. We /did/ just cut into it, right?
			ent2:TakeDamage(10,killCredit,ent);
			
			--If we hit something with a physics object, we can weld to it
			local phys2=CollisionData.HitObject;
			if phys2 && phys2:IsValid() then
				
				--But first we have to determine which physics object we hit on the entity (in case of ragdolls)
				local hitbone=0;
				for i=0,ent2:GetPhysicsObjectCount()-1 do
					if ent2:GetPhysicsObjectNum(i)==phys2 then hitbone=i; break; end
				end
				
				--Have to use a timer because according to garry's error message initing a constraint in a physics hook can cause crashes?
				self:SimpleTimer(0,self.StickTo,ent2,hitbone,self.StickStrength,phys2:WorldToLocal(ent:GetPos()),ent2:WorldToLocalAngles(ent:GetAngles()));
			end
		end
	end
end

--[[
Welds the item to an entity and stores the weld in the item's "StickingTo" table.
ent is the entity to weld to.
bone is the physics bone number to weld to.
str is the strength of the weld (0 for unbreakable; except by Unstick() of course)
lpos is the position of the sawblade relative to the physics object.
lang is the rotation of the sawblade relative to the physics object.
]]--
function ITEM:StickTo(ent,bone,str,lpos,lang)
	local eEnt=self:GetEntity();
	if !eEnt || !ent || !ent:IsValid() then return false end
	
	local phys=ent:GetPhysicsObjectNum(bone);
	if !phys || !phys:IsValid() then return false end
	
	--Create the "Sticking To" table if it hasn't been created yet
	if !self.StickingTo then self.StickingTo={} end
	
	--Since the sawblade or what it was sticking to might have moved we set the local pos/ang here
	eEnt:SetPos(phys:LocalToWorld(lpos));
	eEnt:SetAngles(ent:LocalToWorldAngles(lang));
	
	--Weld to what we want, fail if we couldn't
	local weld=constraint.Weld(eEnt,ent,0,bone,str,true);
	if !weld || !weld:IsValid() then return false end
	
	--Add the weld
	local id=table.insert(self.StickingTo,{weld,ent});
	weld:CallOnRemove("Unstuck",self.Unstuck,self,id);
	
	return true;
end

--[[
Returns true if the sawblade has stuck to something with self:StickTo()
This doesn't count for things like toolgun welds.

to is an optional entity. If to is given, then we'll only return true if the sawblade is stuck to THAT entity.
Otherwise, true is returned as long as the sawblade is stuck to something.
False is returned in all other cases.
]]--
function ITEM:IsStuck(to)
	if !self.StickingTo then return false end
	if to==nil then
		for k,v in pairs(self.StickingTo) do
			if v[1]:IsValid() then return true end
		end
	else
		for k,v in pairs(self.StickingTo) do
			if v[1]:IsValid() && v[1]==to then return true end
		end
	end
	
	return false;
end

--[[
Unwelds the sawblade from something it was stuck to with StickTo.
pl is an optional player. If pl is given, any damage the sawblade does to an object from being unstuck will be credited to this player.
from is an optional entity. If from is given, the sawblade is only unstuck from that entity.
Otherwise, the sawblade is unstuck from everything it is attached to.
]]--
function ITEM:Unstick(pl,from)
	if !self.StickingTo then return true end
	local ent=self:GetEntity();
	if pl==nil then pl=ent end
	
	if from==nil then
		for k,v in pairs(self.StickingTo) do
			if v[1]:IsValid() then
				v[1]:RemoveCallOnRemove("Unstuck");
				v[1]:Remove();
			end
			if v[2]:IsValid() then
				v[2]:TakeDamage(10,pl,ent);
			end
		end
		self.StickingTo=nil;
		return true;
	else
		for k,v in pairs(self.StickingTo) do
			if v[2]:IsValid() && v[2]==from then
				if v[1]:IsValid() then
					v[1]:RemoveCallOnRemove("Unstuck");
					v[1]:Remove();
				end
				v[2]:TakeDamage(10,pl,ent);
				self.StickingTo[k]=nil;
				return true;
			end
		end
		return false;
	end
	
end

--[[
Play the unstick sound on this item
]]--
function ITEM:UnstickSound()
	self:EmitSound(self.UnstickSounds);
end

--[[
This function is called when the sawblade is pulled out of one of the things it's stuck in by force.
This function is written strangely for technical reasons.
weld is the weld entity that was broken (this was holding the sawblade and whatever it was stuck in together)
self is this item.
id is where the sawblade recorded weld in self.StickingTo.
]]--
function ITEM.Unstuck(weld,self,id)
	self:UnstickSound();
	local ent=self:GetEntity();
	self.StickingTo[id][2]:TakeDamage(10,ent,ent);
	self.StickingTo[id]=nil;
end




else




--The sawblade icon moves in an elliptical way on the weapons menu
function ITEM:OnSWEPDrawMenu(x,y,w,h,a)
	local icon,s=self:Event("GetIcon");
	if !s then return false end
	
	local t=CurTime()*10;
	local c=self:GetColor();
	surface.SetMaterial(icon);
	surface.SetDrawColor(c.r,c.g,c.b,a-(255-c.a));
	surface.DrawTexturedRect(x + (w-128)*.5 + math.cos(t)*16 ,
							 y + (h-128)*.5 + math.sin(t)*8  ,
							 128,128);
end




end