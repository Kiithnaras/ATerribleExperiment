-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if (User.isHost()) then
		toggle_toolbars.setVisible(true);
	else
		toggle_toolbars.setVisible(false);
	end
	
	updateDisplay();
end

function updateDisplay()
	local bShowToolbar = false
	if (toolbars.getValue() > 0) then
		bShowToolbar = true;
	end

	if (User.isHost()) then
		h1.setVisible(bShowToolbar);
		if (bShowToolbar) then
			toggle_toolbars.setColor("ffffffff");
		else
			toggle_toolbars.setColor("60a0a0a0");
		end

		toolbar_draw.setVisibility(bShowToolbar);
		h2.setVisible(bShowToolbar);
		
		local bShowGridToggle = false;
		if (image.hasGrid()) then
			bShowGridToggle = bShowToolbar;
		end
		toggle_grid.setVisible(bShowGridToggle);
		
		local bGridToggle = false;
		if (toggle_grid.getValue() > 0) then
			bGridToggle = true;
		end
		if (bGridToggle) then
			toggle_grid.setColor("ffffffff");
		else
			toggle_grid.setColor("60a0a0a0");
		end
		
		local bShowGridToolbar = false;
		if (bGridToggle) then
			bShowGridToolbar = bShowGridToggle;
		end
		toolbar_grid.setVisibility(bShowGridToolbar);

		h3.setVisible(bShowGridToggle);
	end

	toolbar_targeting.setVisibility(bShowToolbar);
end
