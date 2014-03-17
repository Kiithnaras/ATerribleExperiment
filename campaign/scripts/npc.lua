-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local sNode = getDatabaseNode().getNodeName();
	for _,v in pairs(DataCommon.abilities) do
		DB.addHandler(sNode .. "." .. v, "onUpdate", updateAbility);
	end
	DB.addHandler(sNode .. ".locked", "onUpdate", onLockChanged);

	TypeChanged();
	updateAbility();
	onLockChanged();
end

function onClose()
	local sNode = getDatabaseNode().getNodeName();
	for _,v in pairs(DataCommon.abilities) do
		DB.removeHandler(sNode .. "." .. v, "onUpdate", updateAbility);
	end
	DB.removeHandler(sNode .. ".locked", "onUpdate", onLockChanged);
end

function onModeChanged()
	for _,vClass in pairs(spellclasslist.getWindows()) do
		vClass.onSpellCounterUpdate();
	end
end

function TypeChanged()
	local sType = DB.getValue(getDatabaseNode(), "npctype", "");
	
	if sType == "Trap" then
		tabs.setTab(1, "main_trap", "tab_main");
	elseif sType == "Vehicle" then
		tabs.setTab(1, "main_vehicle", "tab_main");
	else
		tabs.setTab(1, "main_creature", "tab_main");
	end
end

function onLockChanged()
	StateChanged();
end

function updateControl(sControl, bReadOnly)
	if not self[sControl] then
		return false;
	end
		
	return self[sControl].update(bReadOnly);
end

function StateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main_trap.subwindow then
		main_trap.subwindow.update();
	end
	if main_vehicle.subwindow then
		main_vehicle.subwindow.update();
	end
	if main_creature.subwindow then
		main_creature.subwindow.update();
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	npctype.setReadOnly(bReadOnly);
	text.setReadOnly(bReadOnly);
	
	if bReadOnly then
		tabs.setTab(2, "spellclasslist_mini", "tab_spells");
	else
		tabs.setTab(2, "spellclasslist", "tab_spells");
	end
end

function updateAbility()
	for _,v in pairs(spellclasslist.getWindows()) do
		v.onStatUpdate();
	end
end

function addSpellClass()
	local w = spellclasslist.createWindow();
	if w then
		w.activatedetail.setValue(1);
		w.label.setFocus();
		DB.setValue(getDatabaseNode(), "spellmode", "string", "standard");
	end
end

function onSpellDrop(x, y, draginfo)
	if draginfo.isType("spellmove") then
		ChatManager.Message(Interface.getString("spell_error_dropclassmissing"));
		return true;
	elseif draginfo.isType("spelldescwithlevel") then
		ChatManager.Message(Interface.getString("spell_error_dropclassmissing"));
		return true;
	elseif draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		
		if sClass == "spelldesc" or sClass == "spelldesc2" then
			ChatManager.Message(Interface.getString("spell_error_dropclasslevelmissing"));
			return true;
		end
	end
end

function getEditMode()
	return (spellclasslist_iedit.getValue() == 1);
end
