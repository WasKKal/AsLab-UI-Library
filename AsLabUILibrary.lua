local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Library = {}
Library.__index = Library

local SCALE = 0.85
local function s(n) return n * SCALE end

local Style = {
    Glass = Color3.fromRGB(28, 28, 34),
    GlassTop = Color3.fromRGB(46, 46, 54),
    GlassTransparency = 0.62,
    Stroke = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.72,
    Radius = UDim.new(0, s(18)),
    Text = Color3.fromRGB(245, 245, 247),
    SubText = Color3.fromRGB(180, 184, 194),
    Font = Enum.Font.Gotham,
    SilverTop = Color3.fromRGB(252, 253, 255),
    SilverBottom = Color3.fromRGB(196, 201, 212),
    SilverTransparency = 0.12,
    ActiveText = Color3.fromRGB(24, 25, 30),
    BlockStroke = Color3.fromRGB(180, 186, 200),
    BlockStrokeTransparency = 0.35,
    BlockStrokeThickness = 1.4,
}

do
    local function pickFont()
        local ok, f = pcall(function() return Enum.Font.BuilderSans end)
        if ok and f then return f end
        ok, f = pcall(function() return Enum.Font.Montserrat end)
        if ok and f then return f end
        return nil
    end
    Style.Font = pickFont() or Style.Font
end

local Cfg = {
    DividerColor = Color3.fromRGB(64, 64, 72),
    TabWidth = 130,
    TabAreaGap = 12,
    TabRowHeight = 30,
    TabRowGap = 4,
    TabIconSize = 18,
    TabTextSize = 15,
    TabTextGap = 8,
    TabRowPadX = 6,
    TabActiveColor = Color3.fromRGB(24, 25, 30),
    TabInactiveColor = Color3.fromRGB(150, 152, 162),
    TabSelFill = Color3.fromRGB(34, 34, 42),
    TabSelFillTransparency = 0.15,
    TabSelStroke = Color3.fromRGB(120, 126, 140),
    TabSelStrokeThickness = 1,
    TabSelCorner = UDim.new(0, s(8)),
    TabSelFadeTime = 0.18,
}

local SIDEBAR_W    = s(Cfg.TabWidth)
local TAB_AREA_GAP = s(Cfg.TabAreaGap)
local HEADER_H     = s(64)
local PAD          = s(10)
local GAP          = s(10)
local MIN_BLOCK    = s(92)
local PAD_IN       = s(12)
local ROW_H        = s(34)
local ROW_GAP      = s(8)
local DETAIL_TOP   = s(42)
local HOLD_TIME    = 0.45

local function httpGet(url)
    local ok, res = pcall(function()
        if type(_G.httpGet) == "function" then return _G.httpGet(url) end
        if type(request) == "function" then
            local r = request({ Url = url, Method = "GET" })
            return r and (r.Body or r.body)
        end
        if type(syn) == "table" and type(syn.request) == "function" then
            local r = syn.request({ Url = url, Method = "GET" })
            return r and (r.Body or r.body)
        end
        if game and type(game.HttpGet) == "function" then return game:HttpGet(url) end
        return nil
    end)
    return ok and res or nil
end

local LucideModule = nil
local LucideCache = {}
local LUCIDE_URLS = {
    "https://gcore.jsdelivr.net/gh/WasKKal/DeltaExecutor-UI-Rebuild@lucide-v6/lucide/init.lua",
    "https://cdn.jsdelivr.net/gh/WasKKal/DeltaExecutor-UI-Rebuild@lucide-v6/lucide/init.lua",
    "https://raw.githubusercontent.com/WasKKal/DeltaExecutor-UI-Rebuild@lucide-v6/lucide/init.lua",
}

local function loadLucide()
    if LucideModule then return LucideModule end
    local content
    for _, url in ipairs(LUCIDE_URLS) do
        local ok, res = pcall(httpGet, url)
        if ok and type(res) == "string" and #res > 5000 then content = res break end
        task.wait(0.3)
    end
    if not content then return nil end
    local func = loadstring(content)
    if not func then return nil end
    local ok, module = pcall(func)
    if not ok or type(module) ~= "table" or type(module.GetAsset) ~= "function" then return nil end
    LucideModule = module
    return LucideModule
end

local function resolveIcon(icon)
    if type(icon) ~= "string" or #icon == 0 then return nil end
    if icon:match("^%a[%w+.-]*://") then return { Url = icon } end
    if LucideCache[icon] ~= nil then return LucideCache[icon] end
    local asset = nil
    local mod = loadLucide()
    if mod then
        local ok, a = pcall(mod.GetAsset, icon)
        if ok and a and a.Url then asset = a end
    end
    LucideCache[icon] = asset or false
    return asset
end

local function applyIcon(imageLabel, icon, color)
    local asset = resolveIcon(icon)
    if not asset then return false end
    imageLabel.Image = asset.Url
    if asset.ImageRectOffset then
        imageLabel.ImageRectOffset = asset.ImageRectOffset
        imageLabel.ImageRectSize = asset.ImageRectSize
    end
    imageLabel.ImageColor3 = color or (Style and Style.Text) or Color3.fromRGB(245, 245, 247)
    imageLabel.ScaleType = Enum.ScaleType.Fit
    return true
end

function Library.PreloadLucide()
    return loadLucide() ~= nil
end

local function getHolder()
    local ok, h = pcall(function() return gethui() end)
    if ok and h then return h end
    ok, h = pcall(function() return game:GetService("CoreGui") end)
    if ok and h then return h end
    local ok2, pg = pcall(function() return Players.LocalPlayer:WaitForChild("PlayerGui", 5) end)
    if ok2 and pg then return pg end
    return nil
end

local function makeGlass(parent, props)
    props = props or {}
    local Class = props.Class or "Frame"
    local f = Instance.new(Class)
    f.Name = props.Name or "Glass"
    f.Size = props.Size or UDim2.fromScale(1, 1)
    f.Position = props.Position or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = props.Color or Style.Glass
    f.BackgroundTransparency = props.Transparency or Style.GlassTransparency
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    if f:IsA("TextButton") then
        f.Text = ""
        f.AutoButtonColor = false
    end
    f.Parent = parent

    local corner = Instance.new("UICorner", f)
    corner.CornerRadius = props.Radius or Style.Radius

    if not props.Plain then
        local bg = Instance.new("UIGradient", f)
        bg.Rotation = 90
        bg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, props.GlassTop or Style.GlassTop),
            ColorSequenceKeypoint.new(1, props.Color or Style.Glass),
        })
    end

    if not props.NoStroke then
        local stroke = Instance.new("UIStroke", f)
        stroke.Color = Style.Stroke
        stroke.Transparency = props.StrokeTransparency or Style.StrokeTransparency
        stroke.Thickness = 1
    end

    if not props.NoSheen then
        local sheen = Instance.new("Frame", f)
        sheen.Name = "Sheen"
        sheen.Size = UDim2.fromScale(1, 1)
        sheen.BackgroundColor3 = Color3.new(1, 1, 1)
        sheen.BackgroundTransparency = 1
        sheen.BorderSizePixel = 0
        sheen.Active = false
        local sg = Instance.new("UIGradient", sheen)
        sg.Rotation = 45
        sg.Color = ColorSequence.new(Color3.new(1, 1, 1))
        sg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, props.Highlight or 0.9),
            NumberSequenceKeypoint.new(0.5, 0.97),
            NumberSequenceKeypoint.new(1, 1),
        })
    end

    return f
