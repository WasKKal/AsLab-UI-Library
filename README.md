# AsLab-UI-Library

<p align="center">
  <img src="https://img.shields.io/badge/Roblox-Luau-00a2ff?style=for-the-badge&logo=roblox" alt="Roblox Luau" />
  <img src="https://img.shields.io/badge/Style-ImGui%20%2B%20Apple-000000?style=for-the-badge" alt="ImGui + Apple Style" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License" />
</p>

> 一个单文件 Roblox UI 库，借鉴 **ImGui** 的即时模式理念与 **Apple** 的视觉风格，用最少的代码搭建面板、设置页与调试工具。声明式 API、玻璃拟态外观、配置持久化、多语言与运行时动态更新开箱即用。

---

## ✨ 特性

- 🎛️ **即时模式 API**：以声明式 / 命令式混合方式堆叠控件，无需手动维护冗长的对象层级。
- 🍎 **Apple 风格视觉**：圆角、毛玻璃质感、系统级排版与配色，开箱即用的高级观感。
- 🧩 **丰富控件**：窗口、标签页、开关、按钮、滑块、下拉框、取色器、文本段落、展示块一应俱全。
- ✏️ **运行时可变**：`SetTitle` / `GetTitle` 改标题，`Slider:SetValue` 改数值，`Dropdown:SetOptions` 改选项，全部即时生效并同步配置。
- 🪟 **多窗口与多配置槽**：支持重复加载自动重建、配置分槽保存 / 另存 / 加载 / 改名 / 删除。
- 📂 **配置管理器**：底部 `folder-cog` 按钮唤出独立面板，用居中大下拉切换配置，底部「删除 / 保存 / 载入」三按钮显式管理（配色：删除=红黑渐变，保存/载入=银白渐变）。
- 🛡️ **触摸穿透防护**：拖动窗口、悬浮球、快捷图标或打开设置页时自动启用输入盾，避免视角被误拖动。
- 🧱 **混合布局**：`Notice` 展示块支持 1~3 格横向跨列 / 竖向不限行；`AddCustomTab` 允许在滑动选项卡内自由创建任意自定义 UI。
- 🌐 **多语言**：内置中英文案，支持自定义翻译表与运行时 `SetLanguage`。

## 📦 安装

将 `AsLabUILibrary.lua` 放入项目，通过执行环境加载：

```lua
local Library = loadstring(game:HttpGet("你的资源地址/AsLabUILibrary.lua"))()
Library.PreloadLucide()   -- 预置 Lucide 图标
```

> 也可直接将库文件拷贝到本地模块目录后 `require`。

## 🚀 快速开始

```lua
local Library = loadstring(...)()

local Window = Library.CreateWindow({
    Title = "TitleBar",                 -- 窗口标题
    Info = "ImInfoBar",                 -- 标题下方说明
    TitleIcon = "layout-grid",          -- Lucide 图标名
    Size = UDim2.fromOffset(560, 420),
    Language = "English",               -- 默认语言
    Folder = "FullDemo",                -- 配置与资源目录
})

local Tab = Window:AddTab("设置", "settings")

-- 主控件用 Title
Tab:AddToggle({ Title = "启用功能", Default = true, Callback = function(v) print("开关:", v) end })
Tab:AddButton({ Title = "应用", Callback = function() print("已应用") end })

-- 运行时改标题
local B = Tab:AddButton({ Title = "Switch to 中文" })
B:SetTitle("Switch to English")

-- 子选项需挂在某主控件上：长按主开关进入详情页即可看到
local Feature = Tab:AddToggle({ Title = "音效", Default = true })
local Vol = Feature:AddSlider({ Title = "音量", Min = 0, Max = 100, Default = 50 })
Vol:SetValue(80)   -- 运行时动态改变滑块值（自动 clamp 到 0~100）
```

## 🗂️ 控件一览

**主层级（Tab 上直接添加）**

| 方法 | 说明 |
| --- | --- |
| `Win:AddTab(name, icon)` | 添加标签页 |
| `Win:AddCustomTab(name, icon)` | 添加「自定义选项卡」——同样是选项卡 + 滑动容器，但可自由创建任意 UI（见下文） |
| `Tab:AddToggle(opts)` | 主开关（可长按进入详情页） |
| `Tab:AddButton(opts)` | 主按钮 |
| `Tab:AddNotice(opts)` | 展示型 Notice：外观与主控件一致，但**不可点击**、仅显示信息 |

**子选项（长按主开关进入详情页后添加，挂在某个 `Ctrl` 上）**

