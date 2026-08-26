local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local remotes = ReplicatedStorage:WaitForChild("LostAndFoundRemotes")
local caseUpdate = remotes:WaitForChild("CaseUpdate")

local SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"

local function ping(speed, volume)
    local sound = Instance.new("Sound")
    sound.Name = "LostFoundFeedback"
    sound.SoundId = SOUND_ID
    sound.Volume = volume or 0.16
    sound.PlaybackSpeed = speed or 1
    sound.Parent = SoundService
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    sound:Play()
    task.delay(3, function()
        if sound.Parent then sound:Destroy() end
    end)
end

caseUpdate.OnClientEvent:Connect(function(kind, payload)
    payload = payload or {}

    if kind == "CASE_INCOMING" then
        ping(0.72, 0.10)
    elseif kind == "CASE_READY" then
        ping(0.90, 0.12)
    elseif kind == "INSPECTION" then
        if payload.step == "SCAN" then
            ping(1.00, 0.16)
        elseif payload.step == "TAG" then
            ping(1.14, 0.15)
        elseif payload.step == "OPEN" then
            ping(0.84, 0.14)
        else
            ping(1.00, 0.12)
        end
    elseif kind == "DECISION_BLOCKED" then
        ping(0.62, 0.13)
    elseif kind == "RESULT" then
        if payload.grade == "PERFECT" then
            ping(1.38, 0.20)
        elseif payload.grade == "QUESTIONABLE" then
            ping(0.94, 0.16)
        elseif payload.grade == "CATASTROPHIC" then
            ping(0.50, 0.20)
        elseif payload.grade == "WRONG" then
            ping(0.64, 0.18)
        else
            ping(1.12, 0.17)
        end
    end
end)