end

local function makeBox(parent, w, text)
    local box = makeGlass(parent, {
        Name = "Box",
        Size = UDim2.new(0, w, 0, s(24)),
        Position = UDim2.new(1, -w - s(10), 0.5, -s(12)),
        Transparency = 0.5,
        Radius = UDim.new(0, s(7)),
        Plain = true,
        NoStroke = true,
        NoSheen = true,
    })
    box.ClipsDescendants = false
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = Style.BlockStroke
    stroke.Transparency = Style.BlockStrokeTransparency
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local label = Instance.new("TextLabel", box)
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.Font = Style.Font
    label.TextSize = s(11)
    label.TextColor3 = Style.Text
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.BackgroundTransparency = 1
    label.Active = false
    label.ZIndex = 2
    local hit = Instance.new("TextButton", box)
    hit.Size = UDim2.fromScale(1, 1)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = 3
    return box, label, hit
end

local function makeRow(parent, index, title)
    local row = makeGlass(parent, {
        Name = "Row",
        Size = UDim2.new(1, 0, 0, ROW_H),
        Position = UDim2.new(0, 0, 0, DETAIL_TOP + index * (ROW_H + ROW_GAP)),
        Transparency = 0.5,
        Radius = UDim.new(0, s(9)),
        Plain = true,
        NoStroke = true,
        NoSheen = true,
    })
    row.ClipsDescendants = false
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = Style.BlockStroke
    stroke.Transparency = Style.BlockStrokeTransparency
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.5, -s(10), 1, 0)
    label.Position = UDim2.new(0, s(10), 0, 0)
    label.Text = title
    label.Font = Style.Font
    label.TextSize = s(12)
    label.TextColor3 = Style.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.BackgroundTransparency = 1
    label.Active = false
    return row
end

local fadeGroup, slotY, createShortcut, destroyShortcut, startListen
local buildDetail, addDetailRow, openDetail, closeDetail

fadeGroup = function(group, target, onDone)
    if not (group and group.Parent) then return end
    local ti = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(group, ti, { GroupTransparency = target })
    if onDone then tw.Completed:Connect(function() pcall(onDone) end) end
    tw:Play()
end

local function relayout(tab)
    local win = tab._win
    local areaW = (win._controlW or win._sizeX) - PAD_IN * 2
    local n = math.min(3, math.max(1, math.floor((areaW + GAP) / (MIN_BLOCK + GAP))))
    local side = (areaW - GAP * (n - 1)) / n
    for i, ctrl in ipairs(tab._controls) do
        local col = (i - 1) % n
        local row = math.floor((i - 1) / n)
        ctrl._block.Size = UDim2.new(0, side, 0, side)
        ctrl._block.Position = UDim2.new(0, col * (side + GAP) + side / 2, 0, row * (side + GAP) + side / 2)
    end
end

local function refreshToggle(ctrl, animate)
    local st = ctrl._state
    local bgT = st and Style.SilverTransparency or 1
    local fg = st and Style.ActiveText or Style.Text
    local ti = animate and TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or nil
    local function tw(obj, prop, val)
        if not (obj and obj.Parent) then return end
        if ti then TweenService:Create(obj, ti, { [prop] = val }):Play() else obj[prop] = val end
    end
    tw(ctrl._silver, "BackgroundTransparency", bgT)
    if ctrl._icon then tw(ctrl._icon, "ImageColor3", fg) end
    if ctrl._title then tw(ctrl._title, "TextColor3", fg) end
end

