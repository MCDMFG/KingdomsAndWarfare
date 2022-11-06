--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local applyRacialAbilityDefault = CharWizardManager.applyRacialAbilityDefault;
	CharWizardManager.applyRacialAbilityDefault = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(applyRacialAbilityDefault, ...);
	end

	local applyRacialAbilityOption1 = CharWizardManager.applyRacialAbilityOption1;
	CharWizardManager.applyRacialAbilityOption1 = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(applyRacialAbilityOption1, ...);
	end

	local applyRacialAbilityOption2 = CharWizardManager.applyRacialAbilityOption2;
	CharWizardManager.applyRacialAbilityOption2 = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(applyRacialAbilityOption2, ...);
	end

	local parseChoiceRacialMod = CharWizardManager.parseChoiceRacialMod;
	CharWizardManager.parseChoiceRacialMod = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(parseChoiceRacialMod, ...);
	end

	local calcRacialAbilityMods = CharWizardManager.calcRacialAbilityMods
	CharWizardManager.calcRacialAbilityMods = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(calcRacialAbilityMods, ...);
	end

	local parseASIChoice = CharWizardManager.parseASIChoice
	CharWizardManager.parseASIChoice = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(parseASIChoice, ...);
	end

	local getDefaultRaceTraitMod = CharWizardManager.getDefaultRaceTraitMod
	CharWizardManager.getDefaultRaceTraitMod = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(getDefaultRaceTraitMod, ...);
	end
end