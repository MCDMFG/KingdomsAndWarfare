-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local markers = WarfareManager.getRankMarkers();
	local collapsedMarker = WarfareManager.getCollapsedMarker();
	for _,token in pairs(getTokens()) do
		ImageManagerKw.configureLockability(token, markers, collapsedMarker);
		ImageManagerKw.configureSelection(token);
	end
end

function onTokenAdded(token)
	ImageManagerKw.configureLockability(token);
	ImageManagerKw.configureSelection(token);

	if super and super.onTokenAdded then
		super.onTokenAdded(token);
	end
end

local _sPreviousMode;
function onCursorModeChanged(sMode)
	if _sPreviousMode == "select" then
		local bEdit = (window.toolbar.subwindow.warfare.getValue() == 1);
		ImageManagerKw.deselectLockableTokens(self, bEdit);
	end
	_sPreviousMode = sMode;

	if super and super.onCursorModeChanged then
		super.onCursorModeChanged(sMode);
	end
end
