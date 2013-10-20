-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("SYSTEM", onSystemChanged);
	onSystemChanged();
end

function onClose()
	OptionsManager.unregisterCallback("SYSTEM", onSystemChanged);
end

function onSystemChanged()
	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");
	
	cmdlabel.setVisible(bPFMode);
	
	for _,w in pairs(partylist.getWindows()) do
		w.onSystemChanged(bPFMode);
	end
end

function onSubwindowInstantiated()
	for _,v in pairs(partylist.getWindows()) do
		v.onXPChanged();
		v.onHPChanged();
	end
end

function clearEffect()
	effectduration.setValue(1);
	effectunit.setStringValue("");
	effectisgmonly.setState(0);
	effectapply.setStringValue("");
	effectlabel.setValue("");
end
