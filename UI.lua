-- ============================================================================
-- Turtle Dungeon Timer - New UI (Based on Mockup)
-- ============================================================================

-- ============================================================================
-- DROPDOWN/MENU HELPER FUNCTIONS
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
    scrollFrame:EnableMouseWheel()
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
        local boss = self.bossList[i]
        local bossName = type(boss) == "table" and boss.name or boss
        if not self.optionalBosses[bossName] then
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
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage(
            "[Debug] selectDungeon: Dungeon not found in DUNGEON_DATA: " .. tostring(dungeonName), 1, 0, 0)
        end
        return
    end

    self.selectedDungeon = dungeonName
    self.selectedVariant = nil
    self.bossList = {}

    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] selectDungeon: Set selectedDungeon to: " .. tostring(dungeonName), 0, 1, 0)
    end

    -- Broadcast dungeon selection
    self:broadcastDungeonSelected(dungeonName)
    
    -- Generate and broadcast Run-ID (if group leader or first in group)
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        self:broadcastRunId()
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
        -- No auto-select
        self:rebuildBossRows()
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

    -- Build boss list with proper structure
    self.bossList = {}
    if variantData.bosses then
        for i = 1, table.getn(variantData.bosses) do
            table.insert(self.bossList, {
                name = variantData.bosses[i],
                defeated = false,
                optional = false
            })
        end
    end

    self.optionalBosses = variantData.optionalBosses or {}

    -- Update dungeon name text
    if self.frame and self.frame.dungeonNameText then
        local displayName = self.selectedDungeon
        if variantName ~= "Default" then
            displayName = displayName .. " - " .. variantName
        end
        self.frame.dungeonNameText:SetText(displayName)
        self.frame.dungeonNameText:SetTextColor(1, 0.82, 0)
    end

    TurtleDungeonTimerDB.lastSelection.variant = variantName

    -- Prepare trash counter bar
    TDTTrashCounter:prepareDungeon(self.selectedDungeon, self.selectedVariant)

    -- Rebuild boss list
    self:rebuildBossRows()
end

-- ============================================================================
-- MAIN UI CREATION
-- ============================================================================
function TurtleDungeonTimer:createUI()
    if self.frame then return end

    -- Main Frame
    self.frame = CreateFrame("Frame", "TurtleDungeonTimerFrame", UIParent)
    self.frame:SetWidth(248)
    self.frame:SetHeight(115) -- Collapsed height (same as collapseBossList)

    -- Restore saved position or use default
    local pos = TurtleDungeonTimerDB.position
    self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)

    -- Background
    self.frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    self.frame:SetBackdropColor(0, 0, 0, 0.5)
    self.frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    -- Make movable
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function() this:StartMoving() end)
    self.frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
        TurtleDungeonTimerDB.position = {
            point = point,
            relativeTo = "UIParent",
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)

    -- Create UI sections
    self:createHeader()
    self:createTimerRow()
    self:createProgressBar()
    self:createBossList()

    -- Initialize state
    self.bossListExpanded = false

    self.frame:Hide()
end

