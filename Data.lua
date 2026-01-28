-- ============================================================================
-- Turtle Dungeon Timer - Dungeon and Raid Data
-- ============================================================================

TurtleDungeonTimer.DUNGEON_DATA = {
    ["Stormwind Vault"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = { "Aszosh Grimflame", "Tham'Grarr", "Black Bride", "Damian", "Volkan Cruelblade", "Arc'tiras" },
                trashMobs = {
                    { name = "Black Blood of the Dragonmaw", hp = 13115, count = 9 }, -- 118035
                    { name = "Grellkin Scorcher",            hp = 12378, count = 19 }, -- 235182
                    { name = "Grellkin Sorcerer",            hp = 12367, count = 17 }, -- 210239
                    { name = "Maddened Vault Guard",         hp = 12345, count = 13 }, -- 160485
                    { name = "Manacrazed Grell",             hp = 12298, count = 15 }, -- 184470
                    { name = "Runic Construct",              hp = 19898, count = 2 }, -- 39796
                    { name = "Shadow Creeper",               hp = 16048, count = 12 }, -- 192576
                    { name = "Soulless Husk",                hp = 13357, count = 15 }, -- 200355
                    { name = "Wicked Skitterer",             hp = 13851, count = 13 } -- 180063
                },
                totalTrashHP = 1521201,                                             -- Total: 118035 + 235182 + 210239 + 160485 + 184470 + 39796 + 192576 + 200355 + 180063
                trashRequiredPercent = 65                                           -- 80% required for completion
            }
        }
    },
    ["Stratholme"] = {
        isDungeon = true,
        displayName = "Strath",
        variants = {
            ["Living"] = {
                bosses = { "Timmy the Cruel", "Malor the Zealous", "Cannon Master Willey", "Archivist Galford", "Balnazzar" },
                optionalBosses = {
                    ["Hearthsinger Forresten"] = true -- Rare
                },
                trashRequiredPercent = 65,
                totalTrashHP = 1924677, -- Total: (3242*42)+(1003*16)+(9151*22)+(3401*24)+(10031*14)+(18374*2)+(9187*14)+(6483*3)+(3293*25)+(3344*9)+(9724*8)+(6687*8)+(6299*9)+(9474*6)+(6101*3)+(18949*1)+(9448*8)+(15046*1)+(7818*13)+(6633*4)+(7349*7)+(9187*11)+(6432*5)+(9474*6)+(7580*2)+(6841*5)+(7580*8)+(7049*5)+(7818*1)+(6841*2)+(8059*6)+(6633*1)+(7818*2)+(6841*2)+(10072*5)+(8059*1)
                trashMobs = {
                    { name = "Skeletal Berserker",    level = 56, hp = 3242,  count = 42 },
                    { name = "Broken Cadaver",        level = 56, hp = 1003,  count = 16 },
                    { name = "Mangled Cadaver",       level = 55, hp = 9151,  count = 22 },
                    { name = "Skeletal Guardian",     level = 56, hp = 3401,  count = 24 },
                    { name = "Ravaged Cadaver",       level = 57, hp = 10031, count = 14 },
                    { name = "Patchwork Horror",      level = 57, hp = 18374, count = 2 },
                    { name = "Plague Ghoul",          level = 57, hp = 9187,  count = 14 },
                    { name = "Ghostly Citizen",       level = 56, hp = 6483,  count = 3 },
                    { name = "Skeletal Guardian",     level = 55, hp = 3293,  count = 25 },
                    { name = "Skeletal Berserker",    level = 57, hp = 3344,  count = 9 },
                    { name = "Ravaged Cadaver",       level = 56, hp = 9724,  count = 8 },
                    { name = "Ghostly Citizen",       level = 57, hp = 6687,  count = 8 },
                    { name = "Spectral Citizen",      level = 56, hp = 6299,  count = 9 },
                    { name = "Plague Ghoul",          level = 58, hp = 9474,  count = 6 },
                    { name = "Spectral Citizen",      level = 55, hp = 6101,  count = 3 },
                    { name = "Patchwork Horror",      level = 58, hp = 18949, count = 1 },
                    { name = "Mangled Cadaver",       level = 56, hp = 9448,  count = 8 },
                    { name = "Stratholme Courier",    level = 57, hp = 15046, count = 1 },
                    { name = "Crimson Gallant",       level = 59, hp = 7818,  count = 13 },
                    { name = "Crimson Conjuror",      level = 58, hp = 6633,  count = 4 },
                    { name = "Crimson Initiate",      level = 57, hp = 7349,  count = 7 },
                    { name = "Crimson Guardsman",     level = 57, hp = 9187,  count = 11 },
                    { name = "Crimson Conjuror",      level = 57, hp = 6432,  count = 5 },
                    { name = "Crimson Guardsman",     level = 58, hp = 9474,  count = 6 },
                    { name = "Crimson Initiate",      level = 58, hp = 7580,  count = 2 },
                    { name = "Crimson Priest",        level = 59, hp = 6841,  count = 5 },
                    { name = "Crimson Defender",      level = 58, hp = 7580,  count = 8 },
                    { name = "Crimson Battle Mage",   level = 60, hp = 7049,  count = 5 },
                    { name = "Crimson Defender",      level = 59, hp = 7818,  count = 1 },
                    { name = "Crimson Sorcerer",      level = 59, hp = 6841,  count = 2 },
                    { name = "Crimson Gallant",       level = 60, hp = 8059,  count = 6 },
                    { name = "Crimson Priest",        level = 58, hp = 6633,  count = 1 },
                    { name = "Crimson Inquisitor",    level = 59, hp = 7818,  count = 2 },
                    { name = "Crimson Battle Mage",   level = 59, hp = 6841,  count = 2 },
                    { name = "Crimson Monk",          level = 60, hp = 10072, count = 5 },
                    { name = "Crimson Inquisitor",    level = 60, hp = 8059,  count = 1 }
                }
            },
            ["Undead"] = {
                bosses = { "Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Magistrate Barthilas", "Ramstein the Gorger", "Baron Rivendare" },
                optionalBosses = {
                    ["Stonespine"] = true -- Rare
                },
                trashRequiredPercent = 70,
                totalTrashHP = 1392146,
                trashMobs = {
                    { name = "Mangled Cadaver",       level = 55, hp = 9151,  count = 3 },
                    { name = "Broken Cadaver",        level = 55, hp = 1003,  count = 4 },
                    { name = "Skeletal Berserker",    level = 57, hp = 3344,  count = 2 },
                    { name = "Skeletal Guardian",     level = 55, hp = 3293,  count = 5 },
                    { name = "Ravaged Cadaver",       level = 57, hp = 10031, count = 3 },
                    { name = "Skeletal Berserker",    level = 56, hp = 3242,  count = 4 },
                    { name = "Ravaged Cadaver",       level = 56, hp = 9724,  count = 1 },
                    { name = "Skeletal Guardian",     level = 56, hp = 3401,  count = 2 },
                    { name = "Mangled Cadaver",       level = 56, hp = 9448,  count = 1 },
                    { name = "Crypt Beast",           level = 59, hp = 9771,  count = 1 },
                    { name = "Wailing Banshee",       level = 58, hp = 9474,  count = 4 },
                    { name = "Fleshflayer Ghoul",     level = 59, hp = 9771,  count = 5 },
                    { name = "Ghoul Ravener",         level = 58, hp = 9474,  count = 12 },
                    { name = "Shrieking Banshee",     level = 57, hp = 9187,  count = 6 },
                    { name = "Rockwing Gargoyle",     level = 57, hp = 9187,  count = 3 },
                    { name = "Rockwing Screecher",    level = 59, hp = 9771,  count = 2 },
                    { name = "Crypt Beast",           level = 60, hp = 10072, count = 5 },
                    { name = "Shrieking Banshee",     level = 58, hp = 9474,  count = 3 },
                    { name = "Rockwing Gargoyle",     level = 58, hp = 9474,  count = 1 },
                    { name = "Plague Ghoul",          level = 58, hp = 9474,  count = 5 },
                    { name = "Rockwing Screecher",    level = 58, hp = 9474,  count = 1 },
                    { name = "Thuzadin Shadowcaster", level = 58, hp = 6633,  count = 8 },
                    { name = "Thuzadin Necromancer",  level = 60, hp = 7049,  count = 11 },
                    { name = "Crypt Crawler",         level = 59, hp = 9771,  count = 5 },
                    { name = "Thuzadin Acolyte",      level = 59, hp = 3257,  count = 15 },
                    { name = "Crypt Crawler",         level = 58, hp = 9474,  count = 2 },
                    { name = "Thuzadin Necromancer",  level = 61, hp = 7263,  count = 6 },
                    { name = "Plague Ghoul",          level = 57, hp = 9187,  count = 8 },
                    { name = "Ghoul Ravener",         level = 59, hp = 9771,  count = 5 },
                    { name = "Fleshflayer Ghoul",     level = 60, hp = 10072, count = 5 },
                    { name = "Thuzadin Shadowcaster", level = 59, hp = 6841,  count = 6 },
                    { name = "Wailing Banshee",       level = 59, hp = 9771,  count = 2 },
                    { name = "Venom Belcher",         level = 61, hp = 17292, count = 5 },
                    { name = "Bile Spewer",           level = 59, hp = 16286, count = 1 },
                    { name = "Venom Belcher",         level = 60, hp = 16786, count = 4 },
                    { name = "Bile Spewer",           level = 60, hp = 16786, count = 2 },
                    { name = "Mindless Undead",       level = 57, hp = 1337,  count = 34 },
                    { name = "Black Guard Sentry",    level = 58, hp = 7580,  count = 5 }
                }
            }
        }
    },
    ["Dire Maul"] = {
        isDungeon = true,
        variants = {
            ["North"] = {
                bosses = { "Guard Mol'dar", "Stomper Kreeg", "Guard Fengus", "Guard Slip'kik", "Captain Kromcrush", "Cho'Rush the Observer", "King Gordok" },
            },
            ["East"] = {
                bosses = { "Pusillin", "Zevrim Thornhoof", "Hydrospawn", "Lethtendris", "Pimgib", "Alzzin the Wildshaper" },
            },
            ["West"] = {
                bosses = { "Tendris Warpwood", "Illyanna Ravenoak", "Magister Kalendris", "Immol'thar", "Prince Tortheldrin" },
                optionalBosses = {
                    ["Tsu'zee"] = true,        -- Rare
                    ["Lord Hel'nurath"] = true -- Rare
                },
                trashRequiredPercent = 50,
                totalTrashHP = 1931400,
                trashMobs = {
                    { name = "Arcane Feedback",      level = 57, hp = 1962,  count = 4 },
                    { name = "Arcane Feedback",      level = 58, hp = 2024,  count = 6 },
                    { name = "Arcane Feedback",      level = 59, hp = 2086,  count = 4 },
                    { name = "Arcane Feedback",      level = 60, hp = 2148,  count = 1 },
                    { name = "Arcane Torrent",       level = 58, hp = 17687, count = 3 },
                    { name = "Arcane Torrent",       level = 59, hp = 18245, count = 1 },
                    { name = "Arcane Torrent",       level = 60, hp = 18803, count = 1 },
                    { name = "Eldreth Apparition",   level = 56, hp = 7125,  count = 3 },
                    { name = "Eldreth Apparition",   level = 57, hp = 7352,  count = 6 },
                    { name = "Eldreth Apparition",   level = 58, hp = 7580,  count = 4 },
                    { name = "Eldreth Darter",       level = 58, hp = 7580,  count = 7 },
                    { name = "Eldreth Darter",       level = 59, hp = 7818,  count = 3 },
                    { name = "Eldreth Phantasm",     level = 57, hp = 9187,  count = 4 },
                    { name = "Eldreth Phantasm",     level = 58, hp = 9479,  count = 3 },
                    { name = "Eldreth Phantasm",     level = 59, hp = 9771,  count = 5 },
                    { name = "Eldreth Seether",      level = 58, hp = 9474,  count = 6 },
                    { name = "Eldreth Seether",      level = 59, hp = 9771,  count = 8 },
                    { name = "Eldreth Sorcerer",     level = 58, hp = 7580,  count = 13 },
                    { name = "Eldreth Sorcerer",     level = 59, hp = 7818,  count = 5 },
                    { name = "Eldreth Spectre",      level = 56, hp = 7125,  count = 5 },
                    { name = "Eldreth Spectre",      level = 57, hp = 7356,  count = 3 },
                    { name = "Eldreth Spectre",      level = 58, hp = 7587,  count = 4 },
                    { name = "Eldreth Spectre",      level = 59, hp = 7818,  count = 4 },
                    { name = "Eldreth Spirit",       level = 57, hp = 9187,  count = 10 },
                    { name = "Eldreth Spirit",       level = 58, hp = 9474,  count = 6 },
                    { name = "Ironbark Protector",   level = 57, hp = 18374, count = 3 },
                    { name = "Ironbark Protector",   level = 58, hp = 18958, count = 2 },
                    { name = "Ironbark Protector",   level = 59, hp = 19543, count = 3 },
                    { name = "Mana Remnant",         level = 57, hp = 7349,  count = 4 },
                    { name = "Mana Remnant",         level = 58, hp = 7583,  count = 6 },
                    { name = "Mana Remnant",         level = 59, hp = 7818,  count = 10 },
                    { name = "Petrified Guardian",   level = 57, hp = 7656,  count = 6 },
                    { name = "Petrified Guardian",   level = 58, hp = 7899,  count = 2 },
                    { name = "Petrified Guardian",   level = 59, hp = 8142,  count = 5 },
                    { name = "Petrified Treant",     level = 57, hp = 9187,  count = 1 },
                    { name = "Petrified Treant",     level = 58, hp = 9479,  count = 7 },
                    { name = "Petrified Treant",     level = 59, hp = 9771,  count = 4 },
                    { name = "Residual Monstrosity", level = 59, hp = 15635, count = 8 },
                    { name = "Residual Monstrosity", level = 60, hp = 16117, count = 10 },
                    { name = "Rotting Highborne",    level = 57, hp = 3981,  count = 7 },
                    { name = "Rotting Highborne",    level = 58, hp = 4107,  count = 6 },
                    { name = "Rotting Highborne",    level = 59, hp = 4234,  count = 4 },
                    { name = "Skeletal Highborne",   level = 57, hp = 3981,  count = 9 },
                    { name = "Skeletal Highborne",   level = 58, hp = 4105,  count = 15 },
                    { name = "Warpwood Treant",      level = 54, hp = 8869,  count = 1 }
                }
            }
        }
    },
    ["The Stockade"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = { "Targorr the Dread", "Kam Deepfury", "Hamhock", "Bazil Thredd", "Dextren Ward" },
                optionalBosses = {
                    ["Bruegal Ironknuckle"] = true -- Rare
                },
                trashMobs = {
                    { name = "Defias Captive",   hp = 2323, count = 7 },
                    { name = "Defias Inmate",    hp = 2323, count = 21 },
                    { name = "Defias Prisoner",  hp = 2160, count = 7 },
                    { name = "Defias Prisoner",  hp = 2323, count = 6 },
                    { name = "Defias Captive",   hp = 2160, count = 11 },
                    { name = "Defias Convict",   hp = 2323, count = 7 },
                    { name = "Defias Convict",   hp = 2495, count = 6 },
                    { name = "Defias Inmate",    hp = 2495, count = 15 },
                    { name = "Defias Insurgent", hp = 2495, count = 5 },
                    { name = "Defias Insurgent", hp = 2677, count = 5 }
                },
                totalTrashHP = 212378,    -- Total: (2323*7 + 2323*21 + 2160*7 + 2160*11 + 2323*6 + 2323*7 + 2495*15 + 2495*5 + 2495*6 + 2677*5)
                trashRequiredPercent = 50 -- 50% for testing, normally 80-100%
            }
        }
    }, 
    ["Blackrock Depths"] = {
        isDungeon = true,
        variants = {
            ["Prison"] = {
                bosses = {"High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law"},
                optionalBosses = {
                    ["Pyromancer Loregrain"] = true, -- Rare
                    ["Warder Stilgiss"] = true, -- Rare
                    ["Verek"] = true -- Rare
                }
            },
            ["Upper"] = {
                bosses = {"General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan"},
                optionalBosses = {
                    ["Panzor the Invincible"] = true -- Rare
                }
            },
            ["Full"] = {
                bosses = {"High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Ring of Law", "Lord Incendius", "Fineous Darkvire", "Bael'Gar", "General Angerforge", "Golem Lord Argelmach", "Hurley Blackbreath", "Phalanx", "Plugger Spazzring", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan"},
                optionalBosses = {
                    ["Pyromancer Loregrain"] = true, -- Rare
                    ["Warder Stilgiss"] = true, -- Rare
                    ["Verek"] = true, -- Rare
                    ["Panzor the Invincible"] = true -- Rare
                }
            }
        }
    },
    ["Karazhan Crypt"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = {"Marrowspike", "Hivaxxis", "Corpsemuncher", "Guard Captain Gort", "Archlich Enkhraz", "Commander Andreon", "Alarus"},
                trashMobs = {
                    { name = "Crypt Fearfeaster",  hp = 11375, count = 2 },
                    { name = "Skeletal Remains",   hp = 10681, count = 67 },
                    { name = "Unseen Stalker",     hp = 11292, count = 25 },
                    { name = "Risen Crypt Guard",  hp = 11285, count = 33 },
                    { name = "Possessed Axe",      hp = 13587, count = 6 },
                    { name = "Cursed Blades",      hp = 13775, count = 3 },
                    { name = "Shadowblade Spectre",hp = 16601, count = 3 },
                    { name = "Tomb Creeper",       hp = 13806, count = 7 },
                    { name = "Drowned Sinner",     hp = 5788,  count = 6 },
                    { name = "Drowned Sinner",     hp = 6486,  count = 8 },
                    { name = "Forgotten Soul",     hp = 13410, count = 2 },
                    { name = "Rotten Zombie",      hp = 12546, count = 14 },
                    { name = "Ravenous Strigoi",   hp = 14498, count = 5 },
                    { name = "Forlorn Shrieker",   hp = 13907, count = 2 }
                },
                totalTrashHP = 2051758,        -- Total: (11375*2)+(10681*67)+(11292*25)+(11285*33)+(13587*6)+(13775*3)+(16601*3)+(13806*7)+(5788*6)+(6486*8)+(13410*2)+(12546*14)+(14498*5)+(13907*2)
                trashRequiredPercent = 50      -- 50% required
            }
        }
    },
    ["Black Morass"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = {"Chronar", "Epidamu", "Drifting Avatar of Sand", "Time-Lord Epochronos", "Mossheart", "Antnormi", "Rotmaw"},
                trashMobs = {
                    { name = "Infinite Dragonspawn", hp = 14220, count = 20 },
                    { name = "Infinite Whelp",       hp = 3843,  count = 8 },
                    { name = "Infinite Riftguard",   hp = 16104, count = 8 },
                    { name = "Infinite Riftweaver",  hp = 12179, count = 4 },
                    { name = "Infinite Rift-Lord",   hp = 26356, count = 2 },
                    { name = "Time Anomaly",         hp = 4659,  count = 4 },
                    { name = "Time Anomaly",         hp = 5174,  count = 20 },
                    { name = "Time Anomaly",         hp = 6205,  count = 4 },
                    { name = "Time Anomaly",         hp = 5689,  count = 13 },
                    { name = "Echo of Time",         hp = 18088, count = 5 },
                    { name = "Temporal Dust",        hp = 10232, count = 16 },
                    { name = "Murkwater Crocolisk",  hp = 8318,  count = 10 },
                    { name = "Darkwater Python",     hp = 8318,  count = 10 },
                    { name = "Blackfang Tarantula",  hp = 8318,  count = 10 }
                },
                totalTrashHP = 1269989,      -- Total: (14220*20)+(3843*8)+(16104*8)+(12179*4)+(26356*2)+(4659*4)+(5174*20)+(6205*4)+(5689*13)+(18088*5)+(10232*16)+(8318*10)+(8318*10)+(8318*10)
                trashRequiredPercent = 100   -- 100% required
            }
        }
    },
    ["Blackrock Spire"] = {
        isDungeon = true,
        variants = {
            ["Lower"] = {
                bosses = {"Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mother Smolderweb", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Gizrul the Slavener", "Overlord Wyrmthalak"},
                optionalBosses = {
                    ["Mor Grayhoof"] = true, -- Rare
                    ["Spirestone Butcher"] = true, -- Rare
                    ["Spirestone Battle Lord"] = true, -- Rare
                    ["Spirestone Lord Magus"] = true, -- Rare
                    ["Bannok Grimaxe"] = true, -- Rare
                    ["Crystal Fang"] = true, -- Rare
                    ["Ghok Bashguud"] = true, -- Rare
                    ["Burning Felguard"] = true -- Rare
                }
            },
            ["Upper"] = {
                bosses = {"Pyroguard Emberseer", "Solakar Flamewreath", "Goraluk Anvilcrack", "Warchief Rend Blackhand"},
                optionalBosses = {
                    ["Lord Valthalak"] = true -- Rare
                }
            }
        }
    },
    ["Scholomance"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = {"Kirtonos the Herald", "Jandice Barov", "Rattlegore", "Ras Frostwhisper", "Instructor Malicia", "Doctor Theolen Krastinov", "Lorekeeper Polkelt", "The Ravenian", "Lord Alexei Barov", "Lady Illucia Barov", "Darkmaster Gandling"},
                optionalBosses = {
                    ["Marduk Blackpool"] = true, -- Rare
                    ["Vectus"] = true -- Rare
                },
                trashMobs = {
                    { name = "Risen Guard",               hp = 9479,  count = 1 },
                    { name = "Risen Guard",               hp = 9187,  count = 8 },
                    { name = "Scholomance Acolyte",       hp = 7349,  count = 15 },
                    { name = "Scholomance Neophyte",      hp = 6432,  count = 11 },
                    { name = "Spectral Researcher",       hp = 7580,  count = 5 },
                    { name = "Scholomance Neophyte",      hp = 6633,  count = 6 },
                    { name = "Spectral Researcher",       hp = 8059,  count = 1 },
                    { name = "Spectral Researcher",       hp = 7819,  count = 2 },
                    { name = "Scholomance Acolyte",       hp = 7580,  count = 1 },
                    { name = "Risen Guard",               hp = 9771,  count = 3 },
                    { name = "Scholomance Dark Summoner", hp = 7818,  count = 4 },
                    { name = "Scholomance Necrolyte",     hp = 7580,  count = 2 },
                    { name = "Necrofiend",                hp = 9773,  count = 2 },
                    { name = "Risen Lackey",              hp = 1167,  count = 4 },
                    { name = "Scholomance Necrolyte",     hp = 7349,  count = 8 },
                    { name = "Scholomance Dark Summoner", hp = 7580,  count = 2 },
                    { name = "Risen Protector",           hp = 8059,  count = 2 },
                    { name = "Spectral Tutor",            hp = 8059,  count = 2 },
                    { name = "Scholomance Necromancer",   hp = 7818,  count = 8 },
                    { name = "Scholomance Adept",         hp = 7580,  count = 11 },
                    { name = "Scholomance Adept",         hp = 7818,  count = 6 },
                    { name = "Scholomance Necromancer",   hp = 7580,  count = 6 },
                    { name = "Spectral Tutor",            hp = 7580,  count = 3 },
                    { name = "Risen Protector",           hp = 7819,  count = 2 },
                    { name = "Spectral Tutor",            hp = 7819,  count = 2 },
                    { name = "Plagued Hatchling",         hp = 4265,  count = 13 },
                    { name = "Scholomance Handler",       hp = 8059,  count = 5 },
                    { name = "Plagued Hatchling",         hp = 4397,  count = 9 },
                    { name = "Risen Construct",           hp = 16291, count = 1 },
                    { name = "Risen Construct",           hp = 16791, count = 4 },
                    { name = "Risen Construct",           hp = 15791, count = 3 },
                    { name = "Risen Aberration",          hp = 2297,  count = 17 },
                    { name = "Diseased Ghoul",            hp = 9474,  count = 13 },
                    { name = "Reanimated Corpse",         hp = 1628,  count = 32 },
                    { name = "Risen Aberration",          hp = 2368,  count = 32 },
                    { name = "Diseased Ghoul",            hp = 9771,  count = 16 },
                    { name = "Reanimated Corpse",         hp = 1579,  count = 13 },
                    { name = "Necrofiend",                hp = 10072, count = 2 },
                    { name = "Spectral Teacher",          hp = 7820,  count = 1 },
                    { name = "Spectral Teacher",          hp = 8300,  count = 1 },
                    { name = "Unstable Corpse",           hp = 4263,  count = 23 },
                    { name = "Splintered Skeleton",       hp = 9771,  count = 5 },
                    { name = "Risen Bonewarder",          hp = 7580,  count = 4 },
                    { name = "Risen Warrior",             hp = 17292, count = 2 }
                },
                totalTrashHP = 1852571,        -- Total: (9187*8)+(9479*1)+(7349*15)+(6432*11)+(7580*5)+(6633*6)+(8059*1)+(7819*2)+(7580*1)+(9771*3)+(7818*4)+(7580*2)+(9773*2)+(1167*4)+(7349*8)+(7580*2)+(8059*2)+(8059*2)+(7818*8)+(7580*11)+(7818*6)+(7580*6)+(7580*3)+(7819*2)+(7819*2)+(4265*13)+(8059*5)+(4397*9)+(16291*1)+(16791*4)+(15791*3)+(2297*17)+(9474*13)+(1628*32)+(2368*32)+(9771*16)+(1579*13)+(10072*2)+(7820*1)+(8300*1)+(4263*23)+(9771*5)+(7580*4)+(17292*2)
                trashRequiredPercent = 50      -- 50% required
            }
        }
    },   
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
