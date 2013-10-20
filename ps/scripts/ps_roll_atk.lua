-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
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
	
	local rAction = {};
	rAction.label = "Party Attack";
	rAction.modifier = window.bonus.getValue();
	rAction.crit = 20;
	
	local rRoll = ActionAttack.getRoll(nil, rAction);
	
	local bSecretRoll = window.hiderollresults.getState();
	if bSecretRoll then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end
	
	local sStackDesc, nStackMod = ModifierStack.getStack(true);
	if sStackDesc ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " (" .. sStackDesc .. ")";
	end
	rRoll.nMod = rRoll.nMod + nStackMod;
	
	for _,v in pairs(aParty) do
		ActionsManager.handleActionNonDrag(nil, "attack", { rRoll }, nil, { { v } });
	end

	return true;
end

function onButtonPress()
	return action();
end			

