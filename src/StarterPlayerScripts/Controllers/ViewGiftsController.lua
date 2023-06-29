local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ViewGiftsMenu = PlayerGui:WaitForChild("ViewGifts")
local HudMainFrame = PlayerGui:WaitForChild("HUD.V1"):WaitForChild("Frame")
local ViewGiftsFrame = ViewGiftsMenu:WaitForChild("ViewGifts")
local MainFrame = ViewGiftsFrame:WaitForChild("MainFrame")
local ScrollingFrame = MainFrame:WaitForChild("ScrollingFrame")
local UIListLayout = ScrollingFrame:WaitForChild("UIListLayout")
local GiftTemplate = ScrollingFrame:WaitForChild("GiftTemplate")
local GiftAlertIcon = HudMainFrame:WaitForChild("StatsButton"):WaitForChild("AlertPopup")
local ProfileMenuAlertPopup = PlayerGui:WaitForChild("StatsMenuV2"):WaitForChild("Frame"):WaitForChild("ViewGifts"):WaitForChild("AlertPopup")
local GiftReceivedOpen = HudMainFrame:WaitForChild("POPUP_GiftReceived"):WaitForChild("Frame"):WaitForChild("Button")
local CloseButtonFrame = ViewGiftsFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local GiftReceivedPopupFrame = HudMainFrame:WaitForChild("POPUP_GiftReceived"):WaitForChild("Frame")
local GiftReceivedPopupButton = GiftReceivedPopupFrame:WaitForChild("Button")

local GiftingRemotes = ReplicatedStorage:WaitForChild("GiftingRemotes")
local GetGifts = GiftingRemotes:WaitForChild("GetGifts")
local OnGiftAwarded = GiftingRemotes:WaitForChild("OnGiftAwarded")
local OnGiftRedeemed = GiftingRemotes:WaitForChild("OnGiftRedeemed")
local HideGiftAlert = GiftingRemotes:WaitForChild("HideGiftAlert")

local RegularClaimButtonFrameSize = GiftTemplate:WaitForChild("ClaimButton").Size
local RegularMenuSize = ViewGiftsFrame.Size

local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))

local TweenFrames = {
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(15, CloseButtonFrame)
    },
    {
        ["Frame"] = GiftReceivedPopupFrame,
        ["Button"] = GiftReceivedPopupButton,
        ["RegularFrameSize"] = GiftReceivedPopupFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(12, GiftReceivedPopupFrame)
    }
}

local ViewGiftsController = {}

function ViewGiftsController.Init()
    local GiftsReceived = GetGifts:InvokeServer()
    for _, GiftData in ipairs(GiftsReceived) do
        ViewGiftsController.CreateGiftSlot(GiftData)
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

    CloseButton.Activated:Connect(ViewGiftsController.CloseMenu)

    GiftReceivedOpen.Activated:Connect(function()
        local IsMenuOpen = ViewGiftsController.IsMenuOpen()
        if not IsMenuOpen then
            ViewGiftsController.OpenMenu()
        end
    end)

    HideGiftAlert.OnClientInvoke = function()
        GiftAlertIcon.Visible = false
        ProfileMenuAlertPopup.Visible = false
    end

    OnGiftAwarded.OnClientEvent:Connect(ViewGiftsController.CreateGiftSlot)
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ViewGiftsController.UpdateScrollingFrameCanvasSize)
end

function ViewGiftsController.CreateGiftSlot(GiftData)
    local GifterUserId = GiftData.GiftedBy
    local CoinAmount = GiftData.CoinAmount
    local PurchaseId = GiftData.PurchaseId
    local GiftSlotClone = GiftTemplate:Clone()
    local ClaimButtonFrame = GiftSlotClone:WaitForChild("ClaimButton")
    local ClaimButton = ClaimButtonFrame:WaitForChild("Button")
    local GifterName = GiftSlotClone:WaitForChild("GifterName")
    local CoinText = GiftSlotClone:WaitForChild("CoinText")
    local AvatarImage = GiftSlotClone:WaitForChild("AvatarImage")

    GiftAlertIcon.Visible = true
    ProfileMenuAlertPopup.Visible = true
    task.spawn(function()
        GifterName.Text = "@".. Players:GetNameFromUserIdAsync(GifterUserId)
        AvatarImage.Image = Players:GetUserThumbnailAsync(GifterUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    GiftSlotClone.Name = "Gift"
    GiftSlotClone.Visible = true
    CoinText.Text = "+".. tostring(CoinAmount).. " Coins!"

    ClaimButton.Activated:Connect(function()
        OnGiftRedeemed:FireServer(PurchaseId)
        InterfaceSound.PlaySound("ClaimGift")
        GiftSlotClone:Destroy()
    end)

    local EnlargedClaimButtonFrameSize = UIUtility.CalculateSizePercentage(15, ClaimButtonFrame)

    ClaimButton.MouseEnter:Connect(function()
        UIUtility.Tween(ClaimButtonFrame, 0.05, {Size = EnlargedClaimButtonFrameSize})
    end)

    ClaimButton.MouseLeave:Connect(function()
        UIUtility.Tween(ClaimButtonFrame, 0.05, {Size = RegularClaimButtonFrameSize})
    end)

    GiftSlotClone.Parent = ScrollingFrame
end

function ViewGiftsController.OpenMenu()
    task.spawn(UIUtility.CloseAllUI, "ViewGiftsController")
    InterfaceSound.PlaySound("OpenUI")
    ViewGiftsFrame.Size = UDim2.fromScale(0, 0)
    ViewGiftsMenu.Enabled = true
    UIUtility.Tween(ViewGiftsFrame, 0.1, {Size = RegularMenuSize})
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

function ViewGiftsController.CloseMenu(FullClose)
    if FullClose == nil then
        FullClose = true
    end

    if FullClose then
        InterfaceSound.PlaySound("CloseUI")
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)
    end
    ViewGiftsController.ResetButtonSizes()
    UIUtility.Tween(ViewGiftsFrame, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    ViewGiftsMenu.Enabled = false
end

function ViewGiftsController.ResetButtonSizes()
    for _, Giftslot in ipairs(ScrollingFrame:GetChildren()) do
        if Giftslot.Name == "Gift" then
            local ClaimButtonFrame = Giftslot:WaitForChild("ClaimButton")
            ClaimButtonFrame.Size = RegularClaimButtonFrameSize
        end
    end

    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
end

function ViewGiftsController.UpdateScrollingFrameCanvasSize()
    local AbsoluteContentSize = UIListLayout.AbsoluteContentSize
    local PaddingSize = UDim.new(0, GiftTemplate.AbsoluteSize.Y / 8)
    UIListLayout.Padding = PaddingSize
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, AbsoluteContentSize.Y)
end

function ViewGiftsController.IsMenuOpen()
    return ViewGiftsMenu.Enabled
end

return ViewGiftsController