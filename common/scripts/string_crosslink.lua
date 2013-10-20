-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bLocked = false;
linknode = nil;

function onInit()
	if not User.isHost() then
		setReadOnly(true);
	end

	if self.update then
		self.update();
	end
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.getType() ~= "number" then
			return false;
		end

		if self.handleDrop then
			self.handleDrop(draginfo);
			return true;
		end
	end
end

function onValueChanged()
	if self.update then
		self.update();
	end

	if linknode and not isReadOnly() then
		if not bLocked then
			bLocked = true;
			linknode.setValue(getValue());
			bLocked = false;
		end
	end
end

function onLinkUpdated(source)
	if source then
		if not bLocked then
			bLocked = true;
			setValue(source.getValue());
			bLocked = false;
		end
	end

	if self.update then
		self.update();
	end
end

function setLink(dbnode, bLock)
	if dbnode then
		linknode = dbnode;
		linknode.onUpdate = onLinkUpdated;

		if not nolinkwidget then
			addBitmapWidget("indicator_linked").setPosition("bottomright", -5, -7);
		end
		
		if bLock == true then
			setReadOnly(true);
			setFrame(nil);
		end

		onLinkUpdated(linknode);
	end
end
