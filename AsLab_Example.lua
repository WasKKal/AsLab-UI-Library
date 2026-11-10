-- AsLab UI Library 使用示例
-- 演示：标题栏 / 信息栏 / 竖向选项卡（Lucide 图标）/ Toggle 与 Button 方块（带图标与不带图标）
-- 图标参数接受 Lucide 图标名（如 "settings"）或直接资源地址（http(s)://、rbxasset:// 等）

local Library = loadstring(game:HttpGet("https://ghfast.top/https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/AsLabUILibrary.lua"))()
-- 可选：提前拉取 Lucide（首次用到图标时也会自动加载）
Library.PreloadLucide()

-- 创建窗口：整体大小由 Size 控制
local Win = Library.CreateWindow({
    Title = "我是标题",
    Left = "我是",
    Size = UDim2.fromOffset(540, 400),
    Info = "我是Info",
})

-- 选项卡：竖向，含 Lucide 图标 + 文字
local TabGeneral = Win:AddTab("常规", "settings")
local TabVisual = Win:AddTab("外观", "palette")
local TabSystem = Win:AddTab("系统", "cpu")

-- 选项卡 1：带图标的 Toggle / Button（图标居中稍大，Title 在下方）
TabGeneral:AddToggle({ Title = "自动保存", Icon = "save", Default = true, Callback = function(v)
    print("自动保存:", v)
end })

TabGeneral:AddButton({ Title = "刷新", Icon = "refresh-cw", Callback = function()
    print("已刷新")
end })

TabGeneral:AddToggle({ Title = "通知", Icon = "bell", Default = false, Callback = function(v)
    print("通知:", v)
end })

-- 选项卡 1 续：无图标，文字居中方块
TabGeneral:AddButton({ Title = "执行", Callback = function()
    print("执行按钮被点击")
end })

TabGeneral:AddToggle({ Title = "调试", Default = false, Callback = function(v)
    print("调试:", v)
end })

-- 选项卡 2：外观相关图标
TabVisual:AddToggle({ Title = "深色", Icon = "moon", Default = true, Callback = function(v)
    print("深色模式:", v)
end })

TabVisual:AddButton({ Title = "主题", Icon = "brush", Callback = function()
    print("打开主题")
end })

TabVisual:AddButton({ Title = "重置", Icon = "rotate-ccw", Callback = function()
    print("已重置外观")
end })

-- 选项卡 3：系统相关图标
TabSystem:AddToggle({ Title = "性能", Icon = "gauge", Default = false, Callback = function(v)
    print("性能监控:", v)
end })

TabSystem:AddButton({ Title = "清理", Icon = "trash-2", Callback = function()
    print("已清理")
end })

TabSystem:AddButton({ Title = "关于", Icon = "help-circle", Callback = function()
    print("关于 AsLab UI")
end })

print("AsLab UI 已加载，窗口入场渐显中…")
