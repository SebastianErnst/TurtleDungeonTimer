-- ============================================================================
-- Turtle Dungeon Timer - Group Synchronization
-- ============================================================================
-- NOTE: SYNC_VERSION is defined in Core.lua (single source of truth)

TurtleDungeonTimer.SYNC_PREFIX = "TDT_SYNC"
TurtleDungeonTimer.SYNC_INTERVAL = 10  -- Periodic sync interval in seconds (configurable for testing)
TurtleDungeonTimer.playersWithAddon = {}
TurtleDungeonTimer.resetVotes = {}
TurtleDungeonTimer.resetInitiator = nil
TurtleDungeonTimer.resetVoteDialog = nil
TurtleDungeonTimer.abortVotes = {}
TurtleDungeonTimer.abortInitiator = nil
TurtleDungeonTimer.abortVoteDialog = nil
TurtleDungeonTimer.currentRunId = nil
TurtleDungeonTimer.lastPeriodicSync = 0  -- Track last periodic sync time
TurtleDungeonTimer.isGroupLeader = false  -- Track if we're the group leader

-- ============================================================================
-- UUID GENERATION
-- ============================================================================
function TurtleDungeonTimer:generateRunId()
    local timestamp = math.floor(GetTime() * 1000)
    local random = math.random(10000, 99999)
    return timestamp .. "-" .. random
end

-- ============================================================================
-- PLAYERS WITH ADDON TRACKING
-- ============================================================================
function TurtleDungeonTimer:checkForAddons()
    self.playersWithAddon = {}
    
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return
    end
    
    self:sendSyncMessage("ADDON_CHECK")
end

function TurtleDungeonTimer:onAddonCheckResponse(sender, version)
    self.playersWithAddon[sender] = true
    
    -- Store version for preparation checks
    if not self.preparationChecks then
        self.preparationChecks = {}
    end
    self.preparationChecks[sender] = version or self.SYNC_VERSION
    
    -- Check major version compatibility
    if version and not self:isVersionCompatible(version) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. string.format(TDT_L("SYNC_VERSION_WARNING"), sender, version), 1, 0.5, 0)
    end
end

function TurtleDungeonTimer:getAddonUserCount()
    local count = 0
    for _ in pairs(self.playersWithAddon) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- SYNC INITIALIZATION
-- ============================================================================
function TurtleDungeonTimer:syncFrameOnEvent()
    local instance = TurtleDungeonTimer:getInstance()
    
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = arg1, arg2, arg3, arg4
        if prefix == TurtleDungeonTimer.SYNC_PREFIX then
            instance:onSyncMessage(message, sender, channel)
        end
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        -- Check if a run is active - if yes, abort it due to group composition change
        if instance.isRunning or instance.isCountingDown then
            -- Send sync message to inform all group members
            instance:sendSyncMessage("ABORT_GROUP_CHANGE")
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("RUN_ABORTED_GROUP_CHANGE"), 1, 0, 0)
            instance:abortRun()
        end
        
        instance:checkForAddons()
        -- Delay button update because group status might not be updated immediately
        instance:scheduleTimer(function()
            instance:updatePrepareButtonState()
        end, 0.1, false)
    end
end

function TurtleDungeonTimer:initializeSync()
    if not self.syncFrame then
        self.syncFrame = CreateFrame("Frame")
        self.syncFrame:RegisterEvent("CHAT_MSG_ADDON")
        self.syncFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        self.syncFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        self.syncFrame:SetScript("OnEvent", TurtleDungeonTimer.syncFrameOnEvent)
    end
    
    self:checkForAddons()
    self:updatePrepareButtonState()
    self:startPeriodicSync()
end

-- ============================================================================
-- SEND SYNC MESSAGES
-- ============================================================================
function TurtleDungeonTimer:sendSyncMessage(msgType, data)
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return
    end
    
    local message = self.SYNC_VERSION .. ";" .. msgType
    if data then
        local pipe = "|"
        data = string.gsub(data, pipe, "~")
        message = message .. ";" .. data
    end
    
    local channel = "PARTY"
    if GetNumRaidMembers() > 0 then
        channel = "RAID"
    end
    
    SendAddonMessage(self.SYNC_PREFIX, message, channel)
end

-- ============================================================================
-- RESET SYSTEM
-- ============================================================================
function TurtleDungeonTimer:syncTimerReset()
    local addonUserCount = self:getAddonUserCount()
    if addonUserCount == 0 then
        
        self:performResetDirect()
        return
    end
    
    self:startResetVote()
end

function TurtleDungeonTimer:startResetVote()
    self:sendSyncMessage("RESET_REQUEST")
    
    self.resetVotes = {}
    self.resetInitiator = UnitName("player")
    self.resetVotes[UnitName("player")] = true
    
    DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Turtle Dungeon Timer]||r Du hast eine Resetanfrage gestellt", 1, 1, 0)
end

function TurtleDungeonTimer:voteReset(vote)
    local playerName = UnitName("player")
    
    self.resetVotes[playerName] = vote
    
    local voteSyncStr = vote and "YES" or "NO"
    self:sendSyncMessage("RESET_VOTE", playerName .. ";" .. voteSyncStr)
    
    local voteStr = vote and "||cff00ff00Ja||r" or "||cffff0000Nein||r"
    DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Reset Vote]||r " .. playerName .. ": " .. voteStr, 1, 1, 0)
    
    self:checkResetVotes()
end

function TurtleDungeonTimer:checkResetVotes()
    if not self.resetVotes then
        return
    end
    
    local totalAddonUsers = self:getAddonUserCount() + 1
    local votedMembers = 0
    local yesVotes = 0
    
    for name, voteValue in pairs(self.resetVotes) do
        votedMembers = votedMembers + 1
        if voteValue then
            yesVotes = yesVotes + 1
        end
    end
    
    local allVoted = (votedMembers >= totalAddonUsers)
    
    if allVoted then
        if yesVotes == totalAddonUsers then
            self:sendSyncMessage("RESET_EXECUTE")
            self:performResetSilent()
            self.resetVotes = {}
            self.resetInitiator = nil
            DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Turtle Dungeon Timer]||r " .. TDT_L("SYNC_TIMER_RESET_GROUP"), 1, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("||cffff0000[Turtle Dungeon Timer]||r Reset wurde abgelehnt", 1, 0, 0)
            self:sendSyncMessage("RESET_CANCEL")
            self.resetVotes = {}
            self.resetInitiator = nil
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("||cff00ff00[Turtle Dungeon Timer]||r Reset Vote: %d/%d (JA: %d)", votedMembers, totalAddonUsers, yesVotes), 1, 1, 0)
    end
