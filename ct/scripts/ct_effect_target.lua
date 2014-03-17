-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sLink = nil;

function onInit()
	onRefChanged();
end

function onClose()
	removeLink();
end

function removeLink()
	if sLink then
		DB.removeHandler(sLink .. ".name", "onUpdate", onNameUpdated);
		sLink = nil;
	end
end

function onRefChanged()
	removeLink();
	
	local sTarget = noderef.getValue();
	if sTarget ~= "" then
		sLink = sTarget;
		DB.addHandler(sLink .. ".name", "onUpdate", onNameUpdated);
		onNameUpdated();
	end
end

function onNameUpdated()
	windowlist.window.onTargetsChanged();
end
