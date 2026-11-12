local Library = loadstring(game:HttpGet("https://ghfast.top/https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/AsLabUILibrary.lua"))()
Library.PreloadLucide()

local Win = Library.CreateWindow({
    Title = "Im Title",
    TitleIcon = "layout-grid",
    Size = UDim2.fromOffset(540, 400),
    Info = "Info Bar",
    -- 默认语言：不传 Language 时库内默认 English；传入 "中文" 即默认中文。
    Language = "English",
    Background = "https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/assets/aslab_wallpaper.png",
    -- Folder 签名：在根目录 AsLab 下创建名为 Example 的子文件夹。
    -- 背景图与配置都存放于 AsLab/Example/ ：
    --   AsLab/Example/background.png
    --   AsLab/Example/config.json
    Folder = "Example",
    -- 允许外部为「库内置文本」之外的自定义控件标题注入翻译条目。
    -- 例如把示例中的 "Auto Save" 在中文下显示为「自动保存」。
    Translations = {
        ["中文"] = {
            ["Auto Save"] = "自动保存",
            ["Refresh"] = "刷新",
            ["Notifications"] = "通知",
            ["Run"] = "运行",
            ["Debug"] = "调试",
            ["Boost"] = "加速",
            ["Speed"] = "速度",
            ["Dark Mode"] = "深色模式",
            ["Theme"] = "主题",
            ["Reset"] = "重置",
            ["Performance"] = "性能",
            ["Cleanup"] = "清理",
            ["About"] = "关于",
            ["ESP"] = "透视",
            ["Highlight"] = "高亮",
            ["Highlight Color"] = "高亮颜色",
            ["Draw Skeleton"] = "绘制骨架",
            ["Language"] = "语言",
            ["General"] = "通用",
            ["Appearance"] = "外观",
            ["System"] = "系统",
            ["Notify"] = "通知中心",
            ["Auto Notify (1s)"] = "自动通知 (1秒)",
            ["Single"] = "单条",
            ["Stack"] = "堆叠",
            ["Long Text"] = "长文本",
        },
    },
})

local TabGeneral = Win:AddTab("General", "settings")
local TabVisual = Win:AddTab("Appearance", "palette")
local TabSystem = Win:AddTab("System", "cpu")

TabGeneral:AddToggle({ Title = "Auto Save", Icon = "save", Default = true, ConfigKey = "auto_save", Callback = function(v)
    print("Auto Save:", v)
end })

TabGeneral:AddButton({ Title = "Refresh", Icon = "refresh-cw", Callback = function()
    print("Refreshed")
end })

TabGeneral:AddToggle({ Title = "Notifications", Icon = "bell", Default = false, Callback = function(v)
    print("Notifications:", v)
end })

TabGeneral:AddButton({ Title = "Run", Callback = function()
    print("Run button clicked")
end })

TabGeneral:AddToggle({ Title = "Debug", Default = false, Callback = function(v)
    print("Debug:", v)
end })

-- ===== Boost：实际修改本地角色移动速度 =====
local PlayersSvc = game:GetService("Players")
local lp = PlayersSvc.LocalPlayer

local boostOn = false
local boostSpeed = 50  -- 由下方 Speed 滑块实时控制

local function getHumanoid()
    if not lp then return nil end
    local ok, char = pcall(function() return lp.Character end)
    if not ok or not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function applyBoost()
    local hum = getHumanoid()
    if not hum then return end
    pcall(function() hum.WalkSpeed = boostOn and boostSpeed or 16 end)
end

if lp then
    lp.CharacterAdded:Connect(function()
        task.wait(0.1)
        applyBoost()
    end)
end

local Boost = TabGeneral:AddToggle({ Title = "Boost", Icon = "gauge", Default = false, Callback = function(v)
    boostOn = v
    applyBoost()
end })

local BoostSpeed = Boost:AddSlider({ Title = "Speed", Min = 16, Max = 200, Default = 50, Step = 1, ConfigKey = "boost_speed", Callback = function(v)
    boostSpeed = v
    if boostOn then applyBoost() end
end })