end

-- ============================================================================
-- RECEIVE SYNC MESSAGES
-- ============================================================================
function TurtleDungeonTimer:onSyncMessage(message, sender, channel)
    local playerName = UnitName("player")
    if sender == playerName then
        return
    end
    
    local _, _, version, msgType, data = string.find(message, "([^;]+);([^;]+);?(.*)")
    
    if not version or not msgType then
        return
    end
    
    if version ~= self.SYNC_VERSION then
        return
    end
    
    if data then
        local semi = ";"
        data = string.gsub(data, "~", semi)
    end
    
    if msgType == "ADDON_CHECK" then
        self:sendSyncMessage("ADDON_RESPONSE", self.SYNC_VERSION)
    elseif msgType == "ADDON_RESPONSE" then
        self:onAddonCheckResponse(sender, data)
    elseif msgType == "RESET_REQUEST" then
        self:onSyncResetRequest(sender)
    elseif msgType == "RESET_VOTE" then
        self:onSyncResetVote(data, sender)
    elseif msgType == "RESET_CANCEL" then
        self:onSyncResetCancel(sender)
    elseif msgType == "RESET_EXECUTE" then
        self:onSyncResetExecute(sender)
    elseif msgType == "BOSS_KILL" then
        self:onSyncBossKill(data, sender)
    elseif msgType == "TRASH_KILL" then
        self:onSyncTrashKill(data, sender)
    elseif msgType == "TIMER_START" then
        self:onSyncTimerStart(sender)
    elseif msgType == "TIMER_COMPLETE" then
        self:onSyncTimerComplete(data, sender)
    elseif msgType == "PLAYER_DEATH" then
        self:onSyncPlayerDeath(data, sender)
    elseif msgType == "PREPARE_START" then
        self:onSyncPrepareStart(sender)
    elseif msgType == "PREPARE_READY" then
        self:onSyncPrepareReady(sender)
    elseif msgType == "COUNTDOWN_START" then
        self:onSyncCountdownStart(data, sender)
    elseif msgType == "PREPARE_FAILED" then
        self:onSyncPreparationFailed(data, sender)
    elseif msgType == "DUNGEON_SELECTED" then
        self:onSyncDungeonSelected(data, sender)
    elseif msgType == "SET_DUNGEON" then
        self:onSyncSetDungeon(data, sender)
    elseif msgType == "READY_CHECK_START" then
        self:onSyncReadyCheckStart(data, sender)
    elseif msgType == "READY_CHECK_RESPONSE" then
        self:onSyncReadyCheckResponse(data, sender)
    elseif msgType == "REQUEST_CURRENT_RUN" then
        self:onSyncRequestCurrentRun(data, sender)
    elseif msgType == "CURRENT_RUN_DATA" then
        self:onSyncCurrentRunData(data, sender)
    elseif msgType == "PERIODIC_STATE" then
        self:onPeriodicStateReceived(data, sender)
    elseif msgType == "RUN_ID" then
        self:onRunIdReceived(data, sender)
    elseif msgType == "REMOVE_WORLD_BUFFS" then
        self:onSyncRemoveWorldBuffs(sender)
    elseif msgType == "ABORT_REQUEST" then
        self:onSyncAbortRequest(sender)
    elseif msgType == "ABORT_VOTE" then
        self:onSyncAbortVote(data, sender)
    elseif msgType == "ABORT_CANCEL" then
        self:onSyncAbortCancel(sender)
    elseif msgType == "ABORT_EXECUTE" then
        self:onSyncAbortExecute(sender)
    elseif msgType == "ABORT_GROUP_CHANGE" then
        self:onSyncAbortGroupChange(sender)
    end
end

function TurtleDungeonTimer:onSyncResetRequest(sender)
    self.resetInitiator = sender
    self.resetVotes = {}
    
    DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Turtle Dungeon Timer]||r " .. sender .. " hat Resetanfrage gestellt", 1, 1, 0)
    
    if sender ~= UnitName("player") then
        self:showResetVoteDialog(sender)
    end
end

function TurtleDungeonTimer:onSyncResetVote(data, sender)
    local _, _, playerName, vote = string.find(data, "([^;]+);([^;]+)")
    
    if not playerName or not vote then
        return
    end
    
    if playerName == UnitName("player") then
        return
    end
    
    self.resetVotes[playerName] = (vote == "YES")
    
    local voteStr = vote == "YES" and "||cff00ff00Ja||r" or "||cffff0000Nein||r"
    DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Reset Vote]||r " .. playerName .. ": " .. voteStr, 1, 1, 0)
    
    self:checkResetVotes()
end

function TurtleDungeonTimer:onSyncResetCancel(sender)
    self.resetVotes = {}
    self.resetInitiator = nil
    
    if self.resetVoteDialog then
        self.resetVoteDialog:Hide()
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Turtle Dungeon Timer]||r Reset-Abstimmung abgebrochen", 1, 1, 0)
end

function TurtleDungeonTimer:onSyncResetExecute(sender)
    self:performResetSilent()
    
    self.resetVotes = {}
    self.resetInitiator = nil
    
    DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Turtle Dungeon Timer]||r " .. TDT_L("SYNC_TIMER_RESET_GROUP"), 1, 1, 0)
end

