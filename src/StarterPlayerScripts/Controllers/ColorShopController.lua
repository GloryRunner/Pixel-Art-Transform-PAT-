local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ColorShop = PlayerGui:WaitForChild("ColourShop.V2")
local ColorShopMenuFrame = ColorShop:WaitForChild("Frame")
local ScrollingFrame = ColorShopMenuFrame:WaitForChild("Colours"):WaitForChild("ScrollingFrame")
local Hud = PlayerGui:WaitForChild("HUD.V1")
local ShopButtonFrame = Hud:WaitForChild("Frame"):WaitForChild("ShopButton")
local ShopButton = ShopButtonFrame:WaitForChild("Button")
local CloseButtonFrame = ColorShopMenuFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")

local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))
local DrawingSettingsController = require(script.Parent:WaitForChild("DrawingSettingsController"))

local TweenFrames = {
    {
        ["Frame"] = ShopButtonFrame,
        ["Button"] = ShopButton,
        ["RegularFrameSize"] = ShopButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(10, ShopButtonFrame)
    },
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(20, CloseButtonFrame)
    }
}

local RegularMenuSize = ColorShopMenuFrame.Size
local RegularColorFrameSize = ScrollingFrame:WaitForChild("Slot2"):WaitForChild("ScrollingFrame"):WaitForChild("1.Coin").Size
local RegularBuyAllFrameSize = ScrollingFrame:WaitForChild("Slot2"):WaitForChild("BuyAll").Size

local ColorShopController = {}

function ColorShopController.Init()
    ShopButton.Activated:Connect(function()
        local IsMenuOpen = ColorShopController.IsMenuOpen()
        local IsDrawingSettingsMenuOpen = DrawingSettingsController.IsMenuOpen()
        if not IsDrawingSettingsMenuOpen then
            if IsMenuOpen then
                ColorShopController.CloseMenu()
            else
                ColorShopController.OpenMenu()
            end
        end
    end)

    CloseButton.Activated:Connect(ColorShopController.CloseMenu)

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
    
    for _, SlotFrame in ipairs(ScrollingFrame:GetChildren()) do
        if SlotFrame:IsA("Frame") then
            local SlotScrollingFrame = SlotFrame:WaitForChild("ScrollingFrame")
            local BuyAllFrame = SlotFrame:FindFirstChild("BuyAll")
            if BuyAllFrame then
                local EnlargedBuyAllFrameSize = UIUtility.CalculateSizePercentage(6, BuyAllFrame)
                local BuyAllButton = BuyAllFrame:FindFirstChild("Button")
                if BuyAllButton then
                    BuyAllButton.MouseEnter:Connect(function()
                        UIUtility.Tween(BuyAllFrame, 0.05, {Size = EnlargedBuyAllFrameSize})   
                    end)
                    BuyAllButton.MouseLeave:Connect(function()
                        UIUtility.Tween(BuyAllFrame, 0.05, {Size = RegularBuyAllFrameSize})  
                    end)
                end
            end
            for _, ColorFrame in ipairs(SlotScrollingFrame:GetChildren()) do
                if ColorFrame:IsA("Frame") then
                    local Button = ColorFrame:WaitForChild("Button")
                    local EnlargedColorFrameSize = UIUtility.CalculateSizePercentage(6, ColorFrame)
                    Button.MouseEnter:Connect(function()
                        UIUtility.Tween(ColorFrame, 0.05, {Size = EnlargedColorFrameSize})                
                    end)
                    Button.MouseLeave:Connect(function()
                        UIUtility.Tween(ColorFrame, 0.05, {Size = RegularColorFrameSize})  
                    end)
                end
            end
        end
    end
end

function ColorShopController.ResetButtonSizes()
    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
    for _, SlotFrame in ipairs(ScrollingFrame:GetChildren()) do
        if SlotFrame:IsA("Frame") then
            local SlotScrollingFrame = SlotFrame:WaitForChild("ScrollingFrame")
            local BuyAllFrame = SlotFrame:FindFirstChild("BuyAll")
            if BuyAllFrame then
                BuyAllFrame.Size = RegularBuyAllFrameSize
            end
            for _, ColorFrame in ipairs(SlotScrollingFrame:GetChildren()) do
                if ColorFrame:IsA("Frame") then
                    ColorFrame.Size = RegularColorFrameSize
                end
            end
        end
    end
end

function ColorShopController.IsMenuOpen()
    return ColorShop.Enabled
end

function ColorShopController.OpenMenu()
    task.spawn(UIUtility.CloseAllUI, "ColorShopController")
    InterfaceSound.PlaySound("OpenUI")
    ColorShopMenuFrame.Size = UDim2.fromScale(0 , 0)
    ColorShop.Enabled = true
    UIUtility.Tween(ColorShopMenuFrame, 0.1, {Size = RegularMenuSize})
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

function ColorShopController.CloseMenu(FullClose)
    if FullClose == nil then
        FullClose = true
    end
    if FullClose then
        InterfaceSound.PlaySound("CloseUI")
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)
    end
    ColorShopController.ResetButtonSizes()
    UIUtility.Tween(ColorShopMenuFrame, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    ColorShop.Enabled = false
end

return ColorShopController