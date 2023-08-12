local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local DrawMenu = PlayerGui:WaitForChild("DrawMenu.V3")
local SettingsMenuFrame = DrawMenu:WaitForChild("SettingMenu")
local GridSizeMenu = SettingsMenuFrame:WaitForChild("GridSize")
local CloseButtonFrame = GridSizeMenu:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local ScrollingFrame = GridSizeMenu:WaitForChild("ScrollingFrame")

local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Constants = ReplicatedStorage:WaitForChild("Constants")
local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local Constants = ReplicatedStorage:WaitForChild("Constants")
local Levels = require(SharedUtilities:WaitForChild("Levels"))
local GridSizes = require(Constants:WaitForChild("GridSizes"))
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local IDs = require(Constants:WaitForChild("IDs"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))

local DrawingSettingsBindables = ReplicatedStorage:WaitForChild("DrawingSettingsBindables")
local OnGridSizeChanged = DrawingSettingsBindables:WaitForChild("OnGridSizeChanged")
local GetDrawingSetting = DrawingSettingsBindables:WaitForChild("GetDrawingSetting")
local GamepassCheckRemotes = ReplicatedStorage:WaitForChild("GamepassCheck")
local UserOwnsGamepassRemote = GamepassCheckRemotes:WaitForChild("UserOwnsGamepass")
local OnPassPurchasedRemote = GamepassCheckRemotes:WaitForChild("OnPassPurchased")

local OnCurrencyChangeEvent = ReplicatedStorage:WaitForChild("OnCurrencyChange")
local GetPlayerCurrency = ReplicatedStorage:WaitForChild("GetPlayerCurrency")

local GridSizeMenuSize = GridSizeMenu.Size

local TweenFrames = {
    -- Select and unlock now frames are added at runtime. 
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(20, CloseButtonFrame)
    }
}

local GridSizeMenuController = {}

