local _G, error, type, pairs, table, next, select, math =
	  _G, error, type, pairs, table, next, select, math 
	  
local TMW 						= _G.TMW
local CNDT						= TMW.CNDT 
local Env 						= CNDT.Env
local SwingTimers 				= TMW.COMMON.SwingTimerMonitor.SwingTimers

local A   						= _G.Action	
local CONST 					= A.Const
local Listener					= A.Listener
local InstanceInfo				= A.InstanceInfo

local TeamCache					= A.TeamCache
local TeamCacheFriendly 		= TeamCache.Friendly
local TeamCacheFriendlyUNITs	= TeamCacheFriendly.UNITs
	  
local wipe 						= _G.wipe 
local huge 						= math.huge 	  
local math_max					= math.max 	  
local math_min					= math.min
local math_floor				= math.floor 
local tsort						= table.sort	  

local Enum 						= _G.Enum 
local PowerType 				= Enum.PowerType
local ManaPowerType 			= PowerType.Mana
local RagePowerType 			= PowerType.Rage
local FocusPowerType 			= PowerType.Focus
local EnergyPowerType 			= PowerType.Energy
local ComboPointsPowerType		= PowerType.ComboPoints
local RunicPowerPowerType 		= PowerType.RunicPower
local SoulShardsPowerType 		= PowerType.SoulShards
local LunarPowerPowerType 		= PowerType.LunarPower
local HolyPowerPowerType 		= PowerType.HolyPower
local MaelstromPowerType 		= PowerType.Maelstrom
local ChiPowerType 				= PowerType.Chi
local InsanityPowerType 		= PowerType.Insanity
local ArcaneChargesPowerType 	= PowerType.ArcaneCharges
local FuryPowerType 			= PowerType.Fury
local PainPowerType				= PowerType.Pain
local WarlockPowerBar_UnitPower = _G.WarlockPowerBar_UnitPower

local GetSpellInfo				= _G.GetSpellInfo
local InCombatLockdown			= _G.InCombatLockdown  
local issecure					= _G.issecure

local 	 UnitLevel,    UnitPower, 	 UnitPowerMax, 	  UnitStagger, 	  UnitAttackSpeed, 	  UnitRangedDamage,    UnitDamage, 	  UnitAura =
	  _G.UnitLevel, _G.UnitPower, _G.UnitPowerMax, _G.UnitStagger, _G.UnitAttackSpeed, _G.UnitRangedDamage, _G.UnitDamage, _G.UnitAura

local	 GetPowerRegen,    GetRuneCooldown,    GetShapeshiftForm, 	 GetCritChance,    GetHaste, 	GetMasteryEffect, 	 GetVersatilityBonus, 	 GetCombatRatingBonus =
	  _G.GetPowerRegen, _G.GetRuneCooldown, _G.GetShapeshiftForm, _G.GetCritChance, _G.GetHaste, _G.GetMasteryEffect, _G.GetVersatilityBonus, _G.GetCombatRatingBonus
	  
local 	 IsEquippedItem, 	IsStealthed, 	IsMounted, 	  IsFalling, 	IsSwimming,    IsSubmerged = 	  
	  _G.IsEquippedItem, _G.IsStealthed, _G.IsMounted, _G.IsFalling, _G.IsSwimming, _G.IsSubmerged 
	  
local 	 CancelUnitBuff, 	CancelSpellByName, 	  CombatLogGetCurrentEventInfo =
	  _G.CancelUnitBuff, _G.CancelSpellByName, _G.CombatLogGetCurrentEventInfo	  
	  
-- Bags / Inventory
local 	 GetContainerNumSlots, 	  GetContainerItemID, 	 GetInventoryItemID, 	GetItemInfoInstant,    GetItemCount, 	IsEquippableItem =	  
	  _G.GetContainerNumSlots, _G.GetContainerItemID, _G.GetInventoryItemID, _G.GetItemInfoInstant, _G.GetItemCount, _G.IsEquippableItem	 
	  
-- Totems
local GetTotemInfo				= _G.GetTotemInfo
local GetTotemTimeLeft			= _G.GetTotemTimeLeft	  

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_GetPing, A_GetGCD, A_GetCurrentGCD, A_GetSpellPowerCost, A_GetSpellPowerCostCache, A_GetSpellInfo

