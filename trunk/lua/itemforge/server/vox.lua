--[[
Itemforge Vox module 
SERVER

This module provide Vox, or voice sound effects, for Itemforge. It preloads sounds on clients and when called on the server plays sound effects on characters that all players can hear.
]]--
MODULE.Name="Vox";											--Our module will be stored at IF.Vox
MODULE.Disabled=false;										--Our module will be loaded

--These sounds will be played when PlayRandomSuccess is called. These are called when successful things (a combination works, found something lucky, etc) happen.
MODULE.SuccessSounds={
"vo/coast/odessa/male01/nlo_cheer01.wav",
"vo/coast/odessa/male01/nlo_cheer02.wav",
"vo/coast/odessa/male01/nlo_cheer03.wav",
"vo/coast/odessa/male01/nlo_cheer04.wav",
--[[
"vo/episode_1/c17/ba_hellyeah.wav",
"vo/episode_1/c17/ba_herewego.wav",
"vo/episode_1/c17/ba_nicework.wav",
"vo/episode_1/c17/ba_ohyeah01.wav",
"vo/episode_1/c17/ba_woo.wav",
"vo/episode_1/c17/ba_yeah01.wav",
"vo/episode_1/npc/male01/cit_kill01.wav",
"vo/episode_1/npc/male01/cit_kill03.wav",
"vo/episode_1/npc/male01/cit_kill04.wav",
"vo/episode_1/npc/male01/cit_kill06.wav",
"vo/episode_1/npc/male01/cit_kill07.wav",
"vo/episode_1/npc/male01/cit_kill08.wav",
"vo/episode_1/npc/male01/cit_kill19.wav",
"vo/episode_1/npc/male01/cit_kill20.wav",
]]--
"vo/k_lab/ba_itsworking01.wav",
"vo/k_lab/ba_nottoosoon01.wav",
"vo/k_lab/ba_thingaway01.wav",
"vo/npc/barney/ba_yell.wav",
"vo/npc/barney/ba_laugh03.wav",
"vo/k_lab2/ba_goodnews.wav",
"vo/npc/male01/fantastic01.wav",
"vo/npc/male01/finally.wav",
"vo/npc/male01/ok01.wav",
"vo/npc/male01/ok02.wav",
"vo/npc/male01/yeah02.wav"
}

--These sounds will be played when PlayRandomFailure is called. These are called when unsuccessful things (can't do something, something breaks or fails) happen.
MODULE.FailureSounds={
"vo/coast/odessa/male01/nlo_cubdeath01.wav",
"vo/coast/odessa/male01/nlo_cubdeath02.wav",
--[[
"vo/episode_1/c17/ba_areyoucrazy.wav",
"vo/episode_1/c17/ba_areyousure.wav",
"vo/episode_1/c17/ba_notrophy.wav",
"vo/episode_1/npc/male01/cit_alert_head06.wav",
"vo/episode_1/npc/male01/cit_alert_zombie05.wav",
"vo/episode_1/npc/male01/cit_evac_casualty01.wav",
]]--
"vo/k_lab/ba_cantlook.wav",
"vo/k_lab/ba_careful01.wav",
"vo/k_lab/ba_careful02.wav",
"vo/k_lab/ba_whatthehell.wav",
"vo/k_lab/ba_whoops.wav",
"vo/k_lab/br_tele_02.wav",
"vo/npc/barney/ba_damnit.wav",
"vo/npc/barney/ba_danger02.wav",
"vo/npc/barney/ba_ohshit03.wav",
"vo/npc/male01/gordead_ans01.wav",
"vo/npc/male01/gordead_ans02.wav",
"vo/npc/male01/gordead_ques10.wav",
"vo/npc/male01/gordead_ques14.wav",
"vo/npc/male01/no02.wav",
"vo/npc/male01/ohno.wav",
"vo/npc/male01/question05.wav",
"vo/npc/male01/question11.wav",
"vo/npc/male01/question12.wav",
"vo/npc/male01/question26.wav",
"vo/npc/male01/whoops01.wav"
}

--Initilize vox module
function MODULE:Initialize()
	Msg("Itemforge Vox: Precaching sounds...\n");
	--Precache success and failure vox
	for k,v in pairs(self.SuccessSounds) do
		util.PrecacheSound(v);
	end
	
	for k,v in pairs(self.FailureSounds) do
		util.PrecacheSound(v);
	end
end

--Play a success vox on a given player
function MODULE:PlayRandomSuccess(pl)
	--Player has to be alive.
	if !pl:Alive() then return end
	
	local n=math.random(1,table.maxn(self.SuccessSounds));
	pl:EmitSound(self.SuccessSounds[n],100,100);
end

--Play a failure vox on a given player
function MODULE:PlayRandomFailure(pl)
	--Player has to be alive.
	if !pl:Alive() then return end
	
	local n=math.random(1,table.maxn(self.FailureSounds));
	pl:EmitSound(self.FailureSounds[n],100,100);
end