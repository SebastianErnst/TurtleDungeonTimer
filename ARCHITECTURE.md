# Turtle Dungeon Timer - Architektur Dokumentation

**Version**: 1.0.1-alpha  
**Zielplattform**: WoW 1.12 (Vanilla) / Turtle WoW

---

## Überblick

Turtle Dungeon Timer ist ein modulares WoW-Addon für präzises Dungeon-Timing mit Gruppen-Synchronisation, World Buff Detection und Export-Funktionalität.

---

## Modul-Hierarchie

```
┌─────────────────────────────────────────┐
│         Commands.lua (Entry Point)      │
│         - Slash Commands                │
│         - PLAYER_LOGIN Event            │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│          Core.lua (Singleton)           │
│          - State Management             │
│          - SavedVariables               │
│          - Initialization               │
└──┬──────┬──────┬──────┬──────┬─────────┘
   │      │      │      │      │
   ↓      ↓      ↓      ↓      ↓
┌──────┐┌──────┐┌─────┐┌─────┐┌──────────┐
│Timer ││Events││Sync ││Data ││UI/UIMenus│
└──┬───┘└──┬───┘└──┬──┘└─────┘└────┬─────┘
   │       │       │                │
   ↓       ↓       ↓                ↓
┌────────────────────────────────────────┐
│        Specialized Modules             │
│  ┌─────────┐ ┌────────┐ ┌──────────┐ │
│  │WorldBuff│ │Export  │ │Minimap   │ │
│  └─────────┘ └────────┘ └──────────┘ │
└────────────────────────────────────────┘
```

---

## Load Order (TOC)

Die Reihenfolge in `TurtleDungeonTimer.toc` ist **kritisch** für Lua 5.1:

```toc
Core.lua           # 1. Namespace & Singleton erstellen
Data.lua           # 2. Statische Daten laden
UI.lua             # 3. UI-Framework
UIMenus.lua        # 4. UI-Komponenten (benötigt UI.lua)
Minimap.lua        # 5. Minimap Button (unabhängig)
Timer.lua          # 6. Timer-Logik (nutzt Core + UI)
WorldBuffs.lua     # 7. Buff-Tracking (nutzt Core)
Events.lua         # 8. Event-Handler (nutzt Core + Timer)
Sync.lua           # 9. Gruppen-Sync (nutzt Events)
Export.lua         # 10. Export-System (nutzt Core)
Commands.lua       # 11. ZULETZT - Initialisierung
```

**Warum diese Reihenfolge?**
- `Core.lua` muss zuerst laden (definiert Namespace)
- `Data.lua` vor `UI.lua` (Dungeon-Daten für UI)
- `UI.lua` vor `UIMenus.lua` (Helper-Funktionen)
- `Commands.lua` zuletzt (ruft alle initialize() Funktionen)

---

## Datenfluss

### Timer Start Flow

```
User clicks START
      ↓
Timer:start()
      ↓
  ┌───┴───────────────────────────┐
  ↓                               ↓
Timer State Update         WorldBuffs:checkWorldBuffsOnStart()
(isRunning=true)                  ↓
      ↓                    Delay 0.5s → scanGroupForWorldBuffs()
Core:saveLastRun()                ↓
      ↓                    markRunWithWorldBuffs() → Chat Message
UI:resetUI()
      ↓
UI:toggleMinimized()
```

### Boss Kill Flow

```
Combat Log: "Boss dies."
      ↓
Events:onCombatLog(msg)
      ↓
String Pattern Match Boss Name
      ↓
  ┌───┴────────────────────┐
  ↓                        ↓
Calculate Split Time    Update UI Boss Row
      ↓                        ↓
Add to self.killTimes   Green Checkmark + Time
      ↓                        ↓
Core:saveLastRun()      Compare with Best Time
      ↓                        ↓
Sync:syncBossKill()     Color code (green/red)
      ↓
Check if all bosses defeated
      ↓
Events:onAllBossesDefeated()
      ↓
Core:saveBestTime()
Core:saveToHistory(completed=true)
```

### Group Sync Flow

```
Player Action (Kill/Death/Reset)
      ↓
Sync:sendSyncMessage(type, data)
      ↓
Build message: "VERSION|TYPE|DATA"
      ↓
SendAddonMessage("TDT_SYNC", msg, channel)
      ↓
[Network]
      ↓
Other Client receives CHAT_MSG_ADDON
      ↓
Sync:onSyncMessage(msg, sender)
      ↓
Parse message type
      ↓
  ┌───┴───────────┬───────────┐
  ↓               ↓           ↓
BOSS_KILL      DEATH      RESET
  ↓               ↓           ↓
Update UI    Increment    Show Vote Dialog
             Death Count   or Execute Reset
```

---

## State Management

### Zentrale State Location

Alle Addon-States werden in der **Core Singleton-Instanz** gespeichert:

