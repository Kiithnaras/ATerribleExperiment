-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function isWeapon(sClass, vRecord)
	local bIsWeapon = false;

	local nodeItem;
	if type(vRecord) == "string" then
		nodeItem = DB.findNode(vRecord);
	elseif type(vRecord) == "databasenode" then
		nodeItem = vRecord;
	end
	
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if sClass == "referenceweapon" then
		bIsWeapon = true;
	elseif sClass == "item" then
		if (sTypeLower == "weapon") or (sSubtypeLower == "weapon") then
			bIsWeapon = true;
		end
		if sSubtypeLower == "ammunition" then
			bIsWeapon = false;
		end
	end
	
	return bIsWeapon, sTypeLower, sSubtypeLower;
end

function isItemClass(sClass)
	return StringManager.contains({"referencearmor", "referenceweapon", "referenceequipment"}, sClass);
end

function addItemToList2(sClass, nodeSource, nodeTarget)
	if isItemClass(sClass) then
		DB.copyNode(nodeSource, nodeTarget);
		DB.setValue(nodeTarget, "isidentified", "number", 1);
		return true;
	end

	return false;
end
