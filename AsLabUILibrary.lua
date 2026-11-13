local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Library = {}
Library.__index = Library

local fadeGroup, setGroupTransparency, tweenGroup, showColorPanel
local slotY, createShortcut, destroyShortcut, startListen, refreshConflicts

local SCALE = 0.85
local function s(n) return n * SCALE end

local function colorToHSV(c)
    local r, g, b = c.R, c.G, c.B
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local d = mx - mn
    local h = 0
    if d > 1e-6 then
        if mx == r then h = ((g - b) / d) % 6
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    local sat = (mx <= 0) and 0 or (d / mx)
    return h, sat, mx
end

local function hsvToColor(h, sat, val)
    h = (h or 0) % 1
    sat = math.clamp(sat or 0, 0, 1)
    val = math.clamp(val or 0, 0, 1)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = val * (1 - sat)
    local q = val * (1 - f * sat)
    local t = val * (1 - (1 - f) * sat)
    local r, g, b
    local m = i % 6
    if m == 0 then r, g, b = val, t, p
    elseif m == 1 then r, g, b = q, val, p
    elseif m == 2 then r, g, b = p, val, t
    elseif m == 3 then r, g, b = p, q, val
    elseif m == 4 then r, g, b = t, p, val
    else r, g, b = val, p, q end
    return Color3.new(r, g, b)
end

local function isColor3(c)
    if c == nil then return false end
    if typeof(c) == "Color3" then return true end
    local ok, r, g, b = pcall(function() return c.R, c.G, c.B end)
    return ok and r ~= nil and g ~= nil and b ~= nil
end

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
-- 标题/Info 超线时，竖分隔线顶部下移到标题栏下方的量（避开超长文字）；
-- 竖线底部同时向下延长，与 FooterSeparator 一起闭合关闭按钮区域。
local SEP_TOP_SHRINK = HEADER_H + s(2)
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

AvailableLanguages = { "English", "中文" }
Library.AvailableLanguages = AvailableLanguages

local DEFAULT_CN = {
    ["Settings"] = "设置",
    ["Window Size"] = "窗口大小",
    ["Language"] = "语言",
    ["Apply"] = "应用",
    ["Board-Key"] = "快捷键",
    ["AddShortcut"] = "添加快捷键",
    ["Add"] = "添加",
    ["Create"] = "创建",
    ["Delete"] = "删除",
    ["Setting"] = "设置",
    ["Run"] = "运行",
    ["OFF"] = "关",
    ["ON"] = "开",
    ["Confirm"] = "确认",
    ["Cancel"] = "取消",
    ["Yes"] = "是",
    ["No"] = "否",
    ["Close"] = "关闭",
    ["Minimize"] = "最小化",
    ["Are you sure you want to close?"] = "确定要关闭窗口吗？",
    ["Tap A Key"] = "请按一个键",
    ["Conflict with"] = "冲突于",
    -- Config Manager（配置管理面板）文案
    ["Config Manager"] = "配置管理",
    ["Delete Config"] = "删除配置",
    ["Save Config"] = "保存配置",
    ["Load Config"] = "载入配置",
    ["Select Config"] = "选择配置",
    ["No Configs"] = "暂无配置",
    ["Config Loaded"] = "已载入该配置",
    ["Config Deleted"] = "已删除该配置",
    ["Config Saved"] = "已储存配置",
    ["Saved as"] = "已储存为",
    ["Select a config first"] = "请先选择配置",
    ["Cannot delete default config"] = "无法删除默认配置",
}

local function translateKey(win, key)
    key = tostring(key or "")
    if key == "" then return key end
    local lang = (win and win._language) or "English"
    if lang == "English" then return key end
    local custom = win and win._translations and win._translations[lang] and win._translations[lang][key]
    if custom ~= nil then return custom end
    return DEFAULT_CN[key] or key
end

local function i18nText(win, obj, key)
    if not (win and obj) then
        if obj then obj.Text = tostring(key or "") end
        return
    end
    win._i18n = win._i18n or {}
    obj.Text = translateKey(win, key)
    table.insert(win._i18n, { obj = obj, key = key })
end

local function i18nDynamic(win, fn)
    if not (win and fn) then return end
    win._i18nDynamic = win._i18nDynamic or {}
    table.insert(win._i18nDynamic, fn)
end

-- 把某个已注册 i18n 对象的翻译 key 改成新标题（SetTitle 用），
-- 避免语言切换时 applyLang 用旧 key 把标题覆盖回去。
local function retargetI18n(win, obj, key)
    if not (win and obj) then return end
    for _, e in ipairs(win._i18n or {}) do
        if e.obj == obj then e.key = key end
    end
end

--[[
    输入盾：拖动窗口 / Shortcut / 悬浮球，以及设置页打开期间，屏蔽触摸穿透到 3D 视角。
    Roblox 中 Touch 拖动 GUI 时，若命中区不是 Active 输入，触摸会穿透到 Camera 导致
    屏幕视角移动。这里用「全屏 Active 透明层 + UserInputService.ModalEnabled」双重阻断：
      · 全屏层 ZIndex 低于所有交互层，只吃掉空白区触摸，不遮挡面板按钮 / 滑块；
      · ModalEnabled 阻止输入作用于 3D 世界（相机 / 角色），但不影响 GUI 事件，
        也不吞掉拖动所依赖的 InputChanged / InputEnded，拖动本身不受影响。
    用 key 集合管理多来源，幂等且互不干扰（窗口 / 悬浮球 / Shortcut / 设置页可叠加）。
]]
local function setInputSink(win, key, on)
    if not win then return end
    win._sinks = win._sinks or {}
    local before = next(win._sinks) ~= nil
    if on then win._sinks[key] = true else win._sinks[key] = nil end
    local after = next(win._sinks) ~= nil
    if before == after then return end
    win._inputSinkActive = after
    if win._inputShield then win._inputShield.Visible = after end
    pcall(function() UserInputService.ModalEnabled = after end)
end

local function applyLang(win)
    if not win then return end
    for _, e in ipairs(win._i18n or {}) do
        if e.obj and e.obj.Parent then e.obj.Text = translateKey(win, e.key) end
    end
    for _, fn in ipairs(win._i18nDynamic or {}) do pcall(fn) end
end

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
        if not ok or h == nil then return nil end
        local t = typeof(h)
        if t == "Instance" or type(h) == "table" or type(h) == "userdata" then
            return h
        end
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

local ctrlOwner = setmetatable({}, { __mode = "k" })

local function syncConfigValue(ctrl)
    local v = ctrl and ctrl._configValue
    if not v then return end
    local value = ctrl._configCurrent
    pcall(function()
        if v:IsA("BoolValue") then
            v.Value = not not value
        elseif v:IsA("NumberValue") then
            v.Value = tonumber(value) or 0
        elseif v:IsA("Color3Value") then
            v.Value = value
        elseif v:IsA("StringValue") then
            v.Value = tostring(value or "")
        end
    end)
    ctrl._cfgSynced = true
    -- 自动储存已移除：控件状态只同步到内存 Value，不触发任何落盘。
    -- 配置写盘仅由 Config Manager 的「Save Config」显式调用 SaveConfig 触发。
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
    if isColor3(v) then
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

local function ctrlKeyId(ctrl)
    if ctrl._persistId then return ctrl._persistId end
    local id
    local key = ctrl._configKey
    if type(key) == "string" and key ~= "" then
        id = key
    else
        local tab = ctrl._tab
        local tabName = ""
        if tab then tabName = tostring(tab._name or "") end
        id = tabName .. "/" .. tostring((ctrl._opts and ctrl._opts.Title) or ctrl._kind or "")
    end
    ctrl._persistId = id
    return id
end

local DEFAULT_CONFIG = "Default"
local CONFIG_DIR_NAME = "Configs"

local function sanitizeConfigName(name)
    if name == nil then return nil end
    local raw = tostring(name)
    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if raw == "" then return nil end
    raw = raw:gsub("[\\/:*?\"<>|]", "_")
    if #raw > 40 then raw = raw:sub(1, 40) end
    return raw
end

local function resolveConfigPath(win, name)
    if not (win and win._assetDir) then return nil, nil end
    local n = sanitizeConfigName(name) or win._configName or DEFAULT_CONFIG
    if n == DEFAULT_CONFIG then
        return win._assetDir .. "/config.json", DEFAULT_CONFIG
    end
    local dir = win._configDir or (win._assetDir .. "/" .. CONFIG_DIR_NAME)
    return dir .. "/" .. n .. ".json", n
end

local function configFileExists(path)
    if type(path) ~= "string" or type(isfile) ~= "function" then return false end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function viewportSize()
    local vw, vh
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam and cam.ViewportSize and cam.ViewportSize.X > 0 then
            vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
        end
    end)
    return vw, vh
end

function Library:SaveConfig(name)
    local path, resolved = resolveConfigPath(self, name)
    if path then
        self._configPath = path
        self._configName = resolved
    end
    self._savingConfig = true
    for _, ctrl in pairs(self._config or {}) do
        if ctrl then syncConfigValue(ctrl) end
    end
    if not path then path = self._configPath end
    if path then
        pcall(function()
            local data = {}
            for key, ctrl in pairs(self._config or {}) do
                if ctrl and ctrl._configCurrent ~= nil then
                    data[key] = cfgToJSON(ctrl._configCurrent)
                end
            end
            local keys, shortcuts = {}, {}
            for _, tab in ipairs(self._tabs or {}) do
                for _, c in ipairs(tab._controls or {}) do
                    local id = ctrlKeyId(c)
                    if c._keybind ~= nil then
                        local kn = c._keybind.Name
                        if type(kn) ~= "string" or kn == "" then kn = tostring(c._keybind) end
                        keys[id] = kn
                    end
                    local sc = c._shortcut
                    local frame = sc and sc.frame
                    if frame and frame.Parent then
                        shortcuts[id] = {
                            on = true,
                            x = math.floor((frame.Position.X.Offset or 0) + 0.5),
                            y = math.floor((frame.Position.Y.Offset or 0) + 0.5),
                        }
                    end
                end
            end
            if next(keys) ~= nil then data.__keys = keys end
            if next(shortcuts) ~= nil then data.__shortcuts = shortcuts end
            writefile(path, jsonEncodeValue(data))
            if self._assetDir then
                writefile(self._assetDir .. "/active.json",
                    jsonEncodeValue({ name = self._configName or DEFAULT_CONFIG }))
            end
        end)
    end
    self._savingConfig = false
    return self
end

function Library:_autoSave()
    -- 自动储存已移除：保留空实现仅为兼容旧调用，不再落盘。
    return self
end

function Library:LoadConfig(name)
    if name == nil and self._assetDir then
        local active
        pcall(function()
            local ap = self._assetDir .. "/active.json"
            if configFileExists(ap) then
                local ok, d = pcall(function() return jsonDecodeRaw(readfile(ap)) end)
                if ok and type(d) == "table" and type(d.name) == "string" and d.name ~= "" then
                    active = d.name
                end
            end
        end)
        if active and configFileExists(resolveConfigPath(self, active)) then name = active end
    end
    local path, resolved = resolveConfigPath(self, name)
    if not path then return false end
    if name ~= nil and not configFileExists(path) then return false end
    local jsonData = nil
    if path then
        pcall(function()
            if configFileExists(path) then
                local raw = readfile(path)
                if raw and raw ~= "" then
                    local ok, d = pcall(function() return jsonDecodeRaw(raw) end)
                    if ok and type(d) == "table" then jsonData = d end
                end
            end
        end)
    end
    self._configPath = path
    self._configName = resolved
    self._loadingConfig = true
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
    local savedKeys = jsonData and jsonData.__keys
    if type(savedKeys) == "table" then
        for _, tab in ipairs(self._tabs or {}) do
            for _, c in ipairs(tab._controls or {}) do
                local kbName = savedKeys[ctrlKeyId(c)]
                if type(kbName) == "string" and kbName ~= "" then
                    local kc = Enum.KeyCode[kbName]
                    if kc then
                        c._keybind = kc
                        if c._keyLabel and c._keyLabel.Parent then
                            c._keyLabel.Text = tostring(kc.Name)
                        end
                    end
                end
            end
        end
    end
    local savedSc = jsonData and jsonData.__shortcuts
    if type(savedSc) == "table" then
        for _, tab in ipairs(self._tabs or {}) do
            for _, c in ipairs(tab._controls or {}) do
                local e = savedSc[ctrlKeyId(c)]
                if type(e) == "table" and e.on ~= false then
                    if not c._shortcut and type(createShortcut) == "function" then
                        pcall(createShortcut, self, c)
                    end
                    local sc = c._shortcut
                    local frame = sc and sc.frame
                    if frame and frame.Parent then
                        local fx = tonumber(e.x)
                        local fy = tonumber(e.y)
                        if fx and fy then
                            local fw = frame.Size.X.Offset or 0
                            local fh = frame.Size.Y.Offset or 0
                            local vw, vh = viewportSize()
                            if vw and vh then
                                fx = math.clamp(fx, fw / 2, math.max(fw / 2, vw - fw / 2))
                                fy = math.clamp(fy, fh / 2, math.max(fh / 2, vh - fh / 2))
                            end
                            frame.Position = UDim2.fromOffset(fx, fy)
                        end
                    end
                end
            end
        end
    end
    self._loadingConfig = false
    if type(refreshConflicts) == "function" then pcall(refreshConflicts, self) end
    return true
end

