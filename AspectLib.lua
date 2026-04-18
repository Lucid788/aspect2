-- ================================================================
--  AspectLib  |  Custom UI Library for Aspect Hub
--  Minimal, fast, exploit-safe — no external dependencies
--  Returns: Library object
-- ================================================================

local AspectLib = {}
AspectLib.__index = AspectLib

-- ── Services ──────────────────────────────────────────────────
local Players          = game:GetService('Players')
local RunService       = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService     = game:GetService('TweenService')
local LP               = Players.LocalPlayer

-- ── Constants ─────────────────────────────────────────────────
local COLORS = {
    bg        = Color3.fromRGB(14,  14,  18),
    sidebar   = Color3.fromRGB(10,  10,  14),
    panel     = Color3.fromRGB(20,  20,  26),
    element   = Color3.fromRGB(28,  28,  36),
    hover     = Color3.fromRGB(36,  36,  46),
    accent    = Color3.fromRGB(110, 80,  220),
    accentHov = Color3.fromRGB(130, 100, 240),
    text      = Color3.fromRGB(220, 220, 230),
    textDim   = Color3.fromRGB(130, 130, 150),
    border    = Color3.fromRGB(40,  40,  55),
    success   = Color3.fromRGB(80,  200, 120),
    danger    = Color3.fromRGB(220, 80,  80),
    notifBg   = Color3.fromRGB(18,  18,  24),
    toggleOn  = Color3.fromRGB(110, 80,  220),
    toggleOff = Color3.fromRGB(50,  50,  65),
}

local FONT     = Enum.Font.GothamSemibold
local FONT_REG = Enum.Font.Gotham
local TWEEN_I  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.08, Enum.EasingStyle.Quad)

-- ── Helpers ───────────────────────────────────────────────────
local function tween(obj, props, info)
    TweenService:Create(obj, info or TWEEN_I, props):Play()
end

local function makeInst(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in pairs(props) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

local function corner(r, parent)
    return makeInst('UICorner', {CornerRadius=UDim.new(0,r)}, parent)
end

local function stroke(t, c, parent)
    return makeInst('UIStroke', {Thickness=t, Color=c, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, parent)
end

local function pad(p, parent)
    local u = Instance.new('UIPadding')
    if type(p) == 'number' then
        u.PaddingTop=UDim.new(0,p); u.PaddingBottom=UDim.new(0,p)
        u.PaddingLeft=UDim.new(0,p); u.PaddingRight=UDim.new(0,p)
    else
        u.PaddingTop=UDim.new(0,p[1] or 0); u.PaddingBottom=UDim.new(0,p[2] or 0)
        u.PaddingLeft=UDim.new(0,p[3] or 0); u.PaddingRight=UDim.new(0,p[4] or 0)
    end
    u.Parent = parent; return u
end

local function listLayout(parent, pad_v, sort)
    local l = makeInst('UIListLayout', {
        FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        SortOrder=sort or Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0, pad_v or 4),
    }, parent)
    return l
end

-- Auto-resize container to fit list
local function autoSize(frame, list)
    local function update()
        frame.Size = UDim2.new(1,0,0, list.AbsoluteContentSize.Y)
    end
    list:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(update)
    update()
end

-- ── Notifications ─────────────────────────────────────────────
local notifGui = makeInst('ScreenGui', {
    Name='AspectLibNotif', ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    DisplayOrder=100
}, LP:WaitForChild('PlayerGui'))

local notifHolder = makeInst('Frame', {
    Size=UDim2.new(0,280,1,0), Position=UDim2.new(1,-295,0,0),
    BackgroundTransparency=1, Name='Holder',
}, notifGui)
listLayout(notifHolder, 8)
makeInst('UIPadding',{PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,16)}, notifHolder)

local function createNotif(title, body, dur, color)
    color = color or COLORS.accent
    local card = makeInst('Frame', {
        Size=UDim2.new(1,0,0,72), BackgroundColor3=COLORS.notifBg,
        ClipsDescendants=true, AutomaticSize=Enum.AutomaticSize.Y,
    }, notifHolder)
    corner(8, card)
    stroke(1, COLORS.border, card)

    local accent = makeInst('Frame', {
        Size=UDim2.new(0,3,1,0), BackgroundColor3=color,
    }, card)
    corner(2, accent)

    local inner = makeInst('Frame', {
        Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1,
    }, card)
    pad({10,10,2,4}, inner)
    listLayout(inner, 2)

    makeInst('TextLabel', {
        Size=UDim2.new(1,0,0,18), Text=title,
        Font=FONT, TextSize=13, TextColor3=COLORS.text,
        TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundTransparency=1,
    }, inner)
    makeInst('TextLabel', {
        Size=UDim2.new(1,0,0,14), Text=body,
        Font=FONT_REG, TextSize=11, TextColor3=COLORS.textDim,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,
    }, inner)

    -- Slide in
    card.Position = UDim2.new(1.1,0,0,0)
    tween(card, {Position=UDim2.new(0,0,0,0)})

    task.delay(dur or 4, function()
        tween(card, {BackgroundTransparency=1, Position=UDim2.new(1.1,0,0,0)})
        task.wait(0.25); card:Destroy()
    end)
