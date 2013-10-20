-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local TOKEN_MAX_EFFECTS = 6;
local TOKEN_EFFECT_WIDTH = 12;
local TOKEN_EFFECT_MARGIN = 2;
local TOKEN_EFFECT_OFFSETX = 6;
local TOKEN_EFFECT_OFFSETY = -6;
local TOKEN_HEALTH_MINBAR = 14;
local TOKEN_HEALTH_WIDTH = 20;

function onInit()
	if User.isHost() then
		Token.onDelete = onDelete;

		Token.onClickRelease = onClickRelease;
		Token.onWheel = onWheel;

		Token.onContainerChanged = onContainerChanged;
		Token.onTargetUpdate = onTargetUpdate;

		DB.addHandler("combattracker.*.space", "onUpdate", updateSpaceReach);
		DB.addHandler("combattracker.*.reach", "onUpdate", updateSpaceReach);
	end

	Token.onAdd = onAdd;
	Token.onDrop = onDrop;
	Token.onScaleChanged = onScaleChanged;
	Token.onHover = onHover;

	DB.addHandler("combattracker.*.tokenrefid", "onUpdate", updateAttributes);

	DB.addHandler("combattracker.*.friendfoe", "onUpdate", updateFaction);
	
	DB.addHandler("combattracker.*.name", "onUpdate", updateName);
	
	DB.addHandler("combattracker.*.hp", "onUpdate", updateHealth);
	DB.addHandler("combattracker.*.hptemp", "onUpdate", updateHealth);
	DB.addHandler("combattracker.*.nonlethal", "onUpdate", updateHealth);
	DB.addHandler("combattracker.*.wounds", "onUpdate", updateHealth);

	DB.addHandler("combattracker.*.effects", "onChildUpdate", updateEffectsList);
	DB.addHandler("combattracker.*.effects.*.isactive", "onAdd", updateEffects);
	DB.addHandler("combattracker.*.effects.*.isactive", "onUpdate", updateEffects);
	DB.addHandler("combattracker.*.effects.*.isgmonly", "onAdd", updateEffects);
	DB.addHandler("combattracker.*.effects.*.isgmonly", "onUpdate", updateEffects);
	DB.addHandler("combattracker.*.effects.*.label", "onAdd", updateEffects);
	DB.addHandler("combattracker.*.effects.*.label", "onUpdate", updateEffects);

	DB.addHandler("options.TNAM", "onUpdate", onOptionChanged);
	DB.addHandler("options.TNPCE", "onUpdate", onOptionChanged);
	DB.addHandler("options.TNPCH", "onUpdate", onOptionChanged);
	DB.addHandler("options.TPCE", "onUpdate", onOptionChanged);
	DB.addHandler("options.TPCH", "onUpdate", onOptionChanged);
	DB.addHandler("options.WNDC", "onUpdate", onOptionChanged);
end

function onOptionChanged(nodeOption)
	for _, vChild in pairs(DB.getChildren("combattracker")) do
		local tokeninstance = Token.getToken(DB.getValue(vChild, "tokenrefnode", ""), DB.getValue(vChild, "tokenrefid", ""));
		if tokeninstance then
			updateAttributesHelper(tokeninstance, vChild);
		end
	end
end

function onAdd(tokeninstance)
	if User.isHost() then
		tokeninstance.registerMenuItem("Reset individual token scaling", "minimize", 2);
		tokeninstance.onMenuSelection = onTokenMenuSelection;
	end
	updateAttributesFromToken(tokeninstance);
end

function onTokenMenuSelection(tokeninstance, selection)
	if selection == 2 then
		tokeninstance.setScale(1);
	end
end

function onDelete(tokeninstance)
	local nodeCT = CTManager.getCTFromToken(tokeninstance);
	if nodeCT then
		DB.setValue(nodeCT, "tokenrefnode", "string", "");
		DB.setValue(nodeCT, "tokenrefid", "string", "");
		DB.setValue(nodeCT, "tokenscale", "number", 1);
	end
	local nodePS = PartyManager.getNodeFromToken(tokeninstance);
	if nodePS then
		DB.setValue(nodePS, "tokenrefnode", "string", "");
		DB.setValue(nodePS, "tokenrefid", "string", "");
		DB.setValue(nodePS, "tokenscale", "number", 1);
	end
