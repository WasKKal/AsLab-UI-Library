-- AsLab UI Library
-- 一个 Roblox UI 库：模仿 ImGui 的即时模式体验 + Apple 的液态玻璃视觉风格
-- 本文件仅实现以下规格（不含其他扩展）：
--   1) 入场动画：渐显
--   2) 整体玻璃效果（带角落高光），大小由 CreateWindow 的 Size 控制
--   3) UI 布局（标题栏 / 信息栏 / 左侧竖向选项卡 / 右侧控件区）
--   4) 选项卡含 Icon 与文字；右侧控件区仅含 Toggle 与 Button
--   5) 控件为正方形 + 圆角 + 同款液态玻璃；可选 Icon
--   6) 方块按顺序排列，单行最多 3 个；按窗口大小分配单行数量与方块比例
--   7) 有 Icon：图标居中稍大，Title 在图标下方；无 Icon：文字居中方块

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Library = {}
Library.__index = Library

-- ===================== 整体 UI 比例 =====================
-- 缩小/放大整体内部比例（仅影响内部元素，窗口外框仍由 CreateWindow 的 Size 控制）
local SCALE = 0.85
local function s(n) return n * SCALE end

-- ===================== 主题（Apple 风液态玻璃） =====================
-- 注意：必须定义在 applyIcon / makeGlass 等使用前，避免 forward-reference 取到 nil。
local Style = {
    Glass = Color3.fromRGB(28, 28, 32),       -- 玻璃底色
    GlassTransparency = 0.72,                  -- 玻璃通透度
    Stroke = Color3.fromRGB(255, 255, 255),    -- 描边（高光感）
    StrokeTransparency = 0.82,
    Radius = UDim.new(0, s(18)),
    Text = Color3.fromRGB(245, 245, 247),
    Accent = Color3.fromRGB(0, 122, 255),      -- Apple 蓝
    ToggleOn = Color3.fromRGB(48, 209, 88),    -- Apple 绿
    ToggleOff = Color3.fromRGB(120, 120, 128),
    Font = Enum.Font.Gotham,
}

-- 布局常量（像素，决定内部比例，整体由 Size 缩放；受 SCALE 控制）
local SIDEBAR_W = s(72)   -- 左侧选项卡宽度
local HEADER_H  = s(42)   -- 标题栏高度
local INFO_H    = s(34)   -- 信息栏高度
local PAD       = s(10)   -- 外边距
local GAP       = s(10)   -- 方块间距
local MIN_BLOCK = s(92)   -- 方块最小边长（用于推算单行数量）
local PAD_IN    = s(12)   -- 控件区内部边距

-- ===================== 网络请求（多执行环境兼容） =====================
local function httpGet(url)
    local ok, res = pcall(function()
        if type(_G.httpGet) == "function" then
            return _G.httpGet(url)
        end
        if type(request) == "function" then
            local r = request({ Url = url, Method = "GET" })
            return r and (r.Body or r.body)
        end
        if type(syn) == "table" and type(syn.request) == "function" then
            local r = syn.request({ Url = url, Method = "GET" })
            return r and (r.Body or r.body)
        end
        if game and type(game.HttpGet) == "function" then
            return game:HttpGet(url)
        end
        return nil
    end)
    return ok and res or nil
end

-- ===================== Lucide 图标集成 =====================
-- 复用 WasKKal/DeltaExecutor-UI-Rebuild@lucide-v6 的 lucide 模块：
--   module.GetAsset(name) -> { Url, ImageRectOffset?, ImageRectSize? }
-- 图标为单色 SVG，通过 ImageLabel.ImageColor3 统一着色（Apple 白）。
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
        if ok and type(res) == "string" and #res > 5000 then
            content = res
            break
        end
        task.wait(0.3)
    end
    if not content then return nil end
    local func, err = loadstring(content)
    if not func then return nil end
    local ok, module = pcall(func)
    if not ok or type(module) ~= "table" or type(module.GetAsset) ~= "function" then
        return nil
    end
    LucideModule = module
    return LucideModule
end

-- Icon 参数支持：直接资源（http(s):// / rbxasset:// / 其他 scheme）或 Lucide 图标名
local function resolveIcon(icon)
    if type(icon) ~= "string" or #icon == 0 then return nil end
    if icon:match("^%a[%w+.-]*://") then
        return { Url = icon }
    end
    if LucideCache[icon] ~= nil then
        return LucideCache[icon]
    end
    local asset = nil
    local mod = loadLucide()
    if mod then
        local ok, a = pcall(mod.GetAsset, icon)
        if ok and a and a.Url then asset = a end
    end
    LucideCache[icon] = asset or false
    return asset
