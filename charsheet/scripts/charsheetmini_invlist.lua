-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onFilter(w)
	return (DB.getValue(w.getDatabaseNode(), "showonminisheet", 0) ~= 0);
end

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	if bFocus and win then
		win.name.setFocus();
	end
	return win;
end
