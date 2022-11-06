--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local onValueChanged = super.onValueChanged;
	super.onValueChanged = function(...)
		KingdomsAndWarfare.invokeWithBaseAbilities(onValueChanged, ...);
	end

	super.onInit();
end