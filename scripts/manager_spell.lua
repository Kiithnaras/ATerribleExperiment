-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Reset power points and individual spells cast
function resetSpells(nodeCaster)
	for _,nodeSpellClass in pairs(DB.getChildren(nodeCaster, "spellset")) do
		DB.setValue(nodeSpellClass, "pointsused", "number", 0);
		
		for _,nodeLevel in pairs(DB.getChildren(nodeSpellClass, "levels")) do
			for _,nodeSpell in pairs(DB.getChildren(nodeLevel, "spells")) do
				DB.setValue(nodeSpell, "cast", "number", 0);
			end
		end
	end
end

-- Iterate through each spell to reset
function resetPrepared(nodeCaster)
	for _,nodeSpellClass in pairs(DB.getChildren(nodeCaster, "spellset")) do
		for _,nodeLevel in pairs(DB.getChildren(nodeSpellClass, "levels")) do
			for _,nodeSpell in pairs(DB.getChildren(nodeLevel, "spells")) do
				DB.setValue(nodeSpell, "prepared", "number", 0);
			end
		end
	end
end

function addSpell(nodeSource, nodeTargetLevelSpells)
	-- Validate
	if not nodeSource or not nodeTargetLevelSpells then
		return nil;
	end
	
	-- Create the new spell entry
	local nodeNewSpell = nodeTargetLevelSpells.createChild();
	if not nodeNewSpell then
		return nil;
	end
	
	-- Copy the spell details over
	DB.copyNode(nodeSource, nodeNewSpell);
	
	-- Convert the description field from module data
	local nodeDesc = nodeNewSpell.getChild("description");
	if nodeDesc then
		local sDescType = nodeDesc.getType();
		if sDescType == "formattedtext" then
			local sDesc = nodeDesc.getText();
			local sValue = nodeDesc.getValue();

			nodeDesc.delete();
			DB.setValue(nodeNewSpell, "description", "string", sDesc);
			
			local nodeLinkedSpells = nodeNewSpell.createChild("linkedspells");
			if nodeLinkedSpells then
				local nIndex = 1;
				local nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, "<link class=\"([^\"]*)\" recordname=\"([^\"]*)\">", nIndex);
				while nLinkStartB and sClass and sRecord do
					local nLinkEndB, nLinkEndE = string.find(sValue, "</link>", nLinkStartE + 1);
					
					if nLinkEndB then
						local sText = string.sub(sValue, nLinkStartE + 1, nLinkEndB - 1);
						
						local nodeLink = nodeLinkedSpells.createChild();
						if nodeLink then
							DB.setValue(nodeLink, "link", "windowreference", sClass, sRecord);
							DB.setValue(nodeLink, "linkedname", "string", sText);
						end
						
						nIndex = nLinkEndE + 1;
						nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, "<link class=\"([^\"]*)\" recordname=\"([^\"]*)\">", nIndex);
					else
						nLinkStartB = nil;
					end
				end
			end
		end
	end

	local nodeParent = nodeTargetLevelSpells.getParent();
	if nodeParent then
		-- Set the default cost for points casters
		local nCost = tonumber(string.sub(nodeParent.getName(), -1)) or 0;
		if nCost > 0 then
			nCost = ((nCost - 1) * 2) + 1;
		end
		DB.setValue(nodeNewSpell, "cost", "number", nCost);

		-- If spell level not visible, then make it so.
		local sAvailablePath = "....available" .. nodeParent.getName();
		local nAvailable = DB.getValue(nodeTargetLevelSpells, sAvailablePath, 1);
		if nAvailable <= 0 then
			DB.setValue(nodeTargetLevelSpells, sAvailablePath, "number", 1);
		end
	end
	
	-- Parse spell details to create actions
	if DB.getChildCount(nodeNewSpell, "actions") == 0 then
		parseSpell(nodeNewSpell);
	end
	
	return nodeNewSpell;
end

