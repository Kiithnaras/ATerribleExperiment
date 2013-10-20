-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodeSource = nil;

function onInit()
	activewidget = addBitmapWidget(activeicon[1]);
	activewidget.setVisible(false);

	nodeSource = window.getDatabaseNode().createChild(getName(), "number");
	if nodeSource then
		nodeSource.onUpdate = onValueChanged;
	end
	
	onValueChanged();
end

function onValueChanged()
	local state = getState();

	activewidget.setVisible(state);
	
	TokenManager.updateActive(window.getDatabaseNode());
	window.setActiveVisible(false);
	window.setTargetingVisible(false);
	
	window.updateDisplay();

	if nodeSource and nodeSource.getValue() == 1 then
		window.windowlist.scrollToWindow(window);
	end
end

function setState(state)
	local datavalue = 1;
	if state == nil or state == false or state == 0 then
		datavalue = 0;
	end
	
	if nodeSource then
		nodeSource.setValue(datavalue);
	end
end

function getState()
	local datavalue = 0;
	if nodeSource then
		datavalue = nodeSource.getValue();
	end
	return datavalue ~= 0;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not getState() and User.isHost() then
		CTManager.requestActivation(window.getDatabaseNode(), true);
	end
	return true;
end

function onDragStart(button, x, y, draginfo)
	if getState() and User.isHost() then
		draginfo.setType("combattrackeractivation");
		draginfo.setIcon(activeicon[1]);

		activewidget.setVisible(false);
		return true;
	end
end

function onDragEnd(draginfo)
	if getState() then
		activewidget.setVisible(true);
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackeractivation") then
		CTManager.requestActivation(window.getDatabaseNode(), true);
		return true;
	end
end