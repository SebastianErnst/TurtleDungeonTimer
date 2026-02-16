# TurtleDungeonTimer - Export Format Dokumentation

## Übersicht

Der TurtleDungeonTimer exportiert Dungeon-Run-Daten als Base64-kodierte Strings. Dieses Dokument beschreibt das komplette Format und wie man die Daten für eine Website dekodieren und importieren kann.

---

## 1. Ausgabeformat

### 1.1 Was wird exportiert?

Der Benutzer erhält einen **Base64-kodierten String**, der über den Export-Dialog oder Chat kopiert werden kann.

**Beispiel einer exportierten Zeichenkette:**
```
VERUfDU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMHxTdHJhdGhvbG1lfExpdmV8MjcyM3wyfFBsYXllcm9uZXxNeUd1aWxkfFdhcnJpb3IsUHJpZXN0LE1hZ2V8MXw2Ny41MHw2NXwxNzM5NDgxNjAwfDF8MXxNYWdpc3RyYXRlX0JhcnRoaWxhczozMzJ8UmFtc3RlaW46MjMyNXxCYXJvbl9SaXZlbmRhcmU6MjcyM3xDSEs6QTNGMKUX
```

### 1.2 Base64-Kodierung

**Verwendeter Zeichensatz:**
```
ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
```

**Standard:** RFC 4648 Base64-Kodierung mit Padding (`=`)

---

## 2. Dekodierung

### 2.1 Schritt 1: Base64 dekodieren

Dekodiere den Base64-String in einen Plain-Text-String.

**Beispiel in verschiedenen Sprachen:**

#### JavaScript/Node.js
```javascript
function decodeBase64(base64String) {
    return Buffer.from(base64String, 'base64').toString('utf-8');
}

const decodedString = decodeBase64(exportString);
```

#### Python
```python
import base64

def decode_base64(base64_string):
    return base64.b64decode(base64_string).decode('utf-8')

decoded_string = decode_base64(export_string)
```

#### PHP
```php
function decodeBase64($base64String) {
    return base64_decode($base64String);
}

$decodedString = decodeBase64($exportString);
```

### 2.2 Schritt 2: Dekodierter String

Nach der Base64-Dekodierung erhältst du einen Pipe-separierten String (`|`):

```
TDT|550e8400-e29b-41d4-a716-446655440000|Stratholme|Living|2723|2|Playerone|MyGuild|Warrior,Priest,Mage|1|67.50|65|1739481600|1|1|Magistrate_Barthilas:332|Ramstein:2325|Baron_Rivendare:2723|CHK:A3F2E1
```

---

## 3. Datenstruktur

### 3.1 Feldaufbau

Die Daten sind mit dem Pipe-Zeichen `|` getrennt. Hier ist die komplette Feldstruktur:

| Position | Feld | Typ | Beschreibung | Beispiel |
|----------|------|-----|--------------|----------|
| 1 | **Prefix** | String | Immer `"TDT"` | `TDT` |
| 2 | **UUID** | String | Eindeutige Run-ID (UUID v4) | `550e8400-e29b-41d4-a716-446655440000` |
| 3 | **Dungeon** | String | Dungeon-Name (Leerzeichen → `_`) | `Stratholme` |
| 4 | **Variant** | String | Variante (z.B. Living/Undead) | `Living` |
| 5 | **Total Time** | Integer | Gesamtzeit in Sekunden | `2723` (= 45:23) |
| 6 | **Deaths** | Integer | Anzahl Tode | `2` |
| 7 | **Player Name** | String | Name des Spielers | `Playerone` |
| 8 | **Guild Name** | String | Gildenname (oder `No_Guild`) | `MyGuild` |
| 9 | **Classes** | String | Klassen (Komma-separiert) | `Warrior,Priest,Mage` |
| 10 | **World Buffs** | String | Weltbuffs vorhanden? | `1` (ja) oder `0` (nein) |
| 11 | **Trash Progress** | Float | Trash-Fortschritt in % | `67.50` |
| 12 | **Trash Required** | Integer | Erforderliche Trash-% | `65` |
| 13 | **Timestamp** | Integer | Unix-Timestamp (Sekunden) | `1739481600` |
| 14 | **Completed** | String | Run abgeschlossen? | `1` (ja) oder `0` (nein) |
| 15 | **Official** | String | Alle hatten Addon? | `1` (ja) oder `0` (nein) |
| 16+ | **Boss Kills** | String | Boss:Zeit Paare | `Baron_Rivendare:2723` |
| Letztes | **Checksum** | String | Prüfsumme | `CHK:A3F2E1` |

