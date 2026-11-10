local Library = loadstring(game:HttpGet("https://ghfast.top/https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/AsLabUILibrary.lua"))()
Library.PreloadLucide()

local Win = Library.CreateWindow({
    Title = "Window Title",
    TitleIcon = "layout-grid",
    Size = UDim2.fromOffset(540, 400),
    Info = "Info Bar",
})

local TabGeneral = Win:AddTab("General", "settings")
local TabVisual = Win:AddTab("Appearance", "palette")
local TabSystem = Win:AddTab("System", "cpu")

TabGeneral:AddToggle({ Title = "Auto Save", Icon = "save", Default = true, Callback = function(v)
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

local Boost = TabGeneral:AddToggle({ Title = "Boost", Icon = "gauge", Default = false, Callback = function(v)
    print("Boost:", v)
end })

Boost:AddSlider({ Title = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v)
    print("Speed:", v)
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

local ESP = TabSystem:AddToggle({ Title = "ESP", Icon = "eye", Default = false, Callback = function(v)
    print("ESP:", v)
end })

ESP:AddToggle({ Title = "Highlight", Default = true, Callback = function(v)
    print("Highlight:", v)
end })

ESP:AddColorPicker({ Title = "Highlight Color", Default = Color3.fromRGB(255, 96, 96), Callback = function(c)
    print("Highlight Color:", c)
end })

ESP:AddToggle({ Title = "Draw Skeleton", Default = false, Callback = function(v)
    print("Draw Skeleton:", v)
end })

local TabNotify = Win:AddTab("Notify", "bell")

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

print("AsLab UI loaded, window fading in...")
