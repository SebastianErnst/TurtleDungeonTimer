# Sync.lua - Group Synchronization Module

## Overview
Handles all party/raid synchronization including addon detection, reset voting system, boss kill broadcasts, and death notifications. Uses WoW's addon communication channel.

---

## Module Responsibilities
- Addon user detection in group
- Reset vote initiation and tallying
- Boss kill synchronization
- Death count synchronization
- Timer stop broadcasts
- Vote dialog management

---

## Constants & State

### Sync Protocol
```lua
TurtleDungeonTimer.SYNC_PREFIX = "TDT_SYNC"    -- Addon message prefix
TurtleDungeonTimer.SYNC_VERSION = "1.0"        -- Protocol version
```

### State Variables
```lua
TurtleDungeonTimer.playersWithAddon = {}       -- {playerName = true}
TurtleDungeonTimer.resetVotes = {}             -- {playerName = "yes"/"no"}
TurtleDungeonTimer.resetInitiator = nil        -- string: Player who started vote
TurtleDungeonTimer.resetVoteDialog = nil       -- Frame: Vote dialog reference
TurtleDungeonTimer.currentRunId = nil          -- string: UUID for current run
```

---

## Message Format

### Protocol Structure
```
VERSION;MESSAGE_TYPE;DATA
```

**Example Messages:**
```
1.0;ADDON_CHECK
1.0;ADDON_RESPONSE
1.0;RESET_REQUEST
1.0;RESET_VOTE;yes
1.0;RESET_VOTE;no
1.0;RESET_CANCEL
1.0;RESET_EXECUTE
1.0;BOSS;BossName:123.45:67.89
1.0;DEATH;5
1.0;STOP
```

---

## UUID Generation

### generateRunId()
**Purpose:** Generate unique run identifier  
**Returns:** `string` - Format: `timestamp-random`

**Implementation:**
```lua
function TurtleDungeonTimer:generateRunId()
    local timestamp = math.floor(GetTime() * 1000)
    local random = math.random(10000, 99999)
    return timestamp .. "-" .. random
end
```

**Usage:**
- Ensures each run has unique ID
- Used for preventing duplicate sync messages
- Combines millisecond timestamp with random number

---

## Addon Detection

### checkForAddons()
**Purpose:** Request addon check from all group members  
**Called by:**
- `initializeSync()` on load
- `PARTY_MEMBERS_CHANGED` event
- `RAID_ROSTER_UPDATE` event

**Process:**
1. Clear `playersWithAddon` table
2. Check if in group (raid or party)
3. If in group: `sendSyncMessage("ADDON_CHECK")`
4. All players with addon respond with ADDON_RESPONSE

**Solo Behavior:** Returns early if not in group

---

### onAddonCheckResponse(sender)
**Purpose:** Add player to addon user list  
**Parameters:**
- `sender` - string: Player name

**Action:**
```lua
self.playersWithAddon[sender] = true
```

---

### getAddonUserCount()
**Purpose:** Count players with addon  
**Returns:** `number` - Count of addon users

**Implementation:**
```lua
function TurtleDungeonTimer:getAddonUserCount()
    local count = 0
    for _ in pairs(self.playersWithAddon) do
        count = count + 1
    end
    return count
end
```

**Used by:** Vote tallying system

---

## Sync Initialization

### initializeSync()
**Purpose:** Register sync events and perform initial check  
**Called by:** `Core.lua:initialize()`

**Event Registration:**
```lua
if not self.syncFrame then
    self.syncFrame = CreateFrame("Frame")
    self.syncFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.syncFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self.syncFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    self.syncFrame:SetScript("OnEvent", TurtleDungeonTimer.syncFrameOnEvent)
end
```

---

### syncFrameOnEvent()
**Purpose:** Central event dispatcher for sync events  
**Uses Implicit Globals:** `event`, `arg1`, `arg2`, `arg3`, `arg4`

