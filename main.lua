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
local MainTab    = Window:CreateTab("Main",     4483362458)
local AimbotTab  = Window:CreateTab("Aimbot",   4483362458)
local WallhackTab = Window:CreateTab("Wallhack",4483362458)
local UtilityTab = Window:CreateTab("Utility",  4483362458)

-- ══════════════════════════════════════════════════
--  MAIN TAB
-- ══════════════════════════════════════════════════
MainTab:CreateSection("General")

MainTab:CreateToggle({ Name="Enable Aimbot", CurrentValue=false, Flag="Aimbot_Enabled",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.Enabled=v end end })

MainTab:CreateToggle({ Name="Enable Wallhack", CurrentValue=false, Flag="Wallhack_Enabled",
    Callback=function(v) if WallHack and WallHack.Settings then WallHack.Settings.Enabled=v end end })

MainTab:CreateDropdown({ Name="Aimbot Lock Part", Options={"Head","Torso","HumanoidRootPart","UpperTorso","LowerTorso"},
    CurrentOption={"Head"}, Flag="Aimbot_LockPart",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.LockPart=v[1] end end })

MainTab:CreateSlider({ Name="Aimbot Sensitivity", Range={0,2}, Increment=0.01, Suffix="s",
    CurrentValue=0, Flag="Aimbot_Sensitivity",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.Sensitivity=v end end })

MainTab:CreateToggle({ Name="Aimbot Toggle Mode", CurrentValue=false, Flag="Aimbot_Toggle",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.Toggle=v end end })

MainTab:CreateDropdown({ Name="Aimbot Trigger Key",
    Options={"MouseButton1","MouseButton2","MouseButton3","E","Q","F","C","X","Z","V"},
    CurrentOption={"MouseButton2"}, Flag="Aimbot_TriggerKey",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.TriggerKey=v[1] end end })

-- ══════════════════════════════════════════════════
--  AIMBOT TAB
-- ══════════════════════════════════════════════════
AimbotTab:CreateSection("Targeting")

AimbotTab:CreateToggle({ Name="Team Check", CurrentValue=false, Flag="Aimbot_TeamCheck",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.TeamCheck=v end end })

AimbotTab:CreateToggle({ Name="Alive Check", CurrentValue=true, Flag="Aimbot_AliveCheck",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.AliveCheck=v end end })

AimbotTab:CreateToggle({ Name="Wall Check", CurrentValue=false, Flag="Aimbot_WallCheck",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.WallCheck=v end end })

AimbotTab:CreateToggle({ Name="Third Person Mode", CurrentValue=false, Flag="Aimbot_ThirdPerson",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.ThirdPerson=v end end })

AimbotTab:CreateSlider({ Name="Third Person Sensitivity", Range={1,10}, Increment=0.1, Suffix="x",
    CurrentValue=3, Flag="Aimbot_ThirdPersonSens",
    Callback=function(v) if Aimbot and Aimbot.Settings then Aimbot.Settings.ThirdPersonSensitivity=v end end })

AimbotTab:CreateSection("FOV Settings")

AimbotTab:CreateToggle({ Name="Enable FOV", CurrentValue=true, Flag="FOV_Enabled",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.Enabled=v end end })

AimbotTab:CreateToggle({ Name="Show FOV Circle", CurrentValue=true, Flag="FOV_Visible",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.Visible=v end end })

AimbotTab:CreateSlider({ Name="FOV Size", Range={30,500}, Increment=1, Suffix="px",
    CurrentValue=90, Flag="FOV_Amount",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.Amount=v end end })

AimbotTab:CreateSlider({ Name="FOV Transparency", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0.5, Flag="FOV_Transparency",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.Transparency=v end end })

AimbotTab:CreateSlider({ Name="FOV Thickness", Range={1,5}, Increment=1, Suffix="px",
    CurrentValue=1, Flag="FOV_Thickness",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.Thickness=v end end })

AimbotTab:CreateToggle({ Name="FOV Filled", CurrentValue=false, Flag="FOV_Filled",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.Filled=v end end })

AimbotTab:CreateColorPicker({ Name="FOV Color", Color=Color3fromRGB(255,255,255), Flag="FOV_Color",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.Color=v end end })

AimbotTab:CreateColorPicker({ Name="FOV Locked Color", Color=Color3fromRGB(255,70,70), Flag="FOV_LockedColor",
    Callback=function(v) if Aimbot and Aimbot.FOVSettings then Aimbot.FOVSettings.LockedColor=v end end })

AimbotTab:CreateSection("Silent Aim")

