# Export.lua - Data Export Module

## Overview
Handles run data serialization, Base64 encoding, and export string generation for sharing dungeon timer results outside the game.

---

## Module Responsibilities
- Export string generation (current run and history)
- Base64 encoding
- UUID generation
- Export dialog UI
- Format specification for import compatibility

---

## Export Format

### Export String Structure
```
TDT|uuid|dungeon|variant|totalTime|deaths|playerName|guildName|classes|worldBuffFlag|trashProgress|trashRequired|timestamp|completed|isOfficial|boss1:time|boss2:time|...|CHK:checksum
```

**Field Separator:** `|` (pipe)

**Example (before Base64):**
```
TDT|550e8400-e29b-41d4-a716-446655440000|Stratholme|Live|2723|2|Playerone|MyGuild|Warrior,Priest,Mage|1|67.50|65|1739481600|1|1|Magistrate_Barthilas:332|Ramstein:2325|Baron_Rivendare:2723|CHK:A3F2E1
```

**After Base64 Encoding:**
```
VERUfDU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMHxTdHJhdGhvbG1lfExpdmV8MjcyM3wyfFBsYXllcm9uZXxNeUd1aWxkfFdhcnJpb3IsUHJpZXN0LE1hZ2V8MXw2Ny41MHw2NXwxNzM5NDgxNjAwfDF8MXxNYWdpc3RyYXRlX0JhcnRoaWxhczozMzJ8UmFtc3RlaW46MjMyNXxCYXJvbl9SaXZlbmRhcmU6MjcyM3xDSEs6QTNGMKUX...
```

---

## Field Specifications

| Position | Field | Type | Description | Format Rules |
|----------|-------|------|-------------|--------------|
| 1 | Prefix | string | Always "TDT" | Fixed identifier |
| 2 | UUID | string | Unique run ID | UUID v4 format or "no-uuid" |
| 3 | Dungeon | string | Dungeon name | Spaces → `_`, colons → `_` |
| 4 | Variant | string | Variant name | Spaces → `_`, colons → `_` |
| 5 | Total Time | number | Final time in seconds | Integer (no decimals) |
| 6 | Deaths | number | Total death count | Integer |
| 7 | Player Name | string | Run initiator | Spaces → `_`, colons → `_` |
| 8 | Guild Name | string | Guild name | Spaces → `_`, colons → `_`, "No_Guild" if none |
| 9 | Classes | string | Group composition | Comma-separated, "Solo" if alone |
| 10 | World Buffs | string | Buff flag | "1" = yes, "0" = no |
| 11 | Trash Progress | number | Actual trash % killed | Decimal (e.g. "67.50" or "102.30") |
| 12 | Trash Required | number | Required trash % | Integer (e.g. "65" or "85") |
| 13 | Timestamp | number | Run completion time | Unix timestamp (seconds since epoch) |
| 14 | Completed | string | Run finished flag | "1" = completed, "0" = incomplete |
| 15 | Official | string | All had addon flag | "1" = official, "0" = unofficial |
| 16+ | Boss Kills | string | Boss:time pairs | `BossName:timeInSeconds` |
| Last | Checksum | string | Data integrity check | `CHK:HEXVALUE` (CRC-like hash) |

---

## Data Security

### Checksum System
To prevent data manipulation, a checksum is calculated over all fields before Base64 encoding:

```lua
function TurtleDungeonTimer:calculateChecksum(data)
    local sum = 0
    for i = 1, string.len(data) do
        local byte = string.byte(data, i)
        sum = mod(sum + byte * (i * 37), 16777216)
    end
    return string.format("%X", sum)
end
```

**How it works:**
1. All export data fields are concatenated with `|` separator
2. Checksum is calculated over the entire string
3. Checksum is appended as `CHK:HEXVALUE`
4. Complete string (including checksum) is Base64 encoded

**Import validation:**
1. Decode Base64 string
2. Split by `|` and extract checksum
3. Recalculate checksum over data fields
4. Compare calculated vs. provided checksum
5. Reject if they don't match

This prevents:
- Manual manipulation of export strings
- Accidental data corruption
- Fake run submissions

---

## Core Functions

### exportRunData(entry)
**Purpose:** Generate export string from run data  
**Parameters:**
- `entry` - table (optional): History entry to export. If nil, exports current run

