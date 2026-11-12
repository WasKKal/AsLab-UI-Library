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
| `Tab:AddToggle(opts)` | 主开关（可长按进入详情页） |
| `Tab:AddButton(opts)` | 主按钮 |

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
