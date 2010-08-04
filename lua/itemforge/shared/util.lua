--[[
Itemforge Utilities module
SERVER

This module has a few extra bits of functionality that don't belong elsewhere
]]--

MODULE.Name="Util";												--Our module will be stored at IF.Util
MODULE.Disabled=false;											--Our module will be loaded

--Lookup table for faster type comparisons
local StringToType={
	["boolean"]		=	1,
	["number"]		=	2,
	["string"]		=	3,
	["table"]		=	4,
	["function"]	=	5,
	["Vector"]		=   6,
	["Angle"]		=	7,
	["Entity"]		=   8,
	["Player"]		=   9
};

--These folders are not valid
local BadFolders={
	[".."]		= true,
	["."]		= true,
	[".svn"]	= true
};

--Vars related to File Cache and FileSend
local FileCache = {};
local FileSendInProgress = false;
local FileSendCurrentFile = "";
local FileSendCurrentChar = 0;
local FileSendTotalChars = 0;
local FileSendCharsPerTick = 230;
local FileSendPlayer = nil;

--Taskqueue class
local _TASKQUEUE = {};

--[[
* SHARED

Initilize util module
]]--
function MODULE:Initialize()
	IF.Base:RegisterClass(_TASKQUEUE,"TaskQueue");
end

--[[
* SHARED

Cleanup util module
]]--
function MODULE:Cleanup()
end

--[[
* SHARED

Used for checking arguments for errors.
Returns true if the parameter is a boolean or false otherwise
]]--
function MODULE:IsBoolean(vParam)
	return StringToType[type(vParam)] == 1;
end

--[[
* SHARED

Used for checking arguments for errors.
Returns true if the parameter is a number or false otherwise
]]--
function MODULE:IsNumber(vParam)
	return StringToType[type(vParam)] == 2;
end

--[[
* SHARED

Used for checking arguments for errors.
Returns true if the parameter is
	a number,
	above or equal to min,
	and below or equal to max

and false otherwise.
]]--
function MODULE:IsInRange(vParam,min,max)
	return !(StringToType[type(vParam)] != 2 || vParam < min || vParam > max);
end


--[[
* SHARED

Returns true if the parameter is a number and is greater than 0, and false otherwise.
]]--
function MODULE:IsPositive(vParam)
	return StringToType[type(vParam)] == 2 && vParam > 0;
end

--[[
* SHARED

Returns true if the parameter is a number and is less than 0, and false otherwise.
]]--
function MODULE:IsNegative(vParam)
	return StringToType[type(vParam)] == 2 && vParam < 0;
end

--[[
* SHARED

Returns true if the parameter is a string.
]]--
function MODULE:IsString(vParam)
	return StringToType[type(vParam)] == 3;
end

--[[
* SHARED

Takes a string (such as "rock") and a count of how many
of these things there are (such as 5).

If count is greater than 1:
	If no plural string was given, "s" is added to the end of the first string given
	("rocks" in our case), and then returned.
	
	If a plural string was given, that string is returned (such as "gravel").
]]--
function MODULE:Pluralize(strSingular,fCount,strPlural)
	return (fCount > 1 && (strPlural || strSingular.."s")) || strSingular;
end

--[[
* SHARED

Returns true if the parameter is a table, and false otherwise.
]]--
function MODULE:IsTable(vParam)
	return StringToType[type(vParam)] == 4;
end

--[[
* SHARED

Returns true if the parameter is a function, and false otherwise.
]]--
function MODULE:IsFunction(vParam)
	return StringToType[type(vParam)] == 5;
end

--[[
* SHARED

Returns true if the parameter is a vector, and false otherwise.
]]--
function MODULE:IsVector(vParam)
	return StringToType[type(vParam)] == 6;
end

--[[
* SHARED

Returns true if the parameter is an angle, and false otherwise.
]]--
function MODULE:IsAngle(vParam)
	return StringToType[type(vParam)] == 7;
end

--[[
* SHARED

Returns true if the given param is a player.
]]--
function MODULE:IsPlayer(vParam)
	return StringToType[type(vParam)] == 9;	
end

--[[
* SHARED
Returns true if the given folder name is bad (e.g. goes upward in hierarchy or is
an svn folder)

This should be the name of a folder (such as "myfolder"), not a path (such as "itemforge/hello/myfolder").
]]--
function MODULE:IsBadFolder(strName)
	return BadFolders[strName]==true;
end

--[[
* SHARED

Converts from inches (also known as game units) to meters.
fInches is the number of inches.
]]--
function MODULE:InchesToMeters(fInches)
	return 0.0254 * fInches;
end

--[[
* SHARED

Converts from inches (also known as game units) to centimeters.
fInches is the number of inches.
]]--
function MODULE:InchesToCM(fInches)
	return 2.54 * fInches;