-- ============================================================================
-- HEADER (Dungeon Name + Buttons)
-- ============================================================================
function TurtleDungeonTimer:createHeader()
    -- Dungeon name text
    local dungeonName = self.frame:CreateFontString(nil, "OVERLAY")
    dungeonName:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, -15)
    dungeonName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    dungeonName:SetTextColor(1, 1, 1)
    dungeonName:SetText(TDT_L("UI_LEADER_SELECT_DUNGEON"))
    dungeonName:SetJustifyH("LEFT")
    dungeonName:SetWidth(145)
    self.frame.dungeonNameText = dungeonName

    -- Dungeon name is now just text, no longer clickable

    -- Start/Reset Button (red button with text)
    local startBtn = CreateFrame("Button", nil, self.frame)
    startBtn:SetWidth(46)
    startBtn:SetHeight(23)
    startBtn:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 15, 10)
    
    -- Red button backdrop
    startBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    startBtn:SetBackdropColor(0.8, 0.1, 0.1, 1)
    startBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Button text
    local startBtnText = startBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    startBtnText:SetPoint("CENTER", startBtn, "CENTER", 0, 0)
    startBtnText:SetText("Start")
    startBtnText:SetTextColor(1, 1, 1)
    startBtn.text = startBtnText
    
    -- Store reference for later updates
    self.frame.startBtn = startBtn
    
    -- Update button appearance based on leadership status
    self:updateStartButton()

    startBtn:SetScript("OnClick", function()
        local timer = TurtleDungeonTimer:getInstance()

        -- Check if button should show "Abort" (timer running OR preparation complete)
        local shouldShowAbort = timer.isRunning or 
                               (timer.preparationState == "RESETTING" or 
                                timer.preparationState == "READY" or 
                                timer.preparationState == "COUNTDOWN")

        -- If abort mode, show abort confirmation dialog
        if shouldShowAbort then
            if timer:isGroupLeader() then
                timer:showAbortConfirmationDialog()
            else
                DEFAULT_CHAT_FRAME:AddMessage(
                "|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("PREP_LEADER_ONLY_ABORT"), 1, 0, 0)
            end
            return
        end

        -- If group leader and not in abort mode, start preparation
        if timer:isGroupLeader() then
            timer:startPreparation()
        else
            DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("PREP_LEADER_ONLY_START"), 1, 0, 0)
        end
    end)

    -- Tooltip
    startBtn:SetScript("OnEnter", function()
        local timer = TurtleDungeonTimer:getInstance()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")

        if timer.isRunning then
            GameTooltip:SetText(TDT_L("TOOLTIP_STOP_TIMER"), 1, 0.82, 0)
        else
            GameTooltip:SetText(TDT_L("TOOLTIP_PREPARE_RUN"), 1, 0.82, 0)
            if timer:isGroupLeader() then
                GameTooltip:AddLine(TDT_L("TOOLTIP_PREPARE_RUN_DESC"), 1, 1, 1, 1)
                GameTooltip:AddLine(" ", 1, 1, 1, 1)
                GameTooltip:AddLine(TDT_L("TOOLTIP_REQUIREMENTS"), 0.8, 0.8, 0.8, 1)
                GameTooltip:AddLine(TDT_L("TOOLTIP_ALL_HAVE_ADDON"), 1, 1, 1, 1)
                GameTooltip:AddLine(TDT_L("TOOLTIP_NO_ONE_IN_DUNGEON"), 1, 1, 1, 1)
            else
                GameTooltip:AddLine(TDT_L("TOOLTIP_ONLY_LEADER"), 1, 0.5, 0.5, 1)
            end
        end
        GameTooltip:Show()
    end)
    startBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.frame.startButton = startBtn

    -- History Button (Settings/Gear icon)
    local historyBtn = CreateFrame("Button", nil, self.frame)
    historyBtn:SetWidth(20)
    historyBtn:SetHeight(20)
    historyBtn:SetPoint("LEFT", startBtn, "RIGHT", 5, 0)

    historyBtn.icon = historyBtn:CreateTexture(nil, "ARTWORK")
    historyBtn.icon:SetAllPoints(historyBtn)
    historyBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_02") -- Gear icon

    historyBtn:SetScript("OnClick", function()
        TurtleDungeonTimer:getInstance():showHistoryMenu(this)
    end)
    
    -- Tooltip
    historyBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(TDT_L("TOOLTIP_RUN_HISTORY"), 1, 0.82, 0)
        GameTooltip:AddLine(TDT_L("TOOLTIP_RUN_HISTORY_DESC"), 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    historyBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.frame.historyButton = historyBtn
end

-- ============================================================================
-- TIMER ROW (Timer + Death Count)
-- ============================================================================
function TurtleDungeonTimer:createTimerRow()
    -- Timer text (left)
    local timerText = self.frame:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("TOPLEFT", self.frame.dungeonNameText, "BOTTOMLEFT", 0, -6)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
    timerText:SetTextColor(1, 1, 1)
    timerText:SetText("00:00")
    timerText:SetJustifyH("LEFT")
    self.frame.timerText = timerText

    -- Death count (right side)
    -- Skull icon
    local skullIcon = self.frame:CreateTexture(nil, "ARTWORK")
    skullIcon:SetWidth(17)
    skullIcon:SetHeight(17)
    skullIcon:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -14, -34)
    skullIcon:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull") -- Skull icon
    self.frame.skullIcon = skullIcon

    -- Death count text (X before skull)
    local deathText = self.frame:CreateFontString(nil, "OVERLAY")
    deathText:SetPoint("RIGHT", skullIcon, "LEFT", -2, 0)
    deathText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    deathText:SetTextColor(1, 1, 0)
    deathText:SetText("0")
    deathText:SetJustifyH("RIGHT")
    self.frame.deathText = deathText
    
    -- World Buffs indicator (small text left of death counter)
    local worldBuffsText = self.frame:CreateFontString(nil, "OVERLAY")
    worldBuffsText:SetPoint("RIGHT", deathText, "LEFT", -8, 0)
    worldBuffsText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    worldBuffsText:SetTextColor(0.2, 1, 0.2)  -- Light green
    worldBuffsText:SetText("")
    worldBuffsText:SetJustifyH("RIGHT")
    worldBuffsText:Hide()  -- Hidden by default
    self.frame.worldBuffsText = worldBuffsText
    
    -- Create invisible frame for tooltip hover
    local worldBuffsHover = CreateFrame("Frame", nil, self.frame)
    worldBuffsHover:SetPoint("RIGHT", deathText, "LEFT", -8, 0)
    worldBuffsHover:SetWidth(60)
    worldBuffsHover:SetHeight(15)
    worldBuffsHover:EnableMouse(true)
    worldBuffsHover:SetScript("OnEnter", function()
        -- Tooltip disabled for now
    end)
    worldBuffsHover:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    worldBuffsHover:Hide()  -- Hidden by default
    self.frame.worldBuffsHover = worldBuffsHover
