-- ================================================================
--  Aspect Hub | esp.lua
--  github.com/Lucid788/aspect/esp.lua
-- ================================================================

local Players    = game:GetService('Players')
local RunService = game:GetService('RunService')
local Camera     = workspace.CurrentCamera
local LocalPlayer= Players.LocalPlayer

local ESP = {
    box       = false,
    line      = false,
    skel      = false,
    charm     = false,
    teamCheck = false,
    fillColor = Color3.fromRGB(255,215,0),
    outColor  = Color3.fromRGB(255,255,255),
    rainbow   = false,
    rainbowHue= 0,
    rainbowSpeed = 0.004,
    gradient  = false,   -- gradient mode: each player gets offset hue
}

local espBoxes     = {}
local espBoxConns  = {}
local espLines     = {}
local espLineConns = {}
local espSkel      = {}
local charmHL      = {}

local C_GREEN  = Color3.fromRGB(0,255,0)
local C_YELLOW = Color3.fromRGB(255,220,0)
local C_RED    = Color3.fromRGB(255,0,0)

-- Rainbow color (shared base hue)
local function getRainbow(offset)
    offset = offset or 0
    return Color3.fromHSV((ESP.rainbowHue + offset) % 1, 1, 1)
end

-- Update rainbow hue each frame
RunService:BindToRenderStep('AspectRainbow', Enum.RenderPriority.Last.Value, function()
    if ESP.rainbow or ESP.gradient then
        ESP.rainbowHue = (ESP.rainbowHue + ESP.rainbowSpeed) % 1
    end
end)

local function skipESP(p) return ESP.teamCheck and p.Team == LocalPlayer.Team end

-- ── BOX ──────────────────────────────────────────────────────────
local function removeBoxESP(p)
    if espBoxes[p]    then espBoxes[p]:Remove();       espBoxes[p]=nil    end
    if espBoxConns[p] then espBoxConns[p]:Disconnect(); espBoxConns[p]=nil end
end

local function createBoxESP(player)
    if skipESP(player) or espBoxes[player] then return end
    local box = Drawing.new('Square')
    box.Visible=false; box.Thickness=1.5; box.Transparency=1; box.Filled=false
    box.Color=Color3.fromRGB(255,50,50)
    espBoxes[player] = box

    -- gradient offset per player
    local playerIdx = 0
    for i,p in ipairs(Players:GetPlayers()) do if p==player then playerIdx=i; break end end
    local offset = (playerIdx * 0.13) % 1

    espBoxConns[player] = RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera
        if not ESP.box or skipESP(player) then box.Visible=false; return end
        local char = player.Character
        local hrp  = char and char:FindFirstChild('HumanoidRootPart')
        if not hrp then box.Visible=false; return end
        local _,onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then box.Visible=false; return end
        local top = Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3,0))
        local bot = Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,-3,0))
        local h = math.abs(top.Y-bot.Y); local w=h*0.55
        box.Size=Vector2.new(w,h); box.Position=Vector2.new(top.X-w*0.5,top.Y)
        if ESP.gradient then
            box.Color = getRainbow(offset)
        elseif ESP.rainbow then
            box.Color = getRainbow()
        else
            box.Color = Color3.fromRGB(255,50,50)
        end
        box.Visible=true
    end)
end

-- ── LINE ─────────────────────────────────────────────────────────
local function removeLineESP(p)
    if espLines[p]     then espLines[p]:Remove();        espLines[p]=nil     end
    if espLineConns[p] then espLineConns[p]:Disconnect(); espLineConns[p]=nil end
end

local function createLineESP(player)
    if skipESP(player) or espLines[player] then return end
    local line=Drawing.new('Line')
    line.Visible=false; line.Thickness=1.5; line.Transparency=1
    espLines[player]=line

    local playerIdx=0
    for i,p in ipairs(Players:GetPlayers()) do if p==player then playerIdx=i; break end end
    local offset=(playerIdx*0.13)%1

    espLineConns[player]=RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera
        if not ESP.line or skipESP(player) then line.Visible=false; return end
        local lc=LocalPlayer.Character
        local lHRP=lc and lc:FindFirstChild('HumanoidRootPart')
        local pc=player.Character; local pHRP=pc and pc:FindFirstChild('HumanoidRootPart')
        if not lHRP or not pHRP then line.Visible=false; return end
        local dist=(pHRP.Position-lHRP.Position).Magnitude
        if dist>500 then line.Visible=false; return end
        local sp=Camera:WorldToViewportPoint(lHRP.Position)
        local ep=Camera:WorldToViewportPoint(pHRP.Position)
        if sp.Z<=0 or ep.Z<=0 then line.Visible=false; return end
        local col
        if ESP.gradient then
            col = getRainbow(offset)
        elseif ESP.rainbow then
            col = getRainbow()
        elseif dist<80 then col=C_GREEN
        elseif dist<160 then col=C_GREEN:Lerp(C_YELLOW,(dist-80)/80)
        else col=C_YELLOW:Lerp(C_RED,math.clamp((dist-160)/100,0,1)) end
        line.From=Vector2.new(sp.X,sp.Y); line.To=Vector2.new(ep.X,ep.Y)
        line.Color=col; line.Visible=true
    end)
end

