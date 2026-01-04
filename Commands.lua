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
    TurtleDungeonTimer:getInstance():initialize()
end)