-- ============================================================================
-- RESET VOTE DIALOG
-- ============================================================================
function TurtleDungeonTimer:showResetVoteDialog(initiator)
    if self.resetVoteDialog then
        self.resetVoteDialog:Hide()
    end
    
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(300)
    dialog:SetHeight(140)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
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
    self.resetVoteDialog = dialog
    
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("Timer Reset?")
    title:SetTextColor(1, 0.82, 0)
    
    local message1 = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message1:SetPoint("TOP", title, "BOTTOM", 0, -10)
    message1:SetWidth(260)
    message1:SetText(string.format(TDT_L("UI_RESET_VOTE_MESSAGE"), initiator))
    message1:SetJustifyH("CENTER")
    
    local message2 = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message2:SetPoint("TOP", message1, "BOTTOM", 0, -10)
    message2:SetWidth(260)
    message2:SetText(TDT_L("UI_ABORT_VOTE_QUESTION"))
    message2:SetJustifyH("CENTER")
    
    local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    yesButton:SetWidth(100)
    yesButton:SetHeight(30)
    yesButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -105, 15)
    yesButton:SetText(TDT_L("YES"))
    yesButton:SetScript("OnClick", function()
        local self = TurtleDungeonTimer:getInstance()
        self:voteReset(true)
        self.resetVoteDialog:Hide()
    end)
    
    local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    noButton:SetWidth(100)
    noButton:SetHeight(30)
    noButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", 105, 15)
    noButton:SetText(TDT_L("no"))
    noButton:SetScript("OnClick", function()
        local self = TurtleDungeonTimer:getInstance()
        self:voteReset(false)
        self.resetVoteDialog:Hide()
    end)
    
    dialog.timeout = 30
    dialog:SetScript("OnUpdate", function()
        this.timeout = this.timeout - arg1
        if this.timeout <= 0 then
            local self = TurtleDungeonTimer:getInstance()
            self:voteReset(false)
            self.resetVoteDialog:Hide()
        end
    end)
    
    dialog:Show()
end

-- ============================================================================
-- ABORT VOTING SYSTEM
-- ============================================================================

function TurtleDungeonTimer:syncTimerAbort()
    local addonUserCount = self:getAddonUserCount()
    if addonUserCount == 0 then
        -- No other addon users, abort directly
        self:abortRun()
        return
    end
    
    self:startAbortVote()
end

function TurtleDungeonTimer:startAbortVote()
    self:sendSyncMessage("ABORT_REQUEST")
    
    self.abortVotes = {}
    self.abortInitiator = UnitName("player")
    self.abortVotes[UnitName("player")] = true
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Du hast eine Abbruch-Anfrage gestellt", 1, 1, 0)
end

function TurtleDungeonTimer:voteAbort(vote)
    local playerName = UnitName("player")
    
    self.abortVotes[playerName] = vote
    
    local voteSyncStr = vote and "YES" or "NO"
    self:sendSyncMessage("ABORT_VOTE", playerName .. ";" .. voteSyncStr)
    
    local voteStr = vote and "|cff00ff00Ja|r" or "|cffff0000Nein|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Abort Vote]|r " .. playerName .. ": " .. voteStr, 1, 1, 0)
    
    self:checkAbortVotes()
end

function TurtleDungeonTimer:checkAbortVotes()
    if not self.abortVotes then
        return
    end
    
    local totalAddonUsers = self:getAddonUserCount() + 1
    local votedMembers = 0
    local yesVotes = 0
    
    for name, voteValue in pairs(self.abortVotes) do
        votedMembers = votedMembers + 1
        if voteValue then
            yesVotes = yesVotes + 1
        end
    end
    
    local allVoted = (votedMembers >= totalAddonUsers)
    
    if allVoted then
        if yesVotes == totalAddonUsers then
            self:sendSyncMessage("ABORT_EXECUTE")
            self:abortRun()
            self.abortVotes = {}
            self.abortInitiator = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Run wurde abgebrochen (Gruppenbeschluss)", 1, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r Abbruch wurde abgelehnt", 1, 0, 0)
            self:sendSyncMessage("ABORT_CANCEL")
            self.abortVotes = {}
            self.abortInitiator = nil
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Turtle Dungeon Timer]|r Abbruch Vote: %d/%d (JA: %d)", votedMembers, totalAddonUsers, yesVotes), 1, 1, 0)
    end
end

function TurtleDungeonTimer:onSyncAbortRequest(sender)
    self.abortInitiator = sender
    self.abortVotes = {}
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r " .. sender .. " hat Run-Abbruch vorgeschlagen", 1, 1, 0)
    
    if sender ~= UnitName("player") then
        self:showAbortVoteDialog(sender)
    end
end

function TurtleDungeonTimer:onSyncAbortVote(data, sender)
    local _, _, playerName, vote = string.find(data, "([^;]+);([^;]+)")
    
    if not playerName or not vote then
        return
    end
    
    self.abortVotes[playerName] = (vote == "YES")
    
    local voteStr = (vote == "YES") and "|cff00ff00Ja|r" or "|cffff0000Nein|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Abort Vote]|r " .. playerName .. ": " .. voteStr, 1, 1, 0)
    
    self:checkAbortVotes()
end

function TurtleDungeonTimer:onSyncAbortCancel(sender)
    self.abortVotes = {}
    self.abortInitiator = nil
    
    if self.abortVoteDialog then
        self.abortVoteDialog:Hide()
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r Abbruch-Vote wurde abgebrochen", 1, 0, 0)
end

function TurtleDungeonTimer:onSyncAbortExecute(sender)
    self:abortRun()
    self.abortVotes = {}
    self.abortInitiator = nil
    
    if self.abortVoteDialog then
        self.abortVoteDialog:Hide()
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Run wurde von der Gruppe abgebrochen", 1, 1, 0)
end

function TurtleDungeonTimer:onSyncAbortGroupChange(sender)
    -- Only abort if we're actually running (prevent duplicate aborts)
    if self.isRunning or self.isCountingDown then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Turtle Dungeon Timer]|r " .. TDT_L("RUN_ABORTED_GROUP_CHANGE"), 1, 0, 0)
        self:abortRun()
    end
    
    self.abortVotes = {}
    self.abortInitiator = nil
    
    if self.abortVoteDialog then
        self.abortVoteDialog:Hide()
    end
end

