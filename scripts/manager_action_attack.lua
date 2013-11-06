-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

	ActionsManager.registerActionIcon("attack", "action_attack");
	ActionsManager.registerActionIcon("fullattack", "action_attack");
	ActionsManager.registerActionIcon("grapple", "action_attack");
	
	ActionsManager.registerMultiHandler("fullattack", translateFullAttack);
	
	ActionsManager.registerTargetingHandler("attack", onTargeting);
	ActionsManager.registerTargetingHandler("grapple", onTargeting);
	ActionsManager.registerTargetingHandler("fullattack", onTargeting);
	
	ActionsManager.registerModHandler("attack", modAttack);
	ActionsManager.registerModHandler("grapple", modAttack);
	
	ActionsManager.registerResultHandler("attack", onAttack);
	ActionsManager.registerResultHandler("critconfirm", onAttack);
	ActionsManager.registerResultHandler("misschance", onMissChance);
	ActionsManager.registerResultHandler("grapple", onGrapple);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.getActor("ct", msgOOB.sSourceCTNode);
	
	local rTarget = ActorManager.getActor("ct", msgOOB.sTargetCTNode);
	if not rTarget then
		rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetCreatureNode);
	end
	
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyAttack(rSource, rTarget, msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
end

function notifyApplyAttack(rSource, rTarget, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYATK;
	
	msgOOB.sAttackType = sAttackType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;
	msgOOB.sTargetType = rTarget.sType;
	msgOOB.sTargetCreatureNode = rTarget.sCreatureNode;
	msgOOB.sTargetCTNode = rTarget.sCTNode;
	if rSource then
		msgOOB.sSourceCTNode = rSource.sCTNode;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyHRFC(msgOOB)
	TableManager.processTableRoll("", msgOOB.sTable);
end

function notifyApplyHRFC(sTable)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
	
	msgOOB.sTable = sTable;

	Comm.deliverOOBMessage(msgOOB, "");
end

function translateFullAttack(nSlot)
	return "attack";
end

function onTargeting(rSource, rRolls)
	local aTargets = TargetingManager.getFullTargets(rSource);
	
	if #aTargets <= 1 then
		return { aTargets };
	end
	
	for kRoll, vRoll in ipairs(rRolls) do
		if not string.match(vRoll.sDesc, "%[FULL%]") then
			vRoll.sDesc = vRoll.sDesc .. " [MULTI]";
		end
	end
	
	local aTargeting = {};
	for _,vTarget in ipairs(aTargets) do
		table.insert(aTargeting, { vTarget });
	end
	
	return aTargeting;
end

function getRoll(rActor, rAction)
	-- Build basic roll
	local rRoll = {};
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = rAction.modifier or 0;
	
	-- Build the description label
	if rAction.cm then
		rRoll.sDesc = "[CMB";
		if rAction.order and rAction.order > 1 then
			rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
		end
		rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	else
		rRoll.sDesc = "[ATTACK";
		if rAction.order and rAction.order > 1 then
			rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
		end
		if rAction.range then
			rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
		end
		rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	end
	
	-- Add ability modifiers
	if rAction.stat then
		if (rAction.range == "M" and rAction.stat ~= "strength") or (rAction.range == "R" and rAction.stat ~= "dexterity") then
			local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
			if sAbilityEffect then
				rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
			end
		end
	end
	
	-- Add other modifiers
	if rAction.crit and rAction.crit < 18 then
		rRoll.sDesc = rRoll.sDesc .. " [CRIT " .. rAction.crit .. "]";
	end
	if rAction.touch then
		rRoll.sDesc = rRoll.sDesc .. " [TOUCH]";
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	
	if rAction.cm then
		ActionsManager.performSingleRollAction(draginfo, rActor, "grapple", rRoll);
	else
		ActionsManager.performSingleRollAction(draginfo, rActor, "attack", rRoll);
	end
end

function getGrappleRoll(rActor, rAction)
	local rRoll = {};
	
	-- Build basic roll
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = rAction.modifier or 0;
	
	-- Build description label
	if OptionsManager.isOption("SYSTEM", "pf") then
		rRoll.sDesc = "[CMB]";
	else
		rRoll.sDesc = "[GRAPPLE]";
	end
	if rAction.label and rAction.label ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. rAction.label;
	end
	
	-- Add ability modifiers
	if rAction.stat then
		if rAction.stat ~= "strength" then
			local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
			if sAbilityEffect then
				rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
			end
		end
	end
	
	return rRoll;
end

function performGrappleRoll(draginfo, rActor, rAction)
	local rRoll = getGrappleRoll(rActor, rAction);
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "grapple", rRoll);
end

function modAttack(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
	clearCritState(rSource);
	
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	-- Check for opportunity attack
	local bOpportunity = ModifierStack.getModifierKey("ATT_OPP") or Input.isShiftPressed();

	-- Check defense modifiers
	local bTouch = ModifierStack.getModifierKey("ATT_TCH");
	local bFlatFooted = ModifierStack.getModifierKey("ATT_FF");
	local bCover = ModifierStack.getModifierKey("DEF_COVER");
	local bPartialCover = ModifierStack.getModifierKey("DEF_PCOVER");
	local bSuperiorCover = ModifierStack.getModifierKey("DEF_SCOVER");
	local bConceal = ModifierStack.getModifierKey("DEF_CONC");
	local bTotalConceal = ModifierStack.getModifierKey("DEF_TCONC");
	
	if bOpportunity then
		table.insert(aAddDesc, "[OPPORTUNITY]");
	end
	if bTouch then
		if not string.match(rRoll.sDesc, "%[TOUCH%]") then
			table.insert(aAddDesc, "[TOUCH]");
		end
	end
	if bFlatFooted then
		table.insert(aAddDesc, "[FF]");
	end
	if bSuperiorCover then
		table.insert(aAddDesc, "[COVER -8]");
	elseif bCover then
		table.insert(aAddDesc, "[COVER -4]");
	elseif bPartialCover then
		table.insert(aAddDesc, "[COVER -2]");
	end
	if bConceal then
		table.insert(aAddDesc, "[CONCEAL]");
	end
	if bTotalConceal then
		table.insert(aAddDesc, "[TOTAL CONC]");
	end
	
	if rSource then
		-- Determine attack type
		local sAttackType = nil;
		if rRoll.sType == "attack" or rRoll.sType == "castattack" then
			sAttackType = string.match(rRoll.sDesc, "%[ATTACK.*%((%w+)%)%]");
			if not sAttackType then
				sAttackType = "M";
			end
		elseif rRoll.sType == "grapple" then
			sAttackType = "M";
		end

		-- Determine ability used
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			if sAttackType == "M" then
				sActionStat = "strength";
			elseif sAttackType == "R" then
				sActionStat = "dexterity";
			end
		end

		-- Build attack filter
		local aAttackFilter = {};
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end
		
		-- Get attack effect modifiers
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"ATK"}, false, aAttackFilter);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		if rRoll.sType == "grapple" then
			local aPFDice, nPFMod, nPFCount = EffectsManager.getEffectsBonus(rSource, {"CMB"}, false, aAttackFilter);
			if nPFCount > 0 then
				bEffects = true;
				for k, v in ipairs(aPFDice) do
					table.insert(aAddDice, v);
				end
				nAddMod = nAddMod + nPFMod;
			end
		end
		
		-- Get condition modifiers
		if EffectsManager.hasEffect(rSource, "Invisible") then
			bEffects = true;
			nAddMod = nAddMod + 2;
			table.insert(aAddDesc, "[CA]");
		elseif EffectsManager.hasEffect(rSource, "CA") then
			bEffects = true;
			table.insert(aAddDesc, "[CA]");
		end
		if EffectsManager.hasEffect(rSource, "Blinded") then
			bEffects = true;
			table.insert(aAddDesc, "[BLINDED]");
		end
		if OptionsManager.isOption("SYSTEM", "off") then
			if EffectsManager.hasEffect(rSource, "Incorporeal") and sAttackType == "M" and not string.match(string.lower(rRoll.sDesc), "incorporeal touch") then
				bEffects = true;
				table.insert(aAddDesc, "[INCORPOREAL]");
			end
		end
		if EffectsManager.hasEffectCondition(rSource, "Dazzled") then
			bEffects = true;
			nAddMod = nAddMod - 1;
		end
		if EffectsManager.hasEffectCondition(rSource, "Slowed") then
			bEffects = true;
			nAddMod = nAddMod - 1;
		end
		if EffectsManager.hasEffectCondition(rSource, "Entangled") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if (rRoll.sType == "attack" or rRoll.sType == "castattack") and 
				(EffectsManager.hasEffectCondition(rSource, "Pinned") or
				EffectsManager.hasEffectCondition(rSource, "Grappled")) then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
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

		-- Get other effect modifiers
		if EffectsManager.hasEffectCondition(rSource, "Squeezing") then
			bEffects = true;
			nAddMod = nAddMod - 4;
		end
		if EffectsManager.hasEffectCondition(rSource, "Prone") then
			if sAttackType == "M" then
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
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[EFFECTS " .. sMod .. "]";
			else
				sEffects = "[EFFECTS]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	if bSuperiorCover then
		nAddMod = nAddMod - 8;
	elseif bCover then
		nAddMod = nAddMod - 4;
	elseif bPartialCover then
		nAddMod = nAddMod - 2;
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onAttack(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local bIsSourcePC = (rSource and rSource.sType == "pc");
	local bAllowCC = OptionsManager.isOption("HRCC", "on") or (not bIsSourcePC and OptionsManager.isOption("HRCC", "npc"));
	local bHideFromPlayer = not bIsSourcePC and OptionsManager.isOption("REVL", "off");
	
	if rRoll.sDesc:match("%[CMB") then
		rRoll.sType = "grapple";
	end
	
	local rAction = {};
	rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};
	
	-- If we have a target, then calculate the defense we need to exceed
	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance;
	if rRoll.sType == "critconfirm" then
		local sDefenseVal = string.match(rRoll.sDesc, " %[AC (%d+)%]");
		if sDefenseVal then
			nDefenseVal = tonumber(sDefenseVal);
		end
		nMissChance = 0;
		rMessage.text = string.gsub(rMessage.text, " %[AC %d+%]", "");
	else
		nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance = ActorManager.getDefenseValue(rSource, rTarget, rRoll);
		if nAtkEffectsBonus ~= 0 then
			table.insert(rAction.aMessages, string.format("[EFFECTS %+d]", nAtkEffectsBonus));
		end
		if nDefEffectsBonus ~= 0 then
			table.insert(rAction.aMessages, string.format("[DEF EFFECTS %+d]", nDefEffectsBonus));
		end
	end

	-- Get the crit threshold
	rAction.nCrit = 18;	
	local sAltCritRange = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	if sAltCritRange then
		rAction.nCrit = tonumber(sAltCritRange) or 18;
		if (rAction.nCrit <= 3) or (rAction.nCrit > 18) then
			rAction.nCrit = 18;
		end
	end
	
	rAction.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rAction.nFirstDie = (rRoll.aDice[1].result + rRoll.aDice[2].result + rRoll.aDice[3].result) or 0;
	end
	rAction.bCritThreat = false;
	if rAction.nFirstDie >= 18 then
		rAction.bSpecial = true;
		if bHideFromPlayer then
			ChatManager.Message("[GM] Original attack = " .. rAction.nFirstDie .. "+" .. rRoll.nMod .. "=" .. rAction.nTotal, false);
			rMessage.diemodifier = 0;
		end
		if rRoll.sType == "critconfirm" then
			rAction.sResult = "crit";
			table.insert(rAction.aMessages, "[CRITICAL HIT]");
		elseif rRoll.sType == "attack" or rRoll.sType == "castattack" then
			if bAllowCC then
				rAction.sResult = "hit";
				rAction.bCritThreat = true;
				table.insert(rAction.aMessages, "[AUTOMATIC HIT]");
			else
				rAction.sResult = "crit";
				table.insert(rAction.aMessages, "[CRITICAL HIT]");
			end
		else
			rAction.sResult = "hit";
			table.insert(rAction.aMessages, "[AUTOMATIC HIT]");
		end
	elseif rAction.nFirstDie == 3 then
		if bHideFromPlayer then
			rMessage.diemodifier = 0;
		end
		if rRoll.sType == "critconfirm" then
			table.insert(rAction.aMessages, "[CRIT NOT CONFIRMED]");
			rAction.sResult = "miss";
		else
			table.insert(rAction.aMessages, "[AUTOMATIC MISS]");
			rAction.sResult = "fumble";
		end
	elseif nDefenseVal then
		if rAction.nTotal >= nDefenseVal then
			if rRoll.sType == "critconfirm" then
				rAction.sResult = "crit";
				table.insert(rAction.aMessages, "[CRITICAL HIT]");
			elseif (rRoll.sType == "attack" or rRoll.sType == "castattack") and rAction.nFirstDie >= rAction.nCrit then
				if bAllowCC then
					rAction.sResult = "hit";
					rAction.bCritThreat = true;
					table.insert(rAction.aMessages, "[CRITICAL THREAT]");
				else
					rAction.sResult = "crit";
					table.insert(rAction.aMessages, "[CRITICAL HIT]");
				end
			else
				rAction.sResult = "hit";
				table.insert(rAction.aMessages, "[HIT]");
			end
		else
			rAction.sResult = "glance";
			if rRoll.sType == "critconfirm" then
				table.insert(rAction.aMessages, "[CRIT NOT CONFIRMED]");
			else
				table.insert(rAction.aMessages, "[GLANCING]");
			end
		end
	elseif rRoll.sType == "critconfirm" then
		rAction.sResult = "crit";
		table.insert(rAction.aMessages, "[CHECK FOR CRITICAL]");
	elseif (rRoll.sType == "attack" or rRoll.sType == "castattack") and rAction.nFirstDie >= rAction.nCrit then
		if bAllowCC then
			rAction.sResult = "hit";
			rAction.bCritThreat = true;
		else
			rAction.sResult = "crit";
		end
		table.insert(rAction.aMessages, "[CHECK FOR CRITICAL]");
	end
	
	if rRoll.sType ~= "critconfirm" and nMissChance > 0 then
		table.insert(rAction.aMessages, "[MISS CHANCE " .. nMissChance .. "%]");
	end

	Comm.deliverChatMessage(rMessage);

	if rRoll.sType == "critconfirm" then
		if rAction.sResult == "crit" then
			setCritState(rSource, rTarget);
		end
	else
		if rAction.bCritThreat then
			local rCritConfirmRoll = { sType = "critconfirm", aDice = {"d6","d6","d6"} };
			
			local nCCMod = EffectsManager.getEffectsBonus(rSource, {"CC"}, true);
			if nCCMod ~= 0 then
				rCritConfirmRoll.sDesc = string.format("%s [CONFIRM %+d]", rRoll.sDesc, nCCMod);
			else
				rCritConfirmRoll.sDesc = rRoll.sDesc .. " [CONFIRM]";
			end
			rCritConfirmRoll.nMod = rRoll.nMod + nCCMod;
			
			if nDefenseVal then
				rCritConfirmRoll.sDesc = rCritConfirmRoll.sDesc .. " [AC " .. nDefenseVal .. "]";
			end
			
			ActionsManager.roll(rSource, rTarget, rCritConfirmRoll);
		end
		if (nMissChance > 0) and (rAction.sResult ~= "miss") and (rAction.sResult ~= "fumble") then
			local rMissChanceRoll = { sType = "misschance", sDesc = rRoll.sDesc .. " [MISS CHANCE " .. nMissChance .. "%]", aDice = { "d100", "d10" }, nMod = 0 };
			ActionsManager.roll(rSource, rTarget, rMissChanceRoll);
		end
	end

	if rTarget then
		notifyApplyAttack(rSource, rTarget, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "));
		
		-- REMOVE TARGET ON MISS OPTION
		if (rAction.sResult == "miss" or rAction.sResult == "fumble") and rRoll.sType ~= "critconfirm" and not string.match(rRoll.sDesc, "%[FULL%]") then
			local bRemoveTarget = false;
			if OptionsManager.isOption("RMMT", "on") then
				bRemoveTarget = true;
			elseif OptionsManager.isOption("RMMT", "multi") then
				local sTargetNumber = string.match(rRoll.sDesc, "%[MULTI%]");
				if sTargetNumber then
					bRemoveTarget = true;
				end
			end
			
			if bRemoveTarget then
				local sTargetType = "client";
				if User.isHost() then
					sTargetType = "host";
				end
			
				TargetingManager.removeTarget(sTargetType, rSource.nodeCT, rTarget.sCTNode);
			end
		end
	end
	
	-- HANDLE FUMBLE/CRIT HOUSE RULES
	local sOptionHRFC = OptionsManager.getOption("HRFC");
	if rAction.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
		notifyApplyHRFC("Fumble");
	end
	if rAction.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
		notifyApplyHRFC("Critical Hit");
	end
end

function onGrapple(rSource, rTarget, rRoll)
	if OptionsManager.isOption("SYSTEM", "pf") then
		onAttack(rSource, rTarget, rRoll);
	else
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		
		if rTarget then
			rMessage.text = rMessage.text .. " [at " .. rTarget.sName .. "]";
		end
		
		if not rSource then
			rMessage.sender = nil;
		end
		Comm.deliverChatMessage(rMessage);
	end
end

function onMissChance(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	--Pulling action result message to differentiate hit vs glance
	--<stuff> related to drawing Attack roll message string - attempts have resulted in pulling onMissChance's messages. Not skilled at drawing messages/values across functions.
	--ex: local sGlance = string.match(rMessage.text, "%[GLANCING%]");
	
	local nTotal = ActionsManager.total(rRoll);
	local nMissChance = tonumber(string.match(rMessage.text, "%[MISS CHANCE (%d+)%%%]")) or 0;
	if nTotal <= nMissChance then
		rMessage.text = rMessage.text .. " [MISS]";
		if rTarget then
			rMessage.icon = "indicator_attack_miss";
		else
			rMessage.icon = "indicator_attack";
		end
	--Differentiation of Glance vs Hit result
	--elseif <ex: sGlance ~= nil> then
		--rMessage.text = rMessage.text .. " [GLANCING]";
		--if rTarget then
			--rMessage.icon = "indicator_attack_glance";
		--else
			--rMessage.icon = "indicator_attack";
		--end
	--Normal Hit vs Miss Chance
	else
		rMessage.text = rMessage.text .. " [HIT]";
		if rTarget then
			rMessage.icon = "indicator_attack_hit";
		else
			rMessage.icon = "indicator_attack";
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end

function applyAttack(rSource, rTarget, sAttackType, sDesc, nTotal, sResults)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	if sAttackType == "grapple" then
		msgShort.text = "Combat Man. ->";
		msgLong.text = "Combat Man. [" .. nTotal .. "] ->";
	else
		msgShort.text = "Attack ->";
		msgLong.text = "Attack [" .. nTotal .. "] ->";
	end
	if rTarget then
		msgShort.text = msgShort.text .. " [at " .. rTarget.sName .. "]";
		msgLong.text = msgLong.text .. " [at " .. rTarget.sName .. "]";
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end
	
	msgShort.icon = "indicator_attack";
	if string.match(sResults, "%[CRITICAL HIT%]") then
		msgLong.icon = "indicator_attack_crit";
	elseif string.match(sResults, "HIT%]") then
		msgLong.icon = "indicator_attack_hit";
	elseif string.match(sResults, "MISS%]") then
		msgLong.icon = "indicator_attack_miss";
	elseif string.match(sResults, "CRITICAL THREAT%]") then
		msgLong.icon = "indicator_attack_hit";
	elseif string.match(sResults, "GLANCING%]") then
		msgLong.icon = "indicator_attack_glance";
	else
		msgLong.icon = "indicator_attack";
	end
		
	local bGMOnly = string.match(sDesc, "^%[GM%]") or string.match(sDesc, "^%[TOWER%]") ;
	ActionsManager.messageResult(bGMOnly, rSource, rTarget, msgLong, msgShort);
end

aCritState = {};

function setCritState(rSource, rTarget)
	if not (rSource and rSource.nodeCT) or not (rTarget and rTarget.nodeCT) then
		return;
	end
	
	if not aCritState[rSource.sCTNode] then
		aCritState[rSource.sCTNode] = {};
	end
	table.insert(aCritState[rSource.sCTNode], rTarget.sCTNode);
end

function clearCritState(rSource)
	if rSource and rSource.nodeCT then
		aCritState[rSource.sCTNode] = nil;
	end
end

function isCrit(rSource, rTarget)
	if not (rSource and rSource.nodeCT) or not (rTarget and rTarget.nodeCT) then
		return false;
	end

	if not aCritState[rSource.sCTNode] then
		return false;
	end
	
	for k,v in ipairs(aCritState[rSource.sCTNode]) do
		if v == rTarget.sCTNode then
			table.remove(aCritState[rSource.sCTNode], k);
			return true;
		end
	end
	
	return false;
end
