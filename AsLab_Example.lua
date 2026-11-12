--[[
    AsLab UI · 全 API 示例
    ------------------------------------------------------------
    覆盖内容：
      Library.PreloadLucide / GetHolderSource / CreateWindow
      Win:AddTab / ShowNotify / SetLanguage / GetLanguage / OnLanguageChanged
      多配置：SaveConfig(name) / LoadConfig(name) / GetConfigs / GetConfigName / GetConfigPath
              SetConfig / RenameConfig / DeleteConfig / ConfigExists
      Tab:AddToggle / AddButton
      Ctrl:AddSlider / AddToggle / AddButton / AddColorPicker / AddDropdown
      Ctrl:Set / SetValue，Dropdown:Get / GetOptions / SetOptions / AddOption / RemoveOption
      详情页内置：Board-Key（按键绑定）、AddShortcut（快捷图标创建 / 拖动 / 删除）
      配置持久化 ConfigKey、窗口设置（比例 / 语言）、关闭二次确认、通知胶囊
    说明：动态 Dropdown 与多配置 API 需要 AsLabUILibrary 2026-11 之后的版本。
]]

local Library = loadstring(game:HttpGet("https://ghfast.top/https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/AsLabUILibrary.lua"))()
Library.PreloadLucide()

-- ============================================================
-- 1. 创建窗口（演示 CreateWindow 的全部参数）
-- ============================================================
local Win = Library.CreateWindow({
    Title = "AsLab Full API",
    TitleIcon = "layout-grid",
    Info = "Every API in one place",
    Size = UDim2.fromOffset(560, 420),
    -- 背景图留空时使用库内置渐变；填写 URL 会下载到 AsLab/<Folder>/background.png
    Background = "https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/assets/aslab_wallpaper.png",
    -- 默认语言：不传为 English；传 "中文" 则首帧即中文
    Language = "English",
    -- 配置与背景落在 AsLab/FullDemo/ 下：background.png / config.json
    Folder = "FullDemo",
    -- 自定义标题的翻译表（库内置文案已自带中英）
    Translations = {
        ["中文"] = {
            ["Profile"] = "配置档案",
            ["Preset"] = "预设",
            ["Target"] = "目标",
            ["Player"] = "玩家",
            ["Tags"] = "标签",
            ["Tag"] = "标签项",
            ["Add Tag"] = "添加标签",
            ["Remove Tag"] = "移除标签",
            ["Reset Tags"] = "重置标签",
            ["Refresh Players"] = "刷新玩家",
            ["Boost"] = "加速",
            ["Speed"] = "速度",
            ["Jump Power"] = "跳跃力",
            ["Auto Jump"] = "自动跳跃",
            ["Reset Speed"] = "重置速度",
            ["Auto Save"] = "自动保存",
            ["Refresh"] = "刷新",
            ["Debug"] = "调试",
            ["Theme"] = "主题",
            ["Accent"] = "强调色",
            ["Blur"] = "模糊",
            ["Glow"] = "发光",
            ["Apply Theme"] = "应用主题",
            ["Reset Visuals"] = "重置外观",
            ["ESP"] = "透视",
            ["Highlight"] = "高亮",
            ["Skeleton"] = "骨架",
            ["Highlight Color"] = "高亮颜色",
            ["Distance"] = "距离",
            ["Performance"] = "性能",
            ["Cleanup"] = "清理",
            ["Reset Everything"] = "全部重置",
            ["Single"] = "单条通知",
            ["Stack"] = "堆叠通知",
            ["Long Text"] = "长文本",
            ["Auto Notify (1s)"] = "自动通知 (1秒)",
            ["Language"] = "语言",
            ["Config"] = "配置",
            ["Config Slot"] = "配置槽",
            ["Enabled"] = "启用",
            ["Save Config"] = "保存配置",
            ["New Config"] = "新建配置",
            ["Load Default"] = "加载默认",
            ["Rename Config"] = "重命名配置",
            ["Delete Config"] = "删除配置",
            ["List Configs"] = "列出全部",
            ["General"] = "通用",
            ["Visuals"] = "视觉",
            ["Dynamic"] = "动态",
            ["System"] = "系统",
            ["Notify"] = "通知",
        },
    },
})

-- 窗口对象提供的只读信息
print("[AsLab] holder =", Library.GetHolderSource(), "| language =", Win:GetLanguage())

