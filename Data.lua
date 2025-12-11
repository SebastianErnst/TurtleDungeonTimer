-- ============================================================================
-- Turtle Dungeon Timer - Dungeon and Raid Data
-- ============================================================================

TurtleDungeonTimer.DUNGEON_DATA = {
    -- TEST MODES
    ["!Test Mode"] = {
        variants = {
            ["Default"] = {
                bosses = {"Deeprun Rat", "Deeprun Rat", "Deeprun Rat"}
            }
        }
    },
    ["!Test Mode - Long"] = {
        variants = {
            ["Default"] = {
                bosses = {"Deeprun Rat", "Deeprun Rat", "Deeprun Rat", "Deeprun Rat", "Deeprun Rat", "Deeprun Rat", "Deeprun Rat", "Deeprun Rat", "Deeprun Rat", "Deeprun Rat"}
            }
        }
    },
    
    -- CLASSIC DUNGEONS
    ["Ragefire Chasm"] = {
        variants = {
            ["Default"] = {
                bosses = {"Taragaman the Hungerer", "Jergosh the Invoker"}
            }
        }
    },
    ["Wailing Caverns"] = {
        variants = {
            ["Default"] = {
                bosses = {"Lady Anacondra", "Lord Cobrahn", "Lord Pythas", "Lord Serpentis", "Skum", "Verdan the Everliving", "Mutanus the Devourer"}
            }
        }
    },
    ["The Deadmines"] = {
        variants = {
            ["Default"] = {
                bosses = {"Rhahk'Zor", "Sneed", "Gilnid", "Mr. Smite", "Captain Greenskin", "Edwin VanCleef"}
            }
        }
    },
    ["Shadowfang Keep"] = {
        variants = {
            ["Default"] = {
                bosses = {"Rethilgore", "Razorclaw the Butcher", "Baron Silverlaine", "Commander Springvale", "Odo the Blindwatcher", "Fenrus the Devourer", "Wolf Master Nandos", "Archmage Arugal"}
            }
        }
    },
    ["Blackfathom Deeps"] = {
        variants = {
            ["Default"] = {
                bosses = {"Ghamoo-ra", "Lady Sarevess", "Gelihast", "Lorgus Jett", "Baron Aquanis", "Twilight Lord Kelris", "Old Serra'kis", "Aku'mai"}
            }
        }
    },
    ["The Stockade"] = {
        variants = {
            ["Default"] = {
                bosses = {"Targorr the Dread", "Kam Deepfury", "Hamhock", "Bazil Thredd", "Dextren Ward"}
            }
        }
    },
    ["Gnomeregan"] = {
        variants = {
            ["Default"] = {
                bosses = {"Grubbis", "Viscous Fallout", "Electrocutioner 6000", "Crowd Pummeler 9-60", "Mekgineer Thermaplugg"}
            }
        }
    },
    ["Razorfen Kraul"] = {
        variants = {
            ["Default"] = {
                bosses = {"Roogug", "Aggem Thorncurse", "Death Speaker Jargba", "Overlord Ramtusk", "Agathelos the Raging", "Charlga Razorflank"}
            }
        }
    },
    ["Scarlet Monastery"] = {
        variants = {
            ["Graveyard"] = {
                bosses = {"Interrogator Vishas", "Bloodmage Thalnos", "Ironspine", "Azshir the Sleepless", "Fallen Champion"}
            },
            ["Library"] = {
                bosses = {"Houndmaster Loksey", "Arcanist Doan"}
            },
            ["Armory"] = {
                bosses = {"Herod"}
            },
            ["Cathedral"] = {
                bosses = {"High Inquisitor Fairbanks", "Scarlet Commander Mograine", "High Inquisitor Whitemane"}
            }
        }
    },
    ["Razorfen Downs"] = {
        variants = {
            ["Default"] = {
                bosses = {"Tuten'kash", "Mordresh Fire Eye", "Glutton", "Amnennar the Coldbringer"}
            }
        }
    },
    ["Uldaman"] = {
        variants = {
            ["Default"] = {
                bosses = {"Revelosh", "The Lost Dwarves", "Ironaya", "Obsidian Sentinel", "Ancient Stone Keeper", "Galgann Firehammer", "Grimlok", "Archaedas"}
            }
        }
    },
    ["Zul'Farrak"] = {
        variants = {
            ["Default"] = {
                bosses = {"Gahz'rilla", "Antu'sul", "Theka the Martyr", "Witch Doctor Zum'rah", "Nekrum Gutchewer", "Shadowpriest Sezz'ziz", "Chief Ukorz Sandscalp"}
            }
        }
    },
    ["Maraudon"] = {
        variants = {
            ["Purple"] = {
                bosses = {"Noxxion", "Razorlash", "Lord Vyletongue", "Celebras the Cursed"}
            },
            ["Orange"] = {
                bosses = {"Landslide", "Tinkerer Gizlock", "Celebras the Cursed"}
            },
            ["Full"] = {
                bosses = {"Noxxion", "Razorlash", "Lord Vyletongue", "Landslide", "Tinkerer Gizlock", "Celebras the Cursed", "Princess Theradras"}
            }
        }
    },
    ["Temple of Atal'Hakkar"] = {
        variants = {
            ["Default"] = {
                bosses = {"Avatar of Hakkar", "Jammal'an the Prophet", "Wardens of the Dream", "Shade of Eranikus"}
            }
        }
    },
    ["Blackrock Depths"] = {
        variants = {
            ["Prison"] = {
                bosses = {"High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law", "Pyromancer Loregrain"}
            },
            ["Upper"] = {
                bosses = {"General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan"}
            },
            ["Full"] = {
                bosses = {"High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law", "Pyromancer Loregrain", "Lord Incendius", "Fineous Darkvire", "Bael'Gar", "General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan"}
            }
        }
    },
    ["Lower Blackrock Spire"] = {
        variants = {
            ["Default"] = {
                bosses = {"Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mor Grayhoof", "Mother Smolderweb", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Gizrul the Slavener", "Overlord Wyrmthalak"}
            }
        }
    },
    ["Upper Blackrock Spire"] = {
        variants = {
            ["Default"] = {
                bosses = {"Pyroguard Emberseer", "Solakar Flamewreath", "Jed Runewatcher", "Goraluk Anvilcrack", "Warchief Rend Blackhand", "The Beast", "General Drakkisath"}
            }
        }
    },
    ["Dire Maul"] = {
        variants = {
            ["East"] = {
                bosses = {"Pusillin", "Zevrim Thornhoof", "Hydrospawn", "Lethtendris", "Alzzin the Wildshaper"}
            },
            ["West"] = {
                bosses = {"Tendris Warpwood", "Illyanna Ravenoak", "Magister Kalendris", "Tsu'zee", "Immol'thar", "Prince Tortheldrin"}
            },
            ["North"] = {
                bosses = {"Guard Mol'dar", "Stomper Kreeg", "Guard Fengus", "Guard Slip'kik", "Captain Kromcrush", "Cho'Rush the Observer", "King Gordok"}
            }
        }
    },
    ["Stratholme"] = {
        variants = {
            ["Living"] = {
                bosses = {"Hearthsinger Forresten", "Timmy the Cruel", "Malor the Zealous", "Cannon Master Willey", "Archivist Galford", "Balnazzar", "Aurius", "The Unforgiven", "Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Magistrate Barthilas", "Ramstein the Gorger", "Baron Rivendare"}
            },
            ["Undead"] = {
                bosses = {"The Unforgiven", "Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Magistrate Barthilas", "Ramstein the Gorger", "Baron Rivendare"}
            }
        }
    },
    ["Scholomance"] = {
        variants = {
            ["Default"] = {
                bosses = {"Kirtonos the Herald", "Jandice Barov", "Rattlegore", "Marduk Blackpool", "Vectus", "Ras Frostwhisper", "Instructor Malicia", "Doctor Theolen Krastinov", "Lorekeeper Polkelt", "The Ravenian", "Lord Alexei Barov", "Lady Illucia Barov", "Darkmaster Gandling"}
            }
        }
    },
    
    -- RAIDS
    ["Molten Core"] = {
        variants = {
            ["Default"] = {
                bosses = {"Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah", "Baron Geddon", "Sulfuron Harbinger", "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros"}
            }
        }
    },
    ["Onyxia's Lair"] = {
        variants = {
            ["Default"] = {
                bosses = {"Onyxia"}
            }
        }
    },
    ["Blackwing Lair"] = {
        variants = {
            ["Default"] = {
                bosses = {"Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer", "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", "Nefarian"}
            }
        }
    },
    ["Zul'Gurub"] = {
        variants = {
            ["Default"] = {
                bosses = {"High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li", "Bloodlord Mandokir", "Edge of Madness", "High Priest Thekal", "High Priestess Arlokk", "Jin'do the Hexxer", "Hakkar"}
            }
        }
    },
    ["Ruins of Ahn'Qiraj"] = {
        variants = {
            ["Default"] = {
                bosses = {"Kurinnaxx", "General Rajaxx", "Moam", "Buru the Gorger", "Ayamiss the Hunter", "Ossirian the Unscarred"}
            }
        }
    },
    ["Temple of Ahn'Qiraj"] = {
        variants = {
            ["Default"] = {
                bosses = {"The Prophet Skeram", "Bug Trio", "Battleguard Sartura", "Fankriss the Unyielding", "Viscidus", "Princess Huhuran", "Twin Emperors", "Ouro", "C'Thun"}
            }
        }
    },
    ["Naxxramas"] = {
        variants = {
            ["Default"] = {
                bosses = {"Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", "Instructor Razuvious", "Gothik the Harvester", "The Four Horsemen", "Patchwerk", "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad"}
            }
        }
    }
}
