-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CharManager.updateEncumbrance(window.getDatabaseNode());
end

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	if bFocus and win then
		win.name.setFocus();
	end
	return win;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not getNextWindow(nil) then
		addEntry(true);
	end
	return true;
end

function onSortCompare(w1, w2)
	local sName1 = ItemsManager.getVisibleName(w1.getDatabaseNode(), true):lower();
	local sName2 = ItemsManager.getVisibleName(w2.getDatabaseNode(), true):lower();
	local sLoc1 = w1.location.getValue():lower();
	local sLoc2 = w2.location.getValue():lower();
	
	-- Check for empty name (sort to end of list)
	if sName1 == "" then
		if sName2 == "" then
			return nil;
		end
		return true;
	elseif sName2 == "" then
		return false;
	end
	
	-- If different containers, then figure out containment
	if sLoc1 ~= sLoc2 then
		-- Check for containment
		if sLoc1 == sName2 then
			return true;
		end
		if sLoc2 == sName1 then
			return false;
		end
	
		if sLoc1 == "" then
			return sName1 > sLoc2;
		elseif sLoc2 == "" then
			return sLoc1 > sName2;
		else
			return sLoc1 > sLoc2;
		end
	end

	-- If same container, then sort by name or node id
	if sName1 ~= sName2 then
		return sName1 > sName2;
	end
end

function onListRearranged(bListChanged)
	if bListChanged then
		local containermapping = {};

		for k, w in ipairs(getWindows()) do
			local entry = {};
			entry.name = w.name.getValue();
			entry.location = w.location.getValue();
			entry.window = w;
			table.insert(containermapping, entry);
		end
		
		local lastcontainer = 1;
		for n, w in ipairs(containermapping) do
			if n > 1 and string.lower(w.location) == string.lower(containermapping[lastcontainer].name) and w.location ~= "" then
				-- Item in a container
				w.window.name.setAnchor("left", nil, "left", "absolute", 40);
			else
				-- Top level item
				w.window.name.setAnchor("left", nil, "left", "absolute", 30);
				lastcontainer = n;
			end
		end
		
		CharManager.updateEncumbrance(window.getDatabaseNode());
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sDropClass, sDropNodeName = draginfo.getShortcutData();
		local nodeSrc = draginfo.getDatabaseNode();
		local nodeList = getDatabaseNode();
		if not nodeSrc or not nodeList then
			return;
		end
		
		if StringManager.contains({"referencearmor", "referenceweapon", "referenceequipment", "item"}, sDropClass) then
			-- Make sure we're not dropping an item from our own list
			if sDropClass == "item" then
				local sListNode = nodeList.getNodeName();
				if string.sub(nodeSrc.getNodeName(), 1, #sListNode) == sListNode then
					return true;
				end
			end

			local nodeItem = CharManager.addItemDB(window.getDatabaseNode(), nodeSrc, sDropClass);
			for kWin, vWin in pairs(getWindows()) do
				if vWin.getDatabaseNode() == nodeItem then
					vWin.name.setFocus();
					break;
				end
			end
			return true;
		end
	end
end
