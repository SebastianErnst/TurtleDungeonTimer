# Timer.lua - Timer Logic Module

## Overview
Manages the dungeon timer lifecycle including start, stop, pause, reset, and automatic boss detection. Integrates with world buff tracking and group synchronization.

---

## Module Responsibilities
- Timer state management (running, paused, stopped)
- Boss kill detection and time tracking
- Death counting
- Group composition collection
- Run UUID generation
- Reset confirmation dialogs
- Timer display updates
- Integration with world buff tracking

---

## State Variables

### Timer State
```lua
self.isRunning              -- boolean: Timer currently active
self.startTime              -- number: GetTime() when timer started
self.killTimes              -- table: Boss kill data {name, time, splitTime}
self.deathCount             -- number: Player deaths during run
self.currentRunUUID         -- string: Unique identifier for current run
```

### Player/Group Info
```lua
self.playerName             -- string: Player name
self.guildName              -- string: Guild name or "No Guild"
self.groupClasses           -- table: Array of class names in group
```

### World Buff Integration
```lua
self.hasWorldBuffs          -- boolean: Any world buffs detected
self.hasCheckedWorldBuffs   -- boolean: Check performed flag
self.worldBuffPlayers       -- table: {playerName = buffName}
```

---

## Core Functions

### start()
**Purpose:** Start the dungeon timer  
**Pre-conditions:**
- `selectedDungeon` and `selectedVariant` must be set
- Boss list must not be empty
- Run must not be completed (all required bosses killed)
- Timer must not already be running

**Process:**
1. Set `isRunning = true`
2. Record `startTime = GetTime()`
3. Reset `killTimes` and `deathCount`
4. Generate new `currentRunUUID`
5. Collect player/guild info
6. Call `checkWorldBuffsOnStart()` for buff detection
7. Reset UI
8. Auto-minimize frame
9. Send chat confirmation

**Example:**
```lua
TurtleDungeonTimer:getInstance():start()
```

---

### stop()
**Purpose:** Stop/abort the current run without saving  
**Side Effects:**
- Sets `isRunning = false`
- Clears `startTime`
- Syncs stop with group via `syncTimerStop()`
- Updates start/pause button text

**Usage:**
```lua
timer:stop()
```

---

### reset()
**Purpose:** Check if reset is needed and show confirmation  
**Logic:**
- Checks if `lastRun` data exists for current dungeon
- Checks if current run has data (kills/deaths/running)
- Shows reset confirmation dialog if data would be lost
- Otherwise performs reset directly

**Called by:** Reset button click, slash commands

---

### performReset()
**Purpose:** Initiate group reset vote  
**Process:**
- If in group → calls `showResetInitiateConfirmation()`
- If solo → calls `performResetDirect()`

---

### showResetInitiateConfirmation()
**Purpose:** Show dialog to confirm initiating group reset vote  
**Dialog Options:**
- **Yes:** Calls `syncTimerReset()` to start group vote
- **No:** Closes dialog

**Notes:** Only initiator can start reset vote to prevent spam

---

### performResetDirect()
**Purpose:** Immediately reset timer without vote  
**Process:**
1. Set `isRunning = false`
2. Clear `startTime`
3. Reset `killTimes` array
4. Reset `deathCount = 0`
5. Reset world buff state (`hasWorldBuffs`, `hasCheckedWorldBuffs`, `worldBuffPlayers`)
6. Reset all boss kill states
7. Update UI
8. Save empty `lastRun` to clear previous data
9. Send chat confirmation

**Used by:** Solo players, after successful group vote

---

### performResetSilent()
**Purpose:** Reset without chat messages or sync  
**Difference from performResetDirect:**
- No chat messages
- No group sync
- Used for receiving sync commands

**Used by:** Group sync system when vote passes

---

### collectGroupClasses()
**Purpose:** Collect class names of all group members  
**Returns:** `table` - Array of class names

**Logic:**
```lua
local classes = {}
-- Check raid members
if GetNumRaidMembers() > 0 then
    for i = 1, GetNumRaidMembers() do
        local _, class = UnitClass("raid" .. i)
        if class then
            table.insert(classes, class)
        end
    end
-- Check party members
elseif GetNumPartyMembers() > 0 then
    table.insert(classes, select(2, UnitClass("player")))
    for i = 1, GetNumPartyMembers() do
        local _, class = UnitClass("party" .. i)
        if class then
            table.insert(classes, class)
        end
    end
else
    -- Solo
    table.insert(classes, select(2, UnitClass("player")))
end
return classes
```

---

### report(chatType)
**Purpose:** Report current/last run to chat channel  
**Parameters:**
- `chatType` - string: "SAY", "PARTY", "RAID", "GUILD"

**Output Format:**
```
[TDT] Dungeon (Variant) - 12:34 (Deaths: 2) [WB]
Boss 1: 3:45 (split: 3:45)
Boss 2: 8:20 (split: 4:35)
```

