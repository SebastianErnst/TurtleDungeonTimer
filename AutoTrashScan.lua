-- ============================================================================
-- Turtle Dungeon Timer - Automatic Pull-Based Trash Scanner
-- ============================================================================
-- Scans trash mobs automatically during combat by tracking targets.
-- Cleans up duplicates based on actual mob deaths.

TDTAutoTrashScan = TDTAutoTrashScan or {}

-- ============================================================================
-- Module Variables
-- ============================================================================

local pullScan = {
    active = false,
    enabled = false,
    tempList = {},      -- {name, hp, level, classification, timestamp}
    deathEvents = {},   -- {name, hp, timestamp}
    hpLookup = {},      -- {[mobName] = {hp1, hp2, ...}} for death matching
    lastTargetName = nil,
    lastTargetHP = nil,
    
    -- Raid Mark System (1-8)
    raidMarks = {},     -- {[markIndex] = {name, hp, level, classification, timestamp}}
    usedMarks = {},     -- {[markIndex] = true/false}
    nextMark = 1        -- Next available mark (1-8)
}

-- ============================================================================
-- Core Functions
-- ============================================================================

-- Get next available raid mark (1-8), returns nil if all used
local function getNextAvailableMark()
    for i = 1, 8 do
        if not pullScan.usedMarks[i] then
            return i
        end
    end
    return nil  -- All marks in use
end

-- Free a raid mark for reuse
local function freeRaidMark(markIndex)
    if markIndex and markIndex >= 1 and markIndex <= 8 then
        pullScan.usedMarks[markIndex] = nil
        pullScan.raidMarks[markIndex] = nil
        
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan]|r Freed raid mark " .. markIndex, 0, 1, 1)
        end
    end
end

-- Reset all raid marks
local function resetRaidMarks()
    pullScan.raidMarks = {}
    pullScan.usedMarks = {}
    pullScan.nextMark = 1
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan]|r All raid marks reset", 0, 1, 1)
    end
end

function TDTAutoTrashScan:initialize()
    -- Initialize SavedVariables for auto scan data
    if not TurtleDungeonTimerDB.autoScannedTrash then
        TurtleDungeonTimerDB.autoScannedTrash = {}
    end
    
    -- Auto-enable by default (can be toggled)
    if TurtleDungeonTimerDB.autoScanEnabled == nil then
        TurtleDungeonTimerDB.autoScanEnabled = true
    end
    
    self:createEventFrame()
    
    if TurtleDungeonTimerDB.autoScanEnabled then
        self:enable()
    end
end

function TDTAutoTrashScan:createEventFrame()
    if self.eventFrame then return end
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            TDTAutoTrashScan:onEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            TDTAutoTrashScan:onLeaveCombat()
        elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
            TDTAutoTrashScan:onMobDeath(arg1)
        end
    end)
end

function TDTAutoTrashScan:enable()
    if pullScan.enabled then return end
    
    pullScan.enabled = true
    TurtleDungeonTimerDB.autoScanEnabled = true
    
    -- Register target change event
    if not self.targetFrame then
        self.targetFrame = CreateFrame("Frame")
        self.targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        self.targetFrame:SetScript("OnEvent", function()
            if event == "PLAYER_TARGET_CHANGED" then
                TDTAutoTrashScan:onTargetChanged()
            end
        end)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Auto Scan]|r Target frame created and registered!", 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Auto Scan]|r Target frame already exists!", 0, 1, 0)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Auto Scan]|r Automatic trash scanning enabled!", 0, 1, 0)
end

function TDTAutoTrashScan:disable()
    if not pullScan.enabled then return end
    
    pullScan.enabled = false
    TurtleDungeonTimerDB.autoScanEnabled = false
    
    if self.targetFrame then
        self.targetFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TDT Auto Scan]|r Automatic trash scanning disabled!", 1, 0.5, 0)
end

function TDTAutoTrashScan:toggle()
    if pullScan.enabled then
        self:disable()
    else
        self:enable()
    end
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

function TDTAutoTrashScan:onEnterCombat()
    if not pullScan.enabled then 
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[TDT Auto Scan]|r Scanner is disabled, use /tdt autoscanon", 1, 0.5, 0)
        return 
    end
    
    -- Check if dungeon is selected
    local timer = TurtleDungeonTimer:getInstance()
    if not timer or not timer.selectedDungeon then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[TDT Auto Scan]|r No dungeon selected!", 1, 0.5, 0)
        return
    end
    
    -- Start new pull scan
    pullScan.active = true
    pullScan.tempList = {}
    pullScan.deathEvents = {}
    pullScan.hpLookup = {}
    pullScan.lastTargetName = nil
    pullScan.lastTargetHP = nil
    
    -- Reset raid marks for new pull
    resetRaidMarks()
    
    -- Always show start message
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Auto Scan]|r Pull scan started - tab through mobs to mark them!", 0, 1, 0)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan Debug]|r Dungeon: " .. timer.selectedDungeon, 0, 1, 1)
    end
