-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	if node then
		node.onChildUpdate = onUpdate;
	end

	onUpdate();
end

function getActorType()
	return windowlist.window.getActorType();
end	

function onHover(bOver)
	windowlist.onHover(bOver);
end			

function onUpdate()
	updateDisplay();
	updateViews();
end

function updateDisplay()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		button.setIcons("button_roll", "button_roll_down");
	elseif sType == "damage" then
		button.setIcons("button_damage_small", "button_damage_small_down");
	elseif sType == "heal" then
		button.setIcons("button_heal_small", "button_heal_small_down");
	elseif sType == "effect" then
		button.setIcons("button_effect_small", "button_effect_small_down");
	end
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
	if not node then
		return;
	end
	
	local sCL = "CAST: " .. DB.getValue(node, "clcbase", 0) + DB.getValue(node, "clcmod", 0);
	
	local sAttack = "";
	local sAttackType = DB.getValue(node, "atktype", "");
	local nAttackMod = DB.getValue(node, "atkmod", 0);
	if sAttackType == "melee" then
		sAttack = "ATK: Melee";
	elseif sAttackType == "ranged" then
		sAttack = "ATK: Ranged";
	elseif sAttackType == "mtouch" then
		sAttack = "ATK: M Touch";
	elseif sAttackType == "rtouch" then
		sAttack = "ATK: R Touch";
	elseif sAttackType == "cm" then
		sAttack = "ATK: CMB";
	end
	if sAttack ~= "" and nAttackMod ~= 0 then
		sAttack = sAttack .. " + " .. nAttackMod;
	end

	local sSave = "";
	local sSaveType = DB.getValue(node, "savetype", "");
	if sSaveType ~= "" and nDC ~= 0 then
		if sSaveType == "fortitude" then
			sSave = "SAVE: Fort";
		elseif sSaveType == "reflex" then
			sSave = "SAVE: Ref";
		elseif sSaveType == "will" then
			sSave = "SAVE: Will";
		end
		
		local nDC = DB.getValue(node, "savedcbase", 0) + DB.getValue(node, "savedcmod", 0);
		sSave = sSave .. " DC " .. nDC;
	end
	
	local sTooltip = sCL;
	if sAttack ~= "" then
		sTooltip = sTooltip .. "\r" .. sAttack;
	end
	if sSave ~= "" then
		sTooltip = sTooltip .. "\r" .. sSave;
	end

	button.setTooltipText(sTooltip);
end

function onDamageChanged()
	local nodeAction = getDatabaseNode();
	local rActor = ActorManager.getActor(getActorType(), nodeAction.getChild("........."));

	local aDice, nMod, sType = SpellsManager.getSpellActionDamage(rActor, nodeAction);

	local sTooltip = "DMG: " .. StringManager.convertDiceToString(aDice, nMod);
	if sType ~= "" then
		sTooltip = sTooltip .. " " .. sType;
	end
	
	local sMeta = DB.getValue(nodeAction, "dmgmeta", "");
	if sMeta == "empower" then
		sTooltip = sTooltip .. " [E]";
	elseif sMeta == "maximize" then
		sTooltip = sTooltip .. " [M]";
	end
	
	button.setTooltipText(sTooltip);
end

function onHealChanged()
	local nodeAction = getDatabaseNode();
	local rActor = ActorManager.getActor(getActorType(), nodeAction.getChild("........."));

	local aDice, nMod, sType = SpellsManager.getSpellActionHeal(rActor, nodeAction);

	local sTooltip = "HEAL: " .. StringManager.convertDiceToString(aDice, nMod);
	if sType == "temp" then
		sTooltip = sTooltip .. " [TEMP]";
	end
	
	local sMeta = DB.getValue(nodeAction, "healmeta", "");
	if sMeta == "empower" then
		sTooltip = sTooltip .. " [E]";
	elseif sMeta == "maximize" then
		sTooltip = sTooltip .. " [M]";
	end
	
	button.setTooltipText(sTooltip);
end

function onEffectChanged()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	local sTooltip = DB.getValue(node, "label", "");

	local sApply = DB.getValue(node, "apply", "");
	if sApply == "action" then
		sTooltip = "[1 ACTN]; " .. sTooltip;
	elseif sApply == "roll" then
		sTooltip = "[1 ROLL]; " .. sTooltip;
	elseif sApply == "single" then
		sTooltip = "[SNGL]; " .. sTooltip;
	end
	
	local sTargeting = DB.getValue(node, "targeting", "");
	if sTargeting == "self" then
		sTooltip = "[SELF]; " .. sTooltip;
	end
	
	sTooltip = "EFFECT: " .. sTooltip;
	
	button.setTooltipText(sTooltip);
end
