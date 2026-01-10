# Commands.lua - Slash Command Module

## Overview
Implements slash command handlers for addon control via chat commands. Provides simple text-based interface for core functionality.

---

## Module Responsibilities
- Slash command registration
- Command parsing and routing
- Auto-initialization on login

---

## Registered Commands

### Primary Commands
```lua
SLASH_TURTLEDUNGEONTIMER1 = "/tdt"
SLASH_TURTLEDUNGEONTIMER2 = "/turtledungeontimer"
```

**Usage:**
- `/tdt` - Short form
- `/turtledungeontimer` - Full form

Both commands work identically.

---

## Command Handler

### SlashCmdList["TURTLEDUNGEONTIMER"]
**Purpose:** Parse and execute slash commands  

**Implementation:**
```lua
SlashCmdList["TURTLEDUNGEONTIMER"] = function(msg)
    local timer = TurtleDungeonTimer:getInstance()
    
    if msg == "start" then
        timer:start()
    elseif msg == "stop" then
        timer:stop()
    elseif msg == "hide" then
        timer:hide()
    elseif msg == "toggle" or msg == "help" then
        timer:toggle()
    else
        timer:toggle()
    end
end
```

---

## Available Commands

### `/tdt` or `/tdt toggle`
**Action:** Toggle main frame visibility  
**Function:** `timer:toggle()`

**Behavior:**
- If frame hidden → Show frame
- If frame visible → Hide frame

**Use Case:** Quick access to addon window

---

### `/tdt start`
**Action:** Start dungeon timer  
**Function:** `timer:start()`

**Requirements:**
- Dungeon and variant must be selected
- Boss list must not be empty
- Timer must not already be running
- Run must not be completed

**Use Case:** Start timer without clicking UI button

---

### `/tdt stop`
**Action:** Stop current timer  
**Function:** `timer:stop()`

**Behavior:**
- Sets `isRunning = false`
- Clears `startTime`
- Syncs stop with group
- Updates UI button text

**Use Case:** Abort run without resetting data

---

### `/tdt hide`
**Action:** Hide main frame  
**Function:** `timer:hide()`

**Behavior:**
- Hides addon window
- Frame can be shown again with `/tdt` or minimap button

**Use Case:** Quickly hide frame to clear screen space

---

### `/tdt help`
**Action:** Toggle main frame (same as no argument)  
**Function:** `timer:toggle()`

**Note:** Help text not currently displayed. Future enhancement could show command list.

---

## Auto-Initialization

### PLAYER_LOGIN Event Handler
**Purpose:** Initialize addon on login  

**Implementation:**
```lua
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    TurtleDungeonTimer:getInstance():initialize()
end)
```

**Process:**
1. Player logs in
2. PLAYER_LOGIN event fires
3. Frame receives event
4. Calls `initialize()` on singleton instance
5. Addon fully loaded and ready

**Why PLAYER_LOGIN:**
- Fires after all SavedVariables loaded
- Player data available (name, guild, etc.)
- UI elements can be safely created
- Later than ADDON_LOADED (which fires per addon)

---

## Integration Points

### Called By
- User via chat commands
- WoW event system (PLAYER_LOGIN)

### Calls To
- [Core.lua](CORE.md) - `getInstance()`, `initialize()`
- [Timer.lua](TIMER.md) - `start()`, `stop()`
- [UI.lua](UI.md) - `toggle()`, `hide()`

---

## Command Parsing

### Current Implementation
**Pattern:** Exact string matching

```lua
if msg == "start" then
    -- Handle start
elseif msg == "stop" then
    -- Handle stop
-- ...
end
```

**Limitations:**
- No partial matching
- No arguments supported
- Case-sensitive (lowercase only)

### Future Enhancement
**Pattern:** Case-insensitive with arguments

```lua
local cmd, args = string.match(msg:lower(), "^(%S*)%s*(.-)$")

if cmd == "start" then
    timer:start()
elseif cmd == "reset" then
    timer:reset()
elseif cmd == "report" then
    local channel = args or "PARTY"
    timer:report(channel:upper())
elseif cmd == "export" then
    timer:showExportDialog()
elseif cmd == "history" then
    -- Show history
elseif cmd == "help" then
    -- Show help text
else
    timer:toggle()
end
```

