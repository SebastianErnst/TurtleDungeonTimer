-- ============================================================================
-- Turtle Dungeon Timer - User Interface
-- ============================================================================

-- ============================================================================
-- UI ELEMENT CREATION UTILITIES
-- ============================================================================
function TurtleDungeonTimer:CreateTDTButton(parent, text, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)
    btn:SetText(text)
    if onClick then
        btn:SetScript("OnClick", onClick)
    end
    return btn
end

function TurtleDungeonTimer:CreateTDTDropdown(parent, width, height)
    local dropdown = CreateFrame("Frame", nil, parent)
    dropdown:SetWidth(width)
    dropdown:SetHeight(height)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropdown:SetFrameStrata("TOOLTIP")
    dropdown:Hide()
    return dropdown
end

function TurtleDungeonTimer:CreateTDTScrollFrame(parent, width, height)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetWidth(width)
    scrollFrame:SetHeight(height)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width)
    scrollChild:SetHeight(height)
    scrollFrame:SetScrollChild(scrollChild)
    return scrollFrame, scrollChild
end

function TurtleDungeonTimer:CreateTDTScrollbar(scrollFrame, contentHeight, frameHeight)
    local scrollbar = CreateFrame("Slider", nil, scrollFrame)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetWidth(16)
    scrollbar:SetHeight(frameHeight)
    scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, 0)
    scrollbar:SetMinMaxValues(0, math.max(0, contentHeight - frameHeight))
    scrollbar:SetValueStep(25)
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
            scrollbar:SetValue(math.min(maxVal, current + 25))
        elseif delta > 0 and current > minVal then
            scrollbar:SetValue(math.max(minVal, current - 25))
        end
    end)
    return scrollbar
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
function TurtleDungeonTimer:getRequiredBossCount()
    local count = 0
    for i = 1, table.getn(self.bossList) do
        if not self.optionalBosses[self.bossList[i]] then
            count = count + 1
        end
    end
    return count
end

function TurtleDungeonTimer:getRequiredBossKills()
    local count = 0
    for i = 1, table.getn(self.killTimes) do
        local bossName = self.killTimes[i].bossName
        if not self.optionalBosses[bossName] then
            count = count + 1
        end
    end
    return count
end

-- ============================================================================
-- DUNGEON/VARIANT SELECTION
-- ============================================================================
function TurtleDungeonTimer:selectDungeon(dungeonName)
    if not dungeonName or dungeonName == "" then
        return
    end
    
    -- Check if dungeon exists in data
    if not TurtleDungeonTimer.DUNGEON_DATA[dungeonName] then
        return
    end
    
    self.selectedDungeon = dungeonName
    self.selectedVariant = nil
    self.bossList = {}
    
    if self.frame and self.frame.dungeonSelector then
        self.frame.dungeonSelector:SetText(tostring(dungeonName))
    end
    
    TurtleDungeonTimerDB.lastSelection.dungeon = dungeonName
    
    -- Auto-select variant if only one exists or if "Default" exists
    local variants = TurtleDungeonTimer.DUNGEON_DATA[dungeonName].variants
    local variantCount = 0
    local firstVariant = nil
    local hasDefault = false
    
    for variantName, _ in pairs(variants) do
        variantCount = variantCount + 1
        if not firstVariant then
            firstVariant = variantName
        end
        if variantName == "Default" then
            hasDefault = true
        end
    end
    
    if hasDefault then
        self:selectVariant("Default")
    elseif variantCount == 1 then
        self:selectVariant(firstVariant)
    else
        self:rebuildBossRows()
        self:updateBestTimeDisplay()
    end
end

function TurtleDungeonTimer:selectVariant(variantName)
    if not self.selectedDungeon then
        return
    end
    if not variantName or variantName == "" then
        return
    end
    
    self.selectedVariant = variantName
    local variantData = TurtleDungeonTimer.DUNGEON_DATA[self.selectedDungeon].variants[variantName]
    if not variantData then
        return
    end
    
    self.bossList = variantData.bosses
    self.optionalBosses = variantData.optionalBosses or {}
    
    -- Update both selector and header text
    if self.frame and self.frame.dungeonSelector then
        if variantName == "Default" then
            self.frame.dungeonSelector:SetText(tostring(self.selectedDungeon))
        else
            self.frame.dungeonSelector:SetText(tostring(self.selectedDungeon) .. " - " .. tostring(variantName))
        end
    end
    
    if self.frame and self.frame.dungeonNameText then
        local displayName = self.selectedDungeon
        if variantName ~= "Default" then
            displayName = displayName .. " - " .. variantName
        end
        self.frame.dungeonNameText:SetText(displayName)
        self.frame.dungeonNameText:SetTextColor(1, 0.82, 0)
    end
    
    TurtleDungeonTimerDB.lastSelection.variant = variantName
    
    self:rebuildBossRows()
    self:updateBestTimeDisplay()
