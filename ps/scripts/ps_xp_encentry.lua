-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem("Award XP", "deletealltokens", 3);
		registerMenuItem("Award XP - One", "one", 3, 3);
		registerMenuItem("Award XP - All", "all", 3, 5);
		registerMenuItem("Delete Entries", "delete", 6);
		registerMenuItem("Delete Entry", "one", 6, 7);
		registerMenuItem("Delete Entries - All", "all", 6, 5);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 3 then
		if subselection == 3 then
			windowlist.awardXPtoParty(self);
		elseif subselection == 5 then
			windowlist.awardXPtoParty();
		end
	elseif selection == 6 then
		if subselection == 7 then
			getDatabaseNode().delete();
		elseif subselection == 5 then
			windowlist.deleteAll();
		end
	end
end
