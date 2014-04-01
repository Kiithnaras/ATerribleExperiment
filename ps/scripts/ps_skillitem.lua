-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSystemChanged();
end

function onSystemChanged()
	local bPFMode = DataCommon.isPFRPG();

	notice.setVisible(true);
	search.setVisible(true);
	sensemotive.setVisible(true);
	
	acrobatics.setVisible(true);
	heal.setVisible(true);
	jump.setVisible(true);
	
	stealth.setVisible(true);
end