end

-- ============================================================================
-- UI CREATION
-- ============================================================================
function TurtleDungeonTimer:createUI()
    if self.frame then return end
    
    self.frame = CreateFrame("Frame", "TurtleDungeonTimerFrame", UIParent)
    self.frame:SetWidth(270)
    self.frame:SetHeight(250)
    
    -- Restore saved position or use default
    local pos = TurtleDungeonTimerDB.position
    self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    
    self.frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function() this:StartMoving() end)
    self.frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        -- Save position
        local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
        TurtleDungeonTimerDB.position = {
            point = point,
            relativeTo = "UIParent",
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)
    
    self:createDungeonSelector()
    self:createButtons()
    self:createHeader()
    self:createMinimizeButton()
    
    self.frame.bossRows = {}
    self:updateFrameSize()
    self.frame:Hide()
end

function TurtleDungeonTimer:createDungeonSelector()
    -- Label
    local dungeonLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonLabel:SetPoint("TOP", self.frame, "TOP", 0, -20)
    dungeonLabel:SetText("Dungeon/Raid:")
    self.frame.dungeonLabel = dungeonLabel
    
    -- Selector Button
    local dungeonSelector = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    dungeonSelector:SetWidth(240)
    dungeonSelector:SetHeight(25)
    dungeonSelector:SetPoint("TOP", dungeonLabel, "BOTTOM", 0, -5)
    dungeonSelector:SetText("Select Dungeon...")
    dungeonSelector:SetScript("OnClick", function() 
        TurtleDungeonTimer:getInstance():showDungeonMenu(this) 
    end)
    self.frame.dungeonSelector = dungeonSelector
end

function TurtleDungeonTimer:createButtons()
    local btnWidth = 56
    local spacing = 3
    
    -- Calculate total width: 4 buttons * 42 + 3 gaps * 3 = 168 + 9 = 177px (zentriert in Frame)
    
    -- All buttons in one row: RESET, REPORT, EXPORT, HISTORY
    self:createResetButton(btnWidth, spacing)
    self:createReportButton(btnWidth, spacing)
    self:createExportButton(btnWidth, spacing)
    self:createHistoryButton(btnWidth, spacing)
end

function TurtleDungeonTimer:createResetButton(btnWidth, spacing)
    local resetButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    resetButton:SetWidth(btnWidth)
    resetButton:SetHeight(30)
    resetButton:SetText("RESET")
    resetButton:SetScript("OnClick", function()
        TurtleDungeonTimer:getInstance():reset()
    end)
    self.frame.resetButton = resetButton
end

function TurtleDungeonTimer:createReportButton(btnWidth, spacing)
    local reportButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    reportButton:SetWidth(btnWidth)
    reportButton:SetHeight(30)
    reportButton:SetText("REPORT")
    self.frame.reportButton = reportButton
    
    local reportDropdown = CreateFrame("Frame", nil, reportButton)
    reportDropdown:SetWidth(100)
    reportDropdown:SetHeight(80)
    reportDropdown:SetPoint("TOP", reportButton, "BOTTOM", 0, 0)
    reportDropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    reportDropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    reportDropdown:SetFrameStrata("DIALOG")
    reportDropdown:Hide()
    self.frame.reportDropdown = reportDropdown
    
    local channels = {{"SAY", "Say"}, {"PARTY", "Party"}, {"RAID", "Raid"}, {"GUILD", "Guild"}}
    for i, channelData in ipairs(channels) do
        local chatType = channelData[1]
        local chatLabel = channelData[2]
        
        local btn = CreateFrame("Button", nil, reportDropdown)
        btn:SetWidth(92)
        btn:SetHeight(18)
        btn:SetPoint("TOP", reportDropdown, "TOP", 0, -4 - (i-1) * 20)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", btn, "CENTER", 0, 0)
        text:SetText(chatLabel)
        btn.text = text
        
        btn:SetScript("OnEnter", function()
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
        end)
        btn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        btn:SetScript("OnClick", function()
            TurtleDungeonTimer:getInstance():report(chatType)
            reportDropdown:Hide()
        end)
    end
    
    reportButton:SetScript("OnClick", function()
        if reportDropdown:IsVisible() then
            reportDropdown:Hide()
        else
            reportDropdown:Show()
        end
    end)
end

