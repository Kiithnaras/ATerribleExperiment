-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerActionIcon("ability", "action_roll");
	ActionsManager.registerModHandler("ability", modRoll);
	ActionsManager.registerResultHandler("ability", onRoll);
end

function getRoll(rActor, sAbilityStat, nTargetDC, bSecretRoll, bAddName)
	local rRoll = {};
	
	-- SETUP
	rRoll.aDice = { "3d6" };
	rRoll.nMod = ActorManager.getAbilityBonus(rActor, sAbilityStat);
	
	-- BUILD THE OUTPUT
	rRoll.sDesc = "[ABILITY]";
	rRoll.sDesc = rRoll.sDesc .. " " .. StringManager.capitalize(sAbilityStat);
	rRoll.sDesc = rRoll.sDesc .. " check";

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
	
	return rRoll, rCustom;
end

function performRoll(draginfo, rActor, sAbilityStat, nTargetDC, bSecretRoll, bAddName)
	local rRoll, rCustom = getRoll(rActor, sAbilityStat, nTargetDC, bSecretRoll, bAddName);
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "ability", rRoll, rCustom);
end

function modRoll(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		local sActionStat = nil;
		local sAbility = string.match(rRoll.sDesc, "%[ABILITY%] (%w+) check");
		if sAbility then
			sAbility = string.lower(sAbility);
		else
			if string.match(rRoll.sDesc, "%[STABILIZATION%]") then
				sAbility = "constitution";
			end
		end

		-- GET ACTION MODIFIERS
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"ABIL"}, false, {sAbility});
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- GET CONDITION MODIFIERS
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

		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects = ActorManager.getAbilityEffectsBonus(rSource, sAbility);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- HANDLE NEGATIVE LEVELS
		local nNegLevelMod, nNegLevelCount = EffectsManager.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			nAddMod = nAddMod - nNegLevelMod;
			bEffects = true;
		end

		-- IF EFFECTS HAPPENED, THEN ADD NOTE
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