end

function TDTAutoTrashScan:onLeaveCombat()
    if not pullScan.active then 
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan Debug]|r Left combat but scan was not active", 0, 1, 1)
        end
        return 
    end
    
    pullScan.active = false
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Auto Scan]|r Combat ended - processing data...", 0, 1, 0)
    
    -- Small delay to ensure all death events are processed
    TurtleDungeonTimer:getInstance():scheduleTimer(function()
        TDTAutoTrashScan:processPullData()
        -- Clear all raid marks after processing
        resetRaidMarks()
    end, 0.5, false)
end

function TDTAutoTrashScan:onTargetChanged()
    -- ALWAYS log that event fired (for debugging)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[TDT Auto Scan Debug]|r Target changed event fired", 1, 0, 1)
    end
    
    if not pullScan.enabled then 
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r Scan not enabled", 1, 0, 1)
        end
        return 
    end
    
    if not pullScan.active then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r Scan not active (not in combat?)", 1, 0, 1)
        end
        return
    end
    
    if not UnitExists("target") then
        pullScan.lastTargetName = nil
        pullScan.lastTargetHP = nil
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r No target exists", 1, 0, 1)
        end
        return
    end
    
    -- Don't scan players or already dead mobs
    if UnitIsPlayer("target") then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r Target is player, skipping", 1, 0, 1)
        end
        return
    end
    
    if UnitIsDead("target") then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r Target is dead, skipping", 1, 0, 1)
        end
        return
    end
    
    local name = UnitName("target")
    local hp = UnitHealthMax("target")
    local level = UnitLevel("target")
    local classification = UnitClassification("target")
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r Name: " .. tostring(name) .. ", HP: " .. tostring(hp), 1, 0, 1)
    end
    
    if not name or not hp or hp == 0 then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r Invalid name or HP, skipping", 1, 0, 1)
        end
        return
    end
    
    -- Check if target already has a raid mark
    local existingMark = GetRaidTargetIndex("target")
    if existingMark then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan]|r " .. name .. " already marked (" .. existingMark .. ")", 0, 1, 1)
        end
        return  -- Already marked, skip
    end
    
    -- Get next available raid mark
    local markIndex = getNextAvailableMark()
    if not markIndex then
        -- All 8 marks in use
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[TDT Auto Scan]|r All 8 raid marks in use! Max pull size reached.", 1, 0.5, 0)
        return
    end
    
    -- Apply raid mark to target
    SetRaidTarget("target", markIndex)
    
    -- Store for potential death matching
    pullScan.lastTargetName = name
    pullScan.lastTargetHP = hp
    
    -- Build HP lookup table for death matching
    if not pullScan.hpLookup[name] then
        pullScan.hpLookup[name] = {}
    end
    -- Only add if not already in the lookup for this mob name
    local found = false
    for i, storedHP in ipairs(pullScan.hpLookup[name]) do
        if storedHP == hp then
            found = true
            break
        end
    end
    if not found then
        table.insert(pullScan.hpLookup[name], hp)
    end
    
    -- Store mob data with raid mark
    pullScan.raidMarks[markIndex] = {
        name = name,
        hp = hp,
        level = level,
        classification = classification,
        timestamp = GetTime()
    }
    pullScan.usedMarks[markIndex] = true
    
    -- Add to temp list
    table.insert(pullScan.tempList, {
        name = name,
        hp = hp,
        level = level,
        classification = classification,
        timestamp = GetTime(),
        markIndex = markIndex
    })
    
    -- Count how many mobs are currently marked
    local markedCount = 0
    for i = 1, 8 do
        if pullScan.usedMarks[i] then
            markedCount = markedCount + 1
        end
    end
    
    -- Show scan confirmation with mark icon
    local markIcons = {
        "{star}",     -- 1
        "{circle}",   -- 2
        "{diamond}",  -- 3
        "{triangle}", -- 4
        "{moon}",     -- 5
        "{square}",   -- 6
        "{cross}",    -- 7
        "{skull}"     -- 8
    }
    local iconName = markIcons[markIndex] or "Mark " .. markIndex
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Auto Scan]|r " .. iconName .. " " .. name .. " (" .. markedCount .. "/8)", 0.5, 1, 1)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan Debug]|r HP: " .. hp .. ", Level: " .. (level or "??"), 0, 1, 1)
    end
end

