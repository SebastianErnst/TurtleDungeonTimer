# Core.lua - Dokumentation

**Modul**: Core  
**Datei**: `Core.lua`  
**Zweck**: Zentrale Addon-Logik, Singleton-Pattern, Datenverwaltung

---

## Übersicht

Das Core-Modul ist das Herzstück des Addons. Es implementiert:
- Singleton-Pattern für zentrale Instanz-Verwaltung
- SavedVariables-Initialisierung
- Best Time Management
- Run History System
- State Restoration
- Helper Functions

---

## Architektur

### Singleton-Pattern

```lua
TurtleDungeonTimer = {}
TurtleDungeonTimer.__index = TurtleDungeonTimer

local _instance = nil

function TurtleDungeonTimer:getInstance()
    if not _instance then
        _instance = TurtleDungeonTimer:new()
    end
    return _instance
end
```

**Vorteile**:
- Garantiert nur eine Instanz
- Globaler Zugriff von allen Modulen
- Verhindert Zustandskonflikte

---

## State Variables

### Timer State
```lua
self.startTime = nil          -- GetTime() beim Timer-Start
self.isRunning = false        -- Timer läuft aktuell
self.isCountingDown = false   -- Countdown aktiv
self.countdownTime = 0        -- Countdown-Sekunden verbleibend
```

### UI State
```lua
self.frame = nil              -- Haupt-UI Frame
self.updateFrame = nil        -- OnUpdate Frame für Timer
```

### Dungeon State
```lua
self.selectedDungeon = nil    -- Aktueller Dungeon-Name
self.selectedVariant = nil    -- Aktuelle Variante
self.bossList = {}            -- Array von Boss-Namen
self.optionalBosses = {}      -- Table: {bossName = true}
self.killTimes = {}           -- Boss Kill History
self.deathCount = 0           -- Anzahl Tode
self.bossListExpanded = true  -- Boss-Liste ausgeklappt
self.minimized = false        -- UI minimiert
self.initialized = false      -- Addon initialisiert
```

### World Buff State
```lua
self.hasWorldBuffs = false        -- Run hat World Buffs
self.hasCheckedWorldBuffs = false -- Check wurde durchgeführt
self.worldBuffPlayers = {}        -- {playerName = buffName}
```

---

## SavedVariables

### TurtleDungeonTimerDB Struktur

```lua
TurtleDungeonTimerDB = {
    bestTimes = {
        ["Dungeon Name"] = {
            ["Variant Name"] = {
                time = 1234.56,          -- Sekunden
                bossTimes = {},          -- Kill-Zeiten
                date = "2026-01-09 15:30",
                deaths = 3,
                playerName = "PlayerName",
                guildName = "Guild",
                groupClasses = {}
            }
        }
    },
    settings = {
        countdownDuration = 5,
        showSplits = true
    },
    lastSelection = {
        dungeon = "Stratholme",
        variant = "Live"
    },
    lastRun = {
        dungeon = "...",
        variant = "...",
        bossList = {},
        killTimes = {},
        deathCount = 0,
        startTime = 0,
        playerName = "...",
        guildName = "...",
        groupClasses = {},
        hasWorldBuffs = false,
        worldBuffPlayers = {}
    },
    history = {
        [1] = {
            uuid = "...",
            dungeon = "...",
            variant = "...",
            time = 0,
            deathCount = 0,
            killTimes = {},
            timestamp = 0,
            date = "...",
            completed = true,
            playerName = "...",
            guildName = "...",
            groupClasses = {},
            hasWorldBuffs = false,
            worldBuffPlayers = {}
        }
        -- ... bis zu 10 Einträge
    },
    position = {
        point = "TOP",
        relativeTo = "UIParent",
        relativePoint = "TOP",
        xOfs = 0,
        yOfs = -100
    },
    visible = false,
    minimized = false,
    minimapAngle = 200
}
```

---

## Wichtige Funktionen

### initializeDatabase()

Initialisiert SavedVariables mit Default-Werten.

```lua
function TurtleDungeonTimer:initializeDatabase()
```

**Aufgaben**:
- Erstellt TurtleDungeonTimerDB wenn nicht vorhanden
- Füllt fehlende Tabellen mit Defaults
- Backward-Kompatibilität für Updates

**Called by**: `new()` Constructor

---

### formatTime(seconds)

Konvertiert Sekunden in MM:SS Format.

```lua
function TurtleDungeonTimer:formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds - (mins * 60)
    return string.format("%02d:%02d", mins, secs)
end
```

**Parameter**:
- `seconds` (number): Zeit in Sekunden

**Returns**: (string) Formatierte Zeit "MM:SS"

**Beispiel**:
```lua
formatTime(125.5) -- "02:05"
formatTime(3661)  -- "61:01"
```

---

### getBestTime()

Gibt die beste Zeit für aktuellen Dungeon/Variante zurück.

```lua
function TurtleDungeonTimer:getBestTime()
```

**Returns**: (table|nil) Best Time Entry oder nil

**Struktur**:
```lua
{
    time = 1234.56,
    bossTimes = {},
    date = "2026-01-09 15:30",
    deaths = 3
}
```

---

### saveBestTime(totalTime)

Speichert neue Best Time wenn besser als aktuell.

```lua
function TurtleDungeonTimer:saveBestTime(totalTime)
```