function GridSizeMenuController.Init()
    for _, GridSizeFrame in ipairs(ScrollingFrame:GetChildren()) do
        if GridSizeFrame:IsA("Frame") then
            local LockedOverlay = GridSizeFrame:FindFirstChild("LockedOverlay")
            if LockedOverlay then
                local UnlockNowFrame = LockedOverlay:WaitForChild("UnlockNow")
                local UnlockNowButton = UnlockNowFrame:WaitForChild("Button")
                UnlockNowButton.Activated:Connect(function()
                    for _, GridSizeData in ipairs(GridSizes.Constants) do
                        local FrameName = GridSizeData.FrameName
                        local ProductId = GridSizeData.ProductId
                        if FrameName == GridSizeFrame.Name then
                            MarketplaceService:PromptProductPurchase(LocalPlayer, ProductId)
                        end
                    end
                end)
            end

            local ActionButtonFrame = GridSizeFrame:WaitForChild("ActionButton")
            local ActionButton = ActionButtonFrame:WaitForChild("Button")
            local GridData = GridSizeMenuController.GetGridDataFromFrameName(GridSizeFrame.Name)
            local GridRowCount = GridData.RowCount
            local GridColumnCount = GridData.ColumnCount
            ActionButton.Activated:Connect(function()
                local CurrentGridSize = GetDrawingSetting:Invoke("GridSize")
                local CurrentGridRowCount = CurrentGridSize.RowCount
                local CurrentGridColumnCount = CurrentGridSize.ColumnCount
                
                for _, GridSizeData in ipairs(GridSizes.Constants) do
                    local RowCount = GridSizeData.RowCount
                    local ColumnCount = GridSizeData.ColumnCount
                    local FrameName = GridSizeData.FrameName
                    local IsSelectedGridSizeFrame = CurrentGridRowCount == RowCount and CurrentGridColumnCount == ColumnCount
                    if IsSelectedGridSizeFrame then
                        local Frame = ScrollingFrame:WaitForChild(FrameName)
                        GridSizeMenuController.DeselectGridSize(Frame)
                    end
                end

                GridSizeMenuController.SelectGridSize(GridSizeFrame)
                OnGridSizeChanged:Fire(GridRowCount, GridColumnCount)
            end)
        end
    end

    for _, GridSizeData in ipairs(GridSizes.Constants) do
        local FrameName = GridSizeData.FrameName
        local GridSizeFrame = ScrollingFrame:WaitForChild(FrameName)
        local SelectButtonFrame = GridSizeFrame:WaitForChild("ActionButton")
        local SelectButton = SelectButtonFrame:WaitForChild("Button")
        local LockedOverlay = GridSizeFrame:FindFirstChild("LockedOverlay")

        if LockedOverlay then
            local UnlockNowButtonFrame = LockedOverlay:WaitForChild("UnlockNow")
            local UnlockNowButton = UnlockNowButtonFrame:WaitForChild("Button")
            local UnlockNowButtonTweenData = {
                ["Frame"] = UnlockNowButtonFrame,
                ["Button"] = UnlockNowButton,
                ["RegularFrameSize"] = UnlockNowButtonFrame.Size,
                ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, UnlockNowButtonFrame)
            }
            table.insert(TweenFrames, UnlockNowButtonTweenData)
        end

        local SelectButtonTweenData = {
            ["Frame"] = SelectButtonFrame,
            ["Button"] = SelectButton,
            ["RegularFrameSize"] = SelectButtonFrame.Size,
            ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(6, SelectButtonFrame)
        }

        table.insert(TweenFrames, SelectButtonTweenData)
    end

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
    
    GridSizeMenuController.UpdateLockedOverlays()
    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName, NewCurrencyAmount)
        if CurrencyName == "XP" then
            GridSizeMenuController.UpdateLockedOverlays()
        end
        for _, GridSizeData in ipairs(GridSizes.Constants) do
            local GridSizeCurrencyName = GridSizeData.CurrencyName
            local HasPurchased = NewCurrencyAmount == 1
            if CurrencyName == GridSizeCurrencyName and HasPurchased then
                GridSizeMenuController.UpdateLockedOverlays()
            end
        end
    end)
    CloseButton.Activated:Connect(GridSizeMenuController.ReturnToSettingsMenu)
end

