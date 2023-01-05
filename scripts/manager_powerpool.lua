-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- This script is needed to manage the ability for players to add power dice to a domain's power pool
local OOB_MSGTYPE_ADDPOWERDIE = "addpowerdie";
local OOB_MSGTYPE_REMOVEPOWERDIE = "removepowerdie";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ADDPOWERDIE, handleAddPowerDie);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_REMOVEPOWERDIE, handleRemovePowerDie);
end

function AddDieToPool(nValue, domainNode)
	if domainNode then
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_ADDPOWERDIE;
		msgOOB.sDomain = domainNode.getNodeName();
		msgOOB.nValue = nValue;

		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function handleAddPowerDie(msgOOB)
	local sNode = msgOOB.sDomain;
	local domainNode = DB.findNode(sNode);
	if domainNode then
		local bReadOnly = true;
		local powerdie = nil;

		if domainNode.getPath():match("partysheet") then
			local domainsize = DB.getValue("partysheet.domainsize", "", 1)
			powerdie = "d4";
			if domainsize == 2 then powerdie = "d6"
			elseif domainsize == 3 then powerdie = "d8"
			elseif domainsize == 4 then powerdie = "d10"
			elseif domainsize == 5 then powerdie = "d12"
			end
		else
			bReadOnly = WindowManager.getReadOnlyState(domainNode);
			powerdie = DB.getValue(domainNode, "powerdie", "d4");
			if (powerdie or "") == "" then
				powerdie = "d4"
			end
		end
		
		local powerDice = domainNode.getChild("powerpool");
		local newDie = DB.createChild(powerDice);
		local valueNode = DB.createChild(newDie, "value", "number")
		valueNode.setValue(tonumber(msgOOB.nValue) or 0);
		local dieNode = DB.createChild(newDie, "die", "dice");
		DB.setValue(dieNode, { powerdie });
	end
end

function RemoveDieFromPool(nValue, domainNode)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_REMOVEPOWERDIE;
	msgOOB.nValue = nValue;
	msgOOB.sDomain = domainNode.getNodeName(); -- DB change

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleRemovePowerDie(msgOOB)
	local domainNode = DB.findNode(msgOOB.sDomain);
	if domainNode then
		local entries = DB.getChildren(domainNode, "powerpool")
		for k,v in pairs(entries) do
			local value = DB.getValue(v, "value", 0);
			if value == tonumber(msgOOB.nValue or 0) then
				DB.deleteNode(v);
				return;
			end
		end
	end
end

