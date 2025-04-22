--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local setAbilityScores = super.setAbilityScores
	super.setAbilityScores = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(setAbilityScores, ...);
	end

	local updateAbilityAlerts = super.updateAbilityAlerts
	super.updateAbilityAlerts = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(updateAbilityAlerts, ...);
	end

	if super and super.onInit then
		super.onInit()
	end
end