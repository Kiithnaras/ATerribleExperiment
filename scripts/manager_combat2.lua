-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(sortfunc);
	CombatManager.setCustomDrop(onDrop);

	CombatManager.setCustomAddNPC(addNPC);
	CombatManager.setCustomNPCSpaceReach(getNPCSpaceReach);

	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomTurnEnd(onTurnEnd);
	CombatManager.setCustomCombatReset(resetInit);
end

--
-- COMBAT TRACKER SORT
--

-- NOTE: Lua sort function expects the opposite boolean value compared to built-in FG sorting
function sortfunc(node1, node2)
	local bHost = User.isHost();
	local sOptCTSI = OptionsManager.getOption("CTSI");
	
	local sFaction1 = DB.getValue(node1, "friendfoe", "");
	local sFaction2 = DB.getValue(node2, "friendfoe", "");
	
	local bShowInit1 = bHost or ((sOptCTSI == "friend") and (sFaction1 == "friend")) or (sOptCTSI == "on");
	local bShowInit2 = bHost or ((sOptCTSI == "friend") and (sFaction2 == "friend")) or (sOptCTSI == "on");
	
	if bShowInit1 ~= bShowInit2 then
		if bShowInit1 then
			return true;
		elseif bShowInit2 then
			return false;
		end
	else
		if bShowInit1 then
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
		else
			if sFaction1 ~= sFaction2 then
				if sFaction1 == "friend" then
					return true;
				elseif sFaction2 == "friend" then
					return false;
				end
			end
		end
	end
	
	local sValue1 = DB.getValue(node1, "name", "");
	local sValue2 = DB.getValue(node2, "name", "");
	if sValue1 ~= sValue2 then
		return sValue1 < sValue2;
	end

	return node1.getNodeName() < node2.getNodeName();
end

--
-- TURN FUNCTIONS
--

