local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Constants = ReplicatedStorage.Constants
local IDs = require(Constants.IDs)

local Statistics = script.Parent.Parent.Statistics
local Utilities = script.Parent.Parent.Utilities
local SharedUtilities = ReplicatedStorage.SharedUtilities
local Levels = require(SharedUtilities.Levels)
local CoinXPHandler = require(Statistics.CoinXPHandler)
local ChatTags = require(script.Parent.ChatTags)
local GridSizes = require(Constants:WaitForChild("GridSizes"))
local SaveSlots = require(Constants:WaitForChild("SaveSlots"))

local GetUserCurrency = ReplicatedStorage:WaitForChild("GetUserCurrency")
local SetUserCurrency = ReplicatedStorage:WaitForChild("SetUserCurrency")
local GiftingRemotes = ReplicatedStorage.GiftingRemotes
local AwardGift = GiftingRemotes.AwardGift
local GamepassCheck = ReplicatedStorage.GamepassCheck
local OnPassPurchasedRemote = GamepassCheck.OnPassPurchased

local ServerAnnouncements = ReplicatedStorage.ServerAnnouncements
local AnnounceGiftMessage = ServerAnnouncements.AnnounceMessage

local ProGamepassId = IDs.Gamepasses.Pro

local PurchaseHandler = {}

function PurchaseHandler.IsCoinPurchase(ProductId)
    local CoinDeveloperProducts = IDs.DeveloperProducts.Coins
    for _, Id in pairs(CoinDeveloperProducts) do
        if Id == ProductId then
            return true
        end
    end
    return false
end

function PurchaseHandler.IsGiftedCoinPurchase(ProductId)
    local GiftedCoinDeveloperProducts = IDs.DeveloperProducts.GiftingCoins
    for _, Id in pairs(GiftedCoinDeveloperProducts) do
        if Id == ProductId then
            return true
        end
    end
    return false
end

function PurchaseHandler.IsGridSizeUnlockPurchase(ProductId)
    local InstantGridSizeUnlockIDs = IDs.DeveloperProducts.GridSizeUnlock
    for _, Id in pairs(InstantGridSizeUnlockIDs) do
        if Id == ProductId then
            return true
        end
    end
    return false
end

function PurchaseHandler.IsSaveSlotUnlockPurchase(ProductId)
    local SaveSlotUnlockIDs = IDs.DeveloperProducts.SaveSlotUnlock
    for _, Id in pairs(SaveSlotUnlockIDs) do
        if Id == ProductId then
            return true
        end
    end
    return false
end

function PurchaseHandler.GetDataFromProductId(ModuleContents, ProductId)
    for _, Dictionary in ipairs(ModuleContents) do
        local DictProductId = Dictionary.ProductId
        if DictProductId == ProductId then
            return Dictionary
        end
    end
end

-- Used for typical unlockables with level-based progression & instant-unlocks
function PurchaseHandler.CanPurchaseUnlockable(Player, ProductId, UnlockableData)
    local CurrentXP = GetUserCurrency:Invoke(Player, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    for _, Data in ipairs(UnlockableData) do
        local RequiredLevel = Data.RequiredLevel
        if RequiredLevel > 1 then
            local ProductId = Data.ProductId
            local CurrencyName = Data.CurrencyName
            local HasPurchasedInstantUnlock = GetUserCurrency:Invoke(Player, CurrencyName) == 1
            if CurrentLevel < RequiredLevel and not HasPurchasedInstantUnlock then
                if ProductId == ProductId then
                    return true
                else
                    return false
                end
            end
        end
    end
end

function PurchaseHandler.Init()
    MarketplaceService.ProcessReceipt = function(ReceiptInfo)
        local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
        local ProductId = ReceiptInfo.ProductId
        local PurchaseId = ReceiptInfo.PurchaseId
        local IsCoinPurchase = PurchaseHandler.IsCoinPurchase(ProductId)
        local IsGiftedCoinPurchase = PurchaseHandler.IsGiftedCoinPurchase(ProductId)
        local IsGridSizeUnlockPurchase = PurchaseHandler.IsGridSizeUnlockPurchase(ProductId)
        local IsSaveSlotUnlockPurchase = PurchaseHandler.IsSaveSlotUnlockPurchase(ProductId)

        if IsCoinPurchase then
            CoinXPHandler.OnCoinsPurchased(Player, ProductId)
        elseif IsGiftedCoinPurchase then
            AwardGift:Invoke(Player, ProductId, PurchaseId)
        elseif IsGridSizeUnlockPurchase then
            local CanPurchaseGridSizeUnlock = PurchaseHandler.CanPurchaseUnlockable(Player, ProductId, GridSizes.Constants)
            if CanPurchaseGridSizeUnlock then
                local GridSizeData = PurchaseHandler.GetDataFromProductId(GridSizes.Constants, ProductId)
                local CurrencyName = GridSizeData.CurrencyName
                SetUserCurrency:Invoke(Player, CurrencyName, 1, false)
            end
        elseif IsSaveSlotUnlockPurchase then
            local CanPurchaseSaveSlotUnlock = PurchaseHandler.CanPurchaseUnlockable(Player, ProductId, SaveSlots.RegularSlots)
            if CanPurchaseSaveSlotUnlock then
                local SaveSlotData = PurchaseHandler.GetDataFromProductId(SaveSlots.RegularSlots, ProductId)
                local CurrencyName = SaveSlotData.CurrencyName
                SetUserCurrency:Invoke(Player, CurrencyName, 1, false)
            end
        end
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Player, GamepassId, WasPurchased)
        if WasPurchased then
            if GamepassId == ProGamepassId then
                ChatTags.ApplyTags(Player)
                local PurchaseAnnouncementMessage = "CONGRATS! ".. Player.Name.. " has joined Pro!"
                for _, Player in ipairs(Players:GetPlayers()) do
                    pcall(function()
                        AnnounceGiftMessage:InvokeClient(Player, PurchaseAnnouncementMessage)
                    end)
                end
            end

            OnPassPurchasedRemote:FireClient(Player, GamepassId)
        end
    end)
end

return PurchaseHandler