local function setPressed(ctrl, on)
    if not (ctrl._scale and ctrl._scale.Parent) then return end
    local ti = TweenInfo.new(on and 0.12 or 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(ctrl._scale, ti, { Scale = on and 0.9 or 1 }):Play()
    TweenService:Create(ctrl._press, TweenInfo.new(0.15), {
        BackgroundTransparency = on and 0.18 or 1,
    }):Play()
end

local function syncShortcut(ctrl)
    local sc = ctrl._shortcut
    if not (sc and sc.silver and sc.silver.Parent) then return end
    local on = (ctrl._kind == "Toggle" and ctrl._state)
    sc.silver.BackgroundTransparency = on and Style.SilverTransparency or 1
    if sc.label and sc.label.Parent then
        sc.label.TextColor3 = on and Style.ActiveText or Style.Text
    end
end

local function fireClick(ctrl)
    local opts = ctrl._opts or {}
    if ctrl._kind == "Toggle" then
        ctrl._state = not ctrl._state
        refreshToggle(ctrl, true)
        if opts.Callback then pcall(opts.Callback, ctrl._state) end
    else
        if opts.Callback then pcall(opts.Callback) end
    end
    syncShortcut(ctrl)
end

slotY = function(win, h)
    local margin = s(16)
    local step = h + s(8)
    for i = 0, 24 do
        local cy = margin + h / 2 + i * step
        local occupied = false
        for _, item in ipairs(win._shortcuts) do
            if item.frame and item.frame.Parent then
                local py = item.frame.Position.Y.Offset
                if math.abs(py - cy) < step * 0.5 then occupied = true break end
            end
        end
        if not occupied then return cy end
    end
    return margin + h / 2 + 24 * step
end

local function screenWidth(win)
    local sw = 1920
    pcall(function()
        local a = win._gui.AbsoluteSize.X
        if a and a > 0 then sw = a end
    end)
    return sw
end

createShortcut = function(win, ctrl)
    if ctrl._shortcut then return end
    local name = tostring(ctrl._opts.Title or "")
    local w = s(120)
    pcall(function()
        local sz = TextService:GetTextSize(name, s(12), Style.Font, Vector2.new(10000, 100))
        w = math.max(s(80), sz.X + s(28))
    end)
    local h = s(30)
    local sc = Instance.new("CanvasGroup", win._gui)
    sc.Name = "Shortcut"
    sc.Size = UDim2.fromOffset(w, h)
    sc.AnchorPoint = Vector2.new(0.5, 0.5)
    sc.BackgroundColor3 = Style.Glass
    sc.BackgroundTransparency = 0.35
    sc.GroupTransparency = 1
    sc.ZIndex = 30
    sc.ClipsDescendants = true
    local c = Instance.new("UICorner", sc)
    c.CornerRadius = UDim.new(0, s(9))
    local stroke = Instance.new("UIStroke", sc)
    stroke.Color = Style.BlockStroke
    stroke.Transparency = Style.BlockStrokeTransparency
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local silver = Instance.new("Frame", sc)
    silver.Name = "Silver"
    silver.Size = UDim2.fromScale(1, 1)
    silver.BackgroundColor3 = Color3.new(1, 1, 1)
    silver.BackgroundTransparency = 1
    silver.BorderSizePixel = 0
    silver.Active = false
    local silverCorner = Instance.new("UICorner", silver)
    silverCorner.CornerRadius = UDim.new(0, s(9))
    local silverGrad = Instance.new("UIGradient", silver)
    silverGrad.Rotation = 135
    silverGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Style.SilverTop),
        ColorSequenceKeypoint.new(1, Style.SilverBottom),
    })

    local label = Instance.new("TextLabel", sc)
    label.Size = UDim2.fromScale(1, 1)
    label.Text = name
    label.Font = Style.Font
    label.TextSize = s(12)
    label.TextColor3 = Style.Text
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.BackgroundTransparency = 1
    label.Active = false
    label.ZIndex = 2

    local press = Instance.new("Frame", sc)
    press.Size = UDim2.fromScale(1, 1)
    press.BackgroundColor3 = Color3.new(0, 0, 0)
    press.BackgroundTransparency = 1
    press.BorderSizePixel = 0
    press.Active = false
    press.ZIndex = 1

    local hit = Instance.new("TextButton", sc)
    hit.Size = UDim2.fromScale(1, 1)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = 3

    local uscale = Instance.new("UIScale", sc)
    uscale.Scale = 1

    sc.Position = UDim2.fromOffset(screenWidth(win) - w / 2 - s(16), slotY(win, h))
    ctrl._shortcut = { frame = sc, silver = silver, label = label }
    table.insert(win._shortcuts, ctrl._shortcut)
    syncShortcut(ctrl)
    fadeGroup(sc, 0)

    local dragging, moved, startX, startY, originX, originY, conn
    hit.MouseButton1Down:Connect(function()
        dragging = true
        moved = false
        local m = UserInputService:GetMouseLocation()
        startX, startY = m.X, m.Y
        originX, originY = sc.Position.X.Offset, sc.Position.Y.Offset
        if ctrl._kind == "Button" then
            TweenService:Create(uscale, TweenInfo.new(0.1), { Scale = 0.92 }):Play()
            TweenService:Create(press, TweenInfo.new(0.1), { BackgroundTransparency = 0.25 }):Play()
        end
        conn = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                local dx, dy = i.Position.X - startX, i.Position.Y - startY
                if math.abs(dx) + math.abs(dy) > 3 then moved = true end
                sc.Position = UDim2.fromOffset(originX + dx, originY + dy)
            end
        end)
    end)
    hit.MouseButton1Up:Connect(function()
        if not dragging then return end
        dragging = false
        if conn then conn:Disconnect() conn = nil end
        if ctrl._kind == "Button" then
            TweenService:Create(uscale, TweenInfo.new(0.18), { Scale = 1 }):Play()
            TweenService:Create(press, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
        end
        if not moved then fireClick(ctrl) end
    end)
end

destroyShortcut = function(win, ctrl)
    local sc = ctrl._shortcut
    if not sc then return end
    for i, item in ipairs(win._shortcuts) do
        if item == sc then table.remove(win._shortcuts, i) break end
    end
    ctrl._shortcut = nil
    if sc.frame and sc.frame.Parent then sc.frame:Destroy() end
end

startListen = function(win, ctrl, label)
    if win._listening then
        local old = win._listening
        old.label.Text = "···"
        old.ctrl._keybind = nil
    end
    ctrl._keybind = nil
    label.Text = "Tap A Key"
    win._listening = { ctrl = ctrl, label = label }
end

buildDetail = function(win, ctrl)
    local layer = Instance.new("CanvasGroup", win._controlRegion)
    layer.Name = "Detail_" .. tostring(ctrl._opts.Title or "")
    layer.Size = UDim2.new(1, -PAD_IN * 2, 1, -PAD_IN * 2)
    layer.Position = UDim2.new(0, PAD_IN, 0, PAD_IN)
    layer.BackgroundTransparency = 1
    layer.GroupTransparency = 1
    layer.Visible = false
    layer.ZIndex = 5
    ctrl._detailLayer = layer
    ctrl._detailCount = 0

    local title = Instance.new("TextLabel", layer)
    title.Name = "DetailTitle"
    title.Size = UDim2.new(1, -s(40), 0, s(24))
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = tostring(ctrl._opts.Title or "") .. " - Setting"
    title.Font = Style.Font
    title.TextSize = s(15)
    title.TextColor3 = Style.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1

    local back = Instance.new("TextButton", layer)
    back.Name = "Back"
    back.Size = UDim2.fromOffset(s(28), s(28))
    back.Position = UDim2.new(1, -s(28), 0, 0)
    back.BackgroundTransparency = 1
    back.Text = ""
    back.AutoButtonColor = false
    local backIcon = Instance.new("ImageLabel", back)
    backIcon.Size = UDim2.new(0.72, 0, 0.72, 0)
    backIcon.Position = UDim2.new(0.14, 0, 0.14, 0)
    backIcon.BackgroundTransparency = 1
    backIcon.Active = false
    applyIcon(backIcon, "arrow-left")
    back.MouseButton1Click:Connect(function() closeDetail(win) end)

    local krow = makeRow(layer, 0, "Board-Key")
    local _, klabel, khit = makeBox(krow, s(110), "···")
    khit.MouseButton1Click:Connect(function() startListen(win, ctrl, klabel) end)

    local arow = makeRow(layer, 1, "AddShortcut")
    local _, alabel, ahit = makeBox(arow, s(110), "Create")
    ahit.MouseButton1Click:Connect(function()
        if ctrl._shortcut then
            destroyShortcut(win, ctrl)
            alabel.Text = "Create"
        else
            createShortcut(win, ctrl)
            alabel.Text = "Delete"
        end
    end)
    ctrl._detailCount = 2
end

addDetailRow = function(win, ctrl, kind, opts)
    opts = opts or {}
    local layer = ctrl._detailLayer
    local index = ctrl._detailCount
    ctrl._detailCount = index + 1
    local row = makeRow(layer, index, opts.Title or kind)

    if kind == "Slider" then
        local minV = opts.Min or 0
        local maxV = opts.Max or 100
        local def = opts.Default or minV
        local track = makeGlass(row, {
            Name = "Track",
            Size = UDim2.new(0.5, -s(50), 0, s(6)),
            Position = UDim2.new(0.5, 0, 0.5, -s(3)),
            Transparency = 0.35,
            Radius = UDim.new(0, s(3)),
            Plain = true, NoStroke = true, NoSheen = true,
        })
        track.ClipsDescendants = false
        local fill = Instance.new("Frame", track)
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Color3.new(1, 1, 1)
        fill.BorderSizePixel = 0
        local fg = Instance.new("UIGradient", fill)
        fg.Rotation = 135
        fg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Style.SilverTop),
            ColorSequenceKeypoint.new(1, Style.SilverBottom),
        })
        local fc = Instance.new("UICorner", fill)
        fc.CornerRadius = UDim.new(0, s(3))
        local knob = Instance.new("Frame", track)
        knob.Size = UDim2.fromOffset(s(12), s(12))
        knob.Position = UDim2.new(0, -s(6), 0.5, -s(6))
        knob.BackgroundColor3 = Style.SilverTop
        knob.BorderSizePixel = 0
        local kc = Instance.new("UICorner", knob)
        kc.CornerRadius = UDim.new(1, 0)
        local valLabel = Instance.new("TextLabel", row)
        valLabel.Size = UDim2.new(0, s(40), 1, 0)
        valLabel.Position = UDim2.new(1, -s(46), 0, 0)
        valLabel.Font = Style.Font
        valLabel.TextSize = s(11)
        valLabel.TextColor3 = Style.SubText
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.BackgroundTransparency = 1
        local hit = Instance.new("TextButton", row)
        hit.Size = UDim2.new(0.5, -s(50), 1, 0)
        hit.Position = UDim2.new(0.5, 0, 0, 0)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.AutoButtonColor = false
        local value = def
        local function setValue(v, fire)
            value = math.clamp(v, minV, maxV)
            local f = (maxV > minV) and ((value - minV) / (maxV - minV)) or 0
            fill.Size = UDim2.new(f, 0, 1, 0)
            knob.Position = UDim2.new(f, -s(6), 0.5, -s(6))
            valLabel.Text = tostring(math.floor(value + 0.5))
            if fire and opts.Callback then pcall(opts.Callback, value) end
        end
        local function applyFrac(px)
            local ax = track.AbsolutePosition.X
            local aw = math.max(1, track.AbsoluteSize.X)
            local f = math.clamp((px - ax) / aw, 0, 1)
            setValue(minV + (maxV - minV) * f, true)
        end
        hit.MouseButton1Down:Connect(function()
            local m = UserInputService:GetMouseLocation()
            applyFrac(m.X)
            local conn = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then applyFrac(i.Position.X) end
            end)
            local up
            up = UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    conn:Disconnect()
                    up:Disconnect()
                end
            end)
        end)
        setValue(def, false)
        local obj = { Value = def }
        function obj:Set(v) setValue(v, false) end
        return obj
    elseif kind == "Toggle" then
        local box, label, hit = makeBox(row, s(52), "OFF")
        local silver = Instance.new("Frame", box)
        silver.Size = UDim2.fromScale(1, 1)
        silver.BackgroundColor3 = Color3.new(1, 1, 1)
        silver.BackgroundTransparency = 1
        silver.BorderSizePixel = 0
        silver.Active = false
        local sc = Instance.new("UICorner", silver)
        sc.CornerRadius = UDim.new(0, s(7))
        local sg = Instance.new("UIGradient", silver)
        sg.Rotation = 135
        sg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Style.SilverTop),
            ColorSequenceKeypoint.new(1, Style.SilverBottom),
        })
        local st = opts.Default or false
        local function refresh()
            silver.BackgroundTransparency = st and Style.SilverTransparency or 1
            label.TextColor3 = st and Style.ActiveText or Style.Text
            label.Text = st and "ON" or "OFF"
        end
        hit.MouseButton1Click:Connect(function()
            st = not st
            refresh()
            if opts.Callback then pcall(opts.Callback, st) end
        end)
        refresh()
        local obj = { Value = st }
        function obj:Set(v) st = v refresh() end
        return obj
    elseif kind == "Button" then
        local box, _, hit = makeBox(row, s(90), opts.Text or "Run")
        local press = Instance.new("Frame", box)
        press.Size = UDim2.fromScale(1, 1)
        press.BackgroundColor3 = Color3.new(0, 0, 0)
        press.BackgroundTransparency = 1
        press.BorderSizePixel = 0
        press.Active = false
        hit.MouseButton1Down:Connect(function()
            TweenService:Create(press, TweenInfo.new(0.1), { BackgroundTransparency = 0.25 }):Play()
        end)
        hit.MouseButton1Up:Connect(function()
            TweenService:Create(press, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
        end)
        hit.MouseButton1Click:Connect(function()
            if opts.Callback then pcall(opts.Callback) end
        end)
        return {}
    elseif kind == "ColorPicker" then
        local box, label, hit = makeBox(row, s(110), "")
        local swatch = Instance.new("Frame", box)
        swatch.Size = UDim2.new(1, -s(6), 1, -s(6))
        swatch.Position = UDim2.new(0, s(3), 0, s(3))
        swatch.BorderSizePixel = 0
        swatch.ZIndex = 1
        local swc = Instance.new("UICorner", swatch)
        swc.CornerRadius = UDim.new(0, s(5))
        label.ZIndex = 2
        label.TextColor3 = Color3.new(1, 1, 1)
        local lstroke = Instance.new("UIStroke", label)
        lstroke.Color = Color3.new(0, 0, 0)
        lstroke.Transparency = 0.35
        lstroke.Thickness = 1

        local def = Color3.fromRGB(255, 96, 96)
        if typeof(opts.Default) == "Color3" then def = opts.Default end
        local h, sat, val = def:ToHSV()

        local pw, ph = s(210), s(158)
        local panel = makeGlass(layer, {
            Name = "ColorPanel",
            Size = UDim2.fromOffset(pw, ph),
            Position = UDim2.new(0.5, -pw / 2, 0.5, -ph / 2),
            Transparency = 0.12,
            Radius = UDim.new(0, s(12)),
            Color = Color3.fromRGB(20, 20, 26),
            Plain = true, NoStroke = true, NoSheen = true,
        })
        panel.ClipsDescendants = true
        panel.Visible = false
        panel.ZIndex = 40
        local pst = Instance.new("UIStroke", panel)
        pst.Color = Style.BlockStroke
        pst.Transparency = 0.4
        pst.Thickness = 1
        win._colorPanels = win._colorPanels or {}
        table.insert(win._colorPanels, panel)

        local pad = s(10)
        local svW, svH = pw - pad * 2, s(90)
        local sv = Instance.new("Frame", panel)
        sv.Name = "SV"
        sv.Size = UDim2.fromOffset(svW, svH)
        sv.Position = UDim2.fromOffset(pad, pad)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        sv.BorderSizePixel = 0
        sv.ClipsDescendants = true
        local svc = Instance.new("UICorner", sv)
        svc.CornerRadius = UDim.new(0, s(6))

        local white = Instance.new("Frame", sv)
        white.Size = UDim2.fromScale(1, 1)
        white.BackgroundColor3 = Color3.new(1, 1, 1)
        white.BackgroundTransparency = 0
        white.BorderSizePixel = 0
        local wg = Instance.new("UIGradient", white)
        wg.Rotation = 0
        wg.Color = ColorSequence.new(Color3.new(1, 1, 1))
        wg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })

        local black = Instance.new("Frame", sv)
        black.Size = UDim2.fromScale(1, 1)
        black.BackgroundColor3 = Color3.new(0, 0, 0)
        black.BackgroundTransparency = 0
        black.BorderSizePixel = 0
        local bg2 = Instance.new("UIGradient", black)
        bg2.Rotation = 90
        bg2.Color = ColorSequence.new(Color3.new(0, 0, 0))
        bg2.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })

        local cursor = Instance.new("Frame", sv)
        cursor.Size = UDim2.fromOffset(s(10), s(10))
        cursor.BackgroundTransparency = 1
        cursor.BorderSizePixel = 0
        cursor.ZIndex = 3
        local cc = Instance.new("UICorner", cursor)
        cc.CornerRadius = UDim.new(1, 0)
        local cstroke = Instance.new("UIStroke", cursor)
        cstroke.Color = Color3.new(1, 1, 1)
        cstroke.Thickness = 1.5

        local hueY = pad + svH + s(8)
        local hue = Instance.new("Frame", panel)
        hue.Name = "Hue"
        hue.Size = UDim2.fromOffset(svW, s(12))
        hue.Position = UDim2.fromOffset(pad, hueY)
        hue.BorderSizePixel = 0
        hue.ClipsDescendants = true
        local hc = Instance.new("UICorner", hue)
        hc.CornerRadius = UDim.new(0, s(6))
        local hg = Instance.new("UIGradient", hue)
        hg.Rotation = 0
        hg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        local hcur = Instance.new("Frame", hue)
        hcur.Size = UDim2.fromOffset(s(4), s(16))
        hcur.Position = UDim2.new(h, -s(2), 0.5, -s(8))
        hcur.BackgroundColor3 = Color3.new(1, 1, 1)
        hcur.BorderSizePixel = 0
        local hcc = Instance.new("UICorner", hcur)
        hcc.CornerRadius = UDim.new(0, s(2))

        local prev = Instance.new("Frame", panel)
        prev.Size = UDim2.fromOffset(s(22), s(22))
        prev.Position = UDim2.fromOffset(pad, ph - pad - s(22))
        prev.BorderSizePixel = 0
        local pvc = Instance.new("UICorner", prev)
        pvc.CornerRadius = UDim.new(0, s(5))
        local pvst = Instance.new("UIStroke", prev)
        pvst.Color = Style.BlockStroke
        pvst.Transparency = 0.4
        pvst.Thickness = 1
        local hexLabel = Instance.new("TextLabel", panel)
        hexLabel.Size = UDim2.new(1, -pad * 2 - s(34), 0, s(22))
        hexLabel.Position = UDim2.fromOffset(pad + s(30), ph - pad - s(22))
        hexLabel.Font = Style.Font
        hexLabel.TextSize = s(12)
        hexLabel.TextColor3 = Style.Text
        hexLabel.TextXAlignment = Enum.TextXAlignment.Left
        hexLabel.BackgroundTransparency = 1

        local function toHex(c)
            return string.format("#%02X%02X%02X",
                math.floor(c.R * 255 + 0.5),
                math.floor(c.G * 255 + 0.5),
                math.floor(c.B * 255 + 0.5))
        end
        local function refresh(fire)
            local c = Color3.fromHSV(h, sat, val)
            local hex = toHex(c)
            swatch.BackgroundColor3 = c
            prev.BackgroundColor3 = c
            label.Text = hex
            hexLabel.Text = hex
            sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            cursor.Position = UDim2.new(sat, -s(5), 1 - val, -s(5))
            hcur.Position = UDim2.new(h, -s(2), 0.5, -s(8))
            if fire and opts.Callback then pcall(opts.Callback, c) end
        end
        local function grab(apply)
            local m = UserInputService:GetMouseLocation()
            apply(m.X, m.Y)
            local conn = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    apply(i.Position.X, i.Position.Y)
                end
            end)
            local up
            up = UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    conn:Disconnect()
                    up:Disconnect()
                end
            end)
        end
        local function setSV(px, py)
            local p, sz = sv.AbsolutePosition, sv.AbsoluteSize
            sat = math.clamp((px - p.X) / math.max(1, sz.X), 0, 1)
            val = 1 - math.clamp((py - p.Y) / math.max(1, sz.Y), 0, 1)
            refresh(true)
        end
        local function setHue(px)
            local p, sz = hue.AbsolutePosition, hue.AbsoluteSize
            h = math.clamp((px - p.X) / math.max(1, sz.X), 0, 1)
            refresh(true)
        end

        local svHit = Instance.new("TextButton", panel)
        svHit.Size = UDim2.fromOffset(svW, svH)
        svHit.Position = UDim2.fromOffset(pad, pad)
        svHit.BackgroundTransparency = 1
        svHit.Text = ""
        svHit.AutoButtonColor = false
        svHit.ZIndex = 5
        svHit.MouseButton1Down:Connect(function() grab(setSV) end)
        local hueHit = Instance.new("TextButton", panel)
        hueHit.Size = UDim2.fromOffset(svW, s(12))
        hueHit.Position = UDim2.fromOffset(pad, hueY)
        hueHit.BackgroundTransparency = 1
        hueHit.Text = ""
        hueHit.AutoButtonColor = false
        hueHit.ZIndex = 5
        hueHit.MouseButton1Down:Connect(function() grab(setHue) end)

        hit.MouseButton1Click:Connect(function()
            for _, p in ipairs(win._colorPanels or {}) do
                if p ~= panel then p.Visible = false end
            end
            panel.Visible = not panel.Visible
        end)

        refresh(false)
        local obj = { Value = def }
        function obj:Set(c)
            if typeof(c) == "Color3" then
                h, sat, val = c:ToHSV()
                refresh(false)
            end
        end
        function obj:Get() return Color3.fromHSV(h, sat, val) end
        return obj
    end
    return {}
