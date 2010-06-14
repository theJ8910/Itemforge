--[[
Itemforge Resources module 
SERVER

This makes clients download the necessary resources for Itemforge to work clientside, such as Lua files and materials for things like the UI, networking, or clientside effects.
The paths get a little funky here. Certain paths have to be relative to the data directory (stuff dealing with the file library),
or others are relative to lua directories in seperate places (for ex, garrysmod/lua on the server, but garrysmod/lua_temp on the client)
I've commented out a few example paths in the code to demonstrate what the path should look like in that format.

It's confusing for me too. That's why I wrote a module to handle it.
]]--

MODULE.Name="Resources";										--Our module will be stored at IF.Resources
MODULE.Disabled=false;											--Our module will be loaded
MODULE.LuaFolder="addons/itemforge/lua/"						--Where's our Lua directory serverside?
MODULE.RelativeToData="../";									--Where is MODULE.ResourceFolder and MODULE.LuaFolder relative to the data folder?

--Initilize resources module
function MODULE:Initialize()
end

function MODULE:Cleanup()
end

--Add resources at the given path and all subfolders to the download list for clients
function MODULE:AddResources(path)
	local pathRelToData=self.RelativeToData..path;		--"../materials/itemforge/"
	local files=file.Find(pathRelToData.."*");
	for k,v in pairs(files) do
		if v!= ".svn" && v!=".." && v!="." then
			if file.IsDir(pathRelToData..v) then
				self:AddResources(path..v.."/");							--"materials/itemforge/inventory/"
			else
				resource.AddFile(path..v);									--"materials/itemforge/icon.vtf" or "materials/itemforge/icon.vmt"
			end
		end
	end
end

--Adds all of the .lua files in the given path and all subfolders
function MODULE:AddCSLuaFiles(path)
	local pathRelToData=self.RelativeToData..self.LuaFolder..path;			--"../addons/itemforge/lua/itemforge/shared/"
	local files=file.FindInLua(path.."*");
	for k,v in pairs(files) do
		if v!=".svn" && v!=".." && v!="." then
			if file.IsDir(pathRelToData..v) then
				self:AddCSLuaFiles(path..v.."/");
			else
				AddCSLuaFile(path..v);										--"itemforge/shared/item.lua"
			end
		end
	end
end

function MODULE:Reload()
	
end