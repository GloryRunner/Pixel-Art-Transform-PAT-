local ChatService = game:GetService("Chat")

local TextFiltering = {}

function TextFiltering.FilterUntargetedText(Text, PlayerSending)
    local FilteredText = ChatService:FilterStringForBroadcast(Text, PlayerSending)
    return FilteredText
end

function TextFiltering.FilterTargetedText(Text, PlayerSending, PlayerReceiving)
    local FilteredText = ChatService:FilterStringAsync(Text, PlayerSending, PlayerReceiving)
    return FilteredText
end

return TextFiltering