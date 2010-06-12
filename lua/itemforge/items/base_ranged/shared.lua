--[[
base_ranged
SHARED

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ranged has two purposes:
	It's designed to help you create ranged weapons easier. You just have to change/override some variables or replace some stuff with your own code.
	You can tell if an item is a ranged weapon (like a pistol or RPG) by checking to see if it inherits from base_ranged.
Some features the base_ranged has:
	Ammunition: 
		You can load base_ranged weapons with other items
		The primary/secondary attack consumes ammo from a clip you set (you can also set primary/secondary not to consume ammo)
		You can set how much ammo the primary/secondary consumes per shot
		You can specify how many clips you want your weapon to have (including none).
		You can specify what type of ammo goes in a clip and how much can be loaded into it at a given time (including no limit)
		If ammo is drag-dropped onto the item, it loads it with that ammo; if two or more clips use the same kind of ammo, then it will load whichever clip is empty first.
		A list of reload functions let you set up where the item looks for ammo when it reloads.
	Cooldowns:
		This is based off of base_weapon so you can set primary/secondary delay and auto delay
		You can set a reload delay
		You can set a "dry delay" for when the gun is out of ammo or underwater (for example, the SMG's primary has a 0.08 second cooldown, but if you're out of ammo, it has a 0.5 second cooldown instead)
	Other:
		The item's right click menu has several functions for dealing with ranged weapons; you can fire it's primary/secondary, unload clips, reload, etc, all from the menu.
		Wiremod can fire the gun's primary/secondary attack. It can also reload the gun, if there is ammo nearby.
		You can set whether or not you want the gun's primary/secondary to work underwater

TODO the base_ranged ammo will not be known to a connecting client; have it send that OnFullUpdate() or whatever
TODO non-singly reloading weapons must stop reloads when holstering during one
TODO wire reload needs to be auto like primary and secondary
]]--
include("findammo.lua");

ITEM.Name="Base Ranged Weapon";
ITEM.Description="This item is the base ranged weapon.\nItems used as ranged weapons, such as firearms, rocket launchers, etc, can inherit from this\nto make their creation easier.\n\nThis is not supposed to be spawned.";
ITEM.Base="base_weapon";

