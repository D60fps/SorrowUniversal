--// Cache
local pcall, getgenv, next, setmetatable, Vector2new, Color3fromRGB, Drawingnew, taskwait = pcall, getgenv, next, setmetatable, Vector2.new, Color3.fromRGB, Drawing.new, task.wait
local stringsplit, tableinsert, tablefind, mathfloor, mathclamp = string.split, table.insert, table.find, math.floor, math.clamp

--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Load Modules
local getgenv = getgenv or genv or (function() return getfenv(0) end)
if not getgenv().AirHub then getgenv().AirHub = {} end
loadstring(game:HttpGet("https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Aimbot.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Wall%20Hack.lua"))()
local Aimbot   = getgenv().AirHub.Aimbot
local WallHack = getgenv().AirHub.WallHack

--// Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Flags = {}

--// Rayfield window (matches your original window name)
local MainWindow = Rayfield:CreateWindow({
    Name = "AirHub V3",
    LoadingTitle = "SORROW AIRHUB",
    LoadingSubtitle = "sorrow.cc | build 2026",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

--// Tab/section wrappers so the rest of your code works unchanged
local function MakeTab(name)
    local t = {}
    local _tab = MainWindow:CreateTab(name, 4483362458)
    -- Create a default section immediately so elements always have somewhere to go
    local _curSection = _tab:CreateSection("Settings", true)

    function t:AddToggle(opts, cb)
        Flags[opts.Flag] = opts.Default or false
        _curSection:CreateToggle({ Name=opts.Text, CurrentValue=opts.Default or false, Flag=opts.Flag,
            Callback=function(v) Flags[opts.Flag]=v; if cb then cb(v) end end })
        return { SetValue = function(_, v) Flags[opts.Flag]=v; if cb then cb(v) end end }
    end

    function t:AddSlider(opts, cb)
        Flags[opts.Flag] = opts.Default or 0
        local inc = (opts.Max and opts.Max <= 1) and 0.01 or 1
        _curSection:CreateSlider({ Name=opts.Text, Range={opts.Min or 0, opts.Max or 100},
            Increment=inc, Suffix=opts.Suffix or "",
            CurrentValue=opts.Default or 0, Flag=opts.Flag,
            Callback=function(v) Flags[opts.Flag]=v; if cb then cb(v) end end })
        return { SetValue = function(_, v) Flags[opts.Flag]=v; if cb then cb(v) end end }
    end

    function t:AddDropdown(opts, cb)
        local def = opts.Default or (opts.Values and opts.Values[1]) or ""
        Flags[opts.Flag] = def
        _curSection:CreateDropdown({ Name=opts.Text, Options=opts.Values or {},
            CurrentOption={def}, Flag=opts.Flag,
            Callback=function(v) local val=v[1]; Flags[opts.Flag]=val; if cb then cb(val) end end })
        return { SetValue = function(_, v) Flags[opts.Flag]=v; if cb then cb(v) end end }
    end

    function t:AddColorPicker(opts, cb)
        local def = opts.Default or Color3fromRGB(255,255,255)
        Flags[opts.Flag] = def
        _curSection:CreateColorPicker({ Name=opts.Text, Color=def, Flag=opts.Flag,
            Callback=function(v) Flags[opts.Flag]=v; if cb then cb(v) end end })
        return { SetValue = function(_, v) Flags[opts.Flag]=v; if cb then cb(v) end end }
    end

    function t:AddButton(opts, cb)
        _curSection:CreateButton({ Name=opts.Text, Callback=function() if cb then cb() end end })
        return { Click = function() if cb then cb() end end }
    end

    function t:AddLabel(text)
        -- Each label becomes a new section header
        _curSection = _tab:CreateSection(text, true)
    end

    return t
end

local Library = {}
function Library:CreateWindow(title)
    return {
        AddTab = function(_, name)
            return MakeTab(name)
        end
    }
end

--// Create Main Window
local MainWindow = Library:CreateWindow("AirHub V2")
local MainTabs = {}

--// Main Tab
MainTabs.Main = MainWindow:AddTab("Main")

MainTabs.Main:AddToggle({
    Text = "Enable Aimbot",
    Flag = "Aimbot_Enabled",
    Default = false
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.Enabled = value
    end
end)

MainTabs.Main:AddToggle({
    Text = "Enable Wallhack",
    Flag = "Wallhack_Enabled",
    Default = false
}, function(value)
    if WallHack and WallHack.Settings then
        WallHack.Settings.Enabled = value
    end
end)

MainTabs.Main:AddDropdown({
    Text = "Aimbot Lock Part",
    Flag = "Aimbot_LockPart",
    Values = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head"
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.LockPart = value
    end
end)

MainTabs.Main:AddSlider({
    Text = "Aimbot Sensitivity",
    Flag = "Aimbot_Sensitivity",
    Min = 0,
    Max = 2,
    Default = 0,
    Suffix = "s"
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.Sensitivity = value
    end
end)

MainTabs.Main:AddToggle({
    Text = "Aimbot Toggle Mode",
    Flag = "Aimbot_Toggle",
    Default = false
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.Toggle = value
    end
end)

MainTabs.Main:AddDropdown({
    Text = "Aimbot Trigger Key",
    Flag = "Aimbot_TriggerKey",
    Values = {"MouseButton1", "MouseButton2", "MouseButton3", "E", "Q", "F", "C", "X", "Z", "V"},
    Default = "MouseButton2"
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.TriggerKey = value
    end
end)

--// Aimbot Settings Tab
MainTabs.Aimbot = MainWindow:AddTab("Aimbot")

MainTabs.Aimbot:AddToggle({
    Text = "Team Check",
    Flag = "Aimbot_TeamCheck",
    Default = false
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.TeamCheck = value
    end
end)

MainTabs.Aimbot:AddToggle({
    Text = "Alive Check",
    Flag = "Aimbot_AliveCheck",
    Default = true
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.AliveCheck = value
    end
end)

MainTabs.Aimbot:AddToggle({
    Text = "Wall Check",
    Flag = "Aimbot_WallCheck",
    Default = false
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.WallCheck = value
    end
end)

MainTabs.Aimbot:AddToggle({
    Text = "Third Person Mode",
    Flag = "Aimbot_ThirdPerson",
    Default = false
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.ThirdPerson = value
    end
end)

MainTabs.Aimbot:AddSlider({
    Text = "Third Person Sensitivity",
    Flag = "Aimbot_ThirdPersonSens",
    Min = 1,
    Max = 10,
    Default = 3
}, function(value)
    if Aimbot and Aimbot.Settings then
        Aimbot.Settings.ThirdPersonSensitivity = value
    end
end)

--// FOV Settings
MainTabs.Aimbot:AddLabel("--- FOV Settings ---")

MainTabs.Aimbot:AddToggle({
    Text = "Enable FOV",
    Flag = "FOV_Enabled",
    Default = true
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Enabled = value
    end
end)

MainTabs.Aimbot:AddToggle({
    Text = "Show FOV Circle",
    Flag = "FOV_Visible",
    Default = true
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Visible = value
    end
end)

MainTabs.Aimbot:AddSlider({
    Text = "FOV Size",
    Flag = "FOV_Amount",
    Min = 30,
    Max = 500,
    Default = 90,
    Suffix = "px"
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Amount = value
    end
end)

MainTabs.Aimbot:AddSlider({
    Text = "FOV Transparency",
    Flag = "FOV_Transparency",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Suffix = ""
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Transparency = value
    end
end)

MainTabs.Aimbot:AddSlider({
    Text = "FOV Thickness",
    Flag = "FOV_Thickness",
    Min = 1,
    Max = 5,
    Default = 1
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Thickness = value
    end
end)

MainTabs.Aimbot:AddToggle({
    Text = "FOV Filled",
    Flag = "FOV_Filled",
    Default = false
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Filled = value
    end
end)

MainTabs.Aimbot:AddColorPicker({
    Text = "FOV Color",
    Flag = "FOV_Color",
    Default = Color3fromRGB(255, 255, 255)
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.Color = value
    end
end)

MainTabs.Aimbot:AddColorPicker({
    Text = "FOV Locked Color",
    Flag = "FOV_LockedColor",
    Default = Color3fromRGB(255, 70, 70)
}, function(value)
    if Aimbot and Aimbot.FOVSettings then
        Aimbot.FOVSettings.LockedColor = value
    end
end)

--// Wallhack Settings Tab
MainTabs.Wallhack = MainWindow:AddTab("Wallhack")

--// General Settings
MainTabs.Wallhack:AddLabel("--- General Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Team Check",
    Flag = "Wallhack_TeamCheck",
    Default = false
}, function(value)
    if WallHack and WallHack.Settings then
        WallHack.Settings.TeamCheck = value
    end
end)

MainTabs.Wallhack:AddToggle({
    Text = "Alive Check",
    Flag = "Wallhack_AliveCheck",
    Default = true
}, function(value)
    if WallHack and WallHack.Settings then
        WallHack.Settings.AliveCheck = value
    end
end)

MainTabs.Wallhack:AddSlider({
    Text = "Max Distance",
    Flag = "Wallhack_MaxDistance",
    Min = 0,
    Max = 5000,
    Default = 1000,
    Suffix = "studs"
}, function(value)
    if WallHack and WallHack.Settings then
        WallHack.Settings.MaxDistance = value
    end
end)

--// ESP Settings
MainTabs.Wallhack:AddLabel("--- ESP Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Enable ESP",
    Flag = "ESP_Enabled",
    Default = true
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ESPSettings then
        WallHack.Visuals.ESPSettings.Enabled = value
    end
end)

MainTabs.Wallhack:AddToggle({
    Text = "Display Name",
    Flag = "ESP_DisplayName",
    Default = true
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ESPSettings then
        WallHack.Visuals.ESPSettings.DisplayName = value
    end
end)

MainTabs.Wallhack:AddToggle({
    Text = "Display Health",
    Flag = "ESP_DisplayHealth",
    Default = true
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ESPSettings then
        WallHack.Visuals.ESPSettings.DisplayHealth = value
    end
end)

MainTabs.Wallhack:AddToggle({
    Text = "Display Distance",
    Flag = "ESP_DisplayDistance",
    Default = true
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ESPSettings then
        WallHack.Visuals.ESPSettings.DisplayDistance = value
    end
end)

MainTabs.Wallhack:AddColorPicker({
    Text = "ESP Text Color",
    Flag = "ESP_TextColor",
    Default = Color3fromRGB(255, 255, 255)
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ESPSettings then
        WallHack.Visuals.ESPSettings.TextColor = value
    end
end)

MainTabs.Wallhack:AddSlider({
    Text = "ESP Text Size",
    Flag = "ESP_TextSize",
    Min = 10,
    Max = 30,
    Default = 14
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ESPSettings then
        WallHack.Visuals.ESPSettings.TextSize = value
    end
end)

MainTabs.Wallhack:AddSlider({
    Text = "ESP Transparency",
    Flag = "ESP_Transparency",
    Min = 0,
    Max = 1,
    Default = 0.7
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ESPSettings then
        WallHack.Visuals.ESPSettings.TextTransparency = value
    end
end)

--// Tracers
MainTabs.Wallhack:AddLabel("--- Tracer Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Enable Tracers",
    Flag = "Tracers_Enabled",
    Default = true
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.TracersSettings then
        WallHack.Visuals.TracersSettings.Enabled = value
    end
end)

MainTabs.Wallhack:AddDropdown({
    Text = "Tracer Type",
    Flag = "Tracers_Type",
    Values = {"Bottom", "Center", "Mouse"},
    Default = "Bottom"
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.TracersSettings then
        local typeNum = value == "Bottom" and 1 or value == "Center" and 2 or 3
        WallHack.Visuals.TracersSettings.Type = typeNum
    end
end)

MainTabs.Wallhack:AddColorPicker({
    Text = "Tracer Color",
    Flag = "Tracers_Color",
    Default = Color3fromRGB(255, 255, 255)
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.TracersSettings then
        WallHack.Visuals.TracersSettings.Color = value
    end
end)

--// Boxes
MainTabs.Wallhack:AddLabel("--- Box Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Enable Boxes",
    Flag = "Box_Enabled",
    Default = true
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.BoxSettings then
        WallHack.Visuals.BoxSettings.Enabled = value
    end
end)

MainTabs.Wallhack:AddDropdown({
    Text = "Box Type",
    Flag = "Box_Type",
    Values = {"3D Box", "2D Box"},
    Default = "3D Box"
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.BoxSettings then
        WallHack.Visuals.BoxSettings.Type = value == "3D Box" and 1 or 2
    end
end)

MainTabs.Wallhack:AddColorPicker({
    Text = "Box Color",
    Flag = "Box_Color",
    Default = Color3fromRGB(255, 255, 255)
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.BoxSettings then
        WallHack.Visuals.BoxSettings.Color = value
    end
end)

--// Head Dot
MainTabs.Wallhack:AddLabel("--- Head Dot Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Enable Head Dot",
    Flag = "HeadDot_Enabled",
    Default = true
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.HeadDotSettings then
        WallHack.Visuals.HeadDotSettings.Enabled = value
    end
end)

MainTabs.Wallhack:AddColorPicker({
    Text = "Head Dot Color",
    Flag = "HeadDot_Color",
    Default = Color3fromRGB(255, 255, 255)
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.HeadDotSettings then
        WallHack.Visuals.HeadDotSettings.Color = value
    end
end)

--// Chams
MainTabs.Wallhack:AddLabel("--- Chams Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Enable Chams",
    Flag = "Chams_Enabled",
    Default = false
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ChamsSettings then
        WallHack.Visuals.ChamsSettings.Enabled = value
    end
end)

MainTabs.Wallhack:AddColorPicker({
    Text = "Chams Color",
    Flag = "Chams_Color",
    Default = Color3fromRGB(255, 255, 255)
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ChamsSettings then
        WallHack.Visuals.ChamsSettings.Color = value
    end
end)

MainTabs.Wallhack:AddSlider({
    Text = "Chams Transparency",
    Flag = "Chams_Transparency",
    Min = 0,
    Max = 1,
    Default = 0.2
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ChamsSettings then
        WallHack.Visuals.ChamsSettings.Transparency = value
    end
end)

MainTabs.Wallhack:AddToggle({
    Text = "Full Body Chams",
    Flag = "Chams_EntireBody",
    Default = false
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.ChamsSettings then
        WallHack.Visuals.ChamsSettings.EntireBody = value
    end
end)

--// Health Bar
MainTabs.Wallhack:AddLabel("--- Health Bar Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Enable Health Bar",
    Flag = "HealthBar_Enabled",
    Default = false
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.HealthBarSettings then
        WallHack.Visuals.HealthBarSettings.Enabled = value
    end
end)

MainTabs.Wallhack:AddDropdown({
    Text = "Health Bar Position",
    Flag = "HealthBar_Type",
    Values = {"Top", "Bottom", "Left", "Right"},
    Default = "Left"
}, function(value)
    if WallHack and WallHack.Visuals and WallHack.Visuals.HealthBarSettings then
        local typeNum = value == "Top" and 1 or value == "Bottom" and 2 or value == "Left" and 3 or 4
        WallHack.Visuals.HealthBarSettings.Type = typeNum
    end
end)

--// Crosshair
MainTabs.Wallhack:AddLabel("--- Crosshair Settings ---")

MainTabs.Wallhack:AddToggle({
    Text = "Enable Custom Crosshair",
    Flag = "Crosshair_Enabled",
    Default = false
}, function(value)
    if WallHack and WallHack.Crosshair and WallHack.Crosshair.Settings then
        WallHack.Crosshair.Settings.Enabled = value
    end
end)

MainTabs.Wallhack:AddColorPicker({
    Text = "Crosshair Color",
    Flag = "Crosshair_Color",
    Default = Color3fromRGB(0, 255, 0)
}, function(value)
    if WallHack and WallHack.Crosshair and WallHack.Crosshair.Settings then
        WallHack.Crosshair.Settings.Color = value
    end
end)

MainTabs.Wallhack:AddSlider({
    Text = "Crosshair Size",
    Flag = "Crosshair_Size",
    Min = 5,
    Max = 30,
    Default = 12
}, function(value)
    if WallHack and WallHack.Crosshair and WallHack.Crosshair.Settings then
        WallHack.Crosshair.Settings.Size = value
    end
end)

--// Utility Tab
MainTabs.Utility = MainWindow:AddTab("Utility")

MainTabs.Utility:AddButton({
    Text = "Reset All Settings"
}, function()
    if Aimbot and Aimbot.Functions and Aimbot.Functions.ResetSettings then
        Aimbot.Functions:ResetSettings()
    end
    
    if WallHack and WallHack.Functions and WallHack.Functions.ResetSettings then
        WallHack.Functions:ResetSettings()
    end
    
    -- Reset flags
    for flag, _ in pairs(Flags) do
        if flag == "Aimbot_Enabled" then Flags[flag] = false
        elseif flag == "Wallhack_Enabled" then Flags[flag] = false
        elseif flag == "Aimbot_LockPart" then Flags[flag] = "Head"
        elseif flag == "Aimbot_Sensitivity" then Flags[flag] = 0
        elseif flag == "Aimbot_Toggle" then Flags[flag] = false
        elseif flag == "Aimbot_TriggerKey" then Flags[flag] = "MouseButton2"
        elseif flag == "Aimbot_TeamCheck" then Flags[flag] = false
        elseif flag == "Aimbot_AliveCheck" then Flags[flag] = true
        elseif flag == "Aimbot_WallCheck" then Flags[flag] = false
        elseif flag == "Aimbot_ThirdPerson" then Flags[flag] = false
        elseif flag == "Aimbot_ThirdPersonSens" then Flags[flag] = 3
        elseif flag == "FOV_Enabled" then Flags[flag] = true
        elseif flag == "FOV_Visible" then Flags[flag] = true
        elseif flag == "FOV_Amount" then Flags[flag] = 90
        elseif flag == "FOV_Transparency" then Flags[flag] = 0.5
        elseif flag == "FOV_Thickness" then Flags[flag] = 1
        elseif flag == "FOV_Filled" then Flags[flag] = false
        elseif flag == "Wallhack_TeamCheck" then Flags[flag] = false
        elseif flag == "Wallhack_AliveCheck" then Flags[flag] = true
        elseif flag == "Wallhack_MaxDistance" then Flags[flag] = 1000
        elseif flag == "ESP_Enabled" then Flags[flag] = true
        elseif flag == "ESP_DisplayName" then Flags[flag] = true
        elseif flag == "ESP_DisplayHealth" then Flags[flag] = true
        elseif flag == "ESP_DisplayDistance" then Flags[flag] = true
        elseif flag == "ESP_TextSize" then Flags[flag] = 14
        elseif flag == "ESP_Transparency" then Flags[flag] = 0.7
        elseif flag == "Tracers_Enabled" then Flags[flag] = true
        elseif flag == "Tracers_Type" then Flags[flag] = "Bottom"
        elseif flag == "Box_Enabled" then Flags[flag] = true
        elseif flag == "Box_Type" then Flags[flag] = "3D Box"
        elseif flag == "HeadDot_Enabled" then Flags[flag] = true
        elseif flag == "Chams_Enabled" then Flags[flag] = false
        elseif flag == "Chams_Transparency" then Flags[flag] = 0.2
        elseif flag == "Chams_EntireBody" then Flags[flag] = false
        elseif flag == "HealthBar_Enabled" then Flags[flag] = false
        elseif flag == "HealthBar_Type" then Flags[flag] = "Left"
        elseif flag == "Crosshair_Enabled" then Flags[flag] = false
        elseif flag == "Crosshair_Size" then Flags[flag] = 12
        end
    end
    
    -- Reset colors
    Flags["FOV_Color"] = Color3fromRGB(255, 255, 255)
    Flags["FOV_LockedColor"] = Color3fromRGB(255, 70, 70)
    Flags["ESP_TextColor"] = Color3fromRGB(255, 255, 255)
    Flags["Tracers_Color"] = Color3fromRGB(255, 255, 255)
    Flags["Box_Color"] = Color3fromRGB(255, 255, 255)
    Flags["HeadDot_Color"] = Color3fromRGB(255, 255, 255)
    Flags["Chams_Color"] = Color3fromRGB(255, 255, 255)
    Flags["Crosshair_Color"] = Color3fromRGB(0, 255, 0)
end)

MainTabs.Utility:AddButton({
    Text = "Restart Modules"
}, function()
    if Aimbot and Aimbot.Functions and Aimbot.Functions.Restart then
        Aimbot.Functions:Restart()
    end
    
    if WallHack and WallHack.Functions and WallHack.Functions.Restart then
        WallHack.Functions:Restart()
    end
end)

MainTabs.Utility:AddButton({
    Text = "Unload (Exit)"
}, function()
    if Aimbot and Aimbot.Functions and Aimbot.Functions.Exit then
        Aimbot.Functions:Exit()
    end
    
    if WallHack and WallHack.Functions and WallHack.Functions.Exit then
        WallHack.Functions:Exit()
    end
    
    -- Clear flags
    Flags = {}
    
    -- Notify
    print("AirHub V2 Unloaded")
end)

--// Initialize Modules with Default Settings
task.wait(1)

-- Set Aimbot defaults
if Aimbot and Aimbot.Settings then
    Aimbot.Settings.Enabled = Flags["Aimbot_Enabled"]
    Aimbot.Settings.TeamCheck = Flags["Aimbot_TeamCheck"]
    Aimbot.Settings.AliveCheck = Flags["Aimbot_AliveCheck"]
    Aimbot.Settings.WallCheck = Flags["Aimbot_WallCheck"]
    Aimbot.Settings.Sensitivity = Flags["Aimbot_Sensitivity"]
    Aimbot.Settings.ThirdPerson = Flags["Aimbot_ThirdPerson"]
    Aimbot.Settings.ThirdPersonSensitivity = Flags["Aimbot_ThirdPersonSens"]
    Aimbot.Settings.TriggerKey = Flags["Aimbot_TriggerKey"]
    Aimbot.Settings.Toggle = Flags["Aimbot_Toggle"]
    Aimbot.Settings.LockPart = Flags["Aimbot_LockPart"]
end

if Aimbot and Aimbot.FOVSettings then
    Aimbot.FOVSettings.Enabled = Flags["FOV_Enabled"]
    Aimbot.FOVSettings.Visible = Flags["FOV_Visible"]
    Aimbot.FOVSettings.Amount = Flags["FOV_Amount"]
    Aimbot.FOVSettings.Color = Flags["FOV_Color"]
    Aimbot.FOVSettings.LockedColor = Flags["FOV_LockedColor"]
    Aimbot.FOVSettings.Transparency = Flags["FOV_Transparency"]
    Aimbot.FOVSettings.Thickness = Flags["FOV_Thickness"]
    Aimbot.FOVSettings.Filled = Flags["FOV_Filled"]
end

-- Set Wallhack defaults
if WallHack and WallHack.Settings then
    WallHack.Settings.Enabled = Flags["Wallhack_Enabled"]
    WallHack.Settings.TeamCheck = Flags["Wallhack_TeamCheck"]
    WallHack.Settings.AliveCheck = Flags["Wallhack_AliveCheck"]
    WallHack.Settings.MaxDistance = Flags["Wallhack_MaxDistance"]
end

if WallHack and WallHack.Visuals then
    -- ESP
    WallHack.Visuals.ESPSettings.Enabled = Flags["ESP_Enabled"]
    WallHack.Visuals.ESPSettings.TextColor = Flags["ESP_TextColor"]
    WallHack.Visuals.ESPSettings.TextSize = Flags["ESP_TextSize"]
    WallHack.Visuals.ESPSettings.TextTransparency = Flags["ESP_Transparency"]
    WallHack.Visuals.ESPSettings.DisplayName = Flags["ESP_DisplayName"]
    WallHack.Visuals.ESPSettings.DisplayHealth = Flags["ESP_DisplayHealth"]
    WallHack.Visuals.ESPSettings.DisplayDistance = Flags["ESP_DisplayDistance"]
    
    -- Tracers
    WallHack.Visuals.TracersSettings.Enabled = Flags["Tracers_Enabled"]
    WallHack.Visuals.TracersSettings.Color = Flags["Tracers_Color"]
    local tracerType = Flags["Tracers_Type"]
    WallHack.Visuals.TracersSettings.Type = tracerType == "Bottom" and 1 or tracerType == "Center" and 2 or 3
    
    -- Box
    WallHack.Visuals.BoxSettings.Enabled = Flags["Box_Enabled"]
    WallHack.Visuals.BoxSettings.Color = Flags["Box_Color"]
    local boxType = Flags["Box_Type"]
    WallHack.Visuals.BoxSettings.Type = boxType == "3D Box" and 1 or 2
    
    -- Head Dot
    WallHack.Visuals.HeadDotSettings.Enabled = Flags["HeadDot_Enabled"]
    WallHack.Visuals.HeadDotSettings.Color = Flags["HeadDot_Color"]
    
    -- Chams
    WallHack.Visuals.ChamsSettings.Enabled = Flags["Chams_Enabled"]
    WallHack.Visuals.ChamsSettings.Color = Flags["Chams_Color"]
    WallHack.Visuals.ChamsSettings.Transparency = Flags["Chams_Transparency"]
    WallHack.Visuals.ChamsSettings.EntireBody = Flags["Chams_EntireBody"]
    
    -- Health Bar
    WallHack.Visuals.HealthBarSettings.Enabled = Flags["HealthBar_Enabled"]
    local healthType = Flags["HealthBar_Type"]
    WallHack.Visuals.HealthBarSettings.Type = healthType == "Top" and 1 or healthType == "Bottom" and 2 or healthType == "Left" and 3 or 4
end

if WallHack and WallHack.Crosshair and WallHack.Crosshair.Settings then
    WallHack.Crosshair.Settings.Enabled = Flags["Crosshair_Enabled"]
    WallHack.Crosshair.Settings.Color = Flags["Crosshair_Color"]
    WallHack.Crosshair.Settings.Size = Flags["Crosshair_Size"]
end

print("AirHub V3 Loaded Successfully!")
