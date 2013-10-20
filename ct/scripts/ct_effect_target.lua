-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onRefChanged();
end

function onRefChanged()
	local nodeTarget = DB.findNode(noderef.getValue());
	if nodeTarget then
		local nodeName = nodeTarget.getChild("name");
		if nodeName then
			nodeName.onUpdate = onNameUpdated;
			onNameUpdated(nodeName);
		end
	end
end

function onNameUpdated(nodeName)
	windowlist.window.onTargetsChanged();
end
