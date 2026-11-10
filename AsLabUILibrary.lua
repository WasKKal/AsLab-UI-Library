-- AsLab UI Library
-- 一个 Roblox UI 库：模仿 ImGui 的即时模式体验 + Apple / iOS26 液态玻璃视觉风格
-- 本文件仅实现以下规格（不含其他扩展）：
--   1) 入场动画：渐显
--   2) 整体玻璃效果（雾化液态玻璃 + 角落微光），大小由 CreateWindow 的 Size 控制
--   3) UI 布局（标题栏 / 信息栏 / 左侧选项卡 / 右侧控件区）
--   4) 选项卡含 Icon 与文字（结构照抄 DynamicCowUI）；右侧控件区仅含 Toggle 与 Button
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

-- ===================== 主题（iOS26 液态玻璃 / Apple 风） =====================
-- 注意：必须定义在 applyIcon / makeGlass 等使用前，避免 forward-reference 取到 nil。
local Style = {
    Glass = Color3.fromRGB(28, 28, 34),        -- 玻璃底色（暗态液态玻璃）
    GlassTop = Color3.fromRGB(46, 46, 54),     -- 顶部略亮，营造磨砂景深
    GlassTransparency = 0.62,                  -- 玻璃通透度（雾化感）
    Stroke = Color3.fromRGB(255, 255, 255),    -- 轮廓高光（rim light）
    StrokeTransparency = 0.72,
    Radius = UDim.new(0, s(18)),
    Text = Color3.fromRGB(245, 245, 247),
    Font = Enum.Font.Gotham,
    -- Toggle 开启态：方块背景银白、图标/文字变黑（平滑过渡）
    ToggleSilver = Color3.fromRGB(228, 230, 236),
    ToggleDark = Color3.fromRGB(22, 22, 26),
}

-- ===================== 选项卡区域（结构照抄 DynamicCowUI 的常量） =====================
local Cfg = {
    DividerColor = Color3.fromRGB(64, 64, 72),
    TabWidth = 130,                 -- 左侧选项卡列表宽度
    TabAreaGap = 12,                -- 选项卡列表与内容区之间间距（含分隔线）
    TabRowHeight = 30,
    TabRowGap = 4,
    TabIconSize = 18,
    TabTextSize = 15,
    TabTextGap = 8,
    TabRowPadX = 6,
    TabActiveColor = Color3.fromRGB(255, 255, 255),
    TabInactiveColor = Color3.fromRGB(150, 152, 162),
    TabSelFill = Color3.fromRGB(34, 34, 42),
    TabSelFillTransparency = 0.15,
    TabSelStroke = Color3.new(1, 1, 1),
    TabSelStrokeThickness = 1,
    TabSelCorner = UDim.new(0, s(8)),
    TabSelFadeTime = 0.18,
}

-- 布局常量（像素，决定内部比例，整体由 Size 缩放；受 SCALE 控制）
local SIDEBAR_W    = s(Cfg.TabWidth)      -- 左侧选项卡列表宽度
local TAB_AREA_GAP = s(Cfg.TabAreaGap)    -- 列表与内容区间距
local HEADER_H     = s(42)   -- 标题栏高度
local INFO_H       = s(34)   -- 信息栏高度
local PAD          = s(10)   -- 外边距
local GAP          = s(10)   -- 方块间距
local MIN_BLOCK    = s(92)   -- 方块最小边长（用于推算单行数量）
local PAD_IN       = s(12)   -- 控件区内部边距

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
-- 图标为单色 SVG，通过 ImageLabel.ImageColor3 统一着色。
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
-- color 可选：覆盖着色色（选项卡未选中态用灰，而非默认白）
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

-- 提前拉取 Lucide 模块（可选，避免首次用图标时阻塞）
function Library.PreloadLucide()
    return loadLucide() ~= nil
end

-- ===================== GUI 挂载点（参考 DynamicCow：优先 gethui） =====================
local function getHolder()
    local ok, h = pcall(function() return gethui() end)
    if ok and h then return h end
    ok, h = pcall(function() return game:GetService("CoreGui") end)
    if ok and h then return h end
    local ok2, pg = pcall(function() return Players.LocalPlayer:WaitForChild("PlayerGui", 5) end)
    if ok2 and pg then return pg end
    return nil
end

