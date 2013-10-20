-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		updateDatabase(DB.findNode("."));
	end
end

function updateDatabase(nodeRoot)
	if not nodeRoot then
		return;
	end
	
	local major, minor = nodeRoot.getRulesetVersion();

	if major < 8 then
		convertCharacters(nodeRoot);
		convertCT(nodeRoot);
		convertEncounters(nodeRoot);
		convertOptions(nodeRoot);
	elseif major < 9 then
		convertCharacters9(nodeRoot);
		convertEncounters9(nodeRoot);
		convertOptions9(nodeRoot);
	elseif major < 10 then
		convertLog10(nodeRoot);
	end
end

function convertLog10(nodeRoot)
	local nodeLog = nodeRoot.getChild("partysheet.adventurelog");
	if nodeLog then
		local nodeNewLog = nodeRoot.createChild("calendar.log");
		if nodeNewLog then
			DB.copyNode(nodeLog, nodeNewLog);
			nodeLog.delete();
		end
	end
end

function migrateCharacter9(nodeChar)
	local nACMisc = DB.getValue(nodeChar, "ac.sources.misc", 0);
	if nACMisc ~= 0 then
		DB.setValue(nodeChar, "ac.sources.ffmisc", "number", nACMisc);
		DB.setValue(nodeChar, "ac.sources.touchmisc", "number", nACMisc);

		local nCMDMisc = DB.getValue(nodeChar, "ac.sources.cmdmisc", 0) + nACMisc;
		DB.setValue(nodeChar, "ac.sources.cmdmisc", "number", nCMDMisc);
	end
end

function convertCharacters9(nodeRoot)
	for _,nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		migrateCharacter9(nodeChar);
	end
end

function migrateEncounter9(nodeRecord)
	for _,nodeNPC in pairs(DB.getChildren(nodeRecord, "npclist")) do
		for _,nodeMapLink in pairs(DB.getChildren(nodeNPC, "maplink")) do
			local nodeImageLink = nodeMapLink.getChild("imagelink");
			if nodeImageLink then
				DB.setValue(nodeMapLink, "imageref", "windowreference", "imagewindow", nodeImageLink.getValue());
				nodeImageLink.delete();
			end
		end
	end
end

function convertEncounters9(nodeRoot)
	for _,nodeEnc in pairs(DB.getChildren(nodeRoot, "battle")) do
		migrateEncounter9(nodeEnc);
	end
end

function convertOptions9(nodeRoot)
	local nodeOptions = nodeRoot.getChild("options");
	if not nodeOptions then
		return;
	end
	
	local sOptionHRNH = "off";
	local nodeOptionRHPS = nodeOptions.getChild("RHPS");
	if nodeOptionRHPS then
		if nodeOptionRHPS.getValue() == "on" then
			sOptionHRNH = "random";
		end
		nodeOptionRHPS.delete();
	end
	DB.setValue(nodeOptions, "HRNH", "string", sOptionHRNH);
end

