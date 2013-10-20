-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSystemChanged();
	onXPChanged();
	onHPChanged();
end

function onSystemChanged()
	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");
	cmd.setVisible(bPFMode);
end

function onXPChanged()
	local nExp = exp.getValue();
	local nExpNeeded = expneeded.getValue();
	
	local sToolText = "";
	local nPercentNextLevel = 0;
	if TableManager and TableManager.findTable("Character Advancement") then
		local nLevel = level.getValue();
		if nLevel < 1 then
			nLevel = 1;
		end
		
		local nRelXPTotal = 0;
		local nRelXPNextLevel = 0;
		local lookupCurrLevelXPTotal = TableManager.lookup("Character Advancement", nLevel, "Total XP");
		local lookupNexttLevelXPTotal = TableManager.lookup("Character Advancement", nLevel + 1, "Total XP");	
		if lookupCurrLevelXPTotal and lookupNexttLevelXPTotal then
			lookupCurrLevelXPTotal = string.gsub(lookupCurrLevelXPTotal, ",", "");
			lookupNexttLevelXPTotal = string.gsub(lookupNexttLevelXPTotal, ",", "");
			
			nRelXPTotal = nExp - tonumber(lookupCurrLevelXPTotal);
			nRelXPNextLevel = tonumber(lookupNexttLevelXPTotal) - tonumber(lookupCurrLevelXPTotal);
		end

		sToolText = "Relative XP: ";
		nExp = nRelXPTotal;
		nExpNeeded = nRelXPNextLevel;
	else
		sToolText = "XP: ";
	end
	
	xpbar.setMax(nExpNeeded);
	xpbar.setValue(nExp);
	sToolText = sToolText .. tostring(nExp) .. " / " .. tostring(nExpNeeded);
	xpbar.updateText(sToolText);
	
	if (nExpNeeded > 0) and ((nExp / nExpNeeded) >= .75) then
		xpbar.updateBackColor("990000");
	else
		xpbar.updateBackColor("0F0B0B");
	end
end

function onHPChanged()
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
