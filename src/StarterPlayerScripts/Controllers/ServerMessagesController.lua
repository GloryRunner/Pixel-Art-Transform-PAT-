local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ServerAnnouncements = ReplicatedStorage.ServerAnnouncements
local AnnounceMessageRemote = ServerAnnouncements.AnnounceMessage

local ServerMessagesController = {}

function ServerMessagesController.Init()
    AnnounceMessageRemote.OnClientInvoke = ServerMessagesController.DisplayServerMessage
end

function ServerMessagesController.DisplayServerMessage(Message)
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = Message,
        Font = Enum.Font.GothamBold,
        Color = Color3.fromRGB(88, 210, 255),
        FontSize = Enum.FontSize.Size96
    })
end

return ServerMessagesController