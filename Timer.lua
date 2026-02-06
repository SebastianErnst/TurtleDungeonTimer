-- ============================================================================
-- Turtle Dungeon Timer - Timer Logic
-- ============================================================================

function TurtleDungeonTimer:start()
    if not self.selectedDungeon or not self.selectedVariant then
        return
    end
    
    if table.getn(self.bossList) == 0 then
        return
    end
    
    -- Don't allow start if run is completed (all required bosses defeated)
    local requiredBosses = self:getRequiredBossCount()
    local requiredKills = self:getRequiredBossKills()
    if requiredKills >= requiredBosses and requiredBosses > 0 then
        return
    end
    
    -- Don't allow start if already running
    if self.isRunning then
        return
    end
    
    -- Cancel countdown if it's running
    if self.preparationState == "COUNTDOWN" then
        self:cancelCountdown()
    end
    
    -- Clear abort flag when manually starting timer
    self.runAborted = false
    
    -- Start timer immediately
    self.isRunning = true
    
    -- Handle timer continuation vs fresh start
    if self.restoredElapsedTime and self.restoredElapsedTime > 0 then
        -- Continue from paused state
        self.startTime = GetTime() - self.restoredElapsedTime
        self.restoredElapsedTime = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Timer fortgesetzt!", 1, 1, 0)
    else
        -- Fresh start
        self.startTime = GetTime()
        self.killTimes = {}
        self.deathCount = 0
        self.runCompleted = false  -- Reset completion flag for new run
        
        -- Reset official run flag (will be set to false by preparation if needed)
        if not self.isOfficialRun then
            self.isOfficialRun = true  -- Reset to true for new run
        end
        
        -- Generate UUID for this run
        self.currentRunUUID = self:generateUUID()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Timer gestartet!", 1, 1, 0)
    end
    
    -- Collect player and group info
    self.playerName = UnitName("player") or "Unknown"
    self.guildName = GetGuildInfo("player") or "No Guild"
    self.groupClasses = self:collectGroupClasses()
    
    -- Check for world buffs
    self:checkWorldBuffsOnStart()
    
    -- Start trash counter if dungeon has trash data
    local dungeonData = TurtleDungeonTimer.DUNGEON_DATA[self.selectedDungeon]
    if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r start(): dungeonData=" .. tostring(dungeonData ~= nil) .. ", selectedVariant=" .. tostring(self.selectedVariant), 1, 1, 0)
    end
    
    if dungeonData and self.selectedVariant then
        local variantData = dungeonData.variants[self.selectedVariant]
        if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r start(): variantData=" .. tostring(variantData ~= nil) .. ", trashMobs=" .. tostring(variantData and variantData.trashMobs ~= nil), 1, 1, 0)
        end
        
        if variantData and variantData.trashMobs then
            if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r Calling TDTTrashCounter:startDungeon(" .. self.selectedDungeon .. ", " .. self.selectedVariant .. ")", 0, 1, 0)
            end
            TDTTrashCounter:startDungeon(self.selectedDungeon, self.selectedVariant)
        else
            if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r No trashMobs data for this dungeon/variant", 1, 0, 0)
            end
        end
    end
    
    -- Save initial state
    self:saveLastRun()
    
    -- Reset UI
    self:resetUI()
    self:updateStartButton()  -- Update button to show "Abort"
end

function TurtleDungeonTimer:showResetConfirmation()
    if self.resetConfirmDialog then
        self.resetConfirmDialog:Show()
        return
    end
    
    -- Create confirmation dialog
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(300)
    dialog:SetHeight(120)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    self.resetConfirmDialog = dialog
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("Reset Run?")
    title:SetTextColor(1, 0.82, 0)
    
    -- Message
    local message = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", title, "BOTTOM", 0, -10)
    message:SetWidth(260)
    message:SetText("Do you want to reset the current run?")
    message:SetJustifyH("CENTER")
    
    -- Yes Button
    local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    yesButton:SetWidth(100)
    yesButton:SetHeight(30)
    yesButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -105, 15)
    yesButton:SetText("Yes")
    yesButton:SetScript("OnClick", function()
        dialog:Hide()
        TurtleDungeonTimer:getInstance():performReset()
    end)
    
    -- No Button
    local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    noButton:SetWidth(100)
    noButton:SetHeight(30)
    noButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", 105, 15)
    noButton:SetText("No")
    noButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:pause()
    -- Pause the timer while keeping the current state
    if not self.isRunning then return end
    
    self.isRunning = false
    
    -- Calculate elapsed time for restoration later
    if self.startTime then
        self.restoredElapsedTime = GetTime() - self.startTime
    end
    
    self.startTime = nil
    
    -- Save paused state
    self:saveLastRun()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Timer pausiert!", 1, 1, 0)
    
    -- Update button text
    self:updateStartButton()
