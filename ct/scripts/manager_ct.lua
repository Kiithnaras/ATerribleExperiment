-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sActiveCT = "";
OOB_MSGTYPE_ENDTURN = "endturn";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ENDTURN, handleEndTurn);
end

--
-- TURN FUNCTIONS
--

function handleEndTurn(msgOOB)
	local rActor = ActorManager.getActor("ct", getActiveCT());
	if rActor and rActor.sType == "pc" and rActor.nodeCreature then
		if rActor.nodeCreature.getOwner() == msgOOB.user then
			nextActor();
		end
	end
end

function notifyEndTurn()
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_ENDTURN;
	msgOOB.user = User.getUsername();

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Lua sort function expects the opposite boolean value compared to built-in FG sorting
function sortfunc(node1, node2)
	local nValue1 = DB.getValue(node1, "initresult", 0);
	local nValue2 = DB.getValue(node2, "initresult", 0);
	if nValue1 ~= nValue2 then
		return nValue1 > nValue2;
	end
	
	nValue1 = DB.getValue(node1, "init", 0);
	nValue2 = DB.getValue(node2, "init", 0);
	if nValue1 ~= nValue2 then
		return nValue1 > nValue2;
	end
	
	local sValue1 = DB.getValue(node1, "name", "");
	local sValue2 = DB.getValue(node2, "name", "");
	if sValue1 ~= sValue2 then
		return sValue1 < sValue2;
	end

	return node1.getNodeName() < node2.getNodeName();
end

function requestActivation(nodeEntry, bSkipBell)
	-- De-activate all other entries
	for _, vChild in pairs(DB.getChildren("combattracker")) do
		DB.setValue(vChild, "active", "number", 0);
	end
	
	-- Set active flag
	DB.setValue(nodeEntry, "active", "number", 1);

	-- Handle beginning of turn changes
	DB.setValue(nodeEntry, "immediate", "number", 0);
	
	-- Get key information
	local sType = DB.getValue(nodeEntry, "type", "");
	local sName = DB.getValue(nodeEntry, "name", "");
	
	-- Handle turn notification
	local msg = {font = "narratorfont", icon = "indicator_flag"};
	msg.text = "[TURN] " .. sName;
	if OptionsManager.isOption("RSHE", "on") then
		local sEffects = EffectsManager.getEffectsString(nodeEntry, true);
		if sEffects ~= "" then
			msg.text = msg.text .. " - [" .. sEffects .. "]";
		end
	end
	if sType == "pc" then
		Comm.deliverChatMessage(msg);
		
		if not bSkipBell and OptionsManager.isOption("RING", "on") then
			local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
			if sRecord ~= "" then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					local sOwner = nodePC.getOwner();
					if sOwner then
						User.ringBell(sOwner);
					end
				end
			end
		end
	else
		if (DB.getValue(nodeEntry, "friendfoe", "") == "friend") or (DB.getValue(nodeEntry, "show_npc", 0) == 1) then
			Comm.deliverChatMessage(msg);
		else
			msg.text = "[GM] " .. msg.text;
			Comm.addChatMessage(msg);
		end
	end

	-- Handle GM identity updates (based on option)
	if sActiveCT ~= "" then
		GmIdentityManager.removeIdentity(sActiveCT);
		sActiveCT = "";
	end
	if OptionsManager.isOption("CTAV", "on") then
		if sType == "pc" or sName == "" then
			GmIdentityManager.activateGMIdentity();
		else
			if GmIdentityManager.existsIdentity(sName) then
				GmIdentityManager.setCurrent(sName);
			else
				sActiveCT = sName;
				GmIdentityManager.addIdentity(sName);
			end
		end
	end
end

function nextActor(bSkipBell)
	local nodeActive = getActiveCT();
	
	-- Check for stabilization
	local sOptionHRST = OptionsManager.getOption("HRST");
	if sOptionHRST ~= "off" then
		if nodeActive then
			if (sOptionHRST == "all") or (DB.getValue(nodeActive, "friendfoe", "") == "friend") then
				local nHP = DB.getValue(nodeActive, "hp", 0);
				local nWounds = DB.getValue(nodeActive, "wounds", 0);
				local nDying = GameSystemManager.getDeathThreshold(rActor);
				if nHP > 0 and nWounds > nHP and nWounds < nHP + nDying then
					local rActor = ActorManager.getActor("ct", nodeActive);
					if not EffectsManager.hasEffect(rActor, "Stable") then
						ActionDamage.performStabilizationRoll(rActor);
					end
				end
			end
		end
	end
	
	-- Determine the next actor
	local nodeNext = nil;
	local nodeTracker = DB.findNode("combattracker");
	if nodeTracker then
		local aEntries = {};
		for _,vChild in pairs(nodeTracker.getChildren()) do
			table.insert(aEntries, vChild);
		end
		
		if #aEntries > 0 then
			table.sort(aEntries, sortfunc);
		
			if nodeActive then
				for i = 1,#aEntries do
					if aEntries[i] == nodeActive then
						nodeNext = aEntries[i+1];
					end
				end
			else
				nodeNext = aEntries[1];
			end
		end
	end

	-- LOOK FOR ACTIVE NODE
	-- Find the next actor.  If no next actor, then start the next round
	if nodeNext then
		if nodeActive then
			EffectsManager.processEffects(nodeTracker, nodeActive, nodeNext);
		else
			EffectsManager.processEffects(nodeTracker, nil, nodeNext);
		end
		requestActivation(nodeNext, bSkipBell);
	else
		nextRound(1);
	end
end

