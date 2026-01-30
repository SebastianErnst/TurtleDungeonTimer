-- ============================================================================
-- Turtle Dungeon Timer - Run Preparation System
-- ============================================================================

TurtleDungeonTimer.preparationState = nil
TurtleDungeonTimer.preparationChecks = {}
TurtleDungeonTimer.preparationButton = nil
TurtleDungeonTimer.countdownFrame = nil
TurtleDungeonTimer.countdownValue = 0
TurtleDungeonTimer.countdownTriggered = false
TurtleDungeonTimer.firstZoneEnter = nil

-- ============================================================================
-- PREPARATION STATE MACHINE
-- ============================================================================
-- States: nil, "CHECKING_ADDON", "CHECKING_VERSION", "CHECKING_ZONE", "RESETTING", "READY", "COUNTDOWN", "FAILED"

-- ============================================================================
-- TRASH DATA HELPERS
-- ============================================================================
function TurtleDungeonTimer:hasTrashData(dungeonKey, variantName)
    local dungeonData = self.DUNGEON_DATA[dungeonKey]
    if not dungeonData or not dungeonData.variants then
        return false
    end
    
    local variantData = dungeonData.variants[variantName]
    if not variantData then
        return false
    end
    
    return variantData.trashMobs ~= nil and variantData.totalTrashHP ~= nil
end

function TurtleDungeonTimer:hasAnyVariantWithTrash(dungeonKey)
    local dungeonData = self.DUNGEON_DATA[dungeonKey]
    if not dungeonData or not dungeonData.variants then
        return false
    end
    
    for variantName, _ in pairs(dungeonData.variants) do
        if self:hasTrashData(dungeonKey, variantName) then
            return true
        end
    end
    
    return false
end

function TurtleDungeonTimer:startPreparation()
    -- Check if player is group leader
    if not self:isGroupLeader() then
        -- No chat message needed - UI button already shows this restriction
        return
    end
    
    -- Show dungeon selection dialog first
    self:showPreparationDungeonSelector()
end

function TurtleDungeonTimer:showPreparationDungeonSelector()
    -- Create selection dialog
    if self.preparationDungeonDialog then
        self.preparationDungeonDialog:Hide()
        self.preparationDungeonDialog = nil
    end
    
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(300)
    dialog:SetHeight(400)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    dialog:SetBackdropColor(0, 0, 0, 0.95)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function() this:StartMoving() end)
    dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    self.preparationDungeonDialog = dialog
    
    -- Close button (X)
    local closeBtn = CreateFrame("Button", nil, dialog)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function() dialog:Hide() end)
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -20)
    title:SetText(TDT_L("UI_PREPARE_RUN_TITLE"))
    title:SetTextColor(1, 0.82, 0)
    
    -- Create scroll frame for dungeon list
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog)
    scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -60)
    scrollFrame:SetWidth(260)
    scrollFrame:SetHeight(280)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(260)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
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
    
    -- Build dungeon list
    local dungeonList = {}
    for dungeonName, dungeonData in pairs(self.DUNGEON_DATA) do
        local displayName = dungeonData.displayName or dungeonName
        local variantCount = 0
        if dungeonData.variants then
            for _ in pairs(dungeonData.variants) do
                variantCount = variantCount + 1
            end
        end
        -- Check if dungeon has any variant with trash data
        local hasTrash = self:hasAnyVariantWithTrash(dungeonName)
        
        table.insert(dungeonList, {
            key = dungeonName,
            displayName = displayName,
            variantCount = variantCount,
            hasTrash = hasTrash
        })
    end
    
    -- Sort by display name
    table.sort(dungeonList, function(a, b) return a.displayName < b.displayName end)
    
    -- Create buttons
    local buttonHeight = 25
    local numDungeons = table.getn(dungeonList)
    scrollChild:SetHeight(numDungeons * buttonHeight)
    
    for i = 1, numDungeons do
        local dungeon = dungeonList[i]
        local yOffset = -(i-1) * buttonHeight
        
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetWidth(240)
        btn:SetHeight(buttonHeight - 2)
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("LEFT", btn, "LEFT", 10, 0)
        btnText:SetJustifyH("LEFT")
        
        -- Check if dungeon has trash data
        local hasTrash = dungeon.hasTrash
        local displayText = dungeon.displayName
        
        if not hasTrash then
            -- Strikethrough text for dungeons without trash data
            displayText = "|cff666666" .. dungeon.displayName .. "|r"
            btnText:SetTextColor(0.4, 0.4, 0.4)  -- Gray out
        else
            btnText:SetTextColor(1, 1, 1)  -- Normal white
        end
        
        btnText:SetText(displayText)
        
        -- Show arrow if multiple variants
        if dungeon.variantCount > 1 then
            local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            arrow:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
            arrow:SetText(">")
            if not hasTrash then
                arrow:SetTextColor(0.4, 0.4, 0.4)  -- Gray out arrow too
            end
        end
        
        -- Capture dungeon name for closure
        local dungeonKey = dungeon.key
        local variantCount = dungeon.variantCount
        local dungeonHasTrash = hasTrash
        
        btn:SetScript("OnEnter", function()
            if not dungeonHasTrash then
                -- Don't allow interaction with disabled dungeons
                return
            end
            this:SetBackdropColor(0.3, 0.3, 0.3, 0.9)
            
            -- Close any existing variant menu first
            local addon = TurtleDungeonTimer:getInstance()
            if addon.preparationVariantMenu then
                addon.preparationVariantMenu:Hide()
                addon.preparationVariantMenu = nil
            end
            
            -- Show variant submenu if multiple variants
            if variantCount > 1 then
                addon:showPreparationVariantMenu(this, dungeonKey)
            end
        end)
        btn:SetScript("OnLeave", function()
            this:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        end)
        btn:SetScript("OnClick", function()
            if not dungeonHasTrash then
                -- Don't allow selection of disabled dungeons
                return
            end
            if variantCount == 1 then
                -- Only one variant, select directly
                local variants = TurtleDungeonTimer.DUNGEON_DATA[dungeonKey].variants
                for variantName, _ in pairs(variants) do
                    TurtleDungeonTimer:getInstance():onPreparationDungeonVariantSelected(dungeonKey, variantName)
                    break
                end
            end
            -- If multiple variants, submenu is already shown on hover
        end)
    end
    
    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    cancelBtn:SetWidth(100)
    cancelBtn:SetHeight(30)
    cancelBtn:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 20)
    cancelBtn:SetText(TDT_L("UI_CANCEL_BUTTON"))
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:showPreparationVariantMenu(parentBtn, dungeonKey)
    -- Close existing variant menu
    if self.preparationVariantMenu then
        self.preparationVariantMenu:Hide()
        self.preparationVariantMenu = nil
    end
    
    local dungeonData = self.DUNGEON_DATA[dungeonKey]
    if not dungeonData or not dungeonData.variants then
        return
    end
    
    -- Build variant list
    local variantList = {}
    for variantName, _ in pairs(dungeonData.variants) do
        table.insert(variantList, variantName)
    end
    
    table.sort(variantList)
    
    local numVariants = table.getn(variantList)
    local btnHeight = 25
    local menuHeight = numVariants * btnHeight + 8
    
    local submenu = CreateFrame("Frame", nil, self.preparationDungeonDialog)
    submenu:SetWidth(150)
    submenu:SetHeight(menuHeight)
    submenu:SetPoint("TOPLEFT", parentBtn, "TOPRIGHT", 5, 0)
    submenu:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    submenu:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    submenu:SetFrameStrata("FULLSCREEN_DIALOG")
    submenu:Show()
    
    self.preparationVariantMenu = submenu
    
    -- Create buttons for each variant
    for i = 1, numVariants do
        local variantName = variantList[i]
        
        -- Check if this variant has trash data
        local hasTrash = self:hasTrashData(dungeonKey, variantName)
        
        local btn = CreateFrame("Button", nil, submenu)
        btn:SetWidth(140)
        btn:SetHeight(btnHeight - 2)
        btn:SetPoint("TOP", submenu, "TOP", 0, -4 - (i-1) * btnHeight)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        text:SetJustifyH("LEFT")
        
        if not hasTrash then
            -- Strikethrough and gray out variants without trash
            text:SetText("|cff666666" .. variantName .. "|r")
            text:SetTextColor(0.4, 0.4, 0.4)
        else
            text:SetText(variantName)
            text:SetTextColor(1, 1, 1)
        end
        
        -- Capture for closure
        local variantHasTrash = hasTrash
        local capturedVariantName = variantName
        
        btn:SetScript("OnEnter", function()
            if not variantHasTrash then
                -- Don't highlight disabled variants
                return
            end
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropColor(0.4, 0.4, 0.4, 0.8)
        end)
        
        btn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        
        btn:SetScript("OnClick", function()
            if not variantHasTrash then
                -- Don't allow selection of disabled variants
                return
            end
            TurtleDungeonTimer:getInstance():onPreparationDungeonVariantSelected(dungeonKey, capturedVariantName)
        end)
    end