function convertCharacters(nodeRoot)
	for _,nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		local nodeSpecial = nodeChar.getChild("special");
		if nodeSpecial then
			local nodeSR = nodeSpecial.getChild("spellresistance");
			if nodeSR then
				DB.setValue(nodeChar, "defenses.sr.base", "number", nodeSR.getValue());
			end
		
			local nodeDR = nodeSpecial.getChild("damagereduction");
			if nodeDR then
				local nDR = nodeDR.getValue();
				if nDR ~= 0 then
					DB.setValue(nodeChar, "defenses.damagereduction", "string", nDR);
				end
			end
			
			local nodeSF = nodeSpecial.getChild("spellfailure");
			if nodeSF then
				DB.setValue(nodeChar, "encumbrance.spellfailure", "number", nodeSF.getValue());
			end

			nodeSpecial.delete();
		end
		
		local nodeEnc = nodeChar.getChild("encumbrance");
		if nodeEnc then
			local nodeEncMaxBonus = nodeEnc.getChild("armormaxdexbonus");
			if nodeEncMaxBonus then
				DB.setValue(nodeEnc, "armormaxstatbonus", "number", nodeEncMaxBonus.getValue());
				nodeEncMaxBonus.delete();
			end
			
			local nodeEncMaxBonusActive = nodeEnc.getChild("armormaxdexbonusactive");
			if nodeEncMaxBonusActive then
				DB.setValue(nodeEnc, "armormaxstatbonusactive", "number", nodeEncMaxBonusActive.getValue());
				nodeEncMaxBonusActive.delete();
			end
		end
		
		local nodeSpeed = nodeChar.getChild("speed");
		if nodeSpeed then
			local nSpeed = nodeSpeed.getValue();
			nodeSpeed.delete();
			DB.setValue(nodeChar, "speed.base", "number", nSpeed);
		end
		
		local aClasses = {};
		local nodeClassList = nodeChar.getChild("classes");
		if nodeClassList then
			local nodeOldClass, nodeNewClass, sClass, nLevel;
			
			for i = 1, 3 do
				nodeOldClass = nodeClassList.getChild("slot" .. i);
				if nodeOldClass then
					sClass = DB.getValue(nodeOldClass, "name", "");
					nLevel = DB.getValue(nodeOldClass, "level", 0);
					
					table.insert(aClasses, sClass);
					
					if (sClass ~= "") or (nLevel ~= 0) then
						local nodeNewClass = nodeClassList.createChild();
						if nodeNewClass then
							DB.setValue(nodeNewClass, "name", "string", sClass);
							DB.setValue(nodeNewClass, "level", "number", nLevel);
						end
					end

					nodeOldClass.delete();
				end
			end
		end
		
		for _,nodeSkill in pairs(DB.getChildren(nodeChar, "skilllist")) do
			local aLabelWords = StringManager.parseWords(DB.getValue(nodeSkill, "label", ""));
			for i = 1, #aLabelWords do
				if aLabelWords[i] ~= "" and aLabelWords[i] ~= "of" then
					aLabelWords[i] = StringManager.capitalize(aLabelWords[i]);
				end
			end
			DB.setValue(nodeSkill, "label", "string", table.concat(aLabelWords, " "));
		end
		
		for _,nodeWeapon in pairs(DB.getChildren(nodeChar, "weaponlist")) do
			local nodeCritRng = nodeWeapon.getChild("critrange");
			if nodeCritRng then
				local sCritRng = nodeCritRng.getValue();
				
				local nDash = string.find(sCritRng, "-");
				if nDash then
					sCritRng = string.sub(sCritRng, 1, nDash - 1);
				end
				local nCritThreshold = tonumber(sCritRng) or 20;
				
				DB.setValue(nodeWeapon, "critatkrange", "number", nCritThreshold);
				
				nodeCritRng.delete();
			end
			
			local nodeCritMult = nodeWeapon.getChild("critmultiplier");
			if nodeCritMult then
				local sCritMult = nodeCritMult.getValue();
				
				local nCritMult = 2;
				local sCritMultNum = string.match(sCritMult, "%d+");
				if sCritMultNum then
					nCritMult = tonumber(sCritMultNum) or 0;
					if nCritMult < 2 then
						nCritMult = 2;
					end
				end
				
				DB.setValue(nodeWeapon, "critdmgmult", "number", nCritMult);
			
				nodeCritMult.delete();
			end
		end
		
		local nodeSpellClassList = nodeChar.getChild("spellset");
		if nodeSpellClassList then
			local nodeSpellClass, nodeNewSpellClass;
			
			for i = 1, 3 do
				nodeSpellClass = nodeSpellClassList.getChild("set" .. i);
				if nodeSpellClass then
					nodeNewSpellClass = nodeSpellClassList.createChild();
					if nodeNewSpellClass then
						DB.copyNode(nodeSpellClass, nodeNewSpellClass);
						
						local sCasterType = "";
						local nodeSpontaneous = nodeNewSpellClass.getChild("spontaneous");
						if nodeSpontaneous then
							local nSpontaneous = nodeSpontaneous.getValue();
							if nSpontaneous == 1 then
								sCasterType = "spontaneous";
							end
							
							nodeSpontaneous.delete();
						end
						DB.setValue(nodeNewSpellClass, "castertype", "string", sCasterType);
						
						if aClasses[i] then
							DB.setValue(nodeNewSpellClass, "label", "string", aClasses[i]);
						end

						nodeSpellClass.delete();
					end
				end
			end
		end
	end  -- END CHARACTER LOOP
end

