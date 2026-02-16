-- Export.lua - Export functionality for TurtleDungeonTimer

-- Base64 encoding table
local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Modulo function for Lua 5.1 compatibility
local function mod(a, b)
    return a - math.floor(a / b) * b
end

-- Simple checksum function for data integrity (CRC-like)
function TurtleDungeonTimer:calculateChecksum(data)
    local sum = 0
    for i = 1, string.len(data) do
        local byte = string.byte(data, i)
        sum = mod(sum + byte * (i * 37), 16777216)  -- Use prime multiplier and keep under 24-bit
    end
    return string.format("%X", sum)  -- Return as hex string
end

-- Generate a UUID v4
function TurtleDungeonTimer:generateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local uuid = string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and random(0, 15) or random(8, 11)
        return string.format("%x", v)
    end)
    return uuid
end

function TurtleDungeonTimer:encodeBase64(data)
    local result = {}
    local i = 1
    while i <= string.len(data) do
        local byte1 = string.byte(data, i)
        local byte2 = string.byte(data, i + 1)
        local byte3 = string.byte(data, i + 2)
        
        local val = byte1 * 65536
        if byte2 then
            val = val + byte2 * 256
        end
        if byte3 then
            val = val + byte3
        end
        
        local char1 = string.sub(base64chars, math.floor(val / 262144) + 1, math.floor(val / 262144) + 1)
        local char2 = string.sub(base64chars, math.floor(mod(val, 262144) / 4096) + 1, math.floor(mod(val, 262144) / 4096) + 1)
        local char3 = "="
        local char4 = "="
        
        if byte2 then
            char3 = string.sub(base64chars, math.floor(mod(val, 4096) / 64) + 1, math.floor(mod(val, 4096) / 64) + 1)
        end
        if byte3 then
            char4 = string.sub(base64chars, mod(val, 64) + 1, mod(val, 64) + 1)
        end
        
        table.insert(result, char1 .. char2 .. char3 .. char4)
        i = i + 3
    end
    
    return table.concat(result)
end

-- Unified export function that works with both current run and history entries
function TurtleDungeonTimer:exportRunData(entry)
    local killTimes, deathCount, dungeon, variant, playerName, guildName, groupClasses, uuid, hasWorldBuffs
    local trashProgress, trashRequired, timestamp, completed, isOfficial
    
    if entry then
        -- Export from history entry
        killTimes = entry.killTimes or {}
        deathCount = entry.deathCount or 0
        dungeon = entry.dungeon
        variant = entry.variant
        playerName = entry.playerName
        guildName = entry.guildName
        groupClasses = entry.groupClasses
        uuid = entry.uuid
        hasWorldBuffs = entry.hasWorldBuffs or false
        trashProgress = entry.trashProgress or 0
        trashRequired = entry.trashRequired or 100
        timestamp = entry.timestamp or 0
        completed = entry.completed or false
        isOfficial = entry.isOfficial or false
    else
        -- Export from current run
        killTimes = self.killTimes or {}
        deathCount = self.deathCount or 0
        dungeon = self.selectedDungeon
        variant = self.selectedVariant
        playerName = self.playerName
        guildName = self.guildName
        groupClasses = self.groupClasses
        uuid = self.currentRunUUID
        hasWorldBuffs = self.hasWorldBuffs or false
        
        -- Get trash progress for current run
        trashProgress = 0
        trashRequired = 100
        local dungeonData = self.DUNGEON_DATA[dungeon]
        if dungeonData and variant then
            local variantData = dungeonData.variants[variant]
            if variantData and variantData.trashMobs and TDTTrashCounter then
                trashProgress = TDTTrashCounter:getProgress() or 0
                trashRequired = variantData.trashRequiredPercent or 100
            end
        end
        
        timestamp = time()
        completed = false  -- Current run is not completed yet
        isOfficial = self.isOfficialRun or false
    end
    
    if table.getn(killTimes) == 0 then
        return nil
    end
    
    -- Build export string: TDT|uuid|dungeon|variant|totalTime|deaths|playerName|guildName|classes|boss1:time|boss2:time|...
    local parts = {"TDT"}
    
    -- UUID
    table.insert(parts, uuid or "no-uuid")
    
    -- Dungeon name (replace spaces and special chars)
    local dungeonName = dungeon or "Unknown"
    dungeonName = string.gsub(dungeonName, "[%s:]", "_")
    table.insert(parts, dungeonName)
    
    -- Variant
    local variantName = variant or "Default"
    variantName = string.gsub(variantName, "[%s:]", "_")
    table.insert(parts, variantName)
    
    -- Total time (last boss kill time)
    local totalTime = 0
    if table.getn(killTimes) > 0 then
        totalTime = killTimes[table.getn(killTimes)].time
    end
    table.insert(parts, string.format("%.0f", totalTime))
    
    -- Deaths
    table.insert(parts, tostring(deathCount))
    
    -- Player name
    local pName = playerName or "Unknown"
    pName = string.gsub(pName, "[%s:]", "_")
    table.insert(parts, pName)
    
    -- Guild name
    local gName = guildName or "No_Guild"
    gName = string.gsub(gName, "[%s:]", "_")
    table.insert(parts, gName)
    
    -- Group classes (comma-separated)
    local classesStr = "Solo"
    if groupClasses and table.getn(groupClasses) > 0 then
        classesStr = table.concat(groupClasses, ",")
    end
    table.insert(parts, classesStr)
    
    -- World Buffs indicator (0 = no, 1 = yes)
    table.insert(parts, hasWorldBuffs and "1" or "0")
    
    -- Trash Progress (e.g. 67.5 or 102.3)
    table.insert(parts, string.format("%.2f", trashProgress))
    
    -- Trash Required (e.g. 65 or 85)
    table.insert(parts, string.format("%.0f", trashRequired))
    
    -- Timestamp (Unix timestamp)
    table.insert(parts, tostring(timestamp))
    
    -- Completed flag (0 = no, 1 = yes)
    table.insert(parts, completed and "1" or "0")
    
    -- Official run flag (0 = no, 1 = yes) - all group members had addon
    table.insert(parts, isOfficial and "1" or "0")
    
    -- Boss times
    for i = 1, table.getn(killTimes) do
        local bossName = string.gsub(killTimes[i].bossName, "[%s:]", "_")
        local bossTime = string.format("%.0f", killTimes[i].time)
        table.insert(parts, bossName .. ":" .. bossTime)
    end
    
    local rawString = table.concat(parts, "|")
    
    -- Calculate checksum for data integrity
    local checksum = self:calculateChecksum(rawString)
    local rawStringWithChecksum = rawString .. "|CHK:" .. checksum
    
    -- Encode with Base64
    return self:encodeBase64(rawStringWithChecksum)
