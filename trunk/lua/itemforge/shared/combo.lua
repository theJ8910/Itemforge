--[[
Itemforge Combinations module
SERVER

This module manages and defines item combinations.
]]--

MODULE.Name="Combo";											--Our module will be stored at IF.Combo
MODULE.Disabled=false;											--Our module will be loaded
MODULE.RegisteredCombos={};

--[[
* SHARED

Initilize combo module
]]--
function MODULE:Initialize()
end

--[[
* SHARED

Cleanup player inventory module
]]--
function MODULE:Cleanup()
end

--[[
* SHARED

]]--
function MODULE:SimpleCombo(sName,tIngredients,sResult)

end

--[[
* SHARED

]]--
function MODULE:DefineCombo(sName,fIsComboValid,fPerformCombo)

end