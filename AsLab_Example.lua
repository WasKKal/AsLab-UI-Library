local Library = loadstring(game:HttpGet("https://ghfast.top/https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/AsLabUILibrary.lua"))()
Library.PreloadLucide() -- 检查Lucide图标状态或下载

-- 创建窗口
local Win = Library.CreateWindow({
    Title = "AsLab", --标题
    TitleIcon = "layout-grid", --标题图标
    Info = "ImInfoBar", --额外信息
    Size = UDim2.fromOffset(560, 420),-- 窗口大小
    -- 背景图留空时使用库内置渐变;填写 URL 会下载到 AsLab/<Folder>/background.png
    Background = "https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/assets/aslab_wallpaper.png",
    -- 默认语言 库默认English 传"中文"则首帧即中文
    Language = "English",
    -- 配置与背景在 AsLab/FullDemo/ 下 background.png / config.json
    Folder = "FullDemo",
    -- 自定义标题的翻译表 库内置文案已自带中英
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
            ["Filters"] = "筛选",
            ["Targets"] = "目标部位",
            ["Select All"] = "全选",
            ["Clear Targets"] = "清空目标",
            ["Only Head"] = "仅头部",
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
            ["TitleBar"] = "标题栏",
            ["ImInfoBar"] = "信息栏",
            ["Custom"] = "自定义",
            ["Notes"] = "备注",
            ["Update Note"] = "更新备注",
            ["Paragraph"] = "段落",
            ["Reloaded module list"] = "已重新加载模块列表",
            ["Accent applied to 12 controls"] = "强调色已应用到 12 个控件",
            ["Locked on"] = "已锁定",
            ["AddOption"] = "添加选项",
            ["RemoveOption"] = "移除选项",
            ["Keep at least one option"] = "至少保留一个选项",
            ["Reset"] = "重置",
            ["All controls restored to defaults"] = "所有控件已恢复默认",
            ["Loaded"] = "已加载",
            ["Not found:"] = "未找到:",
            ["Saved"] = "已保存",
            ["Created"] = "已创建",
            ["Renamed"] = "已重命名",
            ["Rename failed"] = "重命名失败",
            ["Deleted"] = "已删除",
            ["Delete failed"] = "删除失败",
            ["Configs"] = "配置列表",
            ["Hello"] = "你好",
            ["A short toast."] = "一条简短通知。",
            ["First"] = "第一条",
            ["Second"] = "第二条",
            ["Third"] = "第三条",
            ["Short one"] = "短通知",
            ["A longer notification body that wraps after twenty five characters per line"] = "这是一条较长的通知正文，超过每行字符上限后会自动换行显示",
            ["Another one"] = "再来一条",
            ["Wrapped Title That Is Also Quite Long Indeed"] = "这个标题同样很长会自动换行",
            ["The info line wraps automatically when it grows beyond twenty five characters, and the toast grows taller to fit."] = "信息行过长时会自动换行，通知框也会随之变高以容纳内容。",
            ["Live #"] = "实时 #",
            ["Minimize to see the orb capsule"] = "最小化后可看到悬浮球胶囊",
            ["Key N"] = "按键 N",
            ["Minimize the window and press N again"] = "最小化窗口后再按一次 N",
            ["Switch to"] = "切换到",
            ["added"] = "已添加",
            ["removed"] = "已移除",
            ["total"] = "共",
            ["configs"] = "个配置",
            ["back to"] = "返回",
            ["Time / FPS / Network"] = "时间 / 帧率 / 网络",
            ["Server / LocalPlayer"] = "服务器 / 本地玩家",
            ["Time:"] = "时间:",
            ["FPS:"] = "帧率:",
            ["Network:"] = "网络:",
            ["FPS 进度:"] = "帧率进度:",
        },
    },
})

print("[AsLab] holder =", Library.GetHolderSource(), "| language =", Win:GetLanguage())