```lua
local timer = TurtleDungeonTimer:getInstance()

-- Timer State
timer.isRunning
timer.startTime
timer.killTimes
timer.deathCount

-- Selection State
timer.selectedDungeon
timer.selectedVariant
timer.bossList

-- UI State
timer.minimized
timer.frame

-- World Buff State
timer.hasWorldBuffs
timer.worldBuffPlayers
```

### Persistent State (SavedVariables)

```lua
TurtleDungeonTimerDB = {
    bestTimes = {},     -- Per-Dungeon/Variant Best Times
    history = {},       -- Last 10 Runs
    lastRun = {},       -- Unfinished Run State
    lastSelection = {}, -- Last Selected Dungeon
    position = {},      -- Window Position
    visible = false,    -- Window Visibility
    minimized = false,  -- Minimized State
    minimapAngle = 200  -- Minimap Button Position
}
```

**Wann wird gespeichert?**
- `lastRun`: Nach jedem Boss-Kill, Death, Stop
- `bestTimes`: Bei Run-Completion wenn neue Best Time
- `history`: Bei Run-Completion (Stop/All Bosses)
- `position`: Bei OnDragStop
- `visible/minimized`: Bei Show/Hide/Toggle
- `minimapAngle`: Bei Minimap-Button Drag

**Wann wird geladen?**
- `PLAYER_LOGIN` Event in `Commands.lua`
- `Core:initialize()` → `restoreLastRun()`

---

## Event System

### Registrierte Events

| Event | Frame | Handler | Zweck |
|-------|-------|---------|-------|
| `PLAYER_LOGIN` | Commands initFrame | initialize() | Addon starten |
| `CHAT_MSG_COMBAT_HOSTILE_DEATH` | eventFrame | onCombatLog() | Boss-Kills erkennen |
| `CHAT_MSG_COMBAT_FRIENDLY_DEATH` | eventFrame | onCombatLog() | Party-Deaths |
| `PLAYER_DEAD` | deathEventFrame | onDeath() | Player-Death |
| `PLAYER_REGEN_DISABLED` | eventFrame | onCombatStart() | Kampf-Start (Auto-Start) |
| `ZONE_CHANGED_NEW_AREA` | eventFrame | onZoneChanged() | Zone-Wechsel |
| `PLAYER_ENTERING_WORLD` | eventFrame | onZoneChanged() | Login/Reload |
| `CHAT_MSG_ADDON` | syncFrame | onSyncMessage() | Gruppen-Sync |
| `PARTY_MEMBERS_CHANGED` | syncFrame | checkForAddons() | Party-Änderung |
| `RAID_ROSTER_UPDATE` | syncFrame | checkForAddons() | Raid-Änderung |

### OnUpdate Frames

| Frame | Zweck | Frequenz |
|-------|-------|----------|
| `updateFrame` | Timer-Anzeige Update | Jedes Frame |
| `worldBuffCheckFrame` | World Buff Scan (einmalig) | 0.5s Delay |

---

## UI-Struktur

### Frame-Hierarchie

```
TurtleDungeonTimerMainFrame (Draggable)
├── headerBg (Header Background)
│   ├── dungeonNameText
│   ├── timeText
│   ├── bestTimeText
│   ├── deathText
│   ├── worldBuffFrame
│   │   └── worldBuffText
│   └── minimizeButton
├── dungeonSelector (Button)
├── startPauseButton
├── resetButton
├── reportButton
│   └── reportDropdown (Hidden by default)
├── exportButton
├── historyButton
│   └── historyDropdown (Hidden by default)
└── bossScrollFrame
    └── scrollChild
        ├── bossRow[1]
        ├── bossRow[2]
        └── ...
```

### Frame-Ebenen (FrameStrata)

- **BACKGROUND**: Main Frame
- **OVERLAY**: Text Elements, Boss Rows
- **DIALOG**: Dropdowns, Report Menu
- **FULLSCREEN_DIALOG**: Export Dialog, Confirmations

---

## Kommunikations-Pattern

### Addon-Kommunikation (Sync)

```lua
-- Prefix Registration
RegisterAddonMessagePrefix("TDT_SYNC")

-- Send
SendAddonMessage("TDT_SYNC", "1.0|BOSS|BossName:123.45", "RAID")

-- Receive
CHAT_MSG_ADDON → arg1="TDT_SYNC", arg2=message, arg4=sender
```

**Message Format**:
```
VERSION|TYPE|DATA
```

**Beispiele**:
```
1.0|ADDON_CHECK
1.0|BOSS|Ragnaros:1234.5
1.0|DEATH|3
1.0|RESET_REQUEST
1.0|RESET_VOTE|yes
1.0|RESET_EXECUTE
```

---

## Lua 5.1 Constraints

### Wichtige Unterschiede zu modernem Lua

| Modern Lua | Lua 5.1 (WoW 1.12) |
|-----------|---------------------|
| `#table` | `table.getn(table)` |
| `a % b` | `mod(a, b)` |
| `string.gmatch()` | `string.gfind()` |
| `function(self, event, ...)` | Implicit globals: `this`, `event`, `arg1`-`arg9` |
| `frame:EnableMouseWheel(true)` | `frame:EnableMouseWheel()` (no param) |

