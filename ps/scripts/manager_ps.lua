-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aFieldMap = {};

function onInit()
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		linkPCFields(v);
	end

	DB.addHandler("partysheet.*.name", "onUpdate", updateName);
end

function mapChartoPS(nodeChar)
	if not nodeChar then
		return nil;
	end
	local sChar = nodeChar.getNodeName();

	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sChar then
			return v;
		end
	end
	
	return nil;
end

function addChar(nodeChar)
	if not nodeChar then
		return;
	end
	local nodePS = mapChartoPS(nodeChar)
	if nodePS then
		return;
	end
	
	nodePS = DB.createNode("partysheet.partyinformation").createChild();
	DB.setValue(nodePS, "link", "windowreference", "charsheet", nodeChar.getNodeName());
	linkPCFields(nodePS);
end

function onCharDelete(nodeChar)
	local nodePS = mapChartoPS(nodeChar);
	if nodePS then
		nodePS.delete();
	end
end

function onLinkUpdated(nodeField)
	DB.setValue(aFieldMap[nodeField.getNodeName()], nodeField.getType(), nodeField.getValue());
end

function onLinkDeleted(nodeField)
	aFieldMap[nodeField.getNodeName()] = nil;
end

function linkPCField(nodeChar, nodePS, sField, sType, sPSField)
	if not sPSField then
		sPSField = sField;
	end

	local nodeField = nodeChar.createChild(sField, sType);
	nodeField.onUpdate = onLinkUpdated;
	nodeField.onDelete = onLinkDeleted;
	
	aFieldMap[nodeField.getNodeName()] = nodePS.getNodeName() .. "." .. sPSField;
	onLinkUpdated(nodeField);
end

function linkPCClasses(nodeClass)
	local nodePS = mapChartoPS(nodeClass.getParent());
	if not nodePS then
		return;
	end

	DB.setValue(nodePS, "class", "string", CharManager.getClassLevelSummary(nodeClass.getParent()));
end

function linkPCLanguages(nodeLanguages)
	local nodePS = mapChartoPS(nodeLanguages.getParent());
	if not nodePS then
		return;
	end
	
	local aLanguages = {};
	
	for _,v in pairs(nodeLanguages.getChildren()) do
		local sName = DB.getValue(v, "name", "");
		if sName ~= "" then
			table.insert(aLanguages, sName);
		end
	end
	table.sort(aLanguages);
	
	local sLanguages = table.concat(aLanguages, ", ");
	DB.setValue(nodePS, "languages", "string", sLanguages);
end

function linkPCSkill(nodeSkill, nodePS, sPSField)
	local nodeField = nodeSkill.getChild("total");
	if not nodeField then
		return;
	end
	
	local sFullField = nodeField.getNodeName();
	local sFullPSField = nodePS.getNodeName() .. "." .. sPSField;
	if aFieldMap[sFullField] == sFullPSField then
		return;
	end
	
	nodeField.onUpdate = onLinkUpdated;
	nodeField.onDelete = onLinkDeleted;
	aFieldMap[sFullField] = sFullPSField;
	onLinkUpdated(nodeField);
end

function linkPCSkills(nodeSkills)
	local nodePS = mapChartoPS(nodeSkills.getParent());
	if not nodePS then
		return;
	end
	
	for _,v in pairs(nodeSkills.getChildren()) do
		local sLabel = DB.getValue(v, "label", ""):lower();

		if sLabel == "spot" then
			linkPCSkill(v, nodePS, "spot");
		elseif sLabel == "listen" then
			linkPCSkill(v, nodePS, "listen");
		elseif sLabel == "search" then
			linkPCSkill(v, nodePS, "search");
		elseif sLabel == "notice" then
			linkPCSkill(v, nodePS, "notice");
		elseif sLabel == "sense motive" then
			linkPCSkill(v, nodePS, "sensemotive");
		
		elseif sLabel == "knowledge" then
			local sSubLabel = DB.getValue(v, "sublabel", ""):lower();
			
			if sSubLabel == "arcana" then
				linkPCSkill(v, nodePS, "arcana");
			elseif sSubLabel == "dungeoneering" then
				linkPCSkill(v, nodePS, "dungeoneering");
			elseif sSubLabel == "local" then
				linkPCSkill(v, nodePS, "klocal");
			elseif sSubLabel == "nature" then
				linkPCSkill(v, nodePS, "nature");
			elseif sSubLabel == "planes" or sSubLabel == "the planes" then
				linkPCSkill(v, nodePS, "planes");
			elseif sSubLabel == "religion" then
				linkPCSkill(v, nodePS, "religion");
			end
		elseif sLabel:sub(1,9) == "knowledge" then
			local sSubLabel = sLabel:sub(10):match("%w[%w%s]*%w");

			if sSubLabel == "arcana" then
				linkPCSkill(v, nodePS, "arcana");
			elseif sSubLabel == "dungeoneering" then
				linkPCSkill(v, nodePS, "dungeoneering");
			elseif sSubLabel == "local" then
				linkPCSkill(v, nodePS, "klocal");
			elseif sSubLabel == "nature" then
				linkPCSkill(v, nodePS, "nature");
			elseif sSubLabel == "planes" or sSubLabel == "the planes" then
				linkPCSkill(v, nodePS, "planes");
			elseif sSubLabel == "religion" then
				linkPCSkill(v, nodePS, "religion");
			end
		
		elseif sLabel == "bluff" then
			linkPCSkill(v, nodePS, "bluff");
		elseif sLabel == "diplomacy" then
			linkPCSkill(v, nodePS, "diplomacy");
		elseif sLabel == "gather information" then
			linkPCSkill(v, nodePS, "gatherinfo");
		elseif sLabel == "intimidate" then
			linkPCSkill(v, nodePS, "intimidate");
		
		elseif sLabel == "acrobatics" then
			linkPCSkill(v, nodePS, "acrobatics");
		elseif sLabel == "climb" then
			linkPCSkill(v, nodePS, "climb");
		elseif sLabel == "heal" then
			linkPCSkill(v, nodePS, "heal");
		elseif sLabel == "jump" then
			linkPCSkill(v, nodePS, "jump");
		elseif sLabel == "survival" then
			linkPCSkill(v, nodePS, "survival");
		
		elseif sLabel == "hide" then
			linkPCSkill(v, nodePS, "hide");
		elseif sLabel == "move silently" then
			linkPCSkill(v, nodePS, "movesilent");
		elseif sLabel == "stealth" then
			linkPCSkill(v, nodePS, "stealth");
		end
	end