end

function onClickRelease(tokeninstance, button)
	if Input.isControlPressed() and button == 2 then
		tokeninstance.setScale(1);
		return true;
	end
	if Input.isShiftPressed() and button == 1 then
		local rSource = ActorManager.getActor("ct", CTManager.getActiveCT());
		local rTarget = ActorManager.getActorFromToken(tokeninstance);
		if rSource and rTarget then
			TargetingManager.toggleTarget("host", rSource.sCTNode, rTarget.sCTNode);
		end
		return true;
	end
end

function getTokenFromCT(nodeCTEntry)
	return Token.getToken(DB.getValue(nodeCTEntry, "tokenrefnode", ""), DB.getValue(nodeCTEntry, "tokenrefid", ""));
end

function onWheelHelper(tokeninstance, notches)
	if not tokeninstance then
		return;
	end
	
	if Input.isShiftPressed() then
		newscale = math.floor(tokeninstance.getScale() + notches);
		if newscale < 1 then
			newscale = 1;
		end
	else
		newscale = tokeninstance.getScale() + (notches * 0.1);
		if newscale < 0.1 then
			newscale = 0.1;
		end
	end
	
	tokeninstance.setScale(newscale);
end

function onWheelCT(nodeCTEntry, notches)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		onWheelHelper(tokeninstance, notches);
	end
end

function onWheel(tokeninstance, notches)
	if Input.isControlPressed() then
		onWheelHelper(tokeninstance, notches);
		return true;
	end
end

function onDrop(tokeninstance, draginfo)
	local nodeCT = CTManager.getCTFromToken(tokeninstance);
	if nodeCT then
		CTManager.onDrop("ct", nodeCT.getNodeName(), draginfo);
	end
end

function onContainerChanged(tokeninstance, nodeOldContainer, nOldId)
	local nodeCT = CTManager.getCTFromTokenRef(nodeOldContainer, nOldId);
	if nodeCT then
		local nodeNewContainer = tokeninstance.getContainerNode();
		if nodeNewContainer then
			DB.setValue(nodeCT, "tokenrefnode", "string", nodeNewContainer.getNodeName());
			DB.setValue(nodeCT, "tokenrefid", "string", tokeninstance.getId());
			DB.setValue(nodeCT, "tokenscale", "number", tokeninstance.getScale());
		else
			DB.setValue(nodeCT, "tokenrefnode", "string", "");
			DB.setValue(nodeCT, "tokenrefid", "string", "");
			DB.setValue(nodeCT, "tokenscale", "number", 1);
		end
	end
	local nodePS = PartyManager.getNodeFromTokenRef(nodeOldContainer, nOldId);
	if nodePS then
		local nodeNewContainer = tokeninstance.getContainerNode();
		if nodeNewContainer then
			DB.setValue(nodePS, "tokenrefnode", "string", nodeNewContainer.getNodeName());
			DB.setValue(nodePS, "tokenrefid", "string", tokeninstance.getId());
			DB.setValue(nodePS, "tokenscale", "number", tokeninstance.getScale());
		else
			DB.setValue(nodePS, "tokenrefnode", "string", "");
			DB.setValue(nodePS, "tokenrefid", "string", "");
			DB.setValue(nodePS, "tokenscale", "number", 1);
		end
	end
end

function onScaleChanged(tokeninstance)
	local nodeCT = CTManager.getCTFromToken(tokeninstance);

	if User.isHost() then
		if nodeCT then
			DB.setValue(nodeCT, "tokenscale", "number", tokeninstance.getScale());
		end
		local nodePS = PartyManager.getNodeFromToken(tokeninstance);
		if nodePS then
			DB.setValue(nodePS, "tokenscale", "number", tokeninstance.getScale());
		end
	end
	
	if nodeCT then
		updateNameScale(tokeninstance);
		updateHealthBarScale(tokeninstance, nodeCT);
		updateEffectsHelper(tokeninstance, nodeCT);
	end
