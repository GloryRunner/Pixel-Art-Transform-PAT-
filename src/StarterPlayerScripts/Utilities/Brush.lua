local CanvasPixelFrameIndex = 1

local Brush = {}
Brush.__index = Brush

function Brush.new(Size, Canvas)
    local BrushData = setmetatable({}, Brush)
    BrushData.Size = Size
    BrushData.Canvas = Canvas
    return BrushData
end

function Brush:SetCanvas(Canvas)
    self.Canvas = Canvas
end

function Brush:SetSize(Size)
    self.Size = Size
end

function Brush:GetSpannedPixels(AnchorRow, AnchorColumn)
    local BrushSize = self.Size
    local SpannedPixels = {}
    if BrushSize > 1 then
        BrushSize -= 1

        local CanvasMetadata = self.Canvas.Metadata
        local CanvasRowCount = CanvasMetadata.RowCount

        local StartColumn = AnchorColumn - BrushSize
        local EndColumn = AnchorColumn + BrushSize
        local StartRow = AnchorRow - BrushSize
        local EndRow = AnchorRow + BrushSize

        for Row = StartRow, EndRow do
            for Column = StartColumn, EndColumn do
                local PixelFrame = self.Canvas:GetCellValue(Row, Column, CanvasPixelFrameIndex)
                if PixelFrame then
                    table.insert(SpannedPixels, {
                        ["Row"] = Row,
                        ["Column"] = Column,
                        ["PixelFrame"] = PixelFrame
                    })
                end
            end
        end
    else
        table.insert(SpannedPixels, {
            ["Row"] = AnchorRow,
            ["Column"] = AnchorColumn,
            ["PixelFrame"] = self.Canvas:GetCellValue(AnchorRow, AnchorColumn, CanvasPixelFrameIndex)
        })
    end
    return SpannedPixels
end

function Brush:Destroy()
    self = nil
end

return Brush