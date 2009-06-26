--[[
item
CLIENT

item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is item/cl_init.lua, so this item's type is "item")
]]--
include("shared.lua");
include("events_client.lua");
ITEM.Icon=Material("melonracer/go");				--This used to be displayed in item slots (and probably still could) but for now it's only used in the weapon selection menu by default.
ITEM.ThinkRate=0;									--Run think clientside every # of seconds set here. This can be set to 0 to think every frame.
ITEM.UseModelFor2D=true;							--If this is true, when displaying the item in an item slot, we'll create a model panel and display this item's world model in it. If this is false, no model panel is created.
ITEM.WorldModelNudge=Vector(0,0,0);					--The item's world model is shifted by this amount relative to the player's right hand. This is only used if this item's world model is a non-standard weapon model (doesn't have a "ValveBiped.Bip01_R_Hand" bone like the HL2 pistol, crowbar, smg, etc).
ITEM.WorldModelRotate=Angle(0,0,0);					--The item's world model is rotated by this amount relative to the player's right hand. This is only used if this item's world model is a non-standard weapon model (doesn't have a "ValveBiped.Bip01_R_Hand" bone like the HL2 pistol, crowbar, smg, etc).
ITEM.RCMenu=nil;									--Our right click menu (a DMenu).
ITEM.Rand=nil;										--This number adds some random spin when posing this item's world model in 3D.

--[[
This adds the item to an inventory and sets the item's inventory
Clientside, this just sets the inventory the item is in and adds it to that inventory clientside. slot is required.
If the item cannot be inserted (inventory doesn't exist or inventory wouldn't allow the item to be added for some reason) then false is returned.
]]--
function ITEM:ToInventory(inv,slot)
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Items: Could not insert "..tostring(self).." into an inventory, inventory given is not valid.\n"); return false end
	if slot==nil then ErrorNoHalt("Itemforge Items: Could not add "..tostring(self).." to inventory "..inv:GetID().." clientside! slot was not given!\n"); return false end
	
	local container=self:GetContainer();
	
	--We don't stop insertion clientside if the item has an entity or another container already, but we bitch about it so the scripter knows something isn't right
	if container && container!=inv then ErrorNoHalt("Itemforge Items: Warning! "..tostring(self).." is already in an inventory clientside, but is being inserted into inventory "..inv:GetID().." anyway! Not supposed to happen!\n"); end
	
	--We can safely ignore these...
	--Tested this way: Held an item as weapon, then sent to inventory. On server, it removed the entity and then sent to inventory. On client, messages were out of order - instruction to add item to inventory arrived before instruction to remove entity. Interesting.
	--[[
	local ent=self:GetEntity();
	if ent then
		local c=ent:GetClass();
		if c=="itemforge_item" then
			ErrorNoHalt("Itemforge Items: Warning! Item "..self:GetID().." is in the world clientside, but is being inserted into inventory "..inv:GetID().."! Not supposed to happen!\n");
		elseif c=="itemforge_item_held" then
			ErrorNoHalt("Itemforge Items: Warning! Item "..self:GetID().." is being held by a player clientside, but is being inserted into inventory "..inv:GetID().."! Not supposed to happen!\n");
		else
			ErrorNoHalt("Itemforge Items: Warning! Item "..self:GetID().." is in an entity unrelated to Itemforge clientside, but is being inserted into inventory "..inv:GetID().."... Not supposed to happen.\n");
		end
	end
	]]--
	local n=inv:InsertItem(self,slot);
	
	--This will fail if there are insertion errors, not because events deny it (events will still run clientside, though)
	if !n then return false end
	self:SetContainer(inv);
	
	return true;
end
IF.Items:ProtectKey("ToInventory");
--A shorter alias
ITEM.ToInv=ITEM.ToInventory
IF.Items:ProtectKey("ToInv");


