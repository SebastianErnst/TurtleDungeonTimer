# UI.lua - User Interface Module Documentation

## Overview
Complete UI redesign based on mockup. Creates compact, expandable main frame with modern layout. Handles all visual elements, user interactions, and dynamic updates for the dungeon timer addon.

**WoW Version:** 1.12 (Vanilla)  
**Lua Version:** 5.1  
**Constraints:** See [Development Prompt](TurtleWoW_Addon_Development_Prompt.md)

---

## Module Responsibilities
- Main frame creation and positioning (400px x 120px collapsed)
- Dungeon/variant selection UI
- Timer display with death counter
- Cyan progress bar with percentage
- Collapsible boss list with green scrollbar
- Boss row highlighting (green background for defeated)
- Control buttons (Start/History)
- Dynamic frame resizing (collapsed/expanded)
- Position persistence
- UI state management

---

## UI Structure (New Design)

```
TurtleDungeonTimer Frame (400px wide)
├── Header
│   ├── Dungeon Name Text (clickable)
│   ├── History Button (gear icon)
│   └── Start Button (play/stop icon)
├── Timer Row
│   ├── Timer Text (MM:SS)
│   └── Death Counter (X N + skull icon)
├── Progress Bar (cyan, 365px)
│   └── Percentage Text
└── Boss List (collapsible)
    ├── Green Scrollbar (8+ bosses)
    └── Boss Rows (max 8 visible)
        ├── Boss Name
        ├── Kill Time
        └── Green Background (if defeated)
```

**Key Changes from Old UI:**
- Removed: Variant dropdown, Best Time, multiple buttons
- Added: Single-row layout, collapsible boss list, skull icon
- Modernized: Compact header, integrated controls

---

## Critical WoW 1.12 Patterns Used

### Frame Event Handlers
```lua
-- ❌ WRONG (Modern WoW)
frame:SetScript("OnClick", function(self, button)
    -- DOES NOT WORK
end)

-- ✅ CORRECT (1.12)
frame:SetScript("OnClick", function()
    -- Use implicit globals: this, event, arg1, arg2...
    local timer = TurtleDungeonTimer:getInstance()
end)
```

### Namespace Access
```lua
-- ❌ WRONG
local dungeon = DUNGEON_DATA[key]  -- ERROR: global DUNGEON_DATA doesn't exist!

-- ✅ CORRECT
local dungeon = self.DUNGEON_DATA[key]  -- Access via self
local dungeon = TurtleDungeonTimer.DUNGEON_DATA[key]  -- Or explicit namespace
```

### Closures in Loops
```lua
-- ❌ WRONG - All buttons use last boss
for i, boss in ipairs(bosses) do
    button:SetScript("OnClick", function()
        SelectBoss(boss.name)  -- BUG: 'boss' is last value!
    end)
end

-- ✅ CORRECT - Capture values in local variables
for i, boss in ipairs(bosses) do
    local bossName = boss.name  -- Capture value
    button:SetScript("OnClick", function()
        SelectBoss(bossName)  -- Works correctly
    end)
end
```

---

## Dungeon/Variant Selection

### selectDungeon(dungeonName)
**Purpose:** Set active dungeon and prepare UI  
**Parameters:**
- `dungeonName` (string): Dungeon key from DUNGEON_DATA

**Process:**
1. Validate dungeon exists in `self.DUNGEON_DATA`
2. Set `self.selectedDungeon` and clear `self.selectedVariant`
3. Broadcast selection to group via `broadcastDungeonSelected()`
4. Auto-select variant if only one exists or "Default" available
5. Save selection to `TurtleDungeonTimerDB.lastSelection`

**Auto-Selection Logic:**
```lua
-- Check for "Default" variant first
if hasDefault then
    self:selectVariant("Default")
-- Otherwise if only one variant exists
elseif variantCount == 1 then
    self:selectVariant(firstVariant)
else
    -- Manual selection required
    TDTTrashCounter:hideTrashBar()
    self:rebuildBossRows()
end
```

