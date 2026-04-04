-- ================================================================
--   Aspect Hub  |  main.lua  v10.0
--   github.com/Lucid788/aspect
--   Modular build: each system loaded from GitHub
-- ================================================================
-- HOW THIS WORKS:
--   Each feature lives in its own module on GitHub:
--     github.com/Lucid788/aspect/aimbot.lua
--     github.com/Lucid788/aspect/triggerbot.lua
--     github.com/Lucid788/aspect/esp.lua
--     github.com/Lucid788/aspect/movement.lua
--     github.com/Lucid788/aspect/rivals.lua
--     github.com/Lucid788/aspect/visuals.lua
--   main.lua (this file) loads all modules and builds the UI.
-- ================================================================

local BASE = 'https://raw.githubusercontent.com/Lucid788/aspect/main/'

local function loadModule(name)
    return loadstring(game:HttpGet(BASE .. name .. '.lua'))()
end

-- ── LinoriaLib ───────────────────────────────────────────────────
local repo         = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library      = loadstring(game:HttpGet(repo..'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo..'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo..'addons/SaveManager.lua'))()
local Toggles      = Library.Toggles
local Options      = Library.Options

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor          = true
Library.NotifySide                = 'Right'

-- ── Services ─────────────────────────────────────────────────────
local Players          = game:GetService('Players')
local RunService       = game:GetService('RunService')
local TweenService     = game:GetService('TweenService')
local Lighting         = game:GetService('Lighting')
local LocalPlayer      = Players.LocalPlayer

-- ── Notify (7s default so it's readable) ────────────────────────
local function Notify(title, content, dur)
    Library:Notify(content, title, dur or 7)
end

-- ── Load Modules ─────────────────────────────────────────────────
local AimMod  = loadModule('aimbot')
local TrigMod = loadModule('triggerbot')
local EspMod  = loadModule('esp')
local MovMod  = loadModule('movement')
local RivMod  = loadModule('rivals')
local VisMod  = loadModule('visuals')

-- Inject notify into rivals module
RivMod.setNotify(Notify)

-- Shorthand references
local AB   = AimMod.state
local TB   = TrigMod.state
local ESP  = EspMod.state
local MOV  = MovMod.state
local RIV  = RivMod.state
local VIS  = VisMod.vis
local CC   = VisMod.cc
local CROSS= VisMod.cross
local FUN  = VisMod.fun
local GUN  = VisMod.gun

local RIVALS_WEAPONS = {
    'Assault Rifle','Sniper','Burst Rifle','Paintball Gun',
    'Energy Rifle','Bow','Flame Thrower','Shotgun','Crossbow',
    'Gunblade','Grenade Launcher','RPG','Minigun',
    'Revolver','Slingshot','Energy Pistols','Uzi','Shorty',
    'Flare Gun','Daggers','Spray','Handgun',
    'Katana','Scythe','Battle Axe','Fists','Riot Shield','Knife','Chainsaw',
    'Medkit','Molotov','Grenade','War Horn','Freeze Ray',
    'Satchel','Jump Pad','Subspace Tripmine','Flash Grenade',
}

-- ── Blur ─────────────────────────────────────────────────────────
local blurEffect  = Instance.new('BlurEffect')
blurEffect.Size   = 0
blurEffect.Parent = Lighting
local blurEnabled = true
local lastBlurVis = false

RunService.Heartbeat:Connect(function()
    local vis = Library.Visible == true
    if vis ~= lastBlurVis then
        lastBlurVis = vis
        if blurEnabled then
            TweenService:Create(blurEffect, TweenInfo.new(0.25), {Size = vis and 14 or 0}):Play()
        else
            blurEffect.Size = 0
        end
    end
end)

-- ── Window ───────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title='Aspect Hub', Center=true, AutoShow=true, Resizable=true,
    ShowCustomCursor=true, UnlockMouseWhileOpen=true,
    TabPadding=8, MenuFadeTime=0.2,
})

Library:SetWatermarkVisibility(true)
local _fps,_fpsC,_fpsT=60,0,tick()
RunService.RenderStepped:Connect(function()
    _fpsC+=1
    if tick()-_fpsT>=1 then _fps=_fpsC; _fpsC=0; _fpsT=tick() end
    Library:SetWatermark(('Aspect Hub  |  %d FPS'):format(_fps))
end)

local Tabs = {
    Combat    = Window:AddTab('Combat'),
    Awareness = Window:AddTab('Awareness'),
    Movement  = Window:AddTab('Movement'),
    Misc      = Window:AddTab('Misc'),
    Settings  = Window:AddTab('Settings'),
}

-- ================================================================
--  COMBAT TAB
-- ================================================================
local AimG  = Tabs.Combat:AddLeftGroupbox('Aimbot')
local TrigG = Tabs.Combat:AddRightGroupbox('Triggerbot')
local RapG  = Tabs.Combat:AddLeftGroupbox('Rivals Rapid')

