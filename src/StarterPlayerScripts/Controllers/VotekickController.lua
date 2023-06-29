local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VotekickMenu = PlayerGui:WaitForChild("VoteKick")
local VotekickMenuFrame = VotekickMenu:WaitForChild("Frame")
local CloseButtonFrame = VotekickMenuFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local MainFrame = VotekickMenuFrame:WaitForChild("MainFrame")
local UserAvatar = MainFrame:WaitForChild("UserAvatar")
local KickReason = MainFrame:WaitForChild("KickReason")
local KickCounter = MainFrame:WaitForChild("KickCounter")
local UsernameText = MainFrame:WaitForChild("UserTxt")
local Reasons = MainFrame:WaitForChild("Reasons")
local SelectedGradient = VotekickMenu:WaitForChild("SelectedGradient")
local UnselectedGradient = VotekickMenu:WaitForChild("UnselectedGradient")
local ConfirmButtonFrame = MainFrame:WaitForChild("ConfirmButton")
local ConfirmButton = ConfirmButtonFrame:WaitForChild("Button")
local CancelButtonFrame = MainFrame:WaitForChild("CancelButton")
local CancelButton = CancelButtonFrame:WaitForChild("Button")

local Utilties = script.Parent.Parent:WaitForChild("Utilities")
local UIUtility = require(Utilties:WaitForChild("UserInterface"))

local RegularCloseButtonSize = CloseButtonFrame.Size
local EnlargedCloseButtonSize = UIUtility.CalculateSizePercentage(20, CloseButtonFrame)

local VotekickController = {}

function VotekickController.Init()
    CloseButton.Activated:Connect(VotekickController.CloseMenu)

    CloseButton.MouseEnter:Connect(function()
        UIUtility.Tween(CloseButtonFrame, 0.05, {Size = EnlargedCloseButtonSize})
    end)

    CloseButton.MouseLeave:Connect(function()
        UIUtility.Tween(CloseButtonFrame, 0.05, {Size = RegularCloseButtonSize})
    end)

    ConfirmButton.Activated:Connect(VotekickController.RequestVotekick)
    CancelButton.Activated:Connect(VotekickController.CancelVotekick)

    for _, ReasonFrame in ipairs(Reasons:GetChildren()) do
        if ReasonFrame.Name == "ReasonButton" then
            local Button = ReasonFrame:WaitForChild("Button")
            local ListedReasonLabel = ReasonFrame:WaitForChild("TextLabel")
            Button.Activated:Connect(function()
                VotekickController.SetActiveVotekickReason(ReasonFrame)
            end)
        end
    end
end

function VotekickController.DisplayPlayerToVotekick(Player)
    local UserAvatarImage = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    KickReason.Text = ""
    UserAvatar.Image = UserAvatarImage
    UsernameText.Text = "@".. Player.Name
end

function VotekickController.SetActiveVotekickReason(ReasonFrame)
    for _, Frame in ipairs(Reasons:GetChildren()) do
        if Frame.Name == "ReasonButton" then
            local ListedReasonLabel = Frame:WaitForChild("TextLabel")
            local ExistingGradient = Frame:FindFirstChildOfClass("UIGradient")
            if ExistingGradient then
                ExistingGradient:Destroy()
            end
            if Frame == ReasonFrame then
                local SelectedGradientClone = SelectedGradient:Clone()
                SelectedGradientClone.Parent = ReasonFrame
                KickReason.Text = ListedReasonLabel.Text
            else
                local UnselectedGradientClone = UnselectedGradient:Clone()
                UnselectedGradientClone.Parent = Frame
            end
        end
    end
end

function VotekickController.RequestVotekick()
    ConfirmButtonFrame.Visible = false
    CancelButtonFrame.Visible = true
end

function VotekickController.CancelVotekick()
    CancelButtonFrame.Visible = false
    ConfirmButtonFrame.Visible = true
end

function VotekickController.IsMenuOpen()
    return VotekickMenu.Enabled
end

function VotekickController.OpenMenu()
    task.spawn(UIUtility.CloseAllUI, "VotekickController")
    local RegularMenuSize = UDim2.fromScale(0.394, 0.593)
    CloseButtonFrame.Size = RegularCloseButtonSize
    VotekickMenuFrame.Size = UDim2.fromScale(0 , 0)
    VotekickMenu.Enabled = true
    UIUtility.Tween(VotekickMenuFrame, 0.1, {Size = RegularMenuSize})
end

function VotekickController.CloseMenu()
    UIUtility.Tween(VotekickMenuFrame, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    VotekickMenu.Enabled = false
end

return VotekickController