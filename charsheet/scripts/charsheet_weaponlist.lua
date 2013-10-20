-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	if bFocus and win then
		win.name.setFocus();
	end
	return win;
end

function onDrop(x, y, draginfo)
	return CharManager.onActionDrop(draginfo, window.getDatabaseNode());
end
