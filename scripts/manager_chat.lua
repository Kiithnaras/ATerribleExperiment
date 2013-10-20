-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
	if User.isHost() then
		Module.onActivationRequested = moduleActivationRequested;
	end
	Module.onUnloadedReference = moduleUnloadedReference;

	Comm.registerSlashHandler("die", processDie);
	Comm.registerSlashHandler("mod", processMod);

	if User.isHost() then
		Comm.registerSlashHandler("importchar", processImport);
		Comm.registerSlashHandler("exportchar", processExport);
	end
end

--
-- MODULE NOTIFICATIONS
--

function moduleActivationRequested(sModule)
	local msg = {};
	msg.text = "Players have requested permission to load '" .. sModule .. "'";
	msg.font = "systemfont";
	msg.icon = "indicator_moduleloaded";
	Comm.addChatMessage(msg);
end

function moduleUnloadedReference(sModule)
	local msg = {};
	msg.text = "Could not open sheet with data from unloaded module '" .. sModule .. "'";
	msg.font = "systemfont";
	Comm.addChatMessage(msg);
end

--
-- Chat entry control registration for auto-complete
--

function registerEntryControl(ctrl)
	entrycontrol = ctrl;
	ctrl.onSlashCommand = onSlashCommand;
end

--
-- LAUNCH MESSAGES
--

launchmsg = {};

function registerLaunchMessage(msg)
	table.insert(launchmsg, msg);
end

function retrieveLaunchMessages()
	return launchmsg;
end

--
-- SLASH COMMAND HANDLER
--

function onSlashCommand(command, parameters)
	SystemMessage("SLASH COMMANDS [required] <optional>");
	SystemMessage("----------------");
	if User.isHost() then
		SystemMessage("/clear");
		SystemMessage("/console");
		SystemMessage("/day");
		SystemMessage("/die [NdN+N] <message>");
		SystemMessage("/emote [message]");
		SystemMessage("/export");
		SystemMessage("/exportchar");
		SystemMessage("/exportchar [name]");
		SystemMessage("/flushdb");
		SystemMessage("/gmid [name]");
		SystemMessage("/identity [name]");
		SystemMessage("/importchar");
		SystemMessage("/lighting [RGB hex value]");
		SystemMessage("/mod [N] <message>");
		SystemMessage("/mood [mood] <message>");
		SystemMessage("/mood ([multiword mood]) <message>");
		SystemMessage("/ooc [message]");
		SystemMessage("/night");
		SystemMessage("/reload");
		SystemMessage("/reply [message]");
		SystemMessage("/save");
		SystemMessage("/scaleui [50-200]");
		SystemMessage("/story [message]");
		SystemMessage("/vote <message>");
		SystemMessage("/whisper [character] [message]");
	else
		SystemMessage("/action [message]");
		SystemMessage("/console");
		SystemMessage("/die [NdN+N] <message>");
		SystemMessage("/emote [message]");
		SystemMessage("/mod [N] <message>");
		SystemMessage("/mood [mood] <message>");
		SystemMessage("/mood ([multiword mood]) <message>");
		SystemMessage("/ooc [message]");
		SystemMessage("/reply [message]");
		SystemMessage("/save");
		SystemMessage("/scaleui [50-200]");
		SystemMessage("/vote <message>");
		SystemMessage("/whisper GM [message]");
		SystemMessage("/whisper [character] [message]");
	end
end

--
-- AUTO-COMPLETE
--

function searchForIdentity(sSearch)
	for _, sIdentity in ipairs(User.getAllActiveIdentities()) do
		local sLabel = User.getIdentityLabel(sIdentity);
		if string.find(string.lower(sLabel), string.lower(sSearch), 1, true) == 1 then
			if User.getIdentityOwner(sIdentity) then
				return sIdentity;
			end
		end
	end

	return nil;
end

