-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	deliverLaunchMessage()
end

function deliverLaunchMessage()
    local msg = {sender = "", font = "emotefont", icon="portrait_ruleset_token"};
    msg.text = "3.5E v2.9.3 ruleset for Fantasy Grounds II.\rCopyright 2012 Smiteworks USA, LLC."
    Comm.addChatMessage(msg);
    
    local launchmsg = ChatManager.retrieveLaunchMessages();
    for keyMessage, rMessage in ipairs(launchmsg) do
    	Comm.addChatMessage(rMessage);
    end
end

function onDiceLanded(draginfo)
 	return ActionsManager.onDiceLanded(draginfo);
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	if StringManager.contains(DataCommon.actions, sDragType) then
		ActionsManager.handleActionDrop(draginfo, nil);
	end
end
