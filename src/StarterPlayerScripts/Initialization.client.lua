local ModuleFolders = {
    script.Parent:WaitForChild("Controllers"),
    script.Parent:WaitForChild("Utilities")
}

for _, ModuleFolder in ipairs(ModuleFolders) do
    task.spawn(function()
        for _, Module in ipairs(ModuleFolder:GetDescendants()) do
            if Module:IsA("ModuleScript") then
                local ModuleContents = require(Module)
                if typeof(ModuleContents) == "table" and ModuleContents.Init then
                    task.spawn(ModuleContents.Init)
                end
            end
        end
    end)
end