--Base Ranged Weapon
--[[
Ammo clips
Ranged Weapons almost always have ammunition that they're loaded with and use up.
The weapon holds the ammo in what we call a "clip". Itemforge loads it's guns with stacks of other items.
	Type determines what type of items can be loaded into this clip. Any item based off of this type of item will also work.
	Size determines how many "bullets" (or whatever type of ammo you're using) can fit inside of it at any time. If this is 0, the clip can hold as much ammo as you want.

So you might be wondering, "How do I make clips for my weapon?"
Luckily, I've taken the time to make some examples for you.

Most weapons, like the HL2 Pistol for example, only have one clip for bullets:
	ITEM.Clips={};
	ITEM.Clips[1]={Type="ammo_pistol",Size=18};
	ITEM.PrimaryClip=1;

Some weapons, like the HL2 SMG for example, have two clips; one for bullets, and another for grenades:
	ITEM.Clips={};
	ITEM.Clips[1]={Type="ammo_smg",Size=45};
	ITEM.Clips[2]={Type="ammo_smggrenade",Size=3};
	ITEM.PrimaryClip=1;
	ITEM.SecondaryClip=2;

Other weapons, like the HL2 Shotgun, only have one clip (for shotgun shells), but both the primary and secondary attack take shells from that clip.
Since it's the HL2 shotgun, the primary takes one 'bullet', but the secondary takes two 'bullets'.
	ITEM.Clips={};
	ITEM.Clips[1]={Type="ammo_buckshot",Size=6};
	ITEM.PrimaryClip=1;
	ITEM.PrimaryTakes=1;
	ITEM.SecondaryClip=1;
	ITEM.SecondaryTakes=2;

A few weapons don't use clips at all.
	ITEM.Clips={};
	ITEM.PrimaryClip=0;
	ITEM.SecondaryClip=0;
]]--
ITEM.Clips={};

ITEM.PrimaryClip=0;								--What clip does the primary draw ammo from? If this is 0, the primary doesn't use ammo.
ITEM.PrimaryTakes=1;							--How much ammo does the primary take per attack?
ITEM.PrimaryFiresUnderwater=true;				--Does the primary fire underwater?
ITEM.PrimaryFireSounds={						--When attacking with the primary mode, a random sound here plays
	Sound("weapons/pistol/pistol_fire3.wav")
};

ITEM.SecondaryClip=0;							--What clip does the secondary draw ammo from? If this is 0, the secondary doesn't use ammo.
ITEM.SecondaryTakes=1;							--How much ammo does the secondary take per attack?
ITEM.SecondaryFiresUnderwater=true;				--Does the secondary fire underwater?
ITEM.SecondaryFireSounds={						--When attacking with the secondary mode, a random sound here plays
	Sound("weapons/pistol/pistol_fire3.wav")
};

ITEM.ReloadsSingly=false;						--Do we reload like a shotgun (one 'bullet' at a time)?
ITEM.ReloadDelay=1.4333332777023;				--The gun pauses for this long after loading a fresh clip of ammo. If we ReloadSingly, the gun pauses for this long after each "bullet" is loaded.
ITEM.ReloadStartDelay=1;						--If we ReloadSingly, the gun pauses for this long before the first "bullet" is loaded.
ITEM.ReloadFinishDelay=1;						--If we ReloadSingly, the gun pauses for this long after the last "bullet" has been loaded.
ITEM.ReloadSounds={								--When ammo is loaded into any clip, a random sound here plays
	Sound("weapons/pistol/pistol_reload1.wav")
};

ITEM.DryFireDelay=0.5;								--If we try to fire and can't (out of ammo/underwater), when is the next time we can attack?
ITEM.DryFireSounds={								--If we try to fire and can't (out of ammo/underwater), a random sound here plays
	Sound("weapons/pistol/pistol_empty.wav")
};

ITEM.MuzzleName="muzzle";						--What's the name of the muzzle attachment point on the gun? If we're in the world, we'll shoot things from the muzzle (special effects, bullets, grenades, flechettes, whatever)

--Don't modify; these are set automatically
ITEM.MuzzleAP=nil;								--What attachment ID does the muzzle on the gun use (if any?)
ITEM.ReloadSource=nil;							--If we ReloadSingly, we have selected this stack to reload from.
ITEM.ReloadClip=nil;							--If we ReloadSingly, we are currently reloading this clip.

function ITEM:OnInit(owner)
	self.Clip={};
	self:StartThink();
end

--[[
When the player is holding it and tries to primary attack
]]--
function ITEM:OnSWEPPrimaryAttack()
	if !self:CanPrimaryAttack() || (self:IsHeld() && self:GetWOwner():KeyDownLast(IN_ATTACK) && !self:CanPrimaryAttackAuto()) then return false end
	
	if !self.PrimaryFiresUnderwater && self:GetWaterLevel()==3 then
		self:DryFire();
		
		return false;
	--If we use ammo check the clip
	elseif self.PrimaryClip!=0 then
		local ammo=self:GetAmmo(self.PrimaryClip);
		if !ammo || ammo:GetAmount()<self.PrimaryTakes then
			self:DryFire();
			
			return false;
		end
	end
	
	self:SetNextBoth(CurTime()+self:GetPrimaryDelay(),CurTime()+self:GetPrimaryDelayAuto());
	self:TakeAmmo(self.PrimaryTakes,self.PrimaryClip);
	self:PrimaryFireEffects();
	
	return true;
end

--[[
When the player is holding it and tries to secondary attack
]]--
function ITEM:OnSWEPSecondaryAttack()
	if !self:CanSecondaryAttack() || (self:IsHeld() && self:GetWOwner():KeyDownLast(IN_ATTACK2) && !self:CanSecondaryAttackAuto()) then return false end
	
	if !self.SecondaryFiresUnderwater && self:GetWaterLevel()==3 then
		self:DryFire();
		
		return false;
	--If the secondary uses ammo make sure we have enough
	elseif self.SecondaryClip!=0 then
		local ammo=self:GetAmmo(self.SecondaryClip);
		if !ammo || ammo:GetAmount()<self.SecondaryTakes then
			self:DryFire();
			return false;
		end
	end
	
	self:SetNextBoth(CurTime()+self:GetSecondaryDelay(),CurTime()+self:GetSecondaryDelayAuto());
	self:TakeAmmo(self.SecondaryTakes,self.SecondaryClip);
	self:SecondaryFireEffects();
	
	return true;
end

--[[
This function is called when:
	The player presses R to reload.
	The player right clicks the weapon and chooses "Reload"
	Wiremod triggers the "Reload" input
It locates nearby ammo and tells the gun to load it.
]]--
function ITEM:OnSWEPReload()
	if !self:CanReload() then return false end
	if self.ReloadsSingly then return self:StartReload(); end
	
	for i=1,table.getn(self.Clips) do
		local clipsize=self:GetClipSize(clip);
		local curAmmo=self:GetAmmo(clip);
		if clipsize==0 || !curAmmo || curAmmo:GetAmount()<clipsize then
			local getNearbyAmmo=function(self,item)
				return self:Load(item,i,nil,true);
			end
			
			if self:FindAmmo(getNearbyAmmo) then
				return true;
			end
		end
	end
	
	return false;
end

--[[
Loads a clip with the given item.
clip tells us which clip to load. If this is 0, we'll try to load it in any available clip.
item is the stack of ammo to load.
amt is an optional amount indicating how many items from the stack to transfer.
	If this is nil/not given, we'll try to load the whole stack (or we'll try to transfer as many as possible).
Returns false if it couldn't be loaded for some reason, and true if it could.
If bPredicted is:
	true, then the function is expected to be called on server and the client.
		What this means is that the server will not tell the player holding the weapon to play the reload sound; that client is expected to play it itself.
	false or not given, the server tells the client to play the reload sound.
]]--
function ITEM:Load(item,clip,amt,bPredicted)
	if !self:CanReload() then return false end
	
	if clip==nil then
		for i=1,table.getn(self.Clips) do
			if self:Load(item,i,amt,bPredicted) then return true end
		end
		return false;
	end
	
	if !self:CanLoadClipWith(item,clip) then return false end
	
	if bPredicted == nil then bPredicted = false end
	
	if SERVER then
		--How much ammo are we loading
		amt=math.Clamp(amt or item:GetAmount(),1,item:GetAmount());
		
		local clipSize=self:GetClipSize(clip);
		local currentAmmo=self:GetAmmo(clip);
		local isOldAmmo=false;
		
		
		--We don't have any ammo loaded
		if !currentAmmo then
			--We're loading too much ammo into our clip.
			if clipSize!=0 && amt>clipSize then
				item=item:Split(self.Clips[clip].Size,false);
				if !item then return false end
			end
		
		--We're loading more ammo of the same type
		elseif currentAmmo:GetType()==item:GetType() then
			if item:GetAmount()>amt then
				if !item:Transfer(amt,currentAmmo) then return false end
				isOldAmmo=true;
			else
				isOldAmmo=currentAmmo:Merge(item);
				if isOldAmmo==false then return false end
			end
		
		--We're loading in a different type of ammo; try to unload the clip to make room for it
		elseif !self:Unload(clip) then
			return false;
		end
		
		--[[
		When we are loading a clip with "new" ammo, meaning the clip was empty or the ammo in it was swapped out,
		we void the ammo. This is how Itemforge's guns are loaded with ammo.
		I could have given guns an inventory to hold their ammo but that would be somewhat pointless
		since it would only hold one item.
		]]--
		if isOldAmmo==false then
			--If we're only loading a few items from the stack, split them off and load them instead
			if item:GetAmount()>amt then
				item=item:Split(amt,false);
				if !item then return false end
			end
			
			if !item:ToVoid() then return false end
			
			item.OldMaxAmount=item:GetMaxAmount();
			item:SetMaxAmount(self.Clips[clip].Size);

			self.Clip[clip]=item;
			self:SendNWCommand("SetClip",nil,item,clip);
		end
		
		self:UpdateWireAmmoCount();
	end
	
	self:ReloadEffects(bPredicted);
	self:SetNextBoth(CurTime()+self:GetReloadDelay());
	
	return true;
