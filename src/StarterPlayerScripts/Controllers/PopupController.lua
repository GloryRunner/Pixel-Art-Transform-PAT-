--[[

ALL popups will have the same tweening code...and they're all in the same location:
-  ensure that if a player is vote kicked for instance, the reward popup 'waits' for the other one to go away
- Perhaps also have a cooldown so it must wait 1 second after the popup went away for the next one in the queue to appear
- I added a sound effect for popups (any many more things) so try and make the tween type and speed reflect the sound effect

-- everything needs to be part of a queue
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Hud = PlayerGui:WaitForChild("HUD.V1")
local MainFrame = Hud:WaitForChild("Frame")

local Utilties = script.Parent.Parent:WaitForChild("Utilities")
local UIUtility = require(Utilties:WaitForChild("UserInterface"))
local InterfaceSound = require(Utilties:WaitForChild("InterfaceSound"))

local OnCurrencyInterval = ReplicatedStorage:WaitForChild("PopupEvents"):WaitForChild("OnCurrencyInterval")
local GiftingRemotes = ReplicatedStorage:WaitForChild("GiftingRemotes")
local OnGiftAwarded = GiftingRemotes:WaitForChild("OnGiftAwarded")
local OnGiftSentSuccessfully = GiftingRemotes:WaitForChild("OnGiftSentSuccessfully")

local PopupFrames = {
    CurrencyEarned = MainFrame:WaitForChild("POPUP_CurrencyEarned"),
    GiftReceived = MainFrame:WaitForChild("POPUP_GiftReceived"),
    GiftSent = MainFrame:WaitForChild("POPUP_GiftSent"),
    Votekick = MainFrame:WaitForChild("POPUP_VoteKick")
}

local PopupQueue = {}
local PopupDuration = 6
local PopupCooldown = 1
local ShownPosition = UDim2.fromScale(0, 1)
local HiddenPosition = UDim2.fromScale(-0.61, 1)

local IsPopupActive = false

local PopupController = {}

function PopupController.Init()
    OnCurrencyInterval.OnClientEvent:Connect(function(CoinAmountGiven, XPAmountGiven)
        local PopupMetadata = {
            ["Name"] = "CurrencyEarned",
            ["CoinAmountGiven"] = CoinAmountGiven,
            ["XPAmountGiven"] = XPAmountGiven,
            ["Sound"] = "Popup"
        }
        PopupController.AddToQueue(PopupMetadata)
    end)

    OnGiftAwarded.OnClientEvent:Connect(function(PlayerReceiving, GiftData)
        local PopupMetadata = {
            ["Name"] = "GiftReceived",
            ["Sound"] = "Popup"
        }
        PopupController.AddToQueue(PopupMetadata)
    end)

    OnGiftSentSuccessfully.OnClientEvent:Connect(function()
        local PopupMetadata = {
            ["Name"] = "GiftSent",
            ["Sound"] = "Popup"
        }
        PopupController.AddToQueue(PopupMetadata)
    end)

    RunService.Heartbeat:Connect(function()
        for Index, PopupMetadata in ipairs(PopupQueue) do
            if not IsPopupActive then
                IsPopupActive = true
                PopupController.PlayPopup(Index, PopupMetadata)
                task.wait(PopupCooldown)
                IsPopupActive = false
            end
        end
    end)
end

function PopupController.AddToQueue(PopupMetadata)
    table.insert(PopupQueue, PopupMetadata)
end

function PopupController.RemoveFromQueue(Index)
    table.remove(PopupQueue, Index)
end

function PopupController.PlayPopup(Index, PopupMetadata)
    local PopupName = PopupMetadata.Name
    local PopupFrame = PopupController.GetFrameFromName(PopupName)
    local SoundName = PopupMetadata.Sound

    if PopupName == "CurrencyEarned" then
        local CoinCounter = PopupFrame:WaitForChild("CoinCounter")
        local XPCounter = PopupFrame:WaitForChild("XPCounter")
        CoinCounter.Text = "+".. tostring(math.floor(PopupMetadata.CoinAmountGiven))
        XPCounter.Text = "+".. tostring(math.floor(PopupMetadata.XPAmountGiven)).. "xp"
    end

    PopupFrame.Position = HiddenPosition
    PopupFrame.Visible = true
    UIUtility.Tween(PopupFrame, 0.05, {Position = ShownPosition}, true)
    InterfaceSound.PlaySound(SoundName)
    task.wait(PopupDuration)
    UIUtility.Tween(PopupFrame, 0.05, {Position = HiddenPosition}, true)
    PopupFrame.Visible = false
    PopupController.RemoveFromQueue(Index)
end

function PopupController.GetFrameFromName(PopupName)
    return PopupFrames[PopupName]
end

return PopupController