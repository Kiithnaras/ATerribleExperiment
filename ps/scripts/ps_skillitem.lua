-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSystemChanged();
end

function onSystemChanged()
	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");

	spot.setVisible(not bPFMode);
	listen.setVisible(not bPFMode);
	search.setVisible(bPFMode or not bPFMode);
	notice.setVisible(bPFMode);
	sensemotive.setVisible(bPFMode);
	
	gatherinfo.setVisible(not bPFMode);
	
	acrobatics.setVisible(bPFMode);
	heal.setVisible(bPFMode);
	jump.setVisible(bPFMode or not bPFMode);
	
	hide.setVisible(not bPFMode);
	movesilent.setVisible(not bPFMode);
	stealth.setVisible(bPFMode);
end
