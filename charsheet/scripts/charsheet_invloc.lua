-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aAutoFill = {};

function onChar()
	if getCursorPosition() == #getValue() + 1 then
		local sCompletion = StringManager.autoComplete(aAutoFill, getValue(), true);
		if sCompletion then
			setValue(getValue() .. sCompletion);
			setSelectionPosition(getCursorPosition() + #sCompletion);
		end

		return;
	end
end

function onGainFocus()
	aAutoFill = {};
	
	for k, v in ipairs(window.windowlist.getWindows()) do
		local s = v.name.getValue();
		if s ~= "" then
			table.insert(aAutoFill, s);
		end
	end
	
	super.onGainFocus();
end

function onLoseFocus()
	super.onLoseFocus();
	window.windowlist.applySort();
	window.windowlist.onListRearranged(true);
end
