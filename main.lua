--// Cache
local getgenv = getgenv or genv or (function() return getfenv(0) end)
local Color3fromRGB = Color3.fromRGB
local mathclamp = math.clamp

--// Services
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

--// Loaded check
if getgenv().AirHub then return end
getgenv().AirHub = {}

--// Load Modules
loadstring(game:HttpGet("https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Aimbot.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Wall%20Hack.lua"))()

local Aimbot   = getgenv().AirHub.Aimbot
local WallHack = getgenv().AirHub.WallHack

--// Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "AirHub V3",
    LoadingTitle = "SORROW AIRHUB",
    LoadingSubtitle = "sorrow.cc | build 2026",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════
--  TABS
-- ══════════════════════════════════════════════════
local MainTab     = Window:CreateTab("Main",      4483362458)
local AimbotTab   = Window:CreateTab("Aimbot",    4483362458)
local VisualsTab  = Window:CreateTab("Visuals",   4483362458)
local UtilityTab  = Window:CreateTab("Utility",   4483362458)

-- ══════════════════════════════════════════════════
--  MAIN TAB
-- ══════════════════════════════════════════════════
MainTab:CreateSection("Core Settings")

MainTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "Aimbot_Enabled",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.Enabled = v
        end
    end
})

MainTab:CreateToggle({
    Name = "Enable Wallhack",
    CurrentValue = false,
    Flag = "Wallhack_Enabled",
    Callback = function(v)
        if WallHack and WallHack.Settings then
            WallHack.Settings.Enabled = v
        end
    end
})

MainTab:CreateSection("Aimbot Mode Selection")

MainTab:CreateDropdown({
    Name = "Aim Mode",
    Options = {"Camera Mode (CFrame)", "Mouse Mode (Movement)"},
    CurrentOption = {"Camera Mode (CFrame)"},
    Flag = "Aimbot_Mode",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            local mode = v[1] == "Camera Mode (CFrame)" and "Camera" or "Mouse"
            Aimbot.Settings.AimMode = mode
            if Aimbot.Functions and Aimbot.Functions.SetMode then
                Aimbot.Functions:SetMode(mode)
            end
        end
    end
})

MainTab:CreateDropdown({
    Name = "Lock Part",
    Options = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    CurrentOption = {"Head"},
    Flag = "Aimbot_LockPart",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.LockPart = v[1]
        end
    end
})

MainTab:CreateDropdown({
    Name = "Trigger Key",
    Options = {"MouseButton1", "MouseButton2", "MouseButton3", "E", "Q", "F", "C", "X", "Z", "V", "LeftAlt", "RightAlt", "LeftShift", "RightShift"},
    CurrentOption = {"MouseButton2"},
    Flag = "Aimbot_TriggerKey",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.TriggerKey = v[1]
        end
    end
})

MainTab:CreateToggle({
    Name = "Toggle Mode (Hold otherwise)",
    CurrentValue = false,
    Flag = "Aimbot_Toggle",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.Toggle = v
        end
    end
})

-- ══════════════════════════════════════════════════
--  AIMBOT TAB - CAMERA MODE SETTINGS
-- ══════════════════════════════════════════════════
AimbotTab:CreateSection("Camera Mode Settings")

AimbotTab:CreateSlider({
    Name = "Camera Sensitivity (seconds)",
    Range = {0, 2},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0,
    Flag = "Camera_Sensitivity",
    Callback = function(v)
        if Aimbot and Aimbot.Settings and Aimbot.Settings.Camera then
            Aimbot.Settings.Camera.Sensitivity = v
        end
    end
})

AimbotTab:CreateSlider({
    Name = "Camera Smoothness",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 1,
    Flag = "Camera_Smoothness",
    Callback = function(v)
        if Aimbot and Aimbot.Settings and Aimbot.Settings.Camera then
            Aimbot.Settings.Camera.Smoothness = v
        end
    end
})

AimbotTab:CreateSection("Mouse Mode Settings")

AimbotTab:CreateSlider({
    Name = "Mouse Speed",
    Range = {1, 20},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 3,
    Flag = "Mouse_Speed",
    Callback = function(v)
        if Aimbot and Aimbot.Settings and Aimbot.Settings.Mouse then
            Aimbot.Settings.Mouse.Speed = v
        end
    end
})

AimbotTab:CreateSlider({
    Name = "Mouse Smoothness",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "Mouse_Smoothness",
    Callback = function(v)
        if Aimbot and Aimbot.Settings and Aimbot.Settings.Mouse then
            Aimbot.Settings.Mouse.Smoothness = v
        end
    end
})

