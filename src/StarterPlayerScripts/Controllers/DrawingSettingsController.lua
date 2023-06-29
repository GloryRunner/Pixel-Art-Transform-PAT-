local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local DrawMenu = PlayerGui:WaitForChild("DrawMenu.V3")
local SettingsMenuFrame = DrawMenu:WaitForChild("SettingMenu")
local Main = SettingsMenuFrame:WaitForChild("Main")
local CloseButtonFrame = Main:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local MainFrame = Main:WaitForChild("MainFrame")
local DragToDrawFrame = MainFrame:WaitForChild("1.DragDraw")
local EnableDragToDrawFrame = DragToDrawFrame:WaitForChild("Enable")
local EnableDragToDrawButton = EnableDragToDrawFrame:WaitForChild("Button")
local DisableDragToDrawFrame = DragToDrawFrame:WaitForChild("Disable")
local DisableDragToDrawButton = DisableDragToDrawFrame:WaitForChild("Button")
local BrushSizesFrame = MainFrame:WaitForChild("3.BrushSizes")
local BrushSizeLockedOverlay = BrushSizesFrame:WaitForChild("LockedOverlay")
local UnlockNowFrame = BrushSizeLockedOverlay:WaitForChild("UnlockNow")
local UnlockNowButton = UnlockNowFrame:WaitForChild("Button")
local ProgressBarFrame = BrushSizeLockedOverlay:WaitForChild("ProgressBar")
local FillBarFrame = ProgressBarFrame:WaitForChild("Fill")
local ProgressPercentageText = ProgressBarFrame:WaitForChild("PercentageText")
local BrushSizeMinusButtonFrame = BrushSizesFrame:WaitForChild("MinusButton")
local BrushSizeMinusButton = BrushSizeMinusButtonFrame:WaitForChild("Button")
local BrushSizePlusButtonFrame = BrushSizesFrame:WaitForChild("PlusButton")
local BrushSizePlusButton = BrushSizePlusButtonFrame:WaitForChild("Button")
local BrushSizeText = BrushSizesFrame:WaitForChild("BrushSize")
local GridSizeFrame = MainFrame:WaitForChild("2.GridSize")
local SelectGridSizeFrame = GridSizeFrame:WaitForChild("SelectSize")
local SelectGridSizeButton = SelectGridSizeFrame:WaitForChild("Button")

local RegularMainFrameSize = Main.Size

local DrawingSettingsBindables = ReplicatedStorage:WaitForChild("DrawingSettingsBindables")
local OnGridSizeChanged = DrawingSettingsBindables:WaitForChild("OnGridSizeChanged")
local OnBrushSizeChanged = DrawingSettingsBindables:WaitForChild("OnBrushSizeChanged")
local OnDragToDrawStateChanged = DrawingSettingsBindables:WaitForChild("OnDragToDrawStateChanged")
local GetDrawingSetting = DrawingSettingsBindables:WaitForChild("GetDrawingSetting")

local OnCurrencyChangeEvent = ReplicatedStorage:WaitForChild("OnCurrencyChange")
local GetPlayerCurrency = ReplicatedStorage:WaitForChild("GetPlayerCurrency")
local GamepassCheck = ReplicatedStorage:WaitForChild("GamepassCheck")
local UserOwnsGamepassRemote = GamepassCheck:WaitForChild("UserOwnsGamepass")
local OnPassPurchasedRemote = GamepassCheck:WaitForChild("OnPassPurchased")

local Constants = ReplicatedStorage:WaitForChild("Constants")
local IDs = require(Constants:WaitForChild("IDs"))
local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Levels = require(SharedUtilities:WaitForChild("Levels"))
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))

