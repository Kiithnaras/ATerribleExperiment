-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeChar = getDatabaseNode();
	if nodeChar then
		local nodeClass = nodeChar.getChild("classes");
		if nodeClass then
			nodeClass.onChildUpdate = onLevelChanged;
		end
	end
	
	onLevelChanged();

	OptionsManager.registerCallback("SYSTEM", onSystemChanged);
	onSystemChanged();
end

function onClose()
	OptionsManager.unregisterCallback("SYSTEM", onSystemChanged);
end

function onLevelChanged()
	CharManager.calcLevel(getDatabaseNode());
end

function onSystemChanged()
	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");
	
	cmd.setVisible(bPFMode);
	label_cmd.setVisible(bPFMode);
	
	if label_grapple then
		if bPFMode then
			label_grapple.setValue("CMB");
		elseif minisheet then
			label_grapple.setValue("Grp");
		else
			label_grapple.setValue("Grapple");
		end
	end
	
	spot.setVisible(not bPFMode);
	label_spot.setVisible(not bPFMode);
	listen.setVisible(not bPFMode);
	label_listen.setVisible(not bPFMode);
	search.setVisible(bPFMode or not bPFMode);
	label_search.setVisible(bPFMode or not bPFMode);

	notice.setVisible(bPFMode);
	label_notice.setVisible(bPFMode);
end

function onWoundsChanged()
	local sColor = ActorManager.getWoundColor("pc", getDatabaseNode());
	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
end