function TurtleDungeonTimer:showAbortVoteDialog(initiator)
    if self.abortVoteDialog then
        self.abortVoteDialog:Hide()
    end
    
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(300)
    dialog:SetHeight(140)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
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
    self.abortVoteDialog = dialog
    
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("Run abbrechen?")
    title:SetTextColor(1, 0.82, 0)
    
    local message1 = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message1:SetPoint("TOP", title, "BOTTOM", 0, -10)
    message1:SetWidth(260)
    message1:SetText(string.format(TDT_L("UI_ABORT_VOTE_MESSAGE"), initiator))
    message1:SetJustifyH("CENTER")
    
    local message2 = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message2:SetPoint("TOP", message1, "BOTTOM", 0, -10)
    message2:SetWidth(260)
    message2:SetText(TDT_L("UI_ABORT_VOTE_QUESTION"))
    message2:SetJustifyH("CENTER")
    
    local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    yesButton:SetWidth(100)
    yesButton:SetHeight(30)
    yesButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -105, 15)
    yesButton:SetText(TDT_L("YES"))
    yesButton:SetScript("OnClick", function()
        local self = TurtleDungeonTimer:getInstance()
        self:voteAbort(true)
        self.abortVoteDialog:Hide()
    end)
    
    local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    noButton:SetWidth(100)
    noButton:SetHeight(30)
    noButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", 105, 15)
    noButton:SetText(TDT_L("no"))
    noButton:SetScript("OnClick", function()
        local self = TurtleDungeonTimer:getInstance()
        self:voteAbort(false)
        self.abortVoteDialog:Hide()
    end)
    
    dialog.timeout = 30
    dialog:SetScript("OnUpdate", function()
        this.timeout = this.timeout - arg1
        if this.timeout <= 0 then
            local timer = TurtleDungeonTimer:getInstance()
            timer:voteAbort(false)  -- Auto-vote "No" if timeout
            dialog:Hide()
        end
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:showAbortConfirmationDialog()
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetWidth(280)
    dialog:SetHeight(140)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
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
    
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("Run abbrechen?")
    title:SetTextColor(1, 0.82, 0)
    
    local message = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", title, "BOTTOM", 0, -15)
    message:SetWidth(240)
    message:SetText(TDT_L("UI_ABORT_RUN_MESSAGE"))
    message:SetJustifyH("CENTER")
    
    local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    yesButton:SetWidth(60)
    yesButton:SetHeight(30)
    yesButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -65, 15)
    yesButton:SetText(TDT_L("YES"))
    yesButton:SetScript("OnClick", function()
        local self = TurtleDungeonTimer:getInstance()
        self:syncTimerAbort()
        dialog:Hide()
    end)
    
    local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    noButton:SetWidth(60)
    noButton:SetHeight(30)
    noButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", 65, 15)
    noButton:SetText(TDT_L("no"))
    noButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function TurtleDungeonTimer:abortRun()
    -- Stop timer and reset state
    self.isRunning = false
    self.startTime = nil
    self.restoredElapsedTime = nil
    
    -- Set flag to prevent auto-restart from sync
    -- This flag will be cleared when starting a new run manually
    self.runAborted = true
    
    -- Stop countdown if running
    if self.preparationState == "COUNTDOWN" then
        self:stopCountdown()
    end
    
    -- Reset preparation state so button shows "Start" again
    self.preparationState = nil
    
    -- Stop countdown if running
    if self.countdownTriggered then
        self:stopCountdown()
    end
    
    -- Update UI
    self:updateTimerDisplay()
    self:updateStartButton()
    
    -- Save state
    self:saveLastRun()
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
function TurtleDungeonTimer:getGroupMemberCount()
    if GetNumRaidMembers() > 0 then
        return GetNumRaidMembers()
    elseif GetNumPartyMembers() > 0 then
        return GetNumPartyMembers() + 1
    end
    return 1
end

function TurtleDungeonTimer:getGroupChannel()
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

-- ============================================================================
-- KILL SYNCHRONIZATION
-- ============================================================================

-- Broadcast a boss kill to the group
function TurtleDungeonTimer:broadcastBossKill(bossName)
    self:sendSyncMessage("BOSS_KILL", bossName)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Broadcast Boss Kill: " .. bossName)
    end
end

-- Broadcast a trash kill to the group
function TurtleDungeonTimer:broadcastTrashKill(mobName)
    self:sendSyncMessage("TRASH_KILL", mobName)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Broadcast Trash Kill: " .. mobName)
    end
end

-- Handle received boss kill message
function TurtleDungeonTimer:onSyncBossKill(bossName, sender)
    if not bossName or bossName == "" then
        return
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Received Boss Kill from " .. sender .. ": " .. bossName)
    end
    
    -- Check if we already have this boss recorded to prevent duplicates after sync
    local alreadyKilled = false
    for j = 1, table.getn(self.killTimes) do
        if self.killTimes[j].bossName == bossName then
            alreadyKilled = true
            if TurtleDungeonTimerDB.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Boss bereits in killTimes - Sync ignoriert: " .. bossName)
            end
            break
        end
    end
    
    if not alreadyKilled then
        -- Process the boss kill
        self:onBossKilled(bossName)
    end
end

-- Handle received trash kill message
function TurtleDungeonTimer:onSyncTrashKill(mobName, sender)
    if not mobName or mobName == "" then
        return
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Received Trash Kill from " .. sender .. ": " .. mobName)
    end
    
    -- Process the trash kill
    if TDTTrashCounter then
        TDTTrashCounter:onMobKilled(mobName)
    end
end

-- ============================================================================
-- TIMER START SYNCHRONIZATION
-- ============================================================================

-- Broadcast timer start to the group
function TurtleDungeonTimer:broadcastTimerStart()
    self:sendSyncMessage("TIMER_START")
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Broadcast Timer Start")
    end
end

-- Handle received timer start message
function TurtleDungeonTimer:onSyncTimerStart(sender)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Received Timer Start from " .. sender)
    end
    
    -- Start timer if conditions are met
    self:onCombatStart()
end

