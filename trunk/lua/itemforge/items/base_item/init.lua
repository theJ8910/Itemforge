--[[
base_item
SERVER

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/init.lua, so this item's type is "base_item")
]]--
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("health.lua");
AddCSLuaFile("stacks.lua");
AddCSLuaFile("weight.lua");
AddCSLuaFile("nwvars.lua");
AddCSLuaFile("timers.lua");
AddCSLuaFile("sounds.lua");
AddCSLuaFile("events_shared.lua");
AddCSLuaFile("events_client.lua");

include("shared.lua");
include("events_server.lua");

ITEM.ThinkRate=0;									--Run think serverside every # of seconds set here. If this is 0 it runs every frame serverside.
ITEM.GibEffect="auto";								--What kind of gibs does this item leave behind if it's destroyed while in the world? Can be "none" for no gibs, "auto" to use the model's default gibs, "metal" to break into metal pieces, or "wood" to break into wood pieces.

--Don't modify/override these. They're either set automatically or don't need to be changed.

--[[
* SERVER
* Protected

This doesn't actually set the NetOwner, but it will publicize or privitize the item.
lastOwner should be the player who was NetOwner of this item previously. This can be a player, or nil. Doing item:GetNetOwner() or getting the NetOwner of the old container should suffice in most cases.
newOwner should be the player who now owns this item. This can be a player, or nil. The NetOwner of an inventory the item is going in, or nil should work in most cases.
]]--
function ITEM:SetOwner(lastOwner,newOwner)
	if newOwner!=nil then
		if lastOwner==nil then
			IF.Items:RemoveClientsideOnAllBut(self:GetID(),newOwner);
		
		elseif lastOwner!=newOwner then
			IF.Items:RemoveClientside(self:GetID(),lastOwner);
			IF.Items:SendFullUpdate(self:GetID(),newOwner);
			
			for _,i in pairs(self.Inventories) do
				if i.Inv:CanSendInventoryData(newOwner) then i.Inv:ConnectItem(self,newOwner); end
			end
		end
	
	elseif lastOwner!=nil then
		for k,v in pairs(player.GetAll()) do
			if v!=lastOwner then
				IF.Items:SendFullUpdate(self:GetID(),v);
				for _,i in pairs(self.Inventories) do
					if i.Inv:CanSendInventoryData(v) then i.Inv:ConnectItem(self,v); end
				end
			end
		end
	end
end

--[[
* SERVER
* Protected

This function returns true if this item can send information about itself to a given player.
It will return true in two case:
	This item's NetOwner is nil (this item is public)
	This item's NetOwner is the same as the given player (this is a private item "owned" by this player)
]]--
function ITEM:CanSendItemData(pl)
	local owner=self:GetOwner();
	if owner==nil or owner==pl then return true end
	return false;
end
IF.Items:ProtectKey("CanSendItemData");

--[[
* SERVER
* Protected

Run this function to use the item.
It will trigger the OnUse event in the item.
This function will only be run serverside if the item is used while on the ground (with the "e" key).
The function will be run clientside and then serverside in most other cases. The server should have the final say on if something can be used or not though.
False is returned if the item is unable to be used for any reason.

TODO: Possibly have the item used by something other than a player
]]--
function ITEM:Use(pl)
	if !pl || !pl:IsValid() || !pl:IsPlayer() || !self:Event("CanPlayerInteract",false,pl) then return false end
	
	if !self:Event("OnUse",true,pl) then
		pl:PrintMessage(HUD_PRINTTALK,"I can't use this!");
		IF.Vox:PlayRandomFailure(pl);
		return false;
	end
	
	return true;
end
IF.Items:ProtectKey("Use");

--[[
* SERVER
* Protected

Protected start touch event.
World Merge attempts are triggered here.
After an _unsuccessful_ world merge attempt, this calls the overridable OnStartTouch event.
]]--
function ITEM:OnStartTouchSafe(entity,activator,touchItem)
	--[[
	If this item touched an item of the same type and both items' events approve a world merge
	then we'll merge the two items here. We can only merge the whole stack or nothing (otherwise we'd constantly be swapping items between piles back and forth).
	If it works, we stop here. Otherwise, we call the OnStartTouch event.
	]]--
	if touchItem && self:GetType()==touchItem:GetType() && self:Event("CanWorldMerge",false,touchItem) && touchItem:Event("CanWorldMerge",false,self) && self:Merge(touchItem,false) then
		return;
	end
	
	--If a merger isn't possible we pass the touch onto the item's OnStartTouch and let it handle it.
	self:Event("OnStartTouch",nil,entity,activator,touchItem);
