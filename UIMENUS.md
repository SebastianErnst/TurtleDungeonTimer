# UIMenus.lua - Dropdown Menus and Boss Rows Module

## Overview
Handles dungeon selection menus, variant submenus, and boss row creation with scrolling. Manages the multi-level dropdown navigation for selecting dungeons and variants.

---

## Module Responsibilities
- Boss row creation and layout
- Scrollbar implementation for boss lists
- Dungeon dropdown menu (level 2)
- Variant submenu (level 3)
- Optional boss header rendering
- Menu visibility management

---

## Boss List UI

### rebuildBossRows()
**Purpose:** Rebuild entire boss list UI when dungeon/variant selected  
**Called by:** [UI.lua](UI.md) via `selectVariant()`

**Process:**
1. Clear existing `bossScrollFrame`
2. Check if boss list empty → hide and return
3. Organize bosses: required first, then optional
4. Calculate heights and visibility
5. Create scroll frame
6. Add scrollbar if needed (> 6 bosses)
7. Create boss rows
8. Update frame size

**Boss Organization:**
```lua
local orderedBosses = {}
local optionalBossList = {}

-- Separate required and optional
for i = 1, table.getn(self.bossList) do
    local boss = self.bossList[i]
    if not boss.optional then
        table.insert(orderedBosses, boss)
    else
        table.insert(optionalBossList, boss)
    end
end

-- Add optional at end
for i = 1, table.getn(optionalBossList) do
    table.insert(orderedBosses, optionalBossList[i])
end
```

**Height Calculation:**
```lua
local bossRowHeight = 35
local maxVisibleBosses = 6
local numBosses = table.getn(orderedBosses)

local headerHeight = 0
if hasOptional then
    headerHeight = 20 -- Space for "Optional" header
end

local scrollHeight = math.min(maxVisibleBosses, numBosses) * (bossRowHeight + 5)
```

**Scroll Frame Creation:**
```lua
local scrollFrame = CreateFrame("ScrollFrame", nil, self.frame)
scrollFrame:SetWidth(240)
scrollFrame:SetHeight(scrollHeight)
scrollFrame:SetPoint("TOP", self.frame.headerBg, "BOTTOM", 0, -10)
self.frame.bossScrollFrame = scrollFrame

if not self.bossListExpanded then
    scrollFrame:Hide()
end
```

---

### createBossRows(scrollChild, orderedBosses, numBosses, bossRowHeight, hasScrollbar)
**Purpose:** Create individual boss row frames  
**Parameters:**
- `scrollChild` - Frame: Scroll child container
- `orderedBosses` - table: Ordered boss list (required then optional)
- `numBosses` - number: Total boss count
- `bossRowHeight` - number: Height per row (35px)
- `hasScrollbar` - boolean: Adjust width if scrollbar present

**Boss Row Width:**
```lua
local bossRowWidth = hasScrollbar and 205 or 225
```

**Row Layout:**
```
┌────────────────────────────────────┐
│ Boss Name               5:32 (5:32)│
│ [Checkbox] │ Name │ Time │ Split   │
└────────────────────────────────────┘
```

**Optional Header:**
```lua
-- Add "Optional" header before first optional boss
if i == optionalStartIndex and hasOptional then
    local header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -currentY)
    header:SetText("Optional")
    header:SetTextColor(0.7, 0.7, 0.7)
    currentY = currentY + headerHeight
end
```

**Boss Row Components:**
```lua
-- Background frame
local row = CreateFrame("Frame", nil, scrollChild)
row:SetWidth(bossRowWidth)
row:SetHeight(bossRowHeight)
row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)

-- Boss name
local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nameText:SetPoint("LEFT", row, "LEFT", 10, 0)
nameText:SetWidth(bossRowWidth - 100)
nameText:SetJustifyH("LEFT")
nameText:SetText(boss.name)
nameText:SetTextColor(1, 1, 1) -- White by default, green when defeated

-- Kill time (MM:SS)
local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
timeText:SetPoint("RIGHT", row, "RIGHT", -10, 5)
timeText:SetText("")
timeText:SetTextColor(0.8, 0.8, 0.8)

-- Split time (split: MM:SS)
local splitText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
splitText:SetPoint("RIGHT", row, "RIGHT", -10, -8)
splitText:SetText("")
splitText:SetTextColor(0.6, 0.6, 0.6)

boss.nameText = nameText
boss.timeText = timeText
boss.splitText = splitText
```

