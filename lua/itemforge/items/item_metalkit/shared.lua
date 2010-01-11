--[[
item_metalkit
SHARED

This item reinforces other items - it increases their max HP.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Metal Reinforcement Kit";
ITEM.Description="Scrap metal, bolts, rivets, and other miscellanious materials.\nThis kit would be useful for reinforcing wooden objects.";
ITEM.Weight=15000;
ITEM.Size=41;
ITEM.WorldModel="models/props_debris/metal_panelchunk01d.mdl";

--Metal Kit
ITEM.GlossMat="models/props_canal/metalwall005b";				--When applied to another item, the item's material is changed to this.
ITEM.ReinforceBy=200;											--When applied to another item, the item's health and max health are increased by this much.
ITEM.Sounds={
	Sound("physics/metal/metal_box_impact_bullet1.wav"),
	Sound("physics/metal/metal_box_impact_bullet2.wav"),
	Sound("physics/metal/metal_box_impact_bullet3.wav"),
	Sound("physics/metal/metal_box_strain1.wav"),
	Sound("physics/metal/metal_box_strain2.wav"),
	Sound("physics/metal/metal_box_strain3.wav"),
	Sound("physics/metal/metal_box_strain4.wav"),
	Sound("physics/metal/metal_canister_impact_hard3.wav")
}
if SERVER then

ITEM.HoldType="normal";

else

ITEM.WorldModelNudge=Vector(0,0,8);

end

function ITEM:ApplyTo(pl,otherItem)
	if !self:Event("CanPlayerInteract",false,pl) then return false end
	
	if SERVER then
		if self:StartApplying(otherItem) then IF.Vox:PlayRandomSuccess(pl);
		else								  IF.Vox:PlayRandomFailure(pl); end
	else
		self:SendNWCommand("ApplyTo",otherItem);
	end
end

if SERVER then




ITEM.Applying=false;

function ITEM:OnUse(pl)
	return true;
end

function ITEM:StartApplying(otherItem)
	--Don't apply if we're already applying to something.
	--If the item we're applying to is invincible, forget about it.
	--Also, don't apply if we're spreading out the reinforcement over too many items (in other words, 5 or less reinforcement per item really isn't much of a reinforcement, is it?)
	if self.Applying==true || self.ReinforceBy/otherItem:GetAmount()<=5 then return false end
	
	self.Applying=true;
	
	self:EmitSound(self.Sounds[math.random(4,7)]);
	
	self:SimpleTimer(0.2,self.EmitSound,self.Sounds[math.random(1,3)]);
	self:SimpleTimer(0.4,self.EmitSound,self.Sounds[math.random(1,3)]);
	self:SimpleTimer(0.6,self.EmitSound,self.Sounds[math.random(1,3)]);
	self:SimpleTimer(1.0,self.FinishApplying,otherItem);
	return true;
end

function ITEM:FinishApplying(otherItem)
	local newHealth=otherItem:GetMaxHealth()+self.ReinforceBy/otherItem:GetAmount();
	
	otherItem:EmitSound(self.Sounds[8]);
	otherItem:SetMaxHealth(newHealth);
	otherItem:SetHealth(newHealth);
	otherItem:SetOverrideMaterial(self.GlossMat);
	self:Remove();
end

IF.Items:CreateNWCommand(ITEM,"ApplyTo",function(self,...) self:ApplyTo(...) end,{"item"});




else




function ITEM:OnDragDropToItem(item)
	self:ApplyTo(LocalPlayer(),item);
end

IF.Items:CreateNWCommand(ITEM,"ApplyTo",nil,{"item"});




end