-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

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
	window[trigger[1]].updateWidget(getValue() ~= "");
end
