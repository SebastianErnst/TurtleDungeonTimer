# TODO - Future Features & Bug Fixes

## 🐛 Known Bugs

### Final Sync beim Run Completion fehlt
- **Problem:** Wenn der Run abgeschlossen ist, werden die Daten sofort gespeichert, OHNE vorher einen finalen Gruppen-Sync durchzuführen
- **Priorität:** KRITISCH ✅ FIXED in v0.14.2 (1.5s Sync-Wait implementiert)
- **Details:**
  - Verschiedene Spieler können unterschiedliche Statistiken haben (Zeit, Trash-Count, Tode)
  - `broadcastTimerComplete()` sendet nur Completion-Nachricht, NICHT die vollständigen Daten
  - Speichern passiert sofort in `onAllBossesDefeated()` ohne Sync-Wait
- **Lösung:** Final Sync VOR dem Speichern mit 1.5s Wait implementiert

### Timer wird beim Login/Reload abgebrochen
- **Problem:** Wenn ein Spieler einloggt/reloadet, wird der laufende Timer abgebrochen, weil das System denkt, dass sich die Gruppengröße geändert hat
- **Priorität:** KRITISCH ✅ FIXED in v0.14.1 (Grace Period implementiert)
- **Details:**
  - GROUP_ROSTER_UPDATE Event feuert beim Login des Spielers
  - System erkennt Spieler als "neu" in der Gruppe
  - lastGroupSize wird möglicherweise falsch initialisiert
  - Run wird mit "Group composition changed" abgebrochen
- **Lösung:** Grace Period von 8 Sekunden nach Login implementiert

### Button State beim Group Leader Wechsel
- **Problem:** Wenn der Group Lead übertragen wird, müssen die Button-States aktualisiert werden
- **Priorität:** Hoch ✅ FIXED in v0.14.2 (PARTY_LEADER_CHANGED Event)
- **Details:**
  - Alter Leader: Abort/Start Button sollte grau werden (nicht mehr Leader)
  - Neuer Leader: Button sollte rot/grün werden (aktiv)
  - Aktuell: Buttons bleiben im alten State bis UI-Refresh
- **Lösung:**
  - PARTY_LEADER_CHANGED Event registriert
  - Alle Leader-abhängigen Buttons werden automatisch aktualisiert
  - Start/Abort, Prepare, Reset Buttons alle synchronisiert

### Debug Mode wird beim Login nicht deaktiviert
- **Problem:** Debug Mode bleibt nach Login/Reload aktiv
- **Priorität:** Mittel ✅ FIXED in v0.14.2
- **Details:**
  - TurtleDungeonTimerDB.debug sollte beim Login standardmäßig false sein
  - Nur explizit aktiviert lassen wenn Entwickler-Flag gesetzt
- **Lösung:** In Core.lua initialize(): debug standardmäßig false, auch bei Updates

### Kapitalisierung in Übersetzungen
- **Problem:** Inkonsistente Groß-/Kleinschreibung in englischen Texten
- **Priorität:** Niedrig (Kosmetisch) ✅ FIXED in v0.14.2
- **Zu korrigieren:**
  - "no" → "No" (Button-Text) ✅ Bereits korrekt
  - "Abort Run?" → "Abort run?" (Dialog-Titel) ✅ Korrigiert
- **Status:** Alle Kapitalisierungen korrigiert

### Sync Check beim Login fehlschlägt
- **Problem:** Beim Einloggen kommt ein Sync-Check, der failed, obwohl alle Spieler Version 0.14.0 haben
- **Priorität:** Mittel
- **Details:** 
  - Version-Check schlägt fehl trotz identischer Versionen
  - Möglicherweise Timing-Problem beim ADDON_LOADED Event
  - Oder Version-String wird nicht korrekt verglichen
- **Zu prüfen:**
  - Sync-Nachrichten beim Login analysieren
  - Version-String-Vergleich prüfen (Leerzeichen, Case-Sensitivity)
  - Reihenfolge der Events prüfen (ADDON_LOADED vs. GROUP_ROSTER_UPDATE)

## 🚀 Feature Requests

### Close Button für Preparation Windows
- **Feature:** Preparation-Fenster sollten mit einem X-Button geschlossen werden können
- **Priorität:** Mittel
- **Details:**
  - Aktuell: Fenster können nur durch ESC oder Klick außerhalb geschlossen werden
  - Gewünscht: X-Button oben rechts wie bei anderen Dialogen
- **Betroffene Fenster:**
  - Ready Check Dialog
  - Countdown Dialog
  - Abort Vote Dialog
  - Dungeon Selection Window
- **Implementation:**
  - Close-Button-Frame erstellen (mit X-Textur oder "X" Text)
  - Position: Oben rechts im Frame
  - OnClick: Dialog:Hide() aufrufen

## 📝 Nice-to-Have Features

### World Buff Detection verbessern
- Genauere Erkennung welche Buffs aktiv sind
- Anzeige welcher Spieler welche Buffs hat

### Export-Funktion erweitern
- CSV-Export für Excel/Google Sheets
- JSON-Export für externe Tools
- Screenshot-Export mit Run-Statistiken

### Statistiken & History
- Durchschnittliche Run-Zeiten pro Dungeon
- Beste/Schlechteste Runs
- Trends über Zeit anzeigen

### Minimap Button
- Toggle für Timer-Anzeige
- Rechtsklick-Menü für schnelle Aktionen
- Drag & Drop zum Verschieben

## 🔧 Code Quality

### Testing
- Unit Tests für Core-Logik implementieren (mit busted)
- WoW API Mocks erstellen
- Test Fixtures für Dungeons/Bosses
- Integration Tests für Sync-System

### Refactoring
- Weitere unnötige Funktionen entfernen
- Code-Duplikate eliminieren
- Dokumentation vervollständigen

### Performance
- Sync-Nachrichten throtteln (nicht zu oft senden)
- Timer-Updates optimieren (nicht jedes Frame)
- Memory-Leaks prüfen (insbesondere bei Frame-Erstellung)

## 📚 Dokumentation

### User Guide
- Schritt-für-Schritt Anleitung erstellen
- Screenshots hinzufügen
- FAQ erstellen

### Developer Docs
- API-Dokumentation für alle Module
- Sync-Protokoll dokumentieren
- Event-Flow-Diagramme erstellen

---

**Version beim Erstellen dieser TODO:** 0.14.0  
**Letztes Update:** 17.01.2026
