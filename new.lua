-- fps nuke remaster by papi
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- wait for character
local function getCharacter(plr)
    return plr and plr.Character or nil
end

-- helper: name contains cashier/atm
local function hasCashierATMName(inst)
    if not inst or not inst.Name then return false end
    local n = string.lower(inst.Name)
    if n:find("cashier") or n:find("cashiers") or n:find("atm") then
        return true
    end
    return false
end

-- helper: check if the model (or any descendant) contains cashier/atm in its name
local function containsCashierATMInTree(inst)
    if hasCashierATMName(inst) then return true end
    for _, d in ipairs(inst:GetDescendants()) do
        if hasCashierATMName(d) then
            return true
        end
    end
    return false
end

-- helper: is this instance part of any player's character (protect all players)
local function isPartOfAnyPlayer(inst)
    if not inst then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = getCharacter(plr)
        if char then
            -- if the object is the character model, or is descendant of the character,
            -- or the character is descendant of the object, consider it player-related
            if inst == char or inst:IsDescendantOf(char) or char:IsDescendantOf(inst) then
                return true
            end
        end
    end
    return false
end

-- safe destroy: only destroy if not player-related and not cashier/atm related
local function safeDestroy(inst)
    if not inst or not inst.Parent then return end
    if isPartOfAnyPlayer(inst) then return end
    if containsCashierATMInTree(inst) then return end
    pcall(function()
        inst:Destroy()
    end)
end

-- main purge of current workspace children
for _, child in ipairs(workspace:GetChildren()) do
    safeDestroy(child)
end

-- watch for new objects (map respawns, lazy loaders, etc)
workspace.ChildAdded:Connect(function(child)
    -- small delay so things that quickly parent players or cashier parts can settle
    task.wait(0.05)
    safeDestroy(child)
end)

-- make a permanent platform to catch you (30x30)
local function makePlatform()
    local platform = Instance.new("Part")
    platform.Name = "fpsSaverPlatform"
    platform.Size = Vector3.new(30, 1, 30)
    platform.Anchored = true
    platform.CanCollide = true
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.Material = Enum.Material.SmoothPlastic
    platform.Position = Vector3.new(0, -1000, 0) -- start far away
    platform.Parent = workspace

    -- follow local player
    task.spawn(function()
        while task.wait(0.1) do
            local char = getCharacter(localPlayer)
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                -- put platform ~6 studs below root so it catches falls but isn't stuck in you
                local targetPos = root.Position - Vector3.new(0, 6, 0)
                platform.CFrame = CFrame.new(targetPos)
            end
        end
    end)
end

makePlatform()