end

-- ============================================================================
-- PROGRESS BAR
-- ============================================================================
function TurtleDungeonTimer:createProgressBar()
    -- Background
    local progressBg = self.frame:CreateTexture(nil, "BACKGROUND")
    progressBg:SetPoint("TOPLEFT", self.frame.timerText, "BOTTOMLEFT", 0, -6)
    progressBg:SetWidth(218)
    progressBg:SetHeight(21)
    progressBg:SetTexture(0.3, 0.3, 0.3, 0.9)
    self.frame.progressBg = progressBg

    -- Bar (cyan color like mockup)
    local progressBar = self.frame:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
    progressBar:SetWidth(1)                    -- Will be updated
    progressBar:SetHeight(21)
    progressBar:SetTexture(0.3, 0.8, 0.9, 0.8) -- Cyan
    self.frame.progressBar = progressBar

    -- Percentage text
    local progressText = self.frame:CreateFontString(nil, "OVERLAY")
    progressText:SetPoint("CENTER", progressBg, "CENTER", 0, 0)
    progressText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    progressText:SetTextColor(1, 1, 1)
    progressText:SetText("0.00%")
    self.frame.progressText = progressText

    -- Collapse/Expand button (arrow)
    local toggleBtn = CreateFrame("Button", nil, self.frame)
    toggleBtn:SetWidth(30)
    toggleBtn:SetHeight(16)
    toggleBtn:SetPoint("TOPRIGHT", progressBg, "BOTTOMRIGHT", 5, -11)

    toggleBtn.arrow = toggleBtn:CreateTexture(nil, "ARTWORK")
    toggleBtn.arrow:SetWidth(20)
    toggleBtn.arrow:SetHeight(20)
    toggleBtn.arrow:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)
    toggleBtn.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")

    toggleBtn:SetScript("OnClick", function()
        TurtleDungeonTimer:getInstance():toggleBossList()
    end)
    self.frame.toggleButton = toggleBtn

    -- Add OnUpdate handler for automatic UI refresh
    self.frame:SetScript("OnUpdate", function()
        local timer = TurtleDungeonTimer:getInstance()
        if arg1 then -- arg1 = elapsed time
            -- Update UI every frame while timer is running
            if timer.isRunning then
                timer:updateUI()
            end
        end
    end)
end

-- ============================================================================
-- BOSS LIST (Collapsible with Scrollbar)
-- ============================================================================
function TurtleDungeonTimer:createBossList()
    -- Container for boss list
    local bossContainer = CreateFrame("Frame", nil, self.frame)
    bossContainer:SetPoint("TOPLEFT", self.frame.progressBg, "BOTTOMLEFT", 0, -6)
    bossContainer:SetWidth(218)
    bossContainer:SetHeight(1) -- Will expand
    bossContainer:Hide()       -- Hidden by default
    self.frame.bossContainer = bossContainer

    -- Will be populated when dungeon is selected
    self.frame.bossRows = {}
end

-- ============================================================================
-- BOSS LIST MANAGEMENT
-- ============================================================================
function TurtleDungeonTimer:toggleBossList()
    self.bossListExpanded = not self.bossListExpanded

    if self.bossListExpanded then
        self:expandBossList()
    else
        self:collapseBossList()
    end
end

function TurtleDungeonTimer:expandBossList()
    if not self.frame.bossContainer then return end

    local bossCount = table.getn(self.bossList)
    if bossCount == 0 then return end
    
    local rowHeight = 23
    local totalContentHeight = bossCount * rowHeight
    local maxVisibleItems = 8 -- Max bosses visible before scrollbar
    local maxVisibleHeight = maxVisibleItems * rowHeight

    -- Calculate visible height
    local visibleHeight = math.min(totalContentHeight, maxVisibleHeight)

    -- Expand frame
    self.frame:SetHeight(115 + visibleHeight + 10)
    self.frame.bossContainer:SetHeight(visibleHeight)

    self.frame.bossContainer:Show()

    -- Update arrow direction (up) and position
    self.frame.toggleButton.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
    self.frame.toggleButton:ClearAllPoints()
    self.frame.toggleButton:SetPoint("TOPRIGHT", self.frame.bossContainer, "BOTTOMRIGHT", 5, -8)

    -- Create/update boss rows
    self:updateBossRows()
