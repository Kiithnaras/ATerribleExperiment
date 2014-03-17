-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.quests_iedit.getValue() == 1);
	window.idelete_header_quest.setVisible(bEditMode);
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisible(bEditMode);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if w and bFocus then
		w.name.setFocus();
	end
	return w;
end

function onDrop(x, y, dragdata)
	if User.isHost() and dragdata.isType("shortcut") then
		local sClass = dragdata.getShortcutData();
		if sClass == "quest" then
			local nodeSource = dragdata.getDatabaseNode();	
			addQuestsEntry(sClass, nodeSource);
		end
		return true;
	end
end

function addQuestEntry(sClass, ssourcenode)
	if not sClass or not nodeSource then
		return;
	end
		
	local w = createWindow();
	w.shortcut.setValue(sClass, nodeSource.getNodeName());
	w.name.setValue(DB.getValue(nodeSource, "name", ""));
	w.level.setValue(DB.getValue(nodeSource, "level", 0));
	w.xp.setValue(DB.getValue(nodeSource, "xp", 0));
end

function deleteAll()
	for _,v in pairs(getWindows()) do
		v.getDatabaseNode().delete();
	end
end