function onTurnStart(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Handle beginning of turn changes
	DB.setValue(nodeEntry, "immediate", "number", 0);
end

function onTurnEnd(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Check for stabilization (based on option)
	local sOptionHRST = OptionsManager.getOption("HRST");
	if sOptionHRST ~= "off" then
		if (sOptionHRST == "all") or (DB.getValue(nodeEntry, "friendfoe", "") == "friend") then
			local nHP = DB.getValue(nodeEntry, "hp", 0);
			local nWounds = DB.getValue(nodeEntry, "wounds", 0);
			local rActor = ActorManager.getActorFromCT(nodeEntry);
			local nDying = GameSystem.getDeathThreshold(rActor);
			if nHP > 0 and nWounds > nHP and nWounds < nHP + nDying then
				if not EffectManager.hasEffect(rActor, "Stable") then
					ActionDamage.performStabilizationRoll(rActor);
				end
			end
		end
	end
end

--
-- DROP HANDLING
--

function onDrop(rSource, rTarget, draginfo)
	local sDragType = draginfo.getType();

	-- Effect targeting
	if sDragType == "effect_targeting" then
		if User.isHost() then
			onEffectTargetingDrop(rSource, rTarget, draginfo);
			return true;
		end
	end
end

function onEffectTargetingDrop(rSource, rTarget, draginfo)
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sTargetCT ~= "" then
		local sRefClass, sEffectNode = draginfo.getShortcutData();
		if sRefClass and sEffectNode then
			if sRefClass == "ct_effect" then
				EffectManager.addEffectTarget(sEffectNode, sTargetCT);
			end
		end
	end
end

--
-- ADD FUNCTIONS
--

function getNPCSpaceReach(nodeNPC)
	local nSpace = GameSystem.GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;
	
	local sSpaceReach = DB.getValue(nodeNPC, "spacereach", "");
	local sSpace, sReach = string.match(sSpaceReach, "(%d+)%D*/?(%d+)%D*");
	if sSpace then
		nSpace = tonumber(sSpace) or nSpace;
		nReach = tonumber(sReach) or nReach;
	end
	
	return nSpace, nReach;
end

function addNPC(sClass, nodeNPC, sName)
	local nodeEntry, nodeLastMatch = CombatManager.addNPCHelper(nodeNPC, sName);

	-- HP
	local sOptHRNH = OptionsManager.getOption("HRNH");
	local nHP = DB.getValue(nodeNPC, "hp", 0);

	local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
	if sOptHRNH == "max" and sHD ~= "" then
		nHP = StringManager.evalDiceString(sHD, true, true);
	elseif sOptHRNH == "random" and sHD ~= "" then
		nHP = StringManager.evalDiceString(sHD, true);
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

	-- Offensive properties
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

	-- Track additional damage types and intrinsic effects
	local aEffects = {};
	local aAddDamageTypes = {};
	
	-- Decode monster type qualities
	local sType = string.lower(DB.getValue(nodeNPC, "type", ""));
	local sCreatureType, sSubTypes = string.match(sType, "([^(]+) %(([^)]+)%)");
	if not sCreatureType then
		sCreatureType = sType;
	end
	local aTypes = StringManager.split(sCreatureType, " ", true);
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
	
	local bImmuneNonlethal = false;
	local bImmuneCritical = false;
	local bImmunePrecision = false;
	if bPFMode then
		if StringManager.contains(aTypes, "construct") then
			table.insert(aEffects, "Construct traits");
			bImmuneNonlethal = true;
		elseif StringManager.contains(aTypes, "elemental") then
			bImmunePrecision = true;
		elseif StringManager.contains(aTypes, "ooze") then
			table.insert(aEffects, "Ooze traits");
			bImmuneCritical = true;
			bImmunePrecision = true;
		elseif StringManager.contains(aTypes, "undead") then
			table.insert(aEffects, "Undead traits");
			bImmuneNonlethal = true;
		end
		
		if StringManager.contains(aSubTypes, "aeon") then
			table.insert(aEffects, "Aeon traits");
			bImmuneCritical = true;
		end
		if StringManager.contains(aSubTypes, "elemental") then
			table.insert(aEffects, "Elemental traits");
			bImmuneCritical = true;
		end
		if StringManager.contains(aSubTypes, "incorporeal") then
			bImmunePrecision = true;
		end
		if StringManager.contains(aSubTypes, "swarm") then
			table.insert(aEffects, "Swarm traits");
			bImmuneCritical = true;
		end
	else
		if StringManager.contains(aTypes, "construct") then
			table.insert(aEffects, "Construct traits");
			bImmuneNonlethal = true;
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "elemental") then
			table.insert(aEffects, "Elemental traits");
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "ooze") then
			table.insert(aEffects, "Ooze traits");
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "plant") then
			table.insert(aEffects, "Plant traits");
			bImmuneCritical = true;
		elseif StringManager.contains(aTypes, "undead") then
			table.insert(aEffects, "Undead traits");
			bImmuneNonlethal = true;
			bImmuneCritical = true;
		end
		if StringManager.contains(aSubTypes, "swarm") then
			table.insert(aEffects, "Swarm traits");
			bImmuneCritical = true;
		end
	end
	if bImmuneNonlethal then
		table.insert(aEffects, "IMMUNE: nonlethal");
	end
	if bImmuneCritical then
		table.insert(aEffects, "IMMUNE: critical");
	end
	if bImmunePrecision then
		table.insert(aEffects, "IMMUNE: precision");
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
				i = i - 1;
				
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
				elseif not StringManager.isWord(aSQWords[i+1], "and") then
					break;
				end
				
				i = i + 1;
			end
			
		-- VULNERABILITY
		elseif StringManager.isWord(aSQWords[i], {"vulnerability", "vulnerable"}) and StringManager.isWord(aSQWords[i+1], "to") then
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
		EffectManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT == "group" then
		if nodeLastMatch then
			local nLastInit = DB.getValue(nodeLastMatch, "initresult", 0);
			DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		else
			DB.setValue(nodeEntry, "initresult", "number", (math.random(6) + math.random(6) + math.random(6)) + DB.getValue(nodeEntry, "init", 0));
		end
	elseif sOptINIT == "on" then
		DB.setValue(nodeEntry, "initresult", "number", (math.random(6) + math.random(6) + math.random(6)) + DB.getValue(nodeEntry, "init", 0));
	end

	return nodeEntry;
