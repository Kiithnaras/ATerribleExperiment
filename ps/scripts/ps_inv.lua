-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		local nCoinTypes = #(DataCommon.cointypes);
		
		if not parcelcoinlist.getNextWindow(nil) then
			for i = 1, nCoinTypes do
				local w = parcelcoinlist.createWindow();
				w.description.setValue(DataCommon.cointypes[i]);
			end
		end

		rebuild();
	else
		OptionsManager.registerCallback("PSIN", StateChanged);
		StateChanged();
	end
	
	OptionsManager.registerCallback("MIID", onIDChanged);
end

function onClose()
	if not User.isHost() then
		OptionsManager.unregisterCallback("PSIN", StateChanged);
	end

	OptionsManager.unregisterCallback("MIID", onIDChanged);
end

function StateChanged()
	local bOptPSIN = OptionsManager.isOption("PSIN", "on");

	sheetframe.setVisible(bOptPSIN);
	label_inv_main.setVisible(bOptPSIN);
	label_inv_count.setVisible(bOptPSIN);
	label_inv_name.setVisible(bOptPSIN);
	label_inv_carried.setVisible(bOptPSIN);
	itemlist.setVisible(bOptPSIN);
	
	coinframe.setVisible(bOptPSIN);
	label_coin_main.setVisible(bOptPSIN);
	label_coin_count.setVisible(bOptPSIN);
	label_coin_name.setVisible(bOptPSIN);
	label_coin_carried.setVisible(bOptPSIN);
	coinlist.setVisible(bOptPSIN);
	
	if bOptPSIN then
		pitemframe.setStaticBounds(10,35,-350,188);
		pcoinframe.setStaticBounds(-350,35,-20,188);
	else
		pitemframe.setStaticBounds(10,35,-350,-15);
		pcoinframe.setStaticBounds(-350,35,-20,-15);
	end
end

function onIDChanged()
	for _,w in pairs(parcelitemlist.getWindows()) do
		w.onIDChanged();
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "shortcut" then
		local sClass = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		
		if sClass == "treasureparcel" then
			addTreasureParcel(nodeSource);
		elseif sClass == "referencearmor" or sClass == "referenceweapon" or sClass == "referenceequipment" or sClass == "item" or sClass == "referencemagicitem" then
			addTreasureItem(sClass, nodeSource);
		end
	end
	
	return true;
end

function addTreasureItem(sClass, nodeSource)
	local w = parcelitemlist.createWindow();

	w.amount.setValue(1);
	w.description.setValue(DB.getValue(nodeSource, "name", ""));

	w.shortcut.setValue(sClass, nodeSource.getNodeName());

	local nID = DB.getValue(nodeSource, "isidentified", nil);
	if nID then
		w.isidentified.setValue(nID);
		w.nonid_name.setValue(DB.getValue(nodeSource, "nonid_name", ""));
	else
		if StringManager.contains({"item", "referencemagicitem"}, sClass) then
			w.isidentified.setValue(0);
		else
			w.isidentified.setValue(1);
		end
	end
end

function addTreasureParcel(nodeSource)
	if not nodeSource then
		return;
	end
	
	for _,v in pairs(DB.getChildren(nodeSource, "itemlist")) do
		local sItem = DB.getValue(v, "description", "");
		local nItem = DB.getValue(v, "amount", 0);
		if sItem ~= "" then
			if nItem < 1 then
				nItem = 1;
			end
			
			local winItem = parcelitemlist.createWindow();
			
			winItem.description.setValue(sItem);
			winItem.amount.setValue(DB.getValue(v, "amount", 0));

			local sClass, sRecord = DB.getValue(v, "shortcut");
			if sClass and sRecord then
				winItem.shortcut.setValue(sClass, sRecord);
				local nodeItem = winItem.shortcut.getTargetDatabaseNode();
				local nID = DB.getValue(nodeItem, "isidentified", nil);
				if nID then
					winItem.isidentified.setValue(nID);
					winItem.nonid_name.setValue(DB.getValue(nodeItem, "nonid_name", ""));
				else
					if StringManager.contains({"item", "referencemagicitem"}, sClass) then
						winItem.isidentified.setValue(0);
					else
						winItem.isidentified.setValue(1);
					end
				end
			else
				winItem.isidentified.setValue(1);
			end
		end
	end
	
	for _,v in pairs(DB.getChildren(nodeSource, "coinlist")) do
		local sCoin = string.upper(DB.getValue(v, "description", ""));
		local winCoin = nil;
		for _,w in ipairs(parcelcoinlist.getWindows()) do
			if string.upper(w.description.getValue()) == sCoin then
				winCoin = w;
				break;
			end
		end
		
		local nCoin = DB.getValue(v, "amount", 0);
		if winCoin then
			winCoin.description.setValue(sCoin);
			winCoin.amount.setValue(nCoin + winCoin.amount.getValue());
		else
			winCoin = parcelcoinlist.createWindow();
			winCoin.description.setValue(sCoin);
			winCoin.amount.setValue(nCoin);
		end
	end
