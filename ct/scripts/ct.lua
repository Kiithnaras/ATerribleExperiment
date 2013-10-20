-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

enableglobaltoggle = true;
enablevisibilitytoggle = true;

aHostTargeting = {};

function onInit()
	Interface.onHotkeyActivated = onHotkey;
	
	-- Make sure all the clients can see the combat tracker
	for k,v in ipairs(User.getActiveUsers()) do
		DB.addHolder("combattracker", v);
		DB.addHolder("combattracker_props", v);
	end
	
	-- Create a blank window if one doesn't exist already
	if not getNextWindow(nil) then
		addEntry(true);
	end
	
	-- Register callback for option changes
	OptionsManager.registerCallback("WNDC", onOptionWNDCChanged);
	
	-- Register a menu item to create a CT entry
	registerMenuItem("Create Item", "insert", 5);

	-- Rebuild targeting information
	TargetingManager.rebuildClientTargeting();

	-- Initialize global buttons
	onVisibilityToggle();
	onEntrySectionToggle();
end

function onClose()
	OptionsManager.unregisterCallback("WNDC", onOptionWNDCChanged);
end

function onOptionWNDCChanged()
	for _,v in pairs(getWindows()) do
		v.onWoundsChanged();
	end
end

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	if bFocus and win then
		win.name.setFocus();
	end
	return win;
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true);
	end
end

function onSortCompare(w1, w2)
	return not CTManager.sortfunc(w1.getDatabaseNode(), w2.getDatabaseNode());
end

function onHotkey(draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "combattrackernextactor" then
		CTManager.nextActor();
		return true;
	elseif sDragType == "combattrackernextround" then
		CTManager.nextRound(1);
		return true;
	end
end

function deleteTarget(sNode)
	TargetingManager.removeTargetFromAllEntries("host", sNode);
end

function toggleVisibility()
	if not enablevisibilitytoggle then
		return;
	end
	
	local visibilityon = window.button_global_visibility.getState();
	for k,v in pairs(getWindows()) do
		if visibilityon ~= v.show_npc.getState() then
			v.show_npc.setState(visibilityon);
		end
	end
end

function toggleTargeting()
	if not enableglobaltoggle then
		return;
	end
	
	local targetingon = window.button_global_targeting.getValue();
	for k,v in pairs(getWindows()) do
		if targetingon ~= v.activatetargeting.getValue() then
			v.activatetargeting.setValue(targetingon);
			v.setTargetingVisible(v.activatetargeting.getValue());
		end
	end
end

function toggleActive()
	if not enableglobaltoggle then
		return;
	end
	
	local activeon = window.button_global_active.getValue();
	for k,v in pairs(getWindows()) do
		if activeon ~= v.activateactive.getValue() then
			v.activateactive.setValue(activeon);
			v.setActiveVisible(v.activateactive.getValue());
		end
	end
end

function toggleDefensive()
	if not enableglobaltoggle then
		return;
	end
	
	local defensiveon = window.button_global_defensive.getValue();
	for k,v in pairs(getWindows()) do
		if defensiveon ~= v.activatedefensive.getValue() then
			v.activatedefensive.setValue(defensiveon);
			v.setDefensiveVisible(v.activatedefensive.getValue());
		end
	end
end

function toggleSpacing()
	if not enableglobaltoggle then
		return;
	end
	
	local spacingon = window.button_global_spacing.getValue();
	for k,v in pairs(getWindows()) do
		if spacingon ~= v.activatespacing.getValue() then
			v.activatespacing.setValue(spacingon);
			v.setSpacingVisible(v.activatespacing.getValue());
		end
	end
end

function toggleEffects()
	if not enableglobaltoggle then
		return;
	end
	
	local effectson = window.button_global_effects.getValue();
	for k,v in pairs(getWindows()) do
		if effectson ~= v.activateeffects.getValue() then
			v.activateeffects.setValue(effectson);
			v.setEffectsVisible(v.activateeffects.getValue());
		end
	end
end

function onVisibilityToggle()
	local anyVisible = false;
	for _,v in pairs(getWindows()) do
		if v.friendfoe.getStringValue() ~= "friend" and v.show_npc.getState() then
			anyVisible = true;
		end
	end
	
	enablevisibilitytoggle = false;
	window.button_global_visibility.setState(anyVisible);
	enablevisibilitytoggle = true;
end

function onEntrySectionToggle()
	local anyTargeting = false;
	local anyActive = false;
	local anyDefensive = false;
	local anySpacing = false;
	local anyEffects = false;

	for k,v in pairs(getWindows()) do
		if v.activatetargeting.getValue() then
			anyTargeting = true;
		end
		if v.activatespacing.getValue() then
			anySpacing = true;
		end
		if v.activatedefensive.getValue() then
			anyDefensive = true;
		end
		if v.activateactive.getValue() then
			anyActive = true;
		end
		if v.activateeffects.getValue() then
			anyEffects = true;
		end
	end

	enableglobaltoggle = false;
	window.button_global_targeting.setValue(anyTargeting);
	window.button_global_active.setValue(anyActive);
	window.button_global_defensive.setValue(anyDefensive);
	window.button_global_spacing.setValue(anySpacing);
	window.button_global_effects.setValue(anyEffects);
	enableglobaltoggle = true;
end

function onDrop(x, y, draginfo)
	-- Capture certain drag types meant for the host only
	local sDragType = draginfo.getType();

	-- PC
	if sDragType == "playercharacter" then
		CTManager.addPc(draginfo.getDatabaseNode());
		return true;
	end

	if sDragType == "shortcut" then
		local sClass = draginfo.getShortcutData();

		-- NPC
		if sClass == "npc" then
			CTManager.addNpc(draginfo.getDatabaseNode());
			applySort();
			return true;
		end

		-- ENCOUNTER
		if sClass == "battle" then
			CTManager.addBattle(draginfo.getDatabaseNode());
			applySort();
			return true;
		end
	end

	-- Capture any drops meant for specific CT entries
	local win = getWindowAt(x,y);
	if win then
		local nodeWin = win.getDatabaseNode();
		if nodeWin then
			return CTManager.onDrop("ct", nodeWin.getNodeName(), draginfo);
		end
	end
end
