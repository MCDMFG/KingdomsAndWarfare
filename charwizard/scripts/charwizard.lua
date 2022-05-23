--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local setAbilityScoresOriginal;

function onInit()
	setAbilityScoresOriginal = super.setAbilityScores;
	super.setAbilityScores = setAbilityScores;

	if super and super.onInit then
		super.onInit()
	end
end

function updateAbilityAlerts()
	local fullAbilities = DataCommon.abilities;
	DataCommon.abilities = KingdomsAndWarfare.aBaseAbilities;
	super.updateAbilityAlerts();
	DataCommon.abilities = fullAbilities;
end

function setAbilityScores(nodeChar)
	local fullAbilities = DataCommon.abilities;
	DataCommon.abilities = KingdomsAndWarfare.aBaseAbilities;
	setAbilityScoresOriginal(nodeChar);
	DataCommon.abilities = fullAbilities;
end