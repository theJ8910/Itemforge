--[[
item_metalkit
SHARED

This item reinforces other items - it increases their max HP.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Metal Reinforcement Kit";
ITEM.Description		= "Scrap metal, bolts, rivets, and other miscellanious materials.\nThis kit would be useful for reinforcing wooden objects.";
ITEM.Weight				= 15000; --15 kg
ITEM.Size				= 41;
ITEM.WorldModel			= "models/props_debris/metal_panelchunk01d.mdl";

--Metal Kit
ITEM.GlossMat			= "models/props_canal/metalwall005b";			--When applied to another item, the item's material is changed to this.
ITEM.ReinforceBy		= 200;											--When applied to another item, the item's health and max health are increased by this much.
ITEM.Sounds				= {
	Sound( "physics/metal/metal_box_impact_bullet1.wav" ),
	Sound( "physics/metal/metal_box_impact_bullet2.wav" ),
	Sound( "physics/metal/metal_box_impact_bullet3.wav" ),
	Sound( "physics/metal/metal_box_strain1.wav" ),
	Sound( "physics/metal/metal_box_strain2.wav" ),
	Sound( "physics/metal/metal_box_strain3.wav" ),
	Sound( "physics/metal/metal_box_strain4.wav" ),
	Sound( "physics/metal/metal_canister_impact_hard3.wav" )
}

ITEM.SWEPHoldType		= "normal";

if SERVER then

ITEM.Applying = false;

else

ITEM.WorldModelNudge	= Vector( 0, 0, 8 );

end

--[[
* SHARED

Runs when a player wants to apply the metal kit to an item.

Serverside, tries to start applying the metal kit, or if this is not possible makes the player complain.
Clientside, asks the server to apply the metal kit instead.
]]--
function ITEM:PlayerApplyTo( pl, otherItem )
	if !self:Event( "CanPlayerInteract", false, pl ) then return false end
	
	if SERVER then	if !self:StartApplying( otherItem, pl ) then IF.Vox:PlayRandomFailure( pl ) end
	else			self:SendNWCommand( "PlayerApplyTo", otherItem );
	end
end

if SERVER then




--[[
* SERVER
* Event

Nothing happens when you use it
]]--
function ITEM:OnUse( pl )
	return true;
end

--[[
* SERVER

This starts applying the metal kit to the item.
Nothing actually happens during this stage; you hear it being applied, and 1 second later it's actually applied.
]]--
function ITEM:StartApplying( otherItem, pl )
	--[[
	Don't apply if we're already applying to something.
	If the item we're applying to is invincible, forget about it.
	Also, don't apply if we're spreading out the reinforcement over too many items (in other words, 5 or less reinforcement per item really isn't much of a reinforcement, is it?)
	]]--
	if self.Applying == true || self.ReinforceBy / otherItem:GetAmount() <= 5 then return false end
	
	self.Applying = true;
	
	self:EmitSound( self.Sounds[math.random( 4, 7 )] );
	
	self:SimpleTimer( 0.2, self.EmitSound, self.Sounds[math.random( 1, 3 )] );
	self:SimpleTimer( 0.4, self.EmitSound, self.Sounds[math.random( 1, 3 )] );
	self:SimpleTimer( 0.6, self.EmitSound, self.Sounds[math.random( 1, 3 )] );
	self:SimpleTimer( 1.0, self.FinishApplying, otherItem, pl );
	return true;
end

--[[
* SERVER

This finishes the metal kit's attachment to the item.
]]--
function ITEM:FinishApplying( otherItem, pl )
	if !IF.Util:IsItem( otherItem ) then return false end

	local iNewHealth = otherItem:GetMaxHealth() + self.ReinforceBy / otherItem:GetAmount();
	
	otherItem:EmitSound( self.Sounds[8] );
	otherItem:SetMaxHealth( iNewHealth );
	otherItem:SetHealth( iNewHealth );
	otherItem:SetOverrideMaterial( self.GlossMat );
	otherItem:SetGibEffect( "metal" );
	IF.Vox:PlayRandomSuccess( pl );
	self:Remove();
end

IF.Items:CreateNWCommand( ITEM, "PlayerApplyTo", function( self, ... ) self:PlayerApplyTo( ... ) end, { "item" } );




else




--[[
* CLIENT
* Event

When the player drag-drops the metal-kit to another item it reinforces it
]]--
function ITEM:OnDragDropToItem( item )
	self:PlayerApplyTo( LocalPlayer(), item );
end

IF.Items:CreateNWCommand( ITEM, "PlayerApplyTo", nil, { "item" } );




end