end

function TurtleDungeonTimer:collapseBossList()
    if not self.frame.bossContainer then return end

    -- Collapse frame
    self.frame:SetHeight(115)
    self.frame.bossContainer:Hide()

    -- Update arrow direction (down) and position
    self.frame.toggleButton.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    self.frame.toggleButton:ClearAllPoints()
    self.frame.toggleButton:SetPoint("TOPRIGHT", self.frame.progressBg, "BOTTOMRIGHT", 5, -11)
end

function TurtleDungeonTimer:updateBossRows()
    if not self.frame or not self.frame.bossContainer then return end
    
    -- Don't update if list is collapsed
    if not self.bossListExpanded then return end
    
    local rowHeight = 23
    local bossCount = table.getn(self.bossList)
    
    if bossCount == 0 then return end
    
    -- Check if we need to create new rows
    local needsRecreate = false
    if not self.frame.bossRows or table.getn(self.frame.bossRows) ~= bossCount then
        needsRecreate = true
    else
        -- Check if first row is valid
        if not self.frame.bossRows[1] or not self.frame.bossRows[1].name or not self.frame.bossRows[1].name.SetText then
            needsRecreate = true
        end
    end
    
    -- Initialize bossRows if needed (only create once!)
    if needsRecreate then
        -- Clean up ALL children of bossContainer to remove old boss text
        if self.frame.bossContainer then
            local children = {self.frame.bossContainer:GetChildren()}
            for _, child in ipairs(children) do
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Also clean up font strings
            local regions = {self.frame.bossContainer:GetRegions()}
            for _, region in ipairs(regions) do
                if region.Hide then
                    region:Hide()
                end
            end
        end
        
        -- Clean up old rows table
        if self.frame.bossRows then
            for i = 1, table.getn(self.frame.bossRows) do
                self.frame.bossRows[i] = nil
            end
        end
        
        -- Create new rows directly in bossContainer
        self.frame.bossRows = {}
        for i = 1, bossCount do
            local boss = self.bossList[i]
            local bossName = type(boss) == "table" and boss.name or boss
            
            -- Boss name (left) - 3px more right (-2 -> 1)
            local nameText = self.frame.bossContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", self.frame.bossContainer, "TOPLEFT", 1, -(i-1) * rowHeight - 5)
            nameText:SetText(bossName)
            nameText:SetJustifyH("LEFT")
            nameText:SetTextColor(1, 1, 1)
            
            -- Kill time (right) - 30px more right (-35 -> -5)
            local timeText = self.frame.bossContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            timeText:SetPoint("TOPRIGHT", self.frame.bossContainer, "TOPRIGHT", -5, -(i-1) * rowHeight - 5)
            timeText:SetText("--:--")
            timeText:SetJustifyH("RIGHT")
            timeText:SetTextColor(0.5, 0.5, 0.5)
            
            self.frame.bossRows[i] = {name = nameText, time = timeText}
        end
    else
        -- Rows already exist with correct count - just show them!
        for i = 1, bossCount do
            if self.frame.bossRows[i] and self.frame.bossRows[i].name then
                local nameText = self.frame.bossRows[i].name
                local timeText = self.frame.bossRows[i].time
                
                if nameText and nameText.SetText then
                    nameText:Show()
                    timeText:Show()
                end
            end
        end
    end
    
    -- Update existing rows (colors and times only)
    for i = 1, bossCount do
        local boss = self.bossList[i]
        local defeated = type(boss) == "table" and boss.defeated or false
        local row = self.frame.bossRows[i]
        
        -- Skip if row doesn't exist or is incomplete
        if not row or not row.name or not row.time then
            -- Row is invalid, skip this one
        else
            -- Get kill time by searching through killTimes for matching boss index
            local killTime = nil
            for j = 1, table.getn(self.killTimes) do
                local killEntry = self.killTimes[j]
                if type(killEntry) == "table" and killEntry.index == i then
                    killTime = killEntry.time
                    break
                elseif type(killEntry) == "number" and j == i then
                    -- Legacy format support (if killTimes uses direct indexing)
                    killTime = killEntry
                    break
                end
            end
            
            if killTime or defeated then
                -- Boss defeated - green text
                row.name:SetTextColor(0.8, 1, 0.8)
                row.time:SetTextColor(0.8, 1, 0.8)
            
                if killTime then
                    local minutes = math.floor(killTime / 60)
                    local seconds = killTime - (minutes * 60)
                    row.time:SetText(string.format("%02d:%02d", minutes, seconds))
                else
                    row.time:SetText("✓")
                end
            else
                -- Boss alive - white text
                row.name:SetTextColor(1, 1, 1)
                row.time:SetTextColor(0.5, 0.5, 0.5)
                row.time:SetText("--:--")
            end
        end
    end
