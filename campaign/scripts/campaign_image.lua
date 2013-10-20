-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	window.updateDisplay();
	
	for _, vToken in pairs(getTokens()) do
		TokenManager.updateAttributesFromToken(vToken);
	end
end

function onMaskingStateChanged(tool)
	window.toolbar_draw.onValueChanged();
end

function onDrawStateChanged(tool)
	window.toolbar_draw.onValueChanged();
end

function onGridStateChanged(gridtype)
	window.updateDisplay();
end

function onDrop(x, y, draginfo)
	local dragtype = draginfo.getType();
	
	if dragtype == "combattrackerff" then
		-- Grab faction data from drag object
		local sFaction = draginfo.getStringData();

		-- Determine image viewpoint
		-- Handle zoom factor (>100% or <100%) and offset drop coordinates
		local vpx, vpy, vpz = getViewpoint();
		if vpz > 1 then
			x = x / vpz;
			y = y / vpz;
		elseif vpz < 1 then
			x = x + (x * vpz);
			y = y + (y * vpz);
		end
		
		-- If grid, then snap drop point and adjust drop spread
		local nDropSpread = 15;
		if hasGrid() then
			x, y = snapToGrid(x, y);
			nDropSpread = getGridSize();
		end

		-- Get the CT window
		local ctwnd = Interface.findWindow("combattracker_window", "combattracker");
		if ctwnd then
		    -- Loop through the CT entries
			for k,v in pairs(ctwnd.list.getWindows()) do
				-- Make sure we have the right fields to work with
				if v.token and v.friendfoe then
					-- Look for entries with the same faction
					if v.friendfoe.getStringValue() == sFaction then
						-- Get the entries token image
						local tokenproto = v.token.getPrototype();
						if tokenproto then
						    -- Add it to the image at the drop coordinates 
							local addedtoken = addToken(tokenproto, x, y);

							-- Update the CT entry's token references
							v.token.replace(addedtoken);

							-- Offset drop coordinates for next token = nice spread :)
							if x >= (nDropSpread * 1.5) then
								x = x - nDropSpread;
							end
							if y >= (nDropSpread * 1.5) then
								y = y - nDropSpread;
							end
						end
					end
				end
			end
		end
		
		return true;
	end
end
