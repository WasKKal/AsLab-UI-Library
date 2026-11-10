-- AsLab UI Library - Example
-- Demonstrates: title bar / info bar / vertical tabs (Lucide icons) / Toggle & Button squares (with and without icons)
-- The Icon argument accepts a Lucide icon name (e.g. "settings") or a direct asset URL (http(s)://, rbxasset://, etc.)

local Library = loadstring(game:HttpGet("https://ghfast.top/https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/AsLabUILibrary.lua"))()
-- Optional: preload Lucide (it also loads automatically on first icon use)
Library.PreloadLucide()

-- Create a window: the overall size is controlled by Size
local Win = Library.CreateWindow({
    Title = "Window Title",
    Left = "AsLab",
    Size = UDim2.fromOffset(540, 400),
    Info = "Info Bar",
})

-- Tabs: vertical, each with a Lucide icon + label
local TabGeneral = Win:AddTab("General", "settings")
local TabVisual = Win:AddTab("Appearance", "palette")
local TabSystem = Win:AddTab("System", "cpu")

-- Tab 1: Toggle / Button with icons (icon centered and larger, Title below it)
TabGeneral:AddToggle({ Title = "Auto Save", Icon = "save", Default = true, Callback = function(v)
    print("Auto Save:", v)
end })

TabGeneral:AddButton({ Title = "Refresh", Icon = "refresh-cw", Callback = function()
    print("Refreshed")
end })

TabGeneral:AddToggle({ Title = "Notifications", Icon = "bell", Default = false, Callback = function(v)
    print("Notifications:", v)
end })

-- Tab 1 continued: no icon, text centered in the square
TabGeneral:AddButton({ Title = "Run", Callback = function()
    print("Run button clicked")
end })

TabGeneral:AddToggle({ Title = "Debug", Default = false, Callback = function(v)
    print("Debug:", v)
end })

-- Tab 2: appearance related icons
TabVisual:AddToggle({ Title = "Dark Mode", Icon = "moon", Default = true, Callback = function(v)
    print("Dark Mode:", v)
end })

TabVisual:AddButton({ Title = "Theme", Icon = "brush", Callback = function()
    print("Opening theme")
end })

TabVisual:AddButton({ Title = "Reset", Icon = "rotate-ccw", Callback = function()
    print("Appearance reset")
end })

-- Tab 3: system related icons
TabSystem:AddToggle({ Title = "Performance", Icon = "gauge", Default = false, Callback = function(v)
    print("Performance:", v)
end })

TabSystem:AddButton({ Title = "Cleanup", Icon = "trash-2", Callback = function()
    print("Cleaned up")
end })

TabSystem:AddButton({ Title = "About", Icon = "help-circle", Callback = function()
    print("About AsLab UI")
end })

print("AsLab UI loaded, window fading in...")
