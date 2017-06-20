--[[
Itemforge Serverside Init
SERVER

Runs the Itemforge shared.lua and adds cl_init.lua and shared.lua to the download list.
]]--

include( "itemforge/shared.lua" );
AddCSLuaFile( "itemforge/cl_init.lua" );
AddCSLuaFile( "itemforge/shared.lua" );

--Initialize itemforge serverside. This runs AFTER IF:Initialize() in shared.lua (so it's safe to reference itemforge modules here)
function IF:ServerInitialize()
	if self.Resources then
		self.Resources:AddResources( "materials/itemforge/" );
		
		--Recursively send client and shared modules to clients (TODO: Don't include disabled modules)
		self.Resources:AddCSLuaFiles( IF.SharedFolder );
		self.Resources:AddCSLuaFiles( IF.ClientFolder );
	end
	
	local cur = GetConVarString( "sv_tags" );
	if !string.find( cur, self.Tag ) then
		game.ConsoleCommand( "sv_tags "..cur..","..self.Tag.."\n" );
	end
end

--Send Full Update of all items and inventories to a connecting player
function IF:SendItemsAndInventories( pl )
	if self.Items	then self.Items:StartFullUpdateAll( pl )	end
	if self.Inv		then self.Inv:StartFullUpdateAll( pl )		end
	
	if self.Items	then self.Items:EndFullUpdateAll( pl )		end
	if self.Inv		then self.Inv:EndFullUpdateAll( pl )		end
end

--If a player leaves we need to cleanup private inventories
function IF:CleanupInvs(pl)
	if self.Inv then self.Inv:CleanupInvs(pl) end
end

hook.Add( "PlayerInitialSpawn", "itemforge_send_item_inv", function(pl) IF:SendItemsAndInventories(pl) end );
hook.Add( "PlayerDisconnected", "itemforge_cleanup_invs",  function(pl) IF:CleanupInvs(pl) end );