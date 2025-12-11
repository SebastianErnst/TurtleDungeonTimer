-- ============================================================================
-- Turtle Dungeon Timer - Timer Logic
-- ============================================================================

function TurtleDungeonTimer:start()
    if not self.selectedDungeon or not self.selectedVariant then
        print("Please select a dungeon and variant first!")
        return
    end
    
    if table.getn(self.bossList) == 0 then
        print("No bosses configured for this dungeon!")
        return
    end
    
    -- Start countdown
    self.isCountingDown = true
    self.countdownTime = GetTime() + TurtleDungeonTimerDB.settings.countdownDuration
    self.killTimes = {}
    self.deathCount = 0
    
    -- Reset UI
    self:resetUI()
    
    print("Countdown starting: " .. TurtleDungeonTimerDB.settings.countdownDuration .. " seconds...")
end

function TurtleDungeonTimer:stop()
    self.isRunning = false
    self.isCountingDown = false
    
    local finalTime = 0
    if self.startTime then
        finalTime = GetTime() - self.startTime
    end
    
    print("Timer stopped! Total time: " .. self:formatTime(finalTime))
    print("Kills: " .. table.getn(self.killTimes) .. "/" .. table.getn(self.bossList))
    print("Deaths: " .. self.deathCount)
end

function TurtleDungeonTimer:report(chatType)
    if not self.startTime then
        print("No timer data to report!")
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
    
    for i = 1, table.getn(self.killTimes) do
        local bossMessage = i .. ". " .. self.killTimes[i].bossName .. " " .. self:formatTime(self.killTimes[i].time)
        SendChatMessage(bossMessage, chatType)
    end
    
    print("Report sent to " .. chatType)
end

function TurtleDungeonTimer:setupUpdateLoop()
    if self.updateFrame then return end
    
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function()
        TurtleDungeonTimer:getInstance():updateTimer()
    end)
end

function TurtleDungeonTimer:updateTimer()
    if not self.frame then return end
    
    if self.isCountingDown then
        local remaining = self.countdownTime - GetTime()
        if remaining <= 0 then
            self.isCountingDown = false
            self.isRunning = true
            self.startTime = GetTime()
            if self.frame.timeText then
                self.frame.timeText:SetTextColor(1, 1, 1)
            end
            print("TIMER STARTED!")
        else
            if self.frame.timeText then
                self.frame.timeText:SetText(string.format("%.0f", math.ceil(remaining)))
                self.frame.timeText:SetTextColor(1, 1, 0)
            end
        end
    elseif self.isRunning and self.startTime then
        local elapsed = GetTime() - self.startTime
        if self.frame.timeText then
            self.frame.timeText:SetText(self:formatTime(elapsed))
            
            -- Compare with best time
            local bestTime = self:getBestTime()
            if bestTime then
                if elapsed < bestTime.time then
                    self.frame.timeText:SetTextColor(0, 1, 0) -- Green = ahead
                else
                    self.frame.timeText:SetTextColor(1, 0.5, 0.5) -- Red = behind
                end
            else
                self.frame.timeText:SetTextColor(1, 1, 1)
            end
        end
    end
    
    -- Update death count
    if self.frame.deathText then
        self.frame.deathText:SetText("Deaths: " .. self.deathCount)
    end
end
