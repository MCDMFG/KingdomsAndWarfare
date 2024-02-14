-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

TOKEN_STATE_SIZE = 15
TOKEN_STATE_POSX = 0;
TOKEN_STATE_POSY = 0;
TOKEN_STATE_SPACING = 2;

TOKEN_BROKEN_SIZE = 40;

UNDERLAY_OPACITY = "7F";
DEFAULT_COLOR = "FFFFFFFF";

local fUpdateEffectsHelper;
local fUpdateSizeHelper;
local fUpdateTokenColor;
local fLinkToken;

function onInit()
	fUpdateEffectsHelper = TokenManager.updateEffectsHelper;
	TokenManager.updateEffectsHelper = updateEffectsHelper;
	fUpdateSizeHelper = TokenManager.updateSizeHelper;
	TokenManager.updateSizeHelper = updateSizeHelper;
	fUpdateTokenColor = TokenManager.updateTokenColor;
	TokenManager.updateTokenColor = updateTokenColor;
	fLinkToken = TokenManager.linkToken;
	TokenManager.linkToken = linkToken;

	CombatManager.addCombatantFieldChangeHandler("activated", "onUpdate", updateState);
	CombatManager.addCombatantFieldChangeHandler("reaction", "onUpdate", updateState);
	CombatManager.addCombatantFieldChangeHandler("exposed", "onUpdate", updateExposed);
	CombatManager.addCombatantFieldChangeHandler("wounds", "onUpdate", updateWounds);

	if Session.IsHost then
		CombatManager.addCombatantFieldChangeHandler("color", "onUpdate", updateColor);
	end

	CombatManagerKw.registerUnitSelectionHandler(onBattleTrackerSelection);

	-- Initialize the states of tokens
	initializeStates();
end

function updateEffectsHelper(tokenCT, nodeCT)
	fUpdateEffectsHelper(tokenCT, nodeCT);
	updateStateHelper(tokenCT, nodeCT);
	updateWoundsHelper(tokenCT, nodeCT);
	updateExposedHelper(tokenCT, nodeCT);
end

function updateSizeHelper(tokenCT, nodeCT)
	fUpdateSizeHelper(tokenCT, nodeCT)
	updateColorHelper(tokenCT, nodeCT)
end

function updateTokenColor(token)
	if not token then
		return;
	end
	local nodeCT = CombatManager.getCTFromToken(token);
	if ActorManagerKw.isUnit(nodeCT) then
		updateColorHelper(token, nodeCT);
	else
		fUpdateTokenColor(token);
	end
end

function linkToken(nodeCT, newTokenInstance)
	fLinkToken(nodeCT, newTokenInstance);
	ImageManagerKw.configureSelection(newTokenInstance);
end

--==================================================================================--

function initializeStates()
	-- todo relocate this to updateAttributesHelper, which is invoked (indirectly) on demand by the ImageManager
	local aCurrentCombatants = CombatManager.getCombatantNodes("unit");
	for _,nodeCT in pairs(aCurrentCombatants) do
		if ActorManagerKw.isUnit(nodeCT) then
			local tokenCT = CombatManager.getTokenFromCT(nodeCT);
			if tokenCT then
				updateStateHelper(tokenCT, nodeCT);
				updateWoundsHelper(tokenCT, nodeCT);
				updateColorHelper(tokenCT, nodeCT);
			end
		end
	end
end

function updateWounds(nodeWounds)
	local nodeCT = DB.getParent(nodeWounds);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateWoundsHelper(tokenCT, nodeCT)
	end
end
function updateWoundsHelper(tokenCT, nodeCT)
	if not tokenCT or not ActorManagerKw.isUnit(nodeCT) then
		return;
	end

	if (ActorHealthManager.getWoundPercent(ActorManager.resolveActor(nodeCT)) >= 1) then
		if not tokenCT.findWidget("broken") then
			local tWidget = {
				name = "broken",
				icon = "cond_broken", 
				tooltip = "Broken",
				w = TOKEN_BROKEN_SIZE, h = TOKEN_BROKEN_SIZE, 
			};
			tokenCT.addBitmapWidget(tWidget);
		end
	else
		tokenCT.deleteWidget("broken");
	end
end