function doAutocomplete()
	local buffer = entrycontrol.getValue();
	if buffer == "" then 
		return ;
	end

	-- Parse the string, adding one chunk at a time, looking for the maximum possible match
	local sReplacement = nil;
	local nStart = 2;
	while not sReplacement do
		local nSpace = string.find(string.reverse(buffer), " ", nStart, true);

		if nSpace then
			local sSearch = string.sub(buffer, #buffer - nSpace + 2);

			if not string.match(sSearch, "^%s$") then
				local sIdentity = searchForIdentity(sSearch);
				if sIdentity then
					local sRemainder = string.sub(buffer, 1, #buffer - nSpace + 1);
					sReplacement = sRemainder .. User.getIdentityLabel(sIdentity) .. " ";
					break;
				end
			end
		else
			local sIdentity = searchForIdentity(buffer);
			if sIdentity then
				sReplacement = User.getIdentityLabel(sIdentity) .. " ";
				break;
			end
			
			return;
		end

		nStart = nSpace + 1;
	end

	if sReplacement then
		entrycontrol.setValue(sReplacement);
		entrycontrol.setCursorPosition(#sReplacement + 1);
		entrycontrol.setSelectionPosition(#sReplacement + 1);
	end
end

--
-- DICE AND MOD SLASH HANDLERS
--

function processDie(sCommand, sParams)
	if User.isHost() then
		if sParams == "reveal" then
			OptionsManager.setOption("REVL", "on");
			SystemMessage("Revealing all die rolls");
			return;
		end
		if sParams == "hide" then
			OptionsManager.setOption("REVL", "off");
			SystemMessage("Hiding all die rolls");
			return;
		end
	end

	local sDice, sDesc = string.match(sParams, "%s*(%S+)%s*(.*)");
	
	if not StringManager.isDiceString(sDice) then
		SystemMessage("Usage: /die [dice] [description]");
		return;
	end
	
	local aDice, nMod = StringManager.convertStringToDice(sDice);
	
	local rRolls = {};
	local rRoll = { sType = "dice", sDesc = sDesc, aDice = aDice, nMod = nMod };
	table.insert(rRolls, rRoll);
	ActionsManager.handleActionNonDrag(nil, "dice", rRolls);
end

function processMod(sCommand, sParams)
	local sMod, sDesc = string.match(sParams, "%s*(%S+)%s*(.*)");
	
	local nMod = tonumber(sMod);
	if not nMod then
		SystemMessage("Usage: /mod [number] [description]");
		return;
	end
	
	ModifierStack.addSlot(sDesc, nMod);
end

function handleImport()
	local sFile = Interface.dialogFileOpen();
	if sFile then
		DB.import(sFile, "charsheet", "character");
	end
end

function processImport(sCommand, sParams)
	CharManager.import();
end

function processExport(sCommand, sParams)
	local nodeChar = nil;
	
	local sFind = StringManager.trim(sParams);
	if string.len(sFind) > 0 then
		for _,vChar in pairs(DB.getChildren("charsheet")) do
			local sChar = DB.getValue(vChar, "name", "");
			if string.len(sChar) > 0 then
				if string.lower(sFind) == string.lower(string.sub(sChar, 1, string.len(sFind))) then
					nodeChar = vChar;
					break;
				end
			end
		end
		if not nodeChar then
			SystemMessage("Unable to find character requested for export. (" .. sParams .. ")");
			return;
		end
	end
	
	CharManager.export(nodeChar);
end

--
--
-- MESSAGES
--
--

function createBaseMessage(rSource, bAddName)
	-- Set up the basic message components
	local msg = {font = "systemfont", text = "", dicesecret = false};

	-- PORTRAIT CHAT?
	local bShowPortrait = false;
	if OptionsManager.isOption("PCHT", "on") then
		msg.icon = getPortraitChatIcon(rSource);
		bShowPortrait = true;
	end

	-- GET SOURCE ACTOR NAME
	local bShowActorName = false;
	if rSource then
		local sOptionShowRoll = OptionsManager.getOption("SHRL");
		if bAddName or (sOptionShowRoll == "all") or ((sOptionShowRoll == "pc") and (rSource.sType == "pc")) then
			msg.text = rSource.sName .. " -> " .. msg.text;
			bShowActorName = true;
		end
	end
	
	-- DETERMINE WHETHER TO SHOW USER ID
	if User.isHost() then
		if not bShowActorName then
			local sGMID, bDefaultID = GmIdentityManager.getCurrent();
			
			if not bShowPortrait or not bDefaultID then
				msg.sender = sGMID;
			end
		end
	else
		if not bShowPortrait and not bShowActorName then
			msg.sender = User.getIdentityLabel();
		end
	end
	
	-- RESULTS
	return msg;
end

-- Get portrait icon
function getPortraitChatIcon(rSource)
	if User.isHost() then
		return "portrait_gm_token";
	else
		if rSource and rSource.sType == "pc" and rSource.nodeCreature then
			return "portrait_" .. rSource.nodeCreature.getName() .. "_chat";
		else
			local sIdentity = User.getCurrentIdentity();
			if sIdentity then
				return "portrait_" .. User.getCurrentIdentity() .. "_chat";
			end
		end
	end
	
	return nil;
end

-- Message: prints a message in the Chatwindow
function Message(msgtxt, broadcast, rActor)
	local msg = createBaseMessage(rActor);
	msg.text = msg.text .. msgtxt;

	if broadcast then
		Comm.deliverChatMessage(msg);
	else
		Comm.addChatMessage(msg);
	end
end

-- SystemMessage: prints a message in the Chatwindow
function SystemMessage(msgtxt)
	local msg = {font = "systemfont"};
	msg.text = msgtxt;
	Comm.addChatMessage(msg);
end
