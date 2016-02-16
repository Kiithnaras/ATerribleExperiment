-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYEFF = "applyeff";
OOB_MSGTYPE_EXPIREEFF = "expireeff";

local nLocked = 0;
local aUsedActionEffects = {};

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYEFF, handleApplyEffect);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_EXPIREEFF, handleExpireEffect);

	CombatManager.setCustomInitChange(processEffects);
end

function handleApplyEffect(msgOOB)
	-- Get the combat tracker node
	local nodeCTEntry = DB.findNode(msgOOB.sTargetNode);
	if not nodeCTEntry then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectapplyfail") .. " (" .. msgOOB.sTargetNode .. ")");
		return;
	end
	
	-- Reconstitute the effect details
	local rEffect = {};
	rEffect.sName = msgOOB.sName;
	rEffect.nDuration = tonumber(msgOOB.nDuration) or 1;
	rEffect.sUnits = msgOOB.sUnits;
	rEffect.nInit = tonumber(msgOOB.nInit) or 0;
	rEffect.sSource = msgOOB.sSource;
	rEffect.nGMOnly = tonumber(msgOOB.nGMOnly) or 0;
	rEffect.sApply = msgOOB.sApply;
	
	local sEffectTargetNode = msgOOB.sEffectTargetNode or "";
	
	-- Apply the damage
	addEffect(msgOOB.user, msgOOB.identity, nodeCTEntry, rEffect, true, sEffectTargetNode);
end

function handleExpireEffect(msgOOB)
	-- Get the effect and combat tracker node
	local nodeEffect = DB.findNode(msgOOB.sEffectNode);
	if not nodeEffect then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectdeletefail") .. " (" .. msgOOB.sEffectNode .. ")");
		return;
	end
	local nodeActor = nodeEffect.getChild("...");
	if not nodeActor then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectmissingactor") .. " (" .. msgOOB.sEffectNode .. ")");
		return;
	end
	
	-- Get the parameters
	local nExpireType = tonumber(msgOOB.nExpireType) or 0;
	
	-- Apply the damage
	expireEffect(nodeActor, nodeEffect, nExpireType);
end

function notifyApply(rEffect, vTargets, sEffectTargetNode)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYEFF;
	if User.isHost() then
		msgOOB.user = "";
	else
		msgOOB.user = User.getUsername();
	end
	msgOOB.identity = User.getIdentityLabel();

	msgOOB.sName = rEffect.sName or "";
	msgOOB.nDuration = rEffect.nDuration or 1;
	msgOOB.sUnits = rEffect.sUnits or "";
	msgOOB.nInit = rEffect.nInit or 0;
	msgOOB.sSource = rEffect.sSource or ""; 
	msgOOB.nGMOnly = rEffect.nGMOnly or 0; 
	msgOOB.sApply = rEffect.sApply or "";

	msgOOB.sEffectTargetNode = sEffectTargetNode;
	
	if type(vTargets) == "table" then
		for _, v in pairs(vTargets) do
			msgOOB.sTargetNode = v;
			Comm.deliverOOBMessage(msgOOB, "");
		end
	else
		msgOOB.sTargetNode = vTargets;
		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function notifyExpire(varEffect, nMatch)
	if type(varEffect) == "databasenode" then
		varEffect = varEffect.getNodeName();
	elseif type(varEffect) ~= "string" then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_EXPIREEFF;
	msgOOB.sEffectNode = varEffect;
	msgOOB.nExpireType = nMatch;
	
	Comm.deliverOOBMessage(msgOOB, "");
end

function setEffect(nodeEffect, rEffect)
	DB.setValue(nodeEffect, "label", "string", rEffect.sName);
	DB.setValue(nodeEffect, "isgmonly", "number", rEffect.nGMOnly);
	DB.setValue(nodeEffect, "apply", "string", rEffect.sApply);
	DB.setValue(nodeEffect, "duration", "number", rEffect.nDuration);
	if nodeEffect.getChild("unit") then
		DB.setValue(nodeEffect, "unit", "string", rEffect.sUnits);
	end
	if nodeEffect.getChild("source_name") then
		DB.setValue(nodeEffect, "source_name", "string", rEffect.sSource);
	end
	if nodeEffect.getChild("init") then
		DB.setValue(nodeEffect, "init", "string", rEffect.nInit);
	end
end

function getEffect(nodeEffect)
	return { 
			sName = DB.getValue(nodeEffect, "label", ""),
			nGMOnly = DB.getValue(nodeEffect, "isgmonly", 0),
			sApply = DB.getValue(nodeEffect, "apply", ""),
			nDuration = DB.getValue(nodeEffect, "duration", 0),
			sUnits = DB.getValue(nodeEffect, "unit", ""),
			sSource = DB.getValue(nodeEffect, "source_name", ""),
			nInit = DB.getValue(nodeEffect, "init", 0),
			};
end

--
-- EFFECTS
--

