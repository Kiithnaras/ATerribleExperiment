-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINIT, handleApplyInit);

	ActionsManager.registerActionIcon("init", "action_roll");
	ActionsManager.registerModHandler("init", modRoll);
	ActionsManager.registerResultHandler("init", onResolve);
end

function handleApplyInit(msgOOB)
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(msgOOB.sSourceCTNode .. ".initresult", "number", nTotal);
end

function notifyApplyInit(rSource, nTotal)
	if not rSource then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYINIT;
	
	msgOOB.nTotal = nTotal;
	msgOOB.sSourceCTNode = rSource.sCTNode;

	Comm.deliverOOBMessage(msgOOB, "");
end

function performRoll(draginfo, rActor, bSecretRoll)
	-- Build the basic roll
	local rRoll = {};
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = 0;
	
	-- Build the description
	rRoll.sDesc = "[INIT]";
	if bSecretRoll then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end

	-- Determine the modifier and ability to use for this roll
	local sAbility = nil;
	if rActor then
		if rActor.sType == "pc" then
			rRoll.nMod = DB.getValue(rActor.nodeCreature, "initiative.total", 0);
			sAbility = DB.getValue(rActor.nodeCreature, "initiative.ability", "");
		elseif rActor.sType == "ct" or rActor.sType == "npc" then
			if rActor.nodeCT then
				rRoll.nMod = DB.getValue(rActor.nodeCT, "init", 0);
			else
				rRoll.nMod = DB.getValue(rActor.nodeCreature, "init", 0);
			end
		end
	end
	if sAbility and sAbility ~= "" and sAbility ~= "dexterity" then
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end
	
	-- Make the roll
	ActionsManager.performSingleRollAction(draginfo, rActor, "init", rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
	if rSource then
		local bEffects = false;

		-- DETERMINE STAT IF ANY
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			sActionStat = "dexterity";
		end
		
		-- DETERMINE EFFECTS
		local aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"INIT"});
		if nEffectCount > 0 then
			bEffects = true;
			for _,vDie in ipairs(aAddDice) do
				table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
		end
		
		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects = ActorManager.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			rRoll.nMod = rRoll.nMod + nBonusStat;
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
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
	end
end

function onResolve(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
	
	local nTotal = ActionsManager.total(rRoll);
	notifyApplyInit(rSource, nTotal);
end
