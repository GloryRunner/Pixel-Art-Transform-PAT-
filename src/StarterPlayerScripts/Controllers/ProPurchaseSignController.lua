local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ProSign = PlayerGui:WaitForChild("ProSign"):WaitForChild("SurfaceGui")
local PurchaseButton = ProSign:WaitForChild("ProPrompt"):WaitForChild("Confirm"):WaitForChild("MainFrame"):WaitForChild("ConfirmButton"):WaitForChild("Button")

local Constants = ReplicatedStorage:WaitForChild("Constants")
local IDs = require(Constants:WaitForChild("IDs"))

local ProGamepassId = IDs.Gamepasses.Pro

local ProPurchaseSign = {}

function ProPurchaseSign.Init()
    PurchaseButton.Activated:Connect(function()
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, ProGamepassId)
    end)
end

return ProPurchaseSign