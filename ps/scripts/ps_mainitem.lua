-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSystemChanged();
	onHealthChanged();
end

function onSystemChanged()
	cmd.setVisible(true);
end

function onHealthChanged()
	local nHP = math.max(hptotal.getValue(), 0);
	local nTempHP = math.max(hptemp.getValue(), 0);

	local nWounds = math.max(wounds.getValue(), 0);
	local nNonlethal = math.max(nonlethal.getValue(), 0);
	
	local nPercentWounded = 0;
	local nPercentNonlethal = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / (nHP + nTempHP);
		nPercentNonlethal = (nWounds + nNonlethal) / (nHP + nTempHP);
	end
	
	if nPercentWounded >= 1 then
		hpbar.updateBackColor("808080");
	elseif nPercentNonlethal >= 1 then
		hpbar.updateBackColor("663399");
	elseif nPercentWounded >= .66 then
		hpbar.updateBackColor("990000");
	elseif nPercentWounded >= .33 then
		hpbar.updateBackColor("CC6600");
	elseif nPercentWounded > 0 then
		hpbar.updateBackColor("006600");
	else
		hpbar.updateBackColor("000099");
	end
	
	hpbar.setMax(nHP + nTempHP);
	hpbar.setValue(nHP + nTempHP - nWounds);
	
	local sText = "HP: " .. (nHP - nWounds);
	if nTempHP > 0 then
		sText = sText .. " (+" .. nTempHP .. ")";
	end
	sText = sText .. " / " .. nHP;
	if nTempHP > 0 then
		sText = sText .. " (+" .. nTempHP .. ")";
	end
	hpbar.updateText(sText);
end
