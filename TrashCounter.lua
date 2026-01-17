-- ============================================================================
-- Turtle Dungeon Timer - Trash Counter System
-- ============================================================================
-- Mythic+ style trash counter using weighted average HP for mobs with same name

TDTTrashCounter = TDTTrashCounter or {}

-- ============================================================================
-- Module Variables
-- ============================================================================

local currentDungeon = nil
local killedTrashHP = 0
local progressFrame = nil
local recentKills = {}  -- Track recent kills to prevent double counting: {mobName = timestamp}
local lastUIUpdate = 0  -- Throttle UI updates
local UI_UPDATE_INTERVAL = 0.1  -- Update UI max once per 0.1 seconds

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Build weighted average lookup table for a dungeon
-- Formula: For mobs with same name: sum(hp × count) / sum(count)
local function buildTrashLookup(variantData)
    if not variantData.trashMobs then
        return nil
    end
    
    local lookup = {}
    local nameData = {}  -- Temporary: {name = {totalHP = x, totalCount = y}}
    
    -- First pass: Aggregate HP and counts by name
    for i, mob in ipairs(variantData.trashMobs) do
        local name = mob.name
        if not nameData[name] then
            nameData[name] = {totalHP = 0, totalCount = 0}
        end
        nameData[name].totalHP = nameData[name].totalHP + (mob.hp * mob.count)
        nameData[name].totalCount = nameData[name].totalCount + mob.count
    end
    
    -- Second pass: Calculate weighted average
    for name, data in pairs(nameData) do
        lookup[name] = data.totalHP / data.totalCount
    end
    
    return lookup
end

-- Calculate current progress percentage (absolute)
local function calculateProgress()
    if not currentDungeon or not currentDungeon.totalTrashHP or currentDungeon.totalTrashHP == 0 then
        return 0
    end
    
    return (killedTrashHP / currentDungeon.totalTrashHP) * 100
end

-- Calculate normalized progress (relative to requirement, 0-100%)
local function calculateNormalizedProgress()
    if not currentDungeon or not currentDungeon.totalTrashHP or currentDungeon.totalTrashHP == 0 then
        return 0
    end
    
    local required = currentDungeon.trashRequiredPercent or 100
    local progress = (killedTrashHP / currentDungeon.totalTrashHP) * 100
    
    -- Normalize to requirement: progress / required * 100
    -- Example: 25% of 50% required = 50% on bar
    -- Note: Can exceed 100% to show overage
    local normalized = (progress / required) * 100
    
    return normalized
end

-- Get color based on normalized progress
local function getProgressColor(normalizedProgress)
    if normalizedProgress >= 100 then
        return 0, 1, 0  -- Green (complete)
    else
        return 0.3, 0.7, 1  -- Light blue (in progress)
    end
end

-- Format HP number with thousands separator
local function formatHP(hp)
    local formatted = tostring(hp)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- ============================================================================
-- Core Functions
-- ============================================================================

function TDTTrashCounter:initialize()
    -- Initialize SavedVariables for trash tracking
    if not TurtleDungeonTimerDB.trashProgress then
        TurtleDungeonTimerDB.trashProgress = {}
    end
    
    -- Build lookup tables for all dungeon variants with trash data
    for dungeonName, dungeonData in pairs(TurtleDungeonTimer.DUNGEON_DATA) do
        if dungeonData.variants then
            for variantName, variantData in pairs(dungeonData.variants) do
                if variantData.trashMobs then
                    variantData.trashLookup = buildTrashLookup(variantData)
                    
                    -- Debug output
                    if TurtleDungeonTimerDB.debug then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Trash]|r Built lookup for " .. dungeonName .. " - " .. variantName .. ":")
                        for name, avgHP in pairs(variantData.trashLookup) do
                            DEFAULT_CHAT_FRAME:AddMessage("  " .. name .. " = " .. avgHP .. " HP (weighted avg)")
                        end
                    end
                end
            end
        end
    end
end

function TDTTrashCounter:prepareDungeon(dungeonName, variantName)
    -- Called when dungeon is selected (but not started yet)
    -- Shows the trash bar at 0% if dungeon has trash data
    local dungeonData = TurtleDungeonTimer.DUNGEON_DATA[dungeonName]
    
    if not dungeonData or not dungeonData.variants then
        return
    end
    
    local variantData = dungeonData.variants[variantName]
    if not variantData or not variantData.trashMobs then
        -- No trash data for this variant
        return
    end
    
    currentDungeon = variantData
    killedTrashHP = 0
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Trash Debug]|r prepareDungeon: killedTrashHP auf 0 gesetzt", 1, 1, 0)
    end
    
    -- Show bar at 0%
    self:updateUI()
end

