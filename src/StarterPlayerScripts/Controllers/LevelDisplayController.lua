local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LevelFrame = PlayerGui:WaitForChild("HUD.V1"):WaitForChild("Frame"):WaitForChild("LevelFrame")
local LevelBar = LevelFrame:WaitForChild("Bar")
local ProgressBar = LevelBar:WaitForChild("ProgressBar")
local LevelCounter = LevelFrame:WaitForChild("LevelCounter")
local XPCounter = LevelFrame:WaitForChild("XPCounter")

local OnCurrencyChangeEvent = ReplicatedStorage:WaitForChild("OnCurrencyChange")
local GetPlayerCurrency = ReplicatedStorage:WaitForChild("GetPlayerCurrency")

local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Levels = require(SharedUtilities:WaitForChild("Levels"))
local UIUtility = require(script.Parent.Parent:WaitForChild("Utilities"):WaitForChild("UserInterface"))

local LevelDisplayController = {}

function LevelDisplayController.Init()
    LevelDisplayController.SetLevelCounter()
    ProgressBar.Size = LevelDisplayController.GetProgressBarSize()
    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName, NewCurrencyAmount)
        if CurrencyName == "XP" then
            LevelDisplayController.SetLevelCounter()
            LevelDisplayController.TweenSizeToXP()
        end
    end)
end

function LevelDisplayController.SetLevelCounter()
    local CurrentXP = GetPlayerCurrency:InvokeServer(LocalPlayer, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    local XPNeededForNextLevel = Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), math.floor(CurrentLevel) + 1)
    local XPTowardNextLevel = Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), CurrentLevel)
    XPCounter.Text = tostring(math.floor(XPTowardNextLevel)).. "/".. tostring(XPNeededForNextLevel)
    LevelCounter.Text = "Level ".. tostring(math.floor(CurrentLevel))
end

function LevelDisplayController.GetProgressBarSize()
    local CurrentXP = GetPlayerCurrency:InvokeServer(LocalPlayer, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    local XPNeededForNextLevel = Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), math.floor(CurrentLevel) + 1)
    local XPTowardNextLevel = math.floor(Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), CurrentLevel))
    local ProgressPercentage = XPTowardNextLevel / XPNeededForNextLevel
    return UDim2.fromScale(ProgressPercentage * 1, ProgressBar.Size.Y.Scale)
end

function LevelDisplayController.TweenSizeToXP()
    local ProgressBarSize = LevelDisplayController.GetProgressBarSize()
    UIUtility.Tween(ProgressBar, 0.05, {Size = ProgressBarSize})
end

return LevelDisplayController