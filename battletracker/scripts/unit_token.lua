-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local selectionWidget;
local nSelectionSlot;
local activeWidget;
local activatedWidget;
local brokenWidget;

function onInit()
	CombatManagerKw.registerUnitSelectionHandler(unitSelected);

	local nodeUnit = window.getDatabaseNode();
	onActivatedUpdated(DB.getChild(nodeUnit, "activated"));
	onWoundsUpdated(DB.getChild(nodeUnit, "wounds"));
	DB.addHandler(DB.getPath(nodeUnit, "activated"), "onUpdate", onActivatedUpdated);
	DB.addHandler(DB.getPath(nodeUnit, "wounds"), "onUpdate", onWoundsUpdated);
end
function onClose()
	CombatManagerKw.unregisterUnitSelectionHandler(unitSelected);
	local nodeUnit = DB.getChild(getDatabaseNode(), "..");
	DB.removeHandler(DB.getPath(nodeUnit, "activated"), "onUpdate", onActivatedUpdated);
	DB.removeHandler(DB.getPath(nodeUnit, "wounds"), "onUpdate", onWoundsUpdated);
end

function onClickDown(button, x, y)
	if button == 1 then
		return true;
	end
end
function onClickRelease(button, x, y)
	if button == 1 then
		if Input.isControlPressed() then
			TargetingManager.notifyToggleTarget(CombatManager.getActiveCT(), window.getDatabaseNode());
			CombatManagerKw.selectUnit(window.getDatabaseNode(), 2);
		elseif Input.isShiftPressed() then
			CombatManagerKw.selectUnit(window.getDatabaseNode(), 2);
		else
			CombatManagerKw.selectUnit(window.getDatabaseNode(), 1);
		end
	end

	return true;
end
function onDoubleClick(x, y)
	CombatManager.handleCTTokenDoubleClick(window.getDatabaseNode());
	-- unit activation if it is the commander's turn, or should control overloading be avoided here?
	CombatManagerKw.notifyActivateUnit(nodeUnit)
end
function onWheel(notches)
	return CombatManager.handleCTTokenWheel(window.getDatabaseNode(), notches);
end
function onDragStart(button, x, y, draginfo)
	if not Session.IsHost then
		return false;
	end

	local nSpace = DB.getValue(node, "space");
	TokenManager.setDragTokenUnits(nSpace);

	local node = window.getDatabaseNode();
	draginfo.setType("battletrackerunit");
	draginfo.setTokenData(getPrototype());
	draginfo.setDatabaseNode(node);

	local base = draginfo.createBaseData();
	base.setType("token");
	base.setTokenData(getPrototype());
	return true;
end
function onDragEnd(draginfo)
	return CombatManager.handleCTTokenDragEnd(window.getDatabaseNode(), draginfo);
end
function onDrop(x, y, draginfo)
	return CombatManager.handleCTTokenDrop(window.getDatabaseNode(), draginfo);
end

function unitSelected(nodeUnit, nSlot)
	if nodeUnit == window.getDatabaseNode() then
		local sSlot = tostring(nSlot);
		if selectionWidget then
			selectionWidget.setText(sSlot);
		else
			selectionWidget = addTextWidget("mini_name_selected",sSlot);
			selectionWidget.setFrame("mini_name", 5, 1, 4, 1);
	
			local w,h = selectionWidget.getSize();
			selectionWidget.setPosition("topright", 0*w/2, h/2+1);
		end

		nSelectionSlot = nSlot;
	elseif nSlot == nSelectionSlot and selectionWidget then
		selectionWidget.destroy();
		selectionWidget = nil;
	end
end

function onActivatedUpdated(nodeActivated)
	local bHasActivated = nodeActivated and (nodeActivated.getValue() == 1);
	if activatedWidget and not bHasActivated then
		activatedWidget.destroy()
		activatedWidget = nil;
	elseif not activatedWidget and bHasActivated then
		activatedWidget = addBitmapWidget();
		activatedWidget.setBitmap("state_activated");
		activatedWidget.setTooltipText("Has Activated");
		activatedWidget.setSize(15, 15);
		activatedWidget.setPosition("topleft", 0*15/2, 15/2)
	end
end
function onWoundsUpdated(nodeWounds)
	local nodeUnit = DB.getChild(nodeWounds, "..");
	local bIsBroken = ActorHealthManager.getWoundPercent(ActorManager.resolveActor(nodeUnit)) >= 1;
	if brokenWidget and not bIsBroken then
		brokenWidget.destroy();
		brokenWidget = nil;
	end
	if not brokenWidget and bIsBroken then
		brokenWidget = addBitmapWidget();
		brokenWidget.setBitmap("cond_broken");
		brokenWidget.setTooltipText("Broken");
		brokenWidget.setSize(20, 20);
	end
end
