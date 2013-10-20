-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bSelected = false;

local sFont = "";
local sSelFont = "";
local sFrame = "";
local sSelFrame = "";

function onInit()
	setSelected(bSelected);
end

function setFonts(sNormal, sSelection)
	sFont = sNormal or "";
	sSelFont = sSelection or "";

	setSelected(bSelected);
end

function setFrames(sNormal, sSelection)
	sFrame = sNormal or "";
	sSelFrame = sSelection or "";

	setSelected(bSelected);
end

function setSelected(bValue)
	if bValue then
		bSelected = true;
		setFrame(sSelFrame);
		Text.setFont(sSelFont);
	else
		bSelected = false;
		setFrame(sFrame);
		Text.setFont(sFont);
	end
end

function clicked()
	if windowlist and windowlist.optionClicked then
		windowlist.optionClicked(self);
	end
end
