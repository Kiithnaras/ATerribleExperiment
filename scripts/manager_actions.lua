-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--  ACTION FLOW
--
--	1. INITIATE ACTION (DRAG OR DOUBLE-CLICK)
--	2. DETERMINE TARGETS (DROP OR TARGETING SUBSYSTEM)
--	3. APPLY MODIFIERS
--	4. PERFORM ROLLS (IF ANY)
--	5. RESOLVE ACTION

-- ROLL
--		.sType
--		.sDesc
--		.aDice
--		.nMod

function onInit()
	Interface.onHotkeyActivated = onHotkey;
end

function onHotkey(draginfo)
	local sDragType = draginfo.getType();
	if StringManager.contains(DataCommon.actions, sDragType) then
		local rSource, rRolls, rCustom = decodeActionFromDrag(draginfo, false);
		handleActionNonDrag(rSource, sDragType, rRolls, rCustom);
		return true;
	end
end

local aActionIcons = {};
function registerActionIcon(sActionType, sIcon)
	aActionIcons[sActionType] = sIcon;
end
function unregisterActionIcon(sActionType)
	if aActionIcons then
		aActionIcons[sActionType] = nil;
	end
end

local aMultiHandlers = {};
function registerMultiHandler(sActionType, callback)
	aMultiHandlers[sActionType] = callback;
end
function unregisterMultiHandler(sRollType)
	if aMultiHandlers then
		aMultiHandlers[sActionType] = nil;
	end
end

function getRollType(sDragType, nSlot)
	for k, v in pairs(aMultiHandlers) do
		if k == sDragType then
			return v(nSlot);
		end
	end

	return sDragType;
end

local aTargetingHandlers = {};
function registerTargetingHandler(sActionType, callback)
	aTargetingHandlers[sActionType] = callback;
end
function unregisterTargetingHandler(sRollType)
	if aTargetingHandlers then
		aTargetingHandlers[sActionType] = nil;
	end
end

local aModHandlers = {};
function registerModHandler(sActionType, callback)
	aModHandlers[sActionType] = callback;
end
function unregisterModHandler(sRollType)
	if aModHandlers then
		aModHandlers[sActionType] = nil;
	end
end

local aPostRollHandlers = {};
function registerPostRollHandler(sActionType, callback)
	aPostRollHandlers[sActionType] = callback;
end
function unregisterPostRollHandler(sRollType)
	if aPostRollHandlers then
		aPostRollHandlers[sActionType] = nil;
	end
end

local aResultHandlers = {};
function registerResultHandler(sActionType, callback)
	aResultHandlers[sActionType] = callback;
end
function unregisterResultHandler(sRollType)
	if aResultHandlers then
		aResultHandlers[sActionType] = nil;
	end
end


--
--  INITIATE ACTION
--

function performSingleRollAction(draginfo, rActor, sType, rRoll, rCustom, bOverride)
	if not rRoll then
		return;
	end
	
	performMultiRollAction(draginfo, rActor, sType, { rRoll }, rCustom, bOverride);
end

function performMultiRollAction(draginfo, rActor, sType, rRolls, rCustom, bOverride)
	if not rRolls or #rRolls < 1 then
		return false;
	end
	
	if not bOverride then
		if draginfo then
			local bOptionDRGR = OptionsManager.getOption("DRGR");
			if bOptionDRGR ~= "on" then
				draginfo.setType("number");
				draginfo.setSlot(1);
				draginfo.setDescription(rRolls[1].sDesc);
				draginfo.setNumberData(rRolls[1].nMod);
				return true;
			end
		else
			local bOptionDCLK = OptionsManager.getOption("DCLK");
			if bOptionDCLK ~= "on" then
				if bOptionDCLK == "mod" then
					ModifierStack.addSlot(rRolls[1].sDesc, rRolls[1].nMod);
				end
				return true;
			end
		end
	end
		
	if draginfo then
		encodeActionForDrag(draginfo, rActor, sType, rRolls, rCustom);
	else
		handleActionNonDrag(rActor, sType, rRolls, rCustom);
	end
	
	return true;
end

