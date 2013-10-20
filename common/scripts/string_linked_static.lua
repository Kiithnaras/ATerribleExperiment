-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

hoverontext = false;

function onInit()
	if getdata then
		if linktarget then
			if window[linktarget[1]] then
				local nodeLink = window[linktarget[1]].getTargetDatabaseNode();
				if nodeLink then
					if linkfield then
						setValue(DB.getValue(nodeLink, linkfield[1], ""));
					else
						setValue(DB.getValue(nodeLink, getName(), ""));
					end
				end
			end
		end
	end
end

function onHover(oncontrol)
	if not oncontrol then
		setUnderline(false);
		hoverontext = false;
	end
end

function onHoverUpdate(x, y)
	setUnderline(true);
	hoverontext = true;
end

function onClickDown(button, x, y)
	if hoverontext then
		return true;
	else
		return false;
	end
end

function onClickRelease(button, x, y)
	if hoverontext then
		if self.activate then
			self.activate();
		elseif linktarget then
			window[linktarget[1]].activate();
		end
		return true;
	end
end

function onDragStart(button, x, y, draginfo)
	if linktarget and hoverontext then
		if window[linktarget[1]].onDragStart then
			window[linktarget[1]].onDragStart(button, x, y, draginfo);
			return true;
		end
	else
		return false;
	end
end
