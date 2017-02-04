if not RCT then return end
local RCT = RCT

RCT.classes = {
	Mage		= "MAGE",
	Paladin		= "PALADIN",
	Warrior		= "WARRIOR",
	Druid		= "DRUID",
	DeathKnight	= "DEATHKNIGHT",
	Hunter		= "HUNTER",
	Priest		= "PRIEST",
	Rogue		= "ROGUE",
	Shaman		= "SHAMAN",
	Warlock		= "WARLOCK",
	Monk		= "MONK",
	DemonHunter	= "DEMONHUNTER"
}

RCT.specs = {
	Mage		= { Arcane 			= 62,	Fire 		= 63, 	Frost		= 64 						},
	Paladin		= { Holy 			= 65,	Protection	= 66,  	Retribution	= 70 						},
	Warrior		= { Arms 			= 71,	Fury 		= 72,	Protection	= 73 						},
	Druid		= { Balance 		= 102, 	Feral 		= 103, 	Guardian	= 104,	Restoration	= 105	},
	DeathKnight	= { Blood			= 250, 	Frost 		= 251, 	Unholy 		= 252 						},
	Hunter		= { BeastMastery 	= 253, 	Marksman 	= 254, 	Survival 	= 255						},
	Priest		= { Discipline 		= 256, 	Holy 		= 257, 	Shadow 		= 258						},
	Rogue		= { Assassination  	= 259, 	Combat 		= 260, 	Subtlety 	= 261					    },
	Shaman		= { Elemental 		= 262, 	Enhancement	= 263, 	Restoration = 264						},
    Warlock 	= {	Affliction 		= 265, 	Demonology	= 266, 	Destruction = 267						},
	Monk		= { Brewmaster 		= 268,	Windwalker	= 269,	Mistweaver 	= 270						},
	DemonHunter	= {	Havoc 			= 577, 	Vengeance	= 581											}
}