--[[
Transfer from one inventory to another.
This function is designed to save bandwidth.
Instead of sending two NWCommands, one to remove from an inventory, another to add to an inventory, only one NWCommand is run.
This function merely voids an item from the old inventory and inserts it into the new inventory.
True is returned if these operations were successful. False is returned otherwise.
]]--
function ITEM:TransInventory(old,new,newSlot)
	if !old || !old:IsValid() then ErrorNoHalt("Itemforge Items: Could not transfer "..tostring(self).." from one inventory to another clientside, 'old' inventory given is not valid.\n"); return false end
	if !new || !new:IsValid() then ErrorNoHalt("Itemforge Items: Could not transfer "..tostring(self).." from inventory "..old:GetID().." to another inventory clientside, 'new' inventory given is not valid.\n"); return false end
	if newSlot==nil then ErrorNoHalt("Itemforge Items: Could not transfer "..tostring(self).." from inventory "..old:GetID().." to inventory "..newInv:GetID().." clientside! newSlot was not given!\n"); return false end
	
	if old!=new && !self:ToVoid(false,old) then end
	if !self:ToInventory(new,newSlot) then return false end
end
IF.Items:ProtectKey("TransInventory");

--[[
Transfer from one slot to another.
True is returned if the move was successful. False is returned otherwise.
]]--
function ITEM:TransSlot(inv,oldslot,newslot)
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Items: Could not transfer "..tostring(self).." from one slot to another clientside, inventory given is not valid.\n"); return false end
	if !inv:MoveItem(self,oldslot,newslot) then return false end
end
IF.Items:ProtectKey("TransSlot");

--[[
Clientside, the ToVoid function clears the entity/weapon associated with this item, or takes the item out of the inventory it's in clientside.
forced is a true/false that indiciates if a removal was graceful or forceful.
	The only reason this will be true is if the server forced the removal.
	Unlike on the server, "forced" doesn't make much of a difference clientside;
	Events cannot stop an item from being voided clientside, but they can know whether or not the server forced the removal or not.
vDoubleCheck is optional; This value should be given by networked functions (or when a SENT/SWEP is removed clientside). ToVoid will check for netsync errors by comparing the given entity/inventory to the current entity/inventory.

true is returned if the item was placed in the void, or is in the void already.
false is returned if the item couldn't be placed in the void.
]]--
function ITEM:ToVoid(forced,vDoubleCheck)
	if self:InWorld() then
		local ent=self:GetEntity();
		
		if vDoubleCheck && ent!=vDoubleCheck then ErrorNoHalt("Itemforge Items: WARNING! Tried to take "..tostring(self).." out of the world, but the entity being removed ("..tostring(vDoubleCheck)..") didn't match the current world entity ("..tostring(ent).."). Old world entity?\n"); return false end
		
		--Let events run
		local s,r=pcall(self.OnWorldExit,self,ent);
		if !s then					ErrorNoHalt(r.."\n")
		end
		
		self:ClearEntity();
	elseif self:IsHeld() then
		local ent=self:GetWeapon();
		
		if vDoubleCheck && ent!=vDoubleCheck then ErrorNoHalt("Itemforge Items: WARNING! Tried to stop holding "..tostring(self).." clientside, but the SWEP given ("..tostring(vDoubleCheck)..") didn't match the current SWEP ("..tostring(ent).."). Old weapon?\n"); return false end
		
		--Let events run
		local s,r=pcall(self.OnRelease,self,self:GetWOwner());
		if !s then					ErrorNoHalt(r.."\n")
		end
		
		self:ClearWeapon();
	elseif self:InInventory() then
		local container,cslot=self:GetContainer();
		if vDoubleCheck && container!=vDoubleCheck then ErrorNoHalt("Itemforge Items: WARNING! Tried to remove "..tostring(self).." from "..tostring(vDoubleCheck)..", but the item is in "..tostring(container).."! Netsync error?\n"); return false end
		
		--Let events run
		local s,r=pcall(self.OnMove,self,container,cslot,nil,nil,forced);
		if !s then					ErrorNoHalt(r.."\n")
		end
		
		container:RemoveItem(self:GetID(),forced);
		self:ClearContainer();
	end
	
	return true;
