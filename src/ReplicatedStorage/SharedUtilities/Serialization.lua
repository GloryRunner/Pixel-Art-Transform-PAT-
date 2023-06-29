local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Grid = require(SharedUtilities:WaitForChild("Grid"))
local Drawing = require(ReplicatedStorage:WaitForChild("Drawings"):WaitForChild("Drawing"))

local Serialization = {}

function Serialization.SerializeColorMap(DrawingObject)
    local ColorMap = DrawingObject.ColorMap
    local Metadata = ColorMap.Metadata
    local RowCount, ColumnCount = Metadata.RowCount, Metadata.ColumnCount
    local SerializedColorMap = Grid.new(RowCount, ColumnCount)
    for Row = 1, RowCount do
        for Column = 1, ColumnCount do
            local PixelColor = ColorMap:GetCellValue(Row, Column, 1)
            if PixelColor then
                SerializedColorMap:SetCellValue(Row, Column, "Red", PixelColor.R)
                SerializedColorMap:SetCellValue(Row, Column, "Green", PixelColor.G)
                SerializedColorMap:SetCellValue(Row, Column, "Blue", PixelColor.B)
            end
        end
    end
    return SerializedColorMap
end

function Serialization.DeserializeColorMap(SerializedColorMap)
    local Metadata = SerializedColorMap.Metadata
    local RowCount, ColumnCount = Metadata.RowCount, Metadata.ColumnCount
    local DeserializedDrawing = Drawing.new(RowCount, ColumnCount)

    for Row = 1, RowCount do
        for Column = 1, ColumnCount do
            local Red = SerializedColorMap.GridMap[Row][Column]["Red"]
            local Green = SerializedColorMap.GridMap[Row][Column]["Green"]
            local Blue = SerializedColorMap.GridMap[Row][Column]["Blue"]
            local Color = Color3.new(Red, Green, Blue)
            if Red and Green and Blue then
                DeserializedDrawing:ColorPixel(Row, Column, Color)
            end
        end
    end
    return DeserializedDrawing
end

return Serialization