-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	if node then
		node.createChild("level0");
		node.createChild("level1");
		node.createChild("level2");
		node.createChild("level3");
		node.createChild("level4");
		node.createChild("level5");
		node.createChild("level6");
		node.createChild("level7");
		node.createChild("level8");
		node.createChild("level9");
	end
end

function onFilter(w)
	return w.getFilter();
end

function addEntry()
	return NodeManager.createWindow(self);
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return false;
	end
	
	local winLevel = getWindowAt(x, y);
	if not winLevel then
		return false;
	end

	-- Draggable spell name to move spells
	if draginfo.isType("spellmove") then
		local node = winLevel.getDatabaseNode();
		if node then
			local nodeSource = draginfo.getDatabaseNode();
			local nodeSpells = node.getChild("spells");
			
			local nodeNew = SpellsManager.addSpell(nodeSource, nodeSpells);
			if nodeNew then
				nodeSource.delete();

				winLevel.spells.setVisible(true);

				-- Change the spell mode so that all spells are shown
				DB.setValue(window.getDatabaseNode().getChild("..."), "spellmode", "string", "standard");
			end
		end
		
		return true;

	-- Module spell reference within class list (i.e. has level information)
	elseif draginfo.isType("spelldescwithlevel") then
		local node = winLevel.getDatabaseNode();
		if node then
			local nodeSource = draginfo.getDatabaseNode();
			local nodeSpells = node.getChild("spells");
				
			local nodeNew = SpellsManager.addSpell(nodeSource, nodeSpells);
			if nodeNew then
				winLevel.spells.setVisible(true);

				-- Change the spell mode so that all spells are shown
				DB.setValue(window.getDatabaseNode().getChild("..."), "spellmode", "string", "standard");
			end
		end
		
		return true;
	
	elseif draginfo.isType("shortcut") then
		local sDropClass, sSource = draginfo.getShortcutData();

		-- Module spell reference with no level information
		if sDropClass == "spelldesc" or sDropClass == "spelldesc2" then
			local nodeSource = DB.findNode(sSource);
			local nodeTargetLevelSpells = nil;
			local nodeTargetLevel = winLevel.getDatabaseNode();
			if nodeTargetLevel then
				nodeTargetLevelSpells = nodeTargetLevel.getChild("spells");
			end
			
			local nodeNew = SpellsManager.addSpell(nodeSource, nodeTargetLevelSpells);
			if nodeNew then
				winLevel.spells.setVisible(true);

				-- Change the spell mode so that all spells are shown
				DB.setValue(window.getDatabaseNode().getChild("..."), "spellmode", "string", "standard");
			end
			
			return true;
		end
	end
end