function TDTAutoTrashScan:onMobDeath(deathMessage)
    -- Always log the death message in debug mode
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug Raw Death]|r " .. tostring(deathMessage), 1, 0, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Debug]|r pullScan.active = " .. tostring(pullScan.active), 1, 0, 1)
    end
    
    if not pullScan.active then 
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Debug]|r Scan not active, death ignored!", 1, 0, 0)
        end
        return 
    end
    
    -- Parse death message: "X stirbt." or "X dies."
    local _, _, mobName = string.find(deathMessage, "(.+) stirbt%.")
    if not mobName then
        _, _, mobName = string.find(deathMessage, "(.+) dies%.")
    end
    
    if not mobName then 
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Debug]|r Failed to parse mob name from death message!", 1, 0, 0)
        end
        return 
    end
    
    -- Try multiple methods to get exact HP:
    -- 1. Check raid marks to match name+HP (but don't free them yet!)
    -- 2. If this mob is currently our target
    -- 3. If we scanned this mob earlier (HP lookup table)
    local exactHP = nil
    
    -- First check raid marks for exact match (read-only, no freeing)
    for markIndex = 1, 8 do
        if pullScan.raidMarks[markIndex] and pullScan.raidMarks[markIndex].name == mobName then
            exactHP = pullScan.raidMarks[markIndex].hp
            if TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r HP from raid mark " .. markIndex .. ": " .. tostring(exactHP), 0, 1, 1)
            end
            break
        end
    end
    
    -- Fallback to other methods if no raid mark matched
    if not exactHP then
        if pullScan.lastTargetName == mobName then
            -- Method 2: Current target
            exactHP = pullScan.lastTargetHP
            if TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r HP from current target: " .. tostring(exactHP), 0, 1, 1)
            end
        elseif pullScan.hpLookup[mobName] then
            -- Method 3: Lookup from scanned mobs
            local hpList = pullScan.hpLookup[mobName]
            if table.getn(hpList) == 1 then
                -- Only one HP value seen for this mob name → use it
                exactHP = hpList[1]
                if TurtleDungeonTimerDB.debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r HP from lookup (single): " .. tostring(exactHP), 0, 1, 1)
                end
            else
                -- Multiple HP values → can't determine which one died
                if TurtleDungeonTimerDB.debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Multiple HP values for " .. mobName .. ", cannot determine exact HP", 1, 0.5, 0)
                end
            end
        end
    end
    
    table.insert(pullScan.deathEvents, {
        name = mobName,
        hp = exactHP,
        timestamp = GetTime()
    })
    
    if TurtleDungeonTimerDB.debug then
        local hpStr = exactHP and (" (" .. exactHP .. " HP)") or " (HP unknown)"
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Death Tracked]|r " .. mobName .. hpStr .. " (Total: " .. table.getn(pullScan.deathEvents) .. ")", 0, 1, 0)
    end
end

-- ============================================================================
-- Data Processing
-- ============================================================================

function TDTAutoTrashScan:processPullData()
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan]|r Processing pull data...", 0, 1, 1)
    end
    
    if table.getn(pullScan.tempList) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[TDT Auto Scan]|r No mobs were scanned (did you tab through them?)", 1, 0.5, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan]|r Scanned: " .. table.getn(pullScan.tempList) .. " mobs, Deaths: " .. table.getn(pullScan.deathEvents), 0, 1, 1)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan Debug]|r Starting aggregation...", 0, 1, 1)
    end
    
    -- Aggregate temp list by name+HP (handle duplicates from tabbing)
    local aggregated = {}
    for i, mob in ipairs(pullScan.tempList) do
        local key = mob.name .. "_" .. mob.hp
        if not aggregated[key] then
            aggregated[key] = {
                name = mob.name,
                hp = mob.hp,
                level = mob.level,
                classification = mob.classification,
                count = 0
            }
        end
        aggregated[key].count = aggregated[key].count + 1
    end
    
    if TurtleDungeonTimerDB.debug then
        local aggCount = 0
        for k, v in pairs(aggregated) do
            aggCount = aggCount + 1
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Aggregated to " .. aggCount .. " unique mobs", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Calling matchDeathsToScans()...", 0, 1, 1)
    end
    
    -- Process deaths to clean up duplicates
    local cleanedData = self:matchDeathsToScans(aggregated, pullScan.deathEvents)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r matchDeathsToScans returned " .. table.getn(cleanedData) .. " mobs", 0, 1, 1)
    end
    
    -- Save to permanent database
    self:saveToDatabase(cleanedData)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r saveToDatabase completed", 0, 1, 1)
    end
    
    -- Show summary
    self:showPullSummary(cleanedData)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r showPullSummary completed", 0, 1, 1)
    end
    
    -- Refresh list window if open
    if self.listFrame and self.listFrame:IsShown() then
        self:refreshListWindow()
    end
end

