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

--// Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ══════════════════════════════════════════════════
--  CONFIG SYSTEM
-- ══════════════════════════════════════════════════

local CONFIG_FOLDER = "AirHub"
local CONFIG_FILE   = CONFIG_FOLDER .. "/config.json"
local FS = (typeof(isfolder)=="function" and typeof(makefolder)=="function" and typeof(readfile)=="function" and typeof(writefile)=="function" and typeof(isfile)=="function")

local function SaveConfig()
    if not FS then return end
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        local s = {
            -- Aimbot
            Aim_Enabled=Aimbot.Settings.Enabled, Aim_Toggle=Aimbot.Settings.Toggle,
            Aim_TriggerKey=Aimbot.Settings.TriggerKey, Aim_Sensitivity=Aimbot.Settings.Sensitivity,
            Aim_LockPart=Aimbot.Settings.LockPart, Aim_TeamCheck=Aimbot.Settings.TeamCheck,
            Aim_WallCheck=Aimbot.Settings.WallCheck, Aim_AliveCheck=Aimbot.Settings.AliveCheck,
            Aim_ThirdPerson=Aimbot.Settings.ThirdPerson, Aim_3PSens=Aimbot.Settings.ThirdPersonSensitivity,
            -- FOV
            FOV_Enabled=Aimbot.FOVSettings.Enabled, FOV_Visible=Aimbot.FOVSettings.Visible,
            FOV_Amount=Aimbot.FOVSettings.Amount, FOV_Transparency=Aimbot.FOVSettings.Transparency,
            FOV_Thickness=Aimbot.FOVSettings.Thickness, FOV_Filled=Aimbot.FOVSettings.Filled,
            FOV_Color={r=Aimbot.FOVSettings.Color.R,g=Aimbot.FOVSettings.Color.G,b=Aimbot.FOVSettings.Color.B},
            FOV_LockedColor={r=Aimbot.FOVSettings.LockedColor.R,g=Aimbot.FOVSettings.LockedColor.G,b=Aimbot.FOVSettings.LockedColor.B},
            -- WallHack
            WH_Enabled=WallHack.Settings.Enabled, WH_TeamCheck=WallHack.Settings.TeamCheck,
            WH_AliveCheck=WallHack.Settings.AliveCheck, WH_MaxDist=WallHack.Settings.MaxDistance,
            -- ESP
            ESP_Enabled=WallHack.Visuals.ESPSettings.Enabled, ESP_Name=WallHack.Visuals.ESPSettings.DisplayName,
            ESP_Health=WallHack.Visuals.ESPSettings.DisplayHealth, ESP_Dist=WallHack.Visuals.ESPSettings.DisplayDistance,
            ESP_Size=WallHack.Visuals.ESPSettings.TextSize, ESP_Alpha=WallHack.Visuals.ESPSettings.TextTransparency,
            ESP_Color={r=WallHack.Visuals.ESPSettings.TextColor.R,g=WallHack.Visuals.ESPSettings.TextColor.G,b=WallHack.Visuals.ESPSettings.TextColor.B},
            -- Box
            Box_Enabled=WallHack.Visuals.BoxSettings.Enabled, Box_Type=WallHack.Visuals.BoxSettings.Type,
            Box_Color={r=WallHack.Visuals.BoxSettings.Color.R,g=WallHack.Visuals.BoxSettings.Color.G,b=WallHack.Visuals.BoxSettings.Color.B},
            -- Tracers
            Tracer_Enabled=WallHack.Visuals.TracersSettings.Enabled, Tracer_Type=WallHack.Visuals.TracersSettings.Type,
            Tracer_Color={r=WallHack.Visuals.TracersSettings.Color.R,g=WallHack.Visuals.TracersSettings.Color.G,b=WallHack.Visuals.TracersSettings.Color.B},
            -- Head Dot
            HD_Enabled=WallHack.Visuals.HeadDotSettings.Enabled,
            HD_Color={r=WallHack.Visuals.HeadDotSettings.Color.R,g=WallHack.Visuals.HeadDotSettings.Color.G,b=WallHack.Visuals.HeadDotSettings.Color.B},
            -- Chams
            Chams_Enabled=WallHack.Visuals.ChamsSettings.Enabled, Chams_Transparency=WallHack.Visuals.ChamsSettings.Transparency,
            Chams_EntireBody=WallHack.Visuals.ChamsSettings.EntireBody,
            Chams_Color={r=WallHack.Visuals.ChamsSettings.Color.R,g=WallHack.Visuals.ChamsSettings.Color.G,b=WallHack.Visuals.ChamsSettings.Color.B},
            -- Health Bar
            HB_Enabled=WallHack.Visuals.HealthBarSettings.Enabled, HB_Type=WallHack.Visuals.HealthBarSettings.Type,
            -- Crosshair
            XH_Enabled=WallHack.Crosshair.Settings.Enabled, XH_Size=WallHack.Crosshair.Settings.Size,
            XH_Color={r=WallHack.Crosshair.Settings.Color.R,g=WallHack.Crosshair.Settings.Color.G,b=WallHack.Crosshair.Settings.Color.B},
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(s))
    end)
