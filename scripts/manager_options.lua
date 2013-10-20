-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sets = {};
local setsort = {};
local options = {};
local callbacks = {};

function isMouseWheelEditEnabled()
	return isOption("MWHL", "on") or Input.isControlPressed();
end

function onInit()
	setGroupSort("Client", "1");
	setGroupSort("System (GM)", "2");
	setGroupSort("Game (GM)", "3");
	setGroupSort("Combat (GM)", "4");
	setGroupSort("Token (GM)", "5");
	setGroupSort("House Rules (GM)", "6");
	
	registerOption("DCLK", true, "Client", "Mouse: Double click action", "option_entry_cycler", 
			{ labels = "Roll|Mod", values = "on|mod", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("DRGR", true, "Client", "Mouse: Drag rolling", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("MWHL", true, "Client", "Mouse: Wheel editing", "option_entry_cycler", 
			{ labels = "Always", values = "on", baselabel = "Ctrl", baseval = "ctrl", default = "ctrl" });
	registerOption("RMMT", true, "Client", "Target: Remove on miss", "option_entry_cycler", 
			{ labels = "On|Multi", values = "on|multi", baselabel = "Off", baseval = "off", default = "multi" });

	registerOption("SYSTEM", false, "System (GM)", "Game System", "option_entry_cycler", 
			{ labels = "PFRPG", values = "pf", baselabel = "3.5E", baseval = "off", default = "off" });
	
	registerOption("CTAV", false, "Game (GM)", "Chat: Set GM voice to active CT", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("SHPW", false, "Game (GM)", "Chat: Show all whispers to GM", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("REVL", false, "Game (GM)", "Chat: Show GM rolls", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("SHRR", false, "Game (GM)", "Chat: Show results to client", "option_entry_cycler", 
			{ labels = "On|PC", values = "on|pc", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("PCHT", false, "Game (GM)", "Chat: Show portraits", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("SHRL", false, "Game (GM)", "Chat: Show roll actor", "option_entry_cycler", 
			{ labels = "All|PC", values = "all|pc", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("TOTL", false, "Game (GM)", "Chat: Show roll totals", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("MIID", false, "Game (GM)", "Item: Identification", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("TBOX", false, "Game (GM)", "Table: Dice tower", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("PSMN", false, "Game (GM)", "Party: Show main tab to clients", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("PSSK", false, "Game (GM)", "Party: Show skills tab to clients", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("PSIN", false, "Game (GM)", "Party: Show items to clients", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "on" });

	registerOption("INIT", false, "Combat (GM)", "Add: Auto NPC initiative", "option_entry_cycler", 
			{ labels = "On|Group", values = "on|group", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("NNPC", false, "Combat (GM)", "Add: Auto NPC numbering", "option_entry_cycler", 
			{ labels = "Append|Random", values = "append|random", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("ANPC", false, "Combat (GM)", "Chat: Anonymize NPC attacks", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("RING", false, "Combat (GM)", "Turn: Ring bell on PC turn", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("RSHE", false, "Combat (GM)", "Turn: Show effects", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("RNDS", false, "Combat (GM)", "Turn: Stop at round start", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("SHPH", false, "Combat (GM)", "View: Show health to clients", "option_entry_cycler", 
			{ labels = "All|Friendly", values = "all|pc", baselabel = "Off", baseval = "off", default = "pc" });
	registerOption("WNDC", false, "Combat (GM)", "View: Wound Categories", "option_entry_cycler", 
			{ labels = "Detailed", values = "detailed", baselabel = "Simple", baseval = "off", default = "off" });

	registerOption("TNPCE", false, "Token (GM)", "Token: Show Enemy effects", "option_entry_cycler", 
			{ labels = "Tooltip|Icons|Icons Hover|Mark|Mark Hover", values = "tooltip|on|hover|mark|markhover", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("TNPCH", false, "Token (GM)", "Token: Show Enemy health", "option_entry_cycler", 
			{ labels = "Tooltip|Bar|Bar Hover|Dot|Dot Hover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "Off", baseval = "off", default = "dot" });
	registerOption("TPCE", false, "Token (GM)", "Token: Show Friend effects", "option_entry_cycler", 
			{ labels = "Tooltip|Icons|Icons Hover|Mark|Mark Hover", values = "tooltip|on|hover|mark|markhover", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("TPCH", false, "Token (GM)", "Token: Show Friend health", "option_entry_cycler", 
			{ labels = "Tooltip|Bar|Bar Hover|Dot|Dot Hover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "Off", baseval = "off", default = "dot" });
	registerOption("TNAM", false, "Token (GM)", "Token: Show name", "option_entry_cycler", 
			{ labels = "Tooltip|Title|Title Hover", values = "tooltip|on|hover", baselabel = "Off", baseval = "off", default = "tooltip" });

	registerOption("HRCC", false, "House Rules (GM)", "Attack: Critical confirm", "option_entry_cycler", 
			{ labels = "On|NPC", values = "on|npc", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("HRNH", false, "House Rules (GM)", "CT: NPC hit points", "option_entry_cycler", 
			{ labels = "Max|Random", values = "max|random", baselabel = "Standard", baseval = "off", default = "off" });
	registerOption("HRST", false, "House Rules (GM)", "CT: Auto stabilization rolls", "option_entry_cycler", 
			{ labels = "All|Friendly", values = "all|on", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("HRFC", false, "House Rules (GM)", "ATK: Fumble/Crit Tables", "option_entry_cycler", 
			{ labels = "Fumble and Crit|Fumble|Crit", values = "both|fumble|criticalhit", baselabel = "Off", baseval = "", default = "" });
end

function populate(win)
	for keySet, rSet in pairs(sets) do
		local winSet = win.grouplist.createWindow();
		if winSet then
			winSet.label.setValue(keySet);
			winSet.setSort(setsort[keySet]);
			
			for keyOption, rOption in pairs(rSet) do
				local winOption = winSet.options_list.createWindowWithClass(rOption.sType);
				if winOption then
					winOption.setLabel(rOption.sLabel);
					winOption.initialize(rOption.sKey, rOption.aCustom);
					winOption.setLock(not (rOption.bLocal or User.isHost()));
				end
			end
			
			winSet.options_list.applySort();
		end
	end
	
	win.grouplist.applySort();
end

function setGroupSort(sGroup, sSort)
	setsort[sGroup] = sSort;
end

function registerOption(sKey, bLocal, sGroup, sLabel, sOptionType, aCustom)
	local rOption = {};
	rOption.sKey = sKey;
	rOption.bLocal = bLocal;
	rOption.sLabel = sLabel;
	rOption.aCustom = aCustom;
	rOption.sType = sOptionType;
	
	if not sets[sGroup] then
		sets[sGroup] = {};
	end
	table.insert(sets[sGroup], rOption);
	
	options[sKey] = rOption;
	options[sKey].value = (options[sKey].aCustom[default]) or "";
	
	linkNode(sKey);
end

function linkNode(sKey)
	if options[sKey] and not options[sKey].bLinked and not options[sKey].bLocal then
		local nodeOptions = DB.createNode("options");
		if nodeOptions then
			local nodeOption = nodeOptions.createChild(sKey, "string");
			if nodeOption then
				nodeOption.onUpdate = onOptionChanged;
				options[sKey].bLinked = true;
			end
		end
	end
end

function onOptionChanged(nodeOption)
	local sKey = nodeOption.getName();
	makeCallback(sKey);
end

function registerCallback(sKey, fCallback)
	if not callbacks[sKey] then
		callbacks[sKey] = {};
	end
	
	table.insert(callbacks[sKey], fCallback);

	linkNode(sKey);
end

function unregisterCallback(sKey, fCallback)
	if callbacks[sKey] then
		for k, v in pairs(callbacks[sKey]) do
			if v == fCallback then
				callbacks[sKey][k] = nil;
			end
		end
	end
end

function makeCallback(sKey)
	if callbacks[sKey] then
		for k, v in pairs(callbacks[sKey]) do
			v(sKey);
		end
	end
end

function setOption(sKey, sValue)
	if options[sKey] then
		if options[sKey].bLocal then
			CampaignRegistry["Opt" .. sKey] = sValue;
			makeCallback(sKey);
		else
			if User.isHost() or User.isLocal() then
				local nodeOptions = DB.createNode("options");
				if nodeOptions then
					local nodeOption = nodeOptions.createChild(sKey, "string");
					if nodeOption then
						nodeOption.setValue(sValue);
					end
				end
			end
		end
	end
end

function isOption(sKey, sTargetValue)
	return (getOption(sKey) == sTargetValue);
end

function getOption(sKey)
	if options[sKey] then
		if options[sKey].bLocal then
			if CampaignRegistry["Opt" .. sKey] then
				return CampaignRegistry["Opt" .. sKey];
			end
		else
			local nodeOptions = DB.findNode("options");
			if nodeOptions then
				local nodeOption = nodeOptions.getChild(sKey);
				if nodeOption then
					local sValue = nodeOption.getValue();
					if sValue ~= "" then
						return sValue;
					end
				end
			end
		end

		return (options[sKey].aCustom.default) or "";
	end

	return "";
end