function TDTAutoTrashScan:matchDeathsToScans(aggregated, deaths)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r matchDeathsToScans() called", 0, 1, 1)
    end
    
    -- ⚠️ NEW SIMPLE LOGIC: Only count deaths for mobs we actually scanned!
    -- Build a set of mob names we saw during the pull
    local scannedMobs = {}
    for key, mob in pairs(aggregated) do
        if not scannedMobs[mob.name] then
            scannedMobs[mob.name] = {
                hp = mob.hp,  -- Use first HP variant we saw
                level = mob.level,
                classification = mob.classification
            }
        end
    end
    
    -- Count deaths only for mobs we scanned
    local deathCounts = {}
    local totalDeathEvents = table.getn(deaths)
    
    for i, death in ipairs(deaths) do
        if scannedMobs[death.name] then
            -- We scanned this mob! Count the death
            deathCounts[death.name] = (deathCounts[death.name] or 0) + 1
        else
            -- We never scanned this mob - ignore the death
            if TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Ignoring death (not scanned): " .. death.name, 1, 0.5, 0)
            end
        end
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Total death events: " .. totalDeathEvents, 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Counted deaths (from scanned mobs):", 0, 1, 1)
        for name, count in pairs(deathCounts) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. name .. ": " .. count .. " deaths", 1, 1, 1)
        end
    end
    
    -- Build result: Only mobs we scanned AND that died
    local cleaned = {}
    
    for mobName, mobData in pairs(scannedMobs) do
        local deathCount = deathCounts[mobName] or 0
        
        if deathCount > 0 then
            -- This mob was scanned AND died - save it!
            table.insert(cleaned, {
                name = mobName,
                hp = mobData.hp,
                level = mobData.level,
                classification = mobData.classification,
                count = deathCount
            })
            if TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Saving: " .. mobName .. " x" .. deathCount, 0, 1, 1)
            end
        else
            -- Scanned but didn't die (e.g., boss, escaped mob)
            if TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Skipped (scanned but didn't die): " .. mobName, 1, 0.5, 0)
            end
        end
    end
    
    -- Final validation
    local totalMobsCount = 0
    for i, mob in ipairs(cleaned) do
        totalMobsCount = totalMobsCount + mob.count
    end
    
    local countedDeaths = 0
    for name, count in pairs(deathCounts) do
        countedDeaths = countedDeaths + count
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Debug]|r Final: " .. table.getn(cleaned) .. " unique mobs, " .. totalMobsCount .. " total instances (counted deaths: " .. countedDeaths .. ")", 0, 1, 0)
    end
    
    return cleaned
end

function TDTAutoTrashScan:saveToDatabase(cleanedData)
    if table.getn(cleanedData) == 0 then
        return
    end
    
    local timer = TurtleDungeonTimer:getInstance()
    local currentDungeon = timer.selectedDungeon
    if not currentDungeon then
        return
    end
    
    -- Initialize dungeon storage
    if not TurtleDungeonTimerDB.autoScannedTrash[currentDungeon] then
        TurtleDungeonTimerDB.autoScannedTrash[currentDungeon] = {}
    end
    
    local saved = TurtleDungeonTimerDB.autoScannedTrash[currentDungeon]
    local newMobs = 0
    local updatedMobs = 0
    
    -- Merge with existing data
    for i, mob in ipairs(cleanedData) do
        local found = false
        
        -- Check if mob already exists (same name + HP)
        for j, existingMob in ipairs(saved) do
            if existingMob.name == mob.name and existingMob.hp == mob.hp then
                -- Update existing entry
                existingMob.count = (existingMob.count or 1) + mob.count
                existingMob.level = mob.level
                existingMob.classification = mob.classification
                found = true
                updatedMobs = updatedMobs + 1
                break
            end
        end
        
        if not found then
            -- Add new entry
            table.insert(saved, {
                name = mob.name,
                hp = mob.hp,
                level = mob.level,
                classification = mob.classification,
                count = mob.count
            })
            newMobs = newMobs + 1
        end
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan Debug]|r Saved: " .. newMobs .. " new, " .. updatedMobs .. " updated", 0, 1, 1)
    end
end

function TDTAutoTrashScan:showPullSummary(cleanedData)
    if table.getn(cleanedData) == 0 then
        return
    end
    
    local totalCount = 0
    for i, mob in ipairs(cleanedData) do
        totalCount = totalCount + (mob.count or 1)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Auto Scan]|r Pull captured: " .. table.getn(cleanedData) .. " unique mobs, " .. totalCount .. " total", 0, 1, 0)
end

-- ============================================================================
-- Data Management
-- ============================================================================

function TDTAutoTrashScan:clearCurrentDungeon()
    local timer = TurtleDungeonTimer:getInstance()
    local currentDungeon = timer.selectedDungeon
    if not currentDungeon then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Auto Scan]|r No dungeon selected!", 1, 0, 0)
        return
    end
    
    if TurtleDungeonTimerDB.autoScannedTrash[currentDungeon] then
        local count = table.getn(TurtleDungeonTimerDB.autoScannedTrash[currentDungeon])
        TurtleDungeonTimerDB.autoScannedTrash[currentDungeon] = {}
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TDT Auto Scan]|r Cleared " .. count .. " mobs for " .. currentDungeon, 1, 0.8, 0)
        
        if self.listFrame and self.listFrame:IsShown() then
            self:refreshListWindow()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TDT Auto Scan]|r No data for " .. currentDungeon, 1, 0.8, 0)
    end
