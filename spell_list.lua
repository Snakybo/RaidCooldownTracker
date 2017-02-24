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

RCT.categories = {
	Healing		= 1,
	Utility		= 2,
	BRez		= 4,
	Defensive	= 8,
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
				cooldown 	= 180,
				duration 	= 8,
				level		= 70,
				category	= RCT.categories.Healing
			},
			[31842] = {		-- Avenging Wrath
				cooldown	= 120,
				duration	= 20,
				level		= 80,
				category	= RCT.categories.Healing,
				modifiers	= {
					-- Sanctified Wrath talent - Increase duration by 25%
					duration	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 6, 2) then return spell.duration * 1.25 else return spell.duration end end
				}
			},
			[105809] = {	-- Holy Avenger
				cooldown	= 90,
				duration	= 20,
				level		= 75,
				category	= RCT.categories.Healing,
				talents		= { { tier=5, column=2 } }
			},
			[200652] = {	-- Tyr's Deliverance
				cooldown	= 90,
				duration	= 10,
				level		= 98,
				category	= RCT.categories.Healing
			},
			[633] = {		-- Lay on Hands
				cooldown	= 420,
				level		= 55,
				category	= RCT.categories.Utility,
				modifiers	= {
					-- Unbreakable Spirit talent - Reduce cooldown by 30%
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 2, 2) then return spell.cooldown * 0.7 else return spell.cooldown end end
				}
			},
			[1022] = {		-- Blessing of Protection
				cooldown	= 255,
				duration	= 10,
				level		= 48,
				category	= RCT.categories.Utility,
			},
			[6940] = {		-- Blessing of Sacrifice
				cooldown	= 204,
				duration	= 12,
				level		= 56,
				category	= RCT.categories.Utility
			},
			[642] = {		-- Divine Shield
				cooldown 	= 300,
				duration 	= 8,
				level		= 18,
				category	= RCT.categories.Defensive,
				modifiers	= {
					-- Unbreakable Spirit talent - Reduce cooldown by 30%
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 2, 2) then return spell.cooldown * 0.7 else return spell.cooldown end end
				}
			},
		},
		[RCT.specs.Paladin.Protection] = {
			[31850] = {		-- Ardent Defender
				cooldown 	= 90,
				duration 	= 8,
				level		= 50,
				category	= RCT.categories.Defensive,
			},
			[204018] = {	-- Blessing of Spellwarding
				cooldown 	= 180,
				duration 	= 10,
				level		= 60,
				category	= RCT.categories.Utility,
				talents		= { { tier=4, column=1 } }
			},
			[1022] = {		-- Blessing of Protection
				cooldown 	= 300,
				duration 	= 10,
				level		= 48,
				category	= RCT.categories.Utility,
				talents		= { { tier=4, column=2 }, { tier=4, column=3 } }
			},
			[6940] = {		-- Blessing of Sacrifice
				cooldown 	= 90,
				duration 	= 12,
				level		= 56,
				category	= RCT.categories.Utility
			},
			[642] = {		-- Divine Shield
				cooldown 	= 300,
				duration 	= 8,
				level		= 18,
				category	= RCT.categories.Defensive
			},
			[633] = {		-- Lay on Hands
				cooldown 	= 600,
				level		= 55,
				category	= RCT.categories.Utility
			},
			[212641] = {	-- Guardian of Ancient Kings
				cooldown 	= 300,
				duration	= 8,
				level		= 72,
				category	= RCT.categories.Defensive
			}
		},
		[RCT.specs.Paladin.Retribution] = {
			[642] = {		-- Divine Shield
				cooldown 	= 300,
				duration 	= 8,
				level		= 18,
				category	= RCT.categories.Defensive,
				modifiers	= {
					-- Divine Intervention talent - Reduce cooldown by 20%
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 6, 1) then return spell.cooldown * 0.8 else return spell.cooldown end end
				}
			},
			[1022] = {		-- Blessing of Protection
				cooldown 	= 210,
				duration 	= 10,
				level		= 48,
				category	= RCT.categories.Utility,
			},
			[633] = {		-- Lay on Hands
				cooldown 	= 600,
				level		= 55,
				category	= RCT.categories.Utility
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
				cooldown 	= 180,
				duration	= 10,
				level		= 80,
				category	= RCT.categories.Utility
			}
		},
		[RCT.specs.Warrior.Protection] = {
		}
	},
	[RCT.classes.Druid] = {
		[RCT.specs.Druid.Balance] = {
			[29166] = {		-- Innervate
				cooldown 	= 180,
				duration	= 10,
				level		= 50,
				category	= RCT.categories.Utility
			}		
		},
		[RCT.specs.Druid.Feral] = {			
		},
		[RCT.specs.Druid.Guardian] = {			
		},
		[RCT.specs.Druid.Restoration] = {
			[740] = {		-- Tranquility
				cooldown 	= 180,
				duration	= 8,
				level		= 80,
				category	= RCT.categories.Healing,
				modifiers	= {
					-- Inner Peace talent - Reduce the cooldown by 60 seconds
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 6, 2) then return spell.cooldown - 60 else return spell.cooldown end end
				}
			},
			[102342] = {	-- Ironbark
				cooldown 	= 90,
				duration	= 12,
				level		= 54,
				category	= RCT.categories.Utility,
				modifiers	= {
					-- Stonebark talent - Reduce the cooldown by 30 seconds
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 7, 2) then return spell.cooldown - 30 else return spell.cooldown end end
				}
			},
			[208253] = {	-- Essence of G'Hanir
				cooldown 	= 90,
				duration	= 8,
				level		= 98,
				category	= RCT.categories.Healing
			},
			[33891] = {		-- Incarnation: Tree of Life
				cooldown 	= 180,
				duration	= 30,
				level		= 75,
				category	= RCT.categories.Healing,
				talents		= { { tier=5, column=2 } }
			},
			[108238] = {	-- Renewal
				cooldown 	= 90,
				level		= 30,
				category	= RCT.categories.Defensive,
				talents		= { { tier=2, column=1 } }
			},
			[29166] = {		-- Innervate
				cooldown 	= 180,
				duration	= 10,
				level		= 50,
				category	= RCT.categories.Utility
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
			[73325] = {		-- Leap of Faith
				cooldown 	= 90,
				level		= 63,
				category	= RCT.categories.Utility
			},
			[62618] = {		-- Power Word: Barrier
				cooldown 	= 300,
				duration	= 10,
				level		= 70,
				category	= RCT.categories.Utility
			},
			[47536] = {		-- Rapture
				cooldown 	= 120,
				duration	= 11,
				level		= 50,
				category	= RCT.categories.Utility
			},
			[207946] = {	-- Light's Wrath
				cooldown 	= 120,
				level		= 98,
				category	= RCT.categories.Utility
			}
		},
		[RCT.specs.Priest.Holy] = {
			[47788] = {		-- Guardian Spirit
				cooldown 	= 240,
				duration	= 10,
				level		= 48,
				category	= RCT.categories.Healing
			},
			[19236] = {		-- Desperate Prayer
				cooldown 	= 90,
				duration	= 10,
				level		= 52,
				category	= RCT.categories.Defensive
			},
			[64843] = {		-- Divine Hymn
				cooldown 	= 180,
				duration	= 8,
				level		= 70,
				category	= RCT.categories.Healing
			},
			[200183] = {	-- Apotheosis
				cooldown 	= 180,
				duration	= 30,
				level		= 100,
				category	= RCT.categories.Healing,
				talents		= { { tier=7, column=1 } }
			},
			[73325] = {		-- Leap of Faith
				cooldown 	= 90,
				level		= 63,
				category	= RCT.categories.Utility
			},
			[64901] = {	-- Symbol of Hope
				cooldown 	= 360,
				duration	= 12,
				level		= 100,
				category	= RCT.categories.Utility,
				talents		= { { tier=4, column=3 } }
			}
		},
		[RCT.specs.Priest.Shadow] = {
			[15286] = {	-- Vampiric Embrace
				cooldown 	= 300,
				duration	= 15,
				level		= 70,
				category	= RCT.categories.Utility
			}
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
			[108281] = {	-- Ancestral Guidance
				cooldown 	= 120,
				duration 	= 10,
				level		= 30,
				category	= RCT.categories.Healing,
				talents		= { { tier=2, column=2 } }
			},
		},
		[RCT.specs.Shaman.Enhancement] = {
		},
		[RCT.specs.Shaman.Restoration] = {
			[207778] = {	-- Gift of the Queen
				cooldown 	= 45,
				duration 	= 6,
				level		= 98,
				category	= RCT.categories.Healing
			},
			[108280] = {	-- Healing Tide Totem
				cooldown 	= 180,
				duration 	= 10,
				level		= 80,
				category	= RCT.categories.Healing
			},
			[98008] = {		-- Spirit Link Totem
				cooldown 	= 120,
				duration 	= 6,
				level		= 56,
				category	= RCT.categories.Healing
			},
			[79206] = {		-- Spiritwalker's Grace
				cooldown 	= 120,
				duration 	= 15,
				level		= 36,
				category	= RCT.categories.Utility,
				modifiers	= {
					-- Graceful Spirit talent - Reduce the cooldown by 60 seconds
					cooldown	= function(playerHandle, spell) if RCT:PlayerHasTalentSelected(playerHandle, 2, 2) then return spell.cooldown - 60 else return spell.cooldown end end
				}
			},
			[114052] = {	-- Ascendance
				cooldown 	= 180,
				duration 	= 15,
				level		= 100,
				category	= RCT.categories.Healing,
				talents		= { { tier=7, column=1 } }
			},
			[207399] = {	-- Ancestral Protection Totem
				cooldown 	= 300,
				duration 	= 30,
				level		= 75,
				category	= RCT.categories.Healing,
				talents		= { { tier=5, column=1 } }
			},
			[108281] = {	-- Ancestral Guidance
				cooldown 	= 120,
				duration 	= 10,
				level		= 60,
				category	= RCT.categories.Healing,
				talents		= { { tier=4, column=2 } }
			},
			[192077] = {	-- Wind Rush Totem
				cooldown 	= 120,
				duration 	= 15,
				level		= 60,
				category	= RCT.categories.Utility,
				talents		= { { tier=2, column=3 } }
			},
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
			[198664] = {	-- Invoke Chi-Ji, the Red Crane
				cooldown 	= 180,
				duration 	= 45,
				level		= 90,
				category	= RCT.categories.Healing,
				talents		= { { tier=6, column=2 } }
			},
			[116849] = {	-- Life Cocoon
				cooldown 	= 180,
				duration 	= 12,
				level		= 35,
				category	= RCT.categories.Healing
			},
			[116849] = {	-- Revival
				cooldown 	= 180,
				level		= 70,
				category	= RCT.categories.Healing
			},
			[122278] = {	-- Dampen Harm
				cooldown 	= 120,
				level		= 75,
				category	= RCT.categories.Defensive
			},
			[197908] = {	-- Mana Tea
				cooldown 	= 120,
				duration 	= 10,
				level		= 100,
				category	= RCT.categories.Utility,
				talents		= { { tier=7, column=1 } }
			}
		}
	},
	[RCT.classes.DemonHunter] = {
		[RCT.specs.DemonHunter.Havoc] = {
		},
		[RCT.specs.DemonHunter.Vengeance] = {
		}
	}
}
