-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getVisibleName(nodeItem, bCharSheet)
	if not User.isHost() or bCharSheet then
		if DB.getValue(nodeItem, "isidentified", 0) == 0 then
			local sName = DB.getValue(nodeItem, "nonid_name", "");
			if sName == "" then
				sName = "Unidentified Item";
			end
			return sName;
		end
	end
	return DB.getValue(nodeItem, "name", "");
end