-- ── Aimbot ───────────────────────────────────────────────────────
AimG:AddToggle('AimbotEnabled',{
    Text='Enable Aimbot', Default=false,
    Tooltip='Lock onto nearest enemy in FOV. Keybind below activates it.',
    Callback=function(v) AB.enabled=v; Notify('Aimbot',v and 'Enabled' or 'Disabled') end,
})

-- Mode dropdown changes the KeyPicker mode
AimG:AddDropdown('AimbotMode',{
    Text='Activation Mode', Values={'Hold','Toggle','Always'}, Default=1,
    Callback=function(v)
        -- KeyPicker is registered AFTER this dropdown; use task.defer
        task.defer(function()
            local kp = Options['AimbotKeybind']
            if kp then pcall(function() kp:SetValue({kp.Value, v}) end) end
        end)
        Notify('Aimbot','Mode -> '..v)
    end,
})

-- KeyPicker: the return value IS the keybind object; store it in AB.keybind
local _aimLabel = AimG:AddLabel('Activation Keybind')
local _aimKP    = _aimLabel:AddKeyPicker('AimbotKeybind',{
    Default='Q', Mode='Hold', SyncToggleState=false, Text='Aimbot Key', NoUI=false,
})
-- Store reference immediately
AB.keybind = _aimKP

AimG:AddDropdown('AimbotPart',{
    Text='Aim Part', Values={'Head','HumanoidRootPart','UpperTorso'}, Default=1,
    Callback=function(v) AB.part=v; Notify('Aimbot','Part -> '..v) end,
})
AimG:AddSlider('AimbotFOV',{
    Text='FOV', Default=90, Min=10, Max=500, Rounding=0, Suffix='px',
    Callback=function(v) AB.fov=v; AimMod.fovCircle.Radius=v end,
})
AimG:AddSlider('AimbotSmooth',{
    Text='Smoothness', Default=50, Min=1, Max=100, Rounding=0, Suffix='%',
    Tooltip='Higher = slower tracking',
    Callback=function(v) AB.smooth=v/100 end,
})
AimG:AddToggle('AimbotTeamCheck',{Text='Team Check',Default=false,
    Callback=function(v) AB.teamCheck=v; Notify('Aimbot','Team Check '..(v and 'ON' or 'OFF')) end})
AimG:AddToggle('AimbotWallCheck',{Text='Wall Check',Default=false,
    Callback=function(v) AB.wallCheck=v; Notify('Aimbot','Wall Check '..(v and 'ON' or 'OFF')) end})
AimG:AddDivider()
AimG:AddToggle('FOVShow',{
    Text='Show FOV Circle', Default=false,
    Callback=function(v) AimMod.fovCircle.Visible=v end,
})
AimG:AddSlider('FOVRadius2',{
    Text='FOV Radius', Default=90, Min=10, Max=500, Rounding=0, Suffix='px',
    Callback=function(v) AB.fov=v; AimMod.fovCircle.Radius=v end,
})
AimG:AddSlider('FOVThickness',{
    Text='FOV Thickness', Default=15, Min=5, Max=80, Rounding=0, Suffix='x0.1',
    Callback=function(v) AimMod.fovCircle.Thickness=v/10 end,
})
AimG:AddLabel('FOV Color'):AddColorPicker('FOVColor',{
    Default=Color3.fromRGB(255,255,255), Title='FOV Circle Color',
    Callback=function(v) AimMod.fovCircle.Color=v end,
})

-- ── Triggerbot ───────────────────────────────────────────────────
TrigG:AddToggle('TrigEnabled',{
    Text='Enable Triggerbot', Default=false, Risky=true,
    Callback=function(v)
        TB.enabled=v
        if v then TrigMod.start() else TrigMod.stop() end
        Notify('Triggerbot',v and 'Enabled' or 'Disabled')
    end,
})
TrigG:AddDropdown('TrigMode',{
    Text='Activation Mode', Values={'Hold','Toggle','Always'}, Default=1,
    Callback=function(v)
        task.defer(function()
            local kp=Options['TrigKeybind']
            if kp then pcall(function() kp:SetValue({kp.Value,v}) end) end
        end)
        Notify('Triggerbot','Mode -> '..v)
    end,
})
local _trigLabel = TrigG:AddLabel('Activation Keybind')
local _trigKP    = _trigLabel:AddKeyPicker('TrigKeybind',{
    Default='MB1', Mode='Hold', SyncToggleState=false, Text='Trigger Key', NoUI=false,
})
TB.keybind = _trigKP

TrigG:AddSlider('TrigDelay',{
    Text='Fire Delay', Default=5, Min=0, Max=500, Rounding=0, Suffix='ms',
    Callback=function(v) TB.delay=v/1000; Notify('Triggerbot','Delay -> '..v..'ms') end,
})
TrigG:AddToggle('TrigTeamCheck',{Text='Team Check',Default=false,
    Callback=function(v) TB.teamCheck=v; Notify('Triggerbot','Team Check '..(v and 'ON' or 'OFF')) end})
