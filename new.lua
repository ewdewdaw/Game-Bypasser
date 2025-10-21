--// made for delta by papi 😎
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

-- delete everything except cashiers/atm
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") or obj:IsA("Model") then
        local n = string.lower(obj.Name)
        if not (n:find("cashier") or n:find("cashiers") or n:find("atm")) then
            pcall(function()
                obj:Destroy()
            end)
        end
    end
end

-- make a platform under u so u don’t die
local platform = Instance.new("Part")
platform.Size = Vector3.new(30, 1, 30)
platform.Anchored = true
platform.Material = Enum.Material.SmoothPlastic
platform.Color = Color3.new(0.1, 0.1, 0.1)
platform.Name = "fpsSaverPlatform"
platform.Parent = workspace

-- keep it under u 24/7
task.spawn(function()
    while task.wait(0.1) do
        if char and root then
            platform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 6, root.Position.Z)
        end
    end
end)
