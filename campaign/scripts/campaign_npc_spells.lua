-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("SYSTEM", onModeChanged);

	registerMenuItem("Reset Spells", "lockvisibilityon", 8);

	update();
	
	local sNode = getDatabaseNode().getNodeName();
	for _,v in pairs(DataCommon.abilities) do
		DB.addHandler(sNode .. "." .. v, "onUpdate", updateAbility);
	end
	updateAbility();
end

function onClose()
	OptionsManager.unregisterCallback("SYSTEM", onModeChanged);

	local sNode = getDatabaseNode().getNodeName();
	for _,v in pairs(DataCommon.abilities) do
		DB.removeHandler(sNode .. "." .. v, "onUpdate", updateAbility);
	end
end

function onMenuSelection(selection)
	if selection == 8 then
		SpellsManager.resetSpells(getDatabaseNode());
	end
end

function updateAbility()
	for _,v in pairs(spellclasslist.getWindows()) do
		v.onStatUpdate();
	end
end

function onDrop(x, y, draginfo)
	local bLock = parentcontrol.window.getAccessState();
	if bLock then
		return false;
	end
	
	if draginfo.isType("spellmove") then
		ChatManager.Message("Unable to determine class for moved spell, please drop within a class.");
		return true;
	elseif draginfo.isType("spelldescwithlevel") then
		ChatManager.Message("Unable to determine class for new spell, please drop within a class.");
		return true;
	elseif draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		
		if sClass == "spelldesc" or sClass == "spelldesc2" then
			ChatManager.Message("Unable to determine class or level for new spell, please drop within a class level.");
			return true;
		end
	end
end

function onModeChanged()
	for _,vClass in pairs(spellclasslist.getWindows()) do
		vClass.onSpellCounterUpdate();
	end
end

function onSetVisibleAll(bShow)
	if spellclasslist.isVisible() then
		for _,vClass in pairs(spellclasslist.getWindows()) do
			for _,vLevel in pairs(vClass.levels.getWindows()) do
				vLevel.spells.setVisible(bShow);
			end
		end
	elseif spellclasslist_mini.isVisible() then
		for _,vClass in pairs(spellclasslist_mini.getWindows()) do
			for _,vLevel in pairs(vClass.levels.getWindows()) do
				vLevel.spells.setVisible(bShow);
			end
		end
	end
end

function update()
	local bLock = parentcontrol.window.getAccessState();
	
	spellclasslist.setVisible(not bLock);
	mode_label.setVisible(not bLock);
	spellmode.setVisible(not bLock);
	
	spellclasslist_mini.setVisible(bLock);
end