TrigG:AddToggle('TrigWallCheck',{Text='Wall Check',Default=false,
    Callback=function(v) TB.wallCheck=v; Notify('Triggerbot','Wall Check '..(v and 'ON' or 'OFF')) end})

-- ── Rivals Rapid ─────────────────────────────────────────────────
RapG:AddToggle('RapidFire',{
    Text='Rapid Fire', Default=false, Risky=true,
    Callback=function(v) RIV.rapidFire=v; if v then RivMod.startRapidFire() end; Notify('Rapid Fire',v and 'ON' or 'OFF') end,
})
RapG:AddToggle('RapidDash',{
    Text='Rapid Dash (Scythe)', Default=false, Risky=true,
    Callback=function(v) RIV.rapidDash=v; if v then RivMod.startRapidDash() end; Notify('Rapid Dash',v and 'ON' or 'OFF') end,
})
RapG:AddDivider()
RapG:AddButton({Text='Anti Subspace (Start)', Func=function() RivMod.startAntiSubspace() end})
RapG:AddButton({Text='Anti Subspace (Stop)',  Func=function() RivMod.stopAntiSubspace()  end})
RapG:AddDivider()
RapG:AddToggle('HitNotify',{
    Text='Hit Notify', Default=false,
    Callback=function(v) RIV.hitNotify=v; if v then RivMod.startHitNotify() else RivMod.stopHitNotify() end; Notify('Hit Notify',v and 'ON' or 'OFF') end,
})

-- ================================================================
--  AWARENESS TAB
-- ================================================================
local ESPL  = Tabs.Awareness:AddLeftGroupbox('Player ESP')
local VisG  = Tabs.Awareness:AddRightGroupbox('Visual')
local CrosG = Tabs.Awareness:AddRightGroupbox('Crosshair')

ESPL:AddToggle('BoxESP',{Text='Box ESP',Default=false,
    Callback=function(v)
        ESP.box=v
        if v then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then EspMod.createBoxESP(p) end end
        else for p in pairs(EspMod.espBoxes) do EspMod.removeBoxESP(p) end end
        Notify('Box ESP',v and 'Enabled' or 'Disabled')
    end})
ESPL:AddToggle('LineESP',{Text='Line ESP',Default=false,
    Callback=function(v)
        ESP.line=v
        if v then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then EspMod.createLineESP(p) end end
        else for _,p in ipairs(Players:GetPlayers()) do EspMod.removeLineESP(p) end end
        Notify('Line ESP',v and 'Enabled' or 'Disabled')
    end})
ESPL:AddToggle('SkelESP',{Text='Skeleton ESP',Default=false,
    Callback=function(v)
        ESP.skel=v
        if v then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then EspMod.createSkelESP(p) end end
        else for p in pairs(EspMod.espSkel) do EspMod.removeSkelESP(p) end end
        Notify('Skeleton ESP',v and 'Enabled' or 'Disabled')
    end})
ESPL:AddToggle('CharmESP',{Text='Charm ESP (Glow)',Default=false,
    Callback=function(v) ESP.charm=v; EspMod.refreshCharm(); Notify('Charm ESP',v and 'Enabled' or 'Disabled') end})
ESPL:AddLabel('Glow Fill'):AddColorPicker('CharmFill',{
    Default=Color3.fromRGB(255,215,0), Title='Charm Fill',
    Callback=function(v) ESP.fillColor=v; for _,h in pairs(EspMod.charmHL) do if h and h.Parent then h.FillColor=v end end end})
ESPL:AddLabel('Glow Outline'):AddColorPicker('CharmOutline',{
    Default=Color3.fromRGB(255,255,255), Title='Charm Outline',
    Callback=function(v) ESP.outColor=v; for _,h in pairs(EspMod.charmHL) do if h and h.Parent then h.OutlineColor=v end end end})
ESPL:AddToggle('ESPTeamCheck',{Text='Team Check (ESP)',Default=false,
    Callback=function(v)
        ESP.teamCheck=v
        if v then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Team==LocalPlayer.Team then
                    EspMod.removeBoxESP(p);EspMod.removeLineESP(p);EspMod.removeSkelESP(p);EspMod.removeCharmESP(p)
                end
            end
        else
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer then
                    if ESP.box   then EspMod.createBoxESP(p)   end
                    if ESP.line  then EspMod.createLineESP(p)  end
                    if ESP.skel  then EspMod.createSkelESP(p)  end
                    if ESP.charm then EspMod.createCharmESP(p) end
                end
            end
        end
        Notify('ESP Team Check',v and 'ON' or 'OFF')
    end})

-- Rainbow Mode (with speed + gradient)
ESPL:AddDivider()
ESPL:AddToggle('RainbowESP',{Text='Rainbow Mode',Default=false,
    Callback=function(v) ESP.rainbow=v; if v then ESP.gradient=false end; Notify('Rainbow',v and 'ON' or 'OFF') end})
