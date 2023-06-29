local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local UserInterface = {}

function UserInterface.IsHoveringOverObject(Object)
    local PointerPosition = LocalPlayer:GetMouse()
    local PointerPosX, PointerPosY = PointerPosition.X, PointerPosition.Y
    local AbsPosX, AbsPosY = Object.AbsolutePosition.X, Object.AbsolutePosition.Y
    local AbsSizeX, AbsSizeY = Object.AbsoluteSize.X, Object.AbsoluteSize.Y
    local PosSizeX = AbsPosX + Object.AbsoluteSize.X
    local PosSizeY = AbsPosY + Object.AbsoluteSize.Y
    if PointerPosX >= AbsPosX and PointerPosY >= AbsPosY and PointerPosX <= PosSizeX and PointerPosY <= PosSizeY then
        return true
    else
        return false
   end
end

function UserInterface.CalculateSizePercentage(Percentage, Object)
    return UDim2.fromScale(Object.Size.X.Scale + (Object.Size.X.Scale * (Percentage / 100)), Object.Size.Y.Scale + (Object.Size.Y.Scale * (Percentage / 100)))
end

function UserInterface.Tween(Object, Time, Properties, ShouldYield)
    local Tween_Info = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    local Tween = TweenService:Create(Object, Tween_Info, Properties)
    ShouldYield = ShouldYield or false
    Tween:Play()
    if ShouldYield then
        Tween.Completed:Wait()
    end
end

function UserInterface.AreMenusOpen()
    local ControllersFolder = script.Parent.Parent:WaitForChild("Controllers")
    local LeaderboardController = require(ControllersFolder:WaitForChild("LeaderboardController"))
    local MenuControllers = {
        CoinShopController = require(ControllersFolder:WaitForChild("CoinShopController")),
        ColorShopController = require(ControllersFolder:WaitForChild("ColorShopController")),
        DrawingController = require(ControllersFolder:WaitForChild("DrawingController")),
        StatsController = require(ControllersFolder:WaitForChild("StatsController")),
        VotekickController = require(ControllersFolder:WaitForChild("VotekickController")),
        DrawingSettingsController = require(ControllersFolder:WaitForChild("DrawingSettingsController"))
    }

    for _, ControllerModule in pairs(MenuControllers) do
        if ControllerModule.IsMenuOpen then
            if ControllerModule.IsMenuOpen() then
                return true
            end
        end
    end
    return false
end

function UserInterface.CloseAllUI(ExceptionController)
    local ControllersFolder = script.Parent.Parent:WaitForChild("Controllers")
    local LeaderboardController = require(ControllersFolder:WaitForChild("LeaderboardController"))
    local MenuControllers = {
        CoinShopController = require(ControllersFolder:WaitForChild("CoinShopController")),
        ColorShopController = require(ControllersFolder:WaitForChild("ColorShopController")),
        DrawingController = require(ControllersFolder:WaitForChild("DrawingController")),
        StatsController = require(ControllersFolder:WaitForChild("StatsController")),
        VotekickController = require(ControllersFolder:WaitForChild("VotekickController")),
        ViewGiftsController = require(ControllersFolder:WaitForChild("ViewGiftsController")),
        GiftingController = require(ControllersFolder:WaitForChild("GiftingController"))
    }

    ExceptionController = ExceptionController or ""

    for ControllerName, ControllerModule in pairs(MenuControllers) do
        if ControllerName ~= ExceptionController then
            if ControllerModule.CloseMenu and ControllerModule.IsMenuOpen then
                if ControllerModule.IsMenuOpen() then
                    ControllerModule.CloseMenu(false)
                end
            end
        end
    end

    local SelectedLeaderslot = LeaderboardController.GetSelectedLeaderslot()
    if SelectedLeaderslot then
        LeaderboardController.SetLeaderslotToInactive(SelectedLeaderslot)
    end
end

return UserInterface