function nextRound(nRounds)
	local nodeTracker = DB.findNode("combattracker");
	local nodeActive = getActiveCT();

	-- IF ACTIVE ACTOR, THEN PROCESS EFFECTS
	local nStartCounter = 1;
	if nodeActive then
		EffectsManager.processEffects(nodeTracker, nodeActive);
		DB.setValue(nodeActive, "active", "number", 0);
		if sActiveCT ~= "" then
			GmIdentityManager.removeIdentity(sActiveCT);
			sActiveCT = "";
		end
		nStartCounter = nStartCounter + 1;
	end
	for i = nStartCounter, nRounds do
		EffectsManager.processEffects(nodeTracker, nil, nil);
	end

	-- ADVANCE ROUND COUNTER
	local nCurrent = 0;
	local nodeRound = DB.findNode("combattracker_props.round");
	if nodeRound then
		nCurrent = nodeRound.getValue() + nRounds;
		nodeRound.setValue(nCurrent);
	end
	
	-- ANNOUNCE NEW ROUND
	local msg = {font = "narratorfont", icon = "indicator_flag"};
	msg.text = "[ROUND " .. nCurrent .. "]";
	Comm.deliverChatMessage(msg);
	
	-- CHECK OPTION TO SEE IF WE SHOULD GO AHEAD AND MOVE TO FIRST ROUND
	if OptionsManager.isOption("RNDS", "off") then
		local bSkipBell = (nRounds > 1);
		if nodeTracker.getChildCount() > 0 then
			nextActor(bSkipBell);
		end
	end
end

--
--	GENERAL
--

function getActiveInit()
	local nActiveInit = nil;
	
	local nodeActive = getActiveCT();
	if nodeActive then
		nActiveInit = DB.getValue(nodeActive, "initresult", 0);
	end
	
	return nActiveInit;
end

function getActiveCT()
	for _,v in pairs(DB.getChildren("combattracker")) do
		if DB.getValue(v, "active", 0) == 1 then
			return v;
		end
	end
	return nil;
end

function getCTFromNode(varNode)
	-- SETUP
	local sNode = "";
	if type(varNode) == "string" then
		sNode = varNode;
	elseif type(varNode) == "databasenode" then
		sNode = varNode.getNodeName();
	else
		return nil;
	end
	
	-- FIND TRACKER NODE
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return nil;
	end

	-- Check for exact CT match
	for _,v in pairs(nodeTracker.getChildren()) do
		if v.getNodeName() == sNode then
			return v;
		end
	end

	-- Otherwise, check for link match
	for _,v in pairs(nodeTracker.getChildren()) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sNode then
			return v;
		end
	end

	return nil;	
end

function getCTFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	local sContainerNode = nodeContainer.getNodeName();

	for _,v in pairs(DB.getChildren("combattracker")) do
		local sCTContainerName = DB.getValue(v, "tokenrefnode", "");
		local nCTId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sCTContainerName == sContainerNode) and (nCTId == nId) then
			return v;
		end
	end
	return nil;
end

function getCTFromToken(token)
	-- GET TOKEN CONTAINER AND ID
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getCTFromTokenRef(nodeContainer, nID);
end


--
-- DROP HANDLING
--

function onDrop(nodetype, nodename, draginfo)
	local rSource, rTarget = ActorManager.getDropActors(nodetype, nodename, draginfo);
	if rTarget then
		local sDragType = draginfo.getType();

		-- Faction changes
		if sDragType == "combattrackerff" then
			if User.isHost() then
				DB.setValue(rTarget.nodeCT, "friendfoe", "string", draginfo.getStringData());
				return true;
			end

		-- Targeting
		elseif sDragType == "targeting" then
			if User.isHost() then
				onTargetingDrop(rSource, rTarget, draginfo);
				return true;
			end

		-- Actions
		elseif StringManager.contains(DataCommon.targetactions, sDragType) then
			ActionsManager.handleActionDrop(draginfo, rTarget);
			return true;

		-- Potential actions
		elseif sDragType == "number" then
			onNumberDrop(rSource, rTarget, draginfo);
			return true;
		end
	end
end

function onTargetingDrop(rSource, rTarget, draginfo)
	if rTarget.nodeCT then
		-- ADD CREATURE TARGET
		if rSource then
			if rSource.nodeCT then
				TargetingManager.addTarget("host", rSource.sCTNode, rTarget.sCTNode);
			end

		-- ADD EFFECT TARGET
		else
			local sRefClass, sRefNode = draginfo.getShortcutData();
			if sRefClass and sRefNode then
				if sRefClass == "combattracker_effect" then
					TargetingManager.addTarget("host", sRefNode, rTarget.sCTNode);
				end
			end
		end
	end
end

function onNumberDrop(rSource, rTarget, draginfo)
	-- CHECK FOR ACTION RESULTS
	local sType = nil;
	local sDescription = draginfo.getDescription();
	if sDescription:match("%[ATTACK") then
		sType = "attack";
	elseif sDescription:match("%[GRAPPLE") then
		sType = "grapple";
	elseif sDescription:match("%[CMB") then
		sType = "grapple";
	elseif sDescription:match("%[DAMAGE") then
		sType = "damage";
	elseif sDescription:match("%[HEAL") then
		sType = "heal";
	elseif sDescription:match("%[EFFECT") then
		sType = "effect";
	elseif sDescription:match("%[CL CHECK") then
		sType = "clc";
	elseif sDescription:match("%[SAVE VS") then
		sType = "spellsave";
	end
	
	-- IF ACTION, THEN RESOLVE IT AGAINST THIS TARGET
	if sType then
		local rRoll = {};
		rRoll.sType = sType;
		rRoll.sDesc = sDescription;
		rRoll.aDice = {};
		rRoll.nMod = draginfo.getNumberData();
		
		if sType == "damage" then
			rRoll.sDesc = rRoll.sDesc .. " [MIN OVERRIDE]";
		end
		
		ActionsManager.resolveAction(rSource, rTarget, rRoll);
	end
