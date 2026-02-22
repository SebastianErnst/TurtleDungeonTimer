# Turtle WoW Addon Development - Comprehensive Reference

You are developing a World of Warcraft addon for **Turtle WoW**, a private server based on **WoW 1.12 (Vanilla)**. This uses **Lua 5.1** with significant restrictions compared to modern Lua and retail WoW.

---

## 📝 Important: Maintaining This Document

**If you discover a general problem, pattern, or gotcha during development that could be valuable for future reference** (examples: closure bugs, API quirks, common mistakes), **ask the user if it should be added to this document**.

This helps build a comprehensive knowledge base over time. Examples of things to document:
- Common bugs and their solutions
- API limitations or unexpected behavior
- Performance patterns
- Best practices discovered through debugging

Always ask first: "Should I add this [closure bug / API limitation / pattern] to the development prompt for future reference?"

---

## Critical Lua 5.1 Constraints

### Operators & Syntax

| ❌ DON'T USE | ✅ USE INSTEAD | Notes |
|-------------|----------------|-------|
| `a % b` | `mod(a, b)` | Modulo operator doesn't exist |
| `#table` | `table.getn(table)` | Length operator doesn't exist |
| `string.gmatch()` | `string.gfind()` | Different function name |
| `string.match()` | `string.find()` with captures | `string.match()` doesn't exist - use `local _, _, cap1, cap2 = string.find(s, pattern)` |
| `...` (varargs) | `arg` table | Varargs work differently |
| `x = x or default` in params | Set defaults in function body | No default parameters |
| `local function f() end` at file root | Works, but be careful with ordering | Forward declarations may be needed |

### String Functions (Lua 5.1)
```lua
-- Pattern matching
string.find(s, pattern)      -- Returns start, end indices
string.gfind(s, pattern)     -- Iterator (NOT gmatch!)
string.gsub(s, pattern, repl) -- Replace
string.sub(s, i, j)          -- Substring
string.format(fmt, ...)      -- Printf-style formatting
string.len(s)                -- Length (or just s:len())
string.lower(s) / string.upper(s)

-- NOTE: Patterns use % not \ for escapes
-- %d = digit, %s = whitespace, %a = letter, %w = alphanumeric
-- . = any char, * = 0+, + = 1+, - = 0+ non-greedy, ? = 0-1
```

### Table Functions (Lua 5.1)
```lua
table.insert(t, value)       -- Append to end
table.insert(t, pos, value)  -- Insert at position
table.remove(t, pos)         -- Remove at position (default: last)
table.getn(t)                -- Get length (NOT #t)
table.sort(t, comp)          -- Sort in-place
table.concat(t, sep)         -- Join to string

-- Iteration
for i, v in ipairs(t) do end -- Numeric indices only (1, 2, 3...)
for k, v in pairs(t) do end  -- All keys
```

### Math Functions
```lua
math.floor(x)
math.ceil(x)
math.abs(x)
math.min(a, b, ...)
math.max(a, b, ...)
math.random()                -- 0-1
math.random(n)               -- 1-n
math.random(m, n)            -- m-n
mod(a, b)                    -- NOT math.mod, NOT %
floor(x)                     -- Global shortcut exists
```

---

## WoW 1.12 API Constraints

### Frame Event Handlers

**Critical:** Event handlers use implicit globals, not parameters!

```lua
-- ❌ WRONG (Modern WoW style)
frame:SetScript("OnEvent", function(self, event, ...)
    -- DOES NOT WORK
end)

-- ✅ CORRECT (1.12 style)
frame:SetScript("OnEvent", function()
    -- Use these implicit globals:
    -- this   = the frame
    -- event  = event name (string)
    -- arg1, arg2, arg3... = event arguments
    
    if event == "ADDON_LOADED" then
        if arg1 == "MyAddon" then
            -- Initialize
        end
    end
end)
```

### Common Handler Globals

| Handler | Available Globals |
|---------|-------------------|
| OnEvent | `this`, `event`, `arg1`-`arg9` |
| OnClick | `this`, `arg1` (button: "LeftButton"/"RightButton") |
| OnUpdate | `this`, `arg1` (elapsed time in seconds) |
| OnEnter/OnLeave | `this` |
| OnShow/OnHide | `this` |
| OnMouseDown/Up | `this`, `arg1` (button) |
| OnMouseWheel | `this`, `arg1` (+1 up, -1 down) |
| OnDragStart/Stop | `this` |
| OnReceiveDrag | `this` |
| OnKeyDown/Up | `this`, `arg1` (key) |
| OnChar | `this`, `arg1` (character) |
| OnEditFocusGained/Lost | `this` |
| OnTextChanged | `this` |

### Frame Methods (1.12 Differences)

```lua
-- ❌ WRONG
frame:EnableMouseWheel(true)

-- ✅ CORRECT (no parameter = enable)
frame:EnableMouseWheel()

-- Creating frames
local frame = CreateFrame("Frame", "GlobalName", parent)
local button = CreateFrame("Button", "MyButton", parent, "UIPanelButtonTemplate")

-- Common methods
frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
frame:SetWidth(100)
frame:SetHeight(100)
frame:SetSize(100, 100)  -- May not exist, use SetWidth + SetHeight
frame:Show()
frame:Hide()
frame:IsVisible()
frame:IsShown()
frame:SetAlpha(0.5)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

-- Backdrop (1.12 style)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(1, 1, 1, 1)
```

### Font Strings & Textures

