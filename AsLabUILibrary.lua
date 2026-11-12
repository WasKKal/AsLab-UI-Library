local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Library = {}
Library.__index = Library

local SCALE = 0.85
local function s(n) return n * SCALE end

local ZBASE = 110000

local Style = {
    Glass = Color3.fromRGB(28, 28, 34),
    GlassTop = Color3.fromRGB(46, 46, 54),
    GlassTransparency = 0.48,
    Stroke = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.72,
    Radius = UDim.new(0, s(18)),
    Text = Color3.new(1, 1, 1),
    SubText = Color3.fromRGB(232, 236, 244),
    Font = Enum.Font.Gotham,
    SilverTop = Color3.fromRGB(252, 253, 255),
    SilverBottom = Color3.fromRGB(196, 201, 212),
    SilverTransparency = 0.12,
    ActiveText = Color3.new(0, 0, 0),
    BlockStroke = Color3.fromRGB(180, 186, 200),
    BlockStrokeTransparency = 0.35,
    BlockStrokeThickness = 1.4,
    SliderFill = Color3.fromRGB(120, 160, 255),
    SliderFillDarken = 0.28,
    SliderTrack = Color3.fromRGB(58, 58, 70),
    SliderTrackTransparency = 0.35,
    SliderThumb = Color3.fromRGB(245, 245, 248),
    SliderThumbSize = 16,
}

local function darkenColor(c, amt)
    amt = amt or 0
    return Color3.new(
        math.clamp(c.R * (1 - amt), 0, 1),
        math.clamp(c.G * (1 - amt), 0, 1),
        math.clamp(c.B * (1 - amt), 0, 1)
    )
end

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
    TabActiveColor = Color3.fromRGB(255, 255, 255),
    TabInactiveColor = Color3.fromRGB(150, 156, 172),
    TabColorFadeTime = 0.22,
    TabSelFill = Color3.fromRGB(50, 58, 82),
    TabSelFillTransparency = 0.1,
    TabSelStroke = Color3.fromRGB(150, 172, 222),
    TabSelStrokeThickness = 1.4,
    TabSelCorner = UDim.new(0, s(8)),
    TabSelFadeTime = 0.18,
}

local SIDEBAR_W    = s(Cfg.TabWidth)
local TAB_AREA_GAP = s(Cfg.TabAreaGap)
local HEADER_H     = s(58)
local HEADER_PAD   = s(16)
local PAD          = s(10)
local GAP          = s(10)
local H_GAP        = s(11.2)
local MIN_BLOCK    = s(92)
local PAD_IN       = s(12)
local PAD_TOP      = s(2)
local ROW_H        = s(34)
local ROW_GAP      = s(8)
local DETAIL_TOP   = s(42)
local HOLD_TIME    = 0.45
local FOOTER_H     = s(38)
local ORB          = s(52)
local TITLE_ICON   = s(28)
local TITLE_ICON_DX = HEADER_PAD + TITLE_ICON / 2 - ORB / 2
local TITLE_ICON_DY = HEADER_H / 2 - ORB / 2
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
    imageLabel.ImageColor3 = color or (Style and Style.Text) or Color3.new(1, 1, 1)
    imageLabel.ScaleType = Enum.ScaleType.Fit
    return true
end

function Library.PreloadLucide()
    return loadLucide() ~= nil
end

local HolderSource = "none"
local function getHolder()
    local function attempt(fn)
        local ok, h = pcall(fn)
        if ok and h and typeof(h) == "Instance" then return h end
        return nil
    end
    local h = attempt(function()
        if type(gethui) == "function" then return gethui() end
    end)
    if h then HolderSource = "gethui" return h end
    h = attempt(function()
        if type(get_hidden_gui) == "function" then return get_hidden_gui() end
    end)
    if h then HolderSource = "get_hidden_gui" return h end
    h = attempt(function() return game:GetService("CoreGui") end)
    if h then HolderSource = "CoreGui" return h end
    h = attempt(function() return Players.LocalPlayer:WaitForChild("PlayerGui", 5) end)
    if h then HolderSource = "PlayerGui" return h end
    return nil
end
function Library.GetHolderSource() return HolderSource end

local function inputPoint(i)
    local p = i and i.Position
    if p and p.X ~= nil and p.Y ~= nil then return p.X, p.Y end
    local ok, m = pcall(function() return UserInputService:GetMouseLocation() end)
    if ok and m and m.X ~= nil and m.Y ~= nil then return m.X, m.Y end
    return 0, 0
end

local function makeConfigValue(win, key, kind)
    local folder = win and win._configFolder
    if not (folder and key and key ~= "") then return nil end
    local v
    if kind == "Toggle" then
        v = Instance.new("BoolValue", folder)
    elseif kind == "Slider" then
        v = Instance.new("NumberValue", folder)
    elseif kind == "ColorPicker" then
        v = Instance.new("Color3Value", folder)
    else
        v = Instance.new("StringValue", folder)
    end
    v.Name = key
    return v
end

local function syncConfigValue(ctrl)
    local v = ctrl and ctrl._configValue
    if not v then return end
    local value = ctrl._configCurrent
    pcall(function()
        if v:IsA("BoolValue") then v.Value = not not value
        elseif v:IsA("NumberValue") then v.Value = tonumber(value) or 0
        elseif v:IsA("Color3Value") then v.Value = value
        elseif v:IsA("StringValue") then v.Value = tostring(value or "") end
    end)
end

local HttpService = game:GetService("HttpService")

local jsonEncodeValue, jsonDecodeRaw
do
    local probe = "__aslab_probe__"
    local ok1, r1 = pcall(function() return HttpService:JSONEncode(probe) end)
    if ok1 and type(r1) == "string" and r1:find("aslab_probe", 1, true) then
        jsonEncodeValue = function(v) return HttpService:JSONEncode(v) end
    else
        jsonEncodeValue = function(v) return HttpService.JSONEncode(v) end
    end
    local ok2, r2 = pcall(function() return HttpService:JSONDecode('{"__aslab_probe__":1}') end)
    if ok2 and type(r2) == "table" and r2.__aslab_probe__ == 1 then
        jsonDecodeRaw = function(s) return HttpService:JSONDecode(s) end
    else
        jsonDecodeRaw = function(s) return HttpService.JSONDecode(s) end
    end
end

local function cfgToJSON(v)
    if typeof(v) == "Color3" then
        return { __aslab_color3 = { r = v.R, g = v.G, b = v.B } }
    end
    return v
end

local function jsonToCfg(v)
    if type(v) == "table" and type(v.__aslab_color3) == "table" then
        local c = v.__aslab_color3
        return Color3.new(tonumber(c.r) or 0, tonumber(c.g) or 0, tonumber(c.b) or 0)
    end
    return v
end