Listener:Add("ACTION_EVENT_PLAYER", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		A_Unit						= A.Unit		
		A_GetPing					= A.GetPing
		A_GetGCD					= A.GetGCD
		A_GetCurrentGCD				= A.GetCurrentGCD
		A_GetSpellPowerCost			= A.GetSpellPowerCost
		A_GetSpellPowerCostCache	= A.GetSpellPowerCostCache
		A_GetSpellInfo				= A.GetSpellInfo
		
		Listener:Remove("ACTION_EVENT_PLAYER", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------

-- [[ Retail ]]
local function sortByLowest(a, b) 
	return a < b	  
end

-------------------------------------------------------------------------------
-- Locals 
-------------------------------------------------------------------------------
local Data = {
	Stance = 0,
	TimeStampCasting = TMW.time,
	TimeStampMoving = 0,
	TimeStampStaying = TMW.time, 
	TimeStampFalling = 0,
	AuraStealthed = {
		["ROGUE"] = {
			11327, 					-- Vanish 
			115193, 				-- Vanish w/ Subterfuge Talent
			115192,					-- Subterfuge Buff
			185422,					-- Stealth from Shadow Dance
		},
		["DRUID"] = {
			--102543, 				-- Incarnation: King of the Jungle
			5215,					-- Prowl 			
		},
		Shadowmeld = 58984,
		MassInvisible = {
			32612, 
			110959, 
			198158,  
		},
	},
	AuraOnCombatMounted = {
		["PALADIN"] = {
			220509,					-- Divine Steed 
			221883, 
			221885,
			221886,
			221887,
			254471,
			254472,
			254473,
			254474,
			220504,					-- Silver Hand Charger
			220507,
		},
		["DRUID"] = {
			783,		 			-- Travel form 
			165962,					-- Druid Flight Form
		},
		["DEMONHUNTER"] = 131347,	-- Demon Hunter Glide
	},
	AuraBuffUnitCount = {},
	AuraDeBuffUnitCount = {},
	-- Shoot 
	AutoShootActive = false, 
	AutoShootNextTick = 0,
	IsShoot = GetSpellInfo(5019),
	-- Attack
	AttackActive = false,	
	-- Behind
	PlayerBehind = 0,
	PetBehind = 0,	
	-- Swap 
	isSwapLocked = false, 
	-- Items 
	CheckItems 	= {},	
	CountItems 	= {},	
	-- Bags 
	CheckBagsMaxN = 0,
	CheckBags	= {},
	InfoBags    = {},
	-- Inventory
	CheckInv 	= {},
	InfoInv 	= {},	
} 

local DataAuraStealthed				= Data.AuraStealthed
local DataAuraOnCombatMounted		= Data.AuraOnCombatMounted
local DataAuraBuffUnitCount			= Data.AuraBuffUnitCount
local DataAuraDeBuffUnitCount		= Data.AuraDeBuffUnitCount
local DataCheckItems				= Data.CheckItems
local DataCountItems				= Data.CountItems
local DataCheckBags					= Data.CheckBags
local DataInfoBags					= Data.InfoBags
local DataCheckInv					= Data.CheckInv
local DataInfoInv					= Data.InfoInv

function Data.logAura(...)
	local _, EVENT, _, SourceGUID, _, _, _, DestGUID, _, _, _, _, spellName, _, auraType = CombatLogGetCurrentEventInfo() 
	if EVENT == "SPELL_AURA_APPLIED" and SourceGUID == TeamCacheFriendlyUNITs.player then 
		if auraType == "DEBUFF" then 
			DataAuraDeBuffUnitCount[spellName] 	= (DataAuraDeBuffUnitCount[spellName] or 0) + 1
		else
			DataAuraBuffUnitCount[spellName] 	= (DataAuraBuffUnitCount[spellName] or 0) 	+ 1
		end 
	end 
	
	if EVENT == "SPELL_AURA_REMOVED" and SourceGUID == TeamCacheFriendlyUNITs.player then 
		if auraType == "DEBUFF" then 
			DataAuraDeBuffUnitCount[spellName] 	= math_max((DataAuraDeBuffUnitCount[spellName] or 0) - 1, 0)
		else 
			DataAuraBuffUnitCount[spellName] 	= math_max((DataAuraBuffUnitCount[spellName] or 0) 	- 1, 0)
		end 
	end 
end 

function Data.wipeAura()
	wipe(DataAuraBuffUnitCount)	
	wipe(DataAuraDeBuffUnitCount)	
end 

function Data.OnItemsUpdate()
	for tier_name, items in pairs(DataCheckItems) do 
		local count = 0
		for i = 1, #items do 
			if IsEquippedItem(items[i]) then 
				count = count + 1
			end 
		end 
		DataCountItems[tier_name] = count
	end 
end

function Data.UpdateStance()
	Data.Stance = GetShapeshiftForm()
end 

function Data.logAutoShootON()
	Data.AutoShootActive = true 
end 

function Data.logAutoShootOFF()
	Data.AutoShootActive = false 
	Data.AutoShootNextTick = 0 
end 

function Data.updateAutoShoot(...)
	local unitID, _, spellID = ... 
	if unitID == "player" and A.IamRanger and A_GetSpellInfo(spellID) == Data.IsShoot then 
		Data.AutoShootNextTick = TMW.time + UnitRangedDamage("player")
	end 
end 

function Data.logAttackON()
	Data.AttackActive = true 
end 

function Data.logAttackOFF()
	Data.AttackActive = false 
end 

function Data.logCast(...)
	if ... == "player" then 
		Data.TimeStampCasting = TMW.time 
	end 
end 

function Data.logBehind(...)
	local message = ...
	if message == SPELL_FAILED_NOT_BEHIND then 
		Data.PlayerBehind = TMW.time
	end 
	
	if message == ERR_PET_SPELL_NOT_BEHIND then 
		Data.PetBehind = TMW.time
	end 
end 

function Data.logLevel(...)
	local lvl = ... 
	if type(arg) ~= "number" then 
		lvl = UnitLevel("player")
	end 
	if lvl and lvl ~= A.PlayerLevel then 
		A.PlayerLevel = lvl
	end 
end 

function Data.logSwapLocked()
	Data.isSwapLocked = true 
end 

function Data.logSwapUnlocked()
	Data.isSwapLocked = false 
end 

function Data.logBag()
	local maxToCheck = Data.CheckBagsMaxN
	local checked	 = 0 
	wipe(DataInfoBags)

	if checked == maxToCheck then 
		return 
	end 
	
	local _, itemID, itemEquipLoc, itemClassID, itemSubClassID
	for i = 0, NUM_BAG_SLOTS do
		for j = 1, GetContainerNumSlots(i) do
			itemID = GetContainerItemID(i, j)
			if itemID then 
				_, _, _, itemEquipLoc, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID)
				for name, v in pairs(DataCheckBags) do 
					if (not v.itemID or v.itemID == itemID) and (not v.itemEquipLoc or v.itemEquipLoc == itemEquipLoc) and (not v.itemClassID or v.itemClassID == itemClassID) and (not v.itemSubClassID or v.itemSubClassID == itemSubClassID) and (v.isEquippableItem == nil or IsEquippableItem(itemID) == v.isEquippableItem) then 
						if not DataInfoBags[name] then 
							DataInfoBags[name] = {} 
						end 
						DataInfoBags[name].count 				= GetItemCount(itemID, nil, true) or 1
						DataInfoBags[name].itemID				= itemID
						
						checked 								= checked + 1
						if checked >= maxToCheck then 
							return 
						end 						
					end 
				end 
			end 		
		end
	end
end 

function Data.logInv()
	wipe(DataInfoInv)
	if not next(DataCheckInv) then 
		return 
	end 
	
	local _, itemID, itemEquipLoc, itemClassID, itemSubClassID
	for name, v in pairs(DataCheckInv) do 
		if v.slot then 
			itemID = GetInventoryItemID("player", v.slot)
			if itemID then 
				_, _, _, itemEquipLoc, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID)
				if (not v.itemID or v.itemID == itemID) and (not v.itemEquipLoc or v.itemEquipLoc == itemEquipLoc) and (not v.itemClassID or v.itemClassID == itemClassID) and (not v.itemSubClassID or v.itemSubClassID == itemSubClassID) and (v.isEquippableItem == nil or IsEquippableItem(itemID) == v.isEquippableItem) then 
					if not DataInfoInv[name] then 
						DataInfoInv[name] = {} 
					end 
					DataInfoInv[name].slot 					= v.slot
					DataInfoInv[name].itemID				= itemID
				end 
			end 
		else
			for i = 1, CONST.INVSLOT_LAST_EQUIPPED do 
				itemID = GetInventoryItemID("player", i)
				if itemID then 
					_, _, _, itemEquipLoc, _, itemClassID, itemSubClassID 	= GetItemInfoInstant(itemID)
					if (not v.itemID or v.itemID == itemID) and (not v.itemEquipLoc or v.itemEquipLoc == itemEquipLoc) and (not v.itemClassID or v.itemClassID == itemClassID) and (not v.itemSubClassID or v.itemSubClassID == itemSubClassID) and (not v.isEquippableItem or IsEquippableItem(itemID)) then 
						if not DataInfoInv[name] then 
							DataInfoInv[name] = {} 
						end 
						DataInfoInv[name].slot 					= i
						DataInfoInv[name].itemID				= itemID
						break 
					end 
				end 			
			end 
		end 
	end 
end 

Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_STARTED_MOVING", function()
	if Data.TimeStampMoving ~= TMW.time then 
		Data.TimeStampMoving = TMW.time 
		Data.TimeStampStaying = 0
	end 
end)

Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_STOPPED_MOVING", function()
	if Data.TimeStampStaying ~= TMW.time then 
		Data.TimeStampMoving = 0
		Data.TimeStampStaying = TMW.time 
	end 
end)

Listener:Add("ACTION_EVENT_PLAYER_AURA", "COMBAT_LOG_EVENT_UNFILTERED", 	Data.logAura)
Listener:Add("ACTION_EVENT_PLAYER_AURA", "PLAYER_ENTERING_WORLD", 			Data.wipeAura)

Listener:Add("ACTION_EVENT_PLAYER_SHOOT", "START_AUTOREPEAT_SPELL", 		Data.logAutoShootON)
Listener:Add("ACTION_EVENT_PLAYER_SHOOT", "STOP_AUTOREPEAT_SPELL", 			Data.logAutoShootOFF)
Listener:Add("ACTION_EVENT_PLAYER_SHOOT", "PLAYER_ENTERING_WORLD", 			Data.logAutoShootOFF)
Listener:Add("ACTION_EVENT_PLAYER_SHOOT", "UNIT_SPELLCAST_SUCCEEDED",		Data.updateAutoShoot)

Listener:Add("ACTION_EVENT_PLAYER_ATTACK", "PLAYER_ENTER_COMBAT", 			Data.logAttackON)
Listener:Add("ACTION_EVENT_PLAYER_ATTACK", "PLAYER_LEAVE_COMBAT", 			Data.logAttackOFF)
Listener:Add("ACTION_EVENT_PLAYER_ATTACK", "PLAYER_ENTERING_WORLD", 		Data.logAttackOFF)

Listener:Add("ACTION_EVENT_PLAYER_CAST", "UNIT_SPELLCAST_START", 			Data.logCast)
Listener:Add("ACTION_EVENT_PLAYER_CAST", "UNIT_SPELLCAST_CHANNEL_START", 	Data.logCast)

Listener:Add("ACTION_EVENT_PLAYER_ATTACK", "UI_ERROR_MESSAGE", 				Data.logBehind)

Listener:Add("ACTION_EVENT_PLAYER_LEVEL", "PLAYER_LEVEL_UP",				Data.logLevel)
Listener:Add("ACTION_EVENT_PLAYER_LEVEL", "PLAYER_ENTERING_WORLD", 			Data.logLevel)
Listener:Add("ACTION_EVENT_PLAYER_LEVEL", "PLAYER_LOGIN", 					Data.logLevel)

Listener:Add("ACTION_EVENT_PLAYER_SWAP_EQUIP", "ITEM_LOCKED", 				Data.logSwapLocked)
Listener:Add("ACTION_EVENT_PLAYER_SWAP_EQUIP", "ITEM_UNLOCKED", 			Data.logSwapUnlocked)
Listener:Add("ACTION_EVENT_PLAYER_SWAP_EQUIP", "MERCHANT_CLOSED", 			Data.logSwapUnlocked)

Listener:Add("ACTION_EVENT_PLAYER", "UPDATE_SHAPESHIFT_FORMS", 				Data.UpdateStance)
Listener:Add("ACTION_EVENT_PLAYER", "UPDATE_SHAPESHIFT_FORM", 				Data.UpdateStance)
Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_ENTERING_WORLD", 				Data.UpdateStance)
Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_LOGIN", 						Data.UpdateStance)

local function RecoveryOffset()
	return A_GetPing() + A_GetCurrentGCD()
end 

