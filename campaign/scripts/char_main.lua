-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onLevelChanged();
	DB.addHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", onLevelChanged);

	onSystemChanged();
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "classes"), "onChildUpdate", onLevelChanged);
end

function onLevelChanged()
	CharManager.calcLevel(getDatabaseNode());
end

function onSystemChanged()
	
	cmd.setVisible(true);
	label_cmd.setVisible(true);
	
	if label_grapple then
		label_grapple.setValue(Interface.getString("cmb"));
	end
	
	search.setVisible(true);
	label_search.setVisible(true);
end

function onHealthChanged()
	local sColor = ActorManager2.getWoundColor("pc", getDatabaseNode());
	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
end
