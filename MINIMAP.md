# Minimap.lua - Minimap Button Module

## Overview
Creates and manages the minimap button for quick access to the addon. Handles button positioning, dragging, tooltips, and click actions.

---

## Module Responsibilities
- Minimap button creation
- Button positioning and dragging
- Tooltip display
- Click handlers (toggle window)
- Position persistence

---

## State Variables

```lua
self.minimapButton         -- Frame: Button reference
TurtleDungeonTimerDB.minimapAngle  -- number: Button angle (radians)
```

**Default Angle:** 200 radians (approximately 4 o'clock position)

---

## Core Functions

### createMinimapButton()
**Purpose:** Create minimap button on first load  
**Called by:** `Core.lua:initialize()`

**Early Exit:** If button already exists

**Button Creation:**
```lua
function TurtleDungeonTimer:createMinimapButton()
    if self.minimapButton then return end
    
    -- Create button
    local button = CreateFrame("Button", "TurtleDungeonTimerMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Icon texture
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01") -- Pocket watch icon
    button.icon = icon
    
    -- Border overlay
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(52)
    overlay:SetHeight(52)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    self.minimapButton = button
    self:setupMinimapHandlers()
    self:updateMinimapButtonPosition()
end
```

**Icon:** Pocket watch (`INV_Misc_PocketWatch_01`)  
**Border:** Standard minimap tracking border

---

### setupMinimapHandlers()
**Purpose:** Configure all button event handlers  

**Tooltip Handlers:**
```lua
button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Turtle Dungeon Timer", 1, 1, 1)
    GameTooltip:AddLine("Left-Click: Toggle window", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-Click: Open menu", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
```

**Click Handlers:**
```lua
button:SetScript("OnClick", function()
    local timer = TurtleDungeonTimer:getInstance()
    if arg1 == "LeftButton" then
        timer:toggleWindow()
    elseif arg1 == "RightButton" then
        timer:showMinimapMenu()
    end
end)
```

**Drag Handlers:**
```lua
button:RegisterForDrag("LeftButton")

button:SetScript("OnDragStart", function()
    this:LockHighlight()
    this.isDragging = true
end)

button:SetScript("OnDragStop", function()
    this:UnlockHighlight()
    this.isDragging = false
    TurtleDungeonTimer:getInstance():saveMinimapPosition()
end)

button:SetScript("OnUpdate", function()
    if this.isDragging then
        TurtleDungeonTimer:getInstance():updateMinimapButtonPosition()
    end
end)
```

**Lua 5.1 Note:** Uses implicit globals `this` and `arg1`

---

## Position Management

### updateMinimapButtonPosition()
**Purpose:** Update button position based on angle  
**Called by:**
- `createMinimapButton()` - Initial positioning
- OnUpdate while dragging

**Calculation:**
```lua
function TurtleDungeonTimer:updateMinimapButtonPosition()
    if not self.minimapButton then return end
    
    local angle = TurtleDungeonTimerDB.minimapAngle or 200
    local x, y
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    
    if self.minimapButton.isDragging then
        -- Calculate angle from cursor position
        local centerX, centerY = Minimap:GetCenter()
        local mouseX, mouseY = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        mouseX = mouseX / scale
        mouseY = mouseY / scale
        
        local dx = mouseX - centerX
        local dy = mouseY - centerY
        angle = math.atan2(dy, dx)
        TurtleDungeonTimerDB.minimapAngle = angle
    end
    
    -- Calculate position (80 pixels from center)
    x = cos * 80
    y = sin * 80
    
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
```

**Positioning:**
- Radius: 80 pixels from minimap center
- Angle stored in radians
- Position recalculated during drag to follow cursor

**Angle Calculation:**
```lua
angle = math.atan2(dy, dx)
```
- `atan2(y, x)` returns angle in radians
- Range: -π to π
- Converts cursor position to angle relative to minimap center

---

### saveMinimapPosition()
**Purpose:** Save current angle to SavedVariables  
**Called by:** OnDragStop handler

**Implementation:**
```lua
function TurtleDungeonTimer:saveMinimapPosition()
    -- Position already saved in updateMinimapButtonPosition via TurtleDungeonTimerDB.minimapAngle
end
```

**Note:** Angle saved during drag, this function exists for clarity

---

### resetMinimapPosition()
**Purpose:** Reset button to default position  
**Called by:** Minimap menu (not implemented)

```lua
function TurtleDungeonTimer:resetMinimapPosition()
    TurtleDungeonTimerDB.minimapAngle = 200
    self:updateMinimapButtonPosition()
end
```

**Default Position:** 200 radians (~4 o'clock)

---

## Window Management

### toggleWindow()
**Purpose:** Show/hide main addon frame  
**Called by:** Left-click on minimap button

```lua
function TurtleDungeonTimer:toggleWindow()
    if not self.frame then return end
    
    if self.frame:IsVisible() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end
```

---

### showMinimapMenu()
**Purpose:** Show right-click context menu (planned feature)  
**Called by:** Right-click on minimap button

**Current Implementation:**
```lua
function TurtleDungeonTimer:showMinimapMenu()
    -- Planned menu:
    -- - Toggle Window
    -- - Reset Position
    -- - Hide Button
    -- - Close
    
    -- For now, just toggle window
    self:toggleWindow()
end
```

**Future Menu Items:**
```lua
local menu = {
    {text = "Toggle Window", func = function() self:toggleWindow() end},
    {text = "Reset Position", func = function() self:resetMinimapPosition() end},
    {text = "Hide Button", func = function() self:hideMinimapButton() end},
    {text = "Close", func = function() end}
}
```

**Note:** Vanilla WoW doesn't have UIDropDownMenu system, would need custom implementation

---

## Visibility Control

### hideMinimapButton()
**Purpose:** Hide minimap button  

```lua
function TurtleDungeonTimer:hideMinimapButton()
    if self.minimapButton then
        self.minimapButton:Hide()
    end
end
```

**Use Case:** User preference to hide button (requires slash command to show again)

---

### showMinimapButton()
**Purpose:** Show minimap button  

```lua
function TurtleDungeonTimer:showMinimapButton()
    if not self.minimapButton then
        self:createMinimapButton()
    else
        self.minimapButton:Show()
    end
end
```

---

## Integration Points

### Called By
- [Core.lua](CORE.md) - `createMinimapButton()` on initialize
- User clicks - Event handlers

### Calls To
- [UI.lua](UI.md) - `toggleWindow()` to show/hide frame
- SavedVariables - Angle persistence

---

## Lua 5.1 Compliance

### Event Handlers
```lua
-- ✅ CORRECT
button:SetScript("OnClick", function()
    local button = arg1 -- "LeftButton" or "RightButton"
    local timer = TurtleDungeonTimer:getInstance()
    -- Use 'this' for frame reference
end)

-- ❌ WRONG
button:SetScript("OnClick", function(self, button)
    -- Parameters don't work in 1.12
end)
```

### Math Functions
```lua
-- ✅ CORRECT
local angle = math.atan2(dy, dx)
local cos = math.cos(angle)
local sin = math.sin(angle)

-- Math functions available in Lua 5.1
math.floor(), math.ceil(), math.abs()
math.random(), math.min(), math.max()
```

---

## Position Calculation Details

### Circular Positioning
Minimap button positioned on a circle around minimap center:

```
        90° (top)
           |
180° ------+------ 0° (right)
   (left)  |
        270° (bottom)
```

**Formula:**
```lua
x = radius * cos(angle)
y = radius * sin(angle)
```

**Example Positions:**
- 0 radians (0°) → Right edge (3 o'clock)
- π/2 (~1.57) → Top edge (12 o'clock)
- π (~3.14) → Left edge (9 o'clock)
- 3π/2 (~4.71) → Bottom edge (6 o'clock)
- 200 radians (mod 2π ~3.15) → ~Left edge (default)

---

## Dragging Behavior

### Drag State Machine
```
1. User clicks and holds left button
   ↓
2. OnDragStart → Set isDragging = true, LockHighlight
   ↓
3. OnUpdate → Continuous position updates
   - Get cursor position
   - Calculate angle from cursor to minimap center
   - Update button position
   - Save angle to SavedVariables
   ↓
4. OnDragStop → Set isDragging = false, UnlockHighlight
```

**Visual Feedback:**
- `LockHighlight()` - Button stays highlighted during drag
- `UnlockHighlight()` - Remove highlight on release

---

## Tooltip Display

### Tooltip Content
```
Turtle Dungeon Timer
Left-Click: Toggle window
Right-Click: Open menu
```

**Colors:**
- Title: White (1, 1, 1)
- Instructions: Light gray (0.8, 0.8, 0.8)

**Anchor:** `ANCHOR_LEFT` - Tooltip appears to left of button

---

## Performance Notes

### OnUpdate Optimization
- Only runs during drag (`isDragging` check)
- Minimal calculations (atan2, cos, sin)
- Direct SavedVariables write (no unnecessary saves)

### Frame Creation
- Button created once, reused forever
- Textures created at initialization
- No frame recreation on position change

---

## Error Handling

### Nil Checks
```lua
if not self.minimapButton then return end
```

All functions check for button existence before proceeding

### Missing SavedVariables
```lua
local angle = TurtleDungeonTimerDB.minimapAngle or 200
```

Defaults to 200 if angle not saved

---

## Testing Checklist
- [ ] Button appears on minimap at default position
- [ ] Button draggable around minimap
- [ ] Position persists after reload
- [ ] Tooltip shows on hover
- [ ] Left-click toggles main frame
- [ ] Right-click behavior works
- [ ] Button respects minimap shape (circular)
- [ ] Reset position returns to default
- [ ] Hide/show functions work

---

## Future Enhancements

### Planned Features
1. **Context Menu:**
   - Toggle window
   - Reset position
   - Hide button
   - Options panel
   
2. **Button Customization:**
   - Icon selection
   - Button size
   - Visibility toggle in options
   
3. **LibDBIcon Support:**
   - Standard addon for minimap buttons
   - Provides additional features
   - Not available in pure Vanilla

---

## See Also
- [Core Module](CORE.md)
- [UI Module](UI.md)
- [Commands Module](COMMANDS.md)
