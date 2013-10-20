-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nOffsetX = 5;
	local nTopOffsetY = 3;
	local nOffsetY = 7;
	
	if anchor then
		if right then
			setAnchor("top", anchor[1], "top", "absolute", 0);
		else
			setAnchor("top", anchor[1], "bottom", "relative", nOffsetY);
		end
	else
		if window.columnanchor then
			if topfield then
				setAnchor("top", "columnanchor", "bottom", "relative", nTopOffsetY);
			else
				setAnchor("top", "columnanchor", "bottom", "relative", nOffsetY);
			end
		else
			setAnchor("top", "", "top", "absolute", nTopOffsetY);
		end
	end
	
	if right then
		setAnchor("right", "", "right", "absolute", -nOffsetX);
	else
		setAnchor("left", "", "left", "absolute", nOffsetX + 82);
	end
	if left then
		setAnchoredWidth(60);
	elseif right then
		setAnchoredWidth(40);
	else
		setAnchor("right", "", "right", "absolute", -nOffsetX);
	end
	
	local node = getDatabaseNode();
	if not node or node.isReadOnly() then
		setFrame(nil);
		if getValue() == "" then
			setVisible(false);
		end
	end
end

function onValueChanged()
	if isVisible() then
		if window.VisDataCleared then
			if getValue() == "" then
				window.VisDataCleared();
			end
		end
	else
		if window.InvisDataAdded then
			if getValue() ~= "" then
				window.InvisDataAdded();
			end
		end
	end
end
