-- ================================================================
--  Aspect Hub | movement.lua
--  github.com/Lucid788/aspect/movement.lua
-- ================================================================

local Players             = game:GetService('Players')
local RunService          = game:GetService('RunService')
local UserInputService    = game:GetService('UserInputService')
local VirtualInputManager = game:GetService('VirtualInputManager')
local LocalPlayer         = Players.LocalPlayer
local Camera              = workspace.CurrentCamera

local MOV = {
    fly=false, flySpeed=50, flyBG=nil, flyBV=nil,
    speed=false, speedVal=50,
    jump=false, jumpPower=80, infJump=false,
    swim=false, swimSpeed=40,
    noclip=false,
    lowGrav=false, lowGravVal=20,
    antiRag=false,
    clickTp=false,
    slideJump=false, slideConn=nil,
    orbit=false, orbitSpeed=1, orbitDist=8, orbitTarget=nil, orbitAngle=0,
    tp3=false, tp3Dist=14, tp3YOff=2, tp3Conn=nil, tp3Orig=nil,
}

local keysHeld = {}

local function getChar()  return LocalPlayer.Character end
local function getHRP()   local c=getChar(); return c and c:FindFirstChild('HumanoidRootPart') end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass('Humanoid') end
local function held(kc)   return keysHeld[kc] == true end

-- ── FLY ──────────────────────────────────────────────────────────
local function cleanFly()
    if MOV.flyBG then MOV.flyBG:Destroy(); MOV.flyBG=nil end
    if MOV.flyBV then MOV.flyBV:Destroy(); MOV.flyBV=nil end
end

local function startFly()
    local hrp=getHRP(); if not hrp then return end
    cleanFly()
    local bg=Instance.new('BodyGyro')
    bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.CFrame=hrp.CFrame; bg.Parent=hrp; MOV.flyBG=bg
    local bv=Instance.new('BodyVelocity')
    bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Parent=hrp; MOV.flyBV=bv
end

local function stopFly()
    cleanFly(); local hrp=getHRP(); if hrp then hrp.Velocity=Vector3.zero end
end

LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); if MOV.fly then startFly() end end)

RunService.Heartbeat:Connect(function()
    Camera = workspace.CurrentCamera
    if not MOV.fly then return end
    local bg=MOV.flyBG; local bv=MOV.flyBV; if not bg or not bv then return end
    local dir=Vector3.zero
    if held(Enum.KeyCode.W) then dir=dir+Camera.CFrame.LookVector  end
    if held(Enum.KeyCode.S) then dir=dir-Camera.CFrame.LookVector  end
    if held(Enum.KeyCode.A) then dir=dir-Camera.CFrame.RightVector end
    if held(Enum.KeyCode.D) then dir=dir+Camera.CFrame.RightVector end
    if held(Enum.KeyCode.Space)     then dir=dir+Vector3.new(0,1,0) end
    if held(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
    bg.CFrame=Camera.CFrame
    bv.Velocity=dir.Magnitude>0 and dir.Unit*MOV.flySpeed or Vector3.zero
end)

-- ── SPEED ─────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not MOV.speed then return end
    local hrp=getHRP(); if not hrp then return end
    local dir=Vector3.zero
    if held(Enum.KeyCode.W) then dir=dir+Camera.CFrame.LookVector  end
    if held(Enum.KeyCode.S) then dir=dir-Camera.CFrame.LookVector  end
    if held(Enum.KeyCode.A) then dir=dir-Camera.CFrame.RightVector end
    if held(Enum.KeyCode.D) then dir=dir+Camera.CFrame.RightVector end
    dir=Vector3.new(dir.X,0,dir.Z)
    if dir.Magnitude>0 then
        dir=dir.Unit; hrp.Velocity=Vector3.new(dir.X*MOV.speedVal,hrp.Velocity.Y,dir.Z*MOV.speedVal)
    end
end)

-- ── JUMP ──────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not MOV.jump then return end
    local hrp=getHRP(); local hum=getHum(); if not hrp or not hum then return end
    if held(Enum.KeyCode.Space) then
        if hum.FloorMaterial~=Enum.Material.Air or MOV.infJump then
            hrp.Velocity=Vector3.new(hrp.Velocity.X,MOV.jumpPower,hrp.Velocity.Z)
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not MOV.infJump then return end
    local hrp=getHRP(); if not hrp then return end
    hrp.Velocity=Vector3.new(hrp.Velocity.X,MOV.jumpPower,hrp.Velocity.Z)
end)

-- ── SWIM ──────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not MOV.swim then return end
    local hrp=getHRP(); if not hrp then return end
    local dir=Vector3.zero
    if held(Enum.KeyCode.W) then dir=dir+Camera.CFrame.LookVector  end
    if held(Enum.KeyCode.S) then dir=dir-Camera.CFrame.LookVector  end
    if held(Enum.KeyCode.A) then dir=dir-Camera.CFrame.RightVector end
    if held(Enum.KeyCode.D) then dir=dir+Camera.CFrame.RightVector end
    if held(Enum.KeyCode.Space)     then dir=dir+Vector3.new(0,1,0) end
    if held(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
    if dir.Magnitude>0 then hrp.Velocity=dir.Unit*MOV.swimSpeed end
end)