function Library:SaveConfig()
    for _, ctrl in pairs(self._config or {}) do
        if ctrl then syncConfigValue(ctrl) end
    end
    local path = self._configPath
    if path then
        pcall(function()
            local data = {}
            for key, ctrl in pairs(self._config or {}) do
                if ctrl and ctrl._configCurrent ~= nil then
                    data[key] = cfgToJSON(ctrl._configCurrent)
                end
            end
            writefile(path, jsonEncodeValue(data))
        end)
    end
    return self
end

function Library:LoadConfig()
    local path = self._configPath
    local jsonData = nil
    if path then
        pcall(function()
            if type(isfile) == "function" and isfile(path) then
                local raw = readfile(path)
                if raw and raw ~= "" then
                    local ok, d = pcall(function() return jsonDecodeRaw(raw) end)
                    if ok and type(d) == "table" then jsonData = d end
                end
            end
        end)
    end
    for key, ctrl in pairs(self._config or {}) do
        local applied = false
        if jsonData and jsonData[key] ~= nil and ctrl.Set then
            applied = pcall(function() ctrl:Set(jsonToCfg(jsonData[key])) end)
        end
        if not applied then
            local v = ctrl and ctrl._configValue
            if v and ctrl.Set then
                pcall(function()
                    if v:IsA("BoolValue") then ctrl:Set(v.Value)
                    elseif v:IsA("NumberValue") then ctrl:Set(v.Value)
                    elseif v:IsA("Color3Value") then ctrl:Set(v.Value) end
                end)
            end
        end
    end
    return self
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
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
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
    label.ZIndex = ZBASE + 2
    local hit = Instance.new("TextButton", box)
    hit.Size = UDim2.fromScale(1, 1)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = ZBASE + 3
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
    conflict.ZIndex = ZBASE + 4
    conflict:SetAttribute("_skipFade", true)
    return box, label, hit, conflict
end

