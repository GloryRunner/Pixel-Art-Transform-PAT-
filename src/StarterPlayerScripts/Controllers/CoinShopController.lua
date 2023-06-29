local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoinShopMenu = PlayerGui:WaitForChild("CoinShopV1")
local CoinShopMenuFrame = CoinShopMenu:WaitForChild("Menu")
local Hud = PlayerGui:WaitForChild("HUD.V1")
local CoinFrame = Hud:WaitForChild("Frame"):WaitForChild("CoinFrame")
local PlusButton = CoinFrame:WaitForChild("PlusButton"):WaitForChild("Button")
local PlusButtonFrame = CoinFrame:WaitForChild("PlusButton")
local CloseButtonFrame = CoinShopMenuFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local CoinCounterText = CoinFrame:WaitForChild("Counter")
local ScrollingFrame = CoinShopMenuFrame:WaitForChild("MainFrame"):WaitForChild("ScrollingFrame")

local OnCurrencyChangeEvent = ReplicatedStorage:WaitForChild("OnCurrencyChange")
local GetPlayerCurrencyRemote = ReplicatedStorage:WaitForChild("GetPlayerCurrency")

local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local Constants = ReplicatedStorage.Constants
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))
local IDs = require(Constants.IDs)
local DrawingSettingsController = require(script.Parent:WaitForChild("DrawingSettingsController"))
local CoinDeveloperProducts = IDs.DeveloperProducts.Coins

local TweenFrames = {
    {
        ["Frame"] = PlusButtonFrame,
        ["Button"] = PlusButton,
        ["RegularFrameSize"] = PlusButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(7, PlusButtonFrame)
    },
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(20, CloseButtonFrame) 
    }
}

local RegularMenuSize = CoinShopMenuFrame.Size
local RegularPurchaseFrameSize = ScrollingFrame:WaitForChild("1.5Coins"):WaitForChild("PurchaseFrame").Size

local CoinShopController = {}

function CoinShopController.Init()
    local CoinAmountOnJoin = GetPlayerCurrencyRemote:InvokeServer(LocalPlayer, "Coins")
    CoinCounterText.Text = tostring(math.floor(CoinAmountOnJoin))

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
            local PurchaseFrame = CoinFrame:WaitForChild("PurchaseFrame")
            local Button = PurchaseFrame:WaitForChild("Button")
            local EnlargedPurchaseFrameSize = UIUtility.CalculateSizePercentage(10, PurchaseFrame)
            Button.MouseEnter:Connect(function()
                UIUtility.Tween(PurchaseFrame, 0.05, {Size = EnlargedPurchaseFrameSize})
            end)
            Button.MouseLeave:Connect(function()
                UIUtility.Tween(PurchaseFrame, 0.05, {Size = RegularPurchaseFrameSize})
            end)
            Button.Activated:Connect(function()
                if CoinFrame.Name == "1.5Coins" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, CoinDeveloperProducts["5Coins"])
                elseif CoinFrame.Name == "2.15Coins" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, CoinDeveloperProducts["15Coins"])
                elseif CoinFrame.Name == "3.40Coins" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, CoinDeveloperProducts["40Coins"])
                elseif CoinFrame.Name == "4.100Coins" then
                    MarketplaceService:PromptProductPurchase(LocalPlayer, CoinDeveloperProducts["100Coins"])
                end
            end)
        end
    end

    PlusButton.Activated:Connect(function()
        local IsMenuOpen = CoinShopController.IsMenuOpen()
        local IsDrawingSettingsMenuOpen = DrawingSettingsController.IsMenuOpen()
        if not IsDrawingSettingsMenuOpen then
            if IsMenuOpen then
                CoinShopController.CloseMenu()
            else
                CoinShopController.OpenMenu()
            end
        end
    end)

    CloseButton.Activated:Connect(CoinShopController.CloseMenu)

    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName, NewCurrencyAmount)
        if CurrencyName == "Coins" then
            CoinCounterText.Text = tostring(math.floor(NewCurrencyAmount))
        end
    end)
end

function CoinShopController.ResetButtonSizes()
    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
    for _, CoinFrame in ipairs(ScrollingFrame:GetChildren()) do
        if CoinFrame:IsA("Frame") then
            local PurchaseFrame = CoinFrame:WaitForChild("PurchaseFrame")
            PurchaseFrame.Size = RegularPurchaseFrameSize
        end
    end
end

function CoinShopController.IsMenuOpen()
    return CoinShopMenu.Enabled
end

function CoinShopController.OpenMenu()
    task.spawn(UIUtility.CloseAllUI, "CoinShopController")
    InterfaceSound.PlaySound("OpenUI")
    CoinShopMenuFrame.Size = UDim2.fromScale(0 , 0)
    CoinShopMenu.Enabled = true
    UIUtility.Tween(CoinShopMenuFrame, 0.1, {Size = RegularMenuSize})
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

function CoinShopController.CloseMenu(FullClose)
    if FullClose == nil then
        FullClose = true
    end

    if FullClose then
        InterfaceSound.PlaySound("CloseUI")
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)
    end
    CoinShopController.ResetButtonSizes()
    UIUtility.Tween(CoinShopMenuFrame, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    CoinShopMenu.Enabled = false 
end

return CoinShopController