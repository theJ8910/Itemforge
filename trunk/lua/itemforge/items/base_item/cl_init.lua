--[[
base_item
CLIENT

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/cl_init.lua, so this item's type is "base_item")
]]--
include("shared.lua");
include("events_client.lua");
ITEM.Icon=Material("editor/env_cubemap");			--This used to be displayed in item slots (and probably still could) but for now it's only used in the weapon selection menu by default.
ITEM.ThinkRate=0;									--Run think clientside every # of seconds set here. This can be set to 0 to think every frame.
ITEM.UseModelFor2D=true;							--If this is true, when displaying the item in an item slot, we'll create a model panel and display this item's world model in it. If this is false, no model panel is created.
ITEM.WorldModelNudge=Vector(0,0,0);					--The item's world model is shifted by this amount relative to the player's right hand. This is only used if this item's world model is a non-standard weapon model (doesn't have a "ValveBiped.Bip01_R_Hand" bone like the HL2 pistol, crowbar, smg, etc).
ITEM.WorldModelRotate=Angle(0,0,0);					--The item's world model is rotated by this amount relative to the player's right hand. This is only used if this item's world model is a non-standard weapon model (doesn't have a "ValveBiped.Bip01_R_Hand" bone like the HL2 pistol, crowbar, smg, etc).
ITEM.RCMenu=nil;									--Our right click menu (a DMenu).
ITEM.ItemSlot=nil;									--When the item is held, this will be a panel displaying this item.
ITEM.WorldModelAttach=nil;							--When the item is held, this will be an attached model (a GearAttach object specifically) attached to the player's right hand.
ITEM.OverrideMaterialMat=nil;						--On the client this is a Material() whose path is the item's override material (item:GetOverrideMaterial()). Use item:GetOverrideMaterialMat() to get this.

--[[
* CLIENT
* Protected

Transfer from one inventory to another.
This function is designed to save bandwidth.
Instead of sending two NWCommands, one to remove from an inventory, another to add to an inventory, only one NWCommand is run.
This function merely voids an item from the old inventory and inserts it into the new inventory.
True is returned if these operations were successful. False is returned otherwise.
]]--
function ITEM:TransInventory(old,new,newSlot)
	if !old || !old:IsValid()	then return self:Error("Could not transfer item from one inventory to another clientside, 'old' inventory given is not valid.\n") end
	if !new || !new:IsValid()	then return self:Error("Could not transfer item from "..tostring(old).." to another inventory clientside, 'new' inventory given is not valid.\n") end
	if newSlot==nil				then return self:Error("Could not transfer item from "..tostring(old).." to "..tostring(new).." clientside! newSlot was not given!\n") end
	
	if old!=new && !self:ToVoid(false,old,nil,false) then end
	if !self:ToInventory(new,newSlot,nil,nil,false) then return false end
end
IF.Items:ProtectKey("TransInventory");

--[[
* CLIENT
* Protected

Transfer from one slot to another.
This function is designed to save bandwidth.
True is returned if the move was successful. False is returned otherwise.
]]--
function ITEM:TransSlot(inv,oldslot,newslot)
	if !inv || !inv:IsValid() then return self:Error("Could not transfer item from one slot to another clientside, inventory given is not valid.\n") end
	if !inv:MoveItem(self,oldslot,newslot,false) then return false end
end
IF.Items:ProtectKey("TransSlot");

--[[
* CLIENT
* Protected

Run this function to use the item.
It will trigger the OnUse event in the item.
If this function is run on the client, the OnUse event can stop it clientside. If it isn't stopped, it requests to "PlayerUse" the item on the server.
False is returned if the item is unable to be used for any reason.

NOTE: If OnUse returns false clientside, "I can't use this!" does not appear, it simply stops the item from being used serverside.
TODO: Possibly have the item used by something other than a player
]]--
function ITEM:Use(pl)
	if !pl || !pl:IsValid() || !pl:IsPlayer() || !self:Event("CanPlayerInteract",false,pl) || !self:Event("OnUse",true,pl) then return false end
	
	--After the event allows the item to be used clientside, ask the server to use the item.
	self:SendNWCommand("PlayerUse");
	
	return true;
end
IF.Items:ProtectKey("Use");

--[[
* CLIENT
* Protected

Run this function to hold the item.
It requests to "Hold" the item on the server.
False is returned if the item is unable to be held for any reason.
]]--
function ITEM:PlayerHold(pl)
	if !pl || !pl:IsValid() || !pl:IsPlayer() || !self:Event("CanPlayerInteract",false,pl) then return false end
	
	self:SendNWCommand("PlayerHold");
	
	return true;
end
IF.Items:ProtectKey("PlayerHold");