end

--
-- PARSE CT ATTACK LINE
--

function parseAttackLine(rActor, sLine)
	-- SETUP
	local rAttackRolls = {};
	local rDamageRolls = {};
	local rAttackCombos = {};

	-- Check the anonymous NPC attacks option
	local sOptANPC = OptionsManager.getOption("ANPC");

	-- PARSE 'OR'/'AND' PHRASES
	sLine = sLine:gsub("–", "-");
	local aPhrasesOR, aSkipOR = ActionDamage.decodeAndOrClauses(sLine);

	-- PARSE EACH ATTACK
	local nAttackIndex = 1;
	local nLineIndex = 1;
	local aCurrentCombo = {};
	local nStarts, nEnds, sAll, sAttackCount, sAttackLabel, sAttackModifier, sAttackType, nDamageStart, sDamage, nDamageEnd;
	for kOR, vOR in ipairs(aPhrasesOR) do
			
		for kAND, sAND in ipairs(vOR) do

			-- Look for the right patterns
			nStarts, nEnds, sAll, sAttackCount, sAttackLabel, sAttackModifier, sAttackType, nDamageStart, sDamage, nDamageEnd 
					= string.find(sAND, '((%+?%d*) ?([%w%s,%[%]%(%)%+%-]*) ([%+%-%d][%+%-%d/]+)([^%(]*)%(()([^%)]*)()%))');
			
			-- Make sure we got a match
			if nStarts then
				local rAttack = {};
				rAttack.startpos = nLineIndex + nStarts - 1;
				rAttack.endpos = nLineIndex + nEnds;
				
				local rDamage = {};
				rDamage.startpos = nLineIndex + nDamageStart - 1;
				rDamage.endpos = nLineIndex + nDamageEnd - 1;
				
				-- Check for implicit damage types
				local aImplicitDamageType = {};
				local aLabelWords = StringManager.parseWords(sAttackLabel:lower());
				local i = 1;
				while aLabelWords[i] do
					if aLabelWords[i] == "touch" then
						rAttack.touch = true;
					elseif aLabelWords[i] == "sonic" or aLabelWords[i] == "electricity" then
						table.insert(aImplicitDamageType, aLabelWords[i]);
						break;
					elseif aLabelWords[i] == "adamantine" or aLabelWords[i] == "silver" then
						table.insert(aImplicitDamageType, aLabelWords[i]);
					elseif aLabelWords[i] == "cold" and aLabelWords[i+1] and aLabelWords[i+1] == "iron" then
						table.insert(aImplicitDamageType, "cold iron");
						i = i + 1;
					elseif aLabelWords[i] == "holy" then
						table.insert(aImplicitDamageType, "good");
					elseif aLabelWords[i] == "unholy" then
						table.insert(aImplicitDamageType, "evil");
					elseif aLabelWords[i] == "anarchic" then
						table.insert(aImplicitDamageType, "chaotic");
					elseif aLabelWords[i] == "axiomatic" then
						table.insert(aImplicitDamageType, "lawful");
					else
						if aLabelWords[i]:sub(-1) == "s" then
							aLabelWords[i] = aLabelWords[i]:sub(1, -2);
						end
						if DataCommon.naturaldmgtypes[aLabelWords[i]] then
							table.insert(aImplicitDamageType, DataCommon.naturaldmgtypes[aLabelWords[i]]);
						elseif DataCommon.weapondmgtypes[aLabelWords[i]] then
							table.insert(aImplicitDamageType, DataCommon.weapondmgtypes[aLabelWords[i]]);
						end
					end
					
					i = i + 1;
				end
				
				-- Clean up the attack count field (i.e. magical weapon bonuses up front, no attack count)
				local bMagicAttack = false;
				local bEpicAttack = false;
				local nAttackCount = 1;
				if string.sub(sAttackCount, 1, 1) == "+" then
					bMagicAttack = true;
					if sOptANPC ~= "on" then
						sAttackLabel = sAttackCount .. " " .. sAttackLabel;
					end
					local nAttackPlus = tonumber(sAttackCount) or 1;
					if nAttackPlus > 5 then
						bEpicAttack = true;
					end
				elseif #sAttackCount then
					nAttackCount = tonumber(sAttackCount) or 1;
					if nAttackCount < 1 then
						nAttackCount = 1;
					end
				end

				-- Capitalize first letter of label
				sAttackLabel = StringManager.capitalize(sAttackLabel);
				
				-- If the anonymize option is on, then remove any label text within parentheses or brackets
				if sOptANPC == "on" then
					-- Strip out label information enclosed in ()
					sAttackLabel = string.gsub(sAttackLabel, "%s?%b()", "");

					-- Strip out label information enclosed in []
					sAttackLabel = string.gsub(sAttackLabel, "%s?%b[]", "");
				end

				rAttack.label = sAttackLabel;
				rAttack.count = nAttackCount;
				rAttack.modifier = sAttackModifier;
				
				rDamage.label = sAttackLabel;
				
				local bRanged = false;
				local aTypeWords = StringManager.parseWords(string.lower(sAttackType));
				for kWord, vWord in pairs(aTypeWords) do
					if vWord == "ranged" then
						bRanged = true;
					elseif vWord == "touch" then
						rAttack.touch = true;
					end
				end
				
				-- Determine attack type
				if bRanged then
					rAttack.range = "R";
					rDamage.range = "R";
					rAttack.stat = "dexterity";
					rDamage.stat = "strength";
					rDamage.statmult = 0;
				else
					rAttack.range = "M";
					rDamage.range = "M";
					rAttack.stat = "strength";
					rDamage.stat = "strength";
					rDamage.statmult = 1;
				end

				-- Determine critical information
				rAttack.crit = 20;
				nCritStart, nCritEnd, sCritThreshold = string.find(sDamage, "/(%d+)%-20");
				if sCritThreshold then
					rAttack.crit = tonumber(sCritThreshold) or 20;
					if rAttack.crit < 2 or rAttack.crit > 20 then
						rAttack.crit = 20;
					end
				end
				
				-- Determine damage clauses
				rDamage.clauses = {};

				local aClausesDamage = {};
				local nIndexDamage = 1;
				local nStartDamage, nEndDamage;
				while nIndexDamage < #sDamage do
					nStartDamage, nEndDamage = string.find(sDamage, ' plus ', nIndexDamage);
					if nStartDamage then
						table.insert(aClausesDamage, string.sub(sDamage, nIndexDamage, nStartDamage - 1));
						nIndexDamage = nEndDamage;
					else
						table.insert(aClausesDamage, string.sub(sDamage, nIndexDamage));
						nIndexDamage = #sDamage;
					end
				end

				for kClause, sClause in pairs(aClausesDamage) do
					local aDamageAttrib = StringManager.split(sClause, "/", true);
					
					local aWordType = {};
					local sDamageRoll, sDamageTypes = string.match(aDamageAttrib[1], "^([d%d%+%-%s]+)([%w%s,]*)");
					if sDamageRoll then
						if sDamageTypes then
							if string.match(sDamageTypes, " and ") then
								sDamageTypes = string.gsub(sDamageTypes, " and .*$", "");
							end
							table.insert(aWordType, sDamageTypes);
						end
						
						local sCrit;
						for nAttrib = 2, #aDamageAttrib do
							sCrit, sDamageTypes = string.match(aDamageAttrib[nAttrib], "^x(%d)([%w%s,]*)");
							if not sCrit then
								sDamageTypes = string.match(aDamageAttrib[nAttrib], "^%d+%-20%s?([%w%s,]*)");
							end
							
							if sDamageTypes then
								table.insert(aWordType, sDamageTypes);
							end
						end
						
						local aWordDice, nWordMod = StringManager.convertStringToDice(sDamageRoll);
						if #aWordDice > 0 or nWordMod ~= 0 then
							local rDamageClause = { dice = {} };
							for kDie, vDie in ipairs(aWordDice) do
								table.insert(rDamageClause.dice, vDie);
							end
							rDamageClause.modifier = nWordMod;

							if kClause == 1 then
								rDamageClause.mult = 2;
							else
								rDamageClause.mult = 1;
							end
							rDamageClause.mult = tonumber(sCrit) or rDamageClause.mult;

							local aDamageType = ActionDamage.getDamageTypesFromString(table.concat(aWordType, ","));
							if #aDamageType == 0 then
								for kType, sType in ipairs(aImplicitDamageType) do
									table.insert(aDamageType, sType);
								end
							end
							if bMagicAttack then
								table.insert(aDamageType, "magic");
							end
							if bEpicAttack then
								table.insert(aDamageType, "epic");
							end
							rDamageClause.dmgtype = table.concat(aDamageType, ",");
							
							table.insert(rDamage.clauses, rDamageClause);
						end
					end
				end
				
				if #(rDamage.clauses) > 0 then
					if bRanged then
						local nDmgBonus = rDamage.clauses[1].modifier;
						if nDmgBonus > 0 then
							local nStatBonus = ActorManager.getAbilityBonus(rActor, "strength");
							if (nDmgBonus >= nStatBonus) then
								rDamage.statmult = 1;
							end
						end
					else
						local nDmgBonus = rDamage.clauses[1].modifier;
						local nStatBonus = ActorManager.getAbilityBonus(rActor, "strength");
						
						if (nStatBonus > 0) and (nDmgBonus > 0) then
							if nDmgBonus >= math.floor(nStatBonus * 1.5) then
								rDamage.statmult = 1.5;
							elseif nDmgBonus >= nStatBonus then
								rDamage.statmult = 1;
							else
								rDamage.statmult = 0.5;
							end
						elseif (nStatBonus == 1) and (nDmgBonus == 0) then
							rDamage.statmult = 0.5;
						end
					end
				end

				-- Add to roll list
				table.insert(rAttackRolls, rAttack);
				table.insert(rDamageRolls, rDamage);

				-- Add to combo
				table.insert(aCurrentCombo, nAttackIndex);
				nAttackIndex = nAttackIndex + 1;
			end

			nLineIndex = nLineIndex + #sAND;
			nLineIndex = nLineIndex + aSkipOR[kOR][kAND];
		end

		-- Finish combination
		if #aCurrentCombo > 0 then
			table.insert(rAttackCombos, aCurrentCombo);
			aCurrentCombo = {};
		end
	end
	
	return rAttackRolls, rDamageRolls, rAttackCombos;