end

function TDTAutoTrashScan:exportToDataFormat()
    if not TurtleDungeonTimerDB.autoScannedTrash then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Auto Scan]|r No data to export!", 1, 0, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Auto Scan Data Export (Data.lua format)", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
    
    for dungeon, mobs in pairs(TurtleDungeonTimerDB.autoScannedTrash) do
        if table.getn(mobs) > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff-- " .. dungeon, 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff{", 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff    trashMobs = {", 1, 1, 1)
            
            -- Sort by HP descending
            local sortedMobs = {}
            for i, mob in ipairs(mobs) do
                table.insert(sortedMobs, mob)
            end
            table.sort(sortedMobs, function(a, b) return a.hp > b.hp end)
            
            for i, mob in ipairs(sortedMobs) do
                local classStr = ""
                if mob.classification and mob.classification ~= "normal" then
                    classStr = ", classification = \"" .. mob.classification .. "\""
                end
                
                local levelStr = ""
                if mob.level and mob.level > 0 then
                    levelStr = ", level = " .. mob.level
                end
                
                local countStr = ", count = " .. (mob.count or 1)
                
                local line = "        {name = \"" .. mob.name .. "\", hp = " .. mob.hp .. countStr .. levelStr .. classStr .. "},"
                DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. line, 1, 1, 1)
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff    },", 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff},", 1, 1, 1)
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Export complete!", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
end

-- ============================================================================
-- UI - List Window (Fixed lag issue by reusing frames!)
-- ============================================================================

function TDTAutoTrashScan:showListWindow()
    if self.listFrame and self.listFrame:IsShown() then
        self.listFrame:Hide()
        return
    end
    
    if not self.listFrame then
        self:createListWindow()
    end
    
    self:refreshListWindow()
    self:updateDungeonLabel()
    self.listFrame:Show()
end

function TDTAutoTrashScan:createListWindow()
    local frame = CreateFrame("Frame", "TDTAutoTrashScanListFrame", UIParent)
    frame:SetWidth(300)
    frame:SetHeight(600)
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:SetFrameStrata("DIALOG")
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("Auto Trash Scanner")
    title:SetTextColor(0, 1, 0.5)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Status indicator
    local statusLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -35, -10)
    frame.statusLabel = statusLabel
    
    -- Dungeon dropdown button
    local dungeonBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    dungeonBtn:SetWidth(260)
    dungeonBtn:SetHeight(25)
    dungeonBtn:SetPoint("TOP", title, "BOTTOM", 0, -10)
    dungeonBtn:SetText("Select Dungeon...")
    dungeonBtn:SetScript("OnClick", function()
        TDTAutoTrashScan:showDungeonMenu(this)
    end)
    frame.dungeonBtn = dungeonBtn
    
    -- Dungeon label (shows selected dungeon)
    local dungeonLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonLabel:SetPoint("TOP", dungeonBtn, "BOTTOM", 0, -5)
    dungeonLabel:SetTextColor(0.7, 0.7, 0.7)
    frame.dungeonLabel = dungeonLabel
    
    -- Button row
    local buttonY = -90
    
    -- Toggle Auto Scan button
    local toggleBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    toggleBtn:SetWidth(130)
    toggleBtn:SetHeight(25)
    toggleBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, buttonY)
    toggleBtn:SetText("Toggle Auto Scan")
    toggleBtn:SetScript("OnClick", function()
        TDTAutoTrashScan:toggle()
        TDTAutoTrashScan:updateStatusLabel()
    end)
    
    -- Clear button
    local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clearBtn:SetWidth(130)
    clearBtn:SetHeight(25)
    clearBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, buttonY)
    clearBtn:SetText("Clear Dungeon")
    clearBtn:SetScript("OnClick", function()
        TDTAutoTrashScan:clearCurrentDungeon()
    end)
    
    -- Header
    local headerBg = frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -125)
    headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -125)
    headerBg:SetHeight(20)
    headerBg:SetTexture(0.2, 0.2, 0.2, 0.8)
    
    local nameHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("TOPLEFT", headerBg, "TOPLEFT", 5, -3)
    nameHeader:SetText("Name")
    nameHeader:SetTextColor(1, 1, 0)
    
    local countHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countHeader:SetPoint("TOPRIGHT", headerBg, "TOPRIGHT", -70, -3)
    countHeader:SetText("Count")
    countHeader:SetTextColor(1, 1, 0)
    
    local hpHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpHeader:SetPoint("TOPRIGHT", headerBg, "TOPRIGHT", -5, -3)
    hpHeader:SetText("HP")
    hpHeader:SetTextColor(1, 1, 0)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "TDTAutoTrashScanScrollFrame", frame)
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -150)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 15)
    scrollFrame:EnableMouseWheel()
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(250)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Mouse wheel handler
    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        local step = 20
        
        if arg1 > 0 then
            scrollFrame:SetVerticalScroll(math.max(0, current - step))
        else
            scrollFrame:SetVerticalScroll(math.min(maxScroll, current + step))
        end
    end)
    
    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild
    
    -- Pre-create row pool (FIX FOR LAG ISSUE!)
    scrollChild.rowPool = {}
    scrollChild.activeRows = {}
    
    self.listFrame = frame
    self:updateStatusLabel()
