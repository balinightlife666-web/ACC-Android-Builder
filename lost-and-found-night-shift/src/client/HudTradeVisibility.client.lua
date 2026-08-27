local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local watched = {}

local function find(name, childName)
    local gui = playerGui:FindFirstChild(name)
    return gui and gui:FindFirstChild(childName) or nil
end

local function refreshTradeButton()
    local tradeHud = playerGui:FindFirstChild("LostAndFoundTradeHUD")
    if not tradeHud then return end
    local tradeButton = tradeHud:FindFirstChild("TradeButton")
    local tradePopup = tradeHud:FindFirstChild("TradePopup")
    if not tradeButton then return end

    local collectionPopup = find("LostAndFoundCollectionHUD", "CollectionPopup")
    local archivePopup = find("LostAndFoundM3HUD", "ArchivePopup")
    local casePopup = find("LostAndFoundHUD", "CaseFilePopup")

    local blocked = (collectionPopup and collectionPopup.Visible)
        or (archivePopup and archivePopup.Visible)
        or (casePopup and casePopup.Visible)
        or (tradePopup and tradePopup.Visible)

    tradeButton.Visible = not blocked
end

local function watchVisible(instance)
    if not instance or watched[instance] then return end
    watched[instance] = true
    instance:GetPropertyChangedSignal("Visible"):Connect(refreshTradeButton)
end

local function scan()
    local collectionPopup = find("LostAndFoundCollectionHUD", "CollectionPopup")
    local archivePopup = find("LostAndFoundM3HUD", "ArchivePopup")
    local casePopup = find("LostAndFoundHUD", "CaseFilePopup")
    local tradePopup = find("LostAndFoundTradeHUD", "TradePopup")
    watchVisible(collectionPopup)
    watchVisible(archivePopup)
    watchVisible(casePopup)
    watchVisible(tradePopup)
    refreshTradeButton()
end

playerGui.ChildAdded:Connect(function()
    task.defer(scan)
end)

task.spawn(function()
    for _ = 1, 30 do
        scan()
        task.wait(0.25)
    end
end)
