-------------------------------------------------------------------------------
--
-- DON'T USE THIS API, IT'S OLD AND WILL BE REMOVED, THIS IS LEAVED HERE TO 
-- PROVIDE SUPPORT FOR OLD PROFILES
--
-------------------------------------------------------------------------------
-- TODO: Remove ALL this for old profile which until June 2019
local TMW 					= TMW
local CNDT 					= TMW.CNDT
local Env 					= CNDT.Env

local A 					= Action

local _G		 			= _G
local strmatch				= _G.strmatch	
local DEFAULT_CHAT_FRAME	= _G.DEFAULT_CHAT_FRAME 
local ChatEdit_SendText		= _G.ChatEdit_SendText or _G.ChatFrameEditBoxMixin.SendText
local isCallbackInitiated 	= false
_G.ptgroup 					= 3

function SystemToggles()   
    if _G.TellMeWhen_GlobalGroup3 and _G.TellMeWhen_GlobalGroup3:IsEnabled() then
        _G.LOSCheck 		= _G.TellMeWhen_GlobalGroup3_Icon1 and _G.TellMeWhen_GlobalGroup3_Icon1.Enabled
        _G.MSG_Toggle 		= _G.TellMeWhen_GlobalGroup3_Icon3 and _G.TellMeWhen_GlobalGroup3_Icon3.Enabled
        _G.Target_Toggle 	= _G.TellMeWhen_GlobalGroup3_Icon5 and _G.TellMeWhen_GlobalGroup3_Icon5.Enabled
    end    
end

