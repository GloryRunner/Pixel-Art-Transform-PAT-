local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ProfileService = require(script.Parent.ProfileService)

local PlayerDataRemotes = ReplicatedStorage.PlayerDataRemotes

local SetPlayerData = PlayerDataRemotes.SetPlayerData
local GetPlayerData = PlayerDataRemotes.GetPlayerData
local IsDataLoaded = PlayerDataRemotes.IsDataLoaded

local LoadedProfiles = {}
local ProfileTemplate = {
	["Statistics"] = {
		["XP"] = 0,
		["Coins"] = 0,
		["CoinsGifted"] = 0,
		["Likes"] = 0,
		["LikesGiven"] = 0,
		["Playtime"] = 0,
		["PixelsCreatedCount"] = 0,
		["ColorsOwnedCount"] = 0,
		["WinCount"] = 0
	},
	["InstantUnlockPurchases"] = {
		["GridSizes"] = {
			["11x11"] = false,
			["13x13"] = false,
			["15x15"] = false,
			["17x17"] = false
		},
		["SaveSlots"] = {
			["Lvl5Slot"] = false,
			["Lvl15Slot"] = false,
			["Lvl25Slot"] = false
		}
	}
}

-- Production Profile Store Name: "PlayerData"

local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

local Profiles = {}

function Profiles.Init()
	for _, Player in ipairs(Players:GetPlayers()) do
		task.spawn(Profiles.OnPlayerAdded, Player)
	end

	Players.PlayerAdded:Connect(Profiles.OnPlayerAdded)
	Players.PlayerRemoving:Connect(function(Player)
		local Profile = LoadedProfiles[Player]
		if Profile then
			Profile:Release()
		end
	end)
	SetPlayerData.OnInvoke = Profiles.SetPlayerData
	GetPlayerData.OnInvoke = Profiles.GetPlayerData
	IsDataLoaded.OnInvoke = function(Player)
		local Profile = LoadedProfiles[Player]
		if Profile then
			return Profile:IsActive()
		else
			return false
		end
	end
end

function Profiles.OnPlayerAdded(Player)
	local Profile = ProfileStore:LoadProfileAsync("Player_" .. Player.UserId)
	if Profile then
		Profile:AddUserId(Player.UserId)
		Profile:Reconcile()
		Profile:ListenToRelease(function()
			LoadedProfiles[Player] = nil
			Player:Kick("Profile released unexpectedly")
		end)

		if Player:IsDescendantOf(Players) then
			LoadedProfiles[Player] = Profile
		else
			-- Player left before the profile loaded:
			Profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		Player:Kick("Detected multiple game instances")
	end
end

function Profiles.SetPlayerData(Player, Index, NewValue)
	local Profile = LoadedProfiles[Player]
	
	if Profile then
		local Value
		Index = tostring(Index)

		local function Loop(Table, Index)
			for i,v in pairs(Table) do
				local index = tostring(i)
				if index == Index then
					Table[index] = NewValue
					return
				elseif index ~= Index and typeof(v) == "table" then
					Loop(v, Index)
				end
			end
		end

		Loop(Profile.Data, Index)
	end
end

function Profiles.GetPlayerData(Player, DataName)
	local Profile = LoadedProfiles[Player]
	if Profile then
		local Value
		DataName = tostring(DataName)

		local function Loop(Table, DataName)
			if Value then return end
			for i,v in pairs(Table) do
				local index = tostring(i)
				if index == DataName then 
					Value = v
					return
				elseif index ~= DataName and typeof(v) == "table" then
					Loop(v, DataName)
				end
			end
		end

		Loop(Profile.Data, DataName)

		return Value
	end
end

return Profiles