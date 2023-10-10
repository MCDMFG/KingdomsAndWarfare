--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- This class manages overrides for the combat manager 5e script

OOB_MSGTYPE_ACTIVATEUNIT = "activateunit";
BT_MAIN_PATH = "battletracker";
BT_COMBATANT_PATH = "battletracker.list.*";
BT_COMBATANT_PARENT = "battletracker.list";
BT_LIST = "battletracker.list";

local fOnNPCPostAdd;
local fOnPCPostAdd;
local fParseAttackLine;
local fParseNPCPower;

function onInit()
	CombatRecordManager.setRecordTypeCallback("unit", addUnit);
	fOnNPCPostAdd = CombatRecordManager.getRecordTypePostAddCallback("npc");
	CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
	fOnPCPostAdd = CombatRecordManager.getRecordTypePostAddCallback("charsheet");
	CombatRecordManager.setRecordTypePostAddCallback("charsheet", onPCPostAdd);
	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomTurnEnd(onTurnEnd);
	CombatManager.setCustomRoundStart(onRoundStart);

	local tData = {
		sTrackerPath = CombatManagerKw.BT_LIST,
		sCombatantParentPath = CombatManagerKw.BT_COMBATANT_PARENT,
		sCombatantPath = CombatManagerKw.BT_COMBATANT_PATH,
		fSort = CombatManager.getCustomSort() or CombatManager.sortfuncSimple,
		fCleanup = CombatManager.deleteCleanup,
	};
	CombatManager.setTracker("unit", tData);

	fParseAttackLine = CombatManager2.parseAttackLine;
	CombatManager2.parseAttackLine = parseAttackLine;
	fParseNPCPower = CombatManager2.parseNPCPower;
	CombatManager2.parseNPCPower = parseNPCPower;

	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ACTIVATEUNIT, handleActivateUnit);
end

function onTabletopInit()
	-- Migrate after the base CombatManager has finished setting up.
	migrateUnits();
end

local combatantAddedHandlers = {};
function registerCombatantAddedHandler(fHandler)
	combatantAddedHandlers[fHandler] = true;
end

function unregisterCombatantAddedHandler(fHandler)
	combatantAddedHandlers[fHandler] = nil;
end

function migrateUnits()
	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes()) do
		if ActorManagerKw.isUnit(nodeCombatant) then
			local nodeUnit = CombatManager.createCombatantNode("unit");
			DB.copyNode(nodeCombatant, nodeUnit);
			-- Clear token references before deleting, so that the tokens remain linked to the migrated unit.
			DB.setValue(nodeCombatant, "tokenrefid", "string", "");
			DB.setValue(nodeCombatant, "tokenrefnode", "string", "");
			DB.deleteNode(nodeCombatant);
		end
	end
end

function getActiveUnitCT()
	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes("unit")) do
		if DB.getValue(nodeCombatant, "active", 0) == 1 then
			return nodeCombatant;
		end
	end
	return nil;
end

local unitSelectionHandlers = {};
function registerUnitSelectionHandler(fHandler, nSlot)
	if not nSlot then
		registerUnitSelectionHandler(fHandler, 1);
		registerUnitSelectionHandler(fHandler, 2);
		return;
	end

	if not unitSelectionHandlers[nSlot] then
		unitSelectionHandlers[nSlot] = {};
	end
	unitSelectionHandlers[nSlot][fHandler] = true;
end

function unregisterUnitSelectionHandler(fHandler, nSlot)
	if not nSlot then
		unregisterUnitSelectionHandler(fHandler, 1);
		unregisterUnitSelectionHandler(fHandler, 2);
		return;
	end

	if unitSelectionHandlers[nSlot] then
		unitSelectionHandlers[nSlot][fHandler] = nil;
	end
end

function selectUnit(nodeUnit, nSlot)
	if unitSelectionHandlers[nSlot] then
		for fHandler,_ in pairs(unitSelectionHandlers[nSlot]) do
			fHandler(nodeUnit, nSlot);
		end
	end
end

