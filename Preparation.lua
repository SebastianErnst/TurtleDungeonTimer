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

function TurtleDungeonTimer:startPreparation()
    -- Check if player is group leader
    if not self:isGroupLeader() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("PREP_LEADER_ONLY_PREPARE"), 1, 0, 0)
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
    self.preparationDungeonDialog = dialog
    
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
        table.insert(dungeonList, {
            key = dungeonName,
            displayName = displayName,
            variantCount = variantCount
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
        btnText:SetText(dungeon.displayName)
        btnText:SetJustifyH("LEFT")
        
        -- Show arrow if multiple variants
        if dungeon.variantCount > 1 then
            local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            arrow:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
            arrow:SetText(">")
        end
        
        -- Capture dungeon name for closure
        local dungeonKey = dungeon.key
        local variantCount = dungeon.variantCount
        
        btn:SetScript("OnEnter", function()
            this:SetBackdropColor(0.3, 0.3, 0.3, 0.9)
            -- Show variant submenu if multiple variants
            if variantCount > 1 then
                TurtleDungeonTimer:getInstance():showPreparationVariantMenu(this, dungeonKey)
            end
        end)
        btn:SetScript("OnLeave", function()
            this:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        end)
        btn:SetScript("OnClick", function()
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
        
        local btn = CreateFrame("Button", nil, submenu)
        btn:SetWidth(140)
        btn:SetHeight(btnHeight - 2)
        btn:SetPoint("TOP", submenu, "TOP", 0, -4 - (i-1) * btnHeight)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        text:SetText(variantName)
        text:SetJustifyH("LEFT")
        
        btn:SetScript("OnEnter", function()
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropColor(0.4, 0.4, 0.4, 0.8)
        end)
        
        btn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        
        btn:SetScript("OnClick", function()
            TurtleDungeonTimer:getInstance():onPreparationDungeonVariantSelected(dungeonKey, variantName)
        end)
    end
end

function TurtleDungeonTimer:onPreparationDungeonVariantSelected(dungeonKey, variantName)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] onPreparationDungeonVariantSelected: " .. tostring(dungeonKey) .. " / " .. tostring(variantName), 0, 1, 1)
    end
    
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
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Stored pending selection: " .. tostring(dungeonKey) .. " / " .. tostring(variantName), 0, 1, 1)
    end
    
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
    self.preparationChecks = {}
    self.countdownTriggered = false
    self.firstZoneEnter = nil
    
    -- Get display name for the pending dungeon
    local dungeonData = self.DUNGEON_DATA[self.pendingDungeonSelection]
    local dungeonDisplayName = dungeonData and dungeonData.name or self.pendingDungeonSelection
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. string.format(TDT_L("PREP_STARTING_FOR"), dungeonDisplayName), 0, 1, 0)
    
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
    
    -- Display results
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Addon Check]|r", 0, 1, 0)
    
    -- Show who has addon
    for playerName, _ in pairs(withAddon) do
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00✓|r " .. playerName, 0.7, 0.7, 0.7)
    end
    
    -- Show who doesn't have addon
    local missingCount = 0
    for playerName, _ in pairs(withoutAddon) do
        DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. playerName .. " |cffff0000(fehlt)|r", 1, 0, 0)
        missingCount = missingCount + 1
    end
    
    if missingCount > 0 then
        self:failPreparation("Nicht alle Gruppenmitglieder haben das Addon installiert!")
        return false
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[✓]|r Alle haben das Addon", 0, 1, 0)
    return true
end

function TurtleDungeonTimer:checkVersionMatch()
    -- Check if all versions match
    local myVersion = self.SYNC_VERSION
    local allMatch = true
    local versionMismatches = {}
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Version Check]|r", 0, 1, 0)
    
    -- Add self
    DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00✓|r " .. UnitName("player") .. " (v" .. myVersion .. ")", 0.7, 0.7, 0.7)
    
    -- Check all players
    for player, version in pairs(self.preparationChecks) do
        if version == myVersion then
            DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00✓|r " .. player .. " (v" .. version .. ")", 0.7, 0.7, 0.7)
        else
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. player .. " (v" .. version .. ") |cffff0000(erwartet: v" .. myVersion .. ")|r", 1, 0, 0)
            allMatch = false
            table.insert(versionMismatches, player)
        end
    end
    
    if not allMatch then
        self:failPreparation("Version mismatch! Nicht alle haben die gleiche Version.")
        return false
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[✓]|r Alle haben die gleiche Version", 0, 1, 0)
    return true
end

