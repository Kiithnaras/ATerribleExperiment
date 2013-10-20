-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bShow = true;

function setFilter(bFilter)
	bShow = bFilter;
end

function getFilter()
	return bShow;
end

function onInit()
	if not windowlist.isReadOnly() then
		registerMenuItem("Delete Spell", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);

		registerMenuItem("Add Spell Action", "pointer", 3);
		registerMenuItem("Add Cast", "radial_sword", 3, 2);
		registerMenuItem("Add Damage", "radial_damage", 3, 3);
		registerMenuItem("Add Heal", "radial_heal", 3, 4);
		registerMenuItem("Add Effect", "radial_effect", 3, 5);
		
		registerMenuItem("Reparse spell actions", "textlist", 4);
	end

	-- Check to see if we should automatically parse spell description
	local nodeSpell = getDatabaseNode();
	local nParse = DB.getValue(nodeSpell, "parse", 0);
	if nParse ~= 0 then
		DB.setValue(nodeSpell, "parse", "number", 0);
		SpellsManager.parseSpell(nodeSpell);
	end
end

function getActorType()
	return windowlist.window.getActorType();
end	

function onHover(bOver)
	if minisheet then
		if bOver then
			setFrame("rowshade");
		else
			setFrame(nil);
		end
	end
end

function createAction(sType)
	local nodeSpell = getDatabaseNode();
	if nodeSpell then
		local nodeActions = nodeSpell.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.createChild();
			if nodeAction then
				DB.setValue(nodeAction, "type", "string", sType);
			end
		end
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		getDatabaseNode().delete();
	elseif selection == 4 then
		SpellsManager.parseSpell(getDatabaseNode());
		activateactions.setValue(true);
	elseif selection == 3 then
		if subselection == 2 then
			createAction("cast");
			activateactions.setValue(true);
		elseif subselection == 3 then
			createAction("damage");
			activateactions.setValue(true);
		elseif subselection == 4 then
			createAction("heal");
			activateactions.setValue(true);
		elseif subselection == 5 then
			createAction("effect");
			activateactions.setValue(true);
		end
	end
end

function onSpellCounterUpdate()
	windowlist.window.onSpellCounterUpdate();
end

function setSpacerState()
	if activateactions.getValue() then
		spacer.setVisible(true);
	else
		spacer.setVisible(false);
	end
end

function toggleActions()
	if minisheet then
		return;
	end
	
	local status = activateactions.getValue();
	actions.setVisible(status);
	
	for k, v in pairs(actions.getWindows()) do
		v.updateDisplay();
	end
	
	setSpacerState();
end

function getDescription()
	local nodeSpell = getDatabaseNode();
	
	local sShort = DB.getValue(nodeSpell, "shortdescription", "");
	if sShort == "" then
		return DB.getValue(nodeSpell, "name", "");
	end

	return DB.getValue(nodeSpell, "name", "") .. " - " .. sShort;
end

function activatePower()
	local nodeSpell = getDatabaseNode();

	if nodeSpell then
		ChatManager.Message(getDescription(), true, ActorManager.getActor("pc", nodeSpell.getChild(".......")));
	end
end

function usePower()
	local nodeSpell = getDatabaseNode();
	local nodeSpellClass = nodeSpell.getChild(".....");

	local sCasterType = DB.getValue(nodeSpellClass, "castertype", "");
	if sCasterType == "points" then
		local nPP = DB.getValue(nodeSpell, ".....points", 0);
		local nPPUsed = DB.getValue(nodeSpell, ".....pointsused", 0);
		local nCost = DB.getValue(nodeSpell, "cost", 0);
		
		local sMessage = DB.getValue(nodeSpell, "name", "") .. " [" .. nCost .. " PP]";
		if (nPP - nPPUsed) < nCost then
			sMessage = sMessage .. " [INSUFFICIENT PP AVAILABLE]";
		else
			nPPUsed = nPPUsed + nCost;
			DB.setValue(nodeSpell, ".....pointsused", "number", nPPUsed);
		end
		ChatManager.Message(sMessage, true, ActorManager.getActor("pc", nodeSpell.getChild(".......")));
	elseif OptionsManager.isOption("SYSTEM", "pf") then
		local sName = DB.getValue(nodeSpell, "name", "");
		ChatManager.Message(sName, true, ActorManager.getActor("pc", nodeSpell.getChild(".......")));
	end
end
