-- ================================================================
--  Aspect Hub | visuals.lua
--  github.com/Lucid788/aspect/visuals.lua
-- ================================================================

local RunService = game:GetService('RunService')
local Lighting   = game:GetService('Lighting')
local Players    = game:GetService('Players')
local LocalPlayer= Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ── X-RAY ─────────────────────────────────────────────────────────
local xrayParts = {}
local VIS = {
    xray=false, xrayRadius=200, xrayTrans=0.35,
    fullbright=false,
}

local XRAY_BIND='AspectXRay'
local function startXRay()
    RunService:BindToRenderStep(XRAY_BIND,Enum.RenderPriority.Last.Value,function()
        if not VIS.xray then return end
        local char=LocalPlayer.Character; if not char then return end
        for _,part in ipairs(workspace:GetPartBoundsInRadius(char:GetPivot().Position,VIS.xrayRadius)) do
            if not xrayParts[part] and part:IsA('BasePart')
               and not part:IsDescendantOf(char) and part.Transparency<0.85 then
                xrayParts[part]=part.Transparency; part.Transparency=VIS.xrayTrans
            end
        end
    end)
end

local function stopXRay()
    pcall(function() RunService:UnbindFromRenderStep(XRAY_BIND) end)
    for part,orig in pairs(xrayParts) do if part and part.Parent then part.Transparency=orig end end
    table.clear(xrayParts)
end

-- ── FULLBRIGHT ────────────────────────────────────────────────────
local function applyFullbright(on)
    if on then
        Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=100000; Lighting.GlobalShadows=false
    else
        Lighting.Brightness=1; Lighting.ClockTime=12; Lighting.FogEnd=1000; Lighting.GlobalShadows=true
    end
end

-- ── COLOR CORRECTION ──────────────────────────────────────────────
local CC = {
    enabled=false, brightness=0, contrast=0, saturation=0,
    tintColor=Color3.fromRGB(255,255,255),
}
local ccEffect = nil

local function applyCC()
    if not ccEffect then
        ccEffect=Instance.new('ColorCorrectionEffect')
        ccEffect.Name='AspectCC'; ccEffect.Parent=Lighting
    end
    ccEffect.Enabled    = CC.enabled
    ccEffect.Brightness = CC.brightness
    ccEffect.Contrast   = CC.contrast
    ccEffect.Saturation = CC.saturation
    ccEffect.TintColor  = CC.tintColor
end

local function removeCC()
    if ccEffect then ccEffect:Destroy(); ccEffect=nil end
end

-- ── SKYBOX ────────────────────────────────────────────────────────
local skyboxOrig=nil
local SKYBOX_ID='rbxassetid://139383601330300'

local function clearSkyboxes()
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA('Sky') then v:Destroy() end end
end

local function saveSkybox()
    local s=Lighting:FindFirstChildOfClass('Sky')
    if s then skyboxOrig={Bk=s.SkyboxBk,Dn=s.SkyboxDn,Ft=s.SkyboxFt,Lf=s.SkyboxLf,Rt=s.SkyboxRt,Up=s.SkyboxUp}
    else skyboxOrig='none' end
end

local function applyCustomSkybox()
    if not skyboxOrig then saveSkybox() end
    clearSkyboxes()
    local s=Instance.new('Sky')
    for _,p in ipairs({'SkyboxBk','SkyboxDn','SkyboxFt','SkyboxLf','SkyboxRt','SkyboxUp'}) do s[p]=SKYBOX_ID end
    s.Parent=Lighting
end

local function revertSkybox()
    clearSkyboxes()
    if type(skyboxOrig)=='table' then
        local s=Instance.new('Sky')
        s.SkyboxBk=skyboxOrig.Bk;s.SkyboxDn=skyboxOrig.Dn;s.SkyboxFt=skyboxOrig.Ft
        s.SkyboxLf=skyboxOrig.Lf;s.SkyboxRt=skyboxOrig.Rt;s.SkyboxUp=skyboxOrig.Up
        s.Parent=Lighting
    end
end

