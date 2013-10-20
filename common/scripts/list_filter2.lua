-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- The target value is a series of consecutive window lists or sub windows
local aTargetPath = {};

function onInit()
	for sWord in string.gmatch(target[1], "([^,]+)") do
		table.insert(aTargetPath, sWord);
	end
end

function hide()
	setVisible(false);
	window[trigger[1]].setVisible(true);
end

function onEnter()
	hide();
	return true;
end

function onLoseFocus()
	hide();
end

function onValueChanged(vTarget)
	applyTo(window[aTargetPath[1]], 1);

	window[trigger[1]].updateWidget(getValue() ~= "");
end

function applyTo(vTarget, nIndex)
	nIndex = nIndex + 1;

	if not vTarget.isVisible() then
		vTarget.setVisible(true);
	end
	if nIndex > #aTargetPath then
		vTarget.applyFilter();
		return;
	end

	local sTargetType = type(vTarget);
	if sTargetType == "windowlist" then
		for kChild, wChild in pairs(vTarget.getWindows()) do
			applyTo(wChild[aTargetPath[nIndex]], nIndex);
		end
	elseif sTargetType == "subwindow" then
		applyTo(vTarget.subwindow[aTargetPath[nIndex]], nIndex);
	end
end
