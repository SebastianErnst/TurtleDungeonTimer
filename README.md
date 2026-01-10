# Turtle Dungeon Timer

**Version:** 1.0.1-alpha  
**Author:** TurtleWoW Community  
**Interface:** 11200 (WoW 1.12 - Vanilla)

Ein fortgeschrittener Dungeon- und Raid-Timer für Turtle WoW mit Boss-Tracking, Best Times, Splits und Gruppen-Synchronisation.

---

## Features

### Core Features
- ⏱️ **Präzises Timing**: Millisekunden-genaue Zeitmessung für Dungeon-Runs
- 📊 **Boss Tracking**: Einzelne Kill-Zeiten für jeden Boss mit Split-Times
- 🏆 **Best Time System**: Automatisches Speichern und Anzeigen der besten Zeiten
- 💀 **Death Counter**: Tracking von Gruppen-Todes mit automatischer Erkennung
- 📜 **Run History**: Speichert die letzten 10 Runs mit vollständigen Details
- 🔄 **Group Sync**: Synchronisiert Timer, Boss-Kills und Resets in der Gruppe
- 🎯 **World Buff Detection**: Erkennt automatisch World Buffs bei Run-Start
- 📤 **Export System**: Base64-kodierte Export-Strings für externe Tracking-Tools

### UI Features
- 🖱️ **Minimap Button**: Schneller Zugriff über Minimap-Icon
- 📐 **Flexible UI**: Minimierbar, verschiebbar, mit Collapse-Funktion
- 🎨 **Visual Feedback**: Farbcodierte Zeiten (grün = besser als Best Time)
- 📋 **Optional Boss Support**: Unterscheidung zwischen Required und Optional Bosses
- 🔍 **History Browser**: Detailansicht vergangener Runs mit Report-Funktion

### Advanced Features
- 🗳️ **Reset Voting**: Demokratisches Reset-System für Gruppen
- 💬 **Report System**: Teile Run-Ergebnisse in verschiedenen Chat-Channels
- 🔌 **Addon Detection**: Automatische Erkennung von Gruppenmitgliedern mit Addon
- 💾 **Persistent State**: Automatisches Speichern und Wiederherstellen von Runs

---

## Installation

1. Lade das Addon herunter
2. Entpacke den Ordner `TurtleDungeonTimer` nach:
   ```
   <WoW-Directory>\Interface\AddOns\
   ```
3. Starte WoW neu oder gib `/reload` ein

---

## Verwendung

### Befehle

```lua
/tdt                    -- Toggle Timer-Fenster
/turtledungeontimer     -- Alias für /tdt
/tdt help               -- Toggle Timer-Fenster
```

### Schnellstart

1. **Dungeon auswählen**: Klicke auf den Dungeon-Selector Button
2. **Timer starten**: 
   - Manuell: Klicke auf "START" Button
   - Automatisch: Betritt Kampf oder stirb im Dungeon
3. **Bosse töten**: Timer trackt automatisch Boss-Kills über Combat-Log
4. **Run abschließen**: Alle Required Bosses töten oder manuell stoppen

### Minimap Button

- **Linksklick**: Timer-Fenster öffnen/schließen
- **Rechtsklick**: Schnellmenü (aktuell: Toggle)
- **Drag**: Position um die Minimap verschieben

---

## Module Übersicht

| Modul | Beschreibung | Dokumentation |
|-------|-------------|---------------|
| **Core.lua** | Hauptlogik, Singleton-Pattern, Datenverwaltung | [CORE.md](CORE.md) |
| **Timer.lua** | Timer-Logik, Start/Stop/Reset, Gruppen-Info | [TIMER.md](TIMER.md) |
| **UI.lua** | Frame-Erstellung, Layout, Visual Updates | [UI.md](UI.md) |
| **UIMenus.lua** | Dropdown-Menüs, Boss-Rows, Dungeon-Auswahl | [UIMENUS.md](UIMENUS.md) |
| **Events.lua** | Event-Handler, Boss-Detection, Combat-Tracking | [EVENTS.md](EVENTS.md) |
| **Data.lua** | Dungeon-Definitionen, Boss-Listen | [DATA.md](DATA.md) |
| **Sync.lua** | Gruppen-Synchronisation, Voting-System | [SYNC.md](SYNC.md) |
| **Export.lua** | Export-System, Base64-Encoding, UUID-Gen | [EXPORT.md](EXPORT.md) |
| **Minimap.lua** | Minimap-Button, Drag-Funktionalität | [MINIMAP.md](MINIMAP.md) |
| **WorldBuffs.lua** | World Buff Detection & Tracking | [WORLDBUFFS_README.md](WORLDBUFFS_README.md) |
| **Commands.lua** | Slash-Commands, Auto-Initialisierung | [COMMANDS.md](COMMANDS.md) |

---

## Saved Variables

### TurtleDungeonTimerDB

```lua
TurtleDungeonTimerDB = {
    bestTimes = {},           -- Best times per dungeon/variant
    settings = {},            -- User settings
    lastSelection = {},       -- Last selected dungeon/variant
    lastRun = {},            -- Last unfinished run data
    history = {},            -- Last 10 completed runs
    position = {},           -- Window position
    visible = false,         -- Window visibility state
    minimized = false,       -- Minimized state
    minimapAngle = 200      -- Minimap button position
}
```