local TweenFrames = {
    {
        ["Frame"] = EnableDragToDrawFrame,
        ["Button"] = EnableDragToDrawButton,
        ["RegularFrameSize"] = EnableDragToDrawFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, EnableDragToDrawFrame)
    },
    {
        ["Frame"] = DisableDragToDrawFrame,
        ["Button"] = DisableDragToDrawButton,
        ["RegularFrameSize"] = DisableDragToDrawFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, DisableDragToDrawFrame)
    },
    {
        ["Frame"] = UnlockNowFrame,
        ["Button"] = UnlockNowButton,
        ["RegularFrameSize"] = UnlockNowFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(10, UnlockNowFrame)
    },
    {
        ["Frame"] = BrushSizePlusButtonFrame,
        ["Button"] = BrushSizePlusButton,
        ["RegularFrameSize"] = BrushSizePlusButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(10, BrushSizePlusButtonFrame)
    },
    {
        ["Frame"] = BrushSizeMinusButtonFrame,
        ["Button"] = BrushSizeMinusButton,
        ["RegularFrameSize"] = BrushSizeMinusButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(10, BrushSizeMinusButtonFrame)
    },
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(15, CloseButtonFrame)
    },
    {
        ["Frame"] = SelectGridSizeFrame,
        ["Button"] = SelectGridSizeButton,
        ["RegularFrameSize"] = SelectGridSizeFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(7, SelectGridSizeFrame)
    }
}

local DisabledTransparency = 0.6
local EnabledTransparency = 0

local LevelRequiredForBrushSizes = 10

local BrushSizes = {
    1, 3, 5
}

local DrawingSettingsController = {}

function DrawingSettingsController.Init()
    local CurrentXP = GetPlayerCurrency:InvokeServer(LocalPlayer, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    DrawingSettingsController.SetPercentageBar()
    if CurrentLevel >= LevelRequiredForBrushSizes then
        BrushSizeLockedOverlay:Destroy()
    end

    local OwnsBrushSizePass = UserOwnsGamepassRemote:InvokeServer(LocalPlayer, IDs.Gamepasses.BrushSizes)
    if OwnsBrushSizePass then
        if BrushSizeLockedOverlay then
            BrushSizeLockedOverlay:Destroy()
        end
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

    OnPassPurchasedRemote.OnClientEvent:Connect(function(GamepassId)
        local BrushSizesGamepass = IDs.Gamepasses.BrushSizes
        if GamepassId == BrushSizesGamepass then
            if BrushSizeLockedOverlay then
                BrushSizeLockedOverlay:Destroy()
            end
        end
    end)

    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName, NewCurrencyAmount)
        if CurrencyName == "XP" and BrushSizeLockedOverlay then
            local CurrentLevel = Levels.GetLevelFromXP(NewCurrencyAmount)
            if CurrentLevel >= LevelRequiredForBrushSizes then
                if BrushSizeLockedOverlay then
                    BrushSizeLockedOverlay:Destroy()
                end
            else
                DrawingSettingsController.SetPercentageBar()
            end
        end
    end)

    BrushSizeMinusButton.Activated:Connect(function()
        local CurrentBrushSize = GetDrawingSetting:Invoke("BrushSize")
        local BrushSizeIndex = table.find(BrushSizes, CurrentBrushSize)
        local InternalBrushSize = CurrentBrushSize - 1
        local NewBrushSize = BrushSizes[InternalBrushSize]
        if NewBrushSize ~= nil then
            BrushSizeText.Text = tostring(NewBrushSize).. "pt"
            OnBrushSizeChanged:Fire(InternalBrushSize)
        end
    end)

    BrushSizePlusButton.Activated:Connect(function()
        local CurrentBrushSize = GetDrawingSetting:Invoke("BrushSize")
        local BrushSizeIndex = table.find(BrushSizes, CurrentBrushSize)
        local InternalBrushSize = CurrentBrushSize + 1
        local NewBrushSize = BrushSizes[InternalBrushSize]
        if NewBrushSize ~= nil then
            BrushSizeText.Text = tostring(NewBrushSize).. "pt"
            OnBrushSizeChanged:Fire(InternalBrushSize)
        end
    end)

    EnableDragToDrawButton.Activated:Connect(function()
        local IsDragToDrawEnabled = GetDrawingSetting:Invoke("DragToDraw")
        if not IsDragToDrawEnabled then
            DrawingSettingsController.DisableSettingFrame(DisableDragToDrawFrame)
            DrawingSettingsController.EnableSettingFrame(EnableDragToDrawFrame)
            OnDragToDrawStateChanged:Fire(true)
        end
    end)

    DisableDragToDrawButton.Activated:Connect(function()
        local IsDragToDrawEnabled = GetDrawingSetting:Invoke("DragToDraw")
        if IsDragToDrawEnabled then
            DrawingSettingsController.EnableSettingFrame(DisableDragToDrawFrame)
            DrawingSettingsController.DisableSettingFrame(EnableDragToDrawFrame)
            OnDragToDrawStateChanged:Fire(false)
        end
    end)

    UnlockNowButton.Activated:Connect(function()
        local BrushSizesGamepass = IDs.Gamepasses.BrushSizes
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, BrushSizesGamepass)
    end)
    SelectGridSizeButton.Activated:Connect(DrawingSettingsController.OpenGridSizeMenu)
    CloseButton.Activated:Connect(DrawingSettingsController.ReturnToDrawingMenu)