end
IF.Items:ProtectKey("OnStartTouchSafe");

--[[
* SERVER
* Protected

Changes the item's world model.
False is returned if this cannot be done for some reason. True is returned if the model was changed.
]]--
function ITEM:SetWorldModel(sModel)
	if !sModel then return self:Error("Couldn't change world model. No model was given.\n") end
	
	local sOldModel=self:GetWorldModel();
	if sModel==sOldModel then return true end
	
	self:SetNWString("WorldModel",sModel);
	
	--If we're in the world when the model changes...
	if self:InWorld() then
		local ent=self:GetEntity();
		local pos=ent:GetPos();
		local ang=ent:GetAngles();
		
		--We must respawn the entity. This means taking the item out of the world and returning it to where it was. In the case of a failure, false is returned and the world model is reset.
		if !self:ToVoid() || !self:ToWorld(pos,ang) then self:SetNWString("WorldModel",sOldModel); return false end
	end
	
	return true;
end

--[[
* SERVER
* Protected

Changes this item's view model.
TODO actually change visible viewmodel.
]]--
function ITEM:SetViewModel(sModel)
	if !sModel then return self:Error("Couldn't change view model. No model was given.\n") end
	self:SetNWString("ViewModel",sModel);
	
	return true;
end
IF.Items:ProtectKey("SetViewModel");

--[[
* SERVER
* Protected

Sends all of the necessary item data to a player. Triggers "OnSendFullUpdate" event.
]]--
function ITEM:SendFullUpdate(pl)
	
	--Send networked vars. We'll only send networked vars that have changed (NWVars that have been set to something other than the default value)
	if self.NWVars then
		for k,v in pairs(self.NWVars) do
			--This shouldn't happen, but just in case.
			if !self.NWVarsByName[k] then self:Error("Couldn't send networked var \""..k.."\" via full update. This networked var has not been defined in the itemtype with IF.Items:CreateNWVar. This shouldn't be happening.\n"); end
			
			if !self.NWVarsByName[k].HoldFromUpdate then self:SendNWVar(k,pl); end
		end
	end
	
	local container,cslot=self:GetContainer();
	if container then self:ToInventory(container,cslot,pl,true); end
	
	self:Event("OnSendFullUpdate",nil,pl);
end
IF.Items:ProtectKey("SendFullUpdate");

--[[
* SERVER
* Protected

Runs every time the server ticks.
]]--
function ITEM:Tick()
	if !self.NWVars then return false end
	
	--Send predicted network vars.
	for k,v in pairs(self.NWVars) do
		--This shouldn't happen, but just in case.
		if !self.NWVarsByName[k] then return self:Error("Couldn't send networked var \""..k.."\" via tick. This networked var has not been defined in the itemtype with IF.Items:CreateNWVar. This shouldn't be happening.\n") end
		
		if self.NWVarsByName[k].Predicted then
			--Create the "Last Tick" table if it hasn't been created yet
			if !self.NWVarsLastTick then self.NWVarsLastTick={}; end
			
			--Only send networked vars that have changed since the last tick
			if self.NWVars[k]!=self.NWVarsLastTick[k] then
				self.NWVarsLastTick[k]=self.NWVars[k];
				self:SendNWVar(k);
			end
		end
	end
	
	self:Event("OnTick");
end
IF.Items:ProtectKey("Tick");

--[[
* SERVER
* Protected

Triggers a Wire output on this item. This will not work if Wiremod is not installed.
Whenever a wire output is triggered, it will send the given value to anything that happened to be wired to that output.

outputName is the name of the output to trigger (ex: "Energy", "DetectedPlayer", etc)
value is what value you want to output.
	Most wire inputs take numbers, so I recommend using a number for value.
	An on/off type output usually uses 0 for off and 1 for on.
	Value can be any kind of data you want - bools, tables, numbers, vectors, angles, whatever. Just keep in mind that it has to be understood by the other side.

Returns false if Wiremod v843 or better is not installed or if the item is not in the world. Returns true if the Wire output was triggered successfully.
WIRE
]]--
function ITEM:WireOutput(outputName,value)
	--This only works if we are in the world
	local entity=self:GetEntity();
	if !entity then return false end
	
	--This only works if we have wire
	if !entity.IsWire then return false end

	Wire_TriggerOutput(entity,outputName,value)
	return true;
