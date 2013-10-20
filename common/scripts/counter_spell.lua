-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

slots = {};

local sSheetMode = "standard";
local bSpontaneous = false;
local nAvailable = 0;
local nTotalCast = 0;
local nTotalPrepared = 0;
local nMaxPrepared = 0;

local nodePrepared = nil;
local nodeCast = nil;

function getPreparedValue()
	if nodePrepared then
		return nodePrepared.getValue();
	end
	
	return 0;
end

function setPreparedValue(nNewValue)
	if nodePrepared then
		nodePrepared.setValue(nNewValue);
	end
end

function getCastValue()
	if nodeCast then
		return nodeCast.getValue();
	end
	
	return 0;
end

function setCastValue(nNewValue)
	if nodeCast then
		nodeCast.setValue(nNewValue);
	end
end

function onInit()
	local node = window.getDatabaseNode();
	
	nodePrepared = node.createChild("prepared", "number");
	nodeCast = node.createChild("cast", "number");

	if nodePrepared then nodePrepared.onUpdate = onValueChanged;	end
	if nodeCast then nodeCast.onUpdate = onValueChanged;	end
end

function onValueChanged()
	window.onSpellCounterUpdate();
end

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end

	adjustCounter(notches);
	return true;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if sSheetMode == "preparation" then
		local nClick = math.floor(x / spacing[1]) + 1;
		local nCurrent = getPreparedValue();
		
		if nClick > nCurrent then
			adjustCounter(1);
		else
			adjustCounter(-1);
		end
	else
		local nClick = math.floor(x / spacing[1]) + 1;
		local nCurrent = getCastValue();
		
		if bSpontaneous then
			if nClick > nTotalCast then
				adjustCounter(1);
			elseif nCurrent > 0 then
				adjustCounter(-1);
			end
		else
			if nClick > nCurrent then
				adjustCounter(1);
			else
				adjustCounter(-1);
			end
		end
	end
	
	return true;
end

function update(sNewSheetMode, bNewSpontaneous, nNewAvailable, nNewTotalCast, nNewTotalPrepared, nNewMaxPrepared)
	sSheetMode = sNewSheetMode;
	bSpontaneous = bNewSpontaneous;
	nAvailable = nNewAvailable;
	nTotalCast = nNewTotalCast;
	nTotalPrepared = nNewTotalPrepared;
	nMaxPrepared = nNewMaxPrepared;
	
	updateSlots();
end

function updateSlots()
	-- Clear
	for k, v in ipairs(slots) do
		v.destroy();
	end
	slots = {};
	
	-- Construct based on values
	local nPrepared = getPreparedValue();
	local nCast = getCastValue();
	local bPrepMode = (sSheetMode == "preparation");

	local nMax = nPrepared;
	if bSpontaneous or bPrepMode then
		nMax = nAvailable;
	end
	
	-- Build the slots, based on the all the spell cast statistics
	local widget;
	for i = 1, nMax do
		widget = nil;

		if bSpontaneous then
			if i > nTotalCast then
				widget = addBitmapWidget(stateicons[1].off[1]);
			else
				widget = addBitmapWidget(stateicons[1].on[1]);
			end
			
			if i <= nTotalCast - nCast or bPrepMode then
				widget.setColor("4fffffff");
			end
		else
			if i > nCast then
				widget = addBitmapWidget(stateicons[1].off[1]);
			else
				widget = addBitmapWidget(stateicons[1].on[1]);
			end
			
			if i > nPrepared then
				widget.setColor("4fffffff");
			end
		end
		
		widget.setPosition("left", (spacing[1] * (i - 0.5)), 0);
		
		slots[i] = widget;
	end

	-- Determine final width of control based on slots
	if bSpontaneous or bPrepMode then
		setAnchoredWidth(spacing[1] * nAvailable);
	else
		setAnchoredWidth(spacing[1] * nMaxPrepared);
	end
end

function adjustCounter(val_adj)
	if sSheetMode == "preparation" then
		if bSpontaneous then
			return true;
		end
	
		local val = getPreparedValue() + val_adj;
		
		if val > nAvailable then
			setPreparedValue(nAvailable);
		elseif val < 0 then
			setPreparedValue(0);
		else
			setPreparedValue(val);
		end
	else
		local val = getCastValue() + val_adj;
		local nTempTotal = nTotalCast + val_adj;

		if bSpontaneous then
			if nTempTotal > nAvailable then
				if val - (nTempTotal - nAvailable) > 0 then
					setCastValue(val - (nTempTotal - nAvailable));
				else
					setCastValue(0);
				end
			elseif val < 0 then
				setCastValue(0);
			else
				setCastValue(val);
			end
		else
			local nPrepared = getPreparedValue();

			if val > nPrepared then
				setCastValue(nPrepared);
			elseif val < 0 then
				setCastValue(0);
			else
				setCastValue(val);
			end
		end
	end
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function canCast()
	if bSpontaneous then
		return (nTotalCast < nAvailable);
	else
		local nCast = getCastValue();
		local nPrepared = getPreparedValue();
		
		return (nCast < nPrepared);
	end
end