function message(sMsg, nodeCTEntry, gmflag, sUser)
	-- ADD NAME OF CT ENTRY TO NOTIFICATION
	if nodeCTEntry then
		sMsg = sMsg .. " [on " .. DB.getValue(nodeCTEntry, "name", "") .. "]";
	end

	-- BUILD MESSAGE OBJECT
	local msg = {font = "msgfont", icon = "roll_effect", text = sMsg};
	
	-- DELIVER MESSAGE BASED ON TARGET AND GMFLAG
	if sUser then
		if sUser == "" then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, sUser);
		end
	elseif gmflag then
		msg.secret = true;
		if User.isHost() then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, User.getUsername());
		end
	else
		Comm.deliverChatMessage(msg);
	end
end

function parseEffect(s)
	local aEffects = {};
	
	local sEffectClause;
	for sEffectClause in string.gmatch(s, "([^;]*);?") do
		local aWords, aWordStats = StringManager.parseWords(sEffectClause, "%[%]%(%):");
		if #aWords > 0 then
			local sType = string.match(aWords[1], "^([^:]+):");
			local aDice = {};
			local nMod = 0;
			
			local aRemainder = {};
			local nRemainderIndex = 1;
			
			if sType then
				nRemainderIndex = 2;
				
				local sValueCheck = string.sub(aWords[1], #sType + 2);
				if sValueCheck ~= "" then
					table.insert(aWords, 2, sValueCheck);
					table.insert(aWordStats, 2, { startpos = aWordStats[1].startpos + #sType + 1, endpos = aWordStats[1].endpos });
					aWords[1] = aWords[1]:sub(1, #sType + 1);
					aWordStats[1].endpos = #sType + 1;
				end
				
				if #aWords > 1 then
					if StringManager.isDiceString(aWords[2]) then
						aDice, nMod = StringManager.convertStringToDice(aWords[2]);
						nRemainderIndex = 3;
					end
				end
			end
			
			if nRemainderIndex <= #aWords then
				while nRemainderIndex <= #aWords and aWords[nRemainderIndex]:match("^%[%a+%]$") do
					table.insert(aRemainder, aWords[nRemainderIndex]);
					nRemainderIndex = nRemainderIndex + 1;
				end
			end
			
			if nRemainderIndex <= #aWords then
				local sRemainder = sEffectClause:sub(aWordStats[nRemainderIndex].startpos);
				local nStartRemainderPhrase = 1;
				local i = 1;
				while i < #sRemainder do
					local sCheck = sRemainder:sub(i, i);
					if sCheck == "," then
						local sRemainderPhrase = sRemainder:sub(nStartRemainderPhrase, i - 1);
						if sRemainderPhrase and sRemainderPhrase ~= "" then
							sRemainderPhrase = StringManager.trim(sRemainderPhrase);
							table.insert(aRemainder, sRemainderPhrase);
						end
						nStartRemainderPhrase = i + 1;
					elseif sCheck == "(" then
						while i < #sRemainder do
							if sRemainder:sub(i, i) == ")" then
								break;
							end
							i = i + 1;
						end
					elseif sCheck == "[" then
						while i < #sRemainder do
							if sRemainder:sub(i, i) == "]" then
								break;
							end
							i = i + 1;
						end
					end
					i = i + 1;
				end
				local sRemainderPhrase = sRemainder:sub(nStartRemainderPhrase, #sRemainder);
				if sRemainderPhrase and sRemainderPhrase ~= "" then
					sRemainderPhrase = StringManager.trim(sRemainderPhrase);
					table.insert(aRemainder, sRemainderPhrase);
				end
			end

			table.insert(aEffects, {type = sType or "", mod = nMod, dice = aDice, 
					remainder = aRemainder, original = StringManager.trim(sEffectClause)});
		end
	end
	
	return aEffects;
end

function rebuildParsedEffect(aEffectComps)
	local aEffect = {};
	
	for kComp, rComp in ipairs(aEffectComps) do
		local aComp = {};

		if rComp.type ~= "" then
			table.insert(aComp, rComp.type .. ":");
		end

		local sDiceString = StringManager.convertDiceToString(rComp.dice, rComp.mod);
		if sDiceString ~= "" then
			table.insert(aComp, sDiceString);
		end
		
		if #(rComp.remainder) > 0 then
			table.insert(aComp, table.concat(rComp.remainder, ","));
		end
		
		table.insert(aEffect, table.concat(aComp, " "));
	end
	
	return table.concat(aEffect, "; ");
end

function getEffectsString(nodeCTEntry, bPublicOnly)
	-- Start with an empty effects list string
	local aOutputEffects = {};
	
	-- Iterate through each effect
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);
	for _,v in pairs(aSorted) do
		if DB.getValue(v, "isactive", 0) == 1 then
			local sLabel = DB.getValue(v, "label", "");

			local bAddEffect = true;
			local bGMOnly = false;
			if sLabel == "" then
				bAddEffect = false;
			elseif DB.getValue(v, "isgmonly", 0) == 1 then
				if User.isHost() and not bPublicOnly then
					bGMOnly = true;
				else
					bAddEffect = false;
				end
			end

			if bAddEffect then
				local aAddCompList = {};
				local bTargeted = false;
				local aEffectComps = EffectManager.parseEffect(sLabel);
				for _,vComp in ipairs(aEffectComps) do
					if vComp.remainder[1] == "TRGT" then
						bTargeted = true;
					else
						table.insert(aAddCompList, vComp);
					end
				end
				
				if isTargetedEffect(v) then
					local sTargets = table.concat(getEffectTargets(v, true), ",");
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[TRGT: " .. sTargets .. "]"}});
				elseif bTargeted then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[TRGT]"}});
				end

				local sApply = DB.getValue(v, "apply", "");
				if sApply == "action" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[ACTN]"}});
				elseif sApply == "roll" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[ROLL]"}});
				elseif sApply == "single" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[SNG]"}});
				end
				
				local nDuration = DB.getValue(v, "duration", 0);
				if nDuration > 0 then
					table.insert(aAddCompList,  {type = "", mod = 0, dice = {}, remainder = {"[D: " .. nDuration .. "]"}});
				end
				
				local sOutputLabel = rebuildParsedEffect(aAddCompList);
				if bGMOnly then
					sOutputLabel = "(" .. sOutputLabel .. ")";
				end

				table.insert(aOutputEffects, sOutputLabel);
			end
		end
	end
	
	-- Return the final effect list string
	return table.concat(aOutputEffects, " | ");
end

function isGMEffect(nodeActor, nodeEffect)
	if nodeEffect and (DB.getValue(nodeEffect, "isgmonly", 0) == 1) then
		return true;
	end
	if nodeActor and CombatManager.isCTHidden(nodeActor) then
		return true;
	end
	return false;
end

function isTargetedEffect(nodeEffect)
	return (DB.getChildCount(nodeEffect, "targets") > 0);
end

function getEffectTargets(nodeEffect, bUseName)
	local aTargets = {};
	
	for _,nodeTarget in pairs(DB.getChildren(nodeEffect, "targets")) do
		local sNode = DB.getValue(nodeTarget, "noderef", "");
		if bUseName then
			local nodeTargetCT = DB.findNode(sNode);
			table.insert(aTargets, DB.getValue(nodeTargetCT, "name", ""));
		else
			table.insert(aTargets, sNode);
		end
	end

	return aTargets;
end

function removeEffect(nodeCTEntry, sEffPatternToRemove)
	-- VALIDATE
	if not sEffPatternToRemove then
		return;
	end

	-- COMPARE EFFECT NAMES TO EFFECT TO REMOVE
	for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		local s = DB.getValue(nodeEffect, "label", "");
		if string.match(s, sEffPatternToRemove) then
			nodeEffect.delete();
			return;
		end
	end
end

function addEffect(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, sEffectTargetNode)
	-- VALIDATE
	if not nodeCT or not rNewEffect or not rNewEffect.sName then
		return;
	end
	rNewEffect.nDuration = rNewEffect.nDuration or 1;
	if rNewEffect.sUnits == "minute" then
		rNewEffect.nDuration = rNewEffect.nDuration * 10;
	elseif rNewEffect.sUnits == "hour" or rNewEffect.sUnits == "day" then
		rNewEffect.nDuration = 0;
	end
	rNewEffect.nInit = rNewEffect.nInit or 0;
	
	-- GET EFFECTS LIST
	local sCTName = DB.getValue(nodeCT, "name", "");
	local nodeEffectsList = nodeCT.createChild("effects");
	if not nodeEffectsList then
		return;
	end
	
	-- PARSE NEW EFFECT
	local aNewEffectParse = parseEffect(rNewEffect.sName);
	
	-- CHECKS TO IGNORE NEW EFFECT (DUPLICATE, SHORTER, WEAKER)
	for k, v in pairs(nodeEffectsList.getChildren()) do
		-- CHECK FOR DUPLICATE EFFECT (ONLY IF LABEL, INIT AND DURATION ARE THE SAME)
		if (DB.getValue(v, "label", "") == rNewEffect.sName) and 
				(DB.getValue(v, "init", 0) == rNewEffect.nInit) and
				(DB.getValue(v, "duration", 0) == rNewEffect.nDuration) then
			local sMsg = "Effect ['" .. rNewEffect.sName .. "'] ";
			if rNewEffect.nDuration > 0 then
				sMsg = sMsg .. " [D:" .. rNewEffect.nDuration .. "] ";
			end
			sMsg = sMsg .. "-> [ALREADY EXISTS]";
			message(sMsg, nodeCT, false, sUser);
			return;
		end
	end
	
	-- WRITE EFFECT RECORD
	local nodeTargetEffect = nodeEffectsList.createChild();
	DB.setValue(nodeTargetEffect, "label", "string", rNewEffect.sName);
	DB.setValue(nodeTargetEffect, "duration", "number", rNewEffect.nDuration);
	DB.setValue(nodeTargetEffect, "init", "number", rNewEffect.nInit);
	DB.setValue(nodeTargetEffect, "isgmonly", "number", rNewEffect.nGMOnly);
	if rNewEffect.sApply then
		DB.setValue(nodeTargetEffect, "apply", "string", rNewEffect.sApply);
	end
	DB.setValue(nodeTargetEffect, "isactive", "number", 1);

	-- HANDLE EFFECT TARGET SETTING
	if sEffectTargetNode and sEffectTargetNode ~= "" then
		addEffectTarget(nodeTargetEffect, sEffectTargetNode);
	end
	
	-- BUILD MESSAGE
	local msg = {font = "msgfont", icon = "roll_effect"};
	msg.text = "Effect ['" .. rNewEffect.sName .. "'] ";
	if rNewEffect.nDuration > 0 then
		msg.text = msg.text .. " [D:" .. rNewEffect.nDuration .. "] ";
	end
	msg.text = msg.text .. "-> [to " .. sCTName .. "]";
	
	-- HANDLE APPLIED BY SETTING
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		DB.setValue(nodeTargetEffect, "source_name", "string", rNewEffect.sSource);
		msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
	end
	
	-- SEND MESSAGE
	if bShowMsg then
		if isGMEffect(nodeCT, nodeTargetEffect) then
			if sUser == "" then
				msg.secret = true;
				Comm.addChatMessage(msg);
			elseif sUser ~= "" then
				Comm.addChatMessage(msg);
				Comm.deliverChatMessage(msg, sUser);
			end
		else
			Comm.deliverChatMessage(msg);
		end
	end
end

function expireEffect(nodeActor, nodeEffect, nExpireComponent, bOverride)
	-- VALIDATE
	if not nodeEffect then
		return false;
	end

	-- PARSE THE EFFECT
	local sEffect = DB.getValue(nodeEffect, "label", "");

	-- DETERMINE MESSAGE VISIBILITY
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);

	-- CHECK FOR PARTIAL EXPIRATION
	if nExpireComponent > 0 then
		local listEffectComp = parseEffect(sEffect);
		if #listEffectComp > 1 then
			table.remove(listEffectComp, nExpireComponent);

			local sNewEffect = rebuildParsedEffect(listEffectComp);
			DB.setValue(nodeEffect, "label", "string", sNewEffect);

			message("Effect ['" .. sEffect .. "'] -> [SINGLE MOD USED]", nodeActor, bGMOnly);
			return true;
		end
	end
	
	-- DELETE THE EFFECT
	sMsg = "Effect ['" .. sEffect .. "'] -> [EXPIRED]";
	nodeEffect.delete();

	-- SEND NOTIFICATION TO THE HOST
	message(sMsg, nodeActor, bGMOnly);
	return true;
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
	-- EXIT IF EMPTY FHEAL OR DMGO
	if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
		return;
	end
	
	-- BUILD MESSAGE
	local aResults = {};
	if rEffectComp.type == "FHEAL" then
		-- MAKE SURE AFFECTED ACTOR IS WOUNDED
		if DB.getValue(nodeActor, "wounds", 0) == 0 and DB.getValue(nodeActor, "nonlethal", 0) == 0 then
			return;
		end
		
		table.insert(aResults, "[FHEAL] Fast Heal");

	elseif rEffectComp.type == "REGEN" then
		-- MAKE SURE AFFECTED ACTOR IS WOUNDED
		local bPFMode = DataCommon.isPFRPG();
		if bPFMode then
			if DB.getValue(nodeActor, "wounds", 0) == 0 and DB.getValue(nodeActor, "nonlethal", 0) == 0 then
				return;
			end
		else
			if DB.getValue(nodeActor, "nonlethal", 0) == 0 then
				return;
			end
		end
		
		table.insert(aResults, "[REGEN] Regeneration");

	else
		table.insert(aResults, "[DAMAGE] Ongoing Damage");

		if #(rEffectComp.remainder) > 0 then
			local sDamageType = string.lower(table.concat(rEffectComp.remainder, ","));
			table.insert(aResults, "[TYPE: " .. sDamageType .. "]");
		end
	end

	-- MAKE ROLL AND APPLY RESULTS
	local rTarget = ActorManager.getActorFromCT(nodeActor);
	local rRoll = { sType = "damage", sDesc = table.concat(aResults, " "), aDice = rEffectComp.dice, nMod = rEffectComp.mod };
	if isGMEffect(nodeActor, nodeEffect) then
		rRoll.bSecret = true;
	end
	ActionsManager.roll(nil, rTarget, rRoll);
end

function processEffects(nodeCurrentActor, nodeNewActor)
	-- Get sorted combatant list
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries == 0 then
		return;
	end
		
	-- Determine current and new initiative values
	local nCurrentInit = 10000;
	if nodeCurrentActor then
		nCurrentInit = DB.getValue(nodeCurrentActor, "initresult", 0); 
	end
	local nNewInit = -10000;
	if nodeNewActor then
		nNewInit = DB.getValue(nodeNewActor, "initresult", 0);
	end
	
	-- For each actor, advance durations, and process start of turn special effects
	local bProcessSpecial = (nodeCurrentActor == nil);
	for i = 1,#aEntries do
		local nodeActor = aEntries[i];
		
		-- Check each effect
		for _,nodeEffect in pairs(DB.getChildren(nodeActor, "effects")) do
			-- Make sure effect is active
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			if (nActive ~= 0) then
				-- Handle start of turn special effects
				if bProcessSpecial then
					local sEffName = DB.getValue(nodeEffect, "label", "");
					local listEffectComp = parseEffect(sEffName);
					for _,rEffectComp in ipairs(listEffectComp) do
						-- Conditionals
						if rEffectComp.type == "IFT" then
							break;
						elseif rEffectComp.type == "IF" then
							local rActor = ActorManager.getActorFromCT(nodeActor);
							if not checkConditional(rActor, nodeEffect, rEffectComp.remainder) then
								break;
							end
						
						-- Ongoing damage, fast healing and regeneration
						elseif rEffectComp.type == "DMGO" or rEffectComp.type == "FHEAL" or rEffectComp.type == "REGEN" then
							if nActive == 2 then
								DB.setValue(nodeEffect, "isactive", "number", 1);
							else
								applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp);
							end
						end
					end
				end

				-- Decrement effect and start of matching initiative, and check for expiration
				local nDuration = DB.getValue(nodeEffect, "duration", 0);
				if (nDuration > 0) then
					local nEffInit = DB.getValue(nodeEffect, "init", 0);
					if nEffInit < nCurrentInit and nEffInit >= nNewInit then
						nDuration = nDuration - 1;
						
						if (nDuration <= 0) then
							expireEffect(nodeActor, nodeEffect, 0);
						else
							DB.setValue(nodeEffect, "duration", "number", nDuration);
						end
					end
				end
			end -- END ACTIVE EFFECT CHECK
		end -- END EFFECT LOOP
		
		-- Determine whether we should process start of turn special effects
		if nodeActor == nodeCurrentActor then
			bProcessSpecial = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecial = false;
		end
	end -- END ACTOR LOOP
end

function evalAbilityHelper(rActor, sEffectAbility)
	-- PARSE EFFECT ABILITY TAG
	local sSign, sModifier, sShortAbility = string.match(sEffectAbility, "^%[([%+%-]?)([H2]?)([A-Z][A-Z][A-Z])%]$");

	-- FIGURE OUT WHICH ABILITY
	local nAbility = nil;
	if sShortAbility == "STR" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "strength");
	elseif sShortAbility == "DEX" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "dexterity");
	elseif sShortAbility == "END" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "endurance");
	elseif sShortAbility == "INT" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "intelligence");
	elseif sShortAbility == "PER" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "perception");
	elseif sShortAbility == "PRS" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "presence");
	elseif sShortAbility == "LVL" then
		nAbility = ActorManager2.getAbilityBonus(rActor, "level");
	end
	
	-- IF VALID SHORT ABILITY, THEN APPLY SIGN AND MODIFIERS
	if nAbility then
		if sSign == "-" then
			nAbility = 0 - nAbility;
		end
		if sModifier == "H" then
			if nAbility > 0 then
				nAbility = math.floor(nAbility / 2);
			else
				nAbility = math.ceil(nAbility / 2);
			end
		elseif sModifier == "2" then
			nAbility = nAbility * 2;
		end
	end
	
	-- RESULTS
	return nAbility;