ESPL:AddToggle('GradientESP',{
    Text='Gradient Mode (per-player offset)',Default=false,
    Tooltip='Each player gets a different hue offset, creating a gradient effect across all players',
    Callback=function(v) ESP.gradient=v; if v then ESP.rainbow=false; Toggles['RainbowESP']:SetValue(false) end; Notify('Gradient',v and 'ON' or 'OFF') end})
ESPL:AddSlider('RainbowSpeed',{
    Text='Rainbow Speed', Default=4, Min=1, Max=50, Rounding=0, Suffix='x0.001',
    Tooltip='Higher = faster color cycling',
    Callback=function(v) ESP.rainbowSpeed=v*0.001 end})

-- Visual
VisG:AddToggle('Fullbright',{Text='Fullbright',Default=false,
    Callback=function(v) VIS.fullbright=v; VisMod.applyFullbright(v); Notify('Fullbright',v and 'ON' or 'OFF') end})

VisG:AddToggle('CCEnabled',{
    Text='Color Correction', Default=false,
    Tooltip='Apply a color filter to the entire game world',
    Callback=function(v) CC.enabled=v; if v then VisMod.applyCC() else VisMod.removeCC() end; Notify('Color Correction',v and 'ON' or 'OFF') end})
VisG:AddSlider('CCBrightness',{Text='Brightness',Default=0,Min=-100,Max=100,Rounding=0,Suffix='%',
    Callback=function(v) CC.brightness=v/100; local e=Lighting:FindFirstChild('AspectCC'); if e then e.Brightness=CC.brightness end end})
VisG:AddSlider('CCContrast',{Text='Contrast',Default=0,Min=-100,Max=100,Rounding=0,Suffix='%',
    Callback=function(v) CC.contrast=v/100; local e=Lighting:FindFirstChild('AspectCC'); if e then e.Contrast=CC.contrast end end})
VisG:AddSlider('CCSaturation',{Text='Saturation',Default=0,Min=-100,Max=100,Rounding=0,Suffix='%',
    Callback=function(v) CC.saturation=v/100; local e=Lighting:FindFirstChild('AspectCC'); if e then e.Saturation=CC.saturation end end})
VisG:AddLabel('Tint Color'):AddColorPicker('CCTintColor',{
    Default=Color3.fromRGB(255,255,255), Title='Color Correction Tint',
    Callback=function(v) CC.tintColor=v; local e=Lighting:FindFirstChild('AspectCC'); if e then e.TintColor=v end end})
VisG:AddDivider()

VisG:AddToggle('XRay',{Text='X-Ray',Default=false,
    Callback=function(v) VIS.xray=v; if v then VisMod.startXRay() else VisMod.stopXRay() end; Notify('X-Ray',v and 'ON' or 'OFF') end})
VisG:AddSlider('XRayRadius',{Text='X-Ray Radius',Default=200,Min=20,Max=600,Rounding=0,Suffix='st',
    Callback=function(v) VIS.xrayRadius=v end})
VisG:AddSlider('XRayTransp',{Text='Transparency',Default=35,Min=0,Max=90,Rounding=0,Suffix='%',
    Callback=function(v) VIS.xrayTrans=v/100 end})
VisG:AddDivider()
VisG:AddButton({Text='Apply Custom Skybox', Func=function() VisMod.applyCustomSkybox(); Notify('Skybox','Applied!') end})
VisG:AddButton({Text='Revert Original Skybox', Func=function() VisMod.revertSkybox(); Notify('Skybox','Reverted!') end})

-- Crosshair
CrosG:AddToggle('CrossEnabled',{Text='Custom Crosshair',Default=false,
    Callback=function(v) CROSS.enabled=v; VisMod.crossBuild(); Notify('Crosshair',v and 'Enabled' or 'Disabled') end})
CrosG:AddSlider('CrossBarLen',{Text='Bar Length',Default=10,Min=2,Max=80,Rounding=0,Suffix='px',
    Callback=function(v) CROSS.barLen=v end})
CrosG:AddSlider('CrossBarThick',{Text='Bar Thickness',Default=2,Min=1,Max=10,Rounding=0,Suffix='px',
    Callback=function(v) CROSS.barThick=v; VisMod.crossBuild() end})
CrosG:AddSlider('CrossBarGap',{Text='Bar Gap',Default=4,Min=0,Max=40,Rounding=0,Suffix='px',
    Callback=function(v) CROSS.barGap=v end})
CrosG:AddSlider('CrossAlpha',{Text='Transparency',Default=100,Min=0,Max=100,Rounding=0,Suffix='%',
    Callback=function(v) CROSS.barAlpha=v/100 end})
CrosG:AddLabel('Bar Color'):AddColorPicker('CrossBarColor',{Default=Color3.fromRGB(255,255,255),Title='Bar Color',
    Callback=function(v) CROSS.barColor=v end})
CrosG:AddSlider('CrossOutline',{Text='Outline Size',Default=1,Min=0,Max=6,Rounding=0,Suffix='px',
    Callback=function(v) CROSS.outlineSize=v; VisMod.crossBuild() end})
