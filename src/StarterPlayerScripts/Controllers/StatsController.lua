local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local StatsMenu = PlayerGui:WaitForChild("StatsMenuV2")
local StatsMenuFrame = StatsMenu:WaitForChild("Frame")
local MainFrame = StatsMenuFrame:WaitForChild("MainFrame")
local UserAvatar = MainFrame:WaitForChild("UserAvatar")
local CoinText = MainFrame:WaitForChild("CoinTxt")
local ColorsOwnedCountText = MainFrame:WaitForChild("ColoursTxt")
local PlaytimeCountText = MainFrame:WaitForChild("HoursTxt")
local LevelText = MainFrame:WaitForChild("LevelTxt")
local XpText = MainFrame:WaitForChild("XpTxt")
local UsernameTxt = MainFrame:WaitForChild("UserTxt")
local WinsCountText = MainFrame:WaitForChild("WinsTxt")
local LikesGivenCountText = MainFrame:WaitForChild("LikesTxt")
local ProfileLikesCountText = MainFrame:WaitForChild("ProfileLikesTxt")
local PixelsCreatedCountText = MainFrame:WaitForChild("PixelsTxt")
local Hud = PlayerGui:WaitForChild("HUD.V1")
local StatsFrame = Hud:WaitForChild("Frame")
local StatsButtonFrame = StatsFrame:WaitForChild("StatsButton")
local StatsButton = StatsButtonFrame:WaitForChild("Button")
local CloseButtonFrame = StatsMenuFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local GiftCoinsButtonFrame = StatsMenuFrame:WaitForChild("GiftCoins")
local GiftCoinsButton = GiftCoinsButtonFrame:WaitForChild("Button")
local ViewGiftsButtonFrame = StatsMenuFrame:WaitForChild("ViewGifts")
local ViewGiftsButton = ViewGiftsButtonFrame:WaitForChild("Button")
local LikeButton = MainFrame:WaitForChild("FillHeart")
local HeartOutlineFrame = MainFrame:WaitForChild("OutlineHeart")

local GetPlayerCurrencyRemote = ReplicatedStorage:WaitForChild("GetPlayerCurrency")
local ProfileLikeRemotes = ReplicatedStorage:WaitForChild("ProfileLikeRemotes")
local GiveLikeRemote = ProfileLikeRemotes:WaitForChild("GiveLike")
local RemoveLikeRemote = ProfileLikeRemotes:WaitForChild("RemoveLike")
local HasPlayerLiked = ProfileLikeRemotes:WaitForChild("HasPlayerLiked")

local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Levels = require(SharedUtilities:WaitForChild("Levels"))
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local ViewGiftsController = require(script.Parent:WaitForChild("ViewGiftsController"))
local GiftingController = require(script.Parent:WaitForChild("GiftingController"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))
local DrawingSettingsController = require(script.Parent:WaitForChild("DrawingSettingsController"))

local TweenFrames = {
    {
        ["Frame"] = StatsButtonFrame,
        ["Button"] = StatsButton,
        ["RegularFrameSize"] = StatsButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(7, StatsButtonFrame)
    },
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(20, CloseButtonFrame)
    },
    {
        ["Frame"] = GiftCoinsButtonFrame,
        ["Button"] = GiftCoinsButton,
        ["RegularFrameSize"] = GiftCoinsButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, GiftCoinsButtonFrame)
    },
    {
        ["Frame"] = ViewGiftsButtonFrame,
        ["Button"] = ViewGiftsButton,
        ["RegularFrameSize"] = ViewGiftsButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, ViewGiftsButtonFrame)
    }
}

local RegularMenuSize = StatsMenuFrame.Size

local StatsController = {}

function StatsController.Init()
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

    StatsButton.Activated:Connect(function()
        local IsStatsMenuOpen = StatsController.IsMenuOpen()
        local IsDrawingSettingsMenuOpen = DrawingSettingsController.IsMenuOpen()
        if not IsDrawingSettingsMenuOpen then
            if IsStatsMenuOpen then
                StatsController.CloseMenu()
            else
                task.spawn(StatsController.DisplayPlayerProfile, LocalPlayer)
                StatsController.OpenMenu()
            end
        end
    end)

    ViewGiftsButton.Activated:Connect(function()
        StatsController.CloseMenu(false)
        ViewGiftsController.OpenMenu()
    end)

    GiftCoinsButton.Activated:Connect(function()
        local PlayerDisplayed = StatsController.GetPlayerDisplayed()
        StatsController.CloseMenu(false)
        GiftingController.OpenMenu()
        GiftingController.DisplayPlayer(PlayerDisplayed)
    end)

    LikeButton.Activated:Connect(function()
        local PlayerDisplayed = StatsController.GetPlayerDisplayed()
        local IsProfileLiked = HasPlayerLiked:InvokeServer(PlayerDisplayed)

        if IsProfileLiked then
            RemoveLikeRemote:InvokeServer(PlayerDisplayed)
            local RemovedLikeSuccessfully = HasPlayerLiked:InvokeServer(PlayerDisplayed) == false
            if RemovedLikeSuccessfully then
                StatsController.RemoveLikeHeart()
            end
        else
            GiveLikeRemote:InvokeServer(PlayerDisplayed)
            local LikedSuccessfully = HasPlayerLiked:InvokeServer(PlayerDisplayed) == true
            if LikedSuccessfully then
                StatsController.FillLikeHeart()
            end
        end

        local ProfileLikesCount = GetPlayerCurrencyRemote:InvokeServer(PlayerDisplayed, "Likes")
        ProfileLikesCountText.Text = tostring(ProfileLikesCount)
    end)

    CloseButton.Activated:Connect(StatsController.CloseMenu)