end

--
-- RESET FUNCTIONS
--

function resetInit()
	-- De-activate all entries
	for _, vChild in pairs(DB.getChildren("combattracker")) do
		DB.setValue(vChild, "active", "number", 0);
		DB.setValue(vChild, "initresult", "number", 0);
		DB.setValue(vChild, "immediate", "number", 0);
	end
	
	-- Clear GM identity additions (based on option)
	if sActiveCT ~= "" then
		GmIdentityManager.removeIdentity(sActiveCT);
		sActiveCT = "";
	end

	-- Reset the round counter
	DB.setValue("combattracker_props.round", "number", 1);
end

function resetEffects()
	for _, vChild in pairs(DB.getChildren("combattracker")) do
		local nodeEffects = vChild.getChild("effects");
		if nodeEffects then
			for _, vEffect in pairs(nodeEffects.getChildren()) do
				vEffect.delete();
			end
			nodeEffects.createChild();
		end
	end
end

function clearExpiringEffects(bShort)
	for _, vChild in pairs(DB.getChildren("combattracker")) do
		local nodeEffects = vChild.getChild("effects");
		if nodeEffects then
			for _, vEffect in pairs(nodeEffects.getChildren()) do
				local sLabel = DB.getValue(vEffect, "label", "");
				local nDuration = DB.getValue(vEffect, "duration", 0);
				local sApply = DB.getValue(vEffect, "apply", "");
				
				if nDuration ~= 0 or sApply ~= "" or sLabel == "" then
					if bShort then
						if nDuration > 50 then
							DB.setValue(vEffect, "duration", "number", nDuration - 50);
						else
							vEffect.delete();
						end
					else
						vEffect.delete();
					end
				end
			end
			
			if nodeEffects.getChildCount() == 0 then
				nodeEffects.createChild();
			end
		end
	end