end

function TDTAutoTrashScan:updateStatusLabel()
    if not self.listFrame then return end
    
    local status = self.listFrame.statusLabel
    if pullScan.enabled then
        status:SetText("● ON")
        status:SetTextColor(0, 1, 0)
    else
        status:SetText("○ OFF")
        status:SetTextColor(0.5, 0.5, 0.5)
    end
end

function TDTAutoTrashScan:getOrCreateRow(scrollChild)
    -- Reuse existing row from pool (FIX FOR LAG!)
    if table.getn(scrollChild.rowPool) > 0 then
        local row = table.remove(scrollChild.rowPool)
        row:Show()
        return row
    end
    
    -- Create new row
    local row = CreateFrame("Frame", nil, scrollChild)
    row:SetWidth(250)
    row:SetHeight(20)
    
    -- Background texture
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row.bg:SetTexture(0.1, 0.1, 0.1, 0.3)
    
    -- Delete button (X)
    row.deleteBtn = CreateFrame("Button", nil, row)
    row.deleteBtn:SetWidth(16)
    row.deleteBtn:SetHeight(16)
    row.deleteBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.deleteBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    
    -- Decrease count button (-)
    row.decreaseBtn = CreateFrame("Button", nil, row)
    row.decreaseBtn:SetWidth(16)
    row.decreaseBtn:SetHeight(16)
    row.decreaseBtn:SetPoint("RIGHT", row.deleteBtn, "LEFT", -2, 0)
    row.decreaseBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    row.decreaseBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    row.decreaseBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    
    -- Increase count button (+)
    row.increaseBtn = CreateFrame("Button", nil, row)
    row.increaseBtn:SetWidth(16)
    row.increaseBtn:SetHeight(16)
    row.increaseBtn:SetPoint("RIGHT", row.decreaseBtn, "LEFT", -2, 0)
    row.increaseBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    row.increaseBtn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    row.increaseBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    
    -- HP text
    row.hpText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.hpText:SetPoint("RIGHT", row.increaseBtn, "LEFT", -4, 0)
    row.hpText:SetWidth(50)
    row.hpText:SetJustifyH("RIGHT")
    row.hpText:SetTextColor(1, 0.5, 0.5)
    
    -- Count text
    row.countText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.countText:SetPoint("RIGHT", row.hpText, "LEFT", -4, 0)
    row.countText:SetWidth(25)
    row.countText:SetJustifyH("RIGHT")
    row.countText:SetTextColor(0.5, 1, 0.5)
    
    -- Name text
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.nameText:SetPoint("RIGHT", row.countText, "LEFT", -4, 0)
    row.nameText:SetJustifyH("LEFT")
    
    return row
end

