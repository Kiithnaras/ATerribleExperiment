-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--	
--	DATA STRUCTURES
--
-- rEffect
--		sName = ""
--		nDuration = #
--		sUnits = ""
-- 		nInit = #
--		sSource = ""
--		nGMOnly = 0, 1
--		sApply = "", "action", "roll", "single"
--

function onInit()
	ActionsManager.registerActionIcon("effect", "action_effect");
	ActionsManager.registerTargetingHandler("effect", onTargeting);
	ActionsManager.registerModHandler("effect", modEffect);
	ActionsManager.registerResultHandler("effect", onEffect);
	
	Interface.onHotkeyDrop = onHotkeyDrop;
end

function onTargeting(rSource, rRolls)
	if not rRolls then
		return { {} };
	end
	
	return { getEffectTargets(rSource, rRolls[1]) };
end

function getEffectTargets(rSource, rRoll)
	if not rRoll then
		return {};
	end
	
	if string.match(rRoll.sDesc, "%[SELF%]") then
		return { rSource };
	end
	
	return TargetingManager.getFullTargets(rSource);
end

function onHotkeyDrop(draginfo)
	local rEffect = decodeEffectFromDrag(draginfo);
	if rEffect then
		rEffect.nInit = nil;

		draginfo.setSlot(1);
		draginfo.setStringData(encodeEffectAsText(rEffect));
	end
end

function getRoll(draginfo, rActor, rAction)
	local rRoll = encodeEffect(rAction);
	if rRoll.sDesc == "" then
		return nil, nil;
	end
	
	local rCustom = nil;
	if draginfo and Input.isShiftPressed() then
		local aTargetNodes = {};
		local aTargets = getEffectTargets(rActor, rRoll);
		for _,v in ipairs(aTargets) do
			if v.sCTNode ~= "" then
				table.insert(aTargetNodes, v.sCTNode);
			end
		end
		
		if #aTargetNodes > 0 then
			rCustom = { { sDesc = table.concat(aTargetNodes, "|") } };
		end
	end

	return rRoll, rCustom;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll, rCustom = getRoll(draginfo, rActor, rAction);
	if not rRoll then
		return false;
	end
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "effect", rRoll, rCustom);
	return true;
end

function modEffect(rSource, rTarget, rRoll)
	-- Tell action manager to skip modifier stack
	return true;
end

function onEffect(rSource, rTarget, rRoll, rCustom)
	-- Decode effect from roll
	local rEffect = decodeEffect(rRoll);
	if not rEffect then
		ChatManager.SystemMessage("[ERROR] Unable to decode effect details.");
		return;
	end
	
	-- If no target, then report to chat window and exit
	if not rTarget then
		-- Clear source and init for effect
		rEffect.sSource = nil;
		rEffect.nInit = nil;
		rRoll.sDesc = encodeEffectAsText(rEffect);
		rRoll.nMod = rEffect.nDuration or 0;

		-- Report effect to chat window
		local rMessage = ActionsManager.createActionMessage(nil, rRoll);
		Comm.deliverChatMessage(rMessage);
		
		return;
	end
	
	-- If target not in combat tracker, then we're done
	if not rTarget.nodeCT then
		ChatManager.SystemMessage("[ERROR] Effect dropped on target which is not listed in the combat tracker.");
		return;
	end

	-- If effect is not a CT effect drag, then figure out source and init
	if rEffect.nInit == 0 then
		-- If effect originated from PC, then use PC as source
		if rEffect.sSource == "" then
			if rSource and rSource.sType == "pc" and rSource.nodeCT then
				rEffect.sSource = rSource.sCTNode;
				rEffect.nInit = DB.getValue(rSource.nodeCT, "initresult", 0);
			end
		end
	
		-- If no source defined, then use active identity (client) or active CT entry (host).
		if rEffect.sSource == "" then
			local nodeTempCT = nil;
			if User.isHost() then
				nodeTempCT = CTManager.getActiveCT();
			else
				nodeTempCT = CTManager.getCTFromNode("charsheet." .. User.getCurrentIdentity());
			end
			if nodeTempCT then
				rEffect.sSource = nodeTempCT.getNodeName();
				rEffect.nInit = DB.getValue(nodeTempCT, "initresult", 0);
			end
		end
	end
	
	-- If source is same as target, then don't specify a source
	if rEffect.sSource == rTarget.sCTNode then
		rEffect.sSource = "";
	end
	
	-- Resolve
	-- If shift-dragging, then apply to the source actor targets, then target the effect to the drop target
	if rCustom and rCustom[1] and rCustom[1].sDesc then
		local aTargets = StringManager.split(rCustom[1].sDesc, "|");
		for _,v in ipairs(aTargets) do
			EffectsManager.notifyApply(rEffect, v, rTarget.sCTNode);
		end
	
	-- Otherwise, just apply effect to target normally
	else
		EffectsManager.notifyApply(rEffect, rTarget.sCTNode);
	end
