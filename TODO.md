# TODO - Future Features & Bug Fixes

## 🐛 Known Bugs

### Timer wird beim Login/Reload abgebrochen
- **Problem:** Wenn ein Spieler einloggt/reloadet, wird der laufende Timer abgebrochen, weil das System denkt, dass sich die Gruppengröße geändert hat
- **Priorität:** KRITISCH
- **Details:**
  - GROUP_ROSTER_UPDATE Event feuert beim Login des Spielers
  - System erkennt Spieler als "neu" in der Gruppe
  - lastGroupSize wird möglicherweise falsch initialisiert
  - Run wird mit "Group composition changed" abgebrochen
- **Betroffene Events:**
  - PLAYER_ENTERING_WORLD (triggert requestCurrentRunData nach 2s)
  - PARTY_MEMBERS_CHANGED / RAID_ROSTER_UPDATE (triggert Gruppencheck)
  - Timing-Konflikt zwischen beiden Events
- **Lösungsansätze:**
  1. Grace Period beim Login: Erste 5-10 Sekunden keine Group-Change-Aborts
  2. Bessere Tracking-Logik: Namen statt nur Größe tracken
  3. Sync-Nachrichten nutzen: Wenn jemand einloggt und Run läuft, keine Gruppe-Changed-Nachricht senden
  4. PLAYER_ENTERING_WORLD ignorieren für Group-Size-Tracking

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