end

-- ── Main Window ───────────────────────────────────────────────
function AspectLib:CreateWindow(cfg)
    cfg = cfg or {}
    local win = {}

    -- ── ScreenGui ──────────────────────────────────────────────
    local sg = makeInst('ScreenGui', {
        Name='AspectHub', ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=50,
    }, LP:WaitForChild('PlayerGui'))

    -- ── Root frame ─────────────────────────────────────────────
    local root = makeInst('Frame', {
        Name='Root', Size=UDim2.new(0, cfg.Width or 760, 0, cfg.Height or 520),
        Position=UDim2.new(0.5,-380,0.5,-260),
        BackgroundColor3=COLORS.bg, ClipsDescendants=true,
    }, sg)
    corner(10, root)
    stroke(1, COLORS.border, root)

    -- Drop shadow
    makeInst('ImageLabel', {
        Size=UDim2.new(1,30,1,30), Position=UDim2.new(0,-15,0,-15),
        BackgroundTransparency=1,
        Image='rbxassetid://5554236805',
        ImageColor3=Color3.new(0,0,0), ImageTransparency=0.55,
        ZIndex=0, ScaleType=Enum.ScaleType.Slice,
        SliceCenter=Rect.new(23,23,277,277),
    }, root)

    -- ── Title bar ──────────────────────────────────────────────
    local titleBar = makeInst('Frame', {
        Name='TitleBar', Size=UDim2.new(1,0,0,38),
        BackgroundColor3=COLORS.sidebar,
    }, root)

    makeInst('TextLabel', {
        Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,14,0,0),
        Text=cfg.Title or 'Aspect Hub',
        Font=FONT, TextSize=14, TextColor3=COLORS.text,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
    }, titleBar)

    -- Close + Minimize buttons
    local function mkBtn(txt, xOff, clr, cb)
        local b = makeInst('TextButton', {
            Size=UDim2.new(0,22,0,22),
            Position=UDim2.new(1,xOff,0.5,-11),
            BackgroundColor3=clr, Text=txt,
            Font=FONT, TextSize=11, TextColor3=COLORS.text,
        }, titleBar)
        corner(11, b)
        b.MouseButton1Click:Connect(cb)
        b.MouseEnter:Connect(function() tween(b,{BackgroundColor3=b.BackgroundColor3:Lerp(Color3.new(1,1,1),0.15)},TWEEN_FAST) end)
        b.MouseLeave:Connect(function() tween(b,{BackgroundColor3=clr},TWEEN_FAST) end)
        return b
    end

    local visible = true
    mkBtn('×', -8,  Color3.fromRGB(200,65,65),  function() root.Visible=false; visible=false end)
    mkBtn('−', -36, Color3.fromRGB(60,60,75), function()
        visible=not visible; root.Visible=visible
    end)

    -- Drag
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position
            startPos=root.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dragStart
            root.Position=UDim2.new(
                startPos.X.Scale, startPos.X.Offset+d.X,
                startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    -- Resize handle
    local resizeHandle = makeInst('TextButton', {
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(1,-16,1,-16),
        BackgroundTransparency=1, Text='', ZIndex=10,
    }, root)
    makeInst('ImageLabel',{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Image='rbxassetid://3926305904', ImageRectOffset=Vector2.new(628,420),
        ImageRectSize=Vector2.new(48,48), ImageColor3=COLORS.textDim,
    }, resizeHandle)

    local resizing, resizeStart, sizeStart
    resizeHandle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            resizing=true; resizeStart=i.Position
            sizeStart=root.AbsoluteSize
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-resizeStart
            root.Size=UDim2.new(0,math.clamp(sizeStart.X+d.X,500,1200),
                                0,math.clamp(sizeStart.Y+d.Y,380,900))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
    end)

    -- ── Body (sidebar + content) ────────────────────────────────
    local body = makeInst('Frame', {
        Name='Body', Size=UDim2.new(1,0,1,-38), Position=UDim2.new(0,0,0,38),
        BackgroundTransparency=1,
    }, root)

    -- Sidebar
    local sidebar = makeInst('Frame', {
        Name='Sidebar', Size=UDim2.new(0,140,1,0),
        BackgroundColor3=COLORS.sidebar,
    }, body)

    local tabList = makeInst('ScrollingFrame', {
        Size=UDim2.new(1,0,1,-8), Position=UDim2.new(0,0,0,4),
        BackgroundTransparency=1, ScrollBarThickness=2,
        ScrollBarImageColor3=COLORS.accent, CanvasSize=UDim2.new(0,0,0,0),
        ScrollingDirection=Enum.ScrollingDirection.Y,
    }, sidebar)
    local tabListLayout = listLayout(tabList, 2)
    pad({6,6,6,6}, tabList)
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    tabList:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        tabList.CanvasSize=UDim2.new(0,0,0,tabListLayout.AbsoluteContentSize.Y+12)
    end)

    -- Watermark at bottom of sidebar
    local wm = makeInst('TextLabel', {
        Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,1,-22),
        Text='Aspect Hub', Font=FONT_REG, TextSize=10,
        TextColor3=COLORS.textDim, BackgroundTransparency=1,
    }, sidebar)

    -- Content area
    local content = makeInst('Frame', {
        Name='Content', Size=UDim2.new(1,-140,1,0), Position=UDim2.new(0,140,0,0),
        BackgroundTransparency=1, ClipsDescendants=true,
    }, body)

    -- ── Tab management ─────────────────────────────────────────
    local tabs = {}
    local activeTab = nil
    local tabOrder = 0

    local function selectTab(t)
        if activeTab == t then return end
        if activeTab then
            tween(activeTab._btn,{BackgroundColor3=COLORS.element,TextColor3=COLORS.textDim},TWEEN_FAST)
            activeTab._frame.Visible = false
        end
        activeTab = t
        tween(t._btn,{BackgroundColor3=COLORS.accent,TextColor3=COLORS.text},TWEEN_FAST)
        t._frame.Visible = true
    end

    function win:AddTab(name, icon)
        tabOrder = tabOrder + 1
        local t = {}

        -- Sidebar button
        local btn = makeInst('TextButton', {
            Size=UDim2.new(1,0,0,32), BackgroundColor3=COLORS.element,
            Font=FONT, TextSize=12, TextColor3=COLORS.textDim,
            Text=(icon and icon..' ' or '')..(name or 'Tab'),
            TextXAlignment=Enum.TextXAlignment.Left,
            LayoutOrder=tabOrder,
        }, tabList)
        corner(6, btn)
        pad({0,0,10,0}, btn)

        btn.MouseEnter:Connect(function()
            if activeTab~=t then tween(btn,{BackgroundColor3=COLORS.hover},TWEEN_FAST) end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab~=t then tween(btn,{BackgroundColor3=COLORS.element},TWEEN_FAST) end
        end)
        btn.MouseButton1Click:Connect(function() selectTab(t) end)

        -- Content frame (two-column scroll)
        local frame = makeInst('ScrollingFrame', {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            ScrollBarThickness=3, ScrollBarImageColor3=COLORS.accent,
            CanvasSize=UDim2.new(0,0,0,0), Visible=false,
            ScrollingDirection=Enum.ScrollingDirection.Y,
        }, content)

        local colContainer = makeInst('Frame', {
            Size=UDim2.new(1,-12,0,0), Position=UDim2.new(0,6,0,6),
            BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
        }, frame)
        makeInst('UIListLayout',{
            FillDirection=Enum.FillDirection.Horizontal,
            HorizontalAlignment=Enum.HorizontalAlignment.Left,
            VerticalAlignment=Enum.VerticalAlignment.Top,
            SortOrder=Enum.SortOrder.LayoutOrder,
            Padding=UDim.new(0,6),
        }, colContainer)

        local leftCol = makeInst('Frame', {
            Size=UDim2.new(0.5,-3,0,0), BackgroundTransparency=1,
            AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=1,
        }, colContainer)
        listLayout(leftCol, 6)

        local rightCol = makeInst('Frame', {
            Size=UDim2.new(0.5,-3,0,0), BackgroundTransparency=1,
            AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=2,
        }, colContainer)
        listLayout(rightCol, 6)

        -- Update canvas height when content changes
        local function updateCanvas()
            local lh = leftCol.AbsoluteSize.Y
            local rh = rightCol.AbsoluteSize.Y
            colContainer.Size = UDim2.new(1,-12,0,math.max(lh,rh)+12)
            frame.CanvasSize = UDim2.new(0,0,0,math.max(lh,rh)+24)
        end
        leftCol:GetPropertyChangedSignal('AbsoluteSize'):Connect(updateCanvas)
        rightCol:GetPropertyChangedSignal('AbsoluteSize'):Connect(updateCanvas)

        t._btn   = btn
        t._frame = frame
        t._left  = leftCol
        t._right = rightCol
        t._colSide = 'left'  -- next groupbox goes here
        table.insert(tabs, t)

        if #tabs == 1 then selectTab(t) end

        -- ── Groupbox ─────────────────────────────────────────
        local function addGroupbox(name2, side)
            local g = {}
            local col = (side=='right') and t._right or t._left

            local box = makeInst('Frame', {
                Size=UDim2.new(1,0,0,0), BackgroundColor3=COLORS.panel,
                AutomaticSize=Enum.AutomaticSize.Y, ClipsDescendants=false,
            }, col)
            corner(8, box)
            stroke(1, COLORS.border, box)

            -- Header
            local hdr = makeInst('Frame', {
                Size=UDim2.new(1,0,0,30), BackgroundColor3=COLORS.sidebar,
            }, box)
            corner(8, hdr)
            -- bottom corners square
            makeInst('Frame', {Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=COLORS.sidebar}, hdr)

            makeInst('TextLabel', {
                Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,12,0,0),
                Text=name2, Font=FONT, TextSize=12,
                TextColor3=COLORS.textDim, TextXAlignment=Enum.TextXAlignment.Left,
                BackgroundTransparency=1,
            }, hdr)

            -- Accent strip left
            makeInst('Frame', {
                Size=UDim2.new(0,2,0,14), Position=UDim2.new(0,0,0.5,-7),
                BackgroundColor3=COLORS.accent,
            }, hdr)

            local itemList = makeInst('Frame', {
                Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,30),
                BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
            }, box)
            pad({4,6,8,8}, itemList)
            local il = listLayout(itemList, 4)

            -- ── Element Builders ────────────────────────────────

            -- Row wrapper
            local function row(h)
                local r2 = makeInst('Frame', {
                    Size=UDim2.new(1,0,0,h or 28),
                    BackgroundTransparency=1,
                }, itemList)
                return r2
            end

            -- Label inside row
            local function rowLabel(parent, txt, xAlign, yOff)
                return makeInst('TextLabel', {
                    Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,yOff or 0),
                    Text=txt, Font=FONT_REG, TextSize=12,
                    TextColor3=COLORS.textDim,
                    TextXAlignment=xAlign or Enum.TextXAlignment.Left,
                    BackgroundTransparency=1, TextWrapped=true,
                }, parent)
            end

            -- Divider
            function g:AddDivider()
                local r2=row(1)
                r2.Size=UDim2.new(1,0,0,1)
                makeInst('Frame',{Size=UDim2.new(1,-16,0,1),Position=UDim2.new(0,8,0,0),BackgroundColor3=COLORS.border},r2)
            end

            -- Toggle
            function g:AddToggle(id, cfg2)
                cfg2 = cfg2 or {}
                local val = cfg2.Default == true
                local r2  = row(28)

                rowLabel(r2, cfg2.Text or id)

                local track = makeInst('Frame', {
                    Size=UDim2.new(0,36,0,18), Position=UDim2.new(1,-36,0.5,-9),
                    BackgroundColor3 = val and COLORS.toggleOn or COLORS.toggleOff,
                }, r2)
                corner(9, track)
                local thumb = makeInst('Frame', {
                    Size=UDim2.new(0,14,0,14),
                    Position = val and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
                    BackgroundColor3=Color3.new(1,1,1),
                }, track)
                corner(7, thumb)

                local function set(v, silent)
                    val = v
                    tween(track,{BackgroundColor3=v and COLORS.toggleOn or COLORS.toggleOff},TWEEN_FAST)
                    tween(thumb,{Position=v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)},TWEEN_FAST)
                    if not silent and cfg2.Callback then pcall(cfg2.Callback, v) end
                end

                track.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not val) end
                end)
                r2.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not val) end
                end)

                local obj = {Value=val}
                function obj:SetValue(v) set(v, false) end
                function obj:GetValue() return val end
                if id then _G['AspectToggle_'..id] = obj end
                return obj
            end

            -- Slider
            function g:AddSlider(id, cfg2)
                cfg2 = cfg2 or {}
                local min  = cfg2.Min or 0
                local max  = cfg2.Max or 100
                local step = cfg2.Rounding or 0
                local val  = math.clamp(cfg2.Default or min, min, max)
                local suffix = cfg2.Suffix or ''

                local r2 = row(42)
                r2.Size  = UDim2.new(1,0,0,42)

                local topRow = makeInst('Frame',{
                    Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
                }, r2)
                rowLabel(topRow, cfg2.Text or id)
                local valLbl = makeInst('TextLabel',{
                    Size=UDim2.new(0,80,1,0), Position=UDim2.new(1,-80,0,0),
                    Font=FONT_REG, TextSize=11, TextColor3=COLORS.accent,
                    TextXAlignment=Enum.TextXAlignment.Right, BackgroundTransparency=1,
                    Text=tostring(val)..(suffix~='' and ' '..suffix or ''),
                }, topRow)

                local track = makeInst('Frame',{
                    Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,24),
                    BackgroundColor3=COLORS.element,
                }, r2)
                corner(3, track)

                local fill = makeInst('Frame',{
                    Size=UDim2.new(0,0,1,0), BackgroundColor3=COLORS.accent,
                }, track)
                corner(3, fill)

                local thumb = makeInst('Frame',{
                    Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,-7,0.5,-7),
                    BackgroundColor3=Color3.new(1,1,1), ZIndex=2,
                }, track)
                corner(7, thumb)

                local function updateFill(v)
                    local pct=(v-min)/(max-min)
                    fill.Size=UDim2.new(pct,0,1,0)
                    thumb.Position=UDim2.new(pct,-7,0.5,-7)
                    local fmt= step>0 and string.format('%.'..tostring(step)..'f', v) or tostring(math.round(v))
                    valLbl.Text=fmt..(suffix~='' and ' '..suffix or '')
                end
                updateFill(val)

                local dragging2=false
                local function calcVal(absX)
                    local rel=(absX-track.AbsolutePosition.X)/track.AbsoluteSize.X
                    local raw=min+math.clamp(rel,0,1)*(max-min)
                    if step>0 then
                        raw=math.round(raw*(10^step))/(10^step)
                    else
                        raw=math.round(raw)
                    end
                    return math.clamp(raw,min,max)
                end

                track.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        dragging2=true
                        val=calcVal(i.Position.X); updateFill(val)
                        if cfg2.Callback then pcall(cfg2.Callback,val) end
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging2 and i.UserInputType==Enum.UserInputType.MouseMovement then
                        val=calcVal(i.Position.X); updateFill(val)
                        if cfg2.Callback then pcall(cfg2.Callback,val) end
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging2=false end
                end)

                local obj={Value=val}
                function obj:SetValue(v)
                    val=math.clamp(v,min,max); updateFill(val)
                    if cfg2.Callback then pcall(cfg2.Callback,val) end
                end
                if id then _G['AspectSlider_'..id]=obj end
                return obj
            end

            -- Dropdown
            function g:AddDropdown(id, cfg2)
                cfg2 = cfg2 or {}
                local values = cfg2.Values or {}
                local selected = cfg2.Default and values[cfg2.Default] or values[1] or ''
                local open = false

                local r2 = row(28)
                rowLabel(r2, cfg2.Text or id)

                local dBtn = makeInst('TextButton',{
                    Size=UDim2.new(0,130,0,22), Position=UDim2.new(1,-130,0.5,-11),
                    BackgroundColor3=COLORS.element, Font=FONT_REG, TextSize=11,
                    TextColor3=COLORS.text, Text=selected, ClipsDescendants=true,
                }, r2)
                corner(4, dBtn)
                stroke(1, COLORS.border, dBtn)
                pad({0,0,6,6}, dBtn)

                local arrow = makeInst('TextLabel',{
                    Size=UDim2.new(0,18,1,0), Position=UDim2.new(1,-18,0,0),
                    Text='▾', Font=FONT, TextSize=11,
                    TextColor3=COLORS.textDim, BackgroundTransparency=1,
                }, dBtn)

                -- Dropdown panel (shown in ScreenGui layer to avoid clipping)
                local dpanel = makeInst('Frame',{
                    Size=UDim2.new(0,130,0,0), BackgroundColor3=COLORS.element,
                    Visible=false, ZIndex=20, ClipsDescendants=true,
                }, sg)
                corner(4, dpanel)
                stroke(1, COLORS.border, dpanel)

                local dScroll = makeInst('ScrollingFrame',{
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                    ScrollBarThickness=2, ScrollBarImageColor3=COLORS.accent,
                    CanvasSize=UDim2.new(0,0,0,0), ZIndex=20,
                }, dpanel)
                local dLayout = listLayout(dScroll, 2)
                pad({2,2,2,2}, dScroll)
                dScroll:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
                    dScroll.CanvasSize=UDim2.new(0,0,0,dLayout.AbsoluteContentSize.Y+4)
                end)

                local function closeDropdown()
                    open=false; dpanel.Visible=false
                    tween(arrow,{Rotation=0},TWEEN_FAST)
                end

                local function buildOptions()
                    for _,c2 in ipairs(dScroll:GetChildren()) do
                        if c2:IsA('TextButton') then c2:Destroy() end
                    end
                    for _,v in ipairs(values) do
                        local opt=makeInst('TextButton',{
                            Size=UDim2.new(1,0,0,22), BackgroundColor3=COLORS.element,
                            Font=FONT_REG, TextSize=11, Text=v,
                            TextColor3=(v==selected) and COLORS.accent or COLORS.text,
                            ZIndex=21,
                        }, dScroll)
                        corner(4, opt)
                        opt.MouseEnter:Connect(function() tween(opt,{BackgroundColor3=COLORS.hover},TWEEN_FAST) end)
                        opt.MouseLeave:Connect(function() tween(opt,{BackgroundColor3=COLORS.element},TWEEN_FAST) end)
                        opt.MouseButton1Click:Connect(function()
                            selected=v; dBtn.Text=v
                            if cfg2.Callback then pcall(cfg2.Callback, v) end
                            closeDropdown()
                        end)
                    end
                    dScroll.CanvasSize=UDim2.new(0,0,0,dLayout.AbsoluteContentSize.Y+4)
                end
                buildOptions()

                dBtn.MouseButton1Click:Connect(function()
                    open=not open
                    if open then
                        buildOptions()
                        local abs = dBtn.AbsolutePosition
                        local h   = math.min(#values*24+4, 180)
                        dpanel.Size=UDim2.new(0,130,0,h)
                        dpanel.Position=UDim2.new(0,abs.X,0,abs.Y+26)
                        dpanel.Visible=true
                        tween(arrow,{Rotation=180},TWEEN_FAST)
                    else closeDropdown() end
                end)

                -- Close if clicked elsewhere
                UserInputService.InputBegan:Connect(function(i)
                    if open and i.UserInputType==Enum.UserInputType.MouseButton1 then
                        if not dpanel:IsAncestorOf(i.Target) and i.Target~=dBtn then
                            closeDropdown()
                        end
                    end
                end)

                local obj={Value=selected}
                function obj:SetValues(v2)
                    values=v2; selected=v2[1] or ''; dBtn.Text=selected; buildOptions()
                end
                function obj:SetValue(v2)
                    selected=v2; dBtn.Text=v2
                    if cfg2.Callback then pcall(cfg2.Callback,v2) end
                    buildOptions()
                end
                if id then _G['AspectDropdown_'..id]=obj end
                return obj
            end

            -- Button
            function g:AddButton(cfg2)
                cfg2 = cfg2 or {}
                local r2 = makeInst('TextButton',{
                    Size=UDim2.new(1,0,0,28), BackgroundColor3=COLORS.accent,
                    Font=FONT, TextSize=12, TextColor3=COLORS.text,
                    Text=cfg2.Text or 'Button',
                }, itemList)
                corner(6, r2)

                local clicks=0; local lastClick=0
                r2.MouseButton1Click:Connect(function()
                    if cfg2.DoubleClick then
                        local now=tick()
                        if now-lastClick<0.4 then
                            if cfg2.Callback then pcall(cfg2.Callback) end
                        end
                        lastClick=now
                    else
                        if cfg2.Callback then pcall(cfg2.Callback) end
                    end
                    tween(r2,{BackgroundColor3=COLORS.accentHov},TWEEN_FAST)
                    task.delay(0.12,function() tween(r2,{BackgroundColor3=COLORS.accent},TWEEN_FAST) end)
                end)
                r2.MouseEnter:Connect(function() tween(r2,{BackgroundColor3=COLORS.accentHov},TWEEN_FAST) end)
                r2.MouseLeave:Connect(function() tween(r2,{BackgroundColor3=COLORS.accent},TWEEN_FAST) end)
                return r2
            end

            -- Color Picker  (simple HSV square approach)
            function g:AddColorPicker(id, cfg2)
                cfg2=cfg2 or {}
                local val=cfg2.Default or Color3.new(1,1,1)
                local open=false

                local r2=row(28)
                rowLabel(r2, cfg2.Text or id)

                local preview=makeInst('TextButton',{
                    Size=UDim2.new(0,36,0,20), Position=UDim2.new(1,-36,0.5,-10),
                    BackgroundColor3=val, Text='',
                }, r2)
                corner(4, preview)
                stroke(1,COLORS.border, preview)

                -- Picker panel
                local picker=makeInst('Frame',{
                    Size=UDim2.new(0,200,0,180), BackgroundColor3=COLORS.panel,
                    Visible=false, ZIndex=25,
                }, sg)
                corner(8, picker)
                stroke(1,COLORS.border, picker)
                pad(8, picker)

                local sv=makeInst('ImageLabel',{
                    Size=UDim2.new(1,0,0,130), BackgroundColor3=Color3.fromHSV(0,0,1),
                    Image='rbxassetid://4155801252',
                    ZIndex=26,
                }, picker)
                corner(4, sv)

                local svThumb=makeInst('Frame',{
                    Size=UDim2.new(0,10,0,10), BackgroundColor3=Color3.new(1,1,1),
                    ZIndex=27,
                }, sv)
                corner(5, svThumb)
                stroke(1,Color3.new(0,0,0), svThumb)

                local hueBar=makeInst('ImageLabel',{
                    Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,138),
                    Image='rbxassetid://4155801252',
                    BackgroundColor3=Color3.new(1,0,0),
                    ZIndex=26,
                }, picker)
                corner(4, hueBar)

                local hueThumb=makeInst('Frame',{
                    Size=UDim2.new(0,6,1,0), BackgroundColor3=Color3.new(1,1,1),
                    ZIndex=27,
                }, hueBar)
                stroke(1,Color3.new(0,0,0),hueThumb)

                local hueGrad=makeInst('UIGradient',{
                    Color=ColorSequence.new({
                        ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.17,Color3.fromHSV(0.17,1,1)),
                        ColorSequenceKeypoint.new(0.33,Color3.fromHSV(0.33,1,1)),
                        ColorSequenceKeypoint.new(0.5,Color3.fromHSV(0.5,1,1)),
                        ColorSequenceKeypoint.new(0.67,Color3.fromHSV(0.67,1,1)),
                        ColorSequenceKeypoint.new(0.83,Color3.fromHSV(0.83,1,1)),
                        ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1)),
                    }),
                    Rotation=0,
                }, hueBar)

                -- State
                local h2,s2,v2=Color3.toHSV(val)
                local function updateColor()
                    val=Color3.fromHSV(h2,s2,v2)
                    preview.BackgroundColor3=val
                    sv.BackgroundColor3=Color3.fromHSV(h2,1,1)
                    svThumb.Position=UDim2.new(s2,-5,(1-v2),-5)
                    hueThumb.Position=UDim2.new(h2,-3,0,0)
                    if cfg2.Callback then pcall(cfg2.Callback,val) end
                end
                updateColor()

                -- SV drag
                local svDrag=false
                sv.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=true end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if svDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
                        local rel=i.Position-sv.AbsolutePosition
                        s2=math.clamp(rel.X/sv.AbsoluteSize.X,0,1)
                        v2=1-math.clamp(rel.Y/sv.AbsoluteSize.Y,0,1)
                        updateColor()
                    end
                end)

                -- Hue drag
                local hueDrag=false
                hueBar.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDrag=true end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if hueDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
                        h2=math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
                        updateColor()
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        svDrag=false; hueDrag=false
                    end
                end)

                preview.MouseButton1Click:Connect(function()
                    open=not open
                    if open then
                        local abs=preview.AbsolutePosition
                        picker.Position=UDim2.new(0,abs.X-210,0,abs.Y-90)
                        picker.Visible=true
                    else picker.Visible=false end
                end)
                UserInputService.InputBegan:Connect(function(i)
                    if open and i.UserInputType==Enum.UserInputType.MouseButton1 then
                        if not picker:IsAncestorOf(i.Target) and i.Target~=preview then
                            picker.Visible=false; open=false
                        end
                    end
                end)

                local obj={Value=val}
                function obj:SetValue(c) val=c; h2,s2,v2=Color3.toHSV(c); updateColor() end
                if id then _G['AspectColor_'..id]=obj end
                return obj
            end

            -- Input
            function g:AddInput(id, cfg2)
                cfg2=cfg2 or {}
                local val=cfg2.Default or ''
                local r2=row(28)
                if cfg2.Text then rowLabel(r2,cfg2.Text) end

                local box=makeInst('TextBox',{
                    Size=UDim2.new(cfg2.Text and 0 or 1, cfg2.Text and 130 or 0, 0,22),
                    Position=UDim2.new(1,-130,0.5,-11),
                    BackgroundColor3=COLORS.element, Font=FONT_REG, TextSize=11,
                    TextColor3=COLORS.text, PlaceholderText=cfg2.Placeholder or '',
                    PlaceholderColor3=COLORS.textDim, Text=val, ClearTextOnFocus=false,
                }, r2)
                corner(4, box)
                stroke(1,COLORS.border, box)
                pad({0,0,6,6}, box)

                box.FocusLost:Connect(function(enter)
                    val=box.Text
                    if cfg2.Callback then pcall(cfg2.Callback, val) end
                end)

                local obj={Value=val}
                function obj:SetValue(v) val=v; box.Text=v end
                if id then _G['AspectInput_'..id]=obj end
                return obj
            end

            -- Label
            function g:AddLabel(txt)
                local r2=row(20)
                r2.Size=UDim2.new(1,0,0,20)
                rowLabel(r2, txt, Enum.TextXAlignment.Left)
                return r2
            end

            -- Keybind (functional)
            function g:AddKeybind(id, cfg2)
                cfg2=cfg2 or {}
                local key=cfg2.Default or Enum.KeyCode.Unknown
                local mode=cfg2.Mode or 'Hold'  -- Hold | Toggle | Always
                local toggled=false
                local listening=false
                local r2=row(28)

                if cfg2.Text then rowLabel(r2,cfg2.Text) end

                local kBtn=makeInst('TextButton',{
                    Size=UDim2.new(0,90,0,22), Position=UDim2.new(1,-90,0.5,-11),
                    BackgroundColor3=COLORS.element, Font=FONT_REG, TextSize=11,
                    TextColor3=COLORS.text,
                    Text=type(key)=='string' and key or key.Name,
                }, r2)
                corner(4, kBtn)
                stroke(1,COLORS.border, kBtn)

                kBtn.MouseButton1Click:Connect(function()
                    listening=true; kBtn.Text='...'
                    kBtn.TextColor3=COLORS.accent
                end)

                UserInputService.InputBegan:Connect(function(i,gp)
                    if listening then
                        if i.UserInputType==Enum.UserInputType.Keyboard then
                            key=i.KeyCode; kBtn.Text=key.Name
                            kBtn.TextColor3=COLORS.text; listening=false
                        elseif i.UserInputType==Enum.UserInputType.MouseButton1 then
                            key='MB1'; kBtn.Text='MB1'
                            kBtn.TextColor3=COLORS.text; listening=false
                        elseif i.UserInputType==Enum.UserInputType.MouseButton2 then
                            key='MB2'; kBtn.Text='MB2'
                            kBtn.TextColor3=COLORS.text; listening=false
                        end
                        return
                    end
                end)

                -- State checker
                local function getState()
                    if mode=='Always' then return true end
                    if mode=='Toggle' then return toggled end
                    -- Hold
                    if type(key)=='string' then
                        if key=='MB1' then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                        if key=='MB2' then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                        return false
                    end
                    return UserInputService:IsKeyDown(key)
                end

                -- Toggle tracking
                UserInputService.InputBegan:Connect(function(i,gp)
                    if listening then return end
                    if mode~='Toggle' then return end
                    local match=false
                    if type(key)=='string' then
                        if key=='MB1' and i.UserInputType==Enum.UserInputType.MouseButton1 then match=true end
                        if key=='MB2' and i.UserInputType==Enum.UserInputType.MouseButton2 then match=true end
                    elseif i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==key then
                        match=true
                    end
                    if match then toggled=not toggled end
                end)

                local obj={}
                function obj:GetState() return getState() end
                function obj:SetMode(m) mode=m end
                function obj:SetKey(k) key=k; kBtn.Text=type(k)=='string' and k or k.Name end
                if id then _G['AspectKeybind_'..id]=obj end
                return obj
            end

            g._box    = box
            g._items  = itemList
            return g
        end  -- end addGroupbox

        function t:AddLeftGroupbox(name2)  return addGroupbox(name2,'left')  end
        function t:AddRightGroupbox(name2) return addGroupbox(name2,'right') end

        return t
    end  -- end AddTab

    -- ── Notifications exposed ──────────────────────────────────
    function win:Notify(title, body, dur, color) createNotif(title, body, dur, color) end
    function win:SetWatermark(txt) wm.Text=txt end
    function win:Destroy() sg:Destroy(); notifGui:Destroy() end
    function win:Toggle() root.Visible=not root.Visible end

    -- Keybind to show/hide (default RightShift)
    local menuKey=Enum.KeyCode.RightShift
    local menuKeyObj={
        _key=menuKey,
        SetKey=function(self,k) self._key=k end
    }
    UserInputService.InputBegan:Connect(function(i,gp)
        if not gp and i.UserInputType==Enum.UserInputType.Keyboard then
            if i.KeyCode==menuKeyObj._key then root.Visible=not root.Visible end
        end
    end)
    win._menuKey=menuKeyObj
    win._root=root

    return win
end

return AspectLib
