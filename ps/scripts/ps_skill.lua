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
	
	spotlabel.setVisible(not bPFMode);
	listenlabel.setVisible(not bPFMode);
	searchlabel.setVisible(bPFMode or not bPFMode);
	noticelabel.setVisible(bPFMode);
	smlabel.setVisible(bPFMode);
	
	gatherinfolabel.setVisible(not bPFMode);
	
	acrobaticslabel.setVisible(bPFMode);
	heallabel.setVisible(bPFMode);
	jumplabel.setVisible(bPFMode or not bPFMode);
	
	hidelabel.setVisible(not bPFMode);
	movesilentlabel.setVisible(not bPFMode);
	stealthlabel.setVisible(bPFMode);
	
	for _,w in pairs(partylist.getWindows()) do
		w.onSystemChanged(bPFMode);
	end
end
