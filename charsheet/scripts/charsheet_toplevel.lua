-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem("Rest", "lockvisibilityon", 8);
		registerMenuItem("Short Rest", "pointer_cone", 8, 8);
		registerMenuItem("Overnight Rest", "pointer_circle", 8, 6);
	end

	if User.isLocal() then
		portrait.setVisible(false);
		localportrait.setVisible(true);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 8 then
		local nodeChar = getDatabaseNode();
		
		if subselection == 8 then
			ChatManager.Message("Taking short rest.", true, ActorManager.getActor("pc", nodeChar));
		elseif subselection == 6 then
			ChatManager.Message("Taking overnight rest.", true, ActorManager.getActor("pc", nodeChar));
			CharManager.rest(nodeChar);
		end
	end
end