end

function TurtleDungeonTimer:onPreparationDungeonVariantSelected(dungeonKey, variantName)
    -- Hide variant menu
    if self.preparationVariantMenu then
        self.preparationVariantMenu:Hide()
        self.preparationVariantMenu = nil
    end
    
    -- Hide selection dialog
    if self.preparationDungeonDialog then
        self.preparationDungeonDialog:Hide()
        self.preparationDungeonDialog = nil
    end
    
    -- Store dungeon + variant selection
    self.pendingDungeonSelection = dungeonKey
    self.pendingVariantSelection = variantName
    
    -- Show World Buff confirmation dialog
    local foundBuffs = self:scanGroupForWorldBuffs()
    self:showWorldBuffConfirmationDialog(foundBuffs)
end

function TurtleDungeonTimer:showWorldBuffConfirmationDialog(foundBuffs)
    -- Create confirmation dialog
    if self.worldBuffConfirmDialog then
        self.worldBuffConfirmDialog:Hide()
        self.worldBuffConfirmDialog = nil
    end
    
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(350)
    dialog:SetHeight(500)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    dialog:SetBackdropColor(0, 0, 0, 0.95)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    dialog:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    self.worldBuffConfirmDialog = dialog
    
    -- Close button (X)
    local closeBtn = CreateFrame("Button", nil, dialog)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function()
        dialog:Hide()
        -- Clear pending selection
        TurtleDungeonTimer:getInstance().pendingDungeonSelection = nil
        TurtleDungeonTimer:getInstance().pendingVariantSelection = nil
    end)
    
    -- Title (was question before)
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -30)
    title:SetText(TDT_L("UI_WORLDBUFF_CONFIRM_QUESTION"))
    title:SetTextColor(1, 0.82, 0)
    
    local yOffset = -60
    
    -- Only show "Players with World Buffs" section if buffs are found
    if foundBuffs and next(foundBuffs) then
        local playersTitle = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playersTitle:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
        playersTitle:SetText(TDT_L("UI_WORLDBUFF_PLAYERS_TITLE"))
        playersTitle:SetTextColor(0.2, 1, 0.2)
        
        yOffset = yOffset - 20
        for playerName, buffName in pairs(foundBuffs) do
            local playerText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            playerText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 30, yOffset)
            playerText:SetText("  " .. playerName .. ": " .. buffName)
            playerText:SetTextColor(1, 1, 0)
            yOffset = yOffset - 15
        end
        yOffset = yOffset - 10
    end
    
    -- World Buffs list section
    local buffListTitle = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffListTitle:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
    buffListTitle:SetText(TDT_L("UI_WORLDBUFF_LIST_TITLE"))
    buffListTitle:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 20
    -- Get list of tracked buffs from WorldBuffs.lua
    local trackedBuffs = {
        "Rallying Cry of the Dragonslayer",
        "Spirit of Zandalar",
        "Warchief's Blessing",
        "Songflower Serenade",
        "Fengus' Ferocity",
        "Mol'dar's Moxie",
        "Slip'kik's Savvy"
    }
    
    for _, buffName in ipairs(trackedBuffs) do
        local buffText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        buffText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 30, yOffset)
        buffText:SetText("  • " .. buffName)
        buffText:SetTextColor(0.7, 0.7, 0.7)
        yOffset = yOffset - 15
    end
    
    -- Add tracking info section
    yOffset = yOffset - 10
    local infoText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
    infoText:SetWidth(310)
    infoText:SetText(TDT_L("UI_WORLDBUFF_TRACKING_INFO"))
    infoText:SetTextColor(1, 1, 0.5)
    infoText:SetJustifyH("LEFT")
    -- Set a reasonable height estimate instead of using GetStringHeight()
    infoText:SetHeight(40)
    yOffset = yOffset - 50
    
    -- Add removal warning section
    local removalText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    removalText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
    removalText:SetWidth(310)
    removalText:SetText(TDT_L("UI_WORLDBUFF_REMOVAL_INFO"))
    removalText:SetTextColor(1, 0.5, 0.5)
    removalText:SetJustifyH("LEFT")
    removalText:SetHeight(30)
    yOffset = yOffset - 40
    
    -- With World Buffs button (green)
    local withBtn = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    withBtn:SetWidth(140)
    withBtn:SetHeight(30)
    withBtn:SetPoint("BOTTOM", dialog, "BOTTOM", -75, 20)
    withBtn:SetText(TDT_L("UI_WITH_WORLDBUFFS"))
    withBtn:SetScript("OnClick", function()
        local timer = TurtleDungeonTimer:getInstance()
        timer.runWithWorldBuffs = true
        dialog:Hide()
        timer:beginPreparationChecks()
    end)
    
    -- Without World Buffs button (red)
    local withoutBtn = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    withoutBtn:SetWidth(140)
    withoutBtn:SetHeight(30)
    withoutBtn:SetPoint("BOTTOM", dialog, "BOTTOM", 75, 20)
    withoutBtn:SetText(TDT_L("UI_WITHOUT_WORLDBUFFS"))
    withoutBtn:SetScript("OnClick", function()
        local timer = TurtleDungeonTimer:getInstance()
        timer.runWithWorldBuffs = false
        dialog:Hide()
        timer:beginPreparationChecks()
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:beginPreparationChecks()
    if not self.pendingDungeonSelection then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("PREP_NO_DUNGEON_SELECTED"), 1, 0, 0)
        return
    end
    
    self.preparationState = "CHECKING_ADDON"
    -- Don't clear preparationChecks if we already have version data from login
    -- This fixes the version check issue where it shows mismatches at login
    if not self.preparationChecks then
        self.preparationChecks = {}
    end
    self.countdownTriggered = false
    self.firstZoneEnter = nil
    
    -- Get display name for the pending dungeon
    local dungeonData = self.DUNGEON_DATA[self.pendingDungeonSelection]
    local dungeonDisplayName = dungeonData and dungeonData.name or self.pendingDungeonSelection
    
    -- No output - silent start
    
    -- Request addon check from all group members
    self:broadcastPrepareStart()