end

function rest(bShort)
	resetInit();
	clearExpiringEffects(bShort);
	
	if not bShort then
		for _, vChild in pairs(DB.getChildren("combattracker")) do
			if DB.getValue(vChild, "type", "") == "pc" then
				local sClass, sRecord = DB.getValue(vChild, "link", "", "");
				if sRecord ~= "" then
					local nodePC = DB.findNode(sRecord);
					if nodePC then
						CharManager.rest(nodePC);
					end
				end
			end
		end
	end
end

function stripCreatureNumber(s)
	local nStarts, _, sNumber = string.find(s, " ?(%d+)$");
	if nStarts then
		return string.sub(s, 1, nStarts - 1), sNumber;
	end
	return s;
end

function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	
	-- Get any effect modifiers
	local rActor = ActorManager.getActor("ct", nodeEntry);
	local aEffectDice, nEffectBonus = EffectsManager.getEffectsBonus(rActor, "INIT");
	nInit = nInit + StringManager.evalDice(aEffectDice, nEffectBonus);
	
	-- For PCs, we always roll unique initiative
	if DB.getValue(nodeEntry, "type", "") == "pc" then
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
	
	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT ~= "group" then
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end

	-- For NPCs with group option enabled
	
	-- Get the entry's database node name and creature name
	local sStripName = stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
	if sStripName == "" then
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
		
	-- Iterate through list looking for other creature's with same name
	local nLastInit = nil;
	for _, vChild in pairs(DB.getChildren("combattracker")) do
		if vChild.getName() ~= nodeEntry.getName() then
			local sTemp = stripCreatureNumber(DB.getValue(vChild, "name", ""));
			if sTemp == sStripName then
				local nChildInit = DB.getValue(vChild, "initresult", 0);
				if nChildInit ~= -10000 then
					nLastInit = nChildInit;
				end
			end
		end
	end
	
	-- If we found similar creatures, then match the initiative of the last one found
	if nLastInit then
		DB.setValue(nodeEntry, "initresult", "number", nLastInit);
	else
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
	end
end

function rollInit(sType)
	local nodeTracker = DB.findNode("combattracker");
	if nodeTracker then
		for _, vChild in pairs(nodeTracker.getChildren()) do
			if not sType or DB.getValue(vChild, "type", "") == sType then
				DB.setValue(vChild, "initresult", "number", -10000);
			end
		end

		for _, vChild in pairs(nodeTracker.getChildren()) do
			if not sType or DB.getValue(vChild, "type", "") == sType then
				rollEntryInit(vChild);
			end
		end
	end
end

--
-- ADD FUNCTIONS
--

function addPc(nodePC)
	-- Parameter validation
	if not nodePC then
		return;
	end

	-- Create a new combat tracker window
	local nodeTracker = DB.createNode("combattracker");
	if not nodeTracker then
		return;
	end
	local nodeEntry = nodeTracker.createChild();
	if not nodeEntry then
		return;
	end
	
	-- Set link and type to get linked fields to prepopulate
	DB.setValue(nodeEntry, "link", "windowreference", "charsheet", nodePC.getNodeName());
	DB.setValue(nodeEntry, "type", "string", "pc");

	-- Set remaining CT specific fields
	DB.setValue(nodeEntry, "token", "token", DB.getValue(nodePC, "combattoken", nil));
	DB.setValue(nodeEntry, "friendfoe", "string", "friend");
	
	-- Rebuild the targeting information, since we have a new PC
	TargetingManager.rebuildClientTargeting();
end

function linkToken(nodeEntry, newTokenInstance)
	local nodeContainer = nil;
	if newTokenInstance then
		nodeContainer = newTokenInstance.getContainerNode();
	end
	
	if nodeContainer then
		DB.setValue(nodeEntry, "tokenrefnode", "string", nodeContainer.getNodeName());
		DB.setValue(nodeEntry, "tokenrefid", "string", newTokenInstance.getId());
		DB.setValue(nodeEntry, "tokenscale", "number", newTokenInstance.getScale());
	else
		DB.setValue(nodeEntry, "tokenrefnode", "string", "");
		DB.setValue(nodeEntry, "tokenrefid", "string", "");
		DB.setValue(nodeEntry, "tokenscale", "number", 1);
	end

	return true;
end

