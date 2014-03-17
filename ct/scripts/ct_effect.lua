-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("ct_tooltip_effectdelete"), "deletepointer", 3);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 3, 3);

	DB.addHandler(getDatabaseNode().getNodeName() .. ".targets", "onChildUpdate", onTargetsChanged);
	onTargetsChanged();
end

function onClose()
	DB.removeHandler(getDatabaseNode().getNodeName() .. ".targets", "onChildUpdate", onTargetsChanged);
end

function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 3 then
		windowlist.deleteChild(self, true);
	end
end

function onTargetsChanged()
	if target_name then
		local aTargets = {};
		for _,w in pairs(targets.getWindows()) do
			local sTarget = DB.getValue(w.noderef.getValue() .. ".name", "");
			table.insert(aTargets, sTarget);
		end
		if #aTargets > 0 then
			target_name.setValue(Interface.getString("ct_label_effecttargets") .. " " .. table.concat(aTargets, ", "));
			target_name.setVisible(true);
		else
			target_name.setValue("");
			target_name.setVisible(false);
		end
	end
end

function onDragStart(button, x, y, draginfo)
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	return ActionEffect.performRoll(draginfo, nil, rEffect);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackerentry") then
		local nodeCTSource = draginfo.getCustomData();
		if nodeCTSource then
			local nodeWin = windowlist.window.getDatabaseNode();
			if nodeWin then
				if nodeCTSource.getNodeName() == nodeWin.getNodeName() then
					source.setSource("");
				else
					source.setSource(nodeCTSource.getNodeName());
					init.setValue(DB.getValue(nodeCTSource, "initresult", 0));
				end
			end
		end
		return true;
	end
end
