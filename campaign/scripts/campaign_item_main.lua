-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bLock, bID, vHideOnValue)
	local bLocalShow = bID;
	
	if self[sControl] then
		if bLock then
			self[sControl].setReadOnly(true);
			
			local vControl = self[sControl].getValue();
			if vControl == "" or vControl == vHideOnValue then
				bLocalShow = false;
			end
		else
			self[sControl].setReadOnly(false);
		end
		self[sControl].setVisible(bLocalShow);
	else
		bLocalShow = false;
	end

	if self[sControl .. "_label"] then
		self[sControl .. "_label"].setVisible(bLocalShow);
	end
	
	return bLocalShow;
end

function update()
	local bOptionID = OptionsManager.isOption("MIID", "on");
	local bLock, bID = parentcontrol.window.getAccessState();

	local sType = type.getValue();
	local bWeapon = (sType == "Weapon");
	local bArmor = (sType == "Armor");

	local bSection1 = false;
	if updateControl("type", bLock, bID) then bSection1 = true; end
	if updateControl("subtype", bLock, bID) then bSection1 = true; end
	
	local bSection2 = false;
	if User.isHost() then
		if updateControl("nonid_name", bLock, bOptionID) then bSection2 = true; end
	else
		updateControl("nonid_name", true, false);
	end
	if updateControl("nonidentified", bLock, bOptionID) then bSection2 = true; end

	local bSection3 = false;
	if updateControl("cost", bLock, bID) then bSection3 = true; end
	if updateControl("weight", bLock, bID, 0) then bSection3 = true; end
	
	local bSection4 = false;
	if updateControl("damage", bLock, bID and bWeapon) then bSection4 = true; end
	if updateControl("damagetype", bLock, bID and bWeapon) then bSection4 = true; end
	if updateControl("critical", bLock, bID and bWeapon) then bSection4 = true; end
	if updateControl("range", bLock, bID and bWeapon, 0) then bSection4 = true; end
	
	if updateControl("ac", bLock, bID and bArmor, 0) then bSection4 = true; end
	if updateControl("maxstatbonus", bLock, bID and bArmor, 0) then bSection4 = true; end
	if updateControl("checkpenalty", bLock, bID and bArmor, 0) then bSection4 = true; end
	if updateControl("spellfailure", bLock, bID and bArmor, 0) then bSection4 = true; end
	if updateControl("speed30", bLock, bID and bArmor, 0) then bSection4 = true; end
	if updateControl("speed20", bLock, bID and bArmor, 0) then bSection4 = true; end

	if updateControl("properties", bLock, bID and (bWeapon or bArmor)) then bSection4 = true; end
	
	local bSection5 = false;
	if updateControl("bonus", bLock, bID and (bWeapon or bArmor), 0) then bSection5 = true; end
	if updateControl("aura", bLock, bID) then bSection5 = true; end
	if updateControl("cl", bLock, bID, 0) then bSection5 = true; end
	if updateControl("prerequisites", bLock, bID) then bSection5 = true; end
	
	local bSection6 = bID;
	description.setReadOnly(bLock);
	description.setVisible(bID);
	
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
	divider4.setVisible((bSection1 or bSection2 or bSection3 or bSection4) and bSection5);
	divider5.setVisible((bSection1 or bSection2 or bSection3 or bSection4 or bSection5) and bSection6);
end
