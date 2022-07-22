-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ancestry lookup data
-- Used to map the various unit ancestries to single categories
ancestrydata = {
	["human"] = "human",
	["dwarf"] = "dwarf",
	["elf"] = "elf",
	["orc"] = "orc",
	["goblin"] = "goblinoid",
	["hobgoblin"] = "goblinoid",
	["bugbear"] = "goblinoid",
	["titan spider"] = "goblinoid",
	["zombie"] = "undead",
	["skeleton"] = "undead",
	["ghoul"] = "undead",
	["wight"] = "undead",
	["wraith"] = "undead",
	["huecuva"] = "undead",
}

-- Should go through here and add sTargeting = "self" to most of the effects, since they're supposed to be self only
domainpowers = {
	-- Adventuring Parties
	-- This one doesn't make much sense since it can be applied after the roll is made
	["never tell me the odds"] = {
		{ type = "effect", sName = "SAVEDC: 2x PDIE", nDuration = 1, sApply = "single", sTargeting = "self" },
	},
	["avenge me"] = {
		{ type = "effect", sName = "AURA: 30 friend; DMG: PDIE", nDuration = 0, sTargeting = "self" }
	},
	["what does this button do?"] = {
		{ type = "effect", sName = "DMG: 1d6 2x PDIE, force", nDuration = 10, sTargeting = "self" },
		{ type = "effect", sName = "ATK: 2x PDIE; DMG: 2x PDIE", nDuration = 0, sTargeting = "self" },
		{ type = "effect", sName = "SAVE: -PDIE", nDuration = 10, sTargeting = "self" },
		{ type = "effect", sName = "AC: PDIE", nDuration = 10, sTargeting = "self" }
	},
	["fighting dirty"] = {
		{ type = "effect", sName = "ATK: -PDIE; DMG: 5x PDIE", nDuration = 1, sApply = "single", sTargeting = "self" }
	},
	-- Martial Regiment
	["brute force"] = { 
		{ type = "effect", sName = "ATK: PDIE; DMG: PDIE", nDuration = 1, sApply = "single", sTargeting = "self" }
	},
	-- Since you take the dice after the effect this is unlikely to be necessary, but it's here
	["steel resolve"] = {
		{ type = "effect", sName = "SAVE: PDIE", nDuration = 1, sApply = "single", sTargeting = "self" }
	},
	["sworn to protect"] = { 
		{ type = "effect", sName = "DECREMENT; AC: PDIE", sTargeting = "self" },
		{ type = "effect", sName = "AURA: 15 friend; SAVE: PDIE", sTargeting = "self" },
	},
	["skirmisher"] = { 
		{ type = "effect", sName = "DECREMENT; Speed 5x PDIE; DMG: PDIE", sTargeting = "self" }
	},
	-- Mercantile Guild
	["outgunned"] = {
		{ type = "effect", sName = "DMG: PDIE", nDuration = 1, sApply = "roll", sTargeting = "self" }
	},
	["action plan"] = {
		{ type = "effect", sName = "ATK: PDIE; CHECK: PDIE; SAVEDC: PDIE", nDuration = 1, sApply = "roll", sTargeting = "self" }
	},
	-- Mystic Circle
	["universal energy field"] = {
		{ type = "effect", sName = "DMG: PDIE, acid", nDuration = 1, sTargeting = "self" },
		{ type = "effect", sName = "DMG: PDIE, cold", nDuration = 1, sTargeting = "self" },
		{ type = "effect", sName = "DMG: PDIE, fire", nDuration = 1, sTargeting = "self" },
		{ type = "effect", sName = "DMG: PDIE, lightning", nDuration = 1, sTargeting = "self" },
	},
	["your staff is broken"] = {
		{ type = "effect", sName = "SAVEDC: PDIE", sTargeting = "self", sApply = "roll" },
		{ type = "powersave", save = "intelligence", savebase = "fixed", savemod = 0 }
	},
	["magic misdirection"] = {
		{ type = "effect", sName = "CHECK: PDIE", nDuration = 1, sApply = "roll", sTargeting = "self" },
		{ type = "effect", sName = "Charmed", nDuration = 1 },
	},
	-- Nature Pact
	["vine entrapment"] = {
		{ type = "effect", sName = "CHECK: PDIE", nDuration = 1, sApply = "roll", sTargeting = "self" },
		{ type = "powersave", save = "dexterity", savebase = "fixed", savemod = 10 },
		{ type = "effect", sName = "Restrained", nDuration = 1 },
	},
	["impenetrable defense"] = {
		{ type = "effect", sName = "RESIST: PDIE", nDuration = 1 }
	},
	["rapid assault"] = {
		{ type = "effect", sName = "ATK: PDIE; DMG: PDIE", nDuration = 1, sApply = "single", sTargeting = "self" }
	},
	-- Noble Court
	["mantle of authority"] = {
		-- This will not work, because the stat short hands (STR, CON, etc) add to the modifier
		-- Not the score total. This is problematic
		-- { type = "effect", sName = "DECREMENT; STR: PDIE", nDuration = 1 }
	},
	["conqueror"] = {
		{ type = "effect", sName = "ATK: PDIE; Speed 10;", nDuration = 1, sTargeting = "self" }
	},
	["timely aid"] = {
		{ type = "effect", sName = "AC: PDIE", nDuration = 1 },
	},
	-- Religious Order
	["penance"] = {
		{ type = "effect", sName = "DECREMENT", sTargeting = "self" },
		{ type = "effect", sName = "DMGO: 2x PDIE, necrotic; Speed penalty: 5x PDIE" },
		{ type = "effect", sName = "DMGO: 2x PDIE, radiant; Speed penalty: 5x PDIE" },
	},
	-- Underworld Syndicate
	["find weakness"] = {
		{ type = "effect", sName = "AC: -PDIE", nDuration = 1 },
	},
	["poison weapons"] = {
		{ type = "effect", sName = "DECREMENT; DMG: PDIE, poison", nDuration = 1, sTargeting = "self", sApply = "single" },
		{ type = "effect", sName = "Poisoned", nDuration = 1 },
	}
}

