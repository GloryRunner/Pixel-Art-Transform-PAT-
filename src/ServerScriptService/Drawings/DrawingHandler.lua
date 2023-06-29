local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DrawingRemotes = ReplicatedStorage.DrawingRemotes
local MorphRemote = DrawingRemotes.Morph
local OnDrawingMenuOpened = DrawingRemotes.OnDrawingMenuOpened
local OnDrawingMenuClosed = DrawingRemotes.OnDrawingMenuClosed

local MorphOverheadTags = ServerStorage.MorphOverheadTags
local DrawingIconTemplate = MorphOverheadTags.DrawingIcon

local Utilities = script.Parent.Parent.Utilities
local Constants = ReplicatedStorage.Constants
local SharedUtilities = ReplicatedStorage.SharedUtilities

local GridSizes = require(Constants.GridSizes)
local IDs = require(Constants.IDs)
local GameplayConstants = require(Constants.Gameplay)
local Morph = require(script.Parent.Morph)
local Serialization = require(ReplicatedStorage.SharedUtilities.Serialization)
local TextFiltering = require(Utilities.TextFiltering)
local Levels = require(SharedUtilities.Levels)

local GetUserCurrency = ReplicatedStorage:WaitForChild("GetUserCurrency")

local UnmorphedDrawingIconOffset = Vector3.new(0, 3, 0)
local MaximumRoleplayNameLength = 20

local ActivePlayerMorphs = {}

local function IsStringBlank(String)
    if not String:match("^%s*$") then
        return false
    else
        return true
    end
end

local DrawingHandler = {}

function DrawingHandler.Init()
    Players.PlayerAdded:Connect(function(Player)
        Player.CharacterAdded:Connect(function(Character)
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart then
                local DrawingIconClone = DrawingIconTemplate:Clone()
                DrawingIconClone.StudsOffset = UnmorphedDrawingIconOffset
                DrawingIconClone.Enabled = false
                DrawingIconClone.Parent = HumanoidRootPart
            end
        end)
    end)

    OnDrawingMenuOpened.OnServerEvent:Connect(function(Player)
        local Character = Player.Character
        if Character then
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart then
                local DrawingIcon = HumanoidRootPart:FindFirstChild("DrawingIcon")
                if DrawingIcon then
                    DrawingIcon.Enabled = true
                end
            end
        end
    end)

    OnDrawingMenuClosed.OnServerEvent:Connect(function(Player)
        local Character = Player.Character
        if Character then
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart then
                local DrawingIcon = HumanoidRootPart:FindFirstChild("DrawingIcon")
                if DrawingIcon then
                    DrawingIcon.Enabled = false
                end
            end
        end
    end)

    -- Going to serialize drawing on client and deserialize on server because objects can't be passed through remotes
    MorphRemote.OnServerInvoke = function(Player, SerializedColorMap, RoleplayName)
        local Character = Player.Character
        local Drawing = Serialization.DeserializeColorMap(SerializedColorMap)
        local IsRoleplayNameBlank = IsStringBlank(RoleplayName)
        local MaximumRoleplayNameLength = GameplayConstants.MaximumRoleplayNameLength
        local IsValidDrawing = DrawingHandler.IsValidDrawing(Player, Drawing)
        if IsValidDrawing then  
            if IsRoleplayNameBlank then
                RoleplayName = Player.DisplayName
            else
                RoleplayName = string.sub(RoleplayName, 1, MaximumRoleplayNameLength)
            end
            local FilteredRoleplayName = TextFiltering.FilterUntargetedText(RoleplayName, Player)
    
            if Character then
                local IsPlayerMorphed = ActivePlayerMorphs[Player]
                if IsPlayerMorphed then
                    DrawingHandler.ClearExistingMorph(Player)
                end
                local MorphObject = Morph.new(Drawing, Character, FilteredRoleplayName)
                MorphObject:Transform()
                ActivePlayerMorphs[Player] = MorphObject
            end
        else
            Player:Kick("Exploits detected")
        end
    end
end

function DrawingHandler.IsValidDrawing(Player, Drawing)
    local ColorMap = Drawing.ColorMap
    local GridMap = ColorMap.GridMap
    local Metadata = ColorMap.Metadata
    local RowCount, ColumnCount = Metadata.RowCount, Metadata.ColumnCount

    local function AreSupportedGridDimensions(Rows, Columns)
        local Valid = false
        for _, GridSizeData in ipairs(GridSizes.Constants) do
            local GridSizeRowCount = GridSizeData.RowCount
            local GridSizeColumnCount = GridSizeData.ColumnCount
            if GridSizeRowCount == Rows and GridSizeColumnCount == Columns then
                Valid = true
            end
        end
        return Valid
    end

    local function HasAccessToGridDimensions(Rows, Columns)
        local CurrentXP = GetUserCurrency:Invoke(Player, "XP")
        local CurrentLevel = Levels.GetLevelFromXP(CurrentXP)
        for _, GridSizeData in ipairs(GridSizes.Constants) do
            local GridSizeRowCount = GridSizeData.RowCount
            local GridSizeColumnCount = GridSizeData.ColumnCount
            local RequiredLevel = GridSizeData.RequiredLevel
            local GridSizeCurrencyName = GridSizeData.CurrencyName
            if GridSizeRowCount == Rows and GridSizeColumnCount == Columns then
                if RequiredLevel > 1 then
                    local PurchasedInstantUnlock = GetUserCurrency:Invoke(Player, GridSizeCurrencyName) == 1
                    if CurrentLevel >= RequiredLevel or PurchasedInstantUnlock then
                        return true
                    end
                else
                    return true
                end
            end
        end
        return false
    end

    if Drawing and ColorMap and RowCount and ColumnCount and GridMap then
        if typeof(ColorMap) ~= "table" or typeof(RowCount) ~= "number" or typeof(ColumnCount) ~= "number" then
            return false
        end

        local SupportedGridDimensions = AreSupportedGridDimensions(RowCount, ColumnCount)
        if not SupportedGridDimensions then
            return false
        else
            local HasAccessToGridDimensions = HasAccessToGridDimensions(RowCount, ColumnCount)
            if not HasAccessToGridDimensions then
                return false
            end
        end

        -- Checking for uniform grid dimensions.
        for Row = 1, RowCount do
            local RowObjectCount = #ColorMap.GridMap[Row] 
            if RowObjectCount ~= ColumnCount then
                return false
            end
        end

        if #ColorMap.GridMap ~= RowCount then
            return false
        end

        
        for Row = 1, RowCount do
            if typeof(ColorMap.GridMap[Row]) ~= "table" then
                return false
            end
            for Column = 1, ColumnCount do
                if typeof(ColorMap.GridMap[Row][Column]) ~= "table" then
                    return false
                end
                local ColorObjectStored = ColorMap:GetCellValue(Row, Column, 1)
                if ColorObjectStored and typeof(ColorObjectStored) ~= "Color3" then
                    return false
                end
            end
        end 
    else
        return false
    end
    return true
end

function DrawingHandler.ClearExistingMorph(Player)
    local ActiveMorph = ActivePlayerMorphs[Player]
    ActiveMorph:Destroy()
    ActivePlayerMorphs[Player] = nil
end

return DrawingHandler