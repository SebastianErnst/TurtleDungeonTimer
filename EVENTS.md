# Events.lua - Event Handler Module

## Overview
Handles all WoW event registrations and responses including combat log parsing for boss kills, player deaths, zone changes, and auto-start triggers.

---

## Module Responsibilities
- Combat log parsing for boss kills and deaths
- Player death detection and counting
- Auto-start timer on combat/death
- Zone change detection for dungeon switching
- Completion detection when all bosses defeated
- Export reminder dialogs
- Boss row UI updates

---

## Registered Events

### Event Frames
```lua
self.eventFrame        -- Frame for CHAT_MSG_COMBAT_HOSTILE_DEATH
self.deathEventFrame   -- Frame for PLAYER_DEAD and PLAYER_REGEN_DISABLED
```

### Event Table

| Event | Purpose | Handler |
|-------|---------|---------|
| `CHAT_MSG_COMBAT_HOSTILE_DEATH` | Boss kill detection, group member deaths | `onCombatLog()` |
| `PLAYER_DEAD` | Player death counting | `onDeath()` |
| `PLAYER_REGEN_DISABLED` | Combat start (auto-start timer) | `onCombatStart()` |
| `ZONE_CHANGED_NEW_AREA` | Zone change detection | `onZoneChanged()` |

---

## Core Functions

### registerEvents()
**Purpose:** Register all event listeners  
**Called by:** `Core.lua:initialize()`

**Implementation:**
```lua
-- Combat log frame
if not self.eventFrame then
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    self.eventFrame:SetScript("OnEvent", function()
        TurtleDungeonTimer:getInstance():onCombatLog(arg1)
    end)
end

-- Death event frame
if not self.deathEventFrame then
    self.deathEventFrame = CreateFrame("Frame")
    self.deathEventFrame:RegisterEvent("PLAYER_DEAD")
    self.deathEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.deathEventFrame:SetScript("OnEvent", function()
        local timer = TurtleDungeonTimer:getInstance()
        if event == "PLAYER_DEAD" then
            timer:onDeath()
        elseif event == "PLAYER_REGEN_DISABLED" then
            timer:onCombatStart()
        end
    end)
end
```

**Note:** Uses implicit globals `event` and `arg1`

---

## Combat Log Parsing

### onCombatLog(msg)
**Purpose:** Parse combat log for boss kills and group deaths  
**Parameters:**
- `msg` - string: Combat log message

**Early Exit:** If timer not running

**Death Detection Pattern:**
```lua
-- Pattern 1: "X dies."
local _, _, name = string.find(msg, "(.+) dies%.")
-- Pattern 2: "X has died."
if not name then
    _, _, name = string.find(msg, "(.+) has died%.")
end
```

**Group Member Death Handling:**
1. Extract name from death message
2. Check if it's a group member:
   - Player (skip - handled by PLAYER_DEAD)
   - Raid members (1 to GetNumRaidMembers())
   - Party members (1 to GetNumPartyMembers())
3. If group member:
   - Increment `deathCount`
   - Update UI death counter
   - Save progress
   - Sync with group
   - Send chat message

**Boss Kill Detection:**
```lua
for i = 1, table.getn(self.bossList) do
    local boss = self.bossList[i]
    if boss.name == name and not boss.defeated then
        -- Calculate times
        local currentTime = GetTime()
        local elapsedTime = currentTime - self.startTime
        local lastKillTime = 0
        if table.getn(self.killTimes) > 0 then
            lastKillTime = self.killTimes[table.getn(self.killTimes)].time
        end
        local splitTime = elapsedTime - lastKillTime
        
        -- Record kill
        table.insert(self.killTimes, {
            name = boss.name,
            time = elapsedTime,
            splitTime = splitTime
        })
        
        -- Mark boss defeated
        boss.defeated = true
        
        -- Update UI
        self:updateBossRow(i, elapsedTime, splitTime)
        
        -- Save progress
        self:saveLastRun()
        
        -- Sync with group
        self:syncBossKill(boss.name, elapsedTime, splitTime)
        
        -- Check completion
        local requiredKills = self:getRequiredBossKills()
        local requiredBosses = self:getRequiredBossCount()
        if requiredKills >= requiredBosses and requiredBosses > 0 then
            self:onAllBossesDefeated()
        end
        
        break
    end
end
```