**Parameter**:
- `totalTime` (number): Finale Zeit in Sekunden

**Returns**: (boolean) true wenn neue Best Time gesetzt

**Logik**:
1. Prüft ob Dungeon/Variante ausgewählt
2. Vergleicht mit aktueller Best Time
3. Speichert wenn besser oder erste Zeit
4. Inkludiert Boss-Zeiten, Datum, Deaths

---

### saveToHistory(finalTime, completed)

Speichert Run in History (letzte 500 Runs).

```lua
function TurtleDungeonTimer:saveToHistory(finalTime, completed)
```

**Parameter**:
- `finalTime` (number): Finale Run-Zeit
- `completed` (boolean): Run vollständig (alle Required Bosses)

**Logik**:
1. Erstellt History-Entry mit UUID
2. Fügt am Anfang ein (`table.insert(history, 1, entry)`)
3. Limitiert auf 500 Einträge
4. Speichert World Buff Status

---

### restoreLastRun()

Stellt unvollendeten Run wieder her.

```lua
function TurtleDungeonTimer:restoreLastRun()
```

**Called by**: `initialize()`

**Aufgaben**:
1. Lädt `TurtleDungeonTimerDB.lastRun`
2. Prüft ob Dungeon/Variante übereinstimmt
3. Stellt Kill-Times, Deaths, World Buffs wieder her
4. Updated UI mit wiederhergestellten Daten
5. Färbt UI grün wenn alle Bosses tot

---

### initialize()

Hauptinitialisierung des Addons.

```lua
function TurtleDungeonTimer:initialize()
```

**Called by**: `Commands.lua` OnEvent PLAYER_LOGIN

**Flow**:
1. Prüft `self.initialized` Flag
2. `createUI()` - Erstellt UI
3. `setupUpdateLoop()` - Timer OnUpdate
4. `registerEvents()` - Combat/Death Events
5. `initializeSync()` - Gruppen-Sync
6. `createMinimapButton()` - Minimap Icon
7. Lädt letzte Auswahl
8. Stellt Visibility/Minimized State wieder her
9. `restoreLastRun()` - Lädt unvollendeten Run

---

## Helper Functions

### truncateText(text, maxChars)

Kürzt Text mit Ellipsis.

```lua
function TurtleDungeonTimer:truncateText(text, maxChars)
    if string.len(text) <= maxChars then
        return text
    end
    return string.sub(text, 1, maxChars - 3) .. "..."
end
```

---

### saveLastRun()

Speichert aktuellen Run-State in SavedVariables.

```lua
function TurtleDungeonTimer:saveLastRun()
```

**Called by**:
- Events.lua nach Boss-Kill
- Events.lua nach Death
- Timer.lua bei Stop

**Zweck**: Ermöglicht Run-Fortsetzung nach Reload/Logout

---

## Usage Examples

### Addon starten

```lua
-- In Commands.lua PLAYER_LOGIN Event
TurtleDungeonTimer:getInstance():initialize()
```

### Best Time abrufen

```lua
local timer = TurtleDungeonTimer:getInstance()
local best = timer:getBestTime()

if best then
    print("Best Time: " .. timer:formatTime(best.time))
    print("Deaths: " .. best.deaths)
    print("Date: " .. best.date)
end
```

### History durchsuchen

```lua
local history = TurtleDungeonTimerDB.history

for i = 1, table.getn(history) do
    local entry = history[i]
    print(entry.dungeon .. " - " .. entry.date)
    
    if entry.hasWorldBuffs then
        print("  > With World Buffs!")
    end
end
```

---

## Lua 5.1 Compliance

✅ **Korrekt implementiert**:
- `table.getn()` statt `#`
- `string.find()`, `string.sub()`, `string.format()`
- Keine modernen Lua Features
- Keine Default-Parameter in Funktionen
- Manual table initialization

---

## Dependencies

### Called By
- `Commands.lua` - initialize()
- `Timer.lua` - saveBestTime(), saveLastRun()
- `Events.lua` - saveLastRun(), saveToHistory()
- `UI.lua` - getBestTime(), formatTime()

### Calls
- `UI.lua` - createUI()
- `Timer.lua` - setupUpdateLoop()
- `Events.lua` - registerEvents()
- `Sync.lua` - initializeSync()
- `Minimap.lua` - createMinimapButton()

---

## Testing

### Manual Tests

```lua
-- Test Best Time Save
/script TurtleDungeonTimer:getInstance():saveBestTime(1234.5)

-- Test formatTime
/script print(TurtleDungeonTimer:getInstance():formatTime(125))

-- Test History
/script print(table.getn(TurtleDungeonTimerDB.history))

-- Reset SavedVariables
/script TurtleDungeonTimerDB = nil
/reload
```

---

## Performance Notes

- **Singleton**: O(1) Zugriff auf Instanz
- **getBestTime()**: O(1) Table-Lookup
- **saveToHistory()**: O(n) Array-Insert, limitiert auf 500
- **restoreLastRun()**: O(n) Boss-Row Updates

---

## Future Enhancements

- [ ] Multiple History-Limits (50/100/500)
- [ ] Best Time per Player/Guild
- [ ] Mehr Settings (Timer-Format, Auto-Start, etc.)
- [ ] History Export to CSV/JSON
- [ ] Cloud Sync über Addon-Kommunikation
