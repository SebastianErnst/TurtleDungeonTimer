-- ============================================================================
-- Turtle Dungeon Timer - Event Handlers
-- ============================================================================

function TurtleDungeonTimer:registerEvents()
    -- Register combat log event
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
        self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH")
        self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        -- Register party member combat events
        self.eventFrame:RegisterEvent("UNIT_COMBAT")
        self.eventFrame:SetScript("OnEvent", function()
            if (event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" or event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH") and arg1 then
                TurtleDungeonTimer:getInstance():onCombatLog(arg1)
            elseif event == "PLAYER_REGEN_DISABLED" then
                TurtleDungeonTimer:getInstance():onCombatStart()
            elseif event == "UNIT_COMBAT" then
                -- Any unit in party/raid enters combat
                local unit = arg1
                if unit and (string.find(unit, "party") or string.find(unit, "raid") or unit == "player") then
                    TurtleDungeonTimer:getInstance():onCombatStart()
                end
            elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
                TurtleDungeonTimer:getInstance():onZoneChanged()
            end
        end)
    end
    
    -- Register death event
    if not self.deathEventFrame then
        self.deathEventFrame = CreateFrame("Frame")
        self.deathEventFrame:RegisterEvent("PLAYER_DEAD")
        self.deathEventFrame:SetScript("OnEvent", function()
            if event == "PLAYER_DEAD" then
                TurtleDungeonTimer:getInstance():onDeath()
            end
        end)
    end
end

function TurtleDungeonTimer:onCombatLog(msg)
    if not self.isRunning then return end
    
    -- Extract name from death message using string.find (Lua 5.0 compatible)
    -- Support both "X dies." and "X has died."
    local _, _, name = string.find(msg, "(.+) dies%.")
    if not name then
        _, _, name = string.find(msg, "(.+) has died%.")
    end
    if not name then return end
    
    -- Check if this is a group member death
    local isGroupMemberDeath = false
    local playerName = UnitName("player")
    
    -- Check if it's the player (but skip - handled by PLAYER_DEAD event)
    if name == playerName then
        -- Don't double-count own death, PLAYER_DEAD handles this
        return
    end
    
    -- Check raid members
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local memberName = UnitName("raid" .. i)
            if memberName and memberName == name then
                isGroupMemberDeath = true
                break
            end
        end
    -- Check party members
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local memberName = UnitName("party" .. i)
            if memberName and memberName == name then
                isGroupMemberDeath = true
                break
            end
        end
    end
    
    -- If it's a group member death, count it
    if isGroupMemberDeath then
        self.deathCount = self.deathCount + 1
        
        -- Update death counter in UI
        if self.frame and self.frame.deathText then
            self.frame.deathText:SetText("Deaths: " .. self.deathCount)
        end
        
        -- Save progress
        self:saveLastRun()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. name .. " ist gestorben (Deaths: " .. self.deathCount .. ")", 1, 0.5, 0)
    end
    
    -- Check if this is one of our boss targets
    for i = 1, table.getn(self.bossList) do
        if name == self.bossList[i] then
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
                    bossName = name,
                    time = elapsed,
                    index = i,
                    splitTime = splitTime
                })
                
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

function TurtleDungeonTimer:onDeath()
    -- Auto-start timer if not running but dungeon is selected
    if not self.isRunning and self.selectedDungeon and self.selectedVariant then
        -- Start timer automatically on first death
        self:start()
    end
    
    if not self.isRunning then return end
    
    self.deathCount = self.deathCount + 1
    
    -- Update death counter in UI
    if self.frame and self.frame.deathText then
        self.frame.deathText:SetText("Deaths: " .. self.deathCount)
    end
    
    -- Save progress
    self:saveLastRun()
end

function TurtleDungeonTimer:onCombatStart()
    -- Auto-start timer when entering combat if:
    -- 1. Timer is not already running
    -- 2. We have a dungeon selected
    if not self.isRunning and self.selectedDungeon and self.selectedVariant then
        -- Simply start without zone check - user selected the dungeon, so trust them
        self:start()
    end
end

function TurtleDungeonTimer:onZoneChanged()
    local zoneName = GetRealZoneText()
    local subZoneName = GetSubZoneText()
    
    -- Timer läuft weiter, auch wenn man die Zone verlässt (z.B. beim Tod)
    -- Der Spieler muss den Timer manuell stoppen mit STOP oder RESET
    
    -- Try to match zone or subzone with dungeon names
    for dungeonName, dungeonData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
        if dungeonName ~= "!Test Mode" and not dungeonData.isHeader then
            -- Check if zone or subzone matches dungeon name
            if zoneName == dungeonName or subZoneName == dungeonName then
                -- Only auto-select if no dungeon is currently selected or different dungeon
                if not self.selectedDungeon or self.selectedDungeon ~= dungeonName then
                    self:selectDungeon(dungeonName)
                    -- Show the frame
                    if self.frame and not self.frame:IsVisible() then
                        self.frame:Show()
                        TurtleDungeonTimerDB.visible = true
                    end
                    -- Send chat message
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. dungeonName .. " erkannt. Timer startet beim ersten Kampf!", 1, 1, 0)
                end
                return
            end
            
            -- Also check partial matches for some dungeons
            -- (e.g. "Blackrock Depths" zone might be "Blackrock Mountain")
            if string.find(zoneName, dungeonName) or string.find(dungeonName, zoneName) then
                if string.len(zoneName) > 5 and string.len(dungeonName) > 5 then
                    -- Only auto-select if no dungeon is currently selected or different dungeon
                    if not self.selectedDungeon or self.selectedDungeon ~= dungeonName then
                        self:selectDungeon(dungeonName)
                        -- Show the frame
                        if self.frame and not self.frame:IsVisible() then
                            self.frame:Show()
                            TurtleDungeonTimerDB.visible = true
                        end
                        -- Send chat message
                        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. dungeonName .. " erkannt. Timer startet beim ersten Kampf!", 1, 1, 0)
                    end
                    return
                end
            end
        end
    end
end

function TurtleDungeonTimer:onAllBossesDefeated()
    self.isRunning = false
    local finalTime = GetTime() - self.startTime
    
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
    
    -- Find the boss row by index (which corresponds to the original bossList)
    local bossName = self.bossList[index]
    local rowIndex = nil
    
    -- Find which row has this boss
    for i = 1, table.getn(self.frame.bossRows) do
        if self.frame.bossRows[i].bossName == bossName then
            rowIndex = i
            break
        end
    end
    
    if not rowIndex or not self.frame.bossRows[rowIndex] then
        return
    end
    
    local timeStr = self:formatTime(elapsed)
    if TurtleDungeonTimerDB.settings.showSplits and splitTime > 0 then
        timeStr = timeStr .. " (+" .. self:formatTime(splitTime) .. ")"
    end
    
    self.frame.bossRows[rowIndex].timeText:SetText(timeStr)
    
    -- Optional bosses get a different color when killed
    local isOptional = self.optionalBosses[bossName]
    
    if isOptional then
        self.frame.bossRows[rowIndex]:SetBackdropColor(0.1, 0.3, 0.4, 0.8) -- Blueish for optional
    else
        self.frame.bossRows[rowIndex]:SetBackdropColor(0.1, 0.5, 0.1, 0.8) -- Green for required
    end
    
    if self.frame.bossRows[rowIndex].checkmark then
        self.frame.bossRows[rowIndex].checkmark:Show()
    end
end