### Event Handler Pattern

```lua
-- ❌ WRONG (Modern)
frame:SetScript("OnEvent", function(self, event, ...)
    print(event) -- DOES NOT WORK
end)

-- ✅ CORRECT (1.12)
frame:SetScript("OnEvent", function()
    -- Use implicit globals
    local frame = this
    local eventName = event
    local arg1Value = arg1
    
    if event == "PLAYER_DEAD" then
        -- Handle death
    end
end)
```

---

## Performance Considerations

### OnUpdate Optimization

```lua
-- Timer OnUpdate läuft nur wenn Timer läuft
function TurtleDungeonTimer:updateTimer()
    if not self.frame then return end
    
    if self.isRunning and self.startTime then
        -- Update time display (jedes Frame)
        local elapsed = GetTime() - self.startTime
        self.frame.timeText:SetText(self:formatTime(elapsed))
    end
    
    -- Death count update (nicht zeitkritisch)
    if self.frame.deathText then
        self.frame.deathText:SetText("Deaths: " .. self.deathCount)
    end
end
```

**Impact**: ~0.001ms pro Frame bei laufendem Timer

### Table Operations

```lua
-- ✅ GOOD: Direct index access
local boss = self.killTimes[5]

-- ❌ BAD: Nested iteration
for i = 1, table.getn(self.killTimes) do
    for j = 1, table.getn(self.bossList) do
        -- Avoid nested loops
    end
end
```

### String Operations

```lua
-- ✅ GOOD: Pre-compute strings
local prefix = "|cff00ff00[TDT]|r "
DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)

-- ❌ BAD: Repeated concatenation in loop
for i = 1, 100 do
    local msg = "|cff00ff00[TDT]|r " .. messages[i]
end
```

---

## Testing Strategy

### Manual Testing

```lua
-- Start Timer
/tdt
-- Select dungeon, click START

-- Simulate Boss Kill
/script TurtleDungeonTimer:getInstance():onCombatLog("Ragnaros dies.")

-- Simulate Death
/script TurtleDungeonTimer:getInstance():onDeath()

-- Check World Buffs
/script local t = TurtleDungeonTimer:getInstance(); print(t.hasWorldBuffs)

-- Export Current Run
-- Click EXPORT button

-- View History
-- Click HISTORY button
```

### Debug Commands

```lua
-- Enable Lua Errors
/console scriptErrors 1

-- Check Addon Version
/script print(TurtleDungeonTimer.SYNC_VERSION)

-- Dump SavedVariables
/script for k,v in pairs(TurtleDungeonTimerDB) do print(k,v) end

-- Force Reset SavedVariables
/script TurtleDungeonTimerDB = nil
/reload
```

---

## Error Handling

### Graceful Degradation

```lua
-- Check if frame exists before access
if self.frame and self.frame.timeText then
    self.frame.timeText:SetText("00:00")
end

-- Nil-safe table access
local lastRun = TurtleDungeonTimerDB.lastRun
if lastRun and lastRun.dungeon then
    -- Safe to use lastRun
end

-- Default values
self.hasWorldBuffs = self.hasWorldBuffs or false
```

### User Feedback

```lua
-- Error: Missing dungeon selection
if not self.selectedDungeon then
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cFFFF0000[TDT]|r Bitte wähle erst einen Dungeon aus!",
        1, 0, 0
    )
    return
end
```

---

## Security Considerations

### Addon Communication

- Prefix `TDT_SYNC` ist öffentlich registriert
- Nachrichten sind unverschlüsselt
- Version-Check verhindert Kompatibilitätsprobleme
- Keine sensiblen Daten übertragen

### SavedVariables

- Lokal gespeichert in `WTF/Account/.../SavedVariables/`
- Kein Server-Side Validation
- User kann Daten manipulieren
- Export-String ist Base64 (keine Verschlüsselung)

---

## Future Architecture Improvements

### Planned
- [ ] Event Queue System (buffered events)
- [ ] Plugin API für externe Addons
- [ ] Async Save System (throttled writes)
- [ ] Proper MVC Pattern für UI

### Under Consideration
- [ ] Web-based Config Tool
- [ ] Cloud Sync via Third-Party Service
- [ ] Real-time Leaderboards
- [ ] Mobile Companion App

---

## Contribution Guidelines

### Code Style

- **Indentation**: 4 Spaces
- **Line Length**: Max 120 chars
- **Naming**: camelCase für Funktionen, UPPER_CASE für Konstanten
- **Comments**: Deutsch oder Englisch, konsistent innerhalb Datei

### Testing vor Commit

1. `/reload` ohne Lua-Errors
2. Start/Stop Timer funktioniert
3. Boss-Kill Detection funktioniert
4. History speichert korrekt
5. Export erzeugt gültigen String
6. Gruppen-Sync funktioniert (2+ Clients)

---

## Lizenz

MIT License - Siehe [LICENSE](LICENSE) für Details
