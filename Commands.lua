-- ============================================================================
-- Turtle Dungeon Timer - Slash Commands
-- ============================================================================

SLASH_TURTLEDUNGEONTIMER1 = "/tdt"
SLASH_TURTLEDUNGEONTIMER2 = "/turtledungeontimer"
SlashCmdList["TURTLEDUNGEONTIMER"] = function(msg)
    local timer = TurtleDungeonTimer:getInstance()
    timer:initialize()
    
    if msg == "start" then
        timer:start()
    elseif msg == "stop" then
        timer:stop()
    elseif msg == "hide" then
        timer:hide()
    elseif msg == "toggle" then
        timer:toggle()
    elseif msg == "help" then
        print("Turtle Dungeon Timer Commands:")
        print("  /tdt or /tdt toggle - Toggle timer window")
        print("  /tdt start - Start timer countdown")
        print("  /tdt stop - Stop timer")
        print("  /tdt hide - Hide timer window")
        print("  /tdt help - Show this help")
    else
        timer:toggle()
    end
end
