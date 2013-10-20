-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end

	if not Input.isShiftPressed() then
		setValue(getValue() + notches);
	else
		setValue(getValue() + (notches * 0.5));
	end
	
	return true;
end

function onValueChanged()
	local nodeWin = window.getDatabaseNode();
	if nodeWin then
		CharManager.updateSkillPoints(nodeWin.getChild("..."));
	end
end
