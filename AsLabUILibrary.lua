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
    TabActiveColor = Color3.fromRGB(0, 0, 0),
    TabInactiveColor = Color3.fromRGB(150, 152, 162),
    TabColorFadeTime = 0.22,
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
local HEADER_PAD   = s(24)
local PAD          = s(10)
local GAP          = s(10)
local MIN_BLOCK    = s(92)
local PAD_IN       = s(12)
local ROW_H        = s(34)
local ROW_GAP      = s(8)
local DETAIL_TOP   = s(42)
local HOLD_TIME    = 0.45
local FOOTER_H     = s(38)
local ORB          = s(52)
local COLLAPSE_T   = 0.38
local NOTIFY_MAXCHARS = 25
local NOTIFY_MARGIN = s(16)
local NOTIFY_GAP = s(8)
local NOTIFY_TIME = 3
local CONFLICT_COLOR = Color3.fromRGB(255, 120, 60)
local KEY_PLACEHOLDER = "···"
local KEY_LISTENING = "Tap A Key"

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
    local conflict = Instance.new("TextLabel", box)
    conflict.Name = "Conflict"
    conflict.AnchorPoint = Vector2.new(1, 0.5)
    conflict.Position = UDim2.new(0, -s(8), 0.5, 0)
    conflict.Size = UDim2.fromOffset(s(170), s(24))
    conflict.Text = ""
    conflict.Font = Style.Font
    conflict.TextSize = s(10)
    conflict.TextColor3 = CONFLICT_COLOR
    conflict.TextXAlignment = Enum.TextXAlignment.Right
    conflict.TextYAlignment = Enum.TextYAlignment.Center
    conflict.TextTruncate = Enum.TextTruncate.AtEnd
    conflict.BackgroundTransparency = 1
    conflict.Active = false
    conflict.ZIndex = 4
    conflict:SetAttribute("_skipFade", true)
    return box, label, hit, conflict
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
    return tw
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

