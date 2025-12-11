-- ============================================================================
-- Turtle Dungeon Timer - UI Menus and Boss Rows
-- ============================================================================

function TurtleDungeonTimer:rebuildBossRows()
    if not self.frame then return end
    
    -- Clear old boss scroll frame
    if self.frame.bossScrollFrame then
        self.frame.bossScrollFrame:Hide()
        self.frame.bossScrollFrame = nil
    end
    
    if table.getn(self.bossList) == 0 then
        self:updateFrameSize()
        return
    end
    
    local bossRowHeight = 35
    local maxVisibleBosses = 6
    local numBosses = table.getn(self.bossList)
    local scrollHeight = math.min(maxVisibleBosses, numBosses) * (bossRowHeight + 5)
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.frame)
    scrollFrame:SetWidth(240)
    scrollFrame:SetHeight(scrollHeight)
    scrollFrame:SetPoint("TOP", self.frame.headerBg, "BOTTOM", 0, -10)
    self.frame.bossScrollFrame = scrollFrame
    
    if not self.bossListExpanded then
        scrollFrame:Hide()
    end
    
    -- Create scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(240)
    scrollChild:SetHeight(numBosses * (bossRowHeight + 5))
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Create scrollbar if needed
    if numBosses > maxVisibleBosses then
        self:createScrollbar(scrollFrame, scrollHeight, numBosses, maxVisibleBosses, bossRowHeight)
    end
    
    -- Create boss rows
    self:createBossRows(scrollChild, numBosses, bossRowHeight)
    
    self:updateFrameSize()
end

function TurtleDungeonTimer:createScrollbar(scrollFrame, scrollHeight, numBosses, maxVisibleBosses, bossRowHeight)
    local scrollbar = CreateFrame("Slider", nil, scrollFrame)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetWidth(16)
    scrollbar:SetHeight(scrollHeight)
    scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 18, 0)
    scrollbar:SetMinMaxValues(0, (numBosses - maxVisibleBosses) * (bossRowHeight + 5))
    scrollbar:SetValueStep(bossRowHeight + 5)
    scrollbar:SetValue(0)
    scrollbar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    scrollbar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    thumb:SetWidth(16)
    thumb:SetHeight(24)
    scrollbar:SetThumbTexture(thumb)
    
    scrollbar:SetScript("OnValueChanged", function()
        scrollFrame:SetVerticalScroll(this:GetValue())
    end)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1
        local current = scrollbar:GetValue()
        local minVal, maxVal = scrollbar:GetMinMaxValues()
        if delta < 0 and current < maxVal then
            scrollbar:SetValue(math.min(maxVal, current + (bossRowHeight + 5)))
        elseif delta > 0 and current > minVal then
            scrollbar:SetValue(math.max(minVal, current - (bossRowHeight + 5)))
        end
    end)
end

function TurtleDungeonTimer:createBossRows(scrollChild, numBosses, bossRowHeight)
    for i = 1, numBosses do
        local bossRow = CreateFrame("Frame", nil, scrollChild)
        bossRow:SetWidth(225)
        bossRow:SetHeight(bossRowHeight)
        bossRow:SetPoint("TOP", scrollChild, "TOP", 0, -((i-1) * (bossRowHeight + 5)))
        bossRow:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        bossRow:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
        
        local bossNameText = bossRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bossNameText:SetPoint("LEFT", bossRow, "LEFT", 10, 0)
        bossNameText:SetJustifyH("LEFT")
        bossNameText:SetText(tostring(self.bossList[i]))
        bossRow.nameText = bossNameText
        
        -- Checkmark
        local checkmark = bossRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        checkmark:SetPoint("LEFT", bossNameText, "RIGHT", 5, 0)
        checkmark:SetText("\226\156\147") -- ✓
        checkmark:SetTextColor(0, 1, 0)
        checkmark:Hide()
        bossRow.checkmark = checkmark
        
        -- Time and Split
        local bossTimeText = bossRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bossTimeText:SetPoint("RIGHT", bossRow, "RIGHT", -10, 0)
        bossTimeText:SetJustifyH("RIGHT")
        bossTimeText:SetText("-")
        bossRow.timeText = bossTimeText
        
        if not self.frame.bossRows then
            self.frame.bossRows = {}
        end
        self.frame.bossRows[i] = bossRow
    end
end

function TurtleDungeonTimer:showDungeonMenu(button)
    -- Close any existing menus
    if self.frame.dungeonDropdown then
        self.frame.dungeonDropdown:Hide()
        self.frame.dungeonDropdown = nil
    end
    if self.frame.variantSubmenu then
        self.frame.variantSubmenu:Hide()
        self.frame.variantSubmenu = nil
    end
    
    local menu = {}
    for dungeonName, _ in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
        local name = dungeonName
        table.insert(menu, {text = name})
    end
    
    table.sort(menu, function(a, b) return a.text < b.text end)
    
    local btnHeight = 20
    local numItems = table.getn(menu)
    local maxVisibleItems = 20
    local dropHeight = math.min(maxVisibleItems * btnHeight + 8, numItems * btnHeight + 8)
    
    local dropdown = CreateFrame("Frame", nil, button)
    dropdown:SetWidth(135)
    dropdown:SetHeight(dropHeight)
    dropdown:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropdown:SetFrameStrata("DIALOG")
    self.frame.dungeonDropdown = dropdown
    
    self:createDungeonDropdownScroll(dropdown, dropHeight, menu, numItems, btnHeight, maxVisibleItems)
end

