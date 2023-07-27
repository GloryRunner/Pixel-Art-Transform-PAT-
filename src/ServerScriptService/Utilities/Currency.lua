local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Leaderstats = require(script.Parent.Leaderstats)
local Levels = require(ReplicatedStorage.SharedUtilities.Levels)

local CurrencyDatastore = DataStoreService:GetDataStore("Currency")

local MAX_SAVE_ATTEMPTS = 2

--[[

CurrencyName = {
    InitialValue : number -- The default value a player is assigned if they've never joined the game before.
    DisplayOnLeaderboard : boolean -- Determines if a currency value should be displayed on leaderstats.
    SaveToDS : boolean -- Determines if a currency value should be saved when a player leaves or the server is shutdown.
    LeaderstatsPos : number -- Determines the position of a currency value if DisplayOnLeaderboard = true. These are ordered from left to right in ascending order with 1 being the value furthest to the left.
    DatastoreName : string -- The key the currency type is stored under in the DataStore dictionary.
}

]]

local CurrencyTypes = {
    XP = {
        InitialValue = Levels.GetXPFromLevel(5),
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "XPStoretdw32323est90" -- XPStoretest90
    },
    Coins = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "CoinsStore1"
    },
    CoinsGifted = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "CoinsGiftedStore1"
    },
    Likes = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "LikesStore1"
    },
    LikesGiven = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "LikesGivenStore1"
    },
    Playtime = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "PlaytimeStore1"
    },
    PixelsCreatedCount = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "PixelsCreatedCountStore1"
    },
    ColorsOwnedCount = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "ColorsOwnedCountStore1"
    },
    WinCount = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "WinCountStore1"
    },

    -- For the instant unlocks, 0 represents false, while 1 represents true.
    Purchased11x11Unlock = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "Purchased11xdwdw11UnlockStore1" -- Purchased11x11UnlockStore1
    },
    Purchased13x13Unlock = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "Purchased13xdwd13UnlockStore1" -- Purchased13x13UnlockStore1
    },
    Purchased15x15Unlock = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "Purchased15x1dwd5UnlockStore1" -- Purchased15x15UnlockStore1
    },
    Purchased17x17Unlock = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "Purchased17xdwd17UnlockStore1" -- Purchased17x17UnlockStore1
    },
    PurchasedLvl5SaveSlotUnlock = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "PurchasedLvl5SaveSlotUnlock" -- PurchasedLvl5SaveSlotUnlock
    },
    PurchasedLvl15SaveSlotUnlock = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "PurchasedLvl15SaveSlotUnlock" -- PurchasedLvl15SaveSlotUnlock
    },
    PurchasedLvl25SaveSlotUnlock = {
        InitialValue = 0,
        DisplayOnLeaderboard = false,
        SaveToDS = true,
        LeaderstatsPos = nil,
        DatastoreName = "PurchasedLvl25SaveSlotUnlock" -- PurchasedLvl25SaveSlotUnlock
    }
}

local Communicators = {
    GetUserCurrencyFunction = Instance.new("BindableFunction"), -- Server -> Server
    SetUserCurrencyFunction = Instance.new("BindableFunction"), -- Server -> Server
    OnUserCurrencyChangeEvent = Instance.new("BindableEvent"), -- Server -> Server
    GetPlayerCurrencyFunction = Instance.new("RemoteFunction"), -- Server -> Client
    OnCurrencyChangeEvent = Instance.new("RemoteEvent"), -- Server -> Client
}

local PlayerCurrencyCache = {}

local Currency = {}

function Currency.Init()

    --[[
    I'm aware that there are redundant functions like GetUserCurrency as a BindableFunction and GetPlayerCurrencyFunction as a RemoteFunction.
    This module, when written, didn't intend to expose a given user's player data to all players. This data module is going to be independent of the pixel
    saving module because of the reasons mentioned above, but also because saving pixels/drawings requires a distinct process that includes data serialization.
    ]]

    Communicators.GetUserCurrencyFunction.Name = "GetUserCurrency"
    Communicators.SetUserCurrencyFunction.Name = "SetUserCurrency"
    Communicators.GetPlayerCurrencyFunction.Name = "GetPlayerCurrency"
    Communicators.OnCurrencyChangeEvent.Name = "OnCurrencyChange" -- Accessed by client
    Communicators.OnUserCurrencyChangeEvent.Name = "OnUserCurrencyChangeEvent" -- Accessed by server

    Communicators.GetUserCurrencyFunction.OnInvoke = Currency.GetPlayerCurrency
    Communicators.SetUserCurrencyFunction.OnInvoke = Currency.SetPlayerCurrency
    Communicators.GetPlayerCurrencyFunction.OnServerInvoke = function(Player, RequestedPlayer, CurrencyName)
        local PlayerExists = Players:FindFirstChild(RequestedPlayer.Name)
        if PlayerExists then
            return Currency.GetPlayerCurrency(RequestedPlayer, CurrencyName)
        end
    end

    for _, Communicator in pairs(Communicators) do
        Communicator.Parent = ReplicatedStorage
    end

    Players.PlayerAdded:Connect(function(Player)
        task.spawn(Currency.OnPlayerJoin, Player)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        task.spawn(Currency.OnPlayerLeave, Player)
    end)

    game:BindToClose(function()
        for _, Player in ipairs(Players:GetPlayers()) do
            task.spawn(Currency.OnPlayerLeave, Player)
        end
    end)
end

function Currency.GetDataFromDS(Player)
    local SavedData = nil
    local GotDataSuccesfully, Error = pcall(function()
		SavedData = CurrencyDatastore:GetAsync(tostring(Player.UserId))
    end)

    if not GotDataSuccesfully then
        Player:Kick("Currency data failed to load. Error: ".. tostring(Error))
    end

    return SavedData, GotDataSuccesfully