end

function evalEffect(rActor, s)
	-- VALIDATE
	if not s then
		return "";
	end
	if not rActor then
		return s;
	end
	
	local aEffectComps = EffectManager.parseEffect(s);
	for _,vComp in ipairs(aEffectComps) do
		for i = #(vComp.remainder), 1, -1 do
			if vComp.remainder[i]:match("^%[([%+%-]?)([H2]?)([A-Z][A-Z][A-Z])%]$") then
				local nAbility = evalAbilityHelper(rActor, vComp.remainder[i]);
				if nAbility then
					vComp.mod = vComp.mod + nAbility;
					table.remove(vComp.remainder, i);
				end
			end
		end
	end
	local sOutput = rebuildParsedEffect(aEffectComps);

	return sOutput;
end

function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	
	-- SETUP
	local results = {};
	
	-- SEPARATE FILTERS
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for _,v in pairs(aFilter) do
			if type(v) ~= "string" then
				table.insert(aOtherFilter, v);
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- DETERMINE WHETHER EFFECT COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETING
	local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
	
	-- ITERATE THROUGH EFFECTS
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		-- MAKE SURE EFFECT IS ACTIVE
		local nActive = DB.getValue(v, "isactive", 0);
		if (nActive ~= 0) then
			-- PARSE EFFECT
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");
			local effect_list = EffectManager.parseEffect(sLabel);

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = isTargetedEffect(v);
			if not bTargeted or isEffectTarget(v, rFilterActor) then

			-- LOOK THROUGH EFFECT CLAUSES FOR A TYPE (or TYPE/SUBTYPE) MATCH
				local nMatch = 0;
				for kEffectComp, rEffectComp in ipairs(effect_list) do
					-- CHECK CONDITIONALS
					if rEffectComp.type == "IF" then
						if not checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFT" then
						if not rFilterActor then
							break;
						end
						if not checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						bTargeted = true;
					
					-- COMPARE ON OTHER EFFECT ATTRIBUTES
					else
						-- STRIP OUT ENERGY OR BONUS TYPES FOR SUBTYPE COMPARISON
						local aEffectRangeFilter = {};
						local aEffectOtherFilter = {};
						
						local aComponents = {};
						for _,vPhrase in ipairs(rEffectComp.remainder) do
							local nTempIndexOR = 0;
							local aPhraseOR = {};
							repeat
								local nStartOR, nEndOR = string.find(vPhrase, "%s+or%s+", nTempIndexOR);
								if nStartOR then
									table.insert(aPhraseOR, string.sub(vPhrase, nTempIndexOR, nStartOR - nTempIndexOR));
									nTempIndexOR = nEndOR;
								else
									table.insert(aPhraseOR, string.sub(vPhrase, nTempIndexOR));
								end
							until nStartOR == nil;
							
							for _,vPhraseOR in ipairs(aPhraseOR) do
								local nTempIndexAND = 0;
								repeat
									local nStartAND, nEndAND = string.find(vPhraseOR, "%s+and%s+", nTempIndexAND);
									if nStartAND then
										local sInsert = StringManager.trim(string.sub(vPhraseOR, nTempIndexAND, nStartAND - nTempIndexAND));
										table.insert(aComponents, sInsert);
										nTempIndexAND = nEndAND;
									else
										local sInsert = StringManager.trim(string.sub(vPhraseOR, nTempIndexAND));
										table.insert(aComponents, sInsert);
									end
								until nStartAND == nil;
							end
						end
						local j = 1;
						while aComponents[j] do
							if StringManager.contains(DataCommon.dmgtypes, aComponents[j]) or 
									StringManager.contains(DataCommon.bonustypes, aComponents[j]) or
									aComponents[j] == "all" then
								-- SKIP
							elseif StringManager.contains(DataCommon.rangetypes, aComponents[j]) then
								table.insert(aEffectRangeFilter, aComponents[j]);
							else
								table.insert(aEffectOtherFilter, aComponents[j]);
							end
							
							j = j + 1;
						end
					
						-- CHECK TO MAKE SURE THIS COMPONENT MATCHES THE ONE WE'RE SEARCHING FOR
						local comp_match = false;
						if rEffectComp.type == sEffectType then

							-- CHECK FOR EFFECT CHECKS FOR TARGETS ONLY (EITHER BY EFFECT OR CONDITION)
							if bTargetedOnly and not bTargeted then
								comp_match = false;
							else
								comp_match = true;
							end
						
							-- CHECK THE FILTERS
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false;
								for _,v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true;
										break;
									end
								end
								if not bRangeMatch then
									comp_match = false;
								end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false;
								for _,v2 in pairs(aOtherFilter) do
									if type(v2) == "table" then
										local bOtherTableMatch = true;
										for k3, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false;
												break;
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true;
											break;
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true;
										break;
									end
								end
								if not bOtherMatch then
									comp_match = false;
								end
							end
						end

						-- WE FOUND A MATCH
						if comp_match then
							nMatch = kEffectComp;
							if nActive == 1 then
								table.insert(results, rEffectComp);
							end
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- REMOVE ONE-SHOT EFFECTS
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							if nLocked > 0 then
								table.insert(aUsedActionEffects, v.getNodeName());
							else
								notifyExpire(v, 0);
							end
						elseif sApply == "roll" then
							notifyExpire(v, 0);
						elseif sApply == "single" then
							notifyExpire(v, nMatch);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

