-- ================================================================
--  Aspect Hub | rivals.lua
--  github.com/Lucid788/aspect/rivals.lua
-- ================================================================

local Players          = game:GetService('Players')
local RunService       = game:GetService('RunService')
local ReplicatedStorage= game:GetService('ReplicatedStorage')
local VirtualInputManager= game:GetService('VirtualInputManager')
local LocalPlayer      = Players.LocalPlayer

local RIV = {
    rapidFire=false, rapidFireRunning=false,
    rapidDash=false, rapidDashRunning=false,
    subspaceHRP=nil, subspaceConn=nil, subspaceRefConn=nil,
    autoEquip=false, autoEquipWeapons={'Assault Rifle','Katana','Grenade','Medkit'},
    autoBan=false, autoBanWeapons={'Riot Shield','Minigun'}, autoBanConn=nil,
    autoQueue=false, autoQueueMode='1v1', autoQueueConn=nil,
    antiTrowel=false, antiTrowelConn=nil,
    hitNotify=false, hitNotifyConn=nil,
    modDetector=false,
    respawn=false, collect=false,
    equip=false, equipSlot='1',
}

local Notify = nil  -- injected by main

local function setNotify(fn) Notify = fn end

local function getHRP()
    local c=LocalPlayer.Character; return c and c:FindFirstChild('HumanoidRootPart')
end

-- ── GC ATTRIBUTE TOGGLE ───────────────────────────────────────────
local function toggleGCAttr(attr, val)
    task.spawn(function()
        for _,gcVal in pairs(getgc(true)) do
            if type(gcVal)=='table' and rawget(gcVal,attr)~=nil then
                rawset(gcVal,attr,val)
            end
        end
    end)
end

-- ── RAPID FIRE ────────────────────────────────────────────────────
local function startRapidFire()
    if RIV.rapidFireRunning then return end
    RIV.rapidFireRunning=true
    task.spawn(function()
        while RIV.rapidFire do toggleGCAttr('ShootCooldown',0); task.wait(0.5) end
        RIV.rapidFireRunning=false; toggleGCAttr('ShootCooldown',0.11)
    end)
end

-- ── RAPID DASH ────────────────────────────────────────────────────
local function startRapidDash()
    if RIV.rapidDashRunning then return end
    RIV.rapidDashRunning=true
    task.spawn(function()
        while RIV.rapidDash do toggleGCAttr('DashCooldown',0); task.wait(0.5) end
        RIV.rapidDashRunning=false; toggleGCAttr('DashCooldown',4)
    end)
end

-- ── ANTI SUBSPACE ─────────────────────────────────────────────────
local function startAntiSubspace()
    RIV.subspaceRefConn=RunService.Heartbeat:Connect(function()
        pcall(function() RIV.subspaceHRP=LocalPlayer.Character.HumanoidRootPart end)
    end)
    local last=0
    RIV.subspaceConn=RunService.Heartbeat:Connect(function()
        local now=tick(); if now-last<0.033 then return end; last=now
        pcall(function()
            if not RIV.subspaceHRP then return end
            for _,s in workspace:GetChildren() do
                if s.Name=='SubspaceTripmineHitbox' then
                    local hb=s:FindFirstChild('Hitbox')
                    if hb then firetouchinterest(RIV.subspaceHRP,hb,1); firetouchinterest(RIV.subspaceHRP,hb,0) end
                end
            end
        end)
    end)
    if Notify then Notify('Anti Subspace','Active!') end
end

local function stopAntiSubspace()
    if RIV.subspaceConn    then RIV.subspaceConn:Disconnect();    RIV.subspaceConn=nil    end
    if RIV.subspaceRefConn then RIV.subspaceRefConn:Disconnect(); RIV.subspaceRefConn=nil end
    RIV.subspaceHRP=nil
    if Notify then Notify('Anti Subspace','Stopped.') end
end

