local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Constants = ReplicatedStorage.Constants
local IDs = require(Constants.IDs)

local GiftingRemotes = ReplicatedStorage.GiftingRemotes
local GetPlayerBeingGifted = GiftingRemotes.GetPlayerBeingGifted
local OnGiftAwarded = GiftingRemotes.OnGiftAwarded
local OnGiftRedeemed = GiftingRemotes.OnGiftRedeemed
local GetGifts = GiftingRemotes.GetGifts
local ServerAnnouncements = ReplicatedStorage.ServerAnnouncements
local AnnounceMessageRemote = ServerAnnouncements.AnnounceMessage
local HideGiftAlert = GiftingRemotes.HideGiftAlert
local OnGiftSentSuccessfully = GiftingRemotes.OnGiftSentSuccessfully
local AwardGift = GiftingRemotes.AwardGift
local SetUserCurrency = ReplicatedStorage:WaitForChild("SetUserCurrency")

local GiftDatastore = DataStoreService:GetDataStore("Gifting")

local MAX_SAVE_ATTEMPTS = 2

local Gifting = {}

--[[

DataStore Index Template

[UserId] = {} -- Empty if no gifts

[UserId] = {
    ["GiftedBy] = UserId
    ["CoinAmount] = 10
    ["PurchaseId] = ... - "A unique identifier for the specific purchase" (API Documentation for ProcessReceipt ReceiptInfo)
}

]]

local ServerGiftContainer = {}

function Gifting.Init()
    GetGifts.OnServerInvoke = function(Player)
        return ServerGiftContainer[Player]
    end

    OnGiftRedeemed.OnServerEvent:Connect(Gifting.RedeemGift)
    AwardGift.OnInvoke = Gifting.OnGiftPurchased
    
    Players.PlayerAdded:Connect(function(Player)
        task.spawn(function()
            ServerGiftContainer[Player] = Gifting.GetReceivedGiftsOfUser(Player.UserId)
        end)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        task.spawn(function()
            local GiftData = ServerGiftContainer[Player]
            for i = 1, MAX_SAVE_ATTEMPTS do
                local Success, Error = pcall(function()
                    GiftDatastore:SetAsync(tostring(Player.UserId), GiftData)
                end)
                if Success then
                    break
                else
                    print("Error saving gift data for: ".. Player.Name.. " '".. tostring(Error).. "'")
                end
            end
            ServerGiftContainer[Player] = nil
        end)
    end)
end

function Gifting.GetReceivedGiftsOfUser(UserId)
    local Data = nil
    local Successful, Error = pcall(function()
        Data = GiftDatastore:GetAsync(tostring(UserId))
    end)
    if Successful then
        if Data == nil then
            return {}
        else
            return Data
        end
    else
        print("Error loading gift data for: ".. tostring(UserId).. " '".. tostring(Error).. "'")
    end
end

function Gifting.AnnounceGiftMessage(PlayerGifting, PlayerReceiving, CoinAmount)
    local Message = PlayerGifting.Name.. " has gifted ".. PlayerReceiving.Name.. " ".. tostring(CoinAmount).. " coins"
    for _, Player in ipairs(Players:GetPlayers()) do
        pcall(function()
            AnnounceMessageRemote:InvokeClient(Player, Message)
        end)
    end
end

function Gifting.AwardGift(PlayerGifting, PlayerReceiving, PurchaseId, CoinAmount)
    local RecievedGiftData = ServerGiftContainer[PlayerReceiving]
    if RecievedGiftData then
        local GiftData = {
            ["GiftedBy"] = PlayerGifting.UserId,
            ["CoinAmount"] = CoinAmount,
            ["PurchaseId"] = PurchaseId
        }
        table.insert(RecievedGiftData, GiftData)
        ServerGiftContainer[PlayerReceiving] = RecievedGiftData
        Gifting.AnnounceGiftMessage(PlayerGifting, PlayerReceiving, CoinAmount)
        OnGiftAwarded:FireClient(PlayerReceiving, GiftData)
        OnGiftSentSuccessfully:FireClient(PlayerGifting)
        SetUserCurrency:Invoke(PlayerGifting, "CoinsGifted", CoinAmount, true)
    end
end

function Gifting.HasPlayerReceivedGift(Player, PurchaseId)
    local RecievedGiftData = ServerGiftContainer[Player]
    for Index, GiftData in ipairs(RecievedGiftData) do
        if GiftData.PurchaseId == PurchaseId then
            return true, Index
        end
    end
    return false
end

function Gifting.RedeemGift(PlayerRedeeming, PurchaseId)
    local HasPlayerReceivedGift, Index = Gifting.HasPlayerReceivedGift(PlayerRedeeming, PurchaseId)
    if HasPlayerReceivedGift then
        local RecievedGiftData = ServerGiftContainer[PlayerRedeeming]
        local CoinAmount = RecievedGiftData[Index]["CoinAmount"]
        SetUserCurrency:Invoke(PlayerRedeeming, "Coins", CoinAmount, true)
        table.remove(RecievedGiftData, Index)
        ServerGiftContainer[PlayerRedeeming] = RecievedGiftData

        local PlayerHasGifts = ServerGiftContainer[PlayerRedeeming][1] ~= nil
        if not PlayerHasGifts then
            HideGiftAlert:InvokeClient(PlayerRedeeming)
        end
    end
end

function Gifting.OnGiftPurchased(PlayerGifting, ProductId, PurchaseId)
    local GiftCoinsDeveloperProducts = IDs.DeveloperProducts.GiftingCoins
    local FiveCoinsId = GiftCoinsDeveloperProducts["5Coins"]
    local FifteenCoinsId = GiftCoinsDeveloperProducts["15Coins"]
    local FortyCoinsId = GiftCoinsDeveloperProducts["40Coins"]
    local PlayerReceiving = GetPlayerBeingGifted:InvokeClient(PlayerGifting)

    if PlayerReceiving then
        if PlayerReceiving ~= PlayerGifting or RunService:IsStudio() then
            if ProductId == FiveCoinsId then
                Gifting.AwardGift(PlayerGifting, PlayerReceiving, PurchaseId, 5)
            elseif ProductId == FifteenCoinsId then
                Gifting.AwardGift(PlayerGifting, PlayerReceiving, PurchaseId, 15)
            elseif ProductId == FortyCoinsId then
                Gifting.AwardGift(PlayerGifting, PlayerReceiving, PurchaseId, 40)
            end
        end
    end
end

return Gifting