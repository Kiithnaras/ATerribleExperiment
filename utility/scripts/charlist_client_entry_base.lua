-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function openCharacter()
	if not User.isLocal() then
		if not bRequested then
			User.requestIdentity(window.id, "charsheet", "name", window.localdatabasenode, window.requestResponse);
			bRequested = true;
		end
	else
		Interface.openWindow("charsheet", window.localdatabasenode);
		window.windowlist.window.close();
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	openCharacter();
	return true;
end

