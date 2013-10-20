-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	activewidget = addBitmapWidget(activeicon[1]);
	activewidget.setVisible(false);
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	window.reset();
	return true;
end

function setState(state)
	activewidget.setVisible(state);
end