-- customize this so it triggers the BT when a PC is added
function onPCPostAdd(tCustom)
	if fOnPCPostAdd then
		fOnPCPostAdd(tCustom);
	end

	-- Parameter validation
	if not tCustom.nodeCT then
		return;
	end

	for fHandler,_ in pairs(combatantAddedHandlers) do
		fHandler(tCustom.nodeCT);
	end
end

-- Temporary variables to allow adding a distinct effect for Souls without rewriting the whole addNpc flow.
local sSoulsToAdd = nil;
local bLetheImmune = false;
function onNPCPostAdd(tCustom)
	if fOnNPCPostAdd then
		fOnNPCPostAdd(tCustom);
	end

	if tCustom.nodeCT and sSoulsToAdd then
		SoulsManager.initializeSouls(tCustom.nodeCT, sSoulsToAdd, bLetheImmune)
	end
	sSoulsToAdd = nil;
	bLetheImmune = false;

	if EffectManagerADND then
		EffectManagerADND.updateCharEffects(tCustom.nodeRecord, tCustom.nodeCT);
	end

	for fHandler,_ in pairs(combatantAddedHandlers) do
		fHandler(tCustom.nodeCT);
	end
end

function parseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride)
	fParseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride);

	local sName = DB.getValue(nodePower, "name", "");
	local sName = StringManager.trim(sName:lower());
	if sName:match("^souls") then
		sSoulsToAdd = sName:match("%((%d+d%d+)%)");
	elseif sName:match("^lethe immunity") then
		bLetheImmune = true;
	end
	
	local sSoulCost = sName:match("%(costs (%d+[-+]?%d*) souls?%)");
	if sSoulCost then
		if sSoulCost then
			if not StringManager.isNumberString(sSoulCost) then
				sSoulCost = "1";
			end
			local sDisplay = DB.getValue(nodePower, "value", "");
			sDisplay = sDisplay .. "[BURN:" .. sSoulCost .. "]";
			DB.setValue(nodePower, "value", "string", sDisplay);
		end
	end

	local sDesc = DB.getValue(nodePower, "desc", ""):lower();
	sOngoingSouls = sDesc:match("automatically gains (%d+d?%d*%s?[+-]?%s?%d*) souls?");
	if sOngoingSouls and StringManager.isDiceMathString(sOngoingSouls) then
		table.insert(aEffects, "OSOULS: " .. sOngoingSouls:gsub("%s", ""));
	end

	local sSoulIncrease = sDesc:match("adds (%d+d?%d*%s?[+-]?%s?%d*) to %w+ soul count");
	if sSoulIncrease and StringManager.isDiceMathString(sSoulIncrease) then
		local sDisplay = DB.getValue(nodePower, "value", "");
		sDisplay = sDisplay .. "[SOULS:" .. sSoulIncrease:gsub("%s", "") .. "]";
		DB.setValue(nodePower, "value", "string", sDisplay);
	end
end

-- We want to use an exclusively high even value for unit initiative
-- to allow trigger effects appropriately even though units are
-- able to activate in arbitrary order under their commander.
function calculateUnitInitiative()
	local initiatives = {};
	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes("unit")) do
		local initiative = DB.getValue(nodeCombatant, "initresult", 0);
		initiatives[initiative] = true;
	end

	local initiative = 100;
	while initiatives[initiative] do
		initiative = initiative + 2;
	end

	return initiative;
end


-- Used to indicate which commander a newly added unit should be placed under as a result of a drop.
local nodeDropCommander;
function setUnitDropCommander(nodeCommander)
	nodeDropCommander = nodeCommander;
end

function clearUnitDropCommander()
	nodeDropCommander = nil;
end

