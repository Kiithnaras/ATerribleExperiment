-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function createWindow(winList)
	if not winList then
		return nil;
	end
	
	local nodeWindowList = winList.getDatabaseNode();
	if nodeWindowList then
		if nodeWindowList.isReadOnly() then
			return nil;
		end
	end
	
	return winList.createWindow();
end
