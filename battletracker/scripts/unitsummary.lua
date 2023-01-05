-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	updateSummary();
	local nodeUnit = link.getTargetDatabaseNode(); -- Build the summary of the linked node
	DB.addHandler(DB.getPath(nodeUnit, "tier"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "experience"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "armor"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "ancestry"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "type"), "onUpdate", updateSummary);

	-- Color and ID are only tracked in the CT node
	local nodeCT = getDatabaseNode();
	onColorChanged(DB.getChild(nodeCT, "color"));
	DB.addHandler(DB.getPath(nodeCT, "color"), "onUpdate", onColorChanged);

	if FriendZone then
		linkFields();
	end
end

function onClose()
	local nodeUnit = link.getTargetDatabaseNode(); -- Build the summary of the linked node
	DB.removeHandler(DB.getPath(nodeUnit, "tier"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "experience"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "armor"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "ancestry"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "type"), "onUpdate", updateSummary);

	DB.removeHandler(DB.getPath(getDatabaseNode(), "color"), "onUpdate", onColorChanged);
end

function linkFields()
	local nodeUnit = link.getTargetDatabaseNode();
	if nodeUnit and FriendZone.isCohort(nodeUnit) then
		name.setLink(DB.createChild(nodeUnit, "name", "string"), true);
		size.setLink(DB.createChild(nodeUnit, "casualties", "number"), false);
		casualties.setLink(DB.createChild(nodeUnit, "wounds", "number"), false);
		defense.setLink(DB.createChild(nodeUnit, "abilities.defense", "number"), true);
		toughness.setLink(DB.createChild(nodeUnit, "abilities.toughness", "number"), true);
		attack.setLink(DB.createChild(nodeUnit, "abilities.attack", "number"), true);
		power.setLink(DB.createChild(nodeUnit, "abilities.power", "number"), true);
		morale.setLink(DB.createChild(nodeUnit, "abilities.morale", "number"), true);
		command.setLink(DB.createChild(nodeUnit, "abilities.command", "number"), true);
		number_attacks.setLink(DB.createChild(nodeUnit, "attacks", "number"), true);
		damage.setLink(DB.createChild(nodeUnit, "damage", "number"), true);
	end
end

function updateSummary()
	local nodeUnit = link.getTargetDatabaseNode();

	local nTier = DB.getValue(nodeUnit, "tier", 1);
	local sExperience = StringManager.capitalize(DB.getValue(nodeUnit, "experience", ""));
	local sArmor = DB.getValue(nodeUnit, "armor", "");
	local sAncestry = DB.getValue(nodeUnit, "ancestry", "");
	local sType = StringManager.capitalize(DB.getValue(nodeUnit, "type", ""));
	
	local aText = { "Tier " .. nTier };
	if sExperience ~= "" then table.insert(aText, sExperience); end
	if sArmor ~= "" then table.insert(aText, sArmor); end
	if sAncestry ~= "" then table.insert(aText, sAncestry); end
	if sType ~= "" then table.insert(aText, sType); end
	
	local sText = table.concat(aText, ", ");
	summary_label.setValue(sText);
end

function onColorChanged(nodeColor)
	color_swatch.setBackColor(DB.getValue(nodeColor, "", "00000000"))
end

-- No need to reinvent the CT action list wheel.
function setActiveVisible()
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