end

openDetail = function(win, ctrl)
    if win._detail then return end
    for _, p in ipairs(win._colorPanels or {}) do p.Visible = false end
    if win._listening then
        win._listening.label.Text = "···"
        win._listening.ctrl._keybind = nil
        win._listening = nil
    end
    if not ctrl._detailLayer then buildDetail(win, ctrl) end
    local cont = nil
    for _, t in ipairs(win._tabs) do
        if t._container.Visible then cont = t._container break end
    end
    win._detailContainer = cont
    if cont then
        fadeGroup(cont, 1, function()
            if win._detail then cont.Visible = false end
        end)
    end
    local layer = ctrl._detailLayer
    layer.Visible = true
    layer.GroupTransparency = 1
    fadeGroup(layer, 0)
    win._detail = ctrl
end

closeDetail = function(win)
    local ctrl = win._detail
    if not ctrl then return end
    win._detail = nil
    if win._listening then
        win._listening.label.Text = "···"
        win._listening.ctrl._keybind = nil
        win._listening = nil
    end
    local layer = ctrl._detailLayer
    if layer then
        fadeGroup(layer, 1, function()
            if win._detail ~= ctrl then layer.Visible = false end
        end)
    end
    local cont = win._detailContainer
    if cont then
        cont.Visible = true
        cont.GroupTransparency = 1
        fadeGroup(cont, 0)
    end
    win._detailContainer = nil