function encodeActionForDrag(draginfo, rSource, sType, rRolls, rCustom)
	draginfo.setType(sType);

	if aActionIcons[sType] then
		draginfo.setIcon(aActionIcons[sType]);
	end
	if #rRolls == 1 then
		draginfo.setDescription(rRolls[1].sDesc);
	end
	
	draginfo.setSlot(1);
	draginfo.setNumberData(#rRolls);
	if rSource then
		if rSource.sCTNode ~= "" then
			draginfo.setShortcutData("combattracker_entry", rSource.sCTNode);
		elseif rSource.sCreatureNode ~= "" then
			if rSource.sType == "pc" then
				draginfo.setShortcutData("charsheet", rSource.sCreatureNode);
			elseif rSource.sType == "npc" then
				draginfo.setShortcutData("npc", rSource.sCreatureNode);
			end
		end
	end
	
	local nStart = 1;
	for kRoll, vRoll in ipairs(rRolls) do
		draginfo.setSlot(kRoll + nStart);

		draginfo.setStringData(vRoll.sDesc);
		draginfo.setDieList(vRoll.aDice);
		draginfo.setNumberData(vRoll.nMod);
	end

	if rCustom then
		nStart = nStart + #rRolls;
		for kCustom, vCustom in ipairs(rCustom) do
			draginfo.setSlot(kCustom + nStart);

			draginfo.setStringData(vCustom.sDesc or "");
			draginfo.setDieList(vCustom.aDice or {});
			draginfo.setNumberData(vCustom.nMod or 0);
			draginfo.setShortcutData(vCustom.sClass or "", vCustom.sRecord or "");
		end
	end
end

function processPercentiles(draginfo)
	local aDragDieList = draginfo.getDieList();
	if not aDragDieList then
		return nil;
	end

	local aD100Indexes = {};
	local aD10Indexes = {};
	for k, v in pairs(aDragDieList) do
		if v["type"] == "d100" then
			table.insert(aD100Indexes, k);
		elseif v["type"] == "d10" then
			table.insert(aD10Indexes, k);
		end
	end

	local nMaxMatch = #aD100Indexes;
	if #aD10Indexes < nMaxMatch then
		nMaxMatch = #aD10Indexes;
	end
	if nMaxMatch <= 0 then
		return aDragDieList;
	end
	
	local nMatch = 1;
	local aNewDieList = {};
	for k, v in pairs(aDragDieList) do
		if v["type"] == "d100" then
			if nMatch > nMaxMatch then
				table.insert(aNewDieList, v);
			else
				v["result"] = aDragDieList[aD100Indexes[nMatch]]["result"] + aDragDieList[aD10Indexes[nMatch]]["result"];
				table.insert(aNewDieList, v);
				nMatch = nMatch + 1;
			end
		elseif v["type"] == "d10" then
			local bInsert = true;
			for i = 1, nMaxMatch do
				if aD10Indexes[i] == k then
					bInsert = false;
				end
			end
			if bInsert then
				table.insert(aNewDieList, v);
			end
		else
			table.insert(aNewDieList, v);
		end
	end

	return aNewDieList;
end

function decodeMetadataFromDrag(draginfo)
	local nSlots = draginfo.getSlotCount();
	
	draginfo.setSlot(1);

	local nRolls = draginfo.getNumberData();
	if nRolls > nSlots - 1 then
		nRolls = nSlots - 1;
	end

	local rSource, aTargets = ActorManager.decodeActors(draginfo);
	
	return rSource, aTargets, nSlots, nRolls;
end

function decodeRollsFromDrag(draginfo, nRolls, bDrag, bFinal)
	local rRolls = {};
	
	local sDragType = draginfo.getType();
	local sDescMain = draginfo.getDescription();

	for i = 1, nRolls do
		if bDrag then
			draginfo.setSlot(i + 1);
		else
			draginfo.setSlot(i);
		end
		
		local sType = getRollType(sDragType, i);
		local sDesc = draginfo.getStringData();
		if bFinal and sDesc == "" then
			sDesc = sDescMain;
		end
		local nMod = draginfo.getNumberData();
		
		local aDice = {};
		if bFinal then
			aDice = processPercentiles(draginfo) or {};
		else
			local aDragDice = draginfo.getDieList();
			if aDragDice then
				for k, v in pairs(aDragDice) do
					if type(v) == "string" then
						table.insert(aDice, v);
					elseif type(v) == "table" then
						table.insert(aDice, v["type"]);
					end
				end
			end
		end
		
		table.insert(rRolls, { sType = sType, sDesc = sDesc, aDice = aDice, nMod = nMod });
	end
	
	return rRolls;
end

function decodeCustomFromDrag(draginfo, nRolls, nSlots)
	local rCustom = {};

	for i = nRolls + 2, nSlots do
		draginfo.setSlot(i);
		
		local sDesc = draginfo.getStringData();
		local nMod = draginfo.getNumberData();
		
		local aDice = {};
		local aDragDice = draginfo.getDieList();
		if aDragDice then
			for k, v in pairs(aDragDice) do
				if type(v) == "string" then
					table.insert(aDice, v);
				elseif type(v) == "table" then
					table.insert(aDice, v["type"]);
				end
			end
		end

		local sClass, sRecord = draginfo.getShortcutData();

		table.insert(rCustom, { sDesc = sDesc, aDice = aDice, nMod = nMod, sClass = sClass, sRecord = sRecord });
	end
	
	return rCustom;
end

function decodeActionFromDrag(draginfo, bFinal)
	local rSource, aTargets = ActorManager.decodeActors(draginfo);
	local nSlots = draginfo.getSlotCount();
	draginfo.setSlot(1);

	local rRolls = {};
	local rCustom = nil;
	if nSlots == 1 then
		rRolls = decodeRollsFromDrag(draginfo, 1, false, bFinal);
		local aCustom = draginfo.getCustomData();
		if aCustom and aCustom["custom"] then
			rCustom = aCustom["custom"];
		end
	else
		local nRolls = draginfo.getNumberData();
		if nRolls > nSlots - 1 then
			nRolls = nSlots - 1;
		end
		rRolls = decodeRollsFromDrag(draginfo, nRolls, true, bFinal);
		rCustom = decodeCustomFromDrag(draginfo, nRolls, nSlots);
	end
	
	return rSource, rRolls, rCustom, aTargets;
end

--
--  DETERMINE TARGETS
--

function handleActionDrop(draginfo, rTarget)
	if rTarget then
		local sDragType = draginfo.getType();
		local rSource, rRolls, rCustom = decodeActionFromDrag(draginfo, false);

		local bModStackUsed = false;
		lockModifiers();

		for k,v in ipairs(rRolls) do
			local sType = getRollType(sDragType, k);
			if applyModifiersAndRoll(rSource, rTarget, false, sType, v, rCustom) then
				bModStackUsed = true;
			end
		end

		unlockModifiers(bModStackUsed);
	else
		handleDragDrop(draginfo, true);
	end
end

function handleActionNonDrag(rActor, sDragType, rRolls, rCustom, aTargeting)
	if not aTargeting then
		local aExtraCustom = nil;
		for k, v in pairs(aTargetingHandlers) do
			if k == sDragType then
				aTargeting, aExtraCustom = v(rActor, rRolls);
				break;
			end
		end
		if not aTargeting then
			aTargeting = {};
		end
	end
	if #aTargeting == 0 then
		table.insert(aTargeting, {});
	end
	
	local bModStackUsed = false;
	lockModifiers();
	
	for kTargets,vTargets in ipairs(aTargeting) do
		for kRoll,vRoll in ipairs(rRolls) do
			local sType = getRollType(sDragType, kRoll);
			
			if aExtraCustom and aExtraCustom[kTargets] then
				if not rCustom then
					rCustom = {};
				end
				for kExtraCustom,vExtraCustom in pairs(aExtraCustom[kTargets]) do
					rCustom[kExtraCustom] = vExtraCustom;
				end
			end
			
			if applyModifiersAndRoll(rActor, vTargets, true, sType, vRoll, rCustom) then
				bModStackUsed = true;
			end

			if aExtraCustom and aExtraCustom[kTargets] then
				for kExtraCustom,_ in pairs(aExtraCustom[kTargets]) do
					rCustom[kExtraCustom] = nil;
				end
			end
		end
	end
	
	unlockModifiers(bModStackUsed);
end

--
--  APPLY MODIFIERS
--

function applyModifiersAndRoll(rSource, vTarget, bMultiTarget, sType, rRoll, rCustom)
	local rNewRoll = {};
	rNewRoll.sType = sType;
	rNewRoll.sDesc = rRoll.sDesc;
	rNewRoll.aDice = {};
	for _,vDie in ipairs(rRoll.aDice) do
		table.insert(rNewRoll.aDice, vDie);
	end
	rNewRoll.nMod = rRoll.nMod;

	-- Only apply non-target specific modifiers before roll
	local bModStackUsed = false;
	if bMultiTarget then
		if vTarget and #vTarget > 1 then
			bModStackUsed = applyModifiers(rSource, nil, rNewRoll, rCustom);
		elseif vTarget and #vTarget == 1 then
			bModStackUsed = applyModifiers(rSource, vTarget[1], rNewRoll, rCustom);
		else
			bModStackUsed = applyModifiers(rSource, nil, rNewRoll, rCustom);
		end
	else
		bModStackUsed = applyModifiers(rSource, vTarget, rNewRoll, rCustom);
	end
	
	roll(rSource, vTarget, rNewRoll, rCustom, bMultiTarget);
	
	return bModStackUsed;
end

function handleDragDrop(draginfo, bResolveIfNoDice)
	local bModStackUsed = false;
	lockModifiers();
	
	local sDragType = draginfo.getType();
	local nSlots = draginfo.getSlotCount();
	
	local nSlotAdj = 0;
	local nRolls = 1;
	local rCustom = nil;
	local rSource = nil;
	local aTargets = {};

	draginfo.setSlot(1);
	if nSlots == 1 then
		local aCustom = draginfo.getCustomData();
		if aCustom and aCustom["custom"] then
			rCustom = aCustom["custom"];
		end
	else
		nSlotAdj = 1;
		nRolls = draginfo.getNumberData();
		if nRolls > nSlots - 1 then
			nRolls = nSlots - 1;
		end
		rSource, aTargets = ActorManager.decodeActors(draginfo);
		rCustom = decodeCustomFromDrag(draginfo, nRolls, nSlots);
	end
	
	for i = 1, nRolls do
		draginfo.setSlot(i + nSlotAdj);
		
		local sType = getRollType(sDragType, i);
		if applyModifiersToDragSlot(draginfo, rSource, sType, rCustom, bResolveIfNoDice) then
			bModStackUsed = true;
		end
	end
	
	unlockModifiers(bModStackUsed);
end

function applyModifiersToDragSlot(draginfo, rSource, sType, rCustom, bResolveIfNoDice)
	local rRoll = {};
	rRoll.sType = sType;
	rRoll.sDesc = draginfo.getStringData();
	rRoll.aDice = draginfo.getDieList() or {};
	rRoll.nMod = draginfo.getNumberData();
	
	local nDice = #(rRoll.aDice);
	local bModStackUsed = applyModifiers(rSource, nil, rRoll, rCustom);
	local nNewDice = #(rRoll.aDice);
	
	if bResolveIfNoDice and #(rRoll.aDice) == 0 then
		resolveAction(rSource, nil, rRoll, rCustom);
	else
		draginfo.setStringData(rRoll.sDesc);
		for i = nDice + 1, nNewDice do
			draginfo.addDie(rRoll.aDice[i]);
		end
		draginfo.setNumberData(rRoll.nMod);
	end
	
	return bModStackUsed;
end

function lockModifiers()
	ModifierStack.lock();
	EffectsManager.lock();
end

function unlockModifiers(bReset)
	ModifierStack.unlock(bReset);
	EffectsManager.unlock();
end

function applyModifiers(rSource, rTarget, rRoll, rCustom, bSkipModStack)	
	local bAddModStack = (#(rRoll.aDice) > 0);
	if bSkipModStack then
		bAddModStack = false;
	end

	for k, v in pairs(aModHandlers) do
		if k == rRoll.sType then
			if v(rSource, rTarget, rRoll, rCustom) then
				bAddModStack = false;
			end
			break;
		end
	end

	if bAddModStack then
		local bDescNotEmpty = (rRoll.sDesc ~= "");
		local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);
		
		if sStackDesc ~= "" then
			if bDescNotEmpty then
				rRoll.sDesc = rRoll.sDesc .. " (" .. sStackDesc .. ")";
			else
				rRoll.sDesc = sStackDesc;
			end
		end
		rRoll.nMod = rRoll.nMod + nStackMod;
	end
	
	return bAddModStack;
end

--
--	RESOLVE DICE
--

function roll(rSource, vTargets, rRoll, rCustom, bMultiTarget)
	if #(rRoll.aDice) > 0 then
		local aCustom = ActorManager.encodeActors(rSource, vTargets, bMultiTarget);
		aCustom["custom"] = rCustom;
		Comm.throwDice(rRoll.sType, rRoll.aDice, rRoll.nMod, rRoll.sDesc, aCustom);
	else
		if bMultiTarget then
			if vTargets and #vTargets > 1 then
				for kTarget, rTarget in ipairs(vTargets) do
					rTarget.nOrder = kTarget;
					resolveAction(rSource, rTarget, rRoll, rCustom); 
				end
			elseif vTargets and #vTargets == 1 then
				resolveAction(rSource, vTargets[1], rRoll, rCustom);
			else
				resolveAction(rSource, nil, rRoll, rCustom);
			end
		else
			resolveAction(rSource, vTargets, rRoll, rCustom);
		end
	end
end 

function onDiceLanded(draginfo)
	local sDragType = draginfo.getType();
	if StringManager.contains(DataCommon.actions, sDragType) then
		local rSource, rRolls, rCustom, aTargets = decodeActionFromDrag(draginfo, true);
		
		for kRoll,vRoll in ipairs(rRolls) do
			if #(vRoll.aDice) > 0 then
				for kHandler,vHandler in pairs(aPostRollHandlers) do
					if kHandler == vRoll.sType then
						vHandler(rSource, vRoll, rCustom);
						break;
					end
				end
				
				if #aTargets == 0 then
					resolveAction(rSource, nil, vRoll, rCustom);
				elseif #aTargets == 1 then
					resolveAction(rSource, aTargets[1], vRoll, rCustom);
				else
					for kTarget, rTarget in ipairs(aTargets) do
						rTarget.nOrder = kTarget;
						resolveAction(rSource, rTarget, vRoll, rCustom);
					end
				end
			end
		end
		
		return true;
	end
end

-- 
--  RESOLVE ACTION
--  (I.E. DISPLAY CHAT MESSAGE, COMPARISONS, ETC.)
--

function resolveAction(rSource, rTarget, rRoll, rCustom)
	-- Handle target specific modifiers for single roll, multiple target scenario
	if rTarget and rTarget.nOrder then
		applyModifiers(rSource, rTarget, rRoll, rCustom, true);
	end

	for k, v in pairs(aResultHandlers) do
		if k == rRoll.sType then
			v(rSource, rTarget, rRoll, rCustom);
			return;
		end
	end
	
	local rMessage = createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

function createActionMessage(rSource, rRoll)
	-- Handle GM flag and TOWER flag
	local isDiceTower = string.match(rRoll.sDesc, "^%[TOWER%]");
	local isGMOnly = string.match(rRoll.sDesc, "^%[GM%]");

	-- Handle forced player name add
	local sDesc = rRoll.sDesc;
	local bAddName = false;
	if string.match(rRoll.sDesc, "%[ADDNAME%] ") then
		sDesc = sDesc:gsub("%[ADDNAME%] ", "");
		bAddName = true;
	end

	-- Build the basic message to deliver
	local rMessage;
	if isDiceTower then
		rMessage = ChatManager.createBaseMessage(nil);
		rMessage.text = rMessage.text .. sDesc;
	elseif isGMOnly then
		rMessage = ChatManager.createBaseMessage(rSource, bAddName);
		rMessage.text = rMessage.text .. string.sub(sDesc, 6);
	else
		rMessage = ChatManager.createBaseMessage(rSource, bAddName);
		rMessage.text = rMessage.text .. sDesc;
	end
	rMessage.dice = rRoll.aDice;
	rMessage.diemodifier = rRoll.nMod;
	
	-- Check to see if this roll should be secret (GM or dice tower tag)
	if isDiceTower then
		rMessage.dicesecret = true;
		rMessage.sender = "";
		rMessage.icon = "dicetower_icon";
	elseif isGMOnly then
		rMessage.dicesecret = true;
		rMessage.text = "[GM] " .. rMessage.text;
	elseif User.isHost() and OptionsManager.isOption("REVL", "off") then
		rMessage.dicesecret = true;
		rMessage.text = "[GM] " .. rMessage.text;
	end
	
	-- Show total if option enabled
	if OptionsManager.isOption("TOTL", "on") and #(rRoll.aDice) > 0 then
		rMessage.dicedisplay = 1;
	end
	
	return rMessage;
end

function total(rRoll)
	local nTotal = 0;

	for k, v in ipairs(rRoll.aDice) do
		nTotal = nTotal + v.result;
	end
	nTotal = nTotal + rRoll.nMod;
	
	return nTotal;
end

function messageResult(bGMOnly, rSource, rTarget, rMessageLong, rMessageShort)
	if bGMOnly then
		rMessageLong.text = "[GM] " .. rMessageLong.text;
		Comm.deliverChatMessage(rMessageLong, "");
	else
		local bShowResultsToPlayer;
		local sOptSHRR = OptionsManager.getOption("SHRR");
		if sOptSHRR == "off" then
			bShowResultsToPlayer = false;
		elseif sOptSHRR == "pc" then
			if (not rSource or rSource.sType == "pc") and (not rTarget or rTarget.sType == "pc") then
				bShowResultsToPlayer = true;
			else
				bShowResultsToPlayer = false;
			end
		else
			bShowResultsToPlayer = true;
		end

		if bShowResultsToPlayer then
			Comm.deliverChatMessage(rMessageLong);
		else
			rMessageLong.text = "[GM] " .. rMessageLong.text;
			Comm.deliverChatMessage(rMessageLong, "");

			if User.isHost() then
				local aUsers = User.getActiveUsers();
				if #aUsers > 0 then
					Comm.deliverChatMessage(rMessageShort, aUsers);
				end
			else
				Comm.addChatMessage(rMessageShort);
			end
		end
	end
end