CrosG:AddLabel('Outline Color'):AddColorPicker('CrossOutlineColor',{Default=Color3.fromRGB(0,0,0),Title='Outline Color',
    Callback=function(v) CROSS.outlineColor=v end})
CrosG:AddDivider()
CrosG:AddToggle('CrossCircleOn',{Text='Show Circle',Default=false,
    Callback=function(v) CROSS.circleOn=v; VisMod.crossBuild() end})
CrosG:AddSlider('CrossCircleR',{Text='Circle Radius',Default=20,Min=5,Max=200,Rounding=0,Suffix='px',
    Callback=function(v) CROSS.circleR=v end})
CrosG:AddToggle('CrossCircleFill',{Text='Fill Circle',Default=false,
    Callback=function(v) CROSS.circleFill=v end})
CrosG:AddSlider('CrossCircleAlpha',{Text='Circle Transparency',Default=80,Min=0,Max=100,Rounding=0,Suffix='%',
    Callback=function(v) CROSS.circleAlpha=v/100 end})
CrosG:AddLabel('Circle Color'):AddColorPicker('CrossCircleColor',{Default=Color3.fromRGB(255,255,255),Title='Circle Color',
    Callback=function(v) CROSS.circleColor=v end})
CrosG:AddDivider()
CrosG:AddToggle('CrossRotateOn',{Text='Rotate',Default=false,
    Callback=function(v) CROSS.rotateOn=v end})
CrosG:AddSlider('CrossRotateSpeed',{Text='Rotation Speed',Default=2,Min=1,Max=20,Rounding=1,
    Callback=function(v) CROSS.rotateSpeed=v end})

-- ================================================================
--  MOVEMENT TAB
-- ================================================================
local FlyG  = Tabs.Movement:AddLeftGroupbox('Fly')
local MoveG = Tabs.Movement:AddLeftGroupbox('Speed & Jump')
local UtilG = Tabs.Movement:AddLeftGroupbox('Utilities')
local CamG  = Tabs.Movement:AddRightGroupbox('3rd Person Camera')
local PhysG = Tabs.Movement:AddRightGroupbox('Physics')
local OrbG  = Tabs.Movement:AddRightGroupbox('Orbit')

FlyG:AddToggle('FlyEnabled',{Text='Fly (WASD+Space/LShift)',Default=false,
    Callback=function(v) MOV.fly=v; if v then MovMod.startFly() else MovMod.stopFly() end; Notify('Fly',v and 'Enabled' or 'Disabled') end})
FlyG:AddSlider('FlySpeed',{Text='Fly Speed',Default=50,Min=5,Max=500,Rounding=0,Suffix='st/s',
    Callback=function(v) MOV.flySpeed=v end})

MoveG:AddToggle('SpeedEnabled',{Text='Speed Boost',Default=false,
    Callback=function(v) MOV.speed=v; Notify('Speed',v and 'ON' or 'OFF') end})
MoveG:AddSlider('SpeedVal',{Text='Speed',Default=50,Min=16,Max=500,Rounding=0,Suffix='st/s',
    Callback=function(v) MOV.speedVal=v end})
MoveG:AddDivider()
MoveG:AddToggle('JumpEnabled',{Text='Jump Boost',Default=false,
    Callback=function(v) MOV.jump=v; Notify('Jump',v and 'ON' or 'OFF') end})
MoveG:AddSlider('JumpPower',{Text='Jump Power',Default=80,Min=16,Max=500,Rounding=0,
    Callback=function(v) MOV.jumpPower=v end})
MoveG:AddToggle('InfJump',{Text='Infinite Jump',Default=false,
    Callback=function(v) MOV.infJump=v; Notify('Inf Jump',v and 'ON' or 'OFF') end})
MoveG:AddDivider()
MoveG:AddToggle('SwimEnabled',{Text='Swim Speed',Default=false,
    Callback=function(v) MOV.swim=v; Notify('Swim',v and 'ON' or 'OFF') end})
MoveG:AddSlider('SwimSpeed',{Text='Swim Speed',Default=40,Min=5,Max=300,Rounding=0,Suffix='st/s',
    Callback=function(v) MOV.swimSpeed=v end})

UtilG:AddToggle('NoclipEnabled',{Text='Noclip',Default=false,Risky=true,
    Callback=function(v)
        MOV.noclip=v
        if not v then
            local char=LocalPlayer.Character
            if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=true end end end
        end
        Notify('Noclip',v and 'ON' or 'OFF')
    end})
UtilG:AddToggle('ClickTP',{Text='Click TP (Z key)',Default=false,
    Callback=function(v) MOV.clickTp=v; Notify('Click TP',v and 'ON' or 'OFF') end})
UtilG:AddToggle('SlideJump',{Text='Auto Slide Jump (C/RCtrl)',Default=false,
    Callback=function(v) MOV.slideJump=v; if v then MovMod.enableSlide() else MovMod.disableSlide() end; Notify('Slide Jump',v and 'ON' or 'OFF') end})
