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

-- Create hidden tooltip for buff scanning
local scanTooltip = CreateFrame("GameTooltip", "TDTWorldBuffScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- ============================================================================
-- BUFF REMOVAL FUNCTIONS
-- ============================================================================

-- Remove all world buffs from all group members (leader only)
function TurtleDungeonTimer:removeAllWorldBuffs()
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Requesting world buff removal from all group members", 0, 1, 1)
    end
    
    -- Send sync message to all group members to remove their own buffs
    if self:isGroupLeader() then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug] Sending REMOVE_WORLD_BUFFS sync message", 0, 1, 1)
        end
        
        self:sendSyncMessage("REMOVE_WORLD_BUFFS")
        
        -- Also remove our own buffs
        self:removeOwnWorldBuffs()
        
        TDT_Print("WB_REMOVAL_SENT", "warning")
    else
        -- Only leaders can initiate group-wide removal
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("PREP_LEADER_ONLY_REMOVE_WB"), 1, 0, 0)
    end
end

-- Remove only our own world buffs (called by sync message)
function TurtleDungeonTimer:removeOwnWorldBuffs()
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Removing own world buffs", 0, 1, 1)
    end
    
    self:removeWorldBuffsFromUnit("player")
end

-- Remove world buffs from specific unit
function TurtleDungeonTimer:removeWorldBuffsFromUnit(unit)
    local removedCount = 0
    
    -- For each world buff name, search through ALL buffs and remove it if found
    for worldBuffName, _ in pairs(WORLD_BUFFS) do
        -- Search through all buffs for this specific world buff
        for buffIndex = 1, 50 do  -- Max 50 buff slots
            local buffTexture = UnitBuff(unit, buffIndex)
            if not buffTexture then 
                break  -- No more buffs
            end
            
            -- Check if this buff matches our target world buff
            scanTooltip:ClearLines()
            scanTooltip:SetUnitBuff(unit, buffIndex)
            local buffName = TDTWorldBuffScanTooltipTextLeft1:GetText()
            
            if buffName == worldBuffName then
                -- Found it! Cancel this buff
                if unit == "player" then
                    CancelPlayerBuff(buffIndex)
                    removedCount = removedCount + 1
                    if TurtleDungeonTimerDB.debug then
                        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Removed " .. buffName .. " from player (slot " .. buffIndex .. ")", 0, 1, 1)
                    end
                else
                    if TurtleDungeonTimerDB.debug then
                        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Cannot remove " .. buffName .. " from " .. UnitName(unit) .. " (not player)", 0, 1, 1)
                    end
                end
                break  -- Exit inner loop, this world buff is handled
            end
        end
    end
    
    if removedCount > 0 then
        TDT_Print("WB_REMOVED_COUNT", "warning", removedCount)
    elseif TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] No world buffs found to remove", 0, 1, 1)
    end
end

-- Iterator for group members - Removed (unused)

-- ============================================================================
-- BUFF SCANNING FUNCTIONS
-- ============================================================================

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
        
        -- If a run is active, permanently mark it as "with World Buffs"
        if self.isRunning and not self.runWithWorldBuffs then
            self.runWithWorldBuffs = true
            
            local count = 0
            for _ in pairs(foundBuffs) do
                count = count + 1
            end
            
            TDT_Print("WB_DETECTED_PERMANENT", "success", count)
        end
        
        -- Update UI indicator (always, even when not running)
        self:updateWorldBuffsIndicator()
        
        -- Log message on first detection (outside of running)
        if isFirstDetection and not self.isRunning then
            local count = 0
            for _ in pairs(foundBuffs) do
                count = count + 1
            end
            
            TDT_Print("WB_DETECTED_CURRENT", "success", count)
        end
    else
        -- No buffs found
        -- If run is active and already marked with World Buffs, keep the marker!
        if self.isRunning and self.runWithWorldBuffs then
            -- Keep hasWorldBuffs = true to show indicator during run
            self.hasWorldBuffs = true
            self.worldBuffPlayers = {} -- Clear player list but keep indicator
            self:updateWorldBuffsIndicator() -- Update UI to keep indicator visible
        else
            -- Clear state (outside of run or run not marked with WB)
            if self.hasWorldBuffs then
                self.hasWorldBuffs = false
                self.worldBuffPlayers = {}
                self:updateWorldBuffsIndicator()
            end
        end
    end
end

-- Start periodic world buff scanning (runs continuously)
function TurtleDungeonTimer:startWorldBuffScanning()
    -- Don't reset flags if already running
    if not self.worldBuffScanFrame then
        self.hasWorldBuffs = false
        self.worldBuffPlayers = {}
    end
    
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
            timer:markRunWithWorldBuffs()
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
