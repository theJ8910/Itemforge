--[[
events_server
SERVER

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/events_server.lua, so this item's type is "base_item")

This specific file deals with events that are present on the server.
]]--

--This table maps gib types to their identifying numbers. 
local GibHash = {
	["metal"] = 1,
	["wood"]  = 2,
	["glass"] = 3
}

--[[
ENTITY SPECIFIC EVENTS
]]--

--[[
* SERVER
* Event

Whenever an item is dropped into the world, an entity is created to represent it.
This function will be run to initialize the entity before it's spawned.

Scripters can override this to init the entity however they like here.
Mine is pretty general, it sets the model to whatever the scripter has provided, inits physics, sets it to simple use (you press E once and it uses it once) and spawns it.

eEntity is a newly created itemforge item entity.
	The entity isn't spawned yet. Don't call eEntity:Spawn(); it's done automatically after this function calls.
]]--
function ITEM:OnEntityInit( eEntity )
	--We'll grab and set the name and world model of the entity first
	eEntity.PrintName = self:Event( "GetName", "Itemforge Item" );
	eEntity:SetModel( self:GetWorldModel() );
	
	--Next we init physics (and wake the object so it starts moving immediately)
	eEntity:PhysicsInit( SOLID_VPHYSICS );
	local phys = eEntity:GetPhysicsObject();
	if phys:IsValid() then
		phys:Wake();
	end
	
	--We'll do some other stuff like set it to simple use here
	eEntity:SetUseType( SIMPLE_USE );
	
	return true;
end

--[[
* SERVER
* Event

While the item is in the world as an entity, if it's damaged physically (such as being burned by fire or hit with a crowbar) then this event will be triggered.
By default, whenever an item's entity is damaged, the item is damaged. Then the item's entity is knocked around a bit when we do TakePhysicsDamage.

eEntity should be the same thing as self:GetEntity(). It's the entity the item is using while it's in the world.
dmgInfo is information passed to the entity's OnTakeDamage function.
]]--
function ITEM:OnEntTakeDamage( eEntity, dmgInfo )
	self:Hurt( dmgInfo:GetDamage(), dmgInfo:GetAttacker() );
	eEntity:TakePhysicsDamage( dmgInfo );
end

--[[
* SERVER
* Event

While the item is in the world, if (one of) it's physics objects hits another physics object, this event is called.

eEntity should be the entity the item is using while it's in the world (the same as self:GetEntity()).
CollisionData is information about the collision passed on from the entity's event.
HitPhysObj is the physics object belonging to this entity which collided.
]]--
function ITEM:OnPhysicsCollide( eEntity, CollisionData, HitPhysObj )
	
end

--[[
* SERVER
* Event

While an item is in the world, if it bumps into another entity this function is called.

eEntity should be the entity the item is using while it's in the world (the same as self:GetEntity()).
eActivator is the entity that has been bumped into by our item's entity.
touchItem will usually be nil, but if it isn't, that means this item has touched another item in the world.
]]--
function ITEM:OnStartTouch( eEntity, eActivator, touchItem )
	
end

--[[
* SERVER
* Event

While an item is in the world, this function is called while our item is touching something.
It will run this function every frame until the item comes to rest on the entity it's touching, or loses contact with it.

eEntity should be the entity the item is using while it's in the world (the same as self:GetEntity()).
eActivator is the entity that is bumping into our entity.
touchItem will usually be nil, but if it isn't, that means this item has touched another item in the world.
]]--
function ITEM:OnTouch( eEntity, eActivator, touchItem )

end

--[[
* SERVER
* Event

While an item is in the world, this function is called when our item loses contact with something it was touching.

eEntity should be the entity the item is using while it's in the world (the same as self:GetEntity()).
eActivator is the entity that had been bumped into by our item's entity but now no longer is being touched.
touchItem will usually be nil, but if it isn't, that means this item has touched another item in the world.
]]--
function ITEM:OnEndTouch( eEntity, eActivator, touchItem )

end

--[[
* SERVER
* Event

Can a player pick up this item with the gravity gun?
This event gives the item a chance to decide.

NOTE:
This event should only determine whether or not the pickup is allowed, not actually respond to it.

pl is the player who is trying to pick up the item with the gravity gun.
eEntity is the item's world entity (should be the same as self:GetEntity())

Return true to allow the pickup, or false to forbid it.
]]--
function ITEM:CanGravGunPickup( pl, eEntity )
	return true;