end

-- 把图标解析结果应用到 ImageLabel，并统一着色 / 缩放
local function applyIcon(imageLabel, icon)
    local asset = resolveIcon(icon)
    if not asset then return false end
    imageLabel.Image = asset.Url
    if asset.ImageRectOffset then
        imageLabel.ImageRectOffset = asset.ImageRectOffset
        imageLabel.ImageRectSize = asset.ImageRectSize
    end
    -- 兜底：Style 任意情况下都应有值；若异常则回退到安全白
    imageLabel.ImageColor3 = (Style and Style.Text) or Color3.fromRGB(245, 245, 247)
    imageLabel.ScaleType = Enum.ScaleType.Fit
    return true
end

-- 提前拉取 Lucide 模块（可选，避免首次用图标时阻塞）
function Library.PreloadLucide()
    return loadLucide() ~= nil
end

-- ===================== 玻璃工厂 =====================
-- 创建一块液态玻璃；可选带左上角高光（Sheen）。
-- props.Class 允许覆盖为 TextButton（让方块可点击）。
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

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Style.Stroke
    stroke.Transparency = Style.StrokeTransparency
    stroke.Thickness = 1

    -- 玻璃光泽 + 角落高光：左上区域白色渐隐
    local sheen = Instance.new("Frame", f)
    sheen.Name = "Sheen"
    sheen.Size = UDim2.new(0.7, 0, 0.7, 0)
    sheen.Position = UDim2.new(0, 0, 0, 0)
    sheen.BackgroundTransparency = 1
    sheen.BorderSizePixel = 0
    sheen.Active = false
    local sg = Instance.new("UIGradient", sheen)
    sg.Rotation = 45
    sg.Color = ColorSequence.new(Color3.new(1, 1, 1))
    sg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, props.Highlight or 0.78),
        NumberSequenceKeypoint.new(1, 1),
    })

    return f
end

