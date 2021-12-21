-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOnFilter;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	fOnFilter = list.onFilter;
	list.onFilter = onFilter;
	list.applyFilter();

	CombatManager.setCustomTurnStart(onTurnStartSetCommander);
	CombatManager.setCustomDeleteCombatantHandler(onCommanderDelete);
end

function onFilter(w)
	local node = w.getDatabaseNode();
	return (not fOnFilter or fOnFilter(w)) and not ActorManagerKw.isUnit(node);
end