end

function rebuild()
	buildPartyInventory();
	buildPartyCoins();
end

function distribute()
	distributeParcelAssignments();
	distributeParcelCoins();
end

function clearInventory()
	for _,v in pairs(itemlist.getWindows()) do
		v.getDatabaseNode().delete();
	end
end

function clearAllCoins()
	for _,v in pairs(coinlist.getWindows()) do
		v.amount.setValue(0);
	end
end

function clearAllParcelItems()
	for _,v in pairs(parcelitemlist.getWindows()) do
		v.getDatabaseNode().delete();
	end
end

function clearAllParcelCoins()
	for _,v in pairs(parcelcoinlist.getWindows()) do
		v.amount.setValue(0);
	end
end

function buildPartyInventory()
	clearInventory();

	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local sName = DB.getValue(v, "name", "");
				table.insert(aParty, { name = sName, node = nodePC } );
			end
		end
	end
	
	-- Build a database of party inventory items
	local aInvDB = {};
	for _,v in ipairs(aParty) do
		for _,nodeItem in pairs(DB.getChildren(v.node, "inventorylist")) do
			local bID = DB.getValue(nodeItem, "isidentified", 0);
			local sItem;
			if bID ~= 0 then
				sItem = DB.getValue(nodeItem, "name", "");
			else
				sItem = DB.getValue(nodeItem, "nonid_name", "");
				if sItem == "" then
					sItem = "Unidentified Item";
				end
			end
			if sItem ~= "" then
				local nCount = math.max(DB.getValue(nodeItem, "count", 0), 1)
				if aInvDB[sItem] then
					aInvDB[sItem].count = aInvDB[sItem].count + nCount;
				else
					local aItem = {};
					aItem.count = nCount;
					if bID ~= 0 then
						local sClass, sRecord = DB.getValue(nodeItem, "shortcut");
						if sClass and sClass ~= "" and sRecord and sRecord ~= "" then
							aItem.shortcut = { class = sClass, record = sRecord };
						else
							aItem.shortcut = { class = "item", record = nodeItem.getNodeName() };
						end
					end
					aInvDB[sItem] = aItem;
				end
				
				if not aInvDB[sItem].carriedby then
					aInvDB[sItem].carriedby = {};
				end
				aInvDB[sItem].carriedby[v.name] = ((aInvDB[sItem].carriedby[v.name]) or 0) + nCount;
			end
		end
	end
	
	-- Create party sheet inventory entries
	for sItem, rItem in pairs(aInvDB) do
		local w = itemlist.createWindow();
		w.count.setValue(rItem.count);
		w.name.setValue(sItem);
		
		local aCarriedBy = {};
		for k,v in pairs(rItem.carriedby) do
			table.insert(aCarriedBy, string.format("%s [%d]", k, math.floor(v)));
		end
		w.carriedby.setValue(table.concat(aCarriedBy, ", "));
		
		if rItem.shortcut then
			w.shortcut.setValue(rItem.shortcut.class, rItem.shortcut.record);
		end
	end
end