end

function linkPCFields(nodePS)
	local sClass, sRecord = DB.getValue(nodePS, "link", "", "");
	if sRecord == "" then
		return;
	end
	local nodeChar = DB.findNode(sRecord);
	if not nodeChar then
		return;
	end
	
	nodeChar.onDelete = onCharDelete;
	
	linkPCField(nodeChar, nodePS, "name", "string");
	linkPCField(nodeChar, nodePS, "combattoken", "token", "token");

	linkPCField(nodeChar, nodePS, "race", "string");
	linkPCField(nodeChar, nodePS, "level", "number");
	linkPCField(nodeChar, nodePS, "exp", "number");
	linkPCField(nodeChar, nodePS, "expneeded", "number");

	linkPCField(nodeChar, nodePS, "senses", "string");
	
	linkPCField(nodeChar, nodePS, "hp.total", "number", "hptotal");
	linkPCField(nodeChar, nodePS, "hp.temporary", "number", "hptemp");
	linkPCField(nodeChar, nodePS, "hp.wounds", "number", "wounds");
	linkPCField(nodeChar, nodePS, "hp.nonlethal", "number", "nonlethal");
	
	linkPCField(nodeChar, nodePS, "abilities.strength.score", "number", "strength");
	linkPCField(nodeChar, nodePS, "abilities.constitution.score", "number", "constitution");
	linkPCField(nodeChar, nodePS, "abilities.dexterity.score", "number", "dexterity");
	linkPCField(nodeChar, nodePS, "abilities.intelligence.score", "number", "intelligence");
	linkPCField(nodeChar, nodePS, "abilities.wisdom.score", "number", "wisdom");
	linkPCField(nodeChar, nodePS, "abilities.charisma.score", "number", "charisma");

	linkPCField(nodeChar, nodePS, "abilities.strength.bonus", "number", "strcheck");
	linkPCField(nodeChar, nodePS, "abilities.constitution.bonus", "number", "concheck");
	linkPCField(nodeChar, nodePS, "abilities.dexterity.bonus", "number", "dexcheck");
	linkPCField(nodeChar, nodePS, "abilities.intelligence.bonus", "number", "intcheck");
	linkPCField(nodeChar, nodePS, "abilities.wisdom.bonus", "number", "wischeck");
	linkPCField(nodeChar, nodePS, "abilities.charisma.bonus", "number", "chacheck");

	linkPCField(nodeChar, nodePS, "ac.totals.general", "number", "ac");
	linkPCField(nodeChar, nodePS, "ac.totals.flatfooted", "number", "flatfootedac");
	linkPCField(nodeChar, nodePS, "ac.totals.touch", "number", "touchac");
	linkPCField(nodeChar, nodePS, "ac.totals.cmd", "number", "cmd");
	
	linkPCField(nodeChar, nodePS, "saves.fortitude.total", "number", "fortitude");
	linkPCField(nodeChar, nodePS, "saves.reflex.total", "number", "reflex");
	linkPCField(nodeChar, nodePS, "saves.will.total", "number", "will");
	
	linkPCField(nodeChar, nodePS, "defenses.damagereduction", "string", "dr");
	linkPCField(nodeChar, nodePS, "defenses.sr.total", "number", "sr");
	
	local nodeClass = nodeChar.createChild("classes");
	if nodeClass then
		nodeClass.onChildUpdate = linkPCClasses;
		linkPCClasses(nodeClass);
	end

	local nodeSkills = nodeChar.createChild("skilllist");
	if nodeSkills then
		nodeSkills.onChildUpdate = linkPCSkills;
		linkPCSkills(nodeSkills);
	end

	local nodeLanguages = nodeChar.createChild("languagelist");
	if nodeLanguages then
		nodeLanguages.onChildUpdate = linkPCLanguages;
		linkPCLanguages(nodeLanguages);
	end
end

function getNodeFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	local sContainerNode = nodeContainer.getNodeName();
	
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sChildContainerName = DB.getValue(v, "tokenrefnode", "");
		local nChildId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sChildContainerName == sContainerNode) and (nChildId == nId) then
			return v;
		end
	end
	return nil;
end

function getNodeFromToken(token)
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getNodeFromTokenRef(nodeContainer, nID);
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
	
	if newTokenInstance then
		newTokenInstance.setTargetable(false);
		newTokenInstance.setActivable(true);
		newTokenInstance.setActive(false);
		newTokenInstance.setVisible(true);

		newTokenInstance.setName(DB.getValue(nodeEntry, "name", ""));
	end

	return true;
end

function updateName(nodeName)
	local nodeEntry = nodeName.getParent();
	local tokeninstance = Token.getToken(DB.getValue(nodeEntry, "tokenrefnode", ""), DB.getValue(nodeEntry, "tokenrefid", ""));
	if tokeninstance then
		tokeninstance.setName(DB.getValue(nodeEntry, "name", ""));
	end
end