local ProfileToggle = {    
    ["[GGL] Mage"] = function()    
        _G.purge_toggle 		= _G.TellMeWhen_Group3_Icon1.Enabled
        _G.dispel_toggle 		= _G.TellMeWhen_Group3_Icon3.Enabled
        _G.kick_toggle 			= _G.TellMeWhen_Group3_Icon5.Enabled
        _G.petattack_focus 		= _G.TellMeWhen_Group3_Icon7.Enabled
        _G.burst_toggle 		= _G.TellMeWhen_Group3_Icon9.Enabled
        _G.deff_toggle 			= _G.TellMeWhen_Group3_Icon11.Enabled
        _G.DragonRoar_toggle 	= _G.TellMeWhen_Group3_Icon13.Enabled
        _G.AoE_Toggle		 	= _G.TellMeWhen_Group3_Icon15.Enabled
		_G.MouseOver_Toggle 	= _G.TellMeWhen_Group3_Icon17.Enabled
    end,        
    ["[GGL] Druid"] = function()
        _G.MouseOver_Toggle 	= _G.TellMeWhen_Group3_Icon1.Enabled
        _G.dispel_toggle 		= _G.TellMeWhen_Group3_Icon3.Enabled
        _G.kick_toggle 			= _G.TellMeWhen_Group3_Icon5.Enabled
        _G.AoE_Toggle 			= _G.TellMeWhen_Group3_Icon7.Enabled
        _G.burst_toggle 		= _G.TellMeWhen_Group3_Icon9.Enabled
        _G.deff_toggle 			= _G.TellMeWhen_Group3_Icon11.Enabled
        _G.Soothe_toggle 		= _G.TellMeWhen_Group3_Icon13.Enabled
        _G.Thorns_toggle 		= _G.TellMeWhen_Group3_Icon15.Enabled 
        _G.HE_Pets 				= _G.TellMeWhen_Group3_Icon17.Enabled 
        if _G.TellMeWhen_Group3_Icon19.Enabled then
            _G.HE_Toggle = nil
        elseif _G.TellMeWhen_Group3_Icon20.Enabled then
            _G.HE_Toggle = "RAID"
        elseif _G.TellMeWhen_Group3_Icon21.Enabled then
            _G.HE_Toggle = "TANK"
        elseif _G.TellMeWhen_Group3_Icon22.Enabled then
            _G.HE_Toggle = "HEALER"
        elseif _G.TellMeWhen_Group3_Icon23.Enabled then
            _G.HE_Toggle = "DAMAGER"
        end
    end,    
    ["[GGL] Paladin"] = function()
        _G.MouseOver_Toggle 	= _G.TellMeWhen_Group3_Icon1.Enabled
        _G.dispel_toggle 		= _G.TellMeWhen_Group3_Icon3.Enabled
        _G.kick_toggle 			= _G.TellMeWhen_Group3_Icon5.Enabled
        _G.AoE_Toggle 			= _G.TellMeWhen_Group3_Icon7.Enabled
        _G.burst_toggle 		= _G.TellMeWhen_Group3_Icon9.Enabled
        _G.deff_toggle 			= _G.TellMeWhen_Group3_Icon11.Enabled
        _G.HoS_toggle 			= _G.TellMeWhen_Group3_Icon13.Enabled
        _G.HoF_toggle 			= _G.TellMeWhen_Group3_Icon15.Enabled 
        _G.BoP_toggle 			= _G.TellMeWhen_Group3_Icon17.Enabled 
        _G.HE_Pets 				= _G.TellMeWhen_Group3_Icon23.Enabled 
        -- FlashOfLight
        if _G.TellMeWhen_Group3_Icon19.Enabled then
            _G.FL_toggle = "ALL"
        elseif _G.TellMeWhen_Group3_Icon20.Enabled then
            _G.FL_toggle = "SELF"
        elseif _G.TellMeWhen_Group3_Icon21.Enabled then
            _G.FL_toggle = "PARTY"
        elseif _G.TellMeWhen_Group3_Icon22.Enabled then
            _G.FL_toggle = "OFF"
        end
        -- HealingEngine
        if _G.TellMeWhen_Group3_Icon25.Enabled then
            _G.HE_Toggle = nil
        elseif _G.TellMeWhen_Group3_Icon26.Enabled then
            _G.HE_Toggle = "RAID"
        elseif _G.TellMeWhen_Group3_Icon27.Enabled then
            _G.HE_Toggle = "TANK"
        elseif _G.TellMeWhen_Group3_Icon28.Enabled then
            _G.HE_Toggle = "HEALER"
        elseif _G.TellMeWhen_Group3_Icon29.Enabled then
            _G.HE_Toggle = "DAMAGER"
        end
        -- Beacon of Faith
        if _G.TellMeWhen_Group3_Icon31.Enabled then
            _G.BoF_Toggle = "SELF"
        elseif _G.TellMeWhen_Group3_Icon32.Enabled then
            _G.BoF_Toggle = "TANK"
        elseif _G.TellMeWhen_Group3_Icon33.Enabled then
            _G.BoF_Toggle = "MARKED"
        else
            _G.BoF_Toggle = "OFF"            
        end
        -- Beacon of Light
        if _G.TellMeWhen_Group3_Icon37.Enabled then
            _G.BoL_Toggle = "SELF"
        elseif _G.TellMeWhen_Group3_Icon38.Enabled then
            _G.BoL_Toggle = "TANK"
        elseif _G.TellMeWhen_Group3_Icon39.Enabled then
            _G.BoL_Toggle = "MOSTINCDMG"
        elseif _G.TellMeWhen_Group3_Icon40.Enabled then
            _G.BoL_Toggle = "MARKED"
        else
            _G.BoL_Toggle = "OFF"            
        end
        _G.BlindingLight_Toggle = _G.TellMeWhen_Group3_Icon43.Enabled
        _G.MasterAura_Toggle 	= _G.TellMeWhen_Group3_Icon45.Enabled
        _G.LayonHands_Toggle 	= _G.TellMeWhen_Group3_Icon47.Enabled
		_G.LOTM_Toggle			= _G.TellMeWhen_Group3_Icon49.Enabled
		_G.HL_Toggle			= _G.TellMeWhen_Group3_Icon51.Enabled
		_G.FoL_Toggle			= _G.TellMeWhen_Group3_Icon53.Enabled
		_G.HS_OnCD_Toggle		= _G.TellMeWhen_Group3_Icon55.Enabled
		_G.HS_DPS_Toggle		= _G.TellMeWhen_Group3_Icon57.Enabled
    end,
    ["[GGL] Demon Hunter"] = function()
        _G.MouseOver_Toggle 	= _G.TellMeWhen_Group3_Icon1.Enabled
        _G.dispel_toggle 		= _G.TellMeWhen_Group3_Icon3.Enabled
        _G.kick_toggle 			= _G.TellMeWhen_Group3_Icon5.Enabled
        _G.AoE_Toggle 			= _G.TellMeWhen_Group3_Icon7.Enabled
        _G.burst_toggle 		= _G.TellMeWhen_Group3_Icon9.Enabled
        _G.deff_toggle 			= _G.TellMeWhen_Group3_Icon11.Enabled
        _G.FelRush_Toggle 		= _G.TellMeWhen_Group3_Icon13.Enabled
        _G.VR_Toggle 			= _G.TellMeWhen_Group3_Icon15.Enabled 
        _G.Purje_toggle 		= _G.TellMeWhen_Group3_Icon17.Enabled
        -- Eye of Leotheras
        if _G.TellMeWhen_Group3_Icon19.Enabled then
            _G.EoL_Toggle = "ON CD"
        elseif _G.TellMeWhen_Group3_Icon20.Enabled then
            _G.EoL_Toggle = "ON ENEMY BURST"
        elseif _G.TellMeWhen_Group3_Icon21.Enabled then
            _G.EoL_Toggle = "ON TEAM DEFF"
        elseif _G.TellMeWhen_Group3_Icon22.Enabled then
            _G.EoL_Toggle = "MARKED"
        else
            _G.EoL_Toggle = "OFF"            
        end
        -- Rain From Above 
        if _G.TellMeWhen_Group3_Icon25.Enabled then
            _G.Rain_Toggle = "ON CD"
        elseif _G.TellMeWhen_Group3_Icon26.Enabled then
            _G.Rain_Toggle = "ON ENEMY BURST"
        elseif _G.TellMeWhen_Group3_Icon27.Enabled then
            _G.Rain_Toggle = "ON TEAM DEFF"
        else
            _G.Rain_Toggle = "OFF"            
        end
        -- Use Darkness and Imprison to DeffT
        _G.DeffTeam_Toggle 		= _G.TellMeWhen_Group3_Icon29.Enabled
        -- Chaos Nova, Fel Eruption, Imprison
        _G.UseCC_Toggle 		= _G.TellMeWhen_Group3_Icon31.Enabled
        -- Facing
        _G.Facing_Toggle 		= _G.TellMeWhen_Group3_Icon33.Enabled
        -- Mana Rift
        if _G.TellMeWhen_Group3_Icon35.Enabled then
            _G.ManaRift_Toggle = "HEALER"
        else
            _G.ManaRift_Toggle = "EVERYONE"
        end
    end,    
    ["[GGL] Death Knight"] = function()
        _G.MouseOver_Toggle 	= _G.TellMeWhen_Group3_Icon1.Enabled
        _G.burst_toggle 		= _G.TellMeWhen_Group3_Icon3.Enabled
        _G.kick_toggle 			= _G.TellMeWhen_Group3_Icon5.Enabled
        _G.AoE_Toggle 			= _G.TellMeWhen_Group3_Icon7.Enabled
        _G.DS_Toggle 			= _G.TellMeWhen_Group3_Icon9.Enabled
        _G.Deff_Toggle 			= _G.TellMeWhen_Group3_Icon11.Enabled
        _G.DG_Toggle 			= _G.TellMeWhen_Group3_Icon13.Enabled
        _G.SM_Toggle 			= _G.TellMeWhen_Group3_Icon15.Enabled 
        _G.AMS_toggle 			= _G.TellMeWhen_Group3_Icon17.Enabled
        -- Simulacrum Cast Bars
        if _G.TellMeWhen_Group3_Icon19.Enabled then
            _G.Simulacrum_Toggle = "EVERYTHING"
        elseif _G.TellMeWhen_Group3_Icon20.Enabled then
            _G.Simulacrum_Toggle = "CHAIN CC"
        elseif _G.TellMeWhen_Group3_Icon21.Enabled then
            _G.Simulacrum_Toggle = "DEFF AGRESS"
        elseif _G.TellMeWhen_Group3_Icon22.Enabled then
            _G.Simulacrum_Toggle = "MARKED"
        else
            _G.Simulacrum_Toggle = "OFF" 
        end
        -- DeathGrip Cast Bars
        if _G.TellMeWhen_Group3_Icon25.Enabled then
            _G.DeathGrip_Toggle = "EVERYTHING"
        elseif _G.TellMeWhen_Group3_Icon26.Enabled then
            _G.DeathGrip_Toggle = "DEFF"
        elseif _G.TellMeWhen_Group3_Icon27.Enabled then
            _G.DeathGrip_Toggle = "BURST"
        else
            _G.DeathGrip_Toggle = "OFF" 
        end
        -- Use Anti-magic zone
        _G.DeffTeam_Toggle 		= _G.TellMeWhen_Group3_Icon29.Enabled
        -- Asphyxiate 
        _G.UseCC_Toggle 		= _G.TellMeWhen_Group3_Icon31.Enabled
        -- Pet
        _G.PetStun_Toggle 		= _G.TellMeWhen_Group3_Icon33.Enabled
        _G.PetDeff_Toggle 		= _G.TellMeWhen_Group3_Icon35.Enabled
        if _G.TellMeWhen_Group3_Icon37.Enabled then
            _G.PetAttack_Toggle = "TARGET"
        elseif _G.TellMeWhen_Group3_Icon38.Enabled then
            _G.PetAttack_Toggle = "FOCUS"
        else
            _G.PetAttack_Toggle = "OFF"
        end     
        -- Chains of Ice
        _G.Slow_Toggle 			= _G.TellMeWhen_Group3_Icon40.Enabled
        _G.Slow_Toggle_Focus 	= _G.TellMeWhen_Group3_Icon42.Enabled        
        -- MassGrip
        _G.MassGrip_Toggle 		= _G.TellMeWhen_Group3_Icon44.Enabled
        -- Army of Dead
        _G.Army_Toggle 			= _G.TellMeWhen_Group3_Icon46.Enabled
        -- PvP 
        _G.PvPCD_Toggle 		= _G.TellMeWhen_Group3_Icon48.Enabled
    end,         
    ["[GGL] Priest"] = function()
        _G.MouseOver_Toggle 		= _G.TellMeWhen_Group3_Icon1.Enabled
        _G.TargetTarget_Toggle 		= _G.TellMeWhen_Group3_Icon3.Enabled
        _G.AoE_Toggle 				= _G.TellMeWhen_Group3_Icon5.Enabled
        _G.Burst_Toggle 			= _G.TellMeWhen_Group3_Icon7.Enabled
        _G.SelfDeff_Toggle 			= _G.TellMeWhen_Group3_Icon9.Enabled
        _G.TeamDeff_Toggle 			= _G.TellMeWhen_Group3_Icon11.Enabled
        _G.Levitate_Toggle 			= _G.TellMeWhen_Group3_Icon13.Enabled
        _G.LeapofFaith_Toggle 		= _G.TellMeWhen_Group3_Icon15.Enabled 
        _G.SpellKick_Toggle 		= _G.TellMeWhen_Group3_Icon17.Enabled
        _G.Purje_Toggle 			= _G.TellMeWhen_Group3_Icon19.Enabled
        _G.Dispel_Toggle 			= _G.TellMeWhen_Group3_Icon21.Enabled
        _G.MassDispel_Toggle 		= _G.TellMeWhen_Group3_Icon23.Enabled
        _G.SPDispel_Toggle 			= _G.TellMeWhen_Group3_Icon25.Enabled
        _G.Kick_Toggle 				= _G.TellMeWhen_Group3_Icon27.Enabled
        _G.AngelicFeather_Toggle 	= _G.TellMeWhen_Group3_Icon29.Enabled
        _G.Opener_Toggle 			= _G.TellMeWhen_Group3_Icon34.Enabled
        _G.VampiricEmbrace_Toggle 	= _G.TellMeWhen_Group3_Icon36.Enabled
        -- Penance 
        if _G.TellMeWhen_Group3_Icon31.Enabled then 
            _G.Penance_Toggle = "BOTH"
        elseif _G.TellMeWhen_Group3_Icon32.Enabled then 
            _G.Penance_Toggle = "HEAL"
        else
            _G.Penance_Toggle = "DMG"
        end 
        -- HealingEngine
        -- HE-Absorb
        _G.HE_Absorb	 		= _G.TellMeWhen_Group3_Icon39.Enabled 
        -- HE-Pets 
        _G.HE_Pets 				= _G.TellMeWhen_Group3_Icon41.Enabled 
        -- HE-Toggle 
        if _G.TellMeWhen_Group3_Icon43.Enabled then
            _G.HE_Toggle = nil
        elseif _G.TellMeWhen_Group3_Icon44.Enabled then
            _G.HE_Toggle = "RAID"
        elseif _G.TellMeWhen_Group3_Icon45.Enabled then
            _G.HE_Toggle = "TANK"
        elseif _G.TellMeWhen_Group3_Icon46.Enabled then
            _G.HE_Toggle = "HEALER"
        elseif _G.TellMeWhen_Group3_Icon47.Enabled then
            _G.HE_Toggle = "DAMAGER"
        end
        -- Arena1-3 Kick Toggle
        if _G.TellMeWhen_Group3_Icon49.Enabled then
            _G.ArenaKick_Toggle = "EVERYTHING"
        elseif _G.TellMeWhen_Group3_Icon50.Enabled then
            _G.ArenaKick_Toggle = "CHAIN CC"
        elseif _G.TellMeWhen_Group3_Icon51.Enabled then
            _G.ArenaKick_Toggle = "AGRESSIVE"
        elseif _G.TellMeWhen_Group3_Icon52.Enabled then
            _G.ArenaKick_Toggle = "DEFENSIVE"
        else
            _G.ArenaKick_Toggle = "OFF"
        end
        -- Arena1-3 CC Toggle
        if _G.TellMeWhen_Group3_Icon54.Enabled then
            _G.ArenaCC_Toggle = "EVERYTHING"
        elseif _G.TellMeWhen_Group3_Icon55.Enabled then
            _G.ArenaCC_Toggle = "AGRESSIVE"
        elseif _G.TellMeWhen_Group3_Icon56.Enabled then
            _G.ArenaCC_Toggle = "DEFENSIVE"
        else
            _G.ArenaCC_Toggle = "OFF"
        end
        -- Use CC
        _G.CC_Toggle 				= _G.TellMeWhen_Group3_Icon58.Enabled
        -- Single Rotation Arena Check BreakAble CC
        _G.BreakAbleCheckCC_Toggle 	= _G.TellMeWhen_Group3_Icon60.Enabled
        _G.AtonementRenew_Toggle 	= _G.TellMeWhen_Group3_Icon62.Enabled
    end,
}
function LocalToggles()
    local current 		= TMW.db:GetCurrentProfile()
    local profile 		= strmatch(current, "Chesder")     
    Env.BasicRotation 	= current == "[GGL] Basic" or profile == "Chesder"
    Env.IsGGLprofile 	= strmatch(current, "GGL") == "GGL" 
    if ProfileToggle[current] and _G.TellMeWhen_Group3 then
		if not _G.TellMeWhen_Group3.Enabled then 
			DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable 3")
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		end 
        ProfileToggle[current]()
    end
