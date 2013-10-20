-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerActionIcon("skill", "action_roll");
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

function performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat, nTargetDC, bSecretRoll, bAddName, sExtra)
	-- Build basic roll
	local rRoll = {};
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = nSkillMod or 0;
	rRoll.sDesc = "[SKILL] " .. sSkillName;
	if sExtra then
		rRoll.sDesc = rRoll.sDesc .. " " .. sExtra;
	end
	
	-- If custom skill, then add in ability that modifies it.
	local bCustom = true;
	for k, v in pairs(GameSystemManager.getSkillList()) do
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
	
	if bAddName then
		rRoll.sDesc = "[ADDNAME] " .. rRoll.sDesc;
	end
	if bSecretRoll then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end
	
	local rCustom = {};
	if nTargetDC then
		table.insert(rCustom, { nMod = nTargetDC } );
	end
	
	-- Perform roll
	ActionsManager.performSingleRollAction(draginfo, rActor, "skill", rRoll, rCustom);
end

function modSkill(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
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
			for k, v in pairs(GameSystemManager.getSkillList()) do
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
		local aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"SKILL"}, false, aSkillFilter);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectsManager.hasEffectCondition(rSource, "Frightened") or 
				EffectsManager.hasEffectCondition(rSource, "Panicked") or
				EffectsManager.hasEffectCondition(rSource, "Shaken") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if EffectsManager.hasEffectCondition(rSource, "Sickened") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if EffectsManager.hasEffectCondition(rSource, "Exhausted") then
			if sActionStat == "strength" or sActionStat == "dexterity" then
				bEffects = true;
				nAddMod = nAddMod - 3;
			end
		elseif EffectsManager.hasEffectCondition(rSource, "Fatigued") then
			if sActionStat == "strength" or sActionStat == "dexterity" then
				bEffects = true;
				nAddMod = nAddMod - 1;
			end
		end
		if EffectsManager.hasEffectCondition(rSource, "Blinded") then
			if sActionStat == "strength" or sActionStat == "dexterity" then
				bEffects = true;
				nAddMod = nAddMod - 2;
			end
			if sSkillLower == "search" or sSkillLower == "perception" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			end
		elseif EffectsManager.hasEffectCondition(rSource, "Dazzled") then
			if sSkillLower == "spot" or sSkillLower == "search" or sSkillLower == "notice" then
				bEffects = true;
				nAddMod = nAddMod - 1;
			end
		end
		if EffectsManager.hasEffectCondition(rSource, "Fascinated") then
			if sSkillLower == "spot" or sSkillLower == "listen" or sSkillLower == "notice" then
				bEffects = true;
				nAddMod = nAddMod - 4;
			end
		end

		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManager.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectsManager.getEffectsBonus(rSource, {"NLVL"}, true);
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
				sEffects = "[EFFECTS " .. sMod .. "]";
			else
				sEffects = "[EFFECTS]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
	end
end

function onRoll(rSource, rTarget, rRoll, rCustom)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rCustom and rCustom[1] and rCustom[1].nMod then
		local nTotal = ActionsManager.total(rRoll);
		
		rMessage.text = rMessage.text .. " (vs. DC " .. rCustom[1].nMod .. ")";
		if nTotal >= rCustom[1].nMod then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	local nTotal = ActionsManager.total(rRoll);
	Comm.deliverChatMessage(rMessage);
end