-- Broadcast timer completion to the group
function TurtleDungeonTimer:broadcastTimerComplete(finalTime)
    local timeStr = tostring(math.floor(finalTime))
    self:sendSyncMessage("TIMER_COMPLETE", timeStr)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Broadcast Timer Complete: " .. timeStr .. "s")
    end
end

-- Handle received timer completion message
function TurtleDungeonTimer:onSyncTimerComplete(timeStr, sender)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Received Timer Complete from " .. sender .. ": " .. (timeStr or "nil"))
    end
    
    -- Display completion message
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r |cFF00FF00" .. sender .. " hat den Run abgeschlossen!|r", 1, 1, 0)
end

-- ============================================================================
-- PLAYER DEATH SYNCHRONIZATION
-- ============================================================================

-- Broadcast player death to the group
function TurtleDungeonTimer:broadcastPlayerDeath(playerName)
    self:sendSyncMessage("PLAYER_DEATH", playerName)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Broadcast Player Death: " .. playerName)
    end
end

-- Handle received player death message
function TurtleDungeonTimer:onSyncPlayerDeath(playerName, sender)
    if not playerName or playerName == "" then
        return
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TDT Sync]|r Received Player Death from " .. sender .. ": " .. playerName)
    end
    
    -- Process the player death
    self:onPlayerDeath(playerName)
end

-- ============================================================================
-- READY CHECK SYNCHRONIZATION
-- ============================================================================

function TurtleDungeonTimer:onSyncReadyCheckStart(data, sender)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Ready Check started by: " .. sender .. " with data: " .. tostring(data), 1, 1, 0)
    end
    
    -- Parse data: format is "dungeonName;wbFlag"
    local dungeonName = ""
    local wbFlag = "0"
    
    if data and data ~= "" then
        -- Split by semicolon using string.find (WoW 1.12 compatible)
        local semicolonPos = string.find(data, ";")
        if semicolonPos then
            dungeonName = string.sub(data, 1, semicolonPos - 1)
            wbFlag = string.sub(data, semicolonPos + 1) or "0"
        else
            dungeonName = data
        end
    end
    
    -- Set World Buff flag based on received data
    if wbFlag == "1" then
        self.runWithWorldBuffs = true
    elseif wbFlag == "2" then
        self.runWithWorldBuffs = false
    else
        self.runWithWorldBuffs = nil
    end
    
    -- Store the dungeon name from leader (for later selection when clicking Yes)
    self.pendingDungeonSelection = dungeonName
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Parsed dungeon: " .. tostring(dungeonName) .. ", WB flag: " .. tostring(self.runWithWorldBuffs), 1, 1, 0)
    end
    
    -- Show ready check prompt to this player with the dungeon name
    self:showReadyCheckPrompt(dungeonName)
end

function TurtleDungeonTimer:onSyncReadyCheckResponse(data, sender)
    -- Forward to preparation module
    self:onReadyCheckResponse(sender, data)
end

-- ============================================================================
-- SET DUNGEON SYNCHRONIZATION (After Ready Check Success)
-- ============================================================================

function TurtleDungeonTimer:onSyncSetDungeon(data, sender)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Received SET_DUNGEON from " .. sender .. ": " .. tostring(data), 1, 1, 0)
    end
    
    -- Parse dungeon data (format: "DungeonKey" or "DungeonKey;VariantKey")
    local dungeonKey = data
    local variantKey = nil
    
    local _, _, key, variant = string.find(data, "^([^;]+);(.+)$")
    if key and variant then
        dungeonKey = key
        variantKey = variant
    end
    
    -- Set the dungeon
    self:selectDungeon(dungeonKey)
    if variantKey then
        self:selectVariant(variantKey)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Dungeon gesetzt: " .. dungeonKey .. (variantKey and (" (" .. variantKey .. ")") or ""), 0, 1, 0)
end

-- ============================================================================
-- RUN DATA SYNC SYSTEM (for re-login)
-- ============================================================================

function TurtleDungeonTimer:requestCurrentRunData()
    -- Only request if we're in a group and have a dungeon selected
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Keine Gruppe - Sync übersprungen", 1, 1, 0)
        end
        return
    end
    
    if not self.selectedDungeon or not self.selectedVariant then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Kein Dungeon/Variant gewählt - Sync übersprungen", 1, 1, 0)
        end
        return
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Sende REQUEST_CURRENT_RUN für " .. self.selectedDungeon .. "/" .. self.selectedVariant, 1, 1, 0)
    end
    
    -- Initialize response tracking
    self.runDataResponses = {}
    self.runDataRequestTime = GetTime()
    
    -- Request current run data from all group members
    self:sendSyncMessage("REQUEST_CURRENT_RUN", self.selectedDungeon .. ";" .. self.selectedVariant)
    
    -- Schedule processing after 2 seconds (give time for responses)
    self:scheduleTimer(function()
        TurtleDungeonTimer:getInstance():processRunDataResponses()
    end, 2.0, false)
end

function TurtleDungeonTimer:onSyncRequestCurrentRun(data, sender)
    -- Someone requested current run data - send ours if we have matching dungeon
    if not data then return end
    
    local _, _, reqDungeon, reqVariant = string.find(data, "([^;]+);([^;]+)")
    
    if not reqDungeon or not reqVariant then return end
    if reqDungeon ~= self.selectedDungeon or reqVariant ~= self.selectedVariant then return end
    
    -- Only respond if we have a running/countdown run or completed run with data
    if not self.isRunning and not self.isCountingDown and table.getn(self.killTimes) == 0 then
        return
    end
    
    -- Build run data string
    local runDataParts = {}
    
    -- 1. Dungeon and variant
    table.insert(runDataParts, self.selectedDungeon)
    table.insert(runDataParts, self.selectedVariant)
    
    -- 2. Basic run info
    local isRunningStr = self.isRunning and "1" or "0"
    table.insert(runDataParts, isRunningStr)
    
    -- 3. Is counting down
    local isCountingDownStr = self.isCountingDown and "1" or "0"
    table.insert(runDataParts, isCountingDownStr)
    
    -- 4. Elapsed time
    local elapsedTime = 0
    if self.isRunning and self.startTime then
        elapsedTime = math.floor(GetTime() - self.startTime)
    elseif self.restoredElapsedTime then
        elapsedTime = math.floor(self.restoredElapsedTime)
    end
    table.insert(runDataParts, tostring(elapsedTime))
    
    -- 5. Death count
    table.insert(runDataParts, tostring(self.deathCount))
    
    -- 6. Boss kills (count only - detailed sync happens via normal BOSS_KILL messages)
    table.insert(runDataParts, tostring(table.getn(self.killTimes)))
    
    -- 7. Trash progress and absolute HP (if available)
    local trashProgress = 0
    local trashKilledHP = 0
    if TDTTrashCounter then
        trashProgress, trashKilledHP = TDTTrashCounter:getProgress()
    end
    table.insert(runDataParts, string.format("%.1f", trashProgress))
    table.insert(runDataParts, tostring(trashKilledHP))  -- Send absolute HP
    
    -- Send as semicolon-separated string
    local runData = table.concat(runDataParts, ";")
    self:sendSyncMessage("CURRENT_RUN_DATA", runData)
