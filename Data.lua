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
                    { name = "Black Blood of the Dragonmaw", hp = 13115, count = 9 },  -- 118035
                    { name = "Grellkin Scorcher",            hp = 12378, count = 19 }, -- 235182
                    { name = "Grellkin Sorcerer",            hp = 12367, count = 17 }, -- 210239
                    { name = "Maddened Vault Guard",         hp = 12345, count = 13 }, -- 160485
                    { name = "Manacrazed Grell",             hp = 12298, count = 15 }, -- 184470
                    { name = "Runic Construct",              hp = 19898, count = 2 },  -- 39796
                    { name = "Shadow Creeper",               hp = 16048, count = 12 }, -- 192576
                    { name = "Soulless Husk",                hp = 13357, count = 15 }, -- 200355
                    { name = "Wicked Skitterer",             hp = 13851, count = 13 }  -- 180063
                },
                totalTrashHP = 1521201,                                                -- Total: 118035 + 235182 + 210239 + 160485 + 184470 + 39796 + 192576 + 200355 + 180063
                trashRequiredPercent = 65,
                trashRequiredPercentTested = true                    
            }
        }
    },
    ["Stratholme"] = {
        isDungeon = true,
        displayName = "Stratholme",
        variants = {
            ["Living"] = {
                bosses = { "Timmy the Cruel", "Malor the Zealous", "Cannon Master Willey", "Archivist Galford", "Balnazzar" },
                optionalBosses = {
                    ["Hearthsinger Forresten"] = true -- Rare
                },
                trashRequiredPercent = 65,
                trashRequiredPercentTested = true,
                totalTrashHP = 1924677, -- Total: (3242*42)+(1003*16)+(9151*22)+(3401*24)+(10031*14)+(18374*2)+(9187*14)+(6483*3)+(3293*25)+(3344*9)+(9724*8)+(6687*8)+(6299*9)+(9474*6)+(6101*3)+(18949*1)+(9448*8)+(15046*1)+(7818*13)+(6633*4)+(7349*7)+(9187*11)+(6432*5)+(9474*6)+(7580*2)+(6841*5)+(7580*8)+(7049*5)+(7818*1)+(6841*2)+(8059*6)+(6633*1)+(7818*2)+(6841*2)+(10072*5)+(8059*1)
                trashMobs = {
                    { name = "Skeletal Berserker",  hp = 3242,  count = 42 },
                    { name = "Broken Cadaver",      hp = 1003,  count = 16 },
                    { name = "Mangled Cadaver",     hp = 9151,  count = 22 },
                    { name = "Skeletal Guardian",   hp = 3401,  count = 24 },
                    { name = "Ravaged Cadaver",     hp = 10031, count = 14 },
                    { name = "Patchwork Horror",    hp = 18374, count = 2 },
                    { name = "Plague Ghoul",        hp = 9187,  count = 14 },
                    { name = "Ghostly Citizen",     hp = 6483,  count = 3 },
                    { name = "Skeletal Guardian",   hp = 3293,  count = 25 },
                    { name = "Skeletal Berserker",  hp = 3344,  count = 9 },
                    { name = "Ravaged Cadaver",     hp = 9724,  count = 8 },
                    { name = "Ghostly Citizen",     hp = 6687,  count = 8 },
                    { name = "Spectral Citizen",    hp = 6299,  count = 9 },
                    { name = "Plague Ghoul",        hp = 9474,  count = 6 },
                    { name = "Spectral Citizen",    hp = 6101,  count = 3 },
                    { name = "Patchwork Horror",    hp = 18949, count = 1 },
                    { name = "Mangled Cadaver",     hp = 9448,  count = 8 },
                    { name = "Stratholme Courier",  hp = 15046, count = 1 },
                    { name = "Crimson Gallant",     hp = 7818,  count = 13 },
                    { name = "Crimson Conjuror",    hp = 6633,  count = 4 },
                    { name = "Crimson Initiate",    hp = 7349,  count = 7 },
                    { name = "Crimson Guardsman",   hp = 9187,  count = 11 },
                    { name = "Crimson Conjuror",    hp = 6432,  count = 5 },
                    { name = "Crimson Guardsman",   hp = 9474,  count = 6 },
                    { name = "Crimson Initiate",    hp = 7580,  count = 2 },
                    { name = "Crimson Priest",      hp = 6841,  count = 5 },
                    { name = "Crimson Defender",    hp = 7580,  count = 8 },
                    { name = "Crimson Battle Mage", hp = 7049,  count = 5 },
                    { name = "Crimson Defender",    hp = 7818,  count = 1 },
                    { name = "Crimson Sorcerer",    hp = 6841,  count = 2 },
                    { name = "Crimson Gallant",     hp = 8059,  count = 6 },
                    { name = "Crimson Priest",      hp = 6633,  count = 1 },
                    { name = "Crimson Inquisitor",  hp = 7818,  count = 2 },
                    { name = "Crimson Battle Mage", hp = 6841,  count = 2 },
                    { name = "Crimson Monk",        hp = 10072, count = 5 },
                    { name = "Crimson Inquisitor",  hp = 8059,  count = 1 }
                }
            },
            ["Undead"] = {
                bosses = { "Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Magistrate Barthilas", "Ramstein the Gorger", "Baron Rivendare" },
                optionalBosses = {
                    ["Stonespine"] = true -- Rare
                },
                trashRequiredPercent = 85,
                trashRequiredPercentTested = true,
                totalTrashHP = 1392146,
                trashMobs = {
                    { name = "Mangled Cadaver",      hp = 9151,  count = 3 },
                    { name = "Broken Cadaver",       hp = 1003,  count = 4 },
                    { name = "Skeletal Berserker",   hp = 3344,  count = 2 },
                    { name = "Skeletal Guardian",    hp = 3293,  count = 5 },
                    { name = "Ravaged Cadaver",      hp = 10031, count = 3 },
                    { name = "Skeletal Berserker",   hp = 3242,  count = 4 },
                    { name = "Ravaged Cadaver",      hp = 9724,  count = 1 },
                    { name = "Skeletal Guardian",    hp = 3401,  count = 2 },
                    { name = "Mangled Cadaver",      hp = 9448,  count = 1 },
                    { name = "Crypt Beast",          hp = 9771,  count = 1 },
                    { name = "Wailing Banshee",      hp = 9474,  count = 4 },
                    { name = "Fleshflayer Ghoul",    hp = 9771,  count = 5 },
                    { name = "Ghoul Ravener",        hp = 9474,  count = 12 },
                    { name = "Shrieking Banshee",    hp = 9187,  count = 6 },
                    { name = "Rockwing Gargoyle",    hp = 9187,  count = 3 },
                    { name = "Rockwing Screecher",   hp = 9771,  count = 2 },
                    { name = "Crypt Beast",          hp = 10072, count = 5 },
                    { name = "Shrieking Banshee",    hp = 9474,  count = 3 },
                    { name = "Rockwing Gargoyle",    hp = 9474,  count = 1 },
                    { name = "Plague Ghoul",         hp = 9474,  count = 5 },
                    { name = "Rockwing Screecher",   hp = 9474,  count = 1 },
                    { name = "Thuzadin Shadowcaster",hp = 6633,  count = 8 },
                    { name = "Thuzadin Necromancer", hp = 7049,  count = 11 },
                    { name = "Crypt Crawler",        hp = 9771,  count = 5 },
                    { name = "Thuzadin Acolyte",     hp = 3257,  count = 15 },
                    { name = "Crypt Crawler",        hp = 9474,  count = 2 },
                    { name = "Thuzadin Necromancer", hp = 7263,  count = 6 },
                    { name = "Plague Ghoul",         hp = 9187,  count = 8 },
                    { name = "Ghoul Ravener",        hp = 9771,  count = 5 },
                    { name = "Fleshflayer Ghoul",    hp = 10072, count = 5 },
                    { name = "Thuzadin Shadowcaster",hp = 6841,  count = 6 },
                    { name = "Wailing Banshee",      hp = 9771,  count = 2 },
                    { name = "Venom Belcher",        hp = 17292, count = 5 },
                    { name = "Bile Spewer",          hp = 16286, count = 1 },
                    { name = "Venom Belcher",        hp = 16786, count = 4 },
                    { name = "Bile Spewer",          hp = 16786, count = 2 },
                    { name = "Mindless Undead",      hp = 1337,  count = 34 },
                    { name = "Black Guard Sentry",   hp = 7580,  count = 5 }
                }
            }
        }
    },
    ["Dire Maul"] = {
        isDungeon = true,
        variants = {
            ["North"] = {
                bosses = { "Guard Mol'dar", "Stomper Kreeg", "Guard Fengus", "Guard Slip'kik", "Captain Kromcrush", "Cho'Rush the Observer", "King Gordok" },
                trashRequiredPercent = 50,
                totalTrashHP = 1751150,
                trashMobs = {
                    { name = "Gordok Brute",             hp = 15791, count = 30 },
                    { name = "Gordok Brute",             hp = 15312, count = 5 },
                    { name = "Gordok Reaver",            hp = 16286, count = 11 },
                    { name = "Gordok Reaver",            hp = 15791, count = 4 },
                    { name = "Gordok Captain",           hp = 16117, count = 2 },
                    { name = "Gordok Captain",           hp = 15635, count = 4 },
                    { name = "Gordok Mage-Lord",         hp = 11055, count = 14 },
                    { name = "Gordok Mage-Lord",         hp = 10720, count = 11 },
                    { name = "Gordok Warlock",           hp = 11748, count = 13 },
                    { name = "Gordok Warlock",           hp = 11402, count = 2 },
                    { name = "Gordok Mastiff",           hp = 4397,  count = 62 },
                    { name = "Gordok Mastiff",           hp = 4134,  count = 3 },
                    { name = "Doomguard Minion",         hp = 4029,  count = 10 },
                    { name = "Doomguard Minion",         hp = 3908,  count = 6 },
                    { name = "Carrion Swarmer",          hp = 947,   count = 36 },
                    { name = "Carrion Swarmer",          hp = 890,   count = 36 },
                    { name = "Wandering Eye of Kilrogg",  hp = 336,  count = 2 }
                    -- Note: Guard Fengus (boss) excluded from trash count
                }
            },
            ["East"] = {
                bosses = { "Pusillin", "Zevrim Thornhoof", "Hydrospawn", "Lethtendris", "Pimgib", "Alzzin the Wildshaper" },
                trashRequiredPercent = 50,
                totalTrashHP = 1735022,
                trashMobs = {
                    { name = "Warpwood Crusher",        hp = 18897, count = 9 },
                    { name = "Warpwood Tangler",        hp = 7319,  count = 1 },
                    { name = "Warpwood Treant",         hp = 8869,  count = 4 },
                    { name = "Warpwood Stomper",        hp = 9474,  count = 3 },
                    { name = "Phase Lasher",            hp = 17174, count = 3 },
                    { name = "Phase Lasher",            hp = 18301, count = 6 },
                    { name = "Whip Lasher",             hp = 2258,  count = 140 },
                    { name = "Warpwood Stomper",        hp = 9187,  count = 5 },
                    { name = "Warpwood Tangler",        hp = 7558,  count = 1 },
                    { name = "Wildspawn Satyr",         hp = 9448,  count = 2 },
                    { name = "Wildspawn Shadowstalker", hp = 9448,  count = 7 },
                    { name = "Wildspawn Betrayer",      hp = 9448,  count = 4 },
                    { name = "Fel Lash",                hp = 15115, count = 4 },
                    { name = "Wildspawn Felsworn",      hp = 6613,  count = 3 },
                    { name = "Wildspawn Satyr",         hp = 9151,  count = 11 },
                    { name = "Wildspawn Betrayer",      hp = 9151,  count = 3 },
                    { name = "Fel Lash",                hp = 14640, count = 6 },
                    { name = "Wildspawn Imp",           hp = 4252,  count = 27 },
                    { name = "Wildspawn Felsworn",      hp = 6406,  count = 3 },
                    { name = "Wildspawn Hellcaller",    hp = 7779,  count = 2 },
                    { name = "Wildspawn Imp",           hp = 4116,  count = 1 },
                    { name = "Wildspawn Trickster",     hp = 7779,  count = 1 },
                    { name = "Wildspawn Rogue",         hp = 10031, count = 2 },
                    { name = "Wildspawn Hellcaller",    hp = 8023,  count = 4 },
                    { name = "Wildspawn Trickster",     hp = 8023,  count = 3 },
                    { name = "Wildspawn Rogue",         hp = 9724,  count = 3 },
                    { name = "Death Lash",              hp = 18374, count = 9 },
                    { name = "Warpwood Guardian",       hp = 7580,  count = 6 },
                    { name = "Warpwood Guardian",       hp = 7349,  count = 4 },
                    { name = "Warpwood Crusher",        hp = 18301, count = 2 }
                }
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
                    { name = "Arcane Feedback",      hp = 1962,  count = 4 },
                    { name = "Arcane Feedback",      hp = 2024,  count = 6 },
                    { name = "Arcane Feedback",      hp = 2086,  count = 4 },
                    { name = "Arcane Feedback",      hp = 2148,  count = 1 },
                    { name = "Arcane Torrent",       hp = 17687, count = 3 },
                    { name = "Arcane Torrent",       hp = 18245, count = 1 },
                    { name = "Arcane Torrent",       hp = 18803, count = 1 },
                    { name = "Eldreth Apparition",   hp = 7125,  count = 3 },
                    { name = "Eldreth Apparition",   hp = 7352,  count = 6 },
                    { name = "Eldreth Apparition",   hp = 7580,  count = 4 },
                    { name = "Eldreth Darter",       hp = 7580,  count = 7 },
                    { name = "Eldreth Darter",       hp = 7818,  count = 3 },
                    { name = "Eldreth Phantasm",     hp = 9187,  count = 4 },
                    { name = "Eldreth Phantasm",     hp = 9479,  count = 3 },
                    { name = "Eldreth Phantasm",     hp = 9771,  count = 5 },
                    { name = "Eldreth Seether",      hp = 9474,  count = 6 },
                    { name = "Eldreth Seether",      hp = 9771,  count = 8 },
                    { name = "Eldreth Sorcerer",     hp = 7580,  count = 13 },
                    { name = "Eldreth Sorcerer",     hp = 7818,  count = 5 },
                    { name = "Eldreth Spectre",      hp = 7125,  count = 5 },
                    { name = "Eldreth Spectre",      hp = 7356,  count = 3 },
                    { name = "Eldreth Spectre",      hp = 7587,  count = 4 },
                    { name = "Eldreth Spectre",      hp = 7818,  count = 4 },
                    { name = "Eldreth Spirit",       hp = 9187,  count = 10 },
                    { name = "Eldreth Spirit",       hp = 9474,  count = 6 },
                    { name = "Ironbark Protector",   hp = 18374, count = 3 },
                    { name = "Ironbark Protector",   hp = 18958, count = 2 },
                    { name = "Ironbark Protector",   hp = 19543, count = 3 },
                    { name = "Mana Remnant",         hp = 7349,  count = 4 },
                    { name = "Mana Remnant",         hp = 7583,  count = 6 },
                    { name = "Mana Remnant",         hp = 7818,  count = 10 },
                    { name = "Petrified Guardian",   hp = 7656,  count = 6 },
                    { name = "Petrified Guardian",   hp = 7899,  count = 2 },
                    { name = "Petrified Guardian",   hp = 8142,  count = 5 },
                    { name = "Petrified Treant",     hp = 9187,  count = 1 },
                    { name = "Petrified Treant",     hp = 9479,  count = 7 },
                    { name = "Petrified Treant",     hp = 9771,  count = 4 },
                    { name = "Residual Monstrosity", hp = 15635, count = 8 },
                    { name = "Residual Monstrosity", hp = 16117, count = 10 },
                    { name = "Rotting Highborne",    hp = 3981,  count = 7 },
                    { name = "Rotting Highborne",    hp = 4107,  count = 6 },
                    { name = "Rotting Highborne",    hp = 4234,  count = 4 },
                    { name = "Skeletal Highborne",   hp = 3981,  count = 9 },
                    { name = "Skeletal Highborne",   hp = 4105,  count = 15 },
                    { name = "Warpwood Treant",      hp = 8869,  count = 1 }
                }
            }
        }
    },
    -- ["The Stockade"] = {
    --     isDungeon = true,
    --     variants = {
    --         ["Default"] = {
    --             bosses = { "Targorr the Dread", "Kam Deepfury", "Hamhock", "Bazil Thredd", "Dextren Ward" },
    --             optionalBosses = {
    --                 ["Bruegal Ironknuckle"] = true -- Rare
    --             },
    --             trashMobs = {
    --                 { name = "Defias Captive",   hp = 2323, count = 7 },
    --                 { name = "Defias Inmate",    hp = 2323, count = 21 },
    --                 { name = "Defias Prisoner",  hp = 2160, count = 7 },
    --                 { name = "Defias Prisoner",  hp = 2323, count = 6 },
    --                 { name = "Defias Captive",   hp = 2160, count = 11 },
    --                 { name = "Defias Convict",   hp = 2323, count = 7 },
    --                 { name = "Defias Convict",   hp = 2495, count = 6 },
    --                 { name = "Defias Inmate",    hp = 2495, count = 15 },
    --                 { name = "Defias Insurgent", hp = 2495, count = 5 },
    --                 { name = "Defias Insurgent", hp = 2677, count = 5 }
    --             },
    --             totalTrashHP = 212378,    -- Total: (2323*7 + 2323*21 + 2160*7 + 2160*11 + 2323*6 + 2323*7 + 2495*15 + 2495*5 + 2495*6 + 2677*5)
    --             trashRequiredPercent = 50 -- 50% for testing, normally 80-100%
    --         }
    --     }
    -- },
    ["Karazhan Crypt"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = { "Marrowspike", "Hivaxxis", "Corpsemuncher", "Guard Captain Gort", "Archlich Enkhraz", "Commander Andreon", "Alarus" },
                trashMobs = {
                    { name = "Crypt Fearfeaster",   hp = 11375, count = 2 },
                    { name = "Skeletal Remains",    hp = 10681, count = 67 },
                    { name = "Unseen Stalker",      hp = 11292, count = 25 },
                    { name = "Risen Crypt Guard",   hp = 11285, count = 33 },
                    { name = "Possessed Axe",       hp = 13587, count = 6 },
                    { name = "Cursed Blades",       hp = 13775, count = 3 },
                    { name = "Shadowblade Spectre", hp = 16601, count = 3 },
                    { name = "Tomb Creeper",        hp = 13806, count = 7 },
                    { name = "Drowned Sinner",      hp = 5788,  count = 6 },
                    { name = "Drowned Sinner",      hp = 6486,  count = 8 },
                    { name = "Forgotten Soul",      hp = 13410, count = 2 },
                    { name = "Rotten Zombie",       hp = 12546, count = 14 },
                    { name = "Ravenous Strigoi",    hp = 14498, count = 5 },
                    { name = "Forlorn Shrieker",    hp = 13907, count = 2 }
                },
                totalTrashHP = 2051758,   -- Total: (11375*2)+(10681*67)+(11292*25)+(11285*33)+(13587*6)+(13775*3)+(16601*3)+(13806*7)+(5788*6)+(6486*8)+(13410*2)+(12546*14)+(14498*5)+(13907*2)
                trashRequiredPercent = 50 -- 50% required
            }
        }
    },
    ["Black Morass"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = { "Chronar", "Epidamu", "Drifting Avatar of Sand", "Time-Lord Epochronos", "Mossheart", "Antnormi", "Rotmaw" },
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
                totalTrashHP = 1269989,    -- Total: (14220*20)+(3843*8)+(16104*8)+(12179*4)+(26356*2)+(4659*4)+(5174*20)+(6205*4)+(5689*13)+(18088*5)+(10232*16)+(8318*10)+(8318*10)+(8318*10)
                trashRequiredPercent = 100 -- 100% required
            }
        }
    },
    ["Blackrock Spire"] = {
        isDungeon = true,
        variants = {
            ["Lower"] = {
                bosses = { "Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mother Smolderweb", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Gizrul the Slavener", "Overlord Wyrmthalak" },
                optionalBosses = {
                    ["Mor Grayhoof"] = true,           -- Rare
                    ["Spirestone Butcher"] = true,     -- Rare
                    ["Spirestone Battle Lord"] = true, -- Rare
                    ["Spirestone Lord Magus"] = true,  -- Rare
                    ["Bannok Grimaxe"] = true,         -- Rare
                    ["Crystal Fang"] = true,           -- Rare
                    ["Ghok Bashguud"] = true,          -- Rare
                    ["Burning Felguard"] = true        -- Rare
                },
                trashMobs = {
                    { name = "Scarshield Legionnaire",       hp = 9151,  count = 31 },
                    { name = "Scarshield Spellbinder",       hp = 7319,  count = 8 },
                    { name = "Scarshield Acolyte",           hp = 7319,  count = 3 },
                    { name = "Scarshield Acolyte",           hp = 7092,  count = 4 },
                    { name = "Scarshield Raider",            hp = 9151,  count = 3 },
                    { name = "Scarshield Worg",              hp = 3916,  count = 5 },
                    { name = "Scarshield Spellbinder",       hp = 7092,  count = 9 },
                    { name = "Scarshield Raider",            hp = 9448,  count = 3 },
                    { name = "Scarshield Worg",              hp = 3792,  count = 9 },
                    { name = "Scarshield Legionnaire",       hp = 8867,  count = 11 },
                    { name = "Scarshield Warlock",           hp = 7092,  count = 5 },
                    { name = "Scarshield Warlock",           hp = 7319,  count = 4 },
                    { name = "Spirestone Enforcer",          hp = 14779, count = 4 },
                    { name = "Spirestone Ogre Magus",        hp = 11821, count = 2 },
                    { name = "Spirestone Battle Mage",       hp = 12249, count = 3 },
                    { name = "Spirestone Reaver",            hp = 15252, count = 3 },
                    { name = "Spirestone Warlord",           hp = 15312, count = 3 },
                    { name = "Spirestone Mystic",            hp = 12597, count = 2 },
                    { name = "Spirestone Warlord",           hp = 15791, count = 6 },
                    { name = "Spirestone Ogre Magus",        hp = 12199, count = 3 },
                    { name = "Spirestone Mystic",            hp = 12199, count = 1 },
                    { name = "Smolderthorn Axe Thrower",     hp = 9151,  count = 3 },
                    { name = "Smolderthorn Shadow Priest",   hp = 7558,  count = 6 },
                    { name = "Smolderthorn Mystic",          hp = 7319,  count = 5 },
                    { name = "Smolderthorn Shadow Priest",   hp = 7319,  count = 11 },
                    { name = "Smolderthorn Mystic",          hp = 7558,  count = 5 },
                    { name = "Smolderthorn Shadow Hunter",   hp = 7779,  count = 4 },
                    { name = "Smolderthorn Axe Thrower",     hp = 9448,  count = 6 },
                    { name = "Smolderthorn Seer",            hp = 8023,  count = 3 },
                    { name = "Smolderthorn Shadow Hunter",   hp = 8023,  count = 2 },
                    { name = "Smolderthorn Headhunter",      hp = 10031, count = 5 },
                    { name = "Smolderthorn Berserker",       hp = 9187,  count = 8 },
                    { name = "Smolderthorn Witch Doctor",    hp = 8023,  count = 5 },
                    { name = "Smolderthorn Seer",            hp = 7779,  count = 7 },
                    { name = "Smolderthorn Headhunter",      hp = 9724,  count = 5 },
                    { name = "Smolderthorn Witch Doctor",    hp = 7779,  count = 2 },
                    { name = "Smolderthorn Berserker",       hp = 9474,  count = 4 },
                    { name = "Firebrand Darkweaver",         hp = 7779,  count = 8 },
                    { name = "Firebrand Grunt",              hp = 9724,  count = 5 },
                    { name = "Firebrand Invoker",            hp = 7779,  count = 5 },
                    { name = "Firebrand Legionnaire",        hp = 9474,  count = 1 },
                    { name = "Firebrand Invoker",            hp = 8023,  count = 5 },
                    { name = "Firebrand Darkweaver",         hp = 8023,  count = 4 },
                    { name = "Firebrand Grunt",              hp = 10031, count = 17 },
                    { name = "Firebrand Dreadweaver",        hp = 7580,  count = 4 },
                    { name = "Firebrand Legionnaire",        hp = 9187,  count = 2 },
                    { name = "Firebrand Pyromancer",         hp = 7349,  count = 3 },
                    { name = "Spire Spiderling",             hp = 3050,  count = 32 },
                    { name = "Spire Spiderling",             hp = 3149,  count = 9 },
                    { name = "Spirestone Battle Mage",       hp = 12634, count = 1 },
                    { name = "Bloodaxe Raider",              hp = 9187,  count = 4 },
                    { name = "Bloodaxe Worg",                hp = 3242,  count = 8 },
                    { name = "Bloodaxe Veteran",             hp = 9771,  count = 10 },
                    { name = "Bloodaxe Warmonger",           hp = 9474,  count = 7 },
                    { name = "Bloodaxe Evoker",              hp = 7818,  count = 4 },
                    { name = "Bloodaxe Summoner",            hp = 7580,  count = 6 },
                    { name = "Bloodaxe Worg",                hp = 3344,  count = 8 },
                    { name = "Bloodaxe Warmonger",           hp = 9187,  count = 5 },
                    { name = "Bloodaxe Raider",              hp = 9474,  count = 3 },
                    { name = "Bloodaxe Veteran",             hp = 9474,  count = 6 },
                    { name = "Bloodaxe Evoker",              hp = 7580,  count = 7 },
                    { name = "Bloodaxe Worg Pup",            hp = 3940,  count = 2 },
                    { name = "Bloodaxe Summoner",            hp = 7349,  count = 3 }
                },
                totalTrashHP = 2939679,      -- Total calculated by Python script
                trashRequiredPercent = 50    -- 50% required
            },
            ["Upper"] = {
                bosses = { "Pyroguard Emberseer", "Solakar Flamewreath", "Goraluk Anvilcrack", "Warchief Rend Blackhand",  "Gyth", "The Beast", "General Drakkisath"},
                optionalBosses = {
                    ["Lord Valthalak"] = true -- Rare
                },
                trashMobs = {
                    { name = "Scarshield Legionnaire",    hp = 8867,  count = 9 },
                    { name = "Rage Talon Dragonspawn",    hp = 16286, count = 9 },
                    { name = "Blackhand Summoner",        hp = 8059,  count = 9 },
                    { name = "Blackhand Veteran",         hp = 9771,  count = 26 },
                    { name = "Blackhand Dreadweaver",     hp = 7818,  count = 8 },
                    { name = "Rage Talon Dragonspawn",    hp = 15791, count = 12 },
                    { name = "Blackhand Veteran",         hp = 10072, count = 8 },
                    { name = "Blackhand Dreadweaver",     hp = 8059,  count = 11 },
                    { name = "Blackhand Summoner",        hp = 7818,  count = 5 },
                    { name = "Rookery Whelp",             hp = 3344,  count = 8 },
                    { name = "Rage Talon Flamescale",     hp = 7580,  count = 7 },
                    { name = "Rookery Whelp",             hp = 3242,  count = 12 },
                    { name = "Rage Talon Flamescale",     hp = 7818,  count = 2 },
                    { name = "Rookery Hatcher",           hp = 9771,  count = 7 },
                    { name = "Rookery Hatcher",           hp = 9474,  count = 2 },
                    { name = "Rookery Guardian",          hp = 11053, count = 1 },
                    { name = "Blackhand Elite",           hp = 16786, count = 8 },
                    { name = "Blackhand Elite",           hp = 17292, count = 8 },
                    { name = "Blackhand Thug",            hp = 16786, count = 2 },
                    { name = "Chromatic Whelp",           hp = 4831,  count = 27 },
                    { name = "Chromatic Dragonspawn",     hp = 19984, count = 9 },
                    { name = "Blackhand Dragon Handler",  hp = 12902, count = 5 },
                    { name = "Rage Talon Fire Tongue",    hp = 20750, count = 5 },
                    { name = "Blackhand Assassin",        hp = 17292, count = 11 },
                    { name = "Rage Talon Dragon Guard",   hp = 20750, count = 8 },
                    { name = "Blackhand Iron Guard",      hp = 13429, count = 6 },
                    { name = "Blackhand Iron Guard",      hp = 13834, count = 11 },
                    { name = "Rage Talon Captain",        hp = 19422, count = 5 },
                    { name = "Rage Talon Fire Tongue",    hp = 20143, count = 2 }
                },
                totalTrashHP = 2757160,      -- Total calculated by Python script
                trashRequiredPercent = 75    -- 50% required
            }
        }
    },
    ["Scholomance"] = {
        isDungeon = true,
        variants = {
            ["Default"] = {
                bosses = { "Jandice Barov", "Rattlegore", "Ras Frostwhisper", "Instructor Malicia", "Doctor Theolen Krastinov", "Lorekeeper Polkelt", "The Ravenian", "Lord Alexei Barov", "Lady Illucia Barov", "Darkmaster Gandling" },
                optionalBosses = {
                    ["Marduk Blackpool"] = true, -- Rare
                    ["Vectus"] = true            -- Rare
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
                totalTrashHP = 1852571,   -- Total: (9187*8)+(9479*1)+(7349*15)+(6432*11)+(7580*5)+(6633*6)+(8059*1)+(7819*2)+(7580*1)+(9771*3)+(7818*4)+(7580*2)+(9773*2)+(1167*4)+(7349*8)+(7580*2)+(8059*2)+(8059*2)+(7818*8)+(7580*11)+(7818*6)+(7580*6)+(7580*3)+(7819*2)+(7819*2)+(4265*13)+(8059*5)+(4397*9)+(16291*1)+(16791*4)+(15791*3)+(2297*17)+(9474*13)+(1628*32)+(2368*32)+(9771*16)+(1579*13)+(10072*2)+(7820*1)+(8300*1)+(4263*23)+(9771*5)+(7580*4)+(17292*2)
                trashRequiredPercent = 70, -- 50% required,
                trashRequiredPercentTested = true
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