end

local function bindPress(ctrl)
    local block = ctrl._block
    local win = ctrl._tab._win
    ctrl._pressed = false
    ctrl._holdGen = 0
    block.MouseButton1Down:Connect(function()
        ctrl._pressed = true
        ctrl._held = false
        setPressed(ctrl, true)
        ctrl._holdGen = ctrl._holdGen + 1
        local gen = ctrl._holdGen
        task.delay(HOLD_TIME, function()
            if ctrl._holdGen == gen and ctrl._pressed and ctrl._block.Parent then
                ctrl._held = true
                setPressed(ctrl, false)
                openDetail(win, ctrl)
            end
        end)
    end)
    block.MouseButton1Up:Connect(function()
        if not ctrl._pressed then return end
        ctrl._pressed = false
        ctrl._holdGen = ctrl._holdGen + 1
        if ctrl._held then ctrl._held = false return end
        setPressed(ctrl, false)
        fireClick(ctrl)
    end)
    block.MouseLeave:Connect(function()
        if ctrl._pressed then
            ctrl._pressed = false
            ctrl._holdGen = ctrl._holdGen + 1
            setPressed(ctrl, false)
        end
    end)
end

local function addControl(tab, kind, opts)
    opts = opts or {}
    local block = makeGlass(tab._container, {
        Name = kind,
        Class = "TextButton",
        Size = UDim2.new(0, 100, 0, 100),
        Position = UDim2.new(0, 50, 0, 50),
        Transparency = 0.55,
        Radius = UDim.new(0, s(16)),
        Highlight = 0.86,
        Plain = true,
        NoStroke = true,
    })
    block.AnchorPoint = Vector2.new(0.5, 0.5)
    local ctrl = { _tab = tab, _kind = kind, _block = block, _opts = opts, _state = opts.Default or false }

    local silver = Instance.new("Frame", block)
    silver.Name = "Silver"
    silver.Size = UDim2.fromScale(1, 1)
    silver.BackgroundColor3 = Color3.new(1, 1, 1)
    silver.BackgroundTransparency = 1
    silver.BorderSizePixel = 0
    silver.Active = false
    local silverCorner = Instance.new("UICorner", silver)
    silverCorner.CornerRadius = UDim.new(0, s(16))
    local silverGrad = Instance.new("UIGradient", silver)
    silverGrad.Rotation = 135
    silverGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Style.SilverTop),
        ColorSequenceKeypoint.new(1, Style.SilverBottom),
    })
    ctrl._silver = silver

    local press = Instance.new("Frame", block)
    press.Name = "Press"
    press.Size = UDim2.fromScale(1, 1)
    press.BackgroundColor3 = Color3.new(0, 0, 0)
    press.BackgroundTransparency = 1
    press.BorderSizePixel = 0
    press.Active = false
    press:SetAttribute("_skipFade", true)
    local pcorner = Instance.new("UICorner", press)
    pcorner.CornerRadius = UDim.new(0, s(16))
    local scale = Instance.new("UIScale", block)
    scale.Scale = 1
    ctrl._press = press
    ctrl._scale = scale

    if opts.Icon then
        local ic = Instance.new("ImageLabel", block)
        ic.Name = "Icon"
        ic.Size = UDim2.new(0.46, 0, 0.46, 0)
        ic.Position = UDim2.new(0.27, 0, 0.16, 0)
        ic.BackgroundTransparency = 1
        ic.Active = false
        applyIcon(ic, opts.Icon)
        ctrl._icon = ic
        local tx = Instance.new("TextLabel", block)
        tx.Name = "Title"
        tx.Size = UDim2.new(1, -8, 0, s(20))
        tx.Position = UDim2.new(0, 4, 0.72, 0)
        tx.Text = opts.Title or ""
        tx.Font = Style.Font
        tx.TextSize = s(12)
        tx.TextColor3 = Style.Text
        tx.TextXAlignment = Enum.TextXAlignment.Center
        tx.BackgroundTransparency = 1
        tx.Active = false
        ctrl._title = tx
    else
        local tx = Instance.new("TextLabel", block)
        tx.Name = "Title"
        tx.Size = UDim2.new(1, -8, 1, -8)
        tx.Position = UDim2.new(0, 4, 0, 4)
        tx.Text = opts.Title or ""
        tx.Font = Style.Font
        tx.TextSize = s(13)
        tx.TextColor3 = Style.Text
        tx.TextXAlignment = Enum.TextXAlignment.Center
        tx.TextYAlignment = Enum.TextYAlignment.Center
        tx.BackgroundTransparency = 1
        tx.Active = false
        ctrl._title = tx
    end

    local border = Instance.new("Frame", block)
    border.Name = "Border"
    border.Size = UDim2.new(1, -2, 1, -2)
    border.Position = UDim2.new(0, 1, 0, 1)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 0
    border.Active = false
    local borderCorner = Instance.new("UICorner", border)
    borderCorner.CornerRadius = UDim.new(0, s(15))
    local borderStroke = Instance.new("UIStroke", border)
    borderStroke.Color = Style.BlockStroke
    borderStroke.Transparency = Style.BlockStrokeTransparency
    borderStroke.Thickness = Style.BlockStrokeThickness
    borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    if kind == "Toggle" then refreshToggle(ctrl, false) end

    bindPress(ctrl)
    buildDetail(tab._win, ctrl)

    function ctrl:AddSlider(o) return addDetailRow(tab._win, ctrl, "Slider", o) end
    function ctrl:AddToggle(o) return addDetailRow(tab._win, ctrl, "Toggle", o) end
    function ctrl:AddButton(o) return addDetailRow(tab._win, ctrl, "Button", o) end
    function ctrl:AddColorPicker(o) return addDetailRow(tab._win, ctrl, "ColorPicker", o) end

    table.insert(tab._controls, ctrl)
    relayout(tab)
    return ctrl