end

local function LoadConfig()
    if not FS then return end
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local s = HttpService:JSONDecode(readfile(CONFIG_FILE))
        local function c(t) return t and Color3.new(t.r,t.g,t.b) or nil end
        local function set(tbl,k,v) if v~=nil then tbl[k]=v end end
        set(Aimbot.Settings,"Enabled",s.Aim_Enabled) set(Aimbot.Settings,"Toggle",s.Aim_Toggle)
        set(Aimbot.Settings,"TriggerKey",s.Aim_TriggerKey) set(Aimbot.Settings,"Sensitivity",s.Aim_Sensitivity)
        set(Aimbot.Settings,"LockPart",s.Aim_LockPart) set(Aimbot.Settings,"TeamCheck",s.Aim_TeamCheck)
        set(Aimbot.Settings,"WallCheck",s.Aim_WallCheck) set(Aimbot.Settings,"AliveCheck",s.Aim_AliveCheck)
        set(Aimbot.Settings,"ThirdPerson",s.Aim_ThirdPerson) set(Aimbot.Settings,"ThirdPersonSensitivity",s.Aim_3PSens)
        set(Aimbot.FOVSettings,"Enabled",s.FOV_Enabled) set(Aimbot.FOVSettings,"Visible",s.FOV_Visible)
        set(Aimbot.FOVSettings,"Amount",s.FOV_Amount) set(Aimbot.FOVSettings,"Transparency",s.FOV_Transparency)
        set(Aimbot.FOVSettings,"Thickness",s.FOV_Thickness) set(Aimbot.FOVSettings,"Filled",s.FOV_Filled)
        if s.FOV_Color then Aimbot.FOVSettings.Color = c(s.FOV_Color) end
        if s.FOV_LockedColor then Aimbot.FOVSettings.LockedColor = c(s.FOV_LockedColor) end
        set(WallHack.Settings,"Enabled",s.WH_Enabled) set(WallHack.Settings,"TeamCheck",s.WH_TeamCheck)
        set(WallHack.Settings,"AliveCheck",s.WH_AliveCheck) set(WallHack.Settings,"MaxDistance",s.WH_MaxDist)
        set(WallHack.Visuals.ESPSettings,"Enabled",s.ESP_Enabled) set(WallHack.Visuals.ESPSettings,"DisplayName",s.ESP_Name)
        set(WallHack.Visuals.ESPSettings,"DisplayHealth",s.ESP_Health) set(WallHack.Visuals.ESPSettings,"DisplayDistance",s.ESP_Dist)
        set(WallHack.Visuals.ESPSettings,"TextSize",s.ESP_Size) set(WallHack.Visuals.ESPSettings,"TextTransparency",s.ESP_Alpha)
        if s.ESP_Color then WallHack.Visuals.ESPSettings.TextColor = c(s.ESP_Color) end
        set(WallHack.Visuals.BoxSettings,"Enabled",s.Box_Enabled) set(WallHack.Visuals.BoxSettings,"Type",s.Box_Type)
        if s.Box_Color then WallHack.Visuals.BoxSettings.Color = c(s.Box_Color) end
        set(WallHack.Visuals.TracersSettings,"Enabled",s.Tracer_Enabled) set(WallHack.Visuals.TracersSettings,"Type",s.Tracer_Type)
        if s.Tracer_Color then WallHack.Visuals.TracersSettings.Color = c(s.Tracer_Color) end
        set(WallHack.Visuals.HeadDotSettings,"Enabled",s.HD_Enabled)
        if s.HD_Color then WallHack.Visuals.HeadDotSettings.Color = c(s.HD_Color) end
        set(WallHack.Visuals.ChamsSettings,"Enabled",s.Chams_Enabled) set(WallHack.Visuals.ChamsSettings,"Transparency",s.Chams_Transparency)
        set(WallHack.Visuals.ChamsSettings,"EntireBody",s.Chams_EntireBody)
        if s.Chams_Color then WallHack.Visuals.ChamsSettings.Color = c(s.Chams_Color) end
        set(WallHack.Visuals.HealthBarSettings,"Enabled",s.HB_Enabled) set(WallHack.Visuals.HealthBarSettings,"Type",s.HB_Type)
        set(WallHack.Crosshair.Settings,"Enabled",s.XH_Enabled) set(WallHack.Crosshair.Settings,"Size",s.XH_Size)
        if s.XH_Color then WallHack.Crosshair.Settings.Color = c(s.XH_Color) end
    end)
