-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYDMG = "applydmg";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);

	ActionsManager.registerModHandler("damage", modDamage);
	ActionsManager.registerModHandler("spdamage", modSpellDamage);
	ActionsManager.registerModHandler("stabilization", modStabilization);

	ActionsManager.registerPostRollHandler("damage", onDamageRoll);
	ActionsManager.registerPostRollHandler("spdamage", onDamageRoll);
	
	ActionsManager.registerResultHandler("damage", onDamage);
	ActionsManager.registerResultHandler("spdamage", onDamage);
	ActionsManager.registerResultHandler("stabilization", onStabilization);
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end
	
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sRollType, msgOOB.sDamage, nTotal);
end

function notifyApplyDamage(rSource, rTarget, bSecret, sRollType, sDesc, nTotal)
	if not rTarget then
		return;
	end
	local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
	if sTargetType ~= "pc" and sTargetType ~= "ct" then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMG;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sRollType = sRollType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDamage = sDesc;
	msgOOB.sTargetType = sTargetType;
	msgOOB.sTargetNode = sTargetNode;
	msgOOB.nTargetOrder = rTarget.nOrder;

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	Comm.deliverOOBMessage(msgOOB, "");
end

function performStabilizationRoll(rActor)
	local rRoll = GameSystem.getStabilizationRoll(rActor);

	ActionsManager.performAction(nil, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "damage";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[DAMAGE";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range ..")";
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	
	-- Add ability modifiers and multiples
	if rAction.stat ~= "" then
		if (rAction.range == "M" and rAction.statmult ~= 1) or (rAction.range == "R" and rAction.statmult ~= 0) then
			rRoll.sDesc = rRoll.sDesc .. " [MULT:" .. rAction.statmult .. "]";
		end
	end
	if (rAction.stat ~= "strength" and rAction.statmult ~= 0) or (rAction.statmax and rAction.statmax > 0) then
		local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect;
			if rAction.statmax and rAction.statmax > 0 then
				rRoll.sDesc = rRoll.sDesc .. ":" .. rAction.statmax;
			end
			rRoll.sDesc = rRoll.sDesc .. "]";
		end
	end
	if rAction.stat2 ~= "" then
		local sAbilityEffect = DataCommon.ability_ltos[rAction.stat2];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD2:" .. sAbilityEffect .. "]";
		end
	end
	
	-- Iterate through damage clauses to get dice, modifiers and damage types
	local aDamageTypes = {};
	for k, v in pairs(rAction.clauses) do
		local nClauseDice = 0;
		local nClauseMod = 0;
		local nClauseMult = v.mult or 2;
		
		for kDie, vDie in ipairs(v.dice) do
			table.insert(rRoll.aDice, vDie);
			nClauseDice = nClauseDice + 1;
		end
			
		nClauseMod = v.modifier;
		rRoll.nMod = rRoll.nMod + v.modifier;
		
		if (nClauseDice > 0) or (nClauseMod ~= 0) then
			table.insert(aDamageTypes, { sType = v.dmgtype, nDice = nClauseDice, nMod = nClauseMod, nMult = nClauseMult } );
		end
	end
	if #aDamageTypes > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. encodeDamageTypes(aDamageTypes);
	end

	if rAction.meta then
		if rAction.meta == "empower" then
			rRoll.sDesc = rRoll.sDesc .. " [EMPOWER]";
		elseif rAction.meta == "maximize" then
			rRoll.sDesc = rRoll.sDesc .. " [MAXIMIZE]";
		end
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modStabilization(rSource, rTarget, rRoll)
	GameSystem.modStabilization(rSource, rTarget, rRoll);
end