```lua
-- Font strings
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
text:SetText("Hello World")
text:SetTextColor(1, 1, 1)  -- RGB 0-1
text:SetJustifyH("LEFT")    -- LEFT, CENTER, RIGHT
text:SetJustifyV("TOP")     -- TOP, MIDDLE, BOTTOM
text:SetWidth(200)
text:SetHeight(0)           -- 0 = auto height
text:GetStringWidth()       -- Actual text width

-- Textures
local tex = frame:CreateTexture(nil, "BACKGROUND")
tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
tex:SetAllPoints(frame)
-- or
tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
tex:SetWidth(32)
tex:SetHeight(32)
tex:SetTexCoord(0, 1, 0, 1)  -- For texture atlas slicing
tex:SetVertexColor(1, 0, 0)  -- Tint
```

### Scroll Frames (1.12 Pattern)

**⚠️ CRITICAL:** ScrollFrames are NOT scrollable by default in 1.12! You MUST add mouse wheel handling manually or they won't work!

```lua
-- Create scroll frame
local scrollFrame = CreateFrame("ScrollFrame", "MyScrollFrame", parent)
scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
scrollFrame:SetWidth(200)
scrollFrame:SetHeight(300)

-- ⚠️ REQUIRED: Enable mouse wheel (no parameter!)
scrollFrame:EnableMouseWheel()

-- Create content frame
local content = CreateFrame("Frame", nil, scrollFrame)
content:SetWidth(200)
content:SetHeight(1)  -- Will grow as content added
scrollFrame:SetScrollChild(content)

-- ⚠️ REQUIRED: Mouse wheel handler or scrolling won't work!
scrollFrame:SetScript("OnMouseWheel", function()
    local current = scrollFrame:GetVerticalScroll()
    local max = scrollFrame:GetVerticalScrollRange()
    local step = 20
    
    if arg1 > 0 then  -- Scroll up (arg1 is +1 for up, -1 for down)
        scrollFrame:SetVerticalScroll(math.max(0, current - step))
    else  -- Scroll down
        scrollFrame:SetVerticalScroll(math.min(max, current + step))
    end
end)
```

**Common mistake:** Forgetting `EnableMouseWheel()` or the `OnMouseWheel` script. Without both, the scroll frame will not respond to mouse wheel input and appear broken!

---

## Common WoW 1.12 API Functions

### Item Information

```lua
-- Get item info (may return nil if item not in cache!)
local name, link, quality, iLevel, reqLevel, class, subclass, 
      maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemIdOrLink)

-- Quality colors
-- 0 = Poor (gray), 1 = Common (white), 2 = Uncommon (green)
-- 3 = Rare (blue), 4 = Epic (purple), 5 = Legendary (orange)

-- Extract item ID from link
local function GetItemIdFromLink(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return tonumber(id)
end

-- Item link format:
-- |cFFFFFFFF|Hitem:12345:0:0:0|h[Item Name]|h|r
-- |cAARRGGBB = color, |H = hyperlink start, |h = hyperlink text, |r = reset
```

### Bag Functions

```lua
for bag = 0, 4 do  -- 0 = backpack, 1-4 = bags
    local slots = GetContainerNumSlots(bag)
    for slot = 1, slots do
        local link = GetContainerItemLink(bag, slot)
        local texture, count, locked, quality, readable = GetContainerItemInfo(bag, slot)
        
        if link then
            -- Process item
        end
    end
end
```

### Auction House

```lua
-- Must be at AH with window open
local numItems = GetNumAuctionItems("list")  -- "list", "bidder", "owner"

for i = 1, numItems do
    local name, texture, count, quality, canUse, level, 
          minBid, minIncrement, buyoutPrice, bidAmount, 
          highBidder, owner = GetAuctionItemInfo("list", i)
    local link = GetAuctionItemLink("list", i)
end
```

### Merchant/Vendor

```lua
-- Must have merchant window open
local numItems = GetMerchantNumItems()

for i = 1, numItems do
    local name, texture, price, quantity, numAvailable, 
          isUsable, extendedCost = GetMerchantItemInfo(i)
    local link = GetMerchantItemLink(i)
    
    -- extendedCost = true if requires tokens/marks (not just gold)
    -- numAvailable = -1 if unlimited supply
end
```

### Tradeskill/Crafting

```lua
-- Must have tradeskill window open
local numSkills = GetNumTradeSkills()

for i = 1, numSkills do
    local name, type, numAvailable, isExpanded = GetTradeSkillInfo(i)
    -- type: "header", "subheader", or "recipe"
    
    if type ~= "header" and type ~= "subheader" then
        local link = GetTradeSkillItemLink(i)
        local numReagents = GetTradeSkillNumReagents(i)
        
        for j = 1, numReagents do
            local reagentName, reagentTexture, reagentCount, 
                  playerReagentCount = GetTradeSkillReagentInfo(i, j)
            local reagentLink = GetTradeSkillReagentItemLink(i, j)
        end
    end
end
```

### Unit Functions

```lua
UnitName("player")           -- Player name
UnitName("target")           -- Target name (nil if none)
UnitClass("player")          -- Localized class, english class
UnitRace("player")           -- Localized race, english race
UnitLevel("player")          -- Level
UnitFactionGroup("player")   -- "Alliance" or "Horde"
UnitGUID("player")           -- May not exist in 1.12!

-- Check unit type
UnitIsPlayer("target")
UnitIsFriend("player", "target")
UnitIsEnemy("player", "target")
UnitIsDead("target")
```

### Buff Functions

**⚠️ CRITICAL: Three different buff APIs with different indexing AND ordering!**