function TurtleDungeonTimer:executeReset()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_RESETTING_INSTANCE_MSG"), 0, 1, 0)
    
    -- Listen for system messages
    if not self.resetCheckFrame then
        self.resetCheckFrame = CreateFrame("Frame")
        self.resetCheckFrame:RegisterEvent("CHAT_MSG_SYSTEM")
        self.resetCheckFrame:SetScript("OnEvent", function()
            TurtleDungeonTimer:getInstance():onResetSystemMessage(arg1)
        end)
    end
    
    -- ⚠️ TESTING MODE - Skip actual reset
    -- ResetInstances()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[TESTING]|r " .. TDT_L("PREP_RESET_SKIPPED_LIMIT"), 1, 0.6, 0)
    
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
        self:failPreparation("Instanz konnte nicht zurückgesetzt werden! Es sind noch Spieler in der Instanz.")
    end
end

function TurtleDungeonTimer:onResetSuccess()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[✓]|r " .. TDT_L("PREP_INSTANCE_RESET_SUCCESS"), 0, 1, 0)
    
    self.preparationState = "READY"
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_RUN_READY_MSG"), 0, 1, 0)
    
    -- Update button to show "Abort" since preparation is now ready
    self:updateStartButton()
    
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
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Starte Ready Check...", 0, 1, 0)
    
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
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Sending READY_CHECK_START with dungeonName: " .. tostring(dungeonName) .. " and WB flag: " .. wbFlag, 1, 1, 0)
    end
    
    self:sendSyncMessage("READY_CHECK_START", syncData)
    
    -- Auto-respond for self (leader) - leader is always ready
    self.readyCheckResponses[UnitName("player")] = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Ready Check]|r Du (Leader) bist automatisch ready", 0, 1, 0)
    
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
function TurtleDungeonTimer:showReadyCheckPrompt(dungeonName)
    -- Close existing ready check frame
    if self.readyCheckPromptFrame then
        self.readyCheckPromptFrame:Hide()
        self.readyCheckPromptFrame = nil
    end
    
    -- Create custom ready check frame
    local frame = CreateFrame("Frame", "TDTReadyCheckFrame", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(250) -- Increased height for World Buff info
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
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetTextColor(1, 1, 0)
    title:SetText(TDT_L("UI_READY_CHECK_TITLE"))
    
    -- Question text with dungeon name
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOP", frame, "TOP", 0, -50)
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetTextColor(1, 1, 1)
    
    -- Use provided dungeonName parameter (from leader) or fallback to own selection
    local dungeonText = TDT_L("UI_READY_CHECK_QUESTION")
    if dungeonName and dungeonName ~= "" then
        -- Use dungeon name from leader's sync message
        dungeonText = string.format(TDT_L("UI_READY_CHECK_DUNGEON"), dungeonName)
    elseif self.selectedDungeon then
        -- Fallback to own selection (shouldn't happen in normal flow)
        local dungeonData = self.DUNGEON_DATA[self.selectedDungeon]
        local dungeonDisplayName = dungeonData and dungeonData.name or self.selectedDungeon
        dungeonText = string.format(TDT_L("UI_READY_CHECK_DUNGEON"), dungeonDisplayName)
    end
    text:SetText(dungeonText)
    
    -- World Buff Info (if applicable)
    local wbInfoY = -80 -- Starting Y position for World Buff info
    if self.runWithWorldBuffs ~= nil then
        local wbInfo = frame:CreateFontString(nil, "OVERLAY")
        wbInfo:SetPoint("TOP", frame, "TOP", 0, wbInfoY)
        wbInfo:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        wbInfo:SetWidth(360)
        
        if self.runWithWorldBuffs then
            -- Run WITH World Buffs
            wbInfo:SetTextColor(0, 1, 0) -- Green
            wbInfo:SetText(TDT_L("READY_CHECK_WITH_WB"))
        else
            -- Run WITHOUT World Buffs
            wbInfo:SetTextColor(1, 0.5, 0) -- Orange
            local infoText = TDT_L("READY_CHECK_WITHOUT_WB") .. "\n" .. TDT_L("READY_CHECK_WB_REMOVED") .. "\n\n" .. TDT_L("UI_WORLDBUFF_TRACKING_INFO")
            wbInfo:SetText(infoText)
        end
    end
    
    -- Yes button (left of center)
    local yesBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    yesBtn:SetWidth(120)
    yesBtn:SetHeight(30)
    yesBtn:SetPoint("RIGHT", frame, "BOTTOM", -10, 55)
    yesBtn:SetText(TDT_L("YES"))
    yesBtn:SetScript("OnClick", function()
        local tdt = TurtleDungeonTimer:getInstance()
        
        -- Just respond to ready check, dungeon will be set later
        tdt:respondToReadyCheck(true)
        frame:Hide()
    end)
    
    -- No button (right of center)
    local noBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    noBtn:SetWidth(120)
    noBtn:SetHeight(30)
    noBtn:SetPoint("LEFT", frame, "BOTTOM", 10, 55)
    noBtn:SetText(TDT_L("UI_NO_BUTTON"))
    noBtn:SetScript("OnClick", function()
        TurtleDungeonTimer:getInstance():respondToReadyCheck(false)
        frame:Hide()
    end)
    
    -- Progress bar background
    local progressBg = frame:CreateTexture(nil, "BACKGROUND")
    progressBg:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    progressBg:SetWidth(350)
    progressBg:SetHeight(20)
    progressBg:SetTexture(0, 0, 0, 0.8)
    
    -- Progress bar
    local progressBar = frame:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
    progressBar:SetWidth(350)
    progressBar:SetHeight(20)
    progressBar:SetTexture(0, 0.8, 0, 0.6)
    frame.progressBar = progressBar
    
    -- Timer text
    local timerText = frame:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("CENTER", progressBg, "CENTER", 0, 0)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    timerText:SetTextColor(1, 1, 1)
    timerText:SetText("30s")
    frame.timerText = timerText
    
    -- Update timer
    frame.startTime = GetTime()
    frame.duration = 30
    frame:SetScript("OnUpdate", function()
        local elapsed = GetTime() - this.startTime
        local remaining = this.duration - elapsed
        
        if remaining <= 0 then
            -- Timeout - auto-respond with "not ready"
            TurtleDungeonTimer:getInstance():respondToReadyCheck(false)
            this:Hide()
            return
        end
        
        -- Update progress bar
        local progress = remaining / this.duration
        this.progressBar:SetWidth(350 * progress)
        
        -- Update timer text
        this.timerText:SetText(math.floor(remaining) .. "s")
        
        -- Change color based on remaining time
        if remaining < 10 then
            this.progressBar:SetTexture(0.8, 0, 0, 0.6) -- Red
        elseif remaining < 20 then
            this.progressBar:SetTexture(0.8, 0.8, 0, 0.6) -- Yellow
        end
    end)
    
    frame:Show()
    self.readyCheckPromptFrame = frame
end

function TurtleDungeonTimer:respondToReadyCheck(isReady)
    -- Send response to leader
    self:sendSyncMessage("READY_CHECK_RESPONSE", isReady and "1" or "0")
    
    -- Update local state for self
    self.readyCheckResponses[UnitName("player")] = isReady
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Ready response sent: " .. tostring(isReady), 1, 1, 0)
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
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] " .. sender .. " ready: " .. isReady, 1, 1, 0)
    end
    
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
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Ready Check: " .. responseCount .. "/" .. expectedCount .. " responded", 1, 1, 0)
    end
    
    -- If all have responded, finish immediately
    if responseCount >= expectedCount then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Alle haben geantwortet!", 0, 1, 0)
        self:finishReadyCheck()
    end
end

function TurtleDungeonTimer:finishReadyCheck()
    if self.preparationState ~= "READY_CHECK" then
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Ready Check Ergebnisse]|r", 0, 1, 0)
    
    local allReady = true
    local notReadyPlayers = {}
    
    -- Check self
    local selfReady = self.readyCheckResponses[UnitName("player")]
    if selfReady == true then
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00✓|r " .. UnitName("player") .. " (Ready)", 0.7, 0.7, 0.7)
    elseif selfReady == false then
        DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. UnitName("player") .. " (Not Ready)", 1, 0, 0)
        allReady = false
        table.insert(notReadyPlayers, UnitName("player"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("  |cffff9900?|r " .. UnitName("player") .. " (Keine Antwort)", 1, 0.6, 0)
        allReady = false
        table.insert(notReadyPlayers, UnitName("player"))
    end
    
    -- Check group members
    for player, _ in pairs(self.playersWithAddon) do
        local ready = self.readyCheckResponses[player]
        if ready == true then
            DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00✓|r " .. player .. " (Ready)", 0.7, 0.7, 0.7)
        elseif ready == false then
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff0000✗|r " .. player .. " (Not Ready)", 1, 0, 0)
            allReady = false
            table.insert(notReadyPlayers, player)
        else
            DEFAULT_CHAT_FRAME:AddMessage("  |cffff9900?|r " .. player .. " (Keine Antwort)", 1, 0.6, 0)
            allReady = false
            table.insert(notReadyPlayers, player)
        end
    end
    
    if allReady then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[✓]|r Alle sind ready!", 0, 1, 0)
        
        -- Remove world buffs if "Without World Buffs" was selected
        if not self.runWithWorldBuffs then
            self:removeAllWorldBuffs()
        end
        
        -- NOW set the dungeon for everyone (leader + all group members)
        if self:isGroupLeader() and self.pendingDungeonSelection then
            local dungeonKey = self.pendingDungeonSelection
            local variantKey = self.pendingVariantSelection
            
            if TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("[Debug] All ready - now setting dungeon for everyone: " .. dungeonKey .. (variantKey and (" / " .. variantKey) or ""), 0, 1, 1)
            end
            
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
        
        -- Reset current run directly and broadcast to group
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. TDT_L("PREP_RESET_CURRENT_RUN"), 0, 1, 0)
        
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
        -- Preparation failed
        self.preparationState = "FAILED"
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[✗] Vorbereitung fehlgeschlagen:|r Nicht alle sind ready! Bereite dich vor und versuche es erneut.", 1, 0, 0)
        self:broadcastPreparationFailed("Nicht alle sind ready!")
    end
end

function TurtleDungeonTimer:failPreparation(reason)
    self.preparationState = "FAILED"
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[✗] Vorbereitung fehlgeschlagen:|r " .. reason, 1, 0, 0)
    self:broadcastPreparationFailed(reason)
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
        if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r No dungeon data for: " .. tostring(self.selectedDungeon))
        end
        return
    end
    
    -- Check all possible zone identifiers
    local zone = GetRealZoneText()
    local subZone = GetSubZoneText()
    local miniMap = GetMinimapZoneText()
    
    -- The dungeon name (key in DUNGEON_DATA) is often identical or contained in zone text
    local dungeonName = self.selectedDungeon
    
    if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r Zone check - RealZone: " .. tostring(zone) .. ", SubZone: " .. tostring(subZone) .. ", MiniMap: " .. tostring(miniMap))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r Looking for dungeon: " .. tostring(dungeonName))
    end
    
    -- Check if we're in the dungeon zone (exact match or contains)
    if zone == dungeonName or subZone == dungeonName or miniMap == dungeonName or
       (zone and string.find(zone, dungeonName)) or 
       (subZone and string.find(subZone, dungeonName)) or
       (miniMap and string.find(miniMap, dungeonName)) then
        
        -- Special handling for Stratholme: Both Living and Undead are in the same zone
        -- We can't differentiate at zone entry, so we always allow countdown
        -- The variant will be auto-detected from the first boss kill
        
        if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r Zone match! Starting countdown broadcast")
        end
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
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. triggeredBy .. " hat die Instanz betreten! Countdown startet in 10 Sekunden...", 0, 1, 0)
    
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
    
    -- Title text (optional - könnte auch entfernt werden)
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
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[Turtle Dungeon Timer]|r Countdown abgebrochen - Timer gestartet!", 1, 0.6, 0)
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
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Run gestartet! Viel Erfolg!", 0, 1, 0)
    
    -- Hide after 2 seconds
    self:scheduleTimer(function()
        self:hideCountdownFrame()
    end, 2, false)
    
    -- Clear preparation state
    self.preparationState = nil
    
    -- Start timer immediately after countdown
    if not self.isRunning and self.selectedDungeon and self.selectedVariant then
        self:start()
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug] Timer gestartet nach Countdown", 1, 1, 0)
        end
    else
        -- Debug: why didn't timer start?
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug] Timer NICHT gestartet - isRunning=" .. tostring(self.isRunning) .. ", Dungeon=" .. tostring(self.selectedDungeon) .. ", Variant=" .. tostring(self.selectedVariant), 1, 0, 0)
        end
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
function TurtleDungeonTimer:onSyncPrepareStart(sender)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Prepare start from: " .. sender, 1, 1, 0)
    end
    
    -- Respond with our version
    self:sendSyncMessage("ADDON_CHECK")
end

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
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r Vorbereitung fehlgeschlagen: " .. reason, 1, 0, 0)
    self.preparationState = "FAILED"
end

function TurtleDungeonTimer:onSyncDungeonSelected(dungeonId, sender)
    if dungeonId ~= self.selectedDungeon then
        local oldDungeon = self.selectedDungeon and TurtleDungeonTimer.DUNGEON_DATA[self.selectedDungeon].name or "Kein Dungeon"
        local newDungeon = TurtleDungeonTimer.DUNGEON_DATA[dungeonId] and TurtleDungeonTimer.DUNGEON_DATA[dungeonId].name or "Unbekannt"
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. string.format(TDT_L("PREP_DUNGEON_CHANGED"), sender, newDungeon, oldDungeon), 1, 1, 0)
    end
end
