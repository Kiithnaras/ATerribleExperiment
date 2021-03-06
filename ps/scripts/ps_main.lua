-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("REVL", update);
	
	if not User.isHost() then
		list.setAnchor("bottom", "", "bottom", "absolute", -25);
	end

	onSystemChanged();
end

function onClose()
	OptionsManager.unregisterCallback("REVL", update);
end

function update()
	hiderollresults.setVisible(OptionsManager.isOption("REVL", "on"));
end

function onSystemChanged()
	cmdlabel.setVisible(true);
end

function onSubwindowInstantiated()
	for _,v in pairs(list.getWindows()) do
		v.onHealthChanged();
	end
end
