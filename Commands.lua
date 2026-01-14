-- ============================================================================
-- Turtle Dungeon Timer - Slash Commands
-- ============================================================================

SLASH_TURTLEDUNGEONTIMER1 = "/tdt"
SLASH_TURTLEDUNGEONTIMER2 = "/turtledungeontimer"
SlashCmdList["TURTLEDUNGEONTIMER"] = function(msg)
    local timer = TurtleDungeonTimer:getInstance()
    
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
    elseif msg == "help" then
        -- Show help message (future feature)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT]|r Help: Use /tdt to toggle the timer UI", 1, 1, 0)
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
    
    -- Request current run data from group immediately
    timer:scheduleTimer(function()
        TurtleDungeonTimer:getInstance():requestCurrentRunData()
    end, 0.5, false)
end)