end
IF.Items:ProtectKey("WireOutput");

--[[
* SERVER
* Protected

Sends a networked command by name with the supplied arguments
Serverside, this sends usermessages.
pl can be a player, a recipient filter, or 'nil' to send to all players (clients). If nil is given for player, and the item is in a private inventory, then the command is sent to that player only. 
]]--
function ITEM:SendNWCommand(sName,pl,...)
	local command=self.NWCommandsByName[sName];
	if command==nil			then return self:Error("Couldn't send command \""..sName.."\", there is no NWCommand by this name!\n") end
	if command.Hook!=nil	then return self:Error("Command \""..command.Name.."\" can't be sent serverside. It has a hook, meaning this command is recieved serverside, not sent.\n") end
	
	if pl!=nil then
		if !pl:IsValid()	then return self:Error("Couldn't send networked command - The player to send \""..command.Name.."\" to isn't valid!\n"); end
		if !pl:IsPlayer()	then return self:Error("Couldn't send networked command - The player to send \""..command.Name.."\" to isn't a player!\n"); end
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:SendNWCommand(sName,v,unpack(arg)) then allSuccess=false end
		end
		return allSuccess;
	end
	
	IF.Items:IFIStart(pl or self:GetOwner(),IFI_MSG_SV2CLCOMMAND,self:GetID());
	IF.Items:IFIChar(self.NWCommandsByName[sName].ID-128);
	
	--If our command sends data, then we need to send the appropriate type of data.
	for i=1,table.maxn(command.Datatypes) do
		local v=command.Datatypes[i];
		
		if v==1 then
			IF.Items:IFILong(math.floor(arg[i] or 0));
		elseif v==2 then
			IF.Items:IFIChar(math.floor(arg[i] or 0));
		elseif v==3 then
			IF.Items:IFIShort(math.floor(arg[i] or 0));
		elseif v==4 then
			IF.Items:IFIFloat(arg[i] or 0);
		elseif v==5 then
			IF.Items:IFIBool(arg[i] or false);
		elseif v==6 then
			IF.Items:IFIString(arg[i] or "");
		elseif v==7 then
			IF.Items:IFIEntity(arg[i]);
		elseif v==8 then
			IF.Items:IFIVector(arg[i] or Vector(0,0,0));
		elseif v==9 then
			IF.Items:IFIAngle(arg[i] or Angle(0,0,0));
		elseif v==10||v==11 then
			if arg[i]!=nil && arg[i]:IsValid() then
				IF.Items:IFIShort(arg[i]:GetID()-32768);
			else
				IF.Items:IFIShort(0);
			end
		elseif v==12 then
			if arg[i]!=nil then
				IF.Items:IFIChar(math.floor(arg[i])-128);
			else
				IF.Items:IFIChar(0);
			end
		elseif v==13 then
			if arg[i]!=nil then
				IF.Items:IFILong(math.floor(arg[i])-2147483648);
			else
				IF.Items:IFILong(0);
			end
		elseif v==14 then
			if arg[i]!=nil then
				IF.Items:IFIShort(math.floor(arg[i])-32768);
			else
				IF.Items:IFIShort(0);
			end
		elseif v==0 then
			IF.Items:IFIChar(0);
		end
	end
	
	IF.Items:IFIEnd();
end
IF.Items:ProtectKey("SendNWCommand");

local NIL="%%00";		--If a command isn't given, this is substituted. It means we received nil (nothing).