local function makeRow(parent, index, title)
    local row = makeGlass(parent, {
        Name = "Row",
        Size = UDim2.new(1, -s(4), 0, ROW_H),
        Position = UDim2.new(0, s(2), 0, DETAIL_TOP + index * (ROW_H + ROW_GAP)),
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
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
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

local function updateCanvas(win)
    local sc = win._scroller
    if not (sc and sc.Parent) then return end
    local need = win._viewH or 0
    local areaW = (win._controlW or win._sizeX) - PAD_IN * 2
    local n = math.min(3, math.max(1, math.floor((areaW + GAP) / (MIN_BLOCK + GAP))))
    local side = (areaW - H_GAP * (n - 1)) / n
    for _, t in ipairs(win._tabs) do
        local rows = math.ceil(#t._controls / n)
        local h = PAD_IN * 2 + rows * (side + GAP) + PAD_IN
        if h > need then need = h end
    end
    for _, t in ipairs(win._tabs) do
        for _, c in ipairs(t._controls) do
            local cnt = c._detailCount or 0
            local h = PAD_IN * 2 + DETAIL_TOP + cnt * (ROW_H + ROW_GAP) + PAD_IN
            if h > need then need = h end
        end
    end
    local w = math.max(1, math.ceil(win._controlW or 0))
    local h = math.max(1, math.ceil(need))
    sc.CanvasSize = UDim2.fromOffset(w, h)
    local innerW = math.max(1, w - PAD_IN * 2)
    local innerH = math.max(1, h - PAD_IN * 2)
    for _, t in ipairs(win._tabs) do
        if t._container then t._container.Size = UDim2.fromOffset(innerW, innerH) end
        for _, c in ipairs(t._controls) do
            if c._detailLayer then c._detailLayer.Size = UDim2.fromOffset(innerW, innerH) end
        end
    end
end

local groupState = setmetatable({}, { __mode = "k" })

local function setGroupTransparency(container, t)
    if not (container and container.Parent) then return end
    t = math.clamp(t or 0, 0, 1)
    local st = groupState[container]
    if not st then st = { gt = 0, base = {} } ; groupState[container] = st end
    local mult = 1 - t
    local base = st.base
    local nodes = { container }
    local function collect(node)
        for _, ch in ipairs(node:GetChildren()) do
            if ch:IsA("GuiObject") then
                nodes[#nodes + 1] = ch
                collect(ch)
            else
                collect(ch)
            end
        end
    end
    collect(container)
    for _, node in ipairs(nodes) do
        local skip = false
        pcall(function() skip = (node:GetAttribute("_skipFade") == true) end)
        if not skip then
            if pcall(function() return node.BackgroundTransparency end) then
                local cur = node.BackgroundTransparency
                local b = base[node]
                if not b then b = {}; base[node] = b end
                if b.bg == nil then b.bg = cur end
                node.BackgroundTransparency = 1 - (1 - b.bg) * mult
            end
            if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                local b = base[node]; if not b then b = {}; base[node] = b end
                local cur = node.TextTransparency
                if b.tt == nil then b.tt = cur end
                node.TextTransparency = 1 - (1 - b.tt) * mult
                local cs = node.TextStrokeTransparency
                if b.ts == nil then b.ts = cs end
                node.TextStrokeTransparency = 1 - (1 - b.ts) * mult
            end
            if node:IsA("ImageLabel") or node:IsA("ImageButton") or node:IsA("VideoFrame") then
                local b = base[node]; if not b then b = {}; base[node] = b end
                local cur = node.ImageTransparency
                if b.it == nil then b.it = cur end
                node.ImageTransparency = 1 - (1 - b.it) * mult
            end
        end
        for _, ch in ipairs(node:GetChildren()) do
            local chSkip = false
            pcall(function() chSkip = (ch:GetAttribute("_skipFade") == true) end)
            if ch:IsA("UIStroke") and not chSkip then
                local b = base[ch]; if not b then b = {}; base[ch] = b end
                local cur = ch.Transparency
                if b.st == nil then b.st = cur end
                ch.Transparency = 1 - (1 - b.st) * mult
            end
        end
    end
    st.gt = t
end

local function tweenGroup(container, target, ti, onDone)
    if not (container and container.Parent) then return end
    local st = groupState[container]
    if not st then st = { gt = 0, base = {} }; groupState[container] = st end
    local oldTw, oldConn = st.tween, st.conn
    st.tween = nil
    st.conn = nil
    if oldConn then pcall(function() oldConn:Disconnect() end) end
    if oldTw then pcall(function() oldTw:Cancel() end) end
    local proxy = container:FindFirstChild("__gtProxy")
    if not proxy then
        proxy = Instance.new("NumberValue", container)
        proxy.Name = "__gtProxy"
    end
    proxy.Value = st.gt or 0
    ti = ti or TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(proxy, ti, { Value = target })
    local conn = proxy:GetPropertyChangedSignal("Value"):Connect(function()
        setGroupTransparency(container, proxy.Value)
    end)
    st.tween = tw
    st.conn = conn
    tw.Completed:Connect(function()
        if st.tween ~= tw then return end
        if conn then conn:Disconnect() end
        st.conn = nil
        st.tween = nil
        setGroupTransparency(container, target)
        if onDone then pcall(onDone) end
    end)
    tw:Play()
    return tw
end

local fadeGen = setmetatable({}, { __mode = "k" })

fadeGroup = function(group, target, onDone)
    if not (group and group.Parent) then return end
    local gen = (fadeGen[group] or 0) + 1
    fadeGen[group] = gen
    return tweenGroup(group, target, nil, function()
        if fadeGen[group] == gen and onDone then onDone() end
    end)
end

local function relayout(tab)
    local win = tab._win
    local areaW = (win._controlW or win._sizeX) - PAD_IN * 2
    local n = math.min(3, math.max(1, math.floor((areaW + GAP) / (MIN_BLOCK + GAP))))
    local side = (areaW - H_GAP * (n - 1)) / n
    for i, ctrl in ipairs(tab._controls) do
        local col = (i - 1) % n
        local row = math.floor((i - 1) / n)
        ctrl._block.Size = UDim2.new(0, side, 0, side)
        ctrl._block.Position = UDim2.new(0, col * (side + H_GAP) + side / 2, 0, row * (side + GAP) + side / 2)
    end
    updateCanvas(win)
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

local function stopPressTweens(ctrl)
    for _, key in ipairs({ "_scaleTween", "_pressTween" }) do
        local tw = ctrl[key]
        if tw then pcall(function() tw:Cancel() end) ctrl[key] = nil end
    end
end

local function setPressed(ctrl, on)
    if not (ctrl._scale and ctrl._scale.Parent) then return end
    stopPressTweens(ctrl)
    local ti = TweenInfo.new(on and 0.12 or 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    ctrl._scaleTween = TweenService:Create(ctrl._scale, ti, { Scale = on and 0.9 or 1 })
    ctrl._scaleTween:Play()
    ctrl._pressTween = TweenService:Create(ctrl._press, TweenInfo.new(0.15), {
        BackgroundTransparency = on and 0.18 or 1,
    })
    ctrl._pressTween:Play()
end

local function releasePress(ctrl)
    if not ctrl then return end
    ctrl._pressed = false
    ctrl._held = false
    ctrl._holdGen = (ctrl._holdGen or 0) + 1
    stopPressTweens(ctrl)
    if ctrl._press and ctrl._press.Parent then ctrl._press.BackgroundTransparency = 1 end
    if ctrl._scale and ctrl._scale.Parent then ctrl._scale.Scale = 1 end
end

local function releaseAllPress(win)
    for _, t in ipairs(win._tabs or {}) do
        for _, c in ipairs(t._controls or {}) do releasePress(c) end
    end
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
        if ctrl._configValue then ctrl._configCurrent = ctrl._state; syncConfigValue(ctrl) end
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
    local sc = Instance.new("Frame", win._gui)
    sc.Name = "Shortcut"
    sc.Size = UDim2.fromOffset(w, h)
    sc.AnchorPoint = Vector2.new(0.5, 0.5)
    sc.BackgroundColor3 = Style.Glass
    sc.BackgroundTransparency = 0.35
    setGroupTransparency(sc, 1)
    sc.ZIndex = ZBASE + 30
    sc.ClipsDescendants = true
    local c = Instance.new("UICorner", sc)
    c.CornerRadius = UDim.new(0, s(9))
    local stroke = Instance.new("UIStroke", sc)
    stroke.Color = Style.BlockStroke
    stroke.Transparency = Style.BlockStrokeTransparency
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    local silver = Instance.new("Frame", sc)
    silver.Name = "Silver"
    silver.Size = UDim2.fromScale(1, 1)
    silver.BackgroundColor3 = Color3.new(1, 1, 1)
    silver.BackgroundTransparency = 1
    silver.BorderSizePixel = 0
    silver.Active = false
    silver:SetAttribute("_skipFade", true)
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
    label.ZIndex = ZBASE + 2

    local press = Instance.new("Frame", sc)
    press.Size = UDim2.fromScale(1, 1)
    press.BackgroundColor3 = Color3.new(0, 0, 0)
    press.BackgroundTransparency = 1
    press.BorderSizePixel = 0
    press.Active = false
    press.ZIndex = ZBASE + 1
    press:SetAttribute("_skipFade", true)
    local pressCorner = Instance.new("UICorner", press)
    pressCorner.CornerRadius = UDim.new(0, s(9))

    local hit = Instance.new("TextButton", sc)
    hit.Size = UDim2.fromScale(1, 1)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = ZBASE + 3

    local uscale = Instance.new("UIScale", sc)
    uscale.Scale = 1

    sc.Position = UDim2.fromOffset(screenWidth(win) - w / 2 - s(16), slotY(win, h))
    ctrl._shortcut = { frame = sc, silver = silver, label = label }
    table.insert(win._shortcuts, ctrl._shortcut)
    syncShortcut(ctrl)
    fadeGroup(sc, 0)

    local dragging, moved, startX, startY, originX, originY, moveConn, endConn, haveStart
    local scaleTween, pressTween
    local function cancelPressTweens()
        if scaleTween then pcall(function() scaleTween:Cancel() end) scaleTween = nil end
        if pressTween then pcall(function() pressTween:Cancel() end) pressTween = nil end
    end
    local function stopDrag(fire)
        if not dragging then return end
        dragging = false
        if moveConn then pcall(function() moveConn:Disconnect() end) moveConn = nil end
        if endConn then pcall(function() endConn:Disconnect() end) endConn = nil end
        cancelPressTweens()
        if sc and sc.Parent then
            pcall(function()
                scaleTween = TweenService:Create(uscale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
                scaleTween:Play()
                pressTween = TweenService:Create(press, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
                pressTween:Play()
            end)
        end
        if fire and not moved then fireClick(ctrl) end
    end
    local dragStartInput = nil
    hit.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragStartInput = input
        end
    end)
    hit.MouseButton1Down:Connect(function()
        if dragging then stopDrag(false) end
        dragging = true
        moved = false
        haveStart = false
        startX, startY = inputPoint(dragStartInput)
        dragStartInput = nil
        originX, originY = sc.Position.X.Offset, sc.Position.Y.Offset
        cancelPressTweens()
        scaleTween = TweenService:Create(uscale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.92 })
        scaleTween:Play()
        pressTween = TweenService:Create(press, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.25 })
        pressTween:Play()
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if not dragging then return end
            local t = i.UserInputType
            if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                local mx, my = inputPoint(i)
                if not haveStart then startX, startY, haveStart = mx, my, true end
                local dx, dy = mx - startX, my - startY
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
    local layer = Instance.new("Frame", win._scroller)
    layer.Name = "Detail_" .. tostring(ctrl._opts.Title or "")
    layer.Size = UDim2.fromOffset((win._controlW or win._sizeX) - PAD_IN * 2, (win._viewH or win._sizeY) - PAD_TOP - PAD_IN)
    layer.Position = UDim2.fromOffset(PAD_IN, PAD_TOP)
    layer.BackgroundTransparency = 1
    setGroupTransparency(layer, 1)
    layer.Visible = false
    layer.ClipsDescendants = false
    layer.ZIndex = ZBASE + 5
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
    updateCanvas(win)
end

addDetailRow = function(win, ctrl, kind, opts)
    opts = opts or {}
    local layer = ctrl._detailLayer
    local index = ctrl._detailCount
    ctrl._detailCount = index + 1
    updateCanvas(win)
    local row = makeRow(layer, index, opts.Title or kind)

    if kind == "Slider" then
        local minV = opts.Min or 0
        local maxV = opts.Max or 100
        local def = opts.Default or minV
        local step = opts.Step or 0

        local valLabel = Instance.new("TextLabel", row)
        valLabel.Name = "SliderValue"
        valLabel.Size = UDim2.new(0, s(40), 1, 0)
        valLabel.Position = UDim2.new(0.5, -s(44), 0, 0)
        valLabel.Font = Style.Font
        valLabel.TextSize = s(11)
        valLabel.TextColor3 = Style.SubText
        valLabel.TextXAlignment = Enum.TextXAlignment.Center
        valLabel.BackgroundTransparency = 1
        valLabel.Active = false
        valLabel.ZIndex = ZBASE + 2

        local track = Instance.new("Frame", row)
        track.Name = "SliderTrack"
        track.Size = UDim2.new(0.5, -s(48), 0, s(6))
        track.Position = UDim2.new(0.5, s(4), 0.5, -s(3))
        track.BackgroundColor3 = Style.SliderTrack
        track.BackgroundTransparency = Style.SliderTrackTransparency
        track.BorderSizePixel = 0
        track.ClipsDescendants = false
        track.Active = true
        local tc = Instance.new("UICorner", track)
        tc.CornerRadius = UDim.new(0, s(3))

        local fill = Instance.new("Frame", track)
        fill.Name = "SliderFill"
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Style.SliderFill
        fill.BorderSizePixel = 0
        fill.Active = false
        local fc = Instance.new("UICorner", fill)
        fc.CornerRadius = UDim.new(0, s(3))
        local fillGrad = Instance.new("UIGradient", fill)
        fillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Style.SliderFill),
            ColorSequenceKeypoint.new(1, darkenColor(Style.SliderFill, Style.SliderFillDarken)),
        })

        local thumb = Instance.new("Frame", track)
        thumb.Name = "SliderThumb"
        thumb.Size = UDim2.fromOffset(s(Style.SliderThumbSize), s(Style.SliderThumbSize))
        thumb.BackgroundColor3 = Style.SliderThumb
        thumb.BorderSizePixel = 0
        thumb.Active = false
        local thc = Instance.new("UICorner", thumb)
        thc.CornerRadius = UDim.new(1, 0)

        local value = def
        local fillTween = nil
        local function clampFrac(f)
            if f < 0 then f = 0 elseif f > 1 then f = 1 end
            return f
        end
        local function getRange() return maxV - minV end
        local function snapVal(v)
            if step and step > 0 then
                v = minV + math.floor((v - minV) / step + 0.5) * step
            end
            if v < minV then v = minV end
            if v > maxV then v = maxV end
            return v
        end
        local function formatVal(v)
            if step >= 1 then return tostring(math.floor(v + 0.5)) end
            if step > 0 then
                local t, dec = step, 0
                while t < 0.999 and dec < 6 do t = t * 10; dec = dec + 1 end
                if dec <= 0 then return tostring(math.floor(v + 0.5)) end
                return string.format("%." .. dec .. "f", v)
            end
            return tostring(math.floor(v + 0.5))
        end
        local function refresh(animate)
            local f = (getRange() > 0) and clampFrac((value - minV) / getRange()) or 0
            if fillTween then pcall(function() fillTween:Cancel() end) fillTween = nil end
            if animate then
                fillTween = TweenService:Create(fill,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    { Size = UDim2.new(f, 0, 1, 0) })
                fillTween:Play()
            else
                fill.Size = UDim2.new(f, 0, 1, 0)
            end
            if thumb and thumb.Parent then
                thumb.Position = UDim2.new(f, -s(Style.SliderThumbSize) / 2, 0.5, -s(Style.SliderThumbSize) / 2)
            end
            if valLabel and valLabel.Parent then
                valLabel.Text = formatVal(value)
            end
        end
        local function applyFrac(f, animate)
            f = clampFrac(f)
            value = snapVal(minV + f * getRange())
            refresh(animate)
            if opts.Callback then pcall(opts.Callback, value) end
            if obj and obj._configValue then obj._configCurrent = value; syncConfigValue(obj) end
        end
        local function pointFrac(input)
            local aw = track.AbsoluteSize.X
            if not aw or aw <= 0 then return 0 end
            return clampFrac((input.Position.X - track.AbsolutePosition.X) / aw)
        end
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                applyFrac(pointFrac(input), true)
                local moveConn
                moveConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        if moveConn then pcall(function() moveConn:Disconnect() end) end
                    elseif input.Position then
                        applyFrac(pointFrac(input), false)
                    end
                end)
            end
        end)
        refresh(false)
        local obj = { Value = def }
        function obj:Set(v)
            value = snapVal(v)
            refresh(false)
            if opts.Callback then pcall(opts.Callback, value) end
            if obj._configValue then obj._configCurrent = value; syncConfigValue(obj) end
        end
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "Slider"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "Slider")
            obj._configCurrent = def
            syncConfigValue(obj)
        end
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
            if obj and obj._configValue then obj._configCurrent = st; syncConfigValue(obj) end
        end)
        refresh()
        local obj = { Value = st }
        function obj:Set(v) st = v; refresh(); if obj._configValue then obj._configCurrent = st; syncConfigValue(obj) end end
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "Toggle"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "Toggle")
            obj._configCurrent = st
            syncConfigValue(obj)
        end
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
        local obj = {}
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "Button"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "Button")
            obj._configCurrent = opts.Text or opts.Title or ""
            syncConfigValue(obj)
            function obj:Set() if opts.Callback then pcall(opts.Callback) end end
        end
        return obj
    elseif kind == "ColorPicker" then
        local box, label, hit = makeBox(row, s(110), "")
        local swatch = Instance.new("Frame", box)
        swatch.Size = UDim2.new(1, -s(6), 1, -s(6))
        swatch.Position = UDim2.new(0, s(3), 0, s(3))
        swatch.BorderSizePixel = 0
        swatch.ZIndex = ZBASE + 1
        local swc = Instance.new("UICorner", swatch)
        swc.CornerRadius = UDim.new(0, s(5))
        label.ZIndex = ZBASE + 2
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
        panel.ZIndex = ZBASE + 40
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
        cursor.ZIndex = ZBASE + 3
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
        local obj
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
            if obj and obj._configValue then obj._configCurrent = c; syncConfigValue(obj) end
        end
        local function grab(apply, initial)
            local px, py = inputPoint(initial)
            apply(px, py)
            local conn = UserInputService.InputChanged:Connect(function(i)
                local t = i.UserInputType
                if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                    local mx, my = inputPoint(i)
                    apply(mx, my)
                end
            end)
            local up
            up = UserInputService.InputEnded:Connect(function(i)
                local t = i.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
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
        svHit.ZIndex = ZBASE + 5
        svHit.InputBegan:Connect(function(input)
            local t = input.UserInputType
            if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
            grab(setSV, input)
        end)
        local hueHit = Instance.new("TextButton", panel)
        hueHit.Size = UDim2.fromOffset(svW, s(12))
        hueHit.Position = UDim2.fromOffset(pad, hueY)
        hueHit.BackgroundTransparency = 1
        hueHit.Text = ""
        hueHit.AutoButtonColor = false
        hueHit.ZIndex = ZBASE + 5
        hueHit.InputBegan:Connect(function(input)
            local t = input.UserInputType
            if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
            grab(setHue, input)
        end)

        win._colorTriggers = win._colorTriggers or {}
        table.insert(win._colorTriggers, hit)
        hit.MouseButton1Click:Connect(function()
            for _, p in ipairs(win._colorPanels or {}) do
                if p ~= panel then p.Visible = false end
            end
            panel.Visible = not panel.Visible
        end)

        refresh(false)
        obj = { Value = def }
        function obj:Set(c)
            if typeof(c) == "Color3" then
                h, sat, val = c:ToHSV()
                refresh(false)
                if obj._configValue then obj._configCurrent = c; syncConfigValue(obj) end
            end
        end
        function obj:Get() return Color3.fromHSV(h, sat, val) end
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "ColorPicker"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "ColorPicker")
            obj._configCurrent = def
            syncConfigValue(obj)
        end
        return obj
    end
    return {}
