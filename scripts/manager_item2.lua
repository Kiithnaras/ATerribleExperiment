-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

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