-- ── CROSSHAIR (Drawing) ───────────────────────────────────────────
local CROSS = {
    enabled=false,
    barLen=10, barThick=2, barColor=Color3.fromRGB(255,255,255), barAlpha=1, barGap=4,
    circleOn=false, circleR=20, circleFill=false, circleColor=Color3.fromRGB(255,255,255), circleAlpha=0.8,
    outlineSize=1, outlineColor=Color3.fromRGB(0,0,0),
    rotateOn=false, rotateSpeed=2, angle=0,
    bars={}, circle=nil, outlines={},
}

local function crossDestroyAll()
    for _,d in ipairs(CROSS.bars) do pcall(function() d:Remove() end) end; CROSS.bars={}
    for _,d in ipairs(CROSS.outlines) do pcall(function() d:Remove() end) end; CROSS.outlines={}
    if CROSS.circle then pcall(function() CROSS.circle:Remove() end); CROSS.circle=nil end
end

local function crossBuild()
    crossDestroyAll()
    if not CROSS.enabled then return end
    for i=1,4 do
        local ol=Drawing.new('Line'); ol.Thickness=CROSS.barThick+CROSS.outlineSize*2
        ol.Transparency=CROSS.barAlpha; ol.Color=CROSS.outlineColor; ol.Visible=false
        CROSS.outlines[i]=ol
        local bl=Drawing.new('Line'); bl.Thickness=CROSS.barThick
        bl.Transparency=CROSS.barAlpha; bl.Color=CROSS.barColor; bl.Visible=false
        CROSS.bars[i]=bl
    end
    if CROSS.circleOn then
        local c=Drawing.new('Circle'); c.Radius=CROSS.circleR; c.Thickness=CROSS.barThick
        c.Color=CROSS.circleColor; c.Transparency=CROSS.circleAlpha; c.Filled=CROSS.circleFill; c.Visible=false
        CROSS.circle=c
    end
end

RunService:BindToRenderStep('AspectCrosshair',Enum.RenderPriority.Last.Value+1,function()
    Camera = workspace.CurrentCamera
    if not CROSS.enabled then
        for _,d in ipairs(CROSS.bars) do d.Visible=false end
        for _,d in ipairs(CROSS.outlines) do d.Visible=false end
        if CROSS.circle then CROSS.circle.Visible=false end; return
    end
    if #CROSS.bars<4 then crossBuild(); return end
    local center=Camera.ViewportSize/2
    if CROSS.rotateOn then CROSS.angle=(CROSS.angle+CROSS.rotateSpeed*0.016)%(math.pi*2) end
    local a=CROSS.angle
    local dirs={
        Vector2.new(math.cos(a),math.sin(a)),
        Vector2.new(-math.cos(a),-math.sin(a)),
        Vector2.new(-math.sin(a),math.cos(a)),
        Vector2.new(math.sin(a),-math.cos(a)),
    }
    for i=1,4 do
        local d=dirs[i]
        local from=center+d*CROSS.barGap; local to=center+d*(CROSS.barGap+CROSS.barLen)
        local ol=CROSS.outlines[i]
        ol.From=from; ol.To=to; ol.Color=CROSS.outlineColor
        ol.Thickness=CROSS.barThick+CROSS.outlineSize*2; ol.Visible=true
        local bl=CROSS.bars[i]
        bl.From=from; bl.To=to; bl.Color=CROSS.barColor
        bl.Thickness=CROSS.barThick; bl.Transparency=CROSS.barAlpha; bl.Visible=true
    end
    if CROSS.circle and CROSS.circleOn then
        CROSS.circle.Position=center; CROSS.circle.Radius=CROSS.circleR
        CROSS.circle.Filled=CROSS.circleFill; CROSS.circle.Transparent=CROSS.circleAlpha; CROSS.circle.Visible=true
    elseif CROSS.circle then
        CROSS.circle.Visible=false
    end
end)

-- ── AP EFFECT ─────────────────────────────────────────────────────
local FUN = { apEffect=false }
local apPart=nil; local apAngle=0