```lua
-- API Comparison (WoW 1.12 / Turtle WoW):

-- 1. UnitBuff(unit, index)
--    - 1-based indexing (first buff = 1)
--    - Internal buff order (NOT visual order!)
--    - Returns: texture only

-- 2. GetPlayerBuff(index, filter)
--    - 0-based indexing (first buff = 0)
--    - Visual/Interface order (matches UI buff bar!)
--    - Returns: texture, count, buffType
--    - Filter: "HELPFUL" (buffs), "HARMFUL" (debuffs), "PASSIVE" (passives)

-- 3. CancelPlayerBuff(index)
--    - 0-based indexing (first buff = 0)
--    - Uses GetPlayerBuff order/indices!

-- CRITICAL: UnitBuff and GetPlayerBuff return buffs in DIFFERENT ORDER!
-- You CANNOT convert UnitBuff index to CancelPlayerBuff index with simple -1!
```

**❌ WRONG - Using UnitBuff with CancelPlayerBuff:**
```lua
-- This will remove THE WRONG BUFFS!
for buffIndex = 1, 50 do
    local buffTexture = UnitBuff("player", buffIndex)
    if not buffTexture then break end
    
    scanTooltip:ClearLines()
    scanTooltip:SetUnitBuff("player", buffIndex)
    local buffName = MyScanTooltipTextLeft1:GetText()
    
    if buffName == "Greater Blessing of Sanctuary" then
        -- BUG: UnitBuff index does NOT match CancelPlayerBuff index!
        -- Different order means buffIndex-1 removes wrong buff!
        CancelPlayerBuff(buffIndex - 1)  -- WRONG BUFF REMOVED!
    end
end
```

**✅ CORRECT - Using GetPlayerBuff with CancelPlayerBuff:**
```lua
-- Create hidden tooltip for scanning
local scanTooltip = CreateFrame("GameTooltip", "MyScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Scan all buffs using GetPlayerBuff
for i = 0, 50 do  -- 0-based!
    local texture, count, buffType = GetPlayerBuff(i, "HELPFUL")
    if not texture then break end  -- No more buffs
    
    -- Get buff name via tooltip
    scanTooltip:ClearLines()
    scanTooltip:SetPlayerBuff(i)  -- Use SetPlayerBuff, not SetUnitBuff!
    local buffName = MyScanTooltipTextLeft1:GetText()
    
    -- Process buff...
    if buffName == "Greater Blessing of Sanctuary" then
        CancelPlayerBuff(i)  -- Correct! Same index, same order
    end
end
```

**Why GetPlayerBuff is better:**
1. **Same indexing:** Both GetPlayerBuff and CancelPlayerBuff use 0-based indices
2. **Same ordering:** Both match the visual buff bar order
3. **More info:** Returns count and buffType, not just texture
4. **Direct mapping:** GetPlayerBuff(5) → CancelPlayerBuff(5) works perfectly

**Tooltip methods:**
- `scanTooltip:SetUnitBuff(unit, index)` - For UnitBuff indices (1-based)
- `scanTooltip:SetPlayerBuff(index)` - For GetPlayerBuff indices (0-based)

