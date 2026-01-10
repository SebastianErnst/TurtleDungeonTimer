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
    
    -- Timer Controls
    createButton("START Timer", function()
        TurtleDungeonTimer:getInstance():start()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Timer gestartet")
    end)
    
    createButton("STOP Timer", function()
        TurtleDungeonTimer:getInstance():stop()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Timer gestoppt")
    end)
    
    createButton("RESET Timer (Direct)", function()
        TurtleDungeonTimer:getInstance():performResetDirect()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Timer zurückgesetzt")
    end)
    
    -- World Buff Testing
    createButton("Scan World Buffs NOW", function()
        local timer = TurtleDungeonTimer:getInstance()
        
        -- Do the actual world buff scan
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r === WORLD BUFF SCAN ===")
        timer:markRunWithWorldBuffs()
        
        -- Print results immediately
        if timer.worldBuffPlayers and next(timer.worldBuffPlayers) then
            local count = 0
            for player, buff in pairs(timer.worldBuffPlayers) do
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r  " .. player .. ": " .. buff)
                count = count + 1
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r Total: " .. count .. " players with world buffs")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r No world buffs found")
        end
    end)
    
    createButton("Print World Buff Status", function()
        local timer = TurtleDungeonTimer:getInstance()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r hasWorldBuffs: " .. tostring(timer.hasWorldBuffs))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r hasCheckedWorldBuffs: " .. tostring(timer.hasCheckedWorldBuffs))
        if timer.worldBuffPlayers then
            local count = 0
            for player, buff in pairs(timer.worldBuffPlayers) do
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r  " .. player .. ": " .. buff)
                count = count + 1
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Total players with buffs: " .. count)
        end
    end)
    
    -- Boss Testing
    createButton("Fake Boss Kill (First Boss)", function()
        local timer = TurtleDungeonTimer:getInstance()
        
        if not timer.selectedDungeon or not timer.selectedVariant then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Kein Dungeon ausgewählt!")
            return
        end
        
        if table.getn(timer.bossList) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Keine Bosse geladen!")
            return
        end
        
        local boss = timer.bossList[1]
        if not boss or type(boss) ~= "table" then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Boss data invalid!")
            return
        end
        
        if boss.defeated then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Boss bereits besiegt!")
            return
        end
        
        local currentTime = GetTime()
        local elapsedTime = 0
        if timer.startTime then
            elapsedTime = currentTime - timer.startTime
        else
            elapsedTime = 60 -- 1 minute default if no timer
        end
        
        local lastKillTime = 0
        if table.getn(timer.killTimes) > 0 then
            lastKillTime = timer.killTimes[table.getn(timer.killTimes)].time
        end
        local splitTime = elapsedTime - lastKillTime
        
        table.insert(timer.killTimes, {
            bossName = boss.name,
            time = elapsedTime,
            splitTime = splitTime
        })
        
        boss.defeated = true
        
        -- Update boss row UI using the official function
        timer:updateBossRow(1, elapsedTime, splitTime)
        
        timer:saveLastRun()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Fake Boss Kill: " .. tostring(boss.name) .. " (" .. timer:formatTime(elapsedTime) .. ")")
        
        -- Check if all required bosses are defeated
        local requiredBosses = timer:getRequiredBossCount()
        local requiredKills = timer:getRequiredBossKills()
        if requiredKills >= requiredBosses then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r Alle required Bosse defeated!")
            timer:onAllBossesDefeated()
        end
    end)
    
    createButton("Fake ALL Boss Kills", function()
        local timer = TurtleDungeonTimer:getInstance()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r === FAKE ALL BOSS KILLS ===")
        
        if not timer.selectedDungeon or timer.selectedDungeon == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Error: Kein Dungeon ausgewählt!")
            return
        end
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Dungeon: " .. timer.selectedDungeon)
        
        if table.getn(timer.bossList) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Error: Boss-Liste ist leer!")
            return
        end
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Bosses: " .. table.getn(timer.bossList))
        
        if not timer.isRunning then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[DEBUG]|r Timer nicht aktiv - starte Timer...")
            timer:start()
        end
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Timer running: " .. tostring(timer.isRunning))
        
        local currentTime = GetTime()
        local baseTime = timer.startTime or currentTime
        local bossInterval = 30 -- 30 Sekunden zwischen Bosskills
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Beginne Boss Kills...")
        
        for i = 1, table.getn(timer.bossList) do
            local boss = timer.bossList[i]
            
            if type(boss) ~= "table" then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Boss " .. i .. " hat falsches Format: " .. type(boss))
                break
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Boss " .. i .. ": " .. boss.name .. " (defeated=" .. tostring(boss.defeated) .. ")")
            
            if not boss.defeated then
                local elapsedTime = (currentTime - baseTime) + (i * bossInterval)
                local lastKillTime = 0
                if table.getn(timer.killTimes) > 0 then
                    lastKillTime = timer.killTimes[table.getn(timer.killTimes)].time
                end
                local splitTime = elapsedTime - lastKillTime
                
                table.insert(timer.killTimes, {
                    bossName = boss.name,
                    time = elapsedTime,
                    splitTime = splitTime
                })
                
                boss.defeated = true
                timer:updateBossRow(i, elapsedTime, splitTime)
                
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r " .. i .. ". " .. boss.name .. " killed @ " .. timer:formatTime(elapsedTime))
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[DEBUG]|r " .. i .. ". " .. boss.name .. " already defeated, skipping")
            end
        end
        
        timer:saveLastRun()
        
        -- Check if all required bosses are defeated
        local requiredBosses = timer:getRequiredBossCount()
        local requiredKills = timer:getRequiredBossKills()
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Required: " .. requiredBosses .. ", Kills: " .. requiredKills)
        if requiredKills >= requiredBosses then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r Alle required Bosse defeated! Run completed!")
            timer:onAllBossesDefeated()
        end
    end)
    
    createButton("Fake Death", function()
        local timer = TurtleDungeonTimer:getInstance()
        timer.deathCount = timer.deathCount + 1
        if timer.frame and timer.frame.deathText then
            timer.frame.deathText:SetText("" .. timer.deathCount)
        end
        timer:saveLastRun()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Fake Death hinzugefügt. Total: " .. timer.deathCount)
    end)
    
    -- State Debugging
    createButton("Print Current State", function()
        local timer = TurtleDungeonTimer:getInstance()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r === CURRENT STATE ===")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r isRunning: " .. tostring(timer.isRunning))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r selectedDungeon: " .. tostring(timer.selectedDungeon))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r selectedVariant: " .. tostring(timer.selectedVariant))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r deathCount: " .. tostring(timer.deathCount))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r killTimes count: " .. table.getn(timer.killTimes))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r bossList count: " .. table.getn(timer.bossList))
        if timer.startTime then
            local elapsed = GetTime() - timer.startTime
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Elapsed time: " .. string.format("%.1f", elapsed) .. "s")
        end
    end)
    
    createButton("Print Boss List", function()
        local timer = TurtleDungeonTimer:getInstance()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r === BOSS LIST ===")
        if table.getn(timer.bossList) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Keine Bosse geladen!")
            return
        end
        
        -- Check format
        local firstBoss = timer.bossList[1]
        local format = type(firstBoss)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Format: " .. format .. " (" .. table.getn(timer.bossList) .. " Bosse)")
        
        for i = 1, table.getn(timer.bossList) do
            local boss = timer.bossList[i]
            
            if type(boss) == "string" then
                -- Old format - just strings
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[DEBUG]|r " .. i .. ". " .. boss .. " |cFFFF0000[OLD STRING FORMAT - RELOAD NEEDED!]|r")
            elseif type(boss) == "table" then
                -- New format - proper tables
                local status = boss.defeated and "[DEFEATED]" or "[ALIVE]"
                local optional = boss.optional and "[OPTIONAL]" or "[REQUIRED]"
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG]|r " .. i .. ". " .. tostring(boss.name) .. " " .. status .. " " .. optional)
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r " .. i .. ". UNKNOWN TYPE: " .. type(boss))
            end
        end
    end)
    
    -- UI Testing
    createButton("Toggle Main Frame", function()
        TurtleDungeonTimer:getInstance():toggleWindow()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Main Frame toggled")
    end)
    
    createButton("Toggle Minimize", function()
        TurtleDungeonTimer:getInstance():toggleMinimized()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Minimize toggled")
    end)
    
    createButton("Reset UI", function()
        TurtleDungeonTimer:getInstance():resetUI()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r UI zurückgesetzt")
    end)
    
    -- Export/History Testing
    createButton("Test Export", function()
        TurtleDungeonTimer:getInstance():showExportDialog()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Export Dialog geöffnet")
    end)
    
    createButton("Force Save to History", function()
        local timer = TurtleDungeonTimer:getInstance()
        if table.getn(timer.killTimes) > 0 then
            local finalTime = timer.killTimes[table.getn(timer.killTimes)].time
            timer:saveToHistory(finalTime, true)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Run in Historie gespeichert")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Keine Kill-Daten zum Speichern!")
        end
    end)
    
    -- === TRASH SCANNER SECTION ===
    createButton("", function() end) -- Spacer
    
    createButton("SCAN Current Target", function()
        TDTTrashScanner:scanCurrentTarget()
    end)
    
    createButton("Show Trash List Window", function()
        TDTTrashScanner:showListWindow()
    end)
    
    createButton("Show Trash Stats", function()
        TDTTrashScanner:showStats()
    end)
    
    createButton("EXPORT Trash Data", function()
        TDTTrashScanner:exportToChat()
    end)
    
    createButton("Clear Current Dungeon", function()
        TDTTrashScanner:clearCurrentDungeon()
    end)
    
    createButton("Clear ALL Trash Data", function()
        TDTTrashScanner:clearAllData()
    end)
    
    -- Trash Counter Debug
    createButton("Start Trash Counter", function()
        TDTTrashCounter:debugStart("The Stockade")
    end)
    
    createButton("Kill Test Mob", function()
        TDTTrashCounter:debugKill("Defias Prisoner")
    end)
    
    createButton("Show Trash Progress", function()
        TDTTrashCounter:debugShow()
    end)
    
    createButton("Toggle Progress UI", function()
        if TDTTrashCounter.progressFrame and TDTTrashCounter.progressFrame:IsVisible() then
            TDTTrashCounter:hideUI()
        else
            TDTTrashCounter:showUI()
        end
    end)
    
    createButton("Show History Dropdown", function()
        TurtleDungeonTimer:getInstance():updateHistoryDropdown()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r History Dropdown aktualisiert")
    end)
    
    -- SavedVariables Testing
    createButton("Print SavedVariables", function()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r === SAVED VARIABLES ===")
        if TurtleDungeonTimerDB then
            if TurtleDungeonTimerDB.lastRun then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r lastRun exists")
            end
            if TurtleDungeonTimerDB.history then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r history entries: " .. table.getn(TurtleDungeonTimerDB.history))
            end
            if TurtleDungeonTimerDB.bestTimes then
                local count = 0
                for _ in pairs(TurtleDungeonTimerDB.bestTimes) do
                    count = count + 1
                end
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r bestTimes dungeons: " .. count)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r TurtleDungeonTimerDB not found!")
        end
    end)
    
    createButton("Clear History", function()
        if TurtleDungeonTimerDB and TurtleDungeonTimerDB.history then
            TurtleDungeonTimerDB.history = {}
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Historie geleert")
        end
    end)
    
    createButton("Clear Best Times", function()
        if TurtleDungeonTimerDB and TurtleDungeonTimerDB.bestTimes then
            TurtleDungeonTimerDB.bestTimes = {}
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Best Times geleert")
        end
    end)
    
    -- Group Testing
    createButton("Print Group Info", function()
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
    end)
    
    createButton("Check Addon Users", function()
        TurtleDungeonTimer:getInstance():checkForAddons()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Addon-Check gesendet")
    end)
    
    createButton("Print Addon Users", function()
        local timer = TurtleDungeonTimer:getInstance()
        local count = timer:getAddonUserCount()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Addon Users: " .. count)
        for player, _ in pairs(timer.playersWithAddon) do
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r  " .. player)
        end
    end)
    
    -- UUID Testing
    createButton("Generate UUID", function()
        local uuid = TurtleDungeonTimer:getInstance():generateUUID()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Generated UUID: " .. uuid)
    end)
    
    -- Utility
    createButton("Reload UI", function()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG]|r Reloading UI in 2 seconds...")
        local timer = TurtleDungeonTimer:getInstance()
        timer:ScheduleTimer(function()
            ReloadUI()
        end, 2, false)
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
