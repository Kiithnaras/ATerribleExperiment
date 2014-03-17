-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("menu_addweapon"), "insert", 3);
	registerMenuItem(Interface.getString("menu_addspellclass"), "insert", 5);
	
	local sNode = getDatabaseNode().getNodeName()
	DB.addHandler(sNode .. ".abilities", "onChildUpdate", updateAbility);
	updateAbility();
	
	DB.addHandler(sNode .. ".weaponlist", "onChildUpdate", update);
	DB.addHandler(sNode .. ".spellset", "onChildUpdate", update);
	update();
end

function onClose()
	local sNode = getDatabaseNode().getNodeName()
	DB.removeHandler(sNode .. ".abilities", "onChildUpdate", updateAbility);
	DB.removeHandler(sNode .. ".weaponlist", "onChildUpdate", update);
	DB.removeHandler(sNode .. ".spellset", "onChildUpdate", update);
end

function onMenuSelection(selection)
	if selection == 3 then
		addWeapon();
	elseif selection == 5 then
		addSpellClass();
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

function addWeapon()
	local w = weaponlist.createWindow();
	if w then
		w.name.setFocus();
	end
end

function updateAbility()
	for _,v in pairs(spellclasslist.getWindows()) do
		v.onStatUpdate();
	end
end

function update()
	weaponlist.update();
	spellclasslist.update();
end

function getEditMode()
	return (parentcontrol.window.actions_iedit.getValue() == 1);
end
