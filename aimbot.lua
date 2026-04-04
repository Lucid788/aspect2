-- ================================================================
--  Aspect Hub | aimbot.lua
--  github.com/Lucid788/aspect/aimbot.lua
-- ================================================================

local AB = {
    enabled   = false,
    part      = 'Head',
    fov       = 90,
    smooth    = 0.5,
    target    = nil,
    teamCheck = false,
    wallCheck = false,
    keybind   = nil,   -- set by main after AddKeyPicker
}

local Players         = game:GetService('Players')
local RunService      = game:GetService('RunService')
local UserInputService= game:GetService('UserInputService')
local Camera          = workspace.CurrentCamera
local LocalPlayer     = Players.LocalPlayer

-- FOV drawing
local FovCircle        = Drawing.new('Circle')
FovCircle.Thickness    = 1.5
FovCircle.Transparency = 0.8
FovCircle.Color        = Color3.fromRGB(255,255,255)
FovCircle.Radius       = 90
FovCircle.Filled       = false
FovCircle.Visible      = false

local function isVisible(part)
    local c = LocalPlayer.Character; if not c then return false end
    local head = c:FindFirstChild('Head'); if not head then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {c, part.Parent}
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    return workspace:Raycast(head.Position, part.Position - head.Position, rp) == nil
end

local function closest()
    local lc  = LocalPlayer.Character; if not lc then return nil end
    local lHRP= lc:FindFirstChild('HumanoidRootPart'); if not lHRP then return nil end
    local center = Camera.ViewportSize / 2
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character; if not char then continue end
        local hum  = char:FindFirstChildOfClass('Humanoid')
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(AB.part); if not part then continue end
        if char:FindFirstChild('ForceField') then continue end
        if AB.teamCheck and p.Team == LocalPlayer.Team then continue end
        if (lHRP.Position - part.Position).Magnitude > 600 then continue end
        if AB.wallCheck and not isVisible(part) then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist > AB.fov then continue end
        if dist < bestDist then bestDist = dist; best = p end
    end
    return best
end

local function lock(target)
    if not target or not target.Character then return end
    local part = target.Character:FindFirstChild(AB.part); if not part then return end
    local sp = Camera:WorldToViewportPoint(part.Position)
    local mp = UserInputService:GetMouseLocation()
    mousemoverel((sp.X - mp.X) * AB.smooth, (sp.Y - mp.Y) * AB.smooth)
end

-- Keybind state: called every RenderStepped, never errors
local function isActive()
    if not AB.enabled then return false end
    if not AB.keybind  then return false end
    local ok, state = pcall(function() return AB.keybind:GetState() end)
    return ok and state == true
end

-- Main loop
RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    FovCircle.Position = Camera.ViewportSize / 2
    FovCircle.Radius   = AB.fov

    if not isActive() then AB.target = nil; return end

    if not AB.target then
        AB.target = closest()
    else
        local c = AB.target.Character
        local h = c and c:FindFirstChildOfClass('Humanoid')
        if not c or not h or h.Health <= 0 then AB.target = closest() end
    end
    if AB.target then lock(AB.target) end
end)

return {
    state     = AB,
    fovCircle = FovCircle,
    isActive  = isActive,
}
