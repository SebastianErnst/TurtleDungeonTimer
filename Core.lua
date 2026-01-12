-- ============================================================================
-- Turtle Dungeon Timer - Core
-- ============================================================================

TurtleDungeonTimer = {}
TurtleDungeonTimer.__index = TurtleDungeonTimer

local _instance = nil

-- ============================================================================
-- SINGLETON
-- ============================================================================
function TurtleDungeonTimer:getInstance()
    if not _instance then
        _instance = TurtleDungeonTimer:new()
    end
    return _instance
end

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================
function TurtleDungeonTimer:new()
    local self = {}
    setmetatable(self, TurtleDungeonTimer)
    
    -- State variables
    self.startTime = nil
    self.isRunning = false
    self.isCountingDown = false
    self.countdownTime = 0
    
    -- UI references
    self.frame = nil
    self.updateFrame = nil
    
    -- Selection state
    self.selectedDungeon = nil
    self.selectedVariant = nil
    self.bossList = {}
    self.optionalBosses = {} -- Table of optional boss names
    self.killTimes = {}
    self.deathCount = 0
    self.bossListExpanded = true
    self.minimized = false
    self.initialized = false
    
    -- World buff tracking
    self.hasWorldBuffs = false
    self.hasCheckedWorldBuffs = false
    self.worldBuffPlayers = {}
    
    -- Initialize database
    self:initializeDatabase()
    
    return self
end

-- ============================================================================
-- DATABASE INITIALIZATION
-- ============================================================================
function TurtleDungeonTimer:initializeDatabase()
    if not TurtleDungeonTimerDB then
        TurtleDungeonTimerDB = {
            bestTimes = {},
            settings = {
                countdownDuration = 5,
                showSplits = true
            },
            lastSelection = {},
            lastRun = {},
            history = {},
            position = {
                point = "TOP",
                relativeTo = "UIParent",
                relativePoint = "TOP",
                xOfs = 0,
                yOfs = -100
            },
            visible = false
        }
    end
    
    -- Ensure history exists for old saves
    if not TurtleDungeonTimerDB.history then
        TurtleDungeonTimerDB.history = {}
    end
    
    -- Ensure position table exists for old saves
    if not TurtleDungeonTimerDB.position then
        TurtleDungeonTimerDB.position = {
            point = "TOP",
            relativeTo = "UIParent",
            relativePoint = "TOP",
            xOfs = 0,
            yOfs = -100
        }
    end
    
    -- Ensure visible flag exists for old saves
    if TurtleDungeonTimerDB.visible == nil then
        TurtleDungeonTimerDB.visible = false
    end
    
    -- Ensure minimized flag exists for old saves
    if TurtleDungeonTimerDB.minimized == nil then
        TurtleDungeonTimerDB.minimized = false
    end
    
    -- Ensure minimap angle exists for old saves
    if TurtleDungeonTimerDB.minimapAngle == nil then
        TurtleDungeonTimerDB.minimapAngle = 200
    end
    
    -- Ensure lastRun table exists for old saves
    if not TurtleDungeonTimerDB.lastRun then
        TurtleDungeonTimerDB.lastRun = {}
    end
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
function TurtleDungeonTimer:formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds - (mins * 60)
    return string.format("%02d:%02d", mins, secs)
end

function TurtleDungeonTimer:truncateText(text, maxChars)
    if string.len(text) <= maxChars then
        return text
    end
    return string.sub(text, 1, maxChars - 3) .. "..."
end

function TurtleDungeonTimer:getBestTime()
    if not self.selectedDungeon or not self.selectedVariant then return nil end
    if not TurtleDungeonTimerDB.bestTimes[self.selectedDungeon] then return nil end
    return TurtleDungeonTimerDB.bestTimes[self.selectedDungeon][self.selectedVariant]
end

