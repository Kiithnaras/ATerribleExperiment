-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;
local bShow = true;
	
function onInit()
	bInitialized = true;
	
	if not minisheet and windowlist.npc then
		frame_stat.setAnchor("top", "frame_dc", "top");
		frame_stat.setAnchor("left", "", "left", "absolute", 160);
		frame_sp.setAnchor("top", "detailanchor", "bottom", "relative");
		frame_sp.setAnchor("left", "", "left", "absolute", 5);
		frame_cc.setAnchor("left", "", "left", "absolute", 155);
	end
	
	onCasterTypeChanged();
	toggleDetail();
end

function registerMenuItems()
	resetMenuItems();
	
	if not windowlist.isReadOnly() then
		registerMenuItem("Delete Spell Class", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);
	end
	
	if DB.getValue(getDatabaseNode(), "castertype", "") == "" then
		registerMenuItem("Reset memorized spells", "pointer_circle", 3);
	end
end

function getActorType()
	if windowlist.npc then
		return "npc";
	end
	return "pc";
end	

function onStatUpdate()
	if dcstatmod then
		local nodeSpellClass = getDatabaseNode();
		local nodeCreature = nodeSpellClass.getChild("...");

		local sType = "pc";
		if nodeCreature.getParent().getName() == "npc" then
			sType = "npc";
		end
		
		local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");

		local rActor = ActorManager.getActor(sType, nodeCreature);
		local nValue = ActorManager.getAbilityBonus(rActor, sAbility);
		
		dcstatmod.setValue(nValue);
	end
	
	for kLevel, vLevel in pairs(levels.getWindows()) do
		for kSpell, vSpell in pairs(vLevel.spells.getWindows()) do
			for kAction, vAction in pairs(vSpell.actions.getWindows()) do
				vAction.updateViews();
			end
		end
	end
end

function onMenuSelection(selection, subselection)
	if selection == 3 then
		local nodeCaster = getDatabaseNode().getChild("...");
		SpellsManager.resetPrepared(nodeCaster);
	elseif selection == 6 and subselection == 7 then
		local node = getDatabaseNode();
		if node then
			node.delete();
		else
			close();
		end
	end
end

function updateControl(sControl, bShow)
	local bLocalShow = bShow;
	
	if self[sControl] then
		self[sControl].setVisible(bLocalShow);
	else
		bLocalShow = false;
	end

	if self[sControl .. "_label"] then
		self[sControl .. "_label"].setVisible(bLocalShow);
	end
end

function toggleDetail()
	if minisheet then
		return;
	end
	
	local status = activatedetail.getValue();

	frame_levels.setVisible(status);
	updateControl("availablelevel", status);
	updateControl("availablelevel0", status);
	updateControl("availablelevel1", status);
	updateControl("availablelevel2", status);
	updateControl("availablelevel3", status);
	updateControl("availablelevel4", status);
	updateControl("availablelevel5", status);
	updateControl("availablelevel6", status);
	updateControl("availablelevel7", status);
	updateControl("availablelevel8", status);
	updateControl("availablelevel9", status);
	
	frame_stat.setVisible(status);
	updateControl("dcstat", status);
	
	frame_dc.setVisible(status);
	dc_label.setVisible(status);
	updateControl("dcstatmod", status);
	updateControl("dcmisc", status);
	updateControl("dctotal", status);
	
	frame_sp.setVisible(status);
	spmain_label.setVisible(status);
	updateControl("sp", status);
	
	frame_cc.setVisible(status);
	label_cc.setVisible(status);
	updateControl("ccmisc", status);
end

function setFilter(bFilter)
	bShow = bFilter;
end

function getFilter()
	return bShow;
end

function isInitialized()
	return bInitialized;
end

function getSheetMode()
	if minisheet then
		return "combat";
	end
	
	return DB.getValue(getDatabaseNode(), "...spellmode", "standard");
end

function onCasterTypeChanged()
	local bShowPP = (DB.getValue(getDatabaseNode(), "castertype", "") == "points");
	pointsused.setVisible(bShowPP);
	label_pointsused.setVisible(bShowPP);
	points.setVisible(bShowPP);
	label_points.setVisible(bShowPP);
	
	onSpellCounterUpdate();
	
	registerMenuItems();
end

function onSpellCounterUpdate()
	SpellsManager.updateSpellClassCounts(getDatabaseNode());

	updateSpellView();
	
	performFilter();
end