**Important notes:**
- **Never mix UnitBuff with CancelPlayerBuff** - different ordering causes wrong buffs to be removed!
- Always use GetPlayerBuff + CancelPlayerBuff together
- GetPlayerBuff filter: "HELPFUL" = buffs, "HARMFUL" = debuffs, "PASSIVE" = passive effects
- Tooltip text fields: `TooltipNameTextLeft1`, `TooltipNameTextRight1` (replace TooltipName with your tooltip's global name)

### Reputation

```lua
-- Iterate all factions
for i = 1, GetNumFactions() do
    local name, description, standingId, barMin, barMax, barValue,
          atWarWith, canToggleAtWar, isHeader, isCollapsed,
          hasRep, isWatched, isChild = GetFactionInfo(i)
    
    -- standingId: 1=Hated, 2=Hostile, 3=Unfriendly, 4=Neutral,
    --             5=Friendly, 6=Honored, 7=Revered, 8=Exalted
end

-- NOTE: GetFactionInfoByID() does NOT exist in 1.12!
-- Must iterate and match by name
```

### Chat Output

```lua
-- Print to default chat frame
DEFAULT_CHAT_FRAME:AddMessage("Hello", r, g, b)  -- RGB 0-1

-- Print with color codes
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Green text|r normal text")

-- Color code format: |cAARRGGBB  (AA = alpha, usually FF)
```

### Slash Commands

```lua
SlashCmdList["MYADDON"] = function(msg)
    -- msg = everything after the command
    -- string.match doesn't exist in 1.12 - use string.find!
    local _, _, cmd, args = string.find(msg, "^(%S+)%s*(.*)$")
    cmd = string.lower(cmd or "")
    
    if cmd == "help" then
        -- Show help
    elseif cmd == "config" then
        -- Open config
    else
        -- Default action
    end
end
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"
```

### Tooltip Hooking

```lua
-- Hook the main game tooltip
local origSetBagItem = GameTooltip.SetBagItem
GameTooltip.SetBagItem = function(self, bag, slot)
    origSetBagItem(self, bag, slot)
    -- Add custom lines after original tooltip
    GameTooltip:AddLine("My custom info", 1, 1, 0)
    GameTooltip:Show()  -- Refresh to include new line
end

-- Other hookable functions:
-- SetInventoryItem, SetLootItem, SetMerchantItem
-- SetTradeSkillItem, SetAuctionItem, SetHyperlink, etc.
```

---

## SavedVariables (Persistent Data)

### TOC File Declaration

```toc
## Interface: 11200
## Title: My Addon
## Notes: Description here
## Author: Your Name
## Version: 1.0
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB

Core.lua
Module1.lua
Module2.lua
```

### Loading/Saving Pattern

```lua
-- Declare with defaults
MyAddonDB = MyAddonDB or {}

local defaults = {
    setting1 = true,
    setting2 = 50,
    prices = {}
}

-- On VARIABLES_LOADED event
local function OnLoad()
    -- Merge with defaults
    for k, v in pairs(defaults) do
        if MyAddonDB[k] == nil then
            MyAddonDB[k] = v
        end
    end
end

-- Data automatically saves on logout/reload
-- Force save: not possible in 1.12 (no explicit SaveVariables call)
```

### Version Management (TurtleDungeonTimer Specific)

**⚠️ CRITICAL:** When updating the addon version, you MUST update it in THREE places:

1. **Core.lua** - The `ADDON_VERSION` constant
2. **TurtleDungeonTimer.toc** - The `## Version:` field
3. **README.md** - The `**Version:**` field in the header

(All three must match exactly!)

**Version Format: x.y.z**
- **x** = Release number (currently 0 for development, will be 1+ for production releases)
- **y** = Feature version (0-999)
  - Increment when user confirms functionality with "funktioniert"
  - Reset z to 0 when incrementing y
- **z** = Build number (0-9999)
  - Increment on EVERY code change made by AI assistant
  - Automatically incremented during development

```lua
-- In Core.lua (lines ~11-18)
-- ============================================================================
-- VERSION MANAGEMENT (SINGLE SOURCE OF TRUTH)
-- ============================================================================
-- VERSION FORMAT: x.y.z
-- x = Release number (currently 0 for development)
-- y = Feature version (0-999, increment when user says "funktioniert", reset z to 0)
-- z = Build number (0-9999, increment on every change)
-- NOTE: This version MUST match the version in TurtleDungeonTimer.toc!
-- When updating version: Change ONLY this constant and the .toc file.
TurtleDungeonTimer.ADDON_VERSION = "0.14.0"
TurtleDungeonTimer.SYNC_VERSION = "1.0"  -- Protocol version for sync compatibility
```

**Version Update Rules:**
1. **Build number (z)**: Increment automatically on every code change
2. **Feature version (y)**: Increment when user says "funktioniert", then reset z to 0
3. **Release number (x)**: Only change for major production releases

**Version Display:**
- Version is shown in chat when addon loads: "[Turtle Dungeon Timer] Version 0.14.8 loaded"
- Always keep Core.lua and .toc file versions synchronized

**Why this matters:** 
- All other files (Sync.lua, Preparation.lua, etc.) reference `self.ADDON_VERSION` or `self.SYNC_VERSION`
- The sync system checks version compatibility between party members
- Having a single source of truth prevents version mismatches and sync failures
- Version tracking helps identify when issues were introduced

**Protocol Version (`SYNC_VERSION`):**
- Only change when sync message format changes (breaking compatibility)
- Format: Major.Minor (e.g., "1.0", "1.1", "2.0")
- All players need same major version for sync to work

### Localization System (TurtleDungeonTimer Specific)

**⚠️ CRITICAL:** The addon uses a comprehensive localization system for multi-language support.

**File Structure:**
- **Localization.lua** - Loaded after Core.lua, before Data.lua in .toc
- Contains all translation keys for English (enUS) and German (deDE)
- Provides helper functions for easy translation usage

**Language Detection:**
```lua
-- Automatic detection via GetLocale()
local clientLocale = GetLocale() or "enUS"

-- Force specific language (override auto-detection)
TurtleDungeonTimer.forceLanguage = "enUS"  -- Set to nil for auto-detection

-- Locale mapping
local localeMapping = {
    ["enUS"] = "enUS", ["enGB"] = "enUS",
    ["deDE"] = "deDE", ["frFR"] = "frFR",
    ["esES"] = "esES", ["ruRU"] = "ruRU",
    ["zhCN"] = "zhCN", ["zhTW"] = "zhTW"
}
```

**Translation System:**
```lua
-- Translation tables structure
translations.enUS = {
    ["PREP_ONLY_LEADER"] = "Only the group leader can prepare the run!",
    ["UI_CANCEL_BUTTON"] = "Cancel",
    -- ... 80+ keys covering all features
}

translations.deDE = {
    ["PREP_ONLY_LEADER"] = "Nur der Gruppenführer kann den Run vorbereiten!",
    ["UI_CANCEL_BUTTON"] = "Abbrechen",
    -- ... German translations
}

-- Metatable with automatic fallback chain:
-- currentLanguage → enUS (English) → key itself
setmetatable(TurtleDungeonTimer.L, {
    __index = function(t, key)
        local lang = translations[currentLanguage]
        if lang and lang[key] then return lang[key] end
        if translations.enUS[key] then return translations.enUS[key] end
        return key
    end
})
```

**Helper Functions:**

1. **TDT_L(key)** - Get translated text (without formatting)
   ```lua
   -- Simple translation
   local text = TDT_L("UI_CANCEL_BUTTON")  -- "Cancel" or "Abbrechen"
   
   -- With string.format for parameters
   local msg = string.format(TDT_L("SYNC_DATA_FROM"), playerName, dungeonName)
   -- "Run data synchronized from %s: %s" → "Run data synchronized from Player: Dungeon"
   ```

2. **TDT_Print(key, color, ...)** - Print colored localized message to chat (with formatting)
   ```lua
   -- Print with color (no parameters)
   TDT_Print("PREP_NO_DUNGEON", "error")
   -- Output: [Turtle Dungeon Timer] No dungeon selected!  (in red)
   
   -- Available colors:
   -- "error" (red), "warning" (orange), "success" (green), "info" (cyan), "normal" (white)
   
   -- With parameters (TDT_Print handles string.format internally)
   TDT_Print("SYNC_DATA_FROM", "success", playerName, dungeonName)
   ```

**Usage in Code:**

```lua
-- ❌ WRONG - Hardcoded text
title:SetText("Run vorbereiten - Dungeon wählen")
DEFAULT_CHAT_FRAME:AddMessage("Kein Dungeon ausgewählt!", 1, 0, 0)

-- ✅ CORRECT - Using localization
title:SetText(TDT_L("UI_PREPARE_RUN_TITLE"))
TDT_Print("PREP_NO_DUNGEON", "error")

-- With formatting
local message = string.format(TDT_L("UI_RESET_VOTE_MESSAGE"), initiatorName)
message:SetText(message)
```

**Adding New Languages:**

1. Copy the `translations.enUS` table structure
2. Add new language code (e.g., `translations.frFR = {}`)
3. Translate all 80+ keys
4. Test with `TurtleDungeonTimer.forceLanguage = "frFR"`

**Translation Key Categories:**
- `PREP_*` - Preparation system messages
- `READY_CHECK_*` - Ready check UI/messages
- `WORLD_BUFFS_*` - World buff detection
- `SYNC_*` - Synchronization messages
- `TRASH_*` - Trash scanner messages
- `BOSS_*` - Boss kill messages
- `EXPORT_*` - Export system messages
- `UI_*` - UI element text (buttons, titles, dialogs)
- `TOOLTIP_*` - Tooltip text
- `DEBUG_*` - Debug messages (keep in English)

**Important Notes:**
- All chat messages should use `TDT_Print()` for consistency
- All UI text (SetText) should use `TDT_L()`
- **When adding new UI text or chat messages:** ALWAYS add the translation key to both `translations.enUS` AND `translations.deDE` in Localization.lua
- Debug messages kept in English for consistency across languages
- Fallback chain ensures addon never shows missing translations

---

## Events Reference

### Addon Lifecycle

```lua
"ADDON_LOADED"       -- arg1 = addon name
"VARIABLES_LOADED"   -- SavedVariables are now available
"PLAYER_LOGIN"       -- Player is fully in the world
"PLAYER_ENTERING_WORLD" -- Fired on login and every zone transition
"PLAYER_LOGOUT"      -- About to logout (save data here!)
```

### Common Events

```lua
-- Bags
"BAG_UPDATE"         -- arg1 = bag number

-- Trading/Vendors
"MERCHANT_SHOW"      -- Vendor window opened
"MERCHANT_CLOSED"    -- Vendor window closed
"AUCTION_HOUSE_SHOW" -- AH opened
"AUCTION_HOUSE_CLOSED"

-- Tradeskills
"TRADE_SKILL_SHOW"
"TRADE_SKILL_CLOSE"
"TRADE_SKILL_UPDATE"

-- Chat
"CHAT_MSG_SYSTEM"    -- arg1 = message
"CHAT_MSG_SAY"       -- arg1 = message, arg2 = sender

-- Combat
"PLAYER_REGEN_DISABLED" -- Entered combat
"PLAYER_REGEN_ENABLED"  -- Left combat
```

---

## Common Patterns

### Addon Namespace

```lua
-- Create addon namespace (Core.lua)
MyAddon = MyAddon or {}
MyAddon.version = "1.0"

-- In other files
MyAddon.SomeFunction = function(self, arg)
    -- Can use self:OtherFunction()
end

-- Or
function MyAddon:SomeFunction(arg)
    -- self is automatically MyAddon
end
```

### Variable Scopes & Namespace Access (CRITICAL!)

**⚠️ COMMON BUG:** Accessing namespace properties as if they were global variables!

```lua
-- ❌ WRONG - Accessing namespace property as global
function MyAddon:someFunction()
    local data = DUNGEON_DATA[key]  -- ERROR: attempt to index global 'DUNGEON_DATA' (a nil value)
end

-- ✅ CORRECT - Use self to access namespace properties
function MyAddon:someFunction()
    local data = self.DUNGEON_DATA[key]  -- Works!
end

-- ✅ ALSO CORRECT - Explicit namespace access
function MyAddon:someFunction()
    local data = MyAddon.DUNGEON_DATA[key]  -- Works!
end

-- In functions without 'self' parameter
local function helperFunction()
    -- Must use full namespace
    local data = MyAddon.DUNGEON_DATA[key]
end
```

**How to identify the correct scope:**

1. **Search first:** Use grep to find how the variable is used elsewhere
   ```bash
   # If you see MyAddon.VARNAME in the codebase:
   grep -r "DUNGEON_DATA" *.lua
   # Results: MyAddon.DUNGEON_DATA, self.DUNGEON_DATA
   # → Variable is in namespace, NOT global!
   ```

2. **Check consistency:** If other code uses `self.VARNAME`, you must too

3. **Global vs Namespace:**
   - Global: Declared at file root without namespace prefix
   - Namespace: Declared as `MyAddon.VARNAME = ...`

**Common namespace properties to watch for:**
- `self.DUNGEON_DATA` or `MyAddon.DUNGEON_DATA`
- `self.selectedDungeon`, `self.selectedVariant`
- `self.currentRun`, `self.runHistory`
- Any property set as `MyAddon.propertyName = value`

**Rule of thumb:** If you see a variable used with a namespace prefix anywhere in the codebase, **NEVER** access it as a plain global variable!

### Persistent Timer System (Important!)

**⚠️ CRITICAL:** The TurtleDungeonTimer addon implements a sophisticated persistent timer system that continues running through reloads, logouts, and even crashes!

```lua
-- How it works:
-- 1. Timer state saved every second while running (Core.lua:saveLastRun)
-- 2. saveTimestamp tracks when the run was last saved
-- 3. On reload: calculates elapsed time + offline time
-- 4. Timer continues seamlessly with correct time display

-- Key variables for persistent timing:
self.isRunning           -- Timer currently active
self.startTime           -- GetTime() when started (recalculated on restore)
self.restoredElapsedTime -- Elapsed time before reload (for paused state)
saveTimestamp            -- Unix time() when saved (for offline calculation)
```

**What happens on reload:**
1. `restoreLastRun()` checks if same dungeon selected
2. If `lastRun.isRunning = true`: Timer continues automatically
3. New `startTime = GetTime() - elapsedAtSave - offlineTime`
4. If `lastRun.isRunning = false`: Timer shows paused with correct elapsed time

**When run state is saved:**
- Every second during active timer (automatic)
- Every boss kill event
- Every death event  
- When timer is paused
- When dungeon/variant is changed

**Common gotcha:** Always use `self.restoredElapsedTime` in `updateTimer()` for paused timers!

```lua
-- ❌ WRONG - Only shows time for running timers
if self.isRunning and self.startTime then
    elapsed = GetTime() - self.startTime
end

-- ✅ CORRECT - Shows time for both running and paused timers
if self.isRunning and self.startTime then
    elapsed = GetTime() - self.startTime
elseif self.restoredElapsedTime then
    elapsed = self.restoredElapsedTime
end
```

### Closures in Loops (CRITICAL!)

**⚠️ COMMON BUG:** Variables in closures inside loops will capture the **last value** from the loop, not the current iteration value!

```lua
-- ❌ WRONG - All buttons will use the last mob value
for i, mob in ipairs(mobs) do
    local button = CreateFrame("Button", nil, parent)
    button:SetScript("OnClick", function()
        -- mob will be the LAST mob from the loop, or nil!
        DeleteMob(mob.name)  -- BUG!
    end)
end

-- ✅ CORRECT - Capture values in local variables
for i, mob in ipairs(mobs) do
    -- Create local copies to capture in closure
    local mobName = mob.name
    local mobHP = mob.hp
    local mobRef = mob  -- If you need the table reference
    
    local button = CreateFrame("Button", nil, parent)
    button:SetScript("OnClick", function()
        -- Now mobName is the correct value for this button
        DeleteMob(mobName)  -- Works correctly!
    end)
end
```

**Why this happens:** Lua closures capture variables by reference, not by value. In a loop, the loop variable changes on each iteration. When the closure executes later (e.g., on button click), it reads the current value of that variable, which is the last value from the loop.

**Solution:** Always create local copies of loop variables if you use them in closures (OnClick, OnUpdate, etc.)!

### Function/Variable Existence Checks (CRITICAL!)

**⚠️ COMMON BUG:** Calling functions or accessing variables that don't exist yet causes runtime errors!

```lua
-- ❌ WRONG - Calling undefined function
function MyAddon:startProcess()
    -- This will crash if handleError doesn't exist!
    self:handleError("Something went wrong")  -- ERROR: attempt to call method 'handleError' (a nil value)
end

-- ✅ CORRECT - Define functions before calling them
function MyAddon:handleError(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Error:|r " .. msg, 1, 0, 0)
end

function MyAddon:startProcess()
    -- Now this works
    self:handleError("Something went wrong")
end

-- ✅ ALSO CORRECT - Check existence before calling
function MyAddon:startProcess()
    if self.handleError then
        self:handleError("Something went wrong")
    else
        DEFAULT_CHAT_FRAME:AddMessage("Error handler not available", 1, 0, 0)
    end
end

-- ❌ WRONG - Accessing undefined variable
local config = MyAddonConfig.setting1  -- ERROR if MyAddonConfig is nil

-- ✅ CORRECT - Check existence first
local config = MyAddonConfig and MyAddonConfig.setting1 or defaultValue
```

**Best Practices:**
1. **Define before use**: Always define functions/variables before calling them
2. **File load order**: Put utility functions in files that load early (check .toc order)
3. **Check existence**: Use `if self.funcName then` or `var and var.field` for safety
4. **Forward declarations**: For mutual recursion, declare functions first:
   ```lua
   local funcA, funcB  -- Forward declarations
   
   funcA = function()
       funcB()
   end
   
   funcB = function()
       funcA()
   end
   ```

**Why this matters:** Lua executes files sequentially. If file A calls a function from file B, but B loads after A, the function doesn't exist yet. Always check your .toc load order!

### FontString/Frame Reuse and Validation (CRITICAL!)

**⚠️ COMMON BUG:** Caching FontStrings or Frames in tables and assuming they're still valid later!

```lua
-- ❌ WRONG - Only checking table length
if not self.frame.bossRows or table.getn(self.frame.bossRows) ~= bossCount then
    -- Create new rows
    self.frame.bossRows = {}
    for i = 1, bossCount do
        local text = parent:CreateFontString(...)
        self.frame.bossRows[i] = {name = text}
    end
end
-- Problem: Table has correct length but entries might be NIL or invalid!

-- ✅ CORRECT - Validate that cached UI elements are still valid
local needsRecreate = false
if not self.frame.bossRows or table.getn(self.frame.bossRows) ~= bossCount then
    needsRecreate = true
else
    -- Check if first row is still valid
    if not self.frame.bossRows[1] or 
       not self.frame.bossRows[1].name or 
       not self.frame.bossRows[1].name.SetText then
        needsRecreate = true
    end
end

if needsRecreate then
    -- Create new rows
    self.frame.bossRows = {}
    for i = 1, bossCount do
        local text = parent:CreateFontString(...)
        self.frame.bossRows[i] = {name = text}
    end
else
    -- Rows are valid, just show them (if they were hidden)
    for i = 1, bossCount do
        self.frame.bossRows[i].name:Show()
    end
end
```

**Why this happens:**
- FontStrings/Frames can be destroyed or invalidated (e.g., parent hidden, frame recycled)
- `Hide()` makes them invisible but they remain in your table
- Table length (`table.getn()`) stays the same even if entries are NIL
- Lua doesn't automatically clean up invalid references

**When to validate:**
- Before reusing cached UI elements after Hide/Show cycles
- When parent frames are shown/hidden repeatedly
- After dungeon/zone changes that might reset UI state
- Any time you're unsure if cached frames are still valid

**Best Practice:**
Always validate that cached UI elements have their expected methods (e.g., `SetText`) before using them!

### Performance Optimization Patterns (CRITICAL!)

**⚠️ COMMON PERFORMANCE ISSUES:** WoW 1.12 is very sensitive to inefficient code. Always optimize hot paths!

#### 1. OnUpdate Throttling

```lua
-- ❌ WRONG - Updates every frame (60+ FPS = massive CPU waste)
frame:SetScript("OnUpdate", function()
    updateUI()  -- Called 60+ times per second!
end)

-- ✅ CORRECT - Throttle to reasonable rate
frame:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - this.lastUpdate >= 0.1 then  -- Max 10 updates/sec
        this.lastUpdate = now
        updateUI()
    end
end)
```

**Rule:** OnUpdate should NEVER call expensive functions every frame. Always throttle!

#### 2. String Formatting Cache

```lua
-- ❌ WRONG - Formats string every frame even if unchanged
function updateTimer()
    local timeStr = string.format("%02d:%02d", mins, secs)
    frame.text:SetText(timeStr)  -- Called 60+ times/sec!
end

-- ✅ CORRECT - Cache and only update when changed
function updateTimer()
    local currentTime = mins * 60 + secs
    if self.lastDisplayedTime ~= currentTime then
        self.lastDisplayedTime = currentTime
        local timeStr = string.format("%02d:%02d", mins, secs)
        frame.text:SetText(timeStr)
    end
end
```

**Why:** `string.format()` is expensive in Lua 5.1. Cache results and early-exit if unchanged!

#### 3. O(1) Lookups Instead of O(n) Iteration

```lua
-- ❌ WRONG - Linear search in hot path (e.g., every mob kill)
function onMobKilled(name)
    for i = 1, table.getn(bossList) do
        if bossList[i] == name then  -- O(n) search!
            -- Do something
        end
    end
end

-- ✅ CORRECT - Build lookup table once, use O(1) access
-- During initialization:
self.bossLookup = {}
for i, boss in ipairs(bossList) do
    self.bossLookup[boss.name] = i  -- name -> index
end

-- In hot path:
function onMobKilled(name)
    local index = self.bossLookup[name]  -- O(1) lookup!
    if index then
        -- Do something
    end
end
```

**Rule:** Never iterate arrays in frequently-called code. Build lookup tables!

#### 4. UI Update Early Exit

```lua
-- ❌ WRONG - Always updates UI even if nothing changed
function updateProgressBar()
    local progress = calculateProgress()
    bar:SetWidth(progress * 200)
    text:SetText(string.format("%.2f%%", progress))
end

-- ✅ CORRECT - Early exit if unchanged
function updateProgressBar()
    local progress = calculateProgress()
    local rounded = math.floor(progress * 100) / 100
    
    if self.lastProgress == rounded then return end  -- Early exit!
    self.lastProgress = rounded
    
    bar:SetWidth(progress * 200)
    text:SetText(string.format("%.2f%%", progress))
end
```

**Rule:** Always check if update is needed before expensive UI operations!

#### 5. Pre-compute and Cache

```lua
-- ❌ WRONG - Builds and sorts menu every time it opens
function showMenu()
    local items = {}
    for name, data in pairs(DUNGEON_DATA) do
        table.insert(items, name)
    end
    table.sort(items)  -- Expensive!
    -- Create UI...
end

-- ✅ CORRECT - Build once, cache forever
-- During addon load:
self.cachedDungeonMenu = buildSortedDungeonList()

-- When showing:
function showMenu()
    local items = self.cachedDungeonMenu  -- Use cache!
    -- Create UI...
end
```

**Rule:** Pre-compute static data at load time, not at runtime!

#### 6. Batch Similar Operations

```lua
-- ❌ WRONG - Multiple addon messages in quick succession
self:sendSyncMessage("BOSS1")
self:sendSyncMessage("BOSS2")
self:sendSyncMessage("BOSS3")

-- ✅ CORRECT - Batch into single message
self:sendSyncMessage("BOSSES:Boss1,Boss2,Boss3")
```

**Rule:** Minimize addon channel traffic - batch related updates!

#### 7. Avoid Redundant OnUpdate Handlers

```lua
-- ❌ WRONG - Multiple OnUpdate handlers doing similar work
frame1:SetScript("OnUpdate", function() updateTimer() end)
frame2:SetScript("OnUpdate", function() updateUI() end)

-- ✅ CORRECT - Single throttled handler
timerFrame:SetScript("OnUpdate", function()
    if now - lastUpdate >= 0.1 then
        lastUpdate = now
        updateTimer()
        updateUI()
    end
end)
```

**Rule:** Consolidate OnUpdate handlers to minimize overhead!

### Performance Checklist

Before committing code, check:
- [ ] No OnUpdate without throttling (min 0.1s intervals)
- [ ] String formatting only when value changes
- [ ] No O(n) loops in event handlers (use lookups)
- [ ] UI updates have early-exit checks
- [ ] Static data pre-computed and cached
- [ ] No redundant frame/string operations
- [ ] Addon messages batched when possible

### Magic Numbers & Central Constants (Best Practice)

**⚠️ COMMON MAINTENANCE ISSUE:** Hardcoded limits spread across code are easy to miss and cause inconsistent behavior.

```lua
-- ❌ WRONG - Hardcoded limit in logic
while table.getn(MyAddonDB.history) > 500 do
    table.remove(MyAddonDB.history)
end

-- ✅ CORRECT - Central constant at file top (or config section)
local HISTORY_LIMIT = 500

while table.getn(MyAddonDB.history) > HISTORY_LIMIT do
    table.remove(MyAddonDB.history)
end
```

**Why this helps:**
1. **Single source of truth** for important limits
2. **Safer refactoring** (change once, applies everywhere)
3. **Clear intent** when reading code (`HISTORY_LIMIT` explains meaning)
4. **Fewer bugs** from mismatched values in different files/functions

**Rule:** Any gameplay/UI/storage limit used in logic should be a named constant, not an inline number.

---

### Delayed/Scheduled Execution

```lua
-- Using OnUpdate (only way in 1.12)
local timerFrame = CreateFrame("Frame")
local timers = {}

timerFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    for id, timer in pairs(timers) do
        if now >= timer.when then
            timer.callback()
            if timer.repeating then
                timer.when = now + timer.delay
            else
                timers[id] = nil
            end
        end
    end
end)

function MyAddon:ScheduleTimer(callback, delay, repeating)
    local id = GetTime() .. math.random()
    timers[id] = {
        callback = callback,
        when = GetTime() + delay,
        delay = delay,
        repeating = repeating
    }
    return id
end

function MyAddon:CancelTimer(id)
    timers[id] = nil
end
```

### Safe Item Info Fetching

```lua
-- GetItemInfo returns nil if item not cached
-- Must wait for item to be queried from server
function MyAddon:GetItemInfoSafe(itemId, callback)
    local name = GetItemInfo(itemId)
    if name then
        callback(GetItemInfo(itemId))
    else
        -- Create a tooltip to query the item
        local tip = CreateFrame("GameTooltip", "MyAddonScanTip", nil, "GameTooltipTemplate")
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        tip:SetHyperlink("item:" .. itemId .. ":0:0:0")
        
        -- Check again after a short delay
        local checkFrame = CreateFrame("Frame")
        local elapsed = 0
        checkFrame:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            local name = GetItemInfo(itemId)
            if name or elapsed > 2 then
                checkFrame:SetScript("OnUpdate", nil)
                if name then
                    callback(GetItemInfo(itemId))
                end
            end
        end)
    end
end
```

---

## Turtle WoW Specific Notes

1. **Custom Content**: Turtle WoW has custom items, quests, and zones not in original 1.12
2. **Extended Level Cap**: May have higher level cap than 60
3. **Custom Races/Classes**: Check their wiki for specifics
4. **API Extensions**: Some custom API functions may exist - check their addon documentation
5. **Hardcore Mode**: Special rules may apply for hardcore characters

---

## Debugging Tips

```lua
-- Debug mode toggle
MyAddonDebug = MyAddonDebug or false

local function Debug(msg)
    if MyAddonDebug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[MyAddon]|r " .. tostring(msg))
    end
end

-- Print table contents
local function PrintTable(t, indent)
    indent = indent or ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            Debug(indent .. tostring(k) .. ":")
            PrintTable(v, indent .. "  ")
        else
            Debug(indent .. tostring(k) .. " = " .. tostring(v))
        end
    end
end
```

---

## File Structure Best Practice

```
MyAddon/
├── MyAddon.toc          # Addon metadata, load order
├── Core.lua             # Namespace, events, initialization
├── Database.lua         # Static data tables
├── Utils.lua            # Helper functions
├── Modules/
│   ├── Feature1.lua
│   └── Feature2.lua
├── UI.lua               # Frame creation, display logic
└── Commands.lua         # Slash commands (load last)
```

### TOC Load Order Matters!
Files are executed in the order listed. Dependencies must load first:
```toc
Core.lua          # First - creates namespace
Database.lua      # Second - static data
Utils.lua         # Third - helpers
Modules/Feature1.lua
Modules/Feature2.lua
UI.lua
Commands.lua      # Last - references everything else
```

---

## Quick Reference Card

```lua
-- Length of table
table.getn(t)           -- NOT #t

-- Modulo
mod(a, b)               -- NOT a % b

-- String iterator
string.gfind(s, pat)    -- NOT string.gmatch

-- Event handlers use globals
this, event, arg1, arg2, arg3...

-- Enable mouse wheel (no parameter)
frame:EnableMouseWheel()

-- Print to chat
DEFAULT_CHAT_FRAME:AddMessage("text", r, g, b)

-- Time
time()                  -- Unix timestamp
GetTime()               -- Game time (seconds since login)
date("*t", timestamp)   -- Parse timestamp to table

-- Item link parsing
string.find(link, "item:(%d+)")
string.find(link, "%[(.-)%]")
```