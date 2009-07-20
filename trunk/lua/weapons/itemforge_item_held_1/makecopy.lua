--[[
itemforge_item_held_1
SHARED

This file registers several copies of itemforge_item_held_1.
]]--
require("weapons");

--Make copies of itemforge_item_held_1
local copy={Base="itemforge_item_held_1"};  
for i=2,32 do
	local sClass="itemforge_item_held_"..i;
	if CLIENT then language.Add(sClass,"Item (held)"); end
	weapons.Register(copy,sClass,true);
end