end

function selectTab(win, activeIdx)
    if win._detail then closeDetail(win) end
    win._activeTab = activeIdx
    for i, t in ipairs(win._tabs) do
        local active = (i == activeIdx)
        t._container.Visible = active
        TweenService:Create(t._nameLabel, TweenInfo.new(0.15), {
            TextColor3 = active and Cfg.TabActiveColor or Cfg.TabInactiveColor,
        }):Play()
        if t._icon then
            TweenService:Create(t._icon, TweenInfo.new(0.15), {
                ImageColor3 = active and Cfg.TabActiveColor or Cfg.TabInactiveColor,
            }):Play()
        end
        local sel = t._sel
        if active then
            if not sel.Visible then
                sel.BackgroundTransparency = 1
                t._selStroke.Transparency = 1
            end
            sel.Visible = true
            TweenService:Create(sel, TweenInfo.new(Cfg.TabSelFadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = Cfg.TabSelFillTransparency,
            }):Play()
            TweenService:Create(t._selStroke, TweenInfo.new(Cfg.TabSelFadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Transparency = 0,
            }):Play()
        elseif sel.Visible then
            TweenService:Create(sel, TweenInfo.new(Cfg.TabSelFadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(t._selStroke, TweenInfo.new(Cfg.TabSelFadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Transparency = 1,
            }):Play()
        end
    end
    win._selected = win._tabs[activeIdx]
end

function Library.CreateWindow(opts)
    opts = opts or {}
    local Size = opts.Size or UDim2.fromOffset(s(620), s(460))
    local Title = opts.Title or "AsLab UI"
    local InfoText = opts.Info or ""
    local TitleIcon = opts.TitleIcon or "layout-grid"

    local holder = getHolder()
    if not holder then return nil end

    local gui = Instance.new("ScreenGui", holder)
    gui.Name = "AsLabUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local backdrop = Instance.new("Frame", gui)
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.45
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 0

    local main = makeGlass(gui, {
        Name = "Main",
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        Transparency = Style.GlassTransparency,
        Radius = UDim.new(0, s(24)),
        Highlight = 0.82,
    })
    main.ZIndex = 1

    local header = Instance.new("Frame", main)
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0

    local iconSize = s(28)
    local titleIcon = Instance.new("ImageLabel", header)
    titleIcon.Name = "TitleIcon"
    titleIcon.Size = UDim2.fromOffset(iconSize, iconSize)
    titleIcon.Position = UDim2.new(0, PAD, 0.5, -iconSize / 2)
    titleIcon.BackgroundTransparency = 1
    applyIcon(titleIcon, TitleIcon)

    local textLeft = PAD + iconSize + s(10)
    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -textLeft - s(44), 0, s(26))
    titleLabel.Position = UDim2.new(0, textLeft, 0, s(10))
    titleLabel.Text = Title
    titleLabel.Font = Style.Font
    titleLabel.TextSize = s(18)
    titleLabel.TextColor3 = Style.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1

    local infoLabel = Instance.new("TextLabel", header)
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -textLeft - s(44), 0, s(18))
    infoLabel.Position = UDim2.new(0, textLeft, 0, s(36))
    infoLabel.Text = InfoText
    infoLabel.Font = Style.Font
    infoLabel.TextSize = s(12)
    infoLabel.TextColor3 = Style.SubText
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.BackgroundTransparency = 1

    local closeSize = s(30)
    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, closeSize, 0, closeSize)
    closeBtn.Position = UDim2.new(1, -PAD - closeSize, 0.5, -closeSize / 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    closeBtn.AutoButtonColor = false
    local closeIcon = Instance.new("ImageLabel", closeBtn)
    closeIcon.Name = "CloseIcon"
    closeIcon.Size = UDim2.new(0.62, 0, 0.62, 0)
    closeIcon.Position = UDim2.new(0.19, 0, 0.19, 0)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Active = false
    if not applyIcon(closeIcon, "x") then
        closeIcon.Visible = false
        closeBtn.Text = "X"
        closeBtn.Font = Style.Font
        closeBtn.TextSize = s(14)
        closeBtn.TextColor3 = Style.Text
    end
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    local bodyY = HEADER_H
    local sidebar = Instance.new("Frame", main)
    sidebar.Name = "TabList"
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -bodyY - PAD)
    sidebar.Position = UDim2.new(0, PAD / 2, 0, bodyY)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0

    local sep = Instance.new("Frame", main)
    sep.Name = "TabSeparator"
    sep.Size = UDim2.new(0, 1, 1, -bodyY - PAD)
    sep.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP / 2, 0, bodyY)
    sep.BackgroundColor3 = Cfg.DividerColor
    sep.BorderSizePixel = 0

    local controlRegion = Instance.new("Frame", main)
    controlRegion.Name = "ControlRegion"
    controlRegion.Size = UDim2.new(1, -(PAD / 2 + SIDEBAR_W + TAB_AREA_GAP + PAD_IN), 1, -bodyY)
    controlRegion.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP, 0, bodyY)
    controlRegion.BackgroundTransparency = 1
    controlRegion.BorderSizePixel = 0

    local win = {
        _gui = gui,
        _main = main,
        _sidebar = sidebar,
        _controlRegion = controlRegion,
        _tabs = {},
        _activeTab = 0,
        _selected = nil,
        _sizeX = Size.X.Offset,
        _sizeY = Size.Y.Offset,
        _controlW = Size.X.Offset - (PAD / 2 + SIDEBAR_W + TAB_AREA_GAP + PAD_IN),
        _shortcuts = {},
        _listening = nil,
        _detail = nil,
        _detailContainer = nil,
    }
    setmetatable(win, Library)

    UserInputService.InputBegan:Connect(function(input)
        if not (gui and gui.Parent) then return end
        local listen = win._listening
        if listen then
            local t = input.UserInputType
            if t == Enum.UserInputType.Keyboard then
                local kc = input.KeyCode
                if kc and kc ~= Enum.KeyCode.Unknown then
                    listen.ctrl._keybind = kc
                    listen.label.Text = tostring(kc.Name)
                    win._listening = nil
                end
            elseif t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                listen.label.Text = "···"
                listen.ctrl._keybind = nil
                win._listening = nil
            end
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode then
            for _, tb in ipairs(win._tabs) do
                for _, c in ipairs(tb._controls) do
                    if c._keybind == input.KeyCode then fireClick(c) end
                end
            end
        end
    end)

    task.delay(0, function()
        if gui and gui.Parent then pcall(function() win:_fadeIn() end) end
    end)

    return win
