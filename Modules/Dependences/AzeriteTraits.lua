--------------------------------------------------------------------------------------
-- AzeriteTraits is special written lib for The Action but can be used for any others
-- addons if will be replaced "A." and "TMW." API by regular provided from game 
-- This library does nothing if not exist required API and all returns will be unvalid
--------------------------------------------------------------------------------------
local _G, print, pairs, ipairs			= _G, print, pairs, ipairs
local TMW 								= _G.TMW 
local A 								= _G.Action 
local Listener							= A.Listener
local Lib 								= LibStub:NewLibrary("AzeriteTraits", 11)

if not Lib or not A or not TMW then 
	if A and A.BuildToC < 90001 then 
		A.Print("[Error] AzeriteTraits - Library wasn't initialized")
	else
		print("[Error] AzeriteTraits - wasn't initialized by Action (or TMW) and Library")
	end 
	
	return 
end 

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_HealingEngine, A_HealingEngineMembersALL, A_GetSpellDescription, ActiveUnitPlates

Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "ADDON_LOADED", function(addonName)
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit							= A.Unit
		A_HealingEngine					= A.HealingEngine
		A_HealingEngineMembersALL		= A_HealingEngine.GetMembersAll()
		A_GetSpellDescription			= A.GetSpellDescription
		ActiveUnitPlates				= A.MultiUnits:GetActiveUnitPlates()
		
		Listener:Remove("ACTION_EVENT_AZERITE_TRAITS", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------	 
	  
local wipe								= _G.wipe	  

local Enum								= _G.Enum
local Item								= _G.Item 
local C_SpellBook						= _G.C_SpellBook
local FindSpellOverrideByID 			= C_SpellBook and C_SpellBook.FindSpellOverrideByID or _G.FindSpellOverrideByID
local AzeriteEmpoweredItem 				= _G.C_AzeriteEmpoweredItem
local AzeriteEssence 					= _G.C_AzeriteEssence
local GetSpellName						 = _G.C_Spell and _G.C_Spell.GetSpellName or _G.GetSpellInfo
Lib.has_8_3_0							= A.BuildToC > 80205

local Data 								= {
	InventorySlots 						= { 1, 2, 3, 5 },
	Ranks 								= {},
	Essences 							= {
		Total 							= {},
		-- Also will be created if relative slot is used:
		-- Major		= {},
		-- MinorOne		= {},
		-- MinorTwo 	= {},
		-- MinorThree 	= {},
	},	
} 

local DataInventorySlots				= Data.InventorySlots
local DataRanks							= Data.Ranks
local DataEssences						= Data.Essences

local A_GetSpellInfo
local function GetInfoSpell(spellID)
	if not A_GetSpellInfo then 
		A_GetSpellInfo = A.GetSpellInfo
		return (A_GetSpellInfo and A_GetSpellInfo(spellID)) or GetSpellName(spellID)
	else
		return A_GetSpellInfo(spellID)
	end 
end 

local AzeriteEmpoweredItemIsHeartOfAzerothEquipped, AzeriteEmpoweredItemIsAzeriteEmpoweredItem, AzeriteEmpoweredItemGetAllTierInfo, AzeriteEmpoweredItemIsPowerSelected, AzeriteEmpoweredItemGetPowerInfo
if AzeriteEmpoweredItem then 
	AzeriteEmpoweredItemIsHeartOfAzerothEquipped,  AzeriteEmpoweredItemIsAzeriteEmpoweredItem,  AzeriteEmpoweredItemGetAllTierInfo,  AzeriteEmpoweredItemIsPowerSelected,  AzeriteEmpoweredItemGetPowerInfo = 
	AzeriteEmpoweredItem.IsHeartOfAzerothEquipped, AzeriteEmpoweredItem.IsAzeriteEmpoweredItem, AzeriteEmpoweredItem.GetAllTierInfo, AzeriteEmpoweredItem.IsPowerSelected, AzeriteEmpoweredItem.GetPowerInfo
end 

-------------------------------------------------------------------------------
-- Constances (spellID to assign or create actions, taken lowest ID)
-------------------------------------------------------------------------------
Lib.CONST = {
	--[[ Essences Used by All Roles - Passive]]
	VisionofPerfection				= 299368,
	ConflictandStrife				= 304017,	
	--[[ Essences Used by All Roles - Active]]
	ConcentratedFlame 				= 295373, 
	WorldveinResonance				= 295186, 
	RippleinSpace					= 302731, 
	MemoryofLucidDreams				= 298357, 
	--[[ Tank ]]
	AzerothsUndyingGift				= 293019, 
	AnimaofDeath					= 294926, 
	AegisoftheDeep					= 298168, 
	EmpoweredNullBarrier			= 295746, 
	SuppressingPulse				= 293031, 
	--[[ Healer ]]
	Refreshment						= 296197, 
	Standstill						= 296094, 
	LifeBindersInvocation			= 293032, 
	OverchargeMana					= 296072, 
	VitalityConduit					= 296230, 
	--[[ Damager ]]
	FocusedAzeriteBeam				= 295258, 
	GuardianofAzeroth				= 295840, 
	BloodoftheEnemy					= 297108, 
	PurifyingBlast					= 295337, 
	TheUnboundForce					= 298452, 
}

if Lib.has_8_3_0 then 
	--[[ Tank - Passive ]]
	Lib.CONST.TouchoftheEverlasting	= 295046	
	--[[ Essences Used by All Roles - Active]]
	Lib.CONST.ReplicaofKnowledge	= 312725
	--[[ Tank ]]
	Lib.CONST.VigilantProtector		= 310592	
	--[[ Healer ]]
	Lib.CONST.SpiritofPreservation	= 297375 
	Lib.CONST.GuardianShell			= 296036 
	--[[ Damager ]]
	Lib.CONST.MomentofGlory 		= 311203
	Lib.CONST.ReapingFlames		 	= 310690
end 

-------------------------------------------------------------------------------
-- Azerite Essences - Major and Minor
-------------------------------------------------------------------------------
local AzeriteEssenceGetMilestoneEssence, AzeriteEssenceGetMilestoneSpell, AzeriteEssenceGetEssenceInfo, AzeriteEssenceGetMilestones, EnumAzeriteEssence
if AzeriteEssence then 
	AzeriteEssenceGetMilestoneEssence, 	AzeriteEssenceGetMilestoneSpell,  AzeriteEssenceGetEssenceInfo,  AzeriteEssenceGetMilestones,  EnumAzeriteEssence =
	AzeriteEssence.GetMilestoneEssence, AzeriteEssence.GetMilestoneSpell, AzeriteEssence.GetEssenceInfo, AzeriteEssence.GetMilestones, Enum.AzeriteEssence
	DataEssences.GetMajorBySpellNameOnENG = {
		-- Taken lowest Azerite Essence ID
		--[[ Essences Used by All Roles - Passive]] 
		-- Vision of Perfection
		[GetSpellName(Lib.CONST.VisionofPerfection) or ""] 			= "Vision of Perfection", 
		-- Conflict and Strife
		[GetSpellName(Lib.CONST.ConflictandStrife) or ""] 			= "Conflict and Strife", 		
		--[[ Essences Used by All Roles - Active]]
		[GetSpellName(Lib.CONST.ConcentratedFlame) or ""] 			= "Concentrated Flame",
		[GetSpellName(Lib.CONST.WorldveinResonance) or ""] 			= "Worldvein Resonance",
		[GetSpellName(Lib.CONST.RippleinSpace) or ""] 				= "Ripple in Space", 
		[GetSpellName(Lib.CONST.MemoryofLucidDreams) or ""] 		= "Memory of Lucid Dreams",
		--[[ Tank ]]
		[GetSpellName(Lib.CONST.AzerothsUndyingGift) or ""] 		= "Azeroth's Undying Gift",
		[GetSpellName(Lib.CONST.AnimaofDeath) or ""] 				= "Anima of Death",
		[GetSpellName(Lib.CONST.AegisoftheDeep) or ""] 				= "Aegis of the Deep",
		[GetSpellName(Lib.CONST.EmpoweredNullBarrier) or ""] 		= "Empowered Null Barrier",
		[GetSpellName(Lib.CONST.SuppressingPulse) or ""] 			= "Suppressing Pulse", 
		--[[ Healer ]]
		[GetSpellName(Lib.CONST.Refreshment) or ""] 				= "Refreshment", 
		[GetSpellName(Lib.CONST.Standstill) or ""] 					= "Standstill", 
		[GetSpellName(Lib.CONST.LifeBindersInvocation) or ""] 		= "Life-Binder's Invocation", 
		[GetSpellName(Lib.CONST.OverchargeMana) or ""] 				= "Overcharge Mana", 
		[GetSpellName(Lib.CONST.VitalityConduit) or ""] 			= "Vitality Conduit", 
		--[[ Damager ]]
		[GetSpellName(Lib.CONST.FocusedAzeriteBeam) or ""] 			= "Focused Azerite Beam", 
		[GetSpellName(Lib.CONST.GuardianofAzeroth) or ""] 			= "Guardian of Azeroth", 
		[GetSpellName(Lib.CONST.BloodoftheEnemy) or ""] 			= "Blood of the Enemy", 
		[GetSpellName(Lib.CONST.PurifyingBlast) or ""] 				= "Purifying Blast", 
		[GetSpellName(Lib.CONST.TheUnboundForce) or ""] 			= "The Unbound Force", 
	}
	DataEssences.IsPassive = {
		-- Checking by spellID which converts to spellName (it's more stable than ID because ID can be changed by Rank and Spec)
		-- Vision of Perfection
		[GetSpellName(Lib.CONST.VisionofPerfection) or ""] 			= true, 
		-- Conflict and Strife
		[GetSpellName(Lib.CONST.ConflictandStrife) or ""]	 		= true, 
	}
	DataEssences.IsTalentPvP = {
		-- Death Knight: Unholy Command (Blood)
		[GetSpellName(202727) or ""] 								= true,
		[202727] 													= true,
		-- Death Knight: Chill Streak (Frost)
		[GetSpellName(204160) or ""] 								= true,
		[204160]													= true,
		-- Death Knight: Necrotic Strike (Unholy)
		[GetSpellName(223829) or ""] 								= true,
		[223829]													= true,
		-- Demon Hunter: Demonic Origins (Vengance)
		[GetSpellName(235893) or ""] 								= true,
		[235893]													= true,
		-- Demon Hunter: Cleansed by Flame (Havoc)
		[GetSpellName(205625) or ""]								= true,
		[205625] 													= true,
		-- Druid: Thorns (Balance / Feral)
		[GetSpellName(236696) or ""]								= true,
		[236696] 													= true,
		-- Druid: Sharpened Claws (Guardian)
		[GetSpellName(202110) or ""]								= true,
		[202110] 													= true,
		-- Druid: Overgrowth (Restoration)
		[GetSpellName(203651) or ""]								= true,
		[203651] 													= true,
		-- Hunter: Hi-Explosive Trap (Beast Mastery / Marksmanship / Survival)
		[GetSpellName(236776) or ""]								= true,
		[236776] 													= true,
		-- Mage: Temporal Shield (Arcane / Frost / Fire)
		[GetSpellName(198111) or ""]								= true,
		[198111] 													= true,
		-- Monk: Hot Trub (Brewmaster)
		[GetSpellName(202126) or ""]								= true,
		[202126] 													= true,
		-- Monk: Way of the Crane (Mistweaver)
		[GetSpellName(216113) or ""]								= true,
		[216113] 													= true,
		-- Monk: Reverse Harm (Windwalker)
		[GetSpellName(287771) or ""]								= true,
		[287771] 													= true,
		-- Paladin: Divine Favor (Holy)
		[GetSpellName(210294) or ""]								= true,
		[210294] 													= true,
		-- Paladin: Steed of Glory (Protection)
		[GetSpellName(199542) or ""]								= true,
		[199542] 													= true,
		-- Paladin: Unbound Freedom (Retribution)
		[GetSpellName(199325) or ""]								= true,
		[199325] 													= true,
		-- Priest: Premonition (Discipline)
		[GetSpellName(209780) or ""]								= true,
		[209780] 													= true,
		-- Priest: Holy Ward (Holy)
		[GetSpellName(213610) or ""]								= true,
		[213610] 													= true,
		-- Priest: Void Shift (Shadow)
		[GetSpellName(108968) or ""]								= true,
		[108968] 													= true,
		-- Rogue: Maneuverability (Assassination / Outlaw / Subtlety)
		[GetSpellName(197000) or ""]								= true,
		[197000] 													= true,
		-- Shaman: Lightning Lasso (Elemental)
		[GetSpellName(204437) or ""]								= true,
		[204437] 													= true,
		-- Shaman: Thundercharge (Enhancement)
		[GetSpellName(204366) or ""]								= true,
		[204366] 													= true,
		-- Shaman: Ancestral Gift (Restoration)
		[GetSpellName(290254) or ""]								= true,
		[290254] 													= true,
		-- Warlock: Endless Affliction (Affliction)
		[GetSpellName(305391) or ""]								= true,
		[305391] 													= true,
		-- Warlock: Nether Ward (Demonology)
		[GetSpellName(212295) or ""]								= true,
		[212295] 													= true,
		-- Warlock: Demon Armor (Destruction)
		[GetSpellName(285933) or ""]								= true,
		[285933] 													= true,
		-- Warrior: Sharpen Blade (Arms)
		[GetSpellName(198817) or ""]								= true,
		[198817] 													= true,
		-- Warrior: Battle Trance (Fury)
		[GetSpellName(213857) or ""]								= true,
		[213857] 													= true,
		-- Warrior: Thunderstruck (Protection)
		[GetSpellName(199045) or ""]								= true,
		[199045] 													= true,		
	}

	if Lib.has_8_3_0 then 
		-- Expend GetMajorBySpellNameOnENG
		--[[ Essences Used by All Roles - Active]]
		DataEssences.GetMajorBySpellNameOnENG[GetSpellName(Lib.CONST.ReplicaofKnowledge) or ""] 	= "Replica of Knowledge"
		--[[ Tank ]]
		DataEssences.GetMajorBySpellNameOnENG[GetSpellName(Lib.CONST.VigilantProtector) or ""] 		= "Vigilant Protector"
		--[[ Healer ]]
		DataEssences.GetMajorBySpellNameOnENG[GetSpellName(Lib.CONST.SpiritofPreservation) or ""] 	= "Spirit of Preservation"
		DataEssences.GetMajorBySpellNameOnENG[GetSpellName(Lib.CONST.GuardianShell) or ""] 			= "Guardian Shell"
		--[[ Damager ]]
		DataEssences.GetMajorBySpellNameOnENG[GetSpellName(Lib.CONST.MomentofGlory) or ""] 			= "Moment of Glory"
		DataEssences.GetMajorBySpellNameOnENG[GetSpellName(Lib.CONST.ReapingFlames) or ""] 			= "Reaping Flames"
		
		-- Expend IsPassive
		DataEssences.IsPassive[GetSpellName(Lib.CONST.TouchoftheEverlasting) or ""] 				= true
	end 
end 

function DataEssences.GetInfo(milestone) 
	-- @return table (all info about milestone) or nil
	local essenceID 	= AzeriteEssenceGetMilestoneEssence(milestone.ID) 	
	if essenceID then 
		local spellInfo = AzeriteEssenceGetMilestoneSpell(milestone.ID)
		local info 		= AzeriteEssenceGetEssenceInfo(essenceID)
		if info and spellInfo then 
			local spellID = FindSpellOverrideByID(spellInfo)    
			local temp = {
				spellID = spellID,
				spellName = (GetInfoSpell(spellID)),
				essenceID = essenceID,							-- same info.ID
				milestoneID = milestone.ID,
				requiredLevel = milestone.requiredLevel,
				slot = milestone.slot, 							-- selected position in AzeriteEssenceUI
				--canUnlock = milestone.canUnlock,				-- bullshit
				Name = info.name, 								-- Name of Essence (not a spell) 
				Rank = info.rank, 
				Unlocked = info.unlocked, 						-- or milestone.unlocked?
				Valid = info.valid, 							-- what is it? (boolean)
				Icon = info.icon,
			}
			return temp 
		end 
	end 
end 

function DataEssences.Update() 
	-- Updates Major (1) and Minor (3) slots  
	DataEssences.Major 		= nil
	DataEssences.MinorOne 	= nil 
	DataEssences.MinorTwo 	= nil
	DataEssences.MinorThree	= nil
	wipe(DataEssences.Total)
	
	if AzeriteEssence and AzeriteEmpoweredItemIsHeartOfAzerothEquipped() then
		local milestones = AzeriteEssenceGetMilestones()
		for i, milestone in ipairs(milestones) do
			-- Enumerates each milestone with output table 'milestone' with keys: ID, requiredLevel, canUnlock, unlocked, slot
			if milestone.slot == EnumAzeriteEssence.MainSlot then
				DataEssences.Major = DataEssences.GetInfo(milestone)
				if DataEssences.Major then 
					DataEssences.Total[DataEssences.Major.spellName] = DataEssences.Major 
				end 
			elseif milestone.slot == EnumAzeriteEssence.PassiveOneSlot then 
				DataEssences.MinorOne = DataEssences.GetInfo(milestone)
				if DataEssences.MinorOne then 
					DataEssences.Total[DataEssences.MinorOne.spellName] = DataEssences.MinorOne 
				end 
			elseif milestone.slot == EnumAzeriteEssence.PassiveTwoSlot then 
				DataEssences.MinorTwo = DataEssences.GetInfo(milestone)
				if DataEssences.MinorTwo then 
					DataEssences.Total[DataEssences.MinorTwo.spellName] = DataEssences.MinorTwo 
				end
			elseif Lib.has_8_3_0 and milestone.slot == EnumAzeriteEssence.PassiveThreeSlot then 
				DataEssences.MinorThree = DataEssences.GetInfo(milestone)
				if DataEssences.MinorThree then 
					DataEssences.Total[DataEssences.MinorThree.spellName] = DataEssences.MinorThree 
				end
			end
			
			-- Break 
			if DataEssences.Major and DataEssences.MinorOne and DataEssences.MinorTwo and DataEssences.MinorThree then 
				break 
			end 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------
local AzeriteItems 
function Data.OnEvent()  	
	if not AzeriteItems then 
		AzeriteItems = {}
		for i = 1, #DataInventorySlots do
			AzeriteItems[DataInventorySlots[i]] = Item:CreateFromEquipmentSlot(DataInventorySlots[i])
		end
		Listener:Remove("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_LOGIN")
	end 
	
	wipe(DataRanks)    
	
	for slot, item in pairs(AzeriteItems) do
		if not item:IsItemEmpty() then
			local itemLoc = item:GetItemLocation()
			
			-- Azerite Empower
			if slot ~= 2 and AzeriteEmpoweredItemIsAzeriteEmpoweredItem(itemLoc) then
				local tierInfos = AzeriteEmpoweredItemGetAllTierInfo(itemLoc)
				for _, tierInfo in pairs(tierInfos) do
					for _, powerId in pairs(tierInfo.azeritePowerIDs) do
						if AzeriteEmpoweredItemIsPowerSelected(itemLoc, powerId) then
							local spellName = GetInfoSpell(AzeriteEmpoweredItemGetPowerInfo(powerId).spellID)							
							if not DataRanks[spellName] then
								DataRanks[spellName] = 1
							else
								DataRanks[spellName] = DataRanks[spellName] + 1
							end                                    
						end
					end
				end
			end
			
			-- Azerite Essence
			if slot == 2 and EnumAzeriteEssence then 
				DataEssences.Update() 
			end 
		end
	end       
end

-- Azerite Empower
if AzeriteEmpoweredItem then 
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_ENTERING_WORLD", 					Data.OnEvent)
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_EQUIPMENT_CHANGED", 				Data.OnEvent)
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_SPECIALIZATION_CHANGED", 			Data.OnEvent)
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "SPELLS_CHANGED", 							Data.OnEvent)
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_LOGIN", 							Data.OnEvent)
end 

-- Azerite Essence
if AzeriteEssence and EnumAzeriteEssence then	 
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_CHANGED", 				DataEssences.Update)
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_UPDATE", 				DataEssences.Update) 
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_ACTIVATED", 			DataEssences.Update)
	--Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_ACTIVATION_FAILED", 	DataEssences.Update)
end 

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
function Lib:IsLoaded()
	return AzeriteEmpoweredItem and AzeriteEssence and true
end 

function Lib:GetRank(spellID)
	-- @return number (0 - not existed or not selected)
	-- Note: Shared for both Azerite Empower and Azerite Essence
	local spellName = GetInfoSpell(spellID)
    local rank 		= DataRanks[spellName] or (DataEssences.Total[spellName] and DataEssences.Total[spellName].Rank)
    return rank and rank or 0
end 

function Lib:EssenceGet(spellID)
	-- @return table (with all available information about total essences in use) or nil
	return DataEssences.Total[GetInfoSpell(spellID)]
end 

function Lib:EssenceGetMajor()
	-- @return table (with all available information about Major slot) or nil 
	return DataEssences.Major
end 

function Lib:EssenceGetMajorBySpellNameOnENG(spellName)
	-- @return string (ENGLISH localization of equal spellName) or nil
	return DataEssences.GetMajorBySpellNameOnENG[spellName or ""]
end 

function Lib:EssenceIsMajorUseable(spellID) 
	-- @return boolean 
	if DataEssences.Major and DataEssences.Major.spellID then 
		return not DataEssences.IsPassive[DataEssences.Major.spellName] and not DataEssences.IsPassive[DataEssences.Major.Name] and (not spellID or self:EssenceHasMajor(spellID))
	end 
end 

function Lib:EssenceHasMajor(spellID)
	-- @return boolean 
	-- Note: Search by localized spellName, essenceName or spellID 
	if DataEssences.Major then 
		if DataEssences.Major.spellID == spellID then 
			return true 
		else 
			local spellName = GetInfoSpell(spellID)
			if DataEssences.Major.spellName == spellName or DataEssences.Major.Name == spellName then 
				return true 
			end 
		end 
	end 
end 

function Lib:EssenceHasMinor(spellID)
	-- @return boolean 
	-- Note: Search by localized spellName, essenceName or spellID 
	if (DataEssences.MinorOne and DataEssences.MinorOne.spellID == spellID) or (DataEssences.MinorTwo and DataEssences.MinorTwo.spellID == spellID) or (DataEssences.MinorThree and DataEssences.MinorThree.spellID == spellID) then 
		return true 
	else 
		local spellName = GetInfoSpell(spellID)
		if (DataEssences.MinorOne and (DataEssences.MinorOne.spellName == spellName or DataEssences.MinorOne.Name == spellName)) or (DataEssences.MinorTwo and (DataEssences.MinorTwo.spellName == spellName or DataEssences.MinorTwo.Name == spellName)) or (DataEssences.MinorThree and (DataEssences.MinorThree.spellName == spellName or DataEssences.MinorThree.Name == spellName)) then 
			return true 
		end 
	end  
end 

function Lib:EssencePredictHealing(MajorSpellNameENG, spellID, unitID, VARIATION)
	-- @return boolean (if can be used without overheal), number (amount of health restoring, in some cases it's percent @percent / in some clear numeric amount @direct)
	
	-- Exception penalty for low level units / friendly boss
    local UnitLvL = A_Unit(unitID):GetLevel()
    if (UnitLvL <= 0 or (UnitLvL > 0 and UnitLvL < A_Unit("player"):GetLevel() - 10)) and MajorSpellNameENG ~= "Anima of Death" and MajorSpellNameENG ~= "Vitality Conduit" then
        return true, 0
    end     
    
    -- Header
    local variation 		= (VARIATION and (VARIATION / 100)) or 1      
    local total 			= 0
    local DMG 				= A_Unit(unitID):GetDMG()
	local HPS 				= A_Unit(unitID):GetHEAL()     
    local HealthDeficit 	= -1 
        
    -- Spells
    if MajorSpellNameENG == "Concentrated Flame" then  
		-- @direct
		HealthDeficit	 	= A_Unit(unitID):HealthDeficit()		
		-- Multiplier (resets on 4th stack, each stack +100%)
		local multiplier 	= A_Unit(unitID):HasBuffsStacks(295378, true) + 1				
		local amount 		= A_GetSpellDescription(spellID)[1] * multiplier
		
		-- Additional +75% over next 6 sec 
		local additional = 0
		if self:GetRank(spellID) >= 2 then
			additional = amount * 0.75 * multiplier + (HPS * 6) - (DMG * 6)
		end 
		
        total = (amount + additional) * variation           
    end
	
	if MajorSpellNameENG == "Anima of Death" then 
		-- @percent 
		local HP		= A_Unit(unitID):HealthPercent()
		HealthDeficit 	= 100 - HP
			
		-- Passing (in case if something went wrong with nameplates)
		if not ActiveUnitPlates then 
			if HP > 80 then 
				return false, 0
			else
				return true, 0
			end 
		end 
		
		local rank 		= self:GetRank(spellID)
		-- HP in percent heal per unit 
		local hpperunit = rank >= 3 and 10 or 5
		-- HP limit (on which stop query)
		local hplimit 	= rank >= 3 and 50 or 25		
		local totalmobs = 0
		for _, unit in pairs(ActiveUnitPlates) do
			if A_Unit(unit):GetRange() <= 8 then
				totalmobs = totalmobs + 1
				total = totalmobs * hpperunit * variation 
				if total >= hplimit then                
					break            
				end        
			end
		end 	
	end 

	if MajorSpellNameENG == "Refreshment" then 
		local maxUnitHP 	= A_Unit(unitID):HealthMax()
		-- @direct
		HealthDeficit 		= maxUnitHP - A_Unit(unitID):Health()  
		-- The Well of Existence do search by name, TMW will do rest work 
		local amount 		= A_Unit("player"):AuraTooltipNumber(296136, "HELPFUL") 
		
		if amount < maxUnitHP * 0.15 then 
			-- Do nothing if it heal lower than 15% on a unit
			return false, 0				
		elseif amount >= maxUnitHP and A_Unit(unitID):HealthPercent() < 70 then 
			-- Or if we reached cap (?) 
			return true, 0 
		end 
		
		total = amount * variation
	end 
	
	if MajorSpellNameENG == "Vitality Conduit" then 
		-- @AoE 
		local amount 		= A_GetSpellDescription(spellID)[1]
		total 				= amount * variation
		
		local validMembers 	= A_HealingEngine.GetMinimumUnits(1, 5)
		if validMembers < 2 then 
			validMembers 	= 2
		end 
		
		local totalMembers 	= 0 
		if #A_HealingEngineMembersALL > 0 and validMembers >= 2 then 
			for i = 1, #A_HealingEngineMembersALL do
				if A_Unit(A_HealingEngineMembersALL[i].Unit):HealthMax() - A_HealingEngineMembersALL[i].AHP >= total then
					totalMembers = totalMembers + 1
				end
				if totalMembers >= validMembers then 
					return true, total * totalMembers
				end 
			end
		end
		
		return false, total * totalMembers
	end 
	
	if MajorSpellNameENG == "Spirit of Preservation" then 
		-- @direct  
		HealthDeficit	 	= A_Unit(unitID):HealthDeficit()
		local desc 			= A_GetSpellDescription(spellID)
		total 				= (desc[1] * variation) + A_Unit(unitID):GetIncomingHeals() + (HPS * desc[2]) - (DMG * desc[2])
	end 
	
	return HealthDeficit >= total, total
end   

function Lib:IsLearnedByConflictandStrife(spell)
	-- @return boolean (if spellName or spellID is learned by Major PvP essence)
	if self:EssenceHasMajor(self.CONST.ConflictandStrife) then -- Get 'Conflict and Strife' localized name 
		return DataEssences.IsTalentPvP[spell]
	end 	
end 

-------------------------------------------------------------------------------
-- Debug
-------------------------------------------------------------------------------
--[[ Example:
-- Get info (@table or @nil) about specified essence by spellID which converts to localized name  
/dump LibStub("AzeriteTraits"):EssenceGet(1245336)
-- Get info (@table or @nil) about Major 
/dump LibStub("AzeriteTraits"):EssenceGetMajor()
]]