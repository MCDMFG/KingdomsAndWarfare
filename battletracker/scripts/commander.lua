-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	CombatManager.addKeyedCombatantFieldChangeHandler("unit", "commander_link", "onUpdate", commanderUpdated);
	DB.addHandler(DB.getPath(node, "friendfoe"), "onUpdate", onFactionUpdated);
	DB.addHandler(DB.getPath(node, "active"), "onUpdate", onActiveUpdated);
	DB.addHandler(DB.getPath(node, "isidentified"), "onUpdate", onIDChanged);
	if Session.IsHost then
		DB.addHandler(DB.getPath(node), "onDelete", onDelete);
	else
		DB.addHandler(DB.getPath(node, "tokenvis"), "onUpdate", onTokenVisUpdated);
	end

	updateDisplay();
	onIDChanged();
	
	-- Initialize color
	if Session.IsHost then
		local rActor = ActorManager.resolveActor(node);
		if rActor and ActorManager.isPC(rActor) then
			local nodeActor = ActorManager.getCreatureNode(rActor);
			if nodeActor then
				-- Check if the Pc is currently activated. If not, getIdentityColor will return black
				if StringManager.isWord(DB.getName(nodeActor), User.getAllActiveIdentities()) then
					color_swatch.setColor(User.getIdentityColor(sCreatureIdentity));
				end
			end
		end
	end
end
function onClose()
	local node = getDatabaseNode();
	CombatManager.removeKeyedCombatantFieldChangeHandler("unit", "commander_link", "onUpdate", commanderUpdated);
	DB.removeHandler(DB.getPath(node, "friendfoe"), "onUpdate", onFactionUpdated);
	DB.removeHandler(DB.getPath(node, "active"), "onUpdate", onActiveUpdated);
	DB.removeHandler(DB.getPath(node, "isidentified"), "onUpdate", onIDChanged);
	if Session.IsHost then
		DB.removeHandler(DB.getPath(node), "onDelete", onDelete);
	else
		DB.removeHandler(DB.getPath(node, "tokenvis"), "onUpdate", onTokenVisUpdated);
	end
end

-- Listen to its own delete event so it can neatly delete all of its units. Could also have the units set their commanders to nil.
function onDelete(nodeCommander)
	for _,w in pairs(list.getWindows()) do
		local node = w.getDatabaseNode();
		if node then
			DB.deleteNode(node);
		end
	end
end
function commanderUpdated(nodeLink)
	if nodeLink then
		local _, sRecord = nodeLink.getValue();
		if sRecord == DB.getPath(getDatabaseNode()) then
			list.createWindow(DB.getChild(nodeLink, ".."));
		end
	end
end
function onFactionUpdated(nodeUpdated)
	local sFaction = nodeUpdated.getValue();
	for k,v in pairs(list.getWindows()) do
		local windownode = v.getDatabaseNode();
		if windownode then
			DB.setValue(windownode, "friendfoe", "string", sFaction);
		end
	end
	updateDisplay();
end
function onActiveUpdated(node)
	updateDisplay();
end
function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = DB.getValue(nodeRecord, "link", "", "");
	if sClass == "npc" then
		local bID = LibraryData.getIDState("npc", nodeRecord, true);
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
	else
		name.setVisible(true);
		nonid_name.setVisible(false);
	end
end
function onTokenVisUpdated(nodeTokenVis)
	windowlist.applyFilter();
end

function updateDisplay()
	local sFaction = DB.getValue(getDatabaseNode(), "friendfoe", "");

	local sFrame = "";
	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then		
		if sFaction == "friend" then
			sFrame = "ctentrybox_friend_active";
		elseif sFaction == "neutral" then
			sFrame = "ctentrybox_neutral_active";
		elseif sFaction == "foe" then
			sFrame = "ctentrybox_foe_active";
		else
			sFrame = "ctentrybox_active";
		end
	else		
		if sFaction == "friend" then
			sFrame = "ctentrybox_friend";
		elseif sFaction == "neutral" then
			sFrame = "ctentrybox_neutral";
		elseif sFaction == "foe" then
			sFrame = "ctentrybox_foe";
		else
			sFrame = "ctentrybox";
		end
	end

	if sFrame ~= "" then
		setFrame(sFrame);
	end
end


-- this function is necessary because the link_ctentry template calls window.onLinkChanged()
function onLinkChanged()
	if link then
		commanderUpdated(link.getDatabaseNode())
	end
end

function onUnitListChanged()
	setColor(color_swatch.getColor());
end

function setColor(sColor)
	if Session.IsHost then
		for _,winUnit in ipairs(list.getWindows()) do
			DB.setValue(winUnit.getDatabaseNode(), "color", "string", sColor); -- Let the TokenManager do the coloration work.
		end
	end
end

function onDrop(x, y, draginfo)
	local sType = draginfo.getType();
	local sClass, sRecord = draginfo.getShortcutData();
	if sType == "battletrackerunit" then
		local nodeCommander = getDatabaseNode();
		local sPath = nodeCommander.getPath();
		local nodeUnit = draginfo.getDatabaseNode();
		local _,sCommander = DB.getValue(nodeUnit, "commander_link");
		if sCommander ~= sPath then
			CombatManagerKw.configureUnitCommander(nodeUnit, nodeCommander);
		end
		return true;
	elseif sClass == "reference_unit" then
		CombatManagerKw.setUnitDropCommander(getDatabaseNode());
		return CombatDropManager.handleAnyDrop(draginfo, "unit"); -- TODO check here
	end
end

