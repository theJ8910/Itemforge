--[[
Itemforge Resources module 
SERVER

This makes clients download the necessary resources for Itemforge to work clientside, such as Lua files and materials for things like the UI, networking, or clientside effects.
The paths get a little funky here. Certain paths have to be relative to the data directory (stuff dealing with the file library),
or others are relative to lua directories in seperate places (for ex, garrysmod/lua on the server, but garrysmod/lua_temp on the client)
I've commented out a few example paths in the code to demonstrate what the path should look like in that format.

It's confusing for me too. That's why I wrote a module to handle it.
]]--

MODULE.Name				= "Resources";										--Our module will be stored at IF.Resources
MODULE.Disabled			= false;											--Our module will be loaded
MODULE.LuaFolder		= "addons/itemforge/lua/"							--Where's our Lua directory serverside?
MODULE.RelativeToData	= "../";											--Where is MODULE.ResourceFolder and MODULE.LuaFolder relative to the data folder?

--[[
* SERVER
* Event

Initilize resources module
]]--
function MODULE:Initialize()
end

--[[
* SERVER
* Event

Cleans up the resources module
]]--
function MODULE:Cleanup()
end

--[[
* SERVER

Recursively adds resources at the given path and all subfolders to the download list for clients.
]]--
function MODULE:AddResources( strPath )
	local strPathRelToData = self.RelativeToData..strPath;											--"../materials/itemforge/"
	local tFiles = file.Find( strPathRelToData.."*" );
	for k, v in ipairs( tFiles ) do
		if !IF.Util:IsBadFolder( v ) then
			if file.IsDir( strPathRelToData..v ) then	self:AddResources( strPath..v.."/");		--"materials/itemforge/inventory/"
			else										resource.AddFile( strPath..v );				--"materials/itemforge/icon.vtf" or "materials/itemforge/icon.vmt"
			end
		end
	end
end

--[[
* SERVER

Recursively adds all of the .lua files in the given path and all subfolders
]]--
function MODULE:AddCSLuaFiles( strPath )
	local strPathRelToData = self.RelativeToData..self.LuaFolder..strPath;							--"../addons/itemforge/lua/itemforge/shared/"
	local tFiles = file.FindInLua( strPath.."*" );
	for k, v in ipairs( tFiles ) do
		if !IF.Util:IsBadFolder( v ) then
			if file.IsDir( strPathRelToData..v ) then	self:AddCSLuaFiles( strPath..v.."/" );		--"itemforge/shared/somefolder/"
			else										AddCSLuaFile( strPath..v );					--"itemforge/shared/item.lua"
			end
		end
	end
end

--[[
* SERVER

I forget why this is here.
]]--
function MODULE:Reload()
	
end