-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	if bFocus and win then
		win.count.setFocus();
	end
	return win;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local class, datasource = draginfo.getShortcutData();
		local source = draginfo.getDatabaseNode();

		if source then
			if class == "npc" then
				local win = addEntry(true);
				if win then
					win.name.setValue(DB.getValue(source, "name", ""));
					win.link.setValue("npc", source.getNodeName());

					local tokenval = DB.getValue(source, "token", nil);
					if tokenval then
						win.token.setPrototype(tokenval);
					end
				end
			end
		end

		return true;
	end
end