function buildPartyCoins()
	for _,v in pairs(coinlist.getWindows()) do
		v.getDatabaseNode().delete();
	end

	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local sName = DB.getValue(v, "name", "");
				table.insert(aParty, { name = sName, node = nodePC } );
			end
		end
	end
	
	-- Build a database of party coins
	local aCoinDB = {};
	for _,v in ipairs(aParty) do
		for _,nodeCoin in pairs(DB.getChildren(v.node, "coins")) do
			local sCoin = string.upper(DB.getValue(nodeCoin, "name", ""));
			if sCoin ~= "" then
				local nCount = DB.getValue(nodeCoin, "amount", 0);
				if nCount > 0 then
					if aCoinDB[sCoin] then
						aCoinDB[sCoin].count = aCoinDB[sCoin].count + nCount;
						aCoinDB[sCoin].carriedby = string.format("%s, %s [%d]", aCoinDB[sCoin].carriedby, v.name, math.floor(nCount));
					else
						local aCoin = {};
						aCoin.count = nCount;
						aCoin.carriedby = string.format("%s [%d]", v.name, math.floor(nCount));
						aCoinDB[sCoin] = aCoin;
					end
				end
			end
		end
	end
	
	-- Create party sheet coin entries
	for sCoin, rCoin in pairs(aCoinDB) do
		local w = coinlist.createWindow();
		w.amount.setValue(rCoin.count);
		w.name.setValue(sCoin);
		w.carriedby.setValue(rCoin.carriedby);
	end
end

function distributeParcelAssignments()
	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local rMember = {};
				
				rMember.name = DB.getValue(v, "name", "");
				rMember.node = nodePC;
				rMember.given = {};
				
				table.insert(aParty, rMember);
			end
		end
	end
	if #aParty == 0 then
		return;
	end

	-- Add assigned items to party members
	local nItems = 0;
	local aItemsAssigned = {};
	for _,w in ipairs(parcelitemlist.getWindows()) do
		local sItem = w.description.getValue();
		local nCount = w.amount.getValue();
		if sItem ~= "" and nCount > 0 then
			nItems = nItems + 1;

			local sAssign = w.assign.getValue();
			if sAssign ~= "" then
				local sError = nil;
				local rMember = nil;
				for _,v in ipairs(aParty) do
					if sAssign == v.name then
						rMember = v;
						break;
					end
				end
				if rMember then
					local nodePCInv = rMember.node.createChild("inventorylist");
					if nodePCInv then
						local sClass, sRecord = w.shortcut.getValue();
						local nodeSource = nil;
						if StringManager.contains({"item", "referencemagicitem", "referencearmor", "referenceweapon", "referenceequipment"}, sClass) then
							nodeSource = w.shortcut.getTargetDatabaseNode();
							if not nodeSource then
								sError = "Target database node for item (" .. sItem .. ") no longer exists.";
							end
						end
						
						local nodeItem = nil;
						if nodeSource then
							nodeItem = CharManager.addItemDB(rMember.node, nodeSource, sClass);
						else
							local nodeItem = nodePCInv.createChild();
							DB.setValue(nodeItem, "count", "number", nCount);
							DB.setValue(nodeItem, "name", "string", sItem);
						end
						
						if nodeItem then
							if nodeSource then
								local nID = DB.getValue(nodeSource, "isidentified", nil);
								if not nID then
									if StringManager.contains({"item", "referencemagicitem"}, sClass) then
										nID = 0;
									else
										nID = 1;
									end
								end
								if nID == 0 then
									sItem = DB.getValue(nodeSource, "nonid_name", "");
									if sItem == "" then
										sItem = "Unidentified Item";
									end
								end
							end
							table.insert(aItemsAssigned, { item = sItem, name = rMember.name });
							w.getDatabaseNode().delete();
						else
							sError = "Unable to create character inventory entry (" .. sAssign .. ") for item assignment.";
						end
					else
						sError = "Unable to locate character inventory (" .. sAssign .. ") for item assignment.";
					end
				else
					sError = "Unable to locate character (" .. sAssign .. ") for item assignment.";
				end
				
				if sError then
					local msg = {font = "msgfont"};
					msg.text = "[WARNING] " .. sError;
					Comm.addChatMessage(msg);
				end
			end
		end
	end
	if nItems == 0 then
		return;
	end
	
	-- Output item assignments and rebuild party inventory
	local msg = {font = "msgfont", icon = "portrait_gm_token"};
	if #aItemsAssigned > 0 then
		msg.text = "Distributing assigned items to the Party";
		Comm.deliverChatMessage(msg);

		msg.icon = "icon_coins";
		for _,v in ipairs(aItemsAssigned) do
			msg.text = "[" .. v.item .. "] -> " .. v.name;
			Comm.deliverChatMessage(msg);
		end

		buildPartyInventory();
	else
		msg.text = "No items assigned for distribution to the Party";
		Comm.addChatMessage(msg);
	end
