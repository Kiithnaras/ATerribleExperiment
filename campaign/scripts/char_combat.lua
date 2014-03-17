-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;

function isInitialized()
	return bInitialized;
end

function onInit()
	bInitialized = true;
	
	acstat.onValueChanged();
	acstat2.onValueChanged();
	cmdbase.onValueChanged();
	cmdstat.onValueChanged();
	fortitudestat.onValueChanged();
	reflexstat.onValueChanged();
	willstat.onValueChanged();
	initiativestat.onValueChanged();
	meleestat.onValueChanged();
	rangedstat.onValueChanged();
	grapplestat.onValueChanged();

	onSystemChanged();
end

function onSystemChanged()
	
	line_cmd.setVisible(true);
	
	cmd.setVisible(true);
	label_cmd.setVisible(true);
	cmdacarmor.setVisible(true);
	cmdacshield.setVisible(true);
	cmdacstatmod.setVisible(true);
	cmdacsize.setVisible(true);
	cmdacnatural.setVisible(true);
	cmdacdeflection.setVisible(true);
	cmdacdodge.setVisible(true);
	cmdmisc.setVisible(true);
	
	cmdstat.setVisible(true);
	cmdstatmod.setVisible(true);
	cmdbase.setVisible(true);
	cmdbasemod.setVisible(true);
	acframe.setStaticBounds(15,0,480,210);
	label_grapple.setValue(Interface.getString("cmb"));
end