local function buildAPEffect()
    if apPart then pcall(function() apPart:Destroy() end); apPart=nil end
    apPart=Instance.new('Part'); apPart.Size=Vector3.new(1,1,1); apPart.Anchored=true
    apPart.CanCollide=false; apPart.Transparency=1; apPart.Name='AspectAPEffect'; apPart.Parent=workspace
    local bb=Instance.new('BillboardGui'); bb.Size=UDim2.new(0,200,0,80)
    bb.AlwaysOnTop=true; bb.Parent=apPart
    local lbl=Instance.new('TextLabel'); lbl.Size=UDim2.fromScale(1,1)
    lbl.BackgroundTransparency=1; lbl.Text='AP'; lbl.Font=Enum.Font.GothamBold
    lbl.TextScaled=true; lbl.TextColor3=Color3.fromRGB(255,80,80)
    lbl.TextStrokeTransparency=0; lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.Parent=bb
end

local function destroyAPEffect()
    if apPart then pcall(function() apPart:Destroy() end); apPart=nil end
end

RunService:BindToRenderStep('AspectAPEffect',Enum.RenderPriority.Last.Value,function()
    if not FUN.apEffect then return end
    local c=LocalPlayer.Character; if not c then return end
    local hrp=c:FindFirstChild('HumanoidRootPart'); if not hrp then return end
    if not apPart or not apPart.Parent then buildAPEffect() end
    apAngle=(apAngle+0.02)%(math.pi*2)
    apPart.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(apAngle)*3,1.5,math.sin(apAngle)*3))
end)

-- ── GUN CHARM / NO ANIM ───────────────────────────────────────────
local GUN = { charm=false, color=Color3.fromRGB(255,255,255), rainbow=false }

local function getFirstPersonFolder()
    local vm=workspace:FindFirstChild('ViewModels'); if not vm then return nil end
    return vm:FindFirstChild('FirstPerson')
end

RunService.Heartbeat:Connect(function()
    if not GUN.charm and not GUN.rainbow then return end
    local fp=getFirstPersonFolder(); if not fp then return end
    local col = GUN.rainbow and Color3.fromHSV(tick()*0.3%1,1,1) or GUN.color
    for _,obj in ipairs(fp:GetDescendants()) do
        if obj:IsA('BasePart') or obj:IsA('MeshPart') then
            pcall(function() obj.Color=col end)
        end
    end
end)

local scheduledForDeletion={}
local NOANIMENABLED=false
local function startNoAnim()
    RunService:BindToRenderStep('AspectNoAnim',Enum.RenderPriority.Character.Value,function()
        if not NOANIMENABLED then return end
        local fp=getFirstPersonFolder(); if not fp then return end
        local name=LocalPlayer.Name:lower()
        for _,child in ipairs(fp:GetChildren()) do
            if child.Name:lower():find(name,1,true) then
                local nfp=child:FindFirstChild('FirstPerson')
                if nfp and not scheduledForDeletion[nfp] then
                    scheduledForDeletion[nfp]=true
                    task.delay(1,function()
                        if nfp and nfp.Parent then nfp:Destroy() end
                        scheduledForDeletion[nfp]=nil
                    end)
                end
            end
        end
    end)
end

local function stopNoAnim()
    NOANIMENABLED=false
    pcall(function() RunService:UnbindFromRenderStep('AspectNoAnim') end)
end

-- ── CLEANUP ───────────────────────────────────────────────────────
local function cleanup()
    stopXRay(); removeCC(); destroyAPEffect(); crossDestroyAll(); stopNoAnim()
    pcall(function() RunService:UnbindFromRenderStep('AspectCrosshair') end)
    pcall(function() RunService:UnbindFromRenderStep('AspectAPEffect')  end)
end

return {
    vis             = VIS,
    cc              = CC,
    cross           = CROSS,
    fun             = FUN,
    gun             = GUN,
    startXRay       = startXRay,
    stopXRay        = stopXRay,
    applyFullbright = applyFullbright,
    applyCC         = applyCC,
    removeCC        = removeCC,
    applyCustomSkybox=applyCustomSkybox,
    revertSkybox    = revertSkybox,
    crossBuild      = crossBuild,
    crossDestroyAll = crossDestroyAll,
    buildAPEffect   = buildAPEffect,
    destroyAPEffect = destroyAPEffect,
    startNoAnim     = startNoAnim,
    stopNoAnim      = stopNoAnim,
    setNoAnim       = function(v) NOANIMENABLED=v end,
    cleanup         = cleanup,
}
