-- ============================================================================
-- Turtle Dungeon Timer - UI Menus and Boss Rows
-- ============================================================================

function TurtleDungeonTimer:rebuildBossRows()
    if not self.frame then return end

    if table.getn(self.bossList) == 0 then
        if self.bossListExpanded then
            self:collapseBossList()
        end
        self:updateBossListToggleState()
        return
    end

    self:updateBossListToggleState()

    if self.bossListExpanded then
        self:expandBossList()
    end
end

function TurtleDungeonTimer:createScrollbar(scrollFrame, scrollHeight, totalHeight, maxVisibleBosses, bossRowHeight, headerHeight)
    local scrollbar = CreateFrame("Slider", nil, scrollFrame)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetWidth(16)
    scrollbar:SetHeight(scrollHeight)
    scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, 0)
    -- Set max scroll value to total content height minus visible height
    scrollbar:SetMinMaxValues(0, totalHeight - scrollHeight)
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
    
    scrollFrame:EnableMouseWheel()
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

function TurtleDungeonTimer:createBossRows(scrollChild, orderedBosses, numBosses, bossRowHeight, hasScrollbar)
    local currentY = 0
    local requiredCount = 0
    local optionalStartIndex = 0
    
    -- Adjust boss row width if scrollbar is present
    local bossRowWidth = hasScrollbar and 205 or 225
    
    -- Count required bosses
    for i = 1, numBosses do
        local bossName = orderedBosses[i]
        if not self.optionalBosses[bossName] then
            requiredCount = requiredCount + 1
        else
            if optionalStartIndex == 0 then
                optionalStartIndex = i
            end
        end
    end
    
    for i = 1, numBosses do
        -- Add "Optional" header before first optional boss
        if i == optionalStartIndex and optionalStartIndex > 0 then
            local headerText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            headerText:SetPoint("TOP", scrollChild, "TOP", 0, -(currentY + 5))
            headerText:SetText("|cff888888Optional|r")
            headerText:SetJustifyH("LEFT")
            headerText:SetWidth(bossRowWidth)
            headerText:SetPoint("LEFT", 10, 0)
            currentY = currentY + 20
        end
        
        local bossRow = CreateFrame("Frame", nil, scrollChild)
        bossRow:SetWidth(bossRowWidth)
        bossRow:SetHeight(bossRowHeight)
        bossRow:SetPoint("TOP", scrollChild, "TOP", 0, -currentY)
        bossRow:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        
        local bossName = orderedBosses[i]
        local isOptional = self.optionalBosses[bossName]
        
        -- Optional bosses get a different background color
        if isOptional then
            bossRow:SetBackdropColor(0.15, 0.15, 0.2, 0.5)
        else
            bossRow:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
        end
        
        local bossNameText = bossRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bossNameText:SetPoint("LEFT", bossRow, "LEFT", 10, 0)
        bossNameText:SetJustifyH("LEFT")
        bossNameText:SetText(tostring(bossName))
        
        bossRow.nameText = bossNameText
        bossRow.bossName = bossName
        
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
        
        currentY = currentY + bossRowHeight + 5
    end
end

function TurtleDungeonTimer:showDungeonMenu(button)
     -- Toggle: if already visible, close everything
    if self.frame.instanceSubmenu and self.frame.instanceSubmenu:IsVisible() then
        self:hideAllMenus()
        return
    end
    
    -- Close all existing menus
    self:hideAllMenus()
    
    -- Show dungeon list directly
    self:showInstanceListDirect(button, true)
end

function TurtleDungeonTimer:hideAllMenus()
    if self.frame.categoryMenu then
        self.frame.categoryMenu:Hide()
        self.frame.categoryMenu = nil
    end
    if self.frame.instanceSubmenu then
        self.frame.instanceSubmenu:Hide()
        self.frame.instanceSubmenu = nil
    end
    if self.frame.variantSubmenu then
        self.frame.variantSubmenu:Hide()
        self.frame.variantSubmenu = nil
    end
end