end

function TurtleDungeonTimer:reset()
    -- Check if there's any data that would be reset
    local lastRun = TurtleDungeonTimerDB.lastRun
    local hasLastRun = lastRun and lastRun.dungeon == self.selectedDungeon 
        and lastRun.variant == self.selectedVariant 
        and lastRun.killTimes and table.getn(lastRun.killTimes) > 0
    local hasCurrentData = table.getn(self.killTimes) > 0 or self.deathCount > 0 or self.isRunning
    
    -- Show reset confirmation dialog
    self:showResetConfirmation()
end

function TurtleDungeonTimer:performReset()
    -- Start the reset process via sync system
    -- This will handle both solo and group scenarios
    self:syncTimerReset()
end

-- ============================================================================
-- PRIVATE: Common reset logic
-- ============================================================================
local function resetRunDataCommon(self)
    -- Stop timer
    self.isRunning = false
    self.startTime = nil
    self.restoredElapsedTime = nil
    
    -- Clear run data
    self.killTimes = {}
    self.deathCount = 0
    
    -- DON'T reset runWithWorldBuffs - it's a preparation setting, not run data!
    -- Only clear the player list
    self.runWorldBuffPlayers = {}
    
    -- Clear Run ID
    self:clearRunId()
    
    -- Reset all boss defeated flags
    for i = 1, table.getn(self.bossList) do
        if type(self.bossList[i]) == "table" then
            self.bossList[i].defeated = false
        end
    end
    
    -- Stop trash counter
    TDTTrashCounter:stopDungeon()
    
    -- Clear last run from database
    TurtleDungeonTimerDB.lastRun = {}
    
    -- Reset UI
    self:resetUI()
    
    -- Update World Buffs indicator
    self:updateWorldBuffsIndicator()
    
    -- Update button text
    self:updateStartPauseButton()
end

function TurtleDungeonTimer:performResetDirect(silent)
    -- Complete reset with all data cleared
    -- silent: if true, don't show chat message
    resetRunDataCommon(self)
    
    -- Always silent now - no output
end

-- Alias for backwards compatibility
function TurtleDungeonTimer:performResetSilent()
    self:performResetDirect(true)
end

function TurtleDungeonTimer:updateStartPauseButton()
    if not self.frame or not self.frame.startPauseButton then return end
    
    -- Check if run is completed
    local requiredBosses = self:getRequiredBossCount()
    local requiredKills = self:getRequiredBossKills()
    local isCompleted = requiredKills >= requiredBosses and requiredBosses > 0
    
    if isCompleted then
        self.frame.startPauseButton:SetText("START")
        self.frame.startPauseButton:Disable()
    else
        self.frame.startPauseButton:Enable()
        if self.isRunning or self.isCountingDown then
            self.frame.startPauseButton:SetText("PAUSE")
        elseif self.restoredElapsedTime and self.restoredElapsedTime > 0 then
            self.frame.startPauseButton:SetText("CONTINUE")
        elseif table.getn(self.killTimes) > 0 or self.deathCount > 0 then
            self.frame.startPauseButton:SetText("CONTINUE")
        else
            self.frame.startPauseButton:SetText("START")
        end
    end
end