-- 创建一些选项卡
local TabGeneral = Win:AddTab("General", "settings")
local TabVisual = Win:AddTab("Visuals", "palette")
local TabDynamic = Win:AddTab("Dynamic", "list-checks")
local TabSystem = Win:AddTab("System", "cpu")
local TabNotify = Win:AddTab("Notify", "bell")

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

-- 带子选项的主开关 Callback ConfigKey Icon 齐全
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
        BoostSpeed:SetValue(50)          -- 子控件 SetValue（Slider 值可动态改变）
        print("[AsLab] boost reset")
    end,
})

-- 段落控件 Title + Info + 可选 Icon 高度随文字自动变化
-- AddParagraph 返回对象支持：SetTitle / SetInfo / SetIcon / SetIconColor / SetBackColor / GetTitle / GetInfo
local Notes = TabGeneral:AddToggle({ Title = "Notes", Icon = "info", Default = false })
local NotePara
Notes:AddButton({ Title = "Update Note", Callback = function()
    -- 动态替换段落文本 控件会重新测量高度并排版
    NotePara:SetInfo("这是通过 Paragraph:SetInfo 动态更新的说明文本 —— 段落控件支持运行时替换文字，并自动重新计算高度与排版。")
    Win:ShowNotify({ Title = "Paragraph", Info = "SetInfo() 已更新", Time = 2 })
end })
NotePara = Notes:AddParagraph({
    Title = "提示",
    Info = "长按主开关打开详情页：可在此绑定快捷键、调整子滑块与开关，并查看本说明段落。段落高度会随文字长度自动变化。",
    Icon = "info",
})

TabGeneral:AddToggle({ Title = "Auto Save", Icon = "save", Default = true, ConfigKey = "auto_save" })
TabGeneral:AddToggle({ Title = "Debug", Icon = "bug", Default = false, ConfigKey = "debug",
    Callback = function(v) print("[AsLab] debug:", v) end })
TabGeneral:AddButton({ Title = "Refresh", Icon = "refresh-cw", Callback = function()
    Win:ShowNotify({ Title = "Refresh", Info = "Reloaded module list", Time = 3 })
end })

-- 视觉选项卡 ColorPicker / Slider / Toggle / Button 组合

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

-- 动态页 运行时增/删 Dropdown 选项
-- Profile 改变时 Preset 的选项整体替换
local presetsByProfile = {
    Default = { "Balanced", "Performance", "Quality" },
    PvP = { "Aggressive", "Defensive", "Sniper", "Support" },
    Farming = { "AFK", "Loop", "Collect" },
}

-- 多选下拉：加 Multi = true 即多选，不写仍是原来的单选（老代码无需改动）
-- 子控件在详情页里，长按 Filters 开关即可展开看到 Targets 与下面三个按钮
local FiltersToggle = TabDynamic:AddToggle({ Title = "Filters", Icon = "filter", Default = false })

