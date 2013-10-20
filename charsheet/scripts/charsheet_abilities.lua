-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		if draginfo.getShortcutData() == "referencefeat" then
			local nodeSource = draginfo.getDatabaseNode();
			
			local win = addEntry(true);
			if win then
				win.value.setValue(DB.getValue(nodeSource, "name", ""));
				win.shortcut.setValue(draginfo.getShortcutData());
			end

		end

		return true;
	end
end