-- ===================== 玻璃工厂（iOS26 液态玻璃 / 雾化 + 角落微光） =====================
-- 创建一块液态玻璃；props.Class 允许覆盖为 TextButton（让方块可点击）。
-- props.Plain=true 时跳过竖向底渐变（控件方块需要纯 BackgroundColor3 以支持颜色平滑过渡）。
-- 关键：整面柔和渐变 + 细亮轮廓边（rim），绝不做成刺眼的大块亮斑（sun glare）。
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

    -- 雾化景深：整面柔和竖向渐变（顶部略亮），营造磨砂玻璃的层次感
    if not props.Plain then
        local bg = Instance.new("UIGradient", f)
        bg.Rotation = 90
        bg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, props.GlassTop or Style.GlassTop),
            ColorSequenceKeypoint.new(1, props.Color or Style.Glass),
        })
    end

    -- 轮廓高光（rim light）：细亮描边，液态玻璃的边框光
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Style.Stroke
    stroke.Transparency = props.StrokeTransparency or Style.StrokeTransparency
    stroke.Thickness = 1

    -- 角落微光：整面柔和对角渐变，左上角一抹微光（透明度高、无刺眼亮斑）
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

    return f
end

-- ===================== 控件布局辅助（前置定义，避免 forward-reference 取到 nil） =====================
-- 按窗口大小推算单行数量（1~3）与方块边长（正方形比例）。
local function relayout(tab)
    local win = tab._win
    -- 与 controlRegion 实际宽度对齐，再扣除 container 内部左右边距
    local areaW = (win._controlW or win._sizeX) - PAD_IN * 2
    local n = math.min(3, math.max(1, math.floor((areaW + GAP) / (MIN_BLOCK + GAP))))
    local side = (areaW - GAP * (n - 1)) / n

    for i, ctrl in ipairs(tab._controls) do
        local col = (i - 1) % n
        local row = math.floor((i - 1) / n)
        ctrl._block.Size = UDim2.new(0, side, 0, side)
        ctrl._block.Position = UDim2.new(0, col * (side + GAP), 0, row * (side + GAP))
    end
end

-- Toggle 状态外观：开启时方块背景平滑变银白、图标/文字平滑变黑；关闭时平滑还原
local function refreshToggle(ctrl, animate)
    local st = ctrl._state
    local bg = st and Style.ToggleSilver or Style.Glass
    local fg = st and Style.ToggleDark or Style.Text
    local ti = animate and TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or nil
    local function tw(obj, prop, val)
        if not (obj and obj.Parent) then return end
        if ti then
            TweenService:Create(obj, ti, { [prop] = val }):Play()
        else
            obj[prop] = val
        end
    end
    tw(ctrl._block, "BackgroundColor3", bg)
    if ctrl._icon then tw(ctrl._icon, "ImageColor3", fg) end
    if ctrl._title then tw(ctrl._title, "TextColor3", fg) end
end