-- ===================== 创建窗口 =====================
function Library.CreateWindow(opts)
    opts = opts or {}
    local Size = opts.Size or UDim2.fromOffset(s(620), s(460))
    local Title = opts.Title or "我是标题"
    local InfoText = opts.Info or "我是Info"
    local InfoIcon = opts.InfoIcon
    local LeftText = opts.Left or "我是"

    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui", pg)
    gui.Name = "AsLabUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 主玻璃面板：整体大小完全由 Size 控制
    local main = makeGlass(gui, {
        Name = "Main",
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        Transparency = Style.GlassTransparency,
        Radius = UDim.new(0, s(24)),
        Highlight = 0.7,
    })

    -- ---- 标题栏 ----
    local header = Instance.new("Frame", main)
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0

    local leftLabel = Instance.new("TextLabel", header)
    leftLabel.Size = UDim2.new(0, s(80), 1, 0)
    leftLabel.Position = UDim2.new(0, PAD, 0, 0)
    leftLabel.Text = LeftText
    leftLabel.Font = Style.Font
    leftLabel.TextSize = s(15)
    leftLabel.TextColor3 = Style.Text
    leftLabel.TextXAlignment = Enum.TextXAlignment.Left
    leftLabel.BackgroundTransparency = 1

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -s(210), 1, 0)
    titleLabel.Position = UDim2.new(0, s(95), 0, 0)
    titleLabel.Text = Title
    titleLabel.Font = Style.Font
    titleLabel.TextSize = s(18)
    titleLabel.TextColor3 = Style.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.BackgroundTransparency = 1

    -- ---- 关闭按钮（圆形） ----
    local closeSize = s(30)
    local closeBtn = makeGlass(header, {
        Name = "Close",
        Class = "TextButton",
        Size = UDim2.new(0, closeSize, 0, closeSize),
        Position = UDim2.new(1, -PAD - closeSize, 0.5, -closeSize / 2),
        Transparency = 0.6,
        Radius = UDim.new(1, 0),  -- 1,0 = 正圆
        Highlight = 0.85,
    })
    local closeTxt = Instance.new("TextLabel", closeBtn)
    closeTxt.Size = UDim2.fromScale(1, 1)
    closeTxt.Text = "关闭"
    closeTxt.Font = Style.Font
    closeTxt.TextSize = s(11)
    closeTxt.TextColor3 = Style.Text
    closeTxt.BackgroundTransparency = 1
    closeTxt.Active = false
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- ---- 信息栏（图标 + 我是Info） ----
    local info = Instance.new("Frame", main)
    info.Name = "InfoBar"
    info.Size = UDim2.new(1, 0, 0, INFO_H)
    info.Position = UDim2.new(0, 0, 0, HEADER_H)
    info.BackgroundTransparency = 1
    info.BorderSizePixel = 0

    local infoIconOffset = 0
    if InfoIcon then
        local ic = Instance.new("ImageLabel", info)
        ic.Size = UDim2.new(0, s(20), 0, s(20))
        ic.Position = UDim2.new(0, PAD + s(4), 0.5, -s(10))
        ic.BackgroundTransparency = 1
        applyIcon(ic, InfoIcon)
        infoIconOffset = s(32)
    end
    local infoText = Instance.new("TextLabel", info)
    infoText.Size = UDim2.new(1, -PAD * 2 - infoIconOffset, 1, 0)
    infoText.Position = UDim2.new(0, PAD + infoIconOffset, 0, 0)
    infoText.Text = InfoText
    infoText.Font = Style.Font
    infoText.TextSize = s(13)
    infoText.TextColor3 = Style.Text
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.BackgroundTransparency = 1

    -- ---- 主体：左侧选项卡 + 右侧控件区 ----
    local bodyY = HEADER_H + INFO_H

    local sidebar = Instance.new("Frame", main)
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -bodyY)
    sidebar.Position = UDim2.new(0, 0, 0, bodyY)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0

    local controlRegion = Instance.new("Frame", main)
    controlRegion.Name = "ControlRegion"
    controlRegion.Size = UDim2.new(1, -SIDEBAR_W, 1, -bodyY)
    controlRegion.Position = UDim2.new(0, SIDEBAR_W, 0, bodyY)
    controlRegion.BackgroundTransparency = 1
    controlRegion.BorderSizePixel = 0

    local win = {
        _gui = gui,
        _main = main,
        _sidebar = sidebar,
        _controlRegion = controlRegion,
        _tabs = {},
        _selected = nil,
        _sizeX = Size.X.Offset,
        _sizeY = Size.Y.Offset,
    }
    setmetatable(win, Library)

    -- 入场动画：渐显（在同步 setup 结束后执行，覆盖所有已添加控件）
    task.delay(0, function()
        if gui and gui.Parent then
            pcall(function() win:_fadeIn() end)
        end
    end)

    return win
end

-- ===================== 入场渐显 =====================
function Library:_fadeIn()
    local targets = {}
    local function scan(obj)
        for _, c in ipairs(obj:GetDescendants()) do
            if c:IsA("Frame") or c:IsA("ImageLabel") or c:IsA("ImageButton") then
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

-- ===================== 选项卡 =====================
function Library:AddTab(name, icon)
    local idx = #self._tabs + 1
    local btnH = s(58)
    local btn = makeGlass(self._sidebar, {
        Name = "Tab_" .. name,
        Class = "TextButton",
        Size = UDim2.new(1, -PAD, 0, btnH),
        Position = UDim2.new(0, PAD / 2, 0, PAD + (idx - 1) * (btnH + PAD / 2)),
        Transparency = 0.7,
        Radius = UDim.new(0, s(14)),
        Highlight = 0.85,
    })

    if icon then
        local ic = Instance.new("ImageLabel", btn)
        ic.Size = UDim2.new(0, s(24), 0, s(24))
        ic.Position = UDim2.new(0.5, -s(12), 0, s(8))
        ic.BackgroundTransparency = 1
        ic.Active = false
        applyIcon(ic, icon)
        local tx = Instance.new("TextLabel", btn)
        tx.Size = UDim2.new(1, 0, 0, s(18))
        tx.Position = UDim2.new(0, 0, 0, s(38))
        tx.Text = name
        tx.Font = Style.Font
        tx.TextSize = s(11)
        tx.TextColor3 = Style.Text
        tx.TextXAlignment = Enum.TextXAlignment.Center
        tx.BackgroundTransparency = 1
        tx.Active = false
    else
        local tx = Instance.new("TextLabel", btn)
        tx.Size = UDim2.new(1, 0, 1, 0)
        tx.Text = name
        tx.Font = Style.Font
        tx.TextSize = s(12)
        tx.TextColor3 = Style.Text
        tx.TextXAlignment = Enum.TextXAlignment.Center
        tx.BackgroundTransparency = 1
        tx.Active = false
    end

    local container = Instance.new("Frame", self._controlRegion)
    container.Name = "Container_" .. name
    container.Size = UDim2.new(1, -PAD_IN * 2, 1, -PAD_IN * 2)
    container.Position = UDim2.new(0, PAD_IN, 0, PAD_IN)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false

    local tab = { _win = self, _name = name, _button = btn, _container = container, _controls = {} }

    function tab:AddToggle(o) return addControl(tab, "Toggle", o) end
    function tab:AddButton(o) return addControl(tab, "Button", o) end

    btn.MouseButton1Click:Connect(function()
        selectTab(self, tab)
    end)

    table.insert(self._tabs, tab)
    if #self._tabs == 1 then
        selectTab(self, tab)
    end
    return tab