AimbotTab:CreateSlider({
    Name = "Max Step (pixels/frame)",
    Range = {10, 200},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 50,
    Flag = "Mouse_MaxStep",
    Callback = function(v)
        if Aimbot and Aimbot.Settings and Aimbot.Settings.Mouse then
            Aimbot.Settings.Mouse.MaxStep = v
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Third Person Mode (Mouse only)",
    CurrentValue = false,
    Flag = "Aimbot_ThirdPerson",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.ThirdPerson = v
        end
    end
})

AimbotTab:CreateSection("Targeting Filters")

AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "Aimbot_TeamCheck",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.TeamCheck = v
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Alive Check",
    CurrentValue = true,
    Flag = "Aimbot_AliveCheck",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.AliveCheck = v
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "Aimbot_WallCheck",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.WallCheck = v
        end
    end
})

-- ══════════════════════════════════════════════════
--  VISUALS TAB
-- ══════════════════════════════════════════════════
VisualsTab:CreateSection("FOV Circle Settings")

VisualsTab:CreateToggle({
    Name = "Enable FOV Circle",
    CurrentValue = true,
    Flag = "FOV_Enabled",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.Enabled = v
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "FOV_Visible",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.Visible = v
        end
    end
})

VisualsTab:CreateSlider({
    Name = "FOV Size",
    Range = {30, 500},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 90,
    Flag = "FOV_Amount",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.Amount = v
        end
    end
})

VisualsTab:CreateSlider({
    Name = "FOV Transparency",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "FOV_Transparency",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.Transparency = v
        end
    end
})

VisualsTab:CreateSlider({
    Name = "FOV Thickness",
    Range = {1, 5},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 1,
    Flag = "FOV_Thickness",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.Thickness = v
        end
    end
})

VisualsTab:CreateToggle({
    Name = "FOV Filled",
    CurrentValue = false,
    Flag = "FOV_Filled",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.Filled = v
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "FOV Default Color",
    Color = Color3fromRGB(255, 255, 255),
    Flag = "FOV_Color",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.Color = v
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "FOV Locked Color",
    Color = Color3fromRGB(255, 70, 70),
    Flag = "FOV_LockedColor",
    Callback = function(v)
        if Aimbot and Aimbot.FOVSettings then
            Aimbot.FOVSettings.LockedColor = v
        end
    end
})

VisualsTab:CreateSection("ESP Settings")

VisualsTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = true,
    Flag = "ESP_Enabled",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.ESPSettings.Enabled = v
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Display Name",
    CurrentValue = true,
    Flag = "ESP_DisplayName",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.ESPSettings.DisplayName = v
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Display Health",
    CurrentValue = true,
    Flag = "ESP_DisplayHealth",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.ESPSettings.DisplayHealth = v
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Display Distance",
    CurrentValue = true,
    Flag = "ESP_DisplayDistance",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.ESPSettings.DisplayDistance = v
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "ESP Text Color",
    Color = Color3fromRGB(255, 255, 255),
    Flag = "ESP_TextColor",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.ESPSettings.TextColor = v
        end
    end
})

VisualsTab:CreateSlider({
    Name = "ESP Text Size",
    Range = {10, 30},
    Increment = 1,
    Suffix = "pt",
    CurrentValue = 14,
    Flag = "ESP_TextSize",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.ESPSettings.TextSize = v
        end
    end
})

VisualsTab:CreateSection("Tracer Settings")

VisualsTab:CreateToggle({
    Name = "Enable Tracers",
    CurrentValue = true,
    Flag = "Tracers_Enabled",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.TracersSettings.Enabled = v
        end
    end
})

VisualsTab:CreateDropdown({
    Name = "Tracer Type",
    Options = {"Bottom", "Center", "Mouse"},
    CurrentOption = {"Bottom"},
    Flag = "Tracers_Type",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            local typeMap = {["Bottom"] = 1, ["Center"] = 2, ["Mouse"] = 3}
            WallHack.Visuals.TracersSettings.Type = typeMap[v[1]]
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Color3fromRGB(255, 255, 255),
    Flag = "Tracers_Color",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.TracersSettings.Color = v
        end
    end
})

VisualsTab:CreateSection("Box Settings")

VisualsTab:CreateToggle({
    Name = "Enable Boxes",
    CurrentValue = true,
    Flag = "Box_Enabled",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.BoxSettings.Enabled = v
        end
    end
})