function TurtleDungeonTimer:showInstanceListDirect(parentBtn, isDungeonFilter)
    -- Close existing submenus
    if self.frame.instanceSubmenu then
        self.frame.instanceSubmenu:Hide()
        self.frame.instanceSubmenu = nil
    end
    if self.frame.variantSubmenu then
        self.frame.variantSubmenu:Hide()
        self.frame.variantSubmenu = nil
    end
    
    -- Performance: Use cached menu if available
    local cacheKey = isDungeonFilter and "cachedDungeonMenu" or "cachedRaidMenu"
    local menu = self[cacheKey]
    
    if not menu then
        -- Build list of instances matching the filter (only once!)
        menu = {}
        for instanceName, instanceData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
            if instanceData.isDungeon == isDungeonFilter or instanceData.isRaid == (not isDungeonFilter) then
                local displayName = instanceData.displayName or instanceName
                table.insert(menu, {text = displayName, key = instanceName})
            end
        end
        
        table.sort(menu, function(a, b) return a.text < b.text end)
        
        -- Cache for future use
        self[cacheKey] = menu
    end
    
    local btnHeight = 20
    local numItems = table.getn(menu)
    local maxVisibleItems = 20
    local menuHeight = math.min(maxVisibleItems * btnHeight + 8, numItems * btnHeight + 8)
    
    -- Create menu directly from the button
    local submenu = self:CreateTDTDropdown(self.frame, 160, menuHeight)
    submenu:SetPoint("TOPLEFT", parentBtn, "BOTTOMLEFT", 0, 0)
     submenu:SetPoint("TOPRIGHT", parentBtn, "BOTTOMRIGHT", 0, 0)
    submenu:Show()
    self.frame.instanceSubmenu = submenu

    local scrollFrame, scrollChild = self:CreateTDTScrollFrame(submenu, 152, menuHeight - 8)
    scrollFrame:SetPoint("TOPLEFT", submenu, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("TOPRIGHT", submenu, "TOPRIGHT", -4, -4)
    scrollChild:SetHeight(numItems * btnHeight)

    if numItems > maxVisibleItems then
        self:CreateTDTScrollbar(scrollFrame, numItems * btnHeight, menuHeight - 8)
    end
    
    -- Create buttons for each instance
    -- Adjust button width if scrollbar is present
    local btnWidth = (numItems > maxVisibleItems) and 130 or 145
    
    for i = 1, numItems do
        local item = menu[i]
        local displayName = item.text
        local instanceName = item.key
        local btn = self:CreateTDTButton(scrollChild, displayName, btnWidth, btnHeight)
        btn:SetPoint("TOP", scrollChild, "TOP", 0, -(i-1) * btnHeight)
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        text:SetPoint("RIGHT", btn, "RIGHT", -18, 0)
        text:SetText(displayName)
        text:SetJustifyH("LEFT")
        local variants = TurtleDungeonTimer.DUNGEON_DATA[instanceName].variants
        local variantCount = 0
        for _ in pairs(variants) do
            variantCount = variantCount + 1
        end
        if variantCount > 1 then
            local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            arrow:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            arrow:SetText(">")
        end
        btn:SetScript("OnEnter", function()
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            if variantCount > 1 then
                TurtleDungeonTimer:getInstance():showVariantSubmenuLevel3(this, instanceName)
            end
        end)
        btn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        btn:SetScript("OnClick", function()
            TurtleDungeonTimer:getInstance():handleInstanceClick(instanceName, variantCount)
        end)
    end
end

function TurtleDungeonTimer:showVariantSubmenuLevel3(parentBtn, instanceName)
    -- Close existing variant submenu
    if self.frame.variantSubmenu then
        self.frame.variantSubmenu:Hide()
        self.frame.variantSubmenu = nil
    end
    
    local variants = TurtleDungeonTimer.DUNGEON_DATA[instanceName].variants
    local variantMenu = {}
    for variantName, _ in pairs(variants) do
        table.insert(variantMenu, variantName)
    end
    table.sort(variantMenu)
    
    local btnHeight = 20
    local numVariants = table.getn(variantMenu)
    local menuHeight = numVariants * btnHeight + 8
    
    -- Create Level 3 submenu for variants
    local submenu = CreateFrame("Frame", nil, self.frame.instanceSubmenu)
    submenu:SetWidth(135)
    submenu:SetHeight(menuHeight)
    submenu:SetPoint("TOPLEFT", parentBtn, "TOPRIGHT", 0, 0)
    submenu:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    submenu:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    submenu:SetFrameStrata("DIALOG")
    submenu:Show()
    self.frame.variantSubmenu = submenu
    
    -- Create buttons for each variant
    for j = 1, numVariants do
        local variantName = variantMenu[j]
        
        local vBtn = CreateFrame("Button", nil, submenu)
        vBtn:SetWidth(120)
        vBtn:SetHeight(btnHeight)
        vBtn:SetPoint("TOP", submenu, "TOP", 0, -4 - (j-1) * btnHeight)
        
        local vText = vBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        vText:SetPoint("LEFT", vBtn, "LEFT", 5, 0)
        vText:SetText(variantName)
        vText:SetJustifyH("LEFT")
        
        vBtn:SetScript("OnEnter", function()
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropColor(0.4, 0.4, 0.4, 0.8)
        end)
        
        vBtn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        
        vBtn:SetScript("OnClick", function()
            TurtleDungeonTimer:getInstance():selectDungeonVariant(instanceName, variantName)
        end)
    end
end

function TurtleDungeonTimer:handleInstanceClick(instanceName, variantCount)
    if variantCount == 1 then
        -- Only one variant, select it directly
        local variants = TurtleDungeonTimer.DUNGEON_DATA[instanceName].variants
        for variantName, _ in pairs(variants) do
            self:selectDungeonVariant(instanceName, variantName)
            break
        end
    end
    -- If multiple variants, user must choose from Level 3 submenu
end

function TurtleDungeonTimer:selectDungeonVariant(instanceName, variantName)
    self:selectDungeon(instanceName)
    self:selectVariant(variantName)
    self:hideAllMenus()
end