end

function TurtleDungeonTimer:createBossRow(index, bossName, rowHeight)
    -- Row container - DIRECTLY on bossContainer for testing
    local row = CreateFrame("Frame", nil, self.frame.bossContainer)
    row:SetWidth(365)            -- Full width
    row:SetHeight(rowHeight - 2) -- Small gap between rows

    -- Background with texture + vertex color
    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints(row)
    row.background:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    row.background:SetVertexColor(0.15, 0.15, 0.15, 0.9) -- Dark gray default

    -- Boss name (left)
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("LEFT", row, "LEFT", 10, 0)
    row.nameText:SetTextColor(1, 1, 1)
    row.nameText:SetText(bossName)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWidth(250)

    -- Kill time (right)
    row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.timeText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    row.timeText:SetTextColor(0.5, 0.5, 0.5)
    row.timeText:SetText("--:--")
    row.timeText:SetJustifyH("RIGHT")

    return row
end

-- ============================================================================
-- UPDATE FUNCTIONS
-- ============================================================================
function TurtleDungeonTimer:updateUI()
    if not self.frame then return end

    self:updateTimerDisplay()
    self:updateProgressBar()
    self:updateDeathCount()

    if self.bossListExpanded then
        self:updateBossRows()
    end
end

function TurtleDungeonTimer:updateTimerDisplay()
    if not self.frame or not self.frame.timerText then return end

    local timeStr = "00:00"
    if self.isRunning and self.startTime then
        local elapsed = GetTime() - self.startTime
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed - (minutes * 60)
        timeStr = string.format("%02d:%02d", minutes, seconds)
    elseif table.getn(self.killTimes) > 0 then
        local lastKillTime = self.killTimes[table.getn(self.killTimes)]
        if lastKillTime and lastKillTime.time then
            local minutes = math.floor(lastKillTime.time / 60)
            local seconds = lastKillTime.time - (minutes * 60)
            timeStr = string.format("%02d:%02d", minutes, seconds)
        end
    end

    self.frame.timerText:SetText(timeStr)
end

function TurtleDungeonTimer:updateProgressBar()
    if not self.frame or not self.frame.progressBar then return end

    local progress = TDTTrashCounter:getProgress()
    
    -- Cap bar width at 100%
    local cappedProgress = math.min(progress, 100)
    local width = 218 * (cappedProgress / 100)
    self.frame.progressBar:SetWidth(math.max(1, width))
    
    -- Show "100% (+x%)" if over 100%
    local textString
    if progress > 100 then
        local overage = progress - 100
        textString = string.format("100%% (+%.2f%%)", overage)
    else
        textString = string.format("%.2f%%", progress)
    end
    self.frame.progressText:SetText(textString)
    
    -- Color bar based on completion
    if progress >= 100 then
        self.frame.progressBar:SetTexture(0, 1, 0, 0.8)  -- Green
    else
        self.frame.progressBar:SetTexture(0.3, 0.8, 0.9, 0.8)  -- Cyan
    end
end

function TurtleDungeonTimer:updateDeathCount()
    if not self.frame or not self.frame.deathText then return end

    self.frame.deathText:SetText("" .. self.deathCount)
    
    -- Update World Buffs indicator
    self:updateWorldBuffsIndicator()
end

function TurtleDungeonTimer:updateWorldBuffsIndicator()
    if not self.frame or not self.frame.worldBuffsText or not self.frame.worldBuffsHover then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug WB Indicator] Frame or elements not found", 1, 0, 0)
        end
        return
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug WB Indicator] hasWorldBuffs: " .. tostring(self.hasWorldBuffs) .. ", runWithWorldBuffs: " .. tostring(self.runWithWorldBuffs) .. ", players: " .. tostring(self.worldBuffPlayers and next(self.worldBuffPlayers) and "yes" or "no"), 1, 1, 0)
    end
    
    -- Show indicator if:
    -- 1. Currently has world buffs (hasWorldBuffs AND players exist) OR
    -- 2. Run is active and permanently marked with WBs (runWithWorldBuffs)
    local shouldShow = (self.hasWorldBuffs and self.worldBuffPlayers and next(self.worldBuffPlayers)) or
                       (self.isRunning and self.runWithWorldBuffs)
    
    if shouldShow then
        self.frame.worldBuffsText:SetText(TDT_L("UI_WORLDBUFFS_DETECTED"))
        self.frame.worldBuffsText:Show()
        self.frame.worldBuffsHover:Show()
        
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug WB Indicator] Showing indicator", 0, 1, 0)
        end
    else
        self.frame.worldBuffsText:Hide()
        self.frame.worldBuffsHover:Hide()
        
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug WB Indicator] Hiding indicator", 1, 0.5, 0)
        end
    end