function TDTTrashCounter:startDungeon(dungeonName, variantName)
    local dungeonData = TurtleDungeonTimer.DUNGEON_DATA[dungeonName]
    
    if not dungeonData or not dungeonData.variants then
        return  -- No dungeon data
    end
    
    local variantData = dungeonData.variants[variantName]
    if not variantData or not variantData.trashMobs then
        return  -- No trash data for this variant
    end
    
    currentDungeon = variantData
    killedTrashHP = 0
    
    -- Initialize saved progress (use dungeon+variant key)
    local progressKey = dungeonName .. "_" .. variantName
    if not TurtleDungeonTimerDB.trashProgress[progressKey] then
        TurtleDungeonTimerDB.trashProgress[progressKey] = {
            killedHP = 0,
            lastUpdate = time()
        }
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Trash]|r Started tracking for " .. dungeonName .. " (" .. variantName .. ")")
        DEFAULT_CHAT_FRAME:AddMessage("  Total trash HP: " .. formatHP(currentDungeon.totalTrashHP))
        DEFAULT_CHAT_FRAME:AddMessage("  Required: " .. (currentDungeon.trashRequiredPercent or 100) .. "%")
    end
    
    self:updateUI()
end

function TDTTrashCounter:stopDungeon()
    currentDungeon = nil
    killedTrashHP = 0
    self:updateUI()
end

function TDTTrashCounter:resetProgress(dungeonName)
    if TurtleDungeonTimerDB.trashProgress[dungeonName] then
        TurtleDungeonTimerDB.trashProgress[dungeonName] = nil
    end
    
    if currentDungeon then
        killedTrashHP = 0
        self:updateUI()
    end
end

function TDTTrashCounter:addTrashHP(hp)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[TDT Trash Debug]|r addTrashHP: %d + %d = %d", killedTrashHP, hp, killedTrashHP + hp), 1, 1, 0)
    end
    
    killedTrashHP = killedTrashHP + hp
    self:updateUI()
    self:checkRunCompletion()
end

function TDTTrashCounter:setTrashHP(hp)
    -- Set absolute HP value instead of adding
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[TDT Trash Debug]|r setTrashHP: %d → %d", killedTrashHP, hp), 1, 1, 0)
    end
    
    killedTrashHP = hp
    self:updateUI()
    self:checkRunCompletion()
end

function TDTTrashCounter:checkRunCompletion()
    if not currentDungeon then
        return
    end
    
    local progress = calculateProgress()
    local required = currentDungeon.trashRequiredPercent or 100
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FF00[TDT Trash Debug]|r checkRunCompletion: progress=%.4f, required=%d, killedHP=%d, totalHP=%d",
            progress, required, killedTrashHP, currentDungeon.totalTrashHP
        ))
    end
    
    if progress >= required then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FF00[TDT Trash]|r |cFF00FF00Trash requirement completed! (%d%% cleared)|r",
            floor(progress)
        ))
        
        -- Check if all bosses are also dead - if so, complete the run
        local timer = TurtleDungeonTimer:getInstance()
        if timer.isRunning then
            local requiredBosses = timer:getRequiredBossCount()
            local requiredKills = timer:getRequiredBossKills()
            if requiredKills >= requiredBosses then
                -- Both bosses and trash complete!
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Trash]|r Alle Bosse UND Trash erledigt - Run abgeschlossen!")
                timer:onAllBossesDefeated()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Trash]|r " .. string.format(TDT_L("TRASH_COUNTER_DONE"), requiredBosses - requiredKills))
            end
        end
    end
end

function TDTTrashCounter:onMobKilled(mobName)
    if not currentDungeon or not currentDungeon.trashLookup then
        return
    end
    
    -- Check if this is a trash mob we're tracking
    local avgHP = currentDungeon.trashLookup[mobName]
    if not avgHP then
        return  -- Not a tracked trash mob
    end
    
    -- Add HP to killed total
    killedTrashHP = killedTrashHP + avgHP
    
    -- Calculate progress
    local progress = calculateProgress()
    local required = currentDungeon.trashRequiredPercent or 100
    
    if TurtleDungeonTimerDB.debug then
        local totalHP = currentDungeon.totalTrashHP
        local percentOfTotal = (avgHP / totalHP) * 100
        local percentOfRequired = (percentOfTotal / required) * 100
        
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FF00[TDT Trash]|r %s killed (+%s HP) - Progress: %.1f%%",
            mobName, formatHP(avgHP), progress
        ))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FF00[TDT Trash Debug]|r HP abgezogen: %s | Das sind %.2f%% vom Gesamt | %.2f%% vom Required (%d%%)",
            formatHP(avgHP), percentOfTotal, percentOfRequired, required
        ))
    end
    
    -- Check if requirement met
    self:checkRunCompletion()
    
    -- Update UI (throttled)
    local currentTime = GetTime()
    if currentTime - lastUIUpdate >= UI_UPDATE_INTERVAL then
        self:updateUI()
        lastUIUpdate = currentTime
    end
