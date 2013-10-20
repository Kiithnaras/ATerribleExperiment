-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Update the wound and status displays
	onActiveChanged();
	onFactionChanged();
	onTypeChanged();
	onWoundsChanged();
	
	-- Track the effects list
	local node = getDatabaseNode();
	local node_list_effects = node.createChild("effects");
	if node_list_effects then
		node_list_effects.onChildUpdate = onEffectsChanged;
		node_list_effects.onChildAdded = onEffectsChanged;
	elseif node then
		node.onChildAdded = onCTEntryChildAdded;
	end
	onEffectsChanged();
end

function onCTEntryChildAdded(source, child)
	if child.getName() == "effects" then
		source.onChildAdded = function () end;
		
		child.onChildUpdate = onEffectsChanged;
		child.onChildAdded = onEffectsChanged;
	end
end

function updateDisplay()
	if active.getValue() == 1 then
		name.setFont("ct_active");

		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		local sFaction = friendfoe.getValue();
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end
		
		windowlist.scrollToWindow(self);
	else
		name.setFont("ct_name");

		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		local sFaction = friendfoe.getValue();
		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

function onActiveChanged()
	-- Update the active icon
	active_icon.setVisible(active.getValue() ~= 0);
	
	-- Update the display
	updateDisplay();
end

function onFactionChanged()
	-- Update the faction icon
	friendfoe_icon.updateIcon(friendfoe.getValue());
	
	-- Update what fields are visible for health display
	updateHealthDisplay();
	
	-- Update the display
	updateDisplay();
end

function onTypeChanged()
	-- Update what fields are visible for health display
	updateHealthDisplay();
end

function onWoundsChanged()
	local sColor = ActorManager.getWoundColor("ct", getDatabaseNode());
	
	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
	status.setColor(sColor);
end

function onEffectsChanged()
	-- Rebuild the effects list
	local affectedby = EffectsManager.getEffectsString(getDatabaseNode());
	
	-- Update the effects line in the client combat tracker
	if affectedby == "" then
		effects_label.setVisible(false);
		effects_str.setVisible(false);
	else
		effects_label.setVisible(true);
		effects_str.setVisible(true);
	end
	effects_str.setValue(affectedby);
end

function updateHealthDisplay()
	local sOption = OptionsManager.getOption("SHPH");
	
	local bShowHealth = false;
	if sOption == "all" then
		bShowHealth = true;
	elseif sOption == "pc" then
		if friendfoe.getValue() == "friend" then
			bShowHealth = true;
		end
	end
	
	if bShowHealth then
		hp.setVisible(true);
		hptemp.setVisible(true);
		nonlethal.setVisible(true);
		wounds.setVisible(true);

		status.setVisible(false);
	else
		hp.setVisible(false);
		hptemp.setVisible(false);
		nonlethal.setVisible(false);
		wounds.setVisible(false);

		status.setVisible(true);
	end
end