end

function onTargetUpdate(tokeninstance)
	TargetingManager.rebuildClientTargeting();
end

function onHover(tokeninstance, bOver)
	local nodeCT = CTManager.getCTFromToken(tokeninstance);
	if nodeCT then
		local sFaction = DB.getValue(nodeCT, "friendfoe", "");

		local sOptName = OptionsManager.getOption("TNAM");
		local sOptEffects, sOptHealth;
		if sFaction == "friend" then
			sOptEffects = OptionsManager.getOption("TPCE");
			sOptHealth = OptionsManager.getOption("TPCH");
		else
			sOptEffects = OptionsManager.getOption("TNPCE");
			sOptHealth = OptionsManager.getOption("TNPCH");
		end
		
		local aWidgets = {};
		if sOptName == "hover" then
			aWidgets["name"] = tokeninstance.findWidget("name");
			aWidgets["ordinal"] = tokeninstance.findWidget("ordinal");
		end
		if sOptHealth == "barhover" then
			aWidgets["healthbar"] = tokeninstance.findWidget("healthbar");
		elseif sOptHealth == "dothover" then
			aWidgets["healthdot"] = tokeninstance.findWidget("healthdot");
		end
		if sOptEffects == "hover" or sOptEffects == "markhover" then
			for i = 1, TOKEN_MAX_EFFECTS do
				aWidgets["effect" .. i] = tokeninstance.findWidget("effect" .. i);
			end
		end

		for _, vWidget in pairs(aWidgets) do
			vWidget.setVisible(bOver);
		end
	end
end

