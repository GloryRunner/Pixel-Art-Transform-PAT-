local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Hud = PlayerGui:WaitForChild("HUD.V1")
local LeaderboardFrame = Hud:WaitForChild("Leaderboard")
local LeaderboardScrollingFrame = LeaderboardFrame:WaitForChild("ScrollingFrame")
local RegularLeaderslotTemplate = LeaderboardScrollingFrame:WaitForChild("RegularLeaderslotTemplate")
local ProLeaderslotTemplate = LeaderboardScrollingFrame:WaitForChild("PROLeaderslotTemplate")
local PlayerFrame = LeaderboardFrame:WaitForChild("PlayerFrame")
local Name = PlayerFrame:WaitForChild("Name")
local PersonalAvatarImage = PlayerFrame:WaitForChild("PlayerIcon")
local RegularPopup = Hud:WaitForChild("RegularPopup")
local ProPopup = Hud:WaitForChild("PROPopup")
local PopupProfileFrame = RegularPopup:WaitForChild("Profile")
local ProPopupProfileFrame = ProPopup:WaitForChild("Profile")
local VotekickFrame = RegularPopup:WaitForChild("VoteKick")
local ProVotekickFrame = ProPopup:WaitForChild("VoteKick")
local HidePixelFrame = RegularPopup:WaitForChild("Hide")
local ProHidePixelFrame = ProPopup:WaitForChild("Hide")

local PopupButtons = {
    PopupProfileButton = PopupProfileFrame:WaitForChild("Button"),
    ProPopupProfileButton = ProPopupProfileFrame:WaitForChild("Button"),
    VotekickButton = VotekickFrame:WaitForChild("Button"),
    ProVotekickButton = ProVotekickFrame:WaitForChild("Button"),
    HidePixelButton = HidePixelFrame:WaitForChild("Button"),
    ProHidePixelButton = ProHidePixelFrame:WaitForChild("Button")
}

local StatsController = require(script.Parent:WaitForChild("StatsController"))
local UserOwnsGamepassRemote = ReplicatedStorage:WaitForChild("GamepassCheck"):WaitForChild("UserOwnsGamepass")
local OnPlayerMorphedRemote = ReplicatedStorage:WaitForChild("DrawingRemotes"):WaitForChild("OnPlayerMorphed")

local PremiumIconId = "rbxassetid://13400682039"
local ActiveBackgroundColor = Color3.fromRGB(255, 255, 255)
local ActiveBackgroundTransparency = 0.2
local ActiveNameColor = Color3.fromRGB(0, 0, 0)
local ActiveUsernameColor = Color3.fromRGB(90, 90, 90)
local InactiveBackgroundColor = Color3.fromRGB(54, 64, 68)
local InactiveBackgroundTransparency = 1
local InactiveNameColor = Color3.fromRGB(255, 255, 255)
local InactiveUsernameColor = Color3.fromRGB(175, 175, 175)

local ShownPixelImageId = "rbxassetid://13903594647"
local HiddenPixelImageId = "rbxassetid://13400741152"

local VotekickController = require(script.Parent:WaitForChild("VotekickController"))
local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local TopbarIcon = require(script.Parent.Parent:WaitForChild("Icon"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))
local IDs = require(ReplicatedStorage:WaitForChild("Constants"):WaitForChild("IDs"))

local IsLeaderboardOpen = false

local SelectedLeaderslot = nil
local LeaderboardController = {}

local ActiveTopbarIcon = nil

local PlayerPixels = {}
local OnHidePixelCooldown = false
local HidePixelCooldownDuration = 1