RCT.spellDB = {
	[RCT.classes.Mage] = {
		[RCT.specs.Mage.Arcane] = {
		},
		[RCT.specs.Mage.Fire] = {
		},
		[RCT.specs.Mage.Frost] = {
		}
	},
	[RCT.classes.Paladin] = {
		[RCT.specs.Paladin.Holy] = {
			[31821] = {		-- Aura Mastery
				name		= "Aura Mastery",
				spellId 	= 31821,
				cooldown 	= 180,
				duration 	= 8,
				level		= 70,
				resetOnWipe	= true
			},
			[31842] = {		-- Avenging Wrath
				name		= "Avenging Wrath",
				spellId		= 31842,
				cooldown	= 120,
				duration	= 20,
				level		= 80,
				modifiers	= {
					-- Sanctified Wrath talent - Increase duration by 25%
					duration	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 6, 2) then return spell.duration * 1.25 else return spell.duration end end
				}
			},
			[105809] = {	-- Holy Avenger
				name		= "Holy Avenger",
				spellId		= 105809,
				cooldown	= 90,
				duration	= 20,
				level		= 75,
				talents		= { { tier=5, column=2 } }
			},
			[200652] = {	-- Tyr's Deliverance
				name		= "Tyr's Deliverance",
				spellId		= 200652,
				cooldown	= 90,
				duration	= 10,
				level		= 98
			},
			[633] = {		-- Lay on Hands
				name		= "Lay on Hands",
				spellId		= 633,
				cooldown	= 420,
				level		= 55,
				resetOnWipe	= true,
				modifiers	= {
					-- Unbreakable Spirit talent - Reduce cooldown by 30%
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 2, 2) then return spell.cooldown * 0.7 else return spell.cooldown end end
				}
			},
			[1022] = {		-- Blessing of Protection
				name		= "Blessing of Protection",
				spellId		= 1022,
				cooldown	= 255,
				duration	= 10,
				level		= 48,
				resetOnWipe	= true
			},
			[6940] = {		-- Blessing of Sacrifice
				name		= "Blessing of Sacrifice",
				spellId		= 6940,
				cooldown	= 204,
				duration	= 12,
				level		= 56
			},
			[642] = {		-- Divine Shield
				name		= "Divine Shield",
				spellId 	= 642,
				cooldown 	= 300,
				duration 	= 8,
				level		= 18,
				resetOnWipe	= true,
				modifiers	= {
					-- Unbreakable Spirit talent - Reduce cooldown by 30%
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 2, 2) then return spell.cooldown * 0.7 else return spell.cooldown end end
				}
			},
		},
		[RCT.specs.Paladin.Protection] = {
			[31850] = {		-- Ardent Defender
				name		= "Ardent Defender",
				spellId 	= 31850,
				cooldown 	= 90,
				duration 	= 8,
				level		= 50
			},
			[204018] = {	-- Blessing of Spellwarding
				name		= "Blessing of Spellwarding",
				spellId 	= 204018,
				cooldown 	= 180,
				duration 	= 10,
				level		= 60,
				talents		= { { tier=4, column=1 } }
			},
			[1022] = {		-- Blessing of Protection
				name		= "Blessing of Protection",
				spellId 	= 1022,
				cooldown 	= 300,
				duration 	= 10,
				level		= 48,
				resetOnWipe	= true,
				talents		= { { tier=4, column=2 }, { tier=4, column=3 } }
			},
			[6940] = {		-- Blessing of Sacrifice
				name		= "Blessing of Sacrifice",
				spellId 	= 6940,
				cooldown 	= 90,
				duration 	= 12,
				level		= 56
			},
			[642] = {		-- Divine Shield
				name		= "Divine Shield",
				spellId 	= 642,
				cooldown 	= 300,
				duration 	= 8,
				level		= 18,
				resetOnWipe	= true
			},
			[633] = {		-- Lay on Hands
				name		= "Lay on Hands",
				spellId 	= 633,
				cooldown 	= 600,
				level		= 55,
				resetOnWipe	= true
			},
			[212641] = {	-- Guardian of Ancient Kings
				name		= "Guardian of Ancient Kings",
				spellId 	= 212641,
				cooldown 	= 300,
				duration	= 8,
				level		= 72,
				resetOnWipe	= true
			}
		},
		[RCT.specs.Paladin.Retribution] = {
			[642] = {		-- Divine Shield
				name		= "Divine Shield",
				spellId 	= 642,
				cooldown 	= 300,
				duration 	= 8,
				level		= 18,
				resetOnWipe	= true,
				modifiers	= {
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 6, 1) then return spell.cooldown * 0.8 else return spell.cooldown end end
				}
			},
			[1022] = {		-- Blessing of Protection
				name		= "Blessing of Protection",
				spellId 	= 1022,
				cooldown 	= 210,
				duration 	= 10,
				level		= 48,
				resetOnWipe	= true
			},
			[633] = {		-- Lay on Hands
				name		= "Lay on Hands",
				spellId 	= 633,
				cooldown 	= 600,
				level		= 55,
				resetOnWipe	= true
			},
		},
	},
	[RCT.classes.Warrior] = {
		[RCT.specs.Warrior.Arms] = {
			[97462] = {		-- Commanding Shout
				name		= "Commanding Shout",
				spellId 	= 97462,
				cooldown 	= 180,
				duration	= 10,
				level		= 80
			}
		},
		[RCT.specs.Warrior.Fury] = {
			[97462] = {		-- Commanding Shout
				name		= "Commanding Shout",
				spellId 	= 97462,
				cooldown 	= 180,
				duration	= 10,
				level		= 80
			}
		},
		[RCT.specs.Warrior.Protection] = {
		}
	},
	[RCT.classes.Druid] = {
		[RCT.specs.Druid.Balance] = {
			[29166] = {		-- Innervate
				name		= "Innervate",
				spellId 	= 29166,
				cooldown 	= 180,
				duration	= 10,
				level		= 50
			}		
		},
		[RCT.specs.Druid.Feral] = {			
		},
		[RCT.specs.Druid.Guardian] = {			
		},
		[RCT.specs.Druid.Restoration] = {
			[740] = {		-- Tranquility
				name		= "Tranquility",
				spellId 	= 740,
				cooldown 	= 180,
				duration	= 8,
				level		= 80,
				modifiers	= {
					-- Inner Peace talent - Reduce the cooldown by 60 seconds
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 6, 2) then return spell.cooldown - 60 else return spell.cooldown end end
				}
			},
			[102342] = {	-- Ironbark
				name		= "Ironbark",
				spellId 	= 102342,
				cooldown 	= 90,
				duration	= 12,
				level		= 54,
				modifiers	= {
					-- Stonebark talent - Reduce the cooldown by 30 seconds
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 7, 2) then return spell.cooldown - 30 else return spell.cooldown end end
				}
			},
			[208253] = {	-- Essence of G'Hanir
				name		= "Essence of G'Hanir",
				spellId 	= 208253,
				cooldown 	= 90,
				duration	= 8,
				level		= 98
			},
			[33891] = {		-- Incarnation: Tree of Life
				name		= "Incarnation: Tree of Life",
				spellId 	= 33891,
				cooldown 	= 180,
				duration	= 30,
				level		= 75,
				talents		= { { tier=5, column=2 } }
			},
			-- [108238] = {	-- Renewal
			-- 	name		= "Renewal",
			-- 	spellId 	= 108238,
			-- 	cooldown 	= 90,
			-- 	level		= 30,
			-- 	talents		= { { tier=2, column=1 } }
			-- },
			[29166] = {		-- Innervate
				name		= "Innervate",
				spellId 	= 29166,
				cooldown 	= 180,
				duration	= 10,
				level		= 50
			}
		}
	},
	[RCT.classes.DeathKnight] = {
		[RCT.specs.DeathKnight.Blood] = {			
		},
		[RCT.specs.DeathKnight.Frost] = {			
		},
		[RCT.specs.DeathKnight.Unholy] = {			
		}
	},
	[RCT.classes.Hunter] = {
		[RCT.specs.Hunter.BeastMastery] = {
		},
		[RCT.specs.Hunter.Marksman] = {
		},
		[RCT.specs.Hunter.Survival] = {
		}
	},
	[RCT.classes.Priest] = {
		[RCT.specs.Priest.Discipline] = {
		},
		[RCT.specs.Priest.Holy] = {
			[47788] = {		-- Guardian Spirit
				name		= "Guardian Spirit",
				spellId 	= 47788,
				cooldown 	= 240,
				duration	= 10,
				level		= 48
			},
			-- [19236] = {		-- Desperate Prayer
			-- 	name		= "Desperate Prayer",
			-- 	spellId 	= 19236,
			-- 	cooldown 	= 90,
			-- 	duration	= 10,
			-- 	level		= 52
			-- },
			[64843] = {		-- Divine Hymn
				name		= "Divine Hymn",
				spellId 	= 64843,
				cooldown 	= 180,
				duration	= 8,
				level		= 70
			},
			[200183] = {	-- Apotheosis
				name		= "Apotheosis",
				spellId 	= 200183,
				cooldown 	= 180,
				duration	= 30,
				level		= 100,
				talents		= { { tier=7, column=1 } }
			},
			[73325] = {		-- Leap of Faith
				name		= "Leap of Faith",
				spellId 	= 73325,
				cooldown 	= 90,
				level		= 63
			}
		},
		[RCT.specs.Priest.Shadow] = {
		}
	},
	[RCT.classes.Rogue] = {
		[RCT.specs.Rogue.Assassination] = {
		},
		[RCT.specs.Rogue.Combat] = {
		},
		[RCT.specs.Rogue.Subtlety] = {
		}
	},
	[RCT.classes.Shaman] = {
		[RCT.specs.Shaman.Elemental] = {
		},
		[RCT.specs.Shaman.Enhancement] = {
		},
		[RCT.specs.Shaman.Restoration] = {
		}
	},
	[RCT.classes.Warlock] = {
		[RCT.specs.Warlock.Affliction] = {
		},
		[RCT.specs.Warlock.Demonology] = {
		},
		[RCT.specs.Warlock.Destruction] = {
		}
	},
	[RCT.classes.Monk] = {
		[RCT.specs.Monk.Brewmaster] = {
		},
		[RCT.specs.Monk.Windwalker] = {
		},
		[RCT.specs.Monk.Mistweaver] = {
		}
	},
	[RCT.classes.DemonHunter] = {
		[RCT.specs.DemonHunter.Havoc] = {
		},
		[RCT.specs.DemonHunter.Vengeance] = {
		}
	}
}