end

function distributeParcelCoins() 
	-- Determine coins in parcel
	local aParcelCoins = {};
	local nCoinEntries = 0;
	for _,w in ipairs(parcelcoinlist.getWindows()) do
		local sCoin = string.upper(w.description.getValue());
		local nCount = w.amount.getValue();
		if sCoin ~= "" and nCount > 0 then
			aParcelCoins[sCoin] = (aParcelCoins[sCoin] or 0) + nCount;
			nCoinEntries = nCoinEntries + 1;
		end
	end
	if nCoinEntries == 0 then
		return;
	end
	
	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local rMember = {};
				
				rMember.name = DB.getValue(v, "name", "");
				rMember.node = nodePC;
				rMember.coins = {};
				rMember.given = {};
				
				for _,nodeCoin in pairs(DB.getChildren(nodePC, "coins")) do
					local sCoin = string.upper(DB.getValue(nodeCoin, "name", ""));
					if sCoin ~= "" then
						rMember.coins[sCoin] = nodeCoin;
					end
				end
				
				table.insert(aParty, rMember);
			end
		end
	end
	if #aParty == 0 then
		return;
	end
	
	-- Add party member split to their character sheet
	for sCoin, nCoin in pairs(aParcelCoins) do
		local nAverageSplit;
		if nCoin >= #aParty then
			nAverageSplit = math.floor((nCoin / #aParty) + 0.5);
		else
			nAverageSplit = 0;
		end
		local nFinalSplit = math.max((nCoin - ((#aParty - 1) * nAverageSplit)), 0);
		
		for k,v in ipairs(aParty) do
			local nAmount;
			if k == #aParty then
				nAmount = nFinalSplit;
			else
				nAmount = nAverageSplit;
			end
			
			if nAmount > 0 then
				-- Add distribution amount to character
				local nodeTarget = nil;
				if v.coins[sCoin] then
					nodeTarget = v.coins[sCoin];
				else
					local nodeCoins = v.node.getChild("coins");
					if nodeCoins then
						for i = 1, 6 do
							local nodeCoin = nodeCoins.getChild("slot" .. i);
							if nodeCoin then
								local sCharCoin = DB.getValue(nodeCoin, "name", "");
								local nCharAmt = DB.getValue(nodeCoin, "amount", 0);
								if sCharCoin == "" and nCharAmt == 0 then
									nodeTarget = nodeCoin;
									break;
								end
							end
						end
					end
				end
				if nodeTarget then
					local nNewAmount = DB.getValue(nodeTarget, "amount", 0) + nAmount;
					DB.setValue(nodeTarget, "amount", "number", nNewAmount);
					DB.setValue(nodeTarget, "name", "string", sCoin);
				else
					local sCoinOther = DB.getValue(v.node, "coinother", "");
					if sCoinOther ~= "" then
						sCoinOther = sCoinOther .. ", ";
					end
					sCoinOther = sCoinOther .. nAmount .. " " .. sCoin;
					DB.setValue(v.node, "coinother", "string", sCoinOther);
				end
				
				-- Track distribution amount for output message
				v.given[sCoin] = nAmount;
			end
		end
	end
	
	-- Output coin assignments
	local aPartyAmount = {};
	for sCoin, nCoin in pairs(aParcelCoins) do
		table.insert(aPartyAmount, tostring(nCoin) .. " " .. sCoin);
	end

	local msg = {font = "msgfont", icon = "portrait_gm_token"};
	msg.text = "Distributing [" .. table.concat(aPartyAmount, ", ") .. "] across the Party";
	Comm.deliverChatMessage(msg);
	
	msg.icon = "icon_coins";
	for k,v in ipairs(aParty) do
		local aMemberAmount = {};
		for sCoin, nCoin in pairs(v.given) do
			table.insert(aMemberAmount, tostring(nCoin) .. " " .. sCoin);
		end
		msg.text = "[" .. table.concat(aMemberAmount, ", ") .. "] -> " .. v.name;
		Comm.deliverChatMessage(msg);
	end
	
	-- Reset parcel and party coin amounts
	clearAllParcelCoins();
	buildPartyCoins();
end