function getEffectsBonusByType(rActor, aEffectType, bAddEmptyBonus, aFilter, rFilterActor, bTargetedOnly)
	-- VALIDATE
	if not rActor or not aEffectType then
		return {}, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	
	-- PER EFFECT TYPE VARIABLES
	local results = {};
	local bonuses = {};
	local penalties = {};
	local nEffectCount = 0;
	
	for k, v in pairs(aEffectType) do
		-- LOOK FOR EFFECTS THAT MATCH BONUSTYPE
		local aEffectsByType = getEffectsByType(rActor, v, aFilter, rFilterActor, bTargetedOnly);

		-- ITERATE THROUGH EFFECTS THAT MATCHED
		for k2,v2 in pairs(aEffectsByType) do
			-- LOOK FOR ENERGY OR BONUS TYPES
			local dmg_type = nil;
			local mod_type = nil;
			for _,v3 in pairs(v2.remainder) do
				if StringManager.contains(DataCommon.dmgtypes, v3) or StringManager.contains(DataCommon.immunetypes, v3) or v3 == "all" then
					dmg_type = v3;
					break;
				elseif StringManager.contains(DataCommon.bonustypes, v3) then
					mod_type = v3;
					break;
				end
			end
			
			-- IF MODIFIER TYPE IS UNTYPED, THEN APPEND MODIFIERS
			-- (SUPPORTS DICE)
			if dmg_type or not mod_type then
				-- ADD EFFECT RESULTS 
				local new_key = dmg_type or "";
				local new_results = results[new_key] or {dice = {}, mod = 0, remainder = {}};

				-- BUILD THE NEW RESULT
				for _,v3 in pairs(v2.dice) do
					table.insert(new_results.dice, v3); 
				end
				if bAddEmptyBonus then
					new_results.mod = new_results.mod + v2.mod;
				else
					new_results.mod = math.max(new_results.mod, v2.mod);
				end
				for _,v3 in pairs(v2.remainder) do
					table.insert(new_results.remainder, v3);
				end

				-- SET THE NEW DICE RESULTS BASED ON ENERGY TYPE
				results[new_key] = new_results;

			-- OTHERWISE, TRACK BONUSES AND PENALTIES BY MODIFIER TYPE 
			-- (IGNORE DICE, ONLY TAKE BIGGEST BONUS AND/OR PENALTY FOR EACH MODIFIER TYPE)
			else
				local bStackable = StringManager.contains(DataCommon.stackablebonustypes, mod_type);
				if v2.mod >= 0 then
					if bStackable then
						bonuses[mod_type] = (bonuses[mod_type] or 0) + v2.mod;
					else
						bonuses[mod_type] = math.max(v2.mod, bonuses[mod_type] or 0);
					end
				elseif v2.mod < 0 then
					if bStackable then
						penalties[mod_type] = (penalties[mod_type] or 0) + v2.mod;
					else
						penalties[mod_type] = math.min(v2.mod, penalties[mod_type] or 0);
					end
				end

			end
			
			-- INCREMENT EFFECT COUNT
			nEffectCount = nEffectCount + 1;
		end
	end

	-- COMBINE BONUSES AND PENALTIES FOR NON-ENERGY TYPED MODIFIERS
	for k2,v2 in pairs(bonuses) do
		if results[k2] then
			results[k2].mod = results[k2].mod + v2;
		else
			results[k2] = {dice = {}, mod = v2, remainder = {}};
		end
	end
	for k2,v2 in pairs(penalties) do
		if results[k2] then
			results[k2].mod = results[k2].mod + v2;
		else
			results[k2] = {dice = {}, mod = v2, remainder = {}};
		end
	end

	-- RESULTS
	return results, nEffectCount;
