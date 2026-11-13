# AsLab-UI-Library

<p align="center">
  <img src="https://img.shields.io/badge/Roblox-Luau-00a2ff?style=for-the-badge&logo=roblox" alt="Roblox Luau" />
  <img src="https://img.shields.io/badge/Style-ImGui%20%2B%20Apple-000000?style=for-the-badge" alt="ImGui + Apple Style" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License" />
</p>

> 一个 Roblox UI 库，借鉴 **ImGui** 的即时模式（Immediate-Mode）设计理念与 **Apple** 的视觉风格，让你在 Roblox 中用最少的代码快速搭建美观、易用的调试面板与设置界面。

---

## ✨ 特性

- 🎛️ **ImGui 式即时模式**：以声明式 / 命令式混合 API 快速堆叠控件，无需手动维护冗长的对象层级。
- 🍎 **Apple 风格视觉**：圆角、毛玻璃质感、系统级排版与配色，开箱即用的高级观感。
- 🧩 **丰富控件**：窗口、标签页、按钮、开关、滑块、下拉框、文本框、分段控制器等一应俱全。
- 🪟 **多窗口管理**：支持多实例共存、休眠态切换，重复加载时自动重建避免叠加。
- 🔌 **零依赖注入**：单文件引入即可使用，兼容主流 Roblox 执行环境。
- 🎨 **可主题化**：内置样式系统，方便统一换肤或自定义品牌色。
- 🧱 **混合布局**：`Notice` 展示块支持 1~3 格横向跨列 / 竖向不限行；`AddCustomTab` 允许在滑动选项卡内自由创建任意自定义 UI。

## 📦 安装

将 `AsLabUILibrary.lua` 放入你的项目，并通过执行环境加载：

```lua
local Library = loadstring(game:HttpGet("你的资源地址/AsLabUILibrary.lua"))()
```

> 也可直接将库文件拷贝到本地模块目录后 `require`。

## 🚀 快速开始

```lua
local Library = loadstring(...)()

-- 创建一个窗口
local Window = Library.CreateWindow({
    Title = "AsLab Demo",
    Size = UDim2.fromOffset(520, 360),
})

-- 添加标签页（图标为 Lucide 名称）
local Tab = Window:AddTab("设置", "settings")

-- 主控件用 Title 而非 Text
Tab:AddToggle({ Title = "启用功能", Default = true, Callback = function(v) print("开关:", v) end })
Tab:AddButton({ Title = "应用", Callback = function() print("已应用") end })

-- 子控件（滑块等）需挂在某主控件上：长按主开关进入详情页即可看到
local Feature = Tab:AddToggle({ Title = "音效", Default = true })
local Vol = Feature:AddSlider({ Title = "音量", Min = 0, Max = 100, Default = 50, Callback = function(v) print("音量:", v) end })
Vol:SetValue(80)  -- 运行时动态改变滑块值（自动 clamp 到 0~100）
```

## 🗂️ 控件一览

**主层级（Tab 上直接添加）**

| 方法 | 说明 |
| --- | --- |
| `Win:AddTab(name, icon)` | 添加标签页 |
| `Win:AddCustomTab(name, icon)` | 添加「自定义选项卡」——同样是选项卡 + 滑动容器，但可自由创建任意 UI（见下文） |
| `Tab:AddToggle(opts)` | 主开关（可长按进入详情页） |
| `Tab:AddButton(opts)` | 主按钮 |
| `Tab:AddNotice(opts)` | 展示型 Notice：外观与主控件一致，但**不可点击**、仅显示信息（见下文） |

**子选项（长按主开关进入详情页后添加，挂在某个 `Ctrl` 上）**

| 方法 | 说明 |
| --- | --- |
| `Ctrl:AddSlider(opts)` | 滑块 —— 返回值 `.Set(v)` / `.SetValue(v)` 可在运行时动态改变数值（自动 clamp 到 Min/Max） |
| `Ctrl:AddToggle(opts)` | 子开关 |
| `Ctrl:AddButton(opts)` | 子按钮 |
| `Ctrl:AddColorPicker(opts)` | 取色器 |
| `Ctrl:AddDropdown(opts)` | 下拉选择（支持 `SetOptions` / `AddOption` / `RemoveOption` 动态增删） |
| `Ctrl:AddParagraph(opts)` | 文本段落（照抄 DynamicCow 的 SubParagraph，标题 + 说明 + 可选图标，高度随文字自动变化） |

> Slider 值可动态改变：子滑块对象返回后调用 `.Set(数值)` 或 `.SetValue(数值)` 即可实时更新滑条、数值与配置。

### 📝 段落控件 `Ctrl:AddParagraph`

用于详情页内的静态说明块，签名与 DynamicCow 一致：

```lua
local P = SomeToggle:AddParagraph({
    Title = "提示",                              -- 粗体标题
    Info  = "可以很长，会自动换行并重新计算高度。", -- 说明文字
    Icon  = "info",                             -- 可选 Lucide 图标（左侧）
})
-- 运行时动态更新
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
local panel = Instance.new("Frame", Tab.Container)
panel.Size = UDim2.fromOffset(240, 140)
panel.Position = UDim2.fromOffset(0, 0)
-- …继续添加 UICorner / TextLabel / 按钮等

-- 3) 父入自定义 UI 后刷新，让滚动画布按内容自动撑高
Tab:Refresh()
```

| 成员 | 说明 |
| --- | --- |
| `Tab.Container` | 网格下方的自定义层（`Frame`），把自建 UI 以绝对坐标父于此 |
| `Tab:Refresh()` | 重新计算滚动画布高度；自定义层自动定位到网格下方，并按子控件底边撑高 |

> 完整示例见 `AsLab_Example.lua` 第 11 节：顶部跨 3 格 Notice + 左右双栏（Time/FPS/Network、玩家/LocalPlayer/角色状态）+ 自定义按钮与进度条。

## 💾 配置（多配置槽）

带 `ConfigKey` 的控件会自动落盘到 `AsLab/<Folder>/`：`config.json` 是默认槽，`Configs/<名字>.json` 是其他槽，`active.json` 记录上次使用的槽名。

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

## 🎯 设计理念

- **ImGui 即时模式**：控件在每一帧按需声明，逻辑与界面高度内聚，调试工具与设置面板开发效率极高。
- **Apple 视觉语言**：遵循 Apple 的人机界面规范，强调留白、层级、动效与一致性，使成品更贴近原生体验。

## 📄 许可证

本项目基于 [MIT License](./LICENSE) 开源。

---

<p align="center">Made with ❤️ by AsLab</p>
