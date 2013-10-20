-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if anchor and window[anchor[1]] then
		setAnchor("top", anchor[1], "top", "absolute", 0);

		if right then
			setAnchor("left", "", "right", "absolute", -110);
		else
			setAnchor("left", "", "left", "absolute", 0);
		end
	end
	
	if anchor and window[anchor[1]] then
		if not window[anchor[1]].isVisible() then
			setVisible(false);
		else
			setVisible(true);
		end
	end
end
