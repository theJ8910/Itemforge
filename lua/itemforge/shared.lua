--[[
Itemforge Shared Init
SHARED

This file is the foundation of Itemforge. Version is stored here, and modules are loaded here.
The module loading is carried out here. Modules are loaded, then initialized. After that, client and server initilizations are performed respectively.
]]--
IF={};
IF.Version=0.17;							--Itemforge Version. Your items can use this if you want.
IF.Tag="itemforge_beta";					--Server Tag. Whenever a server is hosting Itemforge, this shows up next to the server's name in the "Tags" column of the Server Browser.
IF.Modules={};

--The following paths are relative to the lua/ folder.
IF.SharedFolder="itemforge/shared/";		--Shared modules will be loaded from here on both client and server and sent to clients.
IF.ServerFolder="itemforge/server/";		--Server modules will be loaded from here on the server
IF.ClientFolder="itemforge/client/";		--Client modules will be loaded from here on the client, and will be sent to clients by the server.

--Initialize Itemforge on both server and client. Load modules.
function IF:Initialize()
	--Register Itemforge modules
	self:RegisterModules()
	
	--Initialize Itemforge modules
	for k,v in pairs(self.Modules) do
		if v.Initialize then
			local s,r=pcall(v.Initialize,v);
			if !s then ErrorNoHalt("Itemforge: Couldn't initialize module "..v.Name..": "..r.."\n") end
		end
	end
	
	--Base needs to handle inheritance of registered types
	if IF.Base then IF.Base:DoInheritance(); end
	
	if IF.Items then IF.Items:SetItemTypeNWVarAndCommandIDs(); end
	
	--Call serverside or clientside initilization after initializing modules.
	if SERVER then	self:ServerInitialize()
	else			self:ClientInitialize() end
end

--Clean up itemforge. This will call every module's cleanup functions and set Itemforge's table to nil to garbage collect it.
function IF:Cleanup()
	for k,v in pairs(self.Modules) do
		if v.Cleanup then
			local s,r=pcall(v.Cleanup,v);
			if !s then ErrorNoHalt("Itemforge: Couldn't cleanup module "..v.Name..": "..r.."\n") end
		end
	end
	hook.Remove("Initialize","itemforge_initialize");
	Itemforge=nil;
end

--Include all lua files in the server, client, and/or shared folders. Register Itemforge modules.
function IF:RegisterModules()
	--Load shared modules. We'll look for lua files in the shared folder and include them both serverside and clientside.
	local SharedModules=file.FindInLua(self.SharedFolder.."*.lua");
	for k,v in pairs(SharedModules) do
		MODULE={};
		
		local s,r=pcall(include,self.SharedFolder..v);
		if !s then	ErrorNoHalt(r.."\n")
		else		self:RegisterModule(MODULE);
		end
		
		MODULE=nil;
	end
	
	--Load server modules. We'll look for lua files in the server folder and include them on the server.
	if SERVER then
		local ServerModules=file.FindInLua(self.ServerFolder.."*.lua");
		for k,v in pairs(ServerModules) do
			MODULE={};
			
			local s,r=pcall(include,self.ServerFolder..v);
			if !s then	ErrorNoHalt(r.."\n")
			else		self:RegisterModule(MODULE);
			end
			
			MODULE=nil;
		end
	else
		--Load client modules. We'll look for lua files in the client folder and include them on the client.
		local ClientModules=file.FindInLua(self.ClientFolder.."*.lua");
		for k,v in pairs(ClientModules) do
			MODULE={};
			
			local s,r=pcall(include,self.ClientFolder..v);
			if !s then	ErrorNoHalt(r.."\n")
			else		self:RegisterModule(MODULE);
			end
			
			MODULE=nil;
		end
	end
end

--Register a newly loaded Itemforge module (or don't register it if it's disabled)
function IF:RegisterModule(tModule)
	if tModule==nil then ErrorNoHalt("Itemforge Module Loader: Module to register was nil\n") return false
	elseif tModule.Name==nil then ErrorNoHalt("Itemforge Module Loader: Module to register has no .Name, cannot be registered\n") return false
	elseif tModule.Disabled==true then return false end
	
	self.Modules[tModule.Name]=tModule; --Modules sorted here to be initialized
	self[tModule.Name]=tModule;			--Modules placed here so they can be accessed in the code by name
end

hook.Add("Initialize","itemforge_initialize",function() IF:Initialize() end);