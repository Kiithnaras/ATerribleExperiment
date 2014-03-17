-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("REVL", update);
	
	if not User.isHost() then
		list.setAnchor("bottom", "sheetframe", "bottom", "absolute", -20);
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
	local bPFMode = DataCommon.isPFRPG();
	cmdlabel.setVisible(bPFMode);
end

function onSubwindowInstantiated()
	for _,v in pairs(list.getWindows()) do
		v.onHealthChanged();
	end
end
