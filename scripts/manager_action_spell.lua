-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);

	ActionsManager.registerActionIcon("spellcast", "action_roll");
	ActionsManager.registerActionIcon("clc", "action_roll");
	ActionsManager.registerActionIcon("save", "action_roll");
	ActionsManager.registerActionIcon("cast", "action_roll");
	ActionsManager.registerActionIcon("castattack", "action_roll");
	ActionsManager.registerActionIcon("castclc", "action_roll");
	ActionsManager.registerActionIcon("castsave", "action_roll");
	ActionsManager.registerActionIcon("spellclc", "action_roll");
	ActionsManager.registerActionIcon("spellsave", "action_roll");
	ActionsManager.registerActionIcon("concentration", "action_roll");
	
	ActionsManager.registerMultiHandler("spellcast", translateSpellCast);
	
	ActionsManager.registerTargetingHandler("spellcast", onCastTargeting);
	ActionsManager.registerTargetingHandler("clc", onTargeting);
	ActionsManager.registerTargetingHandler("spellsave", onTargeting);
	
	ActionsManager.registerModHandler("castattack", modCastAttack);
	ActionsManager.registerModHandler("castsave", modCastSave);
	ActionsManager.registerModHandler("clc", modCLC);
	ActionsManager.registerModHandler("spellsave", modSpellSave);
	ActionsManager.registerModHandler("save", modSave);
	ActionsManager.registerModHandler("concentration", modConcentration);
	
	ActionsManager.registerResultHandler("cast", onSpellCast);
	ActionsManager.registerResultHandler("castattack", onCastAttack);
	ActionsManager.registerResultHandler("castclc", onCastCLC);
	ActionsManager.registerResultHandler("castsave", onCastSave);
	ActionsManager.registerResultHandler("spellclc", onSpellCLC);
	ActionsManager.registerResultHandler("clc", onCLC);
	ActionsManager.registerResultHandler("spellsave", onSpellSave);
	ActionsManager.registerResultHandler("save", onSave);
end

function handleApplySave(msgOOB)
	-- GET THE TARGET ACTOR
	local rSource = ActorManager.getActor("ct", msgOOB.sSourceCTNode);
	if not rSource then
		rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceCreatureNode);
	end
	local rTarget = ActorManager.getActor("ct", msgOOB.sTargetCTNode);
	if not rTarget then
		rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetCreatureNode);
	end
	
	local sSaveShort, sSaveDC = string.match(msgOOB.sDesc, "%[(%w+) DC (%d+)%]")
	if sSaveShort then
		local sSave = DataCommon.save_stol[sSaveShort];
		if sSave then
			local isGMOnly = string.match(msgOOB.sDesc, "^%[GM%]");
			local bRemoveOnMiss = string.match(msgOOB.sDesc, "%[MULTI%]") or string.match(msgOOB.sDesc, "%[RM%]");
	
			performSaveRoll(nil, rTarget, sSave, msgOOB.nDC, isGMOnly, true, rSource, bRemoveOnMiss);
		end
	end
end

function notifyApplySave(rSource, rTarget, sDesc, nDC)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
	
	msgOOB.sDesc = sDesc;
	msgOOB.nDC = nDC;
	if rSource then
		msgOOB.sSourceType = rSource.sType;
		msgOOB.sSourceCreatureNode = rSource.sCreatureNode;
		msgOOB.sSourceCTNode = rSource.sCTNode;
	end
	msgOOB.sTargetType = rTarget.sType;
	msgOOB.sTargetCreatureNode = rTarget.sCreatureNode;
	msgOOB.sTargetCTNode = rTarget.sCTNode;

	if not User.isHost() and rTarget.sType == "pc" and rTarget.nodeCreature and rTarget.nodeCreature.isOwner() then
		handleApplySave(msgOOB);
	else
		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function onCastTargeting(rSource, rRolls)
	local aTargets = TargetingManager.getFullTargets(rSource);
	
	if #aTargets > 1 and OptionsManager.isOption("RMMT", "multi") then
		for i = 2, 4 do
			if rRolls[i] then
				rRolls[i].sDesc = rRolls[i].sDesc .. " [MULTI]";
			end
		end
	elseif OptionsManager.isOption("RMMT", "on") then
		for i = 2, 4 do
			if rRolls[i] then
				rRolls[i].sDesc = rRolls[i].sDesc .. " [RM]";
			end
		end
	end
	
	local aTargeting = {};
	for _,vTarget in ipairs(aTargets) do
		table.insert(aTargeting, { vTarget });
	end
	
	return aTargeting;
