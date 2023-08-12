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
    for _, SaveSlotData in ipairs(SaveSlots.RegularSlots) do
        local FrameName = SaveSlotData.FrameName
        local RequiredLevel = SaveSlotData.RequiredLevel
        local UnlockProductId = SaveSlotData.ProductId
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

    SaveMenuController.UpdateLevelLockedOverlays()
    SaveMenuController.UpdateGroupLockedOverlay()

    OnCurrencyChangeEvent.OnClientEvent:Connect(function(CurrencyName, NewCurrencyAmount)
        if CurrencyName == "XP" then
            SaveMenuController.UpdateLevelLockedOverlays()
        else

            -- Not functioning properly

            for _, SaveSlotData in ipairs(SaveSlots.RegularSlots) do
                local FrameName = SaveSlotData.FrameName
                local Frame = ScrollingFrame:FindFirstChild(FrameName)
                local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
                local SaveSlotCurrencyName = SaveSlotData.CurrencyName
                local PurchasedInstantUnlock = NewCurrencyAmount == 1
                if LockedOverlay then
                    if SaveSlotCurrencyName == CurrencyName and PurchasedInstantUnlock then
                        SaveMenuController.UpdateLevelLockedOverlays()
                    end
                end
            end
        end
    end)

    JoinButton.Activated:Connect(SaveMenuController.UpdateGroupLockedOverlay)
    CloseButton.Activated:Connect(SaveMenuController.CloseMenu)
end

function SaveMenuController.UpdateGroupLockedOverlay()
    local GroupSlotData = SaveSlots.GroupSlot
    local HasUnlockedGroupSlot = GroupSlotData.HasUnlocked(LocalPlayer)
    local FrameName = GroupSlotData.FrameName
    local Frame = ScrollingFrame:FindFirstChild(FrameName)
    local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
    if LockedOverlay and HasUnlockedGroupSlot then
        LockedOverlay:Destroy()
        Frame.BackgroundColor3 = UnlockedBackgroundColor
    end
end

function SaveMenuController.UpdateLevelLockedOverlays()
    local CurrentXP = GetPlayerCurrency:InvokeServer(LocalPlayer, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    
    for _, SaveSlotData in ipairs(SaveSlots.RegularSlots) do
        local FrameName = SaveSlotData.FrameName
        local RequiredLevel = SaveSlotData.RequiredLevel
        local CurrencyName = SaveSlotData.CurrencyName
        local Frame = ScrollingFrame:FindFirstChild(FrameName)
        local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
        if Frame and LockedOverlay then
            local HasPurchasedInstantUnlock = GetPlayerCurrency:InvokeServer(LocalPlayer, CurrencyName) == 1
            if CurrentLevel >= RequiredLevel or HasPurchasedInstantUnlock then
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
                Frame.BackgroundColor3 = UnlockedBackgroundColor
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

    for _, SaveSlotData in ipairs(SaveSlots.RegularSlots) do
        local RequiredLevel = SaveSlotData.RequiredLevel
        if RequiredLevel > 1 then
            local ProductId = SaveSlotData.ProductId
            local CurrencyName = SaveSlotData.CurrencyName
            local FrameName = SaveSlotData.FrameName
            local HasPurchasedInstantUnlock = GetPlayerCurrency:InvokeServer(LocalPlayer, CurrencyName) == 1
            if CurrentLevel < RequiredLevel and not HasPurchasedInstantUnlock then
                local FrameToUnlock = ScrollingFrame:WaitForChild(FrameName)
                SaveMenuController.UnlockSaveSlotFrame(FrameToUnlock)
                break
            end
        end
    end
end

function SaveMenuController.UnlockSaveSlotFrame(Frame)
    local LockedOverlay = Frame:FindFirstChild("LockedOverlay")
    if LockedOverlay then
        local UnlockNowFrame = LockedOverlay:WaitForChild("UnlockNow")
        local OrText = Frame:WaitForChild("ORText")
        local OverlayButtonFrame = LockedOverlay:WaitForChild("OverlayButton")
        OrText.Visible = true
        UnlockNowFrame.Visible = true
        OverlayButtonFrame.Visible = false 
    end
end

function SaveMenuController.EnableLoadingFromSlot(Frame)
    local LoadableBackgroundTransparency = 0
    local LoadableTextTransparency = 0

    local LoadButton = Frame:WaitForChild("LoadButton")
    local LoadTextLabel = LoadButton:WaitForChild("TextLabel")
    
    LoadButton.BackgroundTransparency = LoadableBackgroundTransparency
    LoadTextLabel.TextTransparency = LoadableTextTransparency
end

function SaveMenuController.DisableLoadingFromSlot(Frame)

    -- Will be used when players who leave the group in game have the group slot unlocked and need it locked again

    local NonLoadableTextTransparency = 0.5
    local NonLoadableBackgroundTransparency = 0.5

    local LoadButton = Frame:WaitForChild("LoadButton")
    local LoadTextLabel = LoadButton:WaitForChild("TextLabel")
    
    LoadButton.BackgroundTransparency = NonLoadableTextTransparency
    LoadTextLabel.TextTransparency = NonLoadableTextTransparency
end

function SaveMenuController.OpenMenu()
    SaveMenuFrame.Visible = true
    SelectSlotFrame.Visible = true
end

function SaveMenuController.CloseMenu()
    SaveMenuFrame.Visible = false
    SelectSlotFrame.Visible = false
    ConfirmSaveFrame.Visible = false
end

return SaveMenuController