TabVisual:AddToggle({ Title = "Dark Mode", Icon = "moon", Default = true, Callback = function(v)
    print("Dark Mode:", v)
end })

TabVisual:AddButton({ Title = "Theme", Icon = "brush", Callback = function()
    print("Opening theme")
end })

TabVisual:AddButton({ Title = "Reset", Icon = "rotate-ccw", Callback = function()
    print("Appearance reset")
end })

TabSystem:AddToggle({ Title = "Performance", Icon = "gauge", Default = false, Callback = function(v)
    print("Performance:", v)
end })

TabSystem:AddButton({ Title = "Cleanup", Icon = "trash-2", Callback = function()
    print("Cleaned up")
end })

TabSystem:AddButton({ Title = "About", Icon = "help-circle", Callback = function()
    print("About AsLab UI")
end })

-- ===== ESP：为所有玩家角色添加 Highlight 实际高亮 =====
local espOn = false
local espHighlightOn = true
local espSkeleton = false
local espColor = Color3.fromRGB(255, 96, 96)
local espHighlights = {}

local function clearEsp()
    for plr, hl in pairs(espHighlights) do pcall(function() hl:Destroy() end) end
    espHighlights = {}
end

local function refreshEspVisual()
    for plr, hl in pairs(espHighlights) do
        pcall(function()
            hl.FillColor = espColor
            hl.OutlineColor = espColor
            hl.Enabled = espHighlightOn
            hl.FillTransparency = espSkeleton and 0.5 or 1
            hl.OutlineTransparency = 0
        end)
    end
end

local function addEspFor(plr)
    if not plr or plr == lp then return end
    if espHighlights[plr] then return end
    local function attach()
        local char = plr.Character
        if not char then return end
        local hl = Instance.new("Highlight")
        hl.Name = "AsLabESP"
        hl.FillColor = espColor
        hl.OutlineColor = espColor
        hl.FillTransparency = espSkeleton and 0.5 or 1
        hl.OutlineTransparency = 0
        hl.Enabled = espHighlightOn
        hl.Adornee = char
        hl.Parent = char
        espHighlights[plr] = hl
    end
    pcall(attach)
    pcall(function()
        plr.CharacterAdded:Connect(function(c)
            task.wait(0.1)
            if espOn then
                pcall(function()
                    local hl = Instance.new("Highlight")
                    hl.Name = "AsLabESP"
                    hl.FillColor = espColor; hl.OutlineColor = espColor
                    hl.FillTransparency = espSkeleton and 0.5 or 1
                    hl.OutlineTransparency = 0; hl.Enabled = espHighlightOn
                    hl.Adornee = c; hl.Parent = c
                    espHighlights[plr] = hl
                end)
            end
        end)
    end)
end

local function buildEsp()
    clearEsp()
    if not espOn then return end
    local ok, list = pcall(function() return PlayersSvc:GetPlayers() end)
    if ok and list then for _, plr in ipairs(list) do addEspFor(plr) end end
end

pcall(function()
    PlayersSvc.PlayerAdded:Connect(function(plr)
        if espOn then addEspFor(plr) end
    end)
    PlayersSvc.PlayerRemoving:Connect(function(plr)
        if espHighlights[plr] then pcall(function() espHighlights[plr]:Destroy() end) espHighlights[plr] = nil end
    end)
end)

local ESP = TabSystem:AddToggle({ Title = "ESP", Icon = "eye", Default = false, Callback = function(v)
    espOn = v
    if v then buildEsp() else clearEsp() end
end })

ESP:AddToggle({ Title = "Highlight", Default = true, ConfigKey = "esp_highlight", Callback = function(v)
    espHighlightOn = v
    refreshEspVisual()
end })

local ESPColor = ESP:AddColorPicker({ Title = "Highlight Color", Default = Color3.fromRGB(255, 96, 96), ConfigKey = "esp_color", Callback = function(c)
    espColor = c
    refreshEspVisual()
end })

