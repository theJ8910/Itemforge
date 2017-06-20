--[[
Itemforge Save/Load Module
SERVER

This module handles the saving and loading of things.
The Save/Load module uses "save tables".
Items or Inventories can be saved to or loaded from save tables.
Save tables can be saved to and loaded from text files, strings, SQL databases (locally and remote), single player saves, the duplicator, and more.

To save an item to a text file:
	local tSave = IF.Save:SaveItem( YourItem );
	IF.Save:SaveToFile( tSave, "myFileName.txt" );

To load an item from a text file:
	local tSave = IF.Save:LoadFromFile( "myFileName.txt" );
	local item =  IF.Save:LoadItem( tSave );
]]--

MODULE.Name			= "Save";										--Our module will be stored at IF.Save
MODULE.Disabled		= false;										--Our module will be loaded
MODULE.TextFileVer	= 1;											--When saving text files, we use this format version. When loading text files, the version of that text file must be less than or equal to this version. Versioning exists so older versions of Itemforge don't load newer text files, and so newer versions of Itemforge can load older text files.

--[[
* SERVER

Initilizes the save module
]]--
function MODULE:Initialize()
end

--[[
* SERVER

Cleans up the save module
]]--
function MODULE:Cleanup()
end

--[[
* SERVER

Takes an item and returns a table of data.
This table of data should be given to another function (ex: SaveAsText)

Returns a save table.
Returns false in case of errors.
]]--
function MODULE:SaveItem( iItem )
	if !iItem then ErrorNoHalt( "Itemforge Save/Load: Can't save item. No item was given.\n" ); return false end
	if !fSaveFunc then ErrorNoHalt( "Itemforge Save/Load: Couldn't save "..tostring( iItem )..". No fSaveFunc was given!\n" ); return false end
	
	local tDat = {};
	
	if iItem.NWVars then
		for k, v in pairs( iItem.NWVars ) do
			
		end
	end
	
	return tDat;
end

--[[
* SERVER

Creates a new item from a save table.

tDat should be a save table.
Returns the loaded item.
Returns false if the item could not be loaded.
]]--
function MODULE:LoadItem( tDat )
	local i = IF.Items:Create( tDat.ClassName );
	if !i then return false end			--No error description here because The IF.Items:Create() function will report specific errors in the case of a failure to create.
	
	return i;
end

--[[
* SERVER

Converts a save table into a string.
Returns the string, or false in case of errors.
]]--
function MODULE:SaveToString( tDat )
	local n = "\n";
	
	local strSave = self.TextFileVer..n;
	strSave = strSave..iItem.ClassName..n;
	
	local function fnTakeKV( k, v ) strSave = strSave..tostring( k ).."/"..tostring( v )..n end
	self:SaveItem( iItem, fnTakeKV );
end

--[[
* SERVER

Converts a string into a save table.
Returns the save table, or false in case of errors.
]]--
function MODULE:LoadFromString( str )
	local tLines = string.Explode( "\n", str );
	
	local iVer = tonumber( tLines[1] );
	if iVer == nil then ErrorNoHalt( "Itemforge Save/Load: Couldn't load item from text file. Missing format version!\n" ); return false end
	if iVer > self.TextFileVer then ErrorNoHalt( "Itemforge Save/Load: Couldn't load item from text file. The given text file is a newer format (version "..iVer..") than this version of Itemforge supports (versions "..self.TextFileVer.." and below)\n"); return false end
	
	local tDat = {};
	
	tDat.ClassName = tLines[2];
	if !tDat.ClassName then ErrorNoHalt( "Itemforge Save/Load: Couldn't load item from text file. The item-type was missing from the file!\n" ); return false end
	
	tDat.NWVars = {};
	
	local i = 3;
	while tLines[i] != nil do
		local iDelimiter = string.find( tLines[i], "/" );
		
		--tDat.NWVars[string.sub( tLines[i], 0, iDelimiter - 1 )] = string.sub( tLines[i], iDelimiter + 1 );
		print( "Would have loaded: ", tLines[i] );
		i = i + 1;
	end
end

--[[
* SERVER

Writes a save table to a text file.

tDat should be a save table.
strFilename should be a string containing the name of the text file to save.
	Text files are saved in the garrysmod/data directory.
	You cannot save outside of the garrysmod/data directory.
	However, you can save to a subdirectory in the data folder. Instead of "filename.txt":
		"subdir/filename.txt",
		"subdir1/subdir2/filename.txt",
		etc.
	Only .txt files may be saved, so remember to include that in sFilename.
		GOOD:	"myfile.txt"
		GOOD:	"player5/item5.txt"
		BAD:	"myitem"
		BAD:	"supercrowbar.itm"

Returns true if successful, and false in case of errors.
]]--
function MODULE:SaveToFile( tDat, strFilename )
	if !IF.Util:IsTable( tDat )			then ErrorNoHalt( "Itemforge Save/Load: Can't save item to text file. No item was given.\n" );										return false end
	if !IF.Util:IsString( strFilename ) then ErrorNoHalt( "Itemforge Save/Load: Can't save "..tostring( iItem ).." to text file. strFilename was not a valid string.\n");	return false end
	
	local strSave = self:SaveToString( tDat );
	
	file.Write( strFilename, strSave );
	return true;
end

--[[
* SERVER

Loads a save table from a text file.

strFilename should be the name of the file to load from.

Returns the save table, or nil in case of errors.
]]--
function MODULE:LoadFromFile( strFilename )
	if !IF.Util:IsString( strFilename ) then ErrorNoHalt( "Itemforge Save/Load: Can't load item from text file. strFilename was not a valid string.\n" ); return false end
	
	local str = file.Read( strFilename );
	if !str then ErrorNoHalt( "Itemforge Save/Load: Can't load item from text file \""..strFilename.."\". This file could not be read.\n" ); return false end
	
	local tDat = self:LoadFromString( str );
	
	return tDat;
end

--[[
* SERVER

Saves a save table to SQL.
Returns true if successful, false in case of errors.
]]--
function MODULE:SaveToSQL(tDat, strTableName )

end

--[[
* SERVER

Loads a save table from SQL.
Returns the save table if successful, and false in case of errors.
]]--
function MODULE:LoadFromSQL( strTableName )

end