local function listConfigFiles(win)
    local out, seen = {}, {}
    local dir = win._configDir or (win._assetDir and (win._assetDir .. "/" .. CONFIG_DIR_NAME))
    if dir and type(listfiles) == "function" then
        pcall(function()
            if type(isfolder) == "function" and not isfolder(dir) then return end
            local files = listfiles(dir)
            if type(files) ~= "table" then return end
            for _, f in ipairs(files) do
                local base = tostring(f):match("([^/\\]+)%.json$")
                if base and base ~= "" and not seen[base] then
                    seen[base] = true
                    out[#out + 1] = base
                end
            end
        end)
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

function Library:GetConfigName()
    return self._configName or DEFAULT_CONFIG
end

function Library:GetConfigPath()
    return self._configPath
end

function Library:GetConfigs()
    local out, seen = { DEFAULT_CONFIG }, { [DEFAULT_CONFIG] = true }
    for _, n in ipairs(listConfigFiles(self)) do
        if not seen[n] and n ~= DEFAULT_CONFIG then
            seen[n] = true
            out[#out + 1] = n
        end
    end
    return out
end

function Library:ConfigExists(name)
    local path = resolveConfigPath(self, name)
    return configFileExists(path)
end

function Library:SetConfig(name)
    local path, resolved = resolveConfigPath(self, name)
    if not path then return false end
    self._configPath = path
    self._configName = resolved
    return true
end

function Library:DeleteConfig(name)
    local path, resolved = resolveConfigPath(self, name)
    if not path or resolved == DEFAULT_CONFIG then return false end
    local removed = false
    pcall(function()
        if configFileExists(path) then
            delfile(path)
            removed = true
        end
    end)
    if self._configName == resolved then
        self._configName = DEFAULT_CONFIG
        self._configPath = self._assetDir .. "/config.json"
    end
    return removed
end

function Library:RenameConfig(oldName, newName)
    local from, fromName = resolveConfigPath(self, oldName)
    local to, toName = resolveConfigPath(self, newName)
    if not (from and to) then return false end
    if fromName == DEFAULT_CONFIG or toName == DEFAULT_CONFIG then return false end
    if fromName == toName or configFileExists(to) then return false end
    local ok = false
    pcall(function()
        if configFileExists(from) then
            writefile(to, readfile(from))
            delfile(from)
            ok = true
        end
    end)
    if ok and self._configName == fromName then
        self._configName = toName
        self._configPath = to
    end
    return ok
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
    label:SetAttribute("_skipFade", true)
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

local function makeDropdown(parent, opts)
    opts = opts or {}
    local options = opts.Options or {}
    local capW = opts.Width or s(140)
    local capH = opts.Height or s(26)
    local capPos = opts.Position or UDim2.new(1, -capW - s(10), 0.5, -capH / 2)
    local z = opts.ZIndex or (ZBASE + 8)
    local selected = opts.Default or options[1] or ""
    local cb = opts.Callback
    local obj
    local closeMenu, refreshHighlights
    local optionButtons = {}
    local menuOpen = false
    local outsideConn = nil

    local host = parent
    local hostZ = nil
    local capsule = Instance.new("TextButton", parent)
    capsule.Name = "DropdownCapsule"
    capsule.Size = UDim2.fromOffset(capW, capH)
    capsule.Position = capPos
    capsule.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    capsule.BackgroundTransparency = 0.12
    capsule.BorderSizePixel = 0
    capsule.Text = ""
    capsule.AutoButtonColor = false
    capsule.ZIndex = z
    local capCorner = Instance.new("UICorner", capsule)
    capCorner.CornerRadius = UDim.new(0.5, 0)
    local capStroke = Instance.new("UIStroke", capsule)
    capStroke.Color = Color3.fromRGB(150, 150, 160)
    capStroke.Thickness = 1
    capStroke.Transparency = 0.35
    capStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    local capLabel = Instance.new("TextLabel", capsule)
    capLabel.Name = "DdLabel"
    capLabel.Size = UDim2.new(1, -s(28), 1, 0)
    capLabel.Position = UDim2.fromOffset(s(11), 0)
    capLabel.BackgroundTransparency = 1
    capLabel.Font = Style.Font
    capLabel.TextSize = s(12)
    capLabel.TextColor3 = Color3.new(1, 1, 1)
    capLabel.TextXAlignment = Enum.TextXAlignment.Left
    capLabel.TextYAlignment = Enum.TextYAlignment.Center
    capLabel.TextTruncate = Enum.TextTruncate.AtEnd
    capLabel.Text = tostring(selected)
    capLabel.ZIndex = z + 1
    capLabel:SetAttribute("_skipFade", true)
    local arrow = Instance.new("ImageLabel", capsule)
    arrow.Name = "DdArrow"
    arrow.Size = UDim2.fromOffset(s(12), s(12))
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -s(9), 0.5, 0)
    arrow.BackgroundTransparency = 1
    arrow.Active = false
    arrow.ZIndex = z + 1
    arrow:SetAttribute("_skipFade", true)
    applyIcon(arrow, "chevron-down", Style.SubText)

    local optH = s(28)
    local menuH = #options * optH + s(8)
    local menu = Instance.new("Frame", parent)
    menu.Name = "DropdownMenu"
    menu.Size = UDim2.fromOffset(capW, menuH)
    menu.Position = UDim2.new(capPos.X.Scale, capPos.X.Offset,
        capPos.Y.Scale, capPos.Y.Offset + capH + s(4))
    menu.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    menu.BackgroundTransparency = 0.02
    menu.BorderSizePixel = 0
    menu.ClipsDescendants = true
    menu.Visible = false
    menu.ZIndex = z + 10
    local menuCorner = Instance.new("UICorner", menu)
    menuCorner.CornerRadius = UDim.new(0, s(10))
    local menuStroke = Instance.new("UIStroke", menu)
    menuStroke.Color = Color3.fromRGB(150, 150, 160)
    menuStroke.Thickness = 1
    menuStroke.Transparency = 0.45
    menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    local function buildOptions(list)
        for _, o in ipairs(optionButtons) do
            if o.btn and o.btn.Parent then o.btn:Destroy() end
        end
        optionButtons = {}
        local valid = false
        for _, v in ipairs(list) do if v == selected then valid = true break end end
        if not valid then selected = list[1] or "" end
        capLabel.Text = tostring(selected)
        for i, name in ipairs(list) do
            local txt = tostring(name)
            local ob = Instance.new("TextButton", menu)
            ob.Name = "DdOption"
            ob.Size = UDim2.new(1, -s(8), 0, optH)
            ob.Position = UDim2.fromOffset(s(4), s(4) + (i - 1) * optH)
            ob.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
            ob.BackgroundTransparency = 1
            ob.BorderSizePixel = 0
            ob.Text = ""
            ob.AutoButtonColor = false
            ob.ZIndex = z + 11
            local oc = Instance.new("UICorner", ob)
            oc.CornerRadius = UDim.new(0, s(6))
            local tx = Instance.new("TextLabel", ob)
            tx.Name = "DdOptText"
            tx.Size = UDim2.fromScale(1, 1)
            tx.BackgroundTransparency = 1
            tx.Font = Style.Font
            tx.TextSize = s(12)
            tx.TextColor3 = Color3.fromRGB(230, 230, 235)
            tx.TextXAlignment = Enum.TextXAlignment.Center
            tx.TextYAlignment = Enum.TextYAlignment.Center
            tx.Text = txt
            tx.ZIndex = z + 12
            tx:SetAttribute("_skipFade", true)
            ob.MouseButton1Click:Connect(function()
                if txt == selected then return end
                selected = txt
                capLabel.Text = txt
                refreshHighlights()
                closeMenu()
                if cb then pcall(cb, txt) end
                if obj and obj._configValue then obj._configCurrent = txt; syncConfigValue(obj) end
            end)
            optionButtons[i] = { btn = ob, tx = tx, name = txt }
        end
        refreshHighlights()
        if obj then
            obj.Value = selected
            if obj._configValue then obj._configCurrent = selected; syncConfigValue(obj) end
        end
    end

    refreshHighlights = function()
        local vis = 0
        for _, o in ipairs(optionButtons) do
            local isSel = (o.name == selected)
            o.btn.Visible = not isSel
            o.tx.Visible = not isSel
            o.tx.TextColor3 = Color3.fromRGB(230, 230, 235)
            o.btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
            o.btn.BackgroundTransparency = 1
            if not isSel then
                o.btn.Position = UDim2.fromOffset(s(4), s(4) + vis * optH)
                vis = vis + 1
            end
        end
        menu.Size = UDim2.fromOffset(capW, math.max(1, vis) * optH + s(8))
    end

    local function hitTest(o, px, py)
        if not (o and o.Parent) then return false end
        local a, sz = o.AbsolutePosition, o.AbsoluteSize
        if not (a and sz) then return false end
        return px >= a.X - 2 and px <= a.X + sz.X + 2
            and py >= a.Y - 2 and py <= a.Y + sz.Y + 2
    end

    closeMenu = function()
        if not menuOpen then return end
        menuOpen = false
        if host and hostZ ~= nil then host.ZIndex = hostZ; hostZ = nil end
        fadeGroup(menu, 1, function() if not menuOpen then menu.Visible = false end end)
        if outsideConn then pcall(function() outsideConn:Disconnect() end) outsideConn = nil end
    end

    capsule.MouseButton1Click:Connect(function()
        if menuOpen then closeMenu() return end
        menuOpen = true
        -- 菜单展开时把宿主临时提到库内最高层之上，让下拉浮过所有兄弟元素。
        -- 切勿写死 200 之类的低绝对值：本库普遍使用 ZBASE+ 的 110000 级 ZIndex，
        -- 把设置页面板（ZBASE+52）压到 200 会使其沉到遮罩（ZBASE+60）之下、看似消失。
        if host then hostZ = host.ZIndex; host.ZIndex = ZBASE + 100 end
        menu.Visible = true
        setGroupTransparency(menu, 1)
        fadeGroup(menu, 0)
        refreshHighlights()
        outsideConn = UserInputService.InputBegan:Connect(function(input)
            if not menuOpen then return end
            local t = input.UserInputType
            if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
            local px, py = inputPoint(input)
            if not hitTest(capsule, px, py) and not hitTest(menu, px, py) then closeMenu() end
        end)
    end)

    obj = { Value = selected }
    function obj:Set(v)
        selected = (v ~= nil) and tostring(v) or ""
        capLabel.Text = selected
        obj.Value = selected
        refreshHighlights()
        if obj._configValue then obj._configCurrent = selected; syncConfigValue(obj) end
        if cb then pcall(cb, selected) end
    end
    function obj:Get() return selected end
    function obj:GetOptions()
        local list = {}
        for _, v in ipairs(options) do list[#list + 1] = v end
        return list
    end
    function obj:SetOptions(list)
        local clean = {}
        if type(list) == "table" then
            for _, v in ipairs(list) do
                if v ~= nil then clean[#clean + 1] = tostring(v) end
            end
        end
        options = clean
        obj.Options = options
        buildOptions(options)
    end
    function obj:AddOption(name)
        if name == nil then return end
        local txt = tostring(name)
        for _, v in ipairs(options) do if v == txt then return end end
        local list = obj:GetOptions()
        list[#list + 1] = txt
        obj:SetOptions(list)
    end
    function obj:RemoveOption(name)
        local txt = tostring(name or "")
        local list, hit = {}, false
        for _, v in ipairs(options) do
            if v == txt then hit = true else list[#list + 1] = v end
        end
        if not hit then return end
        obj:SetOptions(list)
    end
    obj.SetValue = obj.Set
    obj._closeMenu = closeMenu
    obj.Options = options
    buildOptions(options)
    return obj
end

local function makeRow(parent, y, title, height)
    height = height or ROW_H
    local row = makeGlass(parent, {
        Name = "Row",
        Size = UDim2.new(1, -s(4), 0, height),
        Position = UDim2.new(0, s(2), 0, y),
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
    label:SetAttribute("_skipFade", true)
    return row, label
end

local buildDetail, addDetailRow, openDetail, closeDetail

-- 按可变列/行跨度（_cols/_rows）把 tab 内的控件流水排布；支持 Notice 跨 1~3 格。
-- 返回网格内容底边像素高度，并把每个控件的像素矩形写回 ctrl._x/_y/_w/_h。
local function layoutTab(tab)
    local win = tab._win
    local areaW = (win._controlW or win._sizeX) - PAD_IN * 2
    local n = math.min(3, math.max(1, math.floor((areaW + GAP) / (MIN_BLOCK + GAP))))
    local side = (areaW - H_GAP * (n - 1)) / n
    local x, y, rowH = 0, 0, 0
    for _, ctrl in ipairs(tab._controls) do
        local cols = math.max(1, math.floor(ctrl._cols or 1))
        local rows = math.max(1, math.floor(ctrl._rows or 1))
        local cw = cols * side + (cols - 1) * H_GAP
        local ch = rows * side + (rows - 1) * GAP
        if x + cw > areaW + 0.5 then
            y = y + rowH + GAP
            x = 0
            rowH = 0
        end
        ctrl._x = x + cw / 2
        ctrl._y = y + ch / 2
        ctrl._w = cw
        ctrl._h = ch
        x = x + cw + H_GAP
        if ch > rowH then rowH = ch end
    end
    return y + rowH
end

local function updateCanvas(win)
    local sc = win._scroller
    if not (sc and sc.Parent) then return end
    local need = win._viewH or 0
    local areaW = (win._controlW or win._sizeX) - PAD_IN * 2
    local n = math.min(3, math.max(1, math.floor((areaW + GAP) / (MIN_BLOCK + GAP))))
    local side = (areaW - H_GAP * (n - 1)) / n
    for _, t in ipairs(win._tabs) do
        local bottom = layoutTab(t)
        -- 自定义选项卡：网格下方的自定义层，按子控件底边自动撑高
        local customBottom = 0
        if t._customLayer then
            t._customLayer.Position = UDim2.fromOffset(0, bottom + GAP)
            for _, ch in ipairs(t._customLayer:GetChildren()) do
                if ch:IsA("GuiObject") and ch.Visible then
                    local b = ch.Position.Y.Offset + (ch.Size.Y.Offset or 0)
                    if b > customBottom then customBottom = b end
                end
            end
            t._customLayer.Size = UDim2.fromOffset(areaW, customBottom)
        end
        local total = bottom + (t._customLayer and (GAP + customBottom) or 0)
        local h = PAD_IN * 2 + total + PAD_IN
        if h > need then need = h end
        for _, c in ipairs(t._controls) do
            local h = PAD_IN * 2 + (c._detailBottom or (DETAIL_TOP + 2 * (ROW_H + ROW_GAP))) + PAD_IN
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
local nominal = setmetatable({}, { __mode = "k" })

local function noteNode(node)
    if not node then return end
    local t = nominal[node]
    if not t then t = {}; nominal[node] = t end
    if pcall(function() return node.BackgroundTransparency end) and t.bg == nil then
        t.bg = node.BackgroundTransparency
    end
    if node.Name == "Press" then t.bg = 1 end
    if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
        if t.tt == nil then t.tt = node.TextTransparency end
        if t.ts == nil then t.ts = node.TextStrokeTransparency end
    end
    if node:IsA("ImageLabel") or node:IsA("ImageButton") or node:IsA("VideoFrame") then
        if t.it == nil then t.it = node.ImageTransparency end
    end
end

local noteTree

local function noteStroke(stroke)
    if not stroke then return end
    local t = nominal[stroke]
    if not t then t = {}; nominal[stroke] = t end
    if t.st == nil then t.st = stroke.Transparency end
end

noteTree = function(root)
    if not root then return end
    if root:IsA("GuiObject") then noteNode(root) end
    for _, ch in ipairs(root:GetChildren()) do
        if ch:IsA("UIStroke") then
            noteStroke(ch)
        else
            noteTree(ch)
        end
    end
end

local function setNominal(node, key, val)
    if not (node and val ~= nil) then return end
    local t = nominal[node]
    if not t then t = {}; nominal[node] = t end
    t[key] = val
end

setGroupTransparency = function(container, t, force)
    if not (container and container.Parent) then return end
    t = math.clamp(t or 0, 0, 1)
    local st = groupState[container]
    if not st then st = { gt = 0, base = {} } ; groupState[container] = st end
    local mult = 1 - t
    local base = st.base
    local nodes = { container }
    local function collect(node)
        for _, ch in ipairs(node:GetChildren()) do
            local nm = ch.Name
            if nm ~= "ClickFx" and nm ~= "Ripple" then
                if ch:IsA("GuiObject") then
                    nodes[#nodes + 1] = ch
                    collect(ch)
                else
                    collect(ch)
                end
            end
        end
    end
    collect(container)
    local function track(node, key, cur)
        local b = base[node]
        if not b then b = {}; base[node] = b end
        local nb = nominal[node]
        if nb and nb[key] ~= nil then
            b[key] = nb[key]
        else
            if b[key] == nil then b[key] = cur end
            -- 首次淡出时把「正常显示值」固化进标称表：部分容器会先被
            -- setGroupTransparency(...,1) 整树淡成透明、随后才 noteTree，
            -- 若不固化，noteNode 会把透明态 1 误记成标称背景透明度，
            -- 导致之后淡入时黑色背景（Orb / Shortcut 等）永远恢复不回来。
            if not nb then nb = {}; nominal[node] = nb end
            nb[key] = b[key]
        end
        return b[key]
    end
    for _, node in ipairs(nodes) do
        local skip = false
        pcall(function() skip = (node:GetAttribute("_skipFade") == true) end)
        if force then skip = false end
        if not skip then
            if pcall(function() return node.BackgroundTransparency end) then
                node.BackgroundTransparency = 1 - (1 - track(node, "bg", node.BackgroundTransparency)) * mult
            end
            if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                node.TextTransparency = 1 - (1 - track(node, "tt", node.TextTransparency)) * mult
                node.TextStrokeTransparency = 1 - (1 - track(node, "ts", node.TextStrokeTransparency)) * mult
            end
            if node:IsA("ImageLabel") or node:IsA("ImageButton") or node:IsA("VideoFrame") then
                node.ImageTransparency = 1 - (1 - track(node, "it", node.ImageTransparency)) * mult
            end
        end
        for _, ch in ipairs(node:GetChildren()) do
            local chSkip = false
            pcall(function() chSkip = (ch:GetAttribute("_skipFade") == true) end)
            if force then chSkip = false end
            if ch:IsA("UIStroke") and not chSkip then
                ch.Transparency = 1 - (1 - track(ch, "st", ch.Transparency)) * mult
            end
        end
    end
    st.gt = t
end

tweenGroup = function(container, target, ti, onDone, force)
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
        setGroupTransparency(container, proxy.Value, force)
    end)
    st.tween = tw
    st.conn = conn
    tw.Completed:Connect(function()
        if st.tween ~= tw then return end
        if conn then conn:Disconnect() end
        st.conn = nil
        st.tween = nil
        setGroupTransparency(container, target, force)
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
    end, true)
end

showColorPanel = function(p, show)
    if not (p and p.Parent) then return end
    if show then
        p.Visible = true
        setGroupTransparency(p, 1)
        fadeGroup(p, 0)
    else
        fadeGroup(p, 1, function() if p and p.Parent then p.Visible = false end end)
    end
end

local function relayout(tab)
    layoutTab(tab)
    for _, ctrl in ipairs(tab._controls) do
        if ctrl._block then
            ctrl._block.Size = UDim2.fromOffset(ctrl._w, ctrl._h)
            ctrl._block.Position = UDim2.fromOffset(ctrl._x, ctrl._y)
        end
    end
    updateCanvas(tab._win)
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
    setNominal(ctrl._silver, "bg", bgT)
    if ctrl._icon then tw(ctrl._icon, "ImageColor3", fg) end
    if ctrl._title then tw(ctrl._title, "TextColor3", fg) end
end

local function ensureFxLayer(btn, tint, radius)
    if not (btn and btn.Parent) then return nil end
    local ov = btn:FindFirstChild("ClickFx")
    if ov then return ov end
    local top = btn.ZIndex or 1
    for _, ch in ipairs(btn:GetChildren()) do
        if ch:IsA("GuiObject") and (ch.ZIndex or 1) > top then top = ch.ZIndex end
    end
    ov = Instance.new("Frame")
    ov.Name = "ClickFx"
    ov.Size = UDim2.fromScale(1, 1)
    ov.BackgroundColor3 = tint or Color3.new(1, 1, 1)
    ov.BackgroundTransparency = 1
    ov.BorderSizePixel = 0
    ov.Active = false
    ov.ClipsDescendants = true
    ov.ZIndex = top + 1
    ov:SetAttribute("_skipFade", true)
    local oc = Instance.new("UICorner")
    oc.CornerRadius = radius or UDim.new(0, s(8))
    oc.Parent = ov
    ov.Parent = btn
    return ov
end

local function clickRipple(btn, tint, radius)
    if not (btn and btn.Parent) then return end
    local ov = ensureFxLayer(btn, tint, radius)
    if not (ov and ov.Parent) then return end
    local w, h = btn.AbsoluteSize.X, btn.AbsoluteSize.Y
    if not w or w <= 0 then w = 40 end
    if not h or h <= 0 then h = 24 end
    local d = math.max(w, h) * 2.4
    local r = Instance.new("Frame")
    r.Name = "Ripple"
    r.AnchorPoint = Vector2.new(0.5, 0.5)
    r.Position = UDim2.fromScale(0.5, 0.5)
    r.Size = UDim2.fromOffset(8, 8)
    r.BackgroundColor3 = tint or Color3.new(1, 1, 1)
    r.BackgroundTransparency = 0.62
    r.BorderSizePixel = 0
    r.ZIndex = ov.ZIndex
    r:SetAttribute("_skipFade", true)
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(1, 0)
    rc.Parent = r
    r.Parent = ov
    local tw = TweenService:Create(r, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(d, d),
        BackgroundTransparency = 1,
    })
    tw:Play()
    task.delay(0.5, function()
        if r and r.Parent then r:Destroy() end
    end)
end

local function attachClickFx(btn, opts)
    if not (btn and btn.Parent) then return end
    local marked = false
    pcall(function() marked = btn:GetAttribute("_clickFx") == true end)
    if marked then return end
    pcall(function() btn:SetAttribute("_clickFx", true) end)
    opts = opts or {}
    local tint = opts.tint or Color3.new(1, 1, 1)
    local peak = opts.peak or 0.82
    local radius = opts.radius or UDim.new(0, s(8))
    local ripple = (opts.ripple ~= false)   -- 默认有波纹；ripple=false 时仅保留按压高亮
    local pressFx = (opts.pressFx ~= false) -- 默认有白色按压高亮；false 时完全不做白色按压/波纹反馈
    local ov = ensureFxLayer(btn, tint, radius)

    local sc = btn:FindFirstChildOfClass("UIScale")
    if not sc then
        sc = Instance.new("UIScale")
        sc.Parent = btn
    end
    local baseScale = sc.Scale or 1
    if baseScale <= 0 then baseScale = 1 end
    local downT, upT, scT
    local endConn

    local function dismiss(tw)
        if tw then pcall(function() tw:Cancel() end) end
        return nil
    end
    local function releaseEndConn()
        if endConn then pcall(function() endConn:Disconnect() end) endConn = nil end
    end

    -- 前向声明：保证 pressDown 内 InputEnded 闭包能正确捕获本地的 pressUp
    -- （Luau 不会把“后声明”的 local 捕获为 upvalue，而会回退到 nil 的全局引用）
    local pressUp
    local function pressDown()
        if not pressFx then return end
        downT = dismiss(downT)
        upT = dismiss(upT)
        downT = TweenService:Create(ov, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = peak,
        })
        downT:Play()
        scT = dismiss(scT)
        scT = TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Scale = baseScale * 0.96,
        })
        scT:Play()
        -- 全局兜底：在窗口/元素外松开时也能释放按压反馈，避免按压卡住
        releaseEndConn()
        endConn = UserInputService.InputEnded:Connect(function(i)
            local t = i and i.UserInputType
            local n = t and t.Name or ""
            if n == "MouseButton1" or n == "Touch" then
                pressUp(false)
            end
        end)
    end

    pressUp = function(clicked)
        if not pressFx then return end
        releaseEndConn()
        downT = dismiss(downT)
        upT = dismiss(upT)
        upT = TweenService:Create(ov, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
        })
        upT:Play()
        scT = dismiss(scT)
        scT = TweenService:Create(sc, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = baseScale,
        })
        scT:Play()
        if clicked and ripple then clickRipple(btn, tint, radius) end
    end

    btn.MouseButton1Down:Connect(pressDown)
    btn.MouseButton1Up:Connect(function() pressUp(false) end)
    btn.MouseButton1Click:Connect(function() pressUp(true) end)
    return ov
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
    local sc = win._scroller
    if sc then
        local function walk(node)
            for _, ch in ipairs(node:GetChildren()) do
                if ch:IsA("Frame") and ch.Name == "Press" then
                    pcall(function() ch.BackgroundTransparency = 1 end)
                elseif ch:IsA("UIScale") then
                    pcall(function() ch.Scale = 1 end)
                end
                walk(ch)
            end
        end
        walk(sc)
    end
end

local function syncShortcut(ctrl)
    local sc = ctrl._shortcut
    if not (sc and sc.silver and sc.silver.Parent) then return end
    local on = (ctrl._kind == "Toggle" and ctrl._state)
    sc.silver.BackgroundTransparency = on and Style.SilverTransparency or 1
    setNominal(sc.silver, "bg", on and Style.SilverTransparency or 1)
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

refreshConflicts = function(win)
    local groups = {}
    for _, t in ipairs(win._tabs or {}) do
        for _, c in ipairs(t._controls or {}) do
            local kb = c._keybind
            local state = c._keyLabel and c._keyLabel.Text or ""
            if kb ~= nil and state ~= KEY_PLACEHOLDER and state ~= translateKey(win, KEY_LISTENING) and state ~= KEY_LISTENING then
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
                    cl.Text = translateKey(win, "Conflict with") .. " " .. table.concat(names, ", ", 1, math.min(#names, 2))
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
    local sw = 0
    pcall(function()
        local a = win._gui.AbsoluteSize.X
        if a and a > 0 then sw = a end
    end)
    if sw <= 0 then
        pcall(function() sw = workspace.CurrentCamera.ViewportSize.X end)
    end
    if not sw or sw <= 0 then sw = 1280 end
    return sw
end

createShortcut = function(win, ctrl)
    if ctrl._shortcut then return end
    local name = tostring(ctrl._opts.Title or "")
    local shown = translateKey(win, name)
    local w = s(120)
    pcall(function()
        local sz = TextService:GetTextSize(shown, s(12), Style.Font, Vector2.new(10000, 100))
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
    label.Text = shown
    label.Font = Style.Font
    label.TextSize = s(12)
    label.TextColor3 = Style.Text
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.BackgroundTransparency = 1
    label.Active = false
    label.ZIndex = ZBASE + 2

    local press = Instance.new("Frame", sc)
    press.Name = "Press"
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
    noteTree(sc)
    -- 语言切换时同步 Shortcut 文字与胶囊宽度（标题可被 SetTitle 运行时改动）
    i18nDynamic(win, function()
        if not (label and label.Parent) then return end
        local t = translateKey(win, tostring(ctrl._opts.Title or ""))
        label.Text = t
        if sc and sc.Parent then
            local nw = w
            pcall(function()
                local sz = TextService:GetTextSize(t, s(12), Style.Font, Vector2.new(10000, 100))
                nw = math.max(s(80), sz.X + s(28))
            end)
            sc.Size = UDim2.fromOffset(nw, sc.Size.Y.Offset)
        end
    end)
    syncShortcut(ctrl)
    fadeGroup(sc, 0)
    if ctrl._refreshAdd then pcall(ctrl._refreshAdd) end
    -- 自动储存已移除：此处不再触发 SaveConfig

    local dragging, moved, startX, startY, originX, originY, moveConn, endConn, haveStart
    local scaleTween, pressTween
    local function cancelPressTweens()
        if scaleTween then pcall(function() scaleTween:Cancel() end) scaleTween = nil end
        if pressTween then pcall(function() pressTween:Cancel() end) pressTween = nil end
    end
    local function stopDrag(fire)
        if not dragging then return end
        dragging = false
        setInputSink(win, "shortcut", false)
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
        if fire and not moved then
            fireClick(ctrl)
        end
        -- 自动储存已移除：此处不再触发 SaveConfig
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
        setInputSink(win, "shortcut", true)
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
    local frame = sc.frame
    if frame and frame.Parent then
        fadeGroup(frame, 1, function()
            if frame and frame.Parent then frame:Destroy() end
        end)
    end
    if ctrl._refreshAdd then pcall(ctrl._refreshAdd) end
    -- 自动储存已移除：此处不再触发 SaveConfig
end

startListen = function(win, ctrl, label)
    if win._listening then
        local old = win._listening
        old.label.Text = KEY_PLACEHOLDER
        old.ctrl._keybind = nil
    end
    ctrl._keybind = nil
    label.Text = translateKey(win, KEY_LISTENING)
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
    ctrl._detailY = DETAIL_TOP
    ctrl._detailBottom = DETAIL_TOP

    local title = Instance.new("TextLabel", layer)
    title.Name = "DetailTitle"
    title.Size = UDim2.new(1, -s(40), 0, s(24))
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Font = Style.Font
    title.TextSize = s(15)
    title.TextColor3 = Style.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    local function refreshDetailTitle()
        title.Text = translateKey(win, ctrl._opts.Title or "") .. " - " .. translateKey(win, "Setting")
    end
    i18nDynamic(win, refreshDetailTitle)
    refreshDetailTitle()
    ctrl._refreshDetailTitle = refreshDetailTitle

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

    local function pushRow(title, height)
        height = height or ROW_H
        local y = ctrl._detailY
        local row, label = makeRow(layer, y, title, height)
        ctrl._detailY = y + height + ROW_GAP
        ctrl._detailBottom = y + height
        return row, label
    end

    local krow, klabel2 = pushRow("Board-Key")
    i18nText(win, klabel2, "Board-Key")
    local _, klabel, khit, kconflict = makeBox(krow, s(110), KEY_PLACEHOLDER)
    ctrl._keyLabel = klabel
    ctrl._conflictLabel = kconflict
    khit.MouseButton1Click:Connect(function() startListen(win, ctrl, klabel) end)

    local arow, alabel2 = pushRow("AddShortcut")
    i18nText(win, alabel2, "AddShortcut")
    local abox, alabel, ahit = makeBox(arow, s(110), "Create")
    abox.BackgroundTransparency = 0.3
    local aicon = Instance.new("ImageLabel", abox)
    aicon.Name = "StateIcon"
    aicon.Size = UDim2.fromOffset(s(13), s(13))
    aicon.Position = UDim2.new(0, s(6), 0.5, -s(6.5))
    aicon.BackgroundTransparency = 1
    aicon.Active = false
    aicon.ZIndex = ZBASE + 4
    aicon:SetAttribute("_skipFade", true)
    alabel.Size = UDim2.new(1, -s(12), 1, 0)
    alabel.Position = UDim2.fromOffset(s(6), 0)
    alabel.TextXAlignment = Enum.TextXAlignment.Right
    local aStroke = abox:FindFirstChildOfClass("UIStroke")
    local function refreshAddState()
        local exists = ctrl._shortcut ~= nil
        alabel.Text = translateKey(win, exists and "Delete" or "Create")
        local fg, bg, sc
        if exists then
            fg = Color3.fromRGB(255, 156, 156)
            bg = Color3.fromRGB(82, 38, 42)
            sc = Color3.fromRGB(224, 112, 112)
            aicon.Visible = applyIcon(aicon, "trash-2", fg)
        else
            fg = Color3.fromRGB(146, 236, 180)
            bg = Color3.fromRGB(32, 68, 50)
            sc = Color3.fromRGB(110, 212, 152)
            aicon.Visible = applyIcon(aicon, "plus", fg)
        end
        abox.BackgroundColor3 = bg
        alabel.TextColor3 = fg
        if aStroke then aStroke.Color = sc end
    end
    i18nDynamic(win, refreshAddState)
    ahit.MouseButton1Click:Connect(function()
        if ctrl._shortcut then destroyShortcut(win, ctrl) else createShortcut(win, ctrl) end
        refreshAddState()
    end)
    refreshAddState()
    ctrl._refreshAdd = refreshAddState
    noteTree(layer)
    updateCanvas(win)
end

local function measureTextHeight(text, size, maxW)
    if type(text) ~= "string" or #text == 0 then return size end
    local lineH = size * 1.4
    local w = maxW or 200
    if w < 40 then w = 200 end
    local total = 0
    for line in (text .. "\n"):gmatch("(.-)\n") do
        local h = size
        local ok, sz = pcall(function()
            return TextService:GetTextSize(line, size, Style.Font, Vector2.new(w, 100000))
        end)
        if ok and sz and sz.Y and sz.Y > 0 then h = sz.Y end
        local lines = math.max(1, math.floor(h / (size * 1.2) + 0.5))
        total = total + lines
    end
    if total < 1 then total = 1 end
    return total * lineH
end

addDetailRow = function(win, ctrl, kind, opts)
    opts = opts or {}
    local layer = ctrl._detailLayer
    local y = ctrl._detailY
    ctrl._detailY = y + ROW_H + ROW_GAP
    ctrl._detailBottom = y + ROW_H
    updateCanvas(win)
    if kind == "Paragraph" then
        -- 段落控件：标题 + 说明 + 可选图标，高度随文字变化
        local paraW = (win._controlW or win._sizeX) - PAD_IN * 2 - s(4)
        local title = opts.Title or ""
        local info = opts.Info or ""
        local icon = opts.Icon
        local iconColor = opts.IconColor or Style.SubText
        local backColor = opts.BackColor or Color3.fromRGB(34, 34, 42)

        local pIconSize = s(18)
        local pIconGap = s(8)
        local pTitleSize = s(14)
        local pTitlePad = s(2)
        local pInfoSize = s(12)
        local pInfoColor = Color3.fromRGB(190, 195, 200)
        local pTextGap = s(2)
        local pTitleDrop = s(8)
        local pBackPad = s(8)
        local pCorner = UDim.new(0, s(8))
        local pBorder = 1
        local pDarken = 0.1

        local hasIco = (icon ~= nil and icon ~= "")
        local frame = Instance.new("Frame", layer)
        frame.Name = "SubParagraph"
        frame.BackgroundColor3 = backColor
        frame.BackgroundTransparency = 0.25
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = false
        frame.ZIndex = ZBASE + 5
        frame:SetAttribute("_skipFade", true)
        local fc = Instance.new("UICorner", frame)
        fc.CornerRadius = pCorner
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = darkenColor(backColor, pDarken)
        stroke.Thickness = pBorder
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        local pad = Instance.new("UIPadding", frame)
        pad.PaddingLeft = UDim.new(0, pBackPad)
        pad.PaddingRight = UDim.new(0, pBackPad)
        local hl = Instance.new("UIListLayout", frame)
        hl.FillDirection = Enum.FillDirection.Horizontal
        hl.HorizontalAlignment = Enum.HorizontalAlignment.Left
        hl.VerticalAlignment = Enum.VerticalAlignment.Center
        hl.SortOrder = Enum.SortOrder.LayoutOrder
        hl.Padding = UDim.new(0, pIconGap)

        local function infoAvailW()
            local w = paraW - pBackPad * 2
            if hasIco then w = w - (pIconSize + pIconGap) end
            return math.max(40, w)
        end
        local function computeH()
            local titleH = pTitleSize + pTitlePad
            local infoH = measureTextHeight(info, pInfoSize, infoAvailW())
            local h = math.ceil(pTitleDrop + titleH + pTextGap + infoH + s(8))
            if h < s(48) then h = s(48) end
            return h
        end

        local icLbl = nil
        if hasIco then
            icLbl = Instance.new("ImageLabel", frame)
            icLbl.Name = "ParaIcon"
            icLbl.Size = UDim2.fromOffset(pIconSize, pIconSize)
            icLbl.BackgroundTransparency = 1
            icLbl.ImageColor3 = iconColor
            icLbl.ScaleType = Enum.ScaleType.Fit
            icLbl.LayoutOrder = 1
            icLbl.ZIndex = ZBASE + 6
            icLbl:SetAttribute("_skipFade", true)
            applyIcon(icLbl, icon, iconColor)
        end

        local txt = Instance.new("Frame", frame)
        txt.Name = "ParaText"
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.new(1, hasIco and -(pIconSize + pIconGap) or 0, 1, 0)
        txt.LayoutOrder = 2
        txt.ZIndex = ZBASE + 6
        txt:SetAttribute("_skipFade", true)
        local vl = Instance.new("UIListLayout", txt)
        vl.FillDirection = Enum.FillDirection.Vertical
        vl.HorizontalAlignment = Enum.HorizontalAlignment.Left
        vl.VerticalAlignment = Enum.VerticalAlignment.Top
        vl.SortOrder = Enum.SortOrder.LayoutOrder
        vl.Padding = UDim.new(0, pTextGap)
        local txtPad = Instance.new("UIPadding", txt)
        txtPad.PaddingTop = UDim.new(0, pTitleDrop)
        local titleLbl = Instance.new("TextLabel", txt)
        titleLbl.Name = "ParaTitle"
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, 0, 0, pTitleSize + pTitlePad)
        titleLbl.Text = title
        titleLbl.TextColor3 = Style.Text
        titleLbl.TextSize = pTitleSize
        titleLbl.Font = Style.Font
        titleLbl.RichText = true
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.TextYAlignment = Enum.TextYAlignment.Center
        titleLbl.LayoutOrder = 1
        titleLbl.ZIndex = ZBASE + 7
        titleLbl:SetAttribute("_skipFade", true)
        local infoLbl = Instance.new("TextLabel", txt)
        infoLbl.Name = "ParaInfo"
        infoLbl.BackgroundTransparency = 1
        infoLbl.Size = UDim2.new(1, 0, 0, measureTextHeight(info, pInfoSize, infoAvailW()))
        infoLbl.Text = info
        infoLbl.TextColor3 = pInfoColor
        infoLbl.TextSize = pInfoSize
        infoLbl.Font = Style.Font
        infoLbl.RichText = true
        infoLbl.TextWrapped = true
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.TextYAlignment = Enum.TextYAlignment.Center
        infoLbl.LayoutOrder = 2
        infoLbl.ZIndex = ZBASE + 7
        infoLbl:SetAttribute("_skipFade", true)

        local height = computeH()
        frame.Size = UDim2.new(1, -s(4), 0, height)
        frame.Position = UDim2.new(0, s(2), 0, y)
        ctrl._detailY = y + height + ROW_GAP
        ctrl._detailBottom = y + height
        noteTree(frame)
        updateCanvas(win)

        local obj = {}
        function obj:SetTitle(v)
            title = v and tostring(v) or ""
            titleLbl.Text = title
        end
        function obj:GetTitle() return title end
        function obj:SetInfo(v)
            info = v and tostring(v) or ""
            infoLbl.Text = info
            local ih = measureTextHeight(info, pInfoSize, infoAvailW())
            infoLbl.Size = UDim2.new(1, 0, 0, ih)
            local newH = computeH()
            frame.Size = UDim2.new(1, -s(4), 0, newH)
            ctrl._detailY = y + newH + ROW_GAP
            ctrl._detailBottom = y + newH
            updateCanvas(win)
        end
        function obj:GetInfo() return info end
        function obj:SetIcon(v)
            local want = (type(v) == "string" and v ~= "") and v or nil
            hasIco = (want ~= nil)
            if want then
                if not icLbl or not icLbl.Parent then
                    icLbl = Instance.new("ImageLabel", frame)
                    icLbl.Name = "ParaIcon"
                    icLbl.Size = UDim2.fromOffset(pIconSize, pIconSize)
                    icLbl.BackgroundTransparency = 1
                    icLbl.ImageColor3 = iconColor
                    icLbl.ScaleType = Enum.ScaleType.Fit
                    icLbl.LayoutOrder = 1
                    icLbl.ZIndex = ZBASE + 6
                    icLbl:SetAttribute("_skipFade", true)
                end
                applyIcon(icLbl, want, iconColor)
                icLbl.Visible = true
            elseif icLbl and icLbl.Parent then
                icLbl.Visible = false
            end
            txt.Size = UDim2.new(1, hasIco and -(pIconSize + pIconGap) or 0, 1, 0)
            local newH = computeH()
            frame.Size = UDim2.new(1, -s(4), 0, newH)
            ctrl._detailY = y + newH + ROW_GAP
            ctrl._detailBottom = y + newH
            updateCanvas(win)
        end
        function obj:SetIconColor(v)
            if typeof(v) == "Color3" then
                iconColor = v
                if icLbl and icLbl.Parent then icLbl.ImageColor3 = v end
            end
        end
        function obj:SetBackColor(v)
            if typeof(v) == "Color3" then
                backColor = v
                frame.BackgroundColor3 = v
                stroke.Color = darkenColor(v, pDarken)
            end
        end
        return obj
    end

    local row, rowLabel = makeRow(layer, y, opts.Title or kind)
    i18nText(win, rowLabel, opts.Title or kind)

    -- 通用标题 API：所有子选项都能在运行时改 Title；同步 rowLabel 文本与 i18n key，
    -- 避免语言切换时 applyLang 用旧 key 把标题覆盖回去。
    opts.Title = opts.Title or kind
    local function decorate(obj)
        function obj:SetTitle(t)
            t = tostring(t or "")
            opts.Title = t
            retargetI18n(win, rowLabel, t)
            rowLabel.Text = translateKey(win, t)
            return obj
        end
        function obj:GetTitle() return tostring(opts.Title or "") end
        return obj
    end

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
            if obj then
                obj.Value = value
                if obj._configValue then obj._configCurrent = value; syncConfigValue(obj) end
            end
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
            obj.Value = value
            refresh(false)
            if opts.Callback then pcall(opts.Callback, value) end
            if obj._configValue then obj._configCurrent = value; syncConfigValue(obj) end
        end
        obj.SetValue = obj.Set
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "Slider"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "Slider")
            obj._configCurrent = def
            syncConfigValue(obj)
        end
        return decorate(obj)
    elseif kind == "Toggle" then
        local box, label, hit = makeBox(row, s(52), "OFF")
        local silver = Instance.new("Frame", box)
        silver.Size = UDim2.fromScale(1, 1)
        silver.BackgroundColor3 = Color3.new(1, 1, 1)
        silver.BackgroundTransparency = 1
        silver.BorderSizePixel = 0
        silver.Active = false
        silver:SetAttribute("_skipFade", true)
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
            label.Text = translateKey(win, st and "ON" or "OFF")
        end
        i18nDynamic(win, refresh)
        hit.MouseButton1Click:Connect(function()
            clickRipple(hit, Color3.new(1, 1, 1), UDim.new(0, s(9)))
            st = not st
            refresh()
            if opts.Callback then pcall(opts.Callback, st) end
            if obj and obj._configValue then obj._configCurrent = st; syncConfigValue(obj) end
        end)
        refresh()
        local obj = { Value = st }
        function obj:Set(v)
            st = not not v
            obj.Value = st
            refresh()
            if opts.Callback then pcall(opts.Callback, st) end
            if obj._configValue then obj._configCurrent = st; syncConfigValue(obj) end
        end
        obj.SetValue = obj.Set
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "Toggle"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "Toggle")
            obj._configCurrent = st
            syncConfigValue(obj)
        end
        return decorate(obj)
    elseif kind == "Button" then
        local box, blabel, hit = makeBox(row, s(90), opts.Text or "Run")
        i18nText(win, blabel, opts.Text or "Run")
        local press = Instance.new("Frame", box)
        press.Name = "Press"
        press.Size = UDim2.fromScale(1, 1)
        press.BackgroundColor3 = Color3.new(0, 0, 0)
        press.BackgroundTransparency = 1
        press.BorderSizePixel = 0
        press.Active = false
        press:SetAttribute("_skipFade", true)
        -- 按压黑色蒙版需跟随方块的圆角，否则直角会溢出圆角显得突兀
        local pressCorner = Instance.new("UICorner", press)
        pressCorner.CornerRadius = UDim.new(0, s(7))
        hit.MouseButton1Down:Connect(function()
            TweenService:Create(press, TweenInfo.new(0.1), { BackgroundTransparency = 0.25 }):Play()
        end)
        hit.MouseButton1Up:Connect(function()
            TweenService:Create(press, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
        end)
        hit.MouseButton1Click:Connect(function()
            clickRipple(hit, Color3.new(1, 1, 1), UDim.new(0, s(8)))
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
        return decorate(obj)
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
        if isColor3(opts.Default) then def = opts.Default end
        local h, sat, val = colorToHSV(def)

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
        sv.BackgroundColor3 = hsvToColor(h, 1, 1)
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
            local c = hsvToColor(h, sat, val)
            local hex = toHex(c)
            swatch.BackgroundColor3 = c
            prev.BackgroundColor3 = c
            label.Text = hex
            hexLabel.Text = hex
            sv.BackgroundColor3 = hsvToColor(h, 1, 1)
            cursor.Position = UDim2.new(sat, -s(5), 1 - val, -s(5))
            hcur.Position = UDim2.new(h, -s(2), 0.5, -s(8))
            if fire and opts.Callback then pcall(opts.Callback, c) end
            if obj then
                obj.Value = c
                if obj._configValue then obj._configCurrent = c; syncConfigValue(obj) end
            end
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
                if p ~= panel then showColorPanel(p, false) end
            end
            if panel.Visible then showColorPanel(panel, false) else showColorPanel(panel, true) end
        end)

        refresh(false)
        obj = { Value = def }
        function obj:Set(c)
            if isColor3(c) then
                h, sat, val = colorToHSV(c)
                obj.Value = c
                refresh(false)
                if obj._configValue then obj._configCurrent = c; syncConfigValue(obj) end
            end
        end
        obj.SetValue = obj.Set
        function obj:Get() return hsvToColor(h, sat, val) end
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "ColorPicker"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "ColorPicker")
            obj._configCurrent = def
            syncConfigValue(obj)
        end
        return decorate(obj)
    elseif kind == "Dropdown" then
        local options = opts.Options or {}
        local def = opts.Default or options[1] or ""
        local obj
        obj = makeDropdown(row, {
            Width = s(150),
            Height = s(24),
            Position = UDim2.new(1, -s(150) - s(10), 0.5, -s(12)),
            Options = options,
            Default = def,
            ZIndex = ZBASE + 8,
            Callback = function(v)
                if obj then obj.Value = v end
                if opts.Callback then pcall(opts.Callback, v) end
            end,
        })
        if opts.ConfigKey and opts.ConfigKey ~= "" then
            obj._configKey = opts.ConfigKey
            obj._configKind = "Dropdown"
            win._config = win._config or {}
            win._config[opts.ConfigKey] = obj
            obj._configValue = makeConfigValue(win, opts.ConfigKey, "Dropdown")
            obj._configCurrent = def
            syncConfigValue(obj)
        end
        return decorate(obj)
    end
    return {}
end

openDetail = function(win, ctrl)
    if win._detail then return end
    releaseAllPress(win)
    for _, p in ipairs(win._colorPanels or {}) do showColorPanel(p, false) end
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
    -- 进入子选项页面不隐藏任何 Shortcut（包括当前控件自己的），快捷入口始终可见。
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
    -- 进入时未隐藏任何 Shortcut，退出时也无需恢复
    win._detailContainer = nil
end

local function bindPress(ctrl)
    local block = ctrl._block
    local win = ctrl._tab._win
    ctrl._pressed = false
    ctrl._holdGen = 0
    local endConn
    local function releaseConn()
        if endConn then pcall(function() endConn:Disconnect() end) endConn = nil end
    end
    local function doClick()
        if not ctrl._pressed then return end
        ctrl._pressed = false
        ctrl._holdGen = ctrl._holdGen + 1
        releaseConn()
        if ctrl._held then ctrl._held = false return end
        setPressed(ctrl, false)
        fireClick(ctrl)
    end
    local function cancelPress()
        if not ctrl._pressed then return end
        ctrl._pressed = false
        ctrl._holdGen = ctrl._holdGen + 1
        releaseConn()
        ctrl._held = false
        setPressed(ctrl, false)
    end
    block.MouseButton1Down:Connect(function()
        ctrl._pressed = true
        ctrl._held = false
        setPressed(ctrl, true)
        ctrl._holdGen = ctrl._holdGen + 1
        local gen = ctrl._holdGen
        releaseConn()
        -- 全局兜底：在窗口/元素外松开时也能释放按压反馈，避免按压卡住
        endConn = UserInputService.InputEnded:Connect(function(i)
            local t = i and i.UserInputType
            local n = t and t.Name or ""
            if n == "MouseButton1" or n == "Touch" then
                if ctrl._holdGen == gen and ctrl._pressed then
                    task.delay(0, function()
                        if ctrl._holdGen == gen and ctrl._pressed then cancelPress() end
                    end)
                end
            end
        end)
        task.delay(HOLD_TIME, function()
            if ctrl._holdGen == gen and ctrl._pressed and ctrl._block.Parent then
                ctrl._held = true
                setPressed(ctrl, false)
                openDetail(win, ctrl)
            end
        end)
    end)
    block.MouseButton1Up:Connect(doClick)
    block.MouseLeave:Connect(cancelPress)
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
    local ctrl = { _tab = tab, _kind = kind, _block = block, _opts = opts, _state = (kind == "Toggle") and (opts.Default == true) or false }
    local cwin = tab._win
    ctrlOwner[ctrl] = cwin

    function ctrl:Set(v)
        if kind == "Toggle" then
            ctrl._state = not not v
            refreshToggle(ctrl, false)
            if opts.Callback then pcall(opts.Callback, ctrl._state) end
        else
            if opts.Callback then pcall(opts.Callback) end
        end
        if ctrl._configValue then
            if kind == "Toggle" then
                ctrl._configCurrent = (ctrl._state == true)
            else
                ctrl._configCurrent = opts.Title or ""
            end
            syncConfigValue(ctrl)
        end
        syncShortcut(ctrl)
    end
    ctrl.SetValue = ctrl.Set

    if opts.ConfigKey and opts.ConfigKey ~= "" then
        ctrl._configKey = opts.ConfigKey
        ctrl._configKind = kind
        cwin._config = cwin._config or {}
        cwin._config[opts.ConfigKey] = ctrl
        ctrl._configValue = makeConfigValue(cwin, opts.ConfigKey, kind)
        if kind == "Toggle" then
            ctrl._configCurrent = (ctrl._state == true)
        else
            ctrl._configCurrent = opts.Title or ""
        end
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
        i18nText(cwin, tx, opts.Title or "")
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
        i18nText(cwin, tx, opts.Title or "")
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

    local function own(obj)
        if type(obj) == "table" then ctrlOwner[obj] = tab._win end
        return obj
    end
    function ctrl:AddSlider(o) return own(addDetailRow(tab._win, ctrl, "Slider", o)) end
    function ctrl:AddToggle(o) return own(addDetailRow(tab._win, ctrl, "Toggle", o)) end
    function ctrl:AddButton(o) return own(addDetailRow(tab._win, ctrl, "Button", o)) end
    function ctrl:AddColorPicker(o) return own(addDetailRow(tab._win, ctrl, "ColorPicker", o)) end
    function ctrl:AddDropdown(o) return own(addDetailRow(tab._win, ctrl, "Dropdown", o)) end
    function ctrl:AddParagraph(o) return own(addDetailRow(tab._win, ctrl, "Paragraph", o)) end

    -- 运行时改变主控件 Title：同步方块标题、i18n key、详情页标题与 Shortcut 名称。
    function ctrl:SetTitle(newTitle)
        newTitle = tostring(newTitle or "")
        opts.Title = newTitle
        if ctrl._title and ctrl._title.Parent then
            retargetI18n(cwin, ctrl._title, newTitle)
            ctrl._title.Text = translateKey(cwin, newTitle)
        end
        if ctrl._refreshDetailTitle then pcall(ctrl._refreshDetailTitle) end
        local sc = ctrl._shortcut
        if sc and sc.label then
            local shown = translateKey(cwin, newTitle)
            sc.label.Text = shown
            pcall(function()
                local sz = TextService:GetTextSize(shown, s(12), Style.Font, Vector2.new(10000, 100))
                sc.frame.Size = UDim2.fromOffset(math.max(s(80), sz.X + s(28)), sc.frame.Size.Y.Offset)
            end)
        end
        return ctrl
    end
    function ctrl:GetTitle() return tostring(opts.Title or "") end

    table.insert(tab._controls, ctrl)
    noteTree(block)
    relayout(tab)
    return ctrl
end

--[[
    Notice：展示型控件。外观与主控件一致（玻璃质感 + 描边），但不可点击、不进详情页。
    左上角大标题 + 下方正文。可指定所占格子数（横向 1~3，竖向不限行数）与摆放朝向。
    opts:
      Title        string   左上角大标题
      Text         string   正文（自动换行）
      Icon         string   标题前的图标（可选）
      Span         number   横向=所占列数(1~3)；竖向=所占行数(>=1，不限制)
      Orientation  "Horizontal"|"Vertical"  默认 Horizontal
      TitleColor / TextColor / IconColor / BackColor  Color3（可选）
    方法：SetTitle / SetText / SetIcon / SetColors
]]
-- 前向声明：makeBold 定义在本函数之后，Luau 不会把后声明的 local 捕获为 upvalue，故先声明
local makeBold
local function addNotice(tab, opts)
    opts = opts or {}
    local block = makeGlass(tab._container, {
        Name = "Notice",
        Size = UDim2.fromOffset(100, 100),
        Position = UDim2.fromOffset(50, 50),
        Transparency = 0.55,
        Radius = UDim.new(0, s(16)),
        Highlight = 0.86,
        Plain = true,
        NoStroke = true,
    })
    block.AnchorPoint = Vector2.new(0.5, 0.5)
    local ctrl = { _tab = tab, _kind = "Notice", _block = block, _opts = opts }
    ctrlOwner[ctrl] = tab._win

    -- 朝向 + 跨度 → 网格占位
    local orient = (opts.Orientation == "Vertical") and "Vertical" or "Horizontal"
    local span = math.floor(tonumber(opts.Span) or 1)
    if orient == "Horizontal" then
        ctrl._cols = math.clamp(span, 1, 3)   -- 横向限制：最多 3 格（一行）
        ctrl._rows = 1
    else
        ctrl._cols = 1
        ctrl._rows = math.max(1, span)         -- 竖向不限制行数
    end

    -- 与主控件一致的描边
    local border = Instance.new("Frame", block)
    border.Name = "Border"
    border.Size = UDim2.new(1, -2, 1, -2)
    border.Position = UDim2.new(0, 1, 0, 1)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 0
    local borderCorner = Instance.new("UICorner", border)
    borderCorner.CornerRadius = UDim.new(0, s(15))
    local borderStroke = Instance.new("UIStroke", border)
    borderStroke.Color = Style.BlockStroke
    borderStroke.Transparency = Style.BlockStrokeTransparency
    borderStroke.Thickness = Style.BlockStrokeThickness
    borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    local pad = s(12)
    local titleH = s(20)

    local iconLbl
    if opts.Icon then
        iconLbl = Instance.new("ImageLabel", block)
        iconLbl.Name = "NoticeIcon"
        iconLbl.Size = UDim2.fromOffset(s(20), s(20))
        iconLbl.Position = UDim2.fromOffset(pad, pad + s(1))
        iconLbl.BackgroundTransparency = 1
        iconLbl.ImageColor3 = opts.IconColor or Style.SubText
        iconLbl.Active = false
        iconLbl.ZIndex = ZBASE + 2
        applyIcon(iconLbl, opts.Icon, opts.IconColor or Style.SubText)
        ctrl._icon = iconLbl
    end

    local title = Instance.new("TextLabel", block)
    title.Name = "NoticeTitle"
    title.BackgroundTransparency = 1
    title.Font = Style.Font
    title.Text = tostring(opts.Title or "")
    title.TextSize = s(16)
    title.TextColor3 = opts.TitleColor or Style.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Top
    title.TextWrapped = false
    title.RichText = false
    title.Active = false
    title.ZIndex = ZBASE + 2
    makeBold(title)
    local iconShift = (opts.Icon and s(26) or 0)
    title.Size = UDim2.new(1, -(pad * 2 + iconShift), 0, titleH)
    title.Position = UDim2.fromOffset(pad + iconShift, pad)
    ctrl._title = title

    local body = Instance.new("TextLabel", block)
    body.Name = "NoticeText"
    body.BackgroundTransparency = 1
    body.Font = Style.Font
    body.Text = tostring(opts.Text or "")
    body.TextSize = s(13)
    body.TextColor3 = opts.TextColor or Style.SubText
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.RichText = false
    body.Active = false
    body.ZIndex = ZBASE + 2
    body.Size = UDim2.new(1, -(pad * 2 + iconShift), 1, -(pad * 2 + titleH + s(8)))
    body.Position = UDim2.fromOffset(pad + iconShift, pad + titleH + s(8))
    ctrl._text = body

    if opts.BackColor then
        block.BackgroundColor3 = opts.BackColor
        local bg = block:FindFirstChildOfClass("UIGradient")
        if bg then bg:Destroy() end
    end

    function ctrl:SetTitle(t)
        if self._title then self._title.Text = tostring(t or "") end
    end
    function ctrl:SetText(t)
        if self._text then self._text.Text = tostring(t or "") end
    end
    function ctrl:SetIcon(ic, color)
        color = color or Style.SubText
        if self._icon then
            applyIcon(self._icon, ic, color)
            self._icon.ImageColor3 = color
        else
            local il = Instance.new("ImageLabel", block)
            il.Name = "NoticeIcon"
            il.Size = UDim2.fromOffset(s(20), s(20))
            il.Position = UDim2.fromOffset(pad, pad + s(1))
            il.BackgroundTransparency = 1
            il.ImageColor3 = color
            il.Active = false
            il.ZIndex = ZBASE + 2
            applyIcon(il, ic, color)
            self._icon = il
        end
    end
    function ctrl:SetColors(c)
        c = c or {}
        if c.TitleColor and self._title then self._title.TextColor3 = c.TitleColor end
        if c.TextColor and self._text then self._text.TextColor3 = c.TextColor end
        if c.IconColor and self._icon then self._icon.ImageColor3 = c.IconColor end
        if c.BackColor then
            block.BackgroundColor3 = c.BackColor
            local bg = block:FindFirstChildOfClass("UIGradient")
            if bg then bg:Destroy() end
        end
    end

    table.insert(tab._controls, ctrl)
    noteTree(block)
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
        setNominal(sel, "bg", active and Cfg.TabSelFillTransparency or 1)
        setNominal(t._selStroke, "st", active and 0 or 1)
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

makeBold = function(label)
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
    -- 通知文案纳入 i18n：固定文案按翻译表转换；动态拼接文案可由调用方先用
    -- Win:Translate() 处理固定部分，此处再转换是幂等的（已翻译文本原样返回）。
    local n = {}
    for k, v in pairs(opts) do n[k] = v end
    n.Title = translateKey(win, tostring(opts.Title or ""))
    n.Info = translateKey(win, tostring(opts.Info or ""))
    opts = n
    if win._panelAnimating then
        table.insert(win._notifyQueue, opts)
        return
    end
    if win._panelState == "closed" then pushCapsule(win, opts) else pushToast(win, opts) end
end

local function cancelAnim(win)
    for _, key in ipairs({ "_mainTween", "_mainScaleTween", "_mainFadeTween", "_cornerTween", "_orbTween", "_fadeTween",
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
        local fadeOutTi = TweenInfo.new(COLLAPSE_T * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        for _, ch in ipairs(main:GetChildren()) do
            if ch:IsA("GuiObject") and ch.Visible then
                saved[ch] = true
                tweenGroup(ch, 1, fadeOutTi, nil, true)
            end
        end
        win._collapseHidden = saved
        task.delay(COLLAPSE_T + 0.02, function()
            if not win._collapsed then return end
            for ch in pairs(saved) do
                if ch and ch.Parent then ch.Visible = false end
            end
        end)
    else
        local saved = win._collapseHidden
        if saved then
            local fadeInTi = TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            for ch in pairs(saved) do
                if ch and ch.Parent then
                    ch.Visible = true
                    setGroupTransparency(ch, 1, true)
                    tweenGroup(ch, 0, fadeInTi, nil, true)
                end
            end
            win._collapseHidden = nil
            task.delay(0.3, function()
                if win._collapsed then return end
                if win._activeTab and win._activeTab > 0 and type(selectTab) == "function" then
                    pcall(selectTab, win, win._activeTab)
                end
            end)
        end
    end
end

local function collapse(win)
    if win._collapsed then return end
    if win._closeSettings then pcall(win._closeSettings) end
    if win._closeConfig then pcall(win._closeConfig) end
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

    local ti = TweenInfo.new(COLLAPSE_T, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    win._mainTween = TweenService:Create(main, ti, {
        Size = UDim2.fromOffset(ORB, ORB),
        Position = UDim2.fromOffset(endX, endY),
    })
    win._mainTween:Play()
    if win._mainScale then
        win._mainScaleTween = TweenService:Create(win._mainScale, ti, { Scale = 1 })
        win._mainScaleTween:Play()
    end
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
    local main = win._main
    local baseW = (win._mainSizeBeforeCollapse and win._mainSizeBeforeCollapse.X.Offset) or win._sizeX
    local baseH = (win._mainSizeBeforeCollapse and win._mainSizeBeforeCollapse.Y.Offset) or win._sizeY
    local anchorX = win._orbBaseX - TITLE_ICON_DX
    local anchorY = win._orbBaseY - TITLE_ICON_DY
    local vw, vh = viewport()
    local visW = baseW * (win._uiScale or 1)
    local visH = baseH * (win._uiScale or 1)
    local goalX = math.clamp(anchorX, 0, math.max(0, vw - visW))
    local goalY = math.clamp(anchorY, 0, math.max(0, vh - visH))
    main.Size = UDim2.fromOffset(ORB, ORB)
    main.Position = UDim2.fromOffset(anchorX, anchorY)
    if win._mainScale then win._mainScale.Scale = 1 end
    main.Visible = true
    win._orb.Visible = false
    setMainContentVisible(win, true)
    local ti = TweenInfo.new(COLLAPSE_T, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    win._mainTween = TweenService:Create(main, ti, {
        Size = UDim2.fromOffset(baseW, baseH),
        Position = UDim2.fromOffset(goalX, goalY),
    })
    win._mainTween:Play()
    if win._mainScale then
        win._mainScaleTween = TweenService:Create(win._mainScale, ti, { Scale = win._uiScale or 1 })
        win._mainScaleTween:Play()
    end
    if win._mainCorner then
        win._cornerTween = TweenService:Create(win._mainCorner, ti,
            { CornerRadius = UDim.new(0, s(24)) })
        win._cornerTween:Play()
    end
    win._mainPosBeforeCollapse = UDim2.fromOffset(goalX, goalY)
    win._mainSizeBeforeCollapse = UDim2.fromOffset(baseW, baseH)
    task.delay(COLLAPSE_T + 0.02, function()
        if win._panelAnimGen ~= gen then return end
        win._panelAnimating = false
        win._panelState = "open"
        pcall(function() syncOrbBase(win) end)
        flushNotifyQueue(win)
    end)
end

function Library:OnLanguageChanged(fn)
    if type(fn) ~= "function" then return self end
    self._languageListeners = self._languageListeners or {}
    table.insert(self._languageListeners, fn)
    return self
end

function Library:SetLanguage(v)
    self._language = tostring(v or "English")
    for _, fn in ipairs(self._languageListeners or {}) do pcall(fn, self._language) end
    return self
end

function Library:GetLanguage()
    return self._language or "English"
end

-- 把任意文本按当前语言翻译（自定义 / 动态拼接文案用）。
-- 未登记的 key 原样返回，因此对已翻译文本再次调用是幂等的。
function Library:Translate(key)
    return translateKey(self, key)
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
    local ConfigDir = AssetDir .. "/" .. CONFIG_DIR_NAME
    local ConfigName = sanitizeConfigName(opts.ConfigName) or DEFAULT_CONFIG
    local ConfigPath = (ConfigName == DEFAULT_CONFIG) and (AssetDir .. "/config.json")
        or (ConfigDir .. "/" .. ConfigName .. ".json")
    pcall(function()
        makefolder(RootFolder)
        makefolder(AssetDir)
        makefolder(ConfigDir)
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

    -- 输入盾：全屏 Active 透明层。拖动窗口 / 悬浮球 / Shortcut 或设置页打开时显示，
    -- 吃掉落在空白区域的触摸，避免穿透到 3D 相机导致视角移动。
    -- ZIndex 低于 Main 及所有交互层，故不遮挡面板按钮 / 滑块。
    local inputShield = Instance.new("Frame", gui)
    inputShield.Name = "InputShield"
    inputShield.Size = UDim2.fromScale(1, 1)
    inputShield.Position = UDim2.fromOffset(0, 0)
    inputShield.BackgroundTransparency = 1
    inputShield.BorderSizePixel = 0
    inputShield.Active = true
    inputShield.Visible = false
    inputShield.ZIndex = ZBASE - 1

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
    local bgUrl, bgVideo, bgDirect
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
            local direct = bgUrl:match("^rbxassetid://") or bgUrl:match("^rbxasset://") or bgUrl:match("^rbxthumb://")
            if not direct then
                direct = bgUrl:match("^https?://www%.roblox%.com/asset") or bgUrl:match("^https?://assetdelivery")
                if not direct then
                    direct = bgUrl:match("^https?://www%.roblox%.com/thumbnail")
                end
            end
            background.Image = direct and bgUrl or ""
            bgDirect = direct and bgUrl or nil
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
    -- 标题图标上移 2px，与两行标题视觉重心对齐
    titleIcon.Position = UDim2.new(0, HEADER_PAD, 0.5, -iconSize / 2 - 2)
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
    infoLabel.Text = tostring(InfoText or "")
    infoLabel.Font = Style.Font
    infoLabel.TextSize = s(12)
    infoLabel.TextColor3 = Style.SubText
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = false
    infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
    infoLabel.BackgroundTransparency = 1

    local bodyY = HEADER_H
    -- 功能区域不再从标题栏底部开始，而是整体上移靠齐窗口顶部：
    -- 标题 / Info 只占左侧栏宽度，右侧顶部原本是一整块空白，把控件区顶上去充分利用。
    local controlTop = PAD / 2
    local sidebar = Instance.new("Frame", main)
    sidebar.Name = "TabList"
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -bodyY - FOOTER_H - PAD)
    sidebar.Position = UDim2.new(0, PAD / 2, 0, bodyY)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0

    local sep = Instance.new("Frame", main)
    sep.Name = "TabSeparator"
    -- 底部向下延长至关闭按钮区域下方，与 FooterSeparator 一起闭合关闭按钮区；
    -- 顶部由 refreshSeparator 依据标题/Info 是否超线动态缩短（未超线时闭合到窗口顶）。
    sep.Size = UDim2.new(0, 1, 1, -PAD / 2)
    sep.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP / 2, 0, 0)
    sep.BackgroundColor3 = Cfg.DividerColor
    sep.BorderSizePixel = 0

    local controlRegion = Instance.new("Frame", main)
    controlRegion.Name = "ControlRegion"
    -- 功能区域整体上移靠齐顶部：顶部 = controlTop，底部仍与左侧 Footer 齐平
    controlRegion.Size = UDim2.new(1, -(PAD / 2 + SIDEBAR_W + TAB_AREA_GAP + PAD_IN), 1, -(controlTop + FOOTER_H + PAD))
    controlRegion.Position = UDim2.new(0, PAD / 2 + SIDEBAR_W + TAB_AREA_GAP, 0, controlTop)
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
        attachClickFx(b, { tint = Color3.new(1, 1, 1), peak = 0.7, radius = UDim.new(1, 0) })
        return b
    end
    local fbtnX = s(2)
    local fstep = fbtn + s(6)
    local minBtn = makeFooterButton("Minimize", "minimize", fbtnX, "_")
    local settingsBtn = makeFooterButton("Settings", "monitor-cog", fbtnX + fstep, "S")
    -- 新增：Config Manager（folder-cog），夹在 Settings 与 Close 之间
    local configBtn = makeFooterButton("ConfigManager", "folder-cog", fbtnX + fstep * 2, "C")
    local closeBtn = makeFooterButton("Close", "x", fbtnX + fstep * 3, "X")

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
    -- 初始仅用 Visible=false 隐藏即可；不要先整树淡成透明，否则随后
    -- noteTree(gui) 会把透明态误记为标称值，收起窗口淡入时黑底恢复不回来。
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
    -- 悬浮球以拖动为主：按住拖动时不需要任何白色按压高亮 / 波纹反馈
    attachClickFx(orbHit, { tint = Color3.new(1, 1, 1), peak = 0.72, radius = UDim.new(1, 0), ripple = false, pressFx = false })

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
        _configDir = ConfigDir,
        _configName = ConfigName,
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
        _inputShield = inputShield,
        _inputSinkActive = false,
        _sinks = {},
        _sizeX = Size.X.Offset,
        _sizeY = Size.Y.Offset,
        _uiScale = 1,
        _visW = Size.X.Offset,
        _visH = Size.Y.Offset,
        _language = "English",
        _settingsOpen = false,
        _settingsScale = 1,
        _settingsLanguage = "English",
        _controlW = Size.X.Offset - (PAD / 2 + SIDEBAR_W + TAB_AREA_GAP + PAD_IN),
        _viewH = Size.Y.Offset - (controlTop + FOOTER_H + PAD),
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

    win._language = opts.Language or "English"
    win._translations = opts.Translations or {}
    win._i18n = {}
    win._i18nDynamic = {}
    win:OnLanguageChanged(function() applyLang(win) end)
    if titleLabel then i18nText(win, titleLabel, Title) end
    if infoLabel then i18nText(win, infoLabel, InfoText) end
    applyLang(win)

    --[[
        分隔线自适应：
        - 标题 / Info 文字「超线」（超出标题栏可用宽度）时，竖分隔线顶部向下缩短到
          标题栏下方，避免竖线纵穿超长的标题文字；
        - 未超线时竖线从窗口顶部起，保持与顶边「闭合」；
        - 竖线底部始终向下延长至关闭按钮区域下方，与 FooterSeparator 一起闭合左下角。
        语言切换会改变 Info 文案，需重算。
    ]]
    local sepX = PAD / 2 + SIDEBAR_W + TAB_AREA_GAP / 2
    local function refreshSeparator()
        if not (sep and sep.Parent) then return end
        local titleLeft = HEADER_PAD + TITLE_ICON + s(10)
        -- 「超线」= 标题/Info 文字右边缘越过竖分隔线所在的 x 位置
        -- 允许文字略微越过竖线（留一点余量），避免短标题被误判；明显超长才触发缩短
        local availW = math.max(40, sepX - titleLeft + s(8))
        local function tooWide(txt, sz)
            if type(txt) ~= "string" or txt == "" then return false end
            -- 优先用引擎精确测量；不支持 / 报错时回退到字符数近似，保证判断不静默失效
            local ok, m = pcall(function()
                return TextService:GetTextSize(txt, sz, Style.Font, Vector2.new(100000, 100000))
            end)
            local w = (ok and m and m.X) or (#txt * sz * 0.58)
            return w > availW
        end
        local overflow = tooWide(titleLabel.Text, s(18)) or tooWide(infoLabel.Text, s(12))
        win._sepOverflow = overflow
        local top = overflow and SEP_TOP_SHRINK or 0
        sep.Position = UDim2.new(0, sepX, 0, top)
        sep.Size = UDim2.new(0, 1, 1, -PAD / 2 - top)
    end
    win._refreshSeparator = refreshSeparator
    win:OnLanguageChanged(function() pcall(refreshSeparator) end)
    refreshSeparator()

    orbExt.Changed:Connect(function() applyOrbLayout(win) end)
    orbBlend.Changed:Connect(function() applyOrbLayout(win) end)

    local SET_Z = ZBASE + 60
    local function silverGradient(parent)
        local g = Instance.new("UIGradient", parent)
        g.Rotation = 90
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Style.SilverTop),
            ColorSequenceKeypoint.new(1, Style.SilverBottom),
        })
        return g
    end

    local overlay = Instance.new("Frame", main)
    overlay.Name = "SettingsOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Position = UDim2.fromOffset(0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.55
    overlay.BorderSizePixel = 0
    overlay.ZIndex = SET_Z
    overlay.Visible = false
    overlay.ClipsDescendants = false
    overlay.Active = true
    local ovCorner = Instance.new("UICorner", overlay)
    ovCorner.CornerRadius = UDim.new(0, s(24))

    local preview = Instance.new("Frame", gui)
    preview.Name = "SizePreview"
    preview.AnchorPoint = Vector2.new(0.5, 0.5)
    preview.Size = UDim2.fromOffset(win._sizeX, win._sizeY)
    preview.Position = UDim2.fromOffset(main.Position.X.Offset + win._sizeX / 2, main.Position.Y.Offset + win._sizeY / 2)
    local PREVIEW_FILL = 0.9
    preview.BackgroundColor3 = Color3.fromRGB(70, 145, 255)
    preview.BackgroundTransparency = PREVIEW_FILL
    preview.BorderSizePixel = 0
    preview.Visible = false
    preview.ZIndex = ZBASE + 50
    local pvCorner = Instance.new("UICorner", preview)
    pvCorner.CornerRadius = UDim.new(0, s(24))
    local pvStroke = Instance.new("UIStroke", preview)
    pvStroke.Color = Color3.fromRGB(120, 180, 255)
    pvStroke.Thickness = 2
    pvStroke.Transparency = 0
    pvStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    local pW, pH = s(320), s(244)
    local panel = makeGlass(gui, {
        Name = "SettingsPanel",
        Size = UDim2.fromOffset(pW, pH),
        Position = UDim2.new(0.5, -pW / 2, 0.5, -pH / 2),
        Transparency = 0.06,
        Radius = UDim.new(0, s(16)),
        Color = Color3.fromRGB(22, 23, 29),
        Plain = true,
    })
    panel.ZIndex = ZBASE + 52
    panel.ClipsDescendants = false
    panel.Visible = false

    local titleLbl = Instance.new("TextLabel", panel)
    titleLbl.Name = "SettingsTitle"
    titleLbl.Size = UDim2.fromOffset(pW - s(60), s(26))
    titleLbl.Position = UDim2.fromOffset(s(16), s(10))
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Style.Font
    titleLbl.TextSize = s(16)
    titleLbl.TextColor3 = Style.Text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextYAlignment = Enum.TextYAlignment.Center
    i18nText(win, titleLbl, "Settings")
    titleLbl.ZIndex = SET_Z + 2

    local xBtn = Instance.new("TextButton", panel)
    xBtn.Name = "CloseSettings"
    xBtn.Size = UDim2.fromOffset(s(26), s(26))
    xBtn.Position = UDim2.fromOffset(pW - s(36), s(10))
    xBtn.BackgroundTransparency = 1
    xBtn.Text = ""
    xBtn.AutoButtonColor = false
    xBtn.ZIndex = SET_Z + 2
    local xIcon = Instance.new("ImageLabel", xBtn)
    xIcon.Size = UDim2.new(0.7, 0, 0.7, 0)
    xIcon.Position = UDim2.new(0.15, 0, 0.15, 0)
    xIcon.BackgroundTransparency = 1
    xIcon.Active = false
    xIcon.ZIndex = SET_Z + 3
    if not applyIcon(xIcon, "x", Style.Text) then
        xBtn.Text = "X"
        xBtn.TextColor3 = Style.Text
        xBtn.Font = Style.Font
        xBtn.TextSize = s(14)
    end
    attachClickFx(xBtn, { tint = Color3.new(1, 1, 1), peak = 0.7, radius = UDim.new(1, 0) })

    local sizeLbl = Instance.new("TextLabel", panel)
    sizeLbl.Name = "SizeLabel"
    sizeLbl.Size = UDim2.fromOffset(pW - s(48), s(20))
    sizeLbl.Position = UDim2.fromOffset(s(24), s(48))
    sizeLbl.BackgroundTransparency = 1
    sizeLbl.Font = Style.Font
    sizeLbl.TextSize = s(12)
    sizeLbl.TextColor3 = Style.SubText
    sizeLbl.TextXAlignment = Enum.TextXAlignment.Left
    i18nText(win, sizeLbl, "Window Size")
    sizeLbl.ZIndex = SET_Z + 2

    local sVal = Instance.new("TextLabel", panel)
    sVal.Name = "SizeValue"
    sVal.Size = UDim2.fromOffset(s(60), s(20))
    sVal.Position = UDim2.fromOffset(pW - s(84), s(48))
    sVal.BackgroundTransparency = 1
    sVal.Font = Style.Font
    sVal.TextSize = s(12)
    sVal.TextColor3 = Color3.fromRGB(120, 170, 255)
    sVal.TextXAlignment = Enum.TextXAlignment.Right
    sVal.Text = "100%"
    sVal.ZIndex = SET_Z + 2

    local sTrack = Instance.new("Frame", panel)
    sTrack.Name = "SettingsSliderTrack"
    sTrack.Size = UDim2.fromOffset(pW - s(48), s(8))
    sTrack.Position = UDim2.fromOffset(s(24), s(76))
    sTrack.BackgroundColor3 = Style.SliderTrack
    sTrack.BackgroundTransparency = 0.2
    sTrack.BorderSizePixel = 0
    sTrack.ClipsDescendants = false
    sTrack.Active = true
    sTrack.ZIndex = SET_Z + 2
    local stc = Instance.new("UICorner", sTrack)
    stc.CornerRadius = UDim.new(0, s(4))
    local sFill = Instance.new("Frame", sTrack)
    sFill.Name = "SettingsSliderFill"
    sFill.Size = UDim2.new(0.42, 0, 1, 0)
    sFill.BackgroundColor3 = Color3.new(1, 1, 1)
    sFill.BorderSizePixel = 0
    sFill.Active = false
    sFill.ZIndex = SET_Z + 3
    local sfg = silverGradient(sFill)
    local sfc = Instance.new("UICorner", sFill)
    sfc.CornerRadius = UDim.new(0, s(4))
    local langLbl = Instance.new("TextLabel", panel)
    langLbl.Name = "LangLabel"
    langLbl.Size = UDim2.fromOffset(pW - s(48), s(20))
    langLbl.Position = UDim2.fromOffset(s(24), s(100))
    langLbl.BackgroundTransparency = 1
    langLbl.Font = Style.Font
    langLbl.TextSize = s(12)
    langLbl.TextColor3 = Style.SubText
    langLbl.TextXAlignment = Enum.TextXAlignment.Left
    i18nText(win, langLbl, "Language")
    langLbl.ZIndex = SET_Z + 2

    local applyBtn = Instance.new("TextButton", panel)
    applyBtn.Name = "Apply"
    applyBtn.Size = UDim2.fromOffset(pW - s(48), s(32))
    applyBtn.Position = UDim2.fromOffset(s(24), pH - s(46))
    applyBtn.BackgroundColor3 = Color3.new(1, 1, 1)
    applyBtn.BackgroundTransparency = Style.SilverTransparency
    applyBtn.BorderSizePixel = 0
    i18nText(win, applyBtn, "Apply")
    applyBtn.Font = Style.Font
    applyBtn.TextSize = s(14)
    applyBtn.TextColor3 = Style.ActiveText
    applyBtn.AutoButtonColor = false
    applyBtn.ZIndex = SET_Z + 3
    attachClickFx(applyBtn, { tint = Color3.new(0, 0, 0), peak = 0.7, radius = UDim.new(0, s(9)) })
    local abg = silverGradient(applyBtn)
    local abCorner = Instance.new("UICorner", applyBtn)
    abCorner.CornerRadius = UDim.new(0, s(9))

    local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.75, 1.35, 0.05
    local previewScale = win._uiScale or 1
    local settingsLanguage = win._language or "English"
    local langOptions = { "English", "中文" }

    local langDropdown = makeDropdown(panel, {
        Width = pW - s(48),
        Height = s(28),
        Position = UDim2.fromOffset(s(24), s(124)),
        Options = langOptions,
        Default = settingsLanguage,
        ZIndex = SET_Z + 4,
        Callback = function(v) settingsLanguage = v end,
    })

    local function refreshScaleSlider()
        local f = math.clamp((previewScale - SCALE_MIN) / (SCALE_MAX - SCALE_MIN), 0, 1)
        sFill.Size = UDim2.new(f, 0, 1, 0)
        sVal.Text = tostring(math.floor(previewScale * 100 + 0.5)) .. "%"
    end

    local previewTweens = {}
    -- 兜底：preview 的 Position 在创建时写死，窗口被拖动后若直接 tween 会从旧位置“飞”过来。
    -- 每次从隐藏恢复显示时，先把位置/尺寸瞬移到位（snap），后续拖动再平滑过渡。
    local previewSnapPending = true
    local function restorePreviewAlpha()
        preview.BackgroundTransparency = PREVIEW_FILL
        if pvStroke then pvStroke.Transparency = 0 end
    end
    local function showPreview()
        pcall(function() setGroupTransparency(preview, 0, true) end)
        restorePreviewAlpha()
        preview.Visible = true
        previewSnapPending = true
    end
    local function hidePreview()
        preview.Visible = false
        restorePreviewAlpha()
        previewSnapPending = false
    end
    local function tweenPreview(nw, nh, cx, cy)
        showPreview()
        if previewSnapPending then
            previewSnapPending = false
            preview.Size = UDim2.fromOffset(nw, nh)
            preview.Position = UDim2.fromOffset(cx, cy)
            return
        end
        local ti = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, tw in ipairs(previewTweens) do pcall(function() tw:Cancel() end) end
        previewTweens = {}
        local tw1 = TweenService:Create(preview, ti, { Size = UDim2.fromOffset(nw, nh) })
        local tw2 = TweenService:Create(preview, ti, { Position = UDim2.fromOffset(cx, cy) })
        table.insert(previewTweens, tw1)
        table.insert(previewTweens, tw2)
        tw1:Play(); tw2:Play()
    end

    local function updatePreview(k)
        if not (win._settingsOpen and k) then hidePreview() return end
        local nw, nh = win._sizeX * k, win._sizeY * k
        local curW, curH = win._sizeX * (win._uiScale or 1), win._sizeY * (win._uiScale or 1)
        local vw, vh = viewport()
        local cx = main.Position.X.Offset + curW / 2
        local cy = main.Position.Y.Offset + curH / 2
        cx = math.clamp(cx, nw / 2, math.max(nw / 2, vw - nw / 2))
        cy = math.clamp(cy, nh / 2, math.max(nh / 2, vh - nh / 2))
        tweenPreview(nw, nh, cx, cy)
    end

    local function setScaleFromFrac(f)
        f = math.clamp(f or 0, 0, 1)
        local raw = SCALE_MIN + f * (SCALE_MAX - SCALE_MIN)
        previewScale = SCALE_MIN + math.floor((raw - SCALE_MIN) / SCALE_STEP + 0.5) * SCALE_STEP
        previewScale = math.clamp(previewScale, SCALE_MIN, SCALE_MAX)
        refreshScaleSlider()
        updatePreview(previewScale)
    end

    sTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local function frac(inp)
                local aw = sTrack.AbsoluteSize.X
                if not aw or aw <= 0 then return 0.5 end
                return math.clamp((inp.Position.X - sTrack.AbsolutePosition.X) / aw, 0, 1)
            end
            setScaleFromFrac(frac(input))
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if conn then pcall(function() conn:Disconnect() end) end
                elseif input.Position then
                    setScaleFromFrac(frac(input))
                end
            end)
        end
    end)

    local settingsGen = 0
    local function closeSettings(instant)
        win._settingsOpen = false
        setInputSink(win, "settings", false)
        settingsGen = settingsGen + 1
        local gen = settingsGen
        if langDropdown and langDropdown._closeMenu then pcall(langDropdown._closeMenu) end
        if instant then
            hidePreview()
            overlay.Visible = false
            panel.Visible = false
            return
        end
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenGroup(preview, 1, ti, function()
            if settingsGen == gen and not win._settingsOpen then hidePreview() end
        end, true)
        tweenGroup(overlay, 1, ti, function()
            if settingsGen == gen and not win._settingsOpen then overlay.Visible = false end
        end, true)
        tweenGroup(panel, 1, ti, function()
            if settingsGen == gen and not win._settingsOpen then panel.Visible = false end
        end, true)
    end
    win._closeSettings = closeSettings

    local function openSettings()
        if win._settingsOpen then return end
        win._settingsOpen = true
        setInputSink(win, "settings", true)
        settingsGen = settingsGen + 1
        previewScale = win._uiScale or 1
        settingsLanguage = win._language or "English"
        refreshScaleSlider()
        langDropdown:Set(settingsLanguage)
        overlay.Visible = true
        panel.Visible = true
        hidePreview()
        setGroupTransparency(overlay, 1, true)
        setGroupTransparency(panel, 1, true)
        local ti = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenGroup(overlay, 0, ti, nil, true)
        tweenGroup(panel, 0, ti, nil, true)
    end
    win._openSettings = openSettings

    local function applySettings()
        local k = previewScale
        local kOld = mainScale.Scale or 1
        win._uiScale = k
        win._visW = win._sizeX * k
        win._visH = win._sizeY * k
        win._settingsScale = k
        local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        local w, h = win._sizeX, win._sizeY
        local cx = main.Position.X.Offset + w * kOld / 2
        local cy = main.Position.Y.Offset + h * kOld / 2
        local nx = cx - w * k / 2
        local ny = cy - h * k / 2
        local vw, vh = viewport()
        nx = math.clamp(nx, 0, math.max(0, vw - w * k))
        ny = math.clamp(ny, 0, math.max(0, vh - h * k))

        win._mainScaleTween = TweenService:Create(mainScale, ti, { Scale = k })
        win._mainScaleTween:Play()
        win._posTween = TweenService:Create(main, ti, { Position = UDim2.fromOffset(nx, ny) })
        win._posTween:Play()
        win._mainPosBeforeCollapse = UDim2.fromOffset(nx, ny)
        win._settingsLanguage = settingsLanguage
        win:SetLanguage(settingsLanguage)
        -- 自动储存已移除：此处不再触发 SaveConfig
        closeSettings()
    end

    xBtn.MouseButton1Click:Connect(closeSettings)
    applyBtn.MouseButton1Click:Connect(applySettings)

    do
        local function markSkip(node)
            pcall(function() node:SetAttribute("_skipFade", true) end)
            for _, ch in ipairs(node:GetChildren()) do markSkip(ch) end
        end
        markSkip(overlay)
        markSkip(panel)
        markSkip(preview)
    end

    local confirmOverlay = Instance.new("Frame", gui)
    confirmOverlay.Name = "CloseConfirmOverlay"
    confirmOverlay.Size = UDim2.fromScale(1, 1)
    confirmOverlay.Position = UDim2.fromOffset(0, 0)
    confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    confirmOverlay.BackgroundTransparency = 0.55
    confirmOverlay.BorderSizePixel = 0
    confirmOverlay.ZIndex = ZBASE + 51
    confirmOverlay.Visible = false
    confirmOverlay.ClipsDescendants = false
    confirmOverlay.Active = true
    local cOvCorner = Instance.new("UICorner", confirmOverlay)
    cOvCorner.CornerRadius = UDim.new(0, s(24))

    local cpW, cpH = s(320), s(150)
    local confirmPanel = makeGlass(gui, {
        Name = "CloseConfirmPanel",
        Size = UDim2.fromOffset(cpW, cpH),
        Position = UDim2.new(0.5, -cpW / 2, 0.5, -cpH / 2),
        Transparency = 0.06,
        Radius = UDim.new(0, s(16)),
        Color = Color3.fromRGB(22, 23, 29),
        Plain = true,
    })
    confirmPanel.ZIndex = ZBASE + 53
    confirmPanel.ClipsDescendants = false
    confirmPanel.Visible = false

    local confirmText = Instance.new("TextLabel", confirmPanel)
    confirmText.Name = "CloseConfirmText"
    confirmText.Size = UDim2.new(1, -s(32), 0, s(48))
    confirmText.Position = UDim2.new(0, s(16), 0, s(18))
    confirmText.BackgroundTransparency = 1
    confirmText.Font = Style.Font
    confirmText.TextSize = s(15)
    confirmText.TextColor3 = Style.Text
    confirmText.TextWrapped = true
    confirmText.TextXAlignment = Enum.TextXAlignment.Center
    confirmText.TextYAlignment = Enum.TextYAlignment.Center
    confirmText.ZIndex = ZBASE + 54
    i18nText(win, confirmText, "Are you sure you want to close?")

    local cbtnW = (cpW - s(48) - s(12)) / 2
    local confirmBtn = Instance.new("TextButton", confirmPanel)
    confirmBtn.Name = "ConfirmClose"
    confirmBtn.Size = UDim2.fromOffset(cbtnW, s(34))
    confirmBtn.Position = UDim2.fromOffset(s(24), cpH - s(46))
    confirmBtn.BackgroundColor3 = Color3.new(1, 1, 1)
    confirmBtn.BackgroundTransparency = Style.SilverTransparency
    confirmBtn.BorderSizePixel = 0
    confirmBtn.Text = ""
    confirmBtn.AutoButtonColor = false
    confirmBtn.ZIndex = ZBASE + 55
    silverGradient(confirmBtn)
    local cbCorner = Instance.new("UICorner", confirmBtn)
    cbCorner.CornerRadius = UDim.new(0, s(9))
    local confirmBtnLbl = Instance.new("TextLabel", confirmBtn)
    confirmBtnLbl.Size = UDim2.fromScale(1, 1)
    confirmBtnLbl.BackgroundTransparency = 1
    confirmBtnLbl.Font = Style.Font
    confirmBtnLbl.TextSize = s(14)
    confirmBtnLbl.TextColor3 = Style.ActiveText
    confirmBtnLbl.TextXAlignment = Enum.TextXAlignment.Center
    confirmBtnLbl.TextYAlignment = Enum.TextYAlignment.Center
    confirmBtnLbl.ZIndex = ZBASE + 56
    i18nText(win, confirmBtnLbl, "Confirm")
    attachClickFx(confirmBtn, { tint = Color3.new(0, 0, 0), peak = 0.7, radius = UDim.new(0, s(9)) })

    local cancelBtn = Instance.new("TextButton", confirmPanel)
    cancelBtn.Name = "CancelClose"
    cancelBtn.Size = UDim2.fromOffset(cbtnW, s(34))
    cancelBtn.Position = UDim2.fromOffset(s(24) + cbtnW + s(12), cpH - s(46))
    cancelBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
    cancelBtn.BackgroundTransparency = 0.2
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = ""
    cancelBtn.AutoButtonColor = false
    cancelBtn.ZIndex = ZBASE + 55
    local canCorner = Instance.new("UICorner", cancelBtn)
    canCorner.CornerRadius = UDim.new(0, s(9))
    local cancelBtnLbl = Instance.new("TextLabel", cancelBtn)
    cancelBtnLbl.Size = UDim2.fromScale(1, 1)
    cancelBtnLbl.BackgroundTransparency = 1
    cancelBtnLbl.Font = Style.Font
    cancelBtnLbl.TextSize = s(14)
    cancelBtnLbl.TextColor3 = Style.Text
    cancelBtnLbl.TextXAlignment = Enum.TextXAlignment.Center
    cancelBtnLbl.TextYAlignment = Enum.TextYAlignment.Center
    cancelBtnLbl.ZIndex = ZBASE + 56
    attachClickFx(cancelBtn, { tint = Color3.new(1, 1, 1), peak = 0.7, radius = UDim.new(0, s(9)) })
    i18nText(win, cancelBtnLbl, "Cancel")

    local confirmGen = 0
    local function closeConfirm()
        confirmGen = confirmGen + 1
        local gen = confirmGen
        local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenGroup(confirmOverlay, 1, ti, function()
            if confirmGen == gen then confirmOverlay.Visible = false end
        end, true)
        tweenGroup(confirmPanel, 1, ti, function()
            if confirmGen == gen then confirmPanel.Visible = false end
        end, true)
    end
    local function openConfirm()
        confirmGen = confirmGen + 1
        confirmOverlay.Visible = true
        confirmPanel.Visible = true
        setGroupTransparency(confirmOverlay, 1, true)
        setGroupTransparency(confirmPanel, 1, true)
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenGroup(confirmOverlay, 0, ti, nil, true)
        tweenGroup(confirmPanel, 0, ti, nil, true)
    end
    confirmBtn.MouseButton1Click:Connect(function()
        local done = false
        local function finish()
            if done then return end
            done = true
            if gui and gui.Parent then gui:Destroy() end
        end
        local ti = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenGroup(gui, 1, ti, finish, true)
        task.delay(0.34, finish)
    end)
    cancelBtn.MouseButton1Click:Connect(closeConfirm)

    closeBtn.MouseButton1Click:Connect(openConfirm)
    minBtn.MouseButton1Click:Connect(function() collapse(win) end)
    settingsBtn.MouseButton1Click:Connect(function() openSettings() end)

    -- ===================== Config Manager（配置管理面板） =====================
    -- folder-cog 唤起，与 Setting 同款面板结构：标题 Config Manager、右上 x、
    -- 居中大下拉（列出 config 名称，展开为可滚动列表，选中项银白渐变高亮）、
    -- 底部三按钮（Delete / Save / Load）。互斥于 Settings 打开，并启用输入盾。
    do
        local cfgOverlay = Instance.new("Frame", gui)
        cfgOverlay.Name = "ConfigOverlay"
        cfgOverlay.Size = UDim2.fromScale(1, 1)
        cfgOverlay.Position = UDim2.fromOffset(0, 0)
        cfgOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
        cfgOverlay.BackgroundTransparency = 0.55
        cfgOverlay.BorderSizePixel = 0
        cfgOverlay.ZIndex = SET_Z
        cfgOverlay.Visible = false
        cfgOverlay.ClipsDescendants = false
        cfgOverlay.Active = true
        local cfgOvCorner = Instance.new("UICorner", cfgOverlay)
        cfgOvCorner.CornerRadius = UDim.new(0, s(24))

        local function silverGradient(parent)
            local g = Instance.new("UIGradient", parent)
            g.Rotation = 90
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Style.SilverTop),
                ColorSequenceKeypoint.new(1, Style.SilverBottom),
            })
            return g
        end
        local function redGradient(parent)
            local g = Instance.new("UIGradient", parent)
            g.Rotation = 90
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(214, 62, 62)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 14, 16)),
            })
            return g
        end

        local function hitTest(o, px, py)
            if not (o and o.Parent) then return false end
            local a, sz = o.AbsolutePosition, o.AbsoluteSize
            if not (a and sz) then return false end
            return px >= a.X - 2 and px <= a.X + sz.X + 2
                and py >= a.Y - 2 and py <= a.Y + sz.Y + 2
        end

        local cpW, cpH = s(340), s(312)
        local cfgPanel = makeGlass(gui, {
            Name = "ConfigPanel",
            Size = UDim2.fromOffset(cpW, cpH),
            Position = UDim2.new(0.5, -cpW / 2, 0.5, -cpH / 2),
            Transparency = 0.06,
            Radius = UDim.new(0, s(16)),
            Color = Color3.fromRGB(22, 23, 29),
            Plain = true,
        })
        cfgPanel.ZIndex = ZBASE + 52
        cfgPanel.ClipsDescendants = false
        cfgPanel.Visible = false

        local cfgTitle = Instance.new("TextLabel", cfgPanel)
        cfgTitle.Name = "ConfigTitle"
        cfgTitle.Size = UDim2.fromOffset(cpW - s(60), s(26))
        cfgTitle.Position = UDim2.fromOffset(s(16), s(10))
        cfgTitle.BackgroundTransparency = 1
        cfgTitle.Font = Style.Font
        cfgTitle.TextSize = s(16)
        cfgTitle.TextColor3 = Style.Text
        cfgTitle.TextXAlignment = Enum.TextXAlignment.Left
        cfgTitle.TextYAlignment = Enum.TextYAlignment.Center
        i18nText(win, cfgTitle, "Config Manager")
        cfgTitle.ZIndex = SET_Z + 2

        local cfgX = Instance.new("TextButton", cfgPanel)
        cfgX.Name = "CloseConfig"
        cfgX.Size = UDim2.fromOffset(s(26), s(26))
        cfgX.Position = UDim2.fromOffset(cpW - s(36), s(10))
        cfgX.BackgroundTransparency = 1
        cfgX.Text = ""
        cfgX.AutoButtonColor = false
        cfgX.ZIndex = SET_Z + 2
        local cfgXIcon = Instance.new("ImageLabel", cfgX)
        cfgXIcon.Size = UDim2.new(0.7, 0, 0.7, 0)
        cfgXIcon.Position = UDim2.new(0.15, 0, 0.15, 0)
        cfgXIcon.BackgroundTransparency = 1
        cfgXIcon.Active = false
        cfgXIcon.ZIndex = SET_Z + 3
        if not applyIcon(cfgXIcon, "x", Style.Text) then
            cfgX.Text = "X"
            cfgX.TextColor3 = Style.Text
            cfgX.Font = Style.Font
            cfgX.TextSize = s(14)
        end
        attachClickFx(cfgX, { tint = Color3.new(1, 1, 1), peak = 0.7, radius = UDim.new(1, 0) })

        -- 居中大下拉：模仿 DynamicCow「切换脚本」窗口。胶囊居中，点击展开
        -- 可滚动列表，列出 config 名称，选中项以银白渐变高亮。
        local ddW = cpW - s(48)
        local ddH = s(36)
        local selectedConfig = ""
        local ddMenuOpen = false
        local ddHostZ = nil
        local ddOutsideConn = nil
        local optionRows = {}
        local ddOptH = s(30)

        local ddCapsule = Instance.new("TextButton", cfgPanel)
        ddCapsule.Name = "ConfigDropdown"
        ddCapsule.Size = UDim2.fromOffset(ddW, ddH)
        ddCapsule.Position = UDim2.new(0.5, -ddW / 2, 0, s(58))
        ddCapsule.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        ddCapsule.BackgroundTransparency = 0.12
        ddCapsule.BorderSizePixel = 0
        ddCapsule.Text = ""
        ddCapsule.AutoButtonColor = false
        ddCapsule.ZIndex = SET_Z + 4
        local ddCapCorner = Instance.new("UICorner", ddCapsule)
        ddCapCorner.CornerRadius = UDim.new(0, s(10))
        local ddCapStroke = Instance.new("UIStroke", ddCapsule)
        ddCapStroke.Color = Color3.fromRGB(150, 150, 160)
        ddCapStroke.Thickness = 1
        ddCapStroke.Transparency = 0.35
        ddCapStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        local ddCapLabel = Instance.new("TextLabel", ddCapsule)
        ddCapLabel.Name = "DdLabel"
        ddCapLabel.Size = UDim2.new(1, -s(34), 1, 0)
        ddCapLabel.Position = UDim2.fromOffset(s(14), 0)
        ddCapLabel.BackgroundTransparency = 1
        ddCapLabel.Font = Style.Font
        ddCapLabel.TextSize = s(13)
        ddCapLabel.TextColor3 = Color3.new(1, 1, 1)
        ddCapLabel.TextXAlignment = Enum.TextXAlignment.Center
        ddCapLabel.TextYAlignment = Enum.TextYAlignment.Center
        ddCapLabel.TextTruncate = Enum.TextTruncate.AtEnd
        ddCapLabel.Text = translateKey(win, "No Configs")
        ddCapLabel.ZIndex = SET_Z + 5
        ddCapLabel:SetAttribute("_skipFade", true)
        local ddArrow = Instance.new("ImageLabel", ddCapsule)
        ddArrow.Name = "DdArrow"
        ddArrow.Size = UDim2.fromOffset(s(14), s(14))
        ddArrow.AnchorPoint = Vector2.new(1, 0.5)
        ddArrow.Position = UDim2.new(1, -s(11), 0.5, 0)
        ddArrow.BackgroundTransparency = 1
        ddArrow.Active = false
        ddArrow.ZIndex = SET_Z + 5
        ddArrow:SetAttribute("_skipFade", true)
        applyIcon(ddArrow, "chevron-down", Style.SubText)

        local ddMenu = Instance.new("Frame", cfgPanel)
        ddMenu.Name = "ConfigMenu"
        ddMenu.Size = UDim2.fromOffset(ddW, s(150))
        ddMenu.Position = UDim2.new(0.5, -ddW / 2, 0, s(58) + ddH + s(4))
        ddMenu.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        ddMenu.BackgroundTransparency = 0.02
        ddMenu.BorderSizePixel = 0
        ddMenu.ClipsDescendants = true
        ddMenu.Visible = false
        ddMenu.ZIndex = SET_Z + 20
        local ddMenuCorner = Instance.new("UICorner", ddMenu)
        ddMenuCorner.CornerRadius = UDim.new(0, s(10))
        local ddMenuStroke = Instance.new("UIStroke", ddMenu)
        ddMenuStroke.Color = Color3.fromRGB(150, 150, 160)
        ddMenuStroke.Thickness = 1
        ddMenuStroke.Transparency = 0.45
        ddMenuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

        local ddScroll = Instance.new("ScrollingFrame", ddMenu)
        ddScroll.Name = "ConfigScroll"
        ddScroll.Size = UDim2.fromScale(1, 1)
        ddScroll.Position = UDim2.fromOffset(0, 0)
        ddScroll.BackgroundTransparency = 1
        ddScroll.BorderSizePixel = 0
        ddScroll.ScrollBarThickness = s(6)
        ddScroll.ZIndex = SET_Z + 21
        ddScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local ddScrollLayout = Instance.new("UIListLayout", ddScroll)
        ddScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ddScrollLayout.Padding = UDim.new(0, s(2))

        local function closeDdMenu()
            if not ddMenuOpen then return end
            ddMenuOpen = false
            if ddHostZ ~= nil then cfgPanel.ZIndex = ddHostZ; ddHostZ = nil end
            fadeGroup(ddMenu, 1, function() if not ddMenuOpen then ddMenu.Visible = false end end)
            if ddOutsideConn then pcall(function() ddOutsideConn:Disconnect() end) ddOutsideConn = nil end
        end

        local function refreshDdHighlights()
            for _, row in ipairs(optionRows) do
                local sel = (row.name == selectedConfig)
                if sel then
                    row.btn.BackgroundTransparency = 0.06
                    silverGradient(row.btn)
                else
                    row.btn.BackgroundTransparency = 1
                end
            end
        end

        local function buildDdOptions()
            for _, row in ipairs(optionRows) do
                if row.btn and row.btn.Parent then row.btn:Destroy() end
            end
            optionRows = {}
            local names = win:GetConfigs()
            if #names == 0 then
                selectedConfig = ""
            elseif selectedConfig == "" or not table.find(names, selectedConfig) then
                selectedConfig = names[1]
            end
            ddCapLabel.Text = selectedConfig ~= "" and selectedConfig or translateKey(win, "No Configs")
            for i, name in ipairs(names) do
                local row = Instance.new("TextButton", ddScroll)
                row.Name = "ConfigOption"
                row.LayoutOrder = i
                row.Size = UDim2.new(1, -s(8), 0, ddOptH)
                row.Position = UDim2.fromOffset(s(4), 0)
                row.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.Text = ""
                row.AutoButtonColor = false
                row.ZIndex = SET_Z + 22
                local rc = Instance.new("UICorner", row)
                rc.CornerRadius = UDim.new(0, s(6))
                local tx = Instance.new("TextLabel", row)
                tx.Size = UDim2.fromScale(1, 1)
                tx.BackgroundTransparency = 1
                tx.Font = Style.Font
                tx.TextSize = s(12)
                tx.TextColor3 = Color3.fromRGB(230, 230, 235)
                tx.TextXAlignment = Enum.TextXAlignment.Center
                tx.TextYAlignment = Enum.TextYAlignment.Center
                tx.Text = tostring(name)
                tx.ZIndex = SET_Z + 23
                tx:SetAttribute("_skipFade", true)
                row.MouseButton1Click:Connect(function()
                    selectedConfig = tostring(name)
                    ddCapLabel.Text = selectedConfig
                    refreshDdHighlights()
                    closeDdMenu()
                end)
                optionRows[i] = { btn = row, name = tostring(name) }
            end
            refreshDdHighlights()
        end

        ddCapsule.MouseButton1Click:Connect(function()
            if ddMenuOpen then closeDdMenu() return end
            ddMenuOpen = true
            if ddHostZ == nil then ddHostZ = cfgPanel.ZIndex; cfgPanel.ZIndex = ZBASE + 100 end
            ddMenu.Visible = true
            setGroupTransparency(ddMenu, 1)
            fadeGroup(ddMenu, 0)
            ddOutsideConn = UserInputService.InputBegan:Connect(function(input)
                if not ddMenuOpen then return end
                local t = input.UserInputType
                if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
                local px, py = inputPoint(input)
                if not hitTest(ddCapsule, px, py) and not hitTest(ddMenu, px, py) then closeDdMenu() end
            end)
        end)

        -- 底部三按钮
        local btnY = cpH - s(52)
        local btnGap = s(10)
        local btnW = (cpW - s(48) - btnGap * 2) / 3
        local btnH = s(38)
        local function makeCfgBtn(textKey, x, gradFn, textColor)
            local b = Instance.new("TextButton", cfgPanel)
            b.Name = "Cfg" .. textKey
            b.Size = UDim2.fromOffset(btnW, btnH)
            b.Position = UDim2.fromOffset(s(24) + x * (btnW + btnGap), btnY)
            b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            b.BackgroundTransparency = 0.06
            b.BorderSizePixel = 0
            i18nText(win, b, textKey)
            b.Font = Style.Font
            b.TextSize = s(13)
            b.TextColor3 = textColor
            b.AutoButtonColor = false
            b.ZIndex = SET_Z + 4
            gradFn(b)
            local bc = Instance.new("UICorner", b)
            bc.CornerRadius = UDim.new(0, s(9))
            attachClickFx(b, { tint = Color3.new(0, 0, 0), peak = 0.65, radius = UDim.new(0, s(9)) })
            return b
        end
        local delBtn = makeCfgBtn("Delete Config", 0, redGradient, Color3.new(1, 1, 1))
        local saveBtn = makeCfgBtn("Save Config", 1, silverGradient, Style.ActiveText)
        local loadBtn = makeCfgBtn("Load Config", 2, silverGradient, Style.ActiveText)

        local function nextConfigName()
            local n = 0
            for _, name in ipairs(win:GetConfigs()) do
                local m = tostring(name):match("^Config (%d+)$")
                if m then n = math.max(n, tonumber(m) or 0) end
            end
            return "Config " .. tostring(n + 1)
        end

        local cfgGen = 0
        local function closeConfig(instant)
            win._configOpen = false
            setInputSink(win, "config", false)
            cfgGen = cfgGen + 1
            local gen = cfgGen
            closeDdMenu()
            if instant then
                cfgOverlay.Visible = false
                cfgPanel.Visible = false
                return
            end
            local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            tweenGroup(cfgOverlay, 1, ti, function()
                if cfgGen == gen and not win._configOpen then cfgOverlay.Visible = false end
            end, true)
            tweenGroup(cfgPanel, 1, ti, function()
                if cfgGen == gen and not win._configOpen then cfgPanel.Visible = false end
            end, true)
        end
        win._closeConfig = closeConfig

        local function openConfig()
            if win._configOpen then return end
            win._configOpen = true
            setInputSink(win, "config", true)
            cfgGen = cfgGen + 1
            buildDdOptions()
            cfgOverlay.Visible = true
            cfgPanel.Visible = true
            setGroupTransparency(cfgOverlay, 1, true)
            setGroupTransparency(cfgPanel, 1, true)
            local ti = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            tweenGroup(cfgOverlay, 0, ti, nil, true)
            tweenGroup(cfgPanel, 0, ti, nil, true)
        end

        delBtn.MouseButton1Click:Connect(function()
            closeDdMenu()
            if selectedConfig == "" then
                win:ShowNotify({ Title = translateKey(win, "Config Manager"), Info = translateKey(win, "Select a config first") })
                return
            end
            if selectedConfig == DEFAULT_CONFIG then
                win:ShowNotify({ Title = translateKey(win, "Config Manager"), Info = translateKey(win, "Cannot delete default config") })
                return
            end
            if win:DeleteConfig(selectedConfig) then
                win:ShowNotify({ Title = translateKey(win, "Config Manager"), Info = translateKey(win, "Config Deleted") .. ": " .. selectedConfig })
                buildDdOptions()
            end
        end)
        saveBtn.MouseButton1Click:Connect(function()
            closeDdMenu()
            local name = nextConfigName()
            pcall(function() win:SaveConfig(name) end)
            win:ShowNotify({ Title = translateKey(win, "Config Manager"), Info = translateKey(win, "Saved as") .. " " .. name .. ".json" })
            buildDdOptions()
        end)
        loadBtn.MouseButton1Click:Connect(function()
            closeDdMenu()
            if selectedConfig == "" then
                win:ShowNotify({ Title = translateKey(win, "Config Manager"), Info = translateKey(win, "Select a config first") })
                return
            end
            pcall(function() win:LoadConfig(selectedConfig) end)
            win:ShowNotify({ Title = translateKey(win, "Config Manager"), Info = translateKey(win, "Config Loaded") .. ": " .. selectedConfig })
        end)

        cfgX.MouseButton1Click:Connect(closeConfig)

        do
            local function markSkip(node)
                pcall(function() node:SetAttribute("_skipFade", true) end)
                for _, ch in ipairs(node:GetChildren()) do markSkip(ch) end
            end
            markSkip(cfgOverlay)
            markSkip(cfgPanel)
        end

        configBtn.MouseButton1Click:Connect(function()
            if win._closeSettings then pcall(win._closeSettings) end
            openConfig()
        end)
    end

    local winDrag, winMoved, wsx, wsy, wox, woy
    local winMoveConn, winEndConn
    local function stopWinDrag()
        if not winDrag then return end
        winDrag = false
        setInputSink(win, "window", false)
        if winMoveConn then pcall(function() winMoveConn:Disconnect() end) winMoveConn = nil end
        if winEndConn then pcall(function() winEndConn:Disconnect() end) winEndConn = nil end
    end
    header.InputBegan:Connect(function(input)
        if win._collapsed then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        if winDrag then stopWinDrag() end
        winDrag = true
        setInputSink(win, "window", true)
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
                local nx = math.clamp(wox + dx, 0, math.max(0, vw - (win._visW or win._sizeX)))
                local ny = math.clamp(woy + dy, 0, math.max(0, vh - (win._visH or win._sizeY)))
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

    local orbDragging, orbGestureMoved, orbSuppressClick, orbHaveStart
    local orbStartX, orbStartY, orbOriginX, orbOriginY
    local orbMoveConn, orbEndConn
    local function stopOrbDrag()
        if not orbDragging then return end
        orbDragging = false
        setInputSink(win, "orb", false)
        win._orbDragging = false
        if orbMoveConn then pcall(function() orbMoveConn:Disconnect() end) orbMoveConn = nil end
        if orbEndConn then pcall(function() orbEndConn:Disconnect() end) orbEndConn = nil end
    end
    local function startOrbDrag(input)
        if orbDragging then return end
        orbDragging = true
        setInputSink(win, "orb", true)
        win._orbDragging = true
        orbGestureMoved = false
        orbSuppressClick = false
        orbHaveStart = false
        orbStartX, orbStartY = inputPoint(input)
        orbOriginX, orbOriginY = win._orbBaseX, win._orbBaseY
        local capsuleLive = win._capsuleActive and win._capsuleCurrent ~= nil
        if win._orbBlendTween then pcall(function() win._orbBlendTween:Cancel() end) win._orbBlendTween = nil end
        if not capsuleLive then
            if win._orbExtTween then pcall(function() win._orbExtTween:Cancel() end) win._orbExtTween = nil end
            win._orbExt.Value = 0
            win._orbBlend.Value = (win._orbSide == "left") and 0 or 1
        end
        applyOrbLayout(win)
        orbMoveConn = UserInputService.InputChanged:Connect(function(i)
            if not orbDragging then return end
            local t = i.UserInputType
            if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                local mx, my = inputPoint(i)
                if not orbHaveStart then orbStartX, orbStartY, orbHaveStart = mx, my, true end
                local dx, dy = mx - orbStartX, my - orbStartY
                if math.abs(dx) + math.abs(dy) > 4 then orbGestureMoved = true end
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
                local wasMoved = orbGestureMoved
                stopOrbDrag()
                orbSuppressClick = wasMoved
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
        if orbSuppressClick then orbSuppressClick = false return end
        if not orbGestureMoved then expand(win) end
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
                    for _, p in ipairs(win._colorPanels or {}) do showColorPanel(p, false) end
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
                    -- 自动储存已移除：此处不再触发 SaveConfig
                end
            elseif t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                listen.label.Text = KEY_PLACEHOLDER
                listen.ctrl._keybind = nil
                win._listening = nil
                refreshConflicts(win)
                -- 自动储存已移除：此处不再触发 SaveConfig
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
    noteTree(gui)
    local function revealMain()
        if revealed then return end
        revealed = true
        if gui and gui.Parent and win._main and win._main.Parent then
            win._main.Visible = true
            pcall(function() syncOrbBase(win) end)
            pcall(function() win:_fadeIn() end)
        end
    end

    if background and background:IsA("ImageLabel") and type(bgUrl) == "string" and bgUrl ~= "" and not bgDirect then
        local bgPath = AssetDir .. "/background.png"
        local bgUrlPath = AssetDir .. "/background.url"

        local function safeCall(fn, ...)
            local ok, r = pcall(fn, ...)
            if ok then return r end
            return nil
        end

        local function readBytes(path)
            if type(readfile) ~= "function" then return nil end
            if type(isfile) == "function" then
                local ok, isf = pcall(isfile, path)
                if not ok or not isf then return nil end
            end
            local data = safeCall(readfile, path)
            if type(data) ~= "string" or data == "" then return nil end
            return data
        end

        local function toAsset(path)
            local cands = {}
            if type(getcustomasset) == "function" then
                cands[#cands + 1] = path
                local rel = path:gsub("^%./", "")
                if rel ~= path then cands[#cands + 1] = rel end
            end
            for _, p in ipairs(cands) do
                local a = safeCall(getcustomasset, p)
                if type(a) == "string" and a ~= "" then
                    if not (a:match("^rbxasset") or a:match("^rbxthumb") or a:match("^http")) then
                        a = "rbxasset://" .. a
                    end
                    return a
                end
            end
            if type(getsynasset) == "function" then
                local a = safeCall(getsynasset, path)
                if type(a) == "string" and a ~= "" then return a end
            end
            if type(getcustomasset) == "function" then
                local a = safeCall(getcustomasset, "rbxasset://" .. path)
                if type(a) == "string" and a ~= "" then return a end
            end
            return nil
        end

        local cachedData = readBytes(bgPath)
        local cachedUrl = readBytes(bgUrlPath)
        if type(cachedUrl) == "string" then
            cachedUrl = cachedUrl:match("^[^\r\n]*") or ""
            cachedUrl = cachedUrl:gsub("^%s+", ""):gsub("%s+$", "")
        end
        local hasCache = type(cachedData) == "string" and #cachedData >= 64
        local linkMatches = (cachedUrl == nil) or (cachedUrl == "") or (cachedUrl == bgUrl)

        local applied = false
        if hasCache and linkMatches then
            local asset = toAsset(bgPath)
            if asset then
                background.Image = asset
                applied = true
                if cachedUrl ~= bgUrl then
                    safeCall(function()
                        makefolder(RootFolder)
                        makefolder(AssetDir)
                        writefile(bgUrlPath, bgUrl)
                    end)
                end
            end
        end

        revealMain()

        if not applied then
            local function pull()
                local data = nil
                local ok, r = pcall(function() return game:HttpGet(bgUrl) end)
                if ok and type(r) == "string" and #r > 0 then data = r end
                if data then
                    safeCall(function()
                        makefolder(RootFolder)
                        makefolder(AssetDir)
                        writefile(bgPath, data)
                        writefile(bgUrlPath, bgUrl)
                    end)
                    local asset = toAsset(bgPath)
                    if asset and background and background.Parent then
                        background.Image = asset
                        return
                    end
                end
                if hasCache then
                    local asset = toAsset(bgPath)
                    if asset and background and background.Parent then
                        background.Image = asset
                        return
                    end
                end
                if type(warn) == "function" then
                    pcall(warn, "[AsLab] background unavailable: " .. tostring(bgUrl))
                end
            end
            if type(task.defer) == "function" then
                task.defer(function() pcall(pull) end)
            else
                task.delay(0, function() pcall(pull) end)
            end
        end
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
    if self._fadeGroupTween then
        pcall(function() self._fadeGroupTween:Cancel() end)
        self._fadeGroupTween = nil
    end
    if self._fadePosTween then
        pcall(function() self._fadePosTween:Cancel() end)
        self._fadePosTween = nil
    end
    self._fadeGen = (self._fadeGen or 0) + 1
    local gen = self._fadeGen

    local main = self._main
    local scale = self._mainScale
    if not (main and main.Parent and scale and scale.Parent) then return end
    local targetScale = self._uiScale or 1

    local basePos = main.Position
    local baseY = basePos.Y.Offset
    self._entranceActive = true
    scale.Scale = targetScale * 0.88
    main.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, baseY + s(14))
    setGroupTransparency(main, 1, true)

    local twScale = TweenService:Create(scale,
        TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = targetScale })
    self._fadeTween = twScale
    twScale:Play()

    local twPos = TweenService:Create(main,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, baseY) })
    self._fadePosTween = twPos
    twPos:Play()

    self._fadeGroupTween = tweenGroup(main, 0,
        TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), nil, true)

    local finalize = function()
        if self._fadeGen ~= gen then return end
        self._entranceActive = false
        if scale and scale.Parent then scale.Scale = self._uiScale or 1 end
        if main and main.Parent then
            main.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, baseY)
            setGroupTransparency(main, 0, true)
        end
        if self._activeTab and self._activeTab > 0 and type(selectTab) == "function" then
            pcall(selectTab, self, self._activeTab)
        end
    end

    local conn
    local okConn = pcall(function()
        conn = twScale.Completed:Connect(function()
            if conn then pcall(function() conn:Disconnect() end) conn = nil end
            finalize()
        end)
    end)
    if not okConn then conn = nil end
    self._fadeDoneConn = conn

    task.delay(1.2, function()
        if conn then
            pcall(function() conn:Disconnect() end)
            conn = nil
        end
        finalize()
    end)
