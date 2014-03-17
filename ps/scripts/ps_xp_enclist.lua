-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.enc_iedit.getValue() == 1);
	window.idelete_header_enc.setVisible(bEditMode);
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisible(bEditMode);
	end
end

function onDrop(x, y, draginfo)
	if User.isHost() and draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		if sClass == "battle" then
			PartyManager2.addEncounter(draginfo.getDatabaseNode());
		end
		return true;
	end
end

function deleteAll()
	for k, v in pairs(getWindows()) do
		v.getDatabaseNode().delete();
	end
end
