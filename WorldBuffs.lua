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
    ["Slip'kik's Savvy"] = true,
    ["Sayge's Dark Fortune of Agility"] = true,
    ["Sayge's Dark Fortune of Intelligence"] = true,
    ["Sayge's Dark Fortune of Spirit"] = true,
    ["Sayge's Dark Fortune of Stamina"] = true,
    ["Sayge's Dark Fortune of Strength"] = true,
    ["Sayge's Dark Fortune of Armor"] = true,
    ["Sayge's Dark Fortune of Resistance"] = true,
    ["Sayge's Dark Fortune of Damage"] = true,
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
        
        -- Send sync message first
        self:sendSyncMessage("REMOVE_WORLD_BUFFS")
        
        -- Delay leader's own removal slightly to ensure sync message is sent first
        local removeFrame = CreateFrame("Frame")
        local elapsed = 0
        removeFrame:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed >= 0.5 then  -- 500ms delay
                removeFrame:SetScript("OnUpdate", nil)
                local timer = TurtleDungeonTimer:getInstance()
                timer:removeOwnWorldBuffs()
            end
        end)
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
    -- Only player can remove their own buffs
    if unit ~= "player" then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug] Cannot remove buffs from " .. UnitName(unit) .. " (not player)", 0, 1, 1)
        end
        return
    end
    
    -- CRITICAL: Collect indices first, then remove from high to low!
    -- When CancelPlayerBuff(i) is called, all buffs after index i shift down by 1
    -- By removing from highest index to lowest, we avoid shifting issues
    local removedCount = 0
    local toRemove = {}  -- List of {index, name} to remove
    
    -- Scan all buffs and collect world buffs to remove
    for i = 0, 32 do
        local texture, count, buffType = GetPlayerBuff(i, "HELPFUL")
        if not texture then
            break  -- No more buffs
        end
        
        -- Get buff name via tooltip - CRITICAL: Must hide/show to refresh!
        scanTooltip:Hide()
        scanTooltip:ClearLines()
        scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        scanTooltip:SetPlayerBuff(i)
        scanTooltip:Show()  -- Force tooltip refresh
        
        local buffName = TDTWorldBuffScanTooltipTextLeft1:GetText()
        
        if buffName and WORLD_BUFFS[buffName] then
            -- Mark for removal
            table.insert(toRemove, {index = i, name = buffName})
        end
    end
    
    scanTooltip:Hide()  -- Clean up tooltip
    
    -- Remove buffs from highest index to lowest to avoid shifting issues
    for i = table.getn(toRemove), 1, -1 do
        local buff = toRemove[i]
        CancelPlayerBuff(buff.index)
        removedCount = removedCount + 1
        
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug] Removed world buff: " .. buff.name, 0, 1, 1)
        end
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
    -- If run is WITHOUT world buffs, don't mark or show messages
    if self.isRunning and self.runWithWorldBuffs == false then
        return
    end
    
    local foundBuffs = self:scanGroupForWorldBuffs()
    
    if foundBuffs and next(foundBuffs) then
        -- Check if this is first detection
        local isFirstDetection = not self.hasWorldBuffs
        
        -- At least one person has world buffs
        self.hasWorldBuffs = true
        self.worldBuffPlayers = foundBuffs
        
        -- Update UI indicator (always, even when not running)
        self:updateWorldBuffsIndicator()
        
        -- Log message ONLY ONCE when first detected AND NOT running
        if not self.isRunning and isFirstDetection then
            local count = 0
            for _ in pairs(foundBuffs) do
                count = count + 1
            end
            
            TDT_Print("WB_DETECTED_CURRENT", "success", count)
        end
        
        -- During run: runWithWorldBuffs is ONLY set by preparation choice
        -- Never automatically mark run as "with WB" during active run
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
            -- If run is active and WITHOUT World Buffs: Remove any detected buffs
            if timer.isRunning and timer.runWithWorldBuffs == false then
                timer:removeOwnWorldBuffs()
            else
                -- Normal behavior: Just mark run with WBs
                timer:markRunWithWorldBuffs()
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

-- Get list of tracked world buffs
function TurtleDungeonTimer:getTrackedWorldBuffs()
    return WORLD_BUFFS
end
