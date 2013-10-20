-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local slots = {};
local enabled = true;

local nodeMax = nil;
local sMaxNodeName = "";
local nodeCurr = nil;
local sCurrNodeName = "";

function onInit()
	-- Get any custom fields
	if sourcefields then
		if sourcefields[1].maximum then
			sMaxNodeName = sourcefields[1].maximum[1];
		end
		if sourcefields[1].current then
			sCurrNodeName = sourcefields[1].current[1];
		end
	end

	-- Synch to the data nodes
	local nodeWin = window.getDatabaseNode();
	if nodeWin then
		local bWatchUpdate = false;
		if sMaxNodeName ~= "" then
			-- If this is a new counter, then set our max value to 1 by default.
			nodeMax = nodeWin.getChild(sMaxNodeName);
			if not nodeMax then
				nodeMax = nodeWin.createChild(sMaxNodeName, "number");
				if nodeMax then
					nodeMax.setValue(1);
				end
			end
			if nodeMax then
				nodeMax.onUpdate = update;
			else
				bWatchUpdate = true;
			end
		end
		if sCurrNodeName ~= "" then
			nodeCurr = nodeWin.createChild(sCurrNodeName, "number");
			if nodeCurr then
				nodeCurr.onUpdate = update;
			else
				bWatchUpdate = true;
			end
		end
		if bWatchUpdate then
			nodeWin.onChildAdded = registerUpdate;
		end
	end
	
	-- Update the view we show he world
	updateSlots();
end

function registerUpdate(nodeSource, nodeChild)
	if nodeChild.getName() == sMaxNodeName then
		nodeMax = nodeChild;
	elseif nodeChild.getName() == sCurrNodeName then
		nodeCurr = nodeChild;
	else
		return;
	end

	if nodeMax and nodeCurr then
		nodeSource.onChildAdded = function () end;
	end
	
	nodeChild.onUpdate = update;
	update();
end

-- Disables incrementing, can still decrement
function disable()
	enabled = false;
	updateSlots();
end

-- Enables incrementing
function enable()
	enabled = true;
	updateSlots();
end

function setMaxValue(p)
	if nodeMax then
		nodeMax.setValue(p);
	end
end

function getMaxValue()
	if nodeMax then
		return nodeMax.getValue();
	end
	
	return 0;
end

function setValue(n)
	if not nodeCurr then
		return;
	end
	
	local p = getMaxValue();
	
	if p < 1 or n < 0 then
		nodeCurr.setValue(0);
	elseif n > p then
		nodeCurr.setValue(p);
	else
		nodeCurr.setValue(n);
	end
end

function getValue()
	if nodeCurr then
		return nodeCurr.getValue();
	end
	
	return 0;
end

function update()
	updateSlots();
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function updateSlots()
	-- Clear
	for k, v in ipairs(slots) do
		v.destroy();
	end
	
	slots = {};
	
	-- Construct based on values
	local p = getMaxValue();
	local c = getValue();

	for i = 1, p do
		local widget = nil;

		if i > c then
			if enabled then
				widget = addBitmapWidget(stateicons[1].off[1]);
			else
				widget = addBitmapWidget(stateicons[1].on[1]);
				widget.setColor("4fffffff");
			end
		else
			widget = addBitmapWidget(stateicons[1].on[1]);
		end

		local pos = spacing[1]*(i-0.5);
		widget.setPosition("left", pos, 0);
		
		slots[i] = widget;
	end
	
	-- Handle the case where p < 1
	-- i.e. We always want to show at least one widget, even if it's disabled.
	if p < 1 then
		local widget = addBitmapWidget(stateicons[1].on[1]);
		widget.setColor("4fffffff");
		widget.setPosition("left", (spacing[1]*0.5), 0);
		slots[1] = widget;
	end

	-- Set the control width
	setAnchoredWidth(spacing[1] * #slots);
end

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end
	
	if enabled or notches < 0 then
		setValue(getValue() + notches);
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	local n = getValue();
	local clickpos = math.floor(x / spacing[1]) + 1;

	if clickpos > n then
		if not enabled then
			return true;
		end
		setValue(n + 1);
	else
		setValue(n - 1);
	end

	return true;
end
