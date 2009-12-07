--[[
Itemforge Gear Attach Module
CLIENT

This implements basic functionality for adding, moving, and removing models fake-merged to bones and attachment points on players.
]]--
MODULE.Name="GearAttach";									--Our module will be stored at IF.GearAttach
MODULE.Disabled=false;										--Our module will be loaded
MODULE.Attachments={};										--All active attachments are stored here

local Up=Vector(0,0,1);

--Attachment functions table. All attachments can use functions and values declared here.
local af={};

--Updates the attachment's position and draws it
function af:Draw()
	if self.type==0 then
		return;
	elseif self.type==1 then
		local pos,ang=self.parent:GetBonePosition(self.PAP);
		self.ent:SetPos(pos								+
						ang:Forward()*self.vOffset.x	+
						ang:Right()*self.vOffset.y		+
						ang:Up()*self.vOffset.z);
		
		ang:RotateAroundAxis(ang:Forward()		,self.aOffset.r);
		ang:RotateAroundAxis(ang:Right()		,self.aOffset.p);
		ang:RotateAroundAxis(ang:Up()			,self.aOffset.y);
		
		self.ent:SetAngles(ang);
	elseif self.type==2 then
		local ap=self.parent:GetAttachment(self.PAP);
		self.ent:SetPos(ap.Pos							+
						ap.Ang:Forward()*self.vOffset.x	+
						ap.Ang:Right()*self.vOffset.y	+
						ap.Ang:Up()*self.vOffset.z);
		ap.Ang:RotateAroundAxis(ap.Ang:Forward(),self.aOffset.r);
		ap.Ang:RotateAroundAxis(ap.Ang:Right()	,self.aOffset.p);
		ap.Ang:RotateAroundAxis(ap.Ang:Up()		,self.aOffset.y);
		
		self.ent:SetAngles(ap.Ang);
	elseif self.type==3 then
		if !self.MAPPos then
			self.ent:SetPos(Vector(0,0,0));
			self.ent:SetAngles(Angle(0,0,0));
			self.MAPPos,self.MAPAng=self.ent:GetBonePosition(self.MAP);
		end
		local pos,a=self.parent:GetBonePosition(self.PAP);
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
	end
	
	if self.Hidden || self.parent==GetViewEntity() then return end
	
	if self.DrawFunc then	self.DrawFunc(self.ent);
	else					self.ent:DrawModel();
	end
	
	return true;
end

--[[
Attaches the gear to a bone on the parent entity.

bone should be the name of a bone on the parent entity (ex: for a character, "ValveBiped.Bip01_Pelvis").

True is returned if the gear is successfully attached to the given bone.
False is returned if:
	no bone was given
	the parent entity's model doesn't have the given bone
]]--
function af:ToBone(bone)
	if !bone then ErrorNoHalt("Itemforge Gear Attach: Couldn't attach gear to bone; no bone was given.\n"); return false end
	
	local index=self.parent:LookupBone(bone);
	if !index then return false end
	
	self.AP=bone;
	self.PAP=index;
	self.type=1;
	
	return true;
end

--[[
Attaches the gear to an attachment point on the parent entity.

attachPoint should be the name of an attachment point on the parent entity (ex: for a character: "eyes", for the jeep: "gun_ref", etc).

true is returned if the gear is successfully attached to the given bone
false is returned if:
	no attachment point was given
	the parent entity's model doesn't have the given attachment point
]]--
function af:ToAP(attachPoint)
	if !attachPoint then ErrorNoHalt("Itemforge Gear Attach: Couldn't attach gear to attachment point; no attachment point was given.\n"); return false end
	
	local index=self.parent:LookupAttachment(attachPoint);
	if index==0 then return false end	
	
	self.AP=attachPoint;
	self.PAP=index;
	self.type=2;
	return true;
end

