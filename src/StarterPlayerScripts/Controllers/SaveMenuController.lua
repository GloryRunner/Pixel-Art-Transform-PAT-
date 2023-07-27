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

local LockedBackgroundColor = Color3.fromRGB(38, 45, 48)
local UnlockedBackgroundColor = Color3.fromRGB(53, 63, 67)

local SaveMenuController = {}

function SaveMenuController.Init()
    for _, SaveSlotData in ipairs(SaveSlots.Constants) do
        local FrameName = SaveSlotData.FrameName
        local RequiredLevel = SaveSlotData.RequiredLevel
        local UnlockProductId = SaveSlotData.UnlockProductId
        local Frame = ScrollingFrame:FindFirstChild(FrameName)
        local HasLevelRequirement = RequiredLevel > 1
        if HasLevelRequirement and UnlockProductId then
            local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
            local UnlockNowFrame = LockedOverlay:FindFirstChild("UnlockNow")
            local UnlockNowButton = UnlockNowFrame:FindFirstChild("Button")
            UnlockNowButton.Activated:Connect(function()
                MarketplaceService:PromptProductPurchase(LocalPlayer, UnlockProductId)
            end)
        end
    end

    task.spawn(function()
        task.wait(5)
        SaveMenuController.UnlockSaveSlotFrame(ScrollingFrame:WaitForChild("Z.Slot3"))
    end)

    SaveMenuController.UpdateLevelOverlays()
    SaveMenuController.UpdateGroupOverlay()

    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName, NewCurrencyAmount)
        if CurrencyName == "XP" then
            SaveMenuController.UpdateLevelOverlays()
            for _, SaveSlotData in ipairs(SaveSlots.Constants) do
                local FrameName = SaveSlotData.FrameName
                local Frame = ScrollingFrame:FindFirstChild(FrameName)
                local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
                local SaveSlotCurrencyName = SaveSlotData.CurrencyName
                local PurchasedInstantUnlock = NewCurrencyAmount == 1
                if SaveSlotCurrencyName and SaveSlotCurrencyName == CurrencyName then
                    if PurchasedInstantUnlock and LockedOverlay then
                        LockedOverlay:Destroy()
                    end
                end
            end
        end
    end)

    JoinButton.Activated:Connect(SaveMenuController.UpdateGroupOverlay)
    CloseButton.Activated:Connect(SaveMenuController.CloseMenu)
end

function SaveMenuController.UpdateGroupOverlay()
    if GroupSlotOverlayFrame then
        for _, SaveSlotData in ipairs(SaveSlots.Constants) do
            local FrameName = SaveSlotData.FrameName
            local Frame = ScrollingFrame:FindFirstChild(FrameName)
            local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
            if SaveSlotData.FrameName == "SlotGroup" then
                local GroupRequirementCallback = SaveSlotData.SpecialRequirement
                local IsGroupMember = GroupRequirementCallback(LocalPlayer) == true
                if IsGroupMember and LockedOverlay then
                    SaveMenuController.UnlockSaveSlotFrame(Frame)
                end
            end
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
        if Frame and LockedOverlay and RequiredLevel > 1 then
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

function SaveMenuController.UnlockSaveSlotFrame(Frame)

    -- needs to set slot name

    local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
    if LockedOverlay then
        local UnlockNowFrame = LockedOverlay:WaitForChild("UnlockNow")
        if UnlockNowFrame then
            local OrText = LockedOverlay:WaitForChild("ORText")
            local OverlayButtonFrame = LockedOverlay:WaitForChild("OverlayButton")
            OrText.Visible = true
            UnlockNowFrame.Visible = true
            OverlayButtonFrame.Visible = false 
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