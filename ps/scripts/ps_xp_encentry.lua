-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem(Interface.getString("ps_menu_awardxp"), "deletealltokens", 3);
		registerMenuItem(Interface.getString("ps_menu_awardxpone"), "one", 3, 3);
		registerMenuItem(Interface.getString("ps_menu_awardxpall"), "all", 3, 5);
		registerMenuItem(Interface.getString("ps_menu_delete"), "delete", 6);
		registerMenuItem(Interface.getString("ps_menu_deleteone"), "one", 6, 7);
		registerMenuItem(Interface.getString("ps_menu_deleteall"), "all", 6, 5);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 3 then
		if subselection == 3 then
			PartyManager2.awardEncountersToParty(getDatabaseNode());
		elseif subselection == 5 then
			PartyManager2.awardEncountersToParty();
		end
	elseif selection == 6 then
		if subselection == 7 then
			getDatabaseNode().delete();
		elseif subselection == 5 then
			windowlist.deleteAll();
		end
	end
end