end

--[[
If a player [USE]s this gun while holding some ammo (an item based off of base_ammo), we'll try to load this gun with it.
If the gun is used clientside, we won't actually load the gun, we'll just return true to indiciate we want the server to load the gun.
TODO check clips instead of checking for base_ammo
]]--
function ITEM:OnUse(pl)
	local wep=pl:GetActiveWeapon();
	if wep:IsValid() then
		local item=IF.Items:GetWeaponItem(wep);
		if item && item:InheritsFrom("base_ammo") && (CLIENT || self:Load(item) ) then
			return true;
		end
	end
	
	--We couldn't load whatever the gun with whatever the player was carrying, so just do the default OnUse
	return self["base_item"].OnUse(self,pl);
end





--[[
Plays a random sound for the primary fire.
Also plays the primary attack animation, both on the weapon and player himself
]]--
function ITEM:PrimaryFireEffects()
	if #self.PrimaryFireSounds>0 then self:EmitSound(self.PrimaryFireSounds,true); end
	
	if self:IsHeld() then
		self:GetWOwner():SetAnimation(PLAYER_ATTACK1);
		self:GetWeapon():SendWeaponAnim(self:GetPrimaryActivity());
	end
end

--[[
Returns the viewmodel activity to play when the primary is fired
]]--
function ITEM:GetPrimaryActivity()
	return ACT_VM_PRIMARYATTACK;
