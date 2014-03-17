-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    local msg = {font = "emotefont", icon="portrait_ruleset_token"};
    msg.text = DataCommon.launchmsg;
 	ChatManager.registerLaunchMessage(msg);

	Interface.onDesktopInit = onDesktopInit;

	registerPublicNodes();
	
	registerOptions();
	
	buildDesktop();
end

function onDesktopInit()
	if not User.isLocal() and not User.isHost() then
		Interface.openWindow("charselect_client", "", true);
	end
end

function registerPublicNodes()
	if User.isHost() then
		DB.createNode("options").setPublic(true);
		DB.createNode("partysheet").setPublic(true);
		DB.createNode("calendar").setPublic(true);
		DB.createNode("combattracker").setPublic(true);
		DB.createNode("modifiers").setPublic(true);
		DB.createNode("effects").setPublic(true);
	end
end

function buildDesktop()
	-- Local mode
	if User.isLocal() then
		DesktopManager.registerStackShortcut2("button_color", "button_color_down", "sidebar_tooltip_colors", "pointerselection");

		DesktopManager.registerDockShortcut2("button_characters", "button_characters_down", "sidebar_tooltip_character", "charselect_client");
		DesktopManager.registerDockShortcut2("button_library", "button_library_down", "sidebar_tooltip_library", "library");
		
	-- GM mode
	elseif User.isHost() then
		DesktopManager.registerStackShortcut2("button_ct", "button_ct_down", "sidebar_tooltip_ct", "combattracker_host", "combattracker");
		DesktopManager.registerStackShortcut2("button_partysheet", "button_partysheet_down", "sidebar_tooltip_ps", "partysheet_host", "partysheet");

		DesktopManager.registerStackShortcut2("button_tables", "button_tables_down", "sidebar_tooltip_tables", "tablelist", "tables");
		DesktopManager.registerStackShortcut2("button_calendar", "button_calendar_down", "sidebar_tooltip_calendar", "calendar", "calendar");

		DesktopManager.registerStackShortcut2("button_light", "button_light_down", "sidebar_tooltip_lighting", "lightingselection");
		DesktopManager.registerStackShortcut2("button_color", "button_color_down", "sidebar_tooltip_colors", "pointerselection");

		DesktopManager.registerStackShortcut2("button_modifiers", "button_modifiers_down", "sidebar_tooltip_modifiers", "modifiers", "modifiers");
		DesktopManager.registerStackShortcut2("button_effects", "button_effects_down", "sidebar_tooltip_effects", "effectlist", "effects");
		
		DesktopManager.registerStackShortcut2("button_options", "button_options_down", "sidebar_tooltip_options", "options");

		DesktopManager.registerDockShortcut2("button_characters", "button_characters_down", "sidebar_tooltip_character", "charselect_host", "charsheet");
		DesktopManager.registerDockShortcut2("button_book", "button_book_down", "sidebar_tooltip_story", "encounterlist", "encounter");
		DesktopManager.registerDockShortcut2("button_maps", "button_maps_down", "sidebar_tooltip_image", "imagelist", "image");
		DesktopManager.registerDockShortcut2("button_people", "button_people_down", "sidebar_tooltip_npc", "npclist", "npc");
		DesktopManager.registerDockShortcut2("button_items", "button_items_down", "sidebar_tooltip_item", "itemlist", "item");
		DesktopManager.registerDockShortcut2("button_notes", "button_notes_down", "sidebar_tooltip_note", "notelist", "notes");
		DesktopManager.registerDockShortcut2("button_library", "button_library_down", "sidebar_tooltip_library", "library");
		
		DesktopManager.registerDockShortcut2("button_tokencase", "button_tokencase_down", "sidebar_tooltip_token", "tokenbag", nil, true);
		
	-- Player mode
	else
		DesktopManager.registerStackShortcut2("button_ct", "button_ct_down", "sidebar_tooltip_ct", "combattracker_client", "combattracker");
		DesktopManager.registerStackShortcut2("button_partysheet", "button_partysheet_down", "sidebar_tooltip_ps", "partysheet_client", "partysheet");

		DesktopManager.registerStackShortcut2("button_tables", "button_tables_down", "sidebar_tooltip_tables", "tablelist", "tables");
		DesktopManager.registerStackShortcut2("button_calendar", "button_calendar_down", "sidebar_tooltip_calendar", "calendar", "calendar");

		DesktopManager.registerStackShortcut2("button_color", "button_color_down", "sidebar_tooltip_colors", "pointerselection");
		DesktopManager.registerStackShortcut2("button_options", "button_options_down", "sidebar_tooltip_options", "options");

		DesktopManager.registerStackShortcut2("button_modifiers", "button_modifiers_down", "sidebar_tooltip_modifiers", "modifiers", "modifiers");
		DesktopManager.registerStackShortcut2("button_effects", "button_effects_down", "sidebar_tooltip_effects", "effectlist", "effects");

		DesktopManager.registerDockShortcut2("button_characters", "button_characters_down", "sidebar_tooltip_character", "charselect_client");
		DesktopManager.registerDockShortcut2("button_book", "button_book_down", "sidebar_tooltip_story", "encounterlist", "encounter");
		DesktopManager.registerDockShortcut2("button_maps", "button_maps_down", "sidebar_tooltip_image", "imagelist", "image");
		DesktopManager.registerDockShortcut2("button_people", "button_people_down", "sidebar_tooltip_npc", "npclist", "npc");
		DesktopManager.registerDockShortcut2("button_items", "button_items_down", "sidebar_tooltip_item", "itemlist", "item");
		DesktopManager.registerDockShortcut2("button_notes", "button_notes_down", "sidebar_tooltip_note", "notelist", "notes");
		DesktopManager.registerDockShortcut2("button_library", "button_library_down", "sidebar_tooltip_library", "library");
		
		DesktopManager.registerDockShortcut2("button_tokencase", "button_tokencase_down", "sidebar_tooltip_token", "tokenbag", nil, true);
	end