end

function TurtleDungeonTimer:isGroupLeader()
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name == UnitName("player") and rank == 2 then
                return true
            end
        end
        return false
    elseif GetNumPartyMembers() > 0 then
        -- In 1.12, IsPartyLeader() returns nil or 1
        local isLeader = IsPartyLeader()
        return isLeader == 1 or isLeader == true
    else
        return true -- Solo
    end
end

function TurtleDungeonTimer:checkAddonPresence()
    -- Build list of all group members
    local allMembers = {}
    local withAddon = {}
    local withoutAddon = {}
    
    -- Add self
    allMembers[UnitName("player")] = true
    withAddon[UnitName("player")] = true
    
    -- Add party/raid members
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name then
                allMembers[name] = true
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                allMembers[name] = true
            end
        end
    end
    
    -- Check who has addon
    for playerName, _ in pairs(self.playersWithAddon) do
        withAddon[playerName] = true
    end
    
    -- Find who doesn't have addon
    for playerName, _ in pairs(allMembers) do
        if not withAddon[playerName] then
            withoutAddon[playerName] = true
        end
    end
    
    -- Display results - only show who doesn't have addon (errors only)
    local missingCount = 0
    for playerName, _ in pairs(withoutAddon) do
        DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. playerName .. " |cffff0000" .. TDT_L("PREP_MISSING") .. "|r", 1, 0, 0)
        missingCount = missingCount + 1
    end
    
    if missingCount > 0 then
        self:failPreparation(TDT_L("PREP_NOT_ALL_HAVE_ADDON"))
        return false
    end
    
    -- Success - no output needed
    return true
end

function TurtleDungeonTimer:checkVersionMatch()
    -- Check if all versions match (using full ADDON_VERSION: major.minor.patch-suffix)
    local myVersion = self.ADDON_VERSION
    local allMatch = true
    local versionMismatches = {}
    
    -- Check all players - only show mismatches
    for player, version in pairs(self.preparationChecks) do
        if version ~= myVersion then
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. player .. " (v" .. version .. ") |cffff0000" .. string.format(TDT_L("PREP_EXPECTED_VERSION"), myVersion) .. "|r", 1, 0, 0)
            allMatch = false
            table.insert(versionMismatches, player)
        end
    end
    
    if not allMatch then
        self:failPreparation(TDT_L("PREP_VERSION_MISMATCH"))
        return false
    end
    
    -- Success - no output needed
    return true
end

function TurtleDungeonTimer:executeReset()
    -- Listen for system messages
    if not self.resetCheckFrame then
        self.resetCheckFrame = CreateFrame("Frame")
        self.resetCheckFrame:RegisterEvent("CHAT_MSG_SYSTEM")
        self.resetCheckFrame:SetScript("OnEvent", function()
            TurtleDungeonTimer:getInstance():onResetSystemMessage(arg1)
        end)
    end
    
    -- ⚠️ TESTING MODE - Skip actual reset
    ResetInstances()
    
    -- Wait a moment for system message (or just simulate success)
    self:scheduleTimer(function()
        -- If we get here without error, reset was successful
        if self.preparationState == "RESETTING" then
            self:onResetSuccess()
        end
    end, 0.5, false)