end

--
-- RESET FUNCTIONS
--

function resetInit()
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		DB.setValue(vChild, "initresult", "number", 0);
		DB.setValue(vChild, "immediate", "number", 0);
	end
end

function resetEffects()
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local nodeEffects = vChild.getChild("effects");
		if nodeEffects then
			for _, vEffect in pairs(nodeEffects.getChildren()) do
				vEffect.delete();
			end
		end
	end
end

function clearExpiringEffects(bShort)
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
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
		end
	end
end

function rest(bShort)
	CombatManager.resetInit();
	clearExpiringEffects(bShort);
	
	if not bShort then
		for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
			local sClass, sRecord = DB.getValue(vChild, "link", "", "");
			if sClass == "charsheet" and sRecord ~= "" then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					CharManager.rest(nodePC);
				end
			end
		end
	end
end

function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	
	-- Get any effect modifiers
	local rActor = ActorManager.getActorFromCT(nodeEntry);
	local aEffectDice, nEffectBonus = EffectManager.getEffectsBonus(rActor, "INIT");
	nInit = nInit + StringManager.evalDice(aEffectDice, nEffectBonus);
	
	-- For PCs, we always roll unique initiative
	local sClass, sRecord = DB.getValue(vChild, "link", "", "");
	if sClass == "charsheet" then
		local nInitResult = (math.random(6) + math.random(6) + math.random(6)) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
	
	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT ~= "group" then
		local nInitResult = (math.random(6) + math.random(6) + math.random(6)) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end

	-- For NPCs with group option enabled
	
	-- Get the entry's database node name and creature name
	local sStripName = CombatManager.stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
	if sStripName == "" then
		local nInitResult = (math.random(6) + math.random(6) + math.random(6)) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
		
	-- Iterate through list looking for other creature's with same name
	local nLastInit = nil;
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		if vChild.getName() ~= nodeEntry.getName() then
			local sTemp = CombatManager.stripCreatureNumber(DB.getValue(vChild, "name", ""));
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
		local nInitResult = (math.random(6) + math.random(6) + math.random(6)) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
	end
end

function rollInit(sType)
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(vChild, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end
		
		if bRoll then
			DB.setValue(vChild, "initresult", "number", -10000);
		end
	end

	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(vChild, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end
		
		if bRoll then
			rollEntryInit(vChild);
		end
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
			if not nStarts then
				nStarts, nEnds, sAll, sAttackLabel, nDamageStart, sDamage, nDamageEnd 
						= sAND:find('(([%w%s,%[%]%(%)%+%-]*)%(()([^%)]*)()%))');
				if nStarts then
					sAttackCount = "";
					sAttackModifier = "+0";
					sAttackType = "";
				end
			end
			
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
				rAttack.modifier = sAttackModifier or 0;
				
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
				else
					rAttack.range = "M";
					rDamage.range = "M";
					rAttack.stat = "strength";
				end

				-- Determine critical information
				rAttack.crit = 18;
				nCritStart, nCritEnd, sCritThreshold = string.find(sDamage, "/(%d+)%-18");
				if sCritThreshold then
					rAttack.crit = tonumber(sCritThreshold) or 18;
					if rAttack.crit < 4 or rAttack.crit > 18 then
						rAttack.crit = 18;
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
								sDamageTypes = string.match(aDamageAttrib[nAttrib], "^%d+%-18%s?([%w%s,]*)");
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
							
							if not bRanged then
								rDamageClause.stat = "strength";
							end

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
							local nStatBonus = ActorManager2.getAbilityBonus(rActor, "strength");
							if (nDmgBonus >= nStatBonus) then
								rDamage.statmult = 1;
							end
						end
					else
						local nDmgBonus = rDamage.clauses[1].modifier;
						local nStatBonus = ActorManager2.getAbilityBonus(rActor, "strength");
						
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

