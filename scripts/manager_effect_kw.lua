-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOnEffectActorStartTurn;
local fCheckConditional;
local fIsTargetedEffect;
local fParseEffectComp;
local fGetEffectsByType;
local fApplyOngoingDamageAdjustment

local bGettingEffects;
local nodeCurrentEffect;

function onInit()
	fIsTargetedEffect = EffectManager.isTargetedEffect;
	EffectManager.isTargetedEffect = isTargetedEffect;
	
	fParseEffectComp = EffectManager5E.parseEffectComp;
	EffectManager5E.parseEffectComp = parseEffectComp;

	fGetEffectsByType = EffectManager5E.getEffectsByType;
	EffectManager5E.getEffectsByType = getEffectsByType;

	fCheckConditional = EffectManager5E.checkConditional;
	EffectManager5E.checkConditional = checkConditional;

	fApplyOngoingDamageAdjustment = EffectManager5E.applyOngoingDamageAdjustment;
	EffectManager5E.applyOngoingDamageAdjustment = applyOngoingDamageAdjustment;

	fOnEffectActorStartTurn = EffectManager5E.onEffectActorStartTurn
	EffectManager.setCustomOnEffectActorStartTurn(onEffectActorStartTurn);
	EffectManager.setCustomOnEffectActorEndTurn(onEffectActorEndTurn)
end

function onEffectActorStartTurn(nodeActor, nodeEffect)
	fOnEffectActorStartTurn(nodeActor, nodeEffect);

	local sEffName = DB.getValue(nodeEffect, "label", "");
	local aEffectComps = EffectManager.parseEffect(sEffName);
	for _,sEffectComp in ipairs(aEffectComps) do
		local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);

		-- Check for damage tokens
		if StringManager.contains(KingdomsAndWarfare.aDamageTokenTypes, rEffectComp.type:lower()) or
				StringManager.contains(KingdomsAndWarfare.aDamageTokenTypes, rEffectComp.original:lower()) then
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			if nActive == 1 then
				applyTokenDamage(nodeActor, nodeEffect, rEffectComp);
			end

		elseif rEffectComp.type == "OSOULS" then
			SoulsManager.applyOngoingSouls(nodeActor, nodeEffect, rEffectComp)
		end
	end
end

function applyTokenDamage(nodeActor, nodeEffect, rEffectComp)
	local rTarget = ActorManager.resolveActor(nodeActor);

	local rAction = {};
	rAction.label = "Ongoing damage";
	rAction.clauses = {};

	-- For tokens, duration can be used to track damage
	local nDuration = DB.getValue(nodeEffect, "duration", 0);
	if nDuration > 0 then
		local aClause = {};
		aClause.dice = {};

		-- Nothing in the book has tokens dealing variable damage, but it could be possible
		-- so handle it here
		for k,v in pairs(rEffectComp.dice) do
			for i=1, nDuration do
				table.insert(aClause.dice, v);
			end
		end

		-- Dmg is a minimum of 1, and multiply duration by damage per turn
		local nDmg = rEffectComp.mod;
		if nDmg == 0 then nDmg = 1; end
		aClause.modifier = nDuration * nDmg;
		
		-- Bleed, Acid, Poison, or Fire
		if rEffectComp.type or "" == "" then
			rEffectComp.type = rEffectComp.original;
		end
		aClause.dmgtype = rEffectComp.type:lower();

		table.insert(rAction.clauses, aClause);

		local rRoll = ActionDamage.getRoll(nil, rAction);
		if EffectManager.isGMEffect(nodeActor, nodeEffect) then
			rRoll.bSecret = true;
		end

		ActionsManager.actionDirect(nil, "damage", { rRoll }, { { rTarget } });
	end
end

