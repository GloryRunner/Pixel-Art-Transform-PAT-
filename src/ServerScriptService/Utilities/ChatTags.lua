local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local ChatService = require(ServerScriptService:WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))

local GetUserCurrency = ReplicatedStorage:WaitForChild("GetUserCurrency")
local OnUserCurrencyChangeEvent = ReplicatedStorage:WaitForChild("OnUserCurrencyChangeEvent")

local Constants = ReplicatedStorage.Constants
local IDs = require(Constants.IDs)

local GroupId = IDs["7Wapy"]
local ProGamepassId = IDs.Gamepasses.Pro
local LegendTagCoinRequirement = 100

local ProColor = Color3.fromRGB(0, 255, 115)
local SupporterColor = Color3.fromRGB(0, 115, 255)
local LegendColor = Color3.fromRGB(255, 208, 0)

--[[
    Tag Priority:
    Supporter = 1
    Legend = 2
    Pro = 3
]]

--[[

Legend and Pro tags are given in real time, while the Supporter tag is given on join.

]]

local ChatTags = {}

function ChatTags.Init()
    ChatService.SpeakerAdded:Connect(function(PlayerName)
        local Player = Players:FindFirstChild(PlayerName)
        if Player then
            ChatTags.ApplyTags(Player)
        end
    end)

    OnUserCurrencyChangeEvent.Event:Connect(ChatTags.ApplyTags)
end

function ChatTags.ApplyTags(Player)
    local Speaker = ChatService:GetSpeaker(Player.Name)
    local HasLegendTag = GetUserCurrency:Invoke(Player, "CoinsGifted") >= 100
    local HasSupporterTag = Player:IsInGroup(GroupId)
    local HasProTag = false
    local Success, Error = pcall(function()
        HasProTag = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, ProGamepassId)
    end)

    if Success then
        if HasProTag then
            Speaker:SetExtraData("Tags", {{TagText = "Pro", TagColor = ProColor}})
        elseif HasLegendTag then
            Speaker:SetExtraData("Tags", {{TagText = "Legend", TagColor = LegendColor}})
        elseif HasSupporterTag then
            Speaker:SetExtraData("Tags", {{TagText = "Supporter", TagColor = SupporterColor}})
        end
    else
        print("Error getting userownsgamepass for: ".. tostring(Player.UserId).. " when applying chattags.")
    end
end


return ChatTags