function TurtleDungeonTimer:saveBestTime(totalTime)
    if not self.selectedDungeon or not self.selectedVariant then return end
    
    if not TurtleDungeonTimerDB.bestTimes[self.selectedDungeon] then
        TurtleDungeonTimerDB.bestTimes[self.selectedDungeon] = {}
    end
    
    local current = TurtleDungeonTimerDB.bestTimes[self.selectedDungeon][self.selectedVariant]
    if not current or totalTime < current.time then
        TurtleDungeonTimerDB.bestTimes[self.selectedDungeon][self.selectedVariant] = {
            time = totalTime,
            bossTimes = self.killTimes,
            date = date("%Y-%m-%d %H:%M"),
            deaths = self.deathCount
        }
        return true
    end
    return false
end

-- ============================================================================
-- PUBLIC INTERFACE
-- ============================================================================
function TurtleDungeonTimer:initialize()
    if self.initialized then return end
    self.initialized = true
    
    self:createUI()
    self:setupUpdateLoop()
    self:registerEvents()
    self:initializeSync()
    self:createMinimapButton()
    
    -- Initialize trash scanner
    TDTTrashScanner:initialize()
    
    -- Initialize trash counter
    TDTTrashCounter:initialize()
    
    -- Load last selection
    if TurtleDungeonTimerDB.lastSelection.dungeon then
        self:selectDungeon(TurtleDungeonTimerDB.lastSelection.dungeon)
        if TurtleDungeonTimerDB.lastSelection.variant then
            self:selectVariant(TurtleDungeonTimerDB.lastSelection.variant)
        end
    end
    
    -- Restore visibility state
    if TurtleDungeonTimerDB.visible then
        self:show()
    end
    
    -- Restore minimized state
    if TurtleDungeonTimerDB.minimized then
        self.minimized = true
        self:updateMinimizedState()
    end
    
    -- Restore last run if available
    self:restoreLastRun()
end

function TurtleDungeonTimer:show()
    if self.frame then
        self.frame:Show()
        TurtleDungeonTimerDB.visible = true
    end
end

function TurtleDungeonTimer:hide()
    if self.frame then
        self.frame:Hide()
        TurtleDungeonTimerDB.visible = false
    end
end

function TurtleDungeonTimer:toggle()
    if self.frame then
        if self.frame:IsVisible() then
            self.frame:Hide()
            TurtleDungeonTimerDB.visible = false
        else
            self.frame:Show()
            TurtleDungeonTimerDB.visible = true
        end
    end
end

function TurtleDungeonTimer:saveLastRun()
    if not self.selectedDungeon or not self.selectedVariant then return end
    
    -- Get current trash progress
    local trashProgress, trashKilledHP = 0, 0
    if TDTTrashCounter then
        trashProgress, trashKilledHP = TDTTrashCounter:getProgress()
    end
    
    TurtleDungeonTimerDB.lastRun = {
        dungeon = self.selectedDungeon,
        variant = self.selectedVariant,
        bossList = self.bossList,
        killTimes = self.killTimes,
        deathCount = self.deathCount,
        startTime = self.startTime,
        playerName = self.playerName,
        guildName = self.guildName,
        groupClasses = self.groupClasses,
        hasWorldBuffs = self.hasWorldBuffs or false,
        worldBuffPlayers = self.worldBuffPlayers or {},
        trashProgress = trashProgress,
        trashKilledHP = trashKilledHP
    }
end

