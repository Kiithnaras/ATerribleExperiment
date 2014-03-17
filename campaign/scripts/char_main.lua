-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(getDatabaseNode().getNodeName() .. ".classes", "onChildUpdate", onLevelChanged);
	onLevelChanged();

	onSystemChanged();
end

function onClose()
	DB.removeHandler(getDatabaseNode().getNodeName() .. ".classes", "onChildUpdate", onLevelChanged);
end

function onLevelChanged()
	CharManager.calcLevel(getDatabaseNode());
end

function onSystemChanged()
	local bPFMode = DataCommon.isPFRPG();
	
	cmd.setVisible(bPFMode);
	label_cmd.setVisible(bPFMode);
	
	if label_grapple then
		if bPFMode then
			label_grapple.setValue(Interface.getString("cmb"));
		elseif minisheet then
			label_grapple.setValue(Interface.getString("grp"));
		else
			label_grapple.setValue(Interface.getString("grapple"));
		end
	end
	
	spot.setVisible(not bPFMode);
	label_spot.setVisible(not bPFMode);
	listen.setVisible(not bPFMode);
	label_listen.setVisible(not bPFMode);
	search.setVisible(not bPFMode);
	label_search.setVisible(not bPFMode);

	perception.setVisible(bPFMode);
	label_perception.setVisible(bPFMode);
end

function onHealthChanged()
	local sColor = ActorManager2.getWoundColor("pc", getDatabaseNode());
	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
end