end

local DeprecatedGroups = {
	["[GGL] Chat trigger"] = true,
	["[GGL] Anchor TOGGLES"] = true,
	["[GGL] System TOGGLES"] = true,
	["[GGL] Basic features"] = true,
	["[GGL] Hidden PvP Healer's Taunt"] = true,
}
local function UpdateChesderGroups()   
    local current 		= TMW.db:GetCurrentProfile() 
	local isOldProfile 	= ProfileToggle[current] and true 
    Env.BasicRotation 	= current == "[GGL] Basic"
    Env.IsGGLprofile 	= strmatch(current, "GGL") == "GGL" 
	A.IsOLDprofile 		= isOldProfile or Env.BasicRotation

	if isOldProfile then 
		for i = 1, 5 do
			DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global " .. i)
			ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		end   
		-- Enable Toggle if was disabled 
		if _G.TellMeWhen_GlobalGroup2_Icon1 and not _G.TellMeWhen_GlobalGroup2_Icon1.Enabled then
			DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global 2 1")
			ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		end
		-- Enable PvP / PvE switcher if was disabled 
		if _G.TellMeWhen_GlobalGroup3_Icon7 and not _G.TellMeWhen_GlobalGroup3_Icon7.Enabled then
			DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global 3 7")
			ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		end
	else 
		for i = 1, 5 do
			local group = _G["TellMeWhen_GlobalGroup" .. i]			
			if group and DeprecatedGroups[group.Name] then
				DEFAULT_CHAT_FRAME.editBox:SetText("/tmw disable global " .. i)
				ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
			end
		end   
	end        
    
    -- Clear history of slash commands
    DEFAULT_CHAT_FRAME.editBox:SetHistoryLines(1)
    DEFAULT_CHAT_FRAME.editBox:AddHistoryLine("")
end

local function HybridProfileLaunch()
    if _G.TellMeWhen_GlobalGroup3 then
        SystemToggles()
        LocalToggles() 
    end    
end 

local function UpdateAll()
	UpdateChesderGroups()
	HybridProfileLaunch()
	TMW:UnregisterCallback("TMW_SAFESETUP_COMPLETE", UpdateAll, "TMW_SAFESETUP_COMPLETE_ACTION_DEPRECATED")
	if not isCallbackInitiated then 
		TMW:RegisterCallback("TMW_ACTION_ENTERING", 				LocalToggles											)
		TMW:RegisterCallback("TMW_ACTION_ON_PROFILE_POST", 			UpdateAll      											)
		isCallbackInitiated = true 
	end 
end 

TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", 						UpdateAll, 	"TMW_SAFESETUP_COMPLETE_ACTION_DEPRECATED"	)	
TMW:RegisterCallback("TMW_ACTION_DEPRECATED_UPDATE_AFTER_REMOVE", 	UpdateAll												)

-- Used for debug 
function RunLocalToggles(profile)
    if ProfileToggle[current] and _G.TellMeWhen_Group3 and _G.TellMeWhen_Group3:IsEnabled() then
        ProfileToggle[current]()
    end 
end 