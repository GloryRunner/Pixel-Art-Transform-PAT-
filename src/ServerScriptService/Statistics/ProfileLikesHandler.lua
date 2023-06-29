local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileLikesDatastore = DataStoreService:GetDataStore("ProfileLikes")

local ProfileLikeRemotes = ReplicatedStorage:WaitForChild("ProfileLikeRemotes")
local GiveLikeRemote = ProfileLikeRemotes:WaitForChild("GiveLike")
local RemoveLikeRemote = ProfileLikeRemotes:WaitForChild("RemoveLike")
local HasPlayerLiked = ProfileLikeRemotes:WaitForChild("HasPlayerLiked")

local SetUserCurrency = ReplicatedStorage:WaitForChild("SetUserCurrency")

local MAX_SAVE_ATTEMPTS = 2
local ActionCooldownDuration = 1

local ProfileLikesContainer = {}
local LikingCooldownContainer = {}

local ProfileLikesHandler = {}

function ProfileLikesHandler.Init()
    Players.PlayerAdded:Connect(function(Player)
        task.spawn(function()
            ProfileLikesContainer[Player] = ProfileLikesHandler.GetProfileLikesForPlayer(Player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        task.spawn(function()
            local ProfileLikesData = ProfileLikesContainer[Player]
            for i = 1, MAX_SAVE_ATTEMPTS do
                local Success, Error = pcall(function()
                    ProfileLikesDatastore:SetAsync(tostring(Player.UserId), ProfileLikesData)
                end)
                if Success then
                    break
                else
                    print("Error saving profile like data for: ".. Player.Name.. " '".. tostring(Error).. "'")
                end
            end
            ProfileLikesContainer[Player] = nil
        end)
    end)

    GiveLikeRemote.OnServerInvoke = function(PlayerLiking, PlayerBeingLiked)
        local HasPlayerLiked = ProfileLikesHandler.HasPlayerLiked(PlayerLiking, PlayerBeingLiked)
        if PlayerBeingLiked ~= PlayerLiking and not HasPlayerLiked then
            ProfileLikesHandler.Like(PlayerLiking, PlayerBeingLiked)
        end
    end

    RemoveLikeRemote.OnServerInvoke = function(PlayerLiking, PlayerBeingUnliked)
        local HasPlayerLiked = ProfileLikesHandler.HasPlayerLiked(PlayerLiking, PlayerBeingUnliked)
        if PlayerBeingUnliked ~= PlayerLiking and HasPlayerLiked then
            ProfileLikesHandler.RemoveLike(PlayerLiking, PlayerBeingUnliked)
        end
    end

    HasPlayerLiked.OnServerInvoke = ProfileLikesHandler.HasPlayerLiked
end

function ProfileLikesHandler.Like(PlayerLiking, PlayerBeingLiked)
    local IsOnActionCooldown = ProfileLikesHandler.IsOnCooldown(PlayerLiking)
    if not IsOnActionCooldown then
        table.insert(ProfileLikesContainer[PlayerLiking], PlayerBeingLiked.UserId)
        SetUserCurrency:Invoke(PlayerBeingLiked, "Likes", 1, true)
        SetUserCurrency:Invoke(PlayerLiking, "LikesGiven", 1, true)
        ProfileLikesHandler.ApplyActionCooldown(PlayerLiking)
    end
end

function ProfileLikesHandler.RemoveLike(PlayerLiking, PlayerBeingUnliked)
    local IsOnActionCooldown = ProfileLikesHandler.IsOnCooldown(PlayerLiking)
    local ProfileLikesData = ProfileLikesContainer[PlayerLiking]
    if not IsOnActionCooldown then
        local Index = table.find(ProfileLikesData, PlayerBeingUnliked.UserId)
        if Index then
            table.remove(ProfileLikesContainer[PlayerLiking], Index)
        end
        SetUserCurrency:Invoke(PlayerBeingUnliked, "Likes", -1, true)
        SetUserCurrency:Invoke(PlayerLiking, "LikesGiven", -1, true)
        ProfileLikesHandler.ApplyActionCooldown(PlayerLiking)
    end
end

function ProfileLikesHandler.HasPlayerLiked(PlayerLiking, PlayerBeingLiked)
    local IndexFound = table.find(ProfileLikesContainer[PlayerLiking], PlayerBeingLiked.UserId)
    if IndexFound then
        return true
    else
        return false
    end
end

function ProfileLikesHandler.GetProfileLikesForPlayer(Player)
    local Data = nil

    local Successful, Error = pcall(function()
        Data = ProfileLikesDatastore:GetAsync(tostring(Player.UserId))
    end)

    if Successful then
        if Data == nil then
            return {}
        else
            return Data
        end
    else
        print("Error loading profile likes data for: ".. tostring(Player.UserId).. " '".. tostring(Error).. "'")
    end
end

function ProfileLikesHandler.IsOnCooldown(Player)
    local IndexFound = table.find(LikingCooldownContainer, Player)
    if IndexFound then
        return true
    else
        return false
    end
end

function ProfileLikesHandler.ApplyActionCooldown(Player)
    task.spawn(function()
        table.insert(LikingCooldownContainer, Player)
        task.wait(ActionCooldownDuration)
        local Index = table.find(LikingCooldownContainer, Player)
        if Index then
            table.remove(LikingCooldownContainer, Index)
        end
    end)
end


return ProfileLikesHandler