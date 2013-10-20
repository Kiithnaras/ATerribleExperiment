-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if not User.isLocal() then
		if User.isHost() then
			DesktopManager.registerStackShortcut("button_characters", "button_characters_down", "Characters", "charlist_host", "charsheet");
			DesktopManager.registerStackShortcut("button_partysheet", "button_partysheet_down", "Party Sheet", "partysheet", "partysheet");

			DesktopManager.registerStackShortcut("button_ct", "button_ct_down", "Combat Tracker", "combattracker_window", "combattracker");
			DesktopManager.registerStackShortcut("button_options", "button_options_down", "Options", "options");

			DesktopManager.registerStackShortcut("button_tables", "button_tables_down", "Tables", "tablelist", "tables");
			DesktopManager.registerStackShortcut("button_calendar", "button_calendar_down", "Calendar", "calendar", "calendar");

			DesktopManager.registerStackShortcut("button_light", "button_light_down", "Lighting", "lightingselection");
			DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");

			DesktopManager.registerStackShortcut("button_modifiers", "button_modifiers_down", "Modifiers", "modifiers", "modifiers");
			DesktopManager.registerStackShortcut("button_effects", "button_effects_down", "Effects", "effectlist", "effects");
			
			DesktopManager.registerDockShortcut("button_book", "button_book_down", "Story", "encounterlist", "encounter");
			DesktopManager.registerDockShortcut("button_maps", "button_maps_down", "Maps &\rImages", "imagelist", "image");
			DesktopManager.registerDockShortcut("button_people", "button_people_down", "Personalities", "npclist", "npc");
			DesktopManager.registerDockShortcut("button_itemchest", "button_itemchest_down", "Items", "itemlist", "item");
			DesktopManager.registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes");
			DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
			
			DesktopManager.registerDockShortcut("button_tokencase", "button_tokencase_down", "Tokens", "tokenbag", nil, true);
		else
			DesktopManager.registerStackShortcut("button_characters", "button_characters_down", "Characters", "identityselection");
			DesktopManager.registerStackShortcut("button_partysheet", "button_partysheet_down", "Party Sheet", "clientpartysheet", "partysheet");

			DesktopManager.registerStackShortcut("button_ct", "button_ct_down", "Combat tracker", "clienttracker_window", "combattracker");
			DesktopManager.registerStackShortcut("button_options", "button_options_down", "Options", "options");

			DesktopManager.registerStackShortcut("button_tables", "button_tables_down", "Tables", "tablelist", "tables");
			DesktopManager.registerStackShortcut("button_calendar", "button_calendar_down", "Calendar", "calendar", "calendar");

			DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");

			DesktopManager.registerStackShortcut("button_modifiers", "button_modifiers_down", "Modifiers", "modifiers", "modifiers");
			DesktopManager.registerStackShortcut("button_effects", "button_effects_down", "Effects", "effectlist", "effects");

			DesktopManager.registerDockShortcut("button_book", "button_book_down", "Story", "encounterlist", "encounter");
			DesktopManager.registerDockShortcut("button_maps", "button_maps_down", "Maps &\rImages", "imagelist", "image");
			DesktopManager.registerDockShortcut("button_itemchest", "button_itemchest_down", "Items", "itemlist", "item");
			DesktopManager.registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes");
			DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
			
			DesktopManager.registerDockShortcut("button_tokencase", "button_tokencase_down", "Tokens", "tokenbag", nil, true);
		end
	else
		DesktopManager.registerStackShortcut("button_characters", "button_characters_down", "Characters", "identityselection");
		DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");

		DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
	end
	
	Interface.onDesktopInit = onDesktopInit;
end

function onDesktopInit()
	if User.isLocal() then
		Interface.openWindow("systemselection", "", true);
	else
		if User.isHost() then
			if not CampaignRegistry.systemselection then
				CampaignRegistry.systemselection = "true";
				Interface.openWindow("systemselection", "", true);
			end
		else
			Interface.openWindow("identityselection", "", true);
		end
	end
end