**Debug Output:**
- Success: "[Debug] selectDungeon: Set selectedDungeon to: [name]"
- Error: "[Debug] selectDungeon: Dungeon not found in DUNGEON_DATA: [name]"

---

### selectVariant(variantName)
**Purpose:** Select difficulty/mode variant  
**Parameters:**
- `variantName` (string): Variant key (e.g., "Default", "Heroic")

**Process:**
1. Validate `self.selectedDungeon` exists
2. Get variant data from `DUNGEON_DATA[dungeon].variants[variant]`
3. Build `self.bossList` from `variantData.bosses`
4. Store `variantData.optionalBosses` in `self.optionalBosses`
5. Update dungeon name text display
6. Prepare trash counter bar
7. Rebuild boss list UI

**Boss List Structure:**
```lua
self.bossList = {
    {
        name = "Boss Name",
        defeated = false,
        optional = false
    },
    -- ...
}
```

**Display Name Format:**
- Default variant: "Ragefire Chasm"
- Other variants: "Ragefire Chasm - Heroic"

---

## Main UI Creation

### createUI()
**Purpose:** Initialize main addon frame  
**Called by:** `Core.lua:initialize()`  
**Constraints:** Only creates once (`if self.frame then return`)

**Frame Setup:**
```lua
-- Main Frame
self.frame = CreateFrame("Frame", "TurtleDungeonTimerFrame", UIParent)
self.frame:SetWidth(400)
self.frame:SetHeight(120)  -- Collapsed height (expands to ~400px)

-- Position (restored from SavedVariables)
local pos = TurtleDungeonTimerDB.position
self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)

-- Background
self.frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
self.frame:SetBackdropColor(0, 0, 0, 1)
```

**Drag Support:**
```lua
self.frame:SetMovable(true)
self.frame:EnableMouse(true)
self.frame:RegisterForDrag("LeftButton")
self.frame:SetScript("OnDragStart", function() this:StartMoving() end)
self.frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    -- Save position to SavedVariables
    local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
    TurtleDungeonTimerDB.position = {
        point = point,
        relativeTo = "UIParent",
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
end)
```

**Creation Order:**
1. `createHeader()` - Dungeon name + buttons
2. `createTimerRow()` - Timer + death count
3. `createProgressBar()` - Cyan progress bar
4. `createBossList()` - Scrollable boss list

**Initial State:**
- `bossListExpanded = false`
- Frame hidden (shown via minimap/command)

---

## Header Section

### createHeader()
**Purpose:** Create top bar with dungeon name and control buttons

**Dungeon Name Text:**
```lua
local dungeonName = self.frame:CreateFontString(nil, "OVERLAY")
dungeonName:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, -15)
dungeonName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
dungeonName:SetTextColor(1, 1, 1)
dungeonName:SetText("Select Dungeon...")
dungeonName:SetJustifyH("LEFT")
dungeonName:SetWidth(250)
self.frame.dungeonNameText = dungeonName
```

**Clickable Dungeon Name:**
- Invisible button overlay on text
- Opens dungeon selector menu via `showDungeonMenu()`
- Provides easy access to change dungeon

**Start/Prepare Button:**
- **Icon:** "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up" (Play icon)
- **Size:** 24x24
- **Position:** Top-right (-40, -12)
- **Behavior:**
  - If running: Toggles pause via `toggleStartPause()`
  - If not running + group leader: Starts preparation via `startPreparation()`
  - If not group leader: Shows error message

