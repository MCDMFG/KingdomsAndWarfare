-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function updateAbilityAlerts()
	local fullAbilities = DataCommon.abilities;
	DataCommon.abilities = KingdomsAndWarfare.aBaseAbilities;
	super.updateAbilityAlerts();
	DataCommon.abilities = fullAbilities;
end