function TurtleDungeonTimer:createExportButton(btnWidth, spacing)
    local exportButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    exportButton:SetWidth(btnWidth)
    exportButton:SetHeight(30)
    exportButton:SetPoint("LEFT", self.frame.reportButton, "RIGHT", spacing, 0)
    exportButton:SetText("EXPORT")
    exportButton:SetScript("OnClick", function()
        TurtleDungeonTimer:getInstance():showExportDialog()
    end)
    self.frame.exportButton = exportButton
end

function TurtleDungeonTimer:createHistoryButton(btnWidth, spacing)
    local historyButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    historyButton:SetWidth(btnWidth)
    historyButton:SetHeight(30)
    historyButton:SetPoint("LEFT", self.frame.exportButton, "RIGHT", spacing, 0)
    historyButton:SetText("HISTORY")
    self.frame.historyButton = historyButton
    
    -- Create history dropdown
    local historyDropdown = CreateFrame("Frame", nil, historyButton)
    historyDropdown:SetWidth(250)
    historyDropdown:SetHeight(200)
    historyDropdown:SetPoint("TOP", historyButton, "BOTTOM", 0, 0)
    historyDropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    historyDropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    historyDropdown:SetFrameStrata("DIALOG")
    historyDropdown:Hide()
    self.frame.historyDropdown = historyDropdown
    
    historyButton:SetScript("OnClick", function()
        if historyDropdown:IsVisible() then
            historyDropdown:Hide()
        else
            TurtleDungeonTimer:getInstance():updateHistoryDropdown()
            historyDropdown:Show()
        end
    end)
end

function TurtleDungeonTimer:updateHistoryDropdown()
    local dropdown = self.frame.historyDropdown
    if not dropdown then return end
    
    -- Clear previous entries
    if dropdown.entries then
        for i = 1, table.getn(dropdown.entries) do
            dropdown.entries[i]:Hide()
        end
    end
    dropdown.entries = {}
    
    local history = TurtleDungeonTimerDB.history
    if not history or table.getn(history) == 0 then
        local noData = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noData:SetPoint("CENTER", dropdown, "CENTER", 0, 0)
        noData:SetText("Keine Historie vorhanden")
        table.insert(dropdown.entries, noData)
        return
    end
    
    for i = 1, math.min(10, table.getn(history)) do
        local entry = history[i]
        local yOffset = -10 - (i-1) * 20
        
        -- Create clickable button instead of text
        local entryBtn = CreateFrame("Button", nil, dropdown)
        entryBtn:SetWidth(230)
        entryBtn:SetHeight(18)
        entryBtn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 10, yOffset)
        
        local entryText = entryBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        entryText:SetPoint("LEFT", entryBtn, "LEFT", 0, 0)
        entryText:SetJustifyH("LEFT")
        entryText:SetWidth(230)
        
        local timeStr = self:formatTime(entry.time)
        local statusStr = entry.completed == false and " [Incomplete]" or ""
        local text = string.format("%s - %s (%dd)%s", entry.dungeon, timeStr, entry.deathCount, statusStr)
        if entry.date then
            text = entry.date .. " - " .. text
        end
        entryText:SetText(text)
        
        -- Color incomplete runs differently
        if entry.completed == false then
            entryText:SetTextColor(1, 0.7, 0.3) -- Orange for incomplete
        else
            entryText:SetTextColor(1, 1, 1) -- White for complete
        end
        
        -- Hover effect
        entryBtn:SetScript("OnEnter", function()
            entryBtn:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            entryBtn:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
        end)
        entryBtn:SetScript("OnLeave", function()
            entryBtn:SetBackdrop(nil)
        end)
        
        -- Click to show details
        entryBtn:SetScript("OnClick", function()
            TurtleDungeonTimer:getInstance():showHistoryDetails(entry)
            dropdown:Hide()
        end)
        
        table.insert(dropdown.entries, entryBtn)
    end
end