end

task.defer(function()
    if FS and isfolder(CONFIG_FOLDER) and isfile(CONFIG_FILE) then LoadConfig() end
end)

-- ══════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "SORROW AIRHUB V3",
    LoadingTitle = "SORROW AIRHUB",
    LoadingSubtitle = "sorrow.cc | build 2026",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════
--  TABS
-- ══════════════════════════════════════════════════

local MainTab    = Window:CreateTab("MAIN",      4483362458)
local AimbotTab  = Window:CreateTab("AIMBOT",    4483362458)
local WallhackTab = Window:CreateTab("WALLHACK", 4483362458)
local UtilityTab = Window:CreateTab("UTILITY",   4483362458)

-- ══════════════════════════════════════════════════
--  MAIN TAB
-- ══════════════════════════════════════════════════

local MainSection = MainTab:CreateSection("GENERAL")

MainSection:CreateToggle({ Name="Enable Aimbot", CurrentValue=false, Flag="Aimbot_Enabled",
    Callback=function(v) Aimbot.Settings.Enabled=v end })

MainSection:CreateToggle({ Name="Enable Wallhack", CurrentValue=false, Flag="Wallhack_Enabled",
    Callback=function(v) WallHack.Settings.Enabled=v end })

MainSection:CreateDropdown({ Name="Aim Lock Part", Options={"Head","Torso","HumanoidRootPart","UpperTorso","LowerTorso"},
    CurrentOption={"Head"}, Flag="Aimbot_LockPart",
    Callback=function(v) Aimbot.Settings.LockPart=v[1] end })

MainSection:CreateSlider({ Name="Aimbot Sensitivity", Range={0,2}, Increment=0.01, Suffix="s",
    CurrentValue=0, Flag="Aimbot_Sensitivity",
    Callback=function(v) Aimbot.Settings.Sensitivity=v end })

MainSection:CreateToggle({ Name="Aimbot Toggle Mode", CurrentValue=false, Flag="Aimbot_Toggle",
    Callback=function(v) Aimbot.Settings.Toggle=v end })

MainSection:CreateDropdown({ Name="Trigger Key",
    Options={"MouseButton1","MouseButton2","MouseButton3","E","Q","F","C","X","Z","V"},
    CurrentOption={"MouseButton2"}, Flag="Aimbot_TriggerKey",
    Callback=function(v) Aimbot.Settings.TriggerKey=v[1] end })

-- ══════════════════════════════════════════════════
--  AIMBOT TAB
-- ══════════════════════════════════════════════════

local AimChecksSection = AimbotTab:CreateSection("TARGETING")

AimChecksSection:CreateToggle({ Name="Team Check", CurrentValue=false, Flag="Aimbot_TeamCheck",
    Callback=function(v) Aimbot.Settings.TeamCheck=v end })

AimChecksSection:CreateToggle({ Name="Alive Check", CurrentValue=true, Flag="Aimbot_AliveCheck",
    Callback=function(v) Aimbot.Settings.AliveCheck=v end })

