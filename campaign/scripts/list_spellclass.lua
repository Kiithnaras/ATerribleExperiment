-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInit = false;
function onInit()
	bInit = true;
end

function onListChanged()
	if not minisheet then
		update();
	end
end

function update()
	if minisheet then
		return;
	end
	
	if bInit then
		local bEditMode = window.getEditMode();
		for _,w in ipairs(getWindows()) do
			w.update(bEditMode);
		end
	end
end

function onFilter(w)
	return w.getFilter();
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return false;
	end

	if draginfo.isType("spellmove") then
		local winClass = getWindowAt(x, y);
		if winClass then
			local nodeWin = winClass.getDatabaseNode();
			if nodeWin then
				local nodeSource = draginfo.getDatabaseNode();
				if nodeSource then
					nodeSourceLevel = nodeSource.getChild("...");
				end

				local nTargetLevel = draginfo.getNumberData();
				local nodeTargetLevel = nodeWin.getChild("levels.level" .. nTargetLevel);
				
				-- Create a new node at the destination, and delete the old node at the source
				if nodeSourceLevel and nodeTargetLevel and nodeSourceLevel.getNodeName() ~= nodeTargetLevel.getNodeName() then
					local nodeTargetLevelSpells = nodeTargetLevel.getChild("spells");
					
					local nodeNew = SpellManager.addSpell(nodeSource, nodeTargetLevelSpells);
					if nodeNew then
						nodeSource.delete();
					
						for kWin, vWin in pairs(winClass.levels.getWindows()) do
							if vWin.getDatabaseNode() == nodeTargetLevel then
								vWin.spells.setVisible(true);
								break;
							end
						end

						-- Change the spell mode so that all spells are shown
						DB.setValue(window.getDatabaseNode(), "spellmode", "string", "standard");
					end
				end
			end

			return true;
		end

	elseif draginfo.isType("spelldescwithlevel") then
		local winClass = getWindowAt(x, y);
		if winClass then
			local nodeWin = winClass.getDatabaseNode();
			if nodeWin then
				local nodeSource = draginfo.getDatabaseNode();
				
				local nSourceLevel = draginfo.getNumberData();
				local nodeTargetLevelSpells = nodeWin.getChild("levels.level" .. nSourceLevel .. ".spells");
				
				local nodeNew = SpellManager.addSpell(nodeSource, nodeTargetLevelSpells);
				if nodeNew then
					local nodeTargetLevel = nodeWin.getChild("levels.level" .. nSourceLevel);
					for kWin, vWin in pairs(winClass.levels.getWindows()) do
						if vWin.getDatabaseNode() == nodeTargetLevel then
							vWin.spells.setVisible(true);
							break;
						end
					end

					-- Change the spell mode so that all spells are shown
					DB.setValue(window.getDatabaseNode(), "spellmode", "string", "standard");
				end
			end
			
			return true;
		end
	end
end
