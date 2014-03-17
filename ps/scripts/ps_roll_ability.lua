-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local aParty = {};
	for _,v in pairs(window.list.getWindows()) do
		local rActor = ActorManager.getActor("pc", v.link.getTargetDatabaseNode());
		if rActor then
			table.insert(aParty, rActor);
		end
	end
	if #aParty == 0 then
		aParty = nil;
	end
	
	local sAbilityStat = window.abilityselected.getValue():lower();
	
	local nTargetDC = window.abilitydc.getValue();
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	
	local bSecretRoll = (window.hiderollresults.getValue() == 1);
	
	for _,v in pairs(aParty) do
		ActionAbility.performRoll(nil, v, sAbilityStat, nTargetDC, bSecretRoll);
	end

	return true;
end

function onButtonPress()
	return action();
end			