-- ── SKELETON ─────────────────────────────────────────────────────
local BONES={
    {'Head','UpperTorso'},{'UpperTorso','LowerTorso'},
    {'UpperTorso','LeftUpperArm'},{'LeftUpperArm','LeftLowerArm'},{'LeftLowerArm','LeftHand'},
    {'UpperTorso','RightUpperArm'},{'RightUpperArm','RightLowerArm'},{'RightLowerArm','RightHand'},
    {'LowerTorso','LeftUpperLeg'},{'LeftUpperLeg','LeftLowerLeg'},{'LeftLowerLeg','LeftFoot'},
    {'LowerTorso','RightUpperLeg'},{'RightUpperLeg','RightLowerLeg'},{'RightLowerLeg','RightFoot'},
}

local function removeSkelESP(p)
    if not espSkel[p] then return end
    for _,l in ipairs(espSkel[p].lines) do l:Remove() end
    if espSkel[p].conn then espSkel[p].conn:Disconnect() end
    espSkel[p]=nil
end

local function createSkelESP(player)
    if skipESP(player) or espSkel[player] then return end
    local lines={}
    for i=1,#BONES do
        local l=Drawing.new('Line'); l.Thickness=1; l.Transparency=1
        l.Color=Color3.fromRGB(255,50,50); l.Visible=false; lines[i]=l
    end
    local playerIdx=0
    for i,p in ipairs(Players:GetPlayers()) do if p==player then playerIdx=i; break end end
    local offset=(playerIdx*0.13)%1

    local conn=RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera
        if not ESP.skel or skipESP(player) then
            for _,l in ipairs(lines) do l.Visible=false end; return
        end
        local char=player.Character
        if not char then for _,l in ipairs(lines) do l.Visible=false end; return end
        for i,pair in ipairs(BONES) do
            local p1=char:FindFirstChild(pair[1]); local p2=char:FindFirstChild(pair[2])
            local ln=lines[i]
            if p1 and p2 then
                local v1,ok1=Camera:WorldToViewportPoint(p1.Position)
                local v2,ok2=Camera:WorldToViewportPoint(p2.Position)
                if ok1 and ok2 then
                    ln.From=Vector2.new(v1.X,v1.Y); ln.To=Vector2.new(v2.X,v2.Y)
                    if ESP.gradient then
                        ln.Color=getRainbow(offset)
                    elseif ESP.rainbow then
                        ln.Color=getRainbow()
                    else
                        ln.Color=Color3.fromRGB(255,50,50)
                    end
                    ln.Visible=true
                else ln.Visible=false end
            else ln.Visible=false end
        end
    end)
    espSkel[player]={lines=lines,conn=conn}
end

-- ── CHARM ────────────────────────────────────────────────────────
local function removeCharmESP(p)
    if charmHL[p] then charmHL[p]:Destroy(); charmHL[p]=nil end
end

local function createCharmESP(player)
    if charmHL[player] then return end
    local char=player.Character; if not char then return end
    local h=Instance.new('Highlight')
    h.Adornee=char; h.FillColor=ESP.fillColor; h.OutlineColor=ESP.outColor
    h.FillTransparency=0.35; h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=char
    charmHL[player]=h
end

-- Rainbow/gradient charm update
RunService.RenderStepped:Connect(function()
    if not (ESP.rainbow or ESP.gradient) then return end

    local playerList = Players:GetPlayers()
    for pi, player in ipairs(playerList) do
        local h = charmHL[player]
        if h and h.Parent then
            local offset = ESP.gradient and ((pi * 0.13) % 1) or 0
            local col = getRainbow(offset)
            h.FillColor    = col
            h.OutlineColor = col
        end
    end
end)

local function refreshCharm()
    if ESP.charm then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and not skipESP(p) then createCharmESP(p) end
        end
    else
        for p in pairs(charmHL) do removeCharmESP(p) end
    end
end

local function watchCharm(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESP.charm then createCharmESP(player) end
    end)
end

for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then watchCharm(p) end end

Players.PlayerAdded:Connect(function(p)
    watchCharm(p); task.wait(1)
    if ESP.box   then createBoxESP(p)   end
    if ESP.line  then createLineESP(p)  end
    if ESP.skel  then createSkelESP(p)  end
    if ESP.charm then createCharmESP(p) end
end)

Players.PlayerRemoving:Connect(function(p)
    removeBoxESP(p); removeLineESP(p); removeSkelESP(p); removeCharmESP(p)
end)

local function cleanup()
    for p in pairs(espBoxes) do removeBoxESP(p) end
    for p in pairs(espLines) do removeLineESP(p) end
    for p in pairs(espSkel)  do removeSkelESP(p) end
    for p in pairs(charmHL)  do removeCharmESP(p) end
    pcall(function() RunService:UnbindFromRenderStep('AspectRainbow') end)
end

return {
    state         = ESP,
    createBoxESP  = createBoxESP,
    removeBoxESP  = removeBoxESP,
    createLineESP = createLineESP,
    removeLineESP = removeLineESP,
    createSkelESP = createSkelESP,
    removeSkelESP = removeSkelESP,
    createCharmESP= createCharmESP,
    removeCharmESP= removeCharmESP,
    refreshCharm  = refreshCharm,
    espBoxes      = espBoxes,
    espLines      = espLines,
    espSkel       = espSkel,
    charmHL       = charmHL,
    cleanup       = cleanup,
}