local function refreshConflicts(win)
    local groups = {}
    for _, t in ipairs(win._tabs or {}) do
        for _, c in ipairs(t._controls or {}) do
            local kb = c._keybind
            local state = c._keyLabel and c._keyLabel.Text or ""
            if kb ~= nil and state ~= KEY_PLACEHOLDER and state ~= KEY_LISTENING then
                local key = tostring(kb)
                groups[key] = groups[key] or {}
                table.insert(groups[key], c)
            end
        end
    end
    for _, t in ipairs(win._tabs or {}) do
        for _, c in ipairs(t._controls or {}) do
            local cl = c._conflictLabel
            if cl and cl.Parent then
                local names = {}
                if c._keybind ~= nil then
                    for _, o in ipairs(groups[tostring(c._keybind)] or {}) do
                        if o ~= c then names[#names + 1] = tostring(o._opts.Title or "") end
                    end
                end
                if #names > 0 then
                    cl.Text = "Conflict with " .. table.concat(names, ", ", 1, math.min(#names, 2))
                else
                    cl.Text = ""
                end
            end
        end
    end
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

    local dragging, moved, startX, startY, originX, originY, moveConn, endConn
    local function stopDrag(fire)
        if not dragging then return end
        dragging = false
        if moveConn then pcall(function() moveConn:Disconnect() end) moveConn = nil end
        if endConn then pcall(function() endConn:Disconnect() end) endConn = nil end
        if sc and sc.Parent and ctrl._kind == "Button" then
            pcall(function()
                TweenService:Create(uscale, TweenInfo.new(0.18), { Scale = 1 }):Play()
                TweenService:Create(press, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
            end)
        end
        if fire and not moved then fireClick(ctrl) end
    end
    hit.MouseButton1Down:Connect(function()
        if dragging then stopDrag(false) end
        dragging = true
        moved = false
        local m = UserInputService:GetMouseLocation()
        startX, startY = m.X, m.Y
        originX, originY = sc.Position.X.Offset, sc.Position.Y.Offset
        if ctrl._kind == "Button" then
            TweenService:Create(uscale, TweenInfo.new(0.1), { Scale = 0.92 }):Play()
            TweenService:Create(press, TweenInfo.new(0.1), { BackgroundTransparency = 0.25 }):Play()
        end
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if not dragging then return end
            local t = i.UserInputType
            if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                local m2 = UserInputService:GetMouseLocation()
                local dx, dy = m2.X - startX, m2.Y - startY
                if math.abs(dx) + math.abs(dy) > 3 then moved = true end
                sc.Position = UDim2.fromOffset(originX + dx, originY + dy)
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(i)
            local t = i.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                stopDrag(true)
            end
        end)
    end)
    hit.MouseButton1Up:Connect(function() stopDrag(true) end)
    ctrl._shortcut.disconnect = function() stopDrag(false) end
end

destroyShortcut = function(win, ctrl)
    local sc = ctrl._shortcut
    if not sc then return end
    if type(sc.disconnect) == "function" then pcall(sc.disconnect) end
    for i, item in ipairs(win._shortcuts) do
        if item == sc then table.remove(win._shortcuts, i) break end
    end
    ctrl._shortcut = nil
    if sc.frame and sc.frame.Parent then sc.frame:Destroy() end
end

startListen = function(win, ctrl, label)
    if win._listening then
        local old = win._listening
        old.label.Text = KEY_PLACEHOLDER
        old.ctrl._keybind = nil
    end
    ctrl._keybind = nil
    label.Text = KEY_LISTENING
    win._listening = { ctrl = ctrl, label = label }
    refreshConflicts(win)
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
    local _, klabel, khit, kconflict = makeBox(krow, s(110), KEY_PLACEHOLDER)
    ctrl._keyLabel = klabel
    ctrl._conflictLabel = kconflict
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
        win._listening.label.Text = KEY_PLACEHOLDER
        win._listening.ctrl._keybind = nil
        win._listening = nil
    end
    refreshConflicts(win)
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
        win._listening.label.Text = KEY_PLACEHOLDER
        win._listening.ctrl._keybind = nil
        win._listening = nil
    end
    refreshConflicts(win)
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
        local tint = active and Cfg.TabActiveColor or Cfg.TabInactiveColor
        local ti = TweenInfo.new(Cfg.TabColorFadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if t._nameTween then pcall(function() t._nameTween:Cancel() end) end
        t._nameTween = TweenService:Create(t._nameLabel, ti, { TextColor3 = tint })
        t._nameTween:Play()
        if t._icon then
            if t._iconTween then pcall(function() t._iconTween:Cancel() end) end
            t._iconTween = TweenService:Create(t._icon, ti, { ImageColor3 = tint })
            t._iconTween:Play()
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

local function utf8Chars(str)
    str = tostring(str or "")
    local out = {}
    local ok = pcall(function()
        for _, cp in utf8.codes(str) do out[#out + 1] = utf8.char(cp) end
    end)
    if not ok or #out == 0 then
        out = {}
        for i = 1, #str do out[i] = str:sub(i, i) end
    end
    return out
end

local function wrapLines(str, limit)
    local chars = utf8Chars(str)
    local lines, cur, n = {}, {}, 0
    for _, ch in ipairs(chars) do
        if ch == "\n" then
            lines[#lines + 1] = table.concat(cur)
            cur, n = {}, 0
        else
            cur[#cur + 1] = ch
            n = n + 1
            if n >= limit then
                lines[#lines + 1] = table.concat(cur)
                cur, n = {}, 0
            end
        end
    end
    if #cur > 0 or #lines == 0 then lines[#lines + 1] = table.concat(cur) end
    return lines
end

local function measureText(text, size, font)
    local ok, sz = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(10000, 100))
    end)
    if ok and sz then return sz.X end
    return #tostring(text) * size * 0.55
end

local function makeBold(label)
    local done = false
    pcall(function()
        local base = Font.fromEnum(Style.Font)
        label.FontFace = Font.new(base.Family, Enum.FontWeight.Bold, base.Style)
        done = true
    end)
    if not done then
        pcall(function()
            label.FontFace = Font.new(Style.Font, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
            done = true
        end)
    end
    if not done then
        pcall(function() label.Font = Enum.Font.GothamBold end)
    end
end

local function viewport()
    local w, h = 1920, 1080
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            local v = cam.ViewportSize
            if v and v.X > 0 and v.Y > 0 then w, h = v.X, v.Y end
        end
    end)
    return w, h
end

local function screenW(win)
    local a = 0
    pcall(function() a = win._gui.AbsoluteSize.X end)
    if a and a > 0 then return a end
    return viewport()
end

local pumpCapsule, pushCapsule, clearCapsule, flushNotifyQueue
local applyOrbLayout, tweenExt, tweenBlend, bumpOrbGen
local renderOrbText, typewriter, computeSide, setOrbSide, syncOrbBase
local reflowToasts, pushToast

applyOrbLayout = function(win)
    local orb = win._orb
    if not (orb and orb.Parent) then return end
    local ext = win._orbExt.Value
    local blend = win._orbBlend.Value
    local baseX, baseY = win._orbBaseX, win._orbBaseY
    local px = baseX - ext * blend
    orb.Size = UDim2.fromOffset(ORB + ext, ORB)
    orb.Position = UDim2.fromOffset(px, baseY)
    local iconOff = ORB * 0.22
    if ext < 0.5 then
        win._orbIcon.Position = UDim2.fromOffset(iconOff, iconOff)
    else
        win._orbIcon.Position = UDim2.fromOffset(baseX + iconOff - px, iconOff)
    end
    win._orbInfo.Size = UDim2.fromOffset(ext, ORB)
    win._orbInfo.Position = UDim2.fromOffset(ORB * (1 - blend), 0)
end

tweenExt = function(win, target, dur, onDone)
    if win._orbExtTween then pcall(function() win._orbExtTween:Cancel() end) end
    local gen = win._orbGen
    local tw = TweenService:Create(win._orbExt,
        TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Value = target })
    win._orbExtTween = tw
    if onDone then
        tw.Completed:Connect(function()
            if win._orbGen == gen then pcall(onDone) end
        end)
    end
    tw:Play()
end

tweenBlend = function(win, target, dur)
    if win._orbBlendTween then pcall(function() win._orbBlendTween:Cancel() end) end
    local tw = TweenService:Create(win._orbBlend,
        TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        { Value = target })
    win._orbBlendTween = tw
    tw:Play()
end

bumpOrbGen = function(win)
    win._orbGen = (win._orbGen or 0) + 1
    win._typeGen = (win._typeGen or 0) + 1
    if win._orbExtTween then
        pcall(function() win._orbExtTween:Cancel() end)
        win._orbExtTween = nil
    end
end

renderOrbText = function(win, n)
    local info = win._orbInfo
    if not (info and info.Parent) then return end
    local chars = win._orbChars or {}
    local len = #chars
    n = math.clamp(math.floor(n or 0), 0, len)
    if n <= 0 then info.Text = "" return end
    if win._orbSide == "left" then
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Text = table.concat(chars, "", 1, n)
    else
        info.TextXAlignment = Enum.TextXAlignment.Right
        info.Text = table.concat(chars, "", len - n + 1, len)
    end
end

typewriter = function(win, from, to, dur)
    win._typeGen = (win._typeGen or 0) + 1
    local my = win._typeGen
    local span = math.abs(to - from)
    local step = span > 0 and (dur / span) or 0
    task.spawn(function()
        local n = from
        renderOrbText(win, n)
        while win._typeGen == my do
            if to == from or (to > from and n >= to) or (to < from and n <= to) then break end
            if step > 0 then task.wait(step) end
            if win._typeGen ~= my then return end
            n = n + (to > from and 1 or -1)
            renderOrbText(win, n)
        end
    end)
end

computeSide = function(win)
    local center = win._orbBaseX + ORB / 2
    return (center < screenW(win) / 2) and "left" or "right"
end

setOrbSide = function(win, side)
    if win._orbSide == side then return end
    win._orbSide = side
    tweenBlend(win, side == "left" and 0 or 1, 0.24)
    if win._capsuleActive and not win._orbEnding and win._orbChars then
        typewriter(win, 0, #win._orbChars, math.min(0.6, 0.03 * #win._orbChars + 0.12))
    end
end

syncOrbBase = function(win)
    pcall(function()
        local a = win._gui.AbsoluteSize
        if a and a.X > 0 then
            local p = win._main.AbsolutePosition
            if p then win._orbBaseX, win._orbBaseY = p.X, p.Y end
        end
    end)
    win._orbSide = computeSide(win)
    win._orbBlend.Value = win._orbSide == "left" and 0 or 1
    applyOrbLayout(win)
end

local function showCapsule(win, opts, onDone)
    local info = tostring(opts.Info or "")
    local dur = tonumber(opts.Time) or NOTIFY_TIME
    bumpOrbGen(win)
    local myGen = win._orbGen
    win._orbEnding = false
    win._orbChars = utf8Chars(info)
    local size = s(13)
    win._orbInfo.TextSize = size
    win._orbInfo.Font = Style.Font
    win._orbInfo.TextColor3 = Style.Text
    win._orbInfo.TextWrapped = false
    win._orbInfo.TextTruncate = Enum.TextTruncate.AtEnd
    win._orbInfo.TextYAlignment = Enum.TextYAlignment.Center
    renderOrbText(win, 0)
    local textW = measureText(info, size, Style.Font)
    local avail = win._orbSide == "left"
        and (screenW(win) - (win._orbBaseX + ORB) - s(16))
        or (win._orbBaseX - s(16))
    local target = math.max(s(52), math.min(textW + s(26), math.max(s(52), avail)))
    tweenExt(win, target, 0.32)
    typewriter(win, 0, #win._orbChars, math.min(0.75, 0.032 * #win._orbChars + 0.12))
    task.delay(math.max(0.2, dur), function()
        if win._orbGen ~= myGen then return end
        win._orbEnding = true
        typewriter(win, #win._orbChars, 0, 0.26)
        tweenExt(win, 0, 0.3, function()
            renderOrbText(win, 0)
            if onDone then pcall(onDone) end
        end)
    end)
end

pumpCapsule = function(win)
    local opts = table.remove(win._capsuleQueue, 1)
    if not opts then
        win._capsuleActive = false
        win._capsuleCurrent = nil
        return
    end
    win._capsuleActive = true
    win._capsuleCurrent = opts
    showCapsule(win, opts, function()
        win._capsuleCurrent = nil
        pumpCapsule(win)
    end)
end

pushCapsule = function(win, opts)
    table.insert(win._capsuleQueue, opts)
    if not win._capsuleActive then pumpCapsule(win) end
end

clearCapsule = function(win, requeue)
    bumpOrbGen(win)
    if requeue then
        if win._capsuleActive and win._capsuleCurrent then
            table.insert(win._notifyQueue, win._capsuleCurrent)
        end
        for _, o in ipairs(win._capsuleQueue) do table.insert(win._notifyQueue, o) end
        win._capsuleQueue = {}
    end
    win._capsuleActive = false
    win._capsuleCurrent = nil
    win._orbEnding = false
    renderOrbText(win, 0)
    tweenExt(win, 0, 0.2)
end

reflowToasts = function(win)
    local y = NOTIFY_MARGIN
    for _, it in ipairs(win._toasts) do
        if it.frame and it.frame.Parent and not it._entering then
            TweenService:Create(it.frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Position = UDim2.fromOffset(NOTIFY_MARGIN, y) }):Play()
        end
        y = y + it.h + NOTIFY_GAP
    end
end

pushToast = function(win, opts)
    local Title = tostring(opts.Title or "")
    local Info = tostring(opts.Info or "")
    local dur = tonumber(opts.Time) or NOTIFY_TIME
    local titleLines = wrapLines(Title, NOTIFY_MAXCHARS)
    local infoLines = wrapLines(Info, NOTIFY_MAXCHARS)
    local tSize, iSize = s(15), s(12)
    local maxW = 0
    for _, l in ipairs(titleLines) do
        maxW = math.max(maxW, measureText(l, tSize, Style.Font) + s(8))
    end
    for _, l in ipairs(infoLines) do
        maxW = math.max(maxW, measureText(l, iSize, Style.Font))
    end
    local padX, padY = s(14), s(10)
    local w = math.max(s(120), maxW + padX * 2)
    local tH = #titleLines * (tSize + s(4))
    local iH = #infoLines * (iSize + s(4))
    local h = padY * 2 + tH + (#infoLines > 0 and (s(4) + iH) or 0)
    local frame = Instance.new("CanvasGroup", win._gui)
    frame.Name = "Notify"
    frame.Size = UDim2.fromOffset(w, h)
    frame.BackgroundColor3 = Style.Glass
    frame.BackgroundTransparency = 0.32
    frame.GroupTransparency = 1
    frame.BorderSizePixel = 0
    frame.ZIndex = 60
    frame.ClipsDescendants = true
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, s(12))
    local grad = Instance.new("UIGradient", frame)
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Style.GlassTop),
        ColorSequenceKeypoint.new(1, Style.Glass),
    })
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Style.Stroke
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    local tLabel = Instance.new("TextLabel", frame)
    tLabel.Size = UDim2.fromOffset(w - padX * 2, tH)
    tLabel.Position = UDim2.fromOffset(padX, padY)
    tLabel.Text = table.concat(titleLines, "\n")
    tLabel.Font = Style.Font
    makeBold(tLabel)
    tLabel.TextSize = tSize
    tLabel.TextColor3 = Style.Text
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.TextYAlignment = Enum.TextYAlignment.Top
    tLabel.TextWrapped = false
    tLabel.BackgroundTransparency = 1
    tLabel.Active = false
    tLabel.ZIndex = 2
    local iLabel = Instance.new("TextLabel", frame)
    iLabel.Size = UDim2.fromOffset(w - padX * 2, iH)
    iLabel.Position = UDim2.fromOffset(padX, padY + tH + s(4))
    iLabel.Text = table.concat(infoLines, "\n")
    iLabel.Font = Style.Font
    iLabel.TextSize = iSize
    iLabel.TextColor3 = Style.SubText
    iLabel.TextXAlignment = Enum.TextXAlignment.Left
    iLabel.TextYAlignment = Enum.TextYAlignment.Top
    iLabel.TextWrapped = false
    iLabel.BackgroundTransparency = 1
    iLabel.Active = false
    iLabel.ZIndex = 2
    local item = { frame = frame, h = h, _entering = true }
    table.insert(win._toasts, item)
    local y = NOTIFY_MARGIN
    for i = 1, #win._toasts - 1 do
        local prev = win._toasts[i]
        y = y + (prev and prev.h or s(40)) + NOTIFY_GAP
    end
    frame.Position = UDim2.fromOffset(-w - s(24), y)
    local enter = TweenService:Create(frame,
        TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Position = UDim2.fromOffset(NOTIFY_MARGIN, y), GroupTransparency = 0 })
    enter.Completed:Connect(function() item._entering = false end)
    enter:Play()
    task.delay(math.max(0.2, dur), function()
        if not (frame and frame.Parent) then return end
        local out = TweenService:Create(frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.fromOffset(-w - s(24), frame.Position.Y.Offset),
              GroupTransparency = 1 })
        out:Play()
        out.Completed:Connect(function()
            for i, it in ipairs(win._toasts) do
                if it == item then table.remove(win._toasts, i) break end
            end
            if frame.Parent then frame:Destroy() end
            reflowToasts(win)
        end)
    end)
end

flushNotifyQueue = function(win)
    while #win._notifyQueue > 0 do
        local opts = table.remove(win._notifyQueue, 1)
        if win._panelState == "closed" then
            pushCapsule(win, opts)
        else
            pushToast(win, opts)
        end
    end
end

function Library:ShowNotify(opts)
    opts = opts or {}
    local win = self
    if not (type(win) == "table" and win._gui) then win = Library._activeWindow end
    if not (win and win._gui and win._gui.Parent) then return end
    if win._panelAnimating then
        table.insert(win._notifyQueue, opts)
        return
    end
    if win._panelState == "closed" then pushCapsule(win, opts) else pushToast(win, opts) end
end

local function cancelAnim(win)
    for _, key in ipairs({ "_mainTween", "_mainFadeTween", "_cornerTween", "_backdropTween", "_orbTween" }) do
        local tw = win[key]
        if tw then pcall(function() tw:Cancel() end) win[key] = nil end
    end
end

local function collapse(win)
    if win._collapsed then return end
    win._collapsed = true
    win._panelAnimGen = (win._panelAnimGen or 0) + 1
    local gen = win._panelAnimGen
    win._panelAnimating = true
    win:_finishFadeIn()
    syncOrbBase(win)
    cancelAnim(win)
    for _, item in ipairs(win._shortcuts) do
        if item.frame and item.frame.Parent then item.frame.Visible = false end
    end
    local sizeTi = TweenInfo.new(COLLAPSE_T, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    win._mainTween = TweenService:Create(win._mainScale, sizeTi, {
        Scale = ORB / math.max(1, win._sizeX),
    })
    win._mainTween:Play()
    win._mainFadeTween = TweenService:Create(win._main,
        TweenInfo.new(COLLAPSE_T * 0.82, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { GroupTransparency = 1 })
    win._mainFadeTween:Play()
    if win._mainCorner then
        win._cornerTween = TweenService:Create(win._mainCorner, sizeTi,
            { CornerRadius = UDim.new(0, ORB / 2) })
        win._cornerTween:Play()
    end
    win._backdropTween = TweenService:Create(win._backdrop,
        TweenInfo.new(COLLAPSE_T, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        { BackgroundTransparency = 1 })
    win._backdropTween:Play()
    win._orb.Visible = true
    win._orb.GroupTransparency = 1
    win._orbTween = TweenService:Create(win._orb,
        TweenInfo.new(COLLAPSE_T * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { GroupTransparency = 0 })
    win._orbTween:Play()
    task.delay(COLLAPSE_T + 0.02, function()
        if win._panelAnimGen ~= gen then return end
        if win._collapsed and win._gui.Parent then
            win._main.Visible = false
            win._orb.Visible = true
            win._orb.GroupTransparency = 0
            applyOrbLayout(win)
        end
        win._panelAnimating = false
        win._panelState = "closed"
        flushNotifyQueue(win)
    end)
end

local function expand(win)
    if not win._collapsed then return end
    win._collapsed = false
    win._panelAnimGen = (win._panelAnimGen or 0) + 1
    local gen = win._panelAnimGen
    win._panelAnimating = true
    win:_finishFadeIn()
    clearCapsule(win, true)
    cancelAnim(win)
    win._main.Visible = true
    win._main.GroupTransparency = 1
    win._orb.Visible = false
    local ti = TweenInfo.new(COLLAPSE_T, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    win._mainTween = TweenService:Create(win._mainScale, ti, { Scale = 1 })
    win._mainTween:Play()
    win._mainFadeTween = TweenService:Create(win._main,
        TweenInfo.new(COLLAPSE_T * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { GroupTransparency = 0 })
    win._mainFadeTween:Play()
    if win._mainCorner then
        win._cornerTween = TweenService:Create(win._mainCorner, ti,
            { CornerRadius = UDim.new(0, s(24)) })
        win._cornerTween:Play()
    end
    win._backdropTween = TweenService:Create(win._backdrop, ti, { BackgroundTransparency = 0.45 })
    win._backdropTween:Play()
    task.delay(COLLAPSE_T * 0.7, function()
        if not win._collapsed and win._gui.Parent then
            for _, item in ipairs(win._shortcuts) do
                if item.frame and item.frame.Parent then item.frame.Visible = true end
            end
        end
    end)
    task.delay(COLLAPSE_T + 0.02, function()
        if win._panelAnimGen ~= gen then return end
        win._panelAnimating = false
        win._panelState = "open"
        flushNotifyQueue(win)
    end)
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
        Class = "CanvasGroup",
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        Transparency = Style.GlassTransparency,
        Radius = UDim.new(0, s(24)),
        Highlight = 0.82,
    })
    main.AnchorPoint = Vector2.new(0, 0)
    main.GroupTransparency = 0
    main.ZIndex = 1
    main.ClipsDescendants = false
    local mainScale = Instance.new("UIScale", main)
    mainScale.Scale = 1

    local header = Instance.new("Frame", main)
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0

    local iconSize = s(28)
    local titleIcon = Instance.new("ImageLabel", header)
    titleIcon.Name = "TitleIcon"
    titleIcon.Size = UDim2.fromOffset(iconSize, iconSize)
    titleIcon.Position = UDim2.new(0, HEADER_PAD, 0.5, -iconSize / 2)
    titleIcon.BackgroundTransparency = 1
    applyIcon(titleIcon, TitleIcon)

    local textLeft = HEADER_PAD + iconSize + s(10)
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

    local bodyY = HEADER_H
    local sidebar = Instance.new("Frame", main)
    sidebar.Name = "TabList"
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -bodyY - FOOTER_H - PAD)
    sidebar.Position = UDim2.new(0, PAD / 2, 0, bodyY)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0

    local sep = Instance.new("Frame", main)
    sep.Name = "TabSeparator"
    sep.Size = UDim2.new(0, 1, 1, -bodyY - FOOTER_H - PAD)
    sep.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP / 2, 0, bodyY)
    sep.BackgroundColor3 = Cfg.DividerColor
    sep.BorderSizePixel = 0

    local controlRegion = Instance.new("Frame", main)
    controlRegion.Name = "ControlRegion"
    controlRegion.Size = UDim2.new(1, -(PAD / 2 + SIDEBAR_W + TAB_AREA_GAP + PAD_IN), 1, -bodyY)
    controlRegion.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP, 0, bodyY)
    controlRegion.BackgroundTransparency = 1
    controlRegion.BorderSizePixel = 0
    controlRegion.ClipsDescendants = false

    local footer = Instance.new("Frame", main)
    footer.Name = "Footer"
    footer.Size = UDim2.new(0, SIDEBAR_W, 0, FOOTER_H)
    footer.Position = UDim2.new(0, PAD / 2, 1, -FOOTER_H - PAD)
    footer.BackgroundTransparency = 1
    footer.BorderSizePixel = 0
    footer.ZIndex = 6
    local footerSep = Instance.new("Frame", footer)
    footerSep.Name = "FooterSeparator"
    footerSep.Size = UDim2.new(1, 0, 0, 1)
    footerSep.Position = UDim2.new(0, 0, 0, 0)
    footerSep.BackgroundColor3 = Cfg.DividerColor
    footerSep.BorderSizePixel = 0

    local fbtn = s(26)
    local function makeFooterButton(name, icon, x, fallback)
        local b = Instance.new("TextButton", footer)
        b.Name = name
        b.Size = UDim2.fromOffset(fbtn, fbtn)
        b.Position = UDim2.new(0, x, 0.5, -fbtn / 2)
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.ZIndex = 7
        local ic = Instance.new("ImageLabel", b)
        ic.Name = "Icon"
        ic.Size = UDim2.new(0.68, 0, 0.68, 0)
        ic.Position = UDim2.new(0.16, 0, 0.16, 0)
        ic.BackgroundTransparency = 1
        ic.Active = false
        if not applyIcon(ic, icon) then
            ic.Visible = false
            b.Text = fallback
            b.Font = Style.Font
            b.TextSize = s(13)
            b.TextColor3 = Style.Text
        end
        return b
    end
    local fbtnX = s(8)
    local closeBtn = makeFooterButton("Close", "x", fbtnX, "X")
    local minBtn = makeFooterButton("Minimize", "minimize", fbtnX + fbtn + s(10), "_")

    local orb = Instance.new("CanvasGroup", gui)
    orb.Name = "Orb"
    orb.Size = UDim2.fromOffset(ORB, ORB)
    local vw, vh = viewport()
    local orbBaseX = vw / 2 - Size.X.Offset / 2
    local orbBaseY = vh / 2 - Size.Y.Offset / 2
    orb.Position = UDim2.fromOffset(orbBaseX, orbBaseY)
    orb.AnchorPoint = Vector2.new(0, 0)
    orb.BackgroundColor3 = Style.Glass
    orb.BackgroundTransparency = Style.GlassTransparency
    orb.GroupTransparency = 1
    orb.Visible = false
    orb.ZIndex = 50
    orb.ClipsDescendants = true
    local orbCorner = Instance.new("UICorner", orb)
    orbCorner.CornerRadius = UDim.new(0, ORB / 2)
    local orbGrad = Instance.new("UIGradient", orb)
    orbGrad.Rotation = 90
    orbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Style.GlassTop),
        ColorSequenceKeypoint.new(1, Style.Glass),
    })
    local orbStroke = Instance.new("UIStroke", orb)
    orbStroke.Color = Style.Stroke
    orbStroke.Transparency = Style.StrokeTransparency
    orbStroke.Thickness = 1
    local orbSheen = Instance.new("Frame", orb)
    orbSheen.Size = UDim2.fromScale(1, 1)
    orbSheen.BackgroundColor3 = Color3.new(1, 1, 1)
    orbSheen.BackgroundTransparency = 1
    orbSheen.BorderSizePixel = 0
    orbSheen.Active = false
    local orbSheenGrad = Instance.new("UIGradient", orbSheen)
    orbSheenGrad.Rotation = 45
    orbSheenGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
    orbSheenGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.82),
        NumberSequenceKeypoint.new(0.5, 0.97),
        NumberSequenceKeypoint.new(1, 1),
    })
    local orbIcon = Instance.new("ImageLabel", orb)
    orbIcon.Name = "OrbIcon"
    orbIcon.Size = UDim2.fromOffset(ORB * 0.56, ORB * 0.56)
    orbIcon.Position = UDim2.fromOffset(ORB * 0.22, ORB * 0.22)
    orbIcon.BackgroundTransparency = 1
    orbIcon.Active = false
    orbIcon.ZIndex = 51
    applyIcon(orbIcon, TitleIcon)
    local orbInfo = Instance.new("TextLabel", orb)
    orbInfo.Name = "OrbInfo"
    orbInfo.Size = UDim2.fromOffset(0, ORB)
    orbInfo.Position = UDim2.fromOffset(ORB, 0)
    orbInfo.Text = ""
    orbInfo.Font = Style.Font
    orbInfo.TextSize = s(13)
    orbInfo.TextColor3 = Style.Text
    orbInfo.TextXAlignment = Enum.TextXAlignment.Left
    orbInfo.TextYAlignment = Enum.TextYAlignment.Center
    orbInfo.TextWrapped = false
    orbInfo.TextTruncate = Enum.TextTruncate.AtEnd
    orbInfo.BackgroundTransparency = 1
    orbInfo.Active = false
    orbInfo.ZIndex = 51
    orbInfo:SetAttribute("_skipFade", true)
    local orbHit = Instance.new("TextButton", orb)
    orbHit.Name = "Hit"
    orbHit.Size = UDim2.fromScale(1, 1)
    orbHit.BackgroundTransparency = 1
    orbHit.Text = ""
    orbHit.AutoButtonColor = false
    orbHit.ZIndex = 52

    local orbExt = Instance.new("NumberValue", gui)
    orbExt.Name = "OrbExt"
    orbExt.Value = 0
    local orbBlend = Instance.new("NumberValue", gui)
    orbBlend.Name = "OrbBlend"
    orbBlend.Value = (orbBaseX + ORB / 2 < vw / 2) and 0 or 1

    local win = {
        _gui = gui,
        _main = main,
        _mainScale = mainScale,
        _mainCorner = main:FindFirstChildOfClass("UICorner"),
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
        _backdrop = backdrop,
        _orb = orb,
        _orbIcon = orbIcon,
        _orbInfo = orbInfo,
        _orbExt = orbExt,
        _orbBlend = orbBlend,
        _orbBaseX = orbBaseX,
        _orbBaseY = orbBaseY,
        _orbSide = (orbBaseX + ORB / 2 < vw / 2) and "left" or "right",
        _orbGen = 0,
        _typeGen = 0,
        _orbChars = {},
        _orbExtTween = nil,
        _orbBlendTween = nil,
        _capsuleQueue = {},
        _capsuleActive = false,
        _capsuleCurrent = nil,
        _orbEnding = false,
        _toasts = {},
        _notifyQueue = {},
        _panelState = "open",
        _panelAnimating = false,
        _panelAnimGen = 0,
        _collapsed = false,
    }
    setmetatable(win, Library)
    Library._activeWindow = win
    orbExt.Changed:Connect(function() applyOrbLayout(win) end)
    orbBlend.Changed:Connect(function() applyOrbLayout(win) end)

    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    minBtn.MouseButton1Click:Connect(function() collapse(win) end)

    local orbDragging, orbMoved, orbStartX, orbStartY, orbOriginX, orbOriginY
    local orbMoveConn, orbEndConn
    local function stopOrbDrag()
        if not orbDragging then return end
        orbDragging = false
        if orbMoveConn then pcall(function() orbMoveConn:Disconnect() end) orbMoveConn = nil end
        if orbEndConn then pcall(function() orbEndConn:Disconnect() end) orbEndConn = nil end
    end
    orbHit.MouseButton1Down:Connect(function()
        if orbDragging then stopOrbDrag() end
        orbDragging = true
        orbMoved = false
        local m = UserInputService:GetMouseLocation()
        orbStartX, orbStartY = m.X, m.Y
        orbOriginX, orbOriginY = win._orbBaseX, win._orbBaseY
        orbMoveConn = UserInputService.InputChanged:Connect(function(i)
            if not orbDragging then return end
            local t = i.UserInputType
            if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                local m2 = UserInputService:GetMouseLocation()
                local dx, dy = m2.X - orbStartX, m2.Y - orbStartY
                if math.abs(dx) + math.abs(dy) > 3 then orbMoved = true end
                local w, h = viewport()
                win._orbBaseX = math.clamp(orbOriginX + dx, 0, math.max(0, w - ORB))
                win._orbBaseY = math.clamp(orbOriginY + dy, 0, math.max(0, h - ORB))
                applyOrbLayout(win)
                local side = computeSide(win)
                if side ~= win._orbSide then setOrbSide(win, side) end
            end
        end)
        orbEndConn = UserInputService.InputEnded:Connect(function(i)
            local t = i.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                local wasMoved = orbMoved
                stopOrbDrag()
                if not wasMoved then expand(win) end
            end
        end)
    end)

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
                    refreshConflicts(win)
                end
            elseif t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                listen.label.Text = KEY_PLACEHOLDER
                listen.ctrl._keybind = nil
                win._listening = nil
                refreshConflicts(win)
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
        if gui and gui.Parent then
            pcall(function() syncOrbBase(win) end)
            pcall(function() win:_fadeIn() end)
        end
    end)

    return win
