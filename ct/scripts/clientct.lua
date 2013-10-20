-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("WNDC", onOptionWNDCChanged);
end

function onClose()
	OptionsManager.unregisterCallback("WNDC", onOptionWNDCChanged);
end

function onOptionWNDCChanged()
	for _,v in pairs(getWindows()) do
		v.onWoundsChanged();
	end
end

function onSortCompare(w1, w2)
	return not CTManager.sortfunc(w1.getDatabaseNode(), w2.getDatabaseNode());
end

function onFilter(w)
	if w.friendfoe.getValue() == "friend" then
		return true;
	end
	if w.show_npc.getValue() ~= 0 then
		return true;
	end
	return false;
end

function onDrop(x, y, draginfo)
	local wnd = getWindowAt(x,y);
	if wnd then
		local nodeWin = wnd.getDatabaseNode();
		if nodeWin then
			return CTManager.onDrop("ct", nodeWin.getNodeName(), draginfo);
		end
	end
end

function onClickDown(button, x, y)
	if Input.isShiftPressed() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if Input.isShiftPressed() then
		local wnd = getWindowAt(x, y);
		if wnd then
			TokenManager.toggleClientTarget(wnd.getDatabaseNode());
		end

		return true;
	end
end
