-- LOST & FOUND: NIGHT SHIFT — M5-A.1 top-right HUD stack hotfix.
-- M5-A v44 placed Station Shop at the same vertical slot as Collection Index.
-- Keep the existing utility stack intact and move Station Shop below Trade.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOP_Y = 170

local function apply()
    local shopGui = playerGui:FindFirstChild("LostAndFoundStationShop")
    local button = shopGui and shopGui:FindFirstChild("StationShopButton")
    if not button or not button:IsA("GuiObject") then return false end

    button.Position = UDim2.new(1, -18, 0, SHOP_Y)
    button:SetAttribute("HudStackSlot", "SHOP_AFTER_TRADE")
    return true
end

local function reconcile()
    for _ = 1, 80 do
        if apply() then return end
        task.wait(0.10)
    end
end

task.spawn(reconcile)

playerGui.ChildAdded:Connect(function(child)
    if child.Name == "LostAndFoundStationShop" then
        task.defer(reconcile)
    end
end)
