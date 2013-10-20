-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function showFullHeaders(show_flag)
	description.setVisible(show_flag);
	if subdescription then
		subdescription.setVisible(show_flag and subdescription.getValue ~= "");
	end
end