| 方法 | 说明 |
| --- | --- |
| `Ctrl:AddSlider(opts)` | 滑块 —— `.Set(v)` / `.SetValue(v)` 可在运行时动态改变数值（自动 clamp） |
| `Ctrl:AddToggle(opts)` | 子开关 |
| `Ctrl:AddButton(opts)` | 子按钮 |
| `Ctrl:AddColorPicker(opts)` | 取色器 |
| `Ctrl:AddDropdown(opts)` | 下拉选择（`Multi = true` 可多选；支持 `SetOptions` / `AddOption` / `RemoveOption` 动态增删） |
| `Ctrl:AddParagraph(opts)` | 文本段落（标题 + 说明 + 可选图标，高度随文字自动变化） |

**通用方法（主控件与子选项均支持）**

| 方法 | 说明 |
| --- | --- |
| `Ctrl:SetTitle(text)` | 运行时改变标题，返回控件自身，便于链式调用 |
| `Ctrl:GetTitle()` | 读回当前标题 |

### ✅ 多选下拉 `Multi = true`

```lua
local targets = host:AddDropdown({
    Title = "Targets",
    Multi = true,                          -- 开启多选
    Options = { "Head", "Torso", "Left Arm", "Right Arm" },
    Default = { "Head", "Torso" },         -- 数组；写成 "Head,Torso" 也可
    ConfigKey = "esp_targets",
    Callback = function(list)              -- 收到数组，顺序与 Options 一致
        print(table.concat(list, ", "))
    end,
})

targets:Get()                -- { "Head", "Torso" }
targets:Set({ "Left Arm" })  -- 覆盖选中
targets:Set("Head,Torso")    -- 逗号串同样接受
targets:Select("Right Arm")  -- 增/删单项（第二参数可显式 true / false）
targets:IsSelected("Head")   -- true
targets:ClearSelection()     -- 清空
```

行为说明：

- **胶囊文案**：≤ 3 项显示 `A, B, C`；超过折叠为 `A, B, C and N more`（中文「等 N 项」）；空选择显示 `None` /「无」。切换语言会自动重算。
- **菜单**：所有选项常驻显示，选中项为银白底 + 深色文字 + 右侧对勾；**点选不收起菜单**，便于连续勾选，点菜单外部收起。
- **配置**：`ConfigKey` 以 JSON 数组存入配置文件（`["Head","Torso"]`），`SaveConfig` / `LoadConfig` 往返不丢项。
- **兼容**：不写 `Multi` 时与旧版行为完全一致（单选，`Get()` 返回字符串）。

### ✏️ 运行时改标题 `SetTitle` / `GetTitle`

主控件（`AddToggle` / `AddButton` / `AddNotice`）与所有子选项（`AddSlider` / `AddToggle` / `AddButton` / `AddColorPicker` / `AddDropdown` / `AddParagraph`）都支持运行时改标题：

```lua
local LangToggle = Tab:AddToggle({ Title = "Language", Icon = "globe", Default = false })
local LangButton
LangButton = LangToggle:AddButton({
    Title = "Switch to 中文",
    Callback = function()
        Win:SetLanguage(Win:GetLanguage() == "English" and "中文" or "English")
        LangToggle:SetTitle("Language [" .. Win:GetLanguage() .. "]")
        LangButton:SetTitle("Switch to English")
    end,
})
```

`SetTitle` 会同步更新方块标题、详情页标题、已注册的翻译 key 与快捷图标文字，因此后续 `SetLanguage()` 不会把标题覆盖回旧值。

### 🌐 多语言 `Translations` / `Win:Translate`

库内置中英文案。控件标题、Tab 名、窗口标题与 Info、**通知（`ShowNotify` 的 Title / Info）**、**Shortcut 胶囊文字**都会随 `SetLanguage()` 自动切换。

自定义文案通过 `CreateWindow` 的 `Translations` 登记，键为英文原文：

```lua
local Win = Library.CreateWindow({
    Title = "TitleBar", Info = "ImInfoBar",
    Translations = {
        ["中文"] = {
            ["TitleBar"] = "标题栏",
            ["ImInfoBar"] = "信息栏",
            ["Hello"] = "你好",
            ["A short toast."] = "一条简短通知。",
        },
    },
})

Win:SetLanguage("中文")
Win:ShowNotify({ Title = "Hello", Info = "A short toast." })  -- 显示「你好 / 一条简短通知。」
```

动态拼接的文案用 `Win:Translate(key)` 处理固定部分；未登记的 key 原样返回，对已翻译文本再次调用是幂等的。自建 UI 可在 `OnLanguageChanged` 里同步：

