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
	
	local sSave = window.saveselected.getValue():lower();
	
	local nTargetDC = window.savedc.getValue();
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	
	local bSecretRoll = window.hiderollresults.getState();
	
	for _,v in pairs(aParty) do
		ActionSpell.performSaveRoll(nil, v, sSave, nTargetDC, bSecretRoll, true)
	end

	return true;
end

function onButtonPress()
	return action();
end			