-------------------------------------------------------------------------------
-- API 
-------------------------------------------------------------------------------
A.Player = {
	UnitID = "player",
}

function A.Player:IsStance(x)
	-- @return boolean 
	return Data.Stance == x
end 

function A.Player:GetStance()
	-- @return number 
	--[[Number - one of following:
		All
		0 = humanoid form
		Druid
		1 = Bear Form
		2 = Cat Form
		3 = Travel Form / Aquatic Form / Flight Form (all 3 location-dependent versions of Travel Form count as Form 3)
		4 = The first known of: Moonkin Form, Treant Form, Stag Form (in order)
		5 = The second known of: Moonkin Form, Treant Form, Stag Form (in order)
		6 = The third known of: Moonkin Form, Treant Form, Stag Form (in order)
		Note: The last 3 are ordered. For example, if you know Stag Form only, it is form 4. If you know both Treant and Stag, Treant is 4 and Stag is 5. If you know all 3, Moonkin is 4, Treant 5, and Stag 6.
		Priest
		1 = Shadowform
		Rogue
		1 = Stealth
		2 = Vanish / Shadow Dance (for Subtlety rogues, both Vanish and Shadow Dance return as Form 1)
		Shaman
		1 = Ghost Wolf
	]]	
	return Data.Stance
end 

function A.Player:IsFalling()
	-- @return boolean (more accurate IsFalling function, which excludes jumps), number 
    if IsFalling() then         
        if Data.TimeStampFalling == 0 then 
            Data.TimeStampFalling = TMW.time 
        elseif TMW.time - Data.TimeStampFalling > 1.7 then 
            return true, TMW.time - Data.TimeStampFalling
        end         
    elseif Data.TimeStampFalling > 0 then  
        Data.TimeStampFalling = 0
    end 
    return false, 0
end

function A.Player:GetFalling()
	-- @return number 
	return select(2, self:IsFalling())
end 

function A.Player:IsMoving()
	-- @return boolean 
	return Data.TimeStampMoving ~= 0
end 

function A.Player:IsMovingTime()
	-- @return number (seconds) 
	return Data.TimeStampMoving == 0 and 0 or TMW.time - Data.TimeStampMoving
end 

function A.Player:IsStaying()
	-- @return boolean 
	return Data.TimeStampStaying ~= 0 
end 

function A.Player:IsStayingTime()
	-- @return number (seconds) 
	return Data.TimeStampStaying == 0 and 0 or TMW.time - Data.TimeStampStaying
end 

function A.Player:IsShooting()
	-- @return boolean 
	return Data.AutoShootActive
end 

function A.Player:GetSwingShoot()
	-- @return number
	if TMW.time <= Data.AutoShootNextTick then 
		return Data.AutoShootNextTick - TMW.time 
	end 
	return 0 
end 

function A.Player:IsAttacking()
	-- @return boolean 
	return Data.AttackActive
end 

function A.Player:IsBehind(x)
	-- @return boolean 
	-- Note: Returns true if player is behind the target since x seconds taken from the last ui message 
	return TMW.time > Data.PlayerBehind + (x or 2.5)
end 

function A.Player:IsBehindTime()
	-- @retun number 
	-- Note: Returns time since player behind the target 
	return TMW.time - Data.PlayerBehind
end 

function A.Player:IsPetBehind(x)
	-- @return boolean 
	-- Note: Returns true if pet is behind the target since x seconds taken from the last ui message 
	return TMW.time > Data.PetBehind + (x or 2.5)
end 

function A.Player:IsPetBehindTime()
	-- @return number 
	-- Note: Returns time since pet behind the target
	return TMW.time - Data.PetBehind
end 

function A.Player:IsMounted()
	-- @return boolean
	return IsMounted() and (not DataAuraOnCombatMounted[A.PlayerClass] or A_Unit(self.UnitID):HasBuffs(DataAuraOnCombatMounted[A.PlayerClass], true, true) == 0)
end 

function A.Player:IsSwimming()
	-- @return boolean 
	return IsSwimming() or IsSubmerged()
end 

function A.Player:IsStealthed()
	-- @return boolean 
	return IsStealthed() or (A.PlayerRace == "NightElf" and A_Unit(self.UnitID):HasBuffs(DataAuraStealthed.Shadowmeld, true, true) > 0) or (DataAuraStealthed[A.PlayerClass] and A_Unit(self.UnitID):HasBuffs(DataAuraStealthed[A.PlayerClass], true, true) > 0) or A_Unit(self.UnitID):HasBuffs(DataAuraStealthed.MassInvisible) > 0
end 

function A.Player:IsCasting()
	-- @return castName or nil 
	local castName, _, _, _, _, isChannel = A_Unit(self.UnitID):IsCasting()
	return not isChannel and castName or nil 
end 

function A.Player:IsChanneling()
	-- @return castName or nil 
	local castName, _, _, _, _, isChannel = A_Unit(self.UnitID):IsCasting()
	return isChannel and castName or nil 
end 

function A.Player:CastTimeSinceStart()
	-- @return number 
	-- Note: Returns seconds since any event which triggered start cast 
	return TMW.time - Data.TimeStampCasting
end 

function A.Player:CastRemains(spellID)
	-- @return number 
	return A_Unit(self.UnitID):IsCastingRemains(spellID)
end 

