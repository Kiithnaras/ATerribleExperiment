-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sTarget = "";

local bActive = false;
local ctrlList = nil;
local ctrlScroll = nil;

local aItems = {};
local winSelected = nil;

function onInit()
	-- This drop-down template requires a name
	local sName = getName();
	if not sName or sName == "" then
		setVisible(false);
		return;
	end
	
	-- Get target stringcontrol
	if target and target[1] then
		sTarget = target[1];
	end

	-- Set position of drop down arrow relative to string control
	local x = 0;
	local y = 0;
	if position and window[sTarget] then
		local sPosition = position[1];
		local nComma = string.find(sPosition, ",");
		if nComma then
			x = tonumber(string.sub(sPosition, 1, nComma-1)) or 0;
			y = tonumber(string.sub(sPosition, nComma+1)) or 0;
		end
	end
	setAnchor("right", sTarget, "right", "absolute", x);
	setAnchor("top", sTarget, "top", "absolute", y);
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if button == 1 or bActive then
		toggle();
	else
		window[sTarget].setValue("");
	end
	return true;
end

function onHover(oncontrol)
	refresh(oncontrol);
end

function toggle(button)
	if bActive then
		bActive = false;
		hideList();
	else
		bActive = true;
		showList();
	end
	refresh();
end

function showList()
	-- Create the list if it does not exist
	if not ctrlList then
		local sName = getName() or "";
		local sList = sName .. "_list";
		
		local w,h = window[sTarget].getSize();
		
		-- Create the list control
		ctrlList = window.createControl("dropdownlist", sList);
		ctrlList.setAnchor("right", sName, "right", "absolute", 0);
		ctrlList.setAnchor("bottom", sName, "top", "absolute", 0);
		ctrlList.setAnchoredWidth(w);
		
		-- Set the fonts and frames used for normal/selected items
		local sFont = fonts[1].normal[1] or "";
		if type(sFont) ~= "string" then
			sFont = "";
		end
		local sSelFont = fonts[1].selected[1] or "";
		if type(sSelFont) ~= "string" then
			sSelFont = "";
		end
		local sFrame = frames[1].normal[1] or "";
		if type(sFrame) ~= "string" then
			sFrame = "";
		end
		local sSelFrame = frames[1].selected[1] or "";
		if type(sSelFrame) ~= "string" then
			sSelFrame = "";
		end
		ctrlList.setFonts(sFont, sSelFont);
		ctrlList.setFrames(sFrame, sSelFrame);
		
		-- populate the list
		for k,v in pairs(aItems) do
			ctrlList.add(k,v);
		end
		aItems = {};
		
		-- set the number of rows displayed
		ctrlList.setRows(tonumber(size[1]) or 0);
		
		-- Create list scroll bar
		ctrlScroll = window.createControl("dropdownscrollbar", "ddscroll");
		ctrlScroll.setAnchor("right", sList, "right");
		ctrlScroll.setAnchor("top", sList, "top");
		ctrlScroll.setAnchor("bottom", sList, "bottom");
		ctrlScroll.setTarget(sList);
	end

	-- Show the list if it already exists
	if ctrlList then
		ctrlList.setVisible(true);
		ctrlList.setFocus(true);

		-- Scroll to the target value
		local sValue = window[sTarget].getValue();
		setValue(sValue);
		ctrlList.applySort();
		if winSelected then
			ctrlList.scrollToWindow(winSelected);
		end
		
		-- Reset target value, if the old value does not correspond to a value on the list
		window[sTarget].setValue(sValue);
	end
end

function hideList()
	if ctrlList then
		ctrlList.setVisible(false);
	end
end

function refresh(bActiveParam)
	if bActive or bActiveParam then
		setIcon("indicator_dropdown_active");
	else
		setIcon("indicator_dropdown");
	end
end

function setValue(sValue)
	if ctrlList then
		local opt = nil;
		for _,win in ipairs(ctrlList.getWindows()) do
			if win.Value.getValue() == sValue then
				opt = win;
				break;
			end
		end
		selectItem(opt);
	end
end

function getValue()
	if winSelected then
		return winSelected.Value.getValue();
	end
	return "";
end

function add(sValue, sText)
	if not sValue then
		return;
	end
	if type(sText) ~= "string" then sText = sValue end;

	if type(sValue) == "string" then
		if ctrlList then
			ctrlList.add(sValue, sText);
		else
			aItems[sValue] = sText;
		end
	end
end

function addItems(aList)
	for _,sValue in ipairs(aList) do
		add(sValue);
	end
end

function clear()
	if ctrlList then
		ctrlList.clear();
	end
	aItems = {};
end

function optionClicked(opt)
	if opt and opt.setSelected then
		selectItem(opt);
	end
	
	bActive = false;
	hideList();
	refresh();
end

function selectItem(opt)
	if not ctrlList then
		return;
	end
	if winSelected == opt then
		return;
	end
	
	if winSelected then
		winSelected.setSelected(false);
	end
	ctrlList.applySort();
	if opt then
		opt.setSelected(true);
	end
	
	winSelected = opt;
	
	if window[sTarget].getValue() ~= getValue() then
		window[sTarget].setValue(getValue());
	end
end

