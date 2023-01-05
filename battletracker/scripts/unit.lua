-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeUnit = getDatabaseNode();
	activeUpdated(DB.getChild(nodeUnit, "active"));
	DB.addHandler(DB.getPath(nodeUnit, "commander_link"), "onUpdate", commanderUpdated);
	DB.addHandler(DB.getPath(nodeUnit, "active"), "onUpdate", activeUpdated);
	
	updateName();
end

function onClose()
	local nodeUnit = getDatabaseNode();
	DB.removeHandler(DB.getPath(nodeUnit, "commander_link"), "onUpdate", commanderUpdated);
	DB.removeHandler(DB.getPath(nodeUnit, "active"), "onUpdate", activeUpdated);
end

function commanderUpdated(nodeLink)
	local sRecord = CombatManager.CT_MAIN_PATH;
	if nodeLink then
		_, sRecord = DB.getValue(nodeLink, "", "", CombatManager.CT_MAIN_PATH);
	end

	if sRecord ~= DB.getPath(windowlist.window.getDatabaseNode()) then
		close();
	end
end

function updateName()
	token.setTooltipText(DB.getValue(name));
end

function activeUpdated(nodeActive)
	local bActive = nodeActive and (DB.getValue(nodeActive) == 1);
	if bActive then
		setFrame("border");
		setBackColor(ColorManagerKw.COLOR_UNIT_SELECTION);
	else
		setFrame(nil);
		setBackColor("00000000");
	end
end

function onDrop(x, y, draginfo)
	local rTarget = ActorManager.resolveActor(getDatabaseNode());
	if rTarget then
		local sDragType = draginfo.getType();
		if StringManager.contains(GameSystem.targetactions, sDragType) then
			ActionsManager.actionDrop(draginfo, rTarget);
			return true;
		end
	end
end