UtilG:AddToggle('AntiRag',{Text='Anti-Ragdoll',Default=false,
    Callback=function(v) MOV.antiRag=v; Notify('Anti-Ragdoll',v and 'ON' or 'OFF') end})

CamG:AddToggle('TP3Enabled',{Text='3rd Person Camera',Default=false,
    Callback=function(v) MOV.tp3=v; if v then MovMod.enableTP3() else MovMod.disableTP3() end; Notify('3rd Person',v and 'Enabled' or 'Disabled') end})
CamG:AddSlider('TP3Dist',{Text='Distance',Default=14,Min=3,Max=80,Rounding=0,Suffix='st',
    Callback=function(v) MOV.tp3Dist=v end})
CamG:AddSlider('TP3YOff',{Text='Y Offset',Default=2,Min=-5,Max=15,Rounding=1,Suffix='st',
    Callback=function(v) MOV.tp3YOff=v end})

PhysG:AddToggle('LowGrav',{Text='Low Gravity',Default=false,
    Callback=function(v) MOV.lowGrav=v; if not v then workspace.Gravity=196.2 end; Notify('Low Gravity',v and 'ON' or 'OFF') end})
PhysG:AddSlider('LowGravVal',{Text='Gravity Value',Default=20,Min=0,Max=196,Rounding=0,
    Callback=function(v) MOV.lowGravVal=v end})
PhysG:AddButton({Text='Reset Gravity',
    Func=function() MOV.lowGrav=false; workspace.Gravity=196.2; pcall(function() Toggles['LowGrav']:SetValue(false) end); Notify('Gravity','Reset to 196.2') end})

OrbG:AddToggle('OrbitEnabled',{Text='Orbit Nearest Player',Default=false,Risky=true,
    Callback=function(v) MOV.orbit=v; if not v then MOV.orbitTarget=nil end; Notify('Orbit',v and 'Enabled' or 'Disabled') end})
OrbG:AddSlider('OrbitSpeed',{Text='Orbit Speed',Default=1,Min=0,Max=10,Rounding=1,
    Callback=function(v) MOV.orbitSpeed=v end})
OrbG:AddSlider('OrbitDist',{Text='Orbit Distance',Default=8,Min=2,Max=60,Rounding=0,Suffix='st',
    Callback=function(v) MOV.orbitDist=v end})

-- ================================================================
--  MISC TAB
-- ================================================================
local QueueG   = Tabs.Misc:AddLeftGroupbox('Queue & Matchmaking')
local RivMG    = Tabs.Misc:AddLeftGroupbox('Rivals Functions')
local FunG     = Tabs.Misc:AddRightGroupbox('Fun & Visuals')
local SpooferG = Tabs.Misc:AddRightGroupbox('Spoofer')

QueueG:AddDropdown('QueueMode',{
    Text='Queue Mode',
    Values={'1v1','2v2','3v3','4v4','5v5','Ranked 1v1','Ranked 2v2','Ranked 3v3'},
    Default=1,
    Callback=function(v) RIV.autoQueueMode=v; Notify('Queue','Mode -> '..v) end,
})
QueueG:AddButton({Text='Join Queue',
    Func=function()
        local ok,res=RivMod.joinQueue(RIV.autoQueueMode)
        Notify('Queue',ok and ('Joined '..RIV.autoQueueMode) or ('Err: '..res))
    end})
QueueG:AddButton({Text='Leave Queue',
    Func=function()
        local ok,res=RivMod.leaveQueue()
        Notify('Queue',ok and 'Left!' or ('Err: '..res))
    end})
QueueG:AddToggle('AutoQueue',{Text='Auto Queue',Default=false,
    Tooltip='Auto-joins selected queue every 3s',
    Callback=function(v) RIV.autoQueue=v; if v then RivMod.startAutoQueue() else RivMod.stopAutoQueue() end; Notify('Auto Queue',v and 'ON' or 'OFF') end})
QueueG:AddDivider()
QueueG:AddToggle('AutoRespawn',{Text='Auto Respawn',Default=false,
    Callback=function(v) RIV.respawn=v; Notify('Auto Respawn',v and 'ON' or 'OFF') end})
QueueG:AddToggle('AutoCollect',{Text='FFA Auto Collect',Default=false,
    Callback=function(v) RIV.collect=v; Notify('Auto Collect',v and 'ON' or 'OFF') end})
QueueG:AddToggle('AutoEquipSlot',{Text='Auto Equip Hotbar',Default=false,
    Callback=function(v) RIV.equip=v; Notify('Auto Equip',v and 'ON' or 'OFF') end})
QueueG:AddDropdown('AutoEquipSlotNum',{Text='Hotbar Slot',Values={'1','2','3','4'},Default=1,
    Callback=function(v) RIV.equipSlot=v end})

RivMG:AddToggle('RivAutoEquip',{Text='Auto Equip Weapons',Default=false,
    Callback=function(v) RIV.autoEquip=v; Notify('Auto Equip Weapons',v and 'ON' or 'OFF') end})