function addSpellCastAction(nodeSpell)
	-- Clean out old actions
	local nodeActions = nodeSpell.createChild("actions");
	if nodeActions then
		local nodeAction = nodeActions.createChild();
		if nodeAction then
			DB.setValue(nodeAction, "type", "string", "cast");
			
			local sSave = DB.getValue(nodeSpell, "save", ""):lower();
			if not sSave:match("harmless") then
				if sSave:match("^fortitude ") then
					DB.setValue(nodeAction, "savetype", "string", "fortitude");
				elseif sSave:match("^reflex ") then
					DB.setValue(nodeAction, "savetype", "string", "reflex");
				elseif sSave:match("^will ") then
					DB.setValue(nodeAction, "savetype", "string", "will");
				end
			end
			
			local sSR = DB.getValue(nodeSpell, "sr", ""):lower();
			if sSR:match("harmless") or sSR:match("^no") then
				DB.setValue(nodeAction, "srnotallowed", "number", 1);
			end
			
			local sDesc = DB.getValue(nodeSpell, "description", ""):lower();
			if sDesc:match("ranged touch attack") then
				DB.setValue(nodeAction, "atktype", "string", "rtouch");
			elseif sDesc:match("melee touch attack") then
				DB.setValue(nodeAction, "atktype", "string", "mtouch");
			elseif sDesc:match("normal ranged attack") then
				DB.setValue(nodeAction, "atktype", "string", "ranged");
			end
		end
	end
end

