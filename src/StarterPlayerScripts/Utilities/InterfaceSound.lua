local SoundService = game:GetService("SoundService")

local InterfaceSound = {}

local Sounds = {
    OpenUI = SoundService:WaitForChild("OpenUI"),
    CloseUI = SoundService:WaitForChild("CloseUI"),
    ClaimGift = SoundService:WaitForChild("Claim"),
    GiftClaimFailed = SoundService:WaitForChild("ClaimFailed"),
    Erase = SoundService:WaitForChild("Erase"),
    Morph = SoundService:WaitForChild("Morph"),
    Popup = SoundService:WaitForChild("Popup")
}

function InterfaceSound.PlaySound(SoundName)
    local Sound = Sounds[SoundName]
    Sound.TimePosition = 0
    if Sound then
        SoundService:PlayLocalSound(Sound)
    end
end

return InterfaceSound