function updateSpellView()
	local nodeSpellClass = getDatabaseNode();

	local bClassShow = false;
	local sSheetMode = getSheetMode();
	local sCasterType = DB.getValue(nodeSpellClass, "castertype", "");

	local bLevelShow, nodeLevel, nAvailable, nTotalCast, nTotalPrepared, nMaxPrepared, nSpells;
	local bSpellShow, nodeSpell, nCast, nPrepared, nPointCost;

	local nPP = DB.getValue(nodeSpellClass, "points", 0);
	local nPPUsed = DB.getValue(nodeSpellClass, "pointsused", 0);
	
	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");
	
	for kLevel, vLevel in pairs(levels.getWindows()) do
		bLevelShow = false;

		nAvailable = 0;
		nodeLevel = vLevel.getDatabaseNode();
		if nodeLevel then
			nAvailable = DB.getValue(nodeSpellClass, "available" .. nodeLevel.getName(), 0);
		end
		
		nSpells = 0;
		nTotalCast = DB.getValue(nodeLevel, "totalcast", 0);
		nTotalPrepared = DB.getValue(nodeLevel, "totalprepared", 0);
		nMaxPrepared = DB.getValue(nodeLevel, "maxprepared", 0);

		if bPFMode and nodeLevel and nodeLevel.getName() == "level0" then
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				bSpellShow = true;
				nPrepared = DB.getValue(nodeSpell, "prepared", 0);
				
				if sCasterType == "" and sSheetMode == "combat" then
					if nPrepared == 0 then
						bSpellShow = false;
					end
				end
				bLevelShow = bLevelShow or bSpellShow;
				vSpell.setFilter(bSpellShow);
				
				if sCasterType == "" then
					if sSheetMode == "preparation" then
						vSpell.usepower.setVisible(false);
						vSpell.counter.setVisible(true);
						vSpell.counter.update(sSheetMode, (sCasterType == "spontaneous"), nAvailable, 0, nTotalPrepared, nMaxPrepared);
						vSpell.usespacer.setVisible(nAvailable == 0);
					else
						if (nPrepared  > 0) then
							vSpell.usepower.setVisible(true);
							vSpell.usepower.setTooltipText("Cast spell");
							vSpell.usespacer.setVisible(false);
						else
							vSpell.usepower.setVisible(false);
							vSpell.usespacer.setVisible(true);
						end
						vSpell.counter.setVisible(false);
					end
				elseif sCasterType == "points" then
					vSpell.usepower.setVisible(true);
					vSpell.usepower.setTooltipText("Use power");
					vSpell.counter.setVisible(false);
					vSpell.usespacer.setVisible(false);
				else
					vSpell.usepower.setVisible(true);
					vSpell.usepower.setTooltipText("Cast spell");
					vSpell.counter.setVisible(false);
					vSpell.usespacer.setVisible(false);
				end
				vSpell.cost.setVisible(false);
			end
			
			if sSheetMode == "combat" then
				bLevelShow = bLevelShow and (nAvailable > 0) and (nSpells > 0);
			else
				bLevelShow = (nAvailable > 0);
			end
			
		elseif sCasterType == "points" then
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				nPointCost = DB.getValue(nodeSpell, "cost", 0);
				
				if sSheetMode ~= "combat" then
					bSpellShow = true;
				else
					bSpellShow = (nPointCost <= (nPP - nPPUsed));
				end
				vSpell.setFilter(bSpellShow);
				bLevelShow = bLevelShow or bSpellShow;

				vSpell.usepower.setVisible(true);
				vSpell.cost.setVisible(true);
				vSpell.counter.setVisible(false);
				vSpell.usespacer.setVisible(false);
			end
		
			if sSheetMode == "combat" then
				bLevelShow = bLevelShow and (nAvailable > 0) and (nSpells > 0);
			else
				bLevelShow = (nAvailable > 0);
			end
		else
			-- Update spell counter objects and spell visibility
			for _,vSpell in pairs(vLevel.spells.getWindows()) do
				nodeSpell = vSpell.getDatabaseNode();
				nSpells = nSpells + 1;
				
				nCast = DB.getValue(nodeSpell, "cast", 0);
				nPrepared = DB.getValue(nodeSpell, "prepared", 0);
				
				if sCasterType == "spontaneous" or sSheetMode ~= "combat" then
					bSpellShow = true;
				else
					bSpellShow = (nCast < nPrepared);
				end
				bLevelShow = bLevelShow or bSpellShow;
				vSpell.setFilter(bSpellShow);

				vSpell.usepower.setVisible(false);
				vSpell.cost.setVisible(false);
				vSpell.counter.setVisible(true);
				vSpell.counter.update(sSheetMode, (sCasterType == "spontaneous"), nAvailable, nTotalCast, nTotalPrepared, nMaxPrepared);
				if (sSheetMode == "preparation" or sCasterType == "spontaneous") then
					vSpell.usespacer.setVisible(nAvailable == 0);
				else
					vSpell.usespacer.setVisible(nMaxPrepared == 0);
				end
			end
			
			-- Determine level visibility
			if sSheetMode == "combat" then
				bLevelShow = bLevelShow and (nTotalCast < nAvailable) and (nAvailable > 0) and (nSpells > 0);
			else
				bLevelShow = (nAvailable > 0);
			end
		end
		bClassShow = bClassShow or bLevelShow;
		vLevel.setFilter(bLevelShow);

		if not minisheet then
			-- Set level statistics label
			if bPFMode and nodeLevel and nodeLevel.getName() == "level0" then
				if sCasterType == "" then
					vLevel.stats.setValue("Prepared: " .. nTotalPrepared);
				else
					vLevel.stats.setValue("");
				end
			elseif (sCasterType ~= "points") and (nAvailable > 0) and (nSpells > 0) then
				if (sCasterType == "spontaneous") then
					vLevel.stats.setValue("Cast: " .. nTotalCast .. " / Per Day: " .. nAvailable);
				else
					vLevel.stats.setValue("Cast: " .. nTotalCast .. " / Prepared: " .. nTotalPrepared);
				end
			else
				vLevel.stats.setValue("");
			end
		end
	end
	
	if sSheetMode == "combat" then
		setFilter(bClassShow);
	else
		setFilter(true);
	end
end

function performFilter()
	for kLevel, vLevel in pairs(levels.getWindows()) do
		vLevel.spells.applyFilter();
	end

	levels.applyFilter();

	windowlist.applyFilter();
end