function parseSpell(nodeSpell)
	-- CLean out old actions
	local nodeActions = nodeSpell.createChild("actions");
	for k, v in pairs(nodeActions.getChildren()) do
		v.delete();
	end
	
	-- Always create a cast action
	addSpellCastAction(nodeSpell);
	
	-- Get the description minos some problem characters and in lowercase
	local sDesc = string.lower(DB.getValue(nodeSpell, "description", ""));
	sDesc = string.gsub(sDesc, "’", "'");
	sDesc = string.gsub(sDesc, "–", "-");
	
	local aWords = StringManager.parseWords(sDesc);
	
	-- Damage/Heal setup
	local aDamages = {};
	local aHeals = {};

  	local i = 1;
  	while aWords[i] do
		-- Main trigger ("damage")
		if StringManager.isWord(aWords[i], "damage") then
			local j = i - 1;

			-- Get damage type
			local sDamageType = "";
			if j > 0 and StringManager.isWord(aWords[j], DataCommon.dmgtypes) then
				sDamageType = aWords[j];
				j = j - 1;
			end
			
			-- Skip "of"
			if StringManager.isWord(aWords[j], "of") then
				j = j - 1;
			end
			
			-- Get heal or damage
			local sRollType = nil;
			local sRollDice = nil;
			if StringManager.isWord(aWords[j], { "points", "point" }) then
				j = j - 1;
				
				-- Skip "hit"
				if StringManager.isWord(aWords[j], "hit") then
					j = j - 1;
				end
				
				if StringManager.isDiceString(aWords[j]) then
					sRollDice = aWords[j];

					j = j - 1;
					if StringManager.isWord(aWords[j], { "deal", "deals", "take", "takes", "dealt", "dealing", "taking", "causes" }) then
						sRollType = "damage";
					elseif StringManager.isWord(aWords[j], { "cure", "cures" }) then
						sRollType = "heal";
					elseif StringManager.isWord(aWords[j], { "damage", "and", "or" }) then
						sRollType = "damage";
					elseif StringManager.isWord(aWords[j], { "yellow", "orange", "red" }) then
						sRollType = "damage";
					end
				end
				
			end
			
			-- If we have a roll
			if sRollType and sRollDice then
				local k = i + 1;
				local bScaling = false;
				local bPointMode = false;
				local bHalfLevel = false;
				local sMaxRollDice = nil;
				
				if StringManager.isWord(aWords[k], "+1") and StringManager.isWord(aWords[k+1], "point") then
					bPointMode = true;
					k = k + 2;
				elseif StringManager.isWord(aWords[k], "+") and StringManager.isWord(aWords[k+1], "1") and StringManager.isWord(aWords[k+2], "point") then
					bPointMode = true;
					k = k + 3;
				end
				
				if StringManager.isWord(aWords[k], "per") then
					k = k + 1;
					if StringManager.isWord(aWords[k], "two") then
						k = k + 1;
						bHalfLevel = true;
					end
					if StringManager.isWord(aWords[k], "caster") then
						k = k + 1;
					end
					if StringManager.isWord(aWords[k], { "level", "levels" }) then
						k = k + 1;
						bScaling = true;
						
						if StringManager.isWord(aWords[k], "of") and StringManager.isWord(aWords[k+1], "the") and StringManager.isWord(aWords[k+2], "caster") then 
							k = k + 3;
						end
						
						if StringManager.isWord(aWords[k], "maximum") then
							sMaxRollDice = aWords[k + 1];
						elseif StringManager.isWord(aWords[k], "to") and
								StringManager.isWord(aWords[k+1], "a") and
								StringManager.isWord(aWords[k+2], "maximum") and
								StringManager.isWord(aWords[k+3], "of") then
							sMaxRollDice = aWords[k + 4];
						end
					end
				end
				
				local rRoll = {};
				rRoll.aDice, rRoll.nMod = StringManager.convertStringToDice(sRollDice);
				rRoll.sType = sDamageType;
				if bScaling then
					local sMult;
					if bHalfLevel then
						sMult = "halfcl";
					else
						sMult = "cl";
					end
					
					if bPointMode or #(rRoll.aDice) == 0 then
						rRoll.sModMult = sMult;
					else
						rRoll.sDiceMult = sMult;
					end
					
					if sMaxRollDice then
						local aMaxDice, nMaxMod = StringManager.convertStringToDice(sMaxRollDice);
						if bPointMode then
							rRoll.nMaxMult = nMaxMod;
						elseif #(rRoll.aDice) > 0 then
							rRoll.nMaxMult = math.floor(#aMaxDice / #(rRoll.aDice))
						else
							rRoll.nMaxMult = math.floor(nMaxMod / rRoll.nMod);
						end
					end
				end
				
				if sRollType == "heal" then
					table.insert(aHeals, rRoll);
				else
					table.insert(aDamages, rRoll);
				end
			end
		end
			
		-- Increment word counter
		i = i + 1;
	end	

	-- Add the Damage and Heal rolls
	for i = 1, #aDamages do
		local rRoll = aDamages[i];
		local nodeAction = nodeActions.createChild();
		
		DB.setValue(nodeAction, "type", "string", "damage");
		
		DB.setValue(nodeAction, "dmgdice", "dice", rRoll.aDice);
		if rRoll.sDiceMult then
			DB.setValue(nodeAction, "dmgdicemult", "string", rRoll.sDiceMult);
			if rRoll.nMaxMult then
				DB.setValue(nodeAction, "dmgdicemultmax", "number", rRoll.nMaxMult);
			end
		end
		
		if rRoll.sModMult then
			DB.setValue(nodeAction, "dmgstat", "string", rRoll.sModMult);
			DB.setValue(nodeAction, "dmgstatmult", "number", rRoll.nMod);
			if rRoll.nMaxMult then
				DB.setValue(nodeAction, "dmgmaxstat", "number", rRoll.nMaxMult);
			end
		else
			DB.setValue(nodeAction, "dmgmod", "number", rRoll.nMod);
		end
		
		DB.setValue(nodeAction, "dmgtype", "string", rRoll.sType);
	end
	for i = 1, #aHeals do
		local rRoll = aHeals[i];
		local nodeAction = nodeActions.createChild();
		
		DB.setValue(nodeAction, "type", "string", "heal");
		
		DB.setValue(nodeAction, "hdice", "dice", rRoll.aDice);
		if rRoll.sDiceMult then
			DB.setValue(nodeAction, "hdicemult", "string", rRoll.sDiceMult);
			if rRoll.nMaxMult then
				DB.setValue(nodeAction, "hdicemultmax", "number", rRoll.nMaxMult);
			end
		end
		
		if rRoll.sModMult then
			DB.setValue(nodeAction, "hstat", "string", rRoll.sModMult);
			DB.setValue(nodeAction, "hstatmult", "number", rRoll.nMod);
			if rRoll.nMaxMult then
				DB.setValue(nodeAction, "hmaxstat", "number", rRoll.nMaxMult);
			end
		else
			DB.setValue(nodeAction, "hmod", "number", rRoll.nMod);
		end
	end
	
	-- Effects setup
	local aEffects = {};

  	i = 1;
  	while aWords[i] do
		if StringManager.isWord(aWords[i], DataCommon.spelleffects) then
			local k = i;
			while StringManager.isWord(aWords[k + 1], DataCommon.spelleffects) or StringManager.isWord(aWords[k + 1], "and") do
				k = k + 1;
			end
			
			local bValidEffect = false;
			local j = i - 1;
			if StringManager.isWord(aWords[j], { "immediately", "only" }) then
				j = j - 1;
			end
			if StringManager.isWord(aWords[j], { "is", "are" }) then
				if not StringManager.isWord(aWords[j - 1], { "beams", "power", "that" }) then
					bValidEffect = true;
				end
			elseif StringManager.isWord(aWords[j], { "become", "becomes" }) then
				if not StringManager.isWord(aWords[j - 1], { "not", "never" }) then
					bValidEffect = true;
				end
			elseif StringManager.isWord(aWords[j], "being") then
				if not StringManager.isWord(aWords[j - 1], "as") then
					bValidEffect = true;
				end
			elseif StringManager.isWord(aWords[j], { "be", "and", "or", "then", "remains", "subject" }) then
				bValidEffect = true;
			end

			if bValidEffect then
				local rEffect = {};
				
				local aEffectWords = {};
				for z = i, k do
					if aWords[z] ~= "and" then
						local sWord = StringManager.capitalize(aWords[z]);
						table.insert(aEffectWords, sWord);
					end
				end
				
				rEffect.sName = table.concat(aEffectWords, "; ");
				
				local m = k + 1;
				if StringManager.isWord(aWords[m], "as") and
						StringManager.isWord(aWords[m + 1], "by") and
						StringManager.isWord(aWords[m + 2], "the") and
						StringManager.isWord(aWords[m + 4], "spell") then
					m = m + 5;
				end
				if StringManager.isWord(aWords[m], "for") then
					m = m + 1;
					
					if StringManager.isDiceString(aWords[m]) then
						local sDiceMod = aWords[m];
						m = m + 1;
						
						local sUnits = nil;
						if StringManager.isWord(aWords[m], { "round", "rounds" }) then
							sUnits = "";
						elseif StringManager.isWord(aWords[m], { "minute", "minutes" }) then
							sUnits = "minute";
						elseif StringManager.isWord(aWords[m], { "hour", "hours" }) then
							sUnits = "hour";
						elseif StringManager.isWord(aWords[m], { "day", "days" }) then
							sUnits = "day";
						end
						m = m + 1;
						
						if sUnits then
							rEffect.aDice, rEffect.nMod = StringManager.convertStringToDice(sDiceMod);
							
							if StringManager.isWord(aWords[m], "per") and
									StringManager.isWord(aWords[m + 1], "caster") and
									StringManager.isWord(aWords[m + 2], "level") then
								rEffect.bCLMult = true;
							end

							rEffect.sUnits = sUnits;
						end
					end
				end
				
				table.insert(aEffects, rEffect);
			end

			i = k;
			
		elseif StringManager.isWord(aWords[i], { "daze", "dazes" }) and 
				StringManager.isWord(aWords[i+1], "one") and 
				StringManager.isWord(aWords[i+2], "living") and
				StringManager.isWord(aWords[i+3], "creature") then
			
			local rEffect = {};
			rEffect.sName = "Dazed";
			
			table.insert(aEffects, rEffect);

			i = i + 3;
		end
		
		-- Increment word counter
		i = i + 1;
	end
	
	-- Remove duplicates
	local aFinalEffects = {};
	for i = 1, #aEffects do
		local bFirstUnique = true;
		for j = i - 1, 1, -1 do
			if aEffects[i].sName == aEffects[j].sName then
				bFirstUnique = false;
				break;
			end
		end
		if bFirstUnique then
			table.insert(aFinalEffects, aEffects[i]);
		end
	end
	
	-- Add the Effects
	for i = 1, #aFinalEffects do
		local rRoll = aFinalEffects[i];
		local nodeAction = nodeActions.createChild();
		
		DB.setValue(nodeAction, "type", "string", "effect");
		DB.setValue(nodeAction, "label", "string", rRoll.sName);
		
		-- If duration is specified in the spell description
		if rRoll.sUnits then
			DB.setValue(nodeAction, "durdice", "dice", rRoll.aDice);
			DB.setValue(nodeAction, "durunit", "string", rRoll.sUnits);
			
			if rRoll.bCLMult then
				DB.setValue(nodeAction, "durmult", "number", rRoll.nMod);
			else
				DB.setValue(nodeAction, "durmod", "number", rRoll.nMod);
			end

		-- Otherwise, use the spell duration (if available), or permanent (if not)
		else
			local sSpellDur = DB.getValue(nodeAction, "...duration", "");
			local aDurWords = StringManager.parseWords(sSpellDur);
			
			i = 1;
			if StringManager.isNumberString(aDurWords[i]) then
				local nSpellDur = tonumber(aDurWords[i]);
				i = i + 1;
				
				local sUnits = nil;
				if StringManager.isWord(aDurWords[i], { "round", "rounds" }) then
					sUnits = "";
				elseif StringManager.isWord(aDurWords[i], { "min", "minute", "minutes" }) then
					sUnits = "minute";
				elseif StringManager.isWord(aDurWords[i], { "hour", "hours" }) then
					sUnits = "hour";
				elseif StringManager.isWord(aDurWords[i], { "day", "days" }) then
					sUnits = "day";
				end
				
				if sUnits then
					i = i + 1;
					
					local nMult = 1;
					if StringManager.isWord(aDurWords[i], "per") then
						i = i + 1;
						if StringManager.isWord(aDurWords[i], "two") then
							nMult = 0.5;
							i = i + 1;
						elseif StringManager.isWord(aDurWords[i], "three") then
							nMult = 0.34;
							i = i + 1;
						end
					end
					
					local bUseCL = false;
					if StringManager.isWord(aDurWords[i], { "level", "levels" }) then
						bUseCL = true;
					end
					
					if bUseCL then
						local nFinalDur = math.max(math.floor(nSpellDur * nMult), nMult);
						DB.setValue(nodeAction, "durmult", "number", nFinalDur);
					else
						DB.setValue(nodeAction, "durmod", "number", nSpellDur);
					end
					DB.setValue(nodeAction, "durunit", "string", sUnits);
				end
			end
		end
	end
end

function updateSpellClassCounts(nodeSpellClass)
	local sCasterType = DB.getValue(nodeSpellClass, "castertype", "");
	if sCasterType == "points" then
		return;
	end
	
	for _,vLevel in pairs(DB.getChildren(nodeSpellClass, "levels")) do
		-- Calculate spell statistics
		local nTotalCast = 0;
		local nTotalPrepared = 0;
		local nMaxPrepared = 0;
		local nSpells = 0;
		
		for _,vSpell in pairs(DB.getChildren(vLevel, "spells")) do
			nSpells = nSpells + 1;
			
			local nCast = DB.getValue(vSpell, "cast", 0);
			nTotalCast = nTotalCast + nCast;
			
			local nPrepared = 0;
			if sCasterType ~= "spontaneous" then
				nPrepared = DB.getValue(vSpell, "prepared", 0);
				nTotalPrepared = nTotalPrepared + nPrepared;
				if nPrepared > nMaxPrepared then
					nMaxPrepared = nPrepared;
				end
			end
		end
		
		DB.setValue(vLevel, "totalcast", "number", nTotalCast);
		DB.setValue(vLevel, "totalprepared", "number", nTotalPrepared);
		DB.setValue(vLevel, "maxprepared", "number", nMaxPrepared);
	end
end

function getSpellActionOutputOrder(nodeAction)
	if not nodeAction then
		return 1;
	end
	local nodeActionList = nodeAction.getParent();
	if not nodeActionList then
		return 1;
	end
	
	-- First, pull some ability attributes
	local sType = DB.getValue(nodeAction, "type", "");
	local nOrder = DB.getValue(nodeAction, "order", 0);
	
	-- Iterate through list node
	local nOutputOrder = 1;
	for k, v in pairs(nodeActionList.getChildren()) do
		if DB.getValue(v, "type", "") == sType then
			if DB.getValue(v, "order", 0) < nOrder then
				nOutputOrder = nOutputOrder + 1;
			end
		end
	end
	
	return nOutputOrder;
end

function getSpellRoll(rActor, nodeAction, sSubRoll)
	if not nodeAction then
		return;
	end
	
	local sType = DB.getValue(nodeAction, "type", "");
	
	local rAction = {};
	rAction.type = sType;
	rAction.label = DB.getValue(nodeAction, "...name", "");
	rAction.order = getSpellActionOutputOrder(nodeAction);
	
	if sType == "cast" then
		rAction.subtype = sSubRoll;
		
		local sAttackType = DB.getValue(nodeAction, "atktype", "");
		if sAttackType ~= "" then
			if sAttackType == "mtouch" then
				rAction.range = "M";
				rAction.touch = true;
			elseif sAttackType == "rtouch" then
				rAction.range = "R";
				rAction.touch = true;
			elseif sAttackType == "ranged" then
				rAction.range = "R";
			elseif sAttackType == "cm" then
				rAction.range = "M";
				rAction.cm = true;
			else
				rAction.range = "M";
			end
			
			local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
			rAction.modifier = DB.getValue(nodeActor, "attackbonus.base", 0) + DB.getValue(nodeAction, "atkmod", 0);
			rAction.crit = 18;
			
			if rAction.range == "R" then
				rAction.stat = DB.getValue(nodeActor, "attackbonus.ranged.ability", "");
				if rAction.stat == "" then
					rAction.stat = "dexterity";
				end
				rAction.modifier = rAction.modifier + DB.getValue(nodeActor, "attackbonus.ranged.size", 0) + DB.getValue(nodeActor, "attackbonus.ranged.misc", 0);
			else
				if rAction.cm then
					rAction.stat = DB.getValue(nodeActor, "attackbonus.grapple.ability", "");
					if rAction.stat == "" then
						rAction.stat = "strength";
					end
					rAction.modifier = rAction.modifier + DB.getValue(nodeActor, "attackbonus.grapple.size", 0) + DB.getValue(nodeActor, "attackbonus.grapple.misc", 0);
				else
					rAction.stat = DB.getValue(nodeActor, "attackbonus.melee.ability", "");
					if rAction.stat == "" then
						rAction.stat = "strength";
					end
					rAction.modifier = rAction.modifier + DB.getValue(nodeActor, "attackbonus.melee.size", 0) + DB.getValue(nodeActor, "attackbonus.melee.misc", 0);
				end
			end
			rAction.modifier = rAction.modifier + ActorManager2.getAbilityBonus(rActor, rAction.stat)
		end
		
		rAction.clc = DB.getValue(nodeAction, "clcbase", 0) + DB.getValue(nodeAction, "clcmod", 0);
		rAction.sr = "yes";
		
		if (DB.getValue(nodeAction, "srnotallowed", 0) == 1) then
			rAction.sr = "no";
		end
		
		rAction.dcstat = DB.getValue(nodeAction, ".......dc.ability", "");
		
		local sSaveType = DB.getValue(nodeAction, "savetype", "");
		if sSaveType ~= "" then
			rAction.save = sSaveType;
			rAction.savemod = DB.getValue(nodeAction, "savedcbase", 0) + DB.getValue(nodeAction, "savedcmod", 0);
		else
			rAction.save = "";
			rAction.savemod = 0;
		end
		
	elseif sType == "damage" then
		-- Pull action statistics
		local aDice, nMod, sType, sStat, nStat, nMaxStat = getSpellActionDamage(rActor, nodeAction);
		
		-- Figure out how many bonuses until max stat value reached (for effects)
		if nMaxStat > 0 then
			if nStat >= nMaxStat then
				sStat = "";
				nStat = nMaxStat;
				nMaxStat = 0;
			elseif nStat > 0 then
				nMaxStat = nMaxStat - nStat;
			end
		end

		-- Build action structure
		rAction.stat = sStat;
		rAction.statmax = nMaxStat;
		rAction.statmult = 1;
		rAction.stat2 = "";
		
		rAction.clauses = {};

		local rSpellClause = {};
		
		rSpellClause.dice = aDice;
		rSpellClause.modifier = nMod;
		rSpellClause.mult = 2;
		
		local aDamageTypes = ActionDamage.getDamageTypesFromString(sType);
		if DB.getValue(nodeAction, "dmgnotspell", 0) == 0 then
			table.insert(aDamageTypes, "spell");
		end
		rSpellClause.dmgtype = table.concat(aDamageTypes, ",");
		
		table.insert(rAction.clauses, rSpellClause);

		rAction.meta = DB.getValue(nodeAction, "dmgmeta", "");
		
	elseif sType == "heal" then
		-- Pull action statistics
		local aDice, nMod, sType, sStat, nStat, nMaxStat = getSpellActionHeal(rActor, nodeAction);
		
		-- Figure out how many bonuses until max stat value reached (for effects)
		if nMaxStat > 0 then
			if nStat >= nMaxStat then
				sStat = "";
				nStat = nMaxStat;
				nMaxStat = 0;
			elseif nStat > 0 then
				nMaxStat = nMaxStat - nStat;
			end
		end

		-- Build action structure
		rAction.subtype = sType;
		rAction.stat = sStat;
		rAction.statmax = nStatMax;
		rAction.dice = aDice;
		rAction.modifier = nMod;
		
		rAction.meta = DB.getValue(nodeAction, "healmeta", "");
	
	elseif sType == "effect" then
		rAction.sName = EffectManager.evalEffect(rActor, DB.getValue(nodeAction, "label", ""));

		rAction.sApply = DB.getValue(nodeAction, "apply", "");
		rAction.sTargeting = DB.getValue(nodeAction, "targeting", "");
		
		rAction.aDice = DB.getValue(nodeAction, "durdice", {});
		rAction.nDuration = DB.getValue(nodeAction, "durmod", 0);

		local nMult = DB.getValue(nodeAction, "durmult", 0);
		if nMult > 0 then
			local sStat = DB.getValue(nodeAction, "durstat", "");
			local nStat = 0;
			if sStat == "cl" or sStat == "halfcl" or sStat == "oddcl" then
				nStat = DB.getValue(nodeAction, ".......cl", 0);
				if sStat == "halfcl" then
					nStat = math.floor((nStat + 0.5) / 2);
				elseif sStat == "oddcl" then
					nStat = math.floor((nStat + 1.5) / 2);
				end
			else
				nStat = ActorManager2.getAbilityBonus(rActor, sStat);
			end
			local nMaxStat = DB.getValue(nodeAction, "dmaxstat", 0);
			if nMaxStat > 0 and nMaxStat < nStat then
				nStat = nMaxStat;
			end
			rAction.nDuration = rAction.nDuration + math.floor(nMult * nStat);
		end
		
		rAction.sUnits = DB.getValue(nodeAction, "durunit", "");
	end
	
	return rAction;
end

function onSpellAction(rActor, nodeAction, draginfo, sSubRoll)
	if not rActor or not nodeAction then
		return;
	end
	
	local rAction = getSpellRoll(rActor, nodeAction, sSubRoll);
	
	local rRolls = {};
	local rCustom = nil;
	if rAction.type == "cast" then
		if not rAction.subtype then
			table.insert(rRolls, ActionSpell.getSpellCastRoll(rActor, rAction));
		end
		
		if not rAction.subtype or rAction.subtype == "atk" then
			if rAction.range then
				table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
			end
		end

		if not rAction.subtype or rAction.subtype == "clc" then
			local rRoll = ActionSpell.getCLCRoll(rActor, rAction);
			if not rAction.subtype then
				rRoll.sType = "castclc";
				rRoll.aDice = {};
			end
			table.insert(rRolls, rRoll);
		end

		if not rAction.subtype or rAction.subtype == "save" then
			if rAction.save and rAction.save ~= "" then
				local rRoll = ActionSpell.getSaveVsRoll(rActor, rAction);
				if not rAction.subtype then
					rRoll.sType = "castsave";
				end
				table.insert(rRolls, rRoll);
			end
		end
		
	elseif rAction.type == "damage" then
		local rRoll = ActionDamage.getRoll(rActor, rAction);
		rRoll.sType = "spdamage";
		table.insert(rRolls, rRoll);
		
	elseif rAction.type == "heal" then
		table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));

	elseif rAction.type == "effect" then
		local rRoll;
		rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
		if rRoll then
			table.insert(rRolls, rRoll);
		end
	end
	
	if #rRolls > 0 then
		ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
	end