end

function selectTab(win, tab)
    for _, t in ipairs(win._tabs) do
        t._container.Visible = (t == tab)
        t._button.BackgroundTransparency = (t == tab) and 0.3 or 0.7
    end
    win._selected = tab
end

-- ===================== 控件布局（正方形方块网格） =====================
-- 按窗口大小推算单行数量（1~3）与方块边长（正方形比例）。
local function relayout(tab)
    local win = tab._win
    local areaW = win._sizeX - SIDEBAR_W - PAD_IN * 2
    local n = math.min(3, math.max(1, math.floor((areaW + GAP) / (MIN_BLOCK + GAP))))
    local side = (areaW - GAP * (n - 1)) / n

    for i, ctrl in ipairs(tab._controls) do
        local col = (i - 1) % n
        local row = math.floor((i - 1) / n)
        ctrl._block.Size = UDim2.new(0, side, 0, side)
        ctrl._block.Position = UDim2.new(0, col * (side + GAP), 0, row * (side + GAP))
    end
end

local function refreshToggle(ctrl)
    if ctrl._ind then
        ctrl._ind.BackgroundColor3 = ctrl._state and Style.ToggleOn or Style.ToggleOff
    end
    ctrl._block.BackgroundColor3 = ctrl._state and Style.Accent or Style.Glass
end

-- kind: "Toggle" | "Button"
local function addControl(tab, kind, opts)
    opts = opts or {}

    local block = makeGlass(tab._container, {
        Name = kind,
        Class = "TextButton",
        Size = UDim2.new(0, 100, 0, 100), -- 占位，relayout 会重设
        Position = UDim2.new(0, 0, 0, 0),
        Transparency = 0.55,
        Radius = UDim.new(0, s(16)),
        Highlight = 0.82,
    })

    local ctrl = { _tab = tab, _kind = kind, _block = block, _opts = opts, _state = opts.Default or false }

    if opts.Icon then
        -- 有图标：图标居中稍大，Title 在图标下方
        local ic = Instance.new("ImageLabel", block)
        ic.Name = "Icon"
        ic.Size = UDim2.new(0.46, 0, 0.46, 0)
        ic.Position = UDim2.new(0.27, 0, 0.16, 0)
        ic.BackgroundTransparency = 1
        ic.Active = false
        applyIcon(ic, opts.Icon)
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
    else
        -- 无图标：文字居中方块
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
    end

    if kind == "Toggle" then
        local ind = Instance.new("Frame", block)
        ind.Name = "State"
        ind.Size = UDim2.new(0.22, 0, 0.22, 0)
        ind.Position = UDim2.new(0.72, 0, 0.06, 0)
        ind.BackgroundColor3 = Style.ToggleOff
        ind.BackgroundTransparency = 0.25
        ind.BorderSizePixel = 0
        ind.Active = false
        local ic = Instance.new("UICorner", ind)
        ic.CornerRadius = UDim.new(1, 0)
        ctrl._ind = ind
        refreshToggle(ctrl)
    end

    block.MouseButton1Click:Connect(function()
        if kind == "Toggle" then
            ctrl._state = not ctrl._state
            refreshToggle(ctrl)
            if opts.Callback then pcall(opts.Callback, ctrl._state) end
        else
            if opts.Callback then pcall(opts.Callback) end
        end
    end)

    table.insert(tab._controls, ctrl)
    relayout(tab)
    return ctrl
end

return Library