--[[
* SERVER
* Protected

This function is called automatically, whenever a networked command from a client is received. fromPl will always be a player.
commandid is the ID of the command recieved from the server
args will be a table of arguments (should be converted to the correct datatype as specified in CreateNWCommand).
There's no need to override this, we'll call the hook the command is associated if there is one.
]]--
function ITEM:ReceiveNWCommand(fromPl,commandid,args)
	local command=self.NWCommandsByID[commandid];
	
	if command==nil			then return self:Error("Couldn't find a NWCommand with ID "..commandid..". Make sure commands are created in the same order BOTH serverside and clientside. \n") end
	if command.Hook==nil	then return self:Error("Command \""..command.Name.."\" was received, but there is no Hook to run!\n") end
	
	--If our command sends data, then we need to receive the appropriate type of data.
	--We'll pass this onto the hook function.
	local hookArgs={};
	
	for i=1,table.maxn(command.Datatypes) do
		local v=command.Datatypes[i];
		local currentArg=args[i];
		if currentArg==NIL then
			hookArgs[i]=nil;
		elseif v==1||v==2||v==3||v==4||v==12||v==13||v==14 then
			hookArgs[i]=tonumber(currentArg);
		elseif v==5 then
			if currentArg=="t" then
				hookArgs[i]=true;
			else
				hookArgs[i]=false;
			end
		elseif v==6 then
			hookArgs[i]=string.gsub(currentArg,"%%20"," ");
		elseif v==7 then
			hookArgs[i]=ents.GetByIndex(currentArg);
		elseif v==8 then
			local breakString=string.Explode(",",currentArg);
			
			hookArgs[i]=Vector(tonumber(breakString[1]),tonumber(breakString[2]),tonumber(breakString[3]));
		elseif v==9 then
			local breakString=string.Explode(",",currentArg);
			
			hookArgs[i]=Angle(tonumber(breakString[1]),tonumber(breakString[2]),tonumber(breakString[3]));
		elseif v==10 then
			local itemid=tonumber(currentArg);
			hookArgs[i]=IF.Items:Get(itemid);
		elseif v==11 then
			local invid=tonumber(currentArg);
			hookArgs[i]=IF.Inv:Get(invid);
		end
	end
	command.Hook(self,fromPl,unpack(hookArgs));
end
IF.Items:ProtectKey("ReceiveNWCommand");

--[[
* SERVER
* Protected

Runs when a client requests to send this item to the world somewhere
]]--
function ITEM:PlayerSendToWorld(pl,from,to)
	if !self:Event("CanPlayerInteract",false,pl) then return false end
	
	local ent=self:ToWorld(from);
	
	local tr={};
	tr.start		=	from;
	tr.endpos		=	from+((to-from):Normalize()*64);
	tr.filter		=	{pl,pl:GetViewEntity(),ent};
	traceRes		=	util.TraceEntity(tr,ent);
	
	if traceRes.HitPos:Distance(pl:GetPos())>200 then return false end
	
	self:ToWorld(traceRes.HitPos);
end
IF.Items:ProtectKey("PlayerSendToWorld");

--[[
* SERVER
* Protected

Runs when a client requests to hold an item
]]--
function ITEM:PlayerHold(pl)
	if !self:Event("CanPlayerInteract",false,pl) then return false end
	self:Hold(pl);
end
IF.Items:ProtectKey("PlayerHold");

--[[
* SERVER
* Protected

Runs when a client requests to merge this item and another item
]]--
function ITEM:PlayerMerge(pl,otherItem)
	if !self:Event("CanPlayerInteract",false,pl) || !otherItem:Event("CanPlayerInteract",false,pl) then return false end
	self:Merge(otherItem);
end
IF.Items:ProtectKey("PlayerMerge");

--[[
* SERVER
* Protected

Runs when a client requests to split this item
]]--
function ITEM:PlayerSplit(player,amt)
	if !self:Event("CanPlayerInteract",false,player) || !self:Event("CanPlayerSplit",true,player) then return false end
	return self:Split(amt);
end
IF.Items:ProtectKey("PlayerSplit");

--Place networked commands here in the same order as in cl_init.lua.
IF.Items:CreateNWCommand(ITEM,"ToInventory",nil,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"RemoveFromInventory",nil,{"bool","inventory"});
IF.Items:CreateNWCommand(ITEM,"TransferInventory",nil,{"inventory","inventory","short"});
IF.Items:CreateNWCommand(ITEM,"TransferSlot",nil,{"inventory","short","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerUse",function(self,...) self:Use(...) end);
IF.Items:CreateNWCommand(ITEM,"PlayerHold",function(self,...) self:PlayerHold(...) end);
IF.Items:CreateNWCommand(ITEM,"PlayerSendToInventory",function(self,...) self:PlayerSendToInventory(...) end,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerSendToWorld",function(self,...) self:PlayerSendToWorld(...) end,{"vector","vector"});
IF.Items:CreateNWCommand(ITEM,"PlayerMerge",function(self,...) self:PlayerMerge(...) end,{"item"});
IF.Items:CreateNWCommand(ITEM,"PlayerSplit",function(self,...) self:PlayerSplit(...) end,{"int"});