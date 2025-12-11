-- ============================================================================
-- Turtle Dungeon Timer - User Interface
-- ============================================================================

-- ============================================================================
-- DUNGEON/VARIANT SELECTION
-- ============================================================================
function TurtleDungeonTimer:selectDungeon(dungeonName)
    if not dungeonName or dungeonName == "" then
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
        self.frame.dungeonNameText:SetText(self:truncateText(displayName, 18))
        self.frame.dungeonNameText:SetTextColor(1, 1, 1)
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
    self.frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
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
    self.frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    self:createDungeonSelector()
    self:createButtons()
    self:createHeader()
    
    self.frame.bossRows = {}
    self:updateFrameSize()
    self.frame:Hide()
end

function TurtleDungeonTimer:createDungeonSelector()
    -- Label
    local dungeonLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonLabel:SetPoint("TOP", self.frame, "TOP", 0, -20)
    dungeonLabel:SetText("Dungeon/Raid:")
    
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
    local btnWidth = 75
    local btnY = -85
    
    -- START Button
    local startButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    startButton:SetWidth(btnWidth)
    startButton:SetHeight(30)
    startButton:SetPoint("TOP", self.frame, "TOP", -85, btnY)
    startButton:SetText("START")
    startButton:SetScript("OnClick", function() 
        TurtleDungeonTimer:getInstance():start() 
    end)
    
    -- STOP Button
    local stopButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    stopButton:SetWidth(btnWidth)
    stopButton:SetHeight(30)
    stopButton:SetPoint("TOP", self.frame, "TOP", 0, btnY)
    stopButton:SetText("STOP")
    stopButton:SetScript("OnClick", function() 
        TurtleDungeonTimer:getInstance():stop() 
    end)
    
    -- REPORT Button with Dropdown
    self:createReportButton(btnWidth, btnY)
end

function TurtleDungeonTimer:createReportButton(btnWidth, btnY)
    local reportButton = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    reportButton:SetWidth(btnWidth)
    reportButton:SetHeight(30)
    reportButton:SetPoint("TOP", self.frame, "TOP", 85, btnY)
    reportButton:SetText("REPORT")
    
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

function TurtleDungeonTimer:createHeader()
    local headerBg = CreateFrame("Button", nil, self.frame)
    headerBg:SetWidth(240)
    headerBg:SetHeight(40)
    headerBg:SetPoint("TOP", self.frame, "TOP", 0, -130)
    headerBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    headerBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    headerBg:SetScript("OnClick", function() 
        TurtleDungeonTimer:getInstance():toggleBossList() 
    end)
    headerBg:SetScript("OnEnter", function() 
        this:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
    end)
    headerBg:SetScript("OnLeave", function() 
        this:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    end)
    self.frame.headerBg = headerBg
    
    -- Dungeon Name
    local dungeonNameText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dungeonNameText:SetPoint("LEFT", headerBg, "LEFT", 10, 5)
    dungeonNameText:SetJustifyH("LEFT")
    dungeonNameText:SetWidth(140)
    dungeonNameText:SetText("Select Dungeon")
    self.frame.dungeonNameText = dungeonNameText
    
    -- Time Display
    local timeText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timeText:SetPoint("RIGHT", headerBg, "RIGHT", -25, 5)
    timeText:SetJustifyH("RIGHT")
    timeText:SetText("00:00")
    self.frame.timeText = timeText
    
    -- Toggle Indicator
    local toggleIndicator = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toggleIndicator:SetPoint("RIGHT", headerBg, "RIGHT", -5, 5)
    toggleIndicator:SetText("-")
    toggleIndicator:SetTextColor(0.8, 0.8, 0.8)
    self.frame.toggleIndicator = toggleIndicator
    
    -- Best Time Display
    local bestTimeText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bestTimeText:SetPoint("LEFT", headerBg, "LEFT", 10, -10)
    bestTimeText:SetJustifyH("LEFT")
    bestTimeText:SetText("Best: --:--")
    bestTimeText:SetTextColor(0.5, 0.5, 0.5)
    self.frame.bestTimeText = bestTimeText
    
    -- Death Counter
    local deathText = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deathText:SetPoint("RIGHT", headerBg, "RIGHT", -25, -10)
    deathText:SetJustifyH("RIGHT")
    deathText:SetText("Deaths: 0")
    deathText:SetTextColor(1, 0.5, 0.5)
    self.frame.deathText = deathText
end

-- ============================================================================
-- UI UPDATE FUNCTIONS
-- ============================================================================
function TurtleDungeonTimer:updateFrameSize()
    if not self.frame then return end
    
    local baseHeight = 200
    local maxVisibleBosses = 6
    local bossRowHeight = 35
    local spacing = 5
    local bossAreaHeight = 0
    
    if self.bossListExpanded and table.getn(self.bossList) > 0 then
        local numBosses = table.getn(self.bossList)
        local visibleBosses = math.min(numBosses, maxVisibleBosses)
        bossAreaHeight = (visibleBosses * bossRowHeight) + ((visibleBosses - 1) * spacing) + 20
    end
    
    self.frame:SetHeight(baseHeight + bossAreaHeight)
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
        self.frame.dungeonNameText:SetText(self:truncateText(displayName, 18))
        self.frame.dungeonNameText:SetTextColor(1, 0.82, 0)
    end
    
    if self.frame.timeText then
        self.frame.timeText:SetText(tostring(TurtleDungeonTimerDB.settings.countdownDuration))
        self.frame.timeText:SetTextColor(1, 1, 0)
    end
    
    if self.frame.headerBg then
        self.frame.headerBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    end
    
    if self.frame.bossRows then
        for i = 1, table.getn(self.frame.bossRows) do
            self.frame.bossRows[i].timeText:SetText("-")
            self.frame.bossRows[i]:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
            if self.frame.bossRows[i].checkmark then
                self.frame.bossRows[i].checkmark:Hide()
            end
        end
    end
end

-- Continued in next file part...