function A.Player:CastCost()
	-- @return number 
	-- Note: Real time value (it's not cached)
	local castName, _, _, _, spellID = A_Unit(self.UnitID):IsCasting()
	return castName and A_GetSpellPowerCost(spellID) or 0
end 

function A.Player:CastCostCache()
	-- @return number 
	local castName, _, _, _, spellID = A_Unit(self.UnitID):IsCasting()
	return castName and A_GetSpellPowerCostCache(spellID) or 0
end 

-- Auras
function A.Player:CancelBuff(buffName)
	-- @return nil 
	if not InCombatLockdown() or issecure() then 
		CancelSpellByName(buffName)	
		--[[
		for i = 1, huge do			
			local Name = UnitAura("player", i, "HELPFUL PLAYER")
			if Name then	
				if Name == buffName then 
					CancelUnitBuff("player", i, "HELPFUL PLAYER")								
				end 
			else 
				break 
			end 
		end ]]
	end
end 

function A.Player:GetBuffsUnitCount(...)
	-- @return number 
	-- Returns how much units are applied by buffs in vararg
	-- ... accepts spellID and spellName 
	local counter = 0
	
	local aura, auraType
	for i = 1, select("#", ...) do 
		aura = select(i, ...)
		
		auraType = type(aura) 
		if auraType == "number" then 
			aura = A_GetSpellInfo(aura)
		elseif auraType == "table" then 
			aura = aura:Info()
		end 
		
		aura = DataAuraBuffUnitCount[aura]
		if aura and aura > 0 then 
			counter = counter + 1
		end 
	end 

	return counter
end 

function A.Player:GetDeBuffsUnitCount(...)
	-- @return number 
	-- Returns how much units are applied by buffs in vararg
	-- ... accepts spellID, spellName and action object 
	local counter = 0
	
	local aura, auraType
	for i = 1, select("#", ...) do 
		aura = select(i, ...)
		
		auraType = type(aura) 
		if auraType == "number" then 
			aura = A_GetSpellInfo(aura)
		elseif auraType == "table" then 
			aura = aura:Info()
		end 
		
		aura = DataAuraDeBuffUnitCount[aura]
		if aura and aura > 0 then 
			counter = counter + 1
		end 
	end 
	
	return counter
end 

-- Retail: Totems 
function A.Player:GetTotemInfo(i)
	-- @return: haveTotem, totemName, startTime, duration, icon
	return GetTotemInfo(i)
end 

function A.Player:GetTotemTimeLeft(i)
	-- @return: number (timeLeft = GetTotemTimeLeft(1 through 4))
	-- Example: <https://github.com/SwimmingTiger/LibTotemInfo/issues/2>
	return GetTotemTimeLeft(i)
end 

-- crit_chance
function A.Player:CritChancePct()
	return GetCritChance()
end

-- haste
function A.Player:HastePct()
	return GetHaste()
end

function A.Player:SpellHaste()
	return 1 / (1 + (self:HastePct() / 100))
end

-- mastery
function A.Player:MasteryPct()
	return GetMasteryEffect()
end

-- versatility
function A.Player:VersatilityDmgPct()
	return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
end

-- execute_time
function A.Player:Execute_Time(spellID) 
    -- @return boolean (GCD > CastTime or GCD)
    local gcd 		= A_GetGCD()
	local cast_time = A_Unit(self.UnitID):CastTime(spellID)     
    if cast_time > gcd then
        return cast_time 
    else
        return gcd
    end	
end 

function A.Player:GCDRemains()
	-- @return number 
	return A_GetCurrentGCD()
end 

-- Swing 
function A.Player:GetSwing(inv)
	-- @return number (time in seconds of the swing for each slot)
	-- Note: inv can be constance or 1 (main hand / dual hand), 2 (off hand), 3 (range), 4 (main + off hands), 5 (all)
	if inv == 1 then 
		inv = CONST.INVSLOT_MAINHAND
	elseif inv == 2 then 
		inv = CONST.INVSLOT_OFFHAND
	elseif inv == 3 then
		inv = CONST.INVSLOT_RANGED
	elseif inv == 4 then 
		local inv1, inv2 = Env.SwingDuration(CONST.INVSLOT_MAINHAND), Env.SwingDuration(CONST.INVSLOT_OFFHAND)
		return math_max(inv1, inv2)
	elseif inv == 5 then 
		local inv1, inv2, inv3 = Env.SwingDuration(CONST.INVSLOT_MAINHAND), Env.SwingDuration(CONST.INVSLOT_OFFHAND), Env.SwingDuration(CONST.INVSLOT_RANGED)
		return math_max(inv1, inv2, inv3)
	end 
	
	return Env.SwingDuration(inv)
end 

function A.Player:GetSwingMax(inv)
	-- @return number (max duration taken from the last swing)
	-- Note: inv can be constance or 1 (main hand / dual hand), 2 (off hand), 3 (range), 4 (main + off hands), 5 (all)
	if inv == 1 then 
		inv = CONST.INVSLOT_MAINHAND
	elseif inv == 2 then 
		inv = CONST.INVSLOT_OFFHAND
	elseif inv == 3 then
		inv = CONST.INVSLOT_RANGED
	elseif inv == 4 then 
		local inv1, inv2 = CONST.INVSLOT_MAINHAND, CONST.INVSLOT_OFFHAND		
		return math_max(SwingTimers[inv1] and SwingTimers[inv1].duration or 0, SwingTimers[inv2] and SwingTimers[inv2].duration or 0)
	elseif inv == 5 then 
		local inv1, inv2, inv3 = CONST.INVSLOT_MAINHAND, CONST.INVSLOT_OFFHAND, CONST.INVSLOT_RANGED
		return math_max(SwingTimers[inv1] and SwingTimers[inv1].duration or 0, SwingTimers[inv2] and SwingTimers[inv2].duration or 0, SwingTimers[inv3] and SwingTimers[inv3].duration or 0)
	end 
	
	return SwingTimers[inv] and SwingTimers[inv].duration or 0
end  

function A.Player:GetSwingStart(inv)
	-- @return number (start stamp taken from the last swing)
	-- Note: inv can be constance or 1 (main hand / dual hand), 2 (off hand), 3 (range), 4 (main + off hands), 5 (all)
	if inv == 1 then 
		inv = CONST.INVSLOT_MAINHAND
	elseif inv == 2 then 
		inv = CONST.INVSLOT_OFFHAND
	elseif inv == 3 then
		inv = CONST.INVSLOT_RANGED
	elseif inv == 4 then 
		local inv1, inv2 = CONST.INVSLOT_MAINHAND, CONST.INVSLOT_OFFHAND		
		return math_max(SwingTimers[inv1] and SwingTimers[inv1].startTime or 0, SwingTimers[inv2] and SwingTimers[inv2].startTime or 0)
	elseif inv == 5 then 
		local inv1, inv2, inv3 = CONST.INVSLOT_MAINHAND, CONST.INVSLOT_OFFHAND, CONST.INVSLOT_RANGED
		return math_max(SwingTimers[inv1] and SwingTimers[inv1].startTime or 0, SwingTimers[inv2] and SwingTimers[inv2].startTime or 0, SwingTimers[inv3] and SwingTimers[inv3].startTime or 0)
	end 
	
	return SwingTimers[inv] and SwingTimers[inv].startTime or 0
end 

function A.Player:ReplaceSwingDuration(inv, dur)
	-- @usage A.Player:ReplaceSwingDuration(1, 2.6)
	if inv == 1 then 
		inv = CONST.INVSLOT_MAINHAND
	elseif inv == 2 then 
		inv = CONST.INVSLOT_OFFHAND
	elseif inv == 3 then
		inv = CONST.INVSLOT_RANGED
	elseif inv == 4 then 
		local inv1, inv2 = CONST.INVSLOT_MAINHAND, CONST.INVSLOT_OFFHAND		
		
		if SwingTimers[inv1] then 
			SwingTimers[inv1].duration = dur
		end 
		
		if SwingTimers[inv2] then 
			SwingTimers[inv2].duration = dur
		end
		return
	elseif inv == 5 then 
		local inv1, inv2, inv3 = CONST.INVSLOT_MAINHAND, CONST.INVSLOT_OFFHAND, CONST.INVSLOT_RANGED
		if SwingTimers[inv1] then 
			SwingTimers[inv1].duration = dur
		end 
		
		if SwingTimers[inv2] then 
			SwingTimers[inv2].duration = dur
		end
		
		if SwingTimers[inv3] then 
			SwingTimers[inv3].duration = dur
		end
		return 
	end 
	
	if SwingTimers[inv] then 
		SwingTimers[inv].duration = dur
	end 
end 

function A.Player:GetWeaponMeleeDamage(inv, mod)
	-- @return number (full average damage), number (average damage per second)
	-- Note: This is only for white hits, usually to calculate damage taken from spell's tooltip
	-- Note: inv can be constance or 1 (main hand / dual hand), 2 (off hand), nil (both)
	-- mod is custom modifier which will be applied to UnitAttackSpeed
	local speed, offhandSpeed = UnitAttackSpeed(self.UnitID)
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage(self.UnitID)
	
	local main_baseDamage, main_fullDamage, main_damagePerSecond
	if speed and (not inv or inv == 1 or inv == CONST.INVSLOT_MAINHAND) then 
		main_baseDamage 		= (minDamage + maxDamage) * 0.5
		main_fullDamage 		= (main_baseDamage + physicalBonusPos + physicalBonusNeg) * percent		
		main_damagePerSecond	= math_max(main_fullDamage, 1) / (speed * (mod or 1))
	end
	
	local offhandBaseDamage, offhandFullDamage, offhandDamagePerSecond
	if offhandSpeed and (not inv or inv == 1 or inv == CONST.INVSLOT_OFFHAND) then 
		offhandBaseDamage 		= (minOffHandDamage + maxOffHandDamage) * 0.5
		offhandFullDamage 		= (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent
		offhandDamagePerSecond 	= math_max(offhandFullDamage, 1) / (offhandSpeed * (mod or 1))
	end 
	
	local full_damage 	 = (main_fullDamage or 0) + (offhandFullDamage or 0)
	local per_sec_damage = (main_damagePerSecond or 0) + (offhandDamagePerSecond or 0)

	return full_damage, per_sec_damage
end 

-- Swap 
function A.Player:IsSwapLocked()
	-- @return boolean 
	-- Note: This condition must be checked always before equip swap
	return Data.isSwapLocked 
end 

-- Equipment
function A.Player:RemoveTier(tier)
	-- @usage A.Player:RemoveTier("Tier21")
	DataCheckItems[tier] = nil 
	DataCountItems[tier] = nil
	if not next(DataCheckItems) then 
		Data.IierIsInitialized = nil 
		--Listener:Remove("ACTION_EVENT_EQUIPMENT", "PLAYER_ENTERING_WORLD")
		Listener:Remove("ACTION_EVENT_EQUIPMENT", "PLAYER_EQUIPMENT_CHANGED")		
	end 
end

function A.Player:AddTier(tier, items)
	-- @usage A.Player:AddTier("Tier21", { itemID, itemID, itemID, itemID, itemID, itemID })
	DataCheckItems[tier] = items 
	DataCountItems[tier] = 0
	if not Data.IierIsInitialized then 
		Data.IierIsInitialized = true 
		--Listener:Add("ACTION_EVENT_EQUIPMENT", "PLAYER_ENTERING_WORLD", 		Data.OnItemsUpdate)
		Listener:Add("ACTION_EVENT_EQUIPMENT", "PLAYER_EQUIPMENT_CHANGED",		Data.OnItemsUpdate)			
	end 
	Data.OnItemsUpdate()
end

function A.Player:GetTier(tier)
	-- @return number (how much parts of tier gear is equipped)
	return DataCountItems[tier] or 0
end 

function A.Player:HasTier(tier, count)
	-- @return boolean 
	-- Set Bonuses are disabled in Challenge Mode (Diff = 8) and in MoP: Proving Grounds (InstanceID = 1148, ZoneID = 480)
	return self:GetTier(tier) >= count and InstanceInfo.difficultyID ~= 8 and A.ZoneID ~= 480 
end 

-- Bags 
function A.Player:RemoveBag(name)
	-- @usage A.Player:RemoveBag("SOMETHING")
	if DataCheckBags[name] then 
		Data.CheckBagsMaxN	= Data.CheckBagsMaxN - 1
	end 
	
	DataCheckBags[name] 	= nil 
	DataInfoBags[name]	 	= nil 
	
	if not next(DataCheckBags) then 
		Data.BagsIsInitialized = false 
		Listener:Remove("ACTION_EVENT_PLAYER_BAG", "BAG_NEW_ITEMS_UPDATED", 	Data.logBag)
		Listener:Remove("ACTION_EVENT_PLAYER_BAG", "BAG_UPDATE_DELAYED",		Data.logBag)				
	end 
end 

function A.Player:AddBag(name, data)
	-- @usage A.Player:AddBag("SOMETHING", { itemID = 123123 }) or A.Player:AddBag("SHIELDS", { itemClassID = LE_ITEM_CLASS_ARMOR, itemSubClassID = LE_ITEM_ARMOR_SHIELD, isEquippableItem = true })
	-- Optional: itemEquipLoc, itemClassID, itemSubClassID, itemID, isEquippableItem but at least one of them must be up 
	-- More info about itemClassID, itemSubClassID here: https://wow.gamepedia.com/ItemType
	if not DataCheckBags[name] then 
		Data.CheckBagsMaxN	 = Data.CheckBagsMaxN + 1
	end 
	
	DataCheckBags[name] = data 
	
	if not Data.BagsIsInitialized then 
		Data.BagsIsInitialized = true 
		Listener:Add("ACTION_EVENT_PLAYER_BAG", "BAG_NEW_ITEMS_UPDATED", 		Data.logBag)
		Listener:Add("ACTION_EVENT_PLAYER_BAG", "BAG_UPDATE_DELAYED",			Data.logBag)				
	end 
	Data.logBag()
end 

function A.Player:GetBag(name)
	-- @return table info ( .count , .itemID ) or nil 
	return DataInfoBags[name]
end 

-- Inventory 
function A.Player:RemoveInv(name)
	-- @usage A.Player:RemoveInv("SOMETHING")
	DataCheckInv[name] 	= nil 
	DataInfoInv[name]	= nil 
	if not next(DataCheckInv) then 
		Data.InvIsInitialized = false 
		Listener:Remove("ACTION_EVENT_PLAYER_INV", "PLAYER_EQUIPMENT_CHANGED", 	Data.logInv)				
	end 
end 

function A.Player:AddInv(name, slot, data)
	-- @usage A.Player:AddInv("SOMETHING", ACTION_CONST_INVSLOT_OFFHAND, { itemID = 123123 }) or A.Player:AddInv("SHIELDS", ACTION_CONST_INVSLOT_OFFHAND, { itemClassID = LE_ITEM_CLASS_ARMOR, itemSubClassID = LE_ITEM_ARMOR_SHIELD, isEquippableItem = true })
	-- Optional: itemEquipLoc, itemClassID, itemSubClassID, itemID, isEquippableItem all of them can be omited 
	-- More info about itemClassID, itemSubClassID here: https://wow.gamepedia.com/ItemType
	data.slot 			= slot 
	DataCheckInv[name] 	= data  
	if not Data.InvIsInitialized then 
		Data.InvIsInitialized = true 
		Listener:Add("ACTION_EVENT_PLAYER_INV", "PLAYER_EQUIPMENT_CHANGED", 	Data.logInv)				
	end 
	Data.logInv()
end 

function A.Player:GetInv(name)
	-- @return table info ( .slot , .itemID ) or nil 
	return DataInfoInv[name]
end 

-----------------------------------
--- Shared Functions | Register ---
-----------------------------------
function A.Player:RegisterAmmo()
	-- Registers to track ammo count in bags
	self:AddBag("AMMO1", 														{ itemClassID = LE_ITEM_CLASS_PROJECTILE, itemSubClassID = 2 												})
	self:AddBag("AMMO2", 														{ itemClassID = LE_ITEM_CLASS_PROJECTILE, itemSubClassID = 3 												})
end 

function A.Player:RegisterThrown()
	-- Registers to track throwns count in bags 
	self:AddBag("THROWN", 														{ itemEquipLoc = "INVTYPE_THROWN"																			})
end 

function A.Player:RegisterShield()
	-- Registers to track shields in bags or equiped 
	self:AddBag("SHIELD", 														{ itemClassID = LE_ITEM_CLASS_ARMOR, itemSubClassID = LE_ITEM_ARMOR_SHIELD, 	isEquippableItem = true 	})
	self:AddInv("SHIELD", 			CONST.INVSLOT_OFFHAND, 						{ itemClassID = LE_ITEM_CLASS_ARMOR, itemSubClassID = LE_ITEM_ARMOR_SHIELD 									})
end 

function A.Player:RegisterWeaponOffHand()
	-- Registers to track off hand weapons in bags or equiped 
	self:AddBag("WEAPON_OFFHAND_1", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_AXE1H, 	isEquippableItem = true 	})
	self:AddBag("WEAPON_OFFHAND_2", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_MACE1H, 	isEquippableItem = true 	})
	self:AddBag("WEAPON_OFFHAND_3", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_SWORD1H, 	isEquippableItem = true 	})
	self:AddBag("WEAPON_OFFHAND_4", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_UNARMED, 	isEquippableItem = true		})
	self:AddBag("WEAPON_OFFHAND_5", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_DAGGER, 	isEquippableItem = true		})
	self:AddInv("WEAPON_OFFHAND", 	CONST.INVSLOT_OFFHAND, 						{ itemClassID = LE_ITEM_CLASS_WEAPON 																		})
