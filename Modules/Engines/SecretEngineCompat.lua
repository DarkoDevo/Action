local _G, pcall, rawget, setmetatable, tostring, type = _G, pcall, rawget, setmetatable, tostring, type

local A = _G.Action
if not A then
	return
end

local Compat = A.Compat or {}
A.Compat = Compat

local NativeSE = rawget(_G, "ActionSecretEngine")
local issecretvalue = _G.issecretvalue
local scrubsecretvalues = _G.scrubsecretvalues
local C_Secrets = _G.C_Secrets
local C_Spell = _G.C_Spell
local C_SpellBook = _G.C_SpellBook
local GetSpellCharges = C_Spell and C_Spell.GetSpellCharges or _G.GetSpellCharges
local FindBaseSpellByID = C_SpellBook and C_SpellBook.FindBaseSpellByID or _G.FindBaseSpellByID
local FindSpellOverrideByID = _G.FindSpellOverrideByID

local function callNative(methodName, ...)
	local native = Compat.NativeSecretEngine or NativeSE
	local method = native and native[methodName]
	if type(method) ~= "function" then
		return false
	end

	local ok, a, b, c, d = pcall(method, native, ...)
	if ok then
		return true, a, b, c, d
	end

	return false
end

local function compatIsRestrictionEnabled(value)
	if value == nil or value == false or value == 0 then
		return false
	end

	if type(value) == "string" then
		return value ~= "" and value ~= "None" and value ~= "none" and value ~= "NonSecret"
	end

	return true
end

Compat.IsRestrictionEnabled = Compat.IsRestrictionEnabled or compatIsRestrictionEnabled

Compat.IsSecret = Compat.IsSecret or function(value)
	if type(issecretvalue) ~= "function" then
		return false
	end

	local ok, secret = pcall(issecretvalue, value)
	return ok and secret or false
end

Compat.NormalizeValue = Compat.NormalizeValue or function(value)
	if not Compat.IsSecret(value) then
		return value
	end

	if type(scrubsecretvalues) == "function" then
		local ok, scrubbed = pcall(scrubsecretvalues, value)
		if ok and not Compat.IsSecret(scrubbed) then
			return scrubbed
		end
	end

	local ok, nativeOk, nativeValue = callNative("TryUnwrap", value)
	if ok and nativeOk and not Compat.IsSecret(nativeValue) then
		return nativeValue
	end

	return nil
end

Compat.TryUnwrap = Compat.TryUnwrap or function(_, value)
	local normalized = Compat.NormalizeValue(value)
	if value == nil or normalized ~= nil then
		return true, normalized
	end

	return false, nil
end

Compat.UntaintNumber = Compat.UntaintNumber or function(_, value, fallback)
	local normalized = Compat.NormalizeValue(value)
	if type(normalized) == "number" then
		return normalized
	end

	local ok, nativeValue = callNative("UntaintNumber", value, fallback)
	if ok and type(nativeValue) == "number" then
		return nativeValue
	end

	return fallback or 0
end

Compat.NormalizeAuraData = Compat.NormalizeAuraData or function(auraData)
	if not auraData then
		return nil
	end

	if type(scrubsecretvalues) == "function" then
		local ok, scrubbed = pcall(scrubsecretvalues, auraData)
		if ok and type(scrubbed) == "table" then
			auraData = scrubbed
		end
	end

	if type(auraData) ~= "table" then
		return nil
	end

	local name = Compat.NormalizeValue(auraData.name)
	local spellId = Compat.NormalizeValue(auraData.spellId)
	if name == nil and spellId == nil then
		return nil
	end

	local applications = Compat.NormalizeValue(auraData.applications)
	local duration = Compat.NormalizeValue(auraData.duration)
	local expirationTime = Compat.NormalizeValue(auraData.expirationTime)

	return {
		name = name,
		spellId = spellId,
		spellID = spellId,
		sourceUnit = Compat.NormalizeValue(auraData.sourceUnit),
		applications = type(applications) == "number" and applications or 0,
		count = type(applications) == "number" and applications or 0,
		points = Compat.NormalizeValue(auraData.points),
		duration = type(duration) == "number" and duration or 0,
		expirationTime = type(expirationTime) == "number" and expirationTime or 0,
		dispelName = Compat.NormalizeValue(auraData.dispelName),
		isStealable = Compat.NormalizeValue(auraData.isStealable),
		nameplateShowAll = Compat.NormalizeValue(auraData.nameplateShowAll),
	}
end

