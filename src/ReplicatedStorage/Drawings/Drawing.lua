local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedUtilities = ReplicatedStorage:WaitForChild("SharedUtilities")
local Grid = require(SharedUtilities:WaitForChild("Grid"))

local Drawing = {}
Drawing.__index = Drawing

function Drawing.new(RowCount, ColumnCount)
    local DrawingObject = setmetatable({}, Drawing)
    DrawingObject.ColorMap = Grid.new(RowCount, ColumnCount)
    return DrawingObject
end

function Drawing:ColorPixel(Row, Column, Color)
    self.ColorMap:SetCellValue(Row, Column, 1, Color)
end

function Drawing:ErasePixel(Row, Column)
    self.ColorMap:ClearCellValue(Row, Column, 1)
end

function Drawing:GetPixelColor(Row, Column)
    return self.ColorMap:GetCellValue(Row, Column, 1)
end

function Drawing:Clear()
    self.ColorMap:ClearAllCells(1)
end

function Drawing:Destroy()
    self = nil
end

return Drawing