end

openDetail = function(win, ctrl)
    if win._detail then return end
    releaseAllPress(win)
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
    setGroupTransparency(layer, 1)
    fadeGroup(layer, 0)
    if win._scroller then win._scroller.CanvasPosition = Vector2.new(0, 0) end
    win._detail = ctrl
end

closeDetail = function(win)
    local ctrl = win._detail
    if not ctrl then return end
    win._detail = nil
    releaseAllPress(win)
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
        setGroupTransparency(cont, 1)
        fadeGroup(cont, 0, function()
            if not win._detail then releaseAllPress(win) end
        end)
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
    local cwin = tab._win

    function ctrl:Set(v)
        if kind == "Toggle" then
            ctrl._state = not not v
            refreshToggle(ctrl, false)
            if opts.Callback then pcall(opts.Callback, ctrl._state) end
        else
            if opts.Callback then pcall(opts.Callback) end
        end
        syncShortcut(ctrl)
    end

    if opts.ConfigKey and opts.ConfigKey ~= "" then
        ctrl._configKey = opts.ConfigKey
        ctrl._configKind = kind
        cwin._config = cwin._config or {}
        cwin._config[opts.ConfigKey] = ctrl
        ctrl._configValue = makeConfigValue(cwin, opts.ConfigKey, kind)
        ctrl._configCurrent = (kind == "Toggle") and ctrl._state or (opts.Title or "")
        syncConfigValue(ctrl)
    end

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
    borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

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
    if win._scroller then win._scroller.CanvasPosition = Vector2.new(0, 0) end
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
    win._orbIcon.Position = UDim2.fromOffset(ORB / 2 + ext * blend, ORB / 2)
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
    if win._orbDragging then return end
    if win._collapsed then return end
    pcall(function()
        local p = win._main.Position
        if p then
            win._orbBaseX = p.X.Offset + TITLE_ICON_DX
            win._orbBaseY = p.Y.Offset + TITLE_ICON_DY
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
    local frame = Instance.new("Frame", win._gui)
    frame.Name = "Notify"
    frame.Size = UDim2.fromOffset(w, h)
    frame.BackgroundColor3 = Style.Glass
    frame.BackgroundTransparency = 0.32
    setGroupTransparency(frame, 1)
    frame.BorderSizePixel = 0
    frame.ZIndex = ZBASE + 60
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
    tLabel.ZIndex = ZBASE + 2
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
    iLabel.ZIndex = ZBASE + 2
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
        { Position = UDim2.fromOffset(NOTIFY_MARGIN, y) })
    enter.Completed:Connect(function() item._entering = false end)
    enter:Play()
    tweenGroup(frame, 0, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
    task.delay(math.max(0.2, dur), function()
        if not (frame and frame.Parent) then return end
        local out = TweenService:Create(frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.fromOffset(-w - s(24), frame.Position.Y.Offset) })
        out:Play()
        tweenGroup(frame, 1, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
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
    for _, key in ipairs({ "_mainTween", "_mainFadeTween", "_cornerTween", "_orbTween", "_fadeTween",
                           "_mainTweenPos", "_posTween" }) do
        local tw = win[key]
        if tw then pcall(function() tw:Cancel() end) win[key] = nil end
    end
end

local function setMainContentVisible(win, show)
    local main = win._main
    if not main then return end
    if not show then
        local saved = {}
        for _, ch in ipairs(main:GetChildren()) do
            if ch:IsA("GuiObject") and ch.Visible then
                saved[ch] = true
                ch.Visible = false
            end
        end
        win._collapseHidden = saved
    else
        local saved = win._collapseHidden
        if saved then
            for ch in pairs(saved) do
                if ch and ch.Parent then ch.Visible = true end
            end
            win._collapseHidden = nil
        end
    end
end

local function collapse(win)
    if win._collapsed then return end
    win._collapsed = true
    win._panelAnimGen = (win._panelAnimGen or 0) + 1
    local gen = win._panelAnimGen
    win._panelAnimating = true
    win:_finishFadeIn()
    cancelAnim(win)

    local main = win._main
    local ax, ay = main.Position.X.Offset, main.Position.Y.Offset

    local endX = ax + TITLE_ICON_DX
    local endY = ay + TITLE_ICON_DY
    main.Position = UDim2.fromOffset(ax, ay)
    win._mainPosBeforeCollapse = UDim2.fromOffset(ax, ay)
    win._mainSizeBeforeCollapse = UDim2.fromOffset(win._sizeX, win._sizeY)

    win._orbBaseX, win._orbBaseY = endX, endY
    local vw = viewport()
    win._orbSide = (endX + ORB / 2 < vw / 2) and "left" or "right"
    win._orbExt.Value = 0
    win._orbBlend.Value = (win._orbSide == "left") and 0 or 1
    applyOrbLayout(win)

    if win._mainScale then win._mainScale.Scale = 1 end
    local ti = TweenInfo.new(COLLAPSE_T, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    win._mainTween = TweenService:Create(main, ti, {
        Size = UDim2.fromOffset(ORB, ORB),
        Position = UDim2.fromOffset(endX, endY),
    })
    win._mainTween:Play()
    if win._mainCorner then
        win._cornerTween = TweenService:Create(win._mainCorner, ti,
            { CornerRadius = UDim.new(0, ORB / 2) })
        win._cornerTween:Play()
    end
    setMainContentVisible(win, false)

    win._orb.Visible = true
    setGroupTransparency(win._orb, 1)
    win._orbTween = tweenGroup(win._orb, 0,
        TweenInfo.new(COLLAPSE_T * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            0, false, COLLAPSE_T * 0.55))

    task.delay(COLLAPSE_T + 0.02, function()
        if win._panelAnimGen ~= gen then return end
        if win._collapsed and win._gui.Parent then
            win._main.Visible = false
            win._orb.Visible = true
            setGroupTransparency(win._orb, 0)
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
    win._orb.Visible = false
    if win._mainScale then win._mainScale.Scale = 1 end
    setMainContentVisible(win, true)
    local ti = TweenInfo.new(COLLAPSE_T, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    win._mainTween = TweenService:Create(win._main, ti, {
        Size = win._mainSizeBeforeCollapse or win._main.Size,
        Position = win._mainPosBeforeCollapse or win._main.Position,
    })
    win._mainTween:Play()
    if win._mainCorner then
        win._cornerTween = TweenService:Create(win._mainCorner, ti,
            { CornerRadius = UDim.new(0, s(24)) })
        win._cornerTween:Play()
    end
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
    local Background = opts.Background or nil

    local holder = getHolder()
    if not holder then return nil end

    local RootFolder = "AsLab"
    local SubFolder = "Default"
    if type(opts.Folder) == "string" and opts.Folder ~= "" then
        SubFolder = opts.Folder:gsub("[/\\]", "_")
    end
    local AssetDir = RootFolder .. "/" .. SubFolder
    local ConfigPath = AssetDir .. "/config.json"
    pcall(function()
        makefolder(RootFolder)
        makefolder(AssetDir)
    end)
    local root = Instance.new("Folder", holder)
    root.Name = RootFolder
    local sub = Instance.new("Folder", root)
    sub.Name = SubFolder
    local configFolder = Instance.new("Folder", sub)
    configFolder.Name = "Config"

    local gui = Instance.new("ScreenGui", sub)
    gui.Name = SubFolder .. "UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100000

    local vw0, vh0 = viewport()
    local initW = Size.X.Offset + (Size.X.Scale or 0) * vw0
    local initH = Size.Y.Offset + (Size.Y.Scale or 0) * vh0
    local initX = (vw0 - initW) / 2
    local initY = (vh0 - initH) / 2

    local main = makeGlass(gui, {
        Name = "Main",
        Class = "Frame",
        Size = Size,
        Position = UDim2.fromOffset(initX, initY),
        Transparency = Style.GlassTransparency,
        Radius = UDim.new(0, s(24)),
        Highlight = 0.82,
    })
    main.AnchorPoint = Vector2.new(0, 0)
    main.ZIndex = ZBASE + 1
    main.ClipsDescendants = true
    local mainScale = Instance.new("UIScale", main)
    mainScale.Scale = 1

    local background = nil
    local bgUrl, bgVideo
    if type(Background) == "string" then
        bgUrl = Background
    elseif type(Background) == "table" then
        bgUrl = Background.Url or Background.url
        bgVideo = not not Background.Video
    end
    if type(bgUrl) == "string" and bgUrl ~= "" then
        if not bgVideo then
            bgVideo = bgUrl:match("%.mp4$") or bgUrl:match("%.webm$") or bgUrl:match("%.mov$")
        end
        if bgVideo then
            background = Instance.new("VideoFrame", main)
            background.Video = bgUrl
            background.Looped = true
            background.Playing = true
            background.Volume = 0
        else
            background = Instance.new("ImageLabel", main)
            background.Image = bgUrl
            background.ScaleType = Enum.ScaleType.Crop
            background.ImageColor3 = Color3.new(1, 1, 1)
        end
        background.Name = "Background"
        background.Size = UDim2.fromScale(1, 1)
        background.Position = UDim2.fromOffset(0, 0)
        background.BackgroundTransparency = 1
        background.BorderSizePixel = 0
        background.ZIndex = 0
        background.ClipsDescendants = true
        local bcorner = Instance.new("UICorner", background)
        bcorner.CornerRadius = UDim.new(0, s(24))
    end

    local header = Instance.new("Frame", main)
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.ClipsDescendants = true

    local iconSize = TITLE_ICON
    local titleIcon = Instance.new("ImageLabel", header)
    titleIcon.Name = "TitleIcon"
    titleIcon.Size = UDim2.fromOffset(iconSize, iconSize)
    titleIcon.Position = UDim2.new(0, HEADER_PAD, 0.5, -iconSize / 2)
    titleIcon.BackgroundTransparency = 1
    applyIcon(titleIcon, TitleIcon)

    local textLeft = HEADER_PAD + iconSize + s(10)
    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -textLeft - s(24), 0, s(26))
    titleLabel.Position = UDim2.new(0, textLeft, 0, s(6))
    titleLabel.Text = Title
    titleLabel.Font = Style.Font
    titleLabel.TextSize = s(18)
    titleLabel.TextColor3 = Style.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextWrapped = false
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.BackgroundTransparency = 1

    local infoLabel = Instance.new("TextLabel", header)
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -textLeft - s(24), 0, s(18))
    infoLabel.Position = UDim2.new(0, textLeft, 0, s(27))
    infoLabel.Text = InfoText
    infoLabel.Font = Style.Font
    infoLabel.TextSize = s(12)
    infoLabel.TextColor3 = Style.SubText
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = false
    infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
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
    sep.Size = UDim2.new(0, 1, 1, -FOOTER_H - PAD)
    sep.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP / 2, 0, 0)
    sep.BackgroundColor3 = Cfg.DividerColor
    sep.BorderSizePixel = 0

    local controlRegion = Instance.new("Frame", main)
    controlRegion.Name = "ControlRegion"
    controlRegion.Size = UDim2.new(1, -(PAD / 2 + SIDEBAR_W + TAB_AREA_GAP + PAD_IN), 1, -(s(8) + FOOTER_H + PAD))
    controlRegion.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP, 0, s(8))
    controlRegion.BackgroundTransparency = 1
    controlRegion.BorderSizePixel = 0
    controlRegion.ClipsDescendants = false

    local scroller = Instance.new("ScrollingFrame", controlRegion)
    scroller.Name = "Scroller"
    scroller.Size = UDim2.fromScale(1, 1)
    scroller.Position = UDim2.fromOffset(0, 0)
    scroller.BackgroundTransparency = 1
    scroller.BorderSizePixel = 0
    scroller.ScrollBarThickness = s(4)
    scroller.ScrollBarImageColor3 = Style.Stroke
    scroller.ScrollBarImageTransparency = 0.7
    scroller.ScrollingDirection = Enum.ScrollingDirection.Y
    scroller.CanvasSize = UDim2.fromOffset(0, 0)
    scroller.ClipsDescendants = true
    scroller.ZIndex = ZBASE + 2

    local footer = Instance.new("Frame", main)
    footer.Name = "Footer"
    footer.Size = UDim2.new(0, SIDEBAR_W, 0, FOOTER_H)
    footer.Position = UDim2.new(0, PAD / 2, 1, -FOOTER_H - PAD)
    footer.BackgroundTransparency = 1
    footer.BorderSizePixel = 0
    footer.ZIndex = ZBASE + 6
    local footerSep = Instance.new("Frame", footer)
    footerSep.Name = "FooterSeparator"
    footerSep.Size = UDim2.new(0, SIDEBAR_W + TAB_AREA_GAP / 2 + 1 + PAD / 2, 0, 1)
    footerSep.Position = UDim2.new(0, -PAD / 2, 0, 0)
    footerSep.BackgroundColor3 = Cfg.DividerColor
    footerSep.BorderSizePixel = 0

    local fbtn = s(26)
    local function makeFooterButton(name, icon, x, fallback)
        local b = Instance.new("TextButton", footer)
        b.Name = name
        b.Size = UDim2.fromOffset(fbtn, fbtn)
        b.Position = UDim2.new(0, x, 0.5, -fbtn / 2 + s(5))
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.ZIndex = ZBASE + 7
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
    local fbtnX = s(2)
    local closeBtn = makeFooterButton("Close", "x", fbtnX, "X")
    local minBtn = makeFooterButton("Minimize", "minimize", fbtnX + fbtn + s(10), "_")

    local orb = Instance.new("Frame", gui)
    orb.Name = "Orb"
    orb.Size = UDim2.fromOffset(ORB, ORB)
    local vw, vh = viewport()
    local orbBaseX = initX + TITLE_ICON_DX
    local orbBaseY = initY + TITLE_ICON_DY
    orb.Position = UDim2.fromOffset(orbBaseX, orbBaseY)
    orb.AnchorPoint = Vector2.new(0, 0)
    orb.BackgroundColor3 = Style.Glass
    orb.BackgroundTransparency = Style.GlassTransparency
    setGroupTransparency(orb, 1)
    orb.Visible = false
    orb.ZIndex = ZBASE + 50
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
    orbIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    orbIcon.Position = UDim2.fromOffset(ORB / 2, ORB / 2)
    orbIcon.BackgroundTransparency = 1
    orbIcon.Active = false
    orbIcon.ZIndex = ZBASE + 51
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
    orbInfo.ZIndex = ZBASE + 51
    orbInfo:SetAttribute("_skipFade", true)
    local orbHit = Instance.new("TextButton", orb)
    orbHit.Name = "Hit"
    orbHit.Size = UDim2.fromScale(1, 1)
    orbHit.BackgroundTransparency = 1
    orbHit.Text = ""
    orbHit.AutoButtonColor = false
    orbHit.ZIndex = ZBASE + 52

    local orbExt = Instance.new("NumberValue", gui)
    orbExt.Name = "OrbExt"
    orbExt.Value = 0
    local orbBlend = Instance.new("NumberValue", gui)
    orbBlend.Name = "OrbBlend"
    orbBlend.Value = (orbBaseX + ORB / 2 < vw / 2) and 0 or 1

    local win = {
        _gui = gui,
        _folder = sub,
        _rootFolder = root,
        _rootFolderName = RootFolder,
        _folderName = SubFolder,
        _assetDir = AssetDir,
        _configPath = ConfigPath,
        _holderSource = HolderSource,
        _configFolder = configFolder,
        _config = {},
        _main = main,
        _mainScale = mainScale,
        _mainCorner = main:FindFirstChildOfClass("UICorner"),
        _sidebar = sidebar,
        _controlRegion = controlRegion,
        _scroller = scroller,
        _tabs = {},
        _activeTab = 0,
        _selected = nil,
        _sizeX = Size.X.Offset,
        _sizeY = Size.Y.Offset,
        _controlW = Size.X.Offset - (PAD / 2 + SIDEBAR_W + TAB_AREA_GAP + PAD_IN),
        _viewH = Size.Y.Offset - HEADER_H,
        _shortcuts = {},
        _listening = nil,
        _detail = nil,
        _detailContainer = nil,
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
        _fadeTween = nil,
        _fadeGen = 0,
    }
    setmetatable(win, Library)
    Library._activeWindow = win
    orbExt.Changed:Connect(function() applyOrbLayout(win) end)
    orbBlend.Changed:Connect(function() applyOrbLayout(win) end)

    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    minBtn.MouseButton1Click:Connect(function() collapse(win) end)

    local winDrag, winMoved, wsx, wsy, wox, woy
    local winMoveConn, winEndConn
    local function stopWinDrag()
        if not winDrag then return end
        winDrag = false
        if winMoveConn then pcall(function() winMoveConn:Disconnect() end) winMoveConn = nil end
        if winEndConn then pcall(function() winEndConn:Disconnect() end) winEndConn = nil end
    end
    header.InputBegan:Connect(function(input)
        if win._collapsed then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        if winDrag then stopWinDrag() end
        winDrag = true
        winMoved = false
        wsx, wsy = inputPoint(input)
        wox, woy = win._main.Position.X.Offset, win._main.Position.Y.Offset
        winMoveConn = UserInputService.InputChanged:Connect(function(i)
            if not winDrag then return end
            local it = i.UserInputType
            if it == Enum.UserInputType.MouseMovement or it == Enum.UserInputType.Touch then
                local mx, my = inputPoint(i)
                local dx, dy = mx - wsx, my - wsy
                if math.abs(dx) + math.abs(dy) > 3 then winMoved = true end
                local vw, vh = viewport()
                local nx = math.clamp(wox + dx, 0, math.max(0, vw - win._sizeX))
                local ny = math.clamp(woy + dy, 0, math.max(0, vh - win._sizeY))
                win._main.Position = UDim2.fromOffset(nx, ny)
            end
        end)
        winEndConn = UserInputService.InputEnded:Connect(function(i)
            local it = i.UserInputType
            if it == Enum.UserInputType.MouseButton1 or it == Enum.UserInputType.Touch then
                stopWinDrag()
            end
        end)
    end)

    local orbDragging, orbMoved, orbStartX, orbStartY, orbOriginX, orbOriginY
    local orbMoveConn, orbEndConn
    local function stopOrbDrag()
        if not orbDragging then return end
        orbDragging = false
        win._orbDragging = false
        if orbMoveConn then pcall(function() orbMoveConn:Disconnect() end) orbMoveConn = nil end
        if orbEndConn then pcall(function() orbEndConn:Disconnect() end) orbEndConn = nil end
    end
    local function startOrbDrag(input)
        if orbDragging then stopOrbDrag() end
        orbDragging = true
        win._orbDragging = true
        orbMoved = false
        orbStartX, orbStartY = inputPoint(input)
        orbOriginX, orbOriginY = win._orbBaseX, win._orbBaseY
        if win._orbExtTween then pcall(function() win._orbExtTween:Cancel() end) win._orbExtTween = nil end
        if win._orbBlendTween then pcall(function() win._orbBlendTween:Cancel() end) win._orbBlendTween = nil end
        win._orbExt.Value = 0
        win._orbBlend.Value = (win._orbSide == "left") and 0 or 1
        applyOrbLayout(win)
        orbMoveConn = UserInputService.InputChanged:Connect(function(i)
            if not orbDragging then return end
            local t = i.UserInputType
            if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                local mx, my = inputPoint(i)
                local dx, dy = mx - orbStartX, my - orbStartY
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
    end
    orbHit.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        startOrbDrag(input)
    end)
    orbHit.MouseButton1Down:Connect(function()
        if orbDragging then return end
        startOrbDrag(nil)
    end)

    orbHit.MouseButton1Click:Connect(function()
        if not orbMoved then expand(win) end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if not (gui and gui.Parent) then return end

        local openPicker = false
        for _, p in ipairs(win._colorPanels or {}) do
            if p and p.Visible then openPicker = true break end
        end
        if openPicker then
            local t = input.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                local px, py = inputPoint(input)
                local function hitTest(o, tol)
                    if not (o and o.Parent) then return false end
                    local a, sz = o.AbsolutePosition, o.AbsoluteSize
                    if not (a and sz) then return false end
                    tol = tol or 2
                    return px >= a.X - tol and px <= a.X + sz.X + tol
                        and py >= a.Y - tol and py <= a.Y + sz.Y + tol
                end
                local inside = false
                for _, p in ipairs(win._colorPanels or {}) do
                    if p.Visible and hitTest(p) then inside = true break end
                end
                if not inside then
                    for _, tr in ipairs(win._colorTriggers or {}) do
                        if hitTest(tr) then inside = true break end
                    end
                end
                if not inside then
                    for _, p in ipairs(win._colorPanels or {}) do p.Visible = false end
                end
            end
        end

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

    local revealed = false
    local function revealMain()
        if revealed then return end
        revealed = true
        if gui and gui.Parent and win._main and win._main.Parent then
            win._main.Visible = true
            pcall(function() syncOrbBase(win) end)
            pcall(function() win:_fadeIn() end)
        end
    end

    if background and background:IsA("ImageLabel") and type(bgUrl) == "string" and bgUrl ~= "" then
        win._main.Visible = false
        task.spawn(function()
            local ok, data = pcall(function() return game:HttpGet(bgUrl) end)
            if ok and type(data) == "string" and #data > 0 then
                pcall(function()
                    makefolder(RootFolder)
                    makefolder(AssetDir)
                    writefile(AssetDir .. "/background.png", data)
                end)
                local asset
                pcall(function() asset = getcustomasset(AssetDir .. "/background.png") end)
                if asset then background.Image = asset end
            end
            revealMain()
        end)
        task.delay(12, revealMain)
    else
        revealMain()
    end

    return win
end

function Library:_fadeIn()
    if self._fadeTween then
        pcall(function() self._fadeTween:Cancel() end)
        self._fadeTween = nil
    end
    self._fadeGen = (self._fadeGen or 0) + 1
    local gen = self._fadeGen
    if self._main and self._main.Parent then
    end
    local scale = self._mainScale
    if not (scale and scale.Parent) then return end
    scale.Scale = 0.96
    local tw = TweenService:Create(scale,
        TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Scale = 1 })
    self._fadeTween = tw
    tw:Play()
    task.delay(0.55, function()
        if self._fadeGen ~= gen then return end
        if scale and scale.Parent then scale.Scale = 1 end
        if self._main and self._main.Parent then end
    end)
end

function Library:_finishFadeIn()
    self._fadeGen = (self._fadeGen or 0) + 1
    if self._fadeTween then
        pcall(function() self._fadeTween:Cancel() end)
        self._fadeTween = nil
    end
    if self._main and self._main.Parent then
    end
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
    row.ZIndex = ZBASE + 2

    local sel = Instance.new("Frame", row)
    sel.Name = "TabSel"
    sel.Size = UDim2.new(1, 0, 1, 0)
    sel.Position = UDim2.new(0, 0, 0, 0)
    sel.BackgroundColor3 = Cfg.TabSelFill
    sel.BackgroundTransparency = 1
    sel.BorderSizePixel = 0
    sel.Visible = false
    sel.ZIndex = ZBASE + 1
    sel:SetAttribute("_skipFade", true)
    local selCorner = Instance.new("UICorner", sel)
    selCorner.CornerRadius = Cfg.TabSelCorner
    local selStroke = Instance.new("UIStroke", sel)
    selStroke.Color = Cfg.TabSelStroke
    selStroke.Thickness = Cfg.TabSelStrokeThickness
    selStroke.Transparency = 1
    selStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    selStroke:SetAttribute("_skipFade", true)
    local selGrad = Instance.new("UIGradient", sel)
    selGrad.Rotation = 135
    selGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(66, 76, 104)),
        ColorSequenceKeypoint.new(1, Cfg.TabSelFill),
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
        ticon.ZIndex = ZBASE + 3
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
    tname.ZIndex = ZBASE + 3
    if hasIcon then
        local x = s(Cfg.TabRowPadX + Cfg.TabIconSize + Cfg.TabTextGap)
        tname.Size = UDim2.new(1, -x, 1, 0)
        tname.Position = UDim2.new(0, x, 0, 0)
    else
        tname.Size = UDim2.new(1, -s(Cfg.TabRowPadX * 2), 1, 0)
        tname.Position = UDim2.new(0, s(Cfg.TabRowPadX), 0, 0)
    end

    local container = Instance.new("Frame", self._scroller)
    container.Name = "Container_" .. name
    container.Size = UDim2.fromOffset((self._controlW or self._sizeX) - PAD_IN * 2, (self._viewH or self._sizeY) - PAD_TOP - PAD_IN)
    container.Position = UDim2.fromOffset(PAD_IN, PAD_TOP)
    container.BackgroundTransparency = 1
    setGroupTransparency(container, 0)
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
    updateCanvas(self)
    if #self._tabs == 1 then selectTab(self, 1) end
    return tab
end

return Library