end

local function restoreFade(st)
    for _, el in ipairs(st.targets) do
        pcall(function()
            if el:IsA("UIStroke") then
                el.Transparency = el:GetAttribute("_st") or 0
            elseif el:IsA("TextLabel") or el:IsA("TextButton") then
                el.TextTransparency = el:GetAttribute("_tt") or 0
            else
                el.BackgroundTransparency = el:GetAttribute("_bt") or 0
            end
        end)
    end
end

function Library:_fadeIn()
    local targets = {}
    local function scan(obj)
        for _, c in ipairs(obj:GetDescendants()) do
            if c:GetAttribute("_skipFade") then
            elseif c:IsA("Frame") or c:IsA("CanvasGroup") or c:IsA("ImageLabel") or c:IsA("ImageButton") then
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
    local st = { v = v, tween = tween, targets = targets }
    self._fadeState = st
    tween:Play()
    v.Changed:Connect(function(k)
        if self._fadeState ~= st then return end
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
        if self._fadeState ~= st then return end
        self._fadeState = nil
        restoreFade(st)
        pcall(function() v:Destroy() end)
    end)
end

function Library:_finishFadeIn()
    local st = self._fadeState
    if not st then return end
    self._fadeState = nil
    if st.tween then pcall(function() st.tween:Cancel() end) end
    restoreFade(st)
    if st.v then pcall(function() st.v:Destroy() end) end
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
    container.ClipsDescendants = false

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