end

function TurtleDungeonTimer:onResetSystemMessage(msg)
    if self.preparationState ~= "RESETTING" then
        return
    end
    
    -- Check for "Cannot reset" message
    if string.find(msg, "Cannot reset") and string.find(msg, "There are players still inside") then
        self:failPreparation(TDT_L("PREP_INSTANCE_RESET_FAILED_PLAYERS_INSIDE"))
    end
end

function TurtleDungeonTimer:onResetSuccess()
    -- Success - no output needed
    
    self.preparationState = "READY"
    
    -- Update button to show "Abort" since preparation is now ready
    self:updateStartButton()
    
    -- Show ready message for leader
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_RUN_READY_MSG"), 0, 1, 0)
    
    -- Broadcast ready state to all
    self:sendSyncMessage("PREPARE_READY")
    
    -- Register zone change event for countdown
    if not self.prepFrame then
        self.prepFrame = CreateFrame("Frame")
        self.prepFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self.prepFrame:SetScript("OnEvent", function()
            TurtleDungeonTimer:getInstance():onZoneChanged()
        end)
    end
end

-- ============================================================================
-- READY CHECK SYSTEM (Custom implementation, not WoW's built-in)
-- ============================================================================
TurtleDungeonTimer.readyCheckResponses = {}
TurtleDungeonTimer.readyCheckStarted = false

function TurtleDungeonTimer:startReadyCheck()
    self.preparationState = "READY_CHECK"
    self.readyCheckResponses = {}
    self.readyCheckStarted = GetTime()
    
    -- Broadcast ready check request with dungeon name to all group members
    local dungeonName = ""
    if self.pendingDungeonSelection then
        -- Use pending dungeon selection (not yet set as selectedDungeon)
        dungeonName = self.pendingDungeonSelection
    end
    -- Ensure dungeonName is never nil
    dungeonName = dungeonName or ""
    
    -- Add World Buff info to sync message (format: "dungeonName;wbFlag")
    local wbFlag = "0" -- Default: no World Buff info
    if self.runWithWorldBuffs ~= nil then
        wbFlag = self.runWithWorldBuffs and "1" or "2" -- 1 = with WBs, 2 = without WBs
    end
    local syncData = dungeonName .. ";" .. wbFlag
    
    self:sendSyncMessage("READY_CHECK_START", syncData)
    
    -- Auto-respond for self (leader) - leader is always ready
    self.readyCheckResponses[UnitName("player")] = true
    
    -- DON'T show ready check prompt for leader - they started it, so they're ready
    -- Check if all members have already responded (solo case)
    self:checkReadyCheckComplete()
    
    -- Timeout after 30 seconds
    self:scheduleTimer(function()
        if self.preparationState == "READY_CHECK" then
            self:finishReadyCheck()
        end
    end, 30, false)
end

-- Show the ready check prompt to a player
-- dungeonName: optional parameter with dungeon name (from sync message)
-- leaderName: name of the player who started the ready check
function TurtleDungeonTimer:showReadyCheckPrompt(dungeonName, leaderName)
    -- Close existing ready check frame
    if self.readyCheckPromptFrame then
        self.readyCheckPromptFrame:Hide()
        self.readyCheckPromptFrame = nil
    end
    
    -- Mark leader as ready automatically (they started the check)
    if leaderName then
        self.readyCheckResponses[leaderName] = true
    end
    
    -- Create custom ready check frame
    local frame = CreateFrame("Frame", "TDTReadyCheckFrame", UIParent)
    frame:SetWidth(420)
    frame:SetHeight(320)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Title: "Ready Check"
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetTextColor(1, 0.82, 0)
    title:SetText(TDT_L("UI_READY_CHECK_TITLE"))
    
    -- ============================================================================
    -- PLAYER STATUS CIRCLES (Top section)
    -- ============================================================================
    
    -- Collect all group members with leader always first
    local groupMembers = {}
    local playerName = UnitName("player")
    local isLeader = self:isGroupLeader()
    
    -- Add leader first (if leader is player, add player first)
    if isLeader and playerName then
        table.insert(groupMembers, playerName)
    end
    
    -- Add all other group members
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name = UnitName("raid" .. i)
            if name and name ~= playerName then
                table.insert(groupMembers, name)
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name and (not isLeader or name ~= playerName) then
                table.insert(groupMembers, name)
            end
        end
    end
    
    -- If player is not leader, add player to list (non-leaders see their own ready check)
    if not isLeader and playerName then
        table.insert(groupMembers, playerName)
    end
    
    local numMembers = table.getn(groupMembers)
    local circleSize = 60
    local spacing = 10
    local totalWidth = numMembers * circleSize + (numMembers - 1) * spacing
    local startX = -totalWidth / 2 + circleSize / 2
    
    frame.playerCircles = {}
    
    for i, playerName in ipairs(groupMembers) do
        local xOffset = startX + (i - 1) * (circleSize + spacing)
        
        -- Portrait frame
        local circle = CreateFrame("Frame", nil, frame)
        circle:SetWidth(circleSize)
        circle:SetHeight(circleSize)
        circle:SetPoint("TOP", frame, "TOP", xOffset, -50)
        
        -- Portrait texture
        local icon = circle:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(circle)
        
        -- Get class info for this player
        local unitId = nil
        if playerName == UnitName("player") then
            unitId = "player"
        elseif GetNumRaidMembers() > 0 then
            for j = 1, GetNumRaidMembers() do
                if UnitName("raid" .. j) == playerName then
                    unitId = "raid" .. j
                    break
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for j = 1, GetNumPartyMembers() do
                if UnitName("party" .. j) == playerName then
                    unitId = "party" .. j
                    break
                end
            end
        end
        
        if unitId then
            SetPortraitTexture(icon, unitId)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        
        circle.icon = icon
        
        -- Status indicator circle (below portrait, overlapping bottom)
        local statusCircleSize = 68
        local statusCircle = CreateFrame("Frame", nil, frame)
        statusCircle:SetWidth(statusCircleSize)
        statusCircle:SetHeight(statusCircleSize)
        statusCircle:SetPoint("TOP", circle, "BOTTOM", 10, 10)
        statusCircle:SetFrameLevel(circle:GetFrameLevel() + 1)
        
        -- Status icon inside circle (like minimap button - FIRST, so it's behind border)
        local statusIcon = statusCircle:CreateTexture(nil, "BACKGROUND")
        statusIcon:SetWidth(statusCircleSize - 43)
        statusIcon:SetHeight(statusCircleSize - 43)
        statusIcon:SetPoint("CENTER", statusCircle, "CENTER", -14, 15)
        statusIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        statusIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop edges
        circle.statusIcon = statusIcon
        
        -- Colored border ring (AFTER icon, so it overlays)
        local border = statusCircle:CreateTexture(nil, "OVERLAY")
        border:SetPoint("CENTER", statusCircle, "CENTER", 0, 0)
        border:SetWidth(statusCircleSize)
        border:SetHeight(statusCircleSize)
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        border:SetVertexColor(1, 1, 0, 1) -- Yellow = pending
        circle.statusBg = border
        
        -- Name text below portrait
        local nameText = circle:CreateFontString(nil, "OVERLAY")
        nameText:SetPoint("TOP", circle, "BOTTOM", 0, -30)
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        nameText:SetTextColor(1, 1, 1)
        nameText:SetText(playerName)
        
        frame.playerCircles[playerName] = circle
    end
    
    -- Update initial status (leader should be green immediately)
    self:updateReadyCheckCircles(frame)
    
    -- ============================================================================
    -- QUESTION SECTION (Middle)
    -- ============================================================================
    
    local questionY = -170 - (numMembers > 3 and 20 or 0) -- Adjust if many players
    
    -- Question text with dungeon name
    local questionText = frame:CreateFontString(nil, "OVERLAY")
    questionText:SetPoint("TOP", frame, "TOP", 0, questionY)
    questionText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    questionText:SetTextColor(1, 1, 1)
    questionText:SetWidth(380)
    
    -- Use provided dungeonName parameter (from leader) or fallback to own selection
    local dungeonDisplayName = ""
    if dungeonName and dungeonName ~= "" then
        dungeonDisplayName = dungeonName
    elseif self.selectedDungeon then
        local dungeonData = self.DUNGEON_DATA[self.selectedDungeon]
        dungeonDisplayName = dungeonData and dungeonData.name or self.selectedDungeon
    end
    
    if dungeonDisplayName ~= "" then
        questionText:SetText(string.format(TDT_L("UI_READY_CHECK_DUNGEON"), dungeonDisplayName))
    else
        questionText:SetText(TDT_L("UI_READY_CHECK_QUESTION"))
    end
    
    -- ============================================================================
    -- BUTTONS (Bottom)
    -- ============================================================================
    
    local buttonY = 80
    
    -- Yes button (left of center)
    local yesBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    yesBtn:SetWidth(140)
    yesBtn:SetHeight(35)
    yesBtn:SetPoint("RIGHT", frame, "BOTTOM", -10, buttonY)
    yesBtn:SetText(TDT_L("YES"))
    yesBtn:SetScript("OnClick", function()
        local tdt = TurtleDungeonTimer:getInstance()
        tdt:respondToReadyCheck(true)
        -- Don't hide frame - keep it open to show responses
    end)
    
    -- No button (right of center)
    local noBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    noBtn:SetWidth(140)
    noBtn:SetHeight(35)
    noBtn:SetPoint("LEFT", frame, "BOTTOM", 10, buttonY)
    noBtn:SetText(TDT_L("UI_NO_BUTTON"))
    noBtn:SetScript("OnClick", function()
        local tdt = TurtleDungeonTimer:getInstance()
        tdt:respondToReadyCheck(false)
        -- Don't hide frame - keep it open to show responses
    end)
    
    -- Store button references for hiding after response
    frame.yesButton = yesBtn
    frame.noButton = noBtn
    
    -- ============================================================================
    -- TIMER BAR (Bottom)
    -- ============================================================================
    
    -- Progress bar background
    local progressBg = frame:CreateTexture(nil, "BACKGROUND")
    progressBg:SetPoint("BOTTOM", frame, "BOTTOM", 0, 100)
    progressBg:SetWidth(380)
    progressBg:SetHeight(18)
    progressBg:SetTexture(0, 0, 0, 0.8)
    
    -- Progress bar
    local progressBar = frame:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
    progressBar:SetWidth(380)
    progressBar:SetHeight(18)
    progressBar:SetTexture(0, 0.8, 0, 0.6)
    frame.progressBar = progressBar
    
    -- Timer text (above buttons)
    local timerText = frame:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("BOTTOM", yesBtn, "TOP", 0, 10)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    timerText:SetTextColor(1, 1, 1)
    timerText:SetText("30s")
    frame.timerText = timerText
    
    -- ============================================================================
    -- UPDATE LOGIC
    -- ============================================================================
    
    -- Update timer and check for completion
    frame.startTime = GetTime()
    frame.duration = 30
    frame.hasResponded = false
    
    frame:SetScript("OnUpdate", function()
        local tdt = TurtleDungeonTimer:getInstance()
        local elapsed = GetTime() - this.startTime
        local remaining = this.duration - elapsed
        
        if remaining <= 0 then
            -- Timeout - auto-close
            if not this.hasResponded then
                tdt:respondToReadyCheck(false)
            end
            this:Hide()
            return
        end
        
        -- Update progress bar
        local progress = remaining / this.duration
        this.progressBar:SetWidth(380 * progress)
        
        -- Update timer text
        this.timerText:SetText(math.floor(remaining) .. "s")
        
        -- Change color based on remaining time
        if remaining < 10 then
            this.progressBar:SetTexture(0.8, 0, 0, 0.6) -- Red
        elseif remaining < 20 then
            this.progressBar:SetTexture(0.8, 0.8, 0, 0.6) -- Yellow
        end
        
        -- Update player status circles
        tdt:updateReadyCheckCircles(this)
        
        -- Check if all have responded (for all players, not just leader)
        local allResponded = true
        local expectedCount = tdt:getGroupSize()
        local responseCount = 0
        
        for playerName, _ in pairs(this.playerCircles) do
            if tdt.readyCheckResponses[playerName] ~= nil then
                responseCount = responseCount + 1
            else
                allResponded = false
            end
        end
        
        -- Alternative check: use expectedCount
        if responseCount >= expectedCount then
            allResponded = true
        end
        
        if allResponded then
            -- All responded - close after 2 seconds
            if not this.closeTimer then
                this.closeTimer = GetTime()
            elseif GetTime() - this.closeTimer > 2 then
                this:Hide()
                return
            end
        else
            -- Reset close timer if not all responded yet
            this.closeTimer = nil
        end
    end)
    
    frame:Show()
    self.readyCheckPromptFrame = frame
end

-- Update visual status of player circles
function TurtleDungeonTimer:updateReadyCheckCircles(frame)
    if not frame or not frame.playerCircles then
        return
    end
    
    for playerName, circle in pairs(frame.playerCircles) do
        local response = self.readyCheckResponses[playerName]
        
        if response == true then
            -- Ready: Green ring with melee damage icon (checkmark-like)
            circle.statusBg:SetVertexColor(0, 1, 0, 1)
            circle.statusIcon:SetTexture("Interface\\Icons\\Ability_MeleeDamage")
        elseif response == false then
            -- Not Ready: Red ring with dual wield icon (crossed swords)
            circle.statusBg:SetVertexColor(1, 0, 0, 1)
            circle.statusIcon:SetTexture("Interface\\Icons\\Ability_DualWield")
        else
            -- Pending: Yellow ring with question mark
            circle.statusBg:SetVertexColor(1, 1, 0, 1)
            circle.statusIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        circle.statusIcon:Show()
    end
end

function TurtleDungeonTimer:respondToReadyCheck(isReady)
    -- Send response to leader
    self:sendSyncMessage("READY_CHECK_RESPONSE", isReady and "1" or "0")
    
    -- Update local state for self
    self.readyCheckResponses[UnitName("player")] = isReady
    
    -- Mark frame as responded (prevent auto-decline on timeout)
    if self.readyCheckPromptFrame then
        self.readyCheckPromptFrame.hasResponded = true
        
        -- Hide buttons after response
        if self.readyCheckPromptFrame.yesButton then
            self.readyCheckPromptFrame.yesButton:Hide()
        end
        if self.readyCheckPromptFrame.noButton then
            self.readyCheckPromptFrame.noButton:Hide()
        end
        
        -- Update circles immediately to show own response
        self:updateReadyCheckCircles(self.readyCheckPromptFrame)
    end
    
    -- Check if all members have responded (if leader)
    if self:isGroupLeader() then
        self:checkReadyCheckComplete()
    end
end

function TurtleDungeonTimer:onReadyCheckResponse(sender, isReady)
    if self.preparationState ~= "READY_CHECK" then
        return
    end
    
    self.readyCheckResponses[sender] = (isReady == "1")
    
    -- Check if all members have responded
    self:checkReadyCheckComplete()
end

function TurtleDungeonTimer:checkReadyCheckComplete()
    if self.preparationState ~= "READY_CHECK" then
        return
    end
    
    -- Count expected responses
    local expectedCount = self:getGroupSize()
    local responseCount = 0
    
    -- Count received responses
    for player, response in pairs(self.readyCheckResponses) do
        if response ~= nil then
            responseCount = responseCount + 1
        end
    end
    
    -- If all have responded, finish immediately
    if responseCount >= expectedCount then
        -- No output - silent
        self:finishReadyCheck()
    end
end

function TurtleDungeonTimer:finishReadyCheck()
    if self.preparationState ~= "READY_CHECK" then
        return
    end
    
    -- Only leader should see detailed status, members just see the result
    local isLeader = self:isGroupLeader()
    
    -- Only show errors, not successful ready checks
    local allReady = true
    local notReadyPlayers = {}
    
    -- Check self
    local selfReady = self.readyCheckResponses[UnitName("player")]
    if selfReady == false then
        if isLeader then
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. UnitName("player") .. " (Not Ready)", 1, 0, 0)
        end
        allReady = false
        table.insert(notReadyPlayers, UnitName("player"))
    elseif selfReady ~= true then
        if isLeader then
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff9900?|r " .. UnitName("player") .. " " .. TDT_L("PREP_NO_RESPONSE"), 1, 0.6, 0)
        end
        allReady = false
        table.insert(notReadyPlayers, UnitName("player"))
    end
    
    -- Check group members
    for player, _ in pairs(self.playersWithAddon) do
        local ready = self.readyCheckResponses[player]
        if ready == false then
            if isLeader then
                DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. player .. " (Not Ready)", 1, 0, 0)
            end
            allReady = false
            table.insert(notReadyPlayers, player)
        elseif ready ~= true then
            if isLeader then
                DEFAULT_CHAT_FRAME:AddMessage("  |cffff9900?|r " .. player .. " " .. TDT_L("PREP_NO_RESPONSE"), 1, 0.6, 0)
            end
            allReady = false
            table.insert(notReadyPlayers, player)
        end
    end
    
    if allReady then
        -- Success - no output
        
        -- Remove world buffs if "Without World Buffs" was selected
        if not self.runWithWorldBuffs then
            self:removeAllWorldBuffs()
        end
        
        -- NOW set the dungeon for everyone (leader + all group members)
        if self:isGroupLeader() and self.pendingDungeonSelection then
            local dungeonKey = self.pendingDungeonSelection
            local variantKey = self.pendingVariantSelection
            
            -- Broadcast dungeon selection to all group members
            local dungeonData = dungeonKey
            if variantKey then
                dungeonData = dungeonKey .. ";" .. variantKey
            end
            self:sendSyncMessage("SET_DUNGEON", dungeonData)
            
            -- Set dungeon locally for leader
            self:selectDungeon(dungeonKey)
            if variantKey then
                self:selectVariant(variantKey)
            end
        end
        
        -- Reset current run directly and broadcast to group (silent)
        
        -- Broadcast reset to all group members
        self:sendSyncMessage("RESET_EXECUTE")
        
        -- Perform reset locally
        self:performResetDirect()
        
        -- Continue with instance reset
        self.preparationState = "RESETTING"
        
        -- Update button to show "Abort" now that run is prepared and resetting
        self:updateStartButton()
        
        self:executeReset()
    else
        -- Preparation failed - build list of not ready players
        self.preparationState = "FAILED"
        if isLeader then
            local playerList = table.concat(notReadyPlayers, ", ")
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r Ready check failed - Players not ready: " .. playerList, 1, 0, 0)
            -- Only broadcast to group, don't show local message again
            self:broadcastPreparationFailed("Players not ready: " .. playerList)
        end
    end
