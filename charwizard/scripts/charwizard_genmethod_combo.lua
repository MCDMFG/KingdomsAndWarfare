-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local onValueChangedOriginal;

function onInit()
	onValueChangedOriginal = super.onValueChanged;
	super.onValueChanged = onValueChanged;
	super.onInit();
end

function onValueChanged()
	local fullAbilities = DataCommon.abilities;
	DataCommon.abilities = KingdomsAndWarfare.aBaseAbilities;
	Debug.chat(DataCommon.abilities)
	onValueChangedOriginal();
	DataCommon.abilities = fullAbilities;
end