**Tooltip Logic:**
```lua
startBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    
    if timer.isRunning then
        GameTooltip:SetText("Timer stoppen", 1, 0.82, 0)
    else
        GameTooltip:SetText("Run vorbereiten", 1, 0.82, 0)
        if timer:isGroupLeader() then
            GameTooltip:AddLine("Startet die Run-Vorbereitung mit Dungeon-Auswahl und Checks", 1, 1, 1, 1)
        else
            GameTooltip:AddLine("Nur der Gruppenführer kann den Run starten", 1, 0.5, 0.5, 1)
        end
    end
    GameTooltip:Show()
end)
```

**History Button:**
- **Icon:** "Interface\\Icons\\INV_Misc_Gear_01" (Gear icon)
- **Size:** 24x24
- **Position:** Left of start button (-5 offset)
- **Function:** Opens history dropdown via `showHistoryMenu()`

---

## Timer Row

### createTimerRow()
**Purpose:** Display elapsed time and death count

**Timer Text:**
```lua
local timerText = self.frame:CreateFontString(nil, "OVERLAY")
timerText:SetPoint("TOPLEFT", self.frame.dungeonNameText, "BOTTOMLEFT", 0, -8)
timerText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
timerText:SetTextColor(1, 1, 1)
timerText:SetText("00:00")
timerText:SetJustifyH("LEFT")
self.frame.timerText = timerText
```

**Death Counter:**
- **Skull Icon:** 20x20, "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
- **Position:** Top-right (-35, -43)
- **Text:** "X N" format, positioned left of skull (-3 offset)
- **Color:** Yellow (1, 1, 0)
- **Font:** FRIZQT__ 14pt with OUTLINE

**Layout:**
```
[Timer Text]                        [X 0 💀]
00:00                                    
```

---

## Progress Bar

### createProgressBar()
**Purpose:** Visual progress indicator with percentage

**Background:**
```lua
local progressBg = self.frame:CreateTexture(nil, "BACKGROUND")
progressBg:SetPoint("TOPLEFT", self.frame.timerText, "BOTTOMLEFT", 0, -8)
progressBg:SetWidth(365)
progressBg:SetHeight(30)
progressBg:SetTexture(0.1, 0.1, 0.1, 0.9)  -- Dark gray
```

**Progress Bar (Cyan):**
```lua
local progressBar = self.frame:CreateTexture(nil, "ARTWORK")
progressBar:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
progressBar:SetWidth(1)  -- Updated dynamically
progressBar:SetHeight(30)
progressBar:SetTexture(0.3, 0.8, 0.9, 0.8)  -- Cyan color
```

**Percentage Text:**
```lua
local progressText = self.frame:CreateFontString(nil, "OVERLAY")
progressText:SetPoint("CENTER", progressBg, "CENTER", 0, 0)
progressText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
progressText:SetTextColor(1, 1, 1)
progressText:SetText("0%")
```

**Update Logic:**
- Width: `365 * (defeatedCount / totalBosses)`
- Text: `math.floor(percentage) .. "%"`
- Updates on boss defeat

---

## Boss List (Collapsible)

### createBossList()
**Purpose:** Scrollable list of dungeon bosses with defeat tracking

**Container Frame:**
```lua
local bossListFrame = CreateFrame("Frame", nil, self.frame)
bossListFrame:SetPoint("TOPLEFT", progressBg, "BOTTOMLEFT", 0, -5)
bossListFrame:SetWidth(365)
bossListFrame:SetHeight(1)  -- Starts collapsed
bossListFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = nil,
    tile = true,
    tileSize = 32,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
})
bossListFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
self.frame.bossListFrame = bossListFrame
```

**Scroll Frame:**
```lua
local scrollFrame = CreateFrame("ScrollFrame", nil, bossListFrame)
scrollFrame:SetPoint("TOPLEFT", bossListFrame, "TOPLEFT", 5, -5)
scrollFrame:SetPoint("BOTTOMRIGHT", bossListFrame, "BOTTOMRIGHT", -25, 5)

-- ⚠️ CRITICAL: Mouse wheel must be enabled manually in 1.12!
scrollFrame:EnableMouseWheel()

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(340)
scrollChild:SetHeight(1)  -- Grows with content
scrollFrame:SetScrollChild(scrollChild)
```