end

function onTargeting(rSource, rRolls)
	local aTargets = TargetingManager.getFullTargets(rSource);
	
	if #aTargets > 1 and OptionsManager.isOption("RMMT", "multi") then
		for _,vRoll in ipairs(rRolls) do
			vRoll.sDesc = vRoll.sDesc .. " [MULTI]";
		end
	end
	
	local aTargeting = {};
	for _,vTarget in ipairs(aTargets) do
		table.insert(aTargeting, { vTarget });
	end
	
	return aTargeting;
end

function translateSpellCast(nSlot)
	local sType = "";
	
	if nSlot == 1 then
		sType = "cast";
	elseif nSlot == 2 then
		sType = "castattack";
	elseif nSlot == 3 then
		sType = "castclc";
	elseif nSlot == 4 then
		sType = "castsave";
	end
	
	return sType;
end

function getSpellCastRoll(rActor, rAction)
	local rRoll = {};

	-- Build the basic roll
	rRoll.aDice = {};
	rRoll.nMod = 0;
	
	-- Build the description
	rRoll.sDesc = "[CAST";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	
	return rRoll;
end

function getCLCRoll(rActor, rAction)
	local rRoll = {};

	-- Build the basic roll
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = rAction.clc or 0;
	
	-- Build the description
	rRoll.sDesc = "[CL CHECK";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if rAction.sr == "no" then
		rRoll.sDesc = rRoll.sDesc .. " [SR NOT ALLOWED]";
	end
	
	return rRoll;
end

function getSaveVsRoll(rActor, rAction)
	local rRoll = {};

	-- Build the basic roll
	rRoll.aDice = {};
	rRoll.nMod = rAction.savemod or 0;
	
	-- Build the description
	rRoll.sDesc = "[SAVE VS";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if rAction.save == "fortitude" then
		rRoll.sDesc = rRoll.sDesc .. " [FORT DC " .. rAction.savemod .. "]";
	elseif rAction.save == "reflex" then
		rRoll.sDesc = rRoll.sDesc .. " [REF DC " .. rAction.savemod .. "]";
	elseif rAction.save == "will" then
		rRoll.sDesc = rRoll.sDesc .. " [WILL DC " .. rAction.savemod .. "]";
	end

	if rAction.dcstat then
		local sAbilityEffect = DataCommon.ability_ltos[rAction.dcstat];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end

	return rRoll;
end

