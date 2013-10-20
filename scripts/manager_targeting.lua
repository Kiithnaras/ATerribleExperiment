-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_REMOVECLIENTTARGET = "removeclienttarget";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_REMOVECLIENTTARGET, handleRemoveClientTarget);
end

function handleRemoveClientTarget(msgOOB)
	TargetingManager.removeClientTarget(msgOOB.user, msgOOB.sourcename, msgOOB.targetnode);
end

function getFullTargets(rActor)
	local sTargetType = "targetct";
	local aTargets = {};
	
	-- CHECK FOR CLIENT OR HOST TARGETING
	if rActor then
		local sTargetType = "client";
		if User.isHost() then
			sTargetType = "host";
		end

		for _,nodeTarget in pairs(DB.getChildren(rActor.nodeCT, "targets")) do
			if DB.getValue(nodeTarget, "type", "") == sTargetType then
				local rTarget = ActorManager.getActor("ct", DB.getValue(nodeTarget, "noderef", ""));
				table.insert(aTargets, rTarget);
			end
		end
	end
	
	return aTargets;
end

function toggleTarget(sTargetType, sSourceNode, sTargetNode)
	local nodeSource = DB.findNode(sSourceNode);
	if nodeSource then
		if isTarget(sTargetType, nodeSource, sTargetNode) then
			removeTarget(sTargetType, nodeSource, sTargetNode);
		else
			addTarget(sTargetType, sSourceNode, sTargetNode);
		end
	end
end

function isTarget(sTargetType, nodeSource, sTargetNode)
	-- CHECK TO SEE IF TARGET ALREADY ON LIST
	for _,v in pairs(DB.getChildren(nodeSource, "targets")) do
		if (DB.getValue(v, "noderef", "") == sTargetNode) and (DB.getValue(v, "type", "") == sTargetType) then
			return true;
		end
	end
	
	-- NO MATCH FOUND
	return false;
end

function addTarget(sTargetType, sSourceNode, sTargetNode)
	-- GET SOURCE NODE
	local nodeSource = DB.findNode(sSourceNode);
	if not nodeSource then
		return;
	end

	-- GET TARGET LIST
	local nodeTargetList = nodeSource.getChild("targets");
	if not nodeTargetList then
		return;
	end
	
	-- CHECK TO SEE IF TARGET ALREADY ON LIST
	for _,nodeTarget in pairs(nodeTargetList.getChildren()) do
		if (DB.getValue(nodeTarget, "noderef", "") == sTargetNode) and 
				(DB.getValue(nodeTarget, "type", "") == sTargetType) then
			return;
		end
	end

	-- ADD THE NEW TARGET TO THE LIST
	local nodeNewTarget = nodeTargetList.createChild();
	if nodeNewTarget then
		DB.setValue(nodeNewTarget, "type", "string", sTargetType);
		DB.setValue(nodeNewTarget, "noderef", "string", sTargetNode);
	end
end

function addFactionTargetsHost(nodeSource, sFaction, bNegated)
	-- VALIDATE
	if not nodeSource then
		return;
	end
	
	-- ITERATE THROUGH TRACKER ENTRIES TO GET FACTION
	for _,nodeEntry in pairs(DB.getChildren("combattracker")) do
		if bNegated then
			if DB.getValue(nodeEntry, "friendfoe", "") ~= sFaction then
				addTarget("host", nodeSource.getNodeName(), nodeEntry.getNodeName());
			end
		else
			if DB.getValue(nodeEntry, "friendfoe", "") == sFaction then
				addTarget("host", nodeSource.getNodeName(), nodeEntry.getNodeName());
			end
		end
	end
end

function addFactionTargetsClient(ctrlImage, bNegated)
	-- VALIDATE
	local sClientID = User.getCurrentIdentity();
	if not sClientID then
		ChatManager.SystemMessage("[WARNING] Unable to target, no active identity selected.");
		return;
	end
	local nodePlayerCT = CTManager.getCTFromNode("charsheet." .. sClientID);
	if not nodePlayerCT then
		ChatManager.SystemMessage("[WARNING] Unable to target, active character is not on combat tracker.");
		return;
	end

	-- GET PLAYER FACTION
	local sFaction = DB.getValue(nodePlayerCT, "friendfoe", "");
	
	-- BUILD AN IMAGE MAP
	local aImageTokenMap = {};
	for kToken, vToken in pairs(ctrlImage.getTokens()) do
		aImageTokenMap[vToken.getId()] = vToken;
	end
	
	-- ITERATE THROUGH CT ENTRIES TO COMPARE FACTION
	for _,nodeEntry in pairs(DB.getChildren("combattracker")) do
		if bNegated then
			if DB.getValue(nodeEntry, "friendfoe", "") ~= sFaction then
				local nTokenID = tonumber(DB.getValue(nodeEntry, "tokenrefid", "")) or 0;
				if aImageTokenMap[nTokenID] then
					-- ONLY TARGET ENEMY TOKENS IF THEY ARE VISIBLE
					if aImageTokenMap[nTokenID].isVisible() then
						aImageTokenMap[nTokenID].setTarget(true, sClientID);
					end
				end
			end
		else
			if DB.getValue(nodeEntry, "friendfoe", "") == sFaction then
				local nTokenID = tonumber(DB.getValue(nodeEntry, "tokenrefid", "")) or 0;
				if aImageTokenMap[nTokenID] then
					aImageTokenMap[nTokenID].setTarget(true, sClientID);
				end
			end
		end
	end