function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
	if ActorManagerKw.isUnit(rActor) then
		local bReturn = true;
		
		if not aIgnore then
			aIgnore = {};
		end
		table.insert(aIgnore, nodeEffect.getPath());

		for _,v in ipairs(aConditions) do
			local sLower = v:lower();
			if sLower == "diminished" then
				local nPercentWounded = ActorHealthManager.getWoundPercent(rActor);
				if nPercentWounded < .5 then
					bReturn = false;
					break;
				end
			elseif sLower == "stronger" then
				if not rTarget then
					bReturn = false;
					break;
				end
				local nActorHp = ActorManagerKw.getUnitCurrentHP(rActor);
				local nTargetHp = ActorManagerKw.getUnitCurrentHP(rTarget);
				if nActorHp <= nTargetHp then
					bReturn = false;
					break;
				end
			elseif sLower == "weaker" then
				if not rTarget then
					bReturn = false;
					break;
				end
				local nActorHp = ActorManagerKw.getUnitCurrentHP(rActor);
				local nTargetHp = ActorManagerKw.getUnitCurrentHP(rTarget);
				if nActorHp >= nTargetHp then
					bReturn = false;
					break;
				end
			elseif StringManager.contains(DataCommon.conditions, sLower) then
				if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
					bReturn = false;
					break;
				end
			elseif StringManager.contains(DataCommon.conditionaltags, sLower) then
				if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
					bReturn = false;
					break;
				end
			else
				local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
				local sAncestryCheck = sLower:match("^ancestry%s*%(([^)]+)%)$");
				local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
				if sTypeCheck then
					local aTypes = StringManager.split(sTypeCheck, ',');
					local bMatch = false;
					for _,type in pairs(aTypes) do
						if type then
							local sTypeLower = StringManager.trim(type):lower();
							if ActorManagerKw.isUnitType(rActor, sTypeLower) then
								bMatch = true;
								break; 
							end
						end
					end

					if not bMatch then
						bReturn = false;
						break;
					end
				elseif sAncestryCheck then
					local aAncestry = StringManager.split(sAncestryCheck, ',');
					local bMatch = false;
					for _,ancestry in pairs(aAncestry) do
						if ancestry then
							local sAncestryLower = StringManager.trim(ancestry):lower();
							if ActorManagerKw.isUnitAncestry(rActor, sAncestryLower) then
								bMatch = true;
								break; 
							end
						end
					end

					if not bMatch then
						bReturn = false;
						break;
					end
				elseif sCustomCheck then
					if not EffectManager5E.checkConditionalHelper(rActor, sCustomCheck, rTarget, aIgnore) then
						bReturn = false;
						break;
					end
				end
			end
		end

		table.remove(aIgnore);

		return bReturn;
	else
		local result =  fCheckConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore);
		if result then
			for _,sCondition in ipairs(aConditions) do
				local sLower = sCondition:lower();
				local sOperator,sCount = sLower:match("^souls%s*%(([<=>]*)(%d+)%)$");
				if sOperator and sCount then
					local nSouls = 0;
					for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
						local nActive = DB.getValue(v, "isactive", 0);
						if nActive ~= 0 then
							local sLabel = DB.getValue(v, "label", "");
							local sSouls = sLabel:lower():match("^souls:%s*(%d+)");
							if sSouls then
								nSouls = nSouls + tonumber(sSouls);
							end
						end
					end

					if sOperator == ">" then
						return nSouls > tonumber(sCount);
					elseif sOperator == ">=" then
						return nSouls >= tonumber(sCount);
					elseif sOperator == "<" then
						return nSouls < tonumber(sCount);
					elseif sOperator == "<=" then
						return nSouls <= tonumber(sCount);
					else
						return nSouls == tonumber(sCount);
					end
				end
			end
		end
		return result;
	end
end

--
-- POWER DIE HANDLING
--