end

-- ============================================================================
-- START/STOP BUTTON UPDATE
-- ============================================================================

function TurtleDungeonTimer:updateStartButton()
    if not self.frame or not self.frame.startBtn then return end

    -- Check if player is group leader
    local isLeader = self:isGroupLeader()
    
    -- Show abort button if timer is running OR preparation is complete
    local shouldShowAbort = self.isRunning or 
                           (self.preparationState == "RESETTING" or 
                            self.preparationState == "READY" or 
                            self.preparationState == "COUNTDOWN")

    if shouldShowAbort then
        -- Show abort button
        self.frame.startBtn.text:SetText("Abort")
        if isLeader then
            self.frame.startBtn:SetBackdropColor(0.8, 0.4, 0.1, 1)  -- Orange for abort (leader)
        else
            self.frame.startBtn:SetBackdropColor(0.4, 0.4, 0.4, 1)  -- Gray for abort (member)
        end
    else
        -- Show start button
        self.frame.startBtn.text:SetText("Start")
        if isLeader then
            self.frame.startBtn:SetBackdropColor(0.8, 0.1, 0.1, 1)  -- Red for start (leader)
        else
            self.frame.startBtn:SetBackdropColor(0.4, 0.4, 0.4, 1)  -- Gray for start (member)
        end
    end
end

function TurtleDungeonTimer:toggleStartPause()
    if self.isRunning then
        self:pause()
    else
        self:start()
    end
end

-- ============================================================================
-- HISTORY MENU
-- ============================================================================
function TurtleDungeonTimer:showHistoryMenu(anchorFrame)
    -- Create dropdown if it doesn't exist
    if not self.historyDropdown then
        self:createHistoryDropdown()
    end

    if self.historyDropdown:IsShown() then
        self.historyDropdown:Hide()
    else
        self:populateHistoryDropdown()
        self.historyDropdown:ClearAllPoints()
        self.historyDropdown:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, 0)
        self.historyDropdown:Show()
    end
end

function TurtleDungeonTimer:createHistoryDropdown()
    local dropdown = CreateFrame("Frame", nil, self.frame)
    dropdown:SetWidth(280)
    dropdown:SetHeight(250)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropdown:SetFrameStrata("DIALOG")
    dropdown:Hide()

    -- Title
    local title = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", dropdown, "TOP", 0, -10)
    title:SetText("Run History")
    title:SetTextColor(1, 0.82, 0)

    -- Scroll frame for entries
    local scrollFrame = CreateFrame("ScrollFrame", nil, dropdown)
    scrollFrame:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 8, -30)
    scrollFrame:SetWidth(264)
    scrollFrame:SetHeight(210)
    dropdown.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(264)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    dropdown.scrollChild = scrollChild

    -- Enable scrolling
    scrollFrame:EnableMouseWheel()
    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollFrame:GetVerticalScroll()
        local max = scrollFrame:GetVerticalScrollRange()
        local step = 20
        if arg1 > 0 then
            scrollFrame:SetVerticalScroll(math.max(0, current - step))
        else
            scrollFrame:SetVerticalScroll(math.min(max, current + step))
        end
    end)

    dropdown.entries = {}
    self.historyDropdown = dropdown
end