**Event Handling:**
```lua
function TurtleDungeonTimer:syncFrameOnEvent()
    local instance = TurtleDungeonTimer:getInstance()
    
    if event == "CHAT_MSG_ADDON" then
        local prefix = arg1
        local message = arg2
        local channel = arg3
        local sender = arg4
        
        if prefix == instance.SYNC_PREFIX then
            instance:onSyncMessage(message, sender, channel)
        end
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        instance:checkForAddons()
    end
end
```

---

## Sending Messages

### sendSyncMessage(msgType, data)
**Purpose:** Send addon message to group  
**Parameters:**
- `msgType` - string: Message type (ADDON_CHECK, RESET_REQUEST, etc.)
- `data` - string (optional): Additional data payload

**Process:**
```lua
function TurtleDungeonTimer:sendSyncMessage(msgType, data)
    -- Don't send if not in group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return
    end
    
    -- Build message
    local message = self.SYNC_VERSION .. ";" .. msgType
    if data then
        message = message .. ";" .. data
    end
    
    -- Determine channel
    local channel = "PARTY"
    if GetNumRaidMembers() > 0 then
        channel = "RAID"
    end
    
    -- Send
    SendAddonMessage(self.SYNC_PREFIX, message, channel)
end
```

**Channel Selection:**
- "RAID" if in raid group
- "PARTY" if in party
- No send if solo

---

## Reset Vote System

### Reset Vote Flow
```
1. Leader clicks Reset → showResetInitiateConfirmation()
2. Leader confirms → syncTimerReset()
3. All players receive RESET_REQUEST → showResetVoteDialog()
4. Players vote Yes/No → voteReset(vote)
5. Votes synced → checkResetVotes()
6. If all Yes → syncResetExecute() → performResetSilent()
7. If any No → syncResetCancel()
```

---

### syncTimerReset()
**Purpose:** Initiate reset vote (called by initiator only)  
**Called by:** `Timer.lua:performReset()` in group

**Process:**
```lua
function TurtleDungeonTimer:syncTimerReset()
    self.resetInitiator = UnitName("player")
    self.resetVotes = {}
    
    -- Add own vote as "yes"
    self.resetVotes[self.resetInitiator] = "yes"
    
    self:sendSyncMessage("RESET_REQUEST")
    self:startResetVote()
end
```

---

### startResetVote()
**Purpose:** Local handling after sending reset request  
**Actions:**
- Send chat message: "Du hast eine Resetanfrage gestellt"
- Initiator automatically votes "yes"

---

### onSyncResetRequest(sender)
**Purpose:** Receive reset request and show vote dialog  
**Parameters:**
- `sender` - string: Player who initiated vote

**Process:**
1. Set `resetInitiator = sender`
2. Clear `resetVotes` table
3. Show vote dialog via `showResetVoteDialog(sender)`

---

### showResetVoteDialog(initiator)
**Purpose:** Display vote dialog for group members  
**Parameters:**
- `initiator` - string: Player name who started vote

**Dialog Elements:**
- Title: "Timer Reset?"
- Message: "[Player] möchte den Timer zurücksetzen. Zustimmen?"
- Buttons:
  - **Ja (Yes):** Call `voteReset("yes")`
  - **Nein (No):** Call `voteReset("no")`

**Frame Setup:**
```lua
local dialog = CreateFrame("Frame", nil, UIParent)
dialog:SetWidth(300)
dialog:SetHeight(120)
dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
dialog:SetFrameStrata("DIALOG")
dialog:EnableMouse(true)
self.resetVoteDialog = dialog
```

---

### voteReset(vote)
**Purpose:** Cast vote and sync with group  
**Parameters:**
- `vote` - string: "yes" or "no"

**Process:**
```lua
function TurtleDungeonTimer:voteReset(vote)
    -- Record own vote
    local playerName = UnitName("player")
    self.resetVotes[playerName] = vote
    
    -- Sync vote to group
    self:sendSyncMessage("RESET_VOTE", vote)
    
    -- Close dialog
    if self.resetVoteDialog then
        self.resetVoteDialog:Hide()
        self.resetVoteDialog = nil
    end
    
    -- Check if all votes in
    self:checkResetVotes()
end
```

