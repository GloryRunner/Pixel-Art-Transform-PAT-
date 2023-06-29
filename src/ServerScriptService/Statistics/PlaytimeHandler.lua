local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SetUserCurrency = ReplicatedStorage:WaitForChild("SetUserCurrency")

local CountdownLength = 60

local ActiveThreads = {}

local PlaytimeHandler = {}

function PlaytimeHandler.Init()
    Players.PlayerAdded:Connect(function(Player)
        local Thread = nil
        Thread = task.spawn(function()
            while task.wait(CountdownLength) do
                SetUserCurrency:Invoke(Player, "Playtime", 1, true)
            end
        end)
        ActiveThreads[Player] = Thread
    end)

    Players.PlayerRemoving:Connect(function(Player)
        local Thread = ActiveThreads[Player]
        if Thread then
            coroutine.close(Thread)
        end
        ActiveThreads[Player] = nil
    end)
end

return PlaytimeHandler