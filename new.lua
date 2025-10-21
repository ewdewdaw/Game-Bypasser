--// fps nuker v3 by papi 😎
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

-- delete everything except players and cashiers/atm
for _, obj in pairs(workspace:GetChildren()) do
    -- skip player characters
    local isPlayerChar = false
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Character and obj == plr.Character then
            isPlayerChar = true
            break
        end
    end

    -- skip cashiers/atm
    local n = string.lower(obj.Name)
    local isCashierStuff = n:find("cashier") or n:find("cashiers") or n:find("atm")

    if not isPlayerChar and not isCashierStuff then
        pcall(function()
            obj:Destroy()
        end)
    end
end

-- make a safe platform under u
local platform = Instance.new("Part")
platform.Size = Vector3.new(30, 1, 30)
platform.Anchored = true
platform.Material = Enum.Material.SmoothPlastic
platform.Color = Color3.fromRGB(25, 25, 25)
platform.Name = "fpsSaverPlatform"
platform.Parent = workspace

-- keep it under u forever
task.spawn(function()
    while task.wait(0.1) do
        if char and root then
            platform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 6, root.Position.Z)
        end
    end
end)