### 3.2 Besonderheiten

#### Namensbereinigung
Alle Namen (Dungeon, Player, Guild, Bosse) haben **Leerzeichen und Doppelpunkte durch Unterstriche ersetzt** bekommen:
- `"Baron Rivendare"` → `"Baron_Rivendare"`
- `"Upper Blackrock Spire"` → `"Upper_Blackrock_Spire"`

**Beim Import müssen Unterstriche wieder in Leerzeichen umgewandelt werden.**

#### Klassen-Komposition
- Solo-Run: `"Solo"`
- Gruppe: Komma-separierte Klassen, z.B. `"Warrior,Priest,Mage,Rogue,Hunter"`

#### Bosskills
Format: `BossName:TimeInSeconds`
- Mehrere Bosse sind als separate Felder getrennt durch `|`
- Zeiten sind **kumulative Sekunden ab Start**

**Beispiel:**
```
Magistrate_Barthilas:332|Ramstein:2325|Baron_Rivendare:2723
```
- Boss 1 getötet nach 5:32
- Boss 2 getötet nach 38:45
- Boss 3 (finaler) getötet nach 45:23

---

## 4. Checksum-Validierung

### 4.1 Zweck

Die Checksum verhindert Manipulation und stellt Datenintegrität sicher.

### 4.2 Berechnung

**Algorithmus:**
```javascript
function calculateChecksum(data) {
    let sum = 0;
    for (let i = 0; i < data.length; i++) {
        const byte = data.charCodeAt(i);
        sum = (sum + byte * ((i + 1) * 37)) % 16777216; // 24-bit
    }
    return sum.toString(16).toUpperCase();
}
```

**Python:**
```python
def calculate_checksum(data):
    sum_val = 0
    for i, char in enumerate(data):
        byte = ord(char)
        sum_val = (sum_val + byte * ((i + 1) * 37)) % 16777216
    return format(sum_val, 'X')
```

### 4.3 Validierung beim Import

1. String bei `|CHK:` splitten
2. Daten-Teil und Checksum-Teil trennen
3. Checksum über Daten-Teil neu berechnen
4. Mit angegebener Checksum vergleichen
5. **Ablehnen wenn unterschiedlich!**

**Beispiel JavaScript:**
```javascript
function validateImport(decodedString) {
    const parts = decodedString.split('|');
    
    // Finde Checksum-Position
    const checksumIndex = parts.findIndex(p => p.startsWith('CHK:'));
    if (checksumIndex === -1) {
        throw new Error('Keine Checksum gefunden');
    }
    
    const providedChecksum = parts[checksumIndex].substring(4); // Nach "CHK:"
    const dataParts = parts.slice(0, checksumIndex);
    const dataString = dataParts.join('|');
    
    const calculatedChecksum = calculateChecksum(dataString);
    
    if (calculatedChecksum !== providedChecksum) {
        throw new Error('Checksum ungültig - Daten wurden manipuliert!');
    }
    
    return dataParts;
}
```

---

## 5. JSON-Schema für Website-Import

### 5.1 Ziel-Datenstruktur

Nach dem Parsen solltest du folgende JSON-Struktur haben:

```json
{
  "prefix": "TDT",
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "dungeon": "Stratholme",
  "variant": "Living",
  "totalTime": 2723,
  "deaths": 2,
  "playerName": "Playerone",
  "guildName": "MyGuild",
  "groupClasses": ["Warrior", "Priest", "Mage"],
  "hasWorldBuffs": true,
  "trashProgress": 67.50,
  "trashRequired": 65,
  "timestamp": 1739481600,
  "completed": true,
  "isOfficial": true,
  "bossKills": [
    {
      "bossName": "Magistrate Barthilas",
      "time": 332
    },
    {
      "bossName": "Ramstein",
      "time": 2325
    },
    {
      "bossName": "Baron Rivendare",
      "time": 2723
    }
  ],
  "checksum": "A3F2E1"
}
```

### 5.2 TypeScript Interface

```typescript
interface DungeonRun {
  prefix: 'TDT';
  uuid: string;
  dungeon: string;
  variant: string;
  totalTime: number;          // Sekunden
  deaths: number;
  playerName: string;
  guildName: string;
  groupClasses: string[];     // Array von Klassennamen
  hasWorldBuffs: boolean;
  trashProgress: number;      // Prozent (float)
  trashRequired: number;      // Prozent (integer)
  timestamp: number;          // Unix timestamp
  completed: boolean;
  isOfficial: boolean;
  bossKills: BossKill[];
  checksum: string;
}

interface BossKill {
  bossName: string;
  time: number;               // Sekunden ab Start
}
```

### 5.3 JSON Schema (für Validierung)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": [
    "prefix", "uuid", "dungeon", "variant", "totalTime", 
    "deaths", "playerName", "guildName", "groupClasses", 
    "hasWorldBuffs", "trashProgress", "trashRequired",
    "timestamp", "completed", "isOfficial", "bossKills", "checksum"
  ],
  "properties": {
    "prefix": {
      "type": "string",
      "const": "TDT"
    },
    "uuid": {
      "type": "string",
      "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
    },
    "dungeon": {
      "type": "string",
      "minLength": 1
    },
    "variant": {
      "type": "string",
      "minLength": 1
    },
    "totalTime": {
      "type": "integer",
      "minimum": 0
    },
    "deaths": {
      "type": "integer",
      "minimum": 0
    },
    "playerName": {
      "type": "string",
      "minLength": 1
    },
    "guildName": {
      "type": "string",
      "minLength": 1
    },
    "groupClasses": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "hasWorldBuffs": {
      "type": "boolean"
    },
    "trashProgress": {
      "type": "number",
      "minimum": 0
    },
    "trashRequired": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100
    },
    "timestamp": {
      "type": "integer",
      "minimum": 0
    },
    "completed": {
      "type": "boolean"
    },
    "isOfficial": {
      "type": "boolean"
    },
    "bossKills": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["bossName", "time"],
        "properties": {
          "bossName": {
            "type": "string",
            "minLength": 1
          },
          "time": {
            "type": "integer",
            "minimum": 0
          }
        }
      },
      "minItems": 1
    },
    "checksum": {
      "type": "string",
      "pattern": "^[0-9A-F]+$"
    }
  }
}
```

---

## 6. Komplettes Import-Beispiel

### 6.1 JavaScript/Node.js Implementation

```javascript
const crypto = require('crypto');

class DungeonRunImporter {
    
    /**
     * Hauptfunktion: Import eines Export-Strings
     */
    static importRun(base64String) {
        // 1. Base64 dekodieren
        const decoded = Buffer.from(base64String, 'base64').toString('utf-8');
        
        // 2. Validierung und Parsing
        const parts = this.validateAndParse(decoded);
        
        // 3. In strukturiertes Objekt umwandeln
        const run = this.parseToObject(parts);
        
        return run;
    }
    
