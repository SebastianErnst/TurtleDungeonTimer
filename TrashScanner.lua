-- TrashScanner.lua
-- Scans and stores trash mob data for building a trash counter database

TDTTrashScanner = {}

function TDTTrashScanner:initialize()
    -- Initialize scanned data storage per dungeon
    if not TurtleDungeonTimerDB.scannedTrash then
        TurtleDungeonTimerDB.scannedTrash = {}
    end
end

function TDTTrashScanner:scanCurrentTarget()
    if not UnitExists("target") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. TDT_L("TRASH_NO_TARGET"), 1, 0.5, 0)
        return false
    end
    
    -- Get target info
    local targetName = UnitName("target")
    local targetMaxHP = UnitHealthMax("target")
    local targetLevel = UnitLevel("target")
    local targetClassification = UnitClassification("target") -- normal, elite, rare, worldboss, rareelite
    
    if not targetName or targetName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. TDT_L("TRASH_NO_NAME"), 1, 0.5, 0)
        return false
    end
    
    -- Check if it's a player (we don't want to scan players)
    if UnitIsPlayer("target") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. TDT_L("TRASH_SCANNER_TARGET_PLAYER"), 1, 0.5, 0)
        return false
    end
    
    -- Get current dungeon
    local timer = TurtleDungeonTimer:getInstance()
    local currentDungeon = timer.selectedDungeon
    if not currentDungeon then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. TDT_L("TRASH_SCANNER_NO_DUNGEON"), 1, 0.5, 0)
        return false
    end
    
    -- Initialize dungeon storage if needed
    if not TurtleDungeonTimerDB.scannedTrash[currentDungeon] then
        TurtleDungeonTimerDB.scannedTrash[currentDungeon] = {}
    end
    
    -- Check if mob already exists (same name AND same HP)
    local existingMob = nil
    for i, mob in ipairs(TurtleDungeonTimerDB.scannedTrash[currentDungeon]) do
        if mob.name == targetName and mob.hp == targetMaxHP then
            existingMob = mob
            break
        end
    end
    
    if existingMob then
        -- Increase count for exact match (name + HP)
        existingMob.count = (existingMob.count or 1) + 1
        existingMob.level = targetLevel
        existingMob.classification = targetClassification
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_SCANNER_COUNT_INCREASED"), targetName, targetMaxHP, existingMob.count), 0, 1, 0)
    else
        -- Add new entry (different name OR different HP)
        local mobData = {
            name = targetName,
            hp = targetMaxHP,
            level = targetLevel,
            classification = targetClassification,
            count = 1
        }
        table.insert(TurtleDungeonTimerDB.scannedTrash[currentDungeon], mobData)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_SAVED"), targetName, targetMaxHP), 0, 1, 0)
    end
    
    -- Show count
    local totalCount = table.getn(TurtleDungeonTimerDB.scannedTrash[currentDungeon])
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_TOTAL_MOBS"), currentDungeon, totalCount), 0, 1, 1)
    
    return true
end

function TDTTrashScanner:clearCurrentDungeon()
    local timer = TurtleDungeonTimer:getInstance()
    local currentDungeon = timer.selectedDungeon
    if not currentDungeon then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. TDT_L("TRASH_SCANNER_NO_DUNGEON"), 1, 0.5, 0)
        return
    end
    
    if TurtleDungeonTimerDB.scannedTrash[currentDungeon] then
        local count = table.getn(TurtleDungeonTimerDB.scannedTrash[currentDungeon])
        TurtleDungeonTimerDB.scannedTrash[currentDungeon] = {}
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_DELETED"), count, currentDungeon), 1, 0.8, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_NO_DATA"), currentDungeon), 1, 0.8, 0)
    end
end

function TDTTrashScanner:clearAllData()
    local totalDungeons = 0
    local totalMobs = 0
    
    if TurtleDungeonTimerDB.scannedTrash then
        for dungeon, mobs in pairs(TurtleDungeonTimerDB.scannedTrash) do
            totalDungeons = totalDungeons + 1
            totalMobs = totalMobs + table.getn(mobs)
        end
    end
    
    TurtleDungeonTimerDB.scannedTrash = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_SCANNER_ALL_DELETED"), totalDungeons, totalMobs), 1, 0, 0)
end