function TurtleDungeonTimer:populateHistoryDropdown()
    if not self.historyDropdown then return end

    local dropdown = self.historyDropdown
    local scrollChild = dropdown.scrollChild

    -- Clear previous entries
    if dropdown.entries then
        for i = 1, table.getn(dropdown.entries) do
            dropdown.entries[i]:Hide()
            dropdown.entries[i] = nil
        end
    end
    dropdown.entries = {}

    local history = TurtleDungeonTimerDB.history
    if not history or table.getn(history) == 0 then
        local noData = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noData:SetPoint("CENTER", scrollChild, "TOP", 0, -50)
        noData:SetText("No history yet")
        noData:SetTextColor(0.5, 0.5, 0.5)
        table.insert(dropdown.entries, noData)
        return
    end

    local rowHeight = 20
    local numEntries = math.min(15, table.getn(history))
    scrollChild:SetHeight(numEntries * rowHeight)

    for i = 1, numEntries do
        local entry = history[i]
        local yOffset = -(i - 1) * rowHeight

        local entryBtn = CreateFrame("Button", nil, scrollChild)
        entryBtn:SetWidth(250)
        entryBtn:SetHeight(rowHeight - 2)
        entryBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)

        local entryText = entryBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        entryText:SetPoint("LEFT", entryBtn, "LEFT", 5, 0)
        entryText:SetJustifyH("LEFT")
        entryText:SetWidth(240)

        local timeStr = self:formatTime(entry.time)
        local statusStr = entry.completed == false and " [X]" or ""
        
        -- Add trash progress if available (already normalized)
        local trashStr = ""
        if entry.trashProgress and entry.trashProgress > 0 then
            trashStr = string.format(" [T: %.2f%%]", entry.trashProgress)
        end
        
        local text = string.format("%s - %s (%dd)%s%s", entry.dungeon or "?", timeStr, entry.deathCount or 0, trashStr, statusStr)
        if entry.date then
            text = entry.date .. " " .. text
        end
        entryText:SetText(text)

        if entry.completed == false then
            entryText:SetTextColor(1, 0.7, 0.3)
        else
            entryText:SetTextColor(1, 1, 1)
        end

        -- Capture entry for closure
        local capturedEntry = entry

        entryBtn:SetScript("OnEnter", function()
            this:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
            this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
        end)
        entryBtn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        entryBtn:SetScript("OnClick", function()
            TurtleDungeonTimer:getInstance():showHistoryDetails(capturedEntry)
            dropdown:Hide()
        end)

        table.insert(dropdown.entries, entryBtn)
    end
end

function TurtleDungeonTimer:showHistoryDetails(entry)
    if self.historyDetailFrame then
        self.historyDetailFrame:Hide()
        self.historyDetailFrame = nil
    end

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
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
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
    title:SetText((entry.dungeon or "?") .. " - " .. (entry.variant or "Default"))
    title:SetTextColor(1, 0.82, 0)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, detailFrame)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetPoint("TOPRIGHT", detailFrame, "TOPRIGHT", -10, -10)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(1, 0, 0)
    closeBtn:SetScript("OnClick", function() detailFrame:Hide() end)

    -- Info text
    local infoText = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    local timeStr = self:formatTime(entry.time or 0)
    local infoStr = string.format("Time: %s | %d", timeStr, entry.deathCount or 0)
    
    -- Add trash progress if available (already normalized)
    if entry.trashProgress and entry.trashProgress > 0 then
        infoStr = infoStr .. string.format(" | Trash: %.2f%%", entry.trashProgress)
    end
    
    infoText:SetText(infoStr)

    -- Boss kills list
    if entry.killTimes and table.getn(entry.killTimes) > 0 then
        local bossTitle = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bossTitle:SetPoint("TOPLEFT", detailFrame, "TOPLEFT", 20, -70)
        bossTitle:SetText("Boss Kills:")
        bossTitle:SetTextColor(1, 0.82, 0)

        -- Sort killTimes by index (boss list order) instead of kill order
        local sortedKills = {}
        for i = 1, table.getn(entry.killTimes) do
            table.insert(sortedKills, entry.killTimes[i])
        end
        table.sort(sortedKills, function(a, b)
            return (a.index or 0) < (b.index or 0)
        end)

        for i = 1, table.getn(sortedKills) do
            local kill = sortedKills[i]
            local killText = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            killText:SetPoint("TOPLEFT", bossTitle, "BOTTOMLEFT", 5, -(i - 1) * 18 - 5)
            killText:SetText(string.format("%d. %s - %s", i, kill.bossName or "?", self:formatTime(kill.time or 0)))
        end
    end

    -- Report Button (with dropdown)
    local reportBtn = CreateFrame("Button", nil, detailFrame, "GameMenuButtonTemplate")
    reportBtn:SetWidth(100)
    reportBtn:SetHeight(25)
    reportBtn:SetPoint("BOTTOMLEFT", detailFrame, "BOTTOMLEFT", 20, 15)
    reportBtn:SetText("REPORT")
    
    -- Create report dropdown
    local reportDropdown = CreateFrame("Frame", nil, detailFrame)
    reportDropdown:SetWidth(100)
    reportDropdown:SetHeight(90)
    reportDropdown:SetPoint("BOTTOM", reportBtn, "TOP", 0, 5)
    reportDropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    reportDropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    reportDropdown:SetFrameStrata("TOOLTIP")
    reportDropdown:Hide()
    
    -- Create dropdown options
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
        
        btn:SetScript("OnEnter", function()
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropCexportHistoryEntryolor(0.3, 0.3, 0.3, 0.8)
        end)
        btn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        
        -- Capture entry in local variable for closure
        local historyEntry = entry
        btn:SetScript("OnClick", function()
            TurtleDungeonTimer:sendHistoryReport(historyEntry, chatType)
            reportDropdown:Hide()
        end)
    end
    
    reportBtn:SetScript("OnClick", function()
        if reportDropdown:IsVisible() then
            reportDropdown:Hide()
        else
            reportDropdown:Show()
        end
    end)
    
    -- Export Button
    local exportBtn = CreateFrame("Button", nil, detailFrame, "GameMenuButtonTemplate")
    exportBtn:SetWidth(100)
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("LEFT", reportBtn, "RIGHT", 10, 0)
    exportBtn:SetText("EXPORT")
    
    -- Capture entry in local variable for closure
    local historyEntry = entry
    exportBtn:SetScript("OnClick", function()
        TurtleDungeonTimer:showHistoryExportDialog(historyEntry)
    end)

    detailFrame:Show()
