-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

dieslots = {};
isrolled = false;

function setDice(n)
	if n < 0 then
		return;
	end

	if #dieslots > n then
		-- Need to close some entries
		for i = n+1, #dieslots do
			dieslots[tonumber(i)].destroy();
			dieslots[tonumber(i)] = nil;
		end
		return;
	end
	
	-- Otherwise, need to create some
	for i = #dieslots+1, n do
		dieslots[tonumber(i)] = createControl("statchatdieslot", "dieslot" .. i);
	end
end

function onInit()
	setDice(windowlist.window.dice.getValue());
end

function isRolled()
	return isrolled;
end

function setRolled(state)
	isrolled = state;
	rolled.setState(isrolled);
	
	windowlist.applySort();
end

function reset()
	for k, v in ipairs(dieslots) do
		v.setValue(0);
	end

	setRolled(false);
	updateTotal();
end

function applyRoll(dielist)
	local results = {};

	-- Insert results and sort
	for k, v in ipairs(dielist) do
		table.insert(results, v.result);
	end
	table.sort(results, function(a,b) return a > b end);

	for k, v in ipairs(results) do
		if k <= #dieslots then
			dieslots[k].setValue(v);
		end
	end
	
	setRolled(true);
	
	updateTotal();
end

function updateTotal()
	local slots = #dieslots;
	local dropped = windowlist.window.dropdice.getValue();
	
	local sum = modifier.getValue();
	
	for i = 1, slots - dropped do
		sum = sum + dieslots[i].getValue();
		dieslots[i].setColor("ff000000");
	end
	
	for i = slots - dropped + 1, slots do
		dieslots[i].setColor("7f000000");
	end
	
	total.setValue(sum);
end