function updateState(nodeState)
	local nodeCT = DB.getParent(nodeState);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateStateHelper(tokenCT, nodeCT);	 
	end
end
function updateStateHelper(tokenCT, nodeCT)
	if not tokenCT or not ActorManagerKw.isUnit(nodeCT) then
		return;
	end

	local posx = 0;

	if (DB.getValue(nodeCT, "activated", 0) == 1) then
		if not tokenCT.findWidget("action") then
			local tWidget = {
				name = "action",
				icon = "state_activated", 
				tooltip = "Has Activated",
				position = "topleft",
				x = posx + TOKEN_STATE_SIZE / 2,
				y = TOKEN_STATE_SIZE / 2,
				w = TOKEN_STATE_SIZE, h = TOKEN_STATE_SIZE, 
			};
			tokenCT.addBitmapWidget(tWidget);
		end
		posx = posx + TOKEN_STATE_SIZE;
	else
		tokenCT.deleteWidget("action");
	end

	if (DB.getValue(nodeCT, "reaction", 0) == 1) then
		if not tokenCT.findWidget("reaction") then
			local tWidget = {
				name = "reaction",
				icon = "state_reacted", 
				tooltip = "Has Reacted",
				position = "topleft",
				x = posx + TOKEN_STATE_SIZE / 2,
				y = TOKEN_STATE_SIZE / 2,
				w = TOKEN_STATE_SIZE, h = TOKEN_STATE_SIZE, 
			};
			tokenCT.addBitmapWidget(tWidget);
		end
	else
		tokenCT.deleteWidget("reaction");
	end
end

function updateExposed(nodeExposed)
	local nodeCT = DB.getParent(nodeExposed);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateExposedHelper(tokenCT, nodeCT);	 
	end
end
function updateExposedHelper(tokenCT, nodeCT)
	if not tokenCT or not ActorManagerKw.isUnit(nodeCT) then
		return;
	end

	if (DB.getValue(nodeCT, "exposed", 0) == 1) then
		if not tokenCT.findWidget("exposed") then
			local tWidget = {
				name = "exposed",
				icon = "state_exposed", 
				tooltip = "Is Exposed",
				position = "bottomright",
				x = -(TOKEN_STATE_SIZE / 2),
				y = -(TOKEN_STATE_SIZE / 2),
				w = TOKEN_STATE_SIZE, h = TOKEN_STATE_SIZE, 
			};
			tokenCT.addBitmapWidget(tWidget);
		end
	else
		tokenCT.deleteWidget("exposed");
	end
end

function updateColor(nodeColor)
	if not nodeColor then return; end

	local nodeCT = nodeColor.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateColorHelper(tokenCT, nodeCT);	 
	end
end
function updateColorHelper(tokenCT, nodeCT)
	if not tokenCT or not ActorManagerKw.isUnit(nodeCT) then
		return;
	end

	local sColor = DB.getValue(nodeCT, "color", DEFAULT_COLOR);
	local sUnderlay = UNDERLAY_OPACITY .. sColor:sub(3);

	tokenCT.removeAllUnderlays();
	tokenCT.addUnderlay(0.5, sUnderlay);
	tokenCT.setColor(sColor);
end

function onBattleTrackerSelection(nodeUnit, nSlot)
	local sSlot = tostring(nSlot);
	local tokenCT = CombatManager.getTokenFromCT(nodeUnit);
	if tokenCT then
		local wgt = tokenCT.findWidget("selectionslot");
		if wgt then
			wgt.setText(sSlot);
		else
			local tWidget = {
				name = "selectionslot",
				frame = "mini_name",
				frameoffset = "5,2,4,2",
				font = "mini_name_selected", 
				text = sSlot,
			};
			wgt = tokenCT.addTextWidget(tWidget);
	
			local w,h = wgt.getSize();
			wgt.setPosition("topright", -w/2-5, h/2+2);
		end
	end

	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes("unit")) do
		if nodeCombatant ~= nodeUnit then
			tokenCT = CombatManager.getTokenFromCT(nodeCombatant);
			if tokenCT then
				local wgt = tokenCT.findWidget("selectionslot");
				if wgt and (wgt.getText() == sSlot) then
					wgt.destroy();
				end
			end
		end
	end
end