function TurtleDungeonTimer:createDungeonDropdownScroll(dropdown, dropHeight, menu, numItems, btnHeight, maxVisibleItems)
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, dropdown)
    scrollFrame:SetWidth(120)
    scrollFrame:SetHeight(dropHeight - 8)
    scrollFrame:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 4, -4)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(120)
    scrollChild:SetHeight(numItems * btnHeight)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Scrollbar
    local scrollbar = CreateFrame("Slider", nil, scrollFrame)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetWidth(16)
    scrollbar:SetHeight(dropHeight - 8)
    scrollbar:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -4, -4)
    scrollbar:SetMinMaxValues(0, math.max(0, (numItems - maxVisibleItems) * btnHeight))
    scrollbar:SetValueStep(btnHeight)
    scrollbar:SetValue(0)
    scrollbar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    scrollbar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    thumb:SetWidth(16)
    thumb:SetHeight(24)
    scrollbar:SetThumbTexture(thumb)
    
    scrollbar:SetScript("OnValueChanged", function()
        scrollFrame:SetVerticalScroll(this:GetValue())
    end)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1
        local current = scrollbar:GetValue()
        local minVal, maxVal = scrollbar:GetMinMaxValues()
        if delta < 0 and current < maxVal then
            scrollbar:SetValue(math.min(maxVal, current + btnHeight))
        elseif delta > 0 and current > minVal then
            scrollbar:SetValue(math.max(minVal, current - btnHeight))
        end
    end)
    
    -- Create menu items
    self:createDungeonMenuItems(scrollChild, menu, numItems, btnHeight, dropdown)
end

function TurtleDungeonTimer:createDungeonMenuItems(scrollChild, menu, numItems, btnHeight, dropdown)
    for i = 1, numItems do
        local item = menu[i]
        local dungeonName = item.text
        
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetWidth(112)
        btn:SetHeight(btnHeight)
        btn:SetPoint("TOP", scrollChild, "TOP", 0, -(i-1) * btnHeight)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        text:SetText(tostring(dungeonName))
        text:SetJustifyH("LEFT")
        btn.text = text
        
        -- Check if this dungeon has multiple variants
        local variants = TurtleDungeonTimer.DUNGEON_DATA[dungeonName].variants
        local variantCount = 0
        for _ in pairs(variants) do
            variantCount = variantCount + 1
        end
        
        -- Add arrow indicator if multiple variants
        if variantCount > 1 then
            local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            arrow:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            arrow:SetText(">")
            btn.arrow = arrow
        end
        
        btn:SetScript("OnEnter", function()
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            
            TurtleDungeonTimer:getInstance():showVariantSubmenu(this, dungeonName, dropdown, variantCount)
        end)
        
        btn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        
        btn:SetScript("OnClick", function()
            TurtleDungeonTimer:getInstance():handleDungeonClick(dungeonName, variantCount, dropdown)
        end)
    end
end

function TurtleDungeonTimer:showVariantSubmenu(btn, dungeonName, dropdown, variantCount)
    -- Hide any existing submenu
    if self.frame.variantSubmenu then
        self.frame.variantSubmenu:Hide()
        self.frame.variantSubmenu = nil
    end
    
    -- Show variant submenu if multiple variants exist
    if variantCount > 1 then
        local variantList = TurtleDungeonTimer.DUNGEON_DATA[dungeonName].variants
        
        local submenu = CreateFrame("Frame", nil, dropdown)
        submenu:SetWidth(180)
        submenu:SetHeight(math.min(200, variantCount * 20 + 8))
        submenu:SetPoint("TOPLEFT", btn, "TOPRIGHT", 0, 0)
        submenu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        submenu:SetBackdropColor(0.15, 0.15, 0.15, 0.95)
        submenu:SetFrameStrata("TOOLTIP")
        self.frame.variantSubmenu = submenu
        
        local variantMenu = {}
        for variantName, _ in pairs(variantList) do
            table.insert(variantMenu, variantName)
        end
        table.sort(variantMenu)
        
        for j = 1, table.getn(variantMenu) do
            local vName = variantMenu[j]
            local vBtn = CreateFrame("Button", nil, submenu)
            vBtn:SetWidth(168)
            vBtn:SetHeight(18)
            vBtn:SetPoint("TOP", submenu, "TOP", 0, -4 - (j-1) * 20)
            
            local vText = vBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            vText:SetPoint("LEFT", vBtn, "LEFT", 5, 0)
            vText:SetText(tostring(vName))
            vText:SetJustifyH("LEFT")
            
            vBtn:SetScript("OnEnter", function()
                this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
                this:SetBackdropColor(0.4, 0.4, 0.4, 0.8)
            end)
            vBtn:SetScript("OnLeave", function()
                this:SetBackdrop(nil)
            end)
            vBtn:SetScript("OnClick", function()
                TurtleDungeonTimer:getInstance():selectDungeon(dungeonName)
                TurtleDungeonTimer:getInstance():selectVariant(vName)
                dropdown:Hide()
                submenu:Hide()
            end)
        end
    end
end

function TurtleDungeonTimer:handleDungeonClick(dungeonName, variantCount, dropdown)
    -- Auto-select if only one variant
    if variantCount == 1 then
        local vList = TurtleDungeonTimer.DUNGEON_DATA[dungeonName].variants
        local singleVariant = nil
        for vName, _ in pairs(vList) do
            singleVariant = vName
            break
        end
        
        self:selectDungeon(dungeonName)
        self:selectVariant(singleVariant)
        dropdown:Hide()
    else
        self:selectDungeon(dungeonName)
    end
end