function TDTAutoTrashScan:refreshListWindow()
    if not self.listFrame then return end
    
    local scrollChild = self.listFrame.scrollChild
    
    -- Return all active rows to pool (FIX FOR LAG!)
    if scrollChild.activeRows then
        for i, row in ipairs(scrollChild.activeRows) do
            row:Hide()
            row:ClearAllPoints()
            table.insert(scrollChild.rowPool, row)
        end
    end
    scrollChild.activeRows = {}
    
    -- Get current dungeon
    local timer = TurtleDungeonTimer:getInstance()
    local currentDungeon = timer.selectedDungeon
    if not currentDungeon then
        self.listFrame.dungeonLabel:SetText("No dungeon selected")
        return
    end
    
    self.listFrame.dungeonLabel:SetText(currentDungeon)
    
    -- Get mobs for this dungeon
    if not TurtleDungeonTimerDB.autoScannedTrash or not TurtleDungeonTimerDB.autoScannedTrash[currentDungeon] then
        scrollChild:SetHeight(1)
        return
    end
    
    local mobs = TurtleDungeonTimerDB.autoScannedTrash[currentDungeon]
    if table.getn(mobs) == 0 then
        scrollChild:SetHeight(1)
        return
    end
    
    -- Sort by name, then by HP
    local sortedMobs = {}
    for i, mob in ipairs(mobs) do
        table.insert(sortedMobs, mob)
    end
    table.sort(sortedMobs, function(a, b)
        if a.name == b.name then
            return a.hp > b.hp
        end
        return a.name < b.name
    end)
    
    -- Create/reuse rows
    local yOffset = 0
    local rowHeight = 20
    
    for i, mob in ipairs(sortedMobs) do
        local row = self:getOrCreateRow(scrollChild)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        
        -- Capture mob values in local scope for closures
        local mobName = mob.name
        local mobHP = mob.hp
        local mobRef = mob
        
        -- Update background
        if mod(i, 2) == 0 then
            row.bg:Show()
        else
            row.bg:Hide()
        end
        
        -- Update texts
        row.nameText:SetText(mobName)
        row.hpText:SetText(mobHP)
        row.countText:SetText(mobRef.count or 1)
        
        -- Update delete button handler
        row.deleteBtn:SetScript("OnClick", function()
            local timer = TurtleDungeonTimer:getInstance()
            local currentDungeon = timer.selectedDungeon
            if currentDungeon and TurtleDungeonTimerDB.autoScannedTrash[currentDungeon] then
                for idx, m in ipairs(TurtleDungeonTimerDB.autoScannedTrash[currentDungeon]) do
                    if m.name == mobName and m.hp == mobHP then
                        table.remove(TurtleDungeonTimerDB.autoScannedTrash[currentDungeon], idx)
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Auto Scan]|r Deleted: " .. mobName .. " (" .. mobHP .. " HP)", 1, 0, 0)
                        break
                    end
                end
            end
            TDTAutoTrashScan:refreshListWindow()
        end)
        
        -- Update decrease button handler
        row.decreaseBtn:SetScript("OnClick", function()
            if (mobRef.count or 1) > 1 then
                mobRef.count = (mobRef.count or 1) - 1
                DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TDT Auto Scan]|r Count decreased: " .. mobName .. " (Count: " .. mobRef.count .. ")", 1, 0.8, 0)
            else
                local timer = TurtleDungeonTimer:getInstance()
                local currentDungeon = timer.selectedDungeon
                if currentDungeon and TurtleDungeonTimerDB.autoScannedTrash[currentDungeon] then
                    for idx, m in ipairs(TurtleDungeonTimerDB.autoScannedTrash[currentDungeon]) do
                        if m.name == mobName and m.hp == mobHP then
                            table.remove(TurtleDungeonTimerDB.autoScannedTrash[currentDungeon], idx)
                            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Auto Scan]|r Deleted: " .. mobName, 1, 0, 0)
                            break
                        end
                    end
                end
            end
            TDTAutoTrashScan:refreshListWindow()
        end)
        
        -- Update increase button handler
        row.increaseBtn:SetScript("OnClick", function()
            mobRef.count = (mobRef.count or 1) + 1
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Auto Scan]|r Count increased: " .. mobName .. " (Count: " .. mobRef.count .. ")", 0, 1, 0)
            TDTAutoTrashScan:refreshListWindow()
        end)
        
        table.insert(scrollChild.activeRows, row)
        yOffset = yOffset - rowHeight
    end
    
    scrollChild:SetHeight(math.max(1, math.abs(yOffset) + 10))
    self.listFrame.scrollFrame:SetVerticalScroll(0)
end

-- ============================================================================
-- Dungeon Selection Menu
-- ============================================================================

function TDTAutoTrashScan:showDungeonMenu(button)
    -- Toggle: if already visible, close it
    if self.listFrame.dungeonMenu and self.listFrame.dungeonMenu:IsVisible() then
        self:hideDungeonMenu()
        return
    end
    
    -- Close existing menu
    self:hideDungeonMenu()
    
    -- Get dungeon list from TurtleDungeonTimer
    local timer = TurtleDungeonTimer:getInstance()
    if not timer or not timer.DUNGEON_DATA then
        return
    end
    
    -- Build sorted dungeon list
    local dungeonList = {}
    for dungeonKey, dungeonData in pairs(timer.DUNGEON_DATA) do
        table.insert(dungeonList, {
            key = dungeonKey,
            name = dungeonData.name or dungeonKey,
            variantCount = 0
        })
    end
    
    -- Count variants for each dungeon
    for i, dungeon in ipairs(dungeonList) do
        local variantCount = 0
        if timer.DUNGEON_DATA[dungeon.key].variants then
            for _, _ in pairs(timer.DUNGEON_DATA[dungeon.key].variants) do
                variantCount = variantCount + 1
            end
        end
        dungeon.variantCount = variantCount
    end
    
    -- Sort alphabetically
    table.sort(dungeonList, function(a, b)
        return a.name < b.name
    end)
    
    -- Create menu frame
    local numDungeons = table.getn(dungeonList)
    local btnHeight = 25
    local menuHeight = numDungeons * btnHeight + 8
    
    local menu = CreateFrame("Frame", nil, self.listFrame)
    menu:SetWidth(200)
    menu:SetHeight(menuHeight)
    menu:SetPoint("TOP", button, "BOTTOM", 0, -2)
    menu:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    menu:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    menu:SetFrameStrata("FULLSCREEN")
    menu:Show()
    
    self.listFrame.dungeonMenu = menu
    
    -- Create buttons for each dungeon
    for i = 1, numDungeons do
        local dungeon = dungeonList[i]
        
        local btn = CreateFrame("Button", nil, menu)
        btn:SetWidth(185)
        btn:SetHeight(btnHeight)
        btn:SetPoint("TOP", menu, "TOP", 0, -4 - (i-1) * btnHeight)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        text:SetText(dungeon.name)
        text:SetJustifyH("LEFT")
        
        btn:SetScript("OnEnter", function()
            this:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
            this:SetBackdropColor(0.4, 0.4, 0.4, 0.8)
        end)
        
        btn:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
        end)
        
        btn:SetScript("OnClick", function()
            if dungeon.variantCount > 1 then
                TDTAutoTrashScan:showVariantMenu(this, dungeon.key)
            else
                -- Only one variant, select directly
                TDTAutoTrashScan:selectDungeon(dungeon.key)
            end
        end)
    end