end

function Currency.CachePlayerData(Player)
    local SavedData, GotDataSuccesfully = Currency.GetDataFromDS(Player)
    local CachedData = {}

	if GotDataSuccesfully then
		if SavedData == nil then
			SavedData = {}
		end
		
        for CurrencyName, CurrencyData in pairs(CurrencyTypes) do
			local DatastoreName = CurrencyData["DatastoreName"]
            local DataIndexFoundInDS = SavedData[DatastoreName] ~= nil and true or false
            local CurrencyValueFoundInDS = SavedData[DatastoreName]
            -- Checks if the player has data under the current datastore names.
            if DataIndexFoundInDS then
                CachedData[CurrencyName] = CurrencyValueFoundInDS
            else
                CachedData[CurrencyName] = CurrencyData["InitialValue"]
            end 
		end
        PlayerCurrencyCache[Player] = CachedData
    end
end

function Currency.RemoveCachedData(Player)
    PlayerCurrencyCache[Player] = nil
end

function Currency.GetPlayerCurrency(Player, CurrencyName)
    assert(CurrencyTypes[CurrencyName] ~= nil, "Currency not supported")
    repeat task.wait() until PlayerCurrencyCache[Player]
    return PlayerCurrencyCache[Player][CurrencyName]
end

function Currency.SaveCachedDataToDS(Player)
    -- Gets the stored data, modifies the dictionary according to the current datastore names and their values, and then stores it.
    local Key = tostring(Player.UserId)
    local SavedData, GotDataSuccesfully = Currency.GetDataFromDS(Player)
    local SaveSuccessful = false

	if GotDataSuccesfully then
		if SavedData == nil then
			SavedData = {}
		end
		
        for CurrencyName, CurrencyData in pairs(CurrencyTypes) do
            local CurrencyDatastoreName = CurrencyData["DatastoreName"]
            local SaveToDS = CurrencyData["SaveToDS"]
            if SaveToDS then
                if CurrencyDatastoreName ~= nil then
                    SavedData[CurrencyDatastoreName] = Currency.GetPlayerCurrency(Player, CurrencyName)
                else
                    error("SaveToDS is enabled for currency: ".. CurrencyName.. ", but DatastoreName has not been set")
                end
            end
        end

        SaveSuccessful = pcall(function()
            CurrencyDatastore:SetAsync(Key, SavedData)
        end)
    end
    return SaveSuccessful
end

function Currency.SetPlayerCurrency(Player, CurrencyName, Amount, ShouldIncrement)
    assert(CurrencyTypes[CurrencyName] ~= nil, "Currency not supported")
    assert(typeof(Amount) == "number", "Passed 'amount' must be of type: number")
    assert(Amount ~= nil, "Amount cannot be nil")

    ShouldIncrement = ShouldIncrement or false

    local NewCurrencyAmount = ShouldIncrement and Currency.GetPlayerCurrency(Player, CurrencyName) + Amount or Amount
    local DisplayOnLeaderboard = CurrencyTypes[CurrencyName]["DisplayOnLeaderboard"]
    
    PlayerCurrencyCache[Player][CurrencyName] = NewCurrencyAmount

    if DisplayOnLeaderboard then
        Leaderstats.ChangeValue(Player, CurrencyName, NewCurrencyAmount)
    end

    Communicators.OnCurrencyChangeEvent:FireClient(Player, CurrencyName, NewCurrencyAmount)
    Communicators.OnUserCurrencyChangeEvent:Fire(Player, CurrencyName, NewCurrencyAmount)
end

function Currency.OnPlayerJoin(Player)
    local NumberOfLeaderstatsValues = 0
    local CreationOrder = {}
    Currency.CachePlayerData(Player)
    Leaderstats.CreateLeaderstats(Player)
    for CurrencyName, CurrencyData in pairs(CurrencyTypes) do
        local DisplayOnLeaderboard = CurrencyData["DisplayOnLeaderboard"]
        local LeaderstatsPos = CurrencyData["LeaderstatsPos"]
        local FoundExistingValueAtPos = CreationOrder[tostring(LeaderstatsPos)] and true or false
        if DisplayOnLeaderboard then
            --assert(LeaderstatsPos ~= nil, "DisplayOnLeaderboard is enabled for currency: ".. CurrencyName.. ", but 'LeaderstatsPos' has not been set")
            --assert(typeof(LeaderstatsPos) == "number", "LeaderstatsPos for object: ".. CurrencyName.. " must be a number")
            --assert(FoundExistingValueAtPos == true, "Multiple objects with the same 'LeaderstatsPos' detected")
            
            if not FoundExistingValueAtPos then
                CreationOrder[tostring(LeaderstatsPos)] = CurrencyName
                NumberOfLeaderstatsValues += 1
            end
        end
    end

    for i = 1, NumberOfLeaderstatsValues do
        local CurrencyName = CreationOrder[tostring(i)]
        local CurrencyValue = Currency.GetPlayerCurrency(Player, CurrencyName)
        Leaderstats.CreateValue(Player, CurrencyName, CurrencyValue)
    end
end

function Currency.OnPlayerLeave(Player)
    local HasDataInitialized = PlayerCurrencyCache[Player] ~= nil and true or false -- used to prevent overwriting user data if there was an error getting data upon join and this could get called if playerremoving is fired
    if HasDataInitialized then
        for i = 1, MAX_SAVE_ATTEMPTS do
            local SaveSuccesful = Currency.SaveCachedDataToDS(Player)
            if SaveSuccesful then break end
        end
        Currency.RemoveCachedData(Player)
    end
end

return Currency