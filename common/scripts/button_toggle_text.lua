-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local shadowText = nil;
local hilightText = nil;
local pressedText = nil;

local active = false;

function onInit()
	local sButtonText = text[1] or "Button";
	shadowText = addTextWidget("defaultstringcontrol", sButtonText);
	shadowText.setPosition("center", 1, 1);
	hilightText = addTextWidget("white", sButtonText);
	pressedText = addTextWidget("white", sButtonText);
	pressedText.setPosition("center", 0, 1);

	if active then
		setFrame("buttondown");
		shadowText.setVisible(false);
		hilightText.setVisible(false);
		pressedText.setVisible(true);
	else
		setFrame("buttonup");
		shadowText.setVisible(true);
		hilightText.setVisible(true);
		pressedText.setVisible(false);
	end
end

function getState()
	return active;
end

function onClickDown(button, x, y)
	if active then
		deactivate();
	else
		activate();
	end

	return true;
end

function activate()
	if active then
		return;
	end
	
	active = true;

	setFrame("buttondown");
	shadowText.setVisible(false);
	hilightText.setVisible(false);
	pressedText.setVisible(true);

	if self.onValueChanged then
		self.onValueChanged();
	end
end

function deactivate()
	if not active then
		return;
	end
	
	active = false;
	
	setFrame("buttonup");
	shadowText.setVisible(true);
	hilightText.setVisible(true);
	pressedText.setVisible(false);

	if self.onValueChanged then
		self.onValueChanged();
	end
end