**Returns:** `string` - Base64 encoded export string, or `nil` if no data

**Process:**
```lua
function TurtleDungeonTimer:exportRunData(entry)
    local killTimes, deathCount, dungeon, variant, playerName, guildName, groupClasses, uuid, hasWorldBuffs
    
    if entry then
        -- Export from history entry
        killTimes = entry.killTimes or {}
        deathCount = entry.deaths or 0
        dungeon = entry.dungeon
        variant = entry.variant
        playerName = entry.playerName or "Unknown"
        guildName = entry.guildName or "No Guild"
        groupClasses = entry.groupClasses or {}
        uuid = entry.uuid or "no-uuid"
        hasWorldBuffs = entry.hasWorldBuffs or false
    else
        -- Export current run
        killTimes = self.killTimes
        deathCount = self.deathCount
        dungeon = self.selectedDungeon
        variant = self.selectedVariant
        playerName = self.playerName or UnitName("player") or "Unknown"
        guildName = self.guildName or GetGuildInfo("player") or "No Guild"
        groupClasses = self.groupClasses or {}
        uuid = self.currentRunUUID or "no-uuid"
        hasWorldBuffs = self.hasWorldBuffs or false
    end
    
    -- Validate data
    if table.getn(killTimes) == 0 then
        return nil
    end
    
    -- Build export string
    local parts = {"TDT"}
    
    -- UUID
    table.insert(parts, uuid or "no-uuid")
    
    -- Dungeon name (sanitize)
    local dungeonName = dungeon or "Unknown"
    dungeonName = string.gsub(dungeonName, "[%s:]", "_")
    table.insert(parts, dungeonName)
    
    -- Variant (sanitize)
    local variantName = variant or "Default"
    variantName = string.gsub(variantName, "[%s:]", "_")
    table.insert(parts, variantName)
    
    -- Total time
    local totalTime = 0
    if table.getn(killTimes) > 0 then
        totalTime = killTimes[table.getn(killTimes)].time
    end
    table.insert(parts, string.format("%.0f", totalTime))
    
    -- Deaths
    table.insert(parts, tostring(deathCount))
    
    -- Player name (sanitize)
    local pName = playerName or "Unknown"
    pName = string.gsub(pName, "[%s:]", "_")
    table.insert(parts, pName)
    
    -- Guild name (sanitize)
    local gName = guildName or "No_Guild"
    gName = string.gsub(gName, "[%s:]", "_")
    table.insert(parts, gName)
    
    -- Group classes
    local classesStr = "Solo"
    if groupClasses and table.getn(groupClasses) > 0 then
        classesStr = table.concat(groupClasses, ",")
    end
    table.insert(parts, classesStr)
    
    -- World Buffs flag
    table.insert(parts, hasWorldBuffs and "1" or "0")
    
    -- Boss kills
    for i = 1, table.getn(killTimes) do
        local kill = killTimes[i]
        local bossName = string.gsub(kill.name, "[%s:]", "_")
        local bossTime = string.format("%.0f", kill.time)
        table.insert(parts, bossName .. ":" .. bossTime)
    end
    
    local rawString = table.concat(parts, "|")
    
    -- Encode
    return self:encodeBase64(rawString)
end
```

---

## Base64 Encoding

### encodeBase64(data)
**Purpose:** Encode string to Base64  
**Parameters:**
- `data` - string: Raw data to encode

**Returns:** `string` - Base64 encoded string

**Implementation:**
```lua
local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function TurtleDungeonTimer:encodeBase64(data)
    local result = {}
    local i = 1
    
    while i <= string.len(data) do
        local byte1 = string.byte(data, i)
        local byte2 = string.byte(data, i + 1) or 0
        local byte3 = string.byte(data, i + 2) or 0
        
        -- Convert 3 bytes to 4 base64 characters
        local buffer = byte1 * 65536 + byte2 * 256 + byte3
        
        local char1 = math.floor(buffer / 262144)
        local char2 = math.floor(mod(buffer, 262144) / 4096)
        local char3 = math.floor(mod(buffer, 4096) / 64)
        local char4 = mod(buffer, 64)
        
        table.insert(result, string.sub(base64chars, char1 + 1, char1 + 1))
        table.insert(result, string.sub(base64chars, char2 + 1, char2 + 1))
        
        if i + 1 <= string.len(data) then
            table.insert(result, string.sub(base64chars, char3 + 1, char3 + 1))
        else
            table.insert(result, "=")
        end
        
        if i + 2 <= string.len(data) then
            table.insert(result, string.sub(base64chars, char4 + 1, char4 + 1))
        else
            table.insert(result, "=")
        end
        
        i = i + 3
    end
    
    return table.concat(result)
end
```