end

function getSpellActionDamage(rActor, nodeAction)
	if not nodeAction then
		return;
	end
	
	local aDice = DB.getValue(nodeAction, "dmgdice", {});
	if #aDice > 0 then
		local sDiceMult = DB.getValue(nodeAction, "dmgdicemult", "");
		local nDiceMult = 1;
		if sDiceMult == "cl" or sDiceMult == "halfcl" or sDiceMult == "oddcl" then
			nDiceMult = DB.getValue(nodeAction, ".......cl", 0);
			if sDiceMult == "halfcl" then
				nDiceMult = math.floor((nDiceMult + 0.5) / 2);
			elseif sDiceMult == "oddcl" then
				nDiceMult = math.floor((nDiceMult + 1.5) / 2);
			end
			
			local nDiceMultMax = DB.getValue(nodeAction, "dmgdicemultmax", 0);
			if nDiceMultMax > 0 and nDiceMultMax < nDiceMult then
				nDiceMult = nDiceMultMax;
			end
			if nDiceMult < 1 then
				nDiceMult = 1;
			end
		end
		
		local nCopy = #aDice;
		for i = 2, nDiceMult do
			for j = 1, nCopy do
				table.insert(aDice, aDice[j]);
			end
		end
	end

	local nMod = DB.getValue(nodeAction, "dmgmod", 0);
	local sStat = DB.getValue(nodeAction, "dmgstat", "");
	local nStat = 0;
	local nMaxStat = DB.getValue(nodeAction, "dmgmaxstat", 0);
	local nStatMult = DB.getValue(nodeAction, "dmgstatmult", 1);
	if nStatMult < 1 then
		nStatMult = 1;
	end
	if sStat ~= "" then
		if sStat == "cl" or sStat == "halfcl" or sStat == "oddcl" then
			nStat = DB.getValue(nodeAction, ".......cl", 0);
			if sStat == "halfcl" then
				nStat = math.floor((nStat + 0.5) / 2);
			elseif sStat == "oddcl" then
				nStat = math.floor((nStat + 1.5) / 2);
			end
		else
			nStat = ActorManager2.getAbilityBonus(rActor, sStat);
		end
		
		if nMaxStat > 0 and nMaxStat < nStat then
			nStat = nMaxStat;
		end
		
		nMod = nMod + (nStat * nStatMult);
	end
	
	local sType = DB.getValue(nodeAction, "dmgtype", "");
	
	return aDice, nMod, sType, sStat, nStat, nMaxStat;
