-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInit = false;

function onInit()
	registerMenuItem("Create", "insert", 5);
	
	-- Register callback on option change
	OptionsManager.registerCallback("SYSTEM", onSystemChanged);
	onSystemChanged();

	local nodeChar = getDatabaseNode().getParent();
	local sChar = nodeChar.getNodeName();
	DB.addHandler(sChar ..  ".abilities", "onChildUpdate", onStatUpdate);
	DB.addHandler(sChar .. ".skilllist.*.label", "onUpdate", constructDefaultSkills);
end

function onClose()
	OptionsManager.unregisterCallback("SYSTEM", onSystemChanged);
end

 function onListRearranged(bListChanged)
	 if bListChanged and bInit then
		for _,w in pairs(getWindows()) do
			w.updateMenu();
		end
	end
end

function onSystemChanged()
	constructDefaultSkills();

	local bPFMode = OptionsManager.isOption("SYSTEM", "pf");
	for _,w in pairs(getWindows()) do
		w.onSystemChanged(bPFMode);
	end

	CharManager.updateSkillPoints(window.getDatabaseNode());
end

function onStatUpdate()
	for _,w in pairs(getWindows()) do
		w.onStatUpdate();
	end
end

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	win.setCustom(true);
	if bFocus and win then
		win.label.setFocus();
	end
	return win;
end

function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

-- Create default skill selection
function constructDefaultSkills()
	bInit = false;
	
	local aSystemSkills = GameSystemManager.getSkillList();
	
	-- Collect existing entries
	local entrymap = {};
	for _,w in pairs(getWindows()) do
		local sLabel = w.label.getValue();
	
		if aSystemSkills[sLabel] then
			if not entrymap[sLabel] then
				entrymap[sLabel] = { w };
			else
				table.insert(entrymap[sLabel], w);
			end
		else
			w.setCustom(true);
		end
	end

	-- Set properties and create missing entries for all known skills
	for k,t in pairs(aSystemSkills) do
		local matches = entrymap[k];
		
		if not matches then
			local wnd = NodeManager.createWindow(self);
			if wnd then
				wnd.label.setValue(k);
				if t.trainedonly then
					wnd.showonminisheet.setState(false);
				end
				matches = { wnd };
			end
		end
		
		-- Update properties
		local bCustom = false;
		for _, match in pairs(matches) do
			match.setCustom(bCustom);
			if not bCustom or t.sublabeling then
				if t.stat then
					match.statname.setStringValue(t.stat);
				else
					match.statname.setStringValue("");
				end
				match.statname.setReadOnly(true);

				if t.sublabeling then
					match.sublabel.setVisible(true);
					match.label.setAnchor("right", "ranks", "left", "absolute", -125);
				end

				if t.armorcheckmultiplier then
					match.armorcheckmultiplier.setValue(t.armorcheckmultiplier);
				else
					match.armorcheckmultiplier.setValue(0);
				end
			else
				match.statname.setReadOnly(false);
				match.armorcheckmultiplier.setValue(0);
			end
			
			if not t.sublabeling then
				bCustom = true;
			end
		end
	end
	
	bInit = true;
end

function addNewInstance(sLabel)
	local rSkill = GameSystemManager.getSkill(sLabel);
	
	if rSkill and rSkill.sublabeling then
		local win = NodeManager.createWindow(self);
		if win then
			win.label.setValue(sLabel);
			win.label.setAnchor("right", "ranks", "left", "absolute", -125);
			win.sublabel.setVisible(true);
			win.statname.setStringValue(rSkill.stat);
			win.setCustom(false);

			win.sublabel.setFocus();
			
			onListRearranged(true);
		end
	end
end