-- 按压反馈：按下缩小并叠加暗层，松开回弹。按住期间保持该状态。
local function setPressed(ctrl, on)
    if not (ctrl._scale and ctrl._scale.Parent) then return end
    local ti = TweenInfo.new(on and 0.12 or 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(ctrl._scale, ti, { Scale = on and 0.9 or 1 }):Play()
    TweenService:Create(ctrl._press, TweenInfo.new(0.15), {
        BackgroundTransparency = on and 0.18 or 1,
    }):Play()
end

-- 触发一次点击逻辑（Toggle 切换状态 / Button 执行回调）
local function fireClick(ctrl)
    local opts = ctrl._opts or {}
    if ctrl._kind == "Toggle" then
        ctrl._state = not ctrl._state
        refreshToggle(ctrl, true)
        if opts.Callback then pcall(opts.Callback, ctrl._state) end
    else
        if opts.Callback then pcall(opts.Callback) end
    end
end

-- 绑定按压交互：MouseButton1Down 进入按压态并保持，Up 松开回弹并触发点击；移出取消
local function bindPress(ctrl)
    local block = ctrl._block
    ctrl._pressed = false
    block.MouseButton1Down:Connect(function()
        ctrl._pressed = true
        setPressed(ctrl, true)
    end)
    block.MouseButton1Up:Connect(function()
        if not ctrl._pressed then return end
        ctrl._pressed = false
        setPressed(ctrl, false)
        fireClick(ctrl)
    end)
    block.MouseLeave:Connect(function()
        if ctrl._pressed then
            ctrl._pressed = false
            setPressed(ctrl, false)
        end
    end)
end

-- kind: "Toggle" | "Button"
local function addControl(tab, kind, opts)
    opts = opts or {}

    -- Plain=true：不加竖向底渐变，让 BackgroundColor3 可直接被平滑 tween（Toggle 银白切换）
    local block = makeGlass(tab._container, {
        Name = kind,
        Class = "TextButton",
        Size = UDim2.new(0, 100, 0, 100), -- 占位，relayout 会重设
        Position = UDim2.new(0, 0, 0, 0),
        Transparency = 0.55,
        Radius = UDim.new(0, s(16)),
        Highlight = 0.86,
        Plain = true,
    })

    local ctrl = { _tab = tab, _kind = kind, _block = block, _opts = opts, _state = opts.Default or false }

    -- 按压暗层（按下时平滑显现，松开恢复；跳过入场渐显以免与之冲突）
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
        -- 有图标：图标居中稍大，Title 在图标下方
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
        ctrl._title = tx
    end

    -- Toggle 初始外观（不再有右上角指示球）
    if kind == "Toggle" then
        refreshToggle(ctrl, false)
    end

    bindPress(ctrl)

    table.insert(tab._controls, ctrl)
    relayout(tab)
    return ctrl
end

-- 选项卡高亮（照抄 DynamicCowUI 的 updateTabsHighlight）：颜色 + 选中滑框平滑渐显
function selectTab(win, activeIdx)
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

-- ===================== 创建窗口 =====================
function Library.CreateWindow(opts)
    opts = opts or {}
    local Size = opts.Size or UDim2.fromOffset(s(620), s(460))
    local Title = opts.Title or "我是标题"
    local InfoText = opts.Info or "我是Info"
    local LeftText = opts.Left or "我是"

    local holder = getHolder()
    if not holder then return nil end

    local gui = Instance.new("ScreenGui", holder)
    gui.Name = "AsLabUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 暗化背景层（参考 DynamicCow 的 Backdrop），让雾化玻璃更突出
    local backdrop = Instance.new("Frame", gui)
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.45
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 0

    -- 主玻璃面板（雾化液态玻璃）：整体大小完全由 Size 控制
    local main = makeGlass(gui, {
        Name = "Main",
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        Transparency = Style.GlassTransparency,
        Radius = UDim.new(0, s(24)),
        Highlight = 0.82,
    })
    main.ZIndex = 1

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
        Highlight = 0.88,
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

    -- ---- 信息栏（我是Info） ----
    local info = Instance.new("Frame", main)
    info.Name = "InfoBar"
    info.Size = UDim2.new(1, 0, 0, INFO_H)
    info.Position = UDim2.new(0, 0, 0, HEADER_H)
    info.BackgroundTransparency = 1
    info.BorderSizePixel = 0

    local infoText = Instance.new("TextLabel", info)
    infoText.Size = UDim2.new(1, -PAD * 2, 1, 0)
    infoText.Position = UDim2.new(0, PAD, 0, 0)
    infoText.Text = InfoText
    infoText.Font = Style.Font
    infoText.TextSize = s(13)
    infoText.TextColor3 = Style.Text
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.BackgroundTransparency = 1

    -- ---- 主体：左侧选项卡列表 + 分隔线 + 右侧控件区（结构照抄 DynamicCow） ----
    local bodyY = HEADER_H + INFO_H

    local sidebar = Instance.new("Frame", main)
    sidebar.Name = "TabList"
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -bodyY - PAD)
    sidebar.Position = UDim2.new(0, PAD / 2, 0, bodyY)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0

    -- 分隔竖线（DynamicCow 的 TabSeparator）
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
            if c:GetAttribute("_skipFade") then
                -- 状态层（选中框/按压层）不参与入场渐显，避免与状态动画冲突
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

-- ===================== 选项卡（结构完全照抄 DynamicCowUI 的 TabRow） =====================
function Library:AddTab(name, icon)
    local idx = #self._tabs + 1

    -- 行：透明 TextButton（不是玻璃块），横向「图标在左 + 文字在右」
    local row = Instance.new("TextButton", self._sidebar)
    row.Name = "TabRow"
    row.Size = UDim2.new(1, 0, 0, s(Cfg.TabRowHeight))
    row.Position = UDim2.new(0, 0, 0, (idx - 1) * s(Cfg.TabRowHeight + Cfg.TabRowGap))
    row.BackgroundTransparency = 1
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = idx
    row.ZIndex = 2

    -- 选中滑框 TabSel：圆角 + 白描边 + 135° 对角渐变，平滑渐显
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
        ColorSequenceKeypoint.new(0, Color3.fromRGB(104, 106, 118)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 34)),
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

    local container = Instance.new("Frame", self._controlRegion)
    container.Name = "Container_" .. name
    container.Size = UDim2.new(1, -PAD_IN * 2, 1, -PAD_IN * 2)
    container.Position = UDim2.new(0, PAD_IN, 0, PAD_IN)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false

    local tab = {
        _win = self, _name = name,
        _row = row, _sel = sel, _selStroke = selStroke,
        _icon = ticon, _nameLabel = tname,
        _container = container, _controls = {},
    }

    function tab:AddToggle(o) return addControl(tab, "Toggle", o) end
    function tab:AddButton(o) return addControl(tab, "Button", o) end

    row.MouseButton1Click:Connect(function()
        selectTab(self, idx)
    end)

    table.insert(self._tabs, tab)
    if #self._tabs == 1 then
        selectTab(self, 1)
    end
    return tab
end

return Library
