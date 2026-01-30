-- ============================================================================
-- Turtle Dungeon Timer - Slash Commands
-- ============================================================================

SLASH_TURTLEDUNGEONTIMER1 = "/tdt"
SLASH_TURTLEDUNGEONTIMER2 = "/turtledungeontimer"
SlashCmdList["TURTLEDUNGEONTIMER"] = function(msg)
    local timer = TurtleDungeonTimer:getInstance()
    local playerName = UnitName("player")
    
    -- Debug commands restricted to authorized users only
    if msg == "debug" or msg == "debugon" or msg == "debugoff" then
        if playerName ~= "Zasamel" then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT]|r Access denied. Debug commands are restricted.", 1, 0, 0)
            return
        end
    end
    
    if msg == "debug" then
        -- Open debug frame directly (DEV TOOLS)
        timer:showDebugFrame()
    elseif msg == "debugon" then
        -- Quick debug enable
        TurtleDungeonTimerDB.debug = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT]|r Debug mode enabled!", 0, 1, 0)
    elseif msg == "debugoff" then
        -- Quick debug disable
        TurtleDungeonTimerDB.debug = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT]|r Debug mode disabled!", 0, 1, 0)
    elseif msg == "trash" then
        -- Open trash counter window (available to all players)
        if TDTTrashScanner and TDTTrashScanner.showListWindow then
            TDTTrashScanner:showListWindow()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT]|r Trash scanner not available!", 1, 0, 0)
        end
    -- AUTOSCANNER DISABLED - UNCOMMENT TO RE-ENABLE
    -- elseif msg == "autoscan" then
    --     -- Open auto trash scanner window
    --     if TDTAutoTrashScan and TDTAutoTrashScan.showListWindow then
    --         TDTAutoTrashScan:showListWindow()
    --     else
    --         DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TDT]|r Auto scan not available!", 1, 0, 0)
    --     end
    -- elseif msg == "autoscanon" then
    --     -- Enable auto scan
    --     if TDTAutoTrashScan then
    --         TDTAutoTrashScan:enable()
    --     end
    -- elseif msg == "autoscanoff" then
    --     -- Disable auto scan
    --     if TDTAutoTrashScan then
    --         TDTAutoTrashScan:disable()
    --     end
    elseif msg == "help" then
        -- Show help message
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT]|r Available commands:", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/tdt|r - Toggle timer window", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/tdt trash|r - Open manual trash scanner", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/tdt version|r - Show addon version", 1, 1, 1)
        -- DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/tdt autoscan|r - Open auto trash scanner", 1, 1, 1)
        -- DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/tdt autoscanon/off|r - Toggle auto scanning", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/tdt help|r - Show this help", 1, 1, 1)
    elseif msg == "version" then
        -- Show addon version
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Version " .. timer.ADDON_VERSION, 0, 1, 1)
    elseif msg == "config" then
        -- Open config menu (future feature)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT]|r Config menu coming soon!", 1, 1, 0)
    else
        -- Any other input (including empty) just toggles the UI
        timer:toggle()
    end
end

-- ============================================================================
-- AUTO-INITIALIZE ON LOGIN
-- ============================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    local timer = TurtleDungeonTimer:getInstance()
    timer:initialize()
    
    -- Show version loaded message
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ff00[" .. TDT_L("ADDON_NAME") .. "]|r " .. 
        string.format(TDT_L("ADDON_VERSION_LOADED"), timer.ADDON_VERSION),
        0, 1, 0
    )
    
    -- AUTOSCANNER DISABLED - UNCOMMENT TO RE-ENABLE
    -- Initialize Auto Trash Scanner
    -- if TDTAutoTrashScan then
    --     TDTAutoTrashScan:initialize()
    -- end
    
    -- Request current run data from group immediately
    timer:scheduleTimer(function()
        TurtleDungeonTimer:getInstance():requestCurrentRunData()
    end, 0.5, false)
end)
