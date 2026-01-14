# Dungeon Trash Tracking - Status Übersicht

Diese Datei dokumentiert den Status der Trash-Daten für alle Dungeon-Varianten.

## Status Legende
- ✅ **GEPRÜFT** - Trash-Daten wurden im Spiel verifiziert
- ❌ **Nicht geprüft** - Trash-Daten vorhanden, aber nicht im Spiel getestet
- ⚠️ **Konsolidiert** - Daten aus mehreren Quellen zusammengeführt (Median-Werte)
- 🚫 **Keine Daten** - Keine Trash-Daten vorhanden

---

## Dungeons mit Trash-Daten

| Dungeon | Variante | Total HP | Threshold | Mob-Typen | Status |
|---------|----------|----------|-----------|-----------|--------|
| **Stormwind Vault** | Default | 1.521.201 HP | 65% (988.781 HP) | 9 | ✅ **GEPRÜFT** |
| **Dire Maul** | West | 1.931.400 HP | 50% (965.700 HP) | 45 | ⚠️ **Konsolidiert (4 Spieler)** |
| **The Stockade** | Default | 212.378 HP | 50% (106.189 HP) | 10 | ❌ **Nicht geprüft** |

---

## Detaillierte Informationen

### ✅ Stormwind Vault (Default)
- **Status**: Vollständig im Spiel geprüft
- **Mob-Typen**: 9
  - Black Blood of the Dragonmaw (13.115 HP × 9)
  - Grellkin Scorcher (12.378 HP × 19)
  - Grellkin Sorcerer (12.367 HP × 17)
  - Maddened Vault Guard (12.345 HP × 13)
  - Manacrazed Grell (12.298 HP × 15)
  - Runic Construct (19.898 HP × 2)
  - Shadow Creeper (16.048 HP × 12)
  - Soulless Husk (13.357 HP × 15)
  - Wicked Skitterer (13.851 HP × 13)
- **Total HP**: 1.521.201
- **Threshold**: 65% (988.781 HP erforderlich)
- **Hinweise**: Erste vollständig verifizierte Trash-Daten

---

### ⚠️ Dire Maul West
- **Status**: Daten von 4 Spielern konsolidiert (Median-Werte)
- **Spieler-Quellen**: Robby, URZ, Xadrac, Zasamel
- **Mob-Typen**: 45 (verschiedene Level 56-60)
  - Arcane Feedback (verschiedene Level)
  - Arcane Torrent (verschiedene Level)
  - Eldreth Apparition
  - Eldreth Darter
  - Eldreth Phantasm
  - Eldreth Seether
  - Eldreth Sorcerer
  - Eldreth Spectre
  - Mana Remnant
  - Petrified Guardian
  - Petrified Treant
  - Residual Monstrosity
  - Stonebark (verschiedene Level)
  - und weitere...
- **Total HP**: 1.931.400
- **Threshold**: 50% (965.700 HP erforderlich)
- **Hinweise**: Daten wurden mit Python-Script (analyze_trash.py) konsolidiert, keine signifikanten Unterschiede zwischen den 4 Spielern

---

### ❌ The Stockade (Default)
- **Status**: Nicht im Spiel geprüft
- **Mob-Typen**: 10
  - Defias Captive (2.323 HP × 7, 2.160 HP × 11)
  - Defias Inmate (2.323 HP × 21, 2.495 HP × 15)
  - Defias Prisoner (2.160 HP × 7, 2.323 HP × 6)
  - Defias Convict (2.323 HP × 7, 2.495 HP × 6)
  - Defias Insurgent (2.495 HP × 5, 2.677 HP × 5)
- **Total HP**: 212.378
- **Threshold**: 50% (106.189 HP erforderlich)
- **Hinweise**: Kommentar in Data.lua: "50% for testing, normally 80-100%"
- **TODO**: Im Spiel verifizieren und Threshold anpassen

---

## Dungeons ohne Trash-Daten

| Dungeon | Variante | Bosse | Status |
|---------|----------|-------|--------|
| **Black Morass** | Default | 7 Bosse | 🚫 Keine Trash-Daten |
| **Stratholme** | Living | 5 Bosse | 🚫 Auskommentiert |
| **Stratholme** | Undead | 5 Bosse | 🚫 Auskommentiert |
| **Dire Maul** | North | 5 Bosse | 🚫 Auskommentiert |
| **Dire Maul** | East | 5 Bosse | 🚫 Auskommentiert |
| **Zul'Gurub** | Default | 10+ Bosse | 🚫 Keine Trash-Daten |

---

## Nächste Schritte

### Priorität 1 - Verifizierung
- [ ] **Dire Maul West** im Spiel testen
- [ ] **The Stockade** im Spiel testen und Threshold anpassen

### Priorität 2 - Neue Dungeons
- [ ] **Stratholme Living** Trash-Daten sammeln
- [ ] **Stratholme Undead** Trash-Daten sammeln
- [ ] **Dire Maul North** Trash-Daten sammeln
- [ ] **Dire Maul East** Trash-Daten sammeln

### Priorität 3 - Raids
- [ ] **Zul'Gurub** Trash-Daten sammeln (falls gewünscht)
- [ ] **Black Morass** Trash-Daten sammeln (falls gewünscht)

---

## Datenerfassungs-Methode

### Für neue Dungeons:
1. Mindestens 3-4 vollständige Runs mit verschiedenen Spielern
2. Alle Trash-Mobs mit Namen, HP und Anzahl dokumentieren
3. Daten mit `analyze_trash.py` konsolidieren (Median-Werte)
4. In `Data.lua` unter entsprechende Variante eintragen
5. Im Spiel testen und verifizieren
6. Diese Datei aktualisieren

### Python-Script zur Konsolidierung:
```bash
python analyze_trash.py player1.txt player2.txt player3.txt player4.txt
```

---

**Letzte Aktualisierung**: 2026-01-12