function LeaderboardController.Init()
    task.spawn(function()
        ActiveTopbarIcon = LeaderboardController.CreateTopbarIcon()
    end)
    task.spawn(LeaderboardController.DisableDefaultLeaderboard)

    Name.Text = LocalPlayer.Name
    PersonalAvatarImage.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)

    for _, Player in ipairs(Players:GetPlayers()) do
        LeaderboardController.AddPlayer(Player)
    end

    PopupButtons.PopupProfileButton.Activated:Connect(LeaderboardController.ViewPlayerProfile)
    PopupButtons.ProPopupProfileButton.Activated:Connect(LeaderboardController.ViewPlayerProfile)
    PopupButtons.VotekickButton.Activated:Connect(LeaderboardController.ViewVotekickMenu)
    PopupButtons.ProVotekickButton.Activated:Connect(LeaderboardController.ViewVotekickMenu)
    PopupButtons.HidePixelButton.Activated:Connect(LeaderboardController.OnHidePixelButtonActivated)
    PopupButtons.ProHidePixelButton.Activated:Connect(LeaderboardController.OnHidePixelButtonActivated)

    for _, PopupButton in pairs(PopupButtons) do
        PopupButton.MouseEnter:Connect(function()
            local PopupButtonFrame = PopupButton.Parent
            LeaderboardController.OnPopupButtonEnter(PopupButtonFrame)
        end)
        PopupButton.MouseLeave:Connect(function()
            local PopupButtonFrame = PopupButton.Parent
            LeaderboardController.OnPopupButtonLeave(PopupButtonFrame)
        end)
    end

    OnPlayerMorphedRemote.OnClientEvent:Connect(function(Player, MorphGui)
        local HasHidden = LeaderboardController.HasPixelHidden(Player)
        PlayerPixels[Player] = {
            ["IsHidden"] = HasHidden,
            ["MorphGui"] = MorphGui
        }
        if HasHidden then
            MorphGui.Enabled = false
        end
    end)

    LeaderboardScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if SelectedLeaderslot then
            LeaderboardController.SetLeaderslotToInactive(SelectedLeaderslot)
        end
    end)

    Players.PlayerAdded:Connect(function(Player)
        if Player ~= LocalPlayer then
            LeaderboardController.AddPlayer(Player)
        end
    end)

    Players.PlayerRemoving:Connect(function(Player)
        if Player ~= LocalPlayer then
            LeaderboardController.RemovePlayer(Player)
        end
        if SelectedLeaderslot and SelectedLeaderslot.Name == Player.Name then
            SelectedLeaderslot = nil
        end
        PlayerPixels[Player] = nil
    end)

    UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
        if Input.KeyCode == Enum.KeyCode.Tab and not GameProcessedEvent then
            local IsLeaderboardOpen = LeaderboardController.IsLeaderboardOpen()
            if IsLeaderboardOpen then
                LeaderboardController.CloseLeaderboard()
            else
                LeaderboardController.OpenLeaderboard()
            end
        end
    end)
end

function LeaderboardController.AddPlayer(Player)
    local ProGamepassId = IDs.Gamepasses.Pro
    local PlayerOwnsPro = UserOwnsGamepassRemote:InvokeServer(Player, ProGamepassId)
    local Leaderslot = nil

    if PlayerOwnsPro or Player.Name == "GloryRunner" then -- DELETE THIS PLEASE
        Leaderslot = ProLeaderslotTemplate:Clone()
    else
        Leaderslot = RegularLeaderslotTemplate:Clone()
    end

    local ImageLabel = Leaderslot:WaitForChild("ImageLabel")
    local DisplayName = Leaderslot:WaitForChild("Name")
    local Username = Leaderslot:WaitForChild("Username")
    local Button = Leaderslot:WaitForChild("Button")
    local AvatarImage = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
    
    Leaderslot.Name = Player.Name
    DisplayName.Text = Player.DisplayName
    Username.Text = "@".. Player.Name

    if Player.MembershipType == Enum.MembershipType.Premium then
        ImageLabel.Image = PremiumIconId
        ImageLabel.Visible = true
    else
        ImageLabel.Image = AvatarImage
        ImageLabel.Visible = false
    end

    Button.Activated:Connect(function()
        LeaderboardController.OnLeaderslotClicked(Leaderslot)
    end)

    Leaderslot.Visible = true
    Leaderslot.Parent = LeaderboardScrollingFrame
end

function LeaderboardController.OnLeaderslotClicked(Leaderslot)
    local IsLeaderslotInactive = Leaderslot.BackgroundColor3 == InactiveBackgroundColor
    local IsProLeaderslot = LeaderboardController.IsProLeaderslot(Leaderslot)
    local Popup = IsProLeaderslot and ProPopup or RegularPopup

    local PopupPosition = UDim2.fromOffset(Leaderslot.AbsolutePosition.X - Popup.AbsoluteSize.X, Leaderslot.AbsolutePosition.Y)

    if SelectedLeaderslot and SelectedLeaderslot ~= Leaderslot then
        Popup.Position = PopupPosition
        LeaderboardController.SetLeaderslotToInactive(SelectedLeaderslot)
    end

    if IsLeaderslotInactive then
        Popup.Position = PopupPosition
        LeaderboardController.SetLeaderslotToActive(Leaderslot)
    else
        LeaderboardController.SetLeaderslotToInactive(Leaderslot)
    end

    LeaderboardController.SetPixelVisibilityText()

    SelectedLeaderslot = Leaderslot
end

function LeaderboardController.OnPopupButtonEnter(PopupButtonFrame)
    PopupButtonFrame.BackgroundTransparency = 0
end

function LeaderboardController.OnPopupButtonLeave(PopupButtonFrame)
    PopupButtonFrame.BackgroundTransparency = 1
end

