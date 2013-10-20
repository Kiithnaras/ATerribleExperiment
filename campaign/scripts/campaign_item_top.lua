-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("MIID", StateChanged);
	StateChanged();

	if User.isHost() then
		if getDatabaseNode().getOwner() then
			playeredit.setVisible(true);
		end
	end
	if name.getValue() ~= "" then
		locked.setState(true);
	end
end

function onClose()
	OptionsManager.unregisterCallback("MIID", StateChanged);
end

function getDetailedAccessState()
	local bLocalLock = locked.getState();
	local bDataLock = getDatabaseNode().isReadOnly();

	local bID = true;
	if not User.isHost() then
		if not bDataLock then
			bDataLock = (DB.getValue(getDatabaseNode(), "playeredit", 0) == 0);
		end
		if OptionsManager.isOption("MIID", "on") then
			bID = (DB.getValue(getDatabaseNode(), "isidentified", 0) == 1);
		end
	end
	
	return bLocalLock, bDataLock, bID;
end

function getAccessState()
	local bLocalLock, bDataLock, bID = getDetailedAccessState();
	return (bLocalLock or bDataLock), bID;
end

function StateChanged()
	local bLocalLock, bDataLock, bID = getDetailedAccessState();
	local bLock = (bLocalLock or bDataLock);

	local bHost = User.isHost();
	if bHost or bID then
		nonid_name.setVisible(false);
		name.setVisible(true);
	else
		nonid_name.setVisible(true);
		name.setVisible(false);
	end

	name.setReadOnly(bLock);
	nonid_name.setReadOnly(bLock);
	
	isidentified.setVisible(OptionsManager.isOption("MIID", "on"));
	if bDataLock then
		hardlocked.setVisible(true);
		locked.setVisible(false);
	else
		hardlocked.setVisible(false);
		locked.setVisible(true);
	end

	if stats.subwindow then
		stats.subwindow.update();
	end
end