end

function removeTargetEx(nodeSource, sTargetNode)
	if User.isHost() then
		removeTarget("host", nodeSource, sTargetNode);
		removeTarget("client", nodeSource, sTargetNode);
	else
		removeTarget("host", nodeSource, sTargetNode);
	end
end

function removeTarget(sTargetType, nodeSource, sTargetNode)
	if User.isHost() then
		for _,v in pairs(DB.getChildren(nodeSource, "targets")) do
			if (DB.getValue(v, "type", "") == sTargetType) and (DB.getValue(v, "noderef", "") == sTargetNode) then
				if sTargetType == "client" then
					TargetingManager.removeClientTarget("", DB.getValue(nodeSource, "name"), sTargetNode);
				else
					v.delete();
				end
			end
		end
	else
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_REMOVECLIENTTARGET;
		msgOOB.user = User.getUsername();
		msgOOB.sourcename = DB.getValue(nodeSource, "name", "");
		msgOOB.targetnode = sTargetNode;
		
		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function removeClientTarget(msguser, sSourceName, sTargetNode)
	local sSourceIdentity = nil;
	for k, v in ipairs(User.getAllActiveIdentities()) do
		if User.getIdentityLabel(v) == sSourceName then
			sSourceIdentity = v;
			break;
		end
	end
	if not sSourceIdentity then
		local msg = {font = "systemfont"};
		msg.text = "[WARNING] Unable to remove client target, attacker does not match any current client identity";
		Comm.deliverChatMessage(msg, msguser);
		return;
	end
	
	for _,nodeCTEntry in pairs(DB.getChildren("combattracker")) do
		if nodeCTEntry.getNodeName() == sTargetNode then
			local tokenCT = TokenManager.getTokenFromCT(nodeCTEntry);
			if tokenCT then
				tokenCT.setTarget(false, sSourceIdentity);
			end
			break;
		end
	end
end

function removeTargetFromAllEntries(sTargetType, sTargetNode)
	for _,nodeCTEntry in pairs(DB.getChildren("combattracker")) do
		removeTarget(sTargetType, nodeCTEntry, sTargetNode);
		
		for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
			local nodeTargets = nodeEffect.getChild("targets");
			if nodeTargets then
				local bHasTargets = false;
				if nodeTargets.getChildCount() > 0 then
					removeTarget(sTargetType, nodeEffect, sTargetNode);
			
					if nodeTargets.getChildCount() == 0 then
						EffectsManager.expireEffect(nodeCTEntry, nodeEffect, 0, true);
					end
				end
			end
		end
	end
end

function clearTargets(sTargetType, nodeSource)
	for _,nodeTarget in pairs(DB.getChildren(nodeSource, "targets")) do
		if DB.getValue(nodeTarget, "type", "") == sTargetType then
			nodeTarget.delete();
		end
	end
end

function clearTargetsClient(ctrlImage)
	local sClientID = User.getCurrentIdentity();
	if sClientID and ctrlImage then
		for kToken, vToken in pairs(ctrlImage.getTokens()) do
			if vToken.isTargetedByIdentity(sClientID) then
				vToken.setTarget(false, sClientID);
			end
		end
	end
end

function getCTFromIdentity(nodeTracker, sIdentity)
	local sIdentityLabel = User.getIdentityLabel(sIdentity);
	if not sIdentityLabel then
		return nil;
	end
	
	for _,v in pairs(DB.getChildren(nodeTracker, "")) do
		if DB.getValue(v, "type", "") == "pc" then
			if DB.getValue(v, "name", "") == sIdentityLabel then
				return v;
			end
		end
	end
	
	return nil;
end

function rebuildClientTargeting()
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return;
	end
	
	local aClientTargets = {};
	
	for _,nodeEntry in pairs(nodeTracker.getChildren()) do
		-- Clear current target list in window
		clearTargets("client", nodeEntry);
		
		-- Get targeting data from default client targeting support
		local instanceToken = Token.getToken(DB.getValue(nodeEntry, "tokenrefnode", ""), DB.getValue(nodeEntry, "tokenrefid", ""));
		if instanceToken then
			local aTargeting = instanceToken.getTargetingIdentities();
			for i = #aTargeting, 1, -1 do
				local winTargetingCTNode = getCTFromIdentity(nodeTracker, aTargeting[i]);
				if winTargetingCTNode then
					table.insert(aClientTargets, {nodeAttacker = winTargetingCTNode.getNodeName(), nodeDefender = nodeEntry.getNodeName()});
				end
			end
		end
	end

	-- Using the target table, add target to windows
	for keyTarget, rTarget in pairs(aClientTargets) do
		TargetingManager.addTarget("client", rTarget.nodeAttacker, rTarget.nodeDefender);
	end
end
