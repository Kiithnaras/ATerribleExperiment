-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("menu_deletespellaction"), "deletepointer", 4);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "deletepointer", 4, 3);
	
	local node = getDatabaseNode();
	if node then
		node.onChildUpdate = onUpdate;
	end

	onUpdate();
end

function onMenuSelection(selection, subselection)
	if selection == 4 and subselection == 3 then
		getDatabaseNode().delete();
	end
end

function onUpdate()
	updateDisplay();
	updateViews();
end

function getActorType()
	return windowlist.window.getActorType();
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
	local bShowAttackDetail = (toggle_attack.getValue() == 1) and bShowCast;
	local bShowLevelCheckDetail = (toggle_levelcheck.getValue() == 1) and bShowCast;
	local bShowSaveDetail = (toggle_save.getValue() == 1) and bShowCast;

	local bShowDamage = (sType == "damage");
	local bShowDamageDetail = (toggle_damage.getValue() == 1) and bShowDamage;
	
	local bShowHeal = (sType == "heal");
	local bShowHealDetail = (toggle_heal.getValue() == 1) and bShowHeal;
	
	local bShowEffect = (sType == "effect");
	local bShowDurationDetail = (toggle_duration.getValue() == 1) and bShowEffect;
	
	castlabel.setVisible(bShowCast);
	castbutton.setVisible(bShowCast);
	attackviewlabel.setVisible(bShowCast);
	attackbutton.setVisible(bShowCast);
	attackview.setVisible(bShowCast);
	toggle_attack.setVisible(bShowCast);
	levelcheckviewlabel.setVisible(bShowCast);
	levelcheckbutton.setVisible(bShowCast);
	levelcheckview.setVisible(bShowCast);
	toggle_levelcheck.setVisible(bShowCast);
	saveviewlabel.setVisible(bShowCast);
	savebutton.setVisible(bShowCast);
	saveview.setVisible(bShowCast);
	toggle_save.setVisible(bShowCast);
	
	atklabel.setVisible(bShowAttackDetail);
	atktype.setVisible(bShowAttackDetail);
	atkplus.setVisible(bShowAttackDetail);
	atkmod.setVisible(bShowAttackDetail);
	clclabel.setVisible(bShowLevelCheckDetail);
	clcbase.setVisible(bShowLevelCheckDetail);
	clcplus.setVisible(bShowLevelCheckDetail);
	clcmod.setVisible(bShowLevelCheckDetail);
	srlabel.setVisible(bShowLevelCheckDetail);
	srnotallowed.setVisible(bShowLevelCheckDetail);
	savelabel.setVisible(bShowSaveDetail);
	savetype.setVisible(bShowSaveDetail);
	savedclabel.setVisible(bShowSaveDetail);
	savedcbase.setVisible(bShowSaveDetail);
	saveplus.setVisible(bShowSaveDetail);
	savedcmod.setVisible(bShowSaveDetail);
	
	damagelabel.setVisible(bShowDamage);
	damagebutton.setVisible(bShowDamage);
	damageview.setVisible(bShowDamage);
	toggle_damage.setVisible(bShowDamage);

	dmglabel.setVisible(bShowDamageDetail);
	dmgdice.setVisible(bShowDamageDetail);
	dmgdicemult.setVisible(bShowDamageDetail);
	dmgdicemultmaxparen.setVisible(bShowDamageDetail);
	dmgdicemultmax.setVisible(bShowDamageDetail);
	dmgdicemultmaxparen2.setVisible(bShowDamageDetail);
	dmgplus.setVisible(bShowDamageDetail);
	dmgstatmult.setVisible(bShowDamageDetail);
	dmgstatmultx.setVisible(bShowDamageDetail);
	dmgstat.setVisible(bShowDamageDetail);
	dmgmaxparen.setVisible(bShowDamageDetail);
	dmgmaxstat.setVisible(bShowDamageDetail);
	dmgmaxparen2.setVisible(bShowDamageDetail);
	dmgplus2.setVisible(bShowDamageDetail);
	dmgmod.setVisible(bShowDamageDetail);
	dmgtypelabel.setVisible(bShowDamageDetail);
	dmgtype.setVisible(bShowDamageDetail);
	dmgspelltype_label.setVisible(bShowDamageDetail);
	dmgspelltype.setVisible(bShowDamageDetail);
	dmgmetalabel.setVisible(bShowDamageDetail);
	dmgmeta.setVisible(bShowDamageDetail);

	heallabel.setVisible(bShowHeal);
	healbutton.setVisible(bShowHeal);
	healview.setVisible(bShowHeal);
	healtypelabel.setVisible(bShowHeal);
	healtype.setVisible(bShowHeal);
	toggle_heal.setVisible(bShowHeal);

	hlabel.setVisible(bShowHealDetail);
	hdice.setVisible(bShowHealDetail);
	hdicemult.setVisible(bShowHealDetail);
	hdicemultmaxparen.setVisible(bShowHealDetail);
	hdicemultmax.setVisible(bShowHealDetail);
	hdicemultmaxparen2.setVisible(bShowHealDetail);
	hplus.setVisible(bShowHealDetail);
	hstatmult.setVisible(bShowHealDetail);
	hstatmultx.setVisible(bShowHealDetail);
	hstat.setVisible(bShowHealDetail);
	hmaxparen.setVisible(bShowHealDetail);
	hmaxstat.setVisible(bShowHealDetail);
	hmaxparen2.setVisible(bShowHealDetail);
	hplus2.setVisible(bShowHealDetail);
	hmod.setVisible(bShowHealDetail);
	healmetalabel.setVisible(bShowHealDetail);
	healmeta.setVisible(bShowHealDetail);

	effectbutton.setVisible(bShowEffect);
	targeting.setVisible(bShowEffect);
	apply.setVisible(bShowEffect);
	durationview.setVisible(bShowEffect);
	toggle_duration.setVisible(bShowEffect);
	label.setVisible(bShowEffect);

	durlabel.setVisible(bShowDurationDetail);
	durmult.setVisible(bShowDurationDetail);
	durstat.setVisible(bShowDurationDetail);
	dmaxparen.setVisible(bShowDurationDetail);
	dmaxstat.setVisible(bShowDurationDetail);
	dmaxparen2.setVisible(bShowDurationDetail);
	durplus.setVisible(bShowDurationDetail);
	durdice.setVisible(bShowDurationDetail);
	durplus2.setVisible(bShowDurationDetail);
	durmod.setVisible(bShowDurationDetail);
	durunit.setVisible(bShowDurationDetail);
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

	local sAttack = "";
	local sAttackType = DB.getValue(node, "atktype", "");
	local nAttackMod = DB.getValue(node, "atkmod", 0);
	if sAttackType == "melee" then
		sAttack = "Melee";
	elseif sAttackType == "ranged" then
		sAttack = "Ranged";
	elseif sAttackType == "mtouch" then
		sAttack = "M Touch";
	elseif sAttackType == "rtouch" then
		sAttack = "R Touch";
	elseif sAttackType == "cm" then
		sAttack = "CMB";
	end
	if sAttack ~= "" and nAttackMod ~= 0 then
		sAttack = sAttack .. " + " .. nAttackMod;
	end
	attackview.setValue(sAttack);

	local nCL = DB.getValue(node, "clcbase", 0) + DB.getValue(node, "clcmod", 0);
	levelcheckview.setValue("" .. nCL);
	
	local sSave = "";
	local sSaveType = DB.getValue(node, "savetype", "");
	local nDC = DB.getValue(node, "savedcbase", 0) + DB.getValue(node, "savedcmod", 0);
	if sSaveType ~= "" and nDC ~= 0 then
		if sSaveType == "fortitude" then
			sSave = "Fort";
		elseif sSaveType == "reflex" then
			sSave = "Ref";
		elseif sSaveType == "will" then
			sSave = "Will";
		end
		
		sSave = sSave .. " DC " .. nDC;
	end
	saveview.setValue(sSave);