end

function Library:_fadeIn()
    local targets = {}
    local function scan(obj)
        for _, c in ipairs(obj:GetDescendants()) do
            if c:GetAttribute("_skipFade") then
            elseif c:IsA("Frame") or c:IsA("ImageLabel") or c:IsA("ImageButton") then
                c:SetAttribute("_bt", c.BackgroundTransparency)
                c.BackgroundTransparency = 1
                table.insert(targets, c)
            elseif c:IsA("TextLabel") or c:IsA("TextButton") then
                c:SetAttribute("_tt", c.TextTransparency)
                c.TextTransparency = 1
                table.insert(targets, c)
            elseif c:IsA("UIStroke") then
                c:SetAttribute("_st", c.Transparency)
                c.Transparency = 1
                table.insert(targets, c)
            end
        end
    end
    scan(self._gui)

    local v = Instance.new("NumberValue")
    v.Value = 1
    local tween = TweenService:Create(v,
        TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Value = 0 })
    tween:Play()
    v.Changed:Connect(function(k)
        for _, el in ipairs(targets) do
            if el:IsA("UIStroke") then
                local t = el:GetAttribute("_st") or 0
                el.Transparency = t + (1 - t) * k
            elseif el:IsA("TextLabel") or el:IsA("TextButton") then
                local t = el:GetAttribute("_tt") or 0
                el.TextTransparency = t + (1 - t) * k
            else
                local t = el:GetAttribute("_bt") or 0
                el.BackgroundTransparency = t + (1 - t) * k
            end
        end
    end)
    tween.Completed:Connect(function()
        for _, el in ipairs(targets) do
            if el:IsA("UIStroke") then
                el.Transparency = el:GetAttribute("_st")
            elseif el:IsA("TextLabel") or el:IsA("TextButton") then
                el.TextTransparency = el:GetAttribute("_tt")
            else
                el.BackgroundTransparency = el:GetAttribute("_bt")
            end
        end
        v:Destroy()
    end)
