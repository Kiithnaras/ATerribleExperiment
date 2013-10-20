-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;

function onInit()
	local nodeLog = DB.createNode("calendar.log");
	nodeLog.onChildUpdate = onEventsChanged;
	buildEvents();
	
	nSelMonth = currentmonth.getValue();
	nSelDay = currentday.getValue();

	onDateChanged();
end								

function buildEvents()
	aEvents = {};
	
	for _,v in pairs(DB.getChildren("calendar.log")) do
		local nYear = DB.getValue(v, "year", 0);
		local nMonth = DB.getValue(v, "month", 0);
		local nDay = DB.getValue(v, "day", 0);
		
		if not aEvents[nYear] then
			aEvents[nYear] = {};
		end
		if not aEvents[nYear][nMonth] then
			aEvents[nYear][nMonth] = {};
		end
		aEvents[nYear][nMonth][nDay] = v;
	end
end

function onEventsChanged(bListChanged)
	if bListChanged then
		buildEvents();
		updateDisplay();
	end
end

function setSelectedDate(nMonth, nDay)
	nSelMonth = nMonth;
	nSelDay = nDay;

	updateDisplay();
	list_calenderperiod.scrollToCampaignDate();
end

function addLogEntryToSelected()
	addLogEntry(nSelMonth, nSelDay);
end

function addLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();
	
	local nodeEvent;
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeEvent = aEvents[nYear][nMonth][nDay];
	elseif User.isHost() then
		local nodeLog = DB.createNode("calendar.log");
		nodeEvent = nodeLog.createChild();
		
		DB.setValue(nodeEvent, "epoch", "string", DB.getValue("calendar.current.epoch", ""));
		DB.setValue(nodeEvent, "year", "number", nYear);
		DB.setValue(nodeEvent, "month", "number", nMonth);
		DB.setValue(nodeEvent, "day", "number", nDay);

		onEventsChanged();
	end

	if nodeEvent then
		Interface.openWindow("advlogentry", nodeEvent);
	end
end

function removeLogEntry(nMonth, nDay)
	if not User.isHost() then
		return;
	end
	
	local nYear = CalendarManager.getCurrentYear();
	
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		(aEvents[nYear][nMonth][nDay]).delete();
	end
end

function onSetButtonPressed()
	if User.isHost() then
		CalendarManager.setCurrentDay(nSelDay);
		CalendarManager.setCurrentMonth(nSelMonth);
	end
end

function onDateChanged()
	updateDisplay();
	list_calenderperiod.scrollToCampaignDate();
end

function onYearChanged()
	list_calenderperiod.rebuildCalendarWindows();
	onDateChanged();
end

function onCalendarChanged()
	list_calenderperiod.rebuildCalendarWindows();
	setSelectedDate(currentmonth.getValue(), currentday.getValue());
end

function updateDisplay()
	local sCampaignEpoch = currentepoch.getValue();
	local nCampaignYear = currentyear.getValue();
	local nCampaignMonth = currentmonth.getValue();
	local nCampaignDay = currentday.getValue();
	
	local sDate = CalendarManager.getShortDateString(sCampaignEpoch, nCampaignYear, nCampaignMonth, nCampaignDay);
	viewdate.setValue(sDate);

	if aEvents[nCampaignYear] and 
			aEvents[nCampaignYear][nSelMonth] and 
			aEvents[nCampaignYear][nSelMonth][nSelDay] then
		button_view.setVisible(true);
		button_view.setText("View Log Entry");
	else
		button_view.setVisible(User.isHost());
		button_view.setText("Add Log Entry");
	end
	
	for _,v in pairs(list_calenderperiod.getWindows()) do
		local nMonth = v.month.getValue();

		local bCampaignMonth = false;
		local bLogMonth = false;
		if nMonth == nCampaignMonth then
			bCampaignMonth = true;
		end
		if nMonth == nSelMonth then
			bLogMonth = true;
		end
			
		if bCampaignMonth then
			v.label_period.setColor("5A1E33");
		else
			v.label_period.setColor("000000");
		end
		
		for _,y in pairs(v.list_days.getWindows()) do
			local nDay = y.day.getValue();
			if nDay > 0 then
				local bHoliday = CalendarManager.isHoliday(nMonth, nDay);
				local bCurrDay = (bCampaignMonth and nDay == nCampaignDay);
				local bSelDay = (bLogMonth and nDay == nSelDay);
				local bEvent = (aEvents[nCampaignYear] and aEvents[nCampaignYear][nMonth] and aEvents[nCampaignYear][nMonth][nDay]);
				
				y.setState(bCurrDay, bSelDay, bHoliday, bEvent);
			end
		end
	end
end