**Mouse Wheel Handler (Required in 1.12):**
```lua
scrollFrame:SetScript("OnMouseWheel", function()
    local current = scrollFrame:GetVerticalScroll()
    local max = scrollFrame:GetVerticalScrollRange()
    local step = 30  -- Pixels per scroll
    
    if arg1 > 0 then  -- Scroll up (arg1 = +1)
        scrollFrame:SetVerticalScroll(math.max(0, current - step))
    else  -- Scroll down (arg1 = -1)
        scrollFrame:SetVerticalScroll(math.min(max, current + step))
    end
end)
```

**Green Scrollbar:**
```lua
local scrollbar = CreateFrame("Frame", nil, bossListFrame)
scrollbar:SetWidth(8)
scrollbar:SetPoint("TOPRIGHT", bossListFrame, "TOPRIGHT", -5, -5)
scrollbar:SetPoint("BOTTOMRIGHT", bossListFrame, "BOTTOMRIGHT", -5, 5)
scrollbar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = nil,
    tile = false,
    insets = {left = 0, right = 0, top = 0, bottom = 0}
})
scrollbar:SetBackdropColor(0.2, 0.8, 0.2, 0.9)  -- Green
```

**Scrollbar Update Logic:**
```lua
scrollFrame:SetScript("OnVerticalScroll", function()
    local current = scrollFrame:GetVerticalScroll()
    local max = scrollFrame:GetVerticalScrollRange()
    
    if max > 0 then
        local scrollHeight = bossListFrame:GetHeight() - 10
        local barHeight = math.max(30, scrollHeight * (scrollHeight / scrollChild:GetHeight()))
        local barPos = (current / max) * (scrollHeight - barHeight)
        
        scrollbar:SetHeight(barHeight)
        scrollbar:ClearAllPoints()
        scrollbar:SetPoint("TOPRIGHT", bossListFrame, "TOPRIGHT", -5, -5 - barPos)
        scrollbar:SetPoint("RIGHT", bossListFrame, "TOPRIGHT", -5, 0)
        scrollbar:Show()
    else
        scrollbar:Hide()
    end
end)
```

**Visibility:**
- Max 8 bosses visible (8 * 35px = 280px)
- Scrollbar only shown if `totalBosses > maxVisibleBosses`
- Collapses to height 1 when `bossListExpanded = false`

---

## Boss Rows

### rebuildBossRows()
**Purpose:** Create/update all boss row UI elements  
**Called when:** Variant selected, boss defeated, list expanded

**Row Creation:**
```lua
local row = CreateFrame("Frame", nil, scrollChild)
row:SetWidth(340)
row:SetHeight(35)
row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)

-- Background (default transparent)
row.bg = row:CreateTexture(nil, "BACKGROUND")
row.bg:SetAllPoints(row)
row.bg:SetTexture(0, 0, 0, 0)

-- Boss name text
row.nameText = row:CreateFontString(nil, "OVERLAY")
row.nameText:SetPoint("LEFT", row, "LEFT", 10, 0)
row.nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
row.nameText:SetTextColor(1, 1, 1)
row.nameText:SetText(boss.name)
row.nameText:SetJustifyH("LEFT")
row.nameText:SetWidth(200)

-- Kill time text
row.timeText = row:CreateFontString(nil, "OVERLAY")
row.timeText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
row.timeText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
row.timeText:SetTextColor(0.8, 0.8, 0.8)
row.timeText:SetText("")
row.timeText:SetJustifyH("RIGHT")
```

**Defeated Boss Highlighting:**
```lua
if boss.defeated then
    -- Green background (matching mockup)
    row.bg:SetTexture(0.1, 0.5, 0.1, 0.7)  -- Dark green
    
    -- Show kill time
    if boss.killTime then
        row.timeText:SetText(self:formatTime(boss.killTime))
    end
end
```

