local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local VotekickRemotes = ReplicatedStorage.VotekickRemotes
local RequestVotekick = VotekickRemotes.RequestVotekick
local RemoveVotekickRequest = VotekickRemotes.RemoveVotekickRequest
    
local MinimumPlayerCount = 2

local Votekicks = {}

--[[
     Votekicks = {
        [Player] = {
            PlayerWhoVotedThem1,
            PlayerWhoVotedThem2
        }
    }
]]

local TimerThreads = {}

local Votekick = {}

function Votekick.Init()
    RequestVotekick.OnServerInvoke = function(Player, VotedPlayer)
        local IsVotingThemself = Player == VotedPlayer
        if not IsVotingThemself then
            Votekick.RequestVotekick(Player, VotedPlayer)
        end
    end

    RemoveVotekickRequest.OnServerInvoke = function(Player)
        local VotedPlayer = Votekicks
    end
end

function Votekick.RequestVotekick(PlayerRequesting, VotedPlayer)
    local ServerPlayerCount = #Players:GetPlayers()
    
    if ServerPlayerCount > MinimumPlayerCount then
        local ActiveVotekickRequest = Votekick.GetRequestedVotekick(PlayerRequesting)
        if ActiveVotekickRequest then
            Votekick.RemoveVotekickRequest(PlayerRequesting)
        end

        table.insert(Votekicks[VotedPlayer], PlayerRequesting)
 
        local TimerThread = nil
        TimerThread = task.spawn(Votekick.ClearVotekickRequestAfterTimer, PlayerRequesting)
        TimerThreads[PlayerRequesting] = TimerThread

        local VotekickCount = Votekick.GetVotekickCountForPlayer(VotedPlayer)

        --[[
            Consider moving votekick requirements to a separate module or 
            at least to the top of the script.
        ]]

        if ServerPlayerCount >= 3 and ServerPlayerCount <= 10 then
            local PercentageRequired = 50
            local VotecountRequired = math.ceil((PercentageRequired / 100) * ServerPlayerCount)
            if VotekickCount >= VotecountRequired then
                Votekick.KickPlayer(VotedPlayer)
            end
        elseif ServerPlayerCount >= 11 then
            local PercentageRequired = 40
            local VotecountRequired = math.ceil((PercentageRequired / 100) * ServerPlayerCount)
            if VotekickCount >= VotecountRequired then
                Votekick.KickPlayer(VotedPlayer)
            end
        end
    end
end

function Votekick.RemoveVotekickRequest(Player)
    for Player, VoteData in pairs(Votekicks) do
        local Index = table.find(VoteData, Player)
        if Index then
            table.remove(VoteData, Index)
        end
    end

    local TimerThread = TimerThreads[Player]
    if TimerThread then
        coroutine.close(TimerThread)
        TimerThreads[Player] = nil
    end
end

function Votekick.GetRequestedVotekick(Player)
    local VotedPlayer = nil
    for PlayerVoted, VotekickData in pairs(Votekicks) do
        local IsVotekickingPlayer = table.find(VotekickData, Player)
        if IsVotekickingPlayer then
            VotedPlayer = PlayerVoted
        end
    end
    return VotedPlayer
end

function Votekick.GetVotekickCountForPlayer(Player)
    return #Votekicks[Player]
end

function Votekick.KickPlayer(KickedPlayer)
    for _, Player in ipairs(Players:GetPlayers()) do
        local PlayerRequestedToVotekick = Votekick.GetRequestedVotekick(Player)
        if PlayerRequestedToVotekick == KickedPlayer then
            Votekick.RemoveVotekickRequest(Player)
        end
    end
    Votekicks[KickedPlayer] = nil
    KickedPlayer:Kick("Votekicked")
end

function Votekick.ClearVotekickRequestAfterTimer(Player)
    local WaitTime = 300
    task.wait(WaitTime)
    local ActiveVotekickRequest = Votekick.GetRequestedVotekick(Player)
    if ActiveVotekickRequest then
        Votekick.RemoveVotekickRequest(Player)
    end
end

return Votekick