function modDamage(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	local bPFMode = DataCommon.isPFRPG();
	
	-- Build attack type filter
	local aAttackFilter = {};
	local sAttackType = string.match(rRoll.sDesc, "%[DAMAGE%s*%(([^%)%]]+)%)%]");
	if sAttackType == "R" then
		table.insert(aAttackFilter, "ranged");
	elseif sAttackType == "M" then
		table.insert(aAttackFilter, "melee");
	end
	
	local aDamageTypes = decodeDamageTypes(false, rRoll.sDesc, rRoll.aDice, rRoll.nMod);
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE: ([^]]+)%]", "");
	
	-- IS CRITICAL?
	local bCritical = ModifierStack.getModifierKey("DMG_CRIT") or Input.isShiftPressed();
	if rTarget then
		if ActionAttack.isCrit(rSource, rTarget) then
			bCritical = true;
		end
	end
	if bCritical then
		local aAddDamageTypes = {};
		table.insert(aAddDesc, "[CRITICAL]");

		local nDiceIndex = 0;
		for _,v in pairs(aDamageTypes) do
			local nMult = v.nMult or 2;
			if nMult > 1 then
				for i = 2, nMult do
					for j = 1, v.nDice do
						local nIndex = nDiceIndex + j;
						if nIndex <= #(rRoll.aDice) then
							local sDie = rRoll.aDice[nIndex];
							if type(sDie) == "table" then
								sDie = sDie.type;
							end
							table.insert(aAddDice, "g" .. string.sub(sDie, 2));
						end
					end
					nAddMod = nAddMod + v.nMod;
				end
				nDiceIndex = nDiceIndex + v.nDice;
				
				table.insert(aAddDamageTypes, { sType = v.sType, nDice = v.nDice * (nMult - 1), nMod = v.nMod * (nMult - 1), nMult = v.nMult });
			end
		end
		
		for _,v in ipairs(aAddDamageTypes) do
			table.insert(aDamageTypes, v);
		end
	end
	
	-- IS HALF?
	local bHalf = ModifierStack.getModifierKey("DMG_HALF");
	if bHalf then
		table.insert(aAddDesc, "[HALF]");
	end
	
	if rSource then
		local bEffects = false;

		-- GET STATS AND MULTIPLES
		local nMult = 1;
		if sAttackType == "R" then
			nMult = 0;
		end
		local sModMult = string.match(rRoll.sDesc, "%[MULT:([%d.]+)%]");
		if sModMult then
			nMult = tonumber(sModMult) or nMult;
			if nMult < 0 then
				nMult = 1;
			end
		end
		local sActionStat = nil;
		local nActionStatMax = 0;
		local sModStat, sModMax = string.match(rRoll.sDesc, "%[MOD:(%w+):?(%d*)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
			nActionStatMax = tonumber(sModMax) or 0;
		end
		if not sActionStat then
			sActionStat = "strength";
		end
		local sActionStat2 = nil;
		local sModStat2 = string.match(rRoll.sDesc, "%[MOD2:%w+%]");
		if sModStat2 then
			sActionStat2 = DataCommon.ability_stol[sModStat2];
		end

		-- NOTE: Effect damage dice are not multiplied on critical, though numerical modifiers are multiplied
		-- http://rpg.stackexchange.com/questions/4465/is-smite-evil-damage-multiplied-by-a-critical-hit
		-- NOTE: Using damage type of the first damage clause for the bonuses
		local aEffectDice = {};
		local nEffectMod = 0;

		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects;
		if nMult > 0 then
			-- Get original stat modifier
			local nActionStatMod = ActorManager2.getAbilityBonus(rSource, sActionStat);
			
			-- Get modified stat modifier
			nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
			if nBonusEffects > 0 then
				bEffects = true;
			end
			local nTotalStatMod = nActionStatMod + nBonusStat;
			
			-- Handle maximums
			-- WORKAROUND: If max limited, then assume bows which allow no penalty
			if nActionStatMax > 0 then
				nActionStatMod = math.max(math.min(nActionStatMod, nActionStatMax), 0);
				nTotalStatMod = math.max(math.min(nTotalStatMod, nActionStatMax), 0);
			end
			
			-- Handle multipliers correctly (i.e. negative values are not multiplied, but positive values are)
			local nMultOrigStatMod, nMultNewStatMod;
			if nActionStatMod <= 0 then
				nMultOrigStatMod = nActionStatMod;
			else
				nMultOrigStatMod = math.floor(nActionStatMod * nMult);
			end
			if nTotalStatMod <= 0 then
				nMultNewStatMod = nTotalStatMod;
			else
				nMultNewStatMod = math.floor(nTotalStatMod * nMult);
			end
			
			-- Calculate bonus difference and apply
			local nMultDiffStatMod = nMultNewStatMod - nMultOrigStatMod;
			nEffectMod = nEffectMod + nMultDiffStatMod;
		end
		nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat2);
		if nBonusEffects > 0 then
			bEffects = true;
			nEffectMod = nEffectMod + nBonusStat;
		end

		-- GET CONDITION MODIFIERS
		if EffectManager.hasEffectCondition(rSource, "Sickened") then
			nEffectMod = nEffectMod - 2;
			bEffects = true;
		end
		if bPFMode then
			if EffectManager.hasEffect(rSource, "Incorporeal") and sAttackType == "M" and not string.match(string.lower(rRoll.sDesc), "incorporeal touch") then
				bEffects = true;
				table.insert(aAddDesc, "[INCORPOREAL]");
			end
		end

		-- APPLY CRITICAL MULTIPLIER TO EFFECTS SO FAR
		if bCritical then
			local nEffectCritMult = 2;
			if #aDamageTypes > 0 then
				nEffectCritMult = aDamageTypes[1].nMult or 2;
			end
			
			nEffectMod = nEffectMod * nEffectCritMult;
		end
		
		-- GET GENERAL DAMAGE MODIFIERS
		local aEffects, nEffectCount = EffectManager.getEffectsBonusByType(rSource, "DMG", true, aAttackFilter, rTarget);
		if nEffectCount > 0 then
			bEffects = true;
			
			local nEffectCritMult = 2;
			local sEffectBaseType = "";
			if #aDamageTypes > 0 then
				nEffectCritMult = aDamageTypes[1].nMult or 2;
				sEffectBaseType = aDamageTypes[1].sType or "";
			end
			
			for _,v in pairs(aEffects) do
				for _,v2 in ipairs(v.dice) do
					table.insert(aEffectDice, v2);
				end
				
				local nCurrentMod;
				if bCritical then
					nCurrentMod = (v.mod * nEffectCritMult);
				else
					nCurrentMod = v.mod;
				end
				nEffectMod = nEffectMod + nCurrentMod;
				
				local aEffectDmgType = {};
				if sEffectBaseType ~= "" then
					table.insert(aEffectDmgType, sEffectBaseType);
				end
				for kWord, sWord in ipairs(v.remainder) do
					if StringManager.contains(DataCommon.dmgtypes, sWord) then
						table.insert(aEffectDmgType, sWord);
					end
				end
				if #aEffectDmgType > 0 then
					table.insert(aDamageTypes, { sType = table.concat(aEffectDmgType, ","), nDice = #(v.dice), nMod = nCurrentMod, nMult = nEffectCritMult });
				else
					table.insert(aDamageTypes, { sType = "", nDice = #(v.dice), nMod = nCurrentMod, nMult = nEffectCritMult });
				end
			end
		end
		
		-- GET DAMAGE TYPE MODIFIER
		local aEffects = EffectManager.getEffectsByType(rSource, "DMGTYPE", {});
		local aAddTypes = {};
		for _,v in ipairs(aEffects) do
			for _,v2 in ipairs(v.remainder) do
				local aSplitTypes = StringManager.split(v2, ",", true);
				for _,v3 in ipairs(aSplitTypes) do
					table.insert(aAddTypes, v3);
				end
			end
		end
		if #aAddTypes > 0 then
			for _,v in ipairs(aDamageTypes) do
				local aSplitTypes = StringManager.split(v.sType, ",", true);
				for _,v2 in ipairs(aAddTypes) do
					if not StringManager.contains(aSplitTypes, v2) then
						if v.sType ~= "" then
							v.sType = v.sType .. "," .. v2;
						else
							v.sType = v2;
						end
					end
				end
			end
		end
		
		-- IF EFFECTS HAPPENED, THEN ADD NOTE
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
			
			for _,vDie in ipairs(aEffectDice) do
				table.insert(aAddDice, "p" .. string.sub(vDie, 2));
			end
			nAddMod = nAddMod + nEffectMod;
		end
	end
	
	if #aDamageTypes > 0 then
		table.insert(aAddDesc, encodeDamageTypes(aDamageTypes));
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		table.insert(rRoll.aDice, vDie);
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function modSpellDamage(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	local aDamageTypes = decodeDamageTypes(false, rRoll.sDesc, rRoll.aDice, rRoll.nMod);
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE: ([^]]+)%]", "");
	
	-- IS CRITICAL?
	local bCritical = ModifierStack.getModifierKey("DMG_CRIT") or Input.isShiftPressed();
	if bCritical then
		local aAddDamageTypes = {};
		table.insert(aAddDesc, "[CRITICAL]");

		local nDiceIndex = 0;
		for _,v in pairs(aDamageTypes) do
			local nMult = v.nMult or 2;
			if nMult > 1 then
				for i = 2, nMult do
					for j = 1, v.nDice do
						local nIndex = nDiceIndex + j;
						if nIndex <= #(rRoll.aDice) then
							local sDie = rRoll.aDice[nIndex];
							table.insert(aAddDice, "g" .. string.sub(sDie, 2));
						end
					end
					nAddMod = nAddMod + v.nMod;
				end
				nDiceIndex = nDiceIndex + v.nDice;
				
				table.insert(aAddDamageTypes, { sType = v.sType, nDice = v.nDice * (nMult - 1), nMod = v.nMod * (nMult - 1), nMult = v.nMult });
			end
		end
		
		for _,v in ipairs(aAddDamageTypes) do
			table.insert(aDamageTypes, v);
		end
	end
	
	-- IS HALF?
	local bHalf = ModifierStack.getModifierKey("DMG_HALF");
	if bHalf then
		table.insert(aAddDesc, "[HALF]");
	end
	
	if rSource then
		local bEffects = false;

		-- GET STATS AND MULTIPLES
		local sActionStat = nil;
		local nActionStatMax = 0;
		local sModStat, sModMax = string.match(rRoll.sDesc, "%[MOD:(%w+):?(%d*)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
			nActionStatMax = tonumber(sModMax) or 0;
		end
		local sActionStat2 = nil;
		local sModStat2 = string.match(rRoll.sDesc, "%[MOD2:%w+%]");
		if sModStat2 then
			sActionStat2 = DataCommon.ability_stol[sModStat2];
		end

		-- NOTE: Effect damage dice are not multiplied on critical, though numerical modifiers are multiplied
		-- http://rpg.stackexchange.com/questions/4465/is-smite-evil-damage-multiplied-by-a-critical-hit
		-- NOTE: Using damage type of the first damage clause for the bonuses
		local aEffectDice = {};
		local nEffectMod = 0;

		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects;
		if sActionStat then
			nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);

			if nBonusEffects > 0 then
				bEffects = true;

				local nActionStatMod = ActorManager2.getAbilityBonus(rSource, sActionStat);
				if nBonusStat > 0 and nActionStatMax > 0 then
					nBonusStat = math.min(nBonusStat, nActionStatMax);
				end

				nEffectMod = nEffectMod + nBonusStat;
			end
		end
		if sActionStat2 then
			nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat2);
			if nBonusEffects > 0 then
				bEffects = true;
				nEffectMod = nEffectMod + nBonusStat;
			end
		end

		-- APPLY CRITICAL MULTIPLIER TO EFFECTS SO FAR
		if bCritical then
			local nEffectCritMult = 2;
			if #aDamageTypes > 0 then
				nEffectCritMult = aDamageTypes[1].nMult or 2;
			end
			
			nEffectMod = nEffectMod * nEffectCritMult;
		end
		
		-- GET GENERAL DAMAGE MODIFIERS
		local aEffects, nEffectCount = EffectManager.getEffectsBonusByType(rSource, "DMGS", true, nil);
		if nEffectCount > 0 then
			bEffects = true;
			
			local nEffectCritMult = 2;
			local sEffectBaseType = "";
			if #aDamageTypes > 0 then
				nEffectCritMult = aDamageTypes[1].nMult or 2;
				sEffectBaseType = aDamageTypes[1].sType or "";
			end
			
			for _,v in pairs(aEffects) do
				for _,v2 in ipairs(v.dice) do
					table.insert(aEffectDice, v2);
				end
				
				local nCurrentMod;
				if bCritical then
					nCurrentMod = (v.mod * nEffectCritMult);
				else
					nCurrentMod = v.mod;
				end
				nEffectMod = nEffectMod + nCurrentMod;
				
				local aEffectDmgType = {};
				if sEffectBaseType ~= "" then
					table.insert(aEffectDmgType, sEffectBaseType);
				end
				for kWord, sWord in ipairs(v.remainder) do
					if StringManager.contains(DataCommon.dmgtypes, sWord) then
						table.insert(aEffectDmgType, sWord);
					end
				end
				if #aEffectDmgType > 0 then
					table.insert(aDamageTypes, { sType = table.concat(aEffectDmgType, ","), nDice = #(v.dice), nMod = nCurrentMod, nMult = nEffectCritMult });
				else
					table.insert(aDamageTypes, { sType = "", nDice = #(v.dice), nMod = nCurrentMod, nMult = nEffectCritMult });
				end
			end
		end
		
		-- GET DAMAGE TYPE MODIFIER
		local aEffects = EffectManager.getEffectsByType(rSource, "DMGTYPE", {});
		local aAddTypes = {};
		for _,v in ipairs(aEffects) do
			for _,v2 in ipairs(v.remainder) do
				local aSplitTypes = StringManager.split(v2, ",", true);
				for _,v3 in ipairs(aSplitTypes) do
					table.insert(aAddTypes, v3);
				end
			end
		end
		if #aAddTypes > 0 then
			for _,v in ipairs(aDamageTypes) do
				local aSplitTypes = StringManager.split(v.sType, ",", true);
				for _,v2 in ipairs(aAddTypes) do
					if not StringManager.contains(aSplitTypes, v2) then
						if v.sType ~= "" then
							v.sType = v.sType .. "," .. v2;
						else
							v.sType = v2;
						end
					end
				end
			end
		end
		
		-- IF EFFECTS HAPPENED, THEN ADD NOTE
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
			
			for _,vDie in ipairs(aEffectDice) do
				table.insert(aAddDice, "p" .. string.sub(vDie, 2));
			end
			nAddMod = nAddMod + nEffectMod;
		end
	end
	
	if #aDamageTypes > 0 then
		table.insert(aAddDesc, encodeDamageTypes(aDamageTypes));
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		table.insert(rRoll.aDice, vDie);
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onDamageRoll(rSource, rRoll)
	local bMaximize = rRoll.sDesc:match(" %[MAXIMIZE%]");
	local bEmpower = rRoll.sDesc:match(" %[EMPOWER%]");
	local nEmpowerTotalMod = 0;
	
	if bMaximize then
		for _, v in ipairs(rRoll.aDice) do
			local nDieSides = tonumber(v.type:match("[dgpr](%d+)")) or 0;
			if nDieSides > 0 then
				v.result = nDieSides;
			end
		end
	end
	
	-- Get damage types for this roll
	local aDamageTypes = decodeDamageTypes(true, rRoll.sDesc, rRoll.aDice, rRoll.nMod);
	if #aDamageTypes > 0 then
		-- Build damage type subtotals
		local nTypeIndex = 1;
		local nTypeCount = 0;
		local nTypeTotal = 0;
		for i, d in ipairs(rRoll.aDice) do
			if nTypeIndex <= #aDamageTypes then
				nTypeCount = nTypeCount + 1;
				nTypeTotal = nTypeTotal + d.result;
				
				if nTypeCount >= aDamageTypes[nTypeIndex].nDice then
					nTypeTotal = nTypeTotal + aDamageTypes[nTypeIndex].nMod;
					if bEmpower then
						local nEmpowerMod = math.floor(nTypeTotal / 2);
						aDamageTypes[nTypeIndex].nMod = aDamageTypes[nTypeIndex].nMod + nEmpowerMod;
						nTypeTotal = nTypeTotal + nEmpowerMod;
						nEmpowerTotalMod = nEmpowerTotalMod + nEmpowerMod;
					end
					aDamageTypes[nTypeIndex].nTotal = nTypeTotal;
					
					nTypeIndex = nTypeIndex + 1;
					nTypeCount = 0;
					nTypeTotal = 0;
				end
			end
		end

		-- Handle any remaining fixed damage
		for i = nTypeIndex, #aDamageTypes do
			if bEmpower then
				local nEmpowerMod = math.floor(aDamageTypes[i].nMod / 2);
				aDamageTypes[i].nTotal = aDamageTypes[i].nMod + nEmpowerMod;
				nEmpowerTotalMod = nEmpowerTotalMod + nEmpowerMod;
			else
				aDamageTypes[i].nTotal = aDamageTypes[i].nMod;
			end
		end
			
		-- Add damage type totals to output
		rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE: ([^]]+)%]", "");
		rRoll.sDesc = rRoll.sDesc .. " " .. encodeDamageTypes(aDamageTypes);
		
		if bEmpower then
			local sReplace = string.format(" [EMPOWER %+d]", nEmpowerTotalMod);
			rRoll.sDesc = string.gsub(rRoll.sDesc, " %[EMPOWER%]", sReplace);
			rRoll.nMod = rRoll.nMod + nEmpowerTotalMod;
		end
	end
end

function onDamage(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local nTotal = ActionsManager.total(rRoll);
	
	-- Handle minimum damage
	if string.match(rMessage.text, " %[MIN OVERRIDE%]") then
		rMessage.text = string.gsub(rMessage.text, " %[MIN OVERRIDE%]", "");
	elseif nTotal <= 0 and rRoll.aDice and #rRoll.aDice > 0 then
		local nMinDmgAdj = -(nTotal) + 1;
		rMessage.text = string.format("%s [MIN DMG ADJ %+d]", rMessage.text, nMinDmgAdj);
		rMessage.diemodifier = rMessage.diemodifier + nMinDmgAdj;
		nTotal = nTotal + nMinDmgAdj;
	end
	
	-- Send the chat message
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		bShowMsg = false;
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end

	-- Apply damage to the PC or CT entry referenced
	notifyApplyDamage(rSource, rTarget, rMessage.secret, rRoll.sType, rMessage.text, nTotal);
end

function onStabilization(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local bSuccess = GameSystem.getStabilizationResult(rRoll);
	if bSuccess then
		rMessage.text = rMessage.text .. " [SUCCESS]";
	else
		rMessage.text = rMessage.text .. " [FAILURE]";
	end
	
	Comm.deliverChatMessage(rMessage);

	if bSuccess then
		EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Stable", nDuration = 0 }, true);
	else
		ActionDamage.applyDamage(nil, rSource, false, "number", "[DAMAGE] Dying", 1);
	end
end

--
-- UTILITY FUNCTIONS
--

function encodeDamageTypes(aDamageTypes)
	local aOutputType = {};
	
	local nTypeCount = 0;
	local sLastDamageType = nil;
	local nLastDieCount = 0;
	local nLastMod = 0;
	local nLastTotal = nil;
	local nLastMult = 2;
	for _,v in ipairs(aDamageTypes) do
		local nCurrentMult = v.nMult or 2;
		
		local sCurrentDamageType = string.lower(v.sType);
		
		if sLastDamageType and ((sCurrentDamageType ~= sLastDamageType) or (nCurrentMult ~= nLastMult)) then
			local sDmgType;
			if sLastDamageType == "" then
				sDmgType = "[TYPE: untyped";
			else
				sDmgType = "[TYPE: " .. sLastDamageType;
			end
			sDmgType = sDmgType .. " (" .. nLastDieCount .. "D";
			if nLastMod > 0 then
				sDmgType = sDmgType .. "+" .. nLastMod;
			elseif nLastMod < 0 then
				sDmgType = sDmgType .. nLastMod;
			end
			if nLastTotal then
				sDmgType = sDmgType .. "=" .. nLastTotal;
			end
			sDmgType = sDmgType .. ")";
			if nLastMult ~= 2 then
				sDmgType = sDmgType .. "(x" .. nLastMult .. ")";
			end
			sDmgType = sDmgType .. "]";
			
			table.insert(aOutputType, sDmgType);
			
			nTypeCount = nTypeCount + 1;
			nLastDieCount = 0;
			nLastMod = 0;
		end
		
		sLastDamageType = sCurrentDamageType;
		nLastDieCount = nLastDieCount + v.nDice;
		nLastMod = nLastMod + v.nMod;
		nLastMult = nCurrentMult;
		nLastTotal = v.nTotal;
	end
	if sLastDamageType and ((sLastDamageType ~= "") or (nLastMult ~= 2)) then
		local sDmgType;
		if sLastDamageType == "" then
			sDmgType = "[TYPE: untyped";
		else
			sDmgType = "[TYPE: " .. sLastDamageType;
		end
		if nTypeCount > 0 then
			sDmgType = sDmgType .. " (" .. nLastDieCount .. "D";
			if nLastMod > 0 then
				sDmgType = sDmgType .. "+" .. nLastMod;
			elseif nLastMod < 0 then
				sDmgType = sDmgType .. nLastMod;
			end
			if nLastTotal then
				sDmgType = sDmgType .. "=" .. nLastTotal;
			end
			sDmgType = sDmgType .. ")";
		end
		if nLastMult ~= 2 then
			sDmgType = sDmgType .. "(x" .. nLastMult .. ")";
		end
		sDmgType = sDmgType .. "]";
		
		table.insert(aOutputType, sDmgType);
	end
	
	return table.concat(aOutputType, " ");
end

function decodeDamageTypes(bRolled, sDesc, aDice, nMod)
	local aDamageTypes = {};
	
	local nDamageDice = 0;
	local nDamageMod = 0;
	
	for sDamageClause in string.gmatch(sDesc, "%[TYPE: ([^]]+)%]") do
		local sDamageType = string.match(sDamageClause, "^([,%w%s]+)");
		if sDamageType then
			sDamageType = StringManager.trim(sDamageType);
			
			local nTotal = nil;
			local sDieCount, sSign, sMod = string.match(sDamageClause, "%((%d+)D([%+%-]?)(%d*)");
			local nDieCount = tonumber(sDieCount) or 0;
			local nDieMod = tonumber(sMod) or 0;
			if nDieCount > 0 or nDieMod > 0 then
				if sSign == "-" then
					nDieMod = 0 - nDieMod;
				end
			else
				nDieCount = #aDice - nDamageDice;
				nDieMod = nMod - nDamageMod;
			end

			nDamageDice = nDamageDice + nDieCount;
			nDamageMod = nDamageMod + nDieMod;

			if sDamageType == "untyped" then
				sDamageType = "";
			end
			
			local rDamageType = { sType = sDamageType, nDice = nDieCount, nMod = nDieMod };

			local sMult = string.match(sDamageClause, "%(x(%d+)%)");
			if sMult then
				rDamageType.nMult = tonumber(sMult) or 2;
			end
			local sTotal = string.match(sDamageClause, "%(%d+D[%+%-]?%d*=(%d+)%)");
			if sTotal then
				rDamageType.nTotal = tonumber(sTotal) or 0;
			end
			
			table.insert(aDamageTypes, rDamageType);
		end
	end
	
	if (nDamageDice < #aDice) or (nDamageMod ~= nMod) then
		local rDamageType = { sType = "", nDice = (#aDice - nDamageDice), nMod = (nMod - nDamageMod) };
		if bRolled then
			rDamageType.nTotal = 0;
			if (nDamageDice < #aDice) then
				for i = nDamageDice + 1, #aDice do
					rDamageType.nTotal = rDamageType.nTotal + aDice[i].result;
				end
			end
			rDamageType.nTotal = rDamageType.nTotal + rDamageType.nMod;
		end
		
		table.insert(aDamageTypes, rDamageType);
	end
	
	return aDamageTypes;
end

function getDamageTypesFromString(sDamageTypes)
	local sLower = string.lower(sDamageTypes);
	local aSplit = StringManager.split(sLower, ",", true);
	
	local aDamageTypes = {};
	for k, v in ipairs(aSplit) do
		if StringManager.contains(DataCommon.dmgtypes, v) then
			table.insert(aDamageTypes, v);
		end
	end
	
	return aDamageTypes;
end

--
-- DAMAGE APPLICATION
--

function getParenDepth(sText, nIndex)
	local nDepth = 0;
	
	local cStart = string.byte("(");
	local cEnd = string.byte(")");
	
	for i = 1, nIndex do
		local cText = string.byte(sText, i);
		if cText == cStart then
			nDepth = nDepth + 1;
		elseif cText == cEnd then
			nDepth = nDepth - 1;
		end
	end
	
	return nDepth;
end

function decodeAndOrClauses(sText)
	local nIndexOR;
	local nStartOR, nEndOR, nStartAND, nEndAND;
	local nStartOR2, nEndOR2;
	local nParen;
	local sPhraseOR;

	local aClausesOR = {};
	local aSkipOR = {};
	local nIndexOR = 1;
	while nIndexOR < #sText do
		local nTempIndex = nIndexOR;
		repeat
			nParen = 0;
			nStartOR, nEndOR = string.find(sText, "%s+or%s+", nTempIndex);
			nStartOR2, nEndOR2 = string.find(sText, "%s*;%s*", nTempIndex);
			
			if nStartOR2 and (not nStartOR or nStartOR > nStartOR2) then
				nStartOR = nStartOR2;
				nEndOR = nEndOR2;
			end
			
			if nStartOR then
				nParen = getParenDepth(sText, nStartOR);
				if nParen ~= 0 then
					nTempIndex = nEndOR + 1;
				end
			end
		until not nStartOR or nParen == 0;
		
		if nStartOR then
			sPhraseOR = string.sub(sText, nIndexOR, nStartOR - 1);
		else
			sPhraseOR = string.sub(sText, nIndexOR);
		end

		local aClausesAND = {};
		local aSkipAND = {};
		local nIndexAND = 1;
		while nIndexAND < #sPhraseOR do
			nTempIndex = nIndexAND;
			repeat
				nParen = 0;
				nStartAND, nEndAND = string.find(sPhraseOR, "%s+and%s+", nTempIndex);
				
				if nStartAND then
					nParen = getParenDepth(sText, nIndexOR + nStartAND);
					if nParen ~= 0 then
						nTempIndex = nEndAND + 1;
					end
				end
			until not nStartAND or nParen == 0;
			
			if nStartAND then
				table.insert(aClausesAND, string.sub(sPhraseOR, nIndexAND, nStartAND - 1));
				nIndexAND = nEndAND + 1;
				table.insert(aSkipAND, nEndAND - nStartAND + 1);
			else
				table.insert(aClausesAND, string.sub(sPhraseOR, nIndexAND));
				nIndexAND = #sPhraseOR;
				if nStartOR then
					table.insert(aSkipAND, nEndOR - nStartOR + 1);
				else
					table.insert(aSkipAND, 0);
				end
			end
		end
		
		if nStartOR then
			nIndexOR = nEndOR + 1;
		else
			nIndexOR = #sText;
		end

		table.insert(aClausesOR, aClausesAND);
		table.insert(aSkipOR, aSkipAND);
	end
	
	return aClausesOR, aSkipOR;
end

function matchAndOrClauses(aClausesOR, aMatchWords)
	for kClauseOR, aClausesAND in ipairs(aClausesOR) do
		local bMatchAND = true;
		local nMatchAND = 0;

		for kClauseAND, sClause in ipairs(aClausesAND) do
			nMatchAND = nMatchAND + 1;

			if not StringManager.contains(aMatchWords, sClause) then
				bMatchAND = false;
				break;
			end
		end
		
		if bMatchAND and nMatchAND > 0 then
			return true;
		end
	end
		
	return false;
end

function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput)
	-- SETUP
	local nDamageAdjust = 0;
	local nNonlethal = 0;
	local bVulnerable = false;
	local bResist = false;
	local aWords;
	local bPFMode = DataCommon.isPFRPG();
	
	-- GET THE DAMAGE ADJUSTMENT EFFECTS
	local aImmune = EffectManager.getEffectsBonusByType(rTarget, "IMMUNE", false, {}, rSource);
	local aVuln = EffectManager.getEffectsBonusByType(rTarget, "VULN", false, {}, rSource);
	local aResist = EffectManager.getEffectsBonusByType(rTarget, "RESIST", false, {}, rSource);
	local aDR = EffectManager.getEffectsByType(rTarget, "DR", {}, rSource);
	
	local bIncorporealTarget = EffectManager.hasEffect(rTarget, "Incorporeal", rSource);
	
	-- IF IMMUNE ALL, THEN JUST HANDLE IT NOW
	if aImmune["all"] then
		nDamageAdjust = 0 - nDamage;
		bResist = true;
		return nDamageAdjust, bVulnerable, bResist;
	end
	
	-- HANDLE REGENERATION
	if not bPFMode then
		local aRegen = EffectManager.getEffectsBonusByType(rTarget, "REGEN", false, {});
		local nRegen = 0;
		for _, _ in pairs(aRegen) do
			nRegen = nRegen + 1;
		end
		if nRegen > 0 then
			local aRemap = {};
			for k,v in pairs(rDamageOutput.aDamageTypes) do
				local bCheckRegen = true;
				
				local aSrcDmgClauseTypes = {};
				local aTemp = StringManager.split(k, ",", true);
				for i = 1, #aTemp do
					if aTemp[i] == "nonlethal" then
						bCheckRegen = false;
						break;
					elseif aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
						table.insert(aSrcDmgClauseTypes, aTemp[i]);
					end
				end

				if bCheckRegen then
					local bMatchAND, nMatchAND, bMatchDMG, aClausesOR;
					local bApplyRegen;
					for kRegen, vRegen in pairs(aRegen) do
						bApplyRegen = true;
						
						local sRegen = table.concat(vRegen.remainder, " ");
						
						aClausesOR = decodeAndOrClauses(sRegen);
						if matchAndOrClauses(aClausesOR, aSrcDmgClauseTypes) then
							bApplyRegen = false;
						end
						
						if bApplyRegen then
							local kNew = table.concat(aSrcDmgClauseTypes, ",");
							if kNew ~= "" then
								kNew = kNew .. ",nonlethal";
							else
								kNew = "nonlethal";
							end
							aRemap[k] = kNew;
						end
					end
				end
			end
			for k,v in pairs(aRemap) do
				rDamageOutput.aDamageTypes[v] = rDamageOutput.aDamageTypes[k];
				rDamageOutput.aDamageTypes[k] = nil;
			end
		end
	end
	
	-- ITERATE THROUGH EACH DAMAGE TYPE ENTRY
	local nVulnApplied = 0;
	for k, v in pairs(rDamageOutput.aDamageTypes) do
		-- GET THE INDIVIDUAL DAMAGE TYPES FOR THIS ENTRY (EXCLUDING UNTYPED DAMAGE TYPE)
		local aSrcDmgClauseTypes = {};
		local bHasEnergyType = false;
		local aTemp = StringManager.split(k, ",", true);
		for i = 1, #aTemp do
			if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
				table.insert(aSrcDmgClauseTypes, aTemp[i]);
				if not bHasEnergyType and (StringManager.contains(DataCommon.energytypes, aTemp[i]) or (aTemp[i] == "spell")) then
					bHasEnergyType = true;
				end
			end
		end

		-- HANDLE IMMUNITY, VULNERABILITY AND RESISTANCE
		local nLocalDamageAdjust = 0;
		if #aSrcDmgClauseTypes > 0 then
			-- CHECK VULN TO DAMAGE TYPES
			for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
				if not aImmune[sDmgType] and aVuln[sDmgType] and not aVuln[sDmgType].nApplied then
					nLocalDamageAdjust = nLocalDamageAdjust + math.floor(v / 2);
					aVuln[sDmgType].nApplied = v;
					bVulnerable = true;
				end
			end
			
			-- CHECK EACH DAMAGE TYPE
			for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
				-- IF IMMUNE, THEN DISCOUNT ALL OF THIS DAMAGE
				if aImmune[sDmgType] then
					nLocalDamageAdjust = nLocalDamageAdjust - v;
					bResist = true;
				else
					-- CHECK RESISTANCE
					if aResist[sDmgType] then
						local nApplied = aResist[sDmgType].nApplied or 0;
						if nApplied < aResist[sDmgType].mod then
							local nChange = math.min((aResist[sDmgType].mod - nApplied), v + nLocalDamageAdjust);
							aResist[sDmgType].nApplied = nApplied + nChange;
							nLocalDamageAdjust = nLocalDamageAdjust - nChange;
							bResist = true;
						end
					end
				end
			end
		end
		
		-- HANDLE DR  (FORM: <type> and <type> or <type> and <type>)
		if not bHasEnergyType and (v + nLocalDamageAdjust) > 0 then
			local bMatchAND, nMatchAND, bMatchDMG, aClausesOR;
			
			local bApplyDR;
			for kDR, vDR in pairs(aDR) do
				if kDR == "" or kDR == "-" or kDR == "all" then
					bApplyDR = true;
				else
					bApplyDR = true;
					aClausesOR = decodeAndOrClauses(table.concat(vDR.remainder, " "));
					if matchAndOrClauses(aClausesOR, aSrcDmgClauseTypes) then
						bApplyDR = false;
					end
				end

				if bApplyDR then
					local nApplied = vDR.nApplied or 0;
					if nApplied < vDR.mod then
						local nChange = math.min((vDR.mod - nApplied), v + nLocalDamageAdjust);
						vDR.nApplied = nApplied + nChange;
						nLocalDamageAdjust = nLocalDamageAdjust - nChange;
						bResist = true;
					end
				end
			end
		end
		
		-- HANDLE INCORPOREAL (PF MODE)
		if bIncorporealTarget and (v + nLocalDamageAdjust) > 0 then
			local bIgnoreDamage = true;
			local bApplyIncorporeal = true;
			for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
				if sDmgType == "force" then
					bApplyIncorporeal = false;
				elseif sDmgType == "spell" or sDmgType == "magic" then
					bIgnoreDamage = false;
				end
			end
			if bApplyIncorporeal then
				if bIgnoreDamage then
					nLocalDamageAdjust = -v;
					bResist = true;
				elseif bPFMode then
					nLocalDamageAdjust = nLocalDamageAdjust - math.ceil((v + nLocalDamageAdjust) / 2);
					bResist = true;
				end
			end
		end
		
		-- CALCULATE NONLETHAL DAMAGE
		local nNonlethalAdjust = 0;
		if (v + nLocalDamageAdjust) > 0 then
			local bNonlethal = false;
			for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
				if sDmgType == "nonlethal" then
					bNonlethal = true;
					break;
				end
			end
			if bNonlethal then
				nNonlethalAdjust = v + nLocalDamageAdjust;
			end
		end

		-- APPLY DAMAGE ADJUSTMENT FROM THIS DAMAGE CLAUSE TO OVERALL DAMAGE ADJUSTMENT
		nDamageAdjust = nDamageAdjust + nLocalDamageAdjust - nNonlethalAdjust;
		nNonlethal = nNonlethal + nNonlethalAdjust;
	end

	-- HANDLE IMMUNITY TO NONLETHAL
	if EffectManager.hasEffectCondition(rTarget, "Construct traits") or EffectManager.hasEffectCondition(rTarget, "Undead traits") then
		if nNonlethal > 0 then
			nNonlethal = 0;
			bResist = true;
		end
	end
	
	-- RESULTS
	return nDamageAdjust, nNonlethal, bVulnerable, bResist;
end

function decodeDamageText(nDamage, sDamageDesc)
	local rDamageOutput = {};
	rDamageOutput.sType = "damage";
	rDamageOutput.sTypeOutput = "Damage";
	rDamageOutput.sVal = "" .. nDamage;
	rDamageOutput.nVal = nDamage;
	
	if string.match(sDamageDesc, "%[HEAL") then
		if nDamage >= 0 then
			if string.match(sDamageDesc, "%[TEMP%]") then
				-- SET MESSAGE TYPE
				rDamageOutput.sType = "temphp";
				rDamageOutput.sTypeOutput = "Temporary hit points";
			else
				-- SET MESSAGE TYPE
				rDamageOutput.sType = "heal";
				rDamageOutput.sTypeOutput = "Heal";
			end
		end
	elseif string.match(sDamageDesc, "%[FHEAL") then
		rDamageOutput.sType = "fheal";
		rDamageOutput.sTypeOutput = "Fast healing";
	elseif string.match(sDamageDesc, "%[REGEN") then
		local bPFMode = DataCommon.isPFRPG();
		if bPFMode then
			rDamageOutput.sType = "heal";
			rDamageOutput.sTypeOutput = "Regeneration";
		else
			rDamageOutput.sType = "regen";
			rDamageOutput.sTypeOutput = "Regeneration";
		end
	elseif nDamage < 0 then
		rDamageOutput.sType = "heal";
		rDamageOutput.sTypeOutput = "Heal";
		rDamageOutput.sVal = "" .. (0 - nDamage);
		rDamageOutput.nVal = 0 - nDamage;
	else
		-- DETERMINE CRITICAL
		rDamageOutput.bCritical = string.match(sDamageDesc, "%[CRITICAL%]");

		-- DETERMINE RANGE
		rDamageOutput.sRange = string.match(sDamageDesc, "%[DAMAGE %((%w)%)%]") or "";

		-- NOTE: Effect damage dice are not multiplied on critical, though numerical modifiers are multiplied
		-- http://rpg.stackexchange.com/questions/4465/is-smite-evil-damage-multiplied-by-a-critical-hit
		-- NOTE: Using damage type of the first damage clause for the bonuses

		-- DETERMINE DAMAGE ENERGY TYPES
		rDamageOutput.aDamageTypes = {};
		local nDamageRemaining = nDamage;
		for sDamageType in string.gmatch(sDamageDesc, "%[TYPE: ([^%]]+)%]") do
			local sDmgType = StringManager.trim(string.match(sDamageType, "^([^(%]]+)"));
			local sDice, sTotal = string.match(sDamageType, "%(([%d%+%-D]+)%=(%d+)%)");
			local nDmgTypeTotal = tonumber(sTotal) or nDamageRemaining;

			if rDamageOutput.aDamageTypes[sDmgType] then
				rDamageOutput.aDamageTypes[sDmgType] = rDamageOutput.aDamageTypes[sDmgType] + nDmgTypeTotal;
			else
				rDamageOutput.aDamageTypes[sDmgType] = nDmgTypeTotal;
			end
			if not rDamageOutput.sFirstDamageType then
				rDamageOutput.sFirstDamageType = sDmgType;
				local sMult = string.match(sDamageType, "%(x(%d+)%)");
				rDamageOutput.nFirstDamageMult = tonumber(sMult) or 2;
			end

			nDamageRemaining = nDamageRemaining - nDmgTypeTotal;
			if nDamageRemaining <= 0 then
				break;
			end
		end
		if nDamageRemaining > 0 then
			rDamageOutput.aDamageTypes[""] = nDamageRemaining;
		end
		
		-- DETERMINE DAMAGE TYPES
		rDamageOutput.aDamageFilter = {};
		if rDamageOutput.sRange == "M" then
			table.insert(rDamageOutput.aDamageFilter, "melee");
		elseif rDamageOutput.sRange == "R" then
			table.insert(rDamageOutput.aDamageFilter, "ranged");
		end
	end
	
	return rDamageOutput;
end

function applyDamage(rSource, rTarget, bSecret, sRollType, sDamage, nTotal)
	-- SETUP
	local nTotalHP = 0;
	local nTempHP = 0;
	local nNonLethal = 0;
	local nWounds = 0;
	local bPFMode = DataCommon.isPFRPG();

	local aNotifications = {};
	
	-- GET HEALTH FIELDS
	local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if sTargetType ~= "pc" and sTargetType ~= "ct" then
		return;
	end
	
	if sTargetType == "pc" then
		nTotalHP = DB.getValue(nodeTarget, "hp.total", 0);
		nTempHP = DB.getValue(nodeTarget, "hp.temporary", 0);
		nNonlethal = DB.getValue(nodeTarget, "hp.nonlethal", 0);
		nWounds = DB.getValue(nodeTarget, "hp.wounds", 0);
	else
		nTotalHP = DB.getValue(nodeTarget, "hp", 0);
		nTempHP = DB.getValue(nodeTarget, "hptemp", 0);
		nNonlethal = DB.getValue(nodeTarget, "nonlethal", 0);
		nWounds = DB.getValue(nodeTarget, "wounds", 0);
	end
	
	-- Remember current health status
	local sOriginalStatus, sNewStatus;
	_,_,sOriginalStatus = ActorManager2.getPercentWounded(sTargetType, nodeTarget);

	-- DECODE DAMAGE DESCRIPTION
	local rDamageOutput = decodeDamageText(nTotal, sDamage);
	
	-- HEALING
	if rDamageOutput.sType == "heal" or rDamageOutput.sType == "fheal" then
		-- CHECK COST
		if nWounds <= 0 and nNonlethal <= 0 then
			table.insert(aNotifications, "[NOT WOUNDED]");
		else
			-- CALCULATE HEAL AMOUNTS
			local nHealAmount = rDamageOutput.nVal;
			
			local nNonlethalHealAmount = math.min(nHealAmount, nNonlethal);
			nNonlethal = nNonlethal - nNonlethalHealAmount;
			if (not bPFMode) and (rDamageOutput.sType == "fheal") then
				nHealAmount = nHealAmount - nNonlethalHealAmount;
			end

			local nOriginalWounds = nWounds;
			
			local nWoundHealAmount = math.min(nHealAmount, nWounds);
			nWounds = nWounds - nWoundHealAmount;
			
			-- IF WE HEALED FROM NEGATIVE TO ZERO OR HIGHER, THEN REMOVE STABLE EFFECT
			if (nOriginalWounds > nTotalHP) and (nWounds <= nTotalHP) then
				EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Stable");
			end
			
			-- SET THE ACTUAL HEAL AMOUNT FOR DISPLAY
			rDamageOutput.nVal = nNonlethalHealAmount + nWoundHealAmount;
			if nWoundHealAmount > 0 then
				rDamageOutput.sVal = "" .. nWoundHealAmount;
				if nNonlethalHealAmount > 0 then
					rDamageOutput.sVal = rDamageOutput.sVal .. " (+" .. nNonlethalHealAmount .. " NL)";
				end
			elseif nNonlethalHealAmount > 0 then
				rDamageOutput.sVal = "" .. nNonlethalHealAmount .. " NL";
			else
				rDamageOutput.sVal = "0";
			end
		end

	-- REGENERATION
	elseif rDamageOutput.sType == "regen" then
		if nNonlethal <= 0 then
			table.insert(aNotifications, "[NO NONLETHAL DAMAGE]");
		else
			local nNonlethalHealAmount = math.min(rDamageOutput.nVal, nNonlethal);
			nNonlethal = nNonlethal - nNonlethalHealAmount;
			
			rDamageOutput.nVal = nNonlethalHealAmount;
			rDamageOutput.sVal = "" .. nNonlethalHealAmount .. " NL";
		end

	-- TEMPORARY HIT POINTS
	elseif rDamageOutput.sType == "temphp" then
		-- APPLY TEMPORARY HIT POINTS
		nTempHP = math.max(nTempHP, nTotal);

	-- DAMAGE
	else
	
		-- APPLY ANY TARGETED DAMAGE EFFECTS
		-- NOTE: DICE ARE RANDOMLY DETERMINED BY COMPUTER, INSTEAD OF ROLLED
		if rSource and rTarget and rTarget.nOrder then
			local aTargetedDamage;
			if sRollType == "spdamage" then
				aTargetedDamage = EffectManager.getEffectsBonusByType(rSource, {"DMGS"}, true, rDamageOutput.aDamageFilter, rTarget, true);
			else
				aTargetedDamage = EffectManager.getEffectsBonusByType(rSource, {"DMG"}, true, rDamageOutput.aDamageFilter, rTarget, true);
			end

			local nDamageEffectTotal = 0;
			local nDamageEffectCount = 0;
			for k, v in pairs(aTargetedDamage) do
				local nSubTotal = 0;
				if rDamageOutput.bCritical then
					local nMult = rDamageOutput.nFirstDamageMult or 2;
					nSubTotal = StringManager.evalDice(v.dice, (nMult * v.mod));
				else
					nSubTotal = StringManager.evalDice(v.dice, v.mod);
				end
				
				local sDamageType = rDamageOutput.sFirstDamageType;
				if sDamageType then
					sDamageType = sDamageType .. "," .. k;
				else
					sDamageType = k;
				end

				rDamageOutput.aDamageTypes[sDamageType] = (rDamageOutput.aDamageTypes[sDamageType] or 0) + nSubTotal;
				
				nDamageEffectTotal = nDamageEffectTotal + nSubTotal;
				nDamageEffectCount = nDamageEffectCount + 1;
			end
			nTotal = nTotal + nDamageEffectTotal;

			if nDamageEffectCount > 0 then
				if nDamageEffectTotal ~= 0 then
					local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
					table.insert(aNotifications, string.format(sFormat, nDamageEffectTotal));
				else
					table.insert(aNotifications, "[" .. Interface.getString("effects_tag") .. "]");
				end
			end
		end
		
		-- CHECK FOR HALF DAMAGE
		local isHalf = string.match(sDamage, "%[HALF%]");
		if isHalf then
			table.insert(aNotifications, "[HALF]");
			for kType, nType in pairs(rDamageOutput.aDamageTypes) do
				rDamageOutput.aDamageTypes[kType] = math.floor(nType / 2);
			end
			nTotal = math.max(math.floor(nTotal / 2), 1);
		end
		
		-- APPLY ANY DAMAGE TYPE ADJUSTMENT EFFECTS
		local nDamageAdjust, nNonlethalDmgAmount, bVulnerable, bResist = getDamageAdjust(rSource, rTarget, nTotal, rDamageOutput);

		-- ADDITIONAL DAMAGE ADJUSTMENTS NOT RELATED TO DAMAGE TYPE
		local nAdjustedDamage = nTotal + nDamageAdjust;
		if nAdjustedDamage < 0 then
			nAdjustedDamage = 0;
		end
		if bResist then
			if nAdjustedDamage <= 0 then
				table.insert(aNotifications, "[RESISTED]");
			else
				table.insert(aNotifications, "[PARTIALLY RESISTED]");
			end
		end
		if bVulnerable then
			table.insert(aNotifications, "[VULNERABLE]");
		end
		
		-- REDUCE DAMAGE BY TEMPORARY HIT POINTS
		if nTempHP > 0 and nAdjustedDamage > 0 then
			if nAdjustedDamage > nTempHP then
				nAdjustedDamage = nAdjustedDamage - nTempHP;
				nTempHP = 0;
				table.insert(aNotifications, "[PARTIALLY ABSORBED]");
			else
				nTempHP = nTempHP - nAdjustedDamage;
				nAdjustedDamage = 0;
				table.insert(aNotifications, "[ABSORBED]");
			end
		end

		-- Update the damage output variable to reflect adjustments
		rDamageOutput.nVal = nAdjustedDamage;
		if nAdjustedDamage > 0 then
			rDamageOutput.sVal = "" .. nAdjustedDamage;
			if nNonlethalDmgAmount > 0 then
				rDamageOutput.sVal = rDamageOutput.sVal .. " (+" .. nNonlethalDmgAmount .. " NL)";
			end
		elseif nNonlethalDmgAmount > 0 then
			rDamageOutput.sVal = "" .. nNonlethalDmgAmount .. " NL";
		else
			rDamageOutput.sVal = "0";
		end

		-- APPLY REMAINING DAMAGE
		local nOriginalWounds = nWounds;
		nWounds = nWounds + nAdjustedDamage;
		if nWounds < 0 then
			nWounds = 0;
		end
		local nOriginalNonlethal = nNonlethal;
		nNonlethal = nNonlethal + nNonlethalDmgAmount;
		if nNonlethal < 0 then
			nNonlethal = 0;
		end
	end

	-- SET HEALTH FIELDS
	if sTargetType == "pc" then
		DB.setValue(nodeTarget, "hp.temporary", "number", nTempHP);
		DB.setValue(nodeTarget, "hp.wounds", "number", nWounds);
		DB.setValue(nodeTarget, "hp.nonlethal", "number", nNonlethal);
	else
		DB.setValue(nodeTarget, "hptemp", "number", nTempHP);
		DB.setValue(nodeTarget, "wounds", "number", nWounds);
		DB.setValue(nodeTarget, "nonlethal", "number", nNonlethal);
	end

	-- Check for status change
	_,_,sNewStatus = ActorManager2.getPercentWounded(sTargetType, nodeTarget);
	if sOriginalStatus ~= sNewStatus then
		table.insert(aNotifications, "[" .. sNewStatus:upper() .. "]");
	end
	
	-- OUTPUT RESULTS
	messageDamage(rSource, rTarget, bSecret, rDamageOutput.sTypeOutput, sDamage, rDamageOutput.sVal, table.concat(aNotifications, " "));
end

function messageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult)
	if not (rTarget or sExtraResult ~= "") then
		return;
	end
	
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};

	if sDamageType == "Heal" or sDamageType == "Temporary hit points" then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";
	end

	msgShort.text = sDamageType .. " ->";
	msgLong.text = sDamageType .. " [" .. sTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [to " .. rTarget.sName .. "]";
		msgLong.text = msgLong.text .. " [to " .. rTarget.sName .. "]";
	end
	
	if sExtraResult and sExtraResult ~= "" then
		msgLong.text = msgLong.text .. " " .. sExtraResult;
	end
	
	ActionsManager.messageResult(bSecret, rSource, rTarget, msgLong, msgShort);
end