end

function TurtleDungeonTimer:showExportDialog()
    local exportString = self:exportRunData()
    
    if not exportString then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r No run data to export. Complete at least one boss first.", 1, 0.5, 0)
        return
    end
    
    -- Create or show existing dialog
    if self.exportDialog then
        self.exportDialog:Show()
        if self.exportDialog.editBox then
            self.exportDialog.editBox:SetText(exportString)
            self.exportDialog.editBox:SetFocus()
            self.exportDialog.editBox:HighlightText(0)
        end
        return
    end
    
    -- Create export dialog
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(400)
    dialog:SetHeight(150)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:EnableMouse(true)
    self.exportDialog = dialog
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText(TDT_L("UI_EXPORT_TITLE"))
    title:SetTextColor(1, 0.82, 0)
    
    -- Description
    local desc = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText(TDT_L("UI_EXPORT_DESCRIPTION"))
    desc:SetTextColor(0, 1, 0)
    
    -- ScrollFrame for export string
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog)
    scrollFrame:SetWidth(360)
    scrollFrame:SetHeight(50)
    scrollFrame:SetPoint("TOP", desc, "BOTTOM", 0, -10)
    
    -- Edit box for export string
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetWidth(350)
    editBox:SetHeight(50)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 10)
    editBox:SetTextColor(1, 1, 1)
    editBox:SetAutoFocus(false)
    editBox:SetText(exportString)
    editBox:SetFocus()
    editBox:HighlightText()
    editBox:SetScript("OnEscapePressed", function()
        dialog:Hide()
        this:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", function()
        this:HighlightText()
    end)
    editBox:SetScript("OnTextChanged", function()
        scrollFrame:UpdateScrollChildRect()
    end)
    
    scrollFrame:SetScrollChild(editBox)
    scrollFrame:EnableMouseWheel()
    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if arg1 > 0 then
            scrollFrame:SetVerticalScroll(math.max(0, current - 20))
        else
            scrollFrame:SetVerticalScroll(math.min(maxScroll, current + 20))
        end
    end)
    
    dialog.editBox = editBox
    
    -- Close Button
    local closeButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    closeButton:SetWidth(100)
    closeButton:SetHeight(30)
    closeButton:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 15)
    closeButton:SetText(TDT_L("UI_CLOSE_BUTTON"))
    closeButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end