AimbotTab:CreateToggle({ Name="Enable Silent Aim", CurrentValue=false, Flag="SA_Enabled",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.Enabled=v end end })

AimbotTab:CreateDropdown({ Name="Silent Aim Lock Part",
    Options={"Head","Torso","HumanoidRootPart","UpperTorso","LowerTorso"},
    CurrentOption={"Head"}, Flag="SA_LockPart",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.LockPart=v[1] end end })

AimbotTab:CreateToggle({ Name="SA Team Check", CurrentValue=false, Flag="SA_TeamCheck",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.TeamCheck=v end end })

AimbotTab:CreateToggle({ Name="SA Alive Check", CurrentValue=true, Flag="SA_AliveCheck",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.AliveCheck=v end end })

AimbotTab:CreateToggle({ Name="SA Wall Check", CurrentValue=false, Flag="SA_WallCheck",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.WallCheck=v end end })

AimbotTab:CreateToggle({ Name="Use FOV Limit", CurrentValue=true, Flag="SA_UseFOV",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.UseFOV=v end end })

AimbotTab:CreateSlider({ Name="SA FOV Radius", Range={10,500}, Increment=1, Suffix="px",
    CurrentValue=180, Flag="SA_FOVAmount",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.FOVAmount=v end end })

AimbotTab:CreateSlider({ Name="SA Prediction", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0, Flag="SA_Prediction",
    Callback=function(v) if Aimbot and Aimbot.SilentAim then Aimbot.SilentAim.Prediction=v end end })

-- ══════════════════════════════════════════════════
--  WALLHACK TAB
-- ══════════════════════════════════════════════════
WallhackTab:CreateSection("General Settings")

WallhackTab:CreateToggle({ Name="Team Check", CurrentValue=false, Flag="Wallhack_TeamCheck",
    Callback=function(v) if WallHack and WallHack.Settings then WallHack.Settings.TeamCheck=v end end })

WallhackTab:CreateToggle({ Name="Alive Check", CurrentValue=true, Flag="Wallhack_AliveCheck",
    Callback=function(v) if WallHack and WallHack.Settings then WallHack.Settings.AliveCheck=v end end })

WallhackTab:CreateSlider({ Name="Max Distance", Range={0,5000}, Increment=50, Suffix="studs",
    CurrentValue=1000, Flag="Wallhack_MaxDistance",
    Callback=function(v) if WallHack and WallHack.Settings then WallHack.Settings.MaxDistance=v end end })

WallhackTab:CreateSection("ESP Settings")

WallhackTab:CreateToggle({ Name="Enable ESP", CurrentValue=true, Flag="ESP_Enabled",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ESPSettings.Enabled=v end end })

WallhackTab:CreateToggle({ Name="Display Name", CurrentValue=true, Flag="ESP_DisplayName",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ESPSettings.DisplayName=v end end })

WallhackTab:CreateToggle({ Name="Display Health", CurrentValue=true, Flag="ESP_DisplayHealth",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ESPSettings.DisplayHealth=v end end })

WallhackTab:CreateToggle({ Name="Display Distance", CurrentValue=true, Flag="ESP_DisplayDistance",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ESPSettings.DisplayDistance=v end end })

WallhackTab:CreateColorPicker({ Name="ESP Text Color", Color=Color3fromRGB(255,255,255), Flag="ESP_TextColor",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ESPSettings.TextColor=v end end })

WallhackTab:CreateSlider({ Name="ESP Text Size", Range={10,30}, Increment=1, Suffix="pt",
    CurrentValue=14, Flag="ESP_TextSize",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ESPSettings.TextSize=v end end })

WallhackTab:CreateSlider({ Name="ESP Transparency", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0.7, Flag="ESP_Transparency",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ESPSettings.TextTransparency=v end end })

WallhackTab:CreateSection("Tracer Settings")

WallhackTab:CreateToggle({ Name="Enable Tracers", CurrentValue=true, Flag="Tracers_Enabled",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.TracersSettings.Enabled=v end end })

WallhackTab:CreateDropdown({ Name="Tracer Type", Options={"Bottom","Center","Mouse"},
    CurrentOption={"Bottom"}, Flag="Tracers_Type",
    Callback=function(v) if WallHack and WallHack.Visuals then
        WallHack.Visuals.TracersSettings.Type = v[1]=="Bottom" and 1 or v[1]=="Center" and 2 or 3
    end end })

WallhackTab:CreateColorPicker({ Name="Tracer Color", Color=Color3fromRGB(255,255,255), Flag="Tracers_Color",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.TracersSettings.Color=v end end })