**Color Coding:**
- Defeated boss name: Green (0, 1, 0)
- Active boss name: White (1, 1, 1)
- Kill time: Light gray (0.8, 0.8, 0.8)
- Split time: Dark gray (0.6, 0.6, 0.6)

---

### createScrollbar(scrollFrame, scrollHeight, totalHeight, maxVisibleBosses, bossRowHeight, headerHeight)
**Purpose:** Create scrollbar for boss list  
**Parameters:**
- `scrollFrame` - Frame: Parent scroll frame
- `scrollHeight` - number: Visible height
- `totalHeight` - number: Total content height
- `maxVisibleBosses` - number: Max visible (6)
- `bossRowHeight` - number: Height per boss (35px)
- `headerHeight` - number: Optional header height (20px or 0)

**Scrollbar Setup:**
```lua
local scrollbar = CreateFrame("Slider", nil, scrollFrame)
scrollbar:SetOrientation("VERTICAL")
scrollbar:SetWidth(16)
scrollbar:SetHeight(scrollHeight)
scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, 0)
scrollbar:SetMinMaxValues(0, totalHeight - scrollHeight)
scrollbar:SetValueStep(bossRowHeight + 5)
scrollbar:SetValue(0)

scrollbar:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
})
scrollbar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
```

**Thumb Texture:**
```lua
local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
thumb:SetWidth(16)
thumb:SetHeight(24)
scrollbar:SetThumbTexture(thumb)
```

**Scroll Handler:**
```lua
scrollbar:SetScript("OnValueChanged", function()
    scrollFrame:SetVerticalScroll(this:GetValue())
end)
```

**Mouse Wheel Support:**
```lua
scrollFrame:EnableMouseWheel()
scrollFrame:SetScript("OnMouseWheel", function()
    local current = scrollbar:GetValue()
    local step = bossRowHeight + 5
    
    if arg1 > 0 then
        scrollbar:SetValue(math.max(0, current - step))
    else
        scrollbar:SetValue(math.min(totalHeight - scrollHeight, current + step))
    end
end)
```

**Lua 5.1 Note:** `EnableMouseWheel()` takes no parameters in 1.12

---

## Dungeon Selection Menus

### showDungeonMenu(button)
**Purpose:** Show level 2 dungeon selection menu  
**Called by:** Dungeon selector button click

**Delegates to:** `showInstanceListDirect(button, true)`

---

### showInstanceListDirect(parentBtn, isDungeonFilter)
**Purpose:** Create and show dungeon dropdown menu  
**Parameters:**
- `parentBtn` - Frame: Anchor button
- `isDungeonFilter` - boolean: Filter for dungeons only (true)

**Menu Creation:**
```lua
if not self.instanceListDropdown then
    local dropdown = CreateFrame("Frame", nil, UIParent)
    dropdown:SetWidth(200)
    dropdown:SetHeight(300)
    dropdown:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropdown:SetFrameStrata("TOOLTIP")
    dropdown:Hide()
    self.instanceListDropdown = dropdown
end
```

**Positioning:**
```lua
dropdown:ClearAllPoints()
dropdown:SetPoint("TOPLEFT", parentBtn, "BOTTOMLEFT", 0, -5)
```

