-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local effectson = false;

function onInit()
	-- Set the displays to what should be shown
	setActiveVisible();
	setDefensiveVisible();
	setSpacingVisible();
	setEffectsVisible();

	-- Acquire token reference, if any
	linkToken();
	
	-- Set up the PC links
	onLinkChanged();
	
	-- Update the displays
	onFactionChanged();
	onHealthChanged();
	
	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

	-- Track the effects list
	DB.addHandler(getDatabaseNode().getNodeName() .. ".effects", "onChildUpdate", onEffectsChanged);
	onEffectsChanged();
	
	local bPFMode = DataCommon.isPFRPG();
	if bPFMode then
		label_grapple.setValue(Interface.getString("cmb"));
	else
		label_grapple.setValue(Interface.getString("grp"));
	end
end

function onClose()
	DB.removeHandler(getDatabaseNode().getNodeName() .. ".effects", "onChildUpdate", onEffectsChanged);
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();

	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
		name.setFont("sheetlabel");
		
		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end
	else
		name.setFont("sheettext");
		
		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
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

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		TokenManager.linkToken(getDatabaseNode(), imageinstance);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
end

function delete()
	local node = getDatabaseNode();
	if not node then
		close();
		return;
	end
	
	-- Remember node name
	local sNode = node.getNodeName();
	
	-- Clear any effects and wounds first, so that saves aren't triggered when initiative advanced
	effects.reset(false);
	wounds.setValue(0);
	
	-- Move to the next actor, if this CT entry is active
	if DB.getValue(node, "active", 0) == 1 then
		CombatManager.nextActor();
	end

	-- If this is an NPC with a token on the map, then remove the token also
	local sClass, sRecord = link.getValue();
	if sClass ~= "charsheet" then
		token.deleteReference();
	end

	-- Delete the database node and close the window
	node.delete();

	-- Update list information (global subsection toggles)
	windowlist.onVisibilityToggle();
	windowlist.onEntrySectionToggle();
end

function onLinkChanged()
	-- If a PC, then set up the links to the char sheet
	local sClass, sRecord = link.getValue();
	if sClass == "charsheet" then
		linkPCFields();
		name.setLine(false);
	end
end

function onHealthChanged()
	local sColor, nPercentWounded, nPercentNonlethal, sStatus = ActorManager2.getWoundColor("ct", getDatabaseNode());
	
	wounds.setColor(sColor);
	nonlethal.setColor(sColor);
	status.setValue(sStatus);
	
	local sClass,_ = link.getValue();
	if sClass ~= "charsheet" then
		idelete.setVisible((nPercentNonlethal > 1));
	end
end

function onFactionChanged()
	-- Update the entry frame
	updateDisplay();

	-- If not a friend, then show visibility toggle
	if friendfoe.getStringValue() == "friend" then
		tokenvis.setVisible(false);
	else
		tokenvis.setVisible(true);
	end
end

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode());
	windowlist.onVisibilityToggle();
end

function onEffectsChanged()
	local affectedby = EffectManager.getEffectsString(getDatabaseNode());
	effects_str.setValue(affectedby);
	
	if affectedby == "" or effectson then
		effects_label.setVisible(false);
		effects_str.setVisible(false);
	else
		effects_label.setVisible(true);
		effects_str.setVisible(true);
	end
end

function onActiveChanged()
	setActiveVisible();
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(nodeChar.createChild("name", "string"), true);

		hp.setLink(nodeChar.createChild("hp.total", "number"));
		hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
		nonlethal.setLink(nodeChar.createChild("hp.nonlethal", "number"));
		wounds.setLink(nodeChar.createChild("hp.wounds", "number"));

		grapple.setLink(nodeChar.createChild("attackbonus.grapple.total", "number"), true);
		
		ac_final.setLink(nodeChar.createChild("ac.totals.general", "number"), true);
		ac_touch.setLink(nodeChar.createChild("ac.totals.touch", "number"), true);
		ac_flatfooted.setLink(nodeChar.createChild("ac.totals.flatfooted", "number"), true);
		cmd.setLink(nodeChar.createChild("ac.totals.cmd", "number"), true);
		
		fortitudesave.setLink(nodeChar.createChild("saves.fortitude.total", "number"), true);
		reflexsave.setLink(nodeChar.createChild("saves.reflex.total", "number"), true);
		willsave.setLink(nodeChar.createChild("saves.will.total", "number"), true);
		
		sr.setLink(nodeChar.createChild("defenses.sr.total", "number"), true);

		init.setLink(nodeChar.createChild("initiative.total", "number"), true);
	end
end

--
-- SECTION VISIBILITY FUNCTIONS
--

function setActiveVisible()
	local v = false;
	if activateactive.getValue() == 1 then
		v = true;
	end
	local sClass, sRecord = link.getValue();
	if sClass ~= "charsheet" and active.getValue() == 1 then
		v = true;
	end
	
	activeicon.setVisible(v);

	attacks.setVisible(v);
	if v and not attacks.getNextWindow(nil) then
		attacks.createWindow();
	end
	atklabel.setVisible(v);
	immediate.setVisible(v);
	immediatelabel.setVisible(v);
	init.setVisible(v);
	initlabel.setVisible(v);
	grapple.setVisible(v);
	label_grapple.setVisible(v);
	speed.setVisible(v);
	speedlabel.setVisible(v);
	
	frame_active.setVisible(v);
end

function setDefensiveVisible()
	local v = false;
	if activatedefensive.getValue() == 1 then
		v = true;
	end
	
	local bPFMode = DataCommon.isPFRPG();
	
	defensiveicon.setVisible(v);

	ac_final.setVisible(v);
	ac_final_label.setVisible(v);
	ac_touch.setVisible(v);
	ac_touch_label.setVisible(v);
	ac_flatfooted.setVisible(v);
	ac_ff_label.setVisible(v);
	
	cmd.setVisible(v and bPFMode);
	cmd_label.setVisible(v and bPFMode);

	fortitudesave.setVisible(v);
	fortitudelabel.setVisible(v);
	reflexsave.setVisible(v);
	reflexlabel.setVisible(v);
	willsave.setVisible(v);
	willlabel.setVisible(v);
	sr.setVisible(v);
	sr_label.setVisible(v);

	specialdef.setVisible(v);
	specialdeflabel.setVisible(v);
	
	frame_defensive.setVisible(v);
end
	
function setSpacingVisible()
	local v = false;
	if activatespacing.getValue() == 1 then
		v = true;
	end

	spacingicon.setVisible(v);
	
	space.setVisible(v);
	spacelabel.setVisible(v);
	reach.setVisible(v);
	reachlabel.setVisible(v);
	
	frame_spacing.setVisible(v);
end

function setEffectsVisible()
	local v = false;
	if activateeffects.getValue() == 1 then
		v = true;
	end
	
	effectson = v;
	effecticon.setVisible(v);
	
	effects.setVisible(v);
	effects_iadd.setVisible(v);

	frame_effects.setVisible(v);

	onEffectsChanged();
end
