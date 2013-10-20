-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local shadowText = nil;
local hilightText = nil;
local pressedText = nil;

function onInit()
	local sButtonText = text[1] or "Button";
	shadowText = addTextWidget("defaultstringcontrol", sButtonText);
	shadowText.setPosition("center", 1, 1);
	hilightText = addTextWidget("white", sButtonText);
	pressedText = addTextWidget("white", sButtonText);
	pressedText.setPosition("center", 0, 1);

	setFrame("buttonup");
	shadowText.setVisible(true);
	hilightText.setVisible(true);
	pressedText.setVisible(false);
end

function onClickDown(button, x, y)
	setFrame("buttondown");
	shadowText.setVisible(false);
	hilightText.setVisible(false);
	pressedText.setVisible(true);
	return true;
end

function onDragStart(button, x, y, draginfo)
	return true;
end

function onClickRelease(button, x, y)
	setFrame("buttonup");
	shadowText.setVisible(true);
	hilightText.setVisible(true);
	pressedText.setVisible(false);

	if self.onButtonPress then
		self.onButtonPress();
	end
end

function setText(sText)
	shadowText.setText(sText);
	hilightText.setText(sText);
	pressedText.setText(sText);
end