WallhackTab:CreateSection("Box Settings")

WallhackTab:CreateToggle({ Name="Enable Boxes", CurrentValue=true, Flag="Box_Enabled",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.BoxSettings.Enabled=v end end })

WallhackTab:CreateDropdown({ Name="Box Type", Options={"3D Box","2D Box"},
    CurrentOption={"3D Box"}, Flag="Box_Type",
    Callback=function(v) if WallHack and WallHack.Visuals then
        WallHack.Visuals.BoxSettings.Type = v[1]=="3D Box" and 1 or 2
    end end })

WallhackTab:CreateColorPicker({ Name="Box Color", Color=Color3fromRGB(255,255,255), Flag="Box_Color",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.BoxSettings.Color=v end end })

WallhackTab:CreateSection("Head Dot Settings")

WallhackTab:CreateToggle({ Name="Enable Head Dot", CurrentValue=true, Flag="HeadDot_Enabled",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.HeadDotSettings.Enabled=v end end })

WallhackTab:CreateColorPicker({ Name="Head Dot Color", Color=Color3fromRGB(255,255,255), Flag="HeadDot_Color",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.HeadDotSettings.Color=v end end })

WallhackTab:CreateSection("Chams Settings")

WallhackTab:CreateToggle({ Name="Enable Chams", CurrentValue=false, Flag="Chams_Enabled",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ChamsSettings.Enabled=v end end })

WallhackTab:CreateColorPicker({ Name="Chams Color", Color=Color3fromRGB(255,255,255), Flag="Chams_Color",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ChamsSettings.Color=v end end })

WallhackTab:CreateSlider({ Name="Chams Transparency", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0.2, Flag="Chams_Transparency",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ChamsSettings.Transparency=v end end })

WallhackTab:CreateToggle({ Name="Full Body Chams", CurrentValue=false, Flag="Chams_EntireBody",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.ChamsSettings.EntireBody=v end end })

WallhackTab:CreateSection("Health Bar Settings")

WallhackTab:CreateToggle({ Name="Enable Health Bar", CurrentValue=false, Flag="HealthBar_Enabled",
    Callback=function(v) if WallHack and WallHack.Visuals then WallHack.Visuals.HealthBarSettings.Enabled=v end end })

WallhackTab:CreateDropdown({ Name="Health Bar Position", Options={"Top","Bottom","Left","Right"},
    CurrentOption={"Left"}, Flag="HealthBar_Type",
    Callback=function(v) if WallHack and WallHack.Visuals then
        local t = v[1]=="Top" and 1 or v[1]=="Bottom" and 2 or v[1]=="Left" and 3 or 4
        WallHack.Visuals.HealthBarSettings.Type=t
    end end })

WallhackTab:CreateSection("Crosshair Settings")

WallhackTab:CreateToggle({ Name="Enable Custom Crosshair", CurrentValue=false, Flag="Crosshair_Enabled",
    Callback=function(v) if WallHack and WallHack.Crosshair then WallHack.Crosshair.Settings.Enabled=v end end })

WallhackTab:CreateColorPicker({ Name="Crosshair Color", Color=Color3fromRGB(0,255,0), Flag="Crosshair_Color",
    Callback=function(v) if WallHack and WallHack.Crosshair then WallHack.Crosshair.Settings.Color=v end end })

WallhackTab:CreateSlider({ Name="Crosshair Size", Range={5,30}, Increment=1, Suffix="px",
    CurrentValue=12, Flag="Crosshair_Size",
    Callback=function(v) if WallHack and WallHack.Crosshair then WallHack.Crosshair.Settings.Size=v end end })

-- ══════════════════════════════════════════════════
--  UTILITY TAB
-- ══════════════════════════════════════════════════
UtilityTab:CreateSection("Controls")

UtilityTab:CreateButton({ Name="Reset All Settings", Callback=function()
    if Aimbot and Aimbot.Functions then Aimbot.Functions:ResetSettings() end
    if WallHack and WallHack.Functions then WallHack.Functions:ResetSettings() end
end })

UtilityTab:CreateButton({ Name="Restart Modules", Callback=function()
    if Aimbot and Aimbot.Functions then Aimbot.Functions:Restart() end
    if WallHack and WallHack.Functions then WallHack.Functions:Restart() end
end })

UtilityTab:CreateButton({ Name="Unload", Callback=function()
    if Aimbot and Aimbot.Functions then Aimbot.Functions:Exit() end
    if WallHack and WallHack.Functions then WallHack.Functions:Exit() end
    getgenv().AirHub = nil
    Rayfield:Destroy()
end })