function addUnit(tCustom)
	if not tCustom.nodeRecord then
		return nil;
	end

	-- Setup
	local aCurrentCombatants = CombatManager.getCombatantNodes("unit");
	tCustom.sTrackerKey = "unit";

	-- Get the name to use for this addition
	local bIsCT = (UtilityManager.getRootNodeName(tCustom.nodeRecord) == CombatManagerKw.BT_MAIN_PATH);
	local sNameLocal = sName;
	if not sNameLocal then
		sNameLocal = DB.getValue(tCustom.nodeRecord, "name", "");
		if bIsCT then
			sNameLocal = CombatManager.stripCreatureNumber(sNameLocal);
		end
	end
	local sNonIDLocal = DB.getValue(tCustom.nodeRecord, "nonid_name", "");
	if sNonIDLocal == "" then
		sNonIDLocal = Interface.getString("library_recordtype_empty_nonid_npc");
	elseif bIsCT then
		sNonIDLocal = CombatManager.stripCreatureNumber(sNonIDLocal);
	end

	local nLocalID = DB.getValue(tCustom.nodeRecord, "isidentified", 1);
	if not bIsCT then
		local sSourcePath = tCustom.nodeRecord.getPath()
		local aMatches = {};
		for _,v in pairs(aCurrentCombatants) do
			local _,sRecord = DB.getValue(v, "sourcelink", "", "");
			if sRecord == sSourcePath then
				table.insert(aMatches, v);
			end
		end
		if #aMatches > 0 then
			nLocalID = 0;
			for _,v in ipairs(aMatches) do
				if DB.getValue(v, "isidentified", 1) == 1 then
					nLocalID = 1;
				end
			end
		end
	end

	local nodeLastMatch = nil;
	if sNameLocal:len() > 0 then
		-- Determine the number of Units with the same name
		local nNameHigh = 0;
		local aMatchesWithNumber = {};
		local aMatchesToNumber = {};
		for _,v in pairs(aCurrentCombatants) do
			local sEntryName = DB.getValue(v, "name", "");
			local sTemp, sNumber = CombatManager.stripCreatureNumber(sEntryName);
			if sTemp == sNameLocal then
				nodeLastMatch = v;

				local nNumber = tonumber(sNumber) or 0;
				if nNumber > 0 then
					nNameHigh = math.max(nNameHigh, nNumber);
					table.insert(aMatchesWithNumber, v);
				else
					table.insert(aMatchesToNumber, v);
				end
			end
		end

		-- If multiple Units of same name, then figure out whether we need to adjust the name based on options
		local sOptNNPC = OptionsManager.getOption("NNPC");
		if sOptNNPC ~= "off" then
			local nNameCount = #aMatchesWithNumber + #aMatchesToNumber;

			for _,v in ipairs(aMatchesToNumber) do
				local sEntryName = DB.getValue(v, "name", "");
				local sEntryNonIDName = DB.getValue(v, "nonid_name", "");
				if sEntryNonIDName == "" then
					sEntryNonIDName = Interface.getString("library_recordtype_empty_nonid_npc");
				end
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nNameHigh);
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sEntryName);
					DB.setValue(v, "name", "string", sNewName);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nSuffix);
				end
			end

			if nNameCount > 0 then
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					sNameLocal = sNameLocal .. " " .. nNameHigh;
					sNonIDLocal = sNonIDLocal .. " " .. nNameHigh;
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sNameLocal);
					sNameLocal = sNewName;
					sNonIDLocal = sNonIDLocal .. " " .. nSuffix;
				end
			end
		end
	end

	tCustom.nodeCT = CombatManager.createCombatantNode(tCustom.sTrackerKey);
	if not tCustom.nodeCT then
		return nil;
	end
	DB.copyNode(tCustom.nodeRecord, tCustom.nodeCT);

	-- Remove any combatant specific information
	DB.setValue(tCustom.nodeCT, "active", "number", 0);
	DB.setValue(tCustom.nodeCT, "tokenrefid", "string", "");
	DB.setValue(tCustom.nodeCT, "tokenrefnode", "string", "");
	DB.deleteChildren(tCustom.nodeCT, "effects");

	-- Set the final name value
	DB.setValue(tCustom.nodeCT, "name", "string", sNameLocal);
	DB.setValue(tCustom.nodeCT, "nonid_name", "string", sNonIDLocal);
	DB.setValue(tCustom.nodeCT, "isidentified", "number", nLocalID);
	DB.setValue(tCustom.nodeCT, "tokenvis", "number", 1);

	-- Lock NPC record view by default when copying to CT
	DB.setValue(tCustom.nodeCT, "locked", "number", 1);

	-- Set up the CT specific information
	DB.setValue(tCustom.nodeCT, "link", "windowreference", "", ""); -- Workaround to force field update on client; client does not pass network update to other clients if setValue creates value node with default value
	DB.setValue(tCustom.nodeCT, "link", "windowreference", "reference_unit", "");
	DB.setValue(tCustom.nodeCT, "friendfoe", "string", "foe");
	if not bIsCT then
		DB.setValue(tCustom.nodeCT, "sourcelink", "windowreference", "reference_unit", tCustom.nodeRecord.getPath());
	end

	-- Calculate space/reach
	DB.setValue(tCustom.nodeCT, "space", "number", 1);
	DB.setValue(tCustom.nodeCT, "reach", "number", 1);

	-- Set default letter token, if no token defined
	local sToken = DB.getValue(tCustom.nodeRecord, "token", "");
	if sToken == "" or not Interface.isToken(sToken) then
		local sLetter = StringManager.trim(sNameLocal):match("^([a-zA-Z])");
		if sLetter then
			sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
		else
			sToken = "tokens/Medium/z.png@Letter Tokens";
		end
		DB.setValue(tCustom.nodeCT, "token", "token", sToken);
	end

	-- set casualty die (aka hit points)
	local nHP = DB.getValue(tCustom.nodeRecord, "casualties", 0);
	DB.setValue(tCustom.nodeCT, "hptotal", "number", nHP);

	-- Add effects to the new ct node from the reference unit's effect list.
	local aEffectsList = DB.getChildren(tCustom.nodeRecord, "effects");
	local aCTNodeEffects = tCustom.nodeCT.createChild("effects");
	for _,v in pairs(aEffectsList) do
		local effectNode = aCTNodeEffects.createChild();
		DB.copyNode(v, effectNode);
	end

	-- Decode traits
	local aTraits = DB.getChildren(tCustom.nodeCT, "traits");
	for _,v in pairs(aTraits) do
		parseUnitTrait(v);
	end

	-- try to find the Commander in the CT and use their initiative and faction
	-- else leave initiative blank and faction = foe
	local nodeCommander = nodeDropCommander or ActorManagerKw.getCommanderCT(tCustom.nodeCT);
	configureUnitCommander(tCustom.nodeCT, nodeCommander);

	DB.setValue(tCustom.nodeCT, "initresult", "number", calculateUnitInitiative());