function addBattle(nodeBattle)
	-- Cycle through the NPC list, and add them to the tracker
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, "npclist")) do
		-- Get link database node
		local nodeNPC = nil;
		local _, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			nodeNPC = DB.findNode(sRecord);
		end
		local sName = DB.getValue(vNPCItem, "name", "");
		
		if nodeNPC then
			local aPlacement = {};
			for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
				local rPlacement = {};
				local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
				rPlacement.imagelink = sRecord;
				rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
				rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
				table.insert(aPlacement, rPlacement);
			end
			
			local nCount = DB.getValue(vNPCItem, "count", 0);
			for i = 1, nCount do
				local nodeEntry = addNpc(nodeNPC, sName);
				if nodeEntry then
					local sToken = DB.getValue(vNPCItem, "token", "");
					if sToken ~= "" then
						DB.setValue(nodeEntry, "token", "token", sToken);
						
						if aPlacement[i] and aPlacement[i].imagelink ~= "" then
							local tokenAdded = Token.addToken(aPlacement[i].imagelink, sToken, aPlacement[i].imagex, aPlacement[i].imagey);
							if tokenAdded then
								linkToken(nodeEntry, tokenAdded);
							end
						end
					end
				else
					ChatManager.SystemMessage("[ERROR] Unable to add '" .. sName .. "' to CT. NPC creation failed.");
				end
			end
		else
			ChatManager.SystemMessage("[ERROR] Unable to add '" .. sName .. "' to CT. Missing data record. Check your modules.");
		end
	end
end

function randomName(sBaseName)
	local nodeTracker = DB.createNode("combattracker");
	if not nodeTracker then
		return sBaseName;
	end
	
	local aNames = {};
	for _, v in pairs(nodeTracker.getChildren()) do
		local sName = DB.getValue(v, "name", "");
		if sName ~= "" then
			table.insert(aNames, DB.getValue(v, "name", ""));
		end
	end
	
	local nRandomRange = nodeTracker.getChildCount() * 2;
	local sNewName = sBaseName;
	local bContinue = true;
	while bContinue do
		bContinue = false;
		sNewName = sBaseName .. " " .. math.random(nRandomRange);
		if StringManager.contains(aNames, sNewName) then
			bContinue = true;
		end
	end

	return sNewName;
end