local Targets = FiltersToggle:AddDropdown({
    Title = "Targets",
    Multi = true,                       -- 多选开关
    -- Default 可传数组，也可传 "Head,Torso" 字符串
    Options = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
    Default = { "Head", "Torso" },
    ConfigKey = "esp_targets",          -- 多选值以 JSON 数组存进配置
    Callback = function(list)
        -- 回调收到数组，且按 Options 顺序排列，不看点击先后
        if #list > 0 then
            print("[AsLab] targets ->", table.concat(list, ", "), "|", #list)
        else
            print("[AsLab] targets -> (none)")
        end
    end,
})

-- 多选的常用操作：全选 / 清空 / 单项开关
FiltersToggle:AddButton({ Title = "Select All", Icon = "check-square", Callback = function()
    Targets:Set(Targets:GetOptions())       -- Set 接受 table，也接受 "A,B" 字符串
    Win:ShowNotify({ Title = "Targets", Info = #Targets:Get() .. " / " .. #Targets:GetOptions(), Time = 2 })
end })

FiltersToggle:AddButton({ Title = "Clear Targets", Icon = "x", Callback = function()
    Targets:ClearSelection()                -- 清空后胶囊显示 None / 无
end })

FiltersToggle:AddButton({ Title = "Only Head", Icon = "crosshair", Callback = function()
    Targets:Select("Head", true)            -- 单项选中，第二个参数省略则为取反
    -- 查询单项：Targets:IsSelected("Head")
    print("[AsLab] head selected ->", Targets:IsSelected("Head"))
end })

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
        -- SetOptions 整体替换选项列表 原先选中的值不存在时自动选中第一项
        Preset:SetOptions(presetsByProfile[v] or presetsByProfile.Default)
        print("[AsLab] profile ->", v, "presets:", #Preset:GetOptions())
    end,
})

-- 玩家列表
local TargetToggle = TabDynamic:AddToggle({ Title = "Target", Icon = "target", Default = false })

local PlayerDropdown = TargetToggle:AddDropdown({
    Title = "Player",
    Options = { "None" },
    Default = "None",
    Callback = function(v)
        if v ~= "None" then
            Win:ShowNotify({ Title = "Target", Info = Win:Translate("Locked on") .. " " .. v, Time = 2 })
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

-- AddOption / RemoveOption
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
    Win:ShowNotify({ Title = "AddOption", Info = "tag-" .. tagSeq .. " " .. Win:Translate("added") .. " · " .. Win:Translate("total") .. " " .. #TagDropdown:GetOptions(), Time = 2 })
end })

TabDynamic:AddButton({ Title = "Remove Tag", Icon = "minus", Callback = function()
    local list = TagDropdown:GetOptions()
    if #list <= 1 then
        Win:ShowNotify({ Title = "RemoveOption", Info = "Keep at least one option", Time = 2 })
        return
    end
    local last = list[#list]
    TagDropdown:RemoveOption(last)
    Win:ShowNotify({ Title = "RemoveOption", Info = last .. " " .. Win:Translate("removed"), Time = 2 })
end })

TabDynamic:AddButton({ Title = "Reset Tags", Icon = "rotate-ccw", Callback = function()
    TagDropdown:SetOptions({ "alpha", "beta" })
    tagSeq = 2
end })

TabDynamic:AddButton({ Title = "Refresh Players", Icon = "refresh-cw", Callback = refreshPlayers })

local ESPPlayers = PlayersSvc
local ESPRun = game:GetService("RunService")
local ESPCamera = workspace and workspace.CurrentCamera
local ESPLocal = ESPPlayers.LocalPlayer

local espState = {
    on = false,
    highlight = true,
    skeleton = false,
    color = Color3.fromRGB(255, 96, 96),
    distance = 1000,
}
local hlCache, tagCache, skelCache = {}, {}, {}

local function espRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function espDist(p)
    local a = espRoot(p.Character)
    local b = ESPLocal and espRoot(ESPLocal.Character)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

local SKEL_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKEL_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}

local function getDrawing()
    local ok, d = pcall(function() return Drawing end)
    if ok and type(d) == "table" and d.new then return d end
    return nil
end

local function killSkeleton(p)
    local list = skelCache[p]
    if list then
        for _, line in ipairs(list) do pcall(function() line:Remove() end) end
        skelCache[p] = nil
    end
    if tagCache[p] then pcall(function() tagCache[p]:Destroy() end); tagCache[p] = nil end
end

local function clearPlayer(p)
    if hlCache[p] then pcall(function() hlCache[p]:Destroy() end); hlCache[p] = nil end
    killSkeleton(p)
end

local function clearAllESP()
    for p in pairs(hlCache) do clearPlayer(p) end
    for p in pairs(tagCache) do clearPlayer(p) end
    for p in pairs(skelCache) do clearPlayer(p) end
end

local function project(worldPos)
    if not ESPCamera then return nil end
    local ok, sp = pcall(function() return ESPCamera:WorldToViewportPoint(worldPos) end)
    if not ok or not sp or sp.Z <= 0 then return nil end
    return sp.X, sp.Y
end

local function applyPlayer(p)
    if not espState.on or p == ESPLocal then clearPlayer(p) return end
    local char = p.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") then clearPlayer(p) return end
    local inRange = espDist(p) <= espState.distance
    if espState.highlight and inRange then
        local hl = hlCache[p]
        if not hl then
            local ok, inst = pcall(Instance.new, "Highlight")
            if ok and inst then
                inst.Name = "AsLabESP"
                pcall(function() inst.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
                inst.FillTransparency = 0.72
                inst.OutlineTransparency = 0
                inst.Parent = workspace
                hlCache[p] = inst
                hl = inst
            end
        end
        if hl then
            pcall(function()
                hl.Adornee = char
                hl.FillColor = espState.color
                hl.OutlineColor = espState.color
                hl.Enabled = true
            end)
        end
    elseif hlCache[p] then
        pcall(function() hlCache[p]:Destroy() end); hlCache[p] = nil
    end
    if espState.skeleton and inRange then
        local DLib = getDrawing()
        if DLib then
            local bones = char:FindFirstChild("UpperTorso") and SKEL_R15 or SKEL_R6
            local list = skelCache[p]
            if not list then
                list = {}
                for i = 1, #bones do
                    local ok, line = pcall(DLib.new, "Line")
                    if ok and line then
                        line.Thickness = 1
                        line.Transparency = 1
                        list[i] = line
                    end
                end
                skelCache[p] = list
            end
            for i, pr in ipairs(bones) do
                local line = list[i]
                local a = char:FindFirstChild(pr[1])
                local b = char:FindFirstChild(pr[2])
                local x1, y1 = a and project(a.Position) or nil
                local x2, y2 = b and project(b.Position) or nil
                if line then
                    if x1 and x2 then
                        pcall(function()
                            line.From = Vector2.new(x1, y1)
                            line.To = Vector2.new(x2, y2)
                            line.Color = espState.color
                            line.Visible = true
                        end)
                    else
                        pcall(function() line.Visible = false end)
                    end
                end
            end
        else
            local head = char:FindFirstChild("Head") or espRoot(char)
            local gui = tagCache[p]
            if not gui and head then
                local ok, g = pcall(Instance.new, "BillboardGui")
                if ok and g then
                    g.Name = "AsLabESPTag"
                    g.Size = UDim2.fromOffset(180, 30)
                    g.StudsOffset = Vector3.new(0, 2.6, 0)
                    g.AlwaysOnTop = true
                    g.Parent = char
                    local lbl = Instance.new("TextLabel")
                    lbl.Parent = g
                    lbl.Name = "Tag"
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.TextScaled = true
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextStrokeTransparency = 0.4
                    tagCache[p] = g
                    gui = g
                end
            end
            if gui then
                pcall(function() gui.Adornee = head end)
                local lbl = gui:FindFirstChild("Tag")
                if lbl then
                    lbl.TextColor3 = espState.color
                    lbl.Text = string.format("%s  [%dm]", p.Name, math.floor(espDist(p)))
                end
            end
        end
    else
        killSkeleton(p)
    end
end

local function refreshESP()
    if not espState.on then clearAllESP() return end
    for _, p in ipairs(ESPPlayers:GetPlayers()) do
        if p ~= ESPLocal then pcall(applyPlayer, p) end
    end
end
local espAcc = 0
if ESPRun and ESPRun.Heartbeat then
    ESPRun.Heartbeat:Connect(function(dt)
        if not espState.on then return end
        espAcc = espAcc + (dt or 0)
        if espAcc < 0.12 then return end
        espAcc = 0
        refreshESP()
    end)
end
pcall(function()
    ESPPlayers.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.4)
            if espState.on then pcall(applyPlayer, p) end
        end)
    end)
    ESPPlayers.PlayerRemoving:Connect(function(p) clearPlayer(p) end)
end)
local ESP = TabSystem:AddToggle({ Title = "ESP", Icon = "eye", Default = false, ConfigKey = "esp",
    Callback = function(v)
        espState.on = v
        if v then task.defer(refreshESP) else clearAllESP() end
    end })

local Highlight = ESP:AddToggle({ Title = "Highlight", Default = true, ConfigKey = "esp_highlight",
    Callback = function(v) espState.highlight = v; if espState.on then refreshESP() end end })

local Skeleton = ESP:AddToggle({ Title = "Skeleton", Default = false, ConfigKey = "esp_skeleton",
    Callback = function(v) espState.skeleton = v; if espState.on then refreshESP() end end })

local ESPColor = ESP:AddColorPicker({
    Title = "Highlight Color", Default = Color3.fromRGB(255, 96, 96), ConfigKey = "esp_color",
    Callback = function(c) espState.color = c; if espState.on then refreshESP() end end,
})

ESP:AddSlider({ Title = "Distance", Min = 0, Max = 2000, Default = 1000, Step = 50, ConfigKey = "esp_distance",
    Callback = function(v) espState.distance = v; if espState.on then refreshESP() end end })

TabSystem:AddToggle({ Title = "Performance", Icon = "gauge", Default = false, ConfigKey = "performance" })

-- 主控件 SetValue 开关与子控件可以一起批量改
TabSystem:AddButton({ Title = "Reset Everything", Icon = "trash-2", Callback = function()
    ESP:SetValue(false)                 -- 主 Toggle
    Highlight:SetValue(true)            -- 子 Toggle
    Skeleton:SetValue(false)
    ESPColor:SetValue(Color3.fromRGB(255, 96, 96))
    Boost:SetValue(false)
    Profile:SetValue("Default")         -- Dropdown
    Win:ShowNotify({ Title = "Reset", Info = "All controls restored to defaults", Time = 3 })
end })

-- 配置相关 懒得写更多注释了
local TabConfig = Win:AddTab("Config", "database")

local function hasConfig(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

local cfgSwitching = false
local ConfigDrop

local ConfigSlot = TabConfig:AddToggle({ Title = "Config Slot", Icon = "server", Default = false })

-- GetConfigs 读取 AsLab/FullDemo/Configs/*.json
ConfigDrop = ConfigSlot:AddDropdown({
    Title = "Config",
    Options = Win:GetConfigs(),
    Default = Win:GetConfigName(),
    Callback = function(v)
        if cfgSwitching or v == Win:GetConfigName() then return end
        -- LoadConfig(name) 从指定配置读取并写回所有带 ConfigKey 的控件
        if Win:LoadConfig(v) then
            Win:ShowNotify({ Title = "Config", Info = Win:Translate("Loaded") .. " " .. v, Time = 2 })
        else
            Win:ShowNotify({ Title = "Config", Info = Win:Translate("Not found:") .. " " .. v, Time = 2 })
        end
    end,
})

-- 这两个控件带 ConfigKey 换配置槽后值会跟着变
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

-- 以当前控件状态另存为一个新配置 并切换过去
TabConfig:AddButton({ Title = "New Config", Icon = "file-pen", Callback = function()
    local list, name = Win:GetConfigs(), nil
    for i = 1, 99 do
        local cand = "Profile-" .. i
        if not hasConfig(list, cand) then name = cand break end
    end
    name = name or ("Profile-" .. tostring(os.time()))
    Win:SaveConfig(name)                 -- 传 name 即"另存为"  并把它设为当前选中项
    local all = syncConfigDrop(name)
    Win:ShowNotify({ Title = "Created", Info = name .. " · " .. #all .. " " .. Win:Translate("configs"), Time = 3 })
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

-- 重命名当前配置 Default 不允许改名
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

-- 删除当前配置 删完选中到 Default 并读回它的值
TabConfig:AddButton({ Title = "Delete Config", Icon = "trash-2", Callback = function()
    local cur = Win:GetConfigName()
    if Win:DeleteConfig(cur) then
        Win:LoadConfig(Win:GetConfigName())
        syncConfigDrop()
        Win:ShowNotify({ Title = "Deleted", Info = cur .. " · " .. Win:Translate("back to") .. " " .. Win:GetConfigName(), Time = 3 })
    else
        Win:ShowNotify({ Title = "Delete failed", Info = "Default 不能删除", Time = 2 })
    end
end })

-- 遍历所有配置 GetConfigs 返回名称数组 Default 固定排第一
ConfigSlot:AddButton({ Title = "List Configs", Icon = "list", Callback = function()
    local list = Win:GetConfigs()
    for i, n in ipairs(list) do
        print(string.format("[AsLab] config %d/%d: %s%s", i, #list, n, n == Win:GetConfigName() and "  <- active" or ""))
    end
    Win:ShowNotify({ Title = Win:Translate("Configs") .. " (" .. #list .. ")", Info = table.concat(list, ", "), Time = 4 })
end })

-- 通知相关演示
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
            Win:ShowNotify({ Title = Win:Translate("Live #") .. autoSeq, Info = "Minimize to see the orb capsule", Time = 2 })
            task.wait(1)
        end
    end)
end })

-- 语言切换
local LangButton
local function refreshLangTitle()
    local cur = Win:GetLanguage()
    local target = (cur == "English") and "中文" or "English"
    LangButton:SetTitle(Win:Translate("Language") .. ": " .. Win:Translate("Switch to") .. " " .. target)
end
LangButton = TabNotify:AddButton({
    Title = "Language",
    Icon = "globe",
    Callback = function()
        Win:SetLanguage(Win:GetLanguage() == "English" and "中文" or "English")  -- 立即切换整套 UI 文案
        refreshLangTitle()  -- 交互后用 SetTitle 更新按钮标题
    end,
})
refreshLangTitle()

-- 语言变化回调
Win:OnLanguageChanged(function(v)
    print("[AsLab] language changed ->", v)
    pcall(refreshLangTitle)   -- 语言变化后同步语言按钮标题
end)

-- 自定义选项卡AddCustomTab 库内控件 + 任意自定义 UI
-- 这是一个选项卡 也是一个滑动容器 除了库内置控件 还能在里面创建任意自定义 UI
local TabCustom = Win:AddCustomTab("Custom", "layout-customize")
local progFill, progLabel

-- 顶部 Notice占3格（一行） 介绍 AsLabUI 特点
TabCustom:AddNotice({
    Title = "AsLab UI 特点",
    Text = "轻量玻璃拟态 · 无头可测 · 长按主开关打开详情页 · 多配置槽持久化 · 动态下拉 · 通知胶囊 · 自定义选项卡。一套 API 覆盖脚本的全部界面需求。",
    Span = 3,
    Orientation = "Horizontal",
})

-- 下方左右两个区域的 Notice 栏 用自定义面板实现，各占一半宽度
local areaW = TabCustom.ContainerWidth or TabCustom.Container.Size.X.Offset
if not areaW or areaW <= 0 then areaW = (Win._controlW or 536) - 24 end
local uGap = 12
local halfW = math.max(120, math.floor((areaW - uGap) / 2))
local barH = 150

-- 复刻库内玻璃观感的面板 库外代码也可自建 UI
local function glassPanel(parent, x, y, w, h, titleKey)
    local f = Instance.new("Frame")
    f.Parent = parent
    f.Name = "CustomPanel"
    f.Size = UDim2.fromOffset(w, h)
    f.Position = UDim2.fromOffset(x, y)
    f.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
    f.BackgroundTransparency = 0.62
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    local corner = Instance.new("UICorner")
    corner.Parent = f
    corner.CornerRadius = UDim.new(0, 16)
    local grad = Instance.new("UIGradient")
    grad.Parent = f
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 43, 54)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 28, 36)),
    })
    local stroke = Instance.new("UIStroke")
    stroke.Parent = f
    stroke.Color = Color3.fromRGB(80, 86, 110)
    stroke.Transparency = 0.55
    stroke.Thickness = 1
    local t = Instance.new("TextLabel")
    t.Parent = f
    t.Size = UDim2.fromOffset(w - 28, 40)
    t.Position = UDim2.fromOffset(14, 10)
    t.BackgroundTransparency = 1
    t.Text = Win:Translate(titleKey or "")
    t.TextSize = 15
    t.TextColor3 = Color3.fromRGB(235, 238, 248)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Top
    t.RichText = false
    t.TextWrapped = true
    return f, t
end

local function statLine(parent, x, y, w, text)
    local t = Instance.new("TextLabel")
    t.Parent = parent
    t.Size = UDim2.fromOffset(w, 20)
    t.Position = UDim2.fromOffset(x, y)
    t.BackgroundTransparency = 1
    t.Text = text or ""
    t.TextSize = 13
    t.TextColor3 = Color3.fromRGB(150, 158, 185)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Top
    t.RichText = false
    t.TextWrapped = false
    return t
end

-- 左栏 Time / FPS / Network
local leftBar, leftTitle = glassPanel(TabCustom.Container, 0, 0, halfW, barH, "Time / FPS / Network")
local lTime = statLine(leftBar, 14, 58, halfW - 28, Win:Translate("Time:") .. "    --")
local lFps = statLine(leftBar, 14, 82, halfW - 28, Win:Translate("FPS:") .. "     --")
local lNet = statLine(leftBar, 14, 106, halfW - 28, Win:Translate("Network:") .. " --")

-- 右栏 在线玩家 / 本地玩家 / 角色状态
local rightBar, rightTitle = glassPanel(TabCustom.Container, halfW + uGap, 0, halfW, barH, "Server / LocalPlayer")
local rPlayers = statLine(rightBar, 14, 58, halfW - 28, "在线玩家: --")
local rName = statLine(rightBar, 14, 82, halfW - 28, "本地玩家: --")
local rChar = statLine(rightBar, 14, 106, halfW - 28, "角色状态: --")

-- 实时读取数据
local function readStats()
    local d = { time = "--", fps = "--", net = "--", players = "--", name = "--", char = "--" }
    pcall(function()
        d.time = os and os.date and os.date("%H:%M:%S") or tostring(math.floor(tick()))
    end)
    pcall(function()
        local stats = game:GetService("Stats")
        local fr = stats and stats:FindFirstChild("FrameRate")
        if fr then d.fps = tostring(math.floor((fr.Value or 0) + 0.5)) end
        local net = stats and stats:FindFirstChild("Network")
        local item = net and net:FindFirstChild("ServerStatsItem")
        if item then
            local rx = item:GetAttribute("Data Receive Rate (KB/s)")
            if rx ~= nil then d.net = tostring(rx) .. " KB/s" end
        end
    end)
    pcall(function()
        local ps = game:GetService("Players")
        d.players = tostring(#ps:GetPlayers())
        local lp = ps.LocalPlayer
        if lp then
            d.name = lp.Name
            local char = lp.Character
            d.char = (char and char:FindFirstChildOfClass("Humanoid")) and "已生成" or "未生成"
        end
    end)
    return d
end

local function refreshStats()
    local ok, d = pcall(readStats)
    if not ok or not d then return end
    pcall(function()
        lTime.Text = Win:Translate("Time:") .. "    " .. d.time
        lFps.Text = Win:Translate("FPS:") .. "     " .. d.fps
        lNet.Text = Win:Translate("Network:") .. " " .. d.net
        rPlayers.Text = "在线玩家: " .. d.players
        rName.Text = "本地玩家: " .. d.name
        rChar.Text = "角色状态: " .. d.char
        local fpsN = tonumber(d.fps) or 0
        progFill.Size = UDim2.new(math.clamp(fpsN / 120, 0, 1), 0, 1, 0)
        progLabel.Text = Win:Translate("FPS 进度:") .. " " .. d.fps
    end)
end

-- 下方再添加一些自定义 UI 自定义按钮与自定义进度条
local uiY = barH + 18
local custBtn = Instance.new("TextButton")
custBtn.Parent = TabCustom.Container
custBtn.Name = "CustomButton"
custBtn.Size = UDim2.fromOffset(halfW, 40)
custBtn.Position = UDim2.fromOffset(0, uiY)
custBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
custBtn.BackgroundTransparency = 0.15
custBtn.BorderSizePixel = 0
custBtn.AutoButtonColor = false
custBtn.Text = "点击切换 (自定义界面)"
custBtn.TextSize = 14
custBtn.TextColor3 = Color3.fromRGB(240, 244, 255)
custBtn.RichText = false
local custBtnCorner = Instance.new("UICorner")
custBtnCorner.Parent = custBtn
custBtnCorner.CornerRadius = UDim.new(0, 10)
local custOn = false
custBtn.MouseButton1Click:Connect(function()
    custOn = not custOn
    custBtn.BackgroundColor3 = custOn and Color3.fromRGB(120, 200, 140) or Color3.fromRGB(70, 130, 255)
    custBtn.Text = custOn and "已开启 (自定义界面)" or "点击切换 (自定义界面)"
end)

local progTrack = Instance.new("Frame")
progTrack.Parent = TabCustom.Container
progTrack.Name = "CustomProgress"
progTrack.Size = UDim2.fromOffset(halfW, 40)
progTrack.Position = UDim2.fromOffset(halfW + uGap, uiY)
progTrack.BackgroundColor3 = Color3.fromRGB(40, 43, 54)
progTrack.BackgroundTransparency = 0.5
progTrack.BorderSizePixel = 0
local progCorner = Instance.new("UICorner")
progCorner.Parent = progTrack
progCorner.CornerRadius = UDim.new(0, 8)
progFill = Instance.new("Frame")
progFill.Parent = progTrack
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.BackgroundColor3 = Color3.fromRGB(120, 200, 140)
progFill.BorderSizePixel = 0
local pfCorner = Instance.new("UICorner")
pfCorner.Parent = progFill
pfCorner.CornerRadius = UDim.new(0, 8)
progLabel = Instance.new("TextLabel")
progLabel.Parent = progTrack
progLabel.Size = UDim2.fromScale(1, 1)
progLabel.BackgroundTransparency = 1
progLabel.Text = Win:Translate("FPS 进度:") .. " --"
progLabel.TextSize = 13
progLabel.TextColor3 = Color3.fromRGB(235, 238, 248)
progLabel.RichText = false

-- 自定义选项卡 父入自定义 UI 后刷新滚动画布高度
TabCustom:Refresh()
refreshStats()
pcall(function()
    task.spawn(function()
        while true do
            pcall(refreshStats)
            task.wait(1)
        end
    end)
end)

-- N 键弹通知 绑定键位请在任意控件详情页用 Board-Key
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

syncConfigDrop()                          -- 初始化示例自己的配置下拉展示

print("AsLab full example ready · language =", Win:GetLanguage(), "· config =", Win:GetConfigName())

-- 语言切换 库内控件 / Tab / 窗口标题 / 通知 / ShortCut 已由库自动 i18n
-- 这里同步示例自己创建的自定义 UI 文案与语言按钮标题
Win:OnLanguageChanged(function()
    pcall(refreshLangTitle)
    if leftTitle and leftTitle.Parent then leftTitle.Text = Win:Translate("Time / FPS / Network") end
    if rightTitle and rightTitle.Parent then rightTitle.Text = Win:Translate("Server / LocalPlayer") end
    pcall(refreshStats)
end)