**Content Height Calculation:**
```lua
local totalHeight = table.getn(self.bossList) * 35
scrollChild:SetHeight(math.max(1, totalHeight))
```

**Closure Bug Prevention:**
```lua
-- ❌ WRONG
for i, boss in ipairs(self.bossList) do
    row:SetScript("OnClick", function()
        SelectBoss(boss.name)  -- 'boss' will be last value!
    end)
end

-- ✅ CORRECT
for i, boss in ipairs(self.bossList) do
    local bossName = boss.name  -- Capture value
    local bossIndex = i         -- Capture index
    row:SetScript("OnClick", function()
        SelectBoss(bossName)  -- Works correctly
    end)
end
```

---

## UI Updates

### updateBossRows()
**Purpose:** Update existing boss rows without rebuild  
**Use case:** Boss defeated, timer updated

**Process:**
1. Iterate through `self.frame.bossListFrame.scrollChild.bossRows`
2. Check if corresponding boss in `self.bossList` is defeated
3. Update background color to green
4. Update kill time text

**Performance:** Faster than `rebuildBossRows()` when structure unchanged

---

### updateTimerDisplay()
**Purpose:** Update timer text every frame  
**Called by:** OnUpdate handler in Core.lua

```lua
function TurtleDungeonTimer:updateTimerDisplay()
    if not self.frame or not self.frame.timerText then
        return
    end
    
    local elapsed = GetTime() - self.startTime
    self.frame.timerText:SetText(self:formatTime(elapsed))
end
```

---

### updateProgressBar()
**Purpose:** Update progress bar width and percentage  
**Called when:** Boss defeated

```lua
function TurtleDungeonTimer:updateProgressBar()
    if not self.frame or not self.frame.progressBar then
        return
    end
    
    local defeated = 0
    local total = table.getn(self.bossList)
    
    for i, boss in ipairs(self.bossList) do
        if boss.defeated then
            defeated = defeated + 1
        end
    end
    
    local percentage = (total > 0) and ((defeated / total) * 100) or 0
    local barWidth = 365 * (defeated / math.max(1, total))
    
    self.frame.progressBar:SetWidth(barWidth)
    self.frame.progressText:SetText(math.floor(percentage) .. "%")
end
```

---

### updateDeathCount()
**Purpose:** Update death counter display  
**Called when:** Player death detected

```lua
function TurtleDungeonTimer:updateDeathCount()
    if not self.frame or not self.frame.deathText then
        return
    end
    
    local deaths = self.currentRun and self.currentRun.deaths or 0
    self.frame.deathText:SetText("X " .. deaths)
end
```

---

### updateMinimizedState()
**Purpose:** Collapse/expand boss list  
**Called by:** Progress bar click (future feature)

```lua
function TurtleDungeonTimer:updateMinimizedState(expanded)
    if not self.frame or not self.frame.bossListFrame then
        return
    end
    
    self.bossListExpanded = expanded
    
    if expanded then
        -- Calculate height for bosses
        local maxVisible = 8
        local bossCount = table.getn(self.bossList)
        local visibleCount = math.min(bossCount, maxVisible)
        local listHeight = visibleCount * 35 + 10  -- Row height + padding
        
        self.frame.bossListFrame:SetHeight(listHeight)
        self.frame:SetHeight(120 + listHeight)  -- Base + list
        
        -- Show scrollbar if needed
        if bossCount > maxVisible then
            self.frame.bossListFrame.scrollbar:Show()
        end
    else
        -- Collapse
        self.frame.bossListFrame:SetHeight(1)
        self.frame:SetHeight(120)  -- Collapsed height
        self.frame.bossListFrame.scrollbar:Hide()
    end
end
```

---

## Compatibility Stubs

### Functions Required by Other Modules

**These functions exist for compatibility with other modules but may have reduced functionality in the new UI:**