```lua
Win:ShowNotify({ Title = "Config", Info = Win:Translate("Loaded") .. " " .. cfgName })
Win:OnLanguageChanged(function(lang)
    myCustomLabel.Text = Win:Translate("Server / LocalPlayer")
end)
```

### 📝 段落控件 `Ctrl:AddParagraph`

用于详情页内的静态说明块，签名简洁统一：

```lua
local P = SomeToggle:AddParagraph({
    Title = "提示",                              -- 粗体标题
    Info  = "可以很长，会自动换行并重新计算高度。", -- 说明文字
    Icon  = "info",                             -- 可选 Lucide 图标（左侧）
})
P:SetTitle("新提示")
P:SetInfo("替换后的说明文字，控件会重新测量高度并回流排版")
P:SetIcon("alert-triangle")     -- 换图标
P:SetIconColor(Color3.new(1, 1, 1))
P:SetBackColor(Color3.fromRGB(34, 34, 42))
P:GetTitle()  -- 读回标题
P:GetInfo()   -- 读回说明
```

### 🔔 展示控件 `Tab:AddNotice`

外观与**普通主控件一致**（玻璃质感 + 描边），但**不可点击、不进详情页**，仅作信息展示。左上角大标题 + 下方正文，文字不做自适应长度（固定字号、自动换行）。

```lua
local N = Tab:AddNotice({
    Title = "AsLab UI 特点",                    -- 左上角大标题
    Text  = "轻量玻璃拟态 · 无头可测 · 多配置槽 …", -- 正文（自动换行）
    Icon  = "info",                             -- 可选：标题前的 Lucide 图标
    Span  = 3,                                  -- 占格数（见下表）
    Orientation = "Horizontal",                 -- "Horizontal" | "Vertical"
    TitleColor = Color3.new(1, 1, 1),           -- 可选配色
    TextColor  = Color3.fromRGB(180, 185, 205),
    IconColor  = Color3.fromRGB(120, 170, 255),
    BackColor  = Color3.fromRGB(26, 28, 36),
})
N:SetTitle("新标题")
N:SetText("替换后的正文")
N:SetIcon("alert-triangle")
N:SetColors({ TitleColor = Color3.new(1, 1, 1), TextColor = Color3.new(.8, .8, .8) })
```

**占格规则**（底层为跨格感知的网格排布，Notice 与普通主控件可混排，自动按行打包换行）：

| Orientation | Span 含义 | 限制 |
| --- | --- | --- |
| `Horizontal`（默认） | 横向所占**列数** | **1~3**（一行最多 3 格），超出自动 clamp |
| `Vertical` | 竖向所占**行数** | ≥1，**不限制**行数 |

### 🧱 自定义选项卡 `Win:AddCustomTab`

与普通 `AddTab` 一样是**选项卡 + 滑动容器**，同样支持 `AddToggle` / `AddButton` / `AddNotice` 等库内控件；区别是额外暴露一个**自定义层**，可用原生 Roblox API 在里面创建任意 UI：

```lua
local Tab = Win:AddCustomTab("Custom", "layout-customize")

-- 1) 库内控件照常添加
Tab:AddNotice({ Title = "说明", Text = "…", Span = 3 })

-- 2) 任意自定义 UI：父到 Tab.Container，用绝对坐标摆放
local panel = Instance.new("Frame")
panel.Parent = Tab.Container
panel.Size = UDim2.fromOffset(240, 140)
panel.Position = UDim2.fromOffset(0, 0)
-- …继续添加 UICorner / TextLabel / 按钮等（同样用「先 new 再 .Parent =」）

-- 3) 父入自定义 UI 后刷新，让滚动画布按内容自动撑高
Tab:Refresh()
```

| 成员 | 说明 |
| --- | --- |
| `Tab.Container` | 网格下方的自定义层（`Frame`），把自建 UI 以绝对坐标父于此 |
| `Tab.ContainerWidth` | 自定义层的可用像素宽度；排布左右双栏时按它计算半栏宽，避免右侧被截断 |
| `Tab:Refresh()` | 重新计算滚动画布高度；自定义层自动定位到网格下方，并按子控件底边撑高 |

> 完整示例见 `AsLab_Example.lua` 第 11 节：顶部跨 3 格 Notice + 左右双栏（Time/FPS/Network、玩家/LocalPlayer/角色状态）+ 自定义按钮与进度条。

## 🛡️ 输入与触摸

拖动窗口、悬浮球、快捷图标，或打开「设置」页时，库会自动启用一层**全屏 Active 透明输入盾**，并置 `UserInputService.ModalEnabled`：