end

function getSpellActionHeal(rActor, nodeAction)
	if not nodeAction then
		return;
	end
	
	local aDice = DB.getValue(nodeAction, "hdice", {});
	if #aDice > 0 then
		local sDiceMult = DB.getValue(nodeAction, "hdicemult", "");
		local nDiceMult = 1;
		if sDiceMult == "cl" or sDiceMult == "halfcl" or sDiceMult == "oddcl" then
			nDiceMult = DB.getValue(nodeAction, ".......cl", 0);
			if sDiceMult == "halfcl" then
				nDiceMult = math.floor((nDiceMult + 0.5) / 2);
			elseif sDiceMult == "oddcl" then
				nDiceMult = math.floor((nDiceMult + 1.5) / 2);
			end
			
			local nDiceMultMax = DB.getValue(nodeAction, "hdicemultmax", 0);
			if nDiceMultMax > 0 and nDiceMultMax < nDiceMult then
				nDiceMult = nDiceMultMax;
			end
			if nDiceMult < 1 then
				nDiceMult = 1;
			end
		end
		
		local nCopy = #aDice;
		for i = 2, nDiceMult do
			for j = 1, nCopy do
				table.insert(aDice, aDice[j]);
			end
		end
	end

	local nMod = DB.getValue(nodeAction, "hmod", 0);
	local sStat = DB.getValue(nodeAction, "hstat", "");
	local nStat = 0;
	local nMaxStat = DB.getValue(nodeAction, "hmaxstat", 0);
	local nStatMult = DB.getValue(nodeAction, "hstatmult", 1);
	if nStatMult < 1 then
		nStatMult = 1;
	end
	if sStat ~= "" then
		if sStat == "cl" or sStat == "halfcl" or sStat == "oddcl" then
			nStat = DB.getValue(nodeAction, ".......cl", 0);
			if sStat == "halfcl" then
				nStat = math.floor((nStat + 0.5) / 2);
			elseif sStat == "oddcl" then
				nStat = math.floor((nStat + 1.5) / 2);
			end
		else
			nStat = ActorManager2.getAbilityBonus(rActor, sStat);
		end
		
		if nMaxStat > 0 and nMaxStat < nStat then
			nStat = nMaxStat;
		end
		
		nMod = nMod + (nStat * nStatMult);
	end
	
	local sType = DB.getValue(nodeAction, "healtype", "");
	
	return aDice, nMod, sType, sStat, nStat, nMaxStat;
end