end

function configureUnitCommander(nodeUnit, nodeCommander)
	if nodeCommander then
		local faction = DB.getValue(nodeCommander, "friendfoe", "foe");
		DB.setValue(nodeUnit, "friendfoe", "string", faction);
		DB.setValue(nodeUnit, "commander_link", "windowreference", "npc", DB.getPath(nodeCommander));
	end
end

function onTurnStart(nodeCT)
	-- Update Exposed for all tokens
	WarfareManager.onTurnStart(nodeCT)
end

function onTurnEnd(nodeCT)
	-- Just process commander turns ending here.
	if ActorManagerKw.isUnit(nodeCT) then
		return;
	end

	local aCurrentCombatants = CombatManager.getCombatantNodes("unit");
	for _,v in pairs(aCurrentCombatants) do
		if ActorManagerKw.getCommanderCT(v) == nodeCT then
			activateUnit(v, true);
		end
	end

	local nodeActive = CombatManagerKw.getActiveUnitCT();
	local nodeFake = DB.createChild(CombatManagerKw.BT_MAIN_PATH, "fake");
	DB.setValue(nodeFake, "commander_link", "windowreference", DB.getValue(nodeActive, "commander_link"));
	DB.setValue(nodeFake, "hptotal", "number", 1);
	DB.setValue(nodeFake, "initresult", "number", DB.getValue(nodeActive, "initresult", 98) - 1);
	DB.setValue(nodeFake, "link", "windowreference", "reference_unit", "");

	activateUnit(nodeFake, true);
	DB.deleteNode(nodeFake);
end