function TDTTrashScanner:exportToChat()
    if not TurtleDungeonTimerDB.scannedTrash then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r Keine Daten zum Exportieren!", 1, 0.5, 0)
        return
    end
    
    -- Count total dungeons and mobs
    local dungeonCount = 0
    local totalMobs = 0
    for dungeon, mobs in pairs(TurtleDungeonTimerDB.scannedTrash) do
        if table.getn(mobs) > 0 then
            dungeonCount = dungeonCount + 1
            totalMobs = totalMobs + table.getn(mobs)
        end
    end
    
    if dungeonCount == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. TDT_L("TRASH_NO_EXPORT_DATA"), 1, 0.5, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[" .. TDT_L("TRASH_EXPORT_HEADER") .. "]", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. string.format(TDT_L("TRASH_EXPORT_INFO"), dungeonCount, totalMobs), 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00" .. TDT_L("TRASH_COPY_TO_DATA"), 1, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
    
    -- Generate Lua code
    for dungeon, mobs in pairs(TurtleDungeonTimerDB.scannedTrash) do
        if table.getn(mobs) > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. string.format(TDT_L("TRASH_EXPORT_MOBS_COUNT"), dungeon, table.getn(mobs)), 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff[\"" .. dungeon .. "\"] = {", 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff    trashMobs = {", 1, 1, 1)
            
            -- Sort by HP descending for better readability
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
                
                local line = "        {name = \"" .. mob.name .. "\", hp = " .. mob.hp .. levelStr .. classStr .. "},"
                DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. line, 1, 1, 1)
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff    },", 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff},", 1, 1, 1)
            DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. TDT_L("TRASH_EXPORT_COMPLETE"), 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00========================================", 0, 1, 0)
end

function TDTTrashScanner:showStats()
    if not TurtleDungeonTimerDB.scannedTrash then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. TDT_L("TRASH_NO_EXPORT_DATA"), 1, 0.5, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff========================================", 0, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[TDT Trash Scanner Statistik]", 0, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff========================================", 0, 1, 1)
    
    local totalMobs = 0
    local totalCount = 0
    local dungeonCount = 0
    
    for dungeon, mobs in pairs(TurtleDungeonTimerDB.scannedTrash) do
        local mobCount = table.getn(mobs)
        if mobCount > 0 then
            dungeonCount = dungeonCount + 1
            totalMobs = totalMobs + mobCount
            
            -- Calculate total HP and count for this dungeon
            local totalHP = 0
            local dungeonCount = 0
            for i, mob in ipairs(mobs) do
                totalHP = totalHP + (mob.hp * (mob.count or 1))
                dungeonCount = dungeonCount + (mob.count or 1)
            end
            totalCount = totalCount + dungeonCount
            
            DEFAULT_CHAT_FRAME:AddMessage(string.format(TDT_L("TRASH_SCANNER_DUNGEON_INFO"), dungeon, mobCount, dungeonCount), 1, 1, 1)
        end
    end
    
    if dungeonCount == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Keine Daten gespeichert.", 1, 0.8, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff========================================", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff" .. string.format(TDT_L("TRASH_SCANNER_TOTAL_INFO"), dungeonCount, totalMobs, totalCount), 0, 1, 1)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff========================================", 0, 1, 1)
end

function TDTTrashScanner:showListWindow()
    if self.listFrame and self.listFrame:IsShown() then
        self.listFrame:Hide()
        return
    end
    
    if not self.listFrame then
        self:createListWindow()
    end
    
    self:refreshListWindow()
    self.listFrame:Show()
end

