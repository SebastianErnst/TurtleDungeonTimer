# World Buff Tracking Feature

## Übersicht
Das World Buff Tracking Modul erkennt automatisch, wenn Spieler in der Gruppe World Buffs aktiv haben und markiert den Run entsprechend.

## Getrackte World Buffs
- Rallying Cry of the Dragonslayer
- Spirit of Zandalar
- Warchief's Blessing
- Songflower Serenade
- Fengus' Ferocity
- Mol'dar's Moxie
- Slip'kik's Savvy

## Funktionsweise

### Automatische Erkennung
- Beim Timer-Start (nach 0.5 Sekunden Verzögerung) werden alle Gruppenmitglieder gescannt
- Wenn mindestens ein Spieler einen World Buff hat, wird der Run als "Mit World Buffs" markiert
- Eine Chat-Nachricht informiert über die Erkennung und Anzahl der Spieler mit Buffs

### UI-Anzeige
- **[WB]** Indikator erscheint neben dem Death Counter im Timer-Header
- Der Indikator ist in Gold (1, 0.84, 0) eingefärbt
- Tooltip zeigt beim Hovern Details (Spielername: Buff-Name)

### Speicherung
Die World Buff Information wird gespeichert in:
- **Aktueller Run**: `self.hasWorldBuffs`, `self.worldBuffPlayers`
- **Last Run**: `TurtleDungeonTimerDB.lastRun.hasWorldBuffs`, `.worldBuffPlayers`
- **History**: Jeder History-Eintrag enthält `hasWorldBuffs` und `worldBuffPlayers`

### Export
- Export-String enthält World Buff Status als "1" (ja) oder "0" (nein)
- Format: `...classesStr|worldBuffFlag|bossdata...`

### History-Anzeige
- History-Dropdown zeigt **[WB]** Tag bei Runs mit World Buffs
- Detail-Ansicht zeigt "World Buffs: Ja" in Gold
- Vollständige Spieler-Liste im Tooltip des [WB] Indikators

## Dateien
- `WorldBuffs.lua` - Haupt-Modul mit Scan- und Tracking-Funktionen
- `TurtleDungeonTimer.toc` - Lädt das neue Modul
- `Core.lua` - Erweitert um World Buff Variablen und Speicherung
- `Timer.lua` - Start-Logik aufruft `checkWorldBuffsOnStart()`
- `UI.lua` - [WB] Indikator im Header mit Tooltip
- `Export.lua` - World Buff Flag im Export-String

## Testing

### Manueller Test
1. `/tdtimer show` - Öffne den Timer
2. Wähle einen Dungeon und starte den Timer
3. Verwende `/run TurtleDungeonTimer:getInstance().hasWorldBuffs = true` um manuell zu setzen
4. Prüfe ob [WB] im Header erscheint

### Mit echten Buffs
1. Besorge einen World Buff (z.B. Songflower)
2. Starte einen Timer-Run
3. Nach 0.5 Sekunden sollte die Chat-Nachricht erscheinen
4. [WB] Indikator sollte sichtbar sein
5. Hover über [WB] um Tooltip zu sehen

### History-Test
1. Beende einen Run mit World Buffs
2. Öffne History (`HISTORY` Button)
3. Prüfe ob [WB] Tag in der Liste erscheint
4. Klicke auf den Eintrag für Details
5. Prüfe "World Buffs: Ja" in der Detail-Ansicht

## API

### Hauptfunktionen

```lua
-- Prüft ob eine Unit World Buffs hat
TurtleDungeonTimer:hasWorldBuffs(unit)
-- Returns: hasBuffs (boolean), buffName (string)

-- Scannt alle Gruppenmitglieder
TurtleDungeonTimer:scanGroupForWorldBuffs()
-- Returns: table {playerName = buffName, ...}

-- Markiert den aktuellen Run
TurtleDungeonTimer:markRunWithWorldBuffs()

-- Wird beim Timer-Start aufgerufen
TurtleDungeonTimer:checkWorldBuffsOnStart()

-- Gibt World Buff Status zurück
TurtleDungeonTimer:getWorldBuffStatus()
-- Returns: table {hasWorldBuffs = bool, worldBuffPlayers = table}
```
