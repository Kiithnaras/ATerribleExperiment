-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local ctrlParent = nil;

local sFont = "";
local sSelFont = "";
local sFrame = "";
local sSelFrame = "";

local nRowHeight = 15;
local nRowsVisible = 0;

function onInit()
	local sName = getName();
	if sName and sName~="" then
		ctrlParent = window[string.sub(sName, 1, #sName - 5)];
	end
end

function optionClicked(opt)
	if ctrlParent and ctrlParent.optionClicked then
		ctrlParent.optionClicked(opt);
	end
end

function setRows(nRows)
	if nRows <= 0 then
		nRows = #(getWindows());
	end
	nRowsVisible = nRows;
	setAnchoredHeight(nRows * nRowHeight);
end

function setFonts(sNormal, sSelection)
	sFont = sNormal or "";
	sSelFont = sSelection or "";

	for _,opt in ipairs(getWindows()) do
		opt.setFonts(sFont, sSelFont);
	end
end

function setFrames(sNormal, sSelection)
	sFrame = sNormal or "";
	sSelFrame = sSelection or "";

	for _,opt in ipairs(getWindows()) do
		opt.setFrames(sFrame, sSelFrame);
	end
end

function add(sValue, sText)
	local opt = createWindow();
	opt.Text.setValue(sText);
	opt.Value.setValue(sValue);
	opt.setFonts(sFont, sSelFont);
	opt.setFrames(sFrame, sSelFrame);
end

function clear()
	closeAll();
end

function onLoseFocus()
	ctrlParent.toggle();
end