end

function TDTTrashCounter:getProgress()
    if not currentDungeon then
        return 0, 0, 0  -- progress%, killedHP, totalHP
    end
    
    -- Return normalized progress (relative to requirement) instead of absolute
    return calculateNormalizedProgress(), killedTrashHP, currentDungeon.totalTrashHP
end

function TDTTrashCounter:isTrashComplete()
    if not currentDungeon then
        return false
    end
    
    local progress = calculateProgress()
    local required = currentDungeon.trashRequiredPercent or 100
    
    return progress >= required
end

-- ============================================================================
-- UI Functions
-- ============================================================================

function TDTTrashCounter:createUI()
    if progressFrame then
        return  -- Already created
    end
    
    -- Create frame (will be positioned by UI.lua or shown separately)
    progressFrame = CreateFrame("Frame", "TDTTrashProgressFrame", UIParent)
    progressFrame:SetWidth(250)
    progressFrame:SetHeight(60)
    progressFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    
    -- Backdrop
    progressFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    progressFrame:SetBackdropColor(0, 0, 0, 0.8)
    progressFrame:SetBackdropBorderColor(1, 1, 1, 1)
    
    -- Make draggable
    progressFrame:SetMovable(true)
    progressFrame:EnableMouse(true)
    progressFrame:RegisterForDrag("LeftButton")
    progressFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    progressFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Title
    local title = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", progressFrame, "TOP", 0, -12)
    title:SetText("Trash Progress")
    progressFrame.title = title
    
    -- Progress bar background
    local barBG = progressFrame:CreateTexture(nil, "BACKGROUND")
    barBG:SetPoint("TOPLEFT", progressFrame, "TOPLEFT", 15, -28)
    barBG:SetWidth(220)
    barBG:SetHeight(16)
    barBG:SetTexture(0, 0, 0, 0.5)
    
    -- Progress bar
    local bar = progressFrame:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", barBG, "TOPLEFT", 0, 0)
    bar:SetWidth(1)  -- Will be updated dynamically
    bar:SetHeight(16)
    bar:SetTexture(0, 1, 0, 0.7)
    progressFrame.bar = bar
    progressFrame.barBG = barBG
    
    -- Progress text
    local text = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", barBG, "CENTER", 0, 0)
    text:SetText("0.0% (0 / 0)")
    progressFrame.text = text
    
    progressFrame:Hide()
end

function TDTTrashCounter:showUI()
    if not progressFrame then
        self:createUI()
    end
    progressFrame:Show()
end

function TDTTrashCounter:hideUI()
    if progressFrame then
        progressFrame:Hide()
    end
end

function TDTTrashCounter:updateUI()
    -- Update standalone progress frame (if exists)
    if progressFrame and progressFrame:IsVisible() then
        if not currentDungeon then
            progressFrame:Hide()
            return
        end
        
        local progress = calculateProgress()
        local normalizedProgress = calculateNormalizedProgress()
        local required = currentDungeon.trashRequiredPercent or 100
        local r, g, b = getProgressColor(normalizedProgress)
        
        -- Update bar (based on normalized progress)
        local barWidth = (normalizedProgress / 100) * 220
        progressFrame.bar:SetWidth(math.max(1, barWidth))
        progressFrame.bar:SetTexture(r, g, b, 0.7)
        
        -- Update text (show absolute progress)
        local text = string.format("%.1f%% / %d%% (%s / %s HP)", 
            progress,
            required,
            formatHP(killedTrashHP), 
            formatHP(currentDungeon.totalTrashHP)
        )
        progressFrame.text:SetText(text)
        
        -- Color text based on completion
        if normalizedProgress >= 100 then
            progressFrame.text:SetTextColor(0, 1, 0)  -- Green
        else
            progressFrame.text:SetTextColor(1, 1, 1)  -- White
        end
    end
    
    -- Main timer UI is updated via TurtleDungeonTimer:updateProgressBar()
    -- which calls TDTTrashCounter:getProgress()
end

-- ============================================================================
-- Combat Log Parser (REMOVED - Now handled via Sync)
-- ============================================================================
-- Trash kills are now synchronized via the Sync system (Sync.lua)
-- When a player kills a mob, Events.lua broadcasts it via broadcastTrashKill()
-- All clients receive the kill via onSyncTrashKill() and process it

-- ============================================================================
-- Debug Commands - Removed (unused)
-- ============================================================================
