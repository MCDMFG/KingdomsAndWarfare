--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onDataChanged();
	local nodeAction = getDatabaseNode();
	DB.addHandler(nodeAction, "onChildUpdate", onDataChanged);
	local nodePower = DB.getChild(nodeAction, "...");
	DB.addHandler(DB.getPath(nodePower, "group"), "onUpdate", onDataChanged);
end
function onClose()
	local nodeAction = getDatabaseNode();
	DB.removeHandler(nodeAction, "onChildUpdate", onDataChanged);
	local nodePower = DB.getChild(nodeAction, "...");
	DB.removeHandler(DB.getPath(nodePower, "group"), "onUpdate", onDataChanged);
end
function onDataChanged()
	local sTest = PowerManagerKw.getPCPowerTestActionText(getDatabaseNode());
	testview.setValue(sTest);
end
function performAction(draginfo, sSubRoll)
	PowerActionManagerCore.performAction(draginfo, getDatabaseNode(), { sSubRoll = sSubRoll });
end