    /**
     * Validiere Checksum und parse String
     */
    static validateAndParse(decodedString) {
        const parts = decodedString.split('|');
        
        // Prefix prüfen
        if (parts[0] !== 'TDT') {
            throw new Error('Ungültiges Format: Prefix muss "TDT" sein');
        }
        
        // Checksum finden und validieren
        const checksumIndex = parts.findIndex(p => p.startsWith('CHK:'));
        if (checksumIndex === -1) {
            throw new Error('Keine Checksum gefunden');
        }
        
        const providedChecksum = parts[checksumIndex].substring(4);
        const dataParts = parts.slice(0, checksumIndex);
        const dataString = dataParts.join('|');
        
        const calculatedChecksum = this.calculateChecksum(dataString);
        
        if (calculatedChecksum !== providedChecksum) {
            throw new Error('Checksum ungültig - Daten wurden manipuliert!');
        }
        
        return dataParts;
    }
    
    /**
     * Berechne Checksum
     */
    static calculateChecksum(data) {
        let sum = 0;
        for (let i = 0; i < data.length; i++) {
            const byte = data.charCodeAt(i);
            sum = (sum + byte * ((i + 1) * 37)) % 16777216;
        }
        return sum.toString(16).toUpperCase();
    }
    
    /**
     * Parse Array in strukturiertes Objekt
     */
    static parseToObject(parts) {
        // Basis-Felder (Positionen 0-14)
        const run = {
            prefix: parts[0],
            uuid: parts[1],
            dungeon: parts[2].replace(/_/g, ' '),
            variant: parts[3].replace(/_/g, ' '),
            totalTime: parseInt(parts[4]),
            deaths: parseInt(parts[5]),
            playerName: parts[6].replace(/_/g, ' '),
            guildName: parts[7].replace(/_/g, ' '),
            groupClasses: parts[8] === 'Solo' ? ['Solo'] : parts[8].split(','),
            hasWorldBuffs: parts[9] === '1',
            trashProgress: parseFloat(parts[10]),
            trashRequired: parseInt(parts[11]),
            timestamp: parseInt(parts[12]),
            completed: parts[13] === '1',
            isOfficial: parts[14] === '1',
            bossKills: []
        };
        
        // Boss Kills (ab Position 15)
        for (let i = 15; i < parts.length; i++) {
            const [bossName, timeStr] = parts[i].split(':');
            run.bossKills.push({
                bossName: bossName.replace(/_/g, ' '),
                time: parseInt(timeStr)
            });
        }
        
        // Validierung
        if (run.bossKills.length === 0) {
            throw new Error('Keine Boss-Kills gefunden');
        }
        
        return run;
    }
    
    /**
     * Formatiere Zeit für Anzeige
     */
    static formatTime(seconds) {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }
}

// Verwendung
try {
    const exportString = 'VERUfDU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMHxTdHJhdGhvbG1lfExpdmluZ3wyNzIzfDJ8UGxheWVyb25lfE15R3VpbGR8V2FycmlvcixQcmllc3QsTWFnZXwxfDY3LjUwfDY1fDE3Mzk0ODE2MDB8MXwxfE1hZ2lzdHJhdGVfQmFydGhpbGFzOjMzMnxSYW1zdGVpbjoyMzI1fEJhcm9uX1JpdmVuZGFyZToyNzIzfENISzpBM0YyRTE=';
    
    const run = DungeonRunImporter.importRun(exportString);
    console.log(JSON.stringify(run, null, 2));
    
} catch (error) {
    console.error('Import fehlgeschlagen:', error.message);
}
```

### 6.2 Python Implementation

```python
import base64
import json
from typing import Dict, List, Any