end

--
-- UTILITY FUNCTIONS
--

function decodeEffectFromDrag(draginfo)
	local rEffect = nil;
	
	local sDragType = draginfo.getType();
	local sDragDesc = "";

	local bEffectDrag = false;
	if sDragType == "effect" then
		bEffectDrag = true;
		draginfo.setSlot(2);
		sDragDesc = draginfo.getStringData();
	elseif sDragType == "number" then
		if string.match(sDragDesc, "%[EFFECT") then
			bEffectDrag = true;
			sDragDesc = draginfo.getDescription();
		end
	end
	
	if bEffectDrag then
		rEffect = decodeEffectFromText(sDragDesc);
		if rEffect then
			rEffect.nDuration = draginfo.getNumberData();
		end
	end
	
	return rEffect;
end

function encodeEffect(rAction)
	local rRoll = {};
	rRoll.sDesc = encodeEffectAsText(rAction);
	rRoll.aDice = rAction.aDice or {};
	rRoll.nMod = rAction.nDuration or 0;
	
	return rRoll;
end

function decodeEffect(rRoll)
	local rEffect = decodeEffectFromText(rRoll.sDesc);
	if rEffect then
		rEffect.aDice = rRoll.aDice;
		rEffect.nMod = rRoll.nMod;
		rEffect.nDuration = ActionsManager.total(rRoll);
	end
	
	return rEffect;
end

function encodeEffectAsText(rEffect)
	local aMessage = {};
	
	if rEffect then
		if rEffect.nGMOnly == 1 then
			table.insert(aMessage, "[GM]");
		end

		table.insert(aMessage, "[EFFECT] " .. rEffect.sName);

		if rEffect.nInit and rEffect.nInit ~= 0 then
			table.insert(aMessage, "[INIT " .. rEffect.nInit .. "]");
		end

		if rEffect.sUnits and rEffect.sUnits ~= "" then
			local sOutputUnits = nil;
			if rEffect.sUnits == "minute" then
				sOutputUnits = "MIN";
			elseif rEffect.sUnits == "hour" then
				sOutputUnits = "HR";
			elseif rEffect.sUnits == "day" then
				sOutputUnits = "DAY";
			end

			if sOutputUnits then
				table.insert(aMessage, "[UNITS " .. sOutputUnits .. "]");
			end
		end

		if rEffect.sTargeting and rEffect.sTargeting ~= "" then
			table.insert(aMessage, "[" .. string.upper(rEffect.sTargeting) .. "]");
		end
		
		if rEffect.sApply and rEffect.sApply ~= "" then
			table.insert(aMessage, "[" .. string.upper(rEffect.sApply) .. "]");
		end
		
		if rEffect.sSource and rEffect.sSource ~= "" then
			table.insert(aMessage, "[by " .. rEffect.sSource .. "]");
		end
	end
	
	return table.concat(aMessage, " ");
end

function decodeEffectFromText(sEffect)
	local rEffect = nil;

	local sEffectName = string.match(sEffect, "%[EFFECT%] ([^[]+)");
	if sEffectName then
		rEffect = {};
		
		if string.match(sEffect, "%[GM%]") then
			rEffect.nGMOnly = 1;
		else
			rEffect.nGMOnly = 0;
		end

		rEffect.sName = StringManager.trim(sEffectName);
		
		rEffect.sSource = string.match(sEffect, "%[by ([^]]+)%]") or "";
		
		local sEffectInit = string.match(sEffect, "%[INIT (%d+)%]");
		rEffect.nInit = tonumber(sEffectInit) or 0;

		rEffect.sTargeting = "";
		if string.match(sEffect, "%[SELF%]") then
			rEffect.sTargeting = "self";
		end
		
		rEffect.sApply = "";
		if string.match(sEffect, "%[ACTION%]") then
			rEffect.sApply = "action";
		elseif string.match(sEffect, "%[ROLL%]") then
			rEffect.sApply = "roll";
		elseif string.match(sEffect, "%[SINGLE%]") then
			rEffect.sApply = "single";
		end
		
		rEffect.sUnits = "";
		local sUnits = string.match(sEffect, "%[UNITS ([^]]+)]");
		if sUnits then
			if sUnits == "MIN" then
				rEffect.sUnits = "minute";
			elseif sUnits == "HR" then
				rEffect.sUnits = "hour";
			elseif sUnits == "DAY" then
				rEffect.sUnits = "day";
			end
		end
	end
	
	return rEffect;
end