---

## Dungeon Support

### Aktuell Implementiert
- **Black Morass** (Turtle WoW Custom)
- **Stormwind Vault** (Turtle WoW Custom)
- **Stratholme** (Live/UD/Full)
- **Dire Maul** (North/East/West)
- **Upper Blackrock Spire** (Full/First Half/Second Half)

### Geplant
Siehe `Data.lua` für kommentierte Classic-Dungeons (Ragefire, Deadmines, etc.)

---

## API für Entwickler

### Singleton-Zugriff

```lua
local timer = TurtleDungeonTimer:getInstance()
```

### Wichtige Methoden

```lua
-- Timer-Steuerung
timer:start()                    -- Timer starten
timer:stop()                     -- Timer stoppen (ohne Save)
timer:reset()                    -- Timer zurücksetzen (mit Bestätigung)

-- Dungeon-Auswahl
timer:selectDungeon("Stratholme")
timer:selectVariant("Live")

-- UI-Steuerung
timer:show()
timer:hide()
timer:toggle()
timer:toggleMinimized()

-- Daten-Zugriff
local bestTime = timer:getBestTime()
local history = TurtleDungeonTimerDB.history

-- World Buffs
local hasBuffs, buffName = timer:hasWorldBuffs("player")
local groupBuffs = timer:scanGroupForWorldBuffs()
```

---

## Technische Details

### Lua 5.1 Kompatibilität

Das Addon folgt strikt den **WoW 1.12 / Lua 5.1** Einschränkungen:
- Kein `#` Operator → `table.getn()`
- Kein `%` Operator → `mod()` Funktion
- Kein `string.gmatch()` → `string.gfind()`
- Event Handler nutzen implicit globals (`this`, `event`, `arg1`-`arg9`)
- Kein `...` varargs → `arg` table

Siehe [TurtleWoW_Addon_Development_Prompt.md](TurtleWoW_Addon_Development_Prompt.md) für Details.

### Performance

- **Event-basiert**: Minimale CPU-Last durch OnUpdate nur wenn nötig
- **Lazy Loading**: UI-Elemente werden erst bei Bedarf erstellt
- **Optimierte Loops**: Keine verschachtelten table-Iterationen
- **SavedVariables**: Automatisches Speichern beim Logout

---

## Bekannte Limitierungen

1. **Boss-Erkennung**: Basiert auf Combat-Log-Namen (exakte Übereinstimmung nötig)
2. **Sync-System**: Erfordert gleiche Addon-Version in der Gruppe
3. **History**: Nur die letzten 10 Runs werden gespeichert
4. **Export**: Keine Import-Funktion (nur Export)

---

## Troubleshooting

### Timer startet nicht automatisch
- Prüfe ob ein Dungeon ausgewählt ist
- Stelle sicher dass mindestens 1 Boss definiert ist
- Überprüfe ob der Run bereits abgeschlossen ist

### Boss-Kills werden nicht erkannt
- Boss-Name muss exakt mit `Data.lua` übereinstimmen
- Combat-Log muss "X dies." oder "X has died." enthalten
- Prüfe mit `/console scriptErrors 1` auf Lua-Fehler

### Sync funktioniert nicht
- Alle Gruppenmitglieder müssen das Addon haben
- Addon-Version muss übereinstimmen
- Prüfe mit `/script print(TurtleDungeonTimer.SYNC_VERSION)`

### World Buffs werden nicht erkannt
- Buff-Name muss exakt übereinstimmen (siehe `WorldBuffs.lua`)
- Check wird 0.5s nach Timer-Start durchgeführt
- Funktioniert nur mit den 7 definierten World Buffs

---

## Mitwirken

### Bug Reports
Bitte öffne ein Issue mit:
- Detaillierter Beschreibung
- Schritte zur Reproduktion
- Lua-Fehler (falls vorhanden)
- Screenshots (wenn hilfreich)

### Feature Requests
Feature-Ideen sind willkommen! Beschreibe:
- Use Case / Anwendungsfall
- Erwartetes Verhalten
- Beispiel-Screenshots (wenn möglich)

### Code Contributions
1. Fork das Repository
2. Erstelle einen Feature-Branch
3. Befolge die Lua 5.1 Guidelines
4. Teste ausgiebig in-game
5. Erstelle einen Pull Request

---

## Credits

- **Entwicklung**: TurtleWoW Community
- **Testing**: Dungeon-Runner Community
- **Inspiration**: ClassicTimers, Details, WeakAuras

---

## Lizenz

MIT License - Siehe LICENSE Datei für Details

---

## Changelog

### v1.0.1-alpha (Current)
- ✨ World Buff Detection hinzugefügt
- 🐛 EnableMouseWheel() Lua 5.1 Fix
- 📚 Umfassende Dokumentation

### v1.0.0-alpha (Initial)
- 🎉 Erste Alpha-Version
- ⏱️ Core Timer-Funktionalität
- 🔄 Gruppen-Sync System
- 📤 Export-Feature
- 🗺️ Minimap-Button