class DungeonRunImporter:
    
    @staticmethod
    def import_run(base64_string: str) -> Dict[str, Any]:
        """Hauptfunktion: Import eines Export-Strings"""
        # 1. Base64 dekodieren
        decoded = base64.b64decode(base64_string).decode('utf-8')
        
        # 2. Validierung und Parsing
        parts = DungeonRunImporter.validate_and_parse(decoded)
        
        # 3. In strukturiertes Dict umwandeln
        run = DungeonRunImporter.parse_to_dict(parts)
        
        return run
    
    @staticmethod
    def validate_and_parse(decoded_string: str) -> List[str]:
        """Validiere Checksum und parse String"""
        parts = decoded_string.split('|')
        
        # Prefix prüfen
        if parts[0] != 'TDT':
            raise ValueError('Ungültiges Format: Prefix muss "TDT" sein')
        
        # Checksum finden
        checksum_index = None
        for i, part in enumerate(parts):
            if part.startswith('CHK:'):
                checksum_index = i
                break
        
        if checksum_index is None:
            raise ValueError('Keine Checksum gefunden')
        
        provided_checksum = parts[checksum_index][4:]  # Nach "CHK:"
        data_parts = parts[:checksum_index]
        data_string = '|'.join(data_parts)
        
        calculated_checksum = DungeonRunImporter.calculate_checksum(data_string)
        
        if calculated_checksum != provided_checksum:
            raise ValueError('Checksum ungültig - Daten wurden manipuliert!')
        
        return data_parts
    
    @staticmethod
    def calculate_checksum(data: str) -> str:
        """Berechne Checksum"""
        sum_val = 0
        for i, char in enumerate(data):
            byte = ord(char)
            sum_val = (sum_val + byte * ((i + 1) * 37)) % 16777216
        return format(sum_val, 'X')
    
    @staticmethod
    def parse_to_dict(parts: List[str]) -> Dict[str, Any]:
        """Parse Array in strukturiertes Dict"""
        run = {
            'prefix': parts[0],
            'uuid': parts[1],
            'dungeon': parts[2].replace('_', ' '),
            'variant': parts[3].replace('_', ' '),
            'totalTime': int(parts[4]),
            'deaths': int(parts[5]),
            'playerName': parts[6].replace('_', ' '),
            'guildName': parts[7].replace('_', ' '),
            'groupClasses': ['Solo'] if parts[8] == 'Solo' else parts[8].split(','),
            'hasWorldBuffs': parts[9] == '1',
            'trashProgress': float(parts[10]),
            'trashRequired': int(parts[11]),
            'timestamp': int(parts[12]),
            'completed': parts[13] == '1',
            'isOfficial': parts[14] == '1',
            'bossKills': []
        }
        
        # Boss Kills (ab Position 15)
        for i in range(15, len(parts)):
            boss_name, time_str = parts[i].split(':')
            run['bossKills'].append({
                'bossName': boss_name.replace('_', ' '),
                'time': int(time_str)
            })
        
        if len(run['bossKills']) == 0:
            raise ValueError('Keine Boss-Kills gefunden')
        
        return run
    
    @staticmethod
    def format_time(seconds: int) -> str:
        """Formatiere Zeit für Anzeige"""
        mins = seconds // 60
        secs = seconds % 60
        return f"{mins}:{secs:02d}"

# Verwendung
if __name__ == '__main__':
    export_string = 'VERUfDU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMHxTdHJhdGhvbG1lfExpdmluZ3wyNzIzfDJ8UGxheWVyb25lfE15R3VpbGR8V2FycmlvcixQcmllc3QsTWFnZXwxfDY3LjUwfDY1fDE3Mzk0ODE2MDB8MXwxfE1hZ2lzdHJhdGVfQmFydGhpbGFzOjMzMnxSYW1zdGVpbjoyMzI1fEJhcm9uX1JpdmVuZGFyZToyNzIzfENISzpBM0YyRTE='
    
    try:
        run = DungeonRunImporter.import_run(export_string)
        print(json.dumps(run, indent=2))
    except Exception as e:
        print(f'Import fehlgeschlagen: {e}')
```

### 6.3 PHP Implementation

```php
<?php

class DungeonRunImporter {
    
    /**
     * Hauptfunktion: Import eines Export-Strings
     */
    public static function importRun($base64String) {
        // 1. Base64 dekodieren
        $decoded = base64_decode($base64String);
        
        // 2. Validierung und Parsing
        $parts = self::validateAndParse($decoded);
        
        // 3. In strukturiertes Array umwandeln
        $run = self::parseToArray($parts);
        
        return $run;
    }
    
