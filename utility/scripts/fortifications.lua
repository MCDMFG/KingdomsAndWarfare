-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onClickDown(button, x, y)
	if Session.IsHost then
		return true;
	end
end
function onClickRelease(button, x, y)
	if Session.IsHost then
		if getWindowCount() == 0 then
			addEntry();
		end
		return true;
	end
end
function onDrop(x, y, draginfo)
	if Session.IsHost then
		local rEffect = EffectManager.decodeEffectFromDrag(draginfo);
		if rEffect then
			local node = addEntry();
			if node then
				EffectManager.setEffect(node, rEffect);
			end
		end
		return true;
	end
end
