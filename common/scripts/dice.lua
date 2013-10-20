-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

widgetShadow = nil;

function onInit()
	widgetShadow = addBitmapWidget("diceshadow");
	if widgetShadow then
		local x,y,w,h = 0,0,0,0;

		if shadow then
			if shadow[1].offset then
				local sX, sY = string.match(shadow[1].offset[1], "(%d+),(%d+)");
				x = tonumber(sX) or 0;
				y = tonumber(sY) or 0;
			end
			if shadow[1].size then
				local sW, sH = string.match(shadow[1].size[1], "(%d+),(%d+)");
				w = tonumber(sW) or 0;
				h = tonumber(sH) or 0;
			else
				if anchored and anchored[1].size then
					if anchored[1].size[1].width then
						w = tonumber(anchored[1].size[1].width[1]) or 0;
					end
					if anchored[1].size[1].height then
						h = tonumber(anchored[1].size[1].height[1]) or 0;
					end
				end
			end
			if w > 2 then
				w = w - 2;
			end
			if h > 2 then
				h = h - 2;
			end
		end

		widgetShadow.setPosition("center", x, y);
		widgetShadow.setSize(w, h);

		checkShadow();
	end
end

function onValueChanged(source)
	checkShadow();
end

function setVisibility(bVisible)
	setVisible(bVisible);
	checkShadow();
end

function checkShadow()
	if widgetShadow then
		local bVisible = false;
		local node = getDatabaseNode();
		if node then
			bVisible = isVisible() and not node.getValue();
		end
		widgetShadow.setVisible(bVisible);
	end
end
