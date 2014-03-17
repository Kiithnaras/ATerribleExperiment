-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("heal", modHeal);
	ActionsManager.registerResultHandler("heal", onHeal);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = rAction.dice;
	rRoll.nMod = rAction.modifier;
	
	rRoll.sDesc = "[HEAL";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if rAction.stat ~= "" then
		local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect;
			if rAction.statmax and rAction.statmax > 0 then
				rRoll.sDesc = rRoll.sDesc .. ":" .. rAction.statmax;
			end
			rRoll.sDesc = rRoll.sDesc .. "]";
		end
	end
	if rAction.subtype == "temp" then
		rRoll.sDesc = rRoll.sDesc .. " [TEMP]";
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

function modHeal(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		-- DETERMINE STAT IF ANY
		local sActionStat = nil;
		local nActionStatMax = 0;
		local sModStat, sModMax = string.match(rRoll.sDesc, "%[MOD:(%w+):?(%d*)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
			nActionStatMax = tonumber(sModMax) or 0;
		end
		
		-- DETERMINE EFFECTS
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"HEAL"});
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			if (nActionStatMax > 0) and (nBonusStat > nActionStatMax) then
				nBonusStat = nActionStatMax;
			end
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- IF EFFECTS HAPPENED, THEN ADD NOTE
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
		table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onHeal(rSource, rTarget, rRoll)
	if rRoll.sDesc:match(" %[MAXIMIZE%]") then
		for _, v in ipairs(rRoll.aDice) do
			local nDieSides = tonumber(v.type:match("d(%d+)")) or 0;
			if nDieSides > 0 then
				v.result = nDieSides;
			end
		end
	end
	if rRoll.sDesc:match(" %[EMPOWER%]") then
		local nEmpowerTotal = ActionsManager.total(rRoll);
		nEmpowerMod = math.floor(nEmpowerTotal / 2);
		
		local sReplace = string.format(" [EMPOWER %+d]", nEmpowerMod);
		rRoll.sDesc = string.gsub(rRoll.sDesc, " %[EMPOWER%]", sReplace);
		rRoll.nMod = rRoll.nMod + nEmpowerMod;
	end
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
	
	local nTotal = ActionsManager.total(rRoll);
	ActionDamage.notifyApplyDamage(rSource, rTarget, rMessage.secret, rRoll.sType, rMessage.text, nTotal);
end