end
IF.Items:ProtectKey("ToVoid");

--[[
Protected OnWorldExit event.
Stops all looping sounds and then runs the overridable OnWorldExit event.
]]--
function ITEM:OnWorldExitSafe(ent)
	self:StopAllLoopingSounds();
	
	--Give events a chance to stop the removal (or at least let them run if it's forced)
	local s,r=pcall(self.OnWorldExit,self,ent);
	if !s then					ErrorNoHalt(r.."\n")
	end
end
IF.Items:ProtectKey("OnWorldExitSafe");

--[[
Run this function to use the item.
It will trigger the OnUse event in the item.
If this function is run on the client, the OnUse event can stop it clientside. If it isn't stopped, it requests to "PlayerUse" the item on the server.
False is returned if the item is unable to be used for any reason.

NOTE: If OnUse returns false clientside, "I can't use this!" does not appear, it simply stops the item from being used serverside.
TODO: Possibly have the item used by something other than a player
]]--
function ITEM:Use(pl)
	if !pl || !pl:IsValid() || !pl:IsPlayer() || !self:CanPlayerInteract(pl) then return false end
	
	local s,r=pcall(self.OnUse,self,pl);
	if !s then ErrorNoHalt(r.."\n")
	elseif !r then
		return false;
	end
	
	--After the event allows the item to be used clientside, ask the server to use the item.
	self:SendNWCommand("PlayerUse");
	
	return true;
end
IF.Items:ProtectKey("Use");

--[[
Run this function to hold the item.
It requests to "Hold" the item on the server.
False is returned if the item is unable to be held for any reason.
]]--
function ITEM:Hold(pl)
	if !pl || !pl:IsValid() || !pl:IsPlayer() || pl!=LocalPlayer() || !pl:Alive() then return false end
	
	self:SendNWCommand("PlayerHold");
	
	return true;
end
IF.Items:ProtectKey("Hold");

--[[
Returns this item's right click menu if one is currently open.
]]--
function ITEM:GetMenu()
	if self.RCMenu && !self.RCMenu:IsValid() then
		self.RCMenu=nil;
	end
	return self.RCMenu;
end
IF.Items:ProtectKey("GetMenu");

--[[
Displays this item's right click menu, positioning one of the menu's corners at x,y.
True is returned if the menu is opened successfully.
False is returned if the menu could not be opened. One possible reason this may happen is if the item's OnPopulateMenu event fails.
]]--
function ITEM:ShowMenu(x,y)
	self.RCMenu=DermaMenu();
	
	--Grab the item's name.
	local s,r=pcall(self.GetName,self)
	if !s then
		ErrorNoHalt(r.."\n");
		r="Itemforge Item";
	end
	if self:IsStack() then r=r.." x "..self:GetAmount() end
	
	--Add header
	local h=vgui.Create("ItemforgeMenuHeader");
	h:SetText(r);
	self.RCMenu:AddPanel(h);
	
	local s,r=pcall(self.OnPopulateMenu,self,self.RCMenu);
	if !s then
		ErrorNoHalt(r.."\n");
		self.RCMenu:Remove();
		return false;
	end
	
	return self.RCMenu:Open(x,y);
end
IF.Items:ProtectKey("ShowMenu");

--[[
Removes the menu if it is open.
Returns true if the menu was open and was closed,
or false if there wasn't a menu open.
]]--
function ITEM:KillMenu()
	local menu=self:GetMenu();
	if !menu then return false end
	
	menu:Remove();
	self.RCMenu=nil;
	return true;
end
IF.Items:ProtectKey("KillMenu");

function ITEM:PlayerSplit(pl)
	if !self:CanPlayerInteract(pl) then return false end
	
	--Can't split 1 item
	local amt=self:GetAmount();
	if amt==1 then return false end
	
	local s,r=pcall(self.GetName,self);
	if !s then ErrorNoHalt(r.."\n"); r="Itemforge Item" end
	
	local Window = vgui.Create("DFrame");
		Window:SetTitle("Split "..r);
		Window:SetDraggable(false);
		Window:ShowCloseButton(false);
		Window:SetBackgroundBlur(true);
		Window:SetDrawOnTop(true);
	
	--The inner pannel contains the following controls:
	local InnerPanel=vgui.Create("DPanel",Window);
		InnerPanel:SetPos(0,25);
		
		--Instructions for how to use this window.
		local Text=Label("Drag the slider to choose how even the split is:",InnerPanel);
			Text:SizeToContents();
			Text:SetWide(Text:GetWide()+100);
			Text:SetContentAlignment(5);
			Text:SetTextColor(Color(255,255,255,255));
			Text:SetPos(0,5);
		
		--Text that displays a fraction like "50/50" or "25/75" that says how "even" the split is
		local Fraction = Label("",InnerPanel);
			Fraction:SizeToContents();
			Fraction:SetContentAlignment(5);
			Fraction:SetPos(0,Text:GetTall()+5)
			Fraction:SetWide(Text:GetWide());		
		
		--Text that displays the number of items that will stay in the original stack
		local Value1 = Label("",InnerPanel);
			Value1:SetFont("ItemforgeInventoryFontBold");
			Value1:SetTextColor(Color(255,255,0,255));
			Value1:SetContentAlignment(6);
			Value1:SetPos(0,Text:GetTall()+Fraction:GetTall()+10)
			Value1:SetWide(50);
		
		--Text that displays the number of items that will be split off into the new stack
		local Value2 = Label("",InnerPanel);
			Value2:SetFont("ItemforgeInventoryFontBold");
			Value2:SetTextColor(Color(255,255,0,255));
			Value2:SetContentAlignment(4);
			Value2:SetPos(0,Text:GetTall()+Fraction:GetTall()+10)
			Value2:SetWide(50);
		
		--Slider that controls how many items will be split.
		local Slider = vgui.Create("DSlider",InnerPanel);
			Slider:SetTrapInside(true);
			Slider:SetImage("vgui/slider");
			Slider:SetLockY(0.5);
			Slider:SetSize(Text:GetWide()-100,13);
			Slider:SetPos(0,Text:GetTall()+Fraction:GetTall()+15)
			Derma_Hook(Slider,"Paint","Paint","NumSlider");
			--Whenever the slider is moved, the Fraction and Stack Numbers will be updated with the correct numbers.
			Slider.TranslateValues=function(self,x,y)
				local firstHalf=math.ceil(amt*x);
				local secondHalf=amt-firstHalf;
				local firstFrac=math.ceil(x*100);
				local secondFrac=100-firstFrac;
				
				Fraction:SetText(firstFrac.."/"..secondFrac);
				Value1:SetText(firstHalf);
				Value2:SetText(secondHalf);
				return x,y;
			end
			
	local ButtonPanel = vgui.Create( "DPanel", Window )
		local Button=vgui.Create("DButton",ButtonPanel)
			Button:SetText("OK");
			Button:SizeToContents();
			Button:SetSize(Button:GetWide()+20,20);		--Make the button a little wider than it's text
			Button:SetPos(5,5)
			Button.DoClick = function(panel) Window:Close(); self:SendNWCommand("PlayerSplit",amt-math.ceil(amt*Slider:GetSlideX())) end
		local Button2=vgui.Create("DButton",ButtonPanel)
			Button2:SetText("Cancel");
			Button2:SizeToContents();
			Button2:SetSize(Button2:GetWide()+20,20);	--Make the button a little wider than it's text
			Button2:SetPos(10+Button:GetWide(),5);
			Button2.DoClick = function(panel) Window:Close(); end
		ButtonPanel:SetSize(Button:GetWide()+Button2:GetWide()+15,30);
		
	InnerPanel:SetSize(Text:GetWide(),Text:GetTall()+Fraction:GetTall()+Slider:GetTall()+20)
	
	Slider:CenterHorizontal();
	Slider:TranslateValues(0.5,0.5);
	Value1:MoveLeftOf(Slider);
	Value2:MoveRightOf(Slider);
	
	Window:SetSize(InnerPanel:GetWide()+10,InnerPanel:GetTall()+ButtonPanel:GetTall()+38);
	Window:Center();
	
	InnerPanel:CenterHorizontal();
	
	ButtonPanel:CenterHorizontal();
	ButtonPanel:AlignBottom(8);
	
	Window:MakePopup();
	Window:DoModal();
end
IF.Items:ProtectKey("PlayerSplit");

--[[
Runs every time the client ticks.
]]--
function ITEM:Tick()
	--Set predicted network vars.
	if self.NWVarsThisTick then
		for k,v in pairs(self.NWVarsThisTick) do
			self:SetNWVar(k,v);
		end
		self.NWVarsThisTick=nil;
	end
end
IF.Items:ProtectKey("Tick");

--[[
Sends a networked command by name with the supplied arguments
Clientside, this runs console commands (sending data to the server in the process)
]]--
function ITEM:SendNWCommand(sName,...)
	local command=self.NWCommandsByName[sName];
	if command==nil then ErrorNoHalt("Itemforge Items: Couldn't send command '"..sName.."' on "..tostring(self)..", there is no NWCommand with this name on this item!\n"); return false end
	if command.Hook!=nil then ErrorNoHalt("Itemforge Items: Command '"..command.Name.."' on "..tostring(self).." can't be sent clientside. It has a hook, meaning this command is recieved clientside, not sent.\n"); return false end
	
	local NIL="%%00";		--If a command isn't given, this is substituted. It means we want to send nil (nothing).
	local SPACE="%%20";		--If a space is given in a string, this is substituted. It means " ".
	
	local arglist={};
	
	--If our command sends data, then we need to send the appropriate type of data. It needs to be converted to string form though because we're using console commands.
	for i=1,table.maxn(command.Datatypes) do
		local v=command.Datatypes[i];
		if v==1||v==2||v==3||v==4||v==12||v==13||v==14 then
			--numerical datatypes
			if arg[i]!=nil then
				arglist[i]=tostring(arg[i]);
			else
				arglist[i]=NIL;
			end
		elseif v==5 then
			--bool
			if arg[i]==true then
				arglist[i]="t";
			elseif arg[i]==false then
				arglist[i]="f";
			else
				arglist[i]=NIL;
			end
		elseif v==6 then
			--str - We replace spaces in a string argument with %20 before sending them because we use spaces to seperate arguments
			if arg[i]!=nil then
				arglist[i]=string.gsub(arg[i]," ",SPACE);
			else
				arglist[i]=NIL;
			end
		elseif v==7 then
			--Entity
			if arg[i]!=nil then
				arglist[i]=tostring(arg[i]:EntIndex());
			else
				arglist[i]=NIL;
			end
		elseif v==8 then
			--Vector
			if arg[i]!=nil then
				arglist[i]=arg[i].x..","..arg[i].y..","..arg[i].z;
			else
				arglist[i]=NIL;
			end
		elseif v==9 then
			--Angle
			if arg[i]!=nil then
				arglist[i]=arg[i].p..","..arg[i].y..","..arg[i].r;
			else
				arglist[i]=NIL;
			end
		elseif v==10 || v==11 then
			--Item or inventory
			if arg[i]!=nil && arg[i]:IsValid() then
				arglist[i]=""..arg[i]:GetID();
			else
				arglist[i]=NIL;
			end
		elseif v==0 then
			arglist[i]=NIL;
		end
	end
	
	local argstring=string.Implode(" ",arglist);
	--DEBUG
	Msg("OUT: Message Type: "..IFI_MSG_CL2SVCOMMAND.." ("..sName..") - Item: "..self:GetID().."\n");
	
	RunConsoleCommand("ifi",IFI_MSG_CL2SVCOMMAND,self:GetID()-32768,self.NWCommandsByName[sName].ID-128,argstring);
end
IF.Items:ProtectKey("SendNWCommand");

--[[
This function is called automatically, whenever a networked command from the server is received.
Clientside, msg will be a bf_read (a usermessage received from the server).
There's no need to override this, we'll call the hook the command is associated if there is one.
]]--
function ITEM:ReceiveNWCommand(msg)
	local commandid=msg:ReadChar()+128;
	local command=self.NWCommandsByID[commandid];
	
	if command==nil then ErrorNoHalt("Itemforge Items: Couldn't find a NWCommand with ID '"..commandid.."' on "..tostring(self)..". Make sure commands are created in the same order BOTH serverside and clientside. \n"); return false end
	if command.Hook==nil then ErrorNoHalt("Itemforge Items: Command '"..command.Name.."' was received on "..tostring(self)..", but there is no Hook to run!\n"); return false end
	
	--If our command sends data, then we need to receive the appropriate type of data.
	--We'll pass this onto the hook function.
	local hookArgs={};
	if command.Datatypes then
		for i=1,table.maxn(command.Datatypes) do
			local v=command.Datatypes[i];
			
			if v==1 then
				hookArgs[i]=msg:ReadLong();
			elseif v==2 then
				hookArgs[i]=msg:ReadChar();
			elseif v==3 then
				hookArgs[i]=msg:ReadShort();
			elseif v==4 then
				hookArgs[i]=msg:ReadFloat();
			elseif v==5 then
				hookArgs[i]=msg:ReadBool();
			elseif v==6 then
				hookArgs[i]=msg:ReadString();
			elseif v==7 then
				hookArgs[i]=msg:ReadEntity();
				if hookArgs[i]==nil then
					hookArgs[i]=NullEntity();
				end
			elseif v==8 then
				hookArgs[i]=msg:ReadVector();
			elseif v==9 then
				hookArgs[i]=msg:ReadAngle();
			elseif v==10 then
				local id=msg:ReadShort()+32768;
				hookArgs[i]=IF.Items:Get(id);
			elseif v==11 then
				local id=msg:ReadShort()+32768;
				hookArgs[i]=IF.Inv:Get(id);
			elseif v==12 then
				hookArgs[i]=msg:ReadChar()+128;
			elseif v==13 then
				hookArgs[i]=msg:ReadLong()+2147483648;
			elseif v==14 then
				hookArgs[i]=msg:ReadShort()+32768;
			end
		end
	end
	command.Hook(self,unpack(hookArgs));
end
IF.Items:ProtectKey("ReceiveNWCommand");




--Place networked commands here in the same order as in init.lua.
IF.Items:CreateNWCommand(ITEM,"ToInventory",ITEM.ToInventory,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"RemoveFromInventory",ITEM.ToVoid,{"bool","inventory"});
IF.Items:CreateNWCommand(ITEM,"TransferInventory",ITEM.TransInventory,{"inventory","inventory","short"});
IF.Items:CreateNWCommand(ITEM,"TransferSlot",ITEM.TransSlot,{"inventory","short","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerUse");
IF.Items:CreateNWCommand(ITEM,"PlayerHold");
IF.Items:CreateNWCommand(ITEM,"PlayerSendToInventory",nil,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerSendToWorld",nil,{"vector"});
IF.Items:CreateNWCommand(ITEM,"PlayerMerge",nil,{"item"});
IF.Items:CreateNWCommand(ITEM,"PlayerSplit",nil,{"int"});