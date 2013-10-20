-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

iscustom = true;
sets = {};

function onInit()
	updateMenu();
	
	onCheckPenaltyChange();
	onStatUpdate();
end

function onSystemChanged(bPFMode)
	total.onSourceUpdate();
end

function onMenuSelection(selection, subselection)
	if selection == 4 then
		windowlist.addNewInstance(label.getValue());
	end
	if selection == 6 and subselection == 7 then
		local node = getDatabaseNode();
		if node then
			node.delete();
		else
			close();
		end
	end
end

function onCheckPenaltyChange()
	if armorcheckmultiplier.getValue() ~= 0 then
		armorwidget.setIcon("indicator_armorcheck");
	else
		armorwidget.setIcon(nil);
	end
end

function onStatUpdate()
	stat.update(statname.getStringValue());
end

-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		label.setEnabled(true);
		label.setLine(true);
		
		statname.setStateFrame("hover", "sheetfocus", 6, 5, 6, 5);
		statname.setReadOnly(false);
	else
		label.setEnabled(false);
		label.setLine(false);
		
		statname.setStateFrame("hover", nil);
		statname.setReadOnly(true);
	end
	
	updateMenu();
end

function updateMenu()
	resetMenuItems();
	
	if iscustom then
		registerMenuItem("Delete Item", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);
	else
		local sLabel = label.getValue();
		local rSkill = GameSystemManager.getSkill(sLabel);
		if rSkill and rSkill.sublabeling then
			-- Allow creation of sub-skills
			registerMenuItem("Create Sub Skill", "edit", 4);
		
			-- Disallow deletion of non-custom skills
			-- Except for sublabeled skills that have several instances
			local count = 0;
			for _,w in pairs(windowlist.getWindows()) do
				if w.label.getValue() == sLabel then
					count = count + 1;
				end
			end
		
			if count > 1 then
				registerMenuItem("Delete Item", "delete", 6);
				registerMenuItem("Confirm Delete", "delete", 6, 7);
			end
		end
	end
end
