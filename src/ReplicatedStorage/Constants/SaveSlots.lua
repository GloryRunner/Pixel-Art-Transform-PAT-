local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IDs = require(script.Parent.IDs)
local InstantLevelIDs = IDs.DeveloperProducts.InstantLevels

local SaveSlots = {}

-- I'm aware that I'm copying code from the GridSizes module. Just trying to get this done quickly.


-- PurchasePriority is organized by ascending order with 1 being the lowest.
SaveSlots.Constants = {
    {
        FrameName = "Z.Slot3",
        RequiredLevel = 5,
        --ProductId = InstantLevelIDs["5"],
        PurchasePriority = 1
    },
    {
        FrameName = "Z.Slot4",
        RequiredLevel = 15,
        --ProductId = InstantLevelIDs["15"],
        PurchasePriority = 2
    },
    {
        FrameName = "Z.Slot5",
        RequiredLevel = 25,
        --ProductId = InstantLevelIDs["25"],
        PurchasePriority = 3
    },
}

return SaveSlots