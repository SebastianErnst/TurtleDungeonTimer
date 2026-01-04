-- ============================================================================
-- Turtle Dungeon Timer - Minimap Button
-- ============================================================================

function TurtleDungeonTimer:createMinimapButton()
    if self.minimapButton then return end
    
    -- Create minimap button
    local button = CreateFrame("Button", "TurtleDungeonTimerMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Icon texture
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")  -- Pocket watch icon
    button.icon = icon
    
    -- Border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(52)
    overlay:SetHeight(52)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- Tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Turtle Dungeon Timer", 1, 1, 1)
        GameTooltip:AddLine("Left-Click: Toggle window", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-Click: Open menu", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Click handlers
    button:SetScript("OnClick", function()
        local timer = TurtleDungeonTimer:getInstance()
        if arg1 == "LeftButton" then
            timer:toggleWindow()
        elseif arg1 == "RightButton" then
            timer:showMinimapMenu()
        end
    end)
    
    -- Enable dragging
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function()
        this:LockHighlight()
        this.isDragging = true
    end)
    
    button:SetScript("OnDragStop", function()
        this:UnlockHighlight()
        this.isDragging = false
        TurtleDungeonTimer:getInstance():saveMinimapPosition()
    end)
    
    button:SetScript("OnUpdate", function()
        if this.isDragging then
            TurtleDungeonTimer:getInstance():updateMinimapButtonPosition()
        end
    end)
    
    self.minimapButton = button
    self:updateMinimapButtonPosition()
end

function TurtleDungeonTimer:updateMinimapButtonPosition()
    if not self.minimapButton then return end
    
    local angle = TurtleDungeonTimerDB.minimapAngle or 200
    local x, y
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    
    if self.minimapButton.isDragging then
        -- Calculate angle while dragging
        local centerX, centerY = Minimap:GetCenter()
        local mouseX, mouseY = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        mouseX = mouseX / scale
        mouseY = mouseY / scale
        
        local dx = mouseX - centerX
        local dy = mouseY - centerY
        angle = math.atan2(dy, dx)
        TurtleDungeonTimerDB.minimapAngle = angle
    end
    
    x = cos * 80
    y = sin * 80
    
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function TurtleDungeonTimer:saveMinimapPosition()
    -- Position is already saved in updateMinimapButtonPosition via TurtleDungeonTimerDB.minimapAngle
end

function TurtleDungeonTimer:toggleWindow()
    if not self.frame then return end
    
    if self.frame:IsVisible() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function TurtleDungeonTimer:showMinimapMenu()
    -- Create simple dropdown menu
    local menu = {
        {text = "Toggle Window", func = function() TurtleDungeonTimer:getInstance():toggleWindow() end},
        {text = "Reset Position", func = function() TurtleDungeonTimer:getInstance():resetMinimapPosition() end},
        {text = "Close", func = function() end}
    }
    
    -- In Vanilla, we need to use UIDropDownMenu if available
    -- For now, just toggle window on right-click
    self:toggleWindow()
end

function TurtleDungeonTimer:resetMinimapPosition()
    TurtleDungeonTimerDB.minimapAngle = 200
    self:updateMinimapButtonPosition()
end

function TurtleDungeonTimer:hideMinimapButton()
    if self.minimapButton then
        self.minimapButton:Hide()
    end
end

function TurtleDungeonTimer:showMinimapButton()
    if not self.minimapButton then
        self:createMinimapButton()
    else
        self.minimapButton:Show()
    end
end
