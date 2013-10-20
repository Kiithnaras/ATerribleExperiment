-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	window[target[1]].setVisible(false);
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if button == 1 then
		setVisible(false);
		window[target[1]].setVisible(true);
		window[target[1]].setFocus();
		window[target[1]].setCursorPosition(1);
		window[target[1]].setSelectionPosition(#(window[target[1]].getValue()) + 1);
	elseif button == 2 then
		window[target[1]].setValue("");
	end

	return true;
end

function updateWidget(state)
	if widget and not state then
		widget.destroy();
		widget = nil;
	elseif not widget and state then
		widget = addBitmapWidget("indicator_checkon");
		widget.setPosition(widgetposition[1].anchor[1], widgetposition[1].offsetx[1], widgetposition[1].offsety[1]);
	end
end
