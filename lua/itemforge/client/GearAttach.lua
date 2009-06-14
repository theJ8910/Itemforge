--[[
Itemforge Gear Attach Module
CLIENT

This implements basic functionality for adding, moving, and removing models fake-merged to bones and attachment points on players.
]]--
MODULE.Name="GearAttach";									--Our module will be stored at IF.GearAttach
MODULE.Disabled=false;										--Our module will be loaded

local Up=Vector(0,0,1);

--Attachment functions table. All attachments can use functions and values declared here.
local af={};

--Updates the attachment's position and draws it
function af:Draw()
	if self.type==1 then
		if !self.MAPPos then
			self.ent:SetPos(Vector(0,0,0));
			self.ent:SetAngles(Angle(0,0,0));
			self.MAPPos,self.MAPAng=self.ent:GetBonePosition(self.MAP);
		end
		local pos,a=self.pl:GetBonePosition(self.PAP);
		local b=self.MAPAng*1;
		
		local c=Angle(0,0,0);
		local offset=a-b;
		c:RotateAroundAxis(b:Forward(),offset.r);
		c:RotateAroundAxis(Up,offset.y);
		b.y=a.y;
		b.p=0;
		b.r=0;
		c:RotateAroundAxis(b:Right(),-offset.p);
		self.ent:SetAngles(c);
		self.ent:SetPos(pos-(self.ent:LocalToWorld(self.MAPPos)-self.ent:GetPos()));
	elseif self.type==2 then
		local ap=self.pl:GetAttachment(self.PAP);
		self.ent:SetPos(ap.Pos+ap.Ang:Forward()*self.vOffset.x+ap.Ang:Right()*self.vOffset.y+ap.Ang:Up()*self.vOffset.z);
		ap.Ang:RotateAroundAxis(ap.Ang:Up(),self.aOffset.y);
		ap.Ang:RotateAroundAxis(ap.Ang:Right(),self.aOffset.p);
		ap.Ang:RotateAroundAxis(ap.Ang:Forward(),self.aOffset.r);
		self.ent:SetAngles(ap.Ang);
	end
	
	self.ent:DrawModel();
	return true;
end

--Attachment metatable. Attachments have their metatables set to this to allow them to use the functions in af above.
local amt={};
function amt:__index(k) return af[k]; end

function MODULE:Initialize()
end

function MODULE:Cleanup()
end

--[[
Creates a model and attaches it to a player.
The given bone is expected to exist in both the player and the model being attached (for example, ValveBiped.Bip01_R_Hand exists in both players and gun models).
The model will be positioned and oriented in such a way that the two bones (one in the player and the other in the model) fuse together.
player should be a valid player.
model should be a string corresponding to a model path.
refBone should be the name of a bone in both the player's model and the given model.

True is returned if the model was created successfully using the given bone.
False is returned if:
	no valid player was given (or if something other than a player was given).
	no model was given
	no reference bone was given
	the given player's model doesn't have the given bone
	the given model didn't have the given bone
	the entity used to display the gear couldn't be created
]]--
function MODULE:ToBone(player,model,refBone)
	if !player then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; no player was given.\n"); return false end
	if !player:IsValid() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; given player was invalid.\n"); return false end
	if !player:IsPlayer() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; given player wasn't a player."); return false end
	
	if !model then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; no model name was given.\n"); return false end
	if !refBone then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; no reference bone was given.\n"); return false end
	
	local newAttach={};
	
	newAttach.pl=player;
	newAttach.type=1;
	newAttach.AP=refBone;
	newAttach.PAP=player:LookupBone(refBone);
	if !newAttach.PAP then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; given player's model ("..player:GetModel()..") does not have the given bone ("..refBone..").\n"); return false end
	
	local ent=ClientsideModel(model,RENDER_GROUP_OPAQUE_ENTITY);
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; couldn't create gear model for some reason.\n"); return false end
	ent:SetPos(Vector(0,0,0));
	ent:SetAngles(Angle(0,0,0));
	ent:SetNoDraw(true);
	
	newAttach.MAP=ent:LookupBone(refBone);
	if !newAttach.MAP then ent:Remove(); return false; end
	
	newAttach.ent=ent;
	
	setmetatable(newAttach,amt);
	return newAttach;
end


--[[
Creates a model and attaches it to a player.
The model is moved to the given attachment point on the player.
	The model will be positioned and oriented on the given attachment point:   
	     |_
	_|_
	 |
	Shifted relative to the attachment point by vOffset:
	     |_   |_
	_|_
	 |
	And then rotated relative to the attachment point's rotation by aOffset:
	     |_   /
	_|_       `
	 |
player should be a valid player.
model should be a string corresponding to a model path.
refBone should be the name of a bone in both the player's model and the given model.

True is returned if the model was created successfully using the given bone.
False is returned if:
	no valid player was given (or if something other than a player was given).
	no model was given
	no attachment point was given was given
	the given player's model doesn't have the given attachment point
	the entity used to display the gear couldn't be created
]]--
function MODULE:ToAP(player,model,attachPoint,vOffset,aOffset)
	if !player then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; no player was given.\n"); return false end
	if !player:IsValid() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; given player was invalid.\n"); return false end
	if !player:IsPlayer() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; given player wasn't a player."); return false end
	local newAttach={};
	
	newAttach.pl=player;
	newAttach.type=2;
	newAttach.vOffset=vOffset or Vector(0,0,0);
	newAttach.aOffset=aOffset or Angle(0,0,0);
	newAttach.AP=attachPoint;
	newAttach.PAP=player:LookupAttachment(attachPoint);
	if newAttach.PAP==0 then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; given player's model ("..player:GetModel()..") does not have the given attachment point ("..attachPoint..").\n"); return false end
	
	local ent=ClientsideModel(model,RENDER_GROUP_OPAQUE_ENTITY);
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; couldn't create gear model for some reason.\n"); return false end
	ent:SetPos(Vector(0,0,0));
	ent:SetAngles(Angle(0,0,0));
	ent:SetNoDraw(true);
	
	newAttach.ent=ent;
	
	setmetatable(newAttach,amt);
	return newAttach;
end