**Lua 5.1 Note:** Uses `mod()` function, not `%` operator

---

## UUID Generation

### generateUUID()
**Purpose:** Generate UUID v4  
**Returns:** `string` - Format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`

**Implementation:**
```lua
function TurtleDungeonTimer:generateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local uuid = string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
    return uuid
end
```

**UUID v4 Format:**
- `4` in 3rd group indicates version 4
- `y` replaced with 8-11 (binary: 10xx) for variant bits
- All other digits random hex (0-15)

**Example:** `550e8400-e29b-41d4-a716-446655440000`

---

## Export Dialog

### showExportDialog()
**Purpose:** Display export dialog with Base64 string  
**Called by:** Export button click

**Process:**
1. Generate export string via `exportRunData()`
2. Check if data available
3. Print to chat for easy copying
4. Show dialog with editable text box

**Dialog Creation:**
```lua
function TurtleDungeonTimer:showExportDialog()
    local exportString = self:exportRunData()
    
    if not exportString then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r No run data available", 1, 0.5, 0)
        return
    end
    
    -- Print to chat
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Export String:")
    DEFAULT_CHAT_FRAME:AddMessage(exportString)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Tip:|r Click and drag to select the string above, then right-click to copy.")
    
    -- Create/reuse dialog
    if self.exportDialog then
        self.exportDialog.editBox:SetText(exportString)
        self.exportDialog.editBox:HighlightText()
        self.exportDialog:Show()
        return
    end
    
    -- Create new dialog
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(400)
    dialog:SetHeight(150)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:EnableMouse(true)
    self.exportDialog = dialog
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("Export Run Data")
    title:SetTextColor(1, 0.82, 0)
    
    -- Description
    local desc = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Export string is also printed in chat for easy copying.")
    desc:SetTextColor(0, 1, 0)
    
    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog)
    scrollFrame:SetWidth(360)
    scrollFrame:SetHeight(50)
    scrollFrame:SetPoint("TOP", desc, "BOTTOM", 0, -10)
    
    -- EditBox
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetWidth(350)
    editBox:SetHeight(50)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontNormal)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetText(exportString)
    editBox:HighlightText()
    
    -- Auto-select on click
    editBox:SetScript("OnMouseDown", function()
        this:HighlightText()
    end)
    
    scrollFrame:SetScrollChild(editBox)
    dialog.editBox = editBox
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    closeButton:SetWidth(100)
    closeButton:SetHeight(25)
    closeButton:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 15)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end
```

---

## Helper Functions

### mod(a, b)
**Purpose:** Modulo operation for Lua 5.1  
**Parameters:**
- `a` - number: Dividend
- `b` - number: Divisor

**Returns:** `number` - Remainder

**Implementation:**
```lua
local function mod(a, b)
    return a - math.floor(a / b) * b
end
```

**Why Needed:** Lua 5.1 doesn't have `%` operator

---

## Integration Points

### Called By
- [UI.lua](UI.md) - Export button click, history export
- [Core.lua](CORE.md) - Manual export requests

### Calls To
- None (self-contained)

---

## Lua 5.1 Compliance

### Modulo Operation
```lua
-- ✅ CORRECT
local function mod(a, b)
    return a - math.floor(a / b) * b
end

local remainder = mod(10, 3) -- 1

-- ❌ WRONG
local remainder = 10 % 3 -- % doesn't exist
```

### String Operations
```lua
-- ✅ CORRECT
string.gsub(name, "[%s:]", "_")  -- Pattern with % escape
string.len(data)                 -- Length
string.byte(data, i)             -- Byte at position
string.sub(chars, i, i)          -- Substring