function LeaderboardController.SetPixelVisibilityText()
    if RegularPopup.Visible or ProPopup.Visible then
        local Player = Players:FindFirstChild(SelectedLeaderslot.Name)
        local HasHidden = LeaderboardController.HasPixelHidden(Player)
    
        local NameLabel, ImageLabel
    
        if RegularPopup.Visible then
            NameLabel = HidePixelFrame:WaitForChild("Name")
            ImageLabel = HidePixelFrame:WaitForChild("ImageLabel")
        elseif ProPopup.Visible then
            NameLabel = ProHidePixelFrame:WaitForChild("Name")
            ImageLabel = ProHidePixelFrame:WaitForChild("ImageLabel")
        end

        if HasHidden then
            NameLabel.Text = "Show pixel"
            ImageLabel.Image = ShownPixelImageId
        else
            NameLabel.Text = "Hide pixel"
            ImageLabel.Image = HiddenPixelImageId
        end
    end
end

function LeaderboardController.OnHidePixelButtonActivated()
    local SelectedPlayer = Players:FindFirstChild(SelectedLeaderslot.Name)
    if SelectedPlayer and not OnHidePixelCooldown then
        local HasHidden = LeaderboardController.HasPixelHidden(SelectedPlayer)
        if HasHidden then
            LeaderboardController.ShowPixel()
        else
            LeaderboardController.HidePixel()
        end
        OnHidePixelCooldown = true
        LeaderboardController.SetPixelVisibilityText()
        task.spawn(function()
            task.wait(HidePixelCooldownDuration)
            OnHidePixelCooldown = false
        end)
    end
end

function LeaderboardController.SetLeaderslotToActive(Leaderslot)
    local AreMenusOpen = UIUtility.AreMenusOpen()
    if not AreMenusOpen then
        local Player = Players:FindFirstChild(Leaderslot.Name)
        if Player then
            local ImageLabel = Leaderslot:WaitForChild("ImageLabel")
            local AvatarImage = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
            ImageLabel.Image = AvatarImage
            ImageLabel.Visible = true
        end

        Leaderslot.BackgroundColor3 = ActiveBackgroundColor
        Leaderslot.BackgroundTransparency = ActiveBackgroundTransparency
        Leaderslot:FindFirstChild("Name").TextColor3 = ActiveNameColor
        Leaderslot:FindFirstChild("Username").TextColor3 = ActiveUsernameColor
        
        if Leaderslot.Name ~= LocalPlayer.Name then
            LeaderboardController.ShowPopup(Leaderslot)
        end
    end
end

function LeaderboardController.SetLeaderslotToInactive(Leaderslot)
    local Player = Players:FindFirstChild(Leaderslot.Name)
    if Player then
        local ImageLabel = Leaderslot:WaitForChild("ImageLabel")
        if Player.MembershipType == Enum.MembershipType.Premium then
            ImageLabel.Image = PremiumIconId
        else
            ImageLabel.Visible = false
        end
    end
    
    Leaderslot.BackgroundColor3 = InactiveBackgroundColor
    Leaderslot.BackgroundTransparency = InactiveBackgroundTransparency
    Leaderslot:FindFirstChild("Name").TextColor3 = InactiveNameColor
    Leaderslot:FindFirstChild("Username").TextColor3 = InactiveUsernameColor
    LeaderboardController.HidePopup(Leaderslot)
end

function LeaderboardController.ShowPopup(Leaderslot)
    local IsProLeaderslot = LeaderboardController.IsProLeaderslot(Leaderslot)
    if IsProLeaderslot then
        ProPopup.Visible = true
    else
        RegularPopup.Visible = true
    end
end

function LeaderboardController.HidePopup(Leaderslot)
    local IsProLeaderslot = LeaderboardController.IsProLeaderslot(Leaderslot)
    if IsProLeaderslot then
        ProPopup.Visible = false
    else
        RegularPopup.Visible = false
    end
end

function LeaderboardController.IsProLeaderslot(Leaderslot)
    local UIGradient = Leaderslot:WaitForChild("Name"):FindFirstChild("UIGradient")
    if UIGradient then
        return true
    else
        return false
    end
end

function LeaderboardController.GetSelectedLeaderslot()
    return SelectedLeaderslot
end

function LeaderboardController.HasPixelHidden(Player)
    if PlayerPixels[Player] then
        return PlayerPixels[Player].IsHidden
    else
        return false
    end
end