end

function getEffectsBonus(rActor, aEffectType, bModOnly, aFilter, rFilterActor, bTargetedOnly)
	-- VALIDATE
	if not rActor or not aEffectType then
		if bModOnly then
			return 0, 0;
		end
		return {}, 0, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	
	-- START WITH AN EMPTY MODIFIER TOTAL
	local aTotalDice = {};
	local nTotalMod = 0;
	local nEffectCount = 0;
	
	-- ITERATE THROUGH EACH BONUS TYPE
	local masterbonuses = {};
	local masterpenalties = {};
	for k, v in pairs(aEffectType) do
		-- GET THE MODIFIERS FOR THIS MODIFIER TYPE
		local effbonusbytype, nEffectSubCount = getEffectsBonusByType(rActor, v, true, aFilter, rFilterActor, bTargetedOnly);
		
		-- ITERATE THROUGH THE MODIFIERS
		for k2, v2 in pairs(effbonusbytype) do
			-- IF MODIFIER TYPE IS UNTYPED, THEN APPEND TO TOTAL MODIFIER
			-- (SUPPORTS DICE)
			if k2 == "" or StringManager.contains(DataCommon.dmgtypes, k2) then
				for k3, v3 in pairs(v2.dice) do
					table.insert(aTotalDice, v3);
				end
				nTotalMod = nTotalMod + v2.mod;
			
			-- OTHERWISE, WE HAVE A NON-ENERGY MODIFIER TYPE, WHICH MEANS WE NEED TO INTEGRATE
			-- (IGNORE DICE, ONLY TAKE BIGGEST BONUS AND/OR PENALTY FOR EACH MODIFIER TYPE)
			else
				if v2.mod >= 0 then
					masterbonuses[k2] = math.max(v2.mod, masterbonuses[k2] or 0);
				elseif v2.mod < 0 then
					masterpenalties[k2] = math.min(v2.mod, masterpenalties[k2] or 0);
				end
			end
		end

		-- ADD TO EFFECT COUNT
		nEffectCount = nEffectCount + nEffectSubCount;
	end

	-- ADD INTEGRATED BONUSES AND PENALTIES FOR NON-ENERGY TYPED MODIFIERS
	for k,v in pairs(masterbonuses) do
		nTotalMod = nTotalMod + v;
	end
	for k,v in pairs(masterpenalties) do
		nTotalMod = nTotalMod + v;
	end
	
	-- RESULTS
	if bModOnly then
		return nTotalMod, nEffectCount;
	end
	return aTotalDice, nTotalMod, nEffectCount;
