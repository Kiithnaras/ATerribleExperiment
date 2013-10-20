-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("SYSTEM", update);

	update();
end

function onClose()
	OptionsManager.unregisterCallback("SYSTEM", update);
end

function updateControl(sControl, bLock, vHideOnValue)
	local bLocalShow = true;
	
	if self[sControl] then
		if bLock then
			self[sControl].setReadOnly(true);
			
			local val = self[sControl].getValue();
			if val == "" or val == vHideOnValue then
				bLocalShow = false;
			end
		else
			self[sControl].setReadOnly(false);
		end
		self[sControl].setVisible(bLocalShow);
	else
		bLocalShow = false;
	end

	if self[sControl .. "_label"] then
		self[sControl .. "_label"].setVisible(bLocalShow);
	end
	
	return bLocalShow;
end

function update()
	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");
	local sType = DB.getValue(getDatabaseNode(), "npctype", "");
	local bLock = parentcontrol.window.getAccessState();

	-- Update labels based on system being played and NPC type
	if babgrp_label then
		if sType == "Vehicle" then
			babgrp_label.setValue("CM");
			babgrp_label.setVisible(bPFMode);
			if babgrp then
				babgrp.setVisible(bPFMode);
			end
		else
			if bPFMode then
				babgrp_label.setValue("BAB / CM");
			else
				babgrp_label.setValue("BAB / Grp");
			end
		end
	end

	updateControl("type", bLock);
	if bPFMode then
		if alignment then
			alignment.setVisible(false);
		end
		if alignment_label then
			alignment_label.setVisible(false);
		end
	else
		updateControl("alignment", bLock);
	end
	updateControl("init", bLock);
	updateControl("cr", bLock, 0);
	if bPFMode then
		updateControl("senses", bLock);
		updateControl("aura", bLock);
	else
		if senses then
			senses.setVisible(false);
		end
		if senses_label then
			senses_label.setVisible(false);
		end
		if aura then
			aura.setVisible(false);
		end
		if aura_label then
			aura_label.setVisible(false);
		end
	end
	
	updateControl("ac", bLock);
	updateControl("hd", bLock);
	updateControl("hp", bLock);
	updateControl("fortitudesave", bLock);
	updateControl("reflexsave", bLock);
	updateControl("willsave", bLock);
	updateControl("specialqualities", bLock);
	
	updateControl("speed", bLock);
	updateControl("atk", bLock);
	updateControl("fullatk", bLock);
	updateControl("spacereach", bLock);
	updateControl("specialattacks", bLock);
	
	updateControl("strength", bLock);
	updateControl("constitution", bLock);
	updateControl("dexterity", bLock);
	updateControl("intelligence", bLock);
	updateControl("wisdom", bLock);
	updateControl("charisma", bLock);
	updateControl("babgrp", bLock);
	updateControl("feats", bLock);
	updateControl("skills", bLock);
	updateControl("languages", bLock);
	updateControl("advancement", bLock);
	updateControl("leveladjustment", bLock);

	updateControl("environment", bLock);
	updateControl("organization", bLock);
	updateControl("treasure", bLock);
	
	-- TRAP SPECIFIC
	updateControl("trigger", bLock);
	updateControl("reset", bLock);

	-- VEHICLE SPECIFIC
	updateControl("squares", bLock);
	updateControl("basesave", bLock);
	
	updateControl("prop", bLock);
	updateControl("drive", bLock);
	updateControl("ff", bLock);
	updateControl("drived", bLock);
	updateControl("drives", bLock);
	updateControl("crew", bLock, 0);
	updateControl("decks", bLock);
	updateControl("weapons", bLock);
end