    /**
     * Validiere Checksum und parse String
     */
    private static function validateAndParse($decodedString) {
        $parts = explode('|', $decodedString);
        
        // Prefix prüfen
        if ($parts[0] !== 'TDT') {
            throw new Exception('Ungültiges Format: Prefix muss "TDT" sein');
        }
        
        // Checksum finden
        $checksumIndex = null;
        foreach ($parts as $i => $part) {
            if (strpos($part, 'CHK:') === 0) {
                $checksumIndex = $i;
                break;
            }
        }
        
        if ($checksumIndex === null) {
            throw new Exception('Keine Checksum gefunden');
        }
        
        $providedChecksum = substr($parts[$checksumIndex], 4);
        $dataParts = array_slice($parts, 0, $checksumIndex);
        $dataString = implode('|', $dataParts);
        
        $calculatedChecksum = self::calculateChecksum($dataString);
        
        if ($calculatedChecksum !== $providedChecksum) {
            throw new Exception('Checksum ungültig - Daten wurden manipuliert!');
        }
        
        return $dataParts;
    }
    
    /**
     * Berechne Checksum
     */
    private static function calculateChecksum($data) {
        $sum = 0;
        $len = strlen($data);
        
        for ($i = 0; $i < $len; $i++) {
            $byte = ord($data[$i]);
            $sum = ($sum + $byte * (($i + 1) * 37)) % 16777216;
        }
        
        return strtoupper(dechex($sum));
    }
    
    /**
     * Parse Array in strukturiertes Array
     */
    private static function parseToArray($parts) {
        $run = [
            'prefix' => $parts[0],
            'uuid' => $parts[1],
            'dungeon' => str_replace('_', ' ', $parts[2]),
            'variant' => str_replace('_', ' ', $parts[3]),
            'totalTime' => intval($parts[4]),
            'deaths' => intval($parts[5]),
            'playerName' => str_replace('_', ' ', $parts[6]),
            'guildName' => str_replace('_', ' ', $parts[7]),
            'groupClasses' => $parts[8] === 'Solo' ? ['Solo'] : explode(',', $parts[8]),
            'hasWorldBuffs' => $parts[9] === '1',
            'trashProgress' => floatval($parts[10]),
            'trashRequired' => intval($parts[11]),
            'timestamp' => intval($parts[12]),
            'completed' => $parts[13] === '1',
            'isOfficial' => $parts[14] === '1',
            'bossKills' => []
        ];
        
        // Boss Kills (ab Position 15)
        for ($i = 15; $i < count($parts); $i++) {
            list($bossName, $timeStr) = explode(':', $parts[$i]);
            $run['bossKills'][] = [
                'bossName' => str_replace('_', ' ', $bossName),
                'time' => intval($timeStr)
            ];
        }
        
        if (count($run['bossKills']) === 0) {
            throw new Exception('Keine Boss-Kills gefunden');
        }
        
        return $run;
    }
    
    /**
     * Formatiere Zeit für Anzeige
     */
    public static function formatTime($seconds) {
        $mins = floor($seconds / 60);
        $secs = $seconds % 60;
        return sprintf("%d:%02d", $mins, $secs);
    }
}

