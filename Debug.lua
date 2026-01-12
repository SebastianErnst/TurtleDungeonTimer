-- ============================================================================
-- Turtle Dungeon Timer - Debug Tools
-- ============================================================================

-- Modulo function for Lua 5.1 compatibility
local function mod(a, b)
    return a - math.floor(a / b) * b
end

TurtleDungeonTimer.debugMode = false
TurtleDungeonTimer.debugFrame = nil

-- ============================================================================
-- DEBUG FRAME CREATION
-- ============================================================================

function TurtleDungeonTimer:createDebugFrame()
    if self.debugFrame then
        self.debugFrame:Show()
        return
    end
    
    -- Create main debug frame
    local frame = CreateFrame("Frame", "TurtleDungeonTimerDebugFrame", UIParent)
    frame:SetWidth(300)
    frame:SetHeight(500)
    frame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    frame:SetBackdropColor(0.1, 0, 0, 0.9) -- Red tint for debug
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    self.debugFrame = frame
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("DEBUG TOOLS")
    title:SetTextColor(1, 0, 0)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    closeBtn:SetWidth(80)
    closeBtn:SetHeight(25)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    closeBtn:SetText("X")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Scroll frame for buttons
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetWidth(260)
    scrollFrame:SetHeight(420)
    scrollFrame:SetPoint("TOP", title, "BOTTOM", 0, -10)
    scrollFrame:EnableMouseWheel()
    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollFrame:GetVerticalScroll()
        local max = scrollFrame:GetVerticalScrollRange()
        local step = 30
        
        if arg1 > 0 then
            scrollFrame:SetVerticalScroll(math.max(0, current - step))
        else
            scrollFrame:SetVerticalScroll(math.min(max, current + step))
        end
    end)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(260)
    scrollChild:SetHeight(1) -- Will grow
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Create buttons
    local yOffset = -10
    local buttonHeight = 30
    local buttonSpacing = 5
    
    -- Helper function to create buttons
    local function createButton(text, onClick)
        local btn = CreateFrame("Button", nil, scrollChild, "GameMenuButtonTemplate")
        btn:SetWidth(240)
        btn:SetHeight(buttonHeight)
        btn:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
        btn:SetText(text)
        btn:SetScript("OnClick", onClick)
        yOffset = yOffset - buttonHeight - buttonSpacing
        return btn
    end
    
    -- === MAIN CONTROLS ===
    createButton("Start/Reset Dungeon", function()
        local timer = TurtleDungeonTimer:getInstance()
        if timer.isRunning then
            timer:performResetDirect()
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Dungeon zurückgesetzt")
        else
            if timer:isGroupLeader() then
                timer:startPreparation()
            else
                timer:start()
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Timer gestartet")
            end
        end
    end)
    
    createButton("Start Countdown (10s)", function()
        local timer = TurtleDungeonTimer:getInstance()
        if timer.isRunning then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Timer läuft bereits!")
            return
        end
        if not timer.selectedDungeon or not timer.selectedVariant then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        
        -- Start countdown as if we entered the zone
        timer:startCountdown(UnitName("player"))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Countdown gestartet!")
    end)
    
    createButton("Start Timer Immediately", function()
        local timer = TurtleDungeonTimer:getInstance()
        if timer.isRunning then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Timer läuft bereits!")
            return
        end
        if not timer.selectedDungeon or not timer.selectedVariant then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        
        -- Start timer directly
        timer:start()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Timer direkt gestartet!")
    end)
    
    createButton("Open Trash List Window", function()
        TDTTrashScanner:showListWindow()
    end)
    createButton("Open Trash List Window", function()
        TDTTrashScanner:showListWindow()
    end)
    
    createButton("Group Status", function()
        local timer = TurtleDungeonTimer:getInstance()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r === GROUP STATUS ===")
        
        local raid = GetNumRaidMembers()
        local party = GetNumPartyMembers()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Raid Members: " .. raid)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Party Members: " .. party)
        
        if raid > 0 then
            for i = 1, raid do
                local name = UnitName("raid" .. i)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r  Raid" .. i .. ": " .. tostring(name))
            end
        elseif party > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r  Player: " .. UnitName("player"))
            for i = 1, party do
                local name = UnitName("party" .. i)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r  Party" .. i .. ": " .. tostring(name))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Solo")
        end
        
        -- World Buffs
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r === WORLD BUFFS ===")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r hasWorldBuffs: " .. tostring(timer.hasWorldBuffs))
        if timer.worldBuffPlayers and next(timer.worldBuffPlayers) then
            local count = 0
            for player, buff in pairs(timer.worldBuffPlayers) do
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r  " .. player .. ": " .. buff)
                count = count + 1
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r Total: " .. count .. " players with world buffs")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r No world buffs detected")
        end
    end)
    
    -- === TRASH DEBUG ===
    createButton("Add 1% Trash", function()
        local timer = TurtleDungeonTimer:getInstance()
        if not timer.selectedDungeon then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        local dungeonData = timer.DUNGEON_DATA[timer.selectedDungeon]
        if not dungeonData or not dungeonData.trashMobs then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Dungeon hat keine Trash-Daten!")
            return
        end
        
        -- Ensure trash counter is started
        if not timer.isRunning then
            TDTTrashCounter:prepareDungeon(timer.selectedDungeon)
        end
        
        local requiredPercent = dungeonData.trashRequiredPercent or 100
        local addHP = (dungeonData.totalTrashHP * requiredPercent / 100) * 0.01
        TDTTrashCounter:addTrashHP(addHP)
        local progress = TDTTrashCounter:getProgress()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r +1% Trash hinzugefügt (Total: " .. string.format("%.2f%%", progress) .. ")")
    end)
    
    createButton("Add 5% Trash", function()
        local timer = TurtleDungeonTimer:getInstance()
        if not timer.selectedDungeon then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        local dungeonData = timer.DUNGEON_DATA[timer.selectedDungeon]
        if not dungeonData or not dungeonData.trashMobs then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Dungeon hat keine Trash-Daten!")
            return
        end
        
        -- Ensure trash counter is started
        if not timer.isRunning then
            TDTTrashCounter:prepareDungeon(timer.selectedDungeon)
        end
        
        local requiredPercent = dungeonData.trashRequiredPercent or 100
        local addHP = (dungeonData.totalTrashHP * requiredPercent / 100) * 0.05
        TDTTrashCounter:addTrashHP(addHP)
        local progress = TDTTrashCounter:getProgress()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r +5% Trash hinzugefügt (Total: " .. string.format("%.2f%%", progress) .. ")")
    end)
    
    createButton("Add 100% Trash", function()
        local timer = TurtleDungeonTimer:getInstance()
        if not timer.selectedDungeon then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        local dungeonData = timer.DUNGEON_DATA[timer.selectedDungeon]
        if not dungeonData or not dungeonData.trashMobs then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Dungeon hat keine Trash-Daten!")
            return
        end
        
        -- Ensure trash counter is started
        if not timer.isRunning then
            TDTTrashCounter:prepareDungeon(timer.selectedDungeon)
        end
        
        local requiredPercent = dungeonData.trashRequiredPercent or 100
        local addHP = (dungeonData.totalTrashHP * requiredPercent / 100) * 1.0
        TDTTrashCounter:addTrashHP(addHP)
        local progress = TDTTrashCounter:getProgress()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r +100% Trash hinzugefügt (Total: " .. string.format("%.2f%%", progress) .. ")")
    end)
    
    -- === BOSS DEBUG ===
    createButton("Kill One Random Boss", function()
        local timer = TurtleDungeonTimer:getInstance()
        
        if not timer.selectedDungeon or not timer.selectedVariant then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        
        if table.getn(timer.bossList) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Keine Bosse geladen!")
            return
        end
        
        -- Find random alive boss
        local aliveBosses = {}
        for i = 1, table.getn(timer.bossList) do
            local boss = timer.bossList[i]
            if type(boss) == "table" and not boss.defeated then
                table.insert(aliveBosses, {index = i, boss = boss})
            end
        end
        
        if table.getn(aliveBosses) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Alle Bosse bereits tot!")
            return
        end
        
        local randomIndex = math.random(1, table.getn(aliveBosses))
        local selected = aliveBosses[randomIndex]
        local bossIndex = selected.index
        local boss = selected.boss
        
        if not timer.isRunning then
            timer:start()
        end
        
        local currentTime = GetTime()
        local elapsedTime = currentTime - (timer.startTime or currentTime)
        
        local lastKillTime = 0
        if table.getn(timer.killTimes) > 0 then
            lastKillTime = timer.killTimes[table.getn(timer.killTimes)].time
        end
        local splitTime = elapsedTime - lastKillTime
        
        table.insert(timer.killTimes, {
            bossName = boss.name,
            time = elapsedTime,
            splitTime = splitTime,
            index = bossIndex
        })
        
        boss.defeated = true
        timer:updateBossRow(bossIndex, elapsedTime, splitTime)
        timer:saveLastRun()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Boss killed: " .. boss.name .. " @ " .. timer:formatTime(elapsedTime))
        
        -- Check if all required bosses are defeated AND trigger trash check
        local requiredBosses = timer:getRequiredBossCount()
        local requiredKills = timer:getRequiredBossKills()
        if requiredKills >= requiredBosses then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r Alle required Bosse defeated!")
            -- Trigger trash check to see if run is complete
            TDTTrashCounter:checkRunCompletion()
        end
    end)
    
    createButton("Kill All Bosses", function()
        local timer = TurtleDungeonTimer:getInstance()
        
        if not timer.selectedDungeon or not timer.selectedVariant then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        
        if table.getn(timer.bossList) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Keine Bosse geladen!")
            return
        end
        
        if not timer.isRunning then
            timer:start()
        end
        
        local currentTime = GetTime()
        local baseTime = timer.startTime or currentTime
        local bossInterval = 30 -- 30 seconds between boss kills
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Töte alle Bosse...")
        
        for i = 1, table.getn(timer.bossList) do
            local boss = timer.bossList[i]
            
            if type(boss) == "table" and not boss.defeated then
                local elapsedTime = (currentTime - baseTime) + (i * bossInterval)
                local lastKillTime = 0
                if table.getn(timer.killTimes) > 0 then
                    lastKillTime = timer.killTimes[table.getn(timer.killTimes)].time
                end
                local splitTime = elapsedTime - lastKillTime
                
                table.insert(timer.killTimes, {
                    bossName = boss.name,
                    time = elapsedTime,
                    splitTime = splitTime,
                    index = i
                })
                
                boss.defeated = true
                timer:updateBossRow(i, elapsedTime, splitTime)
                
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r " .. boss.name .. " @ " .. timer:formatTime(elapsedTime))
            end
        end
        
        timer:saveLastRun()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r Alle Bosse getötet!")
        
        -- Trigger trash check to see if run is complete
        TDTTrashCounter:checkRunCompletion()
    end)
    
    createButton("Finish Run", function()
        local timer = TurtleDungeonTimer:getInstance()
        
        if not timer.selectedDungeon then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        
        -- Start timer if not running
        if not timer.isRunning then
            timer:start()
        end
        
        -- Set trash to 100%
        local dungeonData = timer.DUNGEON_DATA[timer.selectedDungeon]
        if dungeonData and dungeonData.trashMobs then
            local requiredPercent = dungeonData.trashRequiredPercent or 100
            local targetHP = (dungeonData.totalTrashHP * requiredPercent / 100)
            -- Reset first, then add
            TDTTrashCounter:resetProgress(timer.selectedDungeon)
            TDTTrashCounter:addTrashHP(targetHP)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Trash auf 100% gesetzt")
        end
        
        -- Kill all bosses
        if table.getn(timer.bossList) > 0 then
            local currentTime = GetTime()
            local baseTime = timer.startTime or currentTime
            local bossInterval = 30
            
            for i = 1, table.getn(timer.bossList) do
                local boss = timer.bossList[i]
                
                if type(boss) == "table" and not boss.defeated then
                    local elapsedTime = (currentTime - baseTime) + (i * bossInterval)
                    local lastKillTime = 0
                    if table.getn(timer.killTimes) > 0 then
                        lastKillTime = timer.killTimes[table.getn(timer.killTimes)].time
                    end
                    local splitTime = elapsedTime - lastKillTime
                    
                    table.insert(timer.killTimes, {
                        bossName = boss.name,
                        time = elapsedTime,
                        splitTime = splitTime,
                        index = i
                    })
                    
                    boss.defeated = true
                    timer:updateBossRow(i, elapsedTime, splitTime)
                end
            end
        end
        
        timer:saveLastRun()
        
        -- Trigger completion
        timer:onAllBossesDefeated()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r Run abgeschlossen!")
    end)
    
    -- Update scroll child height
    scrollChild:SetHeight(math.abs(yOffset) + 20)
    
    frame:Show()