end

--[[
* SERVER
* Event

Runs right after the player picks up this item with the gravity gun.

If the CanGravGunPickup event denies the pickup, this event does not run.

pl is the player who picked up the item with the gravity gun.
eEntity is the item's world entity (should be the same as self:GetEntity())
]]--
function ITEM:OnGravGunPickup( pl, eEntity )
	
end

--[[
* SERVER
* Event

Runs if the player was holding this item with the gravity gun, then loses hold of the item somehow (whether that's by dropping it or launching it).

NOTE: You can check the player's IN_ATTACK key to see if he launched it, rather than dropping it.

pl is the player who dropped the item with the gravity gun.
eEntity is the item's world entity (should be the same as self:GetEntity())
]]--
function ITEM:OnGravGunDrop( pl, eEntity)
	
end

--[[
* SERVER
* Event

Can a player freeze this item with the physgun?
This event gives the item a chance to decide.

NOTE:
This event should only determine whether or not the freeze is allowed, not actually respond to it.

pl is the player who is trying to freeze the item with the physgun.
eEntity is the item's world entity (should be the same as self:GetEntity())
phys is the specific physics object being frozen.

Return true to allow the freeze, or false to forbid it.
]]--
function ITEM:CanPhysgunFreeze( pl, eEntity, phys )
	return true;
end

--[[
* SERVER
* Event

Runs right after the player freezes this item with the physgun.

If the CanPhysgunFreeze event denies the freeze, this event does not run.

pl is the player who froze the item with the physgun.
eEntity is the item's world entity (should be the same as self:GetEntity())
phys is the specific physics object that was frozen.
]]--
function ITEM:OnPhysgunFreeze( pl, eEntity, phys )
	
end

--[[
* SERVER
* Event

Can a player unfreeze this item with the physgun?
This event gives the item a chance to decide.

NOTE:
This event should only determine whether or not the unfreeze is allowed, not actually respond to it.

pl is the player who is trying to unfreeze the item with the physgun.
eEntity is the item's world entity (should be the same as self:GetEntity())
phys is the specific physics object being unfrozen.

Return true to allow the unfreeze, or false to forbid it.
]]--
function ITEM:CanPhysgunUnfreeze( pl, eEntity, phys )
	return true;
end

--[[
* SERVER
* Event

Runs right after the player unfreezes this item with the physgun.

If the CanPhysgunUnfreeze event denies the freeze, this event does not run.

pl is the player who froze the item with the physgun.
eEntity is the item's world entity (should be the same as self:GetEntity())
phys is the specific physics object that was unfrozen.
]]--
function ITEM:OnPhysgunUnfreeze( pl, eEntity, phys )
	
end

--[[
* SERVER
* Event
* WIRE

This event can be used to give your item a Wire debug name.
When this item enters the world, this event will be called to give the item's entity a Wire debug name (for Wiremod, if it's installed).
By default, this grabs the name of the item (with GetName()). If this fails for some reason, it defaults to "Itemforge Item".
Return a string here to decide what the Wire debug name is.
]]--
function ITEM:GetWireDebugName()
	return self:Event( "GetName", "Itemforge Item" );
end

--[[
* SERVER
* Event
* WIRE

This event can be used to give your items Wire inputs. This event will never be called if Wiremod is not installed.
When this item enters the world, this event will be called to give the item's entity Wire inputs.
Wire entities, like a Wire button, can trigger these inputs and cause things to happen on your item.
For example, if you had an input "On", and you hooked a button up to it, then pressed the button, it would trigger the "On" input on your item.
This function just tells Wiremod what inputs the item has, not what the inputs do. To decide what the inputs do, see ITEM:OnWireInput() below.

entity is this item's world entity ( the same as self:GetEntity() ).
If your item has no inputs:						return nil
If you want to give your item inputs inputs:	return Wire_CreateInputs( entity, { "Your", "Inputs", "Here" } )
]]--
function ITEM:GetWireInputs( entity )
	--return Wire_CreateInputs( entity, { "Example Input", "Another Input", "Yet Another Input" } );
	return nil;
end

