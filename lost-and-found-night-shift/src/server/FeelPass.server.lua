local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("LostAndFoundShared")
local Config = require(shared:WaitForChild("Config"))

local function tunePrompt(instance)
    if not instance:IsA("ProximityPrompt") then return end
    instance.MaxActivationDistance = Config.PromptDistance or 7
    instance.HoldDuration = Config.PromptHoldDuration or 0.08
    instance.RequiresLineOfSight = false
end

local world = workspace:WaitForChild("LostAndFoundM4D", 30)
if not world then return end

for _, instance in ipairs(world:GetDescendants()) do
    tunePrompt(instance)
end
world.DescendantAdded:Connect(function(instance)
    tunePrompt(instance)

    if instance:IsA("Model") and instance.Name == "ActiveClaimant" then
        task.spawn(function()
            task.wait(0.03)
            if not instance.Parent then return end

            local savedTransparency = {}
            local savedBillboards = {}
            for _, descendant in ipairs(instance:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    savedTransparency[descendant] = descendant.Transparency
                    descendant.Transparency = 1
                elseif descendant:IsA("BillboardGui") then
                    savedBillboards[descendant] = descendant.Enabled
                    descendant.Enabled = false
                end
            end

            task.wait(Config.ClaimantArrivalDelay or 0.45)
            if not instance.Parent then return end
            for part, transparency in pairs(savedTransparency) do
                if part.Parent then part.Transparency = transparency end
            end
            for billboard, enabled in pairs(savedBillboards) do
                if billboard.Parent then billboard.Enabled = enabled end
            end
        end)
    end
end)