-- ❌ WRONG
name:gsub("[ :]", "_")           -- Wrong pattern syntax
```

### Table Operations
```lua
-- ✅ CORRECT
table.getn(killTimes)
table.insert(parts, value)
table.concat(parts, "|")

-- ❌ WRONG
#killTimes
```

---

## Export String Examples

### Solo Run
```
TDT|abc123|Stratholme|Live|2723|2|Playerone|MyGuild|Warrior|0|Boss1:332|Boss2:2325|Boss3:2723
```

**Decoded Fields:**
- UUID: `abc123`
- Dungeon: `Stratholme`
- Variant: `Live`
- Time: 2723 seconds (45:23)
- Deaths: 2
- Player: `Playerone`
- Guild: `MyGuild`
- Classes: `Warrior` (solo)
- World Buffs: `0` (no)
- Bosses: 3 kills

---

### Group Run with World Buffs
```
TDT|def456|Upper_Blackrock_Spire|Default|3600|5|Tankman|Elite_Guild|Warrior,Priest,Mage,Rogue,Hunter|1|Boss1:600|Boss2:1200|Boss3:1800|Boss4:2400|Boss5:3000|Boss6:3600
```

**Decoded Fields:**
- UUID: `def456`
- Dungeon: `Upper_Blackrock_Spire` (spaces replaced)
- Variant: `Default`
- Time: 3600 seconds (60:00)
- Deaths: 5
- Player: `Tankman`
- Guild: `Elite_Guild` (spaces replaced)
- Classes: `Warrior,Priest,Mage,Rogue,Hunter`
- World Buffs: `1` (yes)
- Bosses: 6 kills

---

## Error Handling

### No Data Available
```lua
if table.getn(killTimes) == 0 then
    return nil
end
```

**Result:** Function returns `nil`, caller shows error message

### Missing Fields
- UUID: Defaults to `"no-uuid"`
- Player/Guild: Defaults to `"Unknown"` / `"No Guild"`
- Classes: Defaults to `"Solo"`
- World Buffs: Defaults to `false` (0)

### Invalid Characters
- Spaces and colons replaced with underscores
- Prevents breaking pipe-delimited format
- Import parsers must reverse this transformation

---

## Import Compatibility

### Future Import Function
Export format designed for potential import feature:

```lua
-- Pseudo-code for import (not implemented)
function importRunData(base64String)
    local decoded = decodeBase64(base64String)
    local parts = split(decoded, "|")
    
    if parts[1] ~= "TDT" then
        return nil, "Invalid format"
    end
    
    local entry = {
        uuid = parts[2],
        dungeon = parts[3]:gsub("_", " "),
        variant = parts[4]:gsub("_", " "),
        totalTime = tonumber(parts[5]),
        deaths = tonumber(parts[6]),
        playerName = parts[7]:gsub("_", " "),
        guildName = parts[8]:gsub("_", " "),
        groupClasses = split(parts[9], ","),
        hasWorldBuffs = parts[10] == "1",
        killTimes = {}
    }
    
    -- Parse boss kills (fields 11+)
    for i = 11, table.getn(parts) do
        local boss, time = string.match(parts[i], "([^:]+):(%d+)")
        table.insert(entry.killTimes, {
            name = boss:gsub("_", " "),
            time = tonumber(time)
        })
    end
    
    return entry
end
```

---

## Performance Notes

### Base64 Encoding
- Processes 3 bytes at a time
- Output size: ~133% of input size
- Typical export string: 200-400 characters → 270-530 Base64

### String Concatenation
- Uses `table.insert()` + `table.concat()` pattern
- Efficient for large strings in Lua 5.1
- Avoids repeated string copying

---

## Testing Checklist
- [ ] Export string generated correctly
- [ ] Base64 encoding valid (online decoder test)
- [ ] UUID format correct (UUID v4)
- [ ] All fields present and sanitized
- [ ] Spaces/colons replaced with underscores
- [ ] World buff flag correct (0/1)
- [ ] Boss kills in correct order
- [ ] Export dialog displays string
- [ ] Chat message shows string for copying
- [ ] EditBox auto-selects text
- [ ] History export works identically

---

## See Also
- [Core Module](CORE.md)
- [UI Module](UI.md)
- [World Buffs Feature](WORLDBUFFS_README.md)