-- ============================================================
-- 2. 标签页（图标使用 Lucide 名称）
-- ============================================================
local TabGeneral = Win:AddTab("General", "settings")
local TabVisual = Win:AddTab("Visuals", "palette")
local TabDynamic = Win:AddTab("Dynamic", "list-checks")
local TabSystem = Win:AddTab("System", "cpu")
local TabNotify = Win:AddTab("Notify", "bell")

-- ============================================================
-- 3. 通用页：主开关 + 详情页（Slider / Toggle / Button）
-- ============================================================
local PlayersSvc = game:GetService("Players")

local boostOn, boostSpeed, jumpPower = false, 50, 50

local function applyCharacter()
    local ok, lp = pcall(function() return PlayersSvc.LocalPlayer end)
    if not ok or not lp then return end
    local ok2, char = pcall(function() return lp.Character end)
    if not ok2 or not char then return end
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        hum.WalkSpeed = boostOn and boostSpeed or 16
        hum.JumpPower = jumpPower
    end)
end

pcall(function()
    PlayersSvc.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.2)
        applyCharacter()
    end)
end)

-- 带子选项的主开关：Callback、ConfigKey、Icon 齐全
local Boost = TabGeneral:AddToggle({
    Title = "Boost",
    Icon = "gauge",
    Default = false,
    ConfigKey = "boost_enabled",
    Callback = function(v)
        boostOn = v
        applyCharacter()
    end,
})

-- 子滑块：Min / Max / Default / Step / ConfigKey / Callback
local BoostSpeed = Boost:AddSlider({
    Title = "Speed", Min = 16, Max = 200, Default = 50, Step = 1,
    ConfigKey = "boost_speed",
    Callback = function(v)
        boostSpeed = v
        if boostOn then applyCharacter() end
    end,
})

Boost:AddSlider({
    Title = "Jump Power", Min = 50, Max = 300, Default = 50, Step = 5,
    Callback = function(v) jumpPower = v; applyCharacter() end,
})

local autoJumpOn = false

local AutoJump = Boost:AddToggle({
    Title = "Auto Jump", Default = false,
    Callback = function(v)
        autoJumpOn = v
        if not v then return end
        task.spawn(function()
            while autoJumpOn do
                pcall(function()
                    local hum = PlayersSvc.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Jump = true end
                end)
                task.wait(0.6)
            end
        end)
    end,
})

Boost:AddButton({
    Title = "Reset Speed",
    Callback = function()
        boostSpeed, jumpPower = 50, 50
        BoostSpeed:SetValue(50)          -- 子控件 SetValue
        print("[AsLab] boost reset")
    end,
})

TabGeneral:AddToggle({ Title = "Auto Save", Icon = "save", Default = true, ConfigKey = "auto_save" })
TabGeneral:AddToggle({ Title = "Debug", Icon = "bug", Default = false, ConfigKey = "debug",
    Callback = function(v) print("[AsLab] debug:", v) end })
TabGeneral:AddButton({ Title = "Refresh", Icon = "refresh-cw", Callback = function()
    Win:ShowNotify({ Title = "Refresh", Info = "Reloaded module list", Time = 3 })
end })

-- ============================================================
-- 4. 视觉页：ColorPicker / Slider / Toggle / Button 组合
-- ============================================================
local accent = Color3.fromRGB(120, 170, 255)

local Theme = TabVisual:AddToggle({ Title = "Theme", Icon = "brush", Default = false })

local Accent = Theme:AddColorPicker({
    Title = "Accent", Default = accent, ConfigKey = "accent",
    Callback = function(c) accent = c; print("[AsLab] accent", c) end,
})

Theme:AddSlider({ Title = "Blur", Min = 0, Max = 24, Default = 8, Step = 1, ConfigKey = "blur" })
Theme:AddToggle({ Title = "Glow", Default = true, ConfigKey = "glow" })
Theme:AddButton({ Title = "Apply Theme", Callback = function()
    Win:ShowNotify({ Title = "Theme", Info = "Accent applied to 12 controls", Time = 3 })
end })

TabVisual:AddButton({ Title = "Reset Visuals", Icon = "rotate-ccw", Callback = function()
    Accent:SetValue(Color3.fromRGB(120, 170, 255))   -- ColorPicker SetValue
end })

-- ============================================================
-- 5. 动态页：运行时增删 Dropdown 选项
-- ============================================================
-- 5.1 联动：Profile 改变时，Preset 的选项整体替换
local presetsByProfile = {
    Default = { "Balanced", "Performance", "Quality" },
    PvP = { "Aggressive", "Defensive", "Sniper", "Support" },
    Farming = { "AFK", "Loop", "Collect" },
}

local Profile, Preset