end

function TurtleDungeonTimer:onSyncCurrentRunData(data, sender)
    if not self.runDataResponses then
        self.runDataResponses = {}
    end
    
    -- Parse run data
    local parts = {}
    local start = 1
    local dataWithSep = data .. ";"
    while start <= string.len(dataWithSep) do
        local found = string.find(dataWithSep, ";", start)
        if found then
            table.insert(parts, string.sub(dataWithSep, start, found - 1))
            start = found + 1
        else
            break
        end
    end
    
    if table.getn(parts) < 8 then return end
    
    local runData = {
        dungeon = parts[1],
        variant = parts[2],
        isRunning = (parts[3] == "1"),
        isCountingDown = (parts[4] == "1"),
        elapsedTime = tonumber(parts[5]) or 0,
        deathCount = tonumber(parts[6]) or 0,
        bossKills = tonumber(parts[7]) or 0,
        trashProgress = tonumber(parts[8]) or 0,
        trashKilledHP = tonumber(parts[9]) or 0,  -- Parse absolute HP
        sender = sender
    }
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Empfangen von " .. sender, 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] isRunning: " .. tostring(runData.isRunning), 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] isCountingDown: " .. tostring(runData.isCountingDown), 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] elapsedTime: " .. tostring(runData.elapsedTime), 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] bossKills: " .. tostring(runData.bossKills), 1, 1, 0)
    end
    
    table.insert(self.runDataResponses, runData)
end

function TurtleDungeonTimer:processRunDataResponses()
    if not self.runDataResponses or table.getn(self.runDataResponses) == 0 then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Keine Antworten erhalten", 1, 1, 0)
        end
        return
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Verarbeite " .. tostring(table.getn(self.runDataResponses)) .. " Antworten", 1, 1, 0)
    end
    
    -- Find the most advanced run state
    local bestResponse = nil
    local maxProgress = -1
    
    for i, response in ipairs(self.runDataResponses) do
        -- Calculate progress score (more bosses = higher priority)
        local progress = response.bossKills * 1000 + response.trashProgress
        
        if progress > maxProgress then
            maxProgress = progress
            bestResponse = response
        end
    end
    
    if not bestResponse then
        self.runDataResponses = nil
        return
    end
    
    -- Mark countdown sync flag if needed
    if self.wasInCountdown then
        self.syncReceivedCountdownData = true
        self.wasInCountdown = false
        
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] wasInCountdown Flag zurückgesetzt", 1, 1, 0)
        end
    end
    
    -- Convert response to same format as PERIODIC_STATE for unified merge logic
    local remoteState = {
        sender = bestResponse.sender,
        dungeon = bestResponse.dungeon,
        variant = bestResponse.variant,
        runId = bestResponse.runId or "",
        isRunning = bestResponse.isRunning,
        isCountingDown = bestResponse.isCountingDown,
        elapsedTime = bestResponse.elapsedTime,
        deathCount = bestResponse.deathCount,
        trashProgress = bestResponse.trashProgress,
        trashKilledHP = bestResponse.trashKilledHP,
        killTimesData = bestResponse.killTimesData or "",
        timestamp = bestResponse.timestamp
    }
    
    -- Use the same merge logic as periodic sync (Best-of-All)
    self:mergeRemoteState(remoteState)
    
    -- Notify user about login sync
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Login-Sync abgeschlossen von " .. bestResponse.sender, 1, 1, 0)
    end
    
    -- Clear response data
    self.runDataResponses = nil
end

-- ============================================================================
-- PERIODIC SYNC SYSTEM (NEW)
-- ============================================================================

function TurtleDungeonTimer:startPeriodicSync()
    -- Schedule periodic sync check
    self:scheduleTimer(function()
        TurtleDungeonTimer:getInstance():periodicSyncCheck()
    end, self.SYNC_INTERVAL, true)
end

function TurtleDungeonTimer:periodicSyncCheck()
    -- Only sync if in group and have dungeon selected
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return
    end
    
    if not self.selectedDungeon or not self.selectedVariant then
        return
    end
    
    -- Broadcast our current state for "Best-of-All" merge
    self:broadcastCompleteState()
end