- 落在面板空白区的触摸被输入盾吃掉，**不会穿透到 3D 相机导致屏幕视角被拖动**；
- 输入盾 `ZIndex` 低于所有交互控件，因此**不会遮挡按钮 / 滑块**；
- 拖动结束或设置页关闭后自动释放；
- 多个来源（窗口 / 悬浮球 / Shortcut / 设置页）以独立 key 叠加管理，互不干扰、重复触发安全。

标题栏的竖分隔线会检测标题 / Info 文字是否「超线」（右边缘越过竖线位置）：未超线时竖线从窗口顶部起保持闭合；超线时顶部下移到标题栏下方避开长文字；底部始终向下延长至关闭按钮区域下方，与横线一起闭合左下角。功能控件则贴在功能区域顶部排布。语言切换改变文案长度时会自动重算。

## 💾 配置（多配置槽）

> **已从库内移除「自动储存」**：库不再隐式把控件状态落盘。是否保存完全由你通过下方「配置管理器」显式决定，避免脚本在后台静默写盘。

带 `ConfigKey` 的控件在**显式保存**时落盘到 `AsLab/<Folder>/`：`config.json` 是默认槽，`Configs/<名字>.json` 是其他槽，`active.json` 记录上次使用的槽名。

```lua
win:SaveConfig()                 -- 保存到当前槽
win:SaveConfig("PvP")            -- 另存为新配置，并把它设为当前槽
win:LoadConfig("PvP")            -- 从指定配置读回，返回是否成功
win:LoadConfig()                 -- 不传名字：读回上次使用的配置槽
win:GetConfigs()                 -- { "Default", "PvP", ... }（Default 固定第一）
win:GetConfigName()              -- 当前配置名
win:GetConfigPath()              -- 当前配置的完整文件路径
win:ConfigExists("PvP")          -- 配置是否存在
win:SetConfig("Farm")            -- 只切槽，不读盘不写盘
win:RenameConfig("Farm", "F2")   -- 改名（Default 不可改）
win:DeleteConfig("F2")           -- 删除（Default 不可删，删当前槽会回落 Default）
```

按键绑定与快捷图标位置随配置一起保存（`__keys` / `__shortcuts`），换槽时一并恢复。

### 📂 配置管理器 Config Manager

底部功能栏在 **Settings** 与 **Close** 之间有一个 `folder-cog` 图标按钮。点击它唤出一个与设置面板结构一致的「配置管理器」面板：

- 左上角标题 **Config Manager**（中文：`配置管理`），右上角 `x` 关闭；
- 仅一个**居中的大下拉菜单**（模仿 DynamicCow「切换脚本」窗口内的下拉），列出所有 `Configs` 名称；
- 底部三个英文按钮：**Delete Config / Save Config / Load Config**（中文：`删除配置 / 保存配置 / 载入配置`）；
  - **Delete Config**：主红→黑微渐变 + 白字；
  - **Save Config / Load Config**：银白渐变 + 黑字。

行为：

| 操作 | 效果 |
| --- | --- |
| 选中某配置 → **Load Config** | 读取并应用该配置，通知「已载入该配置」（`Config Loaded`） |
| 选中某配置 → **Delete Config** | 删除所选配置、刷新下拉，通知「已删除该配置」（`Config Deleted`）；`Default` 不可删 |
| **Save Config**（无需预选） | 把当前所有控件状态存为 `Config N.json`（`N` 自动递增：配置1、配置2…），通知「已储存为 xxx.json」（`Saved as`） |

面板文案随 `SetLanguage()` 自动切换（见「多语言」一节），因此中英文用户都能直接使用。

```lua
-- 打开 / 关闭由底部 folder-cog 按钮驱动；若要编程触发：
local cfgBtn = findByName("ConfigManager")   -- 底部按钮实例
cfgBtn.MouseButton1Click:Fire()              -- 打开面板
-- 面板内：选中下拉项 → 点底部三按钮之一
```

> 完整示例见 `AsLab_Example.lua`：底部功能栏含 `folder-cog`，Custom 选项卡演示了自定义 UI（双栏玻璃面板 + 进度条 + 按钮），且示例末尾**不再**自动 Load/Save，配置改由手动管理。

## 🎯 设计理念

- **ImGui 即时模式**：控件按需声明，逻辑与界面高度内聚，调试工具与设置面板开发效率极高。
- **Apple 视觉语言**：强调留白、层级、动效与一致性，使成品更贴近原生体验。
- **单文件零依赖**：引入即用，兼容主流 Roblox 执行环境，也便于无头环境验证与回归。

## 📄 许可证

本项目基于 [MIT License](./LICENSE) 开源。

---

<p align="center">Made with ❤️ by WasKKal</p>
