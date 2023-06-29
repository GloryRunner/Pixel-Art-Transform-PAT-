--[[
+5xp and +1 coin every 3-4 minutes (randomly given at a point between 180-240s)

Pro members get 25% more XP

+25% robux purchase xp (e.g. 40 robux → +10xp)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Constants = ReplicatedStorage.Constants
local IDs = require(Constants.IDs)

local SetUserCurrency = ReplicatedStorage:WaitForChild("SetUserCurrency")
local OnCurrencyInterval = ReplicatedStorage.PopupEvents.OnCurrencyInterval

local CountdownIntervalMin = 180
local CountdownIntervalMax = 240

local CoinAmountPerInterval = 1
local XPAmountPerInterval = 5
local ProXPMultiplier = 25
local GroupMemberCoinMultiplier = 100

local CountdownThreads = {}

local CoinXPHandler = {}

function CoinXPHandler.Init()
    Players.PlayerAdded:Connect(function(Player)
        local Thread = nil
        Thread = task.spawn(function()
            local Rand = Random.new(os.clock())
            while true do
                local TimeUntilCoinsGiven = Rand:NextInteger(CountdownIntervalMin, CountdownIntervalMax)
                task.wait(TimeUntilCoinsGiven)
                CoinXPHandler.AwardCoins(Player, CoinAmountPerInterval)
                CoinXPHandler.AwardXP(Player, XPAmountPerInterval)

                local CoinAmountGiven = CoinXPHandler.CalculateCoinAmount(Player, CoinAmountPerInterval)
                local XPAmountGiven = CoinXPHandler.CalculateXPAmount(Player, XPAmountPerInterval)
                OnCurrencyInterval:FireClient(Player, CoinAmountGiven, XPAmountGiven)
            end
        end)
        CountdownThreads[Player] = Thread
    end)

    Players.PlayerRemoving:Connect(function(Player)
        local Thread = CountdownThreads[Player]
        if Thread then
            coroutine.close(Thread)
        end
    end)
end

function CoinXPHandler.CalculateCoinAmount(Player, CoinAmount)
    local GroupId = IDs["7Wapy"]
    local IsGroupMember = Player:IsInGroup(GroupId)
    if IsGroupMember then
        return (GroupMemberCoinMultiplier / 100 * CoinAmount) + CoinAmount
    else
        return CoinAmount
    end
end

function CoinXPHandler.CalculateXPAmount(Player, XPAmount)
    local ProGamepassId = IDs.Gamepasses.Pro
    local OwnsProPass = false
    local Sucess, Error = pcall(function()
        OwnsProPass = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, ProGamepassId)
    end)

    if Sucess then
        if OwnsProPass then
            return (ProXPMultiplier / 100 * XPAmount) + XPAmount
        else
            return XPAmount
        end
    else
        print("Error getting userownsgamepass for: ".. tostring(Player.UserId).. " when calculating XP.")
    end
end

function CoinXPHandler.AwardCoins(Player, CoinAmount)
    local AmountToGive = CoinXPHandler.CalculateCoinAmount(Player, CoinAmount)
    SetUserCurrency:Invoke(Player, "Coins", AmountToGive, true)
end

function CoinXPHandler.AwardXP(Player, XPAmount)
    local AmountToGive = CoinXPHandler.CalculateXPAmount(Player, XPAmount)
    SetUserCurrency:Invoke(Player, "XP", AmountToGive, true)
end

function CoinXPHandler.OnCoinsPurchased(Player, ProductId)
    local CoinDeveloperProducts = IDs.DeveloperProducts.Coins
    local FiveCoins = CoinDeveloperProducts["5Coins"]
    local FifteenCoins = CoinDeveloperProducts["15Coins"]
    local FortyCoins = CoinDeveloperProducts["40Coins"]
    local OneHundredCoins = CoinDeveloperProducts["100Coins"]
    
    if ProductId == FiveCoins then
        CoinXPHandler.AwardCoins(Player, 5)
    elseif ProductId == FifteenCoins then
        CoinXPHandler.AwardCoins(Player, 15)
    elseif ProductId == FortyCoins then
        CoinXPHandler.AwardCoins(Player, 40)
    elseif ProductId == OneHundredCoins then
        CoinXPHandler.AwardCoins(Player, 100)
    end
end

return CoinXPHandler