function TurtleDungeonTimer:broadcastCompleteState()
    if not self.selectedDungeon or not self.selectedVariant then
        return
    end
    
    -- Build complete state data
    local stateParts = {}
    
    -- 1. Dungeon and variant
    table.insert(stateParts, self.selectedDungeon)
    table.insert(stateParts, self.selectedVariant)
    
    -- 2. Run ID
    table.insert(stateParts, self.currentRunId or "")
    
    -- 3. Timer state
    local isRunningStr = self.isRunning and "1" or "0"
    table.insert(stateParts, isRunningStr)
    
    local isCountingDownStr = self.isCountingDown and "1" or "0"
    table.insert(stateParts, isCountingDownStr)
    
    -- 4. Elapsed time
    local elapsedTime = 0
    if self.isRunning and self.startTime then
        elapsedTime = math.floor(GetTime() - self.startTime)
    elseif self.restoredElapsedTime then
        elapsedTime = math.floor(self.restoredElapsedTime)
    end
    table.insert(stateParts, tostring(elapsedTime))
    
    -- 5. Death count
    table.insert(stateParts, tostring(self.deathCount))
    
    -- 6. Trash progress
    local trashProgress = 0
    local trashKilledHP = 0
    if TDTTrashCounter then
        trashProgress, trashKilledHP = TDTTrashCounter:getProgress()
    end
    table.insert(stateParts, string.format("%.1f", trashProgress))
    table.insert(stateParts, tostring(trashKilledHP))  -- Send absolute HP value
    
    -- 7. Boss kills (serialize killTimes array)
    local killTimesData = self:serializeKillTimes()
    table.insert(stateParts, killTimesData)
    
    -- 8. Timestamp (for conflict resolution)
    table.insert(stateParts, tostring(time()))
    
    -- Send state
    local stateData = table.concat(stateParts, ";")
    self:sendSyncMessage("PERIODIC_STATE", stateData)
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Broadcast complete state", 1, 1, 0)
    end
end

function TurtleDungeonTimer:serializeKillTimes()
    if table.getn(self.killTimes) == 0 then
        return ""
    end
    
    local parts = {}
    for i, killData in ipairs(self.killTimes) do
        -- Format: bossName:time:index:splitTime
        local entry = killData.bossName .. ":" .. 
                      math.floor(killData.time) .. ":" .. 
                      killData.index .. ":" .. 
                      math.floor(killData.splitTime or 0)
        table.insert(parts, entry)
    end
    
    return table.concat(parts, ",")
end

function TurtleDungeonTimer:deserializeKillTimes(data)
    if not data or data == "" then
        return {}
    end
    
    local killTimes = {}
    -- Parse entries separated by commas
    local start = 1
    local dataWithSep = data .. ","
    while start <= string.len(dataWithSep) do
        local found = string.find(dataWithSep, ",", start)
        if found then
            local entry = string.sub(dataWithSep, start, found - 1)
            if entry ~= "" then
                local parts = {}
                -- Parse parts separated by colons
                local partStart = 1
                local entryWithSep = entry .. ":"
                while partStart <= string.len(entryWithSep) do
                    local partFound = string.find(entryWithSep, ":", partStart)
                    if partFound then
                        table.insert(parts, string.sub(entryWithSep, partStart, partFound - 1))
                        partStart = partFound + 1
                    else
                        break
                    end
                end
                
                if table.getn(parts) >= 4 then
                    table.insert(killTimes, {
                    bossName = parts[1],
                    time = tonumber(parts[2]) or 0,
                    index = tonumber(parts[3]) or 0,
                    splitTime = tonumber(parts[4]) or 0
                })
                end
            end
            start = found + 1
        else
            break
        end
    end
    
    return killTimes
end

function TurtleDungeonTimer:onPeriodicStateReceived(data, sender)
    if not data then return end
    
    -- Parse state data
    local parts = {}
    local start = 1
    local dataWithSep = data .. ";"
    while start <= string.len(dataWithSep) do
        local found = string.find(dataWithSep, ";", start)
        if found then
            table.insert(parts, string.sub(dataWithSep, start, found - 1))
            start = found + 1
        else
            break
        end
    end
    
    if table.getn(parts) < 10 then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Invalid periodic state data from " .. sender, 1, 0, 0)
        end
        return
    end
    
    local remoteState = {
        dungeon = parts[1],
        variant = parts[2],
        runId = parts[3],
        isRunning = (parts[4] == "1"),
        isCountingDown = (parts[5] == "1"),
        elapsedTime = tonumber(parts[6]) or 0,
        deathCount = tonumber(parts[7]) or 0,
        trashProgress = tonumber(parts[8]) or 0,
        trashKilledHP = tonumber(parts[9]) or 0,  -- Parse absolute HP
        killTimesData = parts[10],
        timestamp = tonumber(parts[11]) or 0,
        sender = sender
    }
    
    -- Only process if same dungeon/variant
    if remoteState.dungeon ~= self.selectedDungeon or remoteState.variant ~= self.selectedVariant then
        return
    end
    
    -- Merge using "Best-of-All" strategy
    self:mergeRemoteState(remoteState)
end