end

function isEffectTarget(nodeEffect, rTarget)
	local bMatch = false;
	
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sTargetCT ~= "" then
		for _,v in pairs(DB.getChildren(nodeEffect, "targets")) do
			if DB.getValue(v, "noderef", "") == sTargetCT then
				bMatch = true;
				break;
			end
		end
	end

	return bMatch;
end

function hasEffectCondition(rActor, sEffect)
	return hasEffect(rActor, sEffect, nil, false, true);
end

function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	-- Parameter validation
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = string.lower(sEffect);
	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local effect_list = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, rEffectComp in ipairs(effect_list) do
				-- CHECK CONDITIONALS
				if rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
				
				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif string.lower(rEffectComp.original) == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
				
			end
			
			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						if nLocked > 0 then
							table.insert(aUsedActionEffects, v.getNodeName());
						else
							notifyExpire(v, 0);
						end
					elseif sApply == "roll" then
						notifyExpire(v, 0);
					elseif sApply == "single" then
						notifyExpire(v, nMatch);
					end
				end
			end
		end
	end
	
	-- Return results
	if #aMatch > 0 then
		return true;
	end
	return false;
end

function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
	local bReturn = true;
	
	if not aIgnore then
		aIgnore = {};
	end
	table.insert(aIgnore, nodeEffect.getNodeName());
	
	for _,v in ipairs(aConditions) do
		local sLower = v:lower();
		if sLower == DataCommon.healthstatushalf then
			local nPercentWounded = ActorManager2.getPercentWounded("ct", ActorManager.getCTNode(rActor));
			if nPercentWounded < .5 then
				bReturn = false;
			end
		elseif sLower == DataCommon.healthstatuswounded then
			local nPercentWounded = ActorManager2.getPercentWounded("ct", ActorManager.getCTNode(rActor));
			if nPercentWounded == 0 then
				bReturn = false;
			end
		elseif StringManager.contains(DataCommon.conditions, sLower) then
			if not checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
			end
		elseif StringManager.contains(DataCommon.conditionaltags, sLower) then
			if not checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
			end
		else
			local sAlignCheck = sLower:match("^align%s*%(([^)]+)%)$");
			local sSizeCheck = sLower:match("^size%s*%(([^)]+)%)$");
			local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
			local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
			if sAlignCheck then
				if not ActorManager2.isAlignment(rActor, sAlignCheck) then
					bReturn = false;
				end
			elseif sSizeCheck then
				if not ActorManager2.isSize(rActor, sSizeCheck) then
					bReturn = false;
				end
			elseif sTypeCheck then
				if not ActorManager2.isCreatureType(rActor, sTypeCheck) then
					bReturn = false;
				end
			elseif sCustomCheck then
				if not EffectManager.hasEffectCondition(rActor, sCustomCheck) then
					bReturn = false;
				end
			end
		end
	end
	
	table.remove(aIgnore);
	
	return bReturn;