end

-- ============================================================================
-- HISTORY REPORT & EXPORT FUNCTIONS
-- ============================================================================
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

function TurtleDungeonTimer:showHistoryExportDialog(entry)
    if not entry then return end
    
    -- Use unified export function from Export.lua
    local exportString = self:exportRunData(entry)
    
    if not exportString then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r No data to export.", 1, 0.5, 0)
        return
    end
    
    -- Create or show existing dialog
    if self.historyExportDialog then
        if self.historyExportDialog.editBox then
            self.historyExportDialog.editBox:SetText(exportString)
            self.historyExportDialog.editBox:HighlightText()
        end
        self.historyExportDialog:Show()
        return
    end
    
    -- Create export dialog
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(400)
    dialog:SetHeight(150)
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
    dialog:EnableMouse(true)
    self.historyExportDialog = dialog
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("Export Run Data")
    title:SetTextColor(1, 0.82, 0)
    
    local desc = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Copy the text to import it on the website.")
    desc:SetTextColor(0, 1, 0)
    
    -- ScrollFrame for export string
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog)
    scrollFrame:SetWidth(360)
    scrollFrame:SetHeight(50)
    scrollFrame:SetPoint("TOP", desc, "BOTTOM", 0, -10)
    
    -- Edit box for export string
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetWidth(350)
    editBox:SetHeight(50)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 10)
    editBox:SetTextColor(1, 1, 1)
    editBox:SetAutoFocus(false)
    editBox:SetText(exportString)
    editBox:HighlightText()
    editBox:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)
    editBox:SetScript("OnEditFocusGained", function()
        this:HighlightText()
    end)
    editBox:SetScript("OnTextChanged", function()
        scrollFrame:UpdateScrollChildRect()
    end)
    
    scrollFrame:SetScrollChild(editBox)
    scrollFrame:EnableMouseWheel()
    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if arg1 > 0 then
            scrollFrame:SetVerticalScroll(math.max(0, current - 20))
        else
            scrollFrame:SetVerticalScroll(math.min(maxScroll, current + 20))
        end
    end)
    
    dialog.editBox = editBox
    
    -- Close Button
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

-- ============================================================================
-- COMPATIBILITY - Keep existing functions for other parts of code
-- ============================================================================
function TurtleDungeonTimer:resetUI()
    self.deathCount = 0
    self.killTimes = {}

    -- Reset boss defeated states
    for i = 1, table.getn(self.bossList) do
        if type(self.bossList[i]) == "table" then
            self.bossList[i].defeated = false
        end
    end
    
    -- Force reset of boss rows (even if collapsed) to clear times
    if self.frame and self.frame.bossRows then
        for i = 1, table.getn(self.frame.bossRows) do
            local row = self.frame.bossRows[i]
            if row and row.time and row.time.SetText then
                row.time:SetText("--:--")
                row.time:SetTextColor(0.5, 0.5, 0.5)
            end
            if row and row.name and row.name.SetTextColor then
                row.name:SetTextColor(1, 1, 1)
            end
        end
    end

    self:updateUI()

    -- Don't collapse boss list on reset - keep it as user left it
end

function TurtleDungeonTimer:updateFrameSize()
    -- Called by other code - trigger boss list update if expanded
    if self.bossListExpanded then
        self:expandBossList()
    end
end

function TurtleDungeonTimer:updatePrepareButtonState()
    -- Update start button when group composition changes
    self:updateStartButton()
end
