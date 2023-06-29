-- morph controller will handle removing the previous morph
-- Current Pixl game resets morph on death. Not sure if we should do the same or not for QOL purposes.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MorphOverheadTags = ServerStorage.MorphOverheadTags
local RoleplayNameTemplate = MorphOverheadTags.RoleplayName

local DrawingRemotes = ReplicatedStorage.DrawingRemotes
local OnPlayerMorphed = DrawingRemotes.OnPlayerMorphed

local MorphSize = UDim2.fromScale(5, 4.5)
local PixelOrigin = UDim2.fromScale(0, 0)
local PixelPadding = UDim2.fromScale(0, 0)

local RoleplayNameOffset = Vector3.new(0, -1.5, 0)
local DrawingIconOffset = Vector3.new(0, 5, 0)

local function GetPixelSize(MorphFrame, RowCount, ColumnCount)
    local SizeX, SizeY
    
    if RowCount <= 0 or RowCount - 1 <= 0 then
        SizeY = MorphFrame.AbsoluteSize.Y
    else
        SizeY = MorphFrame.AbsoluteSize.Y / RowCount
    end
    
    if ColumnCount <= 0 or ColumnCount - 1 <= 0 then
        SizeX = MorphFrame.AbsoluteSize.X
    else
        SizeX = MorphFrame.AbsoluteSize.X / ColumnCount
    end
    
    return UDim2.fromOffset(SizeX, SizeY)
end

local Morph = {}
Morph.__index = Morph

function Morph.new(DrawingObject, Character, RoleplayName)
    local MorphObject = setmetatable({}, Morph)
    MorphObject.Metadata = {
        ["RoleplayName"] = RoleplayName,
        ["Character"] = Character
    }

    local ColorMap = DrawingObject.ColorMap
    local ColorMapMetadata = ColorMap.Metadata
    local DrawingRowCount, DrawingColumnCount = ColorMapMetadata.RowCount, ColorMapMetadata.ColumnCount

    local MorphGui = Instance.new("BillboardGui")
    MorphGui.Name = "MorphGui"
    MorphGui.AlwaysOnTop = false
    MorphGui.ResetOnSpawn = false
    MorphGui.Size = MorphSize

    local BackgroundFrame = Instance.new("Frame")
    BackgroundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    BackgroundFrame.Size = UDim2.fromScale(1, 1)
    BackgroundFrame.Position = UDim2.fromScale(0.5, 0.5)
    BackgroundFrame.BorderSizePixel = 0
    BackgroundFrame.BackgroundTransparency = 1
    BackgroundFrame.BackgroundColor3 = Color3.new(255, 255, 255)
    BackgroundFrame.Visible = false
    BackgroundFrame.Parent = MorphGui

    local UIGridLayout = Instance.new("UIGridLayout")
    UIGridLayout.CellPadding = PixelPadding
    UIGridLayout.CellSize = UDim2.fromScale(1 / DrawingColumnCount, 1 / DrawingRowCount)
    UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    UIGridLayout.StartCorner = Enum.StartCorner.TopLeft
    UIGridLayout.FillDirection = Enum.FillDirection.Horizontal
    UIGridLayout.FillDirectionMaxCells = DrawingColumnCount
    UIGridLayout.Parent = BackgroundFrame

    local RoleplayNameGui = RoleplayNameTemplate:Clone()
    local RoleplayNameText = RoleplayNameGui:WaitForChild("Text")

    local DrawingMetadata = DrawingObject.ColorMap.Metadata
    local DrawingRowCount, DrawingColumnCount = DrawingMetadata.RowCount, DrawingMetadata.ColumnCount 
   
    RoleplayNameGui.StudsOffset = RoleplayNameOffset

    RoleplayNameText.Text = RoleplayName
    RoleplayNameText.Visible = true

    MorphObject.Drawing = DrawingObject
    MorphObject.RoleplayNameGui = RoleplayNameGui
    MorphObject.MorphGui = MorphGui

    for Row = 1, DrawingRowCount do
        task.spawn(function()
            for Column = 1, DrawingColumnCount do
                local Pixel = Instance.new("Frame")
                local PixelColor = DrawingObject:GetPixelColor(Row, Column)
                Pixel.Size = GetPixelSize(BackgroundFrame, DrawingRowCount, DrawingColumnCount)
                Pixel.BorderSizePixel = 0
                
                if PixelColor then
                    Pixel.BackgroundColor3 = PixelColor
                else
                    Pixel.BackgroundTransparency = 1
                end
    
                Pixel.Parent = BackgroundFrame
            end

            if Row == DrawingRowCount then
                task.delay(0.05, function()
                    BackgroundFrame.Visible = true
                end)
            end
        end)
    end

    return MorphObject
end

function Morph:Transform()
    local Character = self.Metadata.Character
    if Character then
        for _, Descendant in ipairs(Character:GetDescendants()) do
            if Descendant:IsA("BasePart") then
                if Descendant.Parent then
                    if Descendant.Parent.Name ~= "Sign" then
                        Descendant.Transparency = 1
                    end
                else
                    Descendant.Transparency = 1
                end
            elseif Descendant:IsA("Accessory") or Descendant.Name == "face" then
                Descendant:Destroy()
            end
        end
    
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        if HumanoidRootPart then
            self.MorphGui.Parent = HumanoidRootPart
            self.RoleplayNameGui.Parent = HumanoidRootPart
    
            local DrawingIcon = HumanoidRootPart:FindFirstChild("DrawingIcon")
            if DrawingIcon then
                DrawingIcon.StudsOffset = DrawingIconOffset
            end
        end

        local Player = Players:GetPlayerFromCharacter(Character) 
        OnPlayerMorphed:FireAllClients(Player, self.MorphGui)
    end
end

function Morph:Destroy()
    self.RoleplayNameGui:Destroy()
    self.MorphGui:Destroy()
    self = nil
end

return Morph