function LeaderboardController.ShowPixel()
    local SelectedPlayer = Players:FindFirstChild(SelectedLeaderslot.Name)
    local HasHidden = LeaderboardController.HasPixelHidden(SelectedPlayer)
    local HasMorphed = PlayerPixels[SelectedPlayer] ~= nil and PlayerPixels[SelectedPlayer]["MorphGui"] ~= nil
    if HasHidden then
        if HasMorphed then
            PlayerPixels[SelectedPlayer].IsHidden = false
            PlayerPixels[SelectedPlayer].MorphGui.Enabled = true
        else
            PlayerPixels[SelectedPlayer] = {
                ["IsHidden"] = false,
                ["MorphGui"] = nil
            }
        end
    end
end

function LeaderboardController.HidePixel()
    local SelectedPlayer = Players:FindFirstChild(SelectedLeaderslot.Name)
    local HasHidden = LeaderboardController.HasPixelHidden(SelectedPlayer)
    local HasMorphed = PlayerPixels[SelectedPlayer] ~= nil and PlayerPixels[SelectedPlayer]["MorphGui"] ~= nil

    if not HasHidden then
        if HasMorphed then
            PlayerPixels[SelectedPlayer].IsHidden = true
            PlayerPixels[SelectedPlayer].MorphGui.Enabled = false
        else
            PlayerPixels[SelectedPlayer] = {
                ["IsHidden"] = true,
                ["MorphGui"] = nil
            }
        end
    end
end

function LeaderboardController.ViewPlayerProfile()
    local SelectedPlayer = Players:FindFirstChild(SelectedLeaderslot.Name)
    if SelectedPlayer then
        local IsProfileMenuOpen = StatsController.IsMenuOpen()
        if not IsProfileMenuOpen then
            StatsController.OpenMenu()
        else
            StatsController.CloseMenu()
        end
        StatsController.DisplayPlayerProfile(SelectedPlayer)
    end
end

function LeaderboardController.ViewVotekickMenu()
    if SelectedLeaderslot then
        local PlayerBeingVoted = Players:FindFirstChild(SelectedLeaderslot.Name)
        local IsMenuOpen = VotekickController.IsMenuOpen()
        if PlayerBeingVoted then
            if IsMenuOpen then
                VotekickController.CloseMenu()
            else
                VotekickController.OpenMenu()
                VotekickController.DisplayPlayerToVotekick(PlayerBeingVoted)
            end
        end
    end
end

function LeaderboardController.RemovePlayer(Player)
    local Leaderslot = LeaderboardScrollingFrame:FindFirstChild(Player.Name)
    if SelectedLeaderslot then
        if SelectedLeaderslot.Name == Player.Name then
            LeaderboardController.HidePopup(Leaderslot)
        end
    end
    if Leaderslot then
        Leaderslot:Destroy()
    end
end

function LeaderboardController.CreateTopbarIcon()
    local Icon = TopbarIcon.new()
	Icon:setLabel("Leaderboard")
	Icon:setTip("Open Leaderboard")
    Icon:bindToggleKey(Enum.KeyCode.Tab)
	Icon:set("iconFont", Enum.Font.GothamBold)
	Icon:bindEvent("selected", function()
        local IsTabKeyHeld = UserInputService:IsKeyDown(Enum.KeyCode.Tab)
        Icon:setTip("Close Leaderboard")
        if not IsTabKeyHeld then
            LeaderboardController.OpenLeaderboard()
        end
	end)
	Icon:bindEvent("deselected", function()
        local IsTabKeyHeld = UserInputService:IsKeyDown(Enum.KeyCode.Tab)
        Icon:setTip("Open Leaderboard")
        if not IsTabKeyHeld then
            LeaderboardController.CloseLeaderboard()
        end
	end)
    return Icon
end

function LeaderboardController.DisableDefaultLeaderboard()
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    end)
end

function LeaderboardController.IsLeaderboardOpen()
    return IsLeaderboardOpen
end

function LeaderboardController.OpenLeaderboard()
    local ViewportSize = workspace.CurrentCamera.ViewportSize
    local OpenPosition = UDim2.new(0, ViewportSize.X - LeaderboardFrame.AbsoluteSize.X, 0.013, 0)
    local ClosedPosition = UDim2.fromScale(1, 0.013)
    IsLeaderboardOpen = true
    InterfaceSound.PlaySound("OpenUI")
    UIUtility.Tween(LeaderboardFrame, 0.05, {Position = OpenPosition})
end

function LeaderboardController.CloseLeaderboard()
    local ClosedPosition = UDim2.fromScale(1, 0.013)
    InterfaceSound.PlaySound("CloseUI")
    if SelectedLeaderslot then
        LeaderboardController.SetLeaderslotToInactive(SelectedLeaderslot)
        SelectedLeaderslot = nil
    end
    IsLeaderboardOpen = false
    UIUtility.Tween(LeaderboardFrame, 0.05, {Position = ClosedPosition})
end

return LeaderboardController