-- ── NOCLIP ────────────────────────────────────────────────────────
RunService:BindToRenderStep('AspectNoclip',Enum.RenderPriority.Character.Value+1,function()
    if not MOV.noclip then return end
    local char=getChar(); if not char then return end
    for _,p in ipairs(char:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=false end end
end)

-- ── LOW GRAVITY ───────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not MOV.lowGrav then return end; workspace.Gravity=MOV.lowGravVal
end)

-- ── ANTI RAGDOLL ──────────────────────────────────────────────────
RunService:BindToRenderStep('AspectAntiRag',Enum.RenderPriority.Character.Value+1,function()
    if not MOV.antiRag then return end
    local char=getChar(); if not char then return end
    for _,v in ipairs(char:GetDescendants()) do
        if v:IsA('BallSocketConstraint') or v:IsA('HingeConstraint') then v.Enabled=false end
    end
end)

-- ── ORBIT ─────────────────────────────────────────────────────────
local function orbitFind()
    local hrp=getHRP(); if not hrp then return nil end
    local best,bestDist=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer then continue end
        local c=p.Character; local r=c and c:FindFirstChild('HumanoidRootPart')
        local h=c and c:FindFirstChildOfClass('Humanoid')
        if r and h and h.Health>0 then
            local d=(hrp.Position-r.Position).Magnitude
            if d<bestDist then bestDist=d; best=p end
        end
    end
    return best
end

RunService.Heartbeat:Connect(function(dt)
    if not MOV.orbit then return end
    if not MOV.orbitTarget or not MOV.orbitTarget.Character then
        MOV.orbitTarget=orbitFind(); MOV.orbitAngle=0; if not MOV.orbitTarget then return end
    end
    local tr=MOV.orbitTarget.Character:FindFirstChild('HumanoidRootPart'); local lr=getHRP()
    if not tr or not lr then return end
    local h=MOV.orbitTarget.Character:FindFirstChildOfClass('Humanoid')
    if not h or h.Health<=0 then MOV.orbitTarget=nil; return end
    MOV.orbitAngle=(MOV.orbitAngle+MOV.orbitSpeed*dt*60)%360
    local rad=math.rad(MOV.orbitAngle)
    lr.CFrame=CFrame.new(tr.Position+Vector3.new(math.cos(rad)*MOV.orbitDist,0,math.sin(rad)*MOV.orbitDist),tr.Position)
end)

-- ── 3RD PERSON ────────────────────────────────────────────────────
local function enableTP3()
    MOV.tp3Orig=Camera.CameraType; Camera.CameraType=Enum.CameraType.Scriptable
    if MOV.tp3Conn then MOV.tp3Conn:Disconnect() end
    MOV.tp3Conn=RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera
        if not MOV.tp3 then return end
        local char=getChar(); if not char then return end
        local hrp=char:FindFirstChild('HumanoidRootPart'); local head=char:FindFirstChild('Head')
        if not hrp or not head then return end
        local camPos=hrp.Position+Vector3.new(0,MOV.tp3YOff,0)+(-hrp.CFrame.LookVector)*MOV.tp3Dist
        Camera.CFrame=CFrame.new(camPos,head.Position+Vector3.new(0,MOV.tp3YOff*0.3,0))
    end)
end

local function disableTP3()
    if MOV.tp3Conn then MOV.tp3Conn:Disconnect(); MOV.tp3Conn=nil end
    Camera.CameraType=MOV.tp3Orig or Enum.CameraType.Custom
end

-- ── SLIDE JUMP ────────────────────────────────────────────────────
local function enableSlide()
    if MOV.slideConn then MOV.slideConn:Disconnect() end
    MOV.slideConn=UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode==Enum.KeyCode.C or input.KeyCode==Enum.KeyCode.RightControl then
            task.delay(0.05,function()
                VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
            end)
        end
    end)
end

local function disableSlide()
    if MOV.slideConn then MOV.slideConn:Disconnect(); MOV.slideConn=nil end
end

-- ── INPUT ─────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input,gp)
    keysHeld[input.KeyCode]=true
    if MOV.clickTp and not gp and input.KeyCode==Enum.KeyCode.Z then
        local char=getChar(); if not char then return end
        local mouse=LocalPlayer:GetMouse()
        local ray=Camera:ScreenPointToRay(mouse.X,mouse.Y)
        local rp=RaycastParams.new()
        rp.FilterDescendantsInstances={char}; rp.FilterType=Enum.RaycastFilterType.Blacklist
        local res=workspace:Raycast(ray.Origin,ray.Direction*1000,rp)
        if res then char:PivotTo(CFrame.new(res.Position+Vector3.new(0,3,0))) end
    end
end)
UserInputService.InputEnded:Connect(function(input) keysHeld[input.KeyCode]=false end)

-- ── CLEANUP ───────────────────────────────────────────────────────
local function cleanup()
    stopFly(); disableTP3(); disableSlide()
    pcall(function() RunService:UnbindFromRenderStep('AspectNoclip')  end)
    pcall(function() RunService:UnbindFromRenderStep('AspectAntiRag') end)
    local char=getChar()
    if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=true end end end
    workspace.Gravity=196.2
end

return {
    state      = MOV,
    startFly   = startFly,
    stopFly    = stopFly,
    enableTP3  = enableTP3,
    disableTP3 = disableTP3,
    enableSlide= enableSlide,
    disableSlide=disableSlide,
    cleanup    = cleanup,
}
