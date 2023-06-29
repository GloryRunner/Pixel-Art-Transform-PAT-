local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IDs = require(script.Parent.IDs)
local GridSizeUnlockIDs = IDs.DeveloperProducts.GridSizeUnlock

local GridSizes = {}

-- PurchasePriority is organized by ascending order with 1 being the lowest.
GridSizes.Constants = {
    {
        RowCount = 9,
        ColumnCount = 9,
        RequiredLevel = 1,
        FrameName = "1.9",
        ProductId = nil,
        PurchasePriority = 0,
        CurrencyName = nil
    },
    {
        RowCount = 11,
        ColumnCount = 11,
        RequiredLevel = 5,
        FrameName = "2.11",
        ProductId = GridSizeUnlockIDs["11x11"],
        PurchasePriority = 1,
        CurrencyName = "Purchased11x11Unlock"
    },
    {
        RowCount = 13,
        ColumnCount = 13,
        RequiredLevel = 10,
        FrameName = "3.13",
        ProductId = GridSizeUnlockIDs["13x13"],
        PurchasePriority = 2,
        CurrencyName = "Purchased13x13Unlock"
    },
    {
        RowCount = 15,
        ColumnCount = 15,
        RequiredLevel = 15,
        FrameName = "4.15",
        ProductId = GridSizeUnlockIDs["15x15"],
        PurchasePriority = 3,
        CurrencyName = "Purchased15x15Unlock"
    },
    {
        RowCount = 17,
        ColumnCount = 17,
        RequiredLevel = 25,
        FrameName = "5.17",
        ProductId = GridSizeUnlockIDs["17x17"],
        PurchasePriority = 4,
        CurrencyName = "Purchased17x17Unlock"
    }
}

return GridSizes