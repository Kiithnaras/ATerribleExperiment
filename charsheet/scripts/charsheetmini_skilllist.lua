-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Register callback on option change
	OptionsManager.registerCallback("SYSTEM", onSystemChanged);
	onSystemChanged();

	local nodeAbilities = getDatabaseNode().createChild("..abilities");
	if nodeAbilities then
		nodeAbilities.onChildUpdate = onStatUpdate;
	end
end

function onClose()
	OptionsManager.unregisterCallback("SYSTEM", onSystemChanged);
end

function onSystemChanged()
	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");
	for _,w in pairs(getWindows()) do
		w.onSystemChanged(bPFMode);
	end
end

function onStatUpdate()
	for _,w in pairs(getWindows()) do
		w.onStatUpdate();
	end
end

function onFilter(w)
	return (DB.getValue(w.getDatabaseNode(), "showonminisheet", 0) ~= 0);
end