end

--[[
* SHARED

Converts from meters to inches (also known as game units).
fMeters is the number of meters.
]]--
function MODULE:MetersToInches(fMeters)
	return 39.3700787 * fMeters;
end

--[[
* SHARED

Converts from centimeters to inches (also known as game units).
fCM is the number of centimeters.
]]--
function MODULE:CMToInches(fCM)
	return 0.393700787 * fCM;
end

--[[
* SHARED

Converts from pounds to grams.
fPounds is the number of pounds.
NOTE: Pounds is a unit of weight, which is a force (mass * gravitational acceleration).
	  Grams is a unit of mass.
	  The conversion assumes that these are pounds in Earth's gravity (Earth's gravity is g = 9.81 m/(s^2)).
	  If these pounds were measured on a planet that had, say, 2 times the gravity of Earth,
	  you'd have to divide the pounds by 2 before passing it to this function.
]]--
function MODULE:PoundsToGrams(fPounds)
	return 453.59237 * fPounds;
end

--[[
* SHARED

Convert from grams to pounds.
fGrams is the number of grams.
NOTE: Pounds is a unit of weight, which is a force (mass * gravitational acceleration).
	  Grams is a unit of mass.
	  The conversion assumes that these are pounds in Earth's gravity (Earth's gravity is g = 9.81 m/(s^2)).
	  If you wanted pounds on a planet that had, say, 2 times the gravity of Earth,
	  you'd have to multiply the grams by 2 before passing it to this function.
]]--
function MODULE:GramsToPounds(fGrams)
	return 0.00220462262 * fGrams;
end

