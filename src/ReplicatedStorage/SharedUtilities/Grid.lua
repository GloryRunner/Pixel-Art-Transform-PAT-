local Grid = {}
Grid.__index = Grid

function Grid.new(RowCount, ColumnCount)
    local GridObject = setmetatable({}, Grid)
    GridObject.GridMap = {}
    GridObject.Metadata = {
        ["RowCount"] = RowCount,
        ["ColumnCount"] = ColumnCount
    }
    for Row = 1, RowCount do
        GridObject.GridMap[Row] = {}
        for Column = 1, ColumnCount do
            GridObject.GridMap[Row][Column] = {}
        end
    end
    return GridObject
end

function Grid:IsValidCell(Row, Column)
    local Metadata = self.Metadata
    local RowCount = Metadata.RowCount
    local ColumnCount = Metadata.ColumnCount
    if Row <= RowCount and Row >= 1 then
        if Column <= ColumnCount and Column >= 1 then
            return true
        end
    end
    return false
end

function Grid:SetCellValue(Row, Column, Index, Value)
    if self:IsValidCell(Row, Column) then
        self.GridMap[Row][Column][Index] = Value
    end
end

function Grid:GetCellValue(Row, Column, Index)
    local CellValue = nil
    if self:IsValidCell(Row, Column) then
        CellValue = self.GridMap[Row][Column][Index]
    end
    return CellValue
end

function Grid:ClearCellValue(Row, Column, Index)
    if self:IsValidCell(Row, Column) then
        self.GridMap[Row][Column][Index] = nil
    end
end

function Grid:ClearAllCells(Index)
    local Metadata = self.Metadata
    local RowCount = Metadata.RowCount
    local ColumnCount = Metadata.ColumnCount
    for Row = 1, RowCount do
        for Column = 1, ColumnCount do
            self:ClearCellValue(Row, Column, Index)
        end
    end
end

function Grid:Destroy()
    self = nil
end

return Grid