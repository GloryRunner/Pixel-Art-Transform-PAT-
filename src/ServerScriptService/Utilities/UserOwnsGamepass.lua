local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GamepassCheck = ReplicatedStorage.GamepassCheck
local UserOwnsGamepassRemote = GamepassCheck.UserOwnsGamepass

local IDs = require(ReplicatedStorage.Constants.IDs)
local ProGamepassId = IDs.Gamepasses.Pro
local BrushSizesGamepassId = IDs.Gamepasses.BrushSizes

local UserOwnsGamepass = {}

function UserOwnsGamepass.Init()
    UserOwnsGamepassRemote.OnServerInvoke = function(Player, PlayerToCheck, GamepassId)
        if GamepassId == ProGamepassId or GamepassId == BrushSizesGamepassId then
            return MarketplaceService:UserOwnsGamePassAsync(PlayerToCheck.UserId, GamepassId) 
        end
    end
end

return UserOwnsGamepass