function toggleClientTarget(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		if tokeninstance.isTargetedByIdentity() then
			tokeninstance.setTarget(false);
		else
			tokeninstance.setTarget(true);
		end
	end
end

function updateAttributesFromToken(tokeninstance)
	local nodeCTEntry = CTManager.getCTFromToken(tokeninstance);
	if nodeCTEntry then
		updateAttributesHelper(tokeninstance, nodeCTEntry);
	end
	
	if User.isHost() then
		local nodePS = PartyManager.getNodeFromToken(tokeninstance);
		if nodePS then
			tokeninstance.setTargetable(false);
			tokeninstance.setActivable(true);
			tokeninstance.setActive(false);
			tokeninstance.setVisible(true);
			
			tokeninstance.setName(DB.getValue(nodePS, "name", ""));
		end
	end
end

function updateAttributes(nodeField)
	local nodeCTEntry = nodeField.getParent();
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateAttributesHelper(tokeninstance, nodeCTEntry);
	end
end

function updateAttributesHelper(tokeninstance, nodeCTEntry)
	if User.isHost() then
		tokeninstance.setTargetable(true);
		tokeninstance.setActivable(true);
		
		updateActiveHelper(tokeninstance, nodeCTEntry);
		updateFactionHelper(tokeninstance, nodeCTEntry);
		updateUnderlayHelper(tokeninstance, nodeCTEntry);
	end
	
	updateNameHelper(tokeninstance, nodeCTEntry);
	updateHealthHelper(tokeninstance, nodeCTEntry);
	updateEffectsHelper(tokeninstance, nodeCTEntry);
	updateTooltip(tokeninstance, nodeCTEntry);
end

function updateTooltip(tokeninstance, nodeCTEntry)
	if User.isHost() then
		local sOptTNAM = OptionsManager.getOption("TNAM");
		local sOptTH, sOptTE;
		if DB.getValue(nodeCTEntry, "friendfoe", "") == "friend" then
			sOptTE = OptionsManager.getOption("TPCE");
			sOptTH = OptionsManager.getOption("TPCH");
		else
			sOptTE = OptionsManager.getOption("TNPCE");
			sOptTH = OptionsManager.getOption("TNPCH");
		end
		
		local aTooltip = {};
		
		if sOptTNAM == "tooltip" then
			table.insert(aTooltip, DB.getValue(nodeCTEntry, "name", ""));
		end
		if sOptTH == "tooltip" then
			local sStatus;
			_, _, sStatus = ActorManager.getPercentWounded("ct", nodeCTEntry);
			table.insert(aTooltip, sStatus);
		end
		if sOptTE == "tooltip" then
			local aCondList = getConditionIconList(nodeCTEntry);
			for _,v in ipairs(aCondList) do
				table.insert(aTooltip, v.sLabel);
			end
		end
		
		tokeninstance.setName(table.concat(aTooltip, "\r"));
	end
end

function updateName(nodeName)
	local nodeCTEntry = nodeName.getParent();
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateNameHelper(tokeninstance, nodeCTEntry);
		updateTooltip(tokeninstance, nodeCTEntry);
	end
end

function updateNameHelper(tokeninstance, nodeCTEntry)
	local sOptTNAM = OptionsManager.getOption("TNAM");
	
	local sName = DB.getValue(nodeCTEntry, "name", "");
	local aWidgets = getWidgetList(tokeninstance, "name");
	
	if sOptTNAM == "off" or sOptTNAM == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local w, h = tokeninstance.getSize();
		if w > 10 then
			local nStarts, _, sNumber = string.find(sName, " ?(%d+)$");
			if nStarts then
				sName = string.sub(sName, 1, nStarts - 1);
			end
			local bWidgetsVisible = (sOptTNAM == "on");

			local widgetName = aWidgets["name"];
			if not widgetName then
				widgetName = tokeninstance.addTextWidget("mini_name", "");
				widgetName.setPosition("top", 0, -2);
				widgetName.setFrame("mini_name", 5, 1, 5, 1);
				widgetName.setName("name");
			end
			if widgetName then
				widgetName.setVisible(bWidgetsVisible);
				widgetName.setText(sName);
				widgetName.setTooltipText(sName);
			end
			updateNameScale(tokeninstance);

			if sNumber then
				local widgetOrdinal = aWidgets["ordinal"];
				if not widgetOrdinal then
					widgetOrdinal = tokeninstance.addTextWidget("sheetlabelsmallbold", "");
					widgetOrdinal.setPosition("topright", -4, -2);
					widgetOrdinal.setFrame("tokennumber", 7, 1, 7, 1);
					widgetOrdinal.setName("ordinal");
				end
				if widgetOrdinal then
					widgetOrdinal.setVisible(bWidgetsVisible);
					widgetOrdinal.setText(sNumber);
				end
			else
				if aWidgets["ordinal"] then
					aWidgets["ordinal"].destroy();
				end
			end
		end
	end
end

function updateNameScale(tokeninstance)
	local widgetName = tokeninstance.findWidget("name");
	if widgetName then
		local w, h = tokeninstance.getSize();
		if w > 10 then
			widgetName.setMaxWidth(w - 10);
		else
			widgetName.setMaxWidth(0);
		end
	end
end

function updateVisibility(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateVisibilityHelper(tokeninstance, nodeCTEntry);
	end
end

function updateVisibilityHelper(tokeninstance, nodeCTEntry)
	if DB.getValue(nodeCTEntry, "friendfoe", "") == "friend" then
		tokeninstance.setVisible(true);
	else
		if DB.getValue(nodeCTEntry, "show_npc", 0) == 1 then
			tokeninstance.setVisible(nil);
		else
			tokeninstance.setVisible(false);
		end
	end
end

function updateActive(nodeCTEntry)
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateActiveHelper(tokeninstance, nodeCTEntry);
	end
end

function updateActiveHelper(tokeninstance, nodeCTEntry)
	if tokeninstance.isActivable() then
		if DB.getValue(nodeCTEntry, "active", 0) == 1 then
			tokeninstance.setActive(true);
		else
			tokeninstance.setActive(false);
		end
	end
end

function updateFaction(nodeFaction)
	local nodeCTEntry = nodeFaction.getParent();
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		if User.isHost() then
			updateFactionHelper(tokeninstance, nodeCTEntry);
		end
		updateHealthHelper(tokeninstance, nodeCTEntry);
		updateEffectsHelper(tokeninstance, nodeCTEntry);
		updateTooltip(tokeninstance, nodeCTEntry);
	end
end

function updateFactionHelper(tokeninstance, nodeCTEntry)
	if DB.getValue(nodeCTEntry, "friendfoe", "") == "friend" then
		tokeninstance.setModifiable(true);
	else
		tokeninstance.setModifiable(false);
	end

	updateVisibilityHelper(tokeninstance, nodeCTEntry);
	updateUnderlayHelper(tokeninstance, nodeCTEntry);
end

function updateSpaceReach(nodeField)
	local nodeCTEntry = nodeField.getParent();
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateUnderlayHelper(tokeninstance, nodeCTEntry);
	end
end

function updateUnderlayHelper(tokeninstance, nodeCTEntry)
	local nSpace = math.ceil(DB.getValue(nodeCTEntry, "space", 5) / 5) / 2;
	local nReach = math.ceil(DB.getValue(nodeCTEntry, "reach", 5) / 5) + nSpace;

	-- RESET UNDERLAYS
	tokeninstance.removeAllUnderlays();

	-- ADD REACH UNDERLAY
	if DB.getValue(nodeCTEntry, "type", "") == "pc" then
		tokeninstance.addUnderlay(nReach, "4f000000", "hover");
	else
		tokeninstance.addUnderlay(nReach, "4f000000", "hover,gmonly");
	end

	-- ADD SPACE/FACTION/HEALTH UNDERLAY
	local sFaction = DB.getValue(nodeCTEntry, "friendfoe", "");
	if sFaction == "friend" then
		tokeninstance.addUnderlay(nSpace, "2f00ff00");
	elseif sFaction == "foe" then
		tokeninstance.addUnderlay(nSpace, "2fff0000");
	elseif sFaction == "neutral" then
		tokeninstance.addUnderlay(nSpace, "2fffff00");
	end
end

function updateHealth(nodeField)
	local nodeCTEntry = nodeField.getParent();
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateHealthHelper(tokeninstance, nodeCTEntry);
		updateTooltip(tokeninstance, nodeCTEntry);
	end
end

function updateHealthHelper(tokeninstance, nodeCTEntry)
	local sOptTH;
	if DB.getValue(nodeCTEntry, "friendfoe", "") == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end
	
	local aWidgets = getWidgetList(tokeninstance, "health");
	
	if sOptTH == "off" or sOptTH == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local sColor, nPercentWounded, nPercentNonlethal, sStatus = ActorManager.getWoundBarColor("ct", nodeCTEntry);
		
		if sOptTH == "bar" or sOptTH == "barhover" then
			local w, h = tokeninstance.getSize();
		
			if h >= TOKEN_HEALTH_MINBAR then
				local widgetHealthBar = aWidgets["healthbar"];
				if not widgetHealthBar then
					widgetHealthBar = tokeninstance.addBitmapWidget("healthbar");
					widgetHealthBar.sendToBack();
					widgetHealthBar.setName("healthbar");
				end
				if widgetHealthBar then
					widgetHealthBar.setColor(sColor);
					widgetHealthBar.setTooltipText(sStatus);
					widgetHealthBar.setVisible(sOptTH == "bar");
				end
			end
			updateHealthBarScale(tokeninstance, nodeCTEntry);
			
			if aWidgets["healthdot"] then
				aWidgets["healthdot"].destroy();
			end
		elseif sOptTH == "dot" or sOptTH == "dothover" then
			local widgetHealthDot = aWidgets["healthdot"];
			if not widgetHealthDot then
				widgetHealthDot = tokeninstance.addBitmapWidget("healthdot");
				widgetHealthDot.setPosition("bottomright", -4, -6);
				widgetHealthDot.setName("healthdot");
			end
			if widgetHealthDot then
				widgetHealthDot.setColor(sColor);
				widgetHealthDot.setTooltipText(sStatus);
				widgetHealthDot.setVisible(sOptTH == "dot");
			end

			if aWidgets["healthbar"] then
				aWidgets["healthbar"].destroy();
			end
		end
	end
end

function updateHealthBarScale(tokeninstance, nodeCT)
	local widgetHealthBar = tokeninstance.findWidget("healthbar");
	if widgetHealthBar then
		local nPercentWounded, nPercentNonlethal = ActorManager.getPercentWounded("ct", nodeCT);
		
		local w, h = tokeninstance.getSize();
		h = h + 4;

		widgetHealthBar.setSize();
		local barw, barh = widgetHealthBar.getSize();
		
		-- Resize bar to match health percentage, but preserve bulb portion of bar graphic
		if h >= TOKEN_HEALTH_MINBAR then
			barh = (math.max(1.0 - nPercentNonlethal, 0) * (math.min(h, barh) - TOKEN_HEALTH_MINBAR)) + TOKEN_HEALTH_MINBAR;
		else
			barh = TOKEN_HEALTH_MINBAR;
		end

		widgetHealthBar.setSize(barw, barh, "bottom");
		widgetHealthBar.setPosition("bottomright", -4, -(barh / 2) + 4);
	end
end

function updateEffects(nodeEffectField)
	local nodeEffect = nodeEffectField.getChild("..");
	local nodeCTEntry = nodeEffect.getChild("...");
	local tokeninstance = getTokenFromCT(nodeCTEntry);
	if tokeninstance then
		updateEffectsHelper(tokeninstance, nodeCTEntry);
		updateTooltip(tokeninstance, nodeCTEntry);
	end
end

function updateEffectsList(nodeEffectsList, bListChanged)
	if bListChanged then
		local nodeCTEntry = nodeEffectsList.getParent();
		local tokeninstance = getTokenFromCT(nodeCTEntry);
		if tokeninstance then
			updateEffectsHelper(tokeninstance, nodeCTEntry);
			updateTooltip(tokeninstance, nodeCTEntry);
		end
	end
end

function updateEffectsHelper(tokeninstance, nodeCTEntry)
	local sOptTE;
	if DB.getValue(nodeCTEntry, "friendfoe", "") == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
	end

	local aWidgets = getWidgetList(tokeninstance, "effect");
	
	if sOptTE == "off" or sOptTE == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	elseif sOptTE == "mark" or sOptTE == "markhover" then
		local bWidgetsVisible = (sOptTE == "mark");
		
		local aTooltip = {};
		local aCondList = getConditionIconList(nodeCTEntry);
		for _,v in ipairs(aCondList) do
			table.insert(aTooltip, v.sLabel);
		end
		
		if #aTooltip > 0 then
			local w = aWidgets["effect1"];
			if not w then
				w = tokeninstance.addBitmapWidget();
				w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX, TOKEN_EFFECT_OFFSETY);
				w.setName("effect1");
			end
			if w then
				w.setBitmap("cond_generic");
				w.setVisible(bWidgetsVisible);
				w.setTooltipText(table.concat(aTooltip, "\r"));
			end
			for i = 2, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		else
			for i = 1, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		end
	else
		local bWidgetsVisible = (sOptTE == "on");
		
		local aCondList = getConditionIconList(nodeCTEntry);
		local nConds = #aCondList;
		
		local wToken, hToken = tokeninstance.getSize();
		local nMaxToken = math.floor(((wToken - TOKEN_HEALTH_WIDTH - TOKEN_EFFECT_MARGIN) / (TOKEN_EFFECT_WIDTH + TOKEN_EFFECT_MARGIN)) + 0.5);
		if nMaxToken < 1 then
			nMaxToken = 1;
		end
		local nMaxShown = math.min(nMaxToken, TOKEN_MAX_EFFECTS);
		
		local i = 1;
		local nMaxLoop = math.min(nConds, nMaxShown);
		while i <= nMaxLoop do
			local w = aWidgets["effect" .. i];
			if not w then
				w = tokeninstance.addBitmapWidget();
				w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX + ((TOKEN_EFFECT_WIDTH + TOKEN_EFFECT_MARGIN) * (i - 1)), TOKEN_EFFECT_OFFSETY);
				w.setName("effect" .. i);
			end
			if w then
				if i == nMaxLoop and nConds > nMaxLoop then
					w.setBitmap("cond_more");
					local aTooltip = {};
					for j = i, nConds do
						table.insert(aTooltip, aCondList[j].sLabel);
					end
					w.setTooltipText(table.concat(aTooltip, "\r"));
				else
					w.setBitmap(aCondList[i].sIcon);
					w.setTooltipText(aCondList[i].sText);
				end
				w.setVisible(bWidgetsVisible);
			end
			i = i + 1;
		end
		while i <= TOKEN_MAX_EFFECTS do
			local w = aWidgets["effect" .. i];
			if w then
				w.destroy();
			end
			i = i + 1;
		end
	end