function addNpc(nodeNPC, sName)
	-- Parameter validation
	if not nodeNPC then
		return nil;
	end

	-- Determine the options relevant to adding NPCs
	local sOptNNPC = OptionsManager.getOption("NNPC");
	local sOptHRNH = OptionsManager.getOption("HRNH");
	local sOptINIT = OptionsManager.getOption("INIT");

	-- Create a new combat tracker window
	local nodeTracker = DB.createNode("combattracker");
	if not nodeTracker then
		return nil;
	end
	local nodeEntry = nodeTracker.createChild();
	if not nodeEntry then
		return nil;
	end
	
	-- Set link and type
	DB.setValue(nodeEntry, "link", "windowreference", "npc", nodeNPC.getNodeName());
	DB.setValue(nodeEntry, "type", "string", "npc");

	-- Set token and faction
	DB.setValue(nodeEntry, "token", "token", DB.getValue(nodeNPC, "token", nil));
	DB.setValue(nodeEntry, "friendfoe", "string", "foe");

	-- Set name
	local sNameLocal = sName;
	if not sNameLocal then
		sNameLocal = DB.getValue(nodeNPC, "name", "");
	end

	-- If multiple NPCs of same name, then figure out what initiative they go on and potentially append a number
	local nNameCount = 0;
	local nLastInit = nil;
	local nNameHigh = 0;
	if string.len(sNameLocal) > 0 then
		local aMatchesToNumber = {};
		
		for _,v in pairs(nodeTracker.getChildren()) do
			if v.getName() ~= nodeEntry.getName() then
				local sEntryName = DB.getValue(v, "name", "");
				local sTemp, sNumber = stripCreatureNumber(sEntryName);
				if sTemp == sNameLocal then
					nNameCount = nNameCount + 1;
					nLastInit = DB.getValue(v, "initresult", 0);
					
					if sNumber then
						local nNumber = tonumber(sNumber) or 0;
						if nNumber > nNameHigh then
							nNameHigh = nNumber;
						end
					else
						table.insert(aMatchesToNumber, v);
					end
				end
			end
		end
		
		for _,v in ipairs(aMatchesToNumber) do
			local sEntryName = DB.getValue(v, "name", "");
			if sOptNNPC == "append" then
				nNameHigh = nNameHigh + 1;
				DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
			elseif sOptNNPC == "random" then
				DB.setValue(v, "name", "string", randomName(sEntryName));
			end
		end
		
		if nNameCount > 0 then
			if sOptNNPC == "append" then
				nNameHigh = nNameHigh + 1;
				sNameLocal = sNameLocal .. " " .. nNameHigh;
			elseif sOptNNPC == "random" then
				sNameLocal = randomName(sNameLocal);
			end
		end
	end
	DB.setValue(nodeEntry, "name", "string", sNameLocal);
	
	-- Space/reach
	local sSpaceReach = DB.getValue(nodeNPC, "spacereach", "");
	local sSpace, sReach = string.match(sSpaceReach, "(%d+)%D*/?(%d+)%D*");
	if sSpace then
		DB.setValue(nodeEntry, "space", "number", tonumber(sSpace) or 1);
		DB.setValue(nodeEntry, "reach", "number", tonumber(sReach) or 1);
	end

	-- HP
	local nHP = DB.getValue(nodeNPC, "hp", 0);
	if sOptHRNH == "max" then
		nHP = StringManager.evalDiceString(DB.getValue(nodeNPC, "hd", ""), true, true);
	elseif sOptHRNH == "random" then
		nHP = StringManager.evalDiceString(DB.getValue(nodeNPC, "hd", ""), true);
	end
	DB.setValue(nodeEntry, "hp", "number", nHP);

	-- Defensive properties
	local sAC = DB.getValue(nodeNPC, "ac", "10");
	DB.setValue(nodeEntry, "ac_final", "number", tonumber(string.match(sAC, "^(%d+)")) or 10);
	DB.setValue(nodeEntry, "ac_touch", "number", tonumber(string.match(sAC, "touch (%d+)")) or 10);
	local sFlatFooted = string.match(sAC, "flat[%-–]footed (%d+)");
	if not sFlatFooted then
		sFlatFooted = string.match(sAC, "flatfooted (%d+)");
	end
	DB.setValue(nodeEntry, "ac_flatfooted", "number", tonumber(sFlatFooted) or 10);
	
	DB.setValue(nodeEntry, "fortitudesave", "number", DB.getValue(nodeNPC, "fortitudesave", 0));
	DB.setValue(nodeEntry, "reflexsave", "number", DB.getValue(nodeNPC, "reflexsave", 0));
	DB.setValue(nodeEntry, "willsave", "number", DB.getValue(nodeNPC, "willsave", 0));

	-- Active properties
	local nInitBonus = DB.getValue(nodeNPC, "init", 0);
	DB.setValue(nodeEntry, "init", "number", nInitBonus);
	DB.setValue(nodeEntry, "speed", "string", DB.getValue(nodeNPC, "speed", ""));

	local nodeAttacks = nodeEntry.createChild("attacks");
	if nodeAttacks then
		for _,v in pairs(nodeAttacks.getChildren()) do
			v.delete();
		end
		
		local nAttacks = 0;
		
		local sAttack = DB.getValue(nodeNPC, "atk", "");
		if sAttack ~= "" then
			local nodeValue = nodeAttacks.createChild();
			if nodeValue then
				DB.setValue(nodeValue, "value", "string", sAttack);
				nAttacks = nAttacks + 1;
			end
		end
		
		local sFullAttack = DB.getValue(nodeNPC, "fullatk", "");
		if sFullAttack ~= "" then
			nodeValue = nodeAttacks.createChild();
			if nodeValue then
				DB.setValue(nodeValue, "value", "string", sFullAttack);
				nAttacks = nAttacks + 1;
			end
		end
		
		if nAttacks == 0 then
			nodeAttacks.createChild();
		end
	end

	-- Handle BAB / Grapple / CM Field
	local sBABGrp = DB.getValue(nodeNPC, "babgrp", "");
	local aSplitBABGrp = StringManager.split(sBABGrp, "/", true);
	
	local sMatch = string.match(sBABGrp, "CMB ([+-]%d+)");
	if sMatch then
		DB.setValue(nodeEntry, "grapple", "number", tonumber(sMatch) or 0);
	else
		if aSplitBABGrp[2] then
			DB.setValue(nodeEntry, "grapple", "number", tonumber(aSplitBABGrp[2]) or 0);
		end
	end

	sMatch = string.match(sBABGrp, "CMD ([+-]?%d+)");
	if sMatch then
		DB.setValue(nodeEntry, "cmd", "number", tonumber(sMatch) or 0);
	else
		if aSplitBABGrp[3] then
			DB.setValue(nodeEntry, "cmd", "number", tonumber(aSplitBABGrp[3]) or 0);
		end
	end

	-- Track additional damage types and intrinsic effects
	local aEffects = {};
	local aAddDamageTypes = {};
	
	-- Decode monster type qualities
	local sType = string.lower(DB.getValue(nodeNPC, "type", ""));
	local sCreatureType, sSubTypes = string.match(sType, "([^(]+) %(([^)]+)%)");
	if not sCreatureType then
		sCreatureType = sType;
	end
	local aSubTypes = {};
	if sSubTypes then
		aSubTypes = StringManager.split(sSubTypes, ",", true);
	end

	if StringManager.contains(aSubTypes, "lawful") then
		table.insert(aAddDamageTypes, "lawful");
	end
	if StringManager.contains(aSubTypes, "chaotic") then
		table.insert(aAddDamageTypes, "chaotic");
	end
	if StringManager.contains(aSubTypes, "good") then
		table.insert(aAddDamageTypes, "good");
	end
	if StringManager.contains(aSubTypes, "evil") then
		table.insert(aAddDamageTypes, "evil");
	end

	-- DECODE SPECIAL QUALITIES
	local sSpecialQualities = string.lower(DB.getValue(nodeNPC, "specialqualities", ""));
	
	local aSQWords = StringManager.parseWords(sSpecialQualities);
	local i = 1;
	while aSQWords[i] do
		-- DAMAGE REDUCTION
		if StringManager.isWord(aSQWords[i], "dr") or (StringManager.isWord(aSQWords[i], "damage") and StringManager.isWord(aSQWords[i+1], "reduction")) then
			if aSQWords[i] ~= "dr" then
				i = i + 1;
			end
			
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				local sDRAmount = aSQWords[i];
				local aDRTypes = {};
				
				while aSQWords[i+1] do
					if StringManager.isWord(aSQWords[i+1], { "and", "or" }) then
						table.insert(aDRTypes, aSQWords[i+1]);
					elseif StringManager.isWord(aSQWords[i+1], { "epic", "magic" }) then
						table.insert(aDRTypes, aSQWords[i+1]);
						table.insert(aAddDamageTypes, aSQWords[i+1]);
					elseif StringManager.isWord(aSQWords[i+1], "cold") and StringManager.isWord(aSQWords[i+2], "iron") then
						table.insert(aDRTypes, "cold iron");
						i = i + 1;
					elseif StringManager.isWord(aSQWords[i+1], DataCommon.dmgtypes) then
						table.insert(aDRTypes, aSQWords[i+1]);
					else
						break;
					end

					i = i + 1;
				end
				
				local sDREffect = "DR: " .. sDRAmount;
				if #aDRTypes > 0 then
					sDREffect = sDREffect .. " " .. table.concat(aDRTypes, " ");
				end
				table.insert(aEffects, sDREffect);
			end

		-- SPELL RESISTANCE
		elseif StringManager.isWord(aSQWords[i], "sr") or (StringManager.isWord(aSQWords[i], "spell") and StringManager.isWord(aSQWords[i+1], "resistance")) then
			if aSQWords[i] ~= "sr" then
				i = i + 1;
			end
			
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				DB.setValue(nodeEntry, "sr", "number", tonumber(aSQWords[i]) or 0);
			end
		
		-- FAST HEALING
		elseif StringManager.isWord(aSQWords[i], "fast") and StringManager.isWord(aSQWords[i+1], { "healing", "heal" }) then
			i = i + 1;
			
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				table.insert(aEffects, "FHEAL: " .. aSQWords[i]);
			end
		
		-- REGENERATION
		elseif StringManager.isWord(aSQWords[i], "regeneration") then
			if StringManager.isNumberString(aSQWords[i+1]) then
				i = i + 1;
				local sRegenAmount = aSQWords[i];
				local aRegenTypes = {};
				
				while aSQWords[i+1] do
					if StringManager.isWord(aSQWords[i+1], { "and", "or" }) then
						table.insert(aRegenTypes, aSQWords[i+1]);
					elseif StringManager.isWord(aSQWords[i+1], "cold") and StringManager.isWord(aSQWords[i+2], "iron") then
						table.insert(aRegenTypes, "cold iron");
						i = i + 1;
					elseif StringManager.isWord(aSQWords[i+1], DataCommon.dmgtypes) then
						table.insert(aRegenTypes, aSQWords[i+1]);
					else
						break;
					end

					i = i + 1;
				end
				
				local sRegenEffect = "REGEN: " .. sRegenAmount;
				if #aRegenTypes > 0 then
					sRegenEffect = sRegenEffect .. " " .. table.concat(aRegenTypes, " ");
				end
				table.insert(aEffects, sRegenEffect);
			end
			
		-- RESISTANCE
		elseif StringManager.isWord(aSQWords[i], "resistance") and StringManager.isWord(aSQWords[i+1], "to") then
			i = i + 1;
		
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], "and") then
					-- SKIP
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.energytypes) and StringManager.isNumberString(aSQWords[i+2]) then
					i = i + 1;
					table.insert(aEffects, "RESIST: " .. aSQWords[i+1] .. " " .. aSQWords[i]);
				else
					break;
				end

				i = i + 1;
			end

		elseif StringManager.isWord(aSQWords[i], "resist") then
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], DataCommon.energytypes) and StringManager.isNumberString(aSQWords[i+2]) then
					i = i + 1;
					table.insert(aEffects, "RESIST: " .. aSQWords[i+1] .. " " .. aSQWords[i]);
				else
					break;
				end
				
				i = i + 1;
			end
			
		-- VULNERABILITY
		elseif StringManager.isWord(aSQWords[i], "vulnerability") and StringManager.isWord(aSQWords[i+1], "to") then
			i = i + 1;
		
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], "and") then
					-- SKIP
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.energytypes) then
					table.insert(aEffects, "VULN: " .. aSQWords[i+1]);
				else
					break;
				end

				i = i + 1;
			end
			
		-- IMMUNITY
		elseif StringManager.isWord(aSQWords[i], "immunity") and StringManager.isWord(aSQWords[i+1], "to") then
			i = i + 1;
		
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], "and") then
					-- SKIP
				elseif StringManager.isWord(aSQWords[i+1], DataCommon.immunetypes) then
					table.insert(aEffects, "IMMUNE: " .. aSQWords[i+1]);
				else
					break;
				end

				i = i + 1;
			end
		elseif StringManager.isWord(aSQWords[i], "immune") then
			while aSQWords[i+1] do
				if StringManager.isWord(aSQWords[i+1], DataCommon.immunetypes) then
					table.insert(aEffects, "IMMUNE: " .. aSQWords[i+1]);
				else
					break;
				end

				i = i + 1;
			end
			
		-- SPECIAL DEFENSES
		elseif StringManager.isWord(aSQWords[i], "uncanny") and StringManager.isWord(aSQWords[i+1], "dodge") then
			if StringManager.isWord(aSQWords[i-1], "improved") then
				table.insert(aEffects, "Improved Uncanny Dodge");
			else
				table.insert(aEffects, "Uncanny Dodge");
			end
			i = i + 1;
		
		elseif StringManager.isWord(aSQWords[i], "evasion") then
			if StringManager.isWord(aSQWords[i-1], "improved") then
				table.insert(aEffects, "Improved Evasion");
			else
				table.insert(aEffects, "Evasion");
			end
		
		-- TRAITS
		elseif StringManager.isWord(aSQWords[i], "incorporeal") then
			table.insert(aEffects, "Incorporeal");
		elseif StringManager.isWord(aSQWords[i], "traits") then
			if StringManager.isWord(aSQWords[i-1], "construct") then
				table.insert(aEffects, "Construct traits");
			elseif StringManager.isWord(aSQWords[i-1], "undead") then
				table.insert(aEffects, "Undead traits");
			elseif StringManager.isWord(aSQWords[i-1], "swarm") then
				table.insert(aEffects, "Swarm traits");
			end
		end
	
		-- ITERATE SPECIAL QUALITIES DECODE
		i = i + 1;
	end

	-- FINISH ADDING EXTRA DAMAGE TYPES
	if #aAddDamageTypes > 0 then
		table.insert(aEffects, "DMGTYPE: " .. table.concat(aAddDamageTypes, ","));
	end
	
	-- ADD DECODED EFFECTS
	if #aEffects > 0 then
		EffectsManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	if sOptINIT == "group" then
		if nLastInit then
			DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		else
			DB.setValue(nodeEntry, "initresult", "number", math.random(20) + nInitBonus);
		end
	elseif sOptINIT == "on" then
		DB.setValue(nodeEntry, "initresult", "number", math.random(20) + nInitBonus);
	end

	return nodeEntry;
end


