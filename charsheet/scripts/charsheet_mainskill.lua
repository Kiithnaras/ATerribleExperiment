-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sSkill = "";
local sSkillNode = nil;

function onInit()
	-- Get any custom fields
	if skill then
		sSkill = skill[1];
	end

	-- If we have a skill name, then find or create a skill node
	if sSkill ~= "" then
		local nodeSkillList = window.getDatabaseNode().createChild("skilllist");
		if nodeSkillList then
			-- First, look for an existing skill node
			local aSkillNodes = nodeSkillList.getChildren();
			for kNode,vNode in pairs(aSkillNodes) do
				local name = DB.getValue(vNode, "label", "");
				if name == sSkill then
					sSkillNode = vNode.getName();
					break;
				end
			end
			
			-- Or else, create a new skill node
			if not sSkillNode then
				local nodeSkill = nodeSkillList.createChild();
				if nodeSkill then
					sSkillNode = nodeSkill.getName();

					DB.setValue(nodeSkill, "label", "string", sSkill);
					DB.setValue(nodeSkill, "ranks", "number", 0);
					DB.setValue(nodeSkill, "misc", "number", 0);
				end
			end
		end
	end

	-- Add the sources for this field to the watch list
	if sSkillNode then
		addSourceWithOp("skilllist." .. sSkillNode .. ".ranks", "+");
		addSourceWithOp("skilllist." .. sSkillNode .. ".misc", "+");
		
		setAbilitySource("skilllist." .. sSkillNode .. ".statname");
	end

	-- Call the default linkednumber init handler to make sure the field adds up correctly
	super.onInit();
end

function onSourceValue(source, sourcename)
	if sourcename == "skilllist." .. sSkillNode .. ".ranks" then
		return math.floor(source.getValue());
	end

	return super.onSourceValue(source, sourcename);
end

function action(draginfo)
	local rActor = ActorManager.getActor("pc", window.getDatabaseNode());
	local sStat = getAbility(1);

	ActionSkill.performRoll(draginfo, rActor, sSkill, getValue(), sStat);
	
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end
					
function onDoubleClick(x,y)
	return action();
end
				