RivMG:AddDropdown('RivWeapon1',{Text='Slot 1',Values=RIVALS_WEAPONS,Default=1,Callback=function(v) RIV.autoEquipWeapons[1]=v end})
RivMG:AddDropdown('RivWeapon2',{Text='Slot 2',Values=RIVALS_WEAPONS,Default=23,Callback=function(v) RIV.autoEquipWeapons[2]=v end})
RivMG:AddDropdown('RivWeapon3',{Text='Slot 3',Values=RIVALS_WEAPONS,Default=31,Callback=function(v) RIV.autoEquipWeapons[3]=v end})
RivMG:AddDropdown('RivWeapon4',{Text='Slot 4',Values=RIVALS_WEAPONS,Default=30,Callback=function(v) RIV.autoEquipWeapons[4]=v end})
RivMG:AddDivider()
RivMG:AddToggle('AutoBan',{Text='Auto Ban Weapons',Default=false,Risky=true,
    Callback=function(v) RIV.autoBan=v; if v then RivMod.startAutoBan() else RivMod.stopAutoBan() end; Notify('Auto Ban',v and 'ON' or 'OFF') end})
RivMG:AddDropdown('BanWeapon1',{Text='Ban Vote 1',Values=RIVALS_WEAPONS,Default=27,Callback=function(v) RIV.autoBanWeapons[1]=v end})
RivMG:AddDropdown('BanWeapon2',{Text='Ban Vote 2',Values=RIVALS_WEAPONS,Default=13,Callback=function(v) RIV.autoBanWeapons[2]=v end})
RivMG:AddDivider()
RivMG:AddToggle('AntiTrowel',{Text='Anti Trowel Wall',Default=false,
    Callback=function(v) RIV.antiTrowel=v; if v then RivMod.startAntiTrowel() else RivMod.stopAntiTrowel() end; Notify('Anti Trowel',v and 'ON' or 'OFF') end})
RivMG:AddDivider()
RivMG:AddButton({Text='Get Rewards',
    Tooltip='ClaimFavoriteReward + ClaimLikeReward + ClaimNotificationsReward',
    Func=function()
        pcall(function()
            local data=game:GetService('ReplicatedStorage'):WaitForChild('Remotes',5):WaitForChild('Data',5)
            data:WaitForChild('ClaimFavoriteReward',3):FireServer()
            data:WaitForChild('ClaimLikeReward',3):FireServer()
            data:WaitForChild('ClaimNotificationsReward',3):FireServer()
        end)
        Notify('Rewards','Claimed all rewards!')
    end})
RivMG:AddDivider()
RivMG:AddToggle('ModDetector',{Text='Mod Detector',Default=false,
    Callback=function(v)
        RIV.modDetector=v
        if v then
            task.spawn(function()
                pcall(function()
                    shared.StaffDetectorLoading=false
                    local f=loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/Ukrubojvo/Modules/main/StaffDetector.lua'))
                    if f then f() end
                end)
            end)
            Notify('Mod Detector','Started!')
        end
    end})
RivMG:AddDivider()
RivMG:AddButton({Text='Copy Discord Invite',
    Func=function()
        local link='https://discord.gg/79HmCephst'
        if setclipboard then setclipboard(link); Notify('Discord','Copied!') end
    end})

FunG:AddToggle('JerkAnim',{Text='Jerk Animation',Default=false,Risky=true,
    Callback=function(v)
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass('Humanoid')
        if v and hum then
            local jerkTrack
            local anim=Instance.new('Animation')
            anim.AnimationId=(char:FindFirstChild('UpperTorso') and 'rbxassetid://698251653' or 'rbxassetid://72042024')
            jerkTrack=hum:LoadAnimation(anim)
            jerkTrack.Priority=Enum.AnimationPriority.Action; jerkTrack.Looped=true; jerkTrack:Play()
            FunG._jerkTrack=jerkTrack
        elseif FunG._jerkTrack then
            FunG._jerkTrack:Stop(); FunG._jerkTrack:Destroy(); FunG._jerkTrack=nil
        end
        Notify('Jerk Animation',v and 'ON' or 'OFF')
    end})

FunG:AddToggle('SynapseMode',{Text='Synapse Mode',Default=false,Risky=true,
    Tooltip='Loops animation: 0.1s play / 0.2s pause',
    Callback=function(v)
        FunG._synapseOn=v
        if v then
            task.spawn(function()
                local synapseTrack
                while FunG._synapseOn do
                    local char=LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass('Humanoid')
                    if hum then
                        if not synapseTrack then
                            local anim=Instance.new('Animation'); anim.AnimationId='rbxassetid://84357226139926'
                            synapseTrack=hum:LoadAnimation(anim)
                            synapseTrack.Priority=Enum.AnimationPriority.Action4; synapseTrack.Looped=false
                        end
                        synapseTrack:Play(0,1,10); task.wait(0.1); synapseTrack:Stop(0); task.wait(0.2)
                    else task.wait(0.5) end
                end
                if synapseTrack then pcall(function() synapseTrack:Stop(); synapseTrack:Destroy() end) end
            end)
        end
        Notify('Synapse Mode',v and 'ON' or 'OFF')
    end})

