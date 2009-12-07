--[[
item_passlock
SHARED

This item is a password lock. It attaches to doors. This is a new version of an item that was in RPMod v2.
]]--

ITEM.Name="Password Lock";
ITEM.Description="Instant security!\nThese keypads can attach to a door and permit or deny access by asking the user for a password.";
ITEM.Base="base_lock";
ITEM.Size=7;
ITEM.Weight=700;
ITEM.WorldModel="models/props_lab/keypad.mdl";
ITEM.ViewModel="models/weapons/v_fists.mdl";
ITEM.MaxHealth=500;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.AllowSound=Sound("buttons/button3.wav");
ITEM.DenySound=Sound("buttons/button2.wav");
ITEM.SetPassSound=Sound("buttons/combine_button5.wav");