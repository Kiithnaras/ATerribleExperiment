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
	
	local sColor;
	if nPercentWounded <= 1 and nPercentNonlethal > 1 then
		sColor = ActorManager2.COLOR_HEALTH_UNCONSCIOUS;
	elseif nPercentWounded == 1 or nPercentNonlethal == 1 then
		sColor = ColorManager.COLOR_HEALTH_SIMPLE_BLOODIED;
	else
		sColor = ColorManager.getHealthColor(nPercentNonlethal, true);
	end
	hpbar.updateBackColor(sColor);
	
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