---

### onSyncResetVote(data, sender)
**Purpose:** Receive vote from group member  
**Parameters:**
- `data` - string: "yes" or "no"
- `sender` - string: Voter name

**Process:**
```lua
function TurtleDungeonTimer:onSyncResetVote(data, sender)
    -- Ignore if no active vote
    if not self.resetInitiator then
        return
    end
    
    -- Record vote
    self.resetVotes[sender] = data
    
    -- Check if all votes in
    self:checkResetVotes()
end
```

---

### checkResetVotes()
**Purpose:** Tally votes and execute/cancel based on result  
**Called by:** `voteReset()`, `onSyncResetVote()`

**Vote Counting:**
```lua
function TurtleDungeonTimer:checkResetVotes()
    if not self.resetInitiator then
        return
    end
    
    -- Count addon users (includes self)
    local expectedVotes = self:getAddonUserCount()
    if expectedVotes == 0 then
        expectedVotes = 1 -- Solo player
    end
    
    -- Count votes
    local totalVotes = 0
    local yesVotes = 0
    for player, vote in pairs(self.resetVotes) do
        totalVotes = totalVotes + 1
        if vote == "yes" then
            yesVotes = yesVotes + 1
        end
    end
    
    -- Wait for all votes
    if totalVotes < expectedVotes then
        return
    end
    
    -- Check result
    if yesVotes == totalVotes then
        -- All yes → execute reset
        if UnitName("player") == self.resetInitiator then
            self:sendSyncMessage("RESET_EXECUTE")
        end
        self:performResetSilent()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Timer wurde zurückgesetzt (Gruppenbeschluss)", 1, 1, 0)
    else
        -- At least one no → cancel
        if UnitName("player") == self.resetInitiator then
            self:sendSyncMessage("RESET_CANCEL")
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Reset-Abstimmung abgebrochen", 1, 1, 0)
    end
    
    -- Clear vote state
    self.resetInitiator = nil
    self.resetVotes = {}
end
```

**Vote Requirements:**
- **All** players must vote "yes" for reset to execute
- **Any** "no" vote cancels the reset
- Initiator sends RESET_EXECUTE or RESET_CANCEL to group

---

### onSyncResetExecute(sender)
**Purpose:** Execute reset after successful vote  
**Parameters:**
- `sender` - string: Initiator name

**Process:**
```lua
function TurtleDungeonTimer:onSyncResetExecute(sender)
    self.resetInitiator = nil
    self.resetVotes = {}
    self:performResetSilent()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Timer wurde zurückgesetzt (Gruppenbeschluss)", 1, 1, 0)
end
```

---

### onSyncResetCancel(sender)
**Purpose:** Cancel reset after failed vote  
**Parameters:**
- `sender` - string: Initiator name

**Process:**
```lua
function TurtleDungeonTimer:onSyncResetCancel(sender)
    self.resetInitiator = nil
    self.resetVotes = {}
    if self.resetVoteDialog then
        self.resetVoteDialog:Hide()
        self.resetVoteDialog = nil
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Turtle Dungeon Timer]|r Reset-Abstimmung abgebrochen", 1, 1, 0)
end
```

---

## Message Receiving

### onSyncMessage(message, sender, channel)
**Purpose:** Central message router for all sync messages  
**Parameters:**
- `message` - string: Full message (VERSION;TYPE;DATA)
- `sender` - string: Sender name
- `channel` - string: "PARTY" or "RAID"

**Parsing:**
```lua
function TurtleDungeonTimer:onSyncMessage(message, sender, channel)
    -- Parse message
    local version, msgType, data = self:parseSyncMessage(message)
    
    -- Version check
    if version ~= self.SYNC_VERSION then
        return -- Ignore incompatible versions
    end
    
    -- Route to handler
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
    elseif msgType == "BOSS" then
        self:onSyncBossKill(data, sender)
    elseif msgType == "DEATH" then
        self:onSyncDeath(data, sender)
    elseif msgType == "STOP" then
        self:onSyncStop(sender)
    end
end
```

