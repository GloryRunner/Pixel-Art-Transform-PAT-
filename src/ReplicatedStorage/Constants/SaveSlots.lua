local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IDs = require(script.Parent.IDs)
local SaveSlotUnlockIDs = IDs.DeveloperProducts.SaveSlotUnlock
local SharedUtilities = ReplicatedStorage.SharedUtilities
local GetUserCurrency = ReplicatedStorage:WaitForChild("GetUserCurrency")
local Levels = require(SharedUtilities.Levels)

local SaveSlots = {}
SaveSlots.RegularSlots = {
    {
        RequiredLevel = 1,
        FrameName = "Slot1",
        ProductId = nil,
        PurchasePriority = 0,
        CurrencyName = nil
    },
    {
        RequiredLevel = 1,
        FrameName = "Slot2",
        ProductId = nil,
        PurchasePriority = 0,
        CurrencyName = nil
    },
    {

        RequiredLevel = 5,
        FrameName = "Z.Slot3",
        ProductId = SaveSlotUnlockIDs["Lvl5"],
        PurchasePriority = 1,
        CurrencyName = "PurchasedLvl5SaveSlotUnlock"
    },
    {

        RequiredLevel = 15,
        FrameName = "Z.Slot4",
        ProductId = SaveSlotUnlockIDs["Lvl15"],
        PurchasePriority = 2,
        CurrencyName = "PurchasedLvl15SaveSlotUnlock"
    },
    {
        RequiredLevel = 25,
        FrameName = "Z.Slot5",
        ProductId = SaveSlotUnlockIDs["Lvl25"],
        SpecialRequirement = nil,
        CurrencyName = "PurchasedLvl25SaveSlotUnlock"
    }
}

SaveSlots.GroupSlot = {
    FrameName = "SlotGroup",
    HasUnlocked = function(Player)
        local GroupService = game:GetService("GroupService")
        local MainGroupId = IDs["7Wapy"]
        for _, GroupData in ipairs(GroupService:GetGroupsAsync(Player.UserId)) do
            local GroupId = GroupData.Id
            if GroupId == MainGroupId then
                return true
            end
        end
        return false
    end
}

return SaveSlots