end

-- ============================================================================
-- DEBUG COMMAND
-- ============================================================================

function TurtleDungeonTimer:toggleDebugMode()
    self.debugMode = not self.debugMode
    
    if self.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Debug Mode AKTIVIERT", 1, 0, 0)
        self:createDebugFrame()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Debug Mode DEAKTIVIERT", 1, 1, 1)
        if self.debugFrame then
            self.debugFrame:Hide()
        end
    end
end

function TurtleDungeonTimer:showDebugFrame()
    if self.debugMode then
        self:createDebugFrame()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Debug Mode ist nicht aktiv. Benutze /tdt debug", 1, 0.5, 0)
    end
end

-- ============================================================================
-- TIMER SCHEDULER (for Reload UI delay)
-- ============================================================================

function TurtleDungeonTimer:ScheduleTimer(callback, delay, repeating)
    if not self.scheduledTimers then
        self.scheduledTimers = {}
        
        -- Create timer frame
        local timerFrame = CreateFrame("Frame")
        timerFrame:SetScript("OnUpdate", function()
            local now = GetTime()
            for id, timer in pairs(TurtleDungeonTimer:getInstance().scheduledTimers) do
                if now >= timer.when then
                    timer.callback()
                    if timer.repeating then
                        timer.when = now + timer.delay
                    else
                        TurtleDungeonTimer:getInstance().scheduledTimers[id] = nil
                    end
                end
            end
        end)
    end
    
    local id = GetTime() .. math.random()
    self.scheduledTimers[id] = {
        callback = callback,
        when = GetTime() + delay,
        delay = delay,
        repeating = repeating
    }
    return id
end
