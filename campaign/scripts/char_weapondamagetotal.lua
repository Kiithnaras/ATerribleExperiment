-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onSourceUpdate()
	local nodeWin = window.getDatabaseNode();
	
	local nValue = calculateSources();

	local sDamageStat1, nMaxStat, nMult, sDamageStat2 = CharManager.getWeaponDamageStats(nodeWin);
	
	local nDamageStat1 = 0;
	if nMult ~= 0 then
		-- Check for max limited stat bonus
		local nDamageStat1 = DB.getValue(nodeWin, "...abilities." .. sDamageStat1 .. ".bonus", 0);
		if nMaxStat then
			if nDamageStat1 >= nMaxStat then
				nDamageStat1 = nMaxStat;
			end
		end
		
		-- Multiplier is always one for stat penalties
		if nDamageStat1 >= 0 then
			nDamageStat1 = math.floor(nDamageStat1 * nMult);
		end
		
		nValue = nValue + nDamageStat1;
	end
	
	if sDamageStat2 ~= "" then
		nValue = nValue + DB.getValue(nodeWin, "...abilities." .. sDamageStat2 .. ".bonus", 0);
	end
	
	setValue(nValue);
end

function action(draginfo)
	local rActor, rDamage = CharManager.getWeaponDamageRollStructures(window.getDatabaseNode());

	ActionDamage.performRoll(draginfo, rActor, rDamage);
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end

function onDoubleClick(x,y)
	return action();
end			
