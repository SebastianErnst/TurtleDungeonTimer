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
    dialog:SetHeight(350)
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
    scrollFrame:SetPoint("TOP", dialog, "TOP", 20, -60)
    scrollFrame:SetWidth(280)
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
    dialog:SetHeight(270)
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
        -- Create interactive link frame for players with buffs
        local playersLinkFrame = CreateFrame("Frame", nil, dialog)
        playersLinkFrame:SetPoint("TOP", dialog, "TOP", 0, yOffset)  -- Centered
        playersLinkFrame:SetWidth(350)
        playersLinkFrame:SetHeight(20)
        playersLinkFrame:EnableMouse(true)
        
        local playersTitle = playersLinkFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playersTitle:SetPoint("CENTER", playersLinkFrame, "CENTER", 0, 0)  -- Centered
        playersTitle:SetText(TDT_L("UI_WORLDBUFF_PLAYERS_TITLE"))
        playersTitle:SetTextColor(0.3, 0.8, 1.0)  -- Light blue link color
        
        -- Tooltip with players and their buffs
        playersLinkFrame:SetScript("OnEnter", function()
            playersTitle:SetTextColor(0.5, 1.0, 1.0)  -- Brighter on hover
            GameTooltip:SetOwner(playersLinkFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(TDT_L("UI_WORLDBUFF_PLAYERS_TITLE"), 1, 0.82, 0, 1, true)
            for playerName, buffName in pairs(foundBuffs) do
                GameTooltip:AddLine(playerName .. ": " .. buffName, 1, 1, 0)
            end
            GameTooltip:Show()
        end)
        
        playersLinkFrame:SetScript("OnLeave", function()
            playersTitle:SetTextColor(0.3, 0.8, 1.0)  -- Back to normal
            GameTooltip:Hide()
        end)
        
        yOffset = yOffset - 30
    end
    
    -- Get list of tracked buffs from WorldBuffs.lua (for tooltip)
    local timer = TurtleDungeonTimer:getInstance()
    local worldBuffsTable = timer:getTrackedWorldBuffs()
    local trackedBuffs = {}
    for buffName, _ in pairs(worldBuffsTable) do
        table.insert(trackedBuffs, buffName)
    end
    table.sort(trackedBuffs)  -- Sort alphabetically for consistent display
    
    -- Combined info section
    local infoText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
    infoText:SetWidth(310)
    infoText:SetText(TDT_L("UI_WORLDBUFF_COMBINED_INFO"))
    infoText:SetTextColor(1, 1, 0.8)
    infoText:SetJustifyH("LEFT")
    yOffset = yOffset - 70  -- Extra spacing before link
    
    -- Create interactive "World Buffs" link frame below info text
    local linkFrame = CreateFrame("Frame", nil, dialog)
    linkFrame:SetPoint("TOP", dialog, "TOP", 0, yOffset)  -- Centered
    linkFrame:SetWidth(350)
    linkFrame:SetHeight(20)
    linkFrame:EnableMouse(true)
    
    local linkText = linkFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    linkText:SetPoint("CENTER", linkFrame, "CENTER", 0, 0)  -- Centered
    linkText:SetText(TDT_L("UI_WORLDBUFF_LINK_TEXT"))
    linkText:SetTextColor(0.3, 0.8, 1.0)  -- Light blue link color
    
    -- Tooltip with buff list on hover
    linkFrame:SetScript("OnEnter", function()
        linkText:SetTextColor(0.5, 1.0, 1.0)  -- Brighter on hover
        GameTooltip:SetOwner(linkFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(TDT_L("UI_WORLDBUFF_TOOLTIP_TITLE"), 1, 0.82, 0, 1, true)
        for _, buffName in ipairs(trackedBuffs) do
            GameTooltip:AddLine("  • " .. buffName, 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    
    linkFrame:SetScript("OnLeave", function()
        linkText:SetTextColor(0.3, 0.8, 1.0)  -- Back to normal
        GameTooltip:Hide()
    end)
    
    yOffset = yOffset - 30
    
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
    self.prepareReadyMessageShown = false  -- Reset flag for new preparation cycle
    
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
    if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r onResetSuccess - About to send PREPARE_READY", 1, 1, 0)
    end
    
    -- Only show message once per preparation cycle
    if not self.prepareReadyMessageShown then
        self.prepareReadyMessageShown = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_RUN_READY_MSG"), 0, 1, 0)
    end
    
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

-- ============================================================================
-- GENERIC GROUP VOTE UI (used for Ready Check and Abort Vote)
-- ============================================================================
-- Creates a vote prompt with player status display (portraits/names)
-- Parameters:
--   voteType: "ready_check" or "abort_vote"
--   title: Dialog title text
--   dungeonName: (optional) Dungeon name to display
--   initiatorName: (optional) Name of player who started the vote
--   responsesTable: Table to track responses {playerName = true/false/nil}
--   onYesCallback: function() - Called when player votes YES
--   onNoCallback: function() - Called when player votes NO
--   frameRefName: (optional) Property name to store frame reference (e.g., "readyCheckPromptFrame")
function TurtleDungeonTimer:showGroupVotePrompt(voteType, title, dungeonName, initiatorName, responsesTable, onYesCallback, onNoCallback, frameRefName)
    -- Close existing frame if specified
    if frameRefName and self[frameRefName] then
        self[frameRefName]:Hide()
        self[frameRefName] = nil
    end
    
    -- Mark initiator as responded automatically (they started the vote)
    if initiatorName and responsesTable then
        responsesTable[initiatorName] = true
    end
    
    -- Create custom vote frame
    local frame = CreateFrame("Frame", "TDTVoteFrame_" .. voteType, UIParent)
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
    
    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY")
    titleText:SetPoint("TOP", frame, "TOP", 0, -15)
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    titleText:SetTextColor(1, 0.82, 0)
    titleText:SetText(title)
    
    -- ============================================================================
    -- PLAYER STATUS CIRCLES (Top section)
    -- ============================================================================
    
    -- Collect all group members with initiator always first (if provided)
    local groupMembers = {}
    local playerName = UnitName("player")
    local isLeader = self:isGroupLeader()
    
    -- Add initiator first if provided
    if initiatorName then
        table.insert(groupMembers, initiatorName)
    elseif isLeader and playerName then
        -- Fallback: Add leader first if no initiator specified
        table.insert(groupMembers, playerName)
    end
    
    -- Add all other group members
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name = UnitName("raid" .. i)
            if name and name ~= (initiatorName or playerName) then
                table.insert(groupMembers, name)
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name and name ~= (initiatorName or playerName) then
                table.insert(groupMembers, name)
            end
        end
    end
    
    -- If player is not in list yet, add them
    local playerInList = false
    for _, name in ipairs(groupMembers) do
        if name == playerName then
            playerInList = true
            break
        end
    end
    if not playerInList and playerName then
        table.insert(groupMembers, playerName)
    end
    
    local numMembers = table.getn(groupMembers)
    frame.playerCircles = {}
    frame.responsesTable = responsesTable  -- Store responses table for OnUpdate handler
    
    -- Choose display mode based on group size
    if numMembers > 5 then
        -- ====================================================================
        -- COMPACT MODE (6+ players): Names only, 5 per row
        -- ====================================================================
        local namesPerRow = 5
        local nameWidth = 70
        local nameSpacing = 10
        local rowHeight = 20
        local startY = -50
        local horizontalPadding = 10
        
        for i, memberName in ipairs(groupMembers) do
            local row = math.floor((i - 1) / namesPerRow)
            local col = mod(i - 1, namesPerRow)
            
            local totalWidth = namesPerRow * nameWidth + (namesPerRow - 1) * nameSpacing
            local xOffset = -(totalWidth / 2) + col * (nameWidth + nameSpacing) + horizontalPadding
            local yOffset = startY - row * rowHeight
            
            local nameText = frame:CreateFontString(nil, "OVERLAY")
            nameText:SetPoint("TOPLEFT", frame, "TOP", xOffset, yOffset)
            nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            nameText:SetWidth(nameWidth)
            nameText:SetHeight(rowHeight)
            nameText:SetJustifyH("LEFT")
            nameText:SetJustifyV("TOP")
            nameText:SetText(memberName)
            nameText:SetTextColor(1, 1, 0) -- Yellow = pending
            
            local fakeCircle = CreateFrame("Frame", nil, frame)
            fakeCircle:SetWidth(1)
            fakeCircle:SetHeight(1)
            fakeCircle:Hide()
            fakeCircle.nameText = nameText
            fakeCircle.isCompactMode = true
            
            frame.playerCircles[memberName] = fakeCircle
        end
    else
        -- ====================================================================
        -- PORTRAIT MODE (1-5 players): Original display with portraits
        -- ====================================================================
        local circleSize = 60
        local spacing = 10
        local totalWidth = numMembers * circleSize + (numMembers - 1) * spacing
        local startX = -totalWidth / 2 + circleSize / 2
        
        for i, memberName in ipairs(groupMembers) do
            local xOffset = startX + (i - 1) * (circleSize + spacing)
            
            local circle = CreateFrame("Frame", nil, frame)
            circle:SetWidth(circleSize)
            circle:SetHeight(circleSize)
            circle:SetPoint("TOP", frame, "TOP", xOffset, -50)
            
            local icon = circle:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(circle)
            
            local unitId = nil
            if memberName == UnitName("player") then
                unitId = "player"
            elseif GetNumRaidMembers() > 0 then
                for j = 1, GetNumRaidMembers() do
                    if UnitName("raid" .. j) == memberName then
                        unitId = "raid" .. j
                        break
                    end
                end
            elseif GetNumPartyMembers() > 0 then
                for j = 1, GetNumPartyMembers() do
                    if UnitName("party" .. j) == memberName then
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
            
            local statusCircleSize = 68
            local statusCircle = CreateFrame("Frame", nil, frame)
            statusCircle:SetWidth(statusCircleSize)
            statusCircle:SetHeight(statusCircleSize)
            statusCircle:SetPoint("TOP", circle, "BOTTOM", 10, 10)
            statusCircle:SetFrameLevel(circle:GetFrameLevel() + 1)
            
            local statusIcon = statusCircle:CreateTexture(nil, "BACKGROUND")
            statusIcon:SetWidth(statusCircleSize - 43)
            statusIcon:SetHeight(statusCircleSize - 43)
            statusIcon:SetPoint("CENTER", statusCircle, "CENTER", -14, 15)
            statusIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            circle.statusIcon = statusIcon
            
            local border = statusCircle:CreateTexture(nil, "OVERLAY")
            border:SetPoint("CENTER", statusCircle, "CENTER", 0, 0)
            border:SetWidth(statusCircleSize)
            border:SetHeight(statusCircleSize)
            border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            border:SetVertexColor(1, 1, 0, 1) -- Yellow = pending
            circle.statusBg = border
            
            local nameText = circle:CreateFontString(nil, "OVERLAY")
            nameText:SetPoint("TOP", circle, "BOTTOM", 0, -30)
            nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            nameText:SetTextColor(1, 1, 1)
            nameText:SetText(memberName)
            
            frame.playerCircles[memberName] = circle
        end
    end
    
    -- Update initial status
    self:updateVoteCircles(frame, responsesTable)
    
    -- ============================================================================
    -- DUNGEON NAME SECTION (Middle) - only for ready_check
    -- ============================================================================
    
    local dungeonY = -160 - (numMembers > 3 and 20 or 0)
    
    if dungeonName and dungeonName ~= "" then
        local dungeonNameText = frame:CreateFontString(nil, "OVERLAY")
        dungeonNameText:SetPoint("TOP", frame, "TOP", 0, dungeonY)
        dungeonNameText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
        dungeonNameText:SetTextColor(1, 0.82, 0)
        dungeonNameText:SetWidth(380)
        dungeonNameText:SetText(dungeonName)
    end
    
    -- ============================================================================
    -- BUTTONS (Bottom)
    -- ============================================================================
    
    local buttonY = 40
    
    local yesBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    yesBtn:SetWidth(140)
    yesBtn:SetHeight(35)
    yesBtn:SetPoint("RIGHT", frame, "BOTTOM", -10, buttonY)
    yesBtn:SetText(TDT_L("YES"))
    yesBtn:SetScript("OnClick", function()
        if onYesCallback then
            onYesCallback()
        end
        -- Mark as responded and hide buttons
        this:GetParent().hasResponded = true
        this:Hide()
        this:GetParent().noButton:Hide()
    end)
    
    local noBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    noBtn:SetWidth(140)
    noBtn:SetHeight(35)
    noBtn:SetPoint("LEFT", frame, "BOTTOM", 10, buttonY)
    noBtn:SetText(TDT_L("UI_NO_BUTTON"))
    noBtn:SetScript("OnClick", function()
        if onNoCallback then
            onNoCallback()
        end
        -- Mark as responded and hide buttons
        this:GetParent().hasResponded = true
        this:Hide()
        this:GetParent().yesButton:Hide()
    end)
    
    frame.yesButton = yesBtn
    frame.noButton = noBtn
    
    -- ============================================================================
    -- TIMER BAR (Bottom)
    -- ============================================================================
    
    local progressBarWidth = 300
    
    local progressBg = frame:CreateTexture(nil, "BACKGROUND")
    progressBg:SetPoint("BOTTOM", frame, "BOTTOM", 0, 80)
    progressBg:SetWidth(progressBarWidth)
    progressBg:SetHeight(18)
    progressBg:SetTexture(0, 0, 0, 0.8)
    
    local progressBar = frame:CreateTexture(nil, "LEFT")
    progressBar:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
    progressBar:SetWidth(progressBarWidth)
    progressBar:SetHeight(18)
    progressBar:SetTexture(0, 0.8, 0, 0.6)
    frame.progressBar = progressBar
    
    local timerText = frame:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("CENTER", progressBg, "CENTER", 0, 0)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    timerText:SetTextColor(1, 1, 1)
    timerText:SetText("30s")
    frame.timerText = timerText
    
    -- ============================================================================
    -- UPDATE LOGIC
    -- ============================================================================
    
    frame.startTime = GetTime()
    frame.duration = 30
    frame.hasResponded = false
    frame.responsesTable = responsesTable
    
    -- If player already responded, mark as responded and hide buttons
    if responsesTable and responsesTable[UnitName("player")] ~= nil then
        frame.hasResponded = true
        yesBtn:Hide()
        noBtn:Hide()
    end
    
    frame:SetScript("OnUpdate", function()
        local elapsed = GetTime() - this.startTime
        local remaining = this.duration - elapsed
        
        if remaining <= 0 then
            -- Timeout
            if not this.hasResponded and onNoCallback then
                onNoCallback()  -- Auto-decline on timeout
            end
            this:Hide()
            return
        end
        
        -- Update timer bar
        local progress = remaining / this.duration
        this.progressBar:SetWidth(progressBarWidth * progress)
        this.timerText:SetText(string.format("%.0fs", remaining))
        
        -- Update player circles
        if this.responsesTable then
            TurtleDungeonTimer:getInstance():updateVoteCircles(this, this.responsesTable)
        end
        
        -- Check if all players have responded
        if this.responsesTable and this.playerCircles then
            local allResponded = true
            for playerName, _ in pairs(this.playerCircles) do
                if this.responsesTable[playerName] == nil then
                    allResponded = false
                    break
                end
            end
            
            -- Auto-close after 3 seconds if all responded
            if allResponded then
                if not this.autoCloseTimer then
                    this.autoCloseTimer = GetTime()
                end
                
                local autoCloseElapsed = GetTime() - this.autoCloseTimer
                if autoCloseElapsed >= 3 then
                    this:Hide()
                    return
                end
            else
                -- Reset timer if not all responded yet
                this.autoCloseTimer = nil
            end
        end
    end)
    
    frame:Show()
    
    -- Store frame reference if specified
    if frameRefName then
        self[frameRefName] = frame
    end
    
    return frame
end

-- Update visual status of player circles in vote prompt
function TurtleDungeonTimer:updateVoteCircles(frame, responsesTable)
    if not frame or not frame.playerCircles or not responsesTable then
        return
    end
    
    for playerName, circle in pairs(frame.playerCircles) do
        local response = responsesTable[playerName]
        
        if circle.isCompactMode then
            -- Compact mode: Just update text color
            if circle.nameText then
                if response == true then
                    circle.nameText:SetTextColor(0, 1, 0) -- Green
                elseif response == false then
                    circle.nameText:SetTextColor(1, 0, 0) -- Red
                else
                    circle.nameText:SetTextColor(1, 1, 0) -- Yellow
                end
            end
        else
            -- Portrait mode: Update icon and border
            if response == true then
                if circle.statusIcon then
                    circle.statusIcon:SetTexture("Interface\\Icons\\Ability_MeleeDamage")
                end
                if circle.statusBg then
                    circle.statusBg:SetVertexColor(0, 1, 0, 1) -- Green
                end
            elseif response == false then
                if circle.statusIcon then
                    circle.statusIcon:SetTexture("Interface\\Icons\\Ability_DualWield")
                end
                if circle.statusBg then
                    circle.statusBg:SetVertexColor(1, 0, 0, 1) -- Red
                end
            else
                if circle.statusIcon then
                    circle.statusIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
                if circle.statusBg then
                    circle.statusBg:SetVertexColor(1, 1, 0, 1) -- Yellow
                end
            end
        end
    end
end

function TurtleDungeonTimer:startReadyCheck()
    self.preparationState = "READY_CHECK"
    self.readyCheckResponses = {}
    self.readyCheckStarted = GetTime()
    
    -- Broadcast ready check request with dungeon name + variant to all group members
    local dungeonKey = ""
    local variantName = ""
    if self.pendingDungeonSelection then
        -- Use pending dungeon selection (not yet set as selectedDungeon)
        dungeonKey = self.pendingDungeonSelection
        variantName = self.pendingVariantSelection or ""
    end
    -- Ensure dungeonKey is never nil
    dungeonKey = dungeonKey or ""
    
    -- Add World Buff info to sync message (format: "dungeonKey;variantName;wbFlag")
    local wbFlag = "0" -- Default: no World Buff info
    if self.runWithWorldBuffs ~= nil then
        wbFlag = self.runWithWorldBuffs and "1" or "2" -- 1 = with WBs, 2 = without WBs
    end
    local syncData = dungeonKey .. ";" .. variantName .. ";" .. wbFlag
    
    self:sendSyncMessage("READY_CHECK_START", syncData)
    
    -- Auto-respond for self (leader) - leader is always ready
    self.readyCheckResponses[UnitName("player")] = true
    
    -- Show ready check prompt for leader too (they should see the window)
    self:showReadyCheckPrompt(dungeonKey, variantName, UnitName("player"))
    
    -- Timeout after 30 seconds
    self:scheduleTimer(function()
        if self.preparationState == "READY_CHECK" then
            self:finishReadyCheck()
        end
    end, 30, false)
end

-- Show the ready check prompt to a player (wrapper for showGroupVotePrompt)
-- dungeonKey: optional parameter with dungeon key (from sync message)
-- variantName: optional parameter with variant name (from sync message)
-- leaderName: name of the player who started the ready check
function TurtleDungeonTimer:showReadyCheckPrompt(dungeonKey, variantName, leaderName)
    -- Build formatted dungeon name with variant
    local dungeonDisplayName = ""
    local localDungeonKey = dungeonKey
    local localVariantName = variantName
    
    -- Use provided parameters (from leader) or fallback to own selection
    if not localDungeonKey or localDungeonKey == "" then
        localDungeonKey = self.selectedDungeon or self.pendingDungeonSelection
        localVariantName = self.selectedVariant or self.pendingVariantSelection
    end
    
    if localDungeonKey and localDungeonKey ~= "" then
        local dungeonData = self.DUNGEON_DATA[localDungeonKey]
        if dungeonData then
            dungeonDisplayName = dungeonData.name or localDungeonKey
            if localVariantName and localVariantName ~= "Default" and localVariantName ~= "" then
                dungeonDisplayName = dungeonDisplayName .. " - " .. localVariantName
            end
        end
    end
    
    -- Use the generic group vote prompt
    self:showGroupVotePrompt(
        "ready_check",
        TDT_L("UI_READY_CHECK_TITLE"),
        dungeonDisplayName,
        leaderName,
        self.readyCheckResponses,
        function() self:respondToReadyCheck(true) end,
        function() self:respondToReadyCheck(false) end,
        "readyCheckPromptFrame"
    )
end

-- Alias for backwards compatibility (redirects to new generic function)
function TurtleDungeonTimer:updateReadyCheckCircles(frame)
    self:updateVoteCircles(frame, self.readyCheckResponses)
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
        self:updateVoteCircles(self.readyCheckPromptFrame, self.readyCheckResponses)
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
    
    -- Only leader should check if all members have responded
    if self:isGroupLeader() then
        self:checkReadyCheckComplete()
    end
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
    local notReadyPlayers = {}  -- Initialize as empty table
    
    -- Check self
    local selfReady = self.readyCheckResponses[UnitName("player")]
    local playerName = UnitName("player")
    
    if selfReady == false then
        if isLeader then
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. playerName .. " (Not Ready)", 1, 0, 0)
        end
        allReady = false
        table.insert(notReadyPlayers, playerName)
    elseif selfReady ~= true then
        if isLeader then
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff9900?|r " .. playerName .. " " .. TDT_L("PREP_NO_RESPONSE"), 1, 0.6, 0)
        end
        allReady = false
        table.insert(notReadyPlayers, playerName)
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
        self.preparationState = nil  -- Reset to nil so button shows "Start" again
        if isLeader then
            local playerList = table.concat(notReadyPlayers, ", ")
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r Ready check failed - Players not ready: " .. playerList, 1, 0, 0)
            -- Only broadcast to group, don't show local message again
            self:broadcastPreparationFailed("Players not ready: " .. playerList)
        end
        
        -- Update button to show "Start" again
        self:updateStartButton()
    end
end

function TurtleDungeonTimer:failPreparation(reason)
    self.preparationState = nil  -- Reset to nil so button shows "Start" again
    
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
    
    -- Update button to show "Start" again
    self:updateStartButton()
end

-- ============================================================================
-- PREPARATION ABORT DIALOG (called when aborting preparation before run starts)
-- ============================================================================
function TurtleDungeonTimer:showPreparationAbortDialog()
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(300)
    dialog:SetHeight(140)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
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
    
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText(TDT_L("UI_ABORT_RUN_TITLE"))
    title:SetTextColor(1, 0.82, 0)
    
    local message = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", title, "BOTTOM", 0, -15)
    message:SetWidth(260)
    message:SetText(TDT_L("UI_ABORT_PREPARATION_MESSAGE"))
    message:SetJustifyH("CENTER")
    
    local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    yesButton:SetWidth(100)
    yesButton:SetHeight(30)
    yesButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -105, 15)
    yesButton:SetText(TDT_L("YES"))
    yesButton:SetScript("OnClick", function()
        -- Reset preparation state
        local timer = TurtleDungeonTimer:getInstance()
        timer.preparationState = nil
        timer.pendingDungeonSelection = nil
        timer.pendingVariantSelection = nil
        timer.readyCheckResponses = {}
        timer:updateStartButton()
        dialog:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_ABORTED"), 0, 1, 0)
    end)
    
    local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    noButton:SetWidth(100)
    noButton:SetHeight(30)
    noButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", 105, 15)
    noButton:SetText(TDT_L("UI_NO_BUTTON"))
    noButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
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
    -- Debug output
    if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF00FF[TDT Debug]|r onSyncPrepareReady called. sender=%s, player=%s, alreadyShown=%s", tostring(sender), tostring(UnitName("player")), tostring(self.prepareReadyMessageShown)), 1, 1, 0)
    end
    
    -- Leader has successfully reset, we're ready too
    self.preparationState = "READY"
    self.countdownTriggered = false
    
    -- Only show message once per preparation cycle
    if not self.prepareReadyMessageShown then
        self.prepareReadyMessageShown = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_RUN_READY_MSG"), 0, 1, 0)
    end
    
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