--[[
Simulates a bone-merge between this gear and the parent entity.
The given bone is expected to exist in both the parent entity's model and this gear's model (for example, "ValveBiped.Bip01_R_Hand" exists in both players and some guns).
The gear will be positioned and oriented in such a way that the two bones (one in the parent entity and the other in the gear) fuse together.

refBone should be the name of a bone in both the parent's model and the given model.

true is returned if the gear is successfully attached
false is returned if:
	no reference bone was given
	the parent entity's model doesn't have the given bone
	the attachment's model doesn't have the given bone
]]--
function af:BoneMerge(refBone)
	if !refBone then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; no reference bone was given.\n"); return false end
	
	local index1=self.parent:LookupBone(refBone);
	if !index1 then return false end
	
	local index2=self.ent:LookupBone(refBone);
	if !index2 then return false end
	
	self.type=3;
	self.AP=refBone;
	self.PAP=index1;
	self.MAP=index2;
	self.MAPPos=nil;
	self.MAPAng=nil;
	
	return true;
end

--[[
Sets the draw function for this attachment. This is called right before the attachment is drawn.
fFunc should be a function(entity)
]]--
function af:SetDrawFunction(fFunc)
	self.DrawFunc=fFunc;
end

--[[
Hides the attachment.
]]--
function af:Hide()
	self.Hidden=true;
end

--[[
Shows the attachment.
Attachments are shown by default. You don't need to call this unless :Hide() has been called before.
]]--
function af:Show()
	self.Hidden=false;
end

--[[
Gets rid of the attachment.
]]--
function af:Remove()
	IF.GearAttach:Remove(self);
end

--[[
Notes on Offset/Angular Offset:

The model will be positioned and oriented on the given bone:   
     |_
_|_
 |

Shifted relative to the bone by offset:
     |_   |_
_|_
 |

And then rotated relative to the bone's rotation by angular offset:
     |_   /
_|_       `
 |
]]--

--[[
Changes the offset of gear relative to the bone/attachment point on it's parent.
NOTE: This will have no visible effect if the attachment is :BoneMerge()'d.
]]--
function af:SetOffset(vPos)
	if !vPos then ErrorNoHalt("Itemforge Gear Attach: Couldn't set offset; no offset given!\n"); return false end
	
	self.vOffset=vPos;
	return true;
end

--[[
Changes the rotation of the gear relative to the bone/attachment point on it's parent.
NOTE: This will have no visible effect if the attachment is :BoneMerge()'d.
]]--
function af:SetOffsetAngles(aAng)
	if !aAng then ErrorNoHalt("Itemforge Gear Attach: Couldn't set angular offset; no angular offset given!\n"); return false end
	
	self.aOffset=aAng;
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
Creates an attachment object with the given model, attached to the given parent entity.
parent should be a valid entity.
model should be a string corresponding to a model path.
]]--
function MODULE:Create(parent,model)
	if !parent then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; no parent entity was given.\n"); return false end
	if !parent:IsValid() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; given parent entity was invalid.\n"); return false end
	if !model then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; no model name was given.\n"); return false end
	local newAttach={};
	newAttach.parent=parent;			--Attached to this
	newAttach.type=0;					--0: None; 1: On Bone; 2: On Attachment Point; 3: Bone-Merge
	newAttach.vOffset=Vector(0,0,0);	--Offset of model relative to bone/attachment
	newAttach.aOffset=Angle(0,0,0);		--Rotation offset of model relative to bone/attachment
	newAttach.DrawFunc=nil;				--This function is called prior to drawing
	newAttach.Hidden=false;				--The model exists but is not drawn
	newAttach.AP="";					--Name of bone/attachment on parent (and model if dealing with a bone-merge)
	newAttach.PAP=0;					--Index of bone/attachment on parent
	newAttach.MAP=0;					--Index of reference bone on gear model (for bone-merge)
	newAttach.MAPPos=nil;				--Position/angle of reference bone relative to center of entity
	newAttach.MAPAng=nil;
	
	local ent=ClientsideModel(model,RENDER_GROUP_OPAQUE_ENTITY);
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Gear Attach: Couldn't create gear; couldn't create gear model for some reason.\n"); return false end
	ent:SetPos(Vector(0,0,0));
	ent:SetAngles(Angle(0,0,0));
	ent:SetNoDraw(true);
	
	newAttach.ent=ent;
	newAttach.id=table.insert(self.Attachments,newAttach);
	setmetatable(newAttach,amt);
	
	local effectdata=EffectData();
	effectdata:SetEntity(parent);
	effectdata:SetScale(newAttach.id)
	util.Effect("Gear",effectdata);
	
	return newAttach;
end

function MODULE:Remove(attach)
	if !attach || !attach.id then return false end
	self.Attachments[attach.id]=nil;
	return true;
end