function GridSizeMenuController.UpdateLockedOverlays()
    local CurrentXP = GetPlayerCurrency:InvokeServer(LocalPlayer, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    
    for _, GridSizeData in ipairs(GridSizes.Constants) do
        local FrameName = GridSizeData.FrameName
        local RequiredLevel = GridSizeData.RequiredLevel
        local Frame = ScrollingFrame:FindFirstChild(FrameName)
        local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
        local CurrencyName = GridSizeData.CurrencyName
        if Frame and LockedOverlay then
            local HasPurchasedInstantUnlock = GetPlayerCurrency:InvokeServer(LocalPlayer, CurrencyName) == 1
            if CurrentLevel >= RequiredLevel or HasPurchasedInstantUnlock then
                for Index, FrameTweenData in ipairs(TweenFrames) do
                    local TweenFrame = FrameTweenData.Frame
                    if TweenFrame == Frame then
                        table.remove(TweenFrames, Index)
                    end
                end
                LockedOverlay:Destroy()
            else
                local UnlockNowFrame = LockedOverlay:WaitForChild("UnlockNow")
                local UnlockNowButton = UnlockNowFrame:WaitForChild("Button")
                local ProgressBarFrame = LockedOverlay:WaitForChild("ProgressBar")
                local FillBarFrame = ProgressBarFrame:WaitForChild("Fill")
                local ProgressPercentageText = ProgressBarFrame:WaitForChild("PercentageText")
                local XPRequiredToUnlockSize = Levels.GetXPFromLevel(RequiredLevel)
                local PercentageTowardRequiredLevel = math.floor((CurrentXP / XPRequiredToUnlockSize) * 100)

                FillBarFrame.Size = UDim2.fromScale(PercentageTowardRequiredLevel / 100, FillBarFrame.Size.Y.Scale)
                ProgressPercentageText.Text = tostring(PercentageTowardRequiredLevel).. "%"
            end
        end
    end

    for _, GridSizeData in ipairs(GridSizes.Constants) do
        local RequiredLevel = GridSizeData.RequiredLevel
        if RequiredLevel > 1 then
            local ProductId = GridSizeData.ProductId
            local CurrencyName = GridSizeData.CurrencyName
            local FrameName = GridSizeData.FrameName
            local HasPurchasedInstantUnlock = GetPlayerCurrency:InvokeServer(LocalPlayer, CurrencyName) == 1
            if CurrentLevel < RequiredLevel and not HasPurchasedInstantUnlock then
                local FrameToUnlock = ScrollingFrame:WaitForChild(FrameName)
                GridSizeMenuController.UnlockGridSizeFrame(FrameToUnlock)
                break
            end
        end
    end
end

function GridSizeMenuController.SelectGridSize(Frame)
    local ActionButtonFrame = Frame:WaitForChild("ActionButton")
    local TextLabel = ActionButtonFrame:WaitForChild("TextLabel")
    local UIGradient = ActionButtonFrame:WaitForChild("UIGradient")
    local SelectedText = "SELECTED"
    local SelectedTextTransparency = 0.5
    local SelectedGradientTransparency = 0.5

    TextLabel.Text = SelectedText
    TextLabel.TextTransparency = SelectedTextTransparency
    UIGradient.Transparency = NumberSequence.new(SelectedGradientTransparency)
end

function GridSizeMenuController.DeselectGridSize(Frame)
    local ActionButtonFrame = Frame:WaitForChild("ActionButton")
    local TextLabel = ActionButtonFrame:WaitForChild("TextLabel")
    local UIGradient = ActionButtonFrame:WaitForChild("UIGradient")
    local DefaultText = "SELECT"
    local DefaultTextTransparency = 0
    local DefaultGradientTransparency = 0

    TextLabel.Text = DefaultText
    TextLabel.TextTransparency = DefaultTextTransparency
    UIGradient.Transparency = NumberSequence.new(DefaultGradientTransparency)
end

function GridSizeMenuController.GetGridDataFromFrameName(Name)
    for _, GridSizeData in ipairs(GridSizes.Constants) do
        local FrameName = GridSizeData.FrameName
        if FrameName == Name then
           return GridSizeData 
        end
    end
end

function GridSizeMenuController.UnlockGridSizeFrame(Frame)
    local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
    if LockedOverlay then
        local UnlockNowFrame = LockedOverlay:WaitForChild("UnlockNow")
        local OrText = LockedOverlay:WaitForChild("ORText")
        local OverlayButtonFrame = LockedOverlay:WaitForChild("OverlayButton")
        OrText.Visible = true
        UnlockNowFrame.Visible = true
        OverlayButtonFrame.Visible = false 
    end
end

function GridSizeMenuController.ResetButtonSizes()
    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
end

function GridSizeMenuController.OpenMenu()
    InterfaceSound.PlaySound("OpenUI")
    GridSizeMenu.Size = UDim2.fromScale(0, 0)
    GridSizeMenu.Visible = true
    UIUtility.Tween(GridSizeMenu, 0.1, {Size = GridSizeMenuSize})
end

function GridSizeMenuController.ReturnToSettingsMenu()
    local DrawingSettingsController = require(script.Parent:WaitForChild("DrawingSettingsController"))
    UIUtility.Tween(GridSizeMenu, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    GridSizeMenu.Visible = false
    GridSizeMenuController.ResetButtonSizes()
    DrawingSettingsController.OpenMenu()
end

function GridSizeMenuController.IsMenuOpen()
    return GridSizeMenu.Visible
end

return GridSizeMenuController