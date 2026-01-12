-- ============================================================================
-- Turtle Dungeon Timer - Event Handlers
-- ============================================================================

function TurtleDungeonTimer:registerEvents()
    -- Register combat log event
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
        self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH")
        self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        -- Register party member combat events
        self.eventFrame:RegisterEvent("UNIT_COMBAT")
        self.eventFrame:SetScript("OnEvent", function()
            if (event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" or event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH") and arg1 then
                TurtleDungeonTimer:getInstance():onCombatLog(arg1)
            elseif event == "PLAYER_REGEN_DISABLED" then
                -- Player entered combat - broadcast to group
                TurtleDungeonTimer:getInstance():broadcastCombatStart()
            elseif event == "UNIT_COMBAT" then
                -- Any unit in party/raid enters combat
                local unit = arg1
                if unit and (string.find(unit, "party") or string.find(unit, "raid") or unit == "player") then
                    TurtleDungeonTimer:getInstance():broadcastCombatStart()
                end
            end
        end)
    end
    
    -- Register death event
    if not self.deathEventFrame then
        self.deathEventFrame = CreateFrame("Frame")
        self.deathEventFrame:RegisterEvent("PLAYER_DEAD")
        self.deathEventFrame:SetScript("OnEvent", function()
            if event == "PLAYER_DEAD" then
                TurtleDungeonTimer:getInstance():broadcastDeath()
            end
        end)
    end
end

function TurtleDungeonTimer:onCombatLog(msg)
    if not self.isRunning then return end
    
    -- Only track kills made by the player
    -- Pattern: "You have slain [Mob Name]!"
    local _, _, name = string.find(msg, "You have slain (.+)!")
    
    if not name then return end
    
    -- Debug output
    if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r Player killed: " .. name)
    end
    
    -- Broadcast the kill to the group
    self:broadcastBossKill(name)
    self:broadcastTrashKill(name)
    
    -- Also process locally (sender doesn't receive own addon messages)
    self:onBossKilled(name)
    if TDTTrashCounter then
        TDTTrashCounter:onMobKilled(name)
    end
end

function TurtleDungeonTimer:onBossKilled(name)
    if not self.isRunning then return end
    
    -- Check if this is one of our boss targets
    for i = 1, table.getn(self.bossList) do
        local boss = self.bossList[i]
        local bossName = type(boss) == "table" and boss.name or boss
        
        -- Debug output
        if TurtleDungeonTimerDB and TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r Comparing '" .. name .. "' with boss " .. i .. ": '" .. bossName .. "'")
        end
        
        if name == bossName then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Turtle Dungeon Timer]|r Boss kill detected: " .. bossName)
            
            -- Check if already killed
            local alreadyKilled = false
            for j = 1, table.getn(self.killTimes) do
                if self.killTimes[j].index == i then
                    alreadyKilled = true
                    break
                end
            end
            
            if not alreadyKilled then
                local elapsed = GetTime() - self.startTime
                local splitTime = 0
                
                if table.getn(self.killTimes) > 0 then
                    splitTime = elapsed - self.killTimes[table.getn(self.killTimes)].time
                else
                    splitTime = elapsed
                end
                
                table.insert(self.killTimes, {
                    bossName = bossName,
                    time = elapsed,
                    index = i,
                    splitTime = splitTime
                })
                
                -- Mark boss as defeated if it's a table
                if type(boss) == "table" then
                    boss.defeated = true
                end
                
                -- Update UI
                self:updateBossRow(i, elapsed, splitTime)
                
                -- Check if all bosses are dead
                local requiredBosses = self:getRequiredBossCount()
                local requiredKills = self:getRequiredBossKills()
                if requiredKills >= requiredBosses then
                    self:onAllBossesDefeated()
                end
                
                break
            end
        end
    end
end

function TurtleDungeonTimer:broadcastDeath()
    -- Get player name
    local playerName = UnitName("player")
    
    -- Broadcast death to group
    self:broadcastPlayerDeath(playerName)
    
    -- Also process locally (sender doesn't receive own addon messages)
    self:onPlayerDeath(playerName)
end

function TurtleDungeonTimer:onPlayerDeath(playerName)
    -- Auto-start timer if not running but dungeon is selected
    if not self.isRunning and self.selectedDungeon and self.selectedVariant then
        -- Start timer automatically on first death
        self:start()
    end
    
    if not self.isRunning then return end
    
    self.deathCount = self.deathCount + 1
    
    -- Update death counter in UI
    if self.frame and self.frame.deathText then
        self.frame.deathText:SetText("" .. self.deathCount)
    end
    
    -- Save progress
    self:saveLastRun()
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Debug]|r Player death counted: " .. playerName)
    end
end