---

## Command Reference Table

| Command | Action | Function | Requirements |
|---------|--------|----------|--------------|
| `/tdt` | Toggle window | `toggle()` | None |
| `/tdt toggle` | Toggle window | `toggle()` | None |
| `/tdt start` | Start timer | `start()` | Dungeon selected |
| `/tdt stop` | Stop timer | `stop()` | Timer running |
| `/tdt hide` | Hide window | `hide()` | None |
| `/tdt help` | Show help (planned) | `toggle()` | None |

**Not Yet Implemented:**
- `/tdt reset` - Reset timer
- `/tdt report [channel]` - Report to channel
- `/tdt export` - Show export dialog
- `/tdt history` - Show history
- `/tdt config` - Open options panel

---

## Lua 5.1 Compliance

### String Matching
```lua
-- ✅ CORRECT (current)
if msg == "start" then
    -- Exact match
end

-- ✅ CORRECT (future with patterns)
local cmd = string.match(msg:lower(), "^(%S+)")

-- ❌ WRONG
local cmd = msg:match("^(%S+)") -- :match() doesn't exist in Lua 5.1
```

### Event Handlers
```lua
-- ✅ CORRECT
initFrame:SetScript("OnEvent", function()
    -- Use implicit global 'event'
    if event == "PLAYER_LOGIN" then
        TurtleDungeonTimer:getInstance():initialize()
    end
end)

-- ❌ WRONG
initFrame:SetScript("OnEvent", function(self, event, ...)
    -- Parameters don't work in 1.12
end)
```

---

## Error Handling

### Missing Timer Instance
All commands call `getInstance()` which creates singleton if needed.

### Invalid Commands
Default case calls `toggle()` - safe fallback behavior.

### Failed Command Execution
Individual functions handle their own error cases:
- `start()` - Silent fail if requirements not met
- `stop()` - Silent fail if not running
- `toggle()` - Always succeeds

**No error messages displayed** - Future enhancement could add feedback

---

## Usage Examples

### Basic Usage
```
/tdt                  → Toggle window
/tdt start            → Start timer
/tdt stop             → Stop timer
/tdt hide             → Hide window
```

### Combining with Macros
```lua
-- Start timer macro
/tdt start

-- Toggle with keybind
/tdt toggle

-- Stop and hide
/tdt stop
/tdt hide
```

---

## Performance Notes

### Command Processing
- Minimal overhead (string comparison)
- No pattern matching in current implementation
- Instant execution

### Initialization
- Runs once per login
- Fires after all addons loaded
- No performance impact after initialization

---

## Testing Checklist
- [ ] `/tdt` toggles window
- [ ] `/tdt start` starts timer (with dungeon selected)
- [ ] `/tdt stop` stops timer (when running)
- [ ] `/tdt hide` hides window
- [ ] `/tdt help` shows help or toggles
- [ ] `/tdt <invalid>` toggles window (fallback)
- [ ] PLAYER_LOGIN triggers initialization
- [ ] Commands work immediately after login
- [ ] Both `/tdt` and `/turtledungeontimer` work

---

## Future Enhancements

### Planned Commands
```lua
/tdt reset                    -- Reset current run
/tdt report [say|party|raid]  -- Report to channel
/tdt export                   -- Show export dialog
/tdt history                  -- Show history panel
/tdt config                   -- Open options panel
/tdt select <dungeon>         -- Quick select dungeon
/tdt minimap                  -- Toggle minimap button
/tdt worldbuffs               -- Check world buffs manually
```

### Help Text
```lua
if cmd == "help" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer] Commands:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt - Toggle window")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt start - Start timer")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt stop - Stop timer")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt reset - Reset timer")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt report [channel] - Report run")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt export - Export run data")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt history - Show history")
    DEFAULT_CHAT_FRAME:AddMessage("  /tdt help - Show this help")
end
```

### Argument Parsing
```lua
-- Parse dungeon selection
/tdt select stratholme live
-- → Select Stratholme (Live) variant

-- Parse report channel
/tdt report guild
-- → Report to guild chat
```

---

## See Also
- [Core Module](CORE.md)
- [Timer Module](TIMER.md)
- [UI Module](UI.md)