function TurtleDungeonTimer:saveToHistory(finalTime, completed)
    if not self.selectedDungeon or not self.selectedVariant then return end
    
    -- Get trash progress if available
    local trashProgress = 0
    local trashRequired = 100
    local dungeonData = self.DUNGEON_DATA[self.selectedDungeon]
    if dungeonData and dungeonData.trashMobs then
        trashProgress = TDTTrashCounter:getProgress()
        trashRequired = dungeonData.trashRequiredPercent or 100
    end
    
    local historyEntry = {
        uuid = self.currentRunUUID or self:generateUUID(),
        dungeon = self.selectedDungeon,
        variant = self.selectedVariant,
        time = finalTime,
        deathCount = self.deathCount,
        killTimes = self.killTimes,
        timestamp = time(),
        date = date("%Y-%m-%d %H:%M"),
        completed = completed or false,
        playerName = self.playerName or "Unknown",
        guildName = self.guildName or "No Guild",
        groupClasses = self.groupClasses or {},
        hasWorldBuffs = self.hasWorldBuffs or false,
        worldBuffPlayers = self.worldBuffPlayers or {},
        trashProgress = trashProgress,
        trashRequired = trashRequired
    }
    
    -- Add to beginning of history
    table.insert(TurtleDungeonTimerDB.history, 1, historyEntry)
    
    -- Keep only last 10 entries
    while table.getn(TurtleDungeonTimerDB.history) > 10 do
        table.remove(TurtleDungeonTimerDB.history)
    end
end

function TurtleDungeonTimer:restoreLastRun()
    local lastRun = TurtleDungeonTimerDB.lastRun
    if not lastRun or not lastRun.dungeon or not lastRun.variant then return end
    
    -- Check if we're viewing the same dungeon
    if self.selectedDungeon == lastRun.dungeon and self.selectedVariant == lastRun.variant then
        self.killTimes = lastRun.killTimes or {}
        self.deathCount = lastRun.deathCount or 0
        self.playerName = lastRun.playerName
        self.guildName = lastRun.guildName
        self.groupClasses = lastRun.groupClasses
        self.hasWorldBuffs = lastRun.hasWorldBuffs or false
        self.worldBuffPlayers = lastRun.worldBuffPlayers or {}
        
        -- Restore trash counter if available
        if lastRun.trashKilledHP and lastRun.trashKilledHP > 0 then
            TDTTrashCounter:prepareDungeon(lastRun.dungeon)
            TDTTrashCounter:addTrashHP(lastRun.trashKilledHP)
        end
        
        -- Update UI with saved data
        if self.frame then
            -- Update death counter
            if self.frame.deathText then
                self.frame.deathText:SetText("" .. self.deathCount)
            end
            
            -- Update timer display from last kill
            if table.getn(self.killTimes) > 0 and self.frame.timerText then
                local finalTime = self.killTimes[table.getn(self.killTimes)].time
                local minutes = math.floor(finalTime / 60)
                local seconds = finalTime - (minutes * 60)
                self.frame.timerText:SetText(string.format("%02d:%02d", minutes, seconds))
            end
            
            -- Update progress bar (shows trash progress including +x%)
            self:updateProgressBar()
            
            -- Update boss rows with kill times
            for i = 1, table.getn(self.killTimes) do
                local killData = self.killTimes[i]
                if killData then
                    self:updateBossRow(killData.index, killData.time, killData.splitTime)
                end
            end
            
            -- Update header if all bosses defeated
            local requiredBosses = self:getRequiredBossCount()
            local requiredKills = self:getRequiredBossKills()
            if requiredKills >= requiredBosses then
                if self.frame.headerBg then
                    self.frame.headerBg:SetBackdropColor(0.1, 0.5, 0.1, 0.8)
                end
                if self.frame.dungeonNameText then
                    self.frame.dungeonNameText:SetTextColor(0, 1, 0)
                end
                if self.frame.timeText then
                    -- Ensure time color is set correctly (green if better than best time)
                    local bestTime = self:getBestTime()
                    if bestTime and table.getn(self.killTimes) > 0 then
                        local finalTime = self.killTimes[table.getn(self.killTimes)].time
                        if finalTime < bestTime.time then
                            self.frame.timeText:SetTextColor(0, 1, 0)
                        else
                            self.frame.timeText:SetTextColor(1, 0.5, 0.5)
                        end
                    end
                end
            end
            
            -- Update button state
            self:updateStartPauseButton()
        end
    end
end