end

function TurtleDungeonTimer:failPreparation(reason)
    self.preparationState = "FAILED"
    
    -- Check if we're the leader
    local isLeader = false
    if GetNumPartyMembers() > 0 then
        isLeader = (UnitIsPartyLeader("player") == 1)
    else
        isLeader = true
    end
    
    if isLeader then
        -- Leader shows message locally and broadcasts to group
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("PREP_FAILED") .. ": " .. reason, 1, 0, 0)
        self:broadcastPreparationFailed(reason)
    end
    -- Non-leaders will receive the message via sync (onSyncPreparationFailed)
end

-- ============================================================================
-- ZONE CHANGE DETECTION FOR COUNTDOWN
-- ============================================================================
function TurtleDungeonTimer:onZoneChanged()
    -- Only trigger countdown if in READY state and not already triggered
    if self.preparationState ~= "READY" then
        return
    end
    
    if self.countdownTriggered then
        return
    end
    
    -- Check if we entered the selected dungeon
    if not self.selectedDungeon then
        return
    end
    
    -- Get dungeon data to verify it exists
    local dungeonData = self.DUNGEON_DATA[self.selectedDungeon]
    if not dungeonData then
        return
    end
    
    -- Check all possible zone identifiers
    local zone = GetRealZoneText()
    local subZone = GetSubZoneText()
    local miniMap = GetMinimapZoneText()
    
    -- The dungeon name (key in DUNGEON_DATA) is often identical or contained in zone text
    local dungeonName = self.selectedDungeon
    
    -- Check if we're in the dungeon zone (exact match or contains)
    if zone == dungeonName or subZone == dungeonName or miniMap == dungeonName or
       (zone and string.find(zone, dungeonName)) or 
       (subZone and string.find(subZone, dungeonName)) or
       (miniMap and string.find(miniMap, dungeonName)) then
        
        -- Special handling for Stratholme: Both Living and Undead are in the same zone
        -- We can't differentiate at zone entry, so we always allow countdown
        -- The variant will be auto-detected from the first boss kill
        
        -- We entered the dungeon - broadcast countdown start
        self:broadcastCountdownStart(UnitName("player"))
    end