auratraits = {
	["burning"] = "AURA: 5 foe; Burning; DMGO: 1",
	["rime"] = "AURA: 5 foe; Rime; Cannot move"
}

fortifications = {
	["stone fence"] = { morale = 1, defense = 2, power = 0, hp = 4},
	["guard tower"] = { morale = 1, defense = 2, power = 2, hp = 6},
	["town walls"] = { morale = 2, defense = 2, power = 2, hp = 8},
	["city gates"] = { morale = 2, defense = 2, power = 2, hp = 8},
	["keep"] = { morale = 3, defense = 2, power = 2, hp = 10},
	["castle"] = { morale = 4, defense = 2, power = 2, hp = 12},
}

colors = {
	["FFFF0000"] = true,
	["FF00FF00"] = true,
	["FF0000FF"] = true,
	["FF00FFFF"] = true,
	["FFFFFF00"] = true,
	["FFFF00FF"] = true,
	["FF6600D2"] = true,
	["FFFF7D04"] = true,
}

unit_experience = {
	["infantry"] = {
		["levies"] = {
			["numberOfAttacks"] = 0,
			["attack"] = -1,
			["defense"] = -2,
			["morale"] = -2,
			["command"]= -1,
		},
		["regular"] = {
			["numberOfAttacks"] = 0,
			["attack"] = 0,
			["defense"] = 0,
			["morale"] = 0,
			["command"]= 1,
		},
		["veteran"]= {
			["numberOfAttacks"] = 0,
			["attack"] = 1,
			["defense"] = 2,
			["morale"] = 2,
			["command"]= 2,
		},
		["elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 2,
			["defense"] = 4,
			["morale"] = 4,
			["command"]= 2,
		},
		["super-elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 3,
			["defense"] = 6,
			["morale"] = 6,
			["command"]= 3,
		},
	},
	["cavalry"] = {
		["levies"] = {
			["numberOfAttacks"] = 0,
			["attack"] = 0,
			["defense"] = 0,
			["morale"] = 0,
			["command"]= 0,
		},
		["regular"] = {
			["numberOfAttacks"] = 0,
			["attack"] = 0,
			["defense"] = 0,
			["morale"] = 0,
			["command"]= 0,
		},
		["veteran"]= {
			["numberOfAttacks"] = 0,
			["attack"] = 1,
			["defense"] = 1,
			["morale"] = 1,
			["command"]= 2,
		},
		["elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 2,
			["defense"] = 2,
			["morale"] = 2,
			["command"]= 4,
		},
		["super-elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 3,
			["defense"] = 3,
			["morale"] = 3,
			["command"]= 6,
		},
	},
	["aerial"] = {
		["levies"] = {
			["numberOfAttacks"] = 0,
			["attack"] = 0,
			["defense"] = 0,
			["morale"] = 0,
			["command"]= 0,
		},
		["regular"] = {
			["numberOfAttacks"] = 0,
			["attack"] = 0,
			["defense"] = 0,
			["morale"] = 0,
			["command"]= 0,
		},
		["veteran"]= {
			["numberOfAttacks"] = 0,
			["attack"] = 1,
			["defense"] = 1,
			["morale"] = 1,
			["command"]= 2,
		},
		["elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 2,
			["defense"] = 2,
			["morale"] = 2,
			["command"]= 4,
		},
		["super-elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 3,
			["defense"] = 3,
			["morale"] = 3,
			["command"]= 6,
		},
	},
	["artillery"] = {
		["levies"] = {
			["numberOfAttacks"] = 0,
			["attack"] = 0,
			["defense"] = 0,
			["morale"] = 0,
			["command"]= 0,
		},
		["regular"] = {
			["numberOfAttacks"] = 0,
			["attack"] = 0,
			["defense"] = 0,
			["morale"] = 0,
			["command"]= 0,
		},
		["veteran"]= {
			["numberOfAttacks"] = 1,
			["attack"] = 2,
			["defense"] = 1,
			["morale"] = 1,
			["command"]= 1,
		},
		["elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 4,
			["defense"] = 2,
			["morale"] = 2,
			["command"]= 2,
		},
		["super-elite"] = {
			["numberOfAttacks"] = 1,
			["attack"] = 6,
			["defense"] = 3,
			["morale"] = 3,
			["command"]= 3,
		},
	}
}