function convertCT(nodeRoot)
	local nodeCT = nodeRoot.getChild("combattracker");
	if not nodeCT then
		return;
	end
	
	-- REMOVE OLD GROUPS (3.5E)
	local aCTChildren = nodeCT.getChildren();
	for _,nodeGroup in pairs(aCTChildren) do
		-- EXISTENCE OF ENTRIES LIST INDICATES OLD 3.5E GROUP FORMAT
		for _,nodeEntry in pairs(DB.getChildren(nodeGroup, "entries")) do
			local nodeNewEntry = nodeCT.createChild();
			if nodeNewEntry then
				DB.copyNode(nodeEntry, nodeNewEntry);
			end
		end
		
		nodeGroup.delete();
	end
	
	-- TRANSLATE INDIVIDUAL ENTRIES
	for _,nodeEntry in pairs(nodeCT.getChildren()) do
		-- TYPE (3.5E)
		local nodeType = nodeEntry.getChild("type");
		if not nodeType then
			local sType = "npc";
			
			local nodeLink = nodeEntry.getChild("link");
			if nodeLink then
				local sClass, sRecord = nodeLink.getValue();
				if sRecord and string.match(sRecord, "^charsheet%.") then
					sType = "pc";
				end
			end
			
			DB.setValue(nodeEntry, "type", "string", sType);
			
			if sType == "npc" then
				DB.setValue(nodeEntry, "show_npc", "number", 1);
			end
		end
		
		-- AC (BOTH)
		local nodeAC = nodeEntry.getChild("ac");
		if nodeAC then
			local sAC = nodeAC.getValue();
			DB.setValue(nodeEntry, "ac_final", "number", tonumber(string.match(sAC, "^(%d+)")) or 10);
			DB.setValue(nodeEntry, "ac_touch", "number", tonumber(string.match(sAC, "touch (%d+)")) or 10);
			local sFlatFooted = string.match(sAC, "flat[%-–]footed (%d+)");
			if not sFlatFooted then
				sFlatFooted = string.match(sAC, "flatfooted (%d+)");
			end
			DB.setValue(nodeEntry, "ac_flatfooted", "number", tonumber(sFlatFooted) or 10);
			
			nodeAC.delete();
		end
		
		-- ATTACK / FULL ATTACK (BOTH)
		local nodeAttacks = nodeEntry.createChild("attacks");
		if nodeAttacks then
			local nodeAtk = nodeEntry.getChild("atk");
			if nodeAtk then
				local nodeNewAtk = nodeAttacks.createChild();
				if nodeNewAtk then
					DB.setValue(nodeNewAtk, "value", "string", nodeAtk.getValue());
					
					nodeAtk.delete();
				end
			end
			local nodeFullAtk = nodeEntry.getChild("fullatk");
			if nodeFullAtk then
				local nodeNewAtk = nodeAttacks.createChild();
				if nodeNewAtk then
					DB.setValue(nodeNewAtk, "value", "string", nodeFullAtk.getValue());
					
					nodeFullAtk.delete();
				end
			end
		end
		
		-- TOKEN (3.5E)
		local nodeOldTokenRefId = nodeEntry.getChild("token_refid");
		if nodeOldTokenRefId then
			DB.setValue(nodeEntry, "tokenrefid", "string", nodeOldTokenRefId.getValue());
			nodeOldTokenRefId.delete();
		end
		local nodeOldTokenRefNode = nodeEntry.getChild("token_refnode");
		if nodeOldTokenRefNode then
			DB.setValue(nodeEntry, "tokenrefnode", "string", nodeOldTokenRefNode.getValue());
			nodeOldTokenRefNode.delete();
		end
		local nodeOldTokenRefScale = nodeEntry.getChild("token_scale");
		if nodeOldTokenRefScale then
			DB.setValue(nodeEntry, "tokenscale", "number", nodeOldTokenRefScale.getValue());
			nodeOldTokenRefScale.delete();
		end
	end
end

function convertEncounters(nodeRoot)
	local nodeCombat = nodeRoot.getChild("combat");
	local nodeBattle = nodeRoot.createChild("battle");
	if not nodeCombat or not nodeBattle then
		return;
	end
	
	for _,nodeOldEnc in pairs(nodeCombat.getChildren()) do
		local nodeNewEnc = nodeBattle.createChild();
		if nodeNewEnc then
			DB.setValue(nodeNewEnc, "name", "string", DB.getValue(nodeOldEnc, "name", ""));
		
			local nodeNewActors = nodeNewEnc.createChild("npclist");
			if nodeNewActors then
				for _,nodeOldActor in pairs(DB.getChildren(nodeOldEnc, "actors")) do
					local nodeNewActor = nodeNewActors.createChild();
					if nodeNewActor then
						DB.setValue(nodeNewActor, "name", "string", DB.getValue(nodeOldActor, "name", ""));
						DB.setValue(nodeNewActor, "token", "token", DB.getValue(nodeOldActor, "token", ""));
					end
				end
			end
		end
	end
	
	nodeCombat.delete();
end

function convertOptions(nodeRoot)
	local nodeOptions = nodeRoot.getChild("options");
	if not nodeOptions then
		return;
	end
	
	local sOptionINIT = DB.getValue(nodeOptions, "INIT", "");
	if DB.getValue(nodeOptions, "INIT", "") == "all" then
		DB.setValue(nodeOptions, "INIT", "string", "on");
	end
end