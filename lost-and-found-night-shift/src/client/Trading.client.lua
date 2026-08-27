local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local tradeUpdate = remotes:WaitForChild("TradeUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "LostAndFoundTradeHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 35
gui.Parent = playerGui

local function corner(target, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = target
end

local function stroke(target, transparency, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(82, 96, 114)
    s.Thickness = thickness or 1.1
    s.Transparency = transparency or 0.35
    s.Parent = target
    return s
end

local function makeLabel(parent, name, size, position, textSize, font, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position or UDim2.new()
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.TextSize = textSize or 12
    label.Font = font or Enum.Font.Gotham
    label.TextColor3 = color or Color3.fromRGB(232, 236, 242)
    label.Parent = parent
    return label
end

local function makeButton(parent, name, text, size, position, background, textColor)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position or UDim2.new()
    button.BackgroundColor3 = background or Color3.fromRGB(35, 43, 55)
    button.BackgroundTransparency = 0.03
    button.BorderSizePixel = 0
    button.Text = text or "BUTTON"
    button.TextColor3 = textColor or Color3.fromRGB(236, 240, 245)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.TextWrapped = true
    button.Parent = parent
    corner(button, 8)
    return button
end

local tradeButton = makeButton(
    gui,
    "TradeButton",
    "TRADE",
    UDim2.fromOffset(128, 30),
    UDim2.new(1, -146, 0, 132),
    Color3.fromRGB(25, 31, 40),
    Color3.fromRGB(207, 181, 255)
)
tradeButton.AnchorPoint = Vector2.new(0, 0)
stroke(tradeButton, 0.35, Color3.fromRGB(127, 102, 176), 1.1)

local popup = Instance.new("Frame")
popup.Name = "TradePopup"
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Size = UDim2.fromOffset(410, 330)
popup.Position = UDim2.new(0.53, 0, 0.52, 0)
popup.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
popup.BackgroundTransparency = 0.01
popup.BorderSizePixel = 0
popup.Visible = false
popup.Active = true
popup.Parent = gui
corner(popup, 12)
stroke(popup, 0.15, Color3.fromRGB(143, 109, 207), 1.2)

local popupConstraint = Instance.new("UISizeConstraint")
popupConstraint.MinSize = Vector2.new(350, 300)
popupConstraint.MaxSize = Vector2.new(430, 350)
popupConstraint.Parent = popup

local title = makeLabel(popup, "Title", UDim2.new(1, -60, 0, 30), UDim2.fromOffset(14, 8), 15, Enum.Font.GothamBold, Color3.fromRGB(224, 196, 255))
title.Text = "SECURE SERIAL TRADE"

local status = makeLabel(popup, "Status", UDim2.new(1, -28, 0, 32), UDim2.fromOffset(14, 40), 10, Enum.Font.GothamMedium, Color3.fromRGB(151, 164, 181))
status.Text = "Same-server • one serialized item for one serialized item"

local close = makeButton(popup, "Close", "×", UDim2.fromOffset(30, 30), UDim2.new(1, -39, 0, 7), Color3.fromRGB(38, 45, 57))
close.TextSize = 16

local content = Instance.new("ScrollingFrame")
content.Name = "TradeContent"
content.Size = UDim2.new(1, -28, 1, -126)
content.Position = UDim2.fromOffset(14, 76)
content.BackgroundColor3 = Color3.fromRGB(18, 23, 31)
content.BackgroundTransparency = 0.12
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.fromOffset(0, 0)
content.Parent = popup
corner(content, 8)

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 8)
contentPadding.PaddingBottom = UDim.new(0, 8)
contentPadding.PaddingLeft = UDim.new(0, 8)
contentPadding.PaddingRight = UDim.new(0, 8)
contentPadding.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 7)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.Size = UDim2.new(1, -28, 0, 38)
actionBar.Position = UDim2.new(0, 14, 1, -44)
actionBar.BackgroundTransparency = 1
actionBar.Parent = popup

local messageToast = makeLabel(gui, "TradeToast", UDim2.fromOffset(350, 44), UDim2.new(0.5, -175, 0, 64), 11, Enum.Font.GothamBold, Color3.fromRGB(233, 236, 242))
messageToast.BackgroundColor3 = Color3.fromRGB(22, 29, 38)
messageToast.BackgroundTransparency = 0.03
messageToast.BorderSizePixel = 0
messageToast.TextXAlignment = Enum.TextXAlignment.Center
messageToast.Visible = false
corner(messageToast, 8)
stroke(messageToast, 0.3, Color3.fromRGB(143, 109, 207), 1.1)

local activeState = nil
local activeRequest = nil
local toastToken = 0

local function clearDynamic(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function showToast(text, color)
    toastToken += 1
    local token = toastToken
    messageToast.Text = tostring(text or "")
    messageToast.TextColor3 = color or Color3.fromRGB(233, 236, 242)
    messageToast.Visible = true
    task.delay(2.6, function()
        if token == toastToken then messageToast.Visible = false end
    end)
end

local function setOtherHudVisible(visible)
    local mainHud = playerGui:FindFirstChild("LostAndFoundHUD")
    if mainHud then
        local compact = mainHud:FindFirstChild("CompactCaseHUD")
        local casePopup = mainHud:FindFirstChild("CaseFilePopup")
        local moneyBar = mainHud:FindFirstChild("MoneyBar")
        if compact then compact.Visible = visible end
        if moneyBar then moneyBar.Visible = visible end
        if not visible and casePopup then casePopup.Visible = false end
    end

    local collectionHud = playerGui:FindFirstChild("LostAndFoundCollectionHUD")
    if collectionHud then
        local collectionPopup = collectionHud:FindFirstChild("CollectionPopup")
        local indexButton = collectionHud:FindFirstChild("IndexButton")
        if collectionPopup then collectionPopup.Visible = false end
        if indexButton then indexButton.Visible = visible end
    end

    local archiveHud = playerGui:FindFirstChild("LostAndFoundM3HUD")
    if archiveHud then
        local archivePopup = archiveHud:FindFirstChild("ArchivePopup")
        local archiveButton = archiveHud:FindFirstChild("ArchiveButton")
        if archivePopup then archivePopup.Visible = false end
        if archiveButton then archiveButton.Visible = visible end
    end
end

local function setOpen(open)
    popup.Visible = open
    tradeButton.Visible = not open
    setOtherHudVisible(not open)
end

local function addTextRow(text, color, height)
    local row = makeLabel(content, "Row", UDim2.new(1, -2, 0, height or 30), UDim2.new(), 11, Enum.Font.GothamMedium, color or Color3.fromRGB(211, 218, 228))
    row.Text = text
    row.TextYAlignment = Enum.TextYAlignment.Center
    return row
end

local function itemText(item)
    if not item then return "NONE SELECTED" end
    return string.format("%s\n%s  •  %s", tostring(item.name), tostring(item.serial), tostring(item.rarity))
end

local function renderLobby(payload)
    activeState = nil
    activeRequest = nil
    clearDynamic(content)
    clearDynamic(actionBar)
    title.Text = "SECURE SERIAL TRADE"
    status.Text = payload.ready and "Choose a player in this server." or ("Trade unavailable: " .. tostring(payload.reason or "NOT READY"))

    local players = payload.players or {}
    if #players == 0 then
        addTextRow("No other players are in this server.", Color3.fromRGB(151, 164, 181), 44)
    end

    for _, other in ipairs(players) do
        local row = Instance.new("Frame")
        row.Name = "Player_" .. tostring(other.userId)
        row.Size = UDim2.new(1, -2, 0, 48)
        row.BackgroundColor3 = Color3.fromRGB(25, 30, 39)
        row.BackgroundTransparency = 0.04
        row.BorderSizePixel = 0
        row.Parent = content
        corner(row, 8)

        local name = makeLabel(row, "Name", UDim2.new(1, -110, 0, 24), UDim2.fromOffset(10, 4), 11, Enum.Font.GothamBold, Color3.fromRGB(236, 239, 244))
        name.Text = tostring(other.name)
        local state = makeLabel(row, "State", UDim2.new(1, -110, 0, 16), UDim2.fromOffset(10, 27), 9, Enum.Font.GothamMedium, other.ready and Color3.fromRGB(110, 224, 226) or Color3.fromRGB(145, 157, 174))
        state.Text = other.ready and "READY TO TRADE" or tostring(other.reason or "UNAVAILABLE")

        local request = makeButton(row, "Request", other.ready and "REQUEST" or "LOCKED", UDim2.fromOffset(90, 30), UDim2.new(1, -100, 0, 9), other.ready and Color3.fromRGB(92, 68, 139) or Color3.fromRGB(45, 49, 58))
        request.Active = other.ready == true
        request.AutoButtonColor = other.ready == true
        if other.ready then
            request.Activated:Connect(function()
                tradeUpdate:FireServer("REQUEST", { targetUserId = other.userId })
            end)
        end
    end

    local refresh = makeButton(actionBar, "Refresh", "REFRESH PLAYERS", UDim2.fromOffset(150, 30), UDim2.new(0.5, -75, 0, 4), Color3.fromRGB(35, 43, 55))
    refresh.Activated:Connect(function()
        tradeUpdate:FireServer("REFRESH")
    end)
end

local function renderIncoming(payload)
    activeState = nil
    activeRequest = payload
    clearDynamic(content)
    clearDynamic(actionBar)
    setOpen(true)
    title.Text = "TRADE REQUEST"
    status.Text = "Review before accepting. No item moves until both final-confirm."
    addTextRow(tostring(payload.fromName) .. " wants to trade serialized items with you.", Color3.fromRGB(236, 239, 244), 60)

    local decline = makeButton(actionBar, "Decline", "DECLINE", UDim2.fromOffset(110, 30), UDim2.fromOffset(0, 4), Color3.fromRGB(74, 43, 48))
    local accept = makeButton(actionBar, "Accept", "ACCEPT", UDim2.fromOffset(110, 30), UDim2.new(1, -110, 0, 4), Color3.fromRGB(46, 93, 86))
    decline.Activated:Connect(function()
        tradeUpdate:FireServer("RESPOND", { fromUserId = payload.fromUserId, accept = false })
        activeRequest = nil
        tradeUpdate:FireServer("OPEN")
    end)
    accept.Activated:Connect(function()
        tradeUpdate:FireServer("RESPOND", { fromUserId = payload.fromUserId, accept = true })
    end)
end

local function renderInventoryPicker(state)
    clearDynamic(content)
    clearDynamic(actionBar)
    title.Text = "SELECT SERIAL"
    status.Text = "Choose the exact owned instance you want to offer."

    for _, item in ipairs(state.inventory or {}) do
        local row = makeButton(content, "Item_" .. tostring(item.instanceId), itemText(item), UDim2.new(1, -2, 0, 52), UDim2.new(), Color3.fromRGB(25, 30, 39), Color3.fromRGB(232, 236, 242))
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextSize = 10
        row.Activated:Connect(function()
            tradeUpdate:FireServer("SELECT_ITEM", { instanceId = item.instanceId })
        end)
    end

    if #(state.inventory or {}) == 0 then
        addTextRow("No tradeable serialized items.", Color3.fromRGB(151, 164, 181), 44)
    end

    local back = makeButton(actionBar, "Back", "BACK", UDim2.fromOffset(100, 30), UDim2.new(0.5, -50, 0, 4), Color3.fromRGB(35, 43, 55))
    back.Activated:Connect(function()
        if activeState then
            -- Re-render from the last authoritative server snapshot.
            tradeUpdate:FireServer("REFRESH")
            renderIncoming({ fromUserId = 0, fromName = "" })
        end
    end)
end

local function renderActive(state)
    activeState = state
    activeRequest = nil
    clearDynamic(content)
    clearDynamic(actionBar)
    setOpen(true)
    title.Text = "TRADE // " .. tostring(state.partner and state.partner.name or "PLAYER")

    if state.stage == "SELECTING" then
        status.Text = "Pick one serial each, then both confirm the offer."
    elseif state.stage == "REVIEW" then
        if (state.reviewRemaining or 0) > 0 then
            status.Text = string.format("FINAL REVIEW LOCK • %.1fs", state.reviewRemaining)
        else
            status.Text = "FINAL REVIEW READY • serials are locked"
        end
    elseif state.stage == "COMMITTING" then
        status.Text = "COMMITTING OWNERSHIP • do not leave"
    else
        status.Text = tostring(state.stage)
    end

    local yourTitle = addTextRow("YOUR OFFER", Color3.fromRGB(224, 196, 255), 20)
    yourTitle.Font = Enum.Font.GothamBold
    local yourOffer = makeButton(content, "YourOffer", itemText(state.yourOffer), UDim2.new(1, -2, 0, 58), UDim2.new(), Color3.fromRGB(28, 34, 44), Color3.fromRGB(236, 239, 244))
    yourOffer.TextXAlignment = Enum.TextXAlignment.Left
    yourOffer.TextSize = 10
    yourOffer.Active = state.stage == "SELECTING"
    yourOffer.AutoButtonColor = state.stage == "SELECTING"
    if state.stage == "SELECTING" then
        yourOffer.Activated:Connect(function()
            renderInventoryPicker(state)
        end)
    end

    local theirTitle = addTextRow("THEIR OFFER", Color3.fromRGB(110, 224, 226), 20)
    theirTitle.Font = Enum.Font.GothamBold
    local theirOffer = addTextRow(itemText(state.theirOffer), Color3.fromRGB(211, 220, 230), 58)
    theirOffer.BackgroundColor3 = Color3.fromRGB(24, 31, 38)
    theirOffer.BackgroundTransparency = 0.08
    theirOffer.TextXAlignment = Enum.TextXAlignment.Left
    corner(theirOffer, 8)

    local confirmState = string.format("YOU: %s   PARTNER: %s", state.yourConfirmed and "CONFIRMED" or "WAITING", state.partnerConfirmed and "CONFIRMED" or "WAITING")
    if state.stage == "REVIEW" or state.stage == "COMMITTING" then
        confirmState = confirmState .. string.format("\nFINAL — YOU: %s   PARTNER: %s", state.yourFinal and "YES" or "WAIT", state.partnerFinal and "YES" or "WAIT")
    end
    addTextRow(confirmState, Color3.fromRGB(151, 164, 181), 38)

    local cancel = makeButton(actionBar, "Cancel", "CANCEL", UDim2.fromOffset(90, 30), UDim2.fromOffset(0, 4), Color3.fromRGB(74, 43, 48))
    cancel.Active = state.stage ~= "COMMITTING"
    cancel.AutoButtonColor = state.stage ~= "COMMITTING"
    if state.stage ~= "COMMITTING" then
        cancel.Activated:Connect(function()
            tradeUpdate:FireServer("CANCEL")
        end)
    end

    if state.stage == "SELECTING" then
        local confirm = makeButton(actionBar, "Confirm", state.yourConfirmed and "CONFIRMED" or "CONFIRM OFFER", UDim2.fromOffset(130, 30), UDim2.new(1, -130, 0, 4), state.yourConfirmed and Color3.fromRGB(44, 66, 64) or Color3.fromRGB(46, 93, 86))
        confirm.Active = not state.yourConfirmed and state.yourOffer ~= nil and state.theirOffer ~= nil
        confirm.AutoButtonColor = confirm.Active
        if confirm.Active then
            confirm.Activated:Connect(function()
                tradeUpdate:FireServer("CONFIRM")
            end)
        end
    elseif state.stage == "REVIEW" then
        local ready = (state.reviewRemaining or 0) <= 0
        local final = makeButton(actionBar, "Final", state.yourFinal and "FINAL CONFIRMED" or (ready and "FINAL CONFIRM" or "REVIEW..."), UDim2.fromOffset(140, 30), UDim2.new(1, -140, 0, 4), ready and Color3.fromRGB(92, 68, 139) or Color3.fromRGB(45, 49, 58))
        final.Active = ready and not state.yourFinal
        final.AutoButtonColor = final.Active
        if final.Active then
            final.Activated:Connect(function()
                tradeUpdate:FireServer("FINAL_CONFIRM")
            end)
        end
    end
end

tradeButton.Activated:Connect(function()
    setOpen(true)
    clearDynamic(content)
    clearDynamic(actionBar)
    status.Text = "Loading secure trade lobby..."
    tradeUpdate:FireServer("OPEN")
end)

close.Activated:Connect(function()
    if activeState and activeState.stage and activeState.stage ~= "COMPLETED" then
        if activeState.stage ~= "COMMITTING" then
            tradeUpdate:FireServer("CANCEL")
        end
        return
    end
    activeRequest = nil
    setOpen(false)
end)

tradeUpdate.OnClientEvent:Connect(function(kind, payload)
    payload = payload or {}
    if kind == "LOBBY_SYNC" then
        setOpen(true)
        renderLobby(payload)
    elseif kind == "REQUEST_INCOMING" then
        renderIncoming(payload)
    elseif kind == "REQUEST_SENT" then
        setOpen(true)
        clearDynamic(content)
        clearDynamic(actionBar)
        title.Text = "REQUEST SENT"
        status.Text = "Waiting for " .. tostring(payload.targetName or "player") .. " to respond."
        addTextRow("No item is locked yet. You can close this panel safely.", Color3.fromRGB(151, 164, 181), 50)
    elseif kind == "REQUEST_DECLINED" then
        showToast("Trade declined by " .. tostring(payload.byName or "player"), Color3.fromRGB(255, 166, 166))
        tradeUpdate:FireServer("OPEN")
    elseif kind == "TRADE_STATE" then
        renderActive(payload)
    elseif kind == "TRADE_ERROR" then
        showToast(payload.message or "Trade error", Color3.fromRGB(255, 166, 166))
    elseif kind == "TRADE_CANCELLED" then
        activeState = nil
        showToast("TRADE CANCELLED • " .. tostring(payload.reason or "CANCELLED"), Color3.fromRGB(255, 190, 140))
        tradeUpdate:FireServer("OPEN")
    elseif kind == "TRADE_COMPLETED" then
        activeState = nil
        setOpen(true)
        clearDynamic(content)
        clearDynamic(actionBar)
        title.Text = "TRADE COMPLETE"
        status.Text = "Ownership saved and serial provenance updated."
        addTextRow("SENT\n" .. itemText(payload.sent), Color3.fromRGB(218, 190, 255), 64)
        addTextRow("RECEIVED\n" .. itemText(payload.received), Color3.fromRGB(110, 224, 226), 64)
        addTextRow("Trade ID\n" .. tostring(payload.tradeId or "UNKNOWN"), Color3.fromRGB(145, 157, 174), 48)
        local done = makeButton(actionBar, "Done", "DONE", UDim2.fromOffset(100, 30), UDim2.new(0.5, -50, 0, 4), Color3.fromRGB(46, 93, 86))
        done.Activated:Connect(function()
            tradeUpdate:FireServer("OPEN")
        end)
    end
end)