end 

function A.Player:RegisterWeaponTwoHand()
	-- Registers to track two hand weapons in bags or equiped 
	self:AddBag("WEAPON_TWOHAND_1", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_AXE2H, 	isEquippableItem = true 	})
	self:AddBag("WEAPON_TWOHAND_2", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_MACE2H, 	isEquippableItem = true 	})
	self:AddBag("WEAPON_TWOHAND_3", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_POLEARM, 	isEquippableItem = true 	})
	self:AddBag("WEAPON_TWOHAND_4", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_SWORD2H, 	isEquippableItem = true		})
	self:AddBag("WEAPON_TWOHAND_5", 											{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_STAFF, 	isEquippableItem = true		})
	self:AddInv("WEAPON_TWOHAND_1", CONST.INVSLOT_MAINHAND, 					{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_AXE2H									})
	self:AddInv("WEAPON_TWOHAND_2", CONST.INVSLOT_MAINHAND, 					{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_MACE2H								})
	self:AddInv("WEAPON_TWOHAND_3", CONST.INVSLOT_MAINHAND, 					{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_POLEARM								})
	self:AddInv("WEAPON_TWOHAND_4", CONST.INVSLOT_MAINHAND, 					{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_SWORD2H								})
	self:AddInv("WEAPON_TWOHAND_5", CONST.INVSLOT_MAINHAND, 					{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_STAFF									})
end 

function A.Player:RegisterWeaponMainOneHandDagger()
	-- Registers to track dagger in the main one hand (not two hand) weapon in bags or equiped 
	self:AddBag("WEAPON_MAINHAND_DAGGER", 										{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_DAGGER, 	isEquippableItem = true		})
	self:AddInv("WEAPON_MAINHAND_DAGGER", 		CONST.INVSLOT_MAINHAND, 		{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_DAGGER								})
end 

function A.Player:RegisterWeaponMainOneHandSword()
	-- Registers to track sword in the main one hand (not two hand) weapon in bags or equiped 
	self:AddBag("WEAPON_MAIN_ONE_HAND_SWORD", 									{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_SWORD1H, 	isEquippableItem = true 	})
	self:AddInv("WEAPON_MAIN_ONE_HAND_SWORD", 	CONST.INVSLOT_MAINHAND, 		{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_SWORD1H								})
end 

function A.Player:RegisterWeaponOffOneHandSword()
	-- Registers to track sword in the off one hand weapon in bags or equiped 
	self:AddBag("WEAPON_OFF_ONE_HAND_SWORD", 									{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_SWORD1H, 	isEquippableItem = true 	})
	self:AddInv("WEAPON_OFF_ONE_HAND_SWORD", 	CONST.INVSLOT_OFFHAND, 			{ itemClassID = LE_ITEM_CLASS_WEAPON, itemSubClassID = LE_ITEM_WEAPON_SWORD1H								})
end 