end


--[[
This function runs when the player fires the secondary successfully.
It plays the weapon's secondary fire sound.
It plays the secondary attack animation on both the player and the viewmodel.
]]--
function ITEM:SecondaryFireEffects()
	if #self.SecondaryFireSounds>0 then self:EmitSound(self.SecondaryFireSounds,true); end
	
	if self:IsHeld() then
		self:GetWOwner():SetAnimation(PLAYER_ATTACK2);
		self:GetWeapon():SendWeaponAnim(self:GetSecondaryActivity());
	end
end


--[[
Returns the viewmodel activity to play when the secondary is fired
]]--
function ITEM:GetSecondaryActivity()
	return ACT_VM_SECONDARYATTACK;
end




--[[
Returns true if we can reload right now.
The only time we can't reload is if the primary or secondary is cooling down;
That means we can't reload if we're already reloading, and we can't reload right after attacking with the primary/secondary.
]]--
function ITEM:CanReload()
	if !self:CanPrimaryAttack() || !self:CanSecondaryAttack() then return false end
	
	return true;
end

--[[
If we ReloadSingly, then this function is called whenever the gun is told to reload.
It returns true if we have started reloading, or false if we couldn't.
]]--
function ITEM:StartReload()
	if self:GetNWBool("InReload") then return false end
	
	--Determine what clip needs to be loaded and locate ammo for it
	for i=1,table.getn(self.Clips) do
		local clipsize=self:GetClipSize(i);
		local curAmmo=self:GetAmmo(i);
		if clipsize==0 || !curAmmo || curAmmo:GetAmount()<clipsize then
			local canUseAmmo=function(self,item)
				if self:CanLoadClipWith(item,i) then
					self.ReloadSource=item;
					self.ReloadClip=i;
					return true;
				end
				return false;
			end
			
			--If we found ammo for this clip, break
			if self:FindAmmo(canUseAmmo) then break; end
		end
	end
	
	--If we couldn't find any ammo then stop
	if self.ReloadSource==nil then return false end
	
	--Show shotgun shell (I'm not sure this even works? But it's in the modcode so uhh)
	local wep=self:GetWeapon();
	if wep then wep:SetBodygroup(1,0) end
	
	self:SetNWBool("InReload",true);
	self:SetNextBoth(CurTime()+self.ReloadStartDelay);
	return true;
end

