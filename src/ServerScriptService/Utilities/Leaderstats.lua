local Leaderstats = {}

function Leaderstats.CreateLeaderstats(Player)
    local Folder = Instance.new("Folder")
    Folder.Name = "leaderstats"
    Folder.Parent = Player
end

function Leaderstats.CreateValue(Player, ValueName, Value)
    local Folder = Player:FindFirstChild("leaderstats")
    local DataObject = Instance.new("NumberValue")
    DataObject.Name = ValueName
    DataObject.Value = Value
    DataObject.Parent = Folder
end

function Leaderstats.ChangeValue(Player, ValueName, NewValue)
    local Folder = Player:FindFirstChild("leaderstats")
    if Folder then
        local ValueObject = Folder:FindFirstChild(ValueName)
        if ValueObject then
            ValueObject.Value = NewValue
        end
    end
end

return Leaderstats