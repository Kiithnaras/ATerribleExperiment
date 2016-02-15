-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSystemChanged();
end

function onSystemChanged()
	notice.setVisible(true);
	spot.setVisible(false);
	listen.setVisible(false);
	search.setVisible(true);
	perception.setVisible(false);
	sensemotive.setVisible(true);
	
	gatherinfo.setVisible(false);
	
	acrobatics.setVisible(true);
	heal.setVisible(true);
	jump.setVisible(false);
	
	hide.setVisible(false);
	movesilent.setVisible(false);
	stealth.setVisible(true);
end