**Special Cases:**
- If no data available → "Keine Run-Daten verfügbar"
- Shows [WB] tag if world buffs detected
- Uses lastRun data if timer not running

---

## Update Loop

### setupUpdateLoop()
**Purpose:** Create frame for OnUpdate timer display  
**Called by:** `initialize()`

**Implementation:**
```lua
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function()
    TurtleDungeonTimer:getInstance():updateTimer()
end)
```

---

### updateTimer()
**Purpose:** Update timer display every frame  
**Process:**
1. Calculate elapsed time: `GetTime() - startTime`
2. Format time as MM:SS
3. Update timer text in UI
4. Update world buff indicator if detected
5. Color timer text:
   - Green (0, 1, 0) if run completed
   - Yellow (1, 0.84, 0) if running
   - White otherwise

**Called by:** OnUpdate frame script

---

## Reset Confirmation Dialog

### showResetConfirmation()
**Purpose:** Show simple yes/no dialog for reset  
**Dialog Elements:**
- Title: "Reset Run?"
- Message: "Do you want to reset the current run?"
- Buttons:
  - **Yes** → `performReset()`
  - **No** → Close dialog

**Frame Setup:**
```lua
dialog:SetWidth(300)
dialog:SetHeight(120)
dialog:SetFrameStrata("DIALOG")
dialog:EnableMouse(true)
```

---

## Start/Pause Button

### updateStartPauseButton()
**Purpose:** Update button text and click handler based on timer state  

**Button States:**
| Timer State | Button Text | OnClick Action |
|-------------|-------------|----------------|
| Not running, no data | "START" | `start()` |
| Running | "STOP" | `stop()` |
| Stopped with data | "CONTINUE" | Resume timer |

**Implementation:**
```lua
if not self.isRunning then
    if table.getn(self.killTimes) == 0 then
        button:SetText("START")
        button:SetScript("OnClick", function() timer:start() end)
    else
        button:SetText("CONTINUE")
        button:SetScript("OnClick", function() timer:start() end)
    end
else
    button:SetText("STOP")
    button:SetScript("OnClick", function() timer:stop() end)
end
```

---

## World Buff Integration

### World Buff Check on Start
When timer starts:
1. Calls `checkWorldBuffsOnStart()` from WorldBuffs.lua
2. Delayed 0.5s to ensure units loaded
3. Scans all party/raid members
4. Sets `hasWorldBuffs` flag if any detected
5. Stores `worldBuffPlayers` table with player:buff mapping
6. Updates UI with [WB] indicator

### Reset Behavior
All world buff state cleared on reset:
```lua
self.hasWorldBuffs = false
self.hasCheckedWorldBuffs = false
self.worldBuffPlayers = {}
```

---

## Integration Points

### Called By
- [UI.lua](UI.md) - Start/Stop/Reset buttons
- [Events.lua](EVENTS.md) - Auto-start on combat/death
- [Sync.lua](SYNC.md) - Group reset votes
- [Commands.lua](COMMANDS.md) - Slash commands

### Calls To
- [Core.lua](CORE.md) - State management, save functions
- [WorldBuffs.lua](WORLDBUFFS_README.md) - Buff detection
- [Sync.lua](SYNC.md) - Group synchronization
- [UI.lua](UI.md) - Display updates

---

## Lua 5.1 Compliance

### Table Operations
```lua
-- ✅ CORRECT
table.getn(self.killTimes)
table.insert(classes, className)

-- ❌ WRONG
#self.killTimes
```

### Event Handlers
```lua
-- ✅ CORRECT - Uses implicit globals
updateFrame:SetScript("OnUpdate", function()
    -- 'arg1' contains elapsed time
    TurtleDungeonTimer:getInstance():updateTimer()
end)

-- ❌ WRONG
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    -- Parameters don't work in 1.12
end)
```

---

## Error Handling

### Start Validation
Timer won't start if:
- No dungeon selected → Silent fail
- No variant selected → Silent fail
- Empty boss list → Silent fail
- All required bosses defeated → Silent fail
- Already running → Silent fail

### Reset Protection
- Checks for data before showing confirmation
- Prevents accidental data loss
- Group vote system for multi-player resets

---

## Performance Notes
- `updateTimer()` runs every frame (~60 FPS)
- Keep calculations minimal in update loop
- Only update UI text when value changes (optimization possible)
- World buff check delayed 0.5s to batch unit queries

---

## Testing Checklist
- [ ] Timer starts correctly with dungeon selected
- [ ] Timer stops and can be continued
- [ ] Reset confirmation shown when data exists
- [ ] Reset clears all state including world buffs
- [ ] Group reset vote works with 2+ players
- [ ] World buffs detected on start
- [ ] Report output correct in all chat channels
- [ ] Start/Pause button text updates correctly
- [ ] UUID generated uniquely for each run

---

## See Also
- [Core.lua Documentation](CORE.md)
- [World Buffs Feature](WORLDBUFFS_README.md)
- [Events Module](EVENTS.md)
- [Sync Module](SYNC.md)