AimChecksSection:CreateToggle({ Name="Wall Check", CurrentValue=false, Flag="Aimbot_WallCheck",
    Callback=function(v) Aimbot.Settings.WallCheck=v end })

AimChecksSection:CreateToggle({ Name="Third Person Mode", CurrentValue=false, Flag="Aimbot_ThirdPerson",
    Callback=function(v) Aimbot.Settings.ThirdPerson=v end })

AimChecksSection:CreateSlider({ Name="Third Person Sensitivity", Range={1,10}, Increment=0.1, Suffix="x",
    CurrentValue=3, Flag="Aimbot_ThirdPersonSens",
    Callback=function(v) Aimbot.Settings.ThirdPersonSensitivity=v end })

local FOVSection = AimbotTab:CreateSection("FOV")

FOVSection:CreateToggle({ Name="Enable FOV", CurrentValue=true, Flag="FOV_Enabled",
    Callback=function(v) Aimbot.FOVSettings.Enabled=v end })

FOVSection:CreateToggle({ Name="Show FOV Circle", CurrentValue=true, Flag="FOV_Visible",
    Callback=function(v) Aimbot.FOVSettings.Visible=v end })

FOVSection:CreateSlider({ Name="FOV Size", Range={30,500}, Increment=1, Suffix="px",
    CurrentValue=90, Flag="FOV_Amount",
    Callback=function(v) Aimbot.FOVSettings.Amount=v end })

FOVSection:CreateSlider({ Name="FOV Transparency", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0.5, Flag="FOV_Transparency",
    Callback=function(v) Aimbot.FOVSettings.Transparency=v end })

FOVSection:CreateSlider({ Name="FOV Thickness", Range={1,5}, Increment=1, Suffix="px",
    CurrentValue=1, Flag="FOV_Thickness",
    Callback=function(v) Aimbot.FOVSettings.Thickness=v end })

FOVSection:CreateToggle({ Name="FOV Filled", CurrentValue=false, Flag="FOV_Filled",
    Callback=function(v) Aimbot.FOVSettings.Filled=v end })

FOVSection:CreateColorPicker({ Name="FOV Color", Color=Color3fromRGB(255,255,255), Flag="FOV_Color",
    Callback=function(v) Aimbot.FOVSettings.Color=v end })

FOVSection:CreateColorPicker({ Name="FOV Locked Color", Color=Color3fromRGB(255,70,70), Flag="FOV_LockedColor",
    Callback=function(v) Aimbot.FOVSettings.LockedColor=v end })

-- Silent Aim
local SilentSection = AimbotTab:CreateSection("SILENT AIM")

SilentSection:CreateToggle({ Name="Enable Silent Aim", CurrentValue=false, Flag="SA_Enabled",
    Callback=function(v) Aimbot.SilentAim.Enabled=v end })

SilentSection:CreateDropdown({ Name="Lock Part", Options={"Head","Torso","HumanoidRootPart","UpperTorso"},
    CurrentOption={"Head"}, Flag="SA_LockPart",
    Callback=function(v) Aimbot.SilentAim.LockPart=v[1] end })

SilentSection:CreateToggle({ Name="Team Check", CurrentValue=false, Flag="SA_TeamCheck",
    Callback=function(v) Aimbot.SilentAim.TeamCheck=v end })

SilentSection:CreateToggle({ Name="Alive Check", CurrentValue=true, Flag="SA_AliveCheck",
    Callback=function(v) Aimbot.SilentAim.AliveCheck=v end })

SilentSection:CreateToggle({ Name="Wall Check", CurrentValue=false, Flag="SA_WallCheck",
    Callback=function(v) Aimbot.SilentAim.WallCheck=v end })

SilentSection:CreateToggle({ Name="Use FOV Limit", CurrentValue=true, Flag="SA_UseFOV",
    Callback=function(v) Aimbot.SilentAim.UseFOV=v end })

SilentSection:CreateSlider({ Name="FOV Radius", Range={10,500}, Increment=1, Suffix="px",
    CurrentValue=180, Flag="SA_FOVAmount",
    Callback=function(v) Aimbot.SilentAim.FOVAmount=v end })