**Lua 5.1 Pattern Notes:**
- Use `%` for escapes (not `\`)
- `%.` matches literal period
- `(.+)` captures one or more characters

---

## Death Handling

### onDeath()
**Purpose:** Handle player death event  
**Called by:** PLAYER_DEAD event

**Auto-Start Logic:**
```lua
if not self.isRunning and self.selectedDungeon and self.selectedVariant then
    -- Auto-start timer on first death
    self:start()
end
```

**If Timer Running:**
1. Increment `deathCount`
2. Update death text in UI:
   ```lua
   if self.frame and self.frame.deathText then
       self.frame.deathText:SetText("Deaths: " .. self.deathCount)
   end
   ```
3. Save progress via `saveLastRun()`

**Why Auto-Start:** Players often die before manually starting timer, so first death triggers timer automatically if dungeon selected.

---

## Combat Detection

### onCombatStart()
**Purpose:** Auto-start timer when entering combat  
**Called by:** PLAYER_REGEN_DISABLED event

**Conditions:**
- Timer not already running
- Dungeon selected
- Variant selected

**Action:**
```lua
self:start()
```

**Use Case:** Convenience feature - timer starts automatically when pulling first mob

---

## Zone Detection

### onZoneChanged()
**Purpose:** Auto-select dungeon when entering dungeon zone  
**Called by:** ZONE_CHANGED_NEW_AREA event

**Process:**
1. Get current zone: `GetRealZoneText()`
2. Get subzone: `GetSubZoneText()`
3. Loop through `DUNGEON_DATA`:
   ```lua
   for dungeonName, dungeonData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
       -- Try matching zone name
       if zoneName == dungeonName then
           self:selectDungeon(dungeonName)
           return
       end
       
       -- Try matching subzone
       if subZoneName == dungeonName then
           self:selectDungeon(dungeonName)
           return
       end
       
       -- Try matching variant names
       if dungeonData.variants then
           for variantName, _ in pairs(dungeonData.variants) do
               if zoneName == variantName or subZoneName == variantName then
                   self:selectDungeon(dungeonName)
                   self:selectVariant(variantName)
                   return
               end
           end
       end
   end
   ```

**Important:** Timer continues running if player leaves zone (e.g., death, teleport). Must manually stop/reset.

---

## Completion Handling

### onAllBossesDefeated()
**Purpose:** Handle run completion when all required bosses killed  
**Triggered by:** Boss kill detection in `onCombatLog()`

**Process:**
1. Stop timer: `self.isRunning = false`
2. Calculate final time: `GetTime() - self.startTime`
3. Save best time: `saveBestTime(finalTime)`
4. Save last run: `saveLastRun()`
5. Save to history: `saveToHistory(finalTime, true)` (marked as completed)
6. Update UI:
   - Change button text to "START"
   - Highlight header green:
     ```lua
     self.frame.headerBg:SetBackdropColor(0.1, 0.5, 0.1, 0.8)
     self.frame.dungeonNameText:SetTextColor(0, 1, 0)
     ```

**No Export Prompt:** Completion automatically saves to history. Use Export button or History panel to export later.

---

## UI Update Functions

### updateBossRow(index, elapsed, splitTime)
**Purpose:** Update boss row UI with kill time  
**Parameters:**
- `index` - number: Boss index in `bossList`
- `elapsed` - number: Total elapsed time
- `splitTime` - number: Time since previous boss

**UI Changes:**
1. Set boss name text color to green (0, 1, 0)
2. Show kill time:
   ```lua
   local minutes = math.floor(elapsed / 60)
   local seconds = mod(elapsed, 60)
   timeText:SetText(string.format("%d:%02d", minutes, seconds))
   ```
3. Show split time:
   ```lua
   local splitMin = math.floor(splitTime / 60)
   local splitSec = mod(splitTime, 60)
   splitText:SetText(string.format("(%d:%02d)", splitMin, splitSec))
   ```

**Lua 5.1 Note:** Uses `mod()` function, not `%` operator

---

## Export Reminder Dialog

### showExportBeforeResetDialog()
**Purpose:** Prompt user to export before reset (currently unused)  
**Dialog Options:**
- **Exportieren:** Open export dialog, then perform reset
- **Überspringen:** Perform reset without export

**Note:** This function exists but is not currently called. Could be integrated into reset flow if desired.

---

## Event Handler Patterns (Lua 5.1)

### Implicit Globals
All event handlers use implicit globals:
```lua
-- ✅ CORRECT
frame:SetScript("OnEvent", function()
    local timer = TurtleDungeonTimer:getInstance()
    if event == "PLAYER_DEAD" then
        timer:onDeath()
    end
end)

-- ❌ WRONG (Modern WoW)
frame:SetScript("OnEvent", function(self, event, ...)
    -- Parameters don't work in 1.12
end)
```

### Available Globals by Event
- `event` - Event name string
- `arg1` to `arg9` - Event-specific arguments
- `this` - Frame that received event

---

## Integration Points

### Called By
- WoW Event System (automatic)
- Core initialization via `registerEvents()`

### Calls To
- [Timer.lua](TIMER.md) - `start()`, `stop()`
- [Core.lua](CORE.md) - `saveLastRun()`, `saveBestTime()`, `saveToHistory()`
- [Sync.lua](SYNC.md) - `syncBossKill()`, `syncDeath()`
- [UI.lua](UI.md) - `updateBossRow()`

---

## Boss Kill Detection Logic

### Required Boss Completion Check
```lua
local requiredKills = 0
local requiredBosses = 0

for i = 1, table.getn(self.bossList) do
    local boss = self.bossList[i]
    if not boss.optional then
        requiredBosses = requiredBosses + 1
        if boss.defeated then
            requiredKills = requiredKills + 1
        end
    end
end

if requiredKills >= requiredBosses and requiredBosses > 0 then
    self:onAllBossesDefeated()
end
```

**Note:** Optional bosses don't count toward completion

---

## Performance Considerations

### Combat Log Volume
- CHAT_MSG_COMBAT_HOSTILE_DEATH fires for all deaths in combat log
- Early exit if timer not running
- String pattern matching on every death message
- Boss list iteration for each potential boss kill

### Optimization Tips
1. Keep `bossList` small (only selected dungeon/variant)
2. Use early returns to skip unnecessary processing
3. Mark bosses as defeated to skip already-killed bosses
4. Pattern matching is relatively fast for short strings

---

## Error Handling

### Nil Checks
```lua
if self.frame and self.frame.deathText then
    self.frame.deathText:SetText("Deaths: " .. self.deathCount)
end
```

### Empty Tables
```lua
if table.getn(self.killTimes) > 0 then
    -- Safe to access last kill time
end
```

### Missing Boss Data
Boss kill detection gracefully handles:
- Boss not in current `bossList`
- Boss already defeated
- Empty boss list

---

## Testing Checklist
- [ ] Boss kills detected correctly in combat log
- [ ] Optional bosses don't trigger completion
- [ ] Player death increments counter
- [ ] Group member deaths counted correctly
- [ ] Auto-start works on combat
- [ ] Auto-start works on death
- [ ] Zone change auto-selects dungeon
- [ ] Completion triggers on last required boss
- [ ] UI updates show correct times
- [ ] Timer continues running after zone change

---

## See Also
- [Timer Module](TIMER.md)
- [Core Module](CORE.md)
- [Sync Module](SYNC.md)
- [UI Module](UI.md)