function onEffectActorEndTurn(nodeActor, nodeEffect)
	local sEffect = DB.getValue(nodeEffect, "label", ""):lower();
	if sEffect:match("decrement") then
		local newTotal = ActorManagerKw.decrementPowerDie(ActorManager.resolveActor(nodeActor));
		-- if the power die was decremented to 0, then remove this effect as well
		if (newTotal or 0) <= 0 then
			EffectManager.notifyExpire(nodeEffect, 0, true);
		end
	end
end

function isTargetedEffect(nodeEffect)
	if bGettingEffects then
		nodeCurrentEffect = nodeEffect;
	end
	return fIsTargetedEffect(nodeEffect);
end

function parseEffectComp(s)
	if nodeCurrentEffect then
		s = s:gsub("%d*x? ?%-?PDIE", function(sMatch)
			sMult, sNegative = sMatch:match("^(%d*)x? ?(%-?)");
			local nMult = 1;
			if sMult ~= "" then
				nMult = tonumber(sMult);
			end
			if sNegative ~= "" then
				nMult = -nMult;
			end
			local rActor = getSourceOfEffect(nodeCurrentEffect);
			if not rActor then
				rActor = ActorManager.resolveActor(DB.getChild(nodeCurrentEffect, "..."));
			end
			local nPowerDie = getPowerDieEffect(rActor);
			return tostring(nPowerDie * nMult);
		end);
	end
	return fParseEffectComp(s);
end

function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	bGettingEffects = true;
	local result = fGetEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly);
	bGettingEffects = false;
	nodeCurrentEffect = nil;
	return result;
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
	rEffectComp.node = nodeEffect.getPath();
	resolvePowerDie(ActorManager.resolveActor(nodeActor), rEffectComp);
	fApplyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp);
end

function resolvePowerDie(rActor, rEffectComp)
	if not rEffectComp then
		return;
	end

	local bPowerDie = false;
	local bNegative = false;
	local nMult = 1;
	local newRemainder = {};
	for k,v in pairs(rEffectComp.remainder or {}) do 
		local sLower = v:lower();
		if sLower:match("-pdie") then
			bPowerDie = true;
			bNegative = true;
		elseif sLower:match("pdie") then
			bPowerDie = true;
		else
			-- Do not add this power die to the final remainder list, since other effects will act weird if there's an un-used remainder value (namely RESIST/VULN/IMMUNE)
			table.insert(newRemainder, v);
		end

		local mult = sLower:match("(%d+)x")
		if mult then
			nMult = tonumber(mult);
		end
	end
	
	if bPowerDie then
		-- Get and add power die (with multiplier) to effect modifier
		local rSource = nil;

		-- First try to set rSource based on the source of the effect node
		if rEffectComp.node then
			rSource = getSourceOfEffect(DB.findNode(rEffectComp.node))
		end
		-- If there's no source, use rActor
		if not rSource then
			rSource = rActor;
		end
		
		local nPowerDie = getPowerDieEffect(rSource);
		local nMod = nMult * nPowerDie;
		if bNegative then
			nMod = nMod * -1;
		end
		rEffectComp.mod = rEffectComp.mod + nMod;
		rEffectComp.remainder = newRemainder;
	end
	return rEffectComp;
end

function getSourceOfEffect(nodeEffect)
	if not nodeEffect then 
		return;
	end

	local source = DB.getValue(nodeEffect, "source_name", "");
	local rActor = ActorManager.resolveActor(source);
	return rActor;
end

function getPowerDieEffect(rActor)
	return getEffect(rActor, "powerdie");
end

function getEffect(rActor, sEffect)
	if not rActor then
		return 0, nil, 0;
	end

	-- Iterate through effects
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		if (nActive ~= 0) then
			local sLabel = DB.getValue(v, "label", "");
			local aEffectComps = EffectManager.parseEffect(sLabel);

			for kEffectComp,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);

				-- check if the type matches, or if the original matches
				if (rEffectComp.type:lower() == sEffect) then
					return rEffectComp.mod or 0, v, kEffectComp;
				end
			end
		end
	end

	return 0, nil, 0;
end