-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action()	
	local aParty = {};
	for _,v in pairs(window.partylist.getWindows()) do
		local rActor = ActorManager.getActor("pc", v.link.getTargetDatabaseNode());
		if rActor then
			table.insert(aParty, rActor);
		end
	end
	if #aParty == 0 then
		aParty = nil;
	end
	
	local sSkill = window.selectedskill.getValue();
	
	local nTargetDC = window.skilldc.getValue();
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	
	local bSecretRoll = window.hiderollresults.getState();
	
	local sSkillLookup;
	local sSubSkill = nil;
	if sSkill:match("^Knowledge") then
		sSubSkill = sSkill:sub(12, -2);
		sSkillLookup = "Knowledge";
	else
		sSkillLookup = sSkill;
	end
	
	for _,v in pairs(aParty) do
		local nValue, bUntrained = CharManager.getSkillValue(v, sSkillLookup, sSubSkill);
		if bUntrained then
			local rMessage = ChatManager.createBaseMessage(v, true);
			rMessage.text = rMessage.text .. "[SKILL] " .. sSkill .. " [UNTRAINED]";			
			if bSecretRoll or OptionsManager.isOption("REVL", "off") then
				rMessage.text = "[GM] " .. rMessage.text;
				Comm.addChatMessage(rMessage);
			else
				Comm.deliverChatMessage(rMessage);
			end
		else
			ActionSkill.performRoll(nil, v, sSkill, nValue, nil, nTargetDC, bSecretRoll, true);
		end
	end
	
	return true;
end

function onButtonPress()
	return action();
end			