end

function TDTAutoTrashScan:showVariantMenu(parentBtn, dungeonKey)
    -- Close existing variant menu
    if self.listFrame.variantMenu then
        self.listFrame.variantMenu:Hide()
        self.listFrame.variantMenu = nil
    end
    
    local timer = TurtleDungeonTimer:getInstance()
    if not timer or not timer.DUNGEON_DATA[dungeonKey] then
        return
    end
    
    local variants = timer.DUNGEON_DATA[dungeonKey].variants
    if not variants then return end
    
    -- Build variant list
    local variantList = {}
    for variantName, _ in pairs(variants) do
        table.insert(variantList, variantName)
    end
    
    table.sort(variantList)
    
    local numVariants = table.getn(variantList)
    local btnHeight = 25
    local menuHeight = numVariants * btnHeight + 8
    
    local submenu = CreateFrame("Frame", nil, self.listFrame.dungeonMenu)
    submenu:SetWidth(150)
    submenu:SetHeight(menuHeight)
    submenu:SetPoint("TOPLEFT", parentBtn, "TOPRIGHT", 0, 0)
    submenu:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    submenu:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    submenu:SetFrameStrata("FULLSCREEN")
    submenu:Show()
    
    self.listFrame.variantMenu = submenu
    
    -- Create buttons for each variant
    for i = 1, numVariants do
        local variantName = variantList[i]
        
        local btn = CreateFrame("Button", nil, submenu)
        btn:SetWidth(135)
        btn:SetHeight(btnHeight)
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
            TDTAutoTrashScan:selectDungeonVariant(dungeonKey, variantName)
        end)
    end
end

function TDTAutoTrashScan:selectDungeon(dungeonKey)
    local timer = TurtleDungeonTimer:getInstance()
    if not timer then return end
    
    -- If dungeon has only one variant, select it
    local variants = timer.DUNGEON_DATA[dungeonKey].variants
    if variants then
        for variantName, _ in pairs(variants) do
            self:selectDungeonVariant(dungeonKey, variantName)
            return
        end
    end
end

function TDTAutoTrashScan:selectDungeonVariant(dungeonKey, variantName)
    local timer = TurtleDungeonTimer:getInstance()
    if not timer then return end
    
    -- Update main timer selection
    timer:selectDungeon(dungeonKey)
    timer:selectVariant(variantName)
    
    -- Update UI
    self:updateDungeonLabel()
    self:hideDungeonMenu()
    self:refreshListWindow()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TDT Auto Scan]|r Dungeon selected: " .. dungeonKey .. " / " .. variantName, 0, 1, 1)
end

function TDTAutoTrashScan:updateDungeonLabel()
    if not self.listFrame then return end
    
    local timer = TurtleDungeonTimer:getInstance()
    if timer and timer.selectedDungeon and timer.selectedVariant then
        local dungeonName = timer.selectedDungeon
        local variantName = timer.selectedVariant
        
        -- Update button text
        self.listFrame.dungeonBtn:SetText(dungeonName)
        
        -- Update label
        self.listFrame.dungeonLabel:SetText(variantName)
    else
        self.listFrame.dungeonBtn:SetText("Select Dungeon...")
        self.listFrame.dungeonLabel:SetText("")
    end
end

function TDTAutoTrashScan:hideDungeonMenu()
    if self.listFrame.dungeonMenu then
        self.listFrame.dungeonMenu:Hide()
        self.listFrame.dungeonMenu = nil
    end
    if self.listFrame.variantMenu then
        self.listFrame.variantMenu:Hide()
        self.listFrame.variantMenu = nil
    end
end

