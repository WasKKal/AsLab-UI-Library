local Library = loadstring(game:HttpGet("https://ghfast.top/https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/AsLabUILibrary.lua"))()
Library.PreloadLucide()

local Win = Library.CreateWindow({
    Title = "Im Title",
    TitleIcon = "layout-grid",
    Size = UDim2.fromOffset(540, 400),
    Info = "Info Bar",
    Background = "https://raw.githubusercontent.com/WasKKal/AsLab-UI-Library/main/assets/aslab_wallpaper.png",
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

Boost:AddSlider({ Title = "Speed", Min = 16, Max = 200, Default = 50, Step = 1, ConfigKey = "boost_speed", Callback = function(v)
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

ESP:AddColorPicker({ Title = "Highlight Color", Default = Color3.fromRGB(255, 96, 96), ConfigKey = "esp_color", Callback = function(c)
    espColor = c
    refreshEspVisual()
end })

ESP:AddToggle({ Title = "Draw Skeleton", Default = false, Callback = function(v)
    espSkeleton = v
    refreshEspVisual()
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

-- 演示 ConfigKey：把带 ConfigKey 的控件状态落盘到 AsLab/Config 文件夹
Win:SaveConfig()
Win:LoadConfig()

print("AsLab UI loaded, window fading in...")