function TurtleDungeonTimer:showHistoryDetails(entry)
    -- Close existing detail window if open
    if self.historyDetailFrame then
        self.historyDetailFrame:Hide()
        self.historyDetailFrame = nil
    end
    
    -- Create detail window
    local detailFrame = CreateFrame("Frame", nil, UIParent)
    detailFrame:SetWidth(350)
    detailFrame:SetHeight(400)
    detailFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    detailFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    detailFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    detailFrame:SetFrameStrata("DIALOG")
    detailFrame:EnableMouse(true)
    detailFrame:SetMovable(true)
    detailFrame:RegisterForDrag("LeftButton")
    detailFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    detailFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    self.historyDetailFrame = detailFrame
    
    -- Title
    local title = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", detailFrame, "TOP", 0, -15)
    title:SetText(entry.dungeon .. " - " .. (entry.variant or "Default"))
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, detailFrame)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetPoint("TOPRIGHT", detailFrame, "TOPRIGHT", -10, -10)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(1, 0, 0)
    closeBtn:SetScript("OnClick", function()
        detailFrame:Hide()
    end)
    
    -- Run info
    local infoText = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    local timeStr = self:formatTime(entry.time)
    infoText:SetText(string.format("Zeit: %s | Deaths: %d", timeStr, entry.deathCount))
    
    if entry.date then
        local dateText = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dateText:SetPoint("TOP", infoText, "BOTTOM", 0, -5)
        dateText:SetText(entry.date)
        dateText:SetTextColor(0.7, 0.7, 0.7)
    end
    
    -- Boss kills section
    local bossHeader = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bossHeader:SetPoint("TOP", infoText, "BOTTOM", 0, -25)
    bossHeader:SetText("Boss Kills:")
    
    -- Scroll frame for boss list
    local scrollFrame = CreateFrame("ScrollFrame", nil, detailFrame)
    scrollFrame:SetWidth(320)
    scrollFrame:SetHeight(220)
    scrollFrame:SetPoint("TOP", bossHeader, "BOTTOM", 0, -10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(300)
    local bossCount = table.getn(entry.killTimes or {})
    scrollChild:SetHeight(math.max(220, bossCount * 25))
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Add scrollbar if needed
    if bossCount * 25 > 220 then
        local scrollbar = CreateFrame("Slider", nil, scrollFrame)
        scrollbar:SetOrientation("VERTICAL")
        scrollbar:SetWidth(16)
        scrollbar:SetHeight(220)
        scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, 0)
        scrollbar:SetMinMaxValues(0, (bossCount * 25) - 220)
        scrollbar:SetValueStep(25)
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
                scrollbar:SetValue(math.min(maxVal, current + 25))
            elseif delta > 0 and current > minVal then
                scrollbar:SetValue(math.max(minVal, current - 25))
            end
        end)
    end
    
    -- Display boss kills
    if entry.killTimes and table.getn(entry.killTimes) > 0 then
        for i = 1, table.getn(entry.killTimes) do
            local kill = entry.killTimes[i]
            local yPos = -5 - (i-1) * 25
            
            local bossText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            bossText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yPos)
            bossText:SetJustifyH("LEFT")
            bossText:SetWidth(180)
            bossText:SetText(kill.bossName or "Unknown Boss")
            
            local timeText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            timeText:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, yPos)
            timeText:SetJustifyH("RIGHT")
            local killTimeStr = self:formatTime(kill.time)
            if kill.splitTime and kill.splitTime > 0 then
                killTimeStr = killTimeStr .. " (+" .. self:formatTime(kill.splitTime) .. ")"
            end
            timeText:SetText(killTimeStr)
            timeText:SetTextColor(0, 1, 0)
        end
    else
        local noBosses = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noBosses:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
        noBosses:SetText("Keine Boss-Daten verfügbar")
        noBosses:SetTextColor(0.7, 0.7, 0.7)
    end
    
    -- Buttons at bottom
    local reportBtn = CreateFrame("Button", nil, detailFrame, "GameMenuButtonTemplate")
    reportBtn:SetWidth(80)
    reportBtn:SetHeight(25)
    reportBtn:SetPoint("BOTTOMLEFT", detailFrame, "BOTTOMLEFT", 50, 15)
    reportBtn:SetText("REPORT")
    reportBtn:SetScript("OnClick", function()
        self:reportHistoryEntry(entry)
    end)
    
    local exportBtn = CreateFrame("Button", nil, detailFrame, "GameMenuButtonTemplate")
    exportBtn:SetWidth(80)
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("BOTTOMRIGHT", detailFrame, "BOTTOMRIGHT", -20, 15)
    exportBtn:SetText("EXPORT")
    exportBtn:SetScript("OnClick", function()
        self:showExportDialog(entry)
    end)
    
    detailFrame:Show()
end

