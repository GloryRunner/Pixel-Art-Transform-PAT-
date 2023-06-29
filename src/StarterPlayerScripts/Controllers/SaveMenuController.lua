local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local DrawMenu = PlayerGui:WaitForChild("DrawMenu.V3")
local SaveMenuFrame = DrawMenu:WaitForChild("SaveMenu")
local ConfirmSaveFrame = SaveMenuFrame:WaitForChild("Confirm")
local SelectSlotFrame = SaveMenuFrame:WaitForChild("Selection")
local CloseButtonFrame = SelectSlotFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local ScrollingFrame = SelectSlotFrame:WaitForChild("MainFrame"):WaitForChild("ScrollingFrame")
local FreeSlot1 = ScrollingFrame:WaitForChild("Slot1")
local FreeSlot2 = ScrollingFrame:WaitForChild("Slot2")
local GroupSlot = ScrollingFrame:WaitForChild("SlotGroup")
local GroupSlotOverlayFrame = GroupSlot:WaitForChild("LockedOverlay")
local JoinButtonFrame = GroupSlotOverlayFrame:WaitForChild("JoinButton")
local JoinButton = JoinButtonFrame:WaitForChild("Button")

local OnCurrencyChangeEvent = ReplicatedStorage:WaitForChild("OnCurrencyChange")
local GetPlayerCurrency = ReplicatedStorage:WaitForChild("GetPlayerCurrency")

local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Constants = ReplicatedStorage:WaitForChild("Constants")
local IDs = require(Constants:WaitForChild("IDs"))
local SaveSlots = require(Constants:WaitForChild("SaveSlots"))
local Levels = require(SharedUtilities:WaitForChild("Levels"))

local SaveMenuController = {}

function SaveMenuController.Init()
    for _, SaveSlotFrame in ipairs(ScrollingFrame:GetChildren()) do
        if SaveSlotFrame:IsA("Frame") and SaveSlotFrame.Name ~= "SlotGroup" then
            local LockedOverlay = SaveSlotFrame:FindFirstChild("LockedOverlay")
            if LockedOverlay then
                local UnlockNowFrame = LockedOverlay:WaitForChild("UnlockNow")
                local UnlockNowButton = UnlockNowFrame:WaitForChild("Button")
                UnlockNowButton.Activated:Connect(function()
                    for _, SaveSlotData in ipairs(SaveSlots.Constants) do
                        local FrameName = SaveSlotData.FrameName
                        local ProductId = SaveSlotData.ProductId
                        if FrameName == SaveSlotFrame.Name then
                            MarketplaceService:PromptProductPurchase(LocalPlayer, ProductId)
                        end
                    end
                end)
            end
        end
    end
    
    SaveMenuController.UpdateLevelOverlays()
    SaveMenuController.UpdateGroupOverlay()

    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName)
        if CurrencyName == "XP" then
            SaveMenuController.UpdateLevelOverlays()
        end
    end)

    JoinButton.Activated:Connect(SaveMenuController.UpdateGroupOverlay)
    CloseButton.Activated:Connect(SaveMenuController.CloseMenu)
end

function SaveMenuController.UpdateGroupOverlay()
    if GroupSlotOverlayFrame then
        local MainGroupId = IDs["7Wapy"]
        local IsInGroup = LocalPlayer:IsInGroup(MainGroupId)
        if IsInGroup then
            GroupSlotOverlayFrame:Destroy()
        end
    end
end

function SaveMenuController.UpdateLevelOverlays()
    local CurrentXP = GetPlayerCurrency:InvokeServer(LocalPlayer, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    
    for _, SaveSlotData in ipairs(SaveSlots.Constants) do
        local FrameName = SaveSlotData.FrameName
        local RequiredLevel = SaveSlotData.RequiredLevel
        local Frame = ScrollingFrame:FindFirstChild(FrameName)
        local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
        if Frame and LockedOverlay then
            if CurrentLevel >= RequiredLevel then
                -- stops unlock now button from tweening once overlay is destroyed to get rid of null refs
                --[[
                    for Index, FrameTweenData in ipairs(TweenFrames) do
                    local TweenFrame = FrameTweenData.Frame
                    if TweenFrame == Frame then
                        table.remove(TweenFrames, Index)
                    end
                end
                ]]
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
end

function SaveMenuController.OpenMenu()
    SaveMenuFrame.Visible = true
end

function SaveMenuController.CloseMenu()
    SaveMenuFrame.Visible = false
end

return SaveMenuController