local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GiftingMenu = PlayerGui:WaitForChild("GiftingMenu")
local GiftingMenuFrame = GiftingMenu:WaitForChild("GiftingMenu")
local BonusRewardFrame = GiftingMenuFrame:WaitForChild("BonusReward")
local BonusProgressLabel = BonusRewardFrame:WaitForChild("ProgressTxt")
local MainFrame = GiftingMenuFrame:WaitForChild("MainFrame")
local CoinText = MainFrame:WaitForChild("CoinTxt")
local LevelText = MainFrame:WaitForChild("LevelTxt")
local UsernameTxt = MainFrame:WaitForChild("UserTxt")
local XPText = MainFrame:WaitForChild("XpTxt")
local CloseButtonFrame = GiftingMenuFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local ScrollingFrame = MainFrame:WaitForChild("ScrollingFrame")

local RegularGiftingMenuFrameSize = GiftingMenuFrame.Size

local GetPlayerCurrencyRemote = ReplicatedStorage:WaitForChild("GetPlayerCurrency")
local OnCurrencyChangeEvent = ReplicatedStorage:WaitForChild("OnCurrencyChange")
local GiftingRemotes = ReplicatedStorage:WaitForChild("GiftingRemotes")
local GetPlayerBeingGifted = GiftingRemotes:WaitForChild("GetPlayerBeingGifted")

local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Levels = require(SharedUtilities:WaitForChild("Levels"))
local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))
local Constants = ReplicatedStorage:WaitForChild("Constants")
local IDs = require(Constants:WaitForChild("IDs"))

local TweenFrames = {
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(20, CloseButtonFrame)
    }
}

local GiftingController = {}

function GiftingController.Init()
    local CoinsGifted = GetPlayerCurrencyRemote:InvokeServer(LocalPlayer, "CoinsGifted")
    if CoinsGifted > 100 then
        BonusRewardFrame:Destroy()
    else
        BonusProgressLabel.Text = tostring(CoinsGifted).. "/100"
    end

    GetPlayerBeingGifted.OnClientInvoke = GiftingController.GetPlayerBeingGifted

    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local Button = FrameData.Button
        local RegularFrameSize = FrameData.RegularFrameSize
        local EnlargedFrameSize = FrameData.EnlargedFrameSize
        Button.MouseEnter:Connect(function()
            UIUtility.Tween(Frame, 0.05, {Size = EnlargedFrameSize})
        end)
        Button.MouseLeave:Connect(function()
            UIUtility.Tween(Frame, 0.05, {Size = RegularFrameSize})
        end)
    end

    for _, CoinFrame in ipairs(ScrollingFrame:GetChildren()) do
        if CoinFrame:IsA("Frame") then
            local GiftButtonFrame = CoinFrame:WaitForChild("GiftButton")
            local GiftButton = GiftButtonFrame:WaitForChild("Button")
            local EnlargedGiftFrameSize = UIUtility.CalculateSizePercentage(10, GiftButtonFrame)
            local RegularGiftFrameSize = GiftButtonFrame.Size
            local GiftCoinsDeveloperProducts = IDs.DeveloperProducts.GiftingCoins

            GiftButton.MouseEnter:Connect(function()
                UIUtility.Tween(GiftButtonFrame, 0.05, {Size = EnlargedGiftFrameSize})
            end)
            GiftButton.MouseLeave:Connect(function()
                UIUtility.Tween(GiftButtonFrame, 0.05, {Size = RegularGiftFrameSize})
            end)

            GiftButton.Activated:Connect(function()
                if CoinFrame.Name == "1.5Coins" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, GiftCoinsDeveloperProducts["5Coins"])
                elseif CoinFrame.Name == "2.15Coins" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, GiftCoinsDeveloperProducts["15Coins"])
                elseif CoinFrame.Name == "3.40Coins" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, GiftCoinsDeveloperProducts["40Coins"])
                end
            end)
        end
    end

    CloseButton.Activated:Connect(GiftingController.CloseMenu)

    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName, NewCurrencyAmount)
        if CurrencyName == "CoinsGifted" then
            if NewCurrencyAmount < 100 then
                BonusProgressLabel.Text = tostring(NewCurrencyAmount).. "/100"
            elseif BonusRewardFrame then
                BonusRewardFrame:Destroy()
            end
        end
    end)
end

function GiftingController.DisplayPlayer(Player)
    local Username = Player.Name
    local CoinCount = math.floor(GetPlayerCurrencyRemote:InvokeServer(Player, "Coins"))
    local CurrentXP = GetPlayerCurrencyRemote:InvokeServer(Player, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    local XPNeededForNextLevel = Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), math.floor(CurrentLevel) + 1)
    local XPTowardNextLevel = Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), CurrentLevel)

    UsernameTxt.Text = "To: @".. Username
    CoinText.Text = tostring(CoinCount)
    LevelText.Text = "Level ".. tostring(math.floor(CurrentLevel))
    XPText.Text = tostring(math.floor(XPTowardNextLevel)).. "/".. tostring(XPNeededForNextLevel)
end

function GiftingController.ResetButtonSizes()
    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
end

function GiftingController.GetPlayerBeingGifted()
    local Length = string.len(UsernameTxt.Text)
    local Username = string.sub(UsernameTxt.Text, 6, Length)
    local Player = Players:FindFirstChild(Username)
    return Player
end

function GiftingController.OpenMenu()
    task.spawn(UIUtility.CloseAllUI, "GiftingController")
    GiftingMenuFrame.Size = UDim2.fromScale(0, 0)
    GiftingMenu.Enabled = true
    UIUtility.Tween(GiftingMenuFrame, 0.1, {Size = RegularGiftingMenuFrameSize})
    InterfaceSound.PlaySound("OpenUI")
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

function GiftingController.CloseMenu(FullClose)
    if FullClose == nil then
        FullClose = true
    end
    if FullClose then
        InterfaceSound.PlaySound("CloseUI")
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)
    end
    GiftingController.ResetButtonSizes()
    UIUtility.Tween(GiftingMenuFrame, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    GiftingMenu.Enabled = false
end

function GiftingController.IsMenuOpen()
    return GiftingMenu.Enabled
end

return GiftingController