**Menu Population:**
```lua
-- Load dungeon list from Data.lua
local dungeons = {}
for dungeonName, dungeonData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
    if not isDungeonFilter or dungeonData.isDungeon then
        table.insert(dungeons, dungeonName)
    end
end

-- Sort alphabetically
table.sort(dungeons)

-- Create menu items
for i, dungeonName in ipairs(dungeons) do
    local menuItem = CreateFrame("Button", nil, dropdown)
    menuItem:SetWidth(180)
    menuItem:SetHeight(20)
    menuItem:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 10, -10 - (i-1)*22)
    
    local text = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", menuItem, "LEFT", 5, 0)
    text:SetText(dungeonName)
    
    menuItem:SetScript("OnClick", function()
        local variantCount = TurtleDungeonTimer:getInstance():getVariantCount(dungeonName)
        TurtleDungeonTimer:getInstance():handleInstanceClick(dungeonName, variantCount)
    end)
    
    -- Highlight on hover
    menuItem:SetScript("OnEnter", function()
        text:SetTextColor(1, 1, 0) -- Yellow
    end)
    menuItem:SetScript("OnLeave", function()
        text:SetTextColor(1, 1, 1) -- White
    end)
end
```

---

### handleInstanceClick(instanceName, variantCount)
**Purpose:** Handle dungeon menu item click  
**Parameters:**
- `instanceName` - string: Dungeon name
- `variantCount` - number: Number of variants

**Logic:**
```lua
if variantCount == 1 then
    -- Single variant → auto-select
    local variantName = self:getFirstVariantName(instanceName)
    self:selectDungeon(instanceName)
    self:selectVariant(variantName)
    self:hideAllMenus()
elseif variantCount > 1 then
    -- Multiple variants → show submenu
    self:showVariantSubmenuLevel3(button, instanceName)
end
```

---

### showVariantSubmenuLevel3(parentBtn, instanceName)
**Purpose:** Show level 3 variant selection submenu  
**Parameters:**
- `parentBtn` - Frame: Parent menu item to anchor to
- `instanceName` - string: Dungeon name

**Submenu Creation:**
```lua
if not self.variantSubmenu then
    local submenu = CreateFrame("Frame", nil, UIParent)
    submenu:SetWidth(180)
    submenu:SetHeight(150)
    submenu:SetBackdrop({...})
    submenu:SetBackdropColor(0.15, 0.15, 0.15, 0.95) -- Slightly lighter
    submenu:SetFrameStrata("TOOLTIP")
    submenu:SetFrameLevel(self.instanceListDropdown:GetFrameLevel() + 1)
    submenu:Hide()
    self.variantSubmenu = submenu
end
```

**Positioning:**
```lua
submenu:ClearAllPoints()
submenu:SetPoint("TOPLEFT", parentBtn, "TOPRIGHT", 5, 0)
```

**Variant List:**
```lua
local variants = {}
local dungeonData = TurtleDungeonTimer.DUNGEON_DATA[instanceName]
if dungeonData and dungeonData.variants then
    for variantName, _ in pairs(dungeonData.variants) do
        table.insert(variants, variantName)
    end
end
table.sort(variants)

-- Create variant items
for i, variantName in ipairs(variants) do
    local menuItem = CreateFrame("Button", nil, submenu)
    menuItem:SetWidth(160)
    menuItem:SetHeight(20)
    menuItem:SetPoint("TOPLEFT", submenu, "TOPLEFT", 10, -10 - (i-1)*22)
    
    local text = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", menuItem, "LEFT", 5, 0)
    text:SetText(variantName)
    
    menuItem:SetScript("OnClick", function()
        TurtleDungeonTimer:getInstance():selectDungeonVariant(instanceName, variantName)
    end)
end
```

---

### selectDungeonVariant(instanceName, variantName)
**Purpose:** Select both dungeon and variant, close all menus  

```lua
function TurtleDungeonTimer:selectDungeonVariant(instanceName, variantName)
    self:selectDungeon(instanceName)
    self:selectVariant(variantName)
    self:hideAllMenus()
end
```

---

### hideAllMenus()
**Purpose:** Close all dropdown menus  