--[[
* SERVER
* Event
* WIRE

This event can be used to give your items Wire outputs. This event will never be called if Wiremod is not installed.
When this item enters the world, this event will be called to give the item's entity Wire outputs.
Wire entities, such as an air compressor, can be controlled by outputs from other wire entities (like buttons or our items)
For example, if you had an output "Energy" (lets pretend it's a battery), and you hooked it up to a monitor, then the monitor would display how much energy the battery has!
This function just tells Wiremod what outputs the item has. Whenever you want to trigger an output, you need to use self:WireOutput("Name",data) (ex: self:WireOutput("Energy",100))

entity is this item's world entity (the same as self:GetEntity()).
If your item has no outputs:					return nil
If you want to give your item outputs:			return Wire_CreateOutputs( entity, { "Your", "Outputs", "Here" } )
]]--
function ITEM:GetWireOutputs( entity )
	--return Wire_CreateOutputs( entity, { "Example Output", "Another Output", "Yet Another Output" } );
	return nil;
end

--[[
* SERVER
* Event
* WIRE

This event runs when a wire input is triggered. This event will never be called if Wiremod is not installed.
While your item is in the world, if a wire input (which you probably specified in GetWireInputs above) is triggered on your item, you can decide what happens here.
For example:
	Lets say your item has an input, "On".
	Your item's "On" input is hooked up to a button.
	Someone comes by and presses the button, and it outputs 1.
	This event runs; entity is, of course, this item's entity, inputName is "On", and value is 1.
	
entity will always be this item's entity (the same as self:GetEntity())
inputName will be the name of the input triggered. It should be one of the inputs you specified in GetWireInputs above.
value will be the value of whatever was outputted here. This is usually a number, BUT it could possibly not be a number, keep this in mind.
]]--
function ITEM:OnWireInput( entity, inputName, value )
	--[[
	--An example for you
	if inputName == "On" then
		if value == 0 then
			--Turn off if value is 0
		else
			--Turn on if value is anything else
		end
	end
	]]--
end




--[[
SWEP SPECIFIC EVENTS
]]--




--[[
* SERVER
* Event

This event runs when an NPC weilds this item as a weapon. This function should tell the NPC
how he's allowed to use the weapon.

You can return 0 to indicate no capabilities or return a combination of valid enums
You can combine enums by using the bitwise OR operator ( the | character ).
Example: ( CAP_WEAPON_RANGE_ATTACK1 | CAP_INNATE_RANGE_ATTACK1 )
]]--
function ITEM:GetSWEPCapabilities()
	return 0;
end




--[[
ENTITY/SWEP SHARED EVENTS
]]--




--[[
* SERVER
* Event

If a key-value is set on the item's entity (either while in the world as an entity or while held as an SWEP), it will trigger this event.
You get to decide what happens when a keyvalue is set using this function.

bSWEP will be true if the keyvalue was set on the item while being held as an SWEP. It will be false if it happened while in the world, as an entity.
eEntity is the entity the keyvalue was set on. It will either be the SWEP entity (SWEP.Weapon) or the SENT entity (ENT.Entity).
strKey is a string. It describes _what_ should be set. It could be something like "health" or "color".
strValue is also a string. It describes what 'key' should be set to. For example, "100",   or "red".
]]--
function ITEM:OnKeyValue( bSWEP, eEntity, strKey, strValue )
	--DEBUG
	Msg( "Itemforge Item: Keyvalue "..strKey.."/"..strValue.." set on "..tostring( eEntity ).." ("..tostring( self )..")\n" );
	
	--Whenever the color tool is used, the renderfx key is set to 0
	--So we take this opportunity to set the item's color
	if strKey == "renderfx" then
		--Entity:GetColor returns four values instead of a color structure... so we use them as the four arguments of a Color() to make a Color structure.
		self:SetColor( Color( eEntity:GetColor() ) );
	end
end

--[[
* SERVER
* Event

If an input is received on the item's entity (either while in the world as an entity or while held as an SWEP), it will trigger this event.
With this event, you get to decide what happens when an entity uses an input on this item's entity.

bSWEP will be true if the input was received on the item while being held as an SWEP. It will be false if it happened while in the world, as an entity.
eEntity is the entity the input was received on. It will either be the SWEP entity (SWEP.Weapon) or the SENT entity (ENT.Entity).
sInput is a string, the name of the input received. This describes what kind of action has been requested, such as "SetRelationship".
eActivator is the entity directly responsible for triggering this input - ex: Entity A sends an input to Entity B, which sends an input to our entity. Entity B is the activator. Check to see if activator is non-nil and valid.
eCaller is the entity indirectly responsible for triggering this input -  ex: Entity A sends an input to Entity B, which sends an input to our entity. Entity A is the caller. Check to see if caller is non-nil and valid.
data is additional data that accompanies the input. It's probably in string format but I haven't tested.

Return true to OVERRIDE the input (meaning, whatever would normally happen to the entity when this input is received gets cancelled)
Return false to ALLOW the input (meaning, whatever would normally happen to the entity, does)
]]--
function ITEM:OnInput( bSWEP, eEntity, strInput, eActivator, eCaller, data )

	--DEBUG
	Msg( "Itemforge Item: \""..tostring( strInput ).."\" called on "..tostring( eEntity ).." ("..tostring( self ).."). Activator/Caller: "..tostring( eActivator ).."/"..tostring( eCaller )..". Additional Data: "..tostring( data ).."\n" );
	return false;

end




--[[
ITEM EVENTS
]]--




--[[
* SERVER
* Event

This function runs when an item in the stack is broken (health reaches 0).
This runs once for each item in the stack. Lets say you have a stack of 10 bottles. Each time a bottle breaks, this function runs.

iHowMany is how many items were broke (in the case of a stack of items, several items can possibly be broken with a single, powerful hit)
bLastBroke will be true if the last item in the stack was broken (and therefore, the whole item stack is about to be removed)
who is the entity or player who broke the items.
]]--
function ITEM:OnBreak( iHowMany, bLastBroke, who )
	if !bLastBroke then return false end
	
	local ent = self:GetEntity();
	if !ent then return false end
	
	--[[
	What kind of gibs does this item leave behind if it's destroyed while in the world?
		Can be "none" for no gibs,
		"auto" to use the model's default gibs,
		"metal" to break into metal pieces,
		"wood" to break into wood pieces,
		"glass" to break into glass shards.
	]]--

	if self.GibEffect == "auto" then

		local breakEnt = ents.Create( "prop_physics" );
		breakEnt:SetModel( ent:GetModel() );
		breakEnt:SetPos( ent:GetPos() );
		breakEnt:SetAngles( ent:GetAngles() );
		breakEnt:SetNotSolid( true );
		
		local phys1 = ent:GetPhysicsObject();
		local phys2 = breakEnt:GetPhysicsObject();
		
		if phys1 && phys1:IsValid() && phys2 && phys2:IsValid() then
			phys2:SetVelocity( phys1:GetVelocity() );
			phys2:AddAngleVelocity( phys1:GetAngleVelocity() );
		end

		breakEnt:Spawn();
		breakEnt:Fire( "break", "", 0 );

	elseif GibHash[self.GibEffect] then

		local data = EffectData();
		data:SetOrigin( ent:LocalToWorld( ent:OBBCenter() ) );
		data:SetStart( ent:OBBMaxs() - ent:OBBCenter() );
		data:SetAngle( ent:GetAngles() );
		
		local phys1 = ent:GetPhysicsObject();

		if phys1 && phys1:IsValid() then
			local v = phys1:GetVelocity();
			data:SetNormal( v:GetNormal() );
			data:SetScale( v:Length() );
			data:SetRadius( phys1:GetVolume() );
		end
		
		data:SetAttachment( GibHash[self.GibEffect] );
		util.Effect( "BasicGibs", data, true, true );

	end
end

--[[
* SERVER
* Event

This event is called when a full update of this item is being sent to a player.
pl may be nil - if it is, it's sending the update to everyone.
]]--
function ITEM:OnSendFullUpdate( pl )
	
end

--[[
* SERVER
* Event

Before items are combined to create something, this function is run. You can return false to stop the combination from happening. Note: The combination has to work (ex: combining a branch and a stone). Non working combinations (ex: a bottle and a vine) will not trigger this.
The order this goes in is: (Are there any combinations for these items?) > (Have necessary # of ingredients?) > (Does the combination okay it?) > (does each item in the combination okay it?)
So, this function is called last. All of the items in the combination must return true for it to work.
Itemset is a table of all the items (including this item)
TODO Item combinations module
]]--
function ITEM:OnCombination( itemset, combination )
	return true;
end