unit_equipment = {
	["infantry"] = {
		["light"] = {
			["power"] = 0,
			["toughness"] = 0,
			["damage"] = 0
		},
		["medium"] = {
			["power"] = 2,
			["toughness"] = 2,
			["damage"] = 0
		},
		["heavy"] = {
			["power"] = 4,
			["toughness"] = 4,
			["damage"] = 0
		},
		["super-heavy"] = {
			["power"] = 6,
			["toughness"] = 6,
			["damage"] = 1
		}
	},
	["cavalry"] = {
		["light"] = {
			["power"] = 0,
			["toughness"] = 0,
			["damage"] = 0
		},
		["medium"] = {
			["power"] = 1,
			["toughness"] = 1,
			["damage"] = 0
		},
		["heavy"] = {
			["power"] = 2,
			["toughness"] = 2,
			["damage"] = 0
		},
		["super-heavy"] = {
			["power"] = 3,
			["toughness"] = 3,
			["damage"] = 1
		}
	},
	["aerial"] = {
		["light"] = {
			["power"] = 0,
			["toughness"] = 0,
			["damage"] = 0
		},
		["medium"] = {
			["power"] = 1,
			["toughness"] = 1,
			["damage"] = 0
		},
		["heavy"] = {
			["power"] = 2,
			["toughness"] = 2,
			["damage"] = 0
		},
		["super-heavy"] = {
			["power"] = 3,
			["toughness"] = 3,
			["damage"] = 1
		}
	},
	["artillery"] = {
		["light"] = {
			["power"] = 0,
			["toughness"] = 0,
			["damage"] = 0
		},
		["medium"] = {
			["power"] = 1,
			["toughness"] = 1,
			["damage"] = 0
		},
		["heavy"] = {
			["power"] = 2,
			["toughness"] = 2,
			["damage"] = 0
		},
		["super-heavy"] = {
			["power"] = 3,
			["toughness"] = 3,
			["damage"] = 0
		}
	}
}

function getUnitExperienceStats(sUnitType, sExperience)
	local unit = unit_experience[sUnitType:lower()];
	if unit and unit[sExperience:lower()] then
		return unit[sExperience:lower()];
	end

	return nil;
end

function getUnitEquipmentStats(sUnitType, sEquipment)
	local unit = unit_equipment[sUnitType:lower()];
	if unit and unit[sEquipment:lower()] then
		return unit[sEquipment:lower()];
	end

	return nil;
end