```lua
function TurtleDungeonTimer:hideAllMenus()
    if self.instanceListDropdown then
        self.instanceListDropdown:Hide()
    end
    if self.variantSubmenu then
        self.variantSubmenu:Hide()
    end
end
```

**Called by:**
- Dungeon/variant selection
- Click outside menu
- ESC key (automatic frame behavior)

---

## Menu Navigation Flow

```
User clicks "Select Dungeon" button
    ↓
showDungeonMenu() → showInstanceListDirect()
    ↓
Level 2 menu shows all dungeons
    ↓
User clicks dungeon item
    ↓
handleInstanceClick()
    ├─ 1 variant → selectDungeon() → selectVariant() → hideAllMenus()
    └─ 2+ variants → showVariantSubmenuLevel3()
                        ↓
                    Level 3 submenu shows variants
                        ↓
                    User clicks variant
                        ↓
                    selectDungeonVariant() → hideAllMenus()
```

---

## Boss List Toggle

### toggleBossList()
**Purpose:** Show/hide boss list (called by expand/collapse button)  

```lua
function TurtleDungeonTimer:toggleBossList()
    self.bossListExpanded = not self.bossListExpanded
    
    if self.frame.bossScrollFrame then
        if self.bossListExpanded then
            self.frame.bossScrollFrame:Show()
        else
            self.frame.bossScrollFrame:Hide()
        end
    end
    
    self:updateFrameSize()
end
```

**State Variable:** `self.bossListExpanded` (boolean)

---

## Integration Points

### Called By
- [UI.lua](UI.md) - Dungeon selector button, variant selection
- [Core.lua](CORE.md) - After dungeon/variant loaded

### Calls To
- [UI.lua](UI.md) - `updateFrameSize()`, `selectDungeon()`, `selectVariant()`
- [Data.lua](DATA.md) - Reads `DUNGEON_DATA` table

---

## Lua 5.1 Compliance

### Table Operations
```lua
-- ✅ CORRECT
for i = 1, table.getn(orderedBosses) do
    local boss = orderedBosses[i]
end

-- ❌ WRONG
for i = 1, #orderedBosses do
```

### Mouse Wheel
```lua
-- ✅ CORRECT
scrollFrame:EnableMouseWheel()
scrollFrame:SetScript("OnMouseWheel", function()
    local delta = arg1 -- +1 for up, -1 for down
end)

-- ❌ WRONG
scrollFrame:EnableMouseWheel(true)
```

### Event Handlers
```lua
-- ✅ CORRECT
button:SetScript("OnClick", function()
    -- Use 'this' for frame, 'arg1' for button
end)

-- ❌ WRONG
button:SetScript("OnClick", function(self, button)
    -- Parameters don't work in 1.12
end)
```

---

## Performance Considerations

### Menu Creation
- Dropdown frames created once and reused
- Only rebuild content when opening
- Destroy old menu items before creating new ones

### Scroll Performance
- Limit visible rows to 6
- Scrollbar only created if needed (> 6 bosses)
- Boss row frames kept simple

---

## Error Handling

### Empty Boss List
```lua
if table.getn(self.bossList) == 0 then
    if self.frame.bossScrollFrame then
        self.frame.bossScrollFrame:Hide()
    end
    return
end
```

### Missing Dungeon Data
- Checks for `dungeonData.variants` existence
- Handles nil gracefully with early returns

---

## Testing Checklist
- [ ] Dungeon menu shows all dungeons alphabetically
- [ ] Single variant dungeons auto-select
- [ ] Multiple variant dungeons show submenu
- [ ] Variant submenu positioned correctly (right of parent)
- [ ] Boss list shows required bosses first
- [ ] "Optional" header appears if optional bosses exist
- [ ] Scrollbar appears for > 6 bosses
- [ ] Mouse wheel scrolls boss list
- [ ] Boss row width adjusts for scrollbar
- [ ] All menus close on selection

---

## See Also
- [UI Module](UI.md)
- [Data Module](DATA.md)
- [Core Module](CORE.md)
