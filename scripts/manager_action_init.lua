-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINIT, handleApplyInit);

	ActionsManager.registerModHandler("init", modRoll);
	ActionsManager.registerResultHandler("init", onResolve);
end

function handleApplyInit(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(ActorManager.getCTNode(rSource), "initresult", "number", nTotal);
end

function notifyApplyInit(rSource, nTotal)
	if not rSource then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYINIT;
	
	msgOOB.nTotal = nTotal;

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	Comm.deliverOOBMessage(msgOOB, "");
end

function getRoll(rActor, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "init";
	rRoll.aDice = { "d6","d6","d6" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[INIT]";
	
	rRoll.bSecret = bSecretRoll;

	-- Determine the modifier and ability to use for this roll
	local sAbility = nil;
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		if sActorType == "pc" then
			rRoll.nMod = DB.getValue(nodeActor, "initiative.total", 0);
			sAbility = DB.getValue(nodeActor, "initiative.ability", "");
		else
			rRoll.nMod = DB.getValue(nodeActor, "init", 0);
		end
	end
	if sAbility and sAbility ~= "" and sAbility ~= "dexterity" then
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end

	return rRoll;
end

function performRoll(draginfo, rActor, bSecretRoll)
	local rRoll = getRoll(rActor, bSecretRoll);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
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
		local aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"INIT"});
		if nEffectCount > 0 then
			bEffects = true;
			for _,vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
		end
		
		-- Get condition modifiers
		if EffectManager.hasEffectCondition(rSource, "Deafened") then
			bEffects = true;
			rRoll.nMod = rRoll.nMod - 4;
		end
		
		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			rRoll.nMod = rRoll.nMod + nBonusStat;
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
