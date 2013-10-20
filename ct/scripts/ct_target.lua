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
		local nodeToken = nodeTarget.getChild("token");
		if nodeToken then
			nodeToken.onUpdate = onTokenUpdated;
			onTokenUpdated(nodeToken);
		end
		local nodeName = nodeTarget.getChild("name");
		if nodeName then
			nodeName.onUpdate = onNameUpdated;
			onNameUpdated(nodeName);
		end
	end
end

function onTokenUpdated(nodeToken)
	token.setPrototype(nodeToken.getValue());
end

function onNameUpdated(nodeName)
	token.setTooltipText(nodeName.getValue());
	windowlist.window.onTargetsChanged();
end

function removeTarget()
	if type.getValue() == "client" then
		TargetingManager.removeClientTarget("", windowlist.window.name.getValue(), noderef.getValue());
	else
		local node = getDatabaseNode();
		if node then
			node.delete();
		else
			close();
		end
	end
end