```lua
-- Hide/show main frame
function TurtleDungeonTimer:hideMainFrame()
    if self.frame then
        self.frame:Hide()
    end
end

function TurtleDungeonTimer:showMainFrame()
    if self.frame then
        self.frame:Show()
    end
end

-- Update start button icon (new UI uses dynamic tooltip instead)
function TurtleDungeonTimer:updateStartButtonState()
    if not self.frame or not self.frame.startButton then
        return
    end
    
    -- Icon changes could be implemented here
    -- Currently uses same icon, behavior changes via OnClick logic
end

-- Update variant text (new UI shows in dungeon name)
function TurtleDungeonTimer:updateVariantText()
    -- Handled automatically by selectVariant()
end

-- Clear timer display
function TurtleDungeonTimer:clearTimer()
    if self.frame and self.frame.timerText then
        self.frame.timerText:SetText("00:00")
    end
    if self.frame and self.frame.deathText then
        self.frame.deathText:SetText("X 0")
    end
    if self.frame and self.frame.progressBar then
        self.frame.progressBar:SetWidth(1)
        self.frame.progressText:SetText("0%")
    end
end

-- Reset UI state
function TurtleDungeonTimer:resetUI()
    self:clearTimer()
    
    -- Reset boss list
    if self.bossList then
        for i, boss in ipairs(self.bossList) do
            boss.defeated = false
            boss.killTime = nil
        end
        self:rebuildBossRows()
    end
    
    self:updateProgressBar()
end
```

---

## Helper Functions

### formatTime(seconds)
**Purpose:** Convert seconds to MM:SS format

```lua
function TurtleDungeonTimer:formatTime(seconds)
    if not seconds or seconds < 0 then
        return "00:00"
    end
    
    local mins = math.floor(seconds / 60)
    local secs = math.floor(mod(seconds, 60))  -- Use mod(), not %
    
    return string.format("%02d:%02d", mins, secs)
end
```

---

## Dependencies

### Required Modules
- **Core.lua** - Provides `getInstance()`, timer state
- **Data.lua** - Provides `DUNGEON_DATA` table
- **UIMenus.lua** - Provides `showDungeonMenu()`, `showHistoryMenu()`
- **TDTTrashCounter.lua** - Provides trash counting bar

### External Dependencies
- **SavedVariables:** `TurtleDungeonTimerDB`
  - `position` - Frame position (point, xOfs, yOfs)
  - `lastSelection` - Last dungeon/variant
  - `debug` - Debug mode flag

### WoW API Used
- `CreateFrame()` - Frame/button creation
- `CreateFontString()` - Text elements
- `CreateTexture()` - Background/icons
- `SetBackdrop()` - Frame backgrounds
- `GetTime()` - Current game time
- `GameTooltip` - Hover tooltips

---

## Known Issues & Limitations

1. **Mouse Wheel Scrolling:** Must manually enable and handle in 1.12
2. **Closure Bugs:** Must capture loop variables before using in callbacks
3. **Namespace Access:** Must use `self.DUNGEON_DATA`, never plain `DUNGEON_DATA`
4. **String Concatenation:** All values must be strings or converted with `tostring()`
5. **Modulo Operator:** Must use `mod(a, b)`, not `a % b`

---

## Future Enhancements

- Click progress bar to toggle boss list expansion
- Drag scrollbar for manual scrolling
- Boss row tooltips with additional info
- Animated transitions for collapse/expand
- Custom boss ordering/filtering
- Best time comparison overlay

---

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System overview
- [CORE.md](CORE.md) - Timer logic
- [UIMENUS.md](UIMENUS.md) - Dropdown menus
- [DATA.md](DATA.md) - Dungeon definitions
- [TurtleWoW_Addon_Development_Prompt.md](TurtleWoW_Addon_Development_Prompt.md) - Lua 5.1 constraints