function TurtleDungeonTimer:reportHistoryEntry(entry)
    if not entry then return end
    
    -- Create report dropdown similar to main report button
    local detailFrame = self.historyDetailFrame
    if not detailFrame then return end
    
    -- Create or show report dropdown
    if detailFrame.reportDropdown and detailFrame.reportDropdown:IsVisible() then
        detailFrame.reportDropdown:Hide()
        return
    end
    
    if not detailFrame.reportDropdown then
        local dropdown = CreateFrame("Frame", nil, detailFrame)
        dropdown:SetWidth(100)
        dropdown:SetHeight(80)
        dropdown:SetPoint("TOPLEFT", detailFrame, "BOTTOMLEFT", 20, -15)
        dropdown:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        dropdown:SetFrameStrata("TOOLTIP")
        detailFrame.reportDropdown = dropdown
        
        local channels = {{"SAY", "Say"}, {"PARTY", "Party"}, {"RAID", "Raid"}, {"GUILD", "Guild"}}
        for i, channelData in ipairs(channels) do
            local chatType = channelData[1]
            local chatLabel = channelData[2]
            
            local btn = CreateFrame("Button", nil, dropdown)
            btn:SetWidth(92)
            btn:SetHeight(18)
            btn:SetPoint("TOP", dropdown, "TOP", 0, -4 - (i-1) * 20)
            
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER", btn, "CENTER", 0, 0)
            text:SetText(chatLabel)
            
            btn:SetScript("OnEnter", function()
                this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
                this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            end)
            btn:SetScript("OnLeave", function()
                this:SetBackdrop(nil)
            end)
            btn:SetScript("OnClick", function()
                TurtleDungeonTimer:getInstance():sendHistoryReport(entry, chatType)
                dropdown:Hide()
            end)
        end
    end
    
    detailFrame.reportDropdown:Show()
end

function TurtleDungeonTimer:sendHistoryReport(entry, chatType)
    if not entry then return end
    
    chatType = chatType or "SAY"
    
    local dungeonStr = entry.dungeon or "Unknown"
    if entry.variant and entry.variant ~= "Default" then
        dungeonStr = dungeonStr .. " (" .. entry.variant .. ")"
    end
    
    -- Remove leading ! to prevent command parsing
    if string.sub(dungeonStr, 1, 1) == "!" then
        dungeonStr = string.sub(dungeonStr, 2)
    end
    
    local mainMessage = dungeonStr .. " completed in " .. self:formatTime(entry.time) .. ". Deaths: " .. entry.deathCount
    SendChatMessage(mainMessage, chatType)
    
    -- Combine bosses into readable messages (max ~255 chars per message)
    if entry.killTimes and table.getn(entry.killTimes) > 0 then
        local bossLine = "Bosses: "
        local lineCount = 0
        
        for i = 1, table.getn(entry.killTimes) do
            local bossEntry = entry.killTimes[i].bossName .. " (" .. self:formatTime(entry.killTimes[i].time) .. ")"
            
            -- Check if adding this boss would make the line too long
            if string.len(bossLine .. bossEntry) > 240 then
                SendChatMessage(bossLine, chatType)
                bossLine = bossEntry
                lineCount = lineCount + 1
            else
                if i > 1 and bossLine ~= "Bosses: " then
                    bossLine = bossLine .. ", "
                end
                bossLine = bossLine .. bossEntry
            end
        end
        
        -- Send remaining bosses
        if bossLine ~= "Bosses: " then
            SendChatMessage(bossLine, chatType)
        end
    end
end

function TurtleDungeonTimer:exportHistoryEntry(entry)
    if not entry then return end
    
    -- Build export string from history entry
    local parts = {"TDT"}
    
    -- Dungeon name
    local dungeonName = entry.dungeon or "Unknown"
    dungeonName = string.gsub(dungeonName, "[%s:]", "_")
    table.insert(parts, dungeonName)
    
    -- Variant
    local variant = entry.variant or "Default"
    variant = string.gsub(variant, "[%s:]", "_")
    table.insert(parts, variant)
    
    -- Total time
    table.insert(parts, string.format("%.0f", entry.time or 0))
    
    -- Deaths
    table.insert(parts, tostring(entry.deathCount or 0))
    
    -- Boss times
    if entry.killTimes then
        for i = 1, table.getn(entry.killTimes) do
            local bossName = string.gsub(entry.killTimes[i].bossName, "[%s:]", "_")
            local bossTime = string.format("%.0f", entry.killTimes[i].time)
            table.insert(parts, bossName .. ":" .. bossTime)
        end
    end
    
    local rawString = table.concat(parts, "|")
    local exportString = self:encodeBase64(rawString)
    
    -- Show export in chat
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Export String:")
    DEFAULT_CHAT_FRAME:AddMessage(exportString)
    
    -- Show in export dialog
    if self.exportDialog then
        if self.exportDialog.editBox then
            self.exportDialog.editBox:SetText(exportString)
            self.exportDialog.editBox:HighlightText()
        end
        self.exportDialog:Show()
    else
        -- Create export dialog if it doesn't exist
        self:createExportDialogForHistory(exportString)
    end
end

