-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("menu_deletespellaction"), "deletepointer", 4);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "deletepointer", 4, 3);

	updateDisplay();

	local sNode = getDatabaseNode().getNodeName();
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	local sNode = getDatabaseNode().getNodeName();
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end

function onMenuSelection(selection, subselection)
	if selection == 4 and subselection == 3 then
		getDatabaseNode().delete();
	end
end

function onDataChanged()
	updateDisplay();
	updateViews();
end

function highlight(bState)
	if bState then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

function updateDisplay()
	local node = getDatabaseNode();
	
	local sType = DB.getValue(node, "type", "");
	
	local bShowCast = (sType == "cast");
	local bShowDamage = (sType == "damage");
	local bShowHeal = (sType == "heal");
	local bShowEffect = (sType == "effect");
	
	castlabel.setVisible(bShowCast);
	castbutton.setVisible(bShowCast);
	attackviewlabel.setVisible(bShowCast);
	attackbutton.setVisible(bShowCast);
	attackview.setVisible(bShowCast);
	levelcheckviewlabel.setVisible(bShowCast);
	levelcheckbutton.setVisible(bShowCast);
	levelcheckview.setVisible(bShowCast);
	saveviewlabel.setVisible(bShowCast);
	savebutton.setVisible(bShowCast);
	saveview.setVisible(bShowCast);
	castdetail.setVisible(bShowCast);

	damagelabel.setVisible(bShowDamage);
	damagebutton.setVisible(bShowDamage);
	damageview.setVisible(bShowDamage);
	damagedetail.setVisible(bShowDamage);

	heallabel.setVisible(bShowHeal);
	healbutton.setVisible(bShowHeal);
	healview.setVisible(bShowHeal);
	healtypelabel.setVisible(bShowHeal);
	healtype.setVisible(bShowHeal);
	healdetail.setVisible(bShowHeal);

	effectbutton.setVisible(bShowEffect);
	targeting.setVisible(bShowEffect);
	apply.setVisible(bShowEffect);
	durationview.setVisible(bShowEffect);
	label.setVisible(bShowEffect);
	effectdetail.setVisible(bShowEffect);
end

function updateViews()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		onCastChanged();
	elseif sType == "damage" then
		onDamageChanged();
	elseif sType == "heal" then
		onHealChanged();
	elseif sType == "effect" then
		onEffectChanged();
	end
end

function onCastChanged()
	local node = getDatabaseNode();

	local sAttack = SpellManager.getActionAttackText(node);
	attackview.setValue(sAttack);

	local nCL = SpellManager.getActionCLC(node);
	levelcheckview.setValue("" .. nCL);
	
	local sSave = SpellManager.getActionSaveText(node);
	saveview.setValue(sSave);
end

function onDamageChanged()
	local sDamage = SpellManager.getActionDamageText(getDatabaseNode());
	damageview.setValue(sDamage);
end

function onHealChanged()
	local sHeal = SpellManager.getActionHealText(getDatabaseNode());
	healview.setValue(sHeal);
end

function onEffectChanged()
	local sDuration = SpellManager.getActionEffectDurationText(getDatabaseNode());
	durationview.setValue(sDuration);
end
