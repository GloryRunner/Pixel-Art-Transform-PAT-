local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IDs = require(script.Parent.IDs)
local SaveSlotUnlockIDs = IDs.DeveloperProducts.SaveSlotUnlock
local SharedUtilities = ReplicatedStorage.SharedUtilities
local GetUserCurrency = ReplicatedStorage:WaitForChild("GetUserCurrency")
local Levels = require(SharedUtilities.Levels)

local SaveSlots = {}
SaveSlots.Constants = {
    {
        RequiredLevel = 1,
        FrameName = "Slot1",
        UnlockProductId = nil,
        SpecialRequirement = nil,
        CurrencyName = nil
    },
    {
        RequiredLevel = 1,
        FrameName = "Slot2",
        UnlockProductId = nil,
        SpecialRequirement = nil,
        CurrencyName = nil
    },
    {
        RequiredLevel = 1,
        FrameName = "SlotGroup",
        UnlockProductId = nil,
        SpecialRequirement = function(Player)
            local GroupService = game:GetService("GroupService")
            local MainGroupId = IDs["7Wapy"]
            for _, GroupData in ipairs(GroupService:GetGroupsAsync(Player.UserId)) do
                local GroupId = GroupData.Id
                if GroupId == MainGroupId then
                    return true
                end
            end
            return false
        end,
        CurrencyName = nil
    },
    {
        RequiredLevel = 5,
        FrameName = "Z.Slot3",
        UnlockProductId = SaveSlotUnlockIDs["Lvl5"],
        SpecialRequirement = nil,
        CurrencyName = "PurchasedLvl5SaveSlotUnlock"
    },
    {
        RequiredLevel = 15,
        FrameName = "Z.Slot4",
        UnlockProductId = SaveSlotUnlockIDs["Lvl15"],
        SpecialRequirement = nil,
        CurrencyName = "PurchasedLvl15SaveSlotUnlock"
    },
    {
        RequiredLevel = 25,
        FrameName = "Z.Slot5",
        UnlockProductId = SaveSlotUnlockIDs["Lvl25"],
        SpecialRequirement = nil,
        CurrencyName = "PurchasedLvl25SaveSlotUnlock"
    }
}

return SaveSlots