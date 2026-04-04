-- ================================================================
--  Aspect Hub | triggerbot.lua
--  github.com/Lucid788/aspect/triggerbot.lua
-- ================================================================

local TB = {
    enabled   = false,
    delay     = 0.05,
    cooldown  = false,
    teamCheck = false,
    wallCheck = false,
    keybind   = nil,   -- set by main after AddKeyPicker
}

local Players         = game:GetService('Players')
local RunService      = game:GetService('RunService')
local UserInputService= game:GetService('UserInputService')
local Camera          = workspace.CurrentCamera
local LocalPlayer     = Players.LocalPlayer

local function isVisible(part)
    local c = LocalPlayer.Character; if not c then return false end
    local head = c:FindFirstChild('Head'); if not head then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {c, part.Parent}
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    return workspace:Raycast(head.Position, part.Position - head.Position, rp) == nil
end

local function getChar() return LocalPlayer.Character end

local function isActive()
    if not TB.enabled then return false end
    if not TB.keybind  then return false end
    local ok, state = pcall(function() return TB.keybind:GetState() end)
    return ok and state == true
end

local BIND = 'AspectTriggerbot'

local function start()
    RunService:BindToRenderStep(BIND, Enum.RenderPriority.Last.Value, function()
        if not isActive() or TB.cooldown then return end
        Camera = workspace.CurrentCamera
        local mouse = UserInputService:GetMouseLocation()
        local ray   = Camera:ViewportPointToRay(mouse.X, mouse.Y)
        local rp    = RaycastParams.new()
        rp.FilterDescendantsInstances = {getChar()}
        rp.FilterType = Enum.RaycastFilterType.Blacklist
        local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, rp)
        if not res then return end
        local inst = res.Instance
        local hum  = inst.Parent:FindFirstChildOfClass('Humanoid')
                  or (inst.Parent.Parent and inst.Parent.Parent:FindFirstChildOfClass('Humanoid'))
        if not hum or hum.Parent == getChar() or hum.Health <= 0 then return end
        if TB.teamCheck then
            local pl = Players:GetPlayerFromCharacter(hum.Parent)
            if pl and pl.Team == LocalPlayer.Team then return end
        end
        if TB.wallCheck and not isVisible(inst) then return end
        TB.cooldown = true
        task.spawn(function()
            mouse1press(); task.wait(TB.delay); mouse1release()
            task.wait(0.05); TB.cooldown = false
        end)
    end)
end

local function stop()
    pcall(function() RunService:UnbindFromRenderStep(BIND) end)
end

return {
    state    = TB,
    start    = start,
    stop     = stop,
    isActive = isActive,
}