**Message Parsing:**
```lua
function TurtleDungeonTimer:parseSyncMessage(message)
    local parts = {}
    for part in string.gfind(message, "[^;]+") do
        table.insert(parts, part)
    end
    
    local version = parts[1]
    local msgType = parts[2]
    local data = parts[3] -- May be nil
    
    return version, msgType, data
end
```

**Lua 5.1 Note:** Uses `string.gfind()`, not `string.gmatch()`

---

## Helper Functions

### getGroupMemberCount()
**Purpose:** Get total group size including self  
**Returns:** `number`

```lua
function TurtleDungeonTimer:getGroupMemberCount()
    if GetNumRaidMembers() > 0 then
        return GetNumRaidMembers()
    elseif GetNumPartyMembers() > 0 then
        return GetNumPartyMembers() + 1 -- +1 for player
    end
    return 1 -- Solo
end
```

---

### getGroupChannel()
**Purpose:** Get appropriate chat channel for group  
**Returns:** `string` - "RAID", "PARTY", or `nil`

```lua
function TurtleDungeonTimer:getGroupChannel()
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end
```

---

## Integration Points

### Called By
- [Core.lua](CORE.md) - `initializeSync()` on load
- [Timer.lua](TIMER.md) - `syncTimerReset()` on reset
- [Events.lua](EVENTS.md) - `syncBossKill()`, `syncDeath()` on events

### Calls To
- [Timer.lua](TIMER.md) - `performResetSilent()` after vote
- WoW API - `SendAddonMessage()`, `GetNumRaidMembers()`, `GetNumPartyMembers()`

---

## Lua 5.1 Compliance

### String Parsing
```lua
-- ✅ CORRECT
for part in string.gfind(message, "[^;]+") do
    table.insert(parts, part)
end

-- ❌ WRONG
for part in string.gmatch(message, "[^;]+") do
    -- gmatch doesn't exist in Lua 5.1
end
```

### Event Handlers
```lua
-- ✅ CORRECT - Uses implicit globals
self.syncFrame:SetScript("OnEvent", TurtleDungeonTimer.syncFrameOnEvent)

function TurtleDungeonTimer:syncFrameOnEvent()
    -- Access 'event', 'arg1', 'arg2', etc.
    if event == "CHAT_MSG_ADDON" then
        local prefix = arg1
        local message = arg2
    end
end
```

---

## Error Handling

### Version Mismatches
- Ignores messages with different SYNC_VERSION
- Prevents protocol conflicts between addon versions

### Solo Player Detection
- All sync functions check if in group first
- Early return if solo to prevent errors

### Missing Data
- Nil checks for optional data fields
- Safe handling of incomplete messages

---

## Performance Notes

### Addon Check Frequency
- Only runs on group roster change
- Clears table each time to prevent stale entries
- Minimal overhead

### Vote System
- Vote state cleared after completion/cancellation
- Dialog destroyed to free memory
- No polling - event-driven

---

## Security Considerations

### Spam Prevention
- Only initiator can send RESET_REQUEST
- Only initiator can send RESET_EXECUTE/CANCEL
- All group members can vote

### Vote Integrity
- Each player can only vote once
- Vote table overwritten if duplicate vote
- All votes must be in for tally

---

## Testing Checklist
- [ ] Addon detection works in party/raid
- [ ] Reset vote requires unanimous "yes"
- [ ] Single "no" vote cancels reset
- [ ] Vote dialog shows initiator name
- [ ] Reset executes on all clients after vote
- [ ] Messages work in both party and raid
- [ ] Solo player doesn't send sync messages
- [ ] Version mismatch ignored gracefully

---

## See Also
- [Timer Module](TIMER.md)
- [Core Module](CORE.md)
- [Events Module](EVENTS.md)
