-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("SYSTEM", onSystemChanged);
end

function onClose()
	OptionsManager.unregisterCallback("SYSTEM", onSystemChanged);
end

function onSystemChanged()
	if minisheet then
		for k,v in pairs(spellclasslist.getWindows()) do
			v.onSpellCounterUpdate();
		end
	else
		for k,v in pairs(actions.subwindow.spellclasslist.getWindows()) do
			v.onSpellCounterUpdate();
		end
	end
end