------------------------------
--- Shared Functions | API ---
------------------------------
function A.Player:GetAmmo()
	-- @return number 
	-- Returns number of remain ammo (Arrow or Bullet depended on what first found) , 0 if none 
	return (self:GetBag("AMMO1") and self:GetBag("AMMO1").count) or (self:GetBag("AMMO2") and self:GetBag("AMMO2").count)
end 

function A.Player:GetArrow()
	-- @return number 
	-- Returns number of remain arrows, 0 if none 
	return (self:GetBag("AMMO1") and self:GetBag("AMMO1").count) or 0 
end 

function A.Player:GetBullet()
	-- @return number 
	-- Returns number of remain bullets, 0 if none 
	return (self:GetBag("AMMO2") and self:GetBag("AMMO2").count) or 0 
end 

function A.Player:GetThrown()
	-- @return number 
	-- Returns number of remain throwns, 0 if none  
	return (self:GetBag("THROWN") and self:GetBag("THROWN").count) or 0 
end 

function A.Player:HasShield(isEquiped)
	-- @return itemID or nil  
	-- Bag 
	if not isEquiped then 
		return (self:GetBag("SHIELD") and self:GetBag("SHIELD").itemID) or nil 
	-- Inventory
	else
		return (self:GetInv("SHIELD") and self:GetInv("SHIELD").itemID) or nil 
	end 
end 

function A.Player:HasWeaponOffHand(isEquiped)
	-- @return itemID or nil 
	-- Bag 
	if not isEquiped then 
		local bag_offhand 
		for i = 1, 5 do 
			bag_offhand = "WEAPON_OFFHAND_" .. i
			if self:GetBag(bag_offhand) and self:GetBag(bag_offhand).itemID then 
				return self:GetBag(bag_offhand).itemID
			end 
		end 
	-- Inventory
	else
		return (self:GetInv("WEAPON_OFFHAND") and self:GetInv("WEAPON_OFFHAND").itemID) or nil 
	end 	
end 

function A.Player:HasWeaponTwoHand(isEquiped)
	-- @return itemID or nil 
	-- Bag 
	if not isEquiped then 
		local inv_twohand 
		for i = 1, 5 do 
			inv_twohand = "WEAPON_TWOHAND_" .. i
			if self:GetBag(inv_twohand) and self:GetBag(inv_twohand).itemID then 
				return self:GetBag(inv_twohand).itemID
			end 
		end 
	-- Inventory
	else
		local inv_twohand 
		for i = 1, 5 do 
			inv_twohand = "WEAPON_TWOHAND_" .. i
			if self:GetInv(inv_twohand) and self:GetInv(inv_twohand).itemID then 
				return self:GetInv(inv_twohand).itemID
			end 
		end 
	end 	
end 

function A.Player:HasWeaponMainOneHandDagger(isEquiped)
	-- @return itemID or nil  
	-- Bag 
	if not isEquiped then 
		return (self:GetBag("WEAPON_MAINHAND_DAGGER") and self:GetBag("WEAPON_MAINHAND_DAGGER").itemID) or nil 
	-- Inventory
	else
		return (self:GetInv("WEAPON_MAINHAND_DAGGER") and self:GetInv("WEAPON_MAINHAND_DAGGER").itemID) or nil 
	end 
end 

function A.Player:HasWeaponMainOneHandSword(isEquiped)
	-- @return itemID or nil 
	-- Bag 
	if not isEquiped then 
		return (self:GetBag("WEAPON_MAIN_ONE_HAND_SWORD") and self:GetBag("WEAPON_MAIN_ONE_HAND_SWORD").itemID) or nil 
	-- Inventory
	else		
		return (self:GetInv("WEAPON_MAIN_ONE_HAND_SWORD") and self:GetInv("WEAPON_MAIN_ONE_HAND_SWORD").itemID) or nil
	end 	
end 

function A.Player:HasWeaponOffOneHandSword(isEquiped)
	-- @return itemID or nil 
	-- Bag 
	if not isEquiped then 
		return (self:GetBag("WEAPON_OFF_ONE_HAND_SWORD") and self:GetBag("WEAPON_OFF_ONE_HAND_SWORD").itemID) or nil 
	-- Inventory
	else		
		return (self:GetInv("WEAPON_OFF_ONE_HAND_SWORD") and self:GetInv("WEAPON_OFF_ONE_HAND_SWORD").itemID) or nil
	end 	
end 

--------------------------
--- 0 | Mana Functions ---
--------------------------
-- mana.max
function A.Player:ManaMax()
	return UnitPowerMax(self.UnitID, ManaPowerType)
end

-- Mana
function A.Player:Mana()
	return UnitPower(self.UnitID, ManaPowerType)
end

-- Mana.pct
function A.Player:ManaPercentage()
	return (self:Mana() / self:ManaMax()) * 100
end

-- Mana.deficit
function A.Player:ManaDeficit()
	return self:ManaMax() - self:Mana()
end

-- "Mana.deficit.pct"
function A.Player:ManaDeficitPercentage()
	return (self:ManaDeficit() / self:ManaMax()) * 100
end

-- mana.regen
function A.Player:ManaRegen()
	return math_floor(GetPowerRegen(self.UnitID))
end

-- Mana regen in a cast
function A.Player:ManaCastRegen(CastTime)
	if self:ManaRegen() == 0 then return -1 end
	return self:ManaRegen() * CastTime
end

-- "remaining_cast_regen"
function A.Player:ManaRemainingCastRegen(Offset)
	if self:ManaRegen() == 0 then return -1 end
	-- If we are casting, we check what we will regen until the end of the cast
	if self:IsCasting() then
		return self:ManaRegen() * (self:CastRemains() + (Offset or 0))
	-- Else we'll use the remaining GCD as "CastTime"
	else
		return self:ManaRegen() * (A_GetCurrentGCD() + (Offset or 0))
	end
end

-- mana.time_to_max
function A.Player:ManaTimeToMax()
	if self:ManaRegen() == 0 then return -1 end
	return self:ManaDeficit() / self:ManaRegen()
end

-- Mana Predicted with current cast
function A.Player:ManaP()
	local FutureMana = self:Mana() - self:CastCost()
	-- Add the mana tha we will regen during the remaining of the cast
	if self:Mana() ~= self:ManaMax() then FutureMana = FutureMana + self:ManaRemainingCastRegen() end
	-- Cap the max
	if FutureMana > self:ManaMax() then FutureMana = self:ManaMax() end
	return FutureMana
end

-- Mana.pct Predicted with current cast
function A.Player:ManaPercentageP()
	return (self:ManaP() / self:ManaMax()) * 100
end

-- Mana.deficit Predicted with current cast
function A.Player:ManaDeficitP()
	return self:ManaMax() - self:ManaP()
end

-- "Mana.deficit.pct" Predicted with current cast
function A.Player:ManaDeficitPercentageP()
	return (self:ManaDeficitP() / self:ManaMax()) * 100
end

--------------------------
--- 1 | Rage Functions ---
--------------------------
-- rage.max
function A.Player:RageMax()
	return UnitPowerMax(self.UnitID, RagePowerType)
end

-- rage
function A.Player:Rage()
	return UnitPower(self.UnitID, RagePowerType)
end

-- rage.pct
function A.Player:RagePercentage()
	return (self:Rage() / self:RageMax()) * 100
end

-- rage.deficit
function A.Player:RageDeficit()
	return self:RageMax() - self:Rage()
end

-- "rage.deficit.pct"
function A.Player:RageDeficitPercentage()
	return (self:RageDeficit() / self:RageMax()) * 100
end

---------------------------
--- 2 | Focus Functions ---
---------------------------
-- focus.max
function A.Player:FocusMax()
	return UnitPowerMax(self.UnitID, FocusPowerType)
end

-- focus
function A.Player:Focus()
	return UnitPower(self.UnitID, FocusPowerType)
end

-- focus.regen
function A.Player:FocusRegen()
	return math_floor(GetPowerRegen(self.UnitID))
end

-- focus.pct
function A.Player:FocusPercentage()
	return (self:Focus() / self:FocusMax()) * 100
end

-- focus.deficit
function A.Player:FocusDeficit()
	return self:FocusMax() - self:Focus()
end

-- "focus.deficit.pct"
function A.Player:FocusDeficitPercentage()
	return (self:FocusDeficit() / self:FocusMax()) * 100
end

-- "focus.regen.pct"
function A.Player:FocusRegenPercentage()
	return (self:FocusRegen() / self:FocusMax()) * 100
end

-- focus.time_to_max
function A.Player:FocusTimeToMax()
	if self:FocusRegen() == 0 then return -1 end
	return self:FocusDeficit() / self:FocusRegen()