function TurtleDungeonTimer:createExportDialogForHistory(exportString)
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(400)
    dialog:SetHeight(200)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    self.exportDialog = dialog
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -20)
    title:SetText("Export Run Data")
    
    -- Description
    local desc = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Export string is also printed in chat for easy copying.")
    
    -- Edit box for export string
    local editBox = CreateFrame("EditBox", nil, dialog)
    editBox:SetWidth(360)
    editBox:SetHeight(60)
    editBox:SetPoint("TOP", desc, "BOTTOM", 0, -15)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontNormalSmall)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    editBox:SetText(exportString)
    editBox:HighlightText()
    editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    dialog.editBox = editBox
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    closeBtn:SetWidth(100)
    closeBtn:SetHeight(25)
    closeBtn:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 20)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:createHeader()
    local headerBg = CreateFrame("Button", nil, self.frame)
    headerBg:SetWidth(240)
    headerBg:SetHeight(65)
    headerBg:SetPoint("TOP", self.frame.dungeonSelector, "BOTTOM", 0, -3)
    headerBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    headerBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    self.frame.headerBg = headerBg
    
    -- Boss List Toggle (clicking on header)
    headerBg:SetScript("OnClick", function() 
        TurtleDungeonTimer:getInstance():toggleBossList() 
    end)
    headerBg:SetScript("OnEnter", function()
        local timer = TurtleDungeonTimer:getInstance()
        -- Check if run is completed (all bosses defeated)
        if table.getn(timer.killTimes) >= table.getn(timer.bossList) and table.getn(timer.killTimes) > 0 then
            this:SetBackdropColor(0.15, 0.6, 0.15, 0.8)  -- Lighter green on hover
        else
            this:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
        end
    end)
    headerBg:SetScript("OnLeave", function()
        local timer = TurtleDungeonTimer:getInstance()
        -- Check if run is completed (all bosses defeated)
        if table.getn(timer.killTimes) >= table.getn(timer.bossList) and table.getn(timer.killTimes) > 0 then
            this:SetBackdropColor(0.1, 0.5, 0.1, 0.8)  -- Green background
        else
            this:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        end
    end)
    
    -- Dungeon Name
    local dungeonNameText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dungeonNameText:SetPoint("LEFT", headerBg, "LEFT", 14, 8)
    dungeonNameText:SetJustifyH("LEFT")
    dungeonNameText:SetWidth(140)
    dungeonNameText:SetHeight(40)
    dungeonNameText:SetText("Select Dungeon")
    dungeonNameText:SetTextColor(1, 0.82, 0)  -- Gold color
    self.frame.dungeonNameText = dungeonNameText
    
    -- Time Display
    local timeText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timeText:SetPoint("RIGHT", headerBg, "RIGHT", -34, 10)
    timeText:SetJustifyH("RIGHT")
    timeText:SetText("00:00")
    timeText:SetTextColor(1, 1, 1)  -- White color
    self.frame.timeText = timeText
    
    -- Toggle Indicator (hidden by default, shown when minimized)
    local toggleIndicator = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toggleIndicator:SetPoint("RIGHT", headerBg, "RIGHT", -14, 10)
    toggleIndicator:SetText("-")
    toggleIndicator:SetTextColor(0.8, 0.8, 0.8)
    toggleIndicator:Hide()
    self.frame.toggleIndicator = toggleIndicator
    
    -- Best Time Display
    local bestTimeText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bestTimeText:SetPoint("LEFT", headerBg, "LEFT", 14, -16)
    bestTimeText:SetJustifyH("LEFT")
    bestTimeText:SetText("Best: --:--")
    bestTimeText:SetTextColor(0.5, 0.5, 0.5)
    self.frame.bestTimeText = bestTimeText
    
    -- Death Counter
    local deathText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deathText:SetPoint("RIGHT", headerBg, "RIGHT", -34, -10)
    deathText:SetJustifyH("RIGHT")
    deathText:SetText("Deaths: 0")
    deathText:SetTextColor(1, 0.5, 0.5)
    self.frame.deathText = deathText
end

function TurtleDungeonTimer:createMinimizeButton()
    -- Minimize Button (top right corner of main frame)
    local minimizeButton = CreateFrame("Button", nil, self.frame)
    minimizeButton:SetWidth(20)
    minimizeButton:SetHeight(20)
    minimizeButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -12, -8)
    minimizeButton:SetFrameLevel(self.frame:GetFrameLevel() + 10)
    
    local minText = minimizeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    minText:SetPoint("CENTER", minimizeButton, "CENTER", 0, 0)
    minText:SetText("_")
    minText:SetTextColor(1, 0.82, 0)
    minimizeButton.text = minText
    
    minimizeButton:SetScript("OnClick", function()
        TurtleDungeonTimer:getInstance():toggleMinimized()
    end)
    minimizeButton:SetScript("OnEnter", function()
        minText:SetTextColor(1, 1, 0)
    end)
    minimizeButton:SetScript("OnLeave", function()
        minText:SetTextColor(1, 0.82, 0)
    end)
    self.frame.minimizeButton = minimizeButton
