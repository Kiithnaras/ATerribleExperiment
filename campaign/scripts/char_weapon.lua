-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("menu_deleteweapon"), "delete", 4);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 4, 3);
	
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

function toggleDetail()
	local bRanged = (type.getValue() == 1);
	local bBow = (bRanged and (damagerangedstatadj.getStringValue() == "bow"));
	local status = (activatedetail.getValue() == 1);

	label_atkdetail.setVisible(status);
	attackstat.setVisible(status);
	label_atkplus.setVisible(status);
	bonus.setVisible(status);
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
	damagemaxstatparen.setVisible(status and bBow);
	damagemaxstat.setVisible(status and bBow);
	damagemaxstatparen2.setVisible(status and bBow);

	label_range.setVisible(status and bRanged);
	rangeincrement.setVisible(status and bRanged);
	label_ammo.setVisible(status and bRanged);
	maxammo.setVisible(status and bRanged);
	ammocounter.setVisible(status and bRanged);
	
	label_properties.setVisible(status);
	properties.setVisible(status);
end