--[[
* SHARED

Given a single lua file, will generate a list of all files included by that file,
and those files' inclusions, and those files' inclusions, and so on.

strFilepath is the path of the .lua file to check for, relative to the garrysmod/ folder.
tIncludeList should be a table to store the file paths of included files in.
	strFilepath is guaranteed to be in tIncludeList.
	It's a good idea to make sure the table is empty before you pass it in, but
	this isn't necessary.
]]--
function MODULE:BuildIncludeList(strFilepath,tIncludeList)
	if FileCache[strFilepath] then ErrorNoHalt("Itemforge Util: Building include list failed - \""..strFilepath.."\" has already been included; possible include loop?\n"); return false end
	
	FileCache[strFilepath] = file.Read("../"..strFilepath);
	if FileCache[strFilepath] == nil then ErrorNoHalt("Itemforge Util: Building include list failed - couldn't read from \""..strFilepath.."\".\n"); return false end
	
	--Add this file to the list of included files now that we've verified it exists
	table.insert(tIncludeList,strFilepath);
	
	--We strip comment blocks and comment lines from the file here
	FileCache[strFilepath]=string.gsub(FileCache[strFilepath],"%-%-%[%[.-%]%]","");
	FileCache[strFilepath]=string.gsub(FileCache[strFilepath],"/%*.-%*/","");
	FileCache[strFilepath]=string.gsub(FileCache[strFilepath],"//.-\n","\n");
	FileCache[strFilepath]=string.gsub(FileCache[strFilepath],"%-%-.-\n","\n");
	
	local strDir = string.GetPathFromFilename(strFilepath);
	local ExpressionStart,IncludeStart,IncludeEnd,ExpressionEnd=0,0,0,0;
	
	--We'll keep looping until we can no longer find an include statement
	while true do
		--Start pattern explanation: Any amount of spacing, the word include, then any amount of spacing, plus an optional left parenthesis and then any amount of spacing followed by a single or double quote
		--Example: include ( "
		ExpressionStart,IncludeStart	= string.find(FileCache[strFilepath],"%s*include%s*%(?%s*[\"']",ExpressionEnd+1);
		if ExpressionStart==nil then return end

		--End pattern explanation: a single or double quote, then any amount of spacing, plus an optional right parenthesis, then any amount of spacing, then an optional ;.
		--Example: " )   ;
		IncludeEnd,ExpressionEnd		= string.find(FileCache[strFilepath],"[\"']%s*%)?%s*;?",IncludeStart+1);
		if IncludeEnd==nil then return end
		
		self:BuildIncludeList(strDir..string.sub(FileCache[strFilepath],IncludeStart+1,IncludeEnd-1),tIncludeList);
	end
end

--[[
* SHARED

Sets the contents of the given file (relative to the garrysmod/ folder)
This just affects the cache, not the actual file.
]]--
function MODULE:FileCacheSet(strFilepath,strContents)
	FileCache[strFilepath]=strContents;
end

--[[
* SHARED

Appends the given contents to the existing cached content
for the file with the given path (relative to the garrysmod/ folder)
]]--
function MODULE:FileCacheAppend(strFilepath,strContents)
	FileCache[strFilepath]=FileCache[strFilepath]..strContents;
end

--[[
* SHARED

Clears the file with the given path (relative to garrysmod/) out of the cache.
]]--
function MODULE:FileCacheClear(strFilepath)
	FileCache[strFilepath]=nil;
end

--[[
* SHARED

Returns the contents of the cached file with the given path (relative to garrysmod/)
Returns nil if the file is not cached.
]]--
function MODULE:FileCacheGet(strFilepath)
	return FileCache[strFilepath];
end

--[[
* SHARED

Returns true if there is a file cached under this name or false otherwise.
]]--
function MODULE:FileIsCached(strFilepath)
	return FileCache[strFilepath]!=nil;
end




if SERVER then




--[[
* SERVER

Sends the indicated file to the given player.
This function can't send a file if another file send is in progress.

strFilepath is the path of the file (starts in lua/)
pl is the player to send to. If this is nil/not given then sends to all players.

Returns true if the file send was started successfully or false otherwise.
]]--
function MODULE:FileSendStart(strFilepath,pl)
	if FileSendInProgress==true then return false end
	
	FileSendInProgress = true;
	FileSendPlayer = pl;
	FileSendCurrentFile = strFilepath;
	FileSendCurrentChar = 1;
	FileSendTotalChars = string.len(self:FileCacheGet(FileSendCurrentFile));

	IF.Network:ServerOut(IFN_MSG_FILESENDSTART,FileSendPlayer,FileSendCurrentFile,FileSendTotalChars);
	return true;
end

--[[
* SERVER

Sends the next part of the current file.
Returns true if there is still data to be sent.
Returns false if a file send is not in progress or the send has completed.
]]--
function MODULE:FileSendTick()
	if FileSendInProgress==false then return false end
	
	local LastChar=FileSendCurrentChar+FileSendCharsPerTick;
	local strFragment=string.sub(self:FileCacheGet(FileSendCurrentFile),FileSendCurrentChar,LastChar);
	FileSendCurrentChar=LastChar+1;
	
	IF.Network:ServerOut(IFN_MSG_FILESEND,FileSendPlayer,strFragment);
	
	if FileSendCurrentChar >= FileSendTotalChars then
		self:FileSendEnd();
		return false;
	end
	
	return true;
end

--[[
* SERVER

Called when the file has been completely sent.
Sends a message to the player telling him that the file has ended.
]]--
function MODULE:FileSendEnd()
	FileSendInProgress=false;
	self:FileCacheClear(FileSendCurrentFile);
	
	IF.Network:ServerOut(IFN_MSG_FILESENDEND,FileSendPlayer);
end




else




--[[
* CLIENT

Called when a file transfer has started
]]--
function MODULE:FileSendStart(strFilepath,iChars)
	FileSendInProgress = true;
	FileSendCurrentFile = strFilepath;
	FileSendCurrentChar = 0;
	FileSendTotalChars = iChars;
	
	self:FileCacheSet(FileSendCurrentFile,"");
end

--[[
* CLIENT

Called when a fragment of the file has been recieved
]]--
function MODULE:FileSendTick(strFragment)
	if FileSendInProgress==false then ErrorNoHalt("Itemforge Util: File fragment received but no file was being sent...\n"); return false end
	
	self:FileCacheAppend(FileSendCurrentFile,strFragment);
	FileSendCurrentChar = FileSendCurrentChar + string.len(strFragment);
	
	return true;
end

--[[
* CLIENT

Called after the file send has ended.
]]--
function MODULE:FileSendEnd()
	FileSendInProgress = false;
	if FileSendCurrentChar != FileSendTotalChars then ErrorNoHalt("Itemforge Util: File send ended but only transferred "..FileSendCurrentChar.." out of expected "..FileSendTotalChars.." characters.\n") end
end




end





--[[
* SHARED

Adds a new task to the back of the queue.
fTask should be a function that returns true when it is complete, and false when it's completed.
]]--
function _TASKQUEUE:Add(fTask)
	if self.Tasks==nil then self.Tasks={}; end
	
	for i=#self.Tasks,1,-1 do
		self.Tasks[i+1]=self.Tasks[i];
	end
	self.Tasks[1]=fTask;
end

--[[
* SHARED

Removes the current task from the queue.
]]--
function _TASKQUEUE:Remove()
	if self:IsEmpty() then return end
	self.Tasks[#self.Tasks]=nil;
end

--[[
* SHARED

Runs the current task.
Removes it if the task returns false to indicate the task has completed.
]]--
function _TASKQUEUE:Process()
	if self:IsEmpty() then return end
	if !self.Tasks[#self.Tasks]() then self:Remove(); end
end

--[[
* SHARED
Returns true if the task queue is empty
]]--
function _TASKQUEUE:IsEmpty()
	return self.Tasks==nil || #self.Tasks == 0;
end