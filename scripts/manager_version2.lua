-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rsname = "3.5E";

function onInit()
	if User.isHost() then
		updateDatabase();
	end
end

function updateDatabase()
	local _, _, aMajor, aMinor = DB.getRulesetVersion();
	local major = aMajor[rsname];
	if not major then
		return;
	end
	
	if major > 0 and major < 11 then
		print("Migrating campaign database to latest data version.");
		DB.backup();
		
		if major < 8 then
			convertCharacters();
			convertCT();
			convertEncounters();
			convertOptions();
		end
		if major < 9 then
			convertCharacters9();
			convertEncounters9();
			convertOptions9();
		end
		if major < 10 then
			convertLog10();
		end
		if major < 11 then
			convertChar11();
			convertParty11();
			convertParcel11();
			convertCombat11();
			convertSystem11();
			convertRegistry11();
		end
		
		DB.updateVersion();
	end
end

-- Last change in release 11
function checkParcel(nodeRecord)
	local sModule = nodeRecord.getModule();
	if not sModule or sModule == "" then
		return;
	end

	for _,vItem in pairs(DB.getChildren(nodeRecord, "itemlist")) do
		local bMigrate = false;
		if DB.getType(vItem.getNodeName() .. ".description") == "string" then
			bMigrate = true;
		end
		
		if bMigrate then
			convertItemInList11(nodeRecord.getNodeName() .. ".itemlist", vItem);
		end
	end
end

function convertChar11()
	for _,vPC in pairs(DB.getChildren("charsheet")) do
		DB.setValue(vPC, "token", "token", DB.getValue(vPC, "combattoken"));
		DB.deleteChild(vPC, "combattoken");
	end
end

function convertCombat11()
	if DB.findNode("combattracker.list") then
		return;
	end
	
	local aCombatants = DB.getChildren("combattracker");
	local nodeList = DB.createNode("combattracker.list");
	
	for _,vNPC in pairs(aCombatants) do
		local nodeNew = nodeList.createChild();

		-- Get rid of type field
		DB.deleteChild(vNPC, "type");
		
		-- Migrate show_npc to tokenvis
		DB.setValue(vNPC, "tokenvis", "number", DB.getValue(vNPC, "show_npc", 0));
		DB.deleteChild(vNPC, "show_npc");
		
		-- Copy node over to new location
		-- And convert partial to full records
		local sClass, sRecord = DB.getValue(vNPC, "link", "", "");
		if sRecord == "" or sClass == "charsheet" then
			DB.copyNode(vNPC, nodeNew);
			if sClass ~= "charsheet" then
				DB.setValue(nodeNew, "link", "windowreference", "npc", "");
			end
		else
			local nodeRecord = DB.findNode(sRecord);
			if nodeRecord then
				DB.copyNode(nodeRecord, nodeNew);
			end
			DB.copyNode(vNPC, nodeNew);
			DB.setValue(nodeNew, "link", "windowreference", "npc", "");
		end
		
		-- Delete the old record
		vNPC.delete();
	end
	
	-- Migrate round counter to new location
	DB.setValue("combattracker.round", "number", DB.getValue("combattracker_props.round", 0));
	DB.deleteNode("combattracker_props");
end

function convertItemInList11(sListNode, vItem)
	local nCount = DB.getValue(vItem, "amount", 0);

	local nodeNew = nil;
	local sClass, sRecord = DB.getValue(vItem, "shortcut");
	if sClass and sRecord then
		nodeNew = ItemManager.addItemToList(sListNode, sClass, sRecord);
		DB.setValue(nodeNew, "count", "number", nCount);
		if nodeNew then
			vItem.delete();
		end
	end
	if not nodeNew then
		local sName = DB.getValue(vItem, "description", "");
		DB.deleteChild(vItem, "description");
		
		if nCount == 0 and sName == "" then
			vItem.delete();
		else
			DB.setValue(vItem, "name", "string", DB.getValue(vItem, "description", ""));
			DB.deleteChild(vItem, "description");
			DB.setValue(vItem, "count", "number", nCount);
		end
	end
end

function convertParty11()
	for _,vItem in pairs(DB.getChildren("partysheet.treasureparcelitemlist")) do
		convertItemInList11("partysheet.treasureparcelitemlist", vItem);
	end
end

function convertParcel11()
	for _,vParcel in pairs(DB.getChildren("treasureparcels")) do
		for _,vItem in pairs(DB.getChildren(vParcel, "itemlist")) do
			convertItemInList11(vParcel.getNodeName() .. ".itemlist", vItem);
		end
	end
end

function convertSystem11()
	if DB.getValue("options.SYSTEM", "") == "pf" then
		Interface.dialogMessage("Converting campaign to PFRPG ruleset");
		DB.convertCampaign("PFRPG");
	end
	DB.deleteNode("options.SYSTEM");
end

function convertRegistry11()
	CampaignRegistry.windowpositions = nil;
end

function convertLog10()
	local nodeLog = DB.findNode("partysheet.adventurelog");
	if nodeLog then
		local nodeNewLog = DB.createNode("calendar.log");
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

function convertCharacters9()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
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

function convertEncounters9()
	for _,nodeEnc in pairs(DB.getChildren("battle")) do
		migrateEncounter9(nodeEnc);
	end
end

function convertOptions9()
	local nodeOptions = DB.findNode("options");
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

function convertCharacters()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
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

function convertCT()
	local nodeCT = DB.findNode("combattracker");
	if not nodeCT then
		return;
	end
	
	-- REMOVE OLD GROUPS
	local aCTChildren = nodeCT.getChildren();
	for _,nodeGroup in pairs(aCTChildren) do
		if nodeGroup.getChild("entries") then
			-- EXISTENCE OF ENTRIES LIST INDICATES OLD GROUP FORMAT
			for _,nodeEntry in pairs(DB.getChildren(nodeGroup, "entries")) do
				local nodeNewEntry = nodeCT.createChild();
				if nodeNewEntry then
					DB.copyNode(nodeEntry, nodeNewEntry);
				end
			end
			
			nodeGroup.delete();
		end
	end
	
	-- TRANSLATE INDIVIDUAL ENTRIES
	for _,nodeEntry in pairs(nodeCT.getChildren()) do
		-- TYPE
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
		
		-- TOKEN
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

function convertEncounters()
	local nodeCombat = DB.findNode("combat");
	local nodeBattle = DB.createNode("battle");
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

function convertOptions()
	local nodeOptions = DB.findNode("options");
	if not nodeOptions then
		return;
	end
	
	local sOptionINIT = DB.getValue(nodeOptions, "INIT", "");
	if DB.getValue(nodeOptions, "INIT", "") == "all" then
		DB.setValue(nodeOptions, "INIT", "string", "on");
	end
end