ESP:AddToggle({ Title = "Draw Skeleton", Default = false, Callback = function(v)
    espSkeleton = v
    refreshEspVisual()
end })

-- ===== 新增 Dropdown 子控件：用于控制语言 =====
Win:OnLanguageChanged(function(v)
    print("[Settings] Language applied:", v)
end)

local LangSetting = TabVisual:AddToggle({ Title = "Language", Icon = "globe", Default = false })
local LangDropdown = LangSetting:AddDropdown({
    Title = "Language",
    -- 语言下拉仅包含 English 与 中文
    Options = { "English", "中文" },
    Default = "English",
    ConfigKey = "language",
    Callback = function(v)
        print("Language selected:", v)
        Win:SetLanguage(v)
    end,
})

local TabNotify = Win:AddTab("Notify", "bell")

local autoNotifyOn = false
local autoNotifyGen = 0
local autoNotifySeq = 0

TabNotify:AddToggle({ Title = "Auto Notify (1s)", Icon = "bell", Default = false, Callback = function(v)
    autoNotifyOn = v
    autoNotifyGen = autoNotifyGen + 1
    local myGen = autoNotifyGen
    if not v then return end
    task.spawn(function()
        while autoNotifyOn and autoNotifyGen == myGen do
            autoNotifySeq = autoNotifySeq + 1
            Win:ShowNotify({
                Title = "Live #" .. autoNotifySeq,
                Info = "Auto #" .. autoNotifySeq .. " every 1s - minimize to see the capsule",
                Time = 2,
            })
            task.wait(1)
        end
    end)
end })

TabNotify:AddButton({ Title = "Single", Icon = "bell", Callback = function()
    Win:ShowNotify({ Title = "Hello", Info = "This is a short message.", Time = 4 })
end })

TabNotify:AddButton({ Title = "Stack", Icon = "layers", Callback = function()
    Win:ShowNotify({ Title = "First", Info = "Short one", Time = 3 })
    Win:ShowNotify({ Title = "Second", Info = "A longer notification body that wraps after twenty five characters per line", Time = 6 })
    Win:ShowNotify({ Title = "Third", Info = "Another one", Time = 8 })
end })

TabNotify:AddButton({ Title = "Long Text", Icon = "align-left", Callback = function()
    Win:ShowNotify({ Title = "Wrapped Title That Is Also Quite Long Indeed", Info = "The info line wraps automatically when it grows beyond twenty five characters, and the toast grows taller to fit.", Time = 7 })
end })

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.N then
        Win:ShowNotify({ Title = "Key N", Info = "Minimize the window and press N to see the orb capsule", Time = 5 })
    end
end)

-- 演示配置持久化：读取 AsLab/Example/config.json
-- 除带 ConfigKey 的控件外，快捷键（Board-Key）与快捷图标的位置/开关状态也会一并保存与恢复
-- 快捷键设置、清除以及快捷图标的创建/删除/拖拽会立即写盘；控件值在 Settings 里点 Apply 时写盘
-- 启动时只调用 LoadConfig（先 SaveConfig 会用默认值覆盖上次保存的内容）
Win:LoadConfig()

-- ===== SetValue 演示（默认不自动执行，避免覆盖你自己保存的配置）=====
-- Slider / Dropdown / ColorPicker / Toggle（主控件与子控件）都支持 SetValue / Set：
--   BoostSpeed:SetValue(80)                              -- 子滑块
--   LangDropdown:SetValue("中文")                        -- 子下拉（会触发 Callback -> 切语言）
--   ESPColor:SetValue(Color3.fromRGB(255, 170, 60))      -- 子取色器
--   ESP:SetValue(true)                                   -- 主开关
--   tg:SetValue(false)                                   -- 子开关
-- 赋值会触发对应 Callback，并同步写入 config.json。

print("AsLab UI loaded, window fading in...")

-- 语言切换示例（外部也可主动调用）：
-- Win:SetLanguage("中文")
-- Win:GetLanguage() --> "English" / "中文"