VisualsTab:CreateDropdown({
    Name = "Box Type",
    Options = {"3D Box", "2D Box"},
    CurrentOption = {"3D Box"},
    Flag = "Box_Type",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.BoxSettings.Type = v[1] == "3D Box" and 1 or 2
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "Box Color",
    Color = Color3fromRGB(255, 255, 255),
    Flag = "Box_Color",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.BoxSettings.Color = v
        end
    end
})

VisualsTab:CreateSection("Head Dot")

VisualsTab:CreateToggle({
    Name = "Enable Head Dot",
    CurrentValue = true,
    Flag = "HeadDot_Enabled",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.HeadDotSettings.Enabled = v
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "Head Dot Color",
    Color = Color3fromRGB(255, 255, 255),
    Flag = "HeadDot_Color",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.HeadDotSettings.Color = v
        end
    end
})

VisualsTab:CreateSection("Health Bar")

VisualsTab:CreateToggle({
    Name = "Enable Health Bar",
    CurrentValue = false,
    Flag = "HealthBar_Enabled",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            WallHack.Visuals.HealthBarSettings.Enabled = v
        end
    end
})

VisualsTab:CreateDropdown({
    Name = "Health Bar Position",
    Options = {"Top", "Bottom", "Left", "Right"},
    CurrentOption = {"Left"},
    Flag = "HealthBar_Type",
    Callback = function(v)
        if WallHack and WallHack.Visuals then
            local posMap = {["Top"] = 1, ["Bottom"] = 2, ["Left"] = 3, ["Right"] = 4}
            WallHack.Visuals.HealthBarSettings.Type = posMap[v[1]]
        end
    end
})

VisualsTab:CreateSection("Crosshair")

VisualsTab:CreateToggle({
    Name = "Enable Custom Crosshair",
    CurrentValue = false,
    Flag = "Crosshair_Enabled",
    Callback = function(v)
        if WallHack and WallHack.Crosshair then
            WallHack.Crosshair.Settings.Enabled = v
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "Crosshair Color",
    Color = Color3fromRGB(0, 255, 0),
    Flag = "Crosshair_Color",
    Callback = function(v)
        if WallHack and WallHack.Crosshair then
            WallHack.Crosshair.Settings.Color = v
        end
    end
})

VisualsTab:CreateSlider({
    Name = "Crosshair Size",
    Range = {5, 30},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 12,
    Flag = "Crosshair_Size",
    Callback = function(v)
        if WallHack and WallHack.Crosshair then
            WallHack.Crosshair.Settings.Size = v
        end
    end
})

-- ══════════════════════════════════════════════════
--  UTILITY TAB
-- ══════════════════════════════════════════════════
UtilityTab:CreateSection("Module Controls")

UtilityTab:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        if Aimbot and Aimbot.Functions then
            Aimbot.Functions:ResetSettings()
        end
        if WallHack and WallHack.Functions then
            WallHack.Functions:ResetSettings()
        end
    end
})

UtilityTab:CreateButton({
    Name = "Restart Modules",
    Callback = function()
        if Aimbot and Aimbot.Functions then
            Aimbot.Functions:Restart()
        end
        if WallHack and WallHack.Functions then
            WallHack.Functions:Restart()
        end
    end
})

UtilityTab:CreateButton({
    Name = "Unload",
    Callback = function()
        if Aimbot and Aimbot.Functions then
            Aimbot.Functions:Destroy()
        end
        if WallHack and WallHack.Functions then
            WallHack.Functions:Destroy()
        end
        getgenv().AirHub = nil
        Rayfield:Destroy()
    end
})

UtilityTab:CreateSection("Wallhack Filters")

UtilityTab:CreateToggle({
    Name = "Wallhack Team Check",
    CurrentValue = false,
    Flag = "Wallhack_TeamCheck",
    Callback = function(v)
        if WallHack and WallHack.Settings then
            WallHack.Settings.TeamCheck = v
        end
    end
})

UtilityTab:CreateToggle({
    Name = "Wallhack Alive Check",
    CurrentValue = true,
    Flag = "Wallhack_AliveCheck",
    Callback = function(v)
        if WallHack and WallHack.Settings then
            WallHack.Settings.AliveCheck = v
        end
    end
})

UtilityTab:CreateSlider({
    Name = "Wallhack Max Distance",
    Range = {0, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "Wallhack_MaxDistance",
    Callback = function(v)
        if WallHack and WallHack.Settings then
            WallHack.Settings.MaxDistance = v
        end
    end
})

-- Initialize with default mode
if Aimbot and Aimbot.Functions and Aimbot.Functions.SetMode then
    Aimbot.Functions:SetMode("Camera")
end