--[[
If we ReloadSingly then this loads one bullet into a clip.
]]--
function ITEM:Reload()
	if !self:CanReload() then return false end
	
	local curAmmo=self:GetAmmo(self.ReloadClip);
	
	--If our ammo source disappeared or we're full we can stop
	--TODO clip holds unlimited ammo??
	if !self:GetNWBool("InReload") || (SERVER && (!self.ReloadSource || !self.ReloadSource:IsValid())) || (curAmmo && curAmmo:GetAmount()>=self:GetClipSize(self.ReloadClip)) then
		self:FinishReload();
	end
	
	--TODO if ammo is unloadable (ex can't split a shell from the stack) it keeps trying to reload; fix this
	if !self:Load(self.ReloadSource,self.ReloadClip,1,true) then return false end
	
	return true;
end

--[[
If we ReloadSingly, then this function is called when the gun is finished reloading (it's clip is full)
It returns true if we finished reloading successfully, or false otherwise.
]]--
function ITEM:FinishReload()
	self.ReloadSource=nil;
	self.ReloadClip=nil;
	
	--Hide shotgun shell (I'm not sure this even works? But it's in the modcode so uhh)
	local wep=self:GetWeapon();
	if wep then wep:SetBodygroup(1,1) end
	
	self:SetNWBool("InReload",false);
	self:SetNextBoth(CurTime()+self.ReloadFinishDelay);
	return true;
end

--[[
Plays a reload sound and plays the reload animation (both on the weapon and player himself).
]]--
function ITEM:ReloadEffects(bPredicted)
	if #self.ReloadSounds>0 then self:EmitSound(self.ReloadSounds,bPredicted); end
	
	local wep = self:GetWeapon();
	if !wep then return false end
	
	if self.ReloadsSingly then wep:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START) end
	wep:SendWeaponAnim(ACT_VM_RELOAD);
	self:GetWOwner():SetAnimation(PLAYER_RELOAD);
end

--[[
Returns the reload delay (this is how long it takes to reload a weapon).
The weapon cannot attack while reloading.
]]--
function ITEM:GetReloadDelay()
	return self.ReloadDelay;
end




--[[
This function runs when the player tries to fire, but the gun doesn't fire anything.
Typically, this runs when the gun is out of ammo or tries to fire underwater
It plays the weapon's dry-fire sound and plays the dry-fire viewmodel animation.
It also cools the weapon down; the length of the cooldown is determined by the dry-fire delay.
]]--
function ITEM:DryFire()
	if #self.DryFireSounds>0 then self:EmitSound(self.DryFireSounds,true); end
	if self:IsHeld() then
		self:GetWeapon():SendWeaponAnim(ACT_VM_DRYFIRE);
	end
	
	self:SetNextBoth(CurTime()+self:GetDryDelay());
end

--[[
Returns the dry-fire delay.
]]--
function ITEM:GetDryDelay()
	return self.DryFireDelay;
end




--[[
Returns the item in the given clip.
If that clip doesn't exist, or if nothing is loaded in it, returns nil.
]]--
function ITEM:GetAmmo(clip)
	if !self.Clip[clip] then return nil end
	if !self.Clip[clip]:IsValid() then self.Clip[clip]=nil; end
	return self.Clip[clip];
end

--[[
Returns false if:
	That given clip doesn't exist.
	No valid item was given.
	The item given is not the right type of ammo (for example, if we use "base_ammo", that means that "base_ammo" or anything that inherits from "base_ammo" works)
Returns true otherwise.
]]--
function ITEM:CanLoadClipWith(item,clip)
	--Don't bother loading if we don't use ammo in that clip or if it's the wrong type of ammo for that clip
	if !self.Clips[clip] || !item || !item:IsValid() || self==item || !item:InheritsFrom(self.Clips[clip].Type) then return false end
	
	return true;
end

--[[
Returns the size of the given clip (the number of 'bullets' it can hold).
Returns 0 if the clip can hold an unlimited amount of ammo.
Returns false if the clip doesn't exist.
]]--
function ITEM:GetClipSize(clip)
	if !self.Clips[clip] then return false end
	return self.Clips[clip].Size;
end





--[[
Returns how submerged the gun is in water, between 0 and 3.
If the item is held, we use the player to calculate water level.
If the item is in the world, we use the item's world entity to calculate water level.
Returns 0 if not submerged, returns 3 if fully submerged.
NOTE: The item is considered to be dry if it is in the void or in an inventory.
]]--
function ITEM:GetWaterLevel()
	if self:IsHeld() then
		return self:GetWOwner():WaterLevel();
	elseif self:InWorld() then
		return self:GetEntity():WaterLevel();
	end
	return 0;
end

--Returns the muzzle position; expects the item to be in the world
function ITEM:GetMuzzle(eEnt)
	if !self.MuzzleAP then		self.MuzzleAP=eEnt:LookupAttachment(self.MuzzleName) end
	if self.MuzzleAP!=0 then	return eEnt:GetAttachment(self.MuzzleAP);
	else						return {Pos=eEnt:GetPos(),Ang=eEnt:GetAngles()};
	end
end

IF.Items:CreateNWVar(ITEM,"InReload","bool",false,true,true);