end

function TurtleDungeonTimer:getGroupSize()
    if GetNumRaidMembers() > 0 then
        return GetNumRaidMembers()
    elseif GetNumPartyMembers() > 0 then
        return GetNumPartyMembers() + 1 -- +1 for player
    else
        return 1
    end
end

-- ============================================================================
-- COUNTDOWN SYSTEM
-- ============================================================================
function TurtleDungeonTimer:startCountdown(triggeredBy)
    if self.countdownTriggered then
        return
    end
    
    -- Clear abort flag when starting countdown
    self.runAborted = false
    
    self.countdownTriggered = true
    self.firstZoneEnter = triggeredBy
    self.countdownValue = 10
    self.preparationState = "COUNTDOWN"
    
    -- Update button to show "Abort" since countdown started
    self:updateStartButton()
    
    -- No chat message - countdown frame provides enough visual information
    
    self:showCountdownFrame()
    self:updateCountdownTick()
end

function TurtleDungeonTimer:showCountdownFrame()
    if self.countdownFrame then
        self.countdownFrame:Show()
        return
    end
    
    -- Create countdown frame (no visible background)
    local frame = CreateFrame("Frame", "TDTCountdownFrame", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(300)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    
    -- No background texture - fully transparent
    
    -- Countdown number - 50% larger (120 * 1.5 = 180)
    local number = frame:CreateFontString(nil, "OVERLAY")
    number:SetPoint("CENTER", frame, "CENTER", 0, 0)
    number:SetFont("Fonts\\FRIZQT__.TTF", 180, "OUTLINE")
    number:SetTextColor(1, 1, 0)
    number:SetText("10")
    frame.number = number
    
    -- Title text (optional - could also be removed)
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    title:SetTextColor(1, 1, 1)
    title:SetText(TDT_L("UI_COUNTDOWN_TITLE"))
    frame.title = title
    
    self.countdownFrame = frame
end

function TurtleDungeonTimer:hideCountdownFrame()
    if self.countdownFrame then
        self.countdownFrame:Hide()
    end
end

function TurtleDungeonTimer:cancelCountdown()
    -- Stop the countdown immediately
    self.preparationState = nil
    self.countdownTriggered = false
    self:hideCountdownFrame()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[Turtle Dungeon Timer]|r " .. TDT_L("PREP_COUNTDOWN_CANCELLED"), 1, 0.6, 0)
end

function TurtleDungeonTimer:updateCountdownTick()
    -- Update display
    if self.countdownFrame and self.countdownFrame.number then
        self.countdownFrame.number:SetText(tostring(self.countdownValue))
        
        -- Flash effect
        if self.countdownValue <= 3 then
            self.countdownFrame.number:SetTextColor(1, 0, 0)
        else
            self.countdownFrame.number:SetTextColor(1, 1, 0)
        end
    end
    
    -- Play sound
    if self.countdownValue <= 3 then
        PlaySound("igMainMenuOptionCheckBoxOn")
    else
        PlaySound("igMainMenuOption")
    end
    
    -- Decrement the value
    self.countdownValue = self.countdownValue - 1
    
    -- Check if countdown is finished
    if self.countdownValue <= 0 then
        -- After 1 second, finish the countdown (show "LOS!" and start timer)
        self.countdownTimerId = self:scheduleTimer(function()
            self:finishCountdown()
        end, 1, false)
    else
        -- Schedule next tick
        self.countdownTimerId = self:scheduleTimer(function()
            self:updateCountdownTick()
        end, 1, false)
    end
end

function TurtleDungeonTimer:finishCountdown()
    -- Play start horn sound
    PlaySound("RaidWarning")
    
    -- Show GO!
    if self.countdownFrame and self.countdownFrame.number then
        self.countdownFrame.number:SetText(TDT_L("UI_COUNTDOWN_GO"))
        self.countdownFrame.number:SetTextColor(0, 1, 0)
    end
    
    -- No chat message - countdown frame provides enough visual information
    
    -- Hide after 2 seconds
    self:scheduleTimer(function()
        self:hideCountdownFrame()
    end, 2, false)
    
    -- Clear preparation state
    self.preparationState = nil
    
    -- Start timer immediately after countdown
    if not self.isRunning and self.selectedDungeon then
        self:start()
    end
end

function TurtleDungeonTimer:stopCountdown()
    -- Cancel countdown timer
    if self.countdownTimerId then
        self:cancelTimer(self.countdownTimerId)
        self.countdownTimerId = nil
    end
    
    -- Hide countdown frame
    if self.countdownFrame then
        self.countdownFrame:Hide()
    end
    
    -- Reset countdown state
    self.countdownTriggered = false
    self.countdownValue = nil
    self.firstZoneEnter = nil
end

-- ============================================================================
-- SIMPLE TIMER SCHEDULER
-- ============================================================================
local scheduledTimers = {}

function TurtleDungeonTimer:scheduleTimer(callback, delay, repeating)
    local id = GetTime() .. math.random(10000, 99999)
    scheduledTimers[id] = {
        callback = callback,
        when = GetTime() + delay,
        delay = delay,
        repeating = repeating
    }
    return id
end

function TurtleDungeonTimer:cancelTimer(id)
    scheduledTimers[id] = nil
end

-- Timer update frame
local timerFrame = CreateFrame("Frame")
local lastTimerUpdate = 0
timerFrame:SetScript("OnUpdate", function()
    -- Throttle to 20 times per second instead of 60+
    local now = GetTime()
    if now - lastTimerUpdate < 0.05 then
        return
    end
    lastTimerUpdate = now
    
    -- Check scheduled timers
    for id, timer in pairs(scheduledTimers) do
        if now >= timer.when then
            timer.callback()
            if timer.repeating then
                timer.when = now + timer.delay
            else
                scheduledTimers[id] = nil
            end
        end
    end
end)

-- ============================================================================
-- BROADCAST FUNCTIONS
-- ============================================================================
function TurtleDungeonTimer:broadcastPrepareStart()
    self:sendSyncMessage("PREPARE_START")
    
    -- Give others time to respond, then start checking
    self:scheduleTimer(function()
        if self:checkAddonPresence() and self:checkVersionMatch() then
            -- Start ready check
            self:startReadyCheck()
        end
    end, 1, false)
end

function TurtleDungeonTimer:broadcastCountdownStart(triggeredBy)
    self:sendSyncMessage("COUNTDOWN_START", triggeredBy)
    self:startCountdown(triggeredBy)
end

function TurtleDungeonTimer:broadcastPreparationFailed(reason)
    self:sendSyncMessage("PREPARE_FAILED", reason)
end

function TurtleDungeonTimer:broadcastDungeonSelected(dungeonId)
    self:sendSyncMessage("DUNGEON_SELECTED", dungeonId)
end

-- ============================================================================
-- SYNC MESSAGE HANDLERS
-- ============================================================================

function TurtleDungeonTimer:onSyncPrepareReady(sender)
    -- Leader has successfully reset, we're ready too
    self.preparationState = "READY"
    self.countdownTriggered = false
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_RUN_READY_MSG"), 0, 1, 0)
    
    -- Update button to show "Abort" since preparation is now ready
    self:updateStartButton()
    
    -- Register zone change event for countdown
    if not self.prepFrame then
        self.prepFrame = CreateFrame("Frame")
        self.prepFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self.prepFrame:SetScript("OnEvent", function()
            TurtleDungeonTimer:getInstance():onZoneChanged()
        end)
    end
end

function TurtleDungeonTimer:onSyncCountdownStart(triggeredBy, sender)
    if self.countdownTriggered then
        return
    end
    
    self:startCountdown(triggeredBy)
end

function TurtleDungeonTimer:onSyncPreparationFailed(reason, sender)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. string.format(TDT_L("PREP_FAILED_REASON"), reason), 1, 0, 0)
    self.preparationState = "FAILED"
end

function TurtleDungeonTimer:onSyncDungeonSelected(dungeonId, sender)
    if dungeonId ~= self.selectedDungeon then
        local oldDungeon = self.selectedDungeon and TurtleDungeonTimer.DUNGEON_DATA[self.selectedDungeon].name or "Kein Dungeon"
        local newDungeon = TurtleDungeonTimer.DUNGEON_DATA[dungeonId] and TurtleDungeonTimer.DUNGEON_DATA[dungeonId].name or "Unbekannt"
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. string.format(TDT_L("PREP_DUNGEON_CHANGED"), sender, newDungeon, oldDungeon), 1, 1, 0)
    end
end
