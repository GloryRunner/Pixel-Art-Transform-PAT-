local SoundService = game:GetService("SoundService")
local Music = SoundService:WaitForChild("Music"):GetChildren()

local CurrentSong = nil

local MusicController = {}

function MusicController.Init()
    MusicController.PlayRandomSong()
end

function MusicController.PlayRandomSong()
    local TableCopy = table.clone(Music)
    if CurrentSong then
        local CurrentSongIndex = table.find(TableCopy, CurrentSong)
        table.remove(TableCopy, CurrentSongIndex)
    end
    local RandomIndex = math.random(1, #TableCopy)
    local RandomSong = TableCopy[RandomIndex]
    CurrentSong = RandomSong
    SoundService:PlayLocalSound(RandomSong)
    task.wait(CurrentSong.TimeLength)
    CurrentSong = nil
    MusicController.PlayRandomSong()
end

return MusicController