end

-- ============================================================================
-- UI UPDATE FUNCTIONS
-- ============================================================================
function TurtleDungeonTimer:updateFrameSize()
    if not self.frame then return end
    
    if self.minimized then
        self.frame:SetHeight(80)
        return
    end
    
    local baseHeight = 135
    local maxVisibleBosses = 6
    local bossRowHeight = 35
    local spacing = 5
    local bossAreaHeight = 0
    local buttonHeight = 55
    
    if self.bossListExpanded and table.getn(self.bossList) > 0 then
        local numBosses = table.getn(self.bossList)
        local visibleBosses = math.min(numBosses, maxVisibleBosses)
        bossAreaHeight = (visibleBosses * bossRowHeight) + ((visibleBosses - 1) * spacing) + 20
    end
    
    self.frame:SetHeight(baseHeight + bossAreaHeight + buttonHeight)
    
    -- Position buttons below boss list with spacing
    local headerY = -75
    local buttonY = headerY - 65 - bossAreaHeight
    
    -- All buttons in one row: RESET, REPORT, EXPORT, HISTORY
    -- Total width: 4*42 + 3*3 = 177px, start at -88.5px to center
    
    -- RESET button (leftmost)
    if self.frame.resetButton then
        self.frame.resetButton:ClearAllPoints()
        self.frame.resetButton:SetPoint("TOP", self.frame, "TOP", -88.5, buttonY)
    end
    
    -- REPORT button right of RESET
    if self.frame.reportButton then
        self.frame.reportButton:ClearAllPoints()
        self.frame.reportButton:SetPoint("LEFT", self.frame.resetButton, "RIGHT", 3, 0)
    end
    
    -- EXPORT button right of REPORT
    if self.frame.exportButton then
        self.frame.exportButton:ClearAllPoints()
        self.frame.exportButton:SetPoint("LEFT", self.frame.reportButton, "RIGHT", 3, 0)
    end
    
    -- HISTORY button right of EXPORT
    if self.frame.historyButton then
        self.frame.historyButton:ClearAllPoints()
        self.frame.historyButton:SetPoint("LEFT", self.frame.exportButton, "RIGHT", 3, 0)
    end
end

function TurtleDungeonTimer:toggleMinimized()
    self.minimized = not self.minimized
    TurtleDungeonTimerDB.minimized = self.minimized
    self:updateMinimizedState()
end

function TurtleDungeonTimer:updateMinimizedState()
    if not self.frame then return end
    
    if self.minimized then
        -- Make main frame background transparent
        self.frame:SetBackdropColor(0, 0, 0, 0)
        self.frame:SetBackdropBorderColor(0, 0, 0, 0)
        
        -- Move header to top of frame
        if self.frame.headerBg then
            self.frame.headerBg:ClearAllPoints()
            self.frame.headerBg:SetPoint("TOP", self.frame, "TOP", 0, -5)
        end
        
        -- Reposition minimize button to headerBg
        if self.frame.minimizeButton and self.frame.headerBg then
            self.frame.minimizeButton:ClearAllPoints()
            self.frame.minimizeButton:SetPoint("RIGHT", self.frame.headerBg, "RIGHT", -5, 0)
        end
        
        -- Hide everything except header, best time and death count
        if self.frame.dungeonSelector then self.frame.dungeonSelector:Hide() end
        if self.frame.dungeonLabel then self.frame.dungeonLabel:Hide() end
        if self.frame.resetButton then self.frame.resetButton:Hide() end
        if self.frame.reportButton then self.frame.reportButton:Hide() end
        if self.frame.exportButton then self.frame.exportButton:Hide() end
        if self.frame.historyButton then self.frame.historyButton:Hide() end
        if self.frame.bossScrollFrame then self.frame.bossScrollFrame:Hide() end
        if self.frame.reportDropdown then self.frame.reportDropdown:Hide() end
        
        -- Show best time and death count
        if self.frame.bestTimeText then self.frame.bestTimeText:Show() end
        if self.frame.deathText then self.frame.deathText:Show() end
        
        -- Update minimize button text
        if self.frame.minimizeButton and self.frame.minimizeButton.text then
            self.frame.minimizeButton.text:SetText("+")
        end
    else
        -- Restore main frame background
        self.frame:SetBackdropColor(0, 0, 0, 1)
        self.frame:SetBackdropBorderColor(1, 1, 1, 1)
        
        -- Restore header position
        if self.frame.headerBg and self.frame.dungeonSelector then
            self.frame.headerBg:ClearAllPoints()
            self.frame.headerBg:SetPoint("TOP", self.frame.dungeonSelector, "BOTTOM", 0, -3)
        end
        
        -- Restore minimize button to frame
        if self.frame.minimizeButton then
            self.frame.minimizeButton:ClearAllPoints()
            self.frame.minimizeButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -12, -8)
        end
        
        -- Show everything
        if self.frame.dungeonSelector then self.frame.dungeonSelector:Show() end
        if self.frame.dungeonLabel then self.frame.dungeonLabel:Show() end
        if self.frame.resetButton then self.frame.resetButton:Show() end
        if self.frame.reportButton then self.frame.reportButton:Show() end
        if self.frame.exportButton then self.frame.exportButton:Show() end
        if self.frame.historyButton then self.frame.historyButton:Show() end
        if self.frame.bestTimeText then self.frame.bestTimeText:Show() end
        if self.frame.deathText then self.frame.deathText:Show() end
        
        if self.frame.bossScrollFrame and self.bossListExpanded then 
            self.frame.bossScrollFrame:Show()
        end
        
        -- Update minimize button text
        if self.frame.minimizeButton and self.frame.minimizeButton.text then
            self.frame.minimizeButton.text:SetText("_")
        end
    end
    
    self:updateFrameSize()