// Verwendung
try {
    $exportString = 'VERUfDU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMHxTdHJhdGhvbG1lfExpdmluZ3wyNzIzfDJ8UGxheWVyb25lfE15R3VpbGR8V2FycmlvcixQcmllc3QsTWFnZXwxfDY3LjUwfDY1fDE3Mzk0ODE2MDB8MXwxfE1hZ2lzdHJhdGVfQmFydGhpbGFzOjMzMnxSYW1zdGVpbjoyMzI1fEJhcm9uX1JpdmVuZGFyZToyNzIzfENISzpBM0YyRTE=';
    
    $run = DungeonRunImporter::importRun($exportString);
    echo json_encode($run, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo "Import fehlgeschlagen: " . $e->getMessage();
}

?>
```

---

## 7. Website-Integration Checkliste

### 7.1 Backend-Anforderungen

- [ ] Base64-Dekodierung implementieren
- [ ] Checksum-Validierung implementieren
- [ ] String-Parsing (Pipe-Separator)
- [ ] Daten-Bereinigung (Unterstriche → Leerzeichen)
- [ ] JSON-Validierung gegen Schema
- [ ] Datenbank-Schema für Run-Speicherung
- [ ] UUID-Duplikatsprüfung (gleicher Run darf nicht mehrfach importiert werden)

### 7.2 Frontend-Anforderungen

- [ ] Upload/Paste-Feld für Export-String
- [ ] Echtzeit-Validierung (Format-Check vor Submit)
- [ ] Preview der importierten Daten
- [ ] Fehlerbehandlung mit benutzerfreundlichen Meldungen
- [ ] Anzeige von:
  - Dungeon & Variante
  - Spielername & Gilde
  - Gesamtzeit & individuelle Boss-Zeiten
  - Gruppenkomposition
  - Trash-Fortschritt
  - World Buff Status
  - Official Run Flag

### 7.3 Datenbank-Schema (Beispiel SQL)

```sql
CREATE TABLE dungeon_runs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) UNIQUE NOT NULL,
    dungeon VARCHAR(100) NOT NULL,
    variant VARCHAR(50) NOT NULL,
    total_time INT NOT NULL,
    deaths INT NOT NULL,
    player_name VARCHAR(50) NOT NULL,
    guild_name VARCHAR(100),
    group_classes JSON,
    has_world_buffs BOOLEAN DEFAULT FALSE,
    trash_progress DECIMAL(5,2),
    trash_required INT,
    timestamp BIGINT NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    is_official BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_dungeon (dungeon),
    INDEX idx_player (player_name),
    INDEX idx_guild (guild_name),
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE boss_kills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    run_id INT NOT NULL,
    boss_name VARCHAR(100) NOT NULL,
    time INT NOT NULL,
    kill_order INT NOT NULL,
    FOREIGN KEY (run_id) REFERENCES dungeon_runs(id) ON DELETE CASCADE,
    INDEX idx_run (run_id),
    INDEX idx_boss (boss_name)
);
```

---

## 8. Fehlerbehandlung

### 8.1 Häufige Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `Invalid Base64` | String wurde falsch kopiert | Benutzer bitten, String neu zu kopieren |
| `Checksum mismatch` | Daten manipuliert oder korrupt | Import ablehnen |
| `Invalid prefix` | Falsches Format | Nur "TDT"-Strings akzeptieren |
| `No boss kills` | Unvollständiger Run | Mindestens 1 Boss erforderlich |
| `UUID duplicate` | Run bereits importiert | Duplikat-Meldung anzeigen |

### 8.2 Benutzerfreundliche Fehlermeldungen

```javascript
const ERROR_MESSAGES = {
    'INVALID_BASE64': 'Der Export-String ist ungültig. Bitte kopiere ihn erneut aus dem Spiel.',
    'CHECKSUM_MISMATCH': 'Die Daten sind beschädigt oder wurden manipuliert. Bitte exportiere den Run erneut.',
    'INVALID_FORMAT': 'Dies ist kein gültiger TurtleDungeonTimer Export-String.',
    'NO_BOSS_KILLS': 'Der Run enthält keine Boss-Kills und kann nicht importiert werden.',
    'DUPLICATE_UUID': 'Dieser Run wurde bereits importiert.',
    'PARSING_ERROR': 'Fehler beim Verarbeiten der Daten. Bitte versuche es erneut.'
};
```

---

## 9. Testdaten

### 9.1 Beispiel 1: Stratholme Living (Gruppe)

**Base64:**
```
VERUfDU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMHxTdHJhdGhvbG1lfExpdmluZ3wyNzIzfDJ8UGxheWVyb25lfE15R3VpbGR8V2FycmlvcixQcmllc3QsTWFnZXwxfDY3LjUwfDY1fDE3Mzk0ODE2MDB8MXwxfE1hZ2lzdHJhdGVfQmFydGhpbGFzOjMzMnxSYW1zdGVpbjoyMzI1fEJhcm9uX1JpdmVuZGFyZToyNzIzfENISzpBM0YyRTE=
```

**Dekodiert:**
```
TDT|550e8400-e29b-41d4-a716-446655440000|Stratholme|Living|2723|2|Playerone|MyGuild|Warrior,Priest,Mage|1|67.50|65|1739481600|1|1|Magistrate_Barthilas:332|Ramstein:2325|Baron_Rivendare:2723|CHK:A3F2E1
```

**JSON:**
```json
{
  "dungeon": "Stratholme",
  "variant": "Living",
  "totalTime": 2723,
  "playerName": "Playerone",
  "guildName": "MyGuild",
  "groupClasses": ["Warrior", "Priest", "Mage"],
  "hasWorldBuffs": true,
  "completed": true,
  "isOfficial": true,
  "bossKills": [
    {"bossName": "Magistrate Barthilas", "time": 332},
    {"bossName": "Ramstein", "time": 2325},
    {"bossName": "Baron Rivendare", "time": 2723}
  ]
}
```

### 9.2 Beispiel 2: Solo Run ohne Weltbuffs

**Dekodiert:**
```
TDT|abc-123-def|Stormwind_Vault|Default|1850|0|Soloking|No_Guild|Solo|0|72.30|65|1739485200|1|0|Aszosh_Grimflame:450|Tham_Grarr:920|Black_Bride:1420|Damian:1850|CHK:B4E3D2
```

**JSON:**
```json
{
  "dungeon": "Stormwind Vault",
  "variant": "Default",
  "totalTime": 1850,
  "deaths": 0,
  "playerName": "Soloking",
  "guildName": "No Guild",
  "groupClasses": ["Solo"],
  "hasWorldBuffs": false,
  "trashProgress": 72.30,
  "completed": true,
  "isOfficial": false,
  "bossKills": [
    {"bossName": "Aszosh Grimflame", "time": 450},
    {"bossName": "Tham'Grarr", "time": 920},
    {"bossName": "Black Bride", "time": 1420},
    {"bossName": "Damian", "time": 1850}
  ]
}
```

---

## 10. Zusätzliche Informationen

### 10.1 Versionskompatibilität

Das aktuelle Format ist **Version 1**. Zukünftige Versionen könnten erweitert werden:

- Neue Felder werden **am Ende vor der Checksum** hinzugefügt
- Alte Parser können neue Felder ignorieren
- Prefix bleibt immer `"TDT"`

**Empfehlung:** Version-Field als erstes Feld nach Prefix einführen (z.B. `TDT|V1|...`)

### 10.2 Sicherheitshinweise

⚠️ **Wichtig für Website-Integration:**

1. **Validiere IMMER die Checksum** - verhindert Manipulation
2. **Prüfe auf UUID-Duplikate** - verhindert mehrfaches Importieren
3. **Sanitize alle Strings** - verhindert SQL-Injection
4. **Rate-Limiting** - max. X Imports pro IP/Stunde
5. **Maximale String-Länge** - z.B. max 10KB Base64

### 10.3 Performance-Überlegungen

- **Base64-Größe:** ~270-600 Zeichen (typisch)
- **Dekodierung:** < 1ms
- **Parsing:** < 1ms
- **Checksum:** < 1ms

**Empfehlung:** Async-Validierung im Frontend, synchrone Verarbeitung im Backend OK.

---

## 11. Support & Kontakt

Bei Fragen zum Export-Format oder bei Implementierungsproblemen:

- Prüfe diese Dokumentation
- Teste mit den bereitgestellten Beispieldaten
- Verwende die Code-Beispiele als Ausgangspunkt

**Wichtige Ressourcen:**
- Export.lua - Lua-Implementierung
- EXPORT.md - Technische Dokumentation (Englisch)
- Testdaten in diesem Dokument

---

**Dokumentationsversion:** 1.0  
**Letzte Aktualisierung:** Februar 2026  
**Kompatibel mit:** TurtleDungeonTimer v1.x