function TurtleDungeonTimer:collectGroupClasses()
    local classes = {}
    
    -- Add player's class and name
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    if playerClass and playerName then
        table.insert(classes, playerClass .. ":" .. playerName)
    end
    
    -- Check if in raid
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            if i ~= 0 then -- Skip raid0 (that's the player)
                local unit = "raid" .. i
                local name = UnitName(unit)
                local _, class = UnitClass(unit)
                if class and name then
                    table.insert(classes, class .. ":" .. name)
                end
            end
        end
    -- Check if in party
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local unit = "party" .. i
            local name = UnitName(unit)
            local _, class = UnitClass(unit)
            if class and name then
                table.insert(classes, class .. ":" .. name)
            end
        end
    end
    
    return classes
end

function TurtleDungeonTimer:report(chatType)
    -- Check if there's any data to report
    if not self.startTime and table.getn(self.killTimes) == 0 then
        return
    end
    
    chatType = chatType or "SAY"
    
    local finalTime = 0
    if self.isRunning then
        finalTime = GetTime() - self.startTime
    else
        if table.getn(self.killTimes) > 0 then
            finalTime = self.killTimes[table.getn(self.killTimes)].time
        end
    end
    
    local dungeonStr = self.selectedDungeon or "Unknown"
    if self.selectedVariant and self.selectedVariant ~= "Default" then
        dungeonStr = dungeonStr .. " (" .. self.selectedVariant .. ")"
    end
    
    -- Remove leading ! to prevent command parsing
    if string.sub(dungeonStr, 1, 1) == "!" then
        dungeonStr = string.sub(dungeonStr, 2)
    end
    
    local mainMessage = dungeonStr .. " completed in " .. self:formatTime(finalTime) .. ". Deaths: " .. self.deathCount
    SendChatMessage(mainMessage, chatType)
    
    -- Combine bosses into readable messages (max ~255 chars per message)
    if table.getn(self.killTimes) > 0 then
        local bossLine = "Bosses: "
        local lineCount = 0
        
        for i = 1, table.getn(self.killTimes) do
            local bossEntry = self.killTimes[i].bossName .. " (" .. self:formatTime(self.killTimes[i].time) .. ")"
            
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

function TurtleDungeonTimer:setupUpdateLoop()
    if self.updateFrame then return end
    
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame.lastUpdate = 0
    self.updateFrame.lastSave = 0
    self.updateFrame:SetScript("OnUpdate", function()
        local timer = TurtleDungeonTimer:getInstance()
        local now = GetTime()
        
        -- Throttle UI updates to once per 0.1 seconds (10 times/sec instead of 60+)
        if now - this.lastUpdate >= 0.1 then
            this.lastUpdate = now
            timer:updateTimer()
        end
        
        -- Save run state every second when timer is running
        if timer.isRunning and now - this.lastSave >= 1.0 then
            this.lastSave = now
            timer:saveLastRun()
        end
    end)
end

function TurtleDungeonTimer:updateTimer()
    if not self.frame then return end
    
    local elapsed = 0
    
    if self.isRunning and self.startTime then
        elapsed = GetTime() - self.startTime
    elseif self.restoredElapsedTime then
        -- Timer is paused but we have restored time from save
        elapsed = self.restoredElapsedTime
    end
    
    if elapsed > 0 and self.frame.timerText then
        self.frame.timerText:SetText(self:formatTime(elapsed))
        self:updateStartButton()  -- Update button text
        
        -- Compare with best time
        local bestTime = self:getBestTime()
        if bestTime then
            if elapsed < bestTime.time then
                self.frame.timerText:SetTextColor(0, 1, 0) -- Green = ahead
            else
                self.frame.timerText:SetTextColor(1, 0.5, 0.5) -- Red = behind
            end
        else
            self.frame.timerText:SetTextColor(1, 1, 1)
        end
    end
    
    -- Update death count
    if self.frame.deathText then
        self.frame.deathText:SetText("" .. self.deathCount)
    end
    
    -- Update world buff indicator
    if self.frame.worldBuffText then
        if self.hasWorldBuffs then
            self.frame.worldBuffText:SetText("[WB]")
        else
            self.frame.worldBuffText:SetText("")
        end
    end
    
    -- Update trash progress bar (calls UI.lua:updateProgressBar)
    self:updateProgressBar()
end
