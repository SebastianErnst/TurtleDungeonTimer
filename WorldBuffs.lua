-- ============================================================================
-- Turtle Dungeon Timer - World Buff Tracker
-- ============================================================================

-- List of world buffs to track
local WORLD_BUFFS = {
    ["Rallying Cry of the Dragonslayer"] = true,
    ["Spirit of Zandalar"] = true,
    ["Warchief's Blessing"] = true,
    ["Songflower Serenade"] = true,
    ["Fengus' Ferocity"] = true,
    ["Mol'dar's Moxie"] = true,
    ["Slip'kik's Savvy"] = true
}

-- ============================================================================
-- BUFF SCANNING FUNCTIONS
-- ============================================================================

-- Create hidden tooltip for buff scanning
local scanTooltip = CreateFrame("GameTooltip", "TDTWorldBuffScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Get buff name from tooltip
local function GetBuffName(unit, buffIndex)
    scanTooltip:ClearLines()
    scanTooltip:SetUnitBuff(unit, buffIndex)
    local buffName = TDTWorldBuffScanTooltipTextLeft1:GetText()
    return buffName
end

-- Check if player has any world buffs active
function TurtleDungeonTimer:checkUnitHasWorldBuffs(unit)
    unit = unit or "player"
    
    local buffIndex = 1
    while true do
        local buffTexture = UnitBuff(unit, buffIndex)
        if not buffTexture then
            break
        end
        
        local buffName = GetBuffName(unit, buffIndex)
        if buffName and WORLD_BUFFS[buffName] then
            return true, buffName
        end
        
        buffIndex = buffIndex + 1
    end
    
    return false, nil
end

-- Scan all party/raid members for world buffs
function TurtleDungeonTimer:scanGroupForWorldBuffs()
    local foundBuffs = {}
    
    -- Check player
    local hasBuffs, buffName = self:checkUnitHasWorldBuffs("player")
    if hasBuffs then
        local playerName = UnitName("player")
        if playerName then
            foundBuffs[playerName] = buffName
        end
    end
    
    -- Check raid members
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local unit = "raid" .. i
            local name = UnitName(unit)
            if name then
                local hasBuffs, buffName = self:checkUnitHasWorldBuffs(unit)
                if hasBuffs then
                    foundBuffs[name] = buffName
                end
            end
        end
    -- Check party members
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local unit = "party" .. i
            local name = UnitName(unit)
            if name then
                local hasBuffs, buffName = self:checkUnitHasWorldBuffs(unit)
                if hasBuffs then
                    foundBuffs[name] = buffName
                end
            end
        end
    end
    
    return foundBuffs
end

-- ============================================================================
-- RUN MARKING FUNCTIONS
-- ============================================================================

-- Mark the current run as having world buffs
function TurtleDungeonTimer:markRunWithWorldBuffs()
    local foundBuffs = self:scanGroupForWorldBuffs()
    
    if foundBuffs and next(foundBuffs) then
        -- Check if this is the first time we found buffs
        local isFirstDetection = not self.hasWorldBuffs
        
        -- At least one person has world buffs
        self.hasWorldBuffs = true
        self.worldBuffPlayers = foundBuffs
        
        -- Only log message on first detection
        if isFirstDetection then
            local count = 0
            for _ in pairs(foundBuffs) do
                count = count + 1
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r World Buffs erkannt! Run wird als 'Mit World Buffs' markiert. (" .. count .. " Spieler)", 1, 1, 0)
        end
    end
end

-- Start periodic world buff scanning (called when timer starts)
function TurtleDungeonTimer:startWorldBuffScanning()
    self.hasWorldBuffs = false
    self.worldBuffPlayers = {}
    
    -- Stop any existing scan
    self:stopWorldBuffScanning()
    
    -- Create scanning frame
    self.worldBuffScanFrame = CreateFrame("Frame")
    local elapsed = 0
    self.worldBuffScanFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 1.0 then  -- Scan every 1 second
            elapsed = 0
            local timer = TurtleDungeonTimer:getInstance()
            if timer.isRunning then
                timer:markRunWithWorldBuffs()
            else
                -- Stop scanning if timer stopped
                timer:stopWorldBuffScanning()
            end
        end
    end)
end

-- Stop periodic scanning
function TurtleDungeonTimer:stopWorldBuffScanning()
    if self.worldBuffScanFrame then
        self.worldBuffScanFrame:SetScript("OnUpdate", nil)
        self.worldBuffScanFrame = nil
    end
end

-- Check for world buffs on timer start (legacy, now uses startWorldBuffScanning)
function TurtleDungeonTimer:checkWorldBuffsOnStart()
    self:startWorldBuffScanning()
end

-- ============================================================================
-- SAVE FUNCTIONS
-- ============================================================================

-- Get world buff status for saving
function TurtleDungeonTimer:getWorldBuffStatus()
    return {
        hasWorldBuffs = self.hasWorldBuffs or false,
        worldBuffPlayers = self.worldBuffPlayers or {}
    }
end