local function actionHasSecretRestrictions()
	if Compat.HasSecretRestrictions and Compat.HasSecretRestrictions ~= actionHasSecretRestrictions then
		return Compat.HasSecretRestrictions()
	end

	if C_Secrets then
		local checker = C_Secrets.HasSecretRestrictions
		if type(checker) == "function" then
			local ok, restricted = pcall(checker, C_Secrets)
			if ok then
				return Compat.IsRestrictionEnabled(restricted)
			end

			ok, restricted = pcall(checker)
			if ok then
				return Compat.IsRestrictionEnabled(restricted)
			end
		elseif checker ~= nil then
			return Compat.IsRestrictionEnabled(checker)
		end
	end

	if _G.C_CombatLog and type(_G.C_CombatLog.IsCombatLogRestricted) == "function" then
		local ok, restricted = pcall(_G.C_CombatLog.IsCombatLogRestricted)
		if ok then
			return restricted == true
		end
	end

	return false
end

Compat.HasSecretRestrictions = Compat.HasSecretRestrictions or actionHasSecretRestrictions

Compat.GetBaseSpellID = Compat.GetBaseSpellID or function(_, spellID)
	if type(FindBaseSpellByID) == "function" then
		local ok, baseSpellID = pcall(FindBaseSpellByID, spellID)
		if ok and type(baseSpellID) == "number" and baseSpellID > 0 then
			return baseSpellID
		end
	end

	local ok, nativeSpellID = callNative("GetBaseSpellID", spellID)
	if ok and type(nativeSpellID) == "number" and nativeSpellID > 0 then
		return nativeSpellID
	end

	return spellID
end

Compat.ResolveSpellID = Compat.ResolveSpellID or function(self, spellID)
	local baseSpellID = self:GetBaseSpellID(spellID)
	if type(FindSpellOverrideByID) == "function" then
		local ok, overrideSpellID = pcall(FindSpellOverrideByID, baseSpellID)
		if ok and type(overrideSpellID) == "number" and overrideSpellID > 0 then
			return overrideSpellID
		end
	end

	local ok, nativeSpellID = callNative("ResolveSpellID", baseSpellID)
	if ok and type(nativeSpellID) == "number" and nativeSpellID > 0 then
		return nativeSpellID
	end

	return baseSpellID
end

Compat.ActionSpellChargeSnapshots = Compat.ActionSpellChargeSnapshots or {}

local function buildChargeInfo(first, second, third, fourth)
	if type(first) == "table" then
		return {
			currentCharges = Compat:UntaintNumber(first.currentCharges, 0),
			maxCharges = Compat:UntaintNumber(first.maxCharges, 0),
			cooldownStartTime = Compat:UntaintNumber(first.cooldownStartTime, 0),
			cooldownDuration = Compat:UntaintNumber(first.cooldownDuration, 0),
		}
	end

	if first == nil and second == nil and third == nil and fourth == nil then
		return nil
	end

	return {
		currentCharges = Compat:UntaintNumber(first, 0),
		maxCharges = Compat:UntaintNumber(second, 0),
		cooldownStartTime = Compat:UntaintNumber(third, 0),
		cooldownDuration = Compat:UntaintNumber(fourth, 0),
	}
end

Compat.SafeGetSpellCharges = Compat.SafeGetSpellCharges or function(self, spellID)
	local resolvedSpellID = self:ResolveSpellID(spellID)
	if type(GetSpellCharges) == "function" then
		local ok, first, second, third, fourth = pcall(GetSpellCharges, resolvedSpellID)
		if ok then
			local info = buildChargeInfo(first, second, third, fourth)
			if info then
				self.ActionSpellChargeSnapshots[resolvedSpellID] = info
				return info
			end
		end
	end

	local ok, first, second, third, fourth = callNative("SafeGetSpellCharges", resolvedSpellID)
	if ok then
		local info = buildChargeInfo(first, second, third, fourth)
		if info then
			self.ActionSpellChargeSnapshots[resolvedSpellID] = info
			return info
		end
	end

	ok, first, second, third, fourth = callNative("GetSpellCharges", resolvedSpellID)
	if ok then
		local info = buildChargeInfo(first, second, third, fourth)
		if info then
			self.ActionSpellChargeSnapshots[resolvedSpellID] = info
			return info
		end
	end

	return self.ActionSpellChargeSnapshots[resolvedSpellID] or {
		currentCharges = 0,
		maxCharges = 0,
		cooldownStartTime = 0,
		cooldownDuration = 0,
	}
end

Compat.NativeSecretEngine = Compat.NativeSecretEngine or NativeSE
_G.ActionSecretEngineNative = _G.ActionSecretEngineNative or NativeSE
_G.ActionHasSecretRestrictions = actionHasSecretRestrictions
_G.ActionSecretEngine = Compat
A.SecretEngine = Compat