function TurtleDungeonTimer:broadcastCombatStart()
    -- Only broadcast if timer is not already running
    if self.isRunning then
        return  -- Timer already running, no need to broadcast
    end
    
    -- Broadcast combat start to group
    self:broadcastTimerStart()
    
    -- Also process locally (sender doesn't receive own addon messages)
    self:onCombatStart()
end

function TurtleDungeonTimer:onCombatStart()
    -- Auto-start timer when entering combat if:
    -- 1. Timer is not already running
    -- 2. We have a dungeon selected
    if not self.isRunning and self.selectedDungeon and self.selectedVariant then
        self:start()
    end
end

function TurtleDungeonTimer:onAllBossesDefeated()
    -- Check if trash requirement is also met (if dungeon has trash data)
    local dungeonData = TurtleDungeonTimer.DUNGEON_DATA[self.selectedDungeon]
    if dungeonData and dungeonData.trashMobs then
        if not TDTTrashCounter:isTrashComplete() then
            -- Bosse sind tot, aber Trash nicht komplett
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Alle Bosse besiegt! Trash noch nicht komplett.", 1, 1, 0)
            return  -- Timer läuft weiter
        end
    end
    
    -- Alle Bosse + Trash (falls vorhanden) sind komplett
    self.isRunning = false
    local finalTime = GetTime() - self.startTime
    
    -- Update progress bar (shows 100% or 100% (+x%) if overage)
    self:updateProgressBar()
    
    -- Broadcast timer completion to group
    self:broadcastTimerComplete(finalTime)
    
    self:saveBestTime(finalTime)
    self:saveLastRun()
    self:saveToHistory(finalTime, true) -- Mark as completed
    
    -- Update button text back to START
    self:updateStartPauseButton()
    
    -- Highlight dungeon name
    if self.frame and self.frame.headerBg then
        self.frame.headerBg:SetBackdropColor(0.1, 0.5, 0.1, 0.8)
    end
    if self.frame and self.frame.dungeonNameText then
        self.frame.dungeonNameText:SetTextColor(0, 1, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r |cFF00FF00Run komplett! Alle Bosse + Trash besiegt!|r", 1, 1, 0)
end

function TurtleDungeonTimer:showDungeonSwitchDialog(newDungeonName)
    -- Create confirmation dialog
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(350)
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
    dialog:SetBackdropColor(0, 0, 0, 0.95)
    dialog:SetFrameStrata("DIALOG")
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("Neuer Dungeon erkannt")
    title:SetTextColor(1, 0.82, 0)
    
    -- Message
    local message = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", title, "BOTTOM", 0, -10)
    message:SetWidth(310)
    message:SetText("Du betrittst " .. newDungeonName .. ".\n\nAktuellen Run resetten?")
    message:SetJustifyH("CENTER")
    
    -- Yes Button
    local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    yesButton:SetWidth(100)
    yesButton:SetHeight(30)
    yesButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -105, 15)
    yesButton:SetText("Ja")
    yesButton:SetScript("OnClick", function()
        dialog:Hide()
        local timer = TurtleDungeonTimer:getInstance()
        timer:performResetSilent()
        timer:selectDungeon(newDungeonName)
        if timer.frame and not timer.frame:IsVisible() then
            timer.frame:Show()
            TurtleDungeonTimerDB.visible = true
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. newDungeonName .. " ausgewählt. Timer startet beim ersten Kampf!", 1, 1, 0)
    end)
    
    -- No Button
    local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    noButton:SetWidth(100)
    noButton:SetHeight(30)
    noButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", 105, 15)
    noButton:SetText("Nein")
    noButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:showExportBeforeResetDialog()
    -- Create confirmation dialog
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(300)
    dialog:SetHeight(120)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    dialog:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dialog:SetFrameStrata("DIALOG")
    
    local text = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", dialog, "TOP", 0, -20)
    text:SetText("Möchtest du deinen Run\nexportieren?")
    
    local exportButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    exportButton:SetWidth(120)
    exportButton:SetHeight(25)
    exportButton:SetPoint("BOTTOM", dialog, "BOTTOM", -65, 15)
    exportButton:SetText("Exportieren")
    exportButton:SetScript("OnClick", function()
        dialog:Hide()
        TurtleDungeonTimer:getInstance():showExportDialog()
        TurtleDungeonTimer:getInstance():performReset()
    end)
    
    local skipButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    skipButton:SetWidth(120)
    skipButton:SetHeight(25)
    skipButton:SetPoint("BOTTOM", dialog, "BOTTOM", 65, 15)
    skipButton:SetText("Überspringen")
    skipButton:SetScript("OnClick", function()
        dialog:Hide()
        TurtleDungeonTimer:getInstance():performReset()
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:updateBossRow(index, elapsed, splitTime)
    if not self.frame or not self.frame.bossRows then
        return
    end
    
    -- Don't update if list is collapsed
    if not self.bossListExpanded then
        return
    end
    
    -- Direct index access (new UI has bossRows matching bossList order)
    local row = self.frame.bossRows[index]
    if not row or not row.time then
        return
    end
    
    -- Update kill time
    local minutes = math.floor(elapsed / 60)
    local seconds = elapsed - (minutes * 60)
    row.time:SetText(string.format("%02d:%02d", minutes, seconds))
    
    -- Update colors to green for defeated
    row.name:SetTextColor(0.8, 1, 0.8)
    row.time:SetTextColor(0.8, 1, 0.8)
end
