-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		local nCoinTypes = #(DataCommon.cointypes);
		
		if not list_coins.getNextWindow(nil) then
			for i = 1, nCoinTypes do
				local w = list_coins.createWindow();
				w.description.setValue(DataCommon.cointypes[i]);
			end
		end

		if not list_items.getNextWindow(nil) then
			for i = 1, nCoinTypes do
				list_items.createWindow();
			end
		end
	end

	local nodeCoinList = getDatabaseNode().createChild("coinlist");
	nodeCoinList.onChildUpdate = totalMoneyTreasure;

	totalMoneyTreasure();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sLink = draginfo.getShortcutData();
		
		if sLink == "referencearmor" or sLink == "referenceweapon" or sLink == "referenceequipment" or sLink == "item" or sLink == "referencemagicitem" then
			local w = nil;
			for _,v in ipairs(list_items.getWindows()) do
				local sLink, sRecord = v.shortcut.getValue();
				if v.amount.getValue() == 0 and v.description.getValue() == "" and sLink == "" and sRecord == "" then
					w = v;
				end
			end
			if not w then
				w = list_items.createWindow();
			end
			
			if w then
				local nodeSrc = draginfo.getDatabaseNode();		
				w.amount.setValue(1);
				w.description.setValue(DB.getValue(nodeSrc, "name", ""));
				w.shortcut.setValue(sLink, nodeSrc.getNodeName());
			end
		end
		return true;
	end
end

function clearAllItems()
	local nCoinTypes = #(DataCommon.cointypes);

	local n = 0;
	for _,v in pairs(DB.getChildren(getDatabaseNode(), "itemlist")) do
		if n < nCoinTypes then
			n = n + 1;
			DB.setValue(v, "amount", "number", 0);
			DB.setValue(v, "description", "string", "");
			DB.setValue(v, "shortcut", "windowreference", "", "");
		else
			v.delete();
		end
	end
end

function clearAllCoins()
	for _,v in pairs(DB.getChildren(getDatabaseNode(), "itemlist")) do
		DB.setValue(v, "amount", "number", 0);
	end
end

function totalMoneyTreasure()
	local nTotal = 0;
	
	for _,v in pairs(DB.getChildren(getDatabaseNode(), "coinlist")) do
		local sDesc = string.lower(DB.getValue(v, "description", ""));
		local nAmount = DB.getValue(v, "amount", 0);
		
		if sDesc:match("gold") or sDesc:match("gp") then
			nTotal = nTotal + nAmount;
		elseif sDesc:match("platinum") or sDesc:match("pp") then
			nTotal = nTotal + (nAmount * 10);
		elseif sDesc:match("silver") or sDesc:match("sp") then
			nTotal = nTotal + math.floor((nAmount / 10) + 0.5);
		elseif sDesc:match("copper") or sDesc:match("cp") then
			nTotal = nTotal + math.floor((nAmount / 100) + 0.5);
		end
	end
						
	monetarytotal.setValue(nTotal);
end