function TurtleDungeonTimer:mergeRemoteState(remoteState)
    local updated = false
    local updateReasons = {}
    
    -- 1. Sync Run ID (if we don't have one yet)
    if not self.currentRunId and remoteState.runId and remoteState.runId ~= "" then
        self.currentRunId = remoteState.runId
        updated = true
        table.insert(updateReasons, "Run-ID uebernommen")
    end
    
    -- 2. Timer: Take highest (furthest progressed)
    -- But skip timer sync if run was recently aborted
    if remoteState.elapsedTime > 0 and not self.runAborted then
        local ourElapsed = 0
        if self.isRunning and self.startTime then
            ourElapsed = GetTime() - self.startTime
        elseif self.restoredElapsedTime then
            ourElapsed = self.restoredElapsedTime
        end
        
        if remoteState.elapsedTime > ourElapsed then
            if remoteState.isRunning then
                self.isRunning = true
                self.startTime = GetTime() - remoteState.elapsedTime
                self.restoredElapsedTime = nil
            else
                self.isRunning = false
                self.restoredElapsedTime = remoteState.elapsedTime
                self.startTime = nil
            end
            updated = true
            table.insert(updateReasons, "Timer: " .. math.floor(ourElapsed) .. "s -> " .. remoteState.elapsedTime .. "s")
        end
    end
    
    -- 3. Deaths: Take highest (more information)
    if remoteState.deathCount > self.deathCount then
        self.deathCount = remoteState.deathCount
        updated = true
        table.insert(updateReasons, "Tode: +" .. (remoteState.deathCount - self.deathCount))
        
        if self.frame and self.frame.deathText then
            self.frame.deathText:SetText("" .. self.deathCount)
        end
    end
    
    -- 4. Trash: Take highest (compare absolute HP to avoid rounding issues)
    local ourTrashProgress, ourTrashHP = 0, 0
    if TDTTrashCounter then
        ourTrashProgress, ourTrashHP = TDTTrashCounter:getProgress()
    end
    
    -- Only update if remote has significantly more trash killed (> 1 HP difference)
    -- This prevents floating-point rounding from causing infinite sync loops
    if remoteState.trashKilledHP > (ourTrashHP + 1) and TDTTrashCounter then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Trash HP: " .. ourTrashHP .. " -> " .. remoteState.trashKilledHP, 1, 1, 0)
        end
        
        TDTTrashCounter:setTrashHP(remoteState.trashKilledHP)
        updated = true
        table.insert(updateReasons, "Trash: " .. math.floor(ourTrashProgress) .. "% -> " .. math.floor(remoteState.trashProgress) .. "%")
    end
    
    -- 5. Boss Kills: Merge killTimes (take latest times for each boss)
    if remoteState.killTimesData and remoteState.killTimesData ~= "" then
        local remoteKillTimes = self:deserializeKillTimes(remoteState.killTimesData)
        local mergedKills = self:mergeKillTimes(self.killTimes, remoteKillTimes)
        
        if table.getn(mergedKills) > table.getn(self.killTimes) then
            self.killTimes = mergedKills
            updated = true
            table.insert(updateReasons, "Boss-Kills: +" .. (table.getn(mergedKills) - table.getn(self.killTimes)))
            
            -- Update UI
            self:updateBossRows()
        end
    end
    
    -- 6. Countdown state
    if remoteState.isCountingDown and not self.isCountingDown then
        self.isCountingDown = true
        updated = true
        table.insert(updateReasons, "Countdown gestartet")
    end
    
    -- Save and notify if anything was updated
    if updated then
        self:saveLastRun()
        self:updateTimerDisplay()
        
        if TurtleDungeonTimerDB.debug then
            local reasonStr = table.concat(updateReasons, ", ")
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Periodic Merge von " .. remoteState.sender .. ": " .. reasonStr, 1, 1, 0)
        end
    end
end

function TurtleDungeonTimer:mergeKillTimes(ours, theirs)
    -- Create a map of boss index -> kill data
    local killMap = {}
    
    -- Add our kills
    for i, killData in ipairs(ours) do
        if not killMap[killData.index] or killData.time > killMap[killData.index].time then
            killMap[killData.index] = killData
        end
    end
    
    -- Merge their kills (take latest times)
    for i, killData in ipairs(theirs) do
        if not killMap[killData.index] or killData.time > killMap[killData.index].time then
            killMap[killData.index] = killData
        end
    end
    
    -- Convert map back to array, sorted by index
    local merged = {}
    for index, killData in pairs(killMap) do
        table.insert(merged, killData)
    end
    
    table.sort(merged, function(a, b)
        return a.index < b.index
    end)
    
    return merged
end

-- ============================================================================
-- RUN-ID SYSTEM
-- ============================================================================

function TurtleDungeonTimer:broadcastRunId()
    if not self.currentRunId then
        -- Generate new Run ID
        self.currentRunId = self:generateRunId()
        
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Generated Run-ID: " .. self.currentRunId, 1, 1, 0)
        end
    end
    
    -- Broadcast to group
    self:sendSyncMessage("RUN_ID", self.currentRunId)
end

function TurtleDungeonTimer:onRunIdReceived(runId, sender)
    if not runId or runId == "" then
        return
    end
    
    -- Accept Run ID if we don't have one yet
    if not self.currentRunId then
        self.currentRunId = runId
        
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Run-ID empfangen von " .. sender .. ": " .. runId, 1, 1, 0)
        end
    end
end

function TurtleDungeonTimer:clearRunId()
    self.currentRunId = nil
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Run-ID geloescht", 1, 1, 0)
    end
end

-- Handle world buff removal request
function TurtleDungeonTimer:onSyncRemoveWorldBuffs(sender)
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug Sync] Received REMOVE_WORLD_BUFFS from: " .. sender, 0, 1, 1)
    end
    
    -- Only respond to group leaders for security
    if not self:isPlayerGroupLeader(sender) then
        if TurtleDungeonTimerDB.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[Debug] Ignoring world buff removal from non-leader: " .. sender, 0, 1, 1)
        end
        return
    end
    
    if TurtleDungeonTimerDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[Debug] Leader verified, removing own world buffs", 0, 1, 1)
    end
    
    -- Remove our own world buffs
    self:removeOwnWorldBuffs()
    
    TDT_Print("WORLDBUFF_REMOVED_BY_LEADER", "warning", sender)
end

-- Check if a player is the group leader
function TurtleDungeonTimer:isPlayerGroupLeader(playerName)
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            print(name, rank)
            if name == playerName and rank == 2 then
                return true
            end
        end
        return false
    elseif GetNumPartyMembers() > 0 then
        -- In party, check if player is the leader
        if GetNumPartyMembers() > 0 then
            -- In a party, leader is not in party1-4, they are "player" unit
            local leaderName = UnitName("party") or UnitName("player")
            -- Actually, in 1.12, we need to check differently
            -- Party leader will have specific unit ID or be the player themselves
            if playerName == UnitName("player") then
                -- Check if we (the player) are the party leader
                local isLeader = IsPartyLeader()
                return isLeader == 1 or isLeader == true
            end
            -- For other party members, leader status is harder to determine
            -- We'll trust that only actual leaders send this message
            return false
        end
        return false
    else
        -- Solo player
        return playerName == UnitName("player")
    end
end

-- ============================================================================
-- VERSION COMPATIBILITY CHECK
-- ============================================================================

function TurtleDungeonTimer:isVersionCompatible(theirVersion)
    -- Extract major version (first number before first dot)
    local _, _, myMajor = string.find(self.SYNC_VERSION, "^(%d+)")
    local _, _, theirMajor = string.find(theirVersion, "^(%d+)")
    
    myMajor = tonumber(myMajor) or 0
    theirMajor = tonumber(theirMajor) or 0
    
    return myMajor == theirMajor
end