function onRoundStart(nCurRound)
	-- This gets set to the first unit on the combat tracker
	-- it is ONLY used to pass to the warfare manager so that the manager can get
	-- which image the token is on in order to check if any ranks have collapsed
	-- CAVEAT: This will fail if units are on multiple maps. So just don't do that.
	local anyUnit = nil;
	local aCurrentCombatants = CombatManager.getCombatantNodes("unit");
	for _,v in pairs(aCurrentCombatants) do
		if ActorManagerKw.isUnit(v) then
			DB.setValue(v, "activated", "number", 0);
			if anyUnit == nil then
				anyUnit = v;
			end
		end
	end

	WarfareManager.onNewRound(anyUnit);
end

function canUnitActivate(nodeUnit, bCommanderIsActive)
	-- Uncommanded units cannot activate.
	local nodeCommander = ActorManagerKw.getCommanderCT(nodeUnit)
	if not nodeCommander then
		return false;
	end

	-- Users can only activate their own units.
	if not Session.IsHost then
		local rActor = ActorManager.resolveActor(nodeCommander);
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if not (nodeActor and (nodeActor.getOwner() == User.getUsername())) then
			return false;
		end
	end

	-- Units can only activate on their commander's turn if they are unbroken and haven't already activated
	return (bCommanderIsActive or (DB.getValue(nodeCommander, "active", 0) == 1)) and
		(DB.getValue(nodeUnit, "active", 0) == 0) and
		(DB.getValue(nodeUnit, "activated", 0) == 0) and
		(DB.getValue(nodeUnit, "wounds", 0) < DB.getValue(nodeUnit, "hptotal"));
end

function requestUnitActivation(nodeEntry, bSkipBell)
	-- De-activate all other entries
	for _,v in pairs(CombatManager.getCombatantNodes("unit")) do
		if DB.getValue(v, "active", 0) == 1 then
			DB.setValue(v, "active", "number", 0);
			DB.setValue(v, "activated", "number", 1);
		end
	end
	
	-- Set active flag
	DB.setValue(nodeEntry, "active", "number", 1);

	-- Turn notification
	CombatManager.showTurnMessage(nodeEntry, true, bSkipBell);

	-- Handle GM identity list updates (based on option)
	CombatManager.clearGMIdentity();
	CombatManager.addGMIdentity(nodeEntry);
end

--
-- HANDLING START/END OF TURN FOR UNIT ACTIVATION
--
function notifyActivateUnit(nodeUnit)
	if canUnitActivate(nodeUnit) then
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_ACTIVATEUNIT;
		msgOOB.unit = nodeUnit.getPath();

		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function handleActivateUnit(msgOOB)
	local nodeNext = DB.findNode(msgOOB.unit);
	activateUnit(nodeNext);
end

function activateUnit(nodeNext, bCommanderIsActive)
	if nodeNext and CombatManagerKw.canUnitActivate(nodeNext, bCommanderIsActive) then
		local nodeActive = CombatManagerKw.getActiveUnitCT();
		CombatManager.onTurnEndEvent(nodeActive);

		local activeInit;
		if nodeActive then
			activeInit = DB.getValue(nodeActive, "initresult", 98);
			DB.setValue(nodeActive, "initresult", "number", DB.getValue(nodeNext, "initResult", 98) + 1);
		end

		CombatManager.onInitChangeEvent(nodeActive, nodeNext);

		if nodeActive then
			DB.setValue(nodeActive, "initresult", "number", activeInit);
		end

		CombatManagerKw.requestUnitActivation(nodeNext);
		CombatManager.onTurnStartEvent(nodeNext);
	end
end