--[[
* CLIENT
* Protected

This is run when the player chooses "Examine" from his menu.
Prints some info about the item (name, amount, weight, health, and description) to the local player's chat.
]]--
function ITEM:PlayerExamine()
	
	local amtstr="";
	if self:IsStack() then amtstr=" x "..self:GetAmount(); end
	
	local w=self:GetStackWeight();
	local weightstr;
	if w>=1000 then	weightstr=(w*0.001).." kg"
	else			weightstr=w.." grams"
	end
	
	
	
	
	LocalPlayer():PrintMessage(HUD_PRINTTALK,self:Event("GetName","Error")..amtstr);
	LocalPlayer():PrintMessage(HUD_PRINTTALK,"Total Weight: "..weightstr);
	local m=self:GetMaxHealth();
	if m!=0 then
		local h=self:GetHealth();
		LocalPlayer():PrintMessage(HUD_PRINTTALK,"Condition: "..math.Round((h/m)*100).."% ("..h.."/"..m..")");
	end
	LocalPlayer():PrintMessage(HUD_PRINTTALK,self:Event("GetDescription","[Error getting description]"));
end
IF.Items:ProtectKey("PlayerExamine");

--[[
* CLIENT
* Protected

Returns this item's override material as a Material() (as opposed to GetOverrideMaterial() which returns the material as a string).
]]--
function ITEM:GetOverrideMaterialMat()
	return self.OverrideMaterialMat;
end
IF.Items:ProtectKey("GetOverrideMaterialMat")

--[[
* CLIENT
* Protected

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
* CLIENT
* Protected

Displays this item's right click menu, positioning one of the menu's corners at x,y.
True is returned if the menu is opened successfully.
False is returned if the menu could not be opened. One possible reason this may happen is if the item's OnPopulateMenu event fails.
]]--
function ITEM:ShowMenu(x,y)
	self.RCMenu=DermaMenu();
	
	local name=self:Event("GetName","Itemforge Item");
	if self:IsStack() then name=name.." x "..self:GetAmount() end
	
	--Add header
	local h=vgui.Create("ItemforgeMenuHeader");
	h:SetText(name);
	self.RCMenu:AddPanel(h);
	
	local r,s=self:Event("OnPopulateMenu",nil,self.RCMenu);
	if !s then
		self.RCMenu:Remove();
		return false;
	end
	
	return self.RCMenu:Open(x,y);
end
IF.Items:ProtectKey("ShowMenu");

--[[
* CLIENT
* Protected

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

--[[
* CLIENT
* Protected

Opens a dialog window asking the player how evenly to split a stack of items.
pl should be LocalPlayer().

This function will return false if the player cannot interact with the item (or splitting this item is otherwise impossible).
]]--
function ITEM:PlayerSplit(pl)
	if !self:Event("CanPlayerInteract",false,pl) || !self:Event("CanPlayerSplit",true,pl) then return false end
	
	--Can't split 1 item
	local amt=self:GetAmount();
	if amt==1 then return false end
	
	local name=self:Event("GetName","Itemforge Item");
	
	local Window = vgui.Create("DFrame");
		Window:SetTitle("Split "..name);
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
* CLIENT
* Protected

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
	
	self:Event("OnTick");
end
IF.Items:ProtectKey("Tick");


local NIL="%%00";		--If a command isn't given, this is substituted. It means we want to send nil (nothing).
local SPACE="%%20";		--If a space is given in a string, this is substituted. It means " ".
	
--[[
* CLIENT
* Protected

Sends a networked command by name with the supplied arguments
Clientside, this runs console commands (sending data to the server in the process)
]]--
function ITEM:SendNWCommand(sName,...)
	local command=self.NWCommandsByName[sName];
	if command==nil			then return self:Error("Couldn't send command \""..sName.."\", there is no NWCommand with this name on this item!\n") end
	if command.Hook!=nil	then return self:Error("Command \""..command.Name.."\" can't be sent clientside. It has a hook, meaning this command is recieved clientside, not sent.\n") end
	
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
* CLIENT
* Protected

This function is called automatically, whenever a networked command from the server is received.
Clientside, msg will be a bf_read (a usermessage received from the server).
There's no need to override this, we'll call the hook the command is associated if there is one.
]]--
function ITEM:ReceiveNWCommand(msg)
	local commandid=msg:ReadChar()+128;
	local command=self.NWCommandsByID[commandid];
	
	if command==nil			then return self:Error("Couldn't find a NWCommand with ID "..commandid..". Make sure commands are created in the same order BOTH serverside and clientside.\n") end
	if command.Hook==nil	then return self:Error("Command \""..command.Name.."\" was received, but there is no Hook to run!\n") end
	
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
IF.Items:CreateNWCommand(ITEM,"ToInventory",function(self,inv,slot) self:ToInventory(inv,slot,nil,nil,false) end,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"RemoveFromInventory",function(self,forced,inv) self:ToVoid(forced,inv,nil,false) end,{"bool","inventory"});
IF.Items:CreateNWCommand(ITEM,"TransferInventory",function(self,oldinv,newinv,newslot) self:TransInventory(oldinv,newinv,newslot) end,{"inventory","inventory","short"});
IF.Items:CreateNWCommand(ITEM,"TransferSlot",function(self,oldinv,oldslot,newslot) self:TransSlot(oldinv,oldslot,newslot) end,{"inventory","short","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerUse");
IF.Items:CreateNWCommand(ITEM,"PlayerHold");
IF.Items:CreateNWCommand(ITEM,"PlayerSendToInventory",nil,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerSendToWorld",nil,{"vector","vector"});
IF.Items:CreateNWCommand(ITEM,"PlayerMerge",nil,{"item"});
IF.Items:CreateNWCommand(ITEM,"PlayerSplit",nil,{"int"});