end

function onDamageChanged()
	local nodeAction = getDatabaseNode();
	local rActor = ActorManager.getActor(getActorType(), nodeAction.getChild("........."));

	local aDice, nMod, sType = SpellManager.getSpellActionDamage(rActor, nodeAction);

	local sDamage = StringManager.convertDiceToString(aDice, nMod);
	if sType ~= "" then
		sDamage = sDamage .. " " .. sType;
	end
	
	local sMeta = DB.getValue(nodeAction, "dmgmeta", "");
	if sMeta == "empower" then
		sDamage = sDamage .. " [E]";
	elseif sMeta == "maximize" then
		sDamage = sDamage .. " [M]";
	end
	
	damageview.setValue(sDamage);
end

function onHealChanged()
	local nodeAction = getDatabaseNode();
	local rActor = ActorManager.getActor(getActorType(), nodeAction.getChild("........."));

	local aDice, nMod, sType = SpellManager.getSpellActionHeal(rActor, nodeAction);

	local sHeal = StringManager.convertDiceToString(aDice, nMod);
	if sType == "temp" then
		sHeal = sHeal .. " [TEMP]";
	end
	
	local sMeta = DB.getValue(nodeAction, "healmeta", "");
	if sMeta == "empower" then
		sHeal = sHeal .. " [E]";
	elseif sMeta == "maximize" then
		sHeal = sHeal .. " [M]";
	end
	
	healview.setValue(sHeal);
end

function onEffectChanged()
	local nodeAction = getDatabaseNode();

	local aDice = DB.getValue(nodeAction, "durdice", {});
	local nMod = DB.getValue(nodeAction, "durmod", 0);
	
	local nCLMult = DB.getValue(nodeAction, "durmult", 0);
	if nCLMult > 0 then
		local sStat = DB.getValue(nodeAction, "durstat", "");
		if sStat == "cl" or sStat == "halfcl" or sStat == "oddcl" then
			nStat = DB.getValue(nodeAction, ".......cl", 0);
			if sStat == "halfcl" then
				nStat = math.floor((nStat + 0.5) / 2);
			elseif sStat == "oddcl" then
				nStat = math.floor((nStat + 1.5) / 2);
			end
		else
			nStat = 0;
			local nodeActor = nodeAction.getChild(".........");
			if nodeActor then
				local rActor;
				if ActorManager.isPC(nodeActor) then
					rActor = ActorManager.getActor("pc", nodeActor);
				else
					rActor = ActorManager.getActor("npc", nodeActor);
				end
				
				nStat = ActorManager2.getAbilityBonus(rActor, sStat);
			end
		end
		local nMaxStat = DB.getValue(nodeAction, "dmaxstat", 0);
		if nMaxStat > 0 and nMaxStat < nStat then
			nStat = nMaxStat;
		end
		
		nMod = nMod + math.floor(nStat * nCLMult);
	end

	local sDuration = StringManager.convertDiceToString(aDice, nMod);
	
	local sUnits = DB.getValue(nodeAction, "durunit", "");
	if sDuration ~= "" then
		if sUnits == "minute" then
			sDuration = sDuration .. " min";
		elseif sUnits == "hour" then
			sDuration = sDuration .. " hr";
		elseif sUnits == "day" then
			sDuration = sDuration .. " dy";
		else
			sDuration = sDuration .. " rd";
		end
	end
	
	durationview.setValue(sDuration);
end