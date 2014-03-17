-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("skill", modSkill);
	ActionsManager.registerResultHandler("skill", onRoll);
end

function performPCRoll(draginfo, rActor, nodeSkill)
	local sSkillName = DB.getValue(nodeSkill, "label", "");
	local sSubskillName = DB.getValue(nodeSkill, "sublabel", "");
	if sSubskillName ~= "" then
		sSkillName = sSkillName .. " (" .. sSubskillName .. ")";
	end

	local nSkillMod = DB.getValue(nodeSkill, "total", 0);
	local sSkillStat = DB.getValue(nodeSkill, "statname", "");
	
	performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat);
end

function getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nTargetDC, bSecretRoll, sExtra)
	local rRoll = {};
	rRoll.sType = "skill";
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = nSkillMod or 0;
	rRoll.sDesc = "[SKILL] " .. sSkillName;
	if sExtra then
		rRoll.sDesc = rRoll.sDesc .. " " .. sExtra;
	end
	
	-- If custom skill, then add in ability that modifies it.
	local bCustom = true;
	for k, v in pairs(DataCommon.skilldata) do
		if k == sSkillName then
			bCustom = false;
		end
	end
	if bCustom then
		local sAbilityEffect = DataCommon.ability_ltos[sSkillStat];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end
	
	rRoll.bSecret = bSecretRoll;
	
	rRoll.nTarget = nTargetDC;
	
	return rRoll;
end

function performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat, nTargetDC, bSecretRoll, sExtra)
	local rRoll = getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nTargetDC, bSecretRoll, sExtra);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modSkill(rSource, rTarget, rRoll)
	local bAssist = Input.isShiftPressed();
	if bAssist then
		rRoll.sDesc = rRoll.sDesc .. " [ASSIST]";
	end

	if rSource then
		local bEffects = false;

		-- Determine skill used
		local sSkillLower = "";
		local sSkill = string.match(rRoll.sDesc, "%[SKILL%] ([^[]+)");
		if sSkill then
			sSkillLower = string.lower(StringManager.trim(sSkill));
		end

		-- Determine ability used with this skill
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		else
			for k, v in pairs(DataCommon.skilldata) do
				if string.lower(k) == sSkillLower then
					sActionStat = v.stat;
				end
			end
		end

		-- Build effect filter for this skill
		local aSkillFilter = {};
		if sActionStat then
			table.insert(aSkillFilter, sActionStat);
		end
		local aSkillNameFilter = {};
		local aSkillWordsLower = StringManager.parseWords(sSkillLower);
		for kWord, vWord in ipairs(aSkillWordsLower) do
			if StringManager.contains(DataCommon.dmgtypes, vWord) or StringManager.contains(DataCommon.bonustypes, vWord) or StringManager.contains(DataCommon.connectors, vWord) then
				-- Skip damage type, bonus type and connector keywords (Hack to allow Use Magic Device bonuses)
			else
				table.insert(aSkillNameFilter, vWord);
			end
		end
		table.insert(aSkillFilter, aSkillNameFilter);
		
		-- Get effects
		local aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"SKILL"}, false, aSkillFilter);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager.hasEffectCondition(rSource, "Frightened") or 
				EffectManager.hasEffectCondition(rSource, "Panicked") or
				EffectManager.hasEffectCondition(rSource, "Shaken") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if EffectManager.hasEffectCondition(rSource, "Sickened") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if EffectManager.hasEffectCondition(rSource, "Blinded") then
			if sActionStat == "strength" or sActionStat == "dexterity" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			elseif sSkillLower == "search" or sSkillLower == "perception" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			end
		elseif EffectManager.hasEffectCondition(rSource, "Dazzled") then
			if sSkillLower == "spot" or sSkillLower == "search" or sSkillLower == "perception" then
				bEffects = true;
				nAddMod = nAddMod - 1;
			end
		end
		if EffectManager.hasEffectCondition(rSource, "Fascinated") then
			if sSkillLower == "spot" or sSkillLower == "listen" or sSkillLower == "perception" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			end
		end
		-- Exhausted and Fatigued are handled by the effect checks for general ability modifiers

		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectManager.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			bEffects = true;
			nAddMod = nAddMod - nNegLevelMod;
		end

		-- If effects, then add them
		if bEffects then
			for _,vDie in ipairs(aAddDice) do
				table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
			end
			rRoll.nMod = rRoll.nMod + nAddMod;

			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
	end
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		rMessage.text = rMessage.text .. " (vs. DC " .. nTargetDC .. ")";
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	local nTotal = ActionsManager.total(rRoll);
	Comm.deliverChatMessage(rMessage);
end