SilentSection:CreateSlider({ Name="Prediction", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0, Flag="SA_Prediction",
    Callback=function(v) Aimbot.SilentAim.Prediction=v end })

-- ══════════════════════════════════════════════════
--  WALLHACK TAB
-- ══════════════════════════════════════════════════

local WHGeneral = WallhackTab:CreateSection("GENERAL")

WHGeneral:CreateToggle({ Name="Team Check", CurrentValue=false, Flag="WH_TeamCheck",
    Callback=function(v) WallHack.Settings.TeamCheck=v end })

WHGeneral:CreateToggle({ Name="Alive Check", CurrentValue=true, Flag="WH_AliveCheck",
    Callback=function(v) WallHack.Settings.AliveCheck=v end })

WHGeneral:CreateSlider({ Name="Max Distance (0=unlimited)", Range={0,5000}, Increment=50, Suffix="studs",
    CurrentValue=1000, Flag="WH_MaxDist",
    Callback=function(v) WallHack.Settings.MaxDistance=v end })

local ESPSection = WallhackTab:CreateSection("ESP")

ESPSection:CreateToggle({ Name="Enable ESP", CurrentValue=true, Flag="ESP_Enabled",
    Callback=function(v) WallHack.Visuals.ESPSettings.Enabled=v end })

ESPSection:CreateToggle({ Name="Display Name", CurrentValue=true, Flag="ESP_DisplayName",
    Callback=function(v) WallHack.Visuals.ESPSettings.DisplayName=v end })

ESPSection:CreateToggle({ Name="Display Health", CurrentValue=true, Flag="ESP_DisplayHealth",
    Callback=function(v) WallHack.Visuals.ESPSettings.DisplayHealth=v end })

ESPSection:CreateToggle({ Name="Display Distance", CurrentValue=true, Flag="ESP_DisplayDistance",
    Callback=function(v) WallHack.Visuals.ESPSettings.DisplayDistance=v end })

ESPSection:CreateSlider({ Name="Text Size", Range={10,30}, Increment=1, Suffix="pt",
    CurrentValue=14, Flag="ESP_TextSize",
    Callback=function(v) WallHack.Visuals.ESPSettings.TextSize=v end })

ESPSection:CreateSlider({ Name="Text Alpha", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0.7, Flag="ESP_Alpha",
    Callback=function(v) WallHack.Visuals.ESPSettings.TextTransparency=v end })

ESPSection:CreateColorPicker({ Name="Text Color", Color=Color3fromRGB(255,255,255), Flag="ESP_TextColor",
    Callback=function(v) WallHack.Visuals.ESPSettings.TextColor=v end })

local TracersSection = WallhackTab:CreateSection("TRACERS")

TracersSection:CreateToggle({ Name="Enable Tracers", CurrentValue=true, Flag="Tracer_Enabled",
    Callback=function(v) WallHack.Visuals.TracersSettings.Enabled=v end })

TracersSection:CreateDropdown({ Name="Tracer Origin", Options={"Bottom","Center","Mouse"},
    CurrentOption={"Bottom"}, Flag="Tracer_Type",
    Callback=function(v) WallHack.Visuals.TracersSettings.Type = v[1]=="Bottom" and 1 or v[1]=="Center" and 2 or 3 end })

TracersSection:CreateColorPicker({ Name="Tracer Color", Color=Color3fromRGB(255,255,255), Flag="Tracer_Color",
    Callback=function(v) WallHack.Visuals.TracersSettings.Color=v end })

local BoxSection = WallhackTab:CreateSection("BOXES")

BoxSection:CreateToggle({ Name="Enable Boxes", CurrentValue=true, Flag="Box_Enabled",
    Callback=function(v) WallHack.Visuals.BoxSettings.Enabled=v end })

BoxSection:CreateDropdown({ Name="Box Type", Options={"3D Box","2D Box"},
    CurrentOption={"3D Box"}, Flag="Box_Type",
    Callback=function(v) WallHack.Visuals.BoxSettings.Type = v[1]=="3D Box" and 1 or 2 end })

BoxSection:CreateColorPicker({ Name="Box Color", Color=Color3fromRGB(255,255,255), Flag="Box_Color",
    Callback=function(v) WallHack.Visuals.BoxSettings.Color=v end })

