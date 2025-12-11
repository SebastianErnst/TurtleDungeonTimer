-- ============================================================================
-- Turtle Dungeon Timer - Event Handlers
-- ============================================================================

function TurtleDungeonTimer:registerEvents()
    -- Register combat log event
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
        self.eventFrame:SetScript("OnEvent", function()
            if event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" and arg1 then
                TurtleDungeonTimer:getInstance():onCombatLog(arg1)
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
    
    local name = string.match(msg, "(.+) dies%.")
    if not name then return end
    
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
                
                print("Boss " .. i .. ": " .. name .. " killed at " .. self:formatTime(elapsed))
                
                -- Check if all bosses are dead
                if table.getn(self.killTimes) >= table.getn(self.bossList) then
                    self:onAllBossesDefeated()
                end
                
                break
            end
        end
    end
end

function TurtleDungeonTimer:onDeath()
    if not self.isRunning then return end
    
    self.deathCount = self.deathCount + 1
    print("Death recorded! Total deaths: " .. self.deathCount)
end

function TurtleDungeonTimer:onAllBossesDefeated()
    self.isRunning = false
    local finalTime = GetTime() - self.startTime
    print("All bosses defeated! Total time: " .. self:formatTime(finalTime))
    
    self:saveBestTime(finalTime)
    
    -- Highlight dungeon name
    if self.frame and self.frame.headerBg then
        self.frame.headerBg:SetBackdropColor(0.1, 0.5, 0.1, 0.8)
    end
    if self.frame and self.frame.dungeonNameText then
        self.frame.dungeonNameText:SetTextColor(0, 1, 0)
    end
end

function TurtleDungeonTimer:updateBossRow(index, elapsed, splitTime)
    if not self.frame or not self.frame.bossRows or not self.frame.bossRows[index] then
        return
    end
    
    local timeStr = self:formatTime(elapsed)
    if TurtleDungeonTimerDB.settings.showSplits and splitTime > 0 then
        timeStr = timeStr .. " (+" .. self:formatTime(splitTime) .. ")"
    end
    
    self.frame.bossRows[index].timeText:SetText(timeStr)
    self.frame.bossRows[index]:SetBackdropColor(0.1, 0.5, 0.1, 0.8)
    if self.frame.bossRows[index].checkmark then
        self.frame.bossRows[index].checkmark:Show()
    end
end