end

function DrawingSettingsController.SetPercentageBar()
    local CurrentXP = GetPlayerCurrency:InvokeServer(LocalPlayer, "XP")
    local XPRequiredForBrushSize = Levels.GetXPFromLevel(LevelRequiredForBrushSizes)
    local PercentageTowardLevel10 = math.floor((CurrentXP / XPRequiredForBrushSize) * 100)
    FillBarFrame.Size = UDim2.fromScale(PercentageTowardLevel10 / 100, FillBarFrame.Size.Y.Scale)
    ProgressPercentageText.Text = tostring(PercentageTowardLevel10).. "%"
end

function DrawingSettingsController.DisableSettingFrame(SettingFrame)
    local Text = SettingFrame:FindFirstChildOfClass("TextLabel")
    UIUtility.Tween(SettingFrame, 0.05, {BackgroundTransparency = DisabledTransparency})
    UIUtility.Tween(Text, 0.05, {TextTransparency = DisabledTransparency})
end

function DrawingSettingsController.EnableSettingFrame(SettingFrame)
    local Text = SettingFrame:FindFirstChildOfClass("TextLabel")
    UIUtility.Tween(SettingFrame, 0.05, {BackgroundTransparency = EnabledTransparency})
    UIUtility.Tween(Text, 0.05, {TextTransparency = EnabledTransparency})
end

function DrawingSettingsController.ResetButtonSizes()
    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
end

function DrawingSettingsController.OpenMenu()
    InterfaceSound.PlaySound("OpenUI")
    Main.Size = UDim2.fromScale(0 , 0)
    SettingsMenuFrame.Visible = true
    Main.Visible = true
    UIUtility.Tween(Main, 0.1, {Size = RegularMainFrameSize})
end

function DrawingSettingsController.ReturnToDrawingMenu()
    local DrawingController = require(script.Parent:WaitForChild("DrawingController"))
    DrawingSettingsController.ResetButtonSizes()
    UIUtility.Tween(Main, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    SettingsMenuFrame.Visible = false
    DrawingController.OpenMenu()
end

function DrawingSettingsController.OpenGridSizeMenu()
    local GridSizeMenuController = require(script.Parent:WaitForChild("GridSizeMenuController"))
    UIUtility.Tween(Main, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    Main.Visible = false
    GridSizeMenuController.OpenMenu()
    DrawingSettingsController.ResetButtonSizes()
end

function DrawingSettingsController.IsMenuOpen()
    return SettingsMenuFrame.Visible
end

return DrawingSettingsController