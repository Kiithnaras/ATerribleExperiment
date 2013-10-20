-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local control = nil;
OOB_MSGTYPE_DICETOWER = "dicetower";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DICETOWER, handleDiceTower);
end

function registerControl(ctrl)
	control = ctrl;
	activate();
end

function activate()
	OptionsManager.registerCallback("TBOX", update);
	OptionsManager.registerCallback("REVL", update);

	update();
end

function update()
	if control then
		if OptionsManager.isOption("TBOX", "on") then
			if User.isHost() and OptionsManager.isOption("REVL", "off") then
				control.setVisible(false);
			else
				control.setVisible(true);
			end
		else
			control.setVisible(false);
		end
	end
end

function onDrop(draginfo)
	if control then
		if OptionsManager.isOption("TBOX", "on") then
			ActionsManager.handleDragDrop(draginfo, false);

			local sDragType = draginfo.getType();
			local rSource, rRolls, rCustom = ActionsManager.decodeActionFromDrag(draginfo, false);

			for k, v in ipairs(rRolls) do
				local sDice = StringManager.convertDiceToString(v.aDice, v.nMod);
				
				local msgOOB = {};
				msgOOB.type = OOB_MSGTYPE_DICETOWER;
				msgOOB.rolltype = ActionsManager.getRollType(sDragType, k);
				msgOOB.rolltext = v.sDesc;
				msgOOB.rolldice = sDice;
				if User.isHost() then
					msgOOB.sender = "";
				else
					msgOOB.sender = User.getCurrentIdentity();
				end

				if rCustom then
					msgOOB.nCustom = #rCustom;
					for i = 1, #rCustom do
						msgOOB["sDesc" .. i] = rCustom.sDesc;
						msgOOB["sDice" .. i] = StringManager.ConvertDiceToString(rCustom.aDice, rCustom.nMod);
						msgOOB["sClass" .. i] = rCustom.sClass;
						msgOOB["sRecord" .. i] = rCustom.sRecord;
					end
				else
					msgOOB.nCustom = 0;
				end

				Comm.deliverOOBMessage(msgOOB, "");

				if not User.isHost() then
					local msg = {font = "chatfont", icon = "dicetower_icon", sender = "[TOWER]", text = ""};
					if msgOOB.rolltext ~= "" then
						msg.text = msgOOB.rolltext .. ": ";
					end
					msg.text = msg.text .. sDice;
					
					Comm.addChatMessage(msg);
				end
			end
		end
	end

	return true;
end

function handleDiceTower(msgOOB)
	local sRoll = "[TOWER] ";
	if msgOOB.sender then
		if msgOOB.sender == "" then
			sRoll = sRoll .. "GM -> ";
		else
			local sIdentity = User.getIdentityLabel(msgOOB.sender);
			if sIdentity then
				sRoll = sRoll .. sIdentity .. " -> ";
			else
				sRoll = sRoll .. "<unknown> -> ";
			end
		end
	end
	if msgOOB.rolltext then
		sRoll = sRoll .. msgOOB.rolltext;
	end
	
	local aDice, nMod = StringManager.convertStringToDice(msgOOB.rolldice);

	local rRoll = { sType = msgOOB.rolltype, sDesc = sRoll, aDice = aDice, nMod = nMod };

	local rCustom = {};
	local nCustom = tonumber(msgOOB.nCustom) or 0;
	if nCustom > 0 then
		for i = 1, nCustom do
			local aDice, nMod = StringManager.convertStringToDice(msgOOB["sDice" .. i]);
			table.insert(rCustom, { 
					sDesc = msgOOB["sDesc" .. i], 
					aDice = aDice, 
					nMod = nMod, 
					sClass = msgOOB["sClass" .. i], 
					sRecord = msgOOB["sRecord" .. i] });
		end
	end
	
	ActionsManager.roll(nil, nil, rRoll, rCustom);
end