local HeadDotSection = WallhackTab:CreateSection("HEAD DOT")

HeadDotSection:CreateToggle({ Name="Enable Head Dot", CurrentValue=true, Flag="HD_Enabled",
    Callback=function(v) WallHack.Visuals.HeadDotSettings.Enabled=v end })

HeadDotSection:CreateColorPicker({ Name="Head Dot Color", Color=Color3fromRGB(255,255,255), Flag="HD_Color",
    Callback=function(v) WallHack.Visuals.HeadDotSettings.Color=v end })

local ChamsSection = WallhackTab:CreateSection("CHAMS")

ChamsSection:CreateToggle({ Name="Enable Chams", CurrentValue=false, Flag="Chams_Enabled",
    Callback=function(v) WallHack.Visuals.ChamsSettings.Enabled=v end })

ChamsSection:CreateToggle({ Name="Full Body (R15)", CurrentValue=false, Flag="Chams_EntireBody",
    Callback=function(v) WallHack.Visuals.ChamsSettings.EntireBody=v end })

ChamsSection:CreateSlider({ Name="Transparency", Range={0,1}, Increment=0.01, Suffix="",
    CurrentValue=0.2, Flag="Chams_Transparency",
    Callback=function(v) WallHack.Visuals.ChamsSettings.Transparency=v end })

ChamsSection:CreateColorPicker({ Name="Chams Color", Color=Color3fromRGB(255,255,255), Flag="Chams_Color",
    Callback=function(v) WallHack.Visuals.ChamsSettings.Color=v end })

local HealthSection = WallhackTab:CreateSection("HEALTH BAR")

HealthSection:CreateToggle({ Name="Enable Health Bar", CurrentValue=false, Flag="HB_Enabled",
    Callback=function(v) WallHack.Visuals.HealthBarSettings.Enabled=v end })

HealthSection:CreateDropdown({ Name="Position", Options={"Top","Bottom","Left","Right"},
    CurrentOption={"Left"}, Flag="HB_Position",
    Callback=function(v) WallHack.Visuals.HealthBarSettings.Type = v[1]=="Top" and 1 or v[1]=="Bottom" and 2 or v[1]=="Left" and 3 or 4 end })

local XhairSection = WallhackTab:CreateSection("CROSSHAIR")

XhairSection:CreateToggle({ Name="Enable Custom Crosshair", CurrentValue=false, Flag="XH_Enabled",
    Callback=function(v) WallHack.Crosshair.Settings.Enabled=v end })

XhairSection:CreateSlider({ Name="Size", Range={5,30}, Increment=1, Suffix="px",
    CurrentValue=12, Flag="XH_Size",
    Callback=function(v) WallHack.Crosshair.Settings.Size=v end })

XhairSection:CreateColorPicker({ Name="Color", Color=Color3fromRGB(0,255,0), Flag="XH_Color",
    Callback=function(v) WallHack.Crosshair.Settings.Color=v end })

-- ══════════════════════════════════════════════════
--  UTILITY TAB
-- ══════════════════════════════════════════════════

local SaveSection = UtilityTab:CreateSection("CONFIG")
local AutoSave = false

task.spawn(function() while task.wait(5) do if AutoSave then SaveConfig() end end end)

SaveSection:CreateToggle({ Name="Auto-Save (every 5s)", CurrentValue=false, Flag="AutoSave",
    Callback=function(v) AutoSave=v; if v then SaveConfig() end end })

SaveSection:CreateButton({ Name="Save Config", Callback=function() SaveConfig() end })
SaveSection:CreateButton({ Name="Load Config", Callback=function() LoadConfig() end })

local ControlSection = UtilityTab:CreateSection("CONTROLS")

ControlSection:CreateButton({ Name="Reset All Settings", Callback=function()
    Aimbot.Functions:ResetSettings()
    WallHack.Functions:ResetSettings()
end })

ControlSection:CreateButton({ Name="Restart Modules", Callback=function()
    Aimbot.Functions:Restart()
    WallHack.Functions:Restart()
end })

ControlSection:CreateButton({ Name="Unload", Callback=function()
    Aimbot.Functions:Exit()
    WallHack.Functions:Exit()
    getgenv().AirHub = nil
    Rayfield:Destroy()
end })
