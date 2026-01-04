-- ============================================================================
-- Turtle Dungeon Timer - Group Synchronization
-- ============================================================================

TurtleDungeonTimer.SYNC_PREFIX = "TDT_SYNC"
TurtleDungeonTimer.SYNC_VERSION = "1.0"
TurtleDungeonTimer.playersWithAddon = {}
TurtleDungeonTimer.resetVotes = {}
TurtleDungeonTimer.resetInitiator = nil
TurtleDungeonTimer.resetVoteDialog = nil
TurtleDungeonTimer.currentRunId = nil

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

function TurtleDungeonTimer:onAddonCheckResponse(sender)
    self.playersWithAddon[sender] = true
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
        instance:checkForAddons()
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
            DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Turtle Dungeon Timer]||r Timer wurde zurückgesetzt (Gruppenbeschluss)", 1, 1, 0)
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
        self:sendSyncMessage("ADDON_RESPONSE")
    elseif msgType == "ADDON_RESPONSE" then
        self:onAddonCheckResponse(sender)
    elseif msgType == "RESET_REQUEST" then
        self:onSyncResetRequest(sender)
    elseif msgType == "RESET_VOTE" then
        self:onSyncResetVote(data, sender)
    elseif msgType == "RESET_CANCEL" then
        self:onSyncResetCancel(sender)
    elseif msgType == "RESET_EXECUTE" then
        self:onSyncResetExecute(sender)
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
    
    DEFAULT_CHAT_FRAME:AddMessage("||cff00ff00[Turtle Dungeon Timer]||r Timer wurde zurückgesetzt (Gruppenbeschluss)", 1, 1, 0)
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
    message1:SetText(initiator .. " möchte den Timer zurücksetzen.")
    message1:SetJustifyH("CENTER")
    
    local message2 = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message2:SetPoint("TOP", message1, "BOTTOM", 0, -10)
    message2:SetWidth(260)
    message2:SetText("Stimmen Sie zu?")
    message2:SetJustifyH("CENTER")
    
    local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    yesButton:SetWidth(100)
    yesButton:SetHeight(30)
    yesButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -105, 15)
    yesButton:SetText("Ja")
    yesButton:SetScript("OnClick", function()
        local self = TurtleDungeonTimer:getInstance()
        self:voteReset(true)
        self.resetVoteDialog:Hide()
    end)
    
    local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    noButton:SetWidth(100)
    noButton:SetHeight(30)
    noButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", 105, 15)
    noButton:SetText("Nein")
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
