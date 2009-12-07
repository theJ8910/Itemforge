--[[
ammo_buckshot
SHARED

This is ammunition for the HL2 shotgun. Or, I guess, any 12 gauge shotgun.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Buckshot";
ITEM.Description="This is 12 gauge buckshot.\nThese lead-shot filled shotgun shells are used for combat purposes as well as for hunting large game.";
ITEM.Base="base_ammo";
ITEM.StartAmount=20;
ITEM.Size=4;
ITEM.Weight=32;

if SERVER then

ITEM.HoldType="slam";

else

ITEM.WorldModelNudge=Vector(-2,-3,-4);
ITEM.WorldModelRotate=Angle(0,0,0);

end

--[[
Just to demonstrate what you can do with this system, the shotgun ammo has two world models!
When we have less than "TurnsBoxAt" shells, we use the single shotgun shell model (you know, the shell-ejection model)
When we have "TurnsBoxAt" shells or more, we use the box of shotgun shells model (like the item_buckshot entity)
]]--
ITEM.TurnsBoxAt=20;
ITEM.WorldModelSingle="models/weapons/Shotgun_shell.mdl";
ITEM.WorldModelBox="models/Items/BoxBuckshot.mdl";
ITEM.WorldModel=ITEM.WorldModelBox;

if SERVER then




ITEM.SingleShellImpactSounds={
	Sound("weapons/fx/tink/shotgun_shell1.wav"),
	Sound("weapons/fx/tink/shotgun_shell2.wav"),
	Sound("weapons/fx/tink/shotgun_shell3.wav"),
}

--[[
If we're using the shell model, we use a custom physics box.
If we're using the box of ammo model, we use it's physics.
]]--
function ITEM:OnEntityInit(entity)
	local wm=self:GetWorldModel();
	entity:SetModel(wm);
	
	if wm==self.WorldModelSingle then	entity:PhysicsInitBox(Vector(-3,-1,0),Vector(3,1,2)) --self:PhysicsInitCylinder(entity,1,6,5,Vector(0,0,1),Angle(0,0,0))
	else								entity:PhysicsInit(SOLID_VPHYSICS); end
	
	local phys = entity:GetPhysicsObject();
	if (phys:IsValid()) then
		if wm==self.WorldModelSingle then phys:SetMass(1) end
		phys:Wake();
	end
	
	entity:SetUseType(SIMPLE_USE);
	
	return true;
end

--[[
Play shell impact sounds on collide.
CollisionData is information about the collision passed on from the entity's event.
HitPhysObj is the physics object belonging to this entity which collided.
]]--
function ITEM:OnPhysicsCollide(entity,CollisionData,HitPhysObj)
	if self:GetAmount()>=self.TurnsBoxAt then return false end
	if (CollisionData.Speed > 20 && CollisionData.DeltaTime > 0.2 ) then
		self:EmitSound(self.SingleShellImpactSounds[math.random(1,#self.SingleShellImpactSounds)]);
	end
end

--TODO changing to single breaks physics; fix by re-sending or re-initing physics
function ITEM:OnSetNWVar(sName,vVal)
	if sName=="Amount" then
		if vVal >= self.TurnsBoxAt then			self:SetWorldModel(self.WorldModelBox);
		else									self:SetWorldModel(self.WorldModelSingle);
		end
	end
	
	return self["base_ammo"].OnSetNWVar(self,sName,vVal);
end

--[[
DOESN'T WORK - Gives me vphysics crap about infinite origins/infinite angles;
For that matter, I tried giving it a Mesh cube physics model and it wouldn't move... so who knows what the hell is going on...
I know that I generated the cylinder itself correctly; I looked at a wireframe version of it and it's polygons are laid out correctly, so I'm guessing this is some problem on garry's end with mesh physics?

Gives the given entity a cylinder for a physics model.
entity is the entity to give a cylinder physics model.
fRadius is the radius of the cylinder, in standard game units.
fHeight is the height of the cylinder, in standard game units.
iSides is the number of sides the cylinder has; the lower this number is, the "rougher" the cylinder is; however this is also FASTER to compute (less lag).
vOffset is an optional amount to shift the physics model from the center of the entity. This should be a vector.
aOffset is an optional amount to rotate the physics model. This should be an angle.

Details about the cylinder generated:
	Orientation: If aOffset is nil or <0,0,0>, then when the entity's angles are set to <0,0,0> the cap of the cylinder is facing up.
	Positioning: If vOffset is nil or <0,0,0>, then the center of the cylinder is the center of the entity.
]]--
function ITEM:PhysicsInitCylinder(eEntity,fRadius,fHeight,iSides,vOffset,aOffset)
	if !eEntity || !eEntity:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't give entity physics cylinder; no entity given!\n"); return false end
	if !fRadius then ErrorNoHalt("Itemforge Items: Couldn't give entity physics cylinder; radius wasn't given!\n"); return false end
	if !fHeight then ErrorNoHalt("Itemforge Items: Couldn't give entity physics cylinder; height wasn't given!\n"); return false end
	if !iSides then ErrorNoHalt("Itemforge Items: Couldn't give entity physics cylinder; number of sides wasn't given!\n"); return false end
	if iSides<3 then ErrorNoHalt("Itemforge Items: Couldn't give entity physics cylinder; cylinders need at least 3 sides. You gave "..tostring(iSides).." sides.\n"); return false end
	
	vOffset=vOffset or Vector(0,0,0);
	aOffset=aOffset or Angle(0,0,0);
	fHeight=fHeight*.5;
	local frac=(2*math.pi)/iSides;
	local Fwd	=	aOffset:Forward();
	local Left	=	aOffset:Right()*-1;
	local Up	=	aOffset:Up()*fHeight;
	local Down	=	Up*-1;
	
	local verts={};
	for i=0,iSides-1 do
		local theta=frac*i;
		local oxy=vOffset+Fwd*math.cos(theta)+Left*math.sin(theta);	--oxy stands for "Offset, X, and Y"
		
		table.insert(verts,Vertex(oxy+Up));
		if i>0 then
			local n=table.getn(verts);
			table.insert(verts,verts[n]);
			table.insert(verts,verts[n-1]);
			table.insert(verts,Vertex(oxy+Down));
			
			--Generate cap segments
			if i>1 then
				--Top cap
				table.insert(verts,verts[1]);
				table.insert(verts,verts[n-2]);
				table.insert(verts,verts[n]);
				--Bottom cap
				table.insert(verts,verts[2]);
				table.insert(verts,verts[n-1]);
				table.insert(verts,verts[n+3]);
			end
			
			table.insert(verts,verts[n]);
			table.insert(verts,verts[n+3]);
			
			--Connect last side
			if i==iSides-1 then
				table.insert(verts,verts[1]);
				table.insert(verts,verts[1]);
				table.insert(verts,verts[n+3]);
				table.insert(verts,verts[2]);
			end
		else
			table.insert(verts,Vertex(oxy+Down));
		end
	end
	
	--DEBUG; draw wireframe version of physics model at center of map
	--Three verts is one polygon
	local c=Color(255,128,0,255);
	for i=1,table.getn(verts),3 do
		debugoverlay.Line(verts[i].pos	,verts[i+1].pos	,60,c);
		debugoverlay.Line(verts[i+1].pos,verts[i+2].pos	,60,c);
		debugoverlay.Line(verts[i+2].pos,verts[i].pos	,60,c);
	end
	
	--Finally, apply to the entity
	eEntity:PhysicsFromMesh(verts);
end




end