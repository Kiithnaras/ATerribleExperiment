-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

sortbytotals = false;

function setRows(n)
	if n < 0 then
		return;
	end

	local windows = getWindows();
	
	if #windows > n then
		-- Need to close some entries
		for i = n+1, #windows do
			windows[i].close();
		end
		return;
	end
	
	-- Otherwise, need to create some
	for i = 1, n - #windows do
		NodeManager.createWindow(self);
	end
end

function setDice(n)
	for k, w in ipairs(getWindows()) do
		w.setDice(n);
		w.updateTotal();
	end
end

function applyRoll(dielist)
	for k, w in ipairs(getWindows()) do
		if not w.isRolled() then
			w.applyRoll(dielist);
			return;
		end
	end
end

function updateTotals()
	for k, w in ipairs(getWindows()) do
		w.updateTotal();
	end
end

function updateModifiers()
	for k, w in ipairs(getWindows()) do
		w.modifier.setValue(window.modifier.getValue());
	end
end

function sortTotals()
	sortbytotals = true;
	applySort(true);
	sortbytotals = false;
end

function onSortCompare(w1, w2)
	if not w1.isRolled() then
		return true;
	end
	if not w2.isRolled() then
		return false;
	end
	
	if sortbytotals then
		return w1.total.getValue() < w2.total.getValue();
	end
end
