-- fps nuke + safe cashier protect + highlight + locked float
-- paste as LocalScript in StarterPlayerScripts
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- config
local PLATFORM_SIZE = Vector3.new(30,1,30)
local PLATFORM_Y_OFFSET = 6
local PURGE_DELAY_AFTER_CHILD = 0.35
local HIGHLIGHT_FILL = Color3.fromRGB(0,255,0)
local HIGHLIGHT_OUTLINE = Color3.fromRGB(0,200,0)

-- utils
local function lower(s) return (s or ""):lower() end
local function nameHasCashierATM(inst)
    if not inst or not inst.Name then return false end
    local n = lower(inst.Name)
    return n:find("cashier") or n:find("cashiers") or n:find("atm")
end

-- returns true if inst itself, any ancestor, or any descendant contains cashier/atm in the name
local function isCashierRelated(inst)
    if not inst then return false end
    -- check self and ancestors
    local cur = inst
    while cur do
        if nameHasCashierATM(cur) then
            return true
        end
        cur = cur.Parent
    end
    -- check descendants
    for _, d in ipairs(inst:GetDescendants()) do
        if nameHasCashierATM(d) then
            return true
        end
    end
    return false
end

-- check for humanoid in tree
local function treeHasHumanoid(inst)
    if not inst then return false end
    if inst:IsA("Humanoid") then return true end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("Humanoid") then return true end
    end
    return false
end

-- protect any instance that is part of a player character or contains a humanoid or is named like a player
local function isPlayerRelated(inst)
    if not inst then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            if inst:IsDescendantOf(char) or char:IsDescendantOf(inst) then
                return true
            end
            if inst.Name and lower(inst.Name) == lower(plr.Name) then
                return true
            end
        end
    end
    if treeHasHumanoid(inst) then return true end
    return false
end

-- only remove baseparts that are NOT player-related and NOT cashier-related
local function shouldRemovePart(part)
    if not part or not part.Parent then return false end
    if not part:IsA("BasePart") then return false end
    if isPlayerRelated(part) then return false end
    if isCashierRelated(part) then return false end
    return true
end

-- purge workspace parts safely
local function purgeWorkspaceParts()
    local toRemove = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if shouldRemovePart(inst) then
            table.insert(toRemove, inst)
        end
    end
    for _, p in ipairs(toRemove) do
        pcall(function() p:Destroy() end)
    end
end

-- highlight management
local highlights = {} -- map key->Highlight

local function findPartForAdornee(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") then return inst.PrimaryPart end
        for _, c in ipairs(inst:GetDescendants()) do
            if c:IsA("BasePart") then return c end
        end
    end
    local anc = inst
    while anc and not anc:IsA("BasePart") do anc = anc.Parent end
    if anc and anc:IsA("BasePart") then return anc end
    return nil
end

local function updateHighlights()
    local seen = {} -- set of representative instances (prefer models)
    -- prefer collecting top-level models that are cashier-related
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("Model") and isCashierRelated(inst) then
            seen[inst] = true
        end
    end
    -- also collect parts that are cashier-related but not under a collected model
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") and isCashierRelated(inst) then
            local topModel = inst.Parent
            while topModel and not topModel:IsA("Model") do topModel = topModel.Parent end
            if topModel and not seen[topModel] then
                seen[topModel] = true
            elseif not topModel then
                seen[inst] = true
            end
        end
    end

    -- destroy highlights for removed keys
    for key, hl in pairs(highlights) do
        if not seen[key] then
            pcall(function() hl:Destroy() end)
            highlights[key] = nil
        end
    end

    -- create/update highlights
    local count = 0
    for keyInst, _ in pairs(seen) do
        count = count + 1
        if not highlights[keyInst] then
            local adornee = findPartForAdornee(keyInst)
            if adornee then
                local hl = Instance.new("Highlight")
                hl.Name = "papiHighlight_cashier"
                hl.Parent = Workspace
                hl.Adornee = adornee
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.FillColor = HIGHLIGHT_FILL
                hl.OutlineColor = HIGHLIGHT_OUTLINE
                highlights[keyInst] = hl
            end
        else
            -- ensure adornee still valid
            local hl = highlights[keyInst]
            if not hl or not hl.Adornee or not hl.Adornee.Parent then
                pcall(function() hl:Destroy() end)
                highlights[keyInst] = nil
            end
        end
    end

    -- print when count changes
    if not updateHighlights._lastCount or updateHighlights._lastCount ~= count then
        updateHighlights._lastCount = count
        print("[papi] cashiers/atms found:", count)
    end
end

-- platform + float logic
local platform = Instance.new("Part")
platform.Name = "fpsSaverPlatform"
platform.Size = PLATFORM_SIZE
platform.Anchored = true
platform.CanCollide = true
platform.TopSurface = Enum.SurfaceType.Smooth
platform.BottomSurface = Enum.SurfaceType.Smooth
platform.Material = Enum.Material.SmoothPlastic
platform.Position = Vector3.new(0, -5000, 0)
platform.Parent = Workspace

local floatConn
local lockedY

local function setupFloatForCharacter(char)
    if floatConn then
        floatConn:Disconnect()
        floatConn = nil
    end
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    lockedY = root.Position.Y

    floatConn = RunService.Heartbeat:Connect(function()
        if not root or not root.Parent then return end
        local cf = root.CFrame
        local targetPos = Vector3.new(root.Position.X, lockedY, root.Position.Z)
        local ok, newCf = pcall(function()
            return CFrame.fromMatrix(targetPos, cf.RightVector, cf.UpVector)
        end)
        if ok and newCf then
            pcall(function() root.CFrame = newCf end)
        else
            local rot = root.Orientation
            pcall(function()
                root.CFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
            end)
        end
        pcall(function()
            platform.CFrame = CFrame.new(targetPos.X, lockedY - PLATFORM_Y_OFFSET, targetPos.Z)
        end)
    end)
end

-- setup on spawn/respawn
if LocalPlayer.Character then
    setupFloatForCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.06)
    setupFloatForCharacter(char)
end)

-- initial run
purgeWorkspaceParts()
updateHighlights()

-- watch for new stuff
Workspace.ChildAdded:Connect(function(child)
    task.wait(PURGE_DELAY_AFTER_CHILD)
    for _, inst in ipairs(child:GetDescendants()) do
        if shouldRemovePart(inst) then
            pcall(function() inst:Destroy() end)
        end
    end
    purgeWorkspaceParts()
    updateHighlights()
end)

-- periodic sweeper for lazy loaded stuff
task.spawn(function()
    while task.wait(1.2) do
        purgeWorkspaceParts()
        updateHighlights()
    end
end)