end

-- "focus.time_to_x"
function A.Player:FocusTimeToX(Amount)
	if self:FocusRegen() == 0 then return -1 end
	return Amount > self:Focus() and (Amount - self:Focus()) / self:FocusRegen() or 0
end

-- "focus.time_to_x.pct"
function A.Player:FocusTimeToXPercentage(Amount)
	if self:FocusRegen() == 0 then return -1 end
	return Amount > self:FocusPercentage() and (Amount - self:FocusPercentage()) / self:FocusRegenPercentage() or 0
end

-- cast_regen
function A.Player:FocusCastRegen(CastTime)
	if self:FocusRegen() == 0 then return -1 end
	return self:FocusRegen() * CastTime
end

-- "remaining_cast_regen"
function A.Player:FocusRemainingCastRegen(Offset)
	if self:FocusRegen() == 0 then return -1 end
	-- If we are casting, we check what we will regen until the end of the cast
	if self:IsCasting() then
		return self:FocusRegen() * (self:CastRemains() + (Offset or 0))
	-- Else we'll use the remaining GCD as "CastTime"
	else
		return self:FocusRegen() * (self:GCDRemains() + (Offset or 0))
	end
end

-- Get the Focus we will loose when our cast will end, if we cast.
function A.Player:FocusLossOnCastEnd()
	local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A_Unit(self.UnitID):IsCasting()
	return castName and A_GetSpellPowerCost(spellID) or 0
end

-- Predict the expected Focus at the end of the Cast/GCD.
function A.Player:FocusPredicted(Offset)
	if self:FocusRegen() == 0 then return -1 end
	return math_min(self:FocusMax(), self:Focus() + self:FocusRemainingCastRegen(Offset) - self:FocusLossOnCastEnd())
end

-- Predict the expected Focus Deficit at the end of the Cast/GCD.
function A.Player:FocusDeficitPredicted(Offset)
	if self:FocusRegen() == 0 then return -1 end
	return self:FocusMax() - self:FocusPredicted(Offset)
end

-- Predict time to max Focus at the end of Cast/GCD
function A.Player:FocusTimeToMaxPredicted()
	if self:FocusRegen() == 0 then return -1 end
	local FocusDeficitPredicted = self:FocusDeficitPredicted()
	if FocusDeficitPredicted <= 0 then
		return 0
	end
	return FocusDeficitPredicted / self:FocusRegen()
end

----------------------------
--- 3 | Energy Functions ---
----------------------------
-- energy.max
function A.Player:EnergyMax()
	return UnitPowerMax(self.UnitID, EnergyPowerType)
end

-- energy
function A.Player:Energy()
	return UnitPower(self.UnitID, EnergyPowerType)
end

-- energy.regen
function A.Player:EnergyRegen()
	return math_floor(GetPowerRegen(self.UnitID))
end

-- energy.pct
function A.Player:EnergyPercentage()
	return (self:Energy() / self:EnergyMax()) * 100
end

-- energy.deficit
function A.Player:EnergyDeficit()
	return self:EnergyMax() - self:Energy()
end

-- "energy.deficit.pct"
function A.Player:EnergyDeficitPercentage()
	return (self:EnergyDeficit() / self:EnergyMax()) * 100
end

-- "energy.regen.pct"
function A.Player:EnergyRegenPercentage()
	return (self:EnergyRegen() / self:EnergyMax()) * 100
end

-- energy.time_to_max
function A.Player:EnergyTimeToMax()
	if self:EnergyRegen() == 0 then return -1 end
	return self:EnergyDeficit() / self:EnergyRegen()
end

-- "energy.time_to_x"
function A.Player:EnergyTimeToX(Amount, Offset)
	if self:EnergyRegen() == 0 then return -1 end
	return Amount > self:Energy() and (Amount - self:Energy()) / (self:EnergyRegen() * (1 - (Offset or 0))) or 0
end

-- "energy.time_to_x.pct"
function A.Player:EnergyTimeToXPercentage(Amount)
	if self:EnergyRegen() == 0 then return -1 end
	return Amount > self:EnergyPercentage() and (Amount - self:EnergyPercentage()) / self:EnergyRegenPercentage() or 0
end

-- "energy.cast_regen"
function A.Player:EnergyRemainingCastRegen(Offset)
    if self:EnergyRegen() == 0 then return -1 end
    -- If we are casting, we check what we will regen until the end of the cast
    if self:IsCasting() or self:IsChanneling() then
		return self:EnergyRegen() * (self:CastRemains() + (Offset or 0))
    -- Else we'll use the remaining GCD as "CastTime"
    else
		return self:EnergyRegen() * (self:GCDRemains() + (Offset or 0))
    end
end

-- Predict the expected Energy at the end of the Cast/GCD.
function A.Player:EnergyPredicted(Offset)
	if self:EnergyRegen() == 0 then return -1 end
	return math_min(self:EnergyMax(), self:Energy() + self:EnergyRemainingCastRegen(Offset))
end

-- Predict the expected Energy Deficit at the end of the Cast/GCD.
function A.Player:EnergyDeficitPredicted(Offset)
	if self:EnergyRegen() == 0 then return -1 end
	return math_max(self:EnergyDeficit() - self:EnergyRemainingCastRegen(Offset), 0) -- math_max(0, self:EnergyDeficit() - self:EnergyRemainingCastRegen(Offset))
end

-- Predict time to max energy at the end of Cast/GCD
function A.Player:EnergyTimeToMaxPredicted()
	if self:EnergyRegen() == 0 then return -1 end
	local EnergyDeficitPredicted = self:EnergyDeficitPredicted()
	if EnergyDeficitPredicted <= 0 then
		return 0
	end
	return EnergyDeficitPredicted / self:EnergyRegen()
end

----------------------------------
--- 4 | Combo Points Functions ---
----------------------------------
-- combo_points.max
function A.Player:ComboPointsMax()
	return UnitPowerMax(self.UnitID, ComboPointsPowerType)
end

-- combo_points
function A.Player:ComboPoints()
	return UnitPower(self.UnitID, ComboPointsPowerType) or 0
end

-- combo_points.deficit
function A.Player:ComboPointsDeficit()
	return self:ComboPointsMax() - self:ComboPoints()
end

---------------------------------
--- 5 | Runic Power Functions ---
---------------------------------
-- runicpower.max
function A.Player:RunicPowerMax()
	return UnitPowerMax(self.UnitID, RunicPowerPowerType)
end

-- runicpower
function A.Player:RunicPower()
	return UnitPower(self.UnitID, RunicPowerPowerType)
end

-- runicpower.pct
function A.Player:RunicPowerPercentage()
	return (self:RunicPower() / self:RunicPowerMax()) * 100
end

-- runicpower.deficit
function A.Player:RunicPowerDeficit()
	return self:RunicPowerMax() - self:RunicPower()
end

-- "runicpower.deficit.pct"
function A.Player:RunicPowerDeficitPercentage()
	return (self:RunicPowerDeficit() / self:RunicPowerMax()) * 100
end

---------------------------
--- 6 | Runes Functions ---
---------------------------
-- Computes any rune cooldown.
local function ComputeRuneCooldown(Slot, BypassRecovery)
	-- Get rune cooldown infos
	local CDTime, CDValue = GetRuneCooldown(Slot)
	-- Return 0 if the rune isn't in CD.
	if CDTime == 0 then return 0 end
	-- Compute the CD.
	local CD = CDTime + CDValue - TMW.time - (BypassRecovery and 0 or RecoveryOffset())
	-- Return the Rune CD
	return CD > 0 and CD or 0
end

-- rune
function A.Player:Rune()
	local Count = 0
	for i = 1, 6 do
		if ComputeRuneCooldown(i) == 0 then
			Count = Count + 1
		end
	end
	return Count
end

-- rune.time_to_x
function A.Player:RuneTimeToX(Value)
	if type(Value) ~= "number" then error("Value must be a number.") end
	if Value < 1 or Value > 6 then error("Value must be a number between 1 and 6.") end
	local Runes = {}
	for i = 1, 6 do
		Runes[i] = ComputeRuneCooldown(i)
	end
	tsort(Runes, sortByLowest)
	local Count = 1
	for _, CD in pairs(Runes) do
		if Count == Value then
			return CD
		end
		Count = Count + 1
	end
end

------------------------
--- 7 | Soul Shards  ---
------------------------
-- soul_shard.max
function A.Player:SoulShardsMax()
	return UnitPowerMax(self.UnitID, SoulShardsPowerType)
end

-- soul_shard
function A.Player:SoulShards()
	return WarlockPowerBar_UnitPower(self.UnitID)
end

