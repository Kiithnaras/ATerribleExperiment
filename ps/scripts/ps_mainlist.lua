-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.isType("playercharacter") then
			PartyManager.addChar(draginfo.getDatabaseNode());
			return true;
		end
	end
	return false;
end

function onListRearranged(bListChanged)	
	for _,v in pairs(getWindows()) do
		if v.xpbar then
			v.xpbar.update();
		end
		if v.hpbar then
			v.hpbar.update();
		end
	end
end
