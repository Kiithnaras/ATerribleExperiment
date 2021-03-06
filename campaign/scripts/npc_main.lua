-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
	
	return self[sControl].update(bReadOnly, bForceHide);
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	local bPFMode = DataCommon.isPFRPG();
	local sType = DB.getValue(getDatabaseNode(), "npctype", "");

	-- Update labels based on system being played and NPC type
	if babgrp_label then
		if sType == "Vehicle" then
			babgrp_label.setValue(Interface.getString("npc_label_cm"));
			updateControl("babgrp", bReadOnly);
		else
			babgrp_label.setValue(Interface.getString("npc_label_babcm"));
		end
	end

	updateControl("type", bReadOnly);
	if bPFMode then
		updateControl("alignment", bReadOnly, true);
	else
		updateControl("alignment", bReadOnly);
	end
	if bPFMode then
		updateControl("senses", bReadOnly);
		updateControl("aura", bReadOnly);
	else
		updateControl("senses", bReadOnly, true);
		updateControl("aura", bReadOnly, true);
	end
	
	updateControl("ac", bReadOnly);
	updateControl("hd", bReadOnly);
	updateControl("specialqualities", bReadOnly);
	
	updateControl("speed", bReadOnly);
	updateControl("atk", bReadOnly);
	updateControl("fullatk", bReadOnly);
	updateControl("spacereach", bReadOnly);
	updateControl("specialattacks", bReadOnly);
	
	updateControl("babgrp", bReadOnly);
	updateControl("feats", bReadOnly);
	updateControl("skills", bReadOnly);
	updateControl("languages", bReadOnly);
	updateControl("advancement", bReadOnly);
	updateControl("leveladjustment", bReadOnly);

	updateControl("environment", bReadOnly);
	updateControl("organization", bReadOnly);
	updateControl("treasure", bReadOnly);
	
	-- Trap
	updateControl("trigger", bReadOnly);
	updateControl("reset", bReadOnly);

	-- Vehicle
	updateControl("squares", bReadOnly);
	updateControl("basesave", bReadOnly);
	
	updateControl("prop", bReadOnly);
	updateControl("drive", bReadOnly);
	updateControl("ff", bReadOnly);
	updateControl("drived", bReadOnly);
	updateControl("drives", bReadOnly);
	updateControl("crew", bReadOnly);
	updateControl("decks", bReadOnly);
	updateControl("weapons", bReadOnly);
end
