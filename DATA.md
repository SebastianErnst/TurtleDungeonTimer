# Data.lua - Dungeon and Boss Data Module

## Overview
Contains all dungeon, raid, and boss definitions. Serves as the central data repository for dungeon selection, boss lists, and variant configurations.

---

## Module Responsibilities
- Dungeon definitions with variants
- Boss lists (required and optional)
- Raid definitions
- Zone name mappings
- Variant configurations

---

## Data Structure

### DUNGEON_DATA Table
```lua
TurtleDungeonTimer.DUNGEON_DATA = {
    ["Dungeon Name"] = {
        isDungeon = true,           -- boolean: Is this a 5-man dungeon (vs raid)
        variants = {
            ["Variant Name"] = {
                bosses = {...},           -- table: Required boss names
                optionalBosses = {...}    -- table: Optional boss name → true
            }
        }
    }
}
```

---

## Current Dungeons

### Black Morass
**Type:** 5-man Dungeon (Turtle WoW custom)  
**Variants:** 1 (Default)

```lua
["Black Morass"] = {
    isDungeon = true,
    variants = {
        ["Default"] = {
            bosses = {"Chronos", "Temporus", "Epoch Hunter", "Aeonus"}
        }
    }
}
```

**Bosses:** 4 required, 0 optional

---

### Stormwind Vault
**Type:** 5-man Dungeon (Turtle WoW custom)  
**Variants:** 1 (Default)

```lua
["Stormwind Vault"] = {
    isDungeon = true,
    variants = {
        ["Default"] = {
            bosses = {"Vault Guardian", "Arcane Protector", "Vault Keeper"}
        }
    }
}
```

**Bosses:** 3 required, 0 optional

---

### Stratholme
**Type:** 5-man Dungeon  
**Variants:** 2 (Live, Undead)

```lua
["Stratholme"] = {
    isDungeon = true,
    variants = {
        ["Live"] = {
            bosses = {
                "Hearthsinger Forresten",
                "Timmy the Cruel",
                "Commander Malor",
                "Willey Hopebreaker",
                "Instructor Galford",
                "Balnazzar",
                "The Unforgiven",
                "Baroness Anastari",
                "Nerub'enkan",
                "Maleki the Pallid",
                "Magistrate Barthilas",
                "Ramstein the Gorger",
                "Baron Rivendare"
            }
        },
        ["Undead"] = {
            bosses = {
                "The Unforgiven",
                "Baroness Anastari",
                "Nerub'enkan",
                "Maleki the Pallid",
                "Magistrate Barthilas",
                "Ramstein the Gorger",
                "Baron Rivendare"
            }
        }
    }
}
```

**Live Side:** 13 bosses  
**Undead Side:** 7 bosses

---

### Dire Maul
**Type:** 5-man Dungeon  
**Variants:** 3 (North, East, West)

```lua
["Dire Maul"] = {
    isDungeon = true,
    variants = {
        ["North"] = {
            bosses = {
                "Guard Mol'dar",
                "Stomper Kreeg",
                "Guard Fengus",
                "Guard Slip'kik",
                "Captain Kromcrush",
                "Cho'Rush the Observer",
                "King Gordok"
            }
        },
        ["East"] = {
            bosses = {
                "Pusillin",
                "Zevrim Thornhoof",
                "Hydrospawn",
                "Lethtendris",
                "Alzzin the Wildshaper"
            },
            optionalBosses = {
                ["Old Ironbark"] = true
            }
        },
        ["West"] = {
            bosses = {
                "Tendris Warpwood",
                "Illyanna Ravenoak",
                "Magister Kalendris",
                "Immol'thar",
                "Prince Tortheldrin"
            },
            optionalBosses = {
                ["Tsu'zee"] = true
            }
        }
    }
}
```

**North:** 7 bosses (Tribute Run)  
**East:** 5 bosses + 1 optional  
**West:** 5 bosses + 1 optional

---