function performSaveRoll(draginfo, rActor, sSave, sSaveDC, bSecretRoll, bAddName, rSource, bRemoveOnMiss)
	-- Build basic roll
	local rRoll = {};
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = 0;
	
	-- Look up actor specific information
	local sAbility = nil;
	if rActor then
		if rActor.sType == "pc" then
			rRoll.nMod = DB.getValue(rActor.nodeCreature, "saves." .. sSave .. ".total", 0);
			sAbility = DB.getValue(rActor.nodeCreature, "saves." .. sSave .. ".ability", "");
		elseif rActor.sType == "ct" or rActor.sType == "npc" then
			if rActor.nodeCT then
				rRoll.nMod = DB.getValue(rActor.nodeCT, sSave .. "save", 0);
			else
				rRoll.nMod = DB.getValue(rActor.nodeCreature, sSave .. "save", 0);
			end
		end
	end
	
	-- Build the description
	local bOverride = false;
	rRoll.sDesc = "[SAVE] " .. string.upper(string.sub(sSave, 1, 1)) .. string.sub(sSave, 2);
	if bAddName then
		rRoll.sDesc = "[ADDNAME] " .. rRoll.sDesc;
	end
	if bSecretRoll then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end
	if sAbility and sAbility ~= "" then
		if (sSave == "fortitude" and sAbility ~= "constitution") or
				(sSave == "reflex" and sAbility ~= "dexterity") or
				(sSave == "will" and sAbility ~= "wisdom") then
			local sAbilityEffect = DataCommon.ability_ltos[sAbility];
			if sAbilityEffect then
				rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
			end
		end
	end
	if sSaveDC then
		rRoll.sDesc = rRoll.sDesc .. " [VS DC " .. sSaveDC .. "]";
		bOverride = true;
	end
	if bRemoveOnMiss then
		rRoll.sDesc = rRoll.sDesc .. " [RM]";
	end

	local rCustom = nil;
	if rSource then
		rCustom = {};
		rCustom.sSourceCT = rSource.sCTNode;
	end

	-- Make the roll
	ActionsManager.performSingleRollAction(draginfo, rActor, "save", rRoll, rCustom, bOverride);
end