end

function Library:AddTab(name, icon)
    local idx = #self._tabs + 1
    local row = Instance.new("TextButton", self._sidebar)
    row.Name = "TabRow"
    row.Size = UDim2.new(1, 0, 0, s(Cfg.TabRowHeight))
    row.Position = UDim2.new(0, 0, 0, (idx - 1) * s(Cfg.TabRowHeight + Cfg.TabRowGap))
    row.BackgroundTransparency = 1
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = idx
    row.ZIndex = 2

    local sel = Instance.new("Frame", row)
    sel.Name = "TabSel"
    sel.Size = UDim2.new(1, 0, 1, 0)
    sel.Position = UDim2.new(0, 0, 0, 0)
    sel.BackgroundColor3 = Cfg.TabSelFill
    sel.BackgroundTransparency = 1
    sel.BorderSizePixel = 0
    sel.Visible = false
    sel.ZIndex = 1
    sel:SetAttribute("_skipFade", true)
    local selCorner = Instance.new("UICorner", sel)
    selCorner.CornerRadius = Cfg.TabSelCorner
    local selStroke = Instance.new("UIStroke", sel)
    selStroke.Color = Cfg.TabSelStroke
    selStroke.Thickness = Cfg.TabSelStrokeThickness
    selStroke.Transparency = 1
    selStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    selStroke:SetAttribute("_skipFade", true)
    local selGrad = Instance.new("UIGradient", sel)
    selGrad.Rotation = 135
    selGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Style.SilverTop),
        ColorSequenceKeypoint.new(1, Style.SilverBottom),
    })

    local hasIcon = (icon ~= nil and icon ~= "")
    local ticon = nil
    if hasIcon then
        ticon = Instance.new("ImageLabel", row)
        ticon.Name = "TabIcon"
        ticon.Size = UDim2.fromOffset(s(Cfg.TabIconSize), s(Cfg.TabIconSize))
        ticon.Position = UDim2.new(0, s(Cfg.TabRowPadX), 0.5, 0)
        ticon.AnchorPoint = Vector2.new(0, 0.5)
        ticon.BackgroundTransparency = 1
        ticon.ImageColor3 = Cfg.TabInactiveColor
        ticon.ZIndex = 3
        applyIcon(ticon, icon, Cfg.TabInactiveColor)
    end

    local tname = Instance.new("TextLabel", row)
    tname.Name = "TabName"
    tname.BackgroundTransparency = 1
    tname.Text = name
    tname.TextColor3 = Cfg.TabInactiveColor
    tname.TextSize = s(Cfg.TabTextSize)
    tname.Font = Style.Font
    tname.TextYAlignment = Enum.TextYAlignment.Center
    tname.TextXAlignment = Enum.TextXAlignment.Left
    tname.ZIndex = 3
    if hasIcon then
        local x = s(Cfg.TabRowPadX + Cfg.TabIconSize + Cfg.TabTextGap)
        tname.Size = UDim2.new(1, -x, 1, 0)
        tname.Position = UDim2.new(0, x, 0, 0)
    else
        tname.Size = UDim2.new(1, -s(Cfg.TabRowPadX * 2), 1, 0)
        tname.Position = UDim2.new(0, s(Cfg.TabRowPadX), 0, 0)
    end

    local container = Instance.new("CanvasGroup", self._controlRegion)
    container.Name = "Container_" .. name
    container.Size = UDim2.new(1, -PAD_IN * 2, 1, -PAD_IN * 2)
    container.Position = UDim2.new(0, PAD_IN, 0, PAD_IN)
    container.BackgroundTransparency = 1
    container.GroupTransparency = 0
    container.Visible = false

    local tab = {
        _win = self, _name = name,
        _row = row, _sel = sel, _selStroke = selStroke,
        _icon = ticon, _nameLabel = tname,
        _container = container, _controls = {},
    }

    function tab:AddToggle(o) return addControl(tab, "Toggle", o) end
    function tab:AddButton(o) return addControl(tab, "Button", o) end

    row.MouseButton1Click:Connect(function() selectTab(self, idx) end)

    table.insert(self._tabs, tab)
    if #self._tabs == 1 then selectTab(self, 1) end
    return tab
end

return Library
