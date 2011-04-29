--[[
Itemforge Item Networked Variables
SHARED

These are here to make it easier to network data between the server and the clients.

Networked vars must first be defined for this item-type.
They must be created in the same order both serverside and clientside (which is why they're in the shared file).
Here is a demonstration of how to create a networked var for this item-type:
	IF.Items:CreateNWVar(ITEM,"MyNetworkedInt","int",1);
	
You can set this networked var to 5 by doing:
	self:SetNWInt("MyNetworkedInt",5);
	
You can get this networked var by doing:
	self:GetNWInt("MyNetworkedInt");


Setting any networked var serverside will cause it to be set clientside as well.
If pl is nil, and the network var changed (ex, changed from 3 to 5, not 3 to 3) Itemforge will update the network var on all connected players (or, if the item has a NetOwner, just that player).
If pl is a certain player, Itemforge will only update the network var on that client, even if the network var didn't change.
If pl is false, Itemforge will NOT update the network var on any clients.
You can set something to nil both clientside and serverside by giving nil to the SetNW* function.

The datatype of the networked var must be given. This tells Itemforge what kind of data it is (like a number, an entity, etc).
So, if your var's datatype is "int", you have to do SetNWInt() to set it.

Networked vars can have default values.
The default value is set when you create the networked var with IF.Items:CreateNWVar() (in our example above, it's 1).
The default value can be
	nil (for nothing - or in other words, it's optional - you don't even have to give it)
	a constant value, like the number 1 or the text "hello"
	a function, like... function(self) return self.Weight end
The default value is given when doing a GetNW* if:
	we haven't set a networked var yet
	we set a networked var to nil with the SetNW* functions

Networked vars will be transferred via inheritance - that is, if Item A has a networked var, and Item B inherits from Item A, Item B has Item A's networked var too.
You can also override networked vars inherited from other item types. For example:
	If Item A:
		has a networked var, "MyNetworkedVar" with a default value of 5
	and Item B:
		has a networked var, "MyNetworkedVar" with a default value of 21
		and inherits from Item A
	
	then Item B's "MyNetworkedVar" overrides Item A's "MyNetworkedVar", instead of inheriting it.
	The default value of MyNetworkedVar will be 21 on Item B.
]]--

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
ITEM.NWVarsByName=nil;		--List of Networked vars in this itemtype (key is name, value is id).
ITEM.NWVarsByID=nil;		--List of Networked vars in this itemtype (key is id, value is name).
ITEM.NWVars=nil;			--The current value for networked vars set on this particular item are stored here, both clientside and serverside.
if SERVER then
ITEM.NWVarsLastTick=nil;	--Last time the server ticked, the predicted networked vars had these values.
else
ITEM.NWVarsThisTick=nil;	--Next time the client ticks, the predicted networked vars will be set to this.
end

--[[
Default Networked Vars - ITEM, NameOfVar, Datatype, DefaultValue (optional), IsPredicted (optional), HoldFromUpdate (optional)
]]--
--What condition is this item in? If the item is actually a stack of items, the 'top' item is in this condition.
IF.Items:CreateNWVar(ITEM,"Health","int",function(self) return self.MaxHealth end);

--How durable is the item (how many hit points total does it have)? Higher values mean the item is more durable.
IF.Items:CreateNWVar(ITEM,"MaxHealth","int",function(self) return self.MaxHealth end);

--Weight is how much an item weighs, in grams. This affects how much weight an item fills in an inventory with a weight cap, not the physics weight when the item is on the ground.
IF.Items:CreateNWVar(ITEM,"Weight","int",function(self) return self.Weight end);

--Size is a measure of how much space an item takes up (think volume, not weight). Inventories can be set up to reject items that are too big.
IF.Items:CreateNWVar(ITEM,"Size","int",function(self) return self.Size end);

--What is this item's world model? This is visible when the item is in the world, in item slots, and when held in third person.
IF.Items:CreateNWVar(ITEM,"WorldModel","string",function(self) return self.WorldModel end);

--What is this item's view model? The player sees himself holding this while he is wielding the item as an SWEP in first person.
IF.Items:CreateNWVar(ITEM,"ViewModel","string",function(self) return self.ViewModel end);

--When the item is held, is the view model flipped?
IF.Items:CreateNWVar(ITEM,"SWEPViewModelFlip","bool",function(self) return self.SWEPViewModelFlip end);

--When the item is held, what slot # and position does it occupy in the weapon selection menu?
IF.Items:CreateNWVar(ITEM,"SWEPSlot","int",function(self) return self.SWEPSlot end);
IF.Items:CreateNWVar(ITEM,"SWEPSlotPos","int",function(self) return self.SWEPSlotPos end);

--What color is the item? This affects model color and icon color by default.
IF.Items:CreateNWVar(ITEM,"Color","color",function(self) return self.Color end);

--What override material does the item use? This affects the world model material by default.
IF.Items:CreateNWVar(ITEM,"OverrideMaterial","string",function(self) return self.OverrideMaterial end);

--[[
How many items are in this stack?
Items with max amounts other than 1 are called stacks.
This doesn't actually create copies of the item, it just "says" there are 100.
The total weight of the stack is calculated by doing (amount * individual item weight)
Whenever an item's health reaches 0, item amounts are subtracted (usually by 1, but possibly more if the damage is great enough).
If amount reaches 0, the item is removed (this is why the default is 1).
:Split() can be used to split the stack, making a new stack (a copy) of the item.
Likewise, :Merge() can remove other items and add their amounts onto this item.
]]--
IF.Items:CreateNWVar(ITEM,"Amount","int",function(self) return self.StartAmount end,true);

--How many items can be in this stack? If this is set to 0, an unlimited amount of items of this type can be in the same stack.
IF.Items:CreateNWVar(ITEM,"MaxAmount","int",function(self)
													return self.MaxAmount
												end);
--[[
* SHARED
* Protected

Set a networked angle on this item
]]--
function ITEM:SetNWAngle(sName,aAng,bSuppress)
	if sName==nil							then return self:Error("Couldn't set networked angle. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil		then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=7		then return self:Error("Couldn't set networked angle. "..sName.." is not a networked angle.\n") end
	if aAng!=nil && type(aAng)!="Angle"		then return self:Error("Couldn't set networked angle. Given value was a \""..type(aAng).."\", not an angle!\n") end
	
	local upd=self:SetNWVar(sName,aAng);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWAngle");

--[[
* SHARED
* Protected

Set a networked bool on this item
]]--
function ITEM:SetNWBool(sName,bBool,bSuppress)
	if sName==nil								then return self:Error("Couldn't set networked bool. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil			then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=3			then return self:Error("Couldn't set networked bool. "..sName.." is not a networked bool.\n") end
	if bBool!=nil && type(bBool)!="boolean"		then return self:Error("Couldn't set networked bool. Given value was a \""..type(bBool).."\", not a bool!\n") end
	
	local upd=self:SetNWVar(sName,bBool);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWBool");

--[[
* SHARED
* Protected

Set a networked entity on this item
]]--
function ITEM:SetNWEntity(sName,cEnt,bSuppress)
	if sName==nil							then return self:Error("Couldn't set networked entity. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil		then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=5		then return self:Error("Couldn't set networked entity. "..sName.." is not a networked entity.\n") end
	if cEnt!=nil && type(cEnt)!="Entity" && type(cEnt)!="Player" && type(cEnt)!="Weapon" && type(cEnt)!="NPC" && type(cEnt)!="Vehicle" then return self:Error("Couldn't set networked entity. Given value was a \""..type(cEnt).."\", not an entity! Valid entity types are: Entity, Player, NPC, Vehicle, and Weapon\n") end
	
	local upd=self:SetNWVar(sName,cEnt);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWEntity");

--[[
* SHARED
* Protected

Set a networked float on this item
]]--
function ITEM:SetNWFloat(sName,fFloat,bSuppress)
	if sName==nil								then return self:Error("Couldn't set networked float. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil			then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=2			then return self:Error("Couldn't set networked float. "..sName.." is not a networked float.\n") end
	if fFloat!=nil && type(fFloat)!="number"	then return self:Error("Couldn't set networked float. Given value was a \""..type(fFloat).."\", not a number!\n") end
	
	local upd=self:SetNWVar(sName,fFloat);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWFloat");

--[[
* SHARED
* Protected

Set a networked integer on this item. The right type of data to send (char, uchar, short, ushort, long, or ulong) is determined automatically.
We opt to use the smallest datatypes possible.
If run on the server, and the number given is too large to be sent (even larger than an unsigned int) the number will be set to 0, both serverside and clientside.
]]--
function ITEM:SetNWInt(sName,iInt,bSuppress)
	if sName==nil							then return self:Error("Couldn't set networked integer. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil		then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=1		then return self:Error("Couldn't set networked int. "..sName.." is not a networked int.\n") end
	if iInt!=nil then
		--We were given something, were we given a valid number?
		if type(iInt)!="number"				then return self:Error("Couldn't set networked int. Given value was a \""..type(iInt).."\", not a number!\n") end
		
		--If we /were/ given a valid number, we need to truncate the decimal, if there is any.
		iInt=math.floor(iInt);
	end
	
	local upd=self:SetNWVar(sName,iInt);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWInt");

--[[
* SHARED
* Protected

Set a networked string on this item
]]--
function ITEM:SetNWString(sName,sString,bSuppress)
	if sName==nil								then return self:Error("Couldn't set networked string. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil			then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=4			then return self:Error("Couldn't set networked string. "..sName.." is not a networked string.\n") end
	if sString!=nil && type(sString)!="string"	then return self:Error("Couldn't set networked string. Given value was a \""..type(sString).."\", not a string!\n") end
	
	local upd=self:SetNWVar(sName,sString);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWString");

--[[
* SHARED
* Protected

Set a networked vector on this item
]]--
function ITEM:SetNWVector(sName,vVec,bSuppress)
	if sName==nil							then return self:Error("Couldn't set networked vector. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil		then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=6		then return self:Error("Couldn't set networked vector. "..sName.." is not a networked vector.\n") end
	if vVec!=nil && type(vVec)!="Vector"	then return self:Error("Couldn't set networked vector. Given value was a \""..type(vVec).."\", not a vector!\n") end
	
	local upd=self:SetNWVar(sName,vVec);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWVector");

--[[
* SHARED
* Protected

Set a networked item on this item
]]--
function ITEM:SetNWItem(sName,cItem,bSuppress)
	if sName==nil							then return self:Error("Couldn't set networked item. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil		then return self:Error("There is no networked var by the name \""..sName.."\".\n") end
	if self.NWVarsByName[sName].Type!=8		then return self:Error("Couldn't set networked item. \""..sName.."\" is not a networked item.\n") end
	if cItem!=nil then
		if type(cItem)!="table" then
			return self:Error("Couldn't set networked item. Given value was a \""..type(cItem).."\", not an item!\n");
		elseif !cItem:IsValid() then
			cItem=nil;
		end
	end
	
	local upd=self:SetNWVar(sName,cItem);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWItem");

--[[
* SHARED
* Protected

Set a networked inventory on this item
]]--
function ITEM:SetNWInventory(sName,cInv,bSuppress)
	if sName==nil							then return self:Error("Couldn't set networked inventory. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil		then return self:Error("There is no networked var by the name "..sName..".\n") end
	if self.NWVarsByName[sName].Type!=9		then return self:Error("Couldn't set networked inventory. "..sName.." is not a networked inventory.\n") end
	if cInv!=nil then
		if type(cInv)!="table" then
			return self:Error("Couldn't set networked inventory. Given value was a \""..type(cInv).."\", not an inventory!\n");
		elseif !cInv:IsValid() then
			cInv=nil;
		end
	end
	
	local upd=self:SetNWVar(sName,cInv);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWInventory");

--[[
* SHARED
* Protected

Set a networked color on this item
]]--
function ITEM:SetNWColor(sName,cColor,bSuppress)
	if sName==nil							then return self:Error("Couldn't set networked color. sName wasn't given!\n") end
	if self.NWVarsByName[sName]==nil		then return self:Error("There is no networked var by the name \""..sName.."\".\n") end
	if self.NWVarsByName[sName].Type!=10	then return self:Error("Couldn't set networked color. \""..sName.."\" is not a networked color.\n") end
	
	if cColor!=nil then
		if type(cColor)!="table" then
			return self:Error("Couldn't set networked color. Given value was a \""..type(cColor).."\", not a color!\n");
		elseif !cColor.r || !cColor.g || !cColor.b || !cColor.a then
			return self:Error("Couldn't set networked color. Given table didn't have an 'r','g','b', and/or 'a' entry; maybe this table is not a color?\n");
		else
			--Lets make sure values are in range here
			cColor.r=math.Clamp(cColor.r,0,255);
			cColor.g=math.Clamp(cColor.g,0,255);
			cColor.b=math.Clamp(cColor.b,0,255);
			cColor.a=math.Clamp(cColor.a,0,255);
		end
	end
	
	local upd=self:SetNWVar(sName,cColor);
	
	if SERVER && upd && !bSuppress && !self.NWVarsByName[sName].Predicted  then
		self:SendNWVar(sName);
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWColor");

--[[
* SHARED
* Protected

Don't call this directly, it's called by the other SetNW* functions
This actually sets the networked var to the given value serverside/clientside.
This returns true if the networked value changed from what it was, or false if it didn't.
]]--
function ITEM:SetNWVar(sName,vValue)
	if self.NWVarsByName[sName]==nil then return self:Error("There is no networked var by the name "..sName..".\n") end
	
	--If NWVars hasn't been created yet, we'll create it
	if self.NWVars==nil then self.NWVars={} end
	
	--No change necessary if new value and old are same thing
	if (vValue==nil && self.NWVars[sName]==nil) || self:GetNWVar(sName)==vValue then return false end
	
	--Set the networked var given to this name
	self.NWVars[sName]=vValue;
	
	--Our OnSetNWVar event gets called here
	self:Event("OnSetNWVar",nil,sName,vValue);
		
	return true;
end
IF.Items:ProtectKey("SetNWVar");

--[[
* SHARED
* Protected

Returns a networked entity with the given name.
If the networked entity is no longer valid it's set to nil.
]]--
function ITEM:GetNWEntity(sName)
	local ent=self:GetNWVar(sName);
	if ent && !ent:IsValid() then
		self:SetNWEntity(sName,nil);
		return nil;
	end
	return ent;
end
IF.Items:ProtectKey("GetNWEntity");

--[[
* SHARED
* Protected

Returns a networked item with the given name.
If the networked item is no longer valid it's set to nil.
]]--
function ITEM:GetNWItem(sName)
	local item=self:GetNWVar(sName);
	if item && !item:IsValid() then
		self:SetNWItem(sName,nil);
		return nil;
	end
	return item;
end
IF.Items:ProtectKey("GetNWItem");

--[[
* SHARED
* Protected

Returns a networked entity with the given name.
If the networked entity is no longer valid it's set to nil.
]]--
function ITEM:GetNWInventory(sName)
	local inv=self:GetNWVar(sName);
	if inv && !inv:IsValid() then
		self:SetNWInventory(sName,nil);
		return nil;
	end
	return inv;
end
IF.Items:ProtectKey("GetNWInventory");

--[[
* SHARED
* Protected

Returns a networked var.
]]--
function ITEM:GetNWVar(sName)
	if self.NWVarsByName[sName]==nil then self:Error("There is no networked var by the name "..sName..".\n"); return nil; end
	
	if self.NWVars && self.NWVars[sName]!=nil then		--Return this NWVar if it has been set
		return self.NWVars[sName];
	else												--If it hasn't, let's check for a default value to return.
		local d=self.NWVarsByName[sName].Default;
		
		--[[
		If the default value is a function we'll run it and return what it returns
		If it isn't, we'll just return whatever the default value was
		if the default value is nil, we return nil
		]]--
		if type(d)=="function" then
			local s,r=pcall(d,self);
			if !s then
				ErrorNoHalt(r.."\n");
				return nil;
			else
				return r;
			end
		else
			return d;
		end
	end
end
IF.Items:ProtectKey("GetNWVar");

--Shitload of aliases for your convenience
ITEM.SetNetworkedAngle=ITEM.SetNWAngle;				IF.Items:ProtectKey("SetNetworkedAngle");
ITEM.SetNetworkedBool=ITEM.SetNWBool;				IF.Items:ProtectKey("SetNetworkedBool");
ITEM.SetNetworkedColor=ITEM.SetNWColor;				IF.Items:ProtectKey("SetNetworkedColor");
ITEM.SetNetworkedEntity=ITEM.SetNWEntity;			IF.Items:ProtectKey("SetNetworkedEntity");
ITEM.SetNetworkedFloat=ITEM.SetNWFloat;				IF.Items:ProtectKey("SetNetworkedFloat");
ITEM.SetNetworkedInt=ITEM.SetNWInt;					IF.Items:ProtectKey("SetNetworkedInt");
ITEM.SetNetworkedString=ITEM.SetNWString;			IF.Items:ProtectKey("SetNetworkedString");
ITEM.SetNetworkedVector=ITEM.SetNWVector;			IF.Items:ProtectKey("SetNetworkedVector");
ITEM.SetNetworkedItem=ITEM.SetNWItem;				IF.Items:ProtectKey("SetNetworkedItem");
ITEM.SetNetworkedInventory=ITEM.SetNWInventory;		IF.Items:ProtectKey("SetNetworkedInventory");
ITEM.SetNetworkedInv=ITEM.SetNWInventory;			IF.Items:ProtectKey("SetNetworkedInv");

ITEM.SetNWInv=ITEM.SetNWInventory;					IF.Items:ProtectKey("SetNWInv");

ITEM.GetNetworkedAngle=ITEM.GetNWVar;				IF.Items:ProtectKey("GetNetworkedAngle");
ITEM.GetNetworkedBool=ITEM.GetNWVar;				IF.Items:ProtectKey("GetNetworkedBool");
ITEM.GetNetworkedColor=ITEM.GetNWVar;				IF.Items:ProtectKey("GetNetworkedColor");
ITEM.GetNetworkedEntity=ITEM.GetNWEntity;			IF.Items:ProtectKey("GetNetworkedEntity");
ITEM.GetNetworkedFloat=ITEM.GetNWVar;				IF.Items:ProtectKey("GetNetworkedFloat");
ITEM.GetNetworkedInt=ITEM.GetNWVar;					IF.Items:ProtectKey("GetNetworkedInt");
ITEM.GetNetworkedString=ITEM.GetNWVar;				IF.Items:ProtectKey("GetNetworkedString");
ITEM.GetNetworkedVector=ITEM.GetNWVar;				IF.Items:ProtectKey("GetNetworkedVector");
ITEM.GetNetworkedItem=ITEM.GetNWItem;				IF.Items:ProtectKey("GetNetworkedItem");
ITEM.GetNetworkedInventory=ITEM.GetNWInventory;		IF.Items:ProtectKey("GetNetworkedInventory");
ITEM.GetNetworkedInv=ITEM.GetNWInv;					IF.Items:ProtectKey("GetNetworkedInv");

ITEM.GetNWAngle=ITEM.GetNWVar;						IF.Items:ProtectKey("GetNWAngle");
ITEM.GetNWBool=ITEM.GetNWVar;						IF.Items:ProtectKey("GetNWBool");
ITEM.GetNWColor=ITEM.GetNWVar;						IF.Items:ProtectKey("GetNWColor");
ITEM.GetNWFloat=ITEM.GetNWVar;						IF.Items:ProtectKey("GetNWFloat");
ITEM.GetNWInt=ITEM.GetNWVar;						IF.Items:ProtectKey("GetNWInt");
ITEM.GetNWString=ITEM.GetNWVar;						IF.Items:ProtectKey("GetNWString");
ITEM.GetNWVector=ITEM.GetNWVar;						IF.Items:ProtectKey("GetNWVector");
ITEM.GetNWInv=ITEM.GetNWInventory;					IF.Items:ProtectKey("GetNWInv");


if SERVER then




--[[
* SERVER
* Protected

Sends a networked var to the given player.
We'll tell the clients to set the var to nil if the networked var:
	Hasn't been set
	Was set to nil
	Hasn't been set to something other than the default yet
Otherwise we'll tell the clients to set the var to what we changed.
	
sName is the name of a networked var to send.
pTo is an optional player to send to.
	If this is nil, we will send the networked var to everybody (or to the owner if the item is private).
True is returned if the networked var was sent to the requested player.
	If we tried to send to everybody, true is returned if the networked var was successfully sent to all players.
False is returned otherwise.
]]--
function ITEM:SendNWVar(sName,pTo)
	if self.NWVarsByName[sName]==nil then return self:Error("There is no networked var by the name "..sName..".\n") end
	
	local owner=self:GetOwner();
	if pTo==nil && owner==nil then
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:SendNWVar(sName,v) then allSuccess=false end
		end
		return allSuccess;
	else
		pTo=pTo or owner;
	end
	
	local varid=self.NWVarsByName[sName].ID-128;
	local type=self.NWVarsByName[sName].Type;
	local val=nil;
	if self.NWVars then val=self.NWVars[sName] end
	
	if val==nil then
		IF.Items:IFIStart(pTo,IFI_MSG_SETNIL,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIEnd();
	elseif type==1 then
		if val>=-128 && val<=127 then						--Send as a char
			IF.Items:IFIStart(pTo,IFI_MSG_SETCHAR,self:GetID());
			IF.Items:IFIChar(varid);
			IF.Items:IFIChar(val);
			IF.Items:IFIEnd();
		elseif val>=0 && val<=255 then					--Send as an unsigned char
			IF.Items:IFIStart(pTo,IFI_MSG_SETUCHAR,self:GetID());
			IF.Items:IFIChar(varid);
			IF.Items:IFIChar(val-128);
			IF.Items:IFIEnd();
		elseif val>=-32768 && val<=32767 then				--Send as a short
			IF.Items:IFIStart(pTo,IFI_MSG_SETSHORT,self:GetID());
			IF.Items:IFIChar(varid);
			IF.Items:IFIShort(val);
			IF.Items:IFIEnd();
		elseif val>=0 && val<=65535 then					--Send as an unsigned short
			IF.Items:IFIStart(pTo,IFI_MSG_SETUSHORT,self:GetID());
			IF.Items:IFIChar(varid);
			IF.Items:IFIShort(val-32768);
			IF.Items:IFIEnd();
		elseif val>=-2147483648 && val<=2147483647 then	--Send as a long
			IF.Items:IFIStart(pTo,IFI_MSG_SETLONG,self:GetID());
			IF.Items:IFIChar(varid);
			IF.Items:IFILong(val);
			IF.Items:IFIEnd();
		elseif val>=0 && val<=4294967295 then				--Send as an unsigned long
			IF.Items:IFIStart(pTo,IFI_MSG_SETULONG,self:GetID());
			IF.Items:IFIChar(varid);
			IF.Items:IFILong(val-2147483648);
			IF.Items:IFIEnd();
		else
			--TODO better error handling here
			self:Error("Trying to send NWVar "..sName.." failed - the number "..val.." is too large to be sent!\n");
			
			--It's an invalid number to send
			self:SetNWVar(sName,0);
			IF.Items:IFIStart(pTo,IFI_MSG_SETCHAR,self:GetID());
			IF.Items:IFIChar(varid);
			IF.Items:IFIChar(0);
			IF.Items:IFIEnd();
		end
	elseif type==3 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETBOOL,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIBool(val);
		IF.Items:IFIEnd();
	elseif type==2 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETFLOAT,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIFloat(val);
		IF.Items:IFIEnd();
	elseif type==4 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETSTRING,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIString(val);
		IF.Items:IFIEnd();
	elseif type==6 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETVECTOR,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIVector(val);
		IF.Items:IFIEnd();
	elseif type==7 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETANGLE,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIAngle(val);
		IF.Items:IFIEnd();
	elseif type==8 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETITEM,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIShort(val:GetID()-32768);
		IF.Items:IFIEnd();
	elseif type==9 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETINV,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIShort(val:GetID()-32768);
		IF.Items:IFIEnd();
	elseif type==5 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETENTITY,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIEntity(val);
		IF.Items:IFIEnd();
	elseif type==10 then
		IF.Items:IFIStart(pTo,IFI_MSG_SETCOLOR,self:GetID());
		IF.Items:IFIChar(varid);
		IF.Items:IFIChar(val.r-128);
		IF.Items:IFIChar(val.g-128);
		IF.Items:IFIChar(val.b-128);
		IF.Items:IFIChar(val.a-128);
		IF.Items:IFIEnd();
	end
end
IF.Items:ProtectKey("SendNWVar");




else




--[[
* CLIENT
* Protected

Whenever a networked var is received from the server, this function is called.
]]--
function ITEM:ReceiveNWVar(sName,vVal)
	if !sName						then return self:Error("Couldn't receive network var from server. Name of network var wasn't given.\n") end
	if !self.NWVarsByName[sName]	then return self:Error("Couldn't receive network var from server. Network var by name \""..sName.."\" doesn't exist clientside.\n") end
	
	if self.NWVarsByName[sName].Predicted then
		if !self.NWVarsThisTick then self.NWVarsThisTick={} end
		self.NWVarsThisTick[sName]=vVal;
	else
		self:SetNWVar(sName,vVal);
	end
end
IF.Items:ProtectKey("ReceiveNWVar");




end