FunG:AddDivider()
FunG:AddToggle('GunCharm',{Text='Gun Charm',Default=false,
    Callback=function(v) GUN.charm=v; Notify('Gun Charm',v and 'ON' or 'OFF') end})
FunG:AddLabel('Gun Charm Color'):AddColorPicker('GunCharmColor',{
    Default=Color3.fromRGB(255,255,255), Title='Gun Charm Color',
    Callback=function(v) GUN.color=v end})
FunG:AddToggle('GunCharmRainbow',{Text='Rainbow Gun Charm',Default=false,
    Callback=function(v) GUN.rainbow=v; Notify('Rainbow Gun Charm',v and 'ON' or 'OFF') end})
FunG:AddDivider()
FunG:AddToggle('NoAnim',{Text='No Animation (FirstPerson)',Default=false,
    Callback=function(v) VisMod.setNoAnim(v); if v then VisMod.startNoAnim() else VisMod.stopNoAnim() end; Notify('No Animation',v and 'ON' or 'OFF') end})
FunG:AddDivider()
FunG:AddToggle('APEffect',{Text='AP Effect (Rotating Text)',Default=false,
    Callback=function(v) FUN.apEffect=v; if not v then VisMod.destroyAPEffect() end; Notify('AP Effect',v and 'ON' or 'OFF') end})
FunG:AddDivider()
FunG:AddButton({Text='Big Head All Players',
    Func=function()
        for _,player in ipairs(Players:GetPlayers()) do
            local char=player.Character; if not char then continue end
            local head=char:FindFirstChild('Head')
            if head and head:IsA('BasePart') then pcall(function() head.Size=head.Size*50 end) end
        end
        Notify('Big Head','Applied!')
    end})
FunG:AddDivider()
FunG:AddButton({Text='Apply Custom Skybox', Func=function() VisMod.applyCustomSkybox(); Notify('Skybox','Applied!') end})
FunG:AddButton({Text='Revert Original Skybox', Func=function() VisMod.revertSkybox(); Notify('Skybox','Reverted!') end})

SpooferG:AddInput('DisplayNameSpoof',{
    Default='', Numeric=false, Finished=true, ClearTextOnFocus=false,
    Text='Display Name', Placeholder='Enter display name',
    Callback=function(v)
        if v and v~='' then pcall(function() LocalPlayer.DisplayName=v end); Notify('Spoofer','Display Name -> '..v) end
    end})
SpooferG:AddInput('NameSpoof',{
    Default='', Numeric=false, Finished=true, ClearTextOnFocus=false,
    Text='Username', Placeholder='Enter username',
    Callback=function(v)
        if v and v~='' then pcall(function() LocalPlayer.Name=v end); Notify('Spoofer','Name -> '..v) end
    end})

-- ================================================================
--  SETTINGS TAB
-- ================================================================
local MenuG = Tabs.Settings:AddLeftGroupbox('Menu')

MenuG:AddToggle('ShowKeybindMenu',{Default=true,Text='Show Keybind List',
    Callback=function(v) pcall(function() Library.KeybindFrame.Visible=v end) end})
MenuG:AddToggle('CustomCursor',{Text='Custom Cursor',Default=true,
    Callback=function(v) Library.ShowCustomCursor=v end})
MenuG:AddToggle('UIBlur',{Text='Blur Background when Open',Default=true,
    Callback=function(v) blurEnabled=v; if not v then blurEffect.Size=0 end end})
MenuG:AddDivider()

-- THE ONLY CORRECT PATTERN:
-- 1. AddKeyPicker on a label, capture the return
-- 2. Set Library.ToggleKeybind = that object (NOT Options[...])
-- 3. Do this BEFORE SaveManager/ThemeManager calls
local _menuLabel = MenuG:AddLabel('Menu Toggle Keybind')
local _menuKP    = _menuLabel:AddKeyPicker('MenuKeybind',{
    Default='RightShift', NoUI=true, Text='Menu keybind',
})
-- Assign immediately (KeyPicker object is valid right now)
Library.ToggleKeybind = _menuKP

MenuG:AddDivider()
MenuG:AddButton({Text='Unload Aspect Hub',DoubleClick=true,Tooltip='Double-click to unload',
    Func=function() Library:Unload() end})

-- Theme + Config (after ToggleKeybind is wired)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder('AspectHub')
SaveManager:SetFolder('AspectHub/Rivals')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- ================================================================
--  UNLOAD
-- ================================================================
Library:OnUnload(function()
    TrigMod.stop(); MovMod.cleanup(); RivMod.cleanup(); EspMod.cleanup(); VisMod.cleanup()
    blurEffect.Size=0; blurEffect:Destroy()
    AimMod.fovCircle:Remove()
    Library.Unloaded=true
end)

SaveManager:LoadAutoloadConfig()

task.delay(0.5, function()
    Notify('Aspect Hub','Loaded! RightShift = toggle menu.',7)
end)
