-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sFocus = "label";

function onInit()
	if newfocus then
		sFocus = newfocus[1];
	end
end

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	if bFocus and win and win[sFocus] then
		win[sFocus].setFocus();
	end
	return win;
end

function onClickDown(button, x, y)
	if not isReadOnly() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if not isReadOnly() then
		if not getNextWindow(nil) then
			addEntry(true);
		end
	end
	return true;
end
