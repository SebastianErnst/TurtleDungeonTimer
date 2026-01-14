-- ============================================================================
-- Turtle Dungeon Timer - Slash Commands
-- ============================================================================

SLASH_TURTLEDUNGEONTIMER1 = "/tdt"
SLASH_TURTLEDUNGEONTIMER2 = "/turtledungeontimer"
SlashCmdList["TURTLEDUNGEONTIMER"] = function(msg)
    local timer = TurtleDungeonTimer:getInstance()
    
    if msg == "start" then
        timer:start()
    elseif msg == "stop" then
        timer:stop()
    elseif msg == "hide" then
        timer:hide()
    elseif msg == "debug" then
        timer:toggleDebugMode()
    elseif msg == "debugshow" then
        timer:showDebugFrame()
    elseif msg == "eventdebug" then
        TurtleDungeonTimerDB.debug = not TurtleDungeonTimerDB.debug
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TDT]|r Event Debug: " .. tostring(TurtleDungeonTimerDB.debug))
    elseif msg == "toggle" or msg == "help" then
        timer:toggle()
    else
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