function parseUnitTrait(nodeTrait)
	local sDisplay = DB.getValue(nodeTrait, "name", "");
	local aDisplayOptions = {};

	local sName = StringManager.trim(sDisplay:lower());

	-- Handle all the other traits and actions (i.e. look for recharge, attacks, damage, saves, reach, etc.)
	local aAbilities = PowerManagerKw.parseUnitTrait(nodeTrait);
	for _,v in ipairs(aAbilities) do			
		if v.type == "unitsavedc" then
			local line =  "[TEST:";
			if v.savemod then
				line = line .. " DC " .. v.savemod;
			end
			if DataCommon.ability_ltos[v.stat] then
				line = line .. " " .. DataCommon.ability_ltos[v.stat] .. "]"
			else
			end

			table.insert(aDisplayOptions, line);

		elseif v.type == "damage" then
			local aDmgDisplay = {};
			for _,vClause in ipairs(v.clauses) do
				local sDmg = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
				if vClause.dmgtype and vClause.dmgtype ~= "" then
					sDmg = sDmg .. " " .. vClause.dmgtype;
				end
				table.insert(aDmgDisplay, sDmg);
			end
			table.insert(aDisplayOptions, string.format("[DMG: %s]", table.concat(aDmgDisplay, " + ")));

		elseif v.type == "heal" then
			local aHealDisplay = {};
			for _,vClause in ipairs(v.clauses) do
				local sHeal = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
				table.insert(aHealDisplay, sHeal);
			end

			local sHeal = table.concat(aHealDisplay, " + ");
			if v.subtype then
				sHeal = sHeal .. " " .. v.subtype;
			end

			table.insert(aDisplayOptions, string.format("[HEAL: %s]", sHeal));

		elseif v.type == "effect" then
			table.insert(aDisplayOptions, EffectManager5E.encodeEffectForCT(v));

		end

		-- Remove recharge in title, and move to details
		local sRecharge = string.match(sName, "recharge (%d)");
		if sRecharge then
			sDisplay = string.gsub(sDisplay, "%s?%([Rr]echarge %d[-�]*%d?%)", "");
			table.insert(aDisplayOptions, "[R:" .. sRecharge .. "]");
		end
	end

	-- Set the value field to the short version
	if #aDisplayOptions > 0 then
		sDisplay = sDisplay .. " " .. table.concat(aDisplayOptions, " ");
	end
	DB.setValue(nodeTrait, "value", "string", sDisplay);
end

function parseAttackLine(sLine)
	local rPower = fParseAttackLine(sLine);


	local nIntroStart, nIntroEnd, sName = sLine:find("([^%[]*)[%[]?");
	if nIntroStart then
		if not rPower.name then
			rPower.name = StringManager.trim(sName);
		end
		if not rPower.aAbilities then
			rPower.aAbilities = {};
		end

		nIndex = nIntroEnd;
		local nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nIntroEnd);
		while nAbilityStart do
			if sAbility:sub(1,5) == "TEST:" and #sAbility > 5 then
				local aWords = StringManager.parseWords(sAbility:sub(7));
				
				local rSave = {};
				rSave.sType = "unitsavedc";
				local sDC, sStat = sAbility:sub(7):match("DC (%d+)%s*(%a+)");
				rSave.nStart = nAbilityStart + 1;
				rSave.nEnd = nAbilityEnd;
				rSave.stat = DataCommon.ability_stol[sStat] or "";
				rSave.label = rPower.name;
				if sDC then
					rSave.savemod = tonumber(sDC) or 0;
				end
				table.insert(rPower.aAbilities, rSave);
			elseif sAbility:sub(1,5) == "BURN:" then
				local rSoulBurn = {};
				rSoulBurn.sType = "burn";
				rSoulBurn.nStart = nAbilityStart + 1;
				rSoulBurn.nEnd = nAbilityEnd;
				rSoulBurn.label = rPower.name;
				rSoulBurn.nBurn = tonumber(sAbility:sub(6):match("(%d+)")) or 0;
				table.insert(rPower.aAbilities, rSoulBurn);
			elseif sAbility:sub(1,6) == "SOULS:" then
				local rSoulGain = {};
				rSoulGain.sType = "souls";
				rSoulGain.nStart = nAbilityStart + 1;
				rSoulGain.nEnd = nAbilityEnd;
				rSoulGain.label = "Increase Soul Count";
				rSoulGain.sTargeting = "self";
				rSoulGain.aDice, rSoulGain.nMod = StringManager.convertStringToDice(sAbility:sub(7));
				table.insert(rPower.aAbilities, rSoulGain);
			end
			
			nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nAbilityEnd + 1);
		end
	end

	return rPower;
end