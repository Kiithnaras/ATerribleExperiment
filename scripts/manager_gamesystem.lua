-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getSkill(sLabel)
	if not sLabel then
		return nil;
	end
	
	if OptionsManager.isOption("SYSTEM", "pf") then
		return DataCommon.PF_skilldata[sLabel];
	end

	return DataCommon.skilldata[sLabel];
end

function getSkillList()
	if OptionsManager.isOption("SYSTEM", "pf") then
		return DataCommon.PF_skilldata;
	end

	return DataCommon.skilldata;
end

function getPSSkillList()
	if OptionsManager.isOption("SYSTEM", "pf") then
		return DataCommon.PF_psskilldata;
	end

	return DataCommon.psskilldata;
end

function getDeathThreshold(rActor)
	local nDying = 10;

	if OptionsManager.isOption("SYSTEM", "pf") then
		local nStat = ActorManager.getAbilityScore(rActor, "constitution");
		local nStatDmg = ActorManager.getAbilityDamage(rActor, "constitution");
		if nStat < 0 then
			nDying = 10;
		else
			nDying = nStat - nStatDmg;
			if nDying < 1 then
				nDying = 1;
			end
		end
	end
	
	return nDying;
end

function getStabilizationRoll(rActor)
	local rRoll = { sType = "stabilization", sDesc = "[STABILIZATION]" };
	
	if OptionsManager.isOption("SYSTEM", "pf") then
		rRoll.aDice = { "d20" };
		rRoll.nMod = ActorManager.getAbilityBonus(rActor, "constitution");
		
		local nHP = 0;
		local nWounds = 0;
		if rActor.sType == "ct" then
			nHP = DB.getValue(rActor.nodeCT, "hp", 0);
			nWounds = DB.getValue(rActor.nodeCT, "wounds", 0);
		elseif rActor.sType == "pc" then
			nHP = DB.getValue(rActor.nodeCreature, "hp.total", 0);
			nWounds = DB.getValue(rActor.nodeCreature, "hp.wounds", 0);
		end
		if nHP > 0 and nWounds > nHP then
			rRoll.sDesc = string.format("%s [at %+d]", rRoll.sDesc, (nHP - nWounds));
			rRoll.nMod = rRoll.nMod + (nHP - nWounds);
		end
	
	else
		rRoll.aDice = { "d100", "d10" };
		rRoll.nMod = 0;
	end
	
	return rRoll;
end

function modStabilization(rSource, rTarget, rRoll)
	if OptionsManager.isOption("SYSTEM", "pf") then
		ActionAbility.modRoll(rSource, rTarget, rRoll);
	end
end

function getStabilizationResult(rRoll)
	local bSuccess = false;
	
	local nTotal = ActionsManager.total(rRoll);

	if OptionsManager.isOption("SYSTEM", "pf") then
		local nFirstDie = 0;
		if #(rRoll.aDice) > 0 then
			nFirstDie = rRoll.aDice[1].result or 0;
		end
		
		if nFirstDie >= 20 or nTotal >= 10 then
			bSuccess = true;
		end
	else
		if nTotal <= 10 then
			bSuccess = true;
		end
	end
	
	return bSuccess;
end

function performConcentrationCheck(draginfo, rActor, nodeSpellClass)
	if OptionsManager.isOption("SYSTEM", "Blob") then
		local rRoll = { sType = "concentration", sDesc = "[CONCENTRATION]", aDice = { "d20" } };
	
		local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end

		local nCL = DB.getValue(nodeSpellClass, "cl", 0);
		rRoll.nMod = nCL + ActorManager.getAbilityBonus(rActor, sAbility);
		
		local nCCMisc = DB.getValue(nodeSpellClass, "cc.misc", 0);
		if nCCMisc ~= 0 then
			rRoll.nMod = rRoll.nMod + nCCMisc;
			rRoll.sDesc = string.format("%s (Spell Class %+d)", rRoll.sDesc, nCCMisc);
		end
		
		ActionsManager.performSingleRollAction(draginfo, rActor, "concentration", rRoll);
	else
		local sSkill = "Concentration";
		local nValue = 0;
		if rActor.sType == "pc" then
			nValue = CharManager.getSkillValue(rActor, sSkill);
		else
			local sSkills = DB.getValue(rActor.nodeCreature, "skills", "");
			local aSkillClauses = StringManager.split(sSkills, ",;\r", true);
			for i = 1, #aSkillClauses do
				local nStarts, nEnds, sLabel, sSign, sMod = string.find(aSkillClauses[i], "([%w%s\(\)]*[%w\(\)]+)%s*([%+%-–]?)(%d*)");
				if nStarts and string.lower(sSkill) == string.lower(sLabel) and sMod ~= "" then
					nValue = tonumber(sMod) or 0;
					if sSign == "-" or sSign == "–" then
						nValue = 0 - nValue;
					end
					break;
				end
			end
		end
		
		local sExtra = nil;
		local nCCMisc = DB.getValue(nodeSpellClass, "cc.misc", 0);
		if nCCMisc ~= 0 then
			nValue = nValue + nCCMisc;
			sExtra = string.format("(Spell Class %+d)", nCCMisc);
		end
		
		ActionSkill.performRoll(draginfo, rActor, sSkill, nValue, nil, nil, false, false, sExtra);
	end
end