function modCastAttack(rSource, rTarget, rRoll)
	if (#(rRoll.aDice) == 0) and (rRoll.nMod == 0) then
		return;
	end
	
	ActionAttack.modAttack(rSource, rTarget, rRoll);
end

function modCastSave(rSource, rTarget, rRoll)
	if rSource then
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if sActionStat then
			local nBonusStat, nBonusEffects = ActorManager.getAbilityEffectsBonus(rSource, sActionStat);
			if nBonusEffects > 0 then
				rRoll.sDesc = rRoll.sDesc .. " " .. string.format("[EFFECTS %+d]", nBonusStat);
				rRoll.nMod = rRoll.nMod + nBonusStat;
			end
		end
	end
end

function modCLC(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
	if rSource then
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectsManager.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			rRoll.nMod = rRoll.nMod - nNegLevelMod;
			rRoll.sDesc = rRoll.sDesc .. " [EFFECTS -" .. nNegLevelCount .. "]";
		end
	end
end

function modSpellSave(rSource, rTarget, rRoll)
	modCastSave(rSource, rTarget, rRoll);
end

function modSave(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		-- Determine ability used
		local sSave = nil;
		local sSaveMatch = string.match(rRoll.sDesc, "%[SAVE%] ([^[]+)");
		if sSaveMatch then
			sSave = string.lower(StringManager.trim(sSaveMatch));
		end
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			if sSave == "fortitude" then
				sActionStat = "constitution";
			elseif sSave == "reflex" then
				sActionStat = "dexterity";
			elseif sSave == "will" then
				sActionStat = "wisdom";
			end
		end
		
		-- Build save filter
		local aSaveFilter = {};
		if sSave then
			table.insert(aSaveFilter, sSave);
		end
		
		-- Get effect modifiers
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, "SAVE", false, aSaveFilter, rTarget);
		if (nEffectCount > 0) then
			bEffects = true;
		end

		-- Get condition modifiers
		if EffectsManager.hasEffectCondition(rSource, "Frightened") or 
				EffectsManager.hasEffectCondition(rSource, "Panicked") or
				EffectsManager.hasEffectCondition(rSource, "Shaken") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if EffectsManager.hasEffectCondition(rSource, "Sickened") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if sSave == "reflex" and EffectsManager.hasEffectCondition(rSource, "Slowed") then
			nAddMod = nAddMod - 1;
			bEffects = true;
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
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function modConcentration(rSource, rTarget, rRoll)
	if rSource then
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end

		local nBonusStat, nBonusEffects = ActorManager.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			rRoll.nMod = rRoll.nMod + nBonusStat;

			if nBonusStat ~= 0 then
				rRoll.sDesc = string.format("%s [EFFECTS %+d]", rRoll.sDesc, nBonusStat);
			else
				rRoll.sDesc = rRoll.sDesc .. " [EFFECTS]";
			end
		end
	end
end

function onSpellCast(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.dice = nil;
	rMessage.icon = "indicator_cast";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. rTarget.sName .. "]";
	end
	
	Comm.deliverChatMessage(rMessage);
end

function onCastAttack(rSource, rTarget, rRoll)
	if (#(rRoll.aDice) == 0) and (rRoll.nMod == 0) then
		return;
	end
	
	ActionAttack.onAttack(rSource, rTarget, rRoll);
end

function onCastCLC(rSource, rTarget, rRoll)
	if rTarget then
		local nSR = ActorManager.getSpellDefense(rTarget);
		if nSR > 0 then
			if not string.match(rRoll.sDesc, "%[SR NOT ALLOWED%]") then
				local rRoll = { sType = "clc", sDesc = rRoll.sDesc, aDice = {"d6","d6","d6"}, nMod = rRoll.nMod };
				ActionsManager.roll(rSource, rTarget, rRoll);
				return true;
			end
		end
	end
	
	return false;
end

function onCastSave(rSource, rTarget, rRoll)
	if rTarget then
		local sSaveShort, sSaveDC = string.match(rRoll.sDesc, "%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.save_stol[sSaveShort];
			if sSave then
				notifyApplySave(rSource, rTarget, rRoll.sDesc, rRoll.nMod);
				return true;
			end
		end
	end

	return false;
end

function onSpellCLC(rSource, rTarget, rRoll)
	if onCastCLC(rSource, rTarget, rRoll) then
		return;
	end
	
	local rRoll = { sType = "clc", sDesc = rRoll.sDesc, aDice = {"d6","d6","d6"}, nMod = rRoll.nMod };
	ActionsManager.roll(rSource, rTarget, rRoll);
end

function onCLC(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);
	local bSRAllowed = not string.match(rRoll.sDesc, "%[SR NOT ALLOWED%]");
	
	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. rTarget.sName .. "]";
		
		if bSRAllowed then
			local nSR = ActorManager.getSpellDefense(rTarget);
			if nSR > 0 then
				if nTotal >= nSR then
					rMessage.text = rMessage.text .. " [SUCCESS]";
				else
					rMessage.text = rMessage.text .. " [FAILURE]";
					if rSource then
						local bRemoveTarget = false;
						if OptionsManager.isOption("RMMT", "on") then
							bRemoveTarget = true;
						elseif OptionsManager.isOption("RMMT", "multi") then
							if (string.match(rRoll.sDesc, "%[MULTI%]")) then
								bRemoveTarget = true;
							end
						end
						
						if bRemoveTarget then
							TargetingManager.removeTargetEx(rSource.nodeCT, rTarget.sCTNode);
						end
					end
				end
			else
				rMessage.text = rMessage.text .. " [TARGET HAS NO SR]";
			end
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end

function onSpellSave(rSource, rTarget, rRoll)
	if onCastSave(rSource, rTarget, rRoll) then
		return;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

function onSave(rSource, rTarget, rRoll, rCustom)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	
	local sSaveDC = string.match(rRoll.sDesc, "%[VS DC (%d+)%]");
	local nSaveDC = tonumber(sSaveDC) or 0;
	if nSaveDC > 0 then
		local nTotal = ActionsManager.total(rRoll);
		if nTotal >= nSaveDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";

			if rSource and rCustom and rCustom.sSourceCT then
				local bRemoveTarget = false;
				if string.match(rRoll.sDesc, "%[RM%]") then
					bRemoveTarget = true;
				end
				
				if bRemoveTarget then
					local nodeCT = DB.findNode(rCustom.sSourceCT);
					TargetingManager.removeTargetEx(nodeCT, rSource.sCTNode);
				end
			end
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end
