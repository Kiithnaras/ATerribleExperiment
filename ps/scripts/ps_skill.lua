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
	
	noticelabel.setVisible(true);
	searchlabel.setVisible(true);
	smlabel.setVisible(true);
		
	acrobaticslabel.setVisible(true);
	heallabel.setVisible(true);
	jumplabel.setVisible(false);
	hidelabel.setVisible(false);
	movesilentlabel.setVisible(false);
	spotlabel.setVisible(false);
	listenlabel.setVisible(false);
	gatherinfolabel.setVisible(false);
	stealthlabel.setVisible(true);
end