function TDTTrashScanner:createListWindow()
    local frame = CreateFrame("Frame", "TDTTrashScannerListFrame", UIParent)
    frame:SetWidth(300)
    frame:SetHeight(600)
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
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
    title:SetText("Trash Scanner Liste")
    title:SetTextColor(1, 0.82, 0)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Dungeon label
    local dungeonLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonLabel:SetPoint("TOP", title, "BOTTOM", 0, -5)
    dungeonLabel:SetTextColor(0.7, 0.7, 0.7)
    frame.dungeonLabel = dungeonLabel
    
    -- Scan Current Target button
    local scanBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    scanBtn:SetWidth(260)
    scanBtn:SetHeight(30)
    scanBtn:SetPoint("TOP", dungeonLabel, "BOTTOM", 0, -5)
    scanBtn:SetText("SCAN Current Target")
    scanBtn:SetScript("OnClick", function()
        TDTTrashScanner:scanCurrentTarget()
        -- Refresh the list after scanning
        TDTTrashScanner:refreshListWindow()
    end)
    
    -- Header
    local headerBg = frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -105)
    headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -105)
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
    local scrollFrame = CreateFrame("ScrollFrame", "TDTTrashScannerScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -130)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 15)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(250)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    frame.scrollChild = scrollChild
    self.listFrame = frame
end

function TDTTrashScanner:refreshListWindow()
    if not self.listFrame then return end
    
    local scrollChild = self.listFrame.scrollChild
    
    -- Clear existing rows
    if scrollChild.rows then
        for i, row in ipairs(scrollChild.rows) do
            row:Hide()
            row:SetParent(nil)
        end
    end
    scrollChild.rows = {}
    
    -- Get current dungeon
    local timer = TurtleDungeonTimer:getInstance()
    local currentDungeon = timer.selectedDungeon
    if not currentDungeon then
        self.listFrame.dungeonLabel:SetText(TDT_L("UI_NO_DUNGEON_SELECTED"))
        return
    end
    
    self.listFrame.dungeonLabel:SetText(currentDungeon)
    
    -- Get mobs for this dungeon
    if not TurtleDungeonTimerDB.scannedTrash or not TurtleDungeonTimerDB.scannedTrash[currentDungeon] then
        return
    end
    
    local mobs = TurtleDungeonTimerDB.scannedTrash[currentDungeon]
    if table.getn(mobs) == 0 then
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
    
    -- Create rows
    local yOffset = 0
    local rowHeight = 20
    
    for i, mob in ipairs(sortedMobs) do
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        row:SetWidth(250)
        row:SetHeight(rowHeight)
        
        -- Capture mob values in local scope for closures
        local mobName = mob.name
        local mobHP = mob.hp
        local mobRef = mob
        
        -- Alternating background
        if mod(i, 2) == 0 then
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(row)
            bg:SetTexture(0.1, 0.1, 0.1, 0.3)
        end
        
        -- Delete button (X)
        local deleteBtn = CreateFrame("Button", nil, row)
        deleteBtn:SetWidth(16)
        deleteBtn:SetHeight(16)
        deleteBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        deleteBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        deleteBtn:SetScript("OnClick", function()
            -- Remove this mob from the list
            local timer = TurtleDungeonTimer:getInstance()
            local currentDungeon = timer.selectedDungeon
            if currentDungeon and TurtleDungeonTimerDB.scannedTrash[currentDungeon] then
                for idx, m in ipairs(TurtleDungeonTimerDB.scannedTrash[currentDungeon]) do
                    if m.name == mobName and m.hp == mobHP then
                        table.remove(TurtleDungeonTimerDB.scannedTrash[currentDungeon], idx)
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_SCANNER_DELETED_MOB"), mobName, mobHP), 1, 0, 0)
                        break
                    end
                end
            end
            TDTTrashScanner:refreshListWindow()
        end)
        
        -- Decrease count button (-)
        local decreaseBtn = CreateFrame("Button", nil, row)
        decreaseBtn:SetWidth(16)
        decreaseBtn:SetHeight(16)
        decreaseBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -2, 0)
        decreaseBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        decreaseBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
        decreaseBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        decreaseBtn:SetScript("OnClick", function()
            -- Decrease count
            if (mobRef.count or 1) > 1 then
                mobRef.count = (mobRef.count or 1) - 1
                DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TDT Trash Scanner]|r Count verringert: " .. mobName .. " (Count: " .. mobRef.count .. ")", 1, 0.8, 0)
            else
                -- If count is 1, delete instead
                local timer = TurtleDungeonTimer:getInstance()
                local currentDungeon = timer.selectedDungeon
                if currentDungeon and TurtleDungeonTimerDB.scannedTrash[currentDungeon] then
                    for idx, m in ipairs(TurtleDungeonTimerDB.scannedTrash[currentDungeon]) do
                        if m.name == mobName and m.hp == mobHP then
                            table.remove(TurtleDungeonTimerDB.scannedTrash[currentDungeon], idx)
                            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_SCANNER_DELETED_MOB_COUNT"), mobName), 1, 0, 0)
                            break
                        end
                    end
                end
            end
            TDTTrashScanner:refreshListWindow()
        end)
        
        -- Increase count button (+)
        local increaseBtn = CreateFrame("Button", nil, row)
        increaseBtn:SetWidth(16)
        increaseBtn:SetHeight(16)
        increaseBtn:SetPoint("RIGHT", decreaseBtn, "LEFT", -2, 0)
        increaseBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
        increaseBtn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
        increaseBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        increaseBtn:SetScript("OnClick", function()
            -- Increase count
            mobRef.count = (mobRef.count or 1) + 1
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT Trash Scanner]|r " .. string.format(TDT_L("TRASH_COUNT_INCREASED_UI"), mobName, mobRef.count), 0, 1, 0)
            TDTTrashScanner:refreshListWindow()
        end)
        
        -- HP
        local hpText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hpText:SetPoint("RIGHT", increaseBtn, "LEFT", -4, 0)
        hpText:SetWidth(50)
        hpText:SetJustifyH("RIGHT")
        hpText:SetText(mobHP)
        hpText:SetTextColor(1, 0.5, 0.5)
        
        -- Count
        local countText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countText:SetPoint("RIGHT", hpText, "LEFT", -4, 0)
        countText:SetWidth(25)
        countText:SetJustifyH("RIGHT")
        countText:SetText(mobRef.count or 1)
        countText:SetTextColor(0.5, 1, 0.5)
        
        -- Name
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 2, 0)
        nameText:SetPoint("RIGHT", countText, "LEFT", -4, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(mobName)
        
        table.insert(scrollChild.rows, row)
        yOffset = yOffset - rowHeight
    end
    
    scrollChild:SetHeight(math.abs(yOffset) + 10)
end
