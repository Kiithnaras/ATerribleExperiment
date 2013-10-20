-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

slots = {};

maxnode = nil;
countnode = nil;

function getMaxValue()
	if maxnode then
		return maxnode.getValue();
	end

	return 0;
end

function getCurrentValue()
	if countnode then
		return countnode.getValue();
	end

	return 0;
end

function setCurrentValue(nCount)
	if countnode then
		countnode.setValue(nCount);
	end
end

function updateSlots()
	-- Clear
	for k, v in ipairs(slots) do
		v.destroy();
	end
	
	slots = {};

	-- Construct based on values
	local m = getMaxValue();
	local c = getCurrentValue();

	local col = 0;
	local row = 0;

	for i = 1, m do
		local widget = nil;

		if i <= c then
			widget = addBitmapWidget(stateicons[1].on[1]);
		else
			widget = addBitmapWidget(stateicons[1].off[1]);
		end

		local posx = spacing[1].horizontal[1] * (col+0.5);
		local posy = spacing[1].vertical[1] * (row+0.5);
		widget.setPosition("topleft", posx, posy);
		
		row = row + 1;
		if row >= tonumber(slotcount[1].vertical[1]) then
			row = 0;
			col = col + 1;
		end
		
		slots[i] = widget;
	end
	
	if minisheet then
		window.windowlist.applyFilter();
	end
end

function getSlotState(x, y)
	local m = getMaxValue();
	local c = getCurrentValue();

	local col = 0;
	local row = 0;
	
	local state = false;

	for i = 1, m do
		local widget = nil;

		if i <= c then
			state = true;
		else
			state = false;
		end

		local posx = spacing[1].horizontal[1] * col;
		local posy = spacing[1].vertical[1] * row;

		if x > posx and x < posx + spacing[1].horizontal[1] and
		   y > posy and y < posy + spacing[1].vertical[1] then
			return state;
		end
		
		row = row + 1;
		if row >= tonumber(slotcount[1].vertical[1]) then
			row = 0;
			col = col + 1;
		end
	end
	
	return state;
end

function checkBounds()
	local m = getMaxValue();
	local c = getCurrentValue();
	
	if c > m then
		setCurrentValue(m);
	elseif c < 0 then
		setCurrentValue(0);
	end
end

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end

	setCurrentValue(getCurrentValue() + notches);

	checkBounds();
	updateSlots();
	return true;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not getSlotState(x, y) then
		setCurrentValue(getCurrentValue() + 1);
	else
		setCurrentValue(getCurrentValue() - 1);
	end

	checkBounds();
	updateSlots();
	return true;
end

function onMenuSelection(...)
	setCurrentValue(0);
	updateSlots();
end

function onInit()
	registerMenuItem("Clear", "erase", 4);
	
	maxnode = window.getDatabaseNode().createChild(fields[1].max[1], "number");
	if maxnode then
		maxnode.onUpdate = updateSlots;
	end

	countnode = window.getDatabaseNode().createChild(fields[1].count[1], "number");
	if countnode then
		countnode.onUpdate = updateSlots;
	end
	
	updateSlots();
end