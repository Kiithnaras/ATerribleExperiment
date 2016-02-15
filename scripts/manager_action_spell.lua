-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);

	ActionsManager.registerTargetingHandler("cast", onSpellTargeting);
	ActionsManager.registerTargetingHandler("clc", onSpellTargeting);
	ActionsManager.registerTargetingHandler("spellsave", onSpellTargeting);

	ActionsManager.registerModHandler("castsave", modCastSave);
	ActionsManager.registerModHandler("spellsave", modCastSave);
	ActionsManager.registerModHandler("clc", modCLC);
	ActionsManager.registerModHandler("save", modSave);
	ActionsManager.registerModHandler("concentration", modConcentration);
	
	ActionsManager.registerResultHandler("cast", onSpellCast);
	ActionsManager.registerResultHandler("castclc", onCastCLC);
	ActionsManager.registerResultHandler("castsave", onCastSave);
	ActionsManager.registerResultHandler("clc", onCLC);
	ActionsManager.registerResultHandler("spellsave", onSpellSave);
	ActionsManager.registerResultHandler("save", onSave);
end

function handleApplySave(msgOOB)
	-- GET THE TARGET ACTOR
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	
	local sSaveShort, sSaveDC = string.match(msgOOB.sDesc, "%[(%w+) DC (%d+)%]")
	if sSaveShort then
		local sSave = DataCommon.save_stol[sSaveShort];
		if sSave then
			performSaveRoll(nil, rTarget, sSave, msgOOB.nDC, (tonumber(msgOOB.nSecret) == 1), rSource, msgOOB.bRemoveOnMiss);
		end
	end
end

function notifyApplySave(rSource, rTarget, bSecret, sDesc, nDC, bRemoveOnMiss)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = sDesc;
	msgOOB.nDC = nDC;

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
	msgOOB.sTargetType = sTargetType;
	msgOOB.sTargetNode = sTargetNode;

	if bRemoveOnMiss then
		msgOOB.bRemoveOnMiss = 1;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function onSpellTargeting(rSource, aTargeting, rRolls)
	if OptionsManager.isOption("RMMT", "multi") then
		local aTargets = {};
		for _,vTargetGroup in ipairs(aTargeting) do
			for _,vTarget in ipairs(vTargetGroup) do
				table.insert(aTargets, vTarget);
			end
		end
		if #aTargets > 1 then
			for _,vRoll in ipairs(rRolls) do
				vRoll.bRemoveOnMiss = "true";
			end
		end
	end
	return aTargeting;
end

function getSpellCastRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "cast";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[CAST";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	
	return rRoll;
end

function getCLCRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "clc";
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = rAction.clc or 0;
	
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
	rRoll.sType = "spellsave";
	rRoll.aDice = {};
	rRoll.nMod = rAction.savemod or 0;
	
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

function performSaveRoll(draginfo, rActor, sSave, sSaveDC, bSecretRoll, rSource, bRemoveOnMiss)
	local rRoll = {};
	rRoll.sType = "save";
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = 0;
	
	-- Look up actor specific information
	local sAbility = nil;
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		if sActorType == "pc" then
			rRoll.nMod = DB.getValue(nodeActor, "saves." .. sSave .. ".total", 0);
			sAbility = DB.getValue(nodeActor, "saves." .. sSave .. ".ability", "");
		else
			rRoll.nMod = DB.getValue(nodeActor, sSave .. "save", 0);
		end
	end
	
	rRoll.sDesc = "[SAVE] " .. string.upper(string.sub(sSave, 1, 1)) .. string.sub(sSave, 2);
	rRoll.bSecret = bSecretRoll;

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
	end
	if bRemoveOnMiss then
		rRoll.bRemoveOnMiss = "true";
	end

	if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modCastSave(rSource, rTarget, rRoll)
	if rSource then
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if sActionStat then
			local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
			if nBonusEffects > 0 then
				local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
				rRoll.sDesc = rRoll.sDesc .. " " .. string.format(sFormat, nBonusStat);
				rRoll.nMod = rRoll.nMod + nBonusStat;
			end
		end
	end
end

function modCLC(rSource, rTarget, rRoll)
	if rSource then
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectManager.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			rRoll.nMod = rRoll.nMod - nNegLevelMod;
			rRoll.sDesc = rRoll.sDesc .. " [" .. Interface.getString("effects_tag") .. " -" .. nNegLevelCount .. "]";
		end
	end
end

function modSave(rSource, rTarget, rRoll)
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
		local rSaveSource = nil;
		if rRoll.sSource then
			rSaveSource = ActorManager.getActor("ct", rRoll.sSource);
		end
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, "SAVE", false, aSaveFilter, rSaveSource);
		if (nEffectCount > 0) then
			bEffects = true;
		end

		-- Get condition modifiers
		if EffectManager.hasEffectCondition(rSource, "Frightened") or 
				EffectManager.hasEffectCondition(rSource, "Panicked") or
				EffectManager.hasEffectCondition(rSource, "Shaken") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "Sickened") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if sSave == "reflex" and EffectManager.hasEffectCondition(rSource, "Slowed") then
			nAddMod = nAddMod - 1;
			bEffects = true;
		end

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
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
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

		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			rRoll.nMod = rRoll.nMod + nBonusStat;

			if nBonusStat ~= 0 then
				local sFormat = "%s [" .. Interface.getString("effects_tag") .. " %+d]";
				rRoll.sDesc = string.format(sFormat, rRoll.sDesc, nBonusStat);
			else
				rRoll.sDesc = rRoll.sDesc .. " [" .. Interface.getString("effects_tag") .. "]";
			end
		end
	end
end

function onSpellCast(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.dice = nil;
	rMessage.icon = "spell_cast";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. rTarget.sName .. "]";
	end
	
	Comm.deliverChatMessage(rMessage);
end

function onCastCLC(rSource, rTarget, rRoll)
	if rTarget then
		local nSR = ActorManager2.getSpellDefense(rTarget);
		if nSR > 0 then
			if not string.match(rRoll.sDesc, "%[SR NOT ALLOWED%]") then
				local rRoll = { sType = "clc", sDesc = rRoll.sDesc, aDice = {"d6","d6","d6"}, nMod = rRoll.nMod };
				ActionsManager.roll(rSource, rTarget, rRoll);
				return true;
			end
		end
	end
end

function onCastSave(rSource, rTarget, rRoll)
	if rTarget then
		local sSaveShort, sSaveDC = string.match(rRoll.sDesc, "%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.save_stol[sSaveShort];
			if sSave then
				notifyApplySave(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, rRoll.nMod, rRoll.bRemoveOnMiss);
				return true;
			end
		end
	end

	return false;
end

function onCLC(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);
	local bSRAllowed = not string.match(rRoll.sDesc, "%[SR NOT ALLOWED%]");
	
	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. rTarget.sName .. "]";
		
		if bSRAllowed then
			local nSR = ActorManager2.getSpellDefense(rTarget);
			if nSR > 0 then
				if nTotal >= nSR then
					rMessage.text = rMessage.text .. " [SUCCESS]";
				else
					rMessage.text = rMessage.text .. " [FAILURE]";
					if rSource then
						local bRemoveTarget = false;
						if OptionsManager.isOption("RMMT", "on") then
							bRemoveTarget = true;
						elseif rRoll.bRemoveOnMiss then
							bRemoveTarget = true;
						end
						
						if bRemoveTarget then
							TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
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

function onSave(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	
	local sSaveDC = string.match(rRoll.sDesc, "%[VS DC (%d+)%]");
	local nSaveDC = tonumber(sSaveDC) or 0;
	if nSaveDC > 0 then
		local nTotal = ActionsManager.total(rRoll);
		if nTotal >= nSaveDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";

			if rSource and rRoll.sSource then
				local bRemoveTarget = false;
				if OptionsManager.isOption("RMMT", "on") then
					bRemoveTarget = true;
				elseif rRoll.bRemoveOnMiss then
					bRemoveTarget = true;
				end
				
				if bRemoveTarget then
					TargetingManager.removeTarget(rRoll.sSource, ActorManager.getCTNodeName(rSource));
				end
			end
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end