local ProfileToggle = TabDynamic:AddToggle({ Title = "Profile", Icon = "users", Default = false })

Preset = ProfileToggle:AddDropdown({
    Title = "Preset",
    Options = presetsByProfile.Default,
    Default = "Balanced",
    ConfigKey = "preset",
    Callback = function(v) print("[AsLab] preset ->", v) end,
})

Profile = ProfileToggle:AddDropdown({
    Title = "Profile",
    Options = { "Default", "PvP", "Farming" },
    Default = "Default",
    ConfigKey = "profile",
    Callback = function(v)
        -- SetOptions：整体替换选项列表；原先选中的值不存在时自动回落到第一项
        Preset:SetOptions(presetsByProfile[v] or presetsByProfile.Default)
        print("[AsLab] profile ->", v, "presets:", #Preset:GetOptions())
    end,
})

-- 5.2 玩家列表：从 Players 服务实时读取，进出房间自动同步
local TargetToggle = TabDynamic:AddToggle({ Title = "Target", Icon = "target", Default = false })

local PlayerDropdown = TargetToggle:AddDropdown({
    Title = "Player",
    Options = { "None" },
    Default = "None",
    Callback = function(v)
        if v ~= "None" then
            Win:ShowNotify({ Title = "Target", Info = "Locked on " .. v, Time = 2 })
        end
    end,
})

local function playerNames()
    local list = {}
    pcall(function()
        for _, plr in ipairs(PlayersSvc:GetPlayers()) do
            if plr ~= PlayersSvc.LocalPlayer then list[#list + 1] = plr.Name end
        end
    end)
    table.sort(list)
    if #list == 0 then list[1] = "None" end
    return list
end

local function refreshPlayers()
    local list = playerNames()
    PlayerDropdown:SetOptions(list)
    print("[AsLab] players refreshed:", table.concat(list, ", "))
end

refreshPlayers()
pcall(function()
    PlayersSvc.PlayerAdded:Connect(refreshPlayers)
    PlayersSvc.PlayerRemoving:Connect(refreshPlayers)
end)

-- 5.3 单条增删：AddOption / RemoveOption
local TagsToggle = TabDynamic:AddToggle({ Title = "Tags", Icon = "list-checks", Default = false })

local TagDropdown = TagsToggle:AddDropdown({
    Title = "Tag",
    Options = { "alpha", "beta" },
    Default = "alpha",
    Callback = function(v) print("[AsLab] tag ->", v) end,
})

local tagSeq = 2

TabDynamic:AddButton({ Title = "Add Tag", Icon = "plus", Callback = function()
    tagSeq = tagSeq + 1
    TagDropdown:AddOption("tag-" .. tagSeq)
    Win:ShowNotify({ Title = "AddOption", Info = "tag-" .. tagSeq .. " added · " .. #TagDropdown:GetOptions() .. " total", Time = 2 })
end })

TabDynamic:AddButton({ Title = "Remove Tag", Icon = "minus", Callback = function()
    local list = TagDropdown:GetOptions()
    if #list <= 1 then
        Win:ShowNotify({ Title = "RemoveOption", Info = "Keep at least one option", Time = 2 })
        return
    end
    local last = list[#list]
    TagDropdown:RemoveOption(last)
    Win:ShowNotify({ Title = "RemoveOption", Info = last .. " removed", Time = 2 })
end })

TabDynamic:AddButton({ Title = "Reset Tags", Icon = "rotate-ccw", Callback = function()
    TagDropdown:SetOptions({ "alpha", "beta" })
    tagSeq = 2
end })

TabDynamic:AddButton({ Title = "Refresh Players", Icon = "refresh-cw", Callback = refreshPlayers })

-- ============================================================
-- 6. 系统页：更多子控件 + 主开关批量 SetValue
-- ============================================================
local ESP = TabSystem:AddToggle({ Title = "ESP", Icon = "eye", Default = false, ConfigKey = "esp" })

local Highlight = ESP:AddToggle({ Title = "Highlight", Default = true, ConfigKey = "esp_highlight" })
local Skeleton = ESP:AddToggle({ Title = "Skeleton", Default = false, ConfigKey = "esp_skeleton" })

local ESPColor = ESP:AddColorPicker({
    Title = "Highlight Color", Default = Color3.fromRGB(255, 96, 96), ConfigKey = "esp_color",
    Callback = function(c) print("[AsLab] esp color", c) end,
})

ESP:AddSlider({ Title = "Distance", Min = 0, Max = 2000, Default = 1000, Step = 50, ConfigKey = "esp_distance" })

TabSystem:AddToggle({ Title = "Performance", Icon = "gauge", Default = false, ConfigKey = "performance" })

-- 主控件 SetValue：开关与子控件可以一起批量改
TabSystem:AddButton({ Title = "Reset Everything", Icon = "trash-2", Callback = function()
    ESP:SetValue(false)                 -- 主 Toggle
    Highlight:SetValue(true)            -- 子 Toggle
    Skeleton:SetValue(false)
    ESPColor:SetValue(Color3.fromRGB(255, 96, 96))
    Boost:SetValue(false)
    Profile:SetValue("Default")         -- Dropdown（会触发联动刷新 Preset）
    Win:ShowNotify({ Title = "Reset", Info = "All controls restored to defaults", Time = 3 })
end })

-- ============================================================
-- 7. 配置页：多配置槽（创建 / 另存 / 加载 / 列举 / 改名 / 删除）
-- ============================================================
local TabConfig = Win:AddTab("Config", "database")

local function hasConfig(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

local cfgSwitching = false
local ConfigDrop

local ConfigSlot = TabConfig:AddToggle({ Title = "Config Slot", Icon = "server", Default = false })

-- 下拉列出所有配置：GetConfigs 读取 AsLab/FullDemo/Configs/*.json
ConfigDrop = ConfigSlot:AddDropdown({
    Title = "Config",
    Options = Win:GetConfigs(),
    Default = Win:GetConfigName(),
    Callback = function(v)
        if cfgSwitching or v == Win:GetConfigName() then return end
        -- LoadConfig(name)：从指定配置读取并写回所有带 ConfigKey 的控件
        if Win:LoadConfig(v) then
            Win:ShowNotify({ Title = "Config", Info = "Loaded " .. v, Time = 2 })
        else
            Win:ShowNotify({ Title = "Config", Info = "Not found: " .. v, Time = 2 })
        end
    end,
})

-- 这两个控件带 ConfigKey：换配置槽后值会跟着变，用来肉眼确认「确实从另一个档读回来了」
local CfgSpeed = ConfigSlot:AddSlider({ Title = "Speed", Min = 0, Max = 100, Default = 50, Step = 1, ConfigKey = "cfg_speed" })
local CfgEnabled = ConfigSlot:AddToggle({ Title = "Enabled", Default = true, ConfigKey = "cfg_enabled" })

-- 把下拉的选项与选中项同步到库内的真实状态
local function syncConfigDrop(select)
    cfgSwitching = true
    local list = Win:GetConfigs()
    ConfigDrop:SetOptions(list)
    local want = select or Win:GetConfigName()
    if not hasConfig(list, want) then want = list[1] end
    ConfigDrop:Set(want)
    cfgSwitching = false
    return list
end

-- 保存到当前配置槽
TabConfig:AddButton({ Title = "Save Config", Icon = "save", Callback = function()
    Win:SaveConfig()
    Win:ShowNotify({ Title = "Saved", Info = Win:GetConfigName() .. " → " .. tostring(Win:GetConfigPath()), Time = 3 })
end })

-- 以当前控件状态另存为一个新配置，并切换过去
TabConfig:AddButton({ Title = "New Config", Icon = "file-pen", Callback = function()
    local list, name = Win:GetConfigs(), nil
    for i = 1, 99 do
        local cand = "Profile-" .. i
        if not hasConfig(list, cand) then name = cand break end
    end
    name = name or ("Profile-" .. tostring(os.time()))
    Win:SaveConfig(name)                 -- 传 name 即「另存为」，并把它设为当前槽
    local all = syncConfigDrop(name)
    Win:ShowNotify({ Title = "Created", Info = name .. " · " .. #all .. " configs", Time = 3 })
end })

-- 从默认配置读取并应用
TabConfig:AddButton({ Title = "Load Default", Icon = "rotate-ccw", Callback = function()
    if Win:LoadConfig("Default") then
        syncConfigDrop("Default")
        Win:ShowNotify({ Title = "Loaded", Info = "Default", Time = 2 })
    else
        Win:ShowNotify({ Title = "Config", Info = "Default 尚未保存过", Time = 2 })
    end
end })

-- 重命名当前配置（Default 不允许改名）
TabConfig:AddButton({ Title = "Rename Config", Icon = "pencil", Callback = function()
    local cur = Win:GetConfigName()
    local new = cur .. "-renamed"
    if Win:RenameConfig(cur, new) then
        syncConfigDrop(new)
        Win:ShowNotify({ Title = "Renamed", Info = cur .. " → " .. new, Time = 3 })
    else
        Win:ShowNotify({ Title = "Rename failed", Info = "Default 不能改名，或目标已存在", Time = 3 })
    end
end })

-- 删除当前配置（删完回落到 Default 并读回它的值）
TabConfig:AddButton({ Title = "Delete Config", Icon = "trash-2", Callback = function()
    local cur = Win:GetConfigName()
    if Win:DeleteConfig(cur) then
        Win:LoadConfig(Win:GetConfigName())
        syncConfigDrop()
        Win:ShowNotify({ Title = "Deleted", Info = cur .. " · back to " .. Win:GetConfigName(), Time = 3 })
    else
        Win:ShowNotify({ Title = "Delete failed", Info = "Default 不能删除", Time = 2 })
    end
end })

-- 遍历所有配置（GetConfigs 返回名称数组，Default 固定排第一）
ConfigSlot:AddButton({ Title = "List Configs", Icon = "list", Callback = function()
    local list = Win:GetConfigs()
    for i, n in ipairs(list) do
        print(string.format("[AsLab] config %d/%d: %s%s", i, #list, n, n == Win:GetConfigName() and "  <- active" or ""))
    end
    Win:ShowNotify({ Title = "Configs (" .. #list .. ")", Info = table.concat(list, ", "), Time = 4 })
end })

-- ============================================================
-- 8. 通知页：ShowNotify + 语言切换
-- ============================================================
TabNotify:AddButton({ Title = "Single", Icon = "bell", Callback = function()
    Win:ShowNotify({ Title = "Hello", Info = "A short toast.", Time = 4 })
end })

TabNotify:AddButton({ Title = "Stack", Icon = "layers", Callback = function()
    Win:ShowNotify({ Title = "First", Info = "Short one", Time = 3 })
    Win:ShowNotify({ Title = "Second", Info = "A longer notification body that wraps after twenty five characters per line", Time = 6 })
    Win:ShowNotify({ Title = "Third", Info = "Another one", Time = 8 })
end })

TabNotify:AddButton({ Title = "Long Text", Icon = "align-left", Callback = function()
    Win:ShowNotify({ Title = "Wrapped Title That Is Also Quite Long Indeed", Info = "The info line wraps automatically when it grows beyond twenty five characters, and the toast grows taller to fit.", Time = 7 })
end })

local autoNotifyOn, autoNotifyGen, autoSeq = false, 0, 0

TabNotify:AddToggle({ Title = "Auto Notify (1s)", Icon = "bell", Default = false, Callback = function(v)
    autoNotifyOn = v
    autoNotifyGen = autoNotifyGen + 1
    local gen = autoNotifyGen
    if not v then return end
    task.spawn(function()
        while autoNotifyOn and autoNotifyGen == gen do
            autoSeq = autoSeq + 1
            Win:ShowNotify({ Title = "Live #" .. autoSeq, Info = "Minimize to see the orb capsule", Time = 2 })
            task.wait(1)
        end
    end)
end })

local LangToggle = TabNotify:AddToggle({ Title = "Language", Icon = "globe", Default = false })
LangToggle:AddDropdown({
    Title = "Language",
    Options = { "English", "中文" },
    Default = "English",
    ConfigKey = "language",
    Callback = function(v) Win:SetLanguage(v) end,   -- 立即切换整套 UI 文案
})

-- 语言变化回调（外部同步自己的文案时使用）
Win:OnLanguageChanged(function(v)
    print("[AsLab] language changed ->", v)
end)

-- ============================================================
-- 9. 键盘：N 键弹通知；绑定键位请在任意控件详情页用 Board-Key
-- ============================================================
pcall(function()
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.N then
            Win:ShowNotify({ Title = "Key N", Info = "Minimize the window and press N again", Time = 5 })
        elseif input.KeyCode == Enum.KeyCode.L then
            Win:SetLanguage(Win:GetLanguage() == "English" and "中文" or "English")
        end
    end)
end)

-- ============================================================
-- 10. 读取配置（必须在所有控件建好之后调用）
--     不传名字：自动读回上次使用的配置槽（active.json 里记录）
-- ============================================================
if Win:LoadConfig() then
    print("[AsLab] loaded config:", Win:GetConfigName())
else
    Win:SaveConfig()                     -- 首次运行：把默认值落盘成 Default
end
syncConfigDrop()                          -- 让配置下拉与真实状态一致

print("AsLab full example ready · language =", Win:GetLanguage(), "· config =", Win:GetConfigName())