-- ── ANTI TROWEL ───────────────────────────────────────────────────
local function startAntiTrowel()
    local last=0
    RIV.antiTrowelConn=RunService.Heartbeat:Connect(function()
        local now=tick(); if now-last<0.1 then return end; last=now
        for _,obj in ipairs(workspace:GetChildren()) do
            if obj.Name=='TrowelWall' then pcall(function() obj:Destroy() end) end
        end
    end)
end

local function stopAntiTrowel()
    if RIV.antiTrowelConn then RIV.antiTrowelConn:Disconnect(); RIV.antiTrowelConn=nil end
end

-- ── HIT NOTIFY ────────────────────────────────────────────────────
local function startHitNotify()
    local Replicate=nil
    pcall(function()
        Replicate=ReplicatedStorage:WaitForChild('Remotes',5):WaitForChild('Replication',5)
            :WaitForChild('Fighter',5):WaitForChild('Replicate',5)
    end)
    if not Replicate then
        if Notify then Notify('Hit Notify','Replicate remote not found!') end; return
    end
    RIV.hitNotifyConn=Replicate.OnClientEvent:Connect(function(...)
        local args={...}; local arg5=args[5]
        if arg5 then
            local t=type(arg5)
            if t=='number' or (t=='string' and arg5=='.') then
                if Notify then Notify('Hit!','Damage: '..tostring(arg5),4) end
            end
        end
    end)
end

local function stopHitNotify()
    if RIV.hitNotifyConn then RIV.hitNotifyConn:Disconnect(); RIV.hitNotifyConn=nil end
end

-- ── AUTO EQUIP WEAPONS ────────────────────────────────────────────
local lastAutoEquipTick=0
local function doAutoEquip()
    if tick()-lastAutoEquipTick<2 then return end; lastAutoEquipTick=tick()
    task.spawn(function()
        task.wait(0.3)
        pcall(function()
            ReplicatedStorage.Remotes.Replication.Fighter.PickWeapons:FireServer(unpack({RIV.autoEquipWeapons}))
        end)
    end)
end

task.spawn(function()
    local PlayerGui=LocalPlayer:WaitForChild('PlayerGui')
    local mainGui=PlayerGui:WaitForChild('MainGui',15)
    if mainGui then
        mainGui.DescendantAdded:Connect(function(obj)
            if not RIV.autoEquip then return end
            if obj:IsA('TextLabel') and obj.Text and obj.Text:lower():find('weapon') then doAutoEquip() end
        end)
    end
    local srg=PlayerGui:WaitForChild('ShootingRangeGui',15)
    if srg then
        srg:GetPropertyChangedSignal('Enabled'):Connect(function()
            if RIV.autoEquip and srg.Enabled then doAutoEquip() end
        end)
    end
end)

-- ── AUTO BAN ──────────────────────────────────────────────────────
local autoBanConn=nil
local function startAutoBan()
    if autoBanConn then autoBanConn:Disconnect() end
    local VR=nil
    pcall(function()
        VR=ReplicatedStorage:WaitForChild('Remotes',5):WaitForChild('Duels',5):WaitForChild('Vote',5)
    end)
    if not VR then
        if Notify then Notify('Auto Ban','Vote remote not found!') end
        RIV.autoBan=false; return
    end
    local idx,last=1,0
    autoBanConn=RunService.Heartbeat:Connect(function()
        local now=tick(); if now-last<1 then return end; last=now
        if not RIV.autoBan then return end
        pcall(function() VR:FireServer(RIV.autoBanWeapons[idx]) end)
        idx=idx%#RIV.autoBanWeapons+1
    end)
end

local function stopAutoBan()
    if autoBanConn then autoBanConn:Disconnect(); autoBanConn=nil end
end

