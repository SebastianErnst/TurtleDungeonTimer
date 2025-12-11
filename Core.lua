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
    self.killTimes = {}
    self.deathCount = 0
    self.bossListExpanded = true
    
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
            lastSelection = {}
        }
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
        print("NEW RECORD! " .. self:formatTime(totalTime) .. " (Previous: " .. (current and self:formatTime(current.time) or "none") .. ")")
        return true
    end
    return false
end

-- ============================================================================
-- PUBLIC INTERFACE
-- ============================================================================
function TurtleDungeonTimer:initialize()
    self:createUI()
    self:setupUpdateLoop()
    self:registerEvents()
    
    -- Load last selection
    if TurtleDungeonTimerDB.lastSelection.dungeon then
        self:selectDungeon(TurtleDungeonTimerDB.lastSelection.dungeon)
        if TurtleDungeonTimerDB.lastSelection.variant then
            self:selectVariant(TurtleDungeonTimerDB.lastSelection.variant)
        end
    end
    
    print("Turtle Dungeon Timer initialized! Use /tdt to toggle the window.")
end

function TurtleDungeonTimer:show()
    if self.frame then
        self.frame:Show()
    end
end

function TurtleDungeonTimer:hide()
    if self.frame then
        self.frame:Hide()
    end
end

function TurtleDungeonTimer:toggle()
    if self.frame then
        if self.frame:IsVisible() then
            self.frame:Hide()
        else
            self.frame:Show()
        end
    end
end
