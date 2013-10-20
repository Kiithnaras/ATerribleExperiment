-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super.onInit then
		super.onInit();
	end
	
	local nOffsetX = 5;
	local nOffsetY = 7;
	
	if anchor then
		if right then
			setAnchor("top", anchor[1], "top", "absolute", 0);
		else
			setAnchor("top", anchor[1], "bottom", "relative", nOffsetY);
		end
	else
		if window.columnanchor then
			setAnchor("top", "columnanchor", "bottom", "relative", nOffsetY);
		else
			setAnchor("top", "", "top", "absolute", nOffsetY);
		end
	end
	
	if right then
		setAnchor("right", "", "right", "absolute", -nOffsetX);
	else
		setAnchor("left", "", "left", "absolute", 80 + nOffsetX);
	end
	
	setAnchoredWidth(40);
	setAnchoredHeight(15);
end