-- ── AUTO QUEUE ────────────────────────────────────────────────────
local JoinQueueRF=nil; local LeaveQueueRE=nil
task.spawn(function()
    local ok,Remotes=pcall(function() return ReplicatedStorage:WaitForChild('Remotes',10) end)
    if not ok or not Remotes then return end
    local ok2,MM=pcall(function() return Remotes:WaitForChild('Matchmaking',10) end)
    if not ok2 or not MM then return end
    repeat task.wait(0.2)
        JoinQueueRF  = MM:FindFirstChild('JoinQueue')
        LeaveQueueRE = MM:FindFirstChild('LeaveQueue')
    until (JoinQueueRF and JoinQueueRF.ClassName=='RemoteFunction')
       and (LeaveQueueRE and LeaveQueueRE.ClassName=='RemoteEvent')
end)

local function startAutoQueue()
    if RIV.autoQueueConn then RIV.autoQueueConn:Disconnect() end
    local last=0
    RIV.autoQueueConn=RunService.Heartbeat:Connect(function()
        local now=tick(); if now-last<3 then return end; last=now
        if not RIV.autoQueue or not JoinQueueRF then return end
        pcall(function() JoinQueueRF:InvokeServer(RIV.autoQueueMode) end)
    end)
end

local function stopAutoQueue()
    if RIV.autoQueueConn then RIV.autoQueueConn:Disconnect(); RIV.autoQueueConn=nil end
end

local function joinQueue(mode)
    if not JoinQueueRF then return false,'Remote not found!' end
    local ok,res=pcall(function() return JoinQueueRF:InvokeServer(mode) end)
    return ok, tostring(res)
end

local function leaveQueue()
    if not LeaveQueueRE then return false,'Remote not found!' end
    pcall(function() LeaveQueueRE:FireServer() end)
    return true,''
end

-- ── AUTO RESPAWN ──────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.2)
        if RIV.respawn then
            local c=LocalPlayer.Character; local hum=c and c:FindFirstChildOfClass('Humanoid')
            if hum and hum.Health<=0 then
                local dl=tick()+2
                while tick()<dl do
                    VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- ── AUTO COLLECT ──────────────────────────────────────────────────
local lastCollect=0
RunService.Heartbeat:Connect(function()
    if not RIV.collect then return end
    local now=tick(); if now-lastCollect<0.05 then return end; lastCollect=now
    local hrp=getHRP(); if not hrp then return end
    for _,obj in pairs(workspace:GetChildren()) do
        if obj.Name=='_drop' and obj:FindFirstChild('TouchInterest') then
            pcall(firetouchinterest,hrp,obj,0); pcall(firetouchinterest,hrp,obj,1)
        end
    end
end)

-- ── AUTO EQUIP SLOT ───────────────────────────────────────────────
local slotMap={['1']=Enum.KeyCode.One,['2']=Enum.KeyCode.Two,['3']=Enum.KeyCode.Three,['4']=Enum.KeyCode.Four}
local lastEquipHb=0
RunService.Heartbeat:Connect(function()
    if not RIV.equip then return end
    local now=tick(); if now-lastEquipHb<0.5 then return end; lastEquipHb=now
    local kc=slotMap[RIV.equipSlot] or Enum.KeyCode.One
    VirtualInputManager:SendKeyEvent(true,kc,false,game); task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false,kc,false,game)
end)

-- ── CLEANUP ───────────────────────────────────────────────────────
local function cleanup()
    stopAutoBan(); stopAutoQueue(); stopAntiSubspace(); stopAntiTrowel(); stopHitNotify()
    RIV.rapidFire=false; RIV.rapidDash=false
end

return {
    state            = RIV,
    setNotify        = setNotify,
    startRapidFire   = startRapidFire,
    startRapidDash   = startRapidDash,
    startAntiSubspace= startAntiSubspace,
    stopAntiSubspace = stopAntiSubspace,
    startAntiTrowel  = startAntiTrowel,
    stopAntiTrowel   = stopAntiTrowel,
    startHitNotify   = startHitNotify,
    stopHitNotify    = stopHitNotify,
    startAutoBan     = startAutoBan,
    stopAutoBan      = stopAutoBan,
    startAutoQueue   = startAutoQueue,
    stopAutoQueue    = stopAutoQueue,
    joinQueue        = joinQueue,
    leaveQueue       = leaveQueue,
    cleanup          = cleanup,
}