-- soul shards predicted, customize in spec overrides
function A.Player:SoulShardsP()
	return WarlockPowerBar_UnitPower(self.UnitID)
end

-- soul_shard.deficit
function A.Player:SoulShardsDeficit()
	return self:SoulShardsMax() - self:SoulShards()
end

------------------------
--- 8 | Astral Power ---
------------------------
-- astral_power.max
function A.Player:AstralPowerMax()
	return UnitPowerMax(self.UnitID, LunarPowerPowerType)
end

-- astral_power
function A.Player:AstralPower(OverrideFutureAstralPower)
	return OverrideFutureAstralPower or UnitPower(self.UnitID, LunarPowerPowerType)
end

-- astral_power.pct
function A.Player:AstralPowerPercentage(OverrideFutureAstralPower)
	return (self:AstralPower(OverrideFutureAstralPower) / self:AstralPowerMax()) * 100
end

-- astral_power.deficit
function A.Player:AstralPowerDeficit(OverrideFutureAstralPower)
	local AstralPower = self:AstralPower(OverrideFutureAstralPower)
	return self:AstralPowerMax() - AstralPower
end

-- "astral_power.deficit.pct"
function A.Player:AstralPowerDeficitPercentage(OverrideFutureAstralPower)
	return (self:AstralPowerDeficit(OverrideFutureAstralPower) / self:AstralPowerMax()) * 100
end

--------------------------------
--- 9 | Holy Power Functions ---
--------------------------------
-- holy_power.max
function A.Player:HolyPowerMax()
	return UnitPowerMax(self.UnitID, HolyPowerPowerType)
end

-- holy_power
function A.Player:HolyPower()
	return UnitPower(self.UnitID, HolyPowerPowerType)
end

-- holy_power.pct
function A.Player:HolyPowerPercentage()
	return (self:HolyPower() / self:HolyPowerMax()) * 100
end

-- holy_power.deficit
function A.Player:HolyPowerDeficit()
	return self:HolyPowerMax() - self:HolyPower()
end

-- "holy_power.deficit.pct"
function A.Player:HolyPowerDeficitPercentage()
	return (self:HolyPowerDeficit() / self:HolyPowerMax()) * 100
end

------------------------------
-- 11 | Maelstrom Functions --
------------------------------
-- maelstrom.max
function A.Player:MaelstromMax()
	return UnitPowerMax(self.UnitID, MaelstromPowerType)
end

-- maelstrom
function A.Player:Maelstrom()
	return UnitPower(self.UnitID, MaelstromPowerType)
end

-- maelstrom.pct
function A.Player:MaelstromPercentage()
	return (self:Maelstrom() / self:MaelstromMax()) * 100
end

-- maelstrom.deficit
function A.Player:MaelstromDeficit()
	return self:MaelstromMax() - self:Maelstrom()
end

-- "maelstrom.deficit.pct"
function A.Player:MaelstromDeficitPercentage()
	return (self:MaelstromDeficit() / self:MaelstromMax()) * 100
end

--------------------------------------
--- 12 | Chi Functions (& Stagger) ---
--------------------------------------
-- chi.max
function A.Player:ChiMax()
	return UnitPowerMax(self.UnitID, ChiPowerType)
end

-- chi
function A.Player:Chi()
	return UnitPower(self.UnitID, ChiPowerType)
end

-- chi.pct
function A.Player:ChiPercentage()
	return (self:Chi() / self:ChiMax()) * 100
end

-- chi.deficit
function A.Player:ChiDeficit()
	return self:ChiMax() - self:Chi()
end

-- "chi.deficit.pct"
function A.Player:ChiDeficitPercentage()
	return (self:ChiDeficit() / self:ChiMax()) * 100
end

-- "stagger.max"
function A.Player:StaggerMax()
	return A_Unit(self.UnitID):HealthMax()
end

-- stagger_amount
function A.Player:Stagger()
	return UnitStagger(self.UnitID)
end

-- stagger_percent
function A.Player:StaggerPercentage()
	return (self:Stagger() / self:StaggerMax()) * 100
end

------------------------------
-- 13 | Insanity Functions ---
------------------------------
-- insanity.max
function A.Player:InsanityMax()
	return UnitPowerMax(self.UnitID, InsanityPowerType)
end

-- insanity
function A.Player:Insanity()
	return UnitPower(self.UnitID, InsanityPowerType)
end

-- insanity.pct
function A.Player:InsanityPercentage()
	return (self:Insanity() / self:InsanityMax()) * 100
end

-- insanity.deficit
function A.Player:InsanityDeficit()
	return self:InsanityMax() - self:Insanity()
end

-- "insanity.deficit.pct"
function A.Player:InsanityDeficitPercentage()
	return (self:InsanityDeficit() / self:InsanityMax()) * 100
end

-- Insanity Drain
function A.Player:Insanityrain()
	local void_form_stack = A_Unit(self.UnitID):HasBuffsStacks(194249, true)
	return (void_form_stack == 0 and 0) or (6 + 0.68 * void_form_stack)
end

-----------------------------------
-- 16 | Arcane Charges Functions --
-----------------------------------
-- arcanecharges.max
function A.Player:ArcaneChargesMax()
	return UnitPowerMax(self.UnitID, ArcaneChargesPowerType)
end

-- arcanecharges
function A.Player:ArcaneCharges()
	return UnitPower(self.UnitID, ArcaneChargesPowerType)
end

-- arcanecharges.pct
function A.Player:ArcaneChargesPercentage()
	return (self:ArcaneCharges() / self:ArcaneChargesMax()) * 100
end

-- arcanecharges.deficit
function A.Player:ArcaneChargesDeficit()
	return self:ArcaneChargesMax() - self:ArcaneCharges()
end

-- "arcanecharges.deficit.pct"
function A.Player:ArcaneChargesDeficitPercentage()
	return (self:ArcaneChargesDeficit() / self:ArcaneChargesMax()) * 100
end

---------------------------
--- 17 | Fury Functions ---
---------------------------
-- fury.max
function A.Player:FuryMax()
	return UnitPowerMax(self.UnitID, FuryPowerType)
end

-- fury
function A.Player:Fury()
	return UnitPower(self.UnitID, FuryPowerType)
end

-- fury.pct
function A.Player:FuryPercentage()
	return (self:Fury() / self:FuryMax()) * 100
end

-- fury.deficit
function A.Player:FuryDeficit()
	return self:FuryMax() - self:Fury()
end

-- "fury.deficit.pct"
function A.Player:FuryDeficitPercentage()
	return (self:FuryDeficit() / self:FuryMax()) * 100
end

---------------------------
--- 18 | Pain Functions ---
---------------------------
-- pain.max
function A.Player:PainMax()
	return UnitPowerMax(self.UnitID, PainPowerType)
end

-- pain
function A.Player:Pain()
	return UnitPower(self.UnitID, PainPowerType)
end

-- pain.pct
function A.Player:PainPercentage()
	return (self:Pain() / self:PainMax()) * 100
end

-- pain.deficit
function A.Player:PainDeficit()
	return self:PainMax() - self:Pain()
end

-- "pain.deficit.pct"
function A.Player:PainDeficitPercentage()
	return (self:PainDeficit() / self:PainMax()) * 100
end

------------------------------
--- Predicted Resource Map ---
------------------------------
A.Player.PredictedResourceMap = {
	-- Health 
	[-2] = function() return A.Player:Health() end,
	-- Generic 
	[-1] = function() return 100 end,
	-- Mana
	[0] = function() return A.Player:ManaP() end,
	-- Rage
	[1] = function() return A.Player:Rage() end,
	-- Focus
	[2] = function() return A.Player:FocusPredicted() end,
	-- Energy
	[3] = function() return A.Player:EnergyPredicted() end,
	-- ComboPoints
	[4] = function() return A.Player:ComboPoints() end,
	-- Runes
	[5] = function() return A.Player:Runes() end,
	-- Runic Power
	[6] = function() return A.Player:RunicPower() end,
	-- Soul Shards
	[7] = function() return A.Player:SoulShardsP() end,
	-- Astral Power
	[8] = function() return A.Player:AstralPower() end,
	-- Holy Power
	[9] = function() return A.Player:HolyPower() end,
	-- Maelstrom
	[11] = function() return A.Player:Maelstrom() end,
	-- Chi
	[12] = function() return A.Player:Chi() end,
	-- Insanity
	[13] = function() return A.Player:Insanity() end,
	-- Arcane Charges
	[16] = function() return A.Player:ArcaneCharges() end,
	-- Fury
	[17] = function() return A.Player:Fury() end,
	-- Pain
	[18] = function() return A.Player:Pain() end,
}