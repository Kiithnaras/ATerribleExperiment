-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bShow = true;

function onInit()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	local nLevel = tonumber(string.sub(node.getName(), 6)) or 0;
	DB.setValue(node, "level", "number", nLevel);

	updateLabel();
	
	if not windowlist.isReadOnly() then
		registerMenuItem("Add Spell", "insert", 5);
		registerMenuItem("Delete Level " .. nLevel .. " Spells", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);
	end
end

function getActorType()
	return windowlist.window.getActorType();
end	

function setFilter(bFilter)
	bShow = bFilter;
end

function getFilter()
	return bShow;
end

function updateLabel()
	local sLabel = "Level " .. DB.getValue(getDatabaseNode(), "level", 0);
	
	label.setValue(sLabel);
end
	
function onSpellCounterUpdate()
	windowlist.window.onSpellCounterUpdate();
end

function onMenuSelection(selection, subselection)
	if selection == 5 then
		spells.addEntry(true);
	elseif selection == 6 and subselection == 7 then
		for _,v in pairs(DB.getChildren(getDatabaseNode(), "spells")) do
			v.delete();
		end
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if DB.getChildCount(spells.getDatabaseNode(), "") == 0 then
		spells.addEntry(true);
		return true;
	end

	spells.setVisible(not spells.isVisible());
	return true;
end
