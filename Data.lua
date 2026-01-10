-- ============================================================================
-- Turtle Dungeon Timer - Dungeon and Raid Data
-- ============================================================================

TurtleDungeonTimer.DUNGEON_DATA = {
    ["Black Morass"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = {"Chronar", "Epidamu", "Drifting Avatar of Sand", "Time-Lord Epochronos", "Mossheart", "Antnormi", "Rotmaw"}
            }
        }
    },
    ["Stormwind Vault"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = {"Aszosh Grimflame", "Tham'Grarr", "Black Bride", "Damian", "Volkan Cruelblade", "Arc'tiras"}
            }
        }
    },
    ["Stratholme"] = {
        isDungeon = true,
        variants = {
            -- ["Living"] = {
            --     bosses = {"Timmy the Cruel", "Malor the Zealous", "Cannon Master Willey", "Archivist Galford", "Balnazzar"},
            --     optionalBosses = {
            --         ["Hearthsinger Forresten"] = true -- Rare
            --     }
            -- },
            ["Undead"] = {
                bosses = {"Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Magistrate Barthilas", "Ramstein the Gorger", "Baron Rivendare"},
                optionalBosses = {                    
                    ["Stonespine"] = true -- Rare
                }
            }
        }
    },
    ["Dire Maul"] = {
        isDungeon = true,
        variants = {
            -- ["East"] = {
            --     bosses = {"Pusillin", "Zevrim Thornhoof", "Hydrospawn", "Lethtendris", "Alzzin the Wildshaper"}
            -- },
            ["West"] = {
                bosses = {"Tendris Warpwood", "Illyanna Ravenoak", "Magister Kalendris", "Immol'thar", "Prince Tortheldrin"},
                optionalBosses = {
                    ["Tsu'zee"] = true, -- Rare
                    ["Lord Hel'nurath"] = true -- Rare
                }
            },
            -- ["North"] = {
            --     bosses = {"Guard Mol'dar", "Stomper Kreeg", "Guard Fengus", "Guard Slip'kik", "Captain Kromcrush", "Cho'Rush the Observer", "King Gordok"}
            -- }
        }
    },
    ["Upper Blackrock Spire"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = {"Pyroguard Emberseer", "Solakar Flamewreath", "Warchief Rend Blackhand", "The Beast", "General Drakkisath"},
                optionalBosses = {
                    ["Jed Runewatcher"] = true, -- Rare
                    ["Goraluk Anvilcrack"] = true -- Rare
                }
            }
        }
    },
    ["Zul'Gurub"] = {
        isDungeon = false, -- 20-man raid
        variants = {
            ["Default"] = {
                bosses = {
                    "High Priestess Jeklik",
                    "High Priest Venoxis",
                    "High Priestess Mar'li",
                    "Bloodlord Mandokir",
                    "High Priest Thekal",
                    "High Priestess Arlokk",
                    "Jin'do the Hexxer",
                    "Hakkar the Soulflayer"
                },
                optionalBosses = {
                    ["Gahz'ranka"] = true -- Summoned hydra boss
                }
            }
        }
    },
    ["The Stockade"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = {"Targorr the Dread", "Kam Deepfury", "Hamhock", "Bazil Thredd", "Dextren Ward"},
                optionalBosses = {
                    ["Bruegal Ironknuckle"] = true -- Rare
                }
            }
        },
        trashMobs = {
            {name = "Defias Captive", hp = 2323, count = 7},
            {name = "Defias Inmate", hp = 2323, count = 21},
            {name = "Defias Prisoner", hp = 2160, count = 7},
            {name = "Defias Prisoner", hp = 2323, count = 6},
            {name = "Defias Captive", hp = 2160, count = 11},            
            {name = "Defias Convict", hp = 2323, count = 7},
            {name = "Defias Convict", hp = 2495, count = 6},
            {name = "Defias Inmate", hp = 2495, count = 15},
            {name = "Defias Insurgent", hp = 2495, count = 5},            
            {name = "Defias Insurgent", hp = 2677, count = 5},
        },
        totalTrashHP = 212378,  -- Total: (2323*7 + 2323*21 + 2160*7 + 2160*11 + 2323*6 + 2323*7 + 2495*15 + 2495*5 + 2495*6 + 2677*5)
        trashRequiredPercent = 50  -- 50% for testing, normally 80-100%
    }
    -- -- CLASSIC DUNGEONS
    -- ["Ragefire Chasm"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Taragaman the Hungerer", "Jergosh the Invoker"}
    --         }
    --     }
    -- },
    -- ["Wailing Caverns"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Lady Anacondra", "Lord Cobrahn", "Lord Pythas", "Lord Serpentis", "Skum", "Verdan the Everliving", "Mutanus the Devourer"},
    --             optionalBosses = {
    --                 ["Trigore the Lasher"] = true, -- Rare
    --                 ["Boahn"] = true, -- Rare
    --                 ["Deviate Faerie Dragon"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["The Deadmines"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Rhahk'Zor", "Sneed", "Gilnid", "Mr. Smite", "Captain Greenskin", "Edwin VanCleef"},
    --             optionalBosses = {
    --                 ["Marisa du'Paige"] = true, -- Rare
    --                 ["Brainwashed Noble"] = true, -- Rare
    --                 ["Miner Johnson"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Shadowfang Keep"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Rethilgore", "Razorclaw the Butcher", "Baron Silverlaine", "Commander Springvale", "Odo the Blindwatcher", "Fenrus the Devourer", "Wolf Master Nandos", "Archmage Arugal"},
    --             optionalBosses = {
    --                 ["Deathsworn Captain"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Blackfathom Deeps"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Ghamoo-ra", "Lady Sarevess", "Gelihast", "Lorgus Jett", "Baron Aquanis", "Twilight Lord Kelris", "Old Serra'kis", "Aku'mai"}
    --         }
    --     }
    -- },
    -- ["The Stockade"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Targorr the Dread", "Kam Deepfury", "Hamhock", "Bazil Thredd", "Bruegal Ironknuckle", "Dextren Ward"},
    --             -- Optionale Bosse (Rare Spawns)
    --             optionalBosses = {
    --                 ["Kam Deepfury"] = true,
    --                 ["Bruegal Ironknuckle"] = true
    --             }
    --         }
    --     }
    -- },
    -- ["Gnomeregan"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Grubbis", "Viscous Fallout", "Electrocutioner 6000", "Crowd Pummeler 9-60", "Mekgineer Thermaplugg"},
    --             optionalBosses = {
    --                 ["Dark Iron Ambassador"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Razorfen Kraul"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Roogug", "Aggem Thorncurse", "Death Speaker Jargba", "Overlord Ramtusk", "Agathelos the Raging", "Charlga Razorflank"},
    --             optionalBosses = {
    --                 ["Razorfen Spearhide"] = true, -- Rare
    --                 ["Blind Hunter"] = true, -- Rare
    --                 ["Earthcaller Halmgar"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Scarlet Monastery"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Graveyard"] = {
    --             bosses = {"Interrogator Vishas", "Bloodmage Thalnos"},
    --             optionalBosses = {
    --                 ["Ironspine"] = true, -- Rare
    --                 ["Azshir the Sleepless"] = true, -- Rare
    --                 ["Fallen Champion"] = true -- Rare
    --             }
    --         },
    --         ["Library"] = {
    --             bosses = {"Houndmaster Loksey", "Arcanist Doan"}
    --         },
    --         ["Armory"] = {
    --             bosses = {"Herod"}
    --         },
    --         ["Cathedral"] = {
    --             bosses = {"High Inquisitor Fairbanks", "Scarlet Commander Mograine", "High Inquisitor Whitemane"}
    --         }
    --     }
    -- },
    -- ["Razorfen Downs"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Tuten'kash", "Mordresh Fire Eye", "Glutton", "Amnennar the Coldbringer"},
    --             optionalBosses = {
    --                 ["Ragglesnout"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Uldaman"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Revelosh", "The Lost Dwarves", "Ironaya", "Obsidian Sentinel", "Ancient Stone Keeper", "Galgann Firehammer", "Grimlok", "Archaedas"},
    --             optionalBosses = {
    --                 ["Digmaster Shovelphlange"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Zul'Farrak"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Gahz'rilla", "Antu'sul", "Theka the Martyr", "Witch Doctor Zum'rah", "Nekrum Gutchewer", "Shadowpriest Sezz'ziz", "Chief Ukorz Sandscalp"},
    --             optionalBosses = {
    --                 ["Dustwraith"] = true, -- Rare
    --                 ["Zerillis"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Maraudon"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Purple"] = {
    --             bosses = {"Noxxion", "Razorlash", "Lord Vyletongue", "Celebras the Cursed"},
    --             optionalBosses = {
    --                 ["Meshlok the Harvester"] = true -- Rare
    --             }
    --         },
    --         ["Orange"] = {
    --             bosses = {"Landslide", "Tinkerer Gizlock", "Celebras the Cursed"},
    --             optionalBosses = {
    --                 ["Meshlok the Harvester"] = true -- Rare
    --             }
    --         },
    --         ["Full"] = {
    --             bosses = {"Noxxion", "Razorlash", "Lord Vyletongue", "Landslide", "Tinkerer Gizlock", "Celebras the Cursed", "Princess Theradras"},
    --             optionalBosses = {
    --                 ["Meshlok the Harvester"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Temple of Atal'Hakkar"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Avatar of Hakkar", "Jammal'an the Prophet", "Wardens of the Dream", "Shade of Eranikus"}
    --         }
    --     }
    -- },
    -- ["Blackrock Depths"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Prison"] = {
    --             bosses = {"High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law"},
    --             optionalBosses = {
    --                 ["Pyromancer Loregrain"] = true, -- Rare
    --                 ["Warder Stilgiss"] = true, -- Rare
    --                 ["Verek"] = true -- Rare
    --             }
    --         },
    --         ["Upper"] = {
    --             bosses = {"General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan"},
    --             optionalBosses = {
    --                 ["Panzor the Invincible"] = true -- Rare
    --             }
    --         },
    --         ["Full"] = {
    --             bosses = {"High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law", "Lord Incendius", "Fineous Darkvire", "Bael'Gar", "General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan"},
    --             optionalBosses = {
    --                 ["Pyromancer Loregrain"] = true, -- Rare
    --                 ["Warder Stilgiss"] = true, -- Rare
    --                 ["Verek"] = true, -- Rare
    --                 ["Panzor the Invincible"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    -- ["Lower Blackrock Spire"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mother Smolderweb", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Gizrul the Slavener", "Overlord Wyrmthalak"},
    --             optionalBosses = {
    --                 ["Mor Grayhoof"] = true, -- Rare
    --                 ["Spirestone Butcher"] = true, -- Rare
    --                 ["Spirestone Battle Lord"] = true, -- Rare
    --                 ["Spirestone Lord Magus"] = true, -- Rare
    --                 ["Bannok Grimaxe"] = true, -- Rare
    --                 ["Crystal Fang"] = true, -- Rare
    --                 ["Ghok Bashguud"] = true, -- Rare
    --                 ["Burning Felguard"] = true -- Rare
    --             }
    --         }
    --     }
    -- },
    


    -- ["Scholomance"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Kirtonos the Herald", "Jandice Barov", "Rattlegore", "Marduk Blackpool", "Vectus", "Ras Frostwhisper", "Instructor Malicia", "Doctor Theolen Krastinov", "Lorekeeper Polkelt", "The Ravenian", "Lord Alexei Barov", "Lady Illucia Barov", "Darkmaster Gandling"}
    --         }
    --     }
    -- },
    
    -- -- TURTLE WOW CUSTOM DUNGEONS
    -- ["The Crescent Grove"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Grovetender Engryss", "Keeper Ranathos", "High Priestess A'lathea", "Fenektis the Deceiver", "Master Raxxieth"}
    --         }
    --     }
    -- },
    -- ["Dragonmaw Retreat"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Gowlfang", "Cavernweb Broodmother", "Web Master Torkon", "Garlok Flamekeeper", "Halgan Redbrand", "Slagfist Destroyer", "Overlord Blackheart", "Elder Hollowblood", "Searistrasz", "Zuluhed the Whacked"}
    --         }
    --     }
    -- },
    -- ["Gilneas City"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Genn Greymane"}
    --         }
    --     }
    -- },
    -- ["Hateforge Quarry"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Har'gesh Doomcaller"}
    --         }
    --     }
    -- },
    -- ["Karazhan Crypt"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Alarus"}
    --         }
    --     }
    -- },
    
    -- ["Stormwrought Ruins"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Oronok Torn-Heart", "Dagar the Glutton", "Librarian Theodorus", "Duke Balor the IV", "Chieftain Stormsong", "Deathlord Tidebane", "Subjugator Halthas Shadecrest", "Mycellakos", "Eldermaw the Primordial", "Lady Drazare", "Ighal'for", "Mergothid"}
    --         }
    --     }
    -- },
    -- ["Windhorn Canyon"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"TODO"} -- Need boss data
    --         }
    --     }
    -- },
    
    -- -- RAIDS
    -- ["Molten Core"] = {
    --     isRaid = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah", "Baron Geddon", "Sulfuron Harbinger", "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros"}
    --         }
    --     }
    -- },
    -- ["Onyxia's Lair"] = {
    --     isRaid = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Onyxia"}
    --         }
    --     }
    -- },
    -- ["Blackwing Lair"] = {
    --     isRaid = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer", "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", "Nefarian"}
    --         }
    --     }
    -- },
    -- ["Zul'Gurub"] = {
    --     isRaid = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li", "Bloodlord Mandokir", "Edge of Madness", "High Priest Thekal", "High Priestess Arlokk", "Jin'do the Hexxer", "Hakkar"}
    --         }
    --     }
    -- },
    -- ["Ruins of Ahn'Qiraj"] = {
    --     isRaid = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Kurinnaxx", "General Rajaxx", "Moam", "Buru the Gorger", "Ayamiss the Hunter", "Ossirian the Unscarred"}
    --         }
    --     }
    -- },
    -- ["Temple of Ahn'Qiraj"] = {
    --     isRaid = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"The Prophet Skeram", "Bug Trio", "Battleguard Sartura", "Fankriss the Unyielding", "Viscidus", "Princess Huhuran", "Twin Emperors", "Ouro", "C'Thun"}
    --         }
    --     }
    -- },
    -- ["Naxxramas"] = {
    --     isRaid = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = {"Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", "Instructor Razuvious", "Gothik the Harvester", "The Four Horsemen", "Patchwerk", "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad"}
    --         }
    --     }
    -- }
}