end

function getConditionIconList(nodeCTEntry)
	local aIconList = {};

	local rActor = ActorManager.getActor("ct", nodeCTEntry);
	
	-- Iterate through effects
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);

	for k,v in pairs(aSorted) do
		if DB.getValue(v, "isactive", 0) == 1 then
			if User.isHost() or (DB.getValue(v, "isgmonly", 0) == 0) then
				local sLabel = DB.getValue(v, "label", "");
				
				local sEffect = nil;
				local bSame = true;
				local sLastIcon = nil;

				local aEffectComps = EffectsManager.parseEffect(sLabel);
				for kComp,vComp in ipairs(aEffectComps) do
					-- CHECK CONDITIONALS
					if vComp.type == "IF" then
						if not EffectsManager.checkConditional(rActor, v, vComp.remainder) then
							break;
						end
					elseif vComp.type == "IFT" then
						-- Do nothing
					
					else
						local sNewIcon = nil;
						
						-- CHECK FOR A BONUS OR PENALTY
						local sComp = vComp.type;
						if StringManager.contains(DataCommon.bonuscomps, sComp) then
							if #(vComp.dice) > 0 or vComp.mod > 0 then
								sNewIcon = "cond_bonus";
							elseif vComp.mod < 0 then
								sNewIcon = "cond_penalty";
							else
								sNewIcon = "cond_generic";
							end
					
						-- CHECK FOR OTHER VISIBLE EFFECT TYPES
						else
							sNewIcon = DataCommon.othercomps[sComp];
						end
					
						-- CHECK FOR A CONDITION
						if not sNewIcon then
							sComp = vComp.original:gsub("-", ""):lower();
							sNewIcon = DataCommon.condcomps[sComp];
						end
						
						if sNewIcon then
							if bSame then
								if sLastIcon and sLastIcon ~= sNewIcon then
									bSame = false;
								end
								sLastIcon = sNewIcon;
							end
						else
							if kComp == 1 then
								sEffect = vComp.original;
							end
						end
					end
				end
				
				if #aEffectComps > 0 then
					local sFinalIcon;
					if bSame and sLastIcon then
						sFinalIcon = sLastIcon;
					else
						sFinalIcon = "cond_generic";
					end
					
					local sFinalLabel;
					if sEffect then
						sFinalLabel = sEffect;
					else
						sFinalLabel = sLabel;
					end
					
					table.insert(aIconList, { sText = sFinalLabel, sIcon = sFinalIcon, sLabel = sLabel } );
				end
			end
		end
	end
	
	return aIconList;
end

function getWidgetList(tokeninstance, sSubset)
	local aWidgets = {};

	local w = nil;
	if not sSubset or sSubset == "name" then
		for _, vName in pairs({"name", "ordinal"}) do
			w = tokeninstance.findWidget(vName);
			if w then
				aWidgets[vName] = w;
			end
		end
	end
	if not sSubset or sSubset == "health" then
		for _, vName in pairs({"healthbar", "healthdot"}) do
			w = tokeninstance.findWidget(vName);
			if w then
				aWidgets[vName] = w;
			end
		end
	end
	if not sSubset or sSubset == "effect" then
		for i = 1, TOKEN_MAX_EFFECTS do
			w = tokeninstance.findWidget("effect" .. i);
			if w then
				aWidgets["effect" .. i] = w;
			end
		end
	end
	
	return aWidgets;
end