end

function TurtleDungeonTimer:toggleBossList()
    self.bossListExpanded = not self.bossListExpanded
    
    if self.frame.bossScrollFrame then
        if self.bossListExpanded then
            self.frame.bossScrollFrame:Show()
        else
            self.frame.bossScrollFrame:Hide()
        end
    end
    
    if self.frame.toggleIndicator then
        if self.bossListExpanded then
            self.frame.toggleIndicator:SetText("-")
        else
            self.frame.toggleIndicator:SetText("+")
        end
    end
    
    self:updateFrameSize()
end

function TurtleDungeonTimer:updateBestTimeDisplay()
    if not self.frame or not self.frame.bestTimeText then return end
    
    local bestTime = self:getBestTime()
    if bestTime then
        self.frame.bestTimeText:SetText("Best: " .. self:formatTime(bestTime.time) .. " (" .. bestTime.deaths .. " deaths)")
        self.frame.bestTimeText:SetTextColor(1, 0.82, 0)
    else
        self.frame.bestTimeText:SetText("Best: --:--")
        self.frame.bestTimeText:SetTextColor(0.5, 0.5, 0.5)
    end
end

function TurtleDungeonTimer:resetUI()
    if not self.frame then return end
    
    if self.frame.dungeonNameText then
        local displayName = self.selectedDungeon
        if self.selectedVariant ~= "Default" then
            displayName = displayName .. " - " .. self.selectedVariant
        end
        self.frame.dungeonNameText:SetText(displayName)
        self.frame.dungeonNameText:SetTextColor(1, 0.82, 0)
    end
    
    if self.frame.timeText then
        self.frame.timeText:SetText("00:00")
        self.frame.timeText:SetTextColor(1, 1, 1)
    end
    
    if self.frame.headerBg then
        self.frame.headerBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    end
    
    if self.frame.bestTimeText then
        local bestTime = self:getBestTime()
        if bestTime then
            self.frame.bestTimeText:SetText("Best: " .. self:formatTime(bestTime.time) .. " (" .. bestTime.deaths .. " deaths)")
        else
            self.frame.bestTimeText:SetText("Best: --:--")
        end
        self.frame.bestTimeText:SetTextColor(0.5, 0.5, 0.5)
    end
    
    if self.frame.deathText then
        self.frame.deathText:SetText("Deaths: 0")
        self.frame.deathText:SetTextColor(1, 0.5, 0.5)
    end
    
    if self.frame.bossRows then
        for i = 1, table.getn(self.frame.bossRows) do
            self.frame.bossRows[i].timeText:SetText("-")
            
            -- Reset background color based on whether boss is optional
            local bossName = self.frame.bossRows[i].bossName
            local isOptional = self.optionalBosses[bossName]
            
            if isOptional then
                self.frame.bossRows[i]:SetBackdropColor(0.15, 0.15, 0.2, 0.5)
            else
                self.frame.bossRows[i]:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
            end
            
            if self.frame.bossRows[i].checkmark then
                self.frame.bossRows[i].checkmark:Hide()
            end
        end
    end
end

-- Continued in next file part...