end

function Library:_finishFadeIn()
    self._fadeGen = (self._fadeGen or 0) + 1
    local wasEntrance = self._entranceActive
    self._entranceActive = false
    if self._fadeTween then
        pcall(function() self._fadeTween:Cancel() end)
        self._fadeTween = nil
    end
    if self._fadeGroupTween then
        pcall(function() self._fadeGroupTween:Cancel() end)
        self._fadeGroupTween = nil
    end
    if self._fadePosTween then
        pcall(function() self._fadePosTween:Cancel() end)
        self._fadePosTween = nil
    end
    if self._main and self._main.Parent and self._mainScale then
        self._mainScale.Scale = self._uiScale or 1
        if wasEntrance then
            setGroupTransparency(self._main, 0, true)
        end
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
    i18nText(self, tname, name)
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
    function tab:AddNotice(o) return addNotice(tab, o) end

    attachClickFx(row, { tint = Color3.new(1, 1, 1), peak = 0.68, radius = UDim.new(0, s(7)) })
    row.MouseButton1Click:Connect(function() selectTab(self, idx) end)

    table.insert(self._tabs, tab)
    updateCanvas(self)
    if #self._tabs == 1 then selectTab(self, 1) end
    return tab
end

--[[
    AddCustomTab：同样是一个选项卡 + 滑动容器，但除库内控件外，所有 UI 都可自定义创建。
    返回 tab 对象，除常规的 AddToggle/AddButton/AddNotice 外，额外暴露：
      tab.Container   —— 网格下方的自定义层（Frame），把任意自建 UI 以绝对坐标父于此即可
      tab:Refresh()   —— 重新计算滚动画布高度（父入自定义 UI 后调用）
]]
function Library:AddCustomTab(name, icon)
    local tab = self:AddTab(name, icon)

    local layer = Instance.new("Frame", tab._container)
    layer.Name = "CustomLayer"
    local customW = (self._controlW or self._sizeX) - PAD_IN * 2
    layer.Size = UDim2.fromOffset(customW, 0)
    layer.Position = UDim2.fromOffset(0, 0)
    layer.BackgroundTransparency = 1
    layer.BorderSizePixel = 0
    layer.ClipsDescendants = false
    setGroupTransparency(layer, 0)
    tab._customLayer = layer
    tab.Container = layer
    tab.ContainerWidth = customW

    function tab:Refresh()
        updateCanvas(self._win)
    end

    updateCanvas(self)
    return tab
end

return Library
