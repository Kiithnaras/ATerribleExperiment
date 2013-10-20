-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bLocked = false;
linknode = nil;

function onInit()
	if super and super.onInit then
		super.onInit();
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
	if not bLocked then
		bLocked = true;

		if self.update then
			self.update();
		end

		if linknode and not isReadOnly() then
			linknode.setValue(getValue());
		end

		bLocked = false;
	end
end

function onLinkUpdated(source)
	if not bLocked then
		bLocked = true;

		if source then
			setValue(source.getValue());
		end

		if self.update then
			self.update();
		end

		bLocked = false;
	end
end

function setLink(dbnode, bLock)
	if dbnode then
		linknode = dbnode;
		linknode.onUpdate = onLinkUpdated;

		if not nolinkwidget then
			if bLock then
				addBitmapWidget("indicator_linked").setPosition("bottomright", 0, -3);
			else
				addBitmapWidget("indicator_linked").setPosition("bottomright", -5, -5);
			end
		end
		
		if bLock == true then
			setReadOnly(true);
		end

		onLinkUpdated(linknode);
	end
end