### Upper Blackrock Spire
**Type:** 10-man Raid  
**Variants:** 1 (Default)

```lua
["Upper Blackrock Spire"] = {
    isDungeon = false,  -- 10-man raid
    variants = {
        ["Default"] = {
            bosses = {
                "Pyroguard Emberseer",
                "Solakar Flamewreath",
                "Jed Runewatcher",
                "Goraluk Anvilcrack",
                "Warchief Rend Blackhand",
                "The Beast",
                "General Drakkisath"
            },
            optionalBosses = {
                ["Quartermaster Zigris"] = true,
                ["Halycon"] = true,
                ["Gizrul the Slavener"] = true,
                ["Overlord Wyrmthalak"] = true,
                ["Mother Smolderweb"] = true
            }
        }
    }
}
```

**Required:** 7 bosses  
**Optional:** 5 bosses

---

## Boss List Format

### Required Bosses
**Array format:**
```lua
bosses = {
    "Boss Name 1",
    "Boss Name 2",
    "Boss Name 3"
}
```

**Characteristics:**
- Listed in expected kill order
- All must be defeated for run completion
- Progress tracking counts these only

---

### Optional Bosses
**Table format:**
```lua
optionalBosses = {
    ["Optional Boss 1"] = true,
    ["Optional Boss 2"] = true
}
```

**Characteristics:**
- Not required for completion
- Displayed separately in UI (under "Optional" header)
- Still tracked if killed
- Don't count toward completion percentage

---

## Variant Configurations

### Single Variant Dungeons
Auto-select variant when dungeon chosen:
```lua
["Dungeon Name"] = {
    isDungeon = true,
    variants = {
        ["Default"] = {
            bosses = {...}
        }
    }
}
```

**Examples:** Black Morass, Stormwind Vault, Upper Blackrock Spire

---

### Multiple Variant Dungeons
Show variant submenu:
```lua
["Dungeon Name"] = {
    isDungeon = true,
    variants = {
        ["Variant 1"] = {
            bosses = {...}
        },
        ["Variant 2"] = {
            bosses = {...}
        }
    }
}
```

**Examples:** Stratholme (Live/Undead), Dire Maul (North/East/West)

---

## Data Access Patterns

### Load Dungeon List
```lua
for dungeonName, dungeonData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
    -- dungeonName: "Stratholme"
    -- dungeonData: {isDungeon = true, variants = {...}}
end
```

---

### Get Variant Data
```lua
local dungeonData = TurtleDungeonTimer.DUNGEON_DATA["Stratholme"]
if dungeonData and dungeonData.variants then
    local variantData = dungeonData.variants["Live"]
    -- variantData: {bosses = {...}}
end
```

---

### Load Boss List
```lua
local variantData = TurtleDungeonTimer.DUNGEON_DATA[dungeon].variants[variant]
if variantData then
    local bossList = {}
    
    -- Add required bosses
    for i = 1, table.getn(variantData.bosses) do
        table.insert(bossList, {
            name = variantData.bosses[i],
            defeated = false,
            optional = false
        })
    end
    
    -- Add optional bosses
    if variantData.optionalBosses then
        for bossName, _ in pairs(variantData.optionalBosses) do
            table.insert(bossList, {
                name = bossName,
                defeated = false,
                optional = true
            })
        end
    end
end
```

---

## Commented Out Dungeons

The file contains extensive commented-out definitions for additional classic dungeons:

**Not Currently Active:**
- Ragefire Chasm
- Wailing Caverns
- The Deadmines
- Shadowfang Keep
- Blackfathom Deeps
- The Stockade
- Gnomeregan
- Razorfen Kraul
- Scarlet Monastery (4 wings)
- Razorfen Downs
- Uldaman
- Zul'Farrak
- Maraudon
- Sunken Temple
- Scholomance
- Lower Blackrock Spire
- Blackrock Depths

**To Enable:**
```lua
-- Remove comment markers (--) from desired dungeon block
["Dungeon Name"] = {
    isDungeon = true,
    variants = {
        ["Default"] = {
            bosses = {...}
        }
    }
}
```

---

## Integration Points

### Called By
- [UIMenus.lua](UIMENUS.md) - Dungeon menu population
- [Core.lua](CORE.md) - Variant loading
- [Events.lua](EVENTS.md) - Zone-based dungeon selection

### Calls To
- None (pure data module)

---

## Lua 5.1 Compliance

### Table Iteration
```lua
-- ✅ CORRECT
for dungeonName, dungeonData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
    -- pairs() works for hash tables
end

for i = 1, table.getn(bosses) do
    -- table.getn() for array length
end

-- ❌ WRONG
for i = 1, #bosses do
    -- # operator doesn't exist
end
```

---

## Data Validation

### Required Fields
Each dungeon entry must have:
- `isDungeon` - boolean
- `variants` - table with at least one variant
- Each variant must have `bosses` - array of strings

### Optional Fields
- `optionalBosses` - table mapping boss names to true

### Validation Checks (Future)
```lua
function validateDungeonData()
    for dungeonName, dungeonData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
        assert(type(dungeonData.isDungeon) == "boolean", "Missing isDungeon")
        assert(dungeonData.variants, "Missing variants")
        
        for variantName, variantData in pairs(dungeonData.variants) do
            assert(variantData.bosses, "Missing bosses array")
            assert(table.getn(variantData.bosses) > 0, "Empty bosses array")
        end
    end
end
```

---

## Boss Name Requirements

### Format Rules
- Use exact combat log names
- Case-sensitive
- Include titles (e.g., "Baron Rivendare" not "Rivendare")
- No special characters that break string matching

### Common Issues
```lua
-- ✅ CORRECT
"Magistrate Barthilas"        -- Full name with title

-- ❌ WRONG
"Barthilas"                   -- Missing title
"magistrate barthilas"        -- Wrong case
"Magistrate_Barthilas"        -- Underscores (only for export)
```

---

## Adding New Dungeons

### Template
```lua
["Dungeon Name"] = {
    isDungeon = true,  -- or false for raids
    variants = {
        ["Default"] = {
            bosses = {
                "Boss 1",
                "Boss 2",
                "Boss 3"
            },
            optionalBosses = {
                ["Optional Boss 1"] = true
            }
        }
    }
}
```

### Steps
1. Determine exact boss names from combat log
2. Order bosses by typical kill sequence
3. Mark optional bosses separately
4. Set `isDungeon` appropriately
5. Test boss kill detection in-game

---

## Performance Notes

### Data Loading
- All data loaded at initialization
- No runtime file I/O
- Entire table in memory (~10KB)

### Access Performance
- Hash table lookup: O(1)
- Boss list iteration: O(n) where n = boss count

---

## Testing Checklist
- [ ] All boss names match combat log exactly
- [ ] Boss order logical for typical runs
- [ ] Optional bosses marked correctly
- [ ] Variants named clearly
- [ ] isDungeon flag correct
- [ ] No duplicate boss names in same variant
- [ ] Zone auto-selection works (if applicable)

---

## Future Enhancements

### Raid Support
```lua
["Molten Core"] = {
    isDungeon = false,
    isRaid = true,
    playerCount = 40,
    variants = {
        ["Default"] = {
            bosses = {
                "Lucifron",
                "Magmadar",
                -- ... all 10 bosses
                "Ragnaros"
            }
        }
    }
}
```

### Boss Metadata
```lua
bosses = {
    {name = "Boss Name", minLevel = 60, maxLevel = 62, elite = true},
    -- ...
}
```

### Zone Mapping
```lua
zoneName = "Stratholme",
subZones = {"King's Square", "The Scarlet Bastion"},
```

---

## See Also
- [UIMenus Module](UIMENUS.md)
- [Core Module](CORE.md)
- [Events Module](EVENTS.md)