end

function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end
	
	local bReturn = false;
	
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 and not StringManager.contains(aIgnore, v.getNodeName()) then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, rEffectComp in ipairs(aEffectComps) do
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				
				-- CHECK CONDITIONALS
				elseif rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end
				
				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif string.lower(rEffectComp.original) == sEffect then
					if bTargeted then
						if isEffectTarget(v, rTarget) then
							bReturn = true;
						end
					else
						bReturn = true;
					end
				end
			end
		end
	end
	
	return bReturn;
end

--
--  HANDLE EFFECT LOCKING
--

function lock()
	nLocked = nLocked + 1;
end

function unlock()
	nLocked = nLocked - 1;
	if nLocked < 0 then
		nLocked = 0;
	end

	if nLocked == 0 then
		local aExpired = {};
		
		for _,v in ipairs(aUsedActionEffects) do
			if not aExpired[v] then
				notifyExpire(v, 0);
				aExpired[v] = true;
			end
		end
	
		aUsedActionEffects = {};
	end
end

--
-- EFFECT TARGETING
--

function addEffectTarget(vEffect, sTargetNode)
	local nodeTargetList = nil;
	if type(vEffect) == "string" then
		nodeTargetList = DB.createChild(DB.findNode(vEffect), "targets");
	elseif type(vEffect) == "databasenode" then
		nodeTargetList = DB.createChild(vEffect, "targets");
	end
	if not nodeTargetList then
		return;
	end
	
	for _,nodeTarget in pairs(nodeTargetList.getChildren()) do
		if (DB.getValue(nodeTarget, "noderef", "") == sTargetNode) then
			return;
		end
	end

	local nodeNewTarget = nodeTargetList.createChild();
	if nodeNewTarget then
		DB.setValue(nodeNewTarget, "noderef", "string", sTargetNode);
	end
end

function setEffectFactionTargets(nodeEffect, sFaction, bNegated)
	if not nodeEffect then
		return;
	end
	
	clearEffectTargets(nodeEffect);
	
	for _,nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		if bNegated then
			if DB.getValue(nodeCT, "friendfoe", "") ~= sFaction then
				addEffectTarget(nodeEffect, nodeCT.getNodeName());
			end
		else
			if DB.getValue(nodeCT, "friendfoe", "") == sFaction then
				addEffectTarget(nodeEffect, nodeCT.getNodeName());
			end
		end
	end
end

function clearEffectTargets(nodeEffect)
	for _,nodeTarget in pairs(DB.getChildren(nodeEffect, "targets")) do
		nodeTarget.delete();
	end
end
