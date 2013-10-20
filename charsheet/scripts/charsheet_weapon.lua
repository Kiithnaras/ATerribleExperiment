-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Delete Weapon", "delete", 4);
	registerMenuItem("Confirm Delete", "delete", 4, 3);
	
	toggleDetail();
end

function onMenuSelection(selection, subselection)
	if selection == 4 and subselection == 3 then
		local node = getDatabaseNode();
		if node then
			node.delete();
		else
			close();
		end
	end
end

function onAttackChanged()
	attack1.onSourceUpdate();
	attack2.onSourceUpdate();
	attack3.onSourceUpdate();
	attack4.onSourceUpdate();
end

function onDamageChanged()
	damagetotalbonus.onSourceUpdate();
end

function onTypeChanged()
	toggleDetail();
end

function setSpacerState()
	if activatedetail.getValue() then
		spacer.setVisible(true);
	else
		spacer.setVisible(false);
	end
end

function toggleDetail()
	local bRanged = (type.getIndex() == 1);
	local bBow = (bRanged and (damagerangedstatadj.getStringValue() == "bow"));
	local status = activatedetail.getValue();

	label_atkdetail.setVisible(status);
	attackstat.setVisible(status);
	label_atkplus.setVisible(status);
	bonus.setVisible(status);
	label_atkplus2.setVisible(status);
	attackmodframe.setVisible(status);
	attack1modifier.setVisible(status);
	attack2modifier.setVisible(status);
	attack3modifier.setVisible(status);
	attack4modifier.setVisible(status);
	label_critrange.setVisible(status);
	critatkrange.setVisible(status);

	label_dmgdetail.setVisible(status);
	damagedicedetail.setVisible(status);
	label_dmgplus.setVisible(status);
	damagestat1.setVisible(status);
	label_dmgplus2.setVisible(status);
	damagestat2.setVisible(status);
	label_dmgplus3.setVisible(status);
	damagebonus.setVisible(status);
	label_critmult.setVisible(status);
	critdmgmult.setVisible(status);
	label_dmgtype.setVisible(status);
	damagetype.setVisible(status);
	
	damageadjanchor.setVisible(status);
	damagemeleestatadj.setVisible(status and not bRanged);
	damagerangedstatadj.setVisible(status and bRanged);
	damagemaxstat.setVisible(status and bBow);
	damageadjspacer.setVisible(status);

	label_range.setVisible(status and bRanged);
	rangeincrement.setVisible(status and bRanged);
	label_ammo.setVisible(status and bRanged);
	maxammo.setVisible(status and bRanged);
	ammocounter.setVisible(status and bRanged);
	
	label_properties.setVisible(status);
	properties.setVisible(status);
	
	setSpacerState();
end
