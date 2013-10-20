-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onButtonPress()
	if User.isHost() then
		local node = window.getDatabaseNode().createChild();
		if node then
			local wnd = Interface.openWindow(class[1], node.getNodeName());
			if wnd and wnd.name then
				wnd.name.setFocus();
			end
		end
	else
		local nodeWin = window.getDatabaseNode();
		if nodeWin then
			Interface.requestNewClientWindow(class[1], nodeWin.getNodeName());
		end
	end
end