end

function StatsController.DisplayPlayerProfile(Player)
    task.spawn(function()
        if Player == LocalPlayer then
            ViewGiftsButtonFrame.Visible = true
            GiftCoinsButtonFrame.Visible = false
        else
            ViewGiftsButtonFrame.Visible = false
            GiftCoinsButtonFrame.Visible = true
        end
    end)

    task.spawn(function()
        -- Getting the UserThumbnail yields the thread.
        UserAvatar.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)

    local Username = "@".. Player.Name
    local CoinCount = math.floor(GetPlayerCurrencyRemote:InvokeServer(Player, "Coins"))
    local PlaytimeCount = math.floor(GetPlayerCurrencyRemote:InvokeServer(Player, "Playtime") / 60)
    local LikesGivenCount = GetPlayerCurrencyRemote:InvokeServer(Player, "LikesGiven")
    local ProfileLikesCount = GetPlayerCurrencyRemote:InvokeServer(Player, "Likes")
    local PixelsCreatedCount = GetPlayerCurrencyRemote:InvokeServer(Player, "PixelsCreatedCount")
    local ColorsOwnedCount = GetPlayerCurrencyRemote:InvokeServer(Player, "ColorsOwnedCount")
    local WinCount = GetPlayerCurrencyRemote:InvokeServer(Player, "WinCount")
    local HasLikedPlayer = HasPlayerLiked:InvokeServer(Player)

    local GetPlayerCurrency = ReplicatedStorage:WaitForChild("GetPlayerCurrency")
    local CurrentXP = GetPlayerCurrency:InvokeServer(Player, "XP")
    local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
    local XPNeededForNextLevel = Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), math.floor(CurrentLevel) + 1)
    local XPTowardNextLevel = Levels.GetRemainingXPForLevel(math.floor(CurrentLevel), CurrentLevel)

    if HasLikedPlayer then
        StatsController.FillLikeHeart()
    else
        StatsController.RemoveLikeHeart()
    end

    UsernameTxt.Text = Username
    CoinText.Text = tostring(CoinCount)
    PlaytimeCountText.Text = tostring(PlaytimeCount)
    LikesGivenCountText.Text = tostring(LikesGivenCount)
    ProfileLikesCountText.Text = tostring(ProfileLikesCount)
    PixelsCreatedCountText.Text = tostring(PixelsCreatedCount)
    ColorsOwnedCountText.Text = tostring(ColorsOwnedCount).. "/52"
    WinsCountText.Text = tostring(WinCount)
    LevelText.Text = "Level ".. tostring(math.floor(CurrentLevel))
    XpText.Text = tostring(math.floor(XPTowardNextLevel)).. "/".. tostring(XPNeededForNextLevel)
end

function StatsController.GetPlayerDisplayed()
    -- Uses the username text set by DisplayPlayerProfile to get the username of the user being gifted.
    local function ParseForUsername()
        local StrLength = string.len(UsernameTxt.Text)
        local Username = string.sub(UsernameTxt.Text, 2, StrLength)
        return Username
    end

    local Username = ParseForUsername()
    local Player = Players:FindFirstChild(Username)
    return Player
end

function StatsController.FillLikeHeart()
    LikeButton.ImageTransparency = 0
    HeartOutlineFrame.Visible = false
end

function StatsController.RemoveLikeHeart()
    LikeButton.ImageTransparency = 1
    HeartOutlineFrame.Visible = true
end

function StatsController.ResetButtonSizes()
    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
end

function StatsController.IsMenuOpen()
    return StatsMenu.Enabled
end

function StatsController.OpenMenu()
    task.spawn(UIUtility.CloseAllUI, "StatsController")
    InterfaceSound.PlaySound("OpenUI")
    StatsMenuFrame.Size = UDim2.fromScale(0, 0)
    StatsMenu.Enabled = true
    UIUtility.Tween(StatsMenuFrame, 0.1, {Size = RegularMenuSize})
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

function StatsController.CloseMenu(FullClose)
    if FullClose == nil then
        FullClose = true
    end

    if FullClose then
        InterfaceSound.PlaySound("CloseUI")
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)
    end
    StatsController.ResetButtonSizes()
    UIUtility.Tween(StatsMenuFrame, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    StatsMenu.Enabled = false
end

return StatsController