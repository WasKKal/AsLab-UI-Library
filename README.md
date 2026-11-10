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

-- 添加标签页
local Tab = Window:AddTab("设置")

-- 即时模式添加控件
Tab:AddToggle({ Text = "启用功能", Default = true, Callback = function(v) print("开关:", v) end })
Tab:AddSlider({ Text = "音量", Min = 0, Max = 100, Default = 50, Callback = function(v) print("音量:", v) end })
Tab:AddButton({ Text = "应用", Callback = function() print("已应用") end })
```

## 🗂️ 控件一览

| 控件 | 说明 |
| --- | --- |
| `CreateWindow` | 创建主窗口 |
| `AddTab` | 添加标签页 |
| `AddButton` | 按钮 |
| `AddToggle` | 开关 |
| `AddSlider` | 滑块 |
| `AddDropdown` | 下拉选择 |
| `AddTextBox` | 文本框 |
| `AddParagraph` | 文本段落 |

## 🎯 设计理念

- **ImGui 即时模式**：控件在每一帧按需声明，逻辑与界面高度内聚，调试工具与设置面板开发效率极高。
- **Apple 视觉语言**：遵循 Apple 的人机界面规范，强调留白、层级、动效与一致性，使成品更贴近原生体验。

## 📄 许可证

本项目基于 [MIT License](./LICENSE) 开源。

---

<p align="center">Made with ❤️ by AsLab</p>