end

function registerOptions()
	OptionsManager.registerOption2("RMMT", true, "option_header_client", "option_label_RMMT", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_multi", values = "on|multi", baselabel = "option_val_off", baseval = "off", default = "multi" });

	OptionsManager.registerOption2("SHRR", false, "option_header_game", "option_label_SHRR", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_pc", values = "on|pc", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("PSMN", false, "option_header_game", "option_label_PSMN", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("INIT", false, "option_header_combat", "option_label_INIT", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_group", values = "on|group", baselabel = "option_val_off", baseval = "off", default = "group" });
	OptionsManager.registerOption2("ANPC", false, "option_header_combat", "option_label_ANPC", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SHPH", false, "option_header_combat", "option_label_SHPH", "option_entry_cycler", 
			{ labels = "option_val_all|option_val_friendly", values = "all|pc", baselabel = "option_val_off", baseval = "off", default = "pc" });
	OptionsManager.registerOption2("WNDC", false, "option_header_combat", "option_label_WNDC", "option_entry_cycler", 
			{ labels = "option_val_detailed", values = "detailed", baselabel = "option_val_simple", baseval = "off", default = "off" });

	OptionsManager.registerOption2("TNPCE", false, "option_header_token", "option_label_TNPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TNPCH", false, "option_header_token", "option_label_TNPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("TPCE", false, "option_header_token", "option_label_TPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TPCH", false, "option_header_token", "option_label_TPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });

	OptionsManager.registerOption2("HRCC", false, "option_header_houserule", "option_label_HRCC", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_npc", values = "on|npc", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("HRNH", false, "option_header_houserule", "option_label_HRNH", "option_entry_cycler", 
			{ labels = "option_val_max|option_val_random", values = "max|random", baselabel = "option_val_standard", baseval = "off", default = "off" });
	OptionsManager.registerOption2("HRST", false, "option_header_houserule", "option_label_HRST", "option_entry_cycler", 
			{ labels = "option_val_all|option_val_friendly", values = "all|on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("HRFC", false, "option_header_houserule", "option_label_HRFC", "option_entry_cycler", 
			{ labels = "option_val_fumbleandcrit|option_val_fumble|option_val_crit", values = "both|fumble|criticalhit", baselabel = "option_val_off", baseval = "", default = "" });
end
