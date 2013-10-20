-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function clearSelection()
	for k, w in ipairs(getWindows()) do
		w.base.setFrame(nil);
	end
end

function addIdentity(id, aLabels, nodeLocal)
	for k, v in ipairs(activeidentities) do
		if v == id then
			return;
		end
	end

	local wnd = NodeManager.createWindow(self);
	if wnd then
		wnd.setId(id);
		wnd.name.setValue(aLabels[1] or "");

		if aLabels[2] then
			wnd.classlevel.setValue("Level " .. aLabels[2]);
		end

		wnd.setLocalNode(nodeLocal);

		if id then
			wnd.portrait.setIcon("portrait_" .. id .. "_charlist", true);
		end
	end
end

function onInit()
	activeidentities = User.getAllActiveIdentities();

	createWindowWithClass("charlist_client_newentry");

	User.getRemoteIdentities("charsheet", "name,#level", addIdentity);
end
