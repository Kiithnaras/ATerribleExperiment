-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aUserStates = {};

OOB_MSGTYPE_SETAFK = "setafk";

function onInit()
	-- Set callbacks for user activity
	if User.isHost() then
		User.onLogin = onLogin;
	end
	User.onUserStateChange = onUserStateChange;
	User.onIdentityActivation = onIdentityActivation;
	User.onIdentityStateChange = onIdentityStateChange;

	Comm.registerSlashHandler("afk", processAFK);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_SETAFK, handleAFK);
end

function addUserAccess(sNode, username)
	local node = DB.createNode(sNode);
	if node then
		node.addHolder(username);
	end
end

function onLogin(username, bActivated)
	if bActivated then
		addUserAccess("options", username);
		addUserAccess("partysheet", username);
		addUserAccess("calendar.current", username);
		addUserAccess("calendar.data", username);
		addUserAccess("calendar.log", username);
		addUserAccess("combattracker", username);
		addUserAccess("combattracker_props", username);
		addUserAccess("modifiers", username);
		addUserAccess("effects", username);
	end
end

function onClose()
	-- Remove holder information from shared nodes to reduce DB clutter
	if User.isHost() then
		DB.removeAllHolders("options", false);
		DB.removeAllHolders("partysheet", false);
		DB.removeAllHolders("calendar", false);
		DB.removeAllHolders("combattracker", false);
		DB.removeAllHolders("combattracker_props", false);
		DB.removeAllHolders("modifiers", false);
		DB.removeAllHolders("effects", false);
	end
end

function findControlForIdentity(identity)
	return self["ctrl_" .. identity];
end

function controlSortCmp(t1, t2)
	return t1.name < t2.name;
end

function layoutControls()
	local identitylist = {};
	
	for key, val in pairs(User.getAllActiveIdentities()) do
		table.insert(identitylist, { name = val, control = findControlForIdentity(val) });
	end
	
	table.sort(identitylist, controlSortCmp);

	local n = 0;
	for key, val in pairs(identitylist) do
		val.control.sendToBack();
	end
	
	anchor.sendToBack();
end

function onUserStateChange(sUser, sStateName, nState)
	if sUser ~= "" then
		if not aUserStates[sUser] then
			aUserStates[sUser] = "active";
		end
		
		if sStateName == "active" or sStateName == "idle" then
			if aUserStates[sUser] ~= "afk" then
				aUserStates[sUser] = sStateName;
			end
		elseif sStateName == "typing" then
			if aUserStates[sUser] == "afk" and sUser == User.getUsername() then
				aUserStates[sUser] = "typing"
				messageAFK(sUser);
			else
				aUserStates[sUser] = "typing"
			end
		end
		
		local sIdentity = User.getCurrentIdentity(sUser);
		if sIdentity then
			local ctrl = findControlForIdentity(sIdentity);
			if ctrl then
				ctrl.setActiveState(aUserStates[sUser]);
			end
		end
	end
end

function onIdentityActivation(sIdentity, sUser, bActivated)
	if bActivated then
		if not findControlForIdentity(sIdentity) then
			createControl("characterlist_entry", "ctrl_" .. sIdentity);
			
			userctrl = findControlForIdentity(sIdentity);
			if userctrl then
				userctrl.createWidgets(sIdentity);
			end

			layoutControls();
		end
		
		if not User.isHost() then
			DiceTowerManager.activate();
		end
	else
		local ctrl = findControlForIdentity(sIdentity);
		if ctrl then
			ctrl.destroy();
			layoutControls();
		end
	end
end

function onIdentityStateChange(sIdentity, sUser, sStateName, vState)
	local ctrl = findControlForIdentity(sIdentity);
	if ctrl then
		if sStateName == "current" then
			ctrl.setCurrent(vState, sUserState);
		elseif sStateName == "label" then
			ctrl.setName(vState);
		elseif sStateName == "color" then
			ctrl.updateColor();
		end
	end
end

function toggleAFK()
	local sUser = User.getUsername();
	
	if aUserStates[sUser] == "afk" then
		aUserStates[sUser] = "active";
	else
		aUserStates[sUser] = "afk";
	end
	
	local sIdentity = User.getCurrentIdentity();
	 if sIdentity then
		local ctrl = findControlForIdentity(sIdentity);
		 if ctrl then
			ctrl.setActiveState(aUserStates[sUser]);
		end
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_SETAFK;
	msgOOB.user = sUser;
	if aUserStates[sUser] == "afk" then
		msgOOB.nState = 1;
	else
		msgOOB.nState = 0;
	end

	Comm.deliverOOBMessage(msgOOB);
end

function processAFK(sCommand, sParams)
	toggleAFK();
end

function handleAFK(msgOOB)
	if not aUserStates[msgOOB.user] then
		aUserStates[msgOOB.user] = "active";
	end
	
	local sIdentity = User.getCurrentIdentity(msgOOB.user);
	if sIdentity then
		local ctrl = findControlForIdentity(sIdentity);
		if ctrl then
			if msgOOB.nState == "0" then
				aUserStates[msgOOB.user] = "active";
			else
				aUserStates[msgOOB.user] = "afk";
			end
			
			ctrl.setActiveState(aUserStates[msgOOB.user]);
		end
		
		messageAFK(msgOOB.user);
	end
end

function messageAFK(sUser)
	local msg = {font = "systemfont"};
	if aUserStates[sUser] == "afk" then
		msg.text = "User '" .. sUser .. "' has gone AFK.";
	else
		msg.text = "User '" .. sUser .. "' is back.";
	end
	Comm.addChatMessage(msg);
end