-- AirHub V3 - Rayfield Version
-- Compatible with most executors

--// Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

--// Environment setup
local env = getgenv or getfenv and getfenv(0) or _G

if env.AirHub then 
    print("AirHub already loaded")
    return 
end
env.AirHub = {}

--// Module URLs
local MODULE_URLS = {
    Aimbot = "https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Aimbot.lua",
    WallHack = "https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Wall_Hack.lua",
}

--// Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

--// Check if Rayfield loaded
if not Rayfield then
    warn("Failed to load Rayfield")
    return
end

--// Variables
local Parts = {
    "Head", "HumanoidRootPart", "Torso",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm",
    "LeftUpperArm", "RightUpperArm", "LeftFoot", "LeftLowerLeg",
    "UpperTorso", "LeftUpperLeg", "RightFoot", "RightLowerLeg",
    "LowerTorso", "RightUpperLeg"
}

local TracersType = {"Bottom", "Center", "Mouse"}
local BoxTypes = {"3D Corner", "2D Square"}
local HBPositions = {"Top", "Bottom", "Left", "Right"}
local XhairFollow = {"Mouse", "Screen Center"}

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "AirHub V3",
    LoadingTitle = "AirHub",
    LoadingSubtitle = "by Air",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AirHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "AirHub",
        Subtitle = "Key System",
        Note = "Join discord for key",
        FileName = "AirHubKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

--// Load modules function
local function loadModules()
    Rayfield:Notify({
        Title = "AirHub",
        Content = "Loading modules...",
        Duration = 2,
        Image = 4483362458
    })
    
    for name, url in pairs(MODULE_URLS) do
        local success, err = pcall(function()
            local content = game:HttpGet(url)
            loadstring(content)()
        end)
        
        if success then
            print("[AirHub] Loaded " .. name)
        else
            warn("[AirHub] Failed to load " .. name .. ": " .. tostring(err))
        end
    end
    
    -- Small delay for modules to initialize
    task.wait(1)
end

-- Load modules first
loadModules()

-- Get module references
local Aimbot = env.AirHub and env.AirHub.Aimbot
local WallHack = env.AirHub and env.AirHub.WallHack

if not Aimbot then
    Rayfield:Notify({
        Title = "AirHub",
        Content = "Aimbot module failed to load",
        Duration = 3,
        Image = 4483362458
    })
end

if not WallHack then
    Rayfield:Notify({
        Title = "AirHub",
        Content = "WallHack module failed to load",
        Duration = 3,
        Image = 4483362458
    })
end

--// Create Tabs
local Tabs = {
    Aimbot = Window:CreateTab("Aimbot", 4483362458),
    SilentAim = Window:CreateTab("Silent Aim", 4483362458),
    Visuals = Window:CreateTab("Visuals", 4483362458),
    Crosshair = Window:CreateTab("Crosshair", 4483362458),
    Settings = Window:CreateTab("Settings", 4483362458)
}

--// ─────────────────────────────────────────────────────────────────────────
--// AIMBOT TAB
--// ─────────────────────────────────────────────────────────────────────────

if Aimbot then
    -- Main Section
    local AimMain = Tabs.Aimbot:CreateSection("Main")
    
    Tabs.Aimbot:CreateToggle({
        Name = "Enable Aimbot",
        CurrentValue = false,
        Flag = "AimbotEnabled",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.Enabled = v
            end
        end
    })
    
    Tabs.Aimbot:CreateToggle({
        Name = "Toggle Mode",
        CurrentValue = false,
        Flag = "AimbotToggle",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.Toggle = v
            end
        end
    })
    
    Tabs.Aimbot:CreateSlider({
        Name = "Smoothing",
        Range = {0, 1},
        Increment = 0.01,
        CurrentValue = 0,
        Flag = "AimbotSmooth",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.Sensitivity = v
            end
        end
    })
    
    Tabs.Aimbot:CreateDropdown({
        Name = "Aim Part",
        Options = Parts,
        CurrentOption = "Head",
        Flag = "AimbotPart",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.LockPart = v
            end
        end
    })
    
    Tabs.Aimbot:CreateKeybind({
        Name = "Trigger Key",
        CurrentKeybind = "MouseButton2",
        HoldToInteract = false,
        Flag = "AimbotKey",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.TriggerKey = v
            end
        end
    })
    
    -- Checks Section
    local AimChecks = Tabs.Aimbot:CreateSection("Checks")
    
    Tabs.Aimbot:CreateToggle({
        Name = "Team Check",
        CurrentValue = false,
        Flag = "AimbotTeam",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.TeamCheck = v
            end
        end
    })
    
    Tabs.Aimbot:CreateToggle({
        Name = "Alive Check",
        CurrentValue = true,
        Flag = "AimbotAlive",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.AliveCheck = v
            end
        end
    })
    
    Tabs.Aimbot:CreateToggle({
        Name = "Wall Check",
        CurrentValue = false,
        Flag = "AimbotWall",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.WallCheck = v
            end
        end
    })
    
    -- FOV Section
    local AimFOV = Tabs.Aimbot:CreateSection("FOV Circle")
    
    Tabs.Aimbot:CreateToggle({
        Name = "Restrict to FOV",
        CurrentValue = false,
        Flag = "FOVEnabled",
        Callback = function(v)
            if Aimbot.FOVSettings then
                Aimbot.FOVSettings.Enabled = v
            end
        end
    })
    
    Tabs.Aimbot:CreateToggle({
        Name = "Show FOV Circle",
        CurrentValue = false,
        Flag = "FOVVisible",
        Callback = function(v)
            if Aimbot.FOVSettings then
                Aimbot.FOVSettings.Visible = v
            end
        end
    })
    
    Tabs.Aimbot:CreateSlider({
        Name = "Radius",
        Range = {10, 500},
        Increment = 1,
        CurrentValue = 90,
        Flag = "FOVRadius",
        Callback = function(v)
            if Aimbot.FOVSettings then
                Aimbot.FOVSettings.Amount = v
            end
        end
    })
    
    Tabs.Aimbot:CreateSlider({
        Name = "Transparency",
        Range = {0, 1},
        Increment = 0.01,
        CurrentValue = 0.5,
        Flag = "FOVTrans",
        Callback = function(v)
            if Aimbot.FOVSettings then
                Aimbot.FOVSettings.Transparency = v
            end
        end
    })
    
    Tabs.Aimbot:CreateColorPicker({
        Name = "Circle Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "FOVColor",
        Callback = function(v)
            if Aimbot.FOVSettings then
                Aimbot.FOVSettings.Color = v
            end
        end
    })
    
    Tabs.Aimbot:CreateColorPicker({
        Name = "Locked Color",
        Color = Color3.fromRGB(255, 70, 70),
        Flag = "FOVLockedColor",
        Callback = function(v)
            if Aimbot.FOVSettings then
                Aimbot.FOVSettings.LockedColor = v
            end
        end
    })
    
    -- Third Person Section
    local AimThird = Tabs.Aimbot:CreateSection("Third Person")
    
    Tabs.Aimbot:CreateToggle({
        Name = "Third Person Mode",
        CurrentValue = false,
        Flag = "ThirdPerson",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.ThirdPerson = v
            end
        end
    })
    
    Tabs.Aimbot:CreateSlider({
        Name = "Sensitivity",
        Range = {1, 10},
        Increment = 0.1,
        CurrentValue = 3,
        Flag = "ThirdPersonSens",
        Callback = function(v)
            if Aimbot.Settings then
                Aimbot.Settings.ThirdPersonSensitivity = v
            end
        end
    })
end

--// ─────────────────────────────────────────────────────────────────────────
--// SILENT AIM TAB
--// ─────────────────────────────────────────────────────────────────────────

if Aimbot then
    local SilentMain = Tabs.SilentAim:CreateSection("Main")
    
    Tabs.SilentAim:CreateToggle({
        Name = "Enable Silent Aim",
        CurrentValue = false,
        Flag = "SAEnabled",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.Enabled = v
            end
        end
    })
    
    Tabs.SilentAim:CreateToggle({
        Name = "Toggle Mode",
        CurrentValue = false,
        Flag = "SAToggle",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.Toggle = v
            end
        end
    })
    
    Tabs.SilentAim:CreateKeybind({
        Name = "Trigger Key",
        CurrentKeybind = "MouseButton2",
        HoldToInteract = false,
        Flag = "SAKey",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.TriggerKey = v
            end
        end
    })
    
    Tabs.SilentAim:CreateDropdown({
        Name = "Lock Part",
        Options = Parts,
        CurrentOption = "Head",
        Flag = "SAPart",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.LockPart = v
            end
        end
    })
    
    local SilentChecks = Tabs.SilentAim:CreateSection("Checks")
    
    Tabs.SilentAim:CreateToggle({
        Name = "Team Check",
        CurrentValue = false,
        Flag = "SATeam",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.TeamCheck = v
            end
        end
    })
    
    Tabs.SilentAim:CreateToggle({
        Name = "Alive Check",
        CurrentValue = true,
        Flag = "SAAlive",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.AliveCheck = v
            end
        end
    })
    
    Tabs.SilentAim:CreateToggle({
        Name = "Wall Check",
        CurrentValue = false,
        Flag = "SAWall",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.WallCheck = v
            end
        end
    })
    
    local SilentFOV = Tabs.SilentAim:CreateSection("FOV & Prediction")
    
    Tabs.SilentAim:CreateToggle({
        Name = "Limit to FOV",
        CurrentValue = true,
        Flag = "SAUseFOV",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.UseFOV = v
            end
        end
    })
    
    Tabs.SilentAim:CreateSlider({
        Name = "FOV Radius",
        Range = {10, 800},
        Increment = 1,
        CurrentValue = 180,
        Flag = "SAFOV",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.FOVAmount = v
            end
        end
    })
    
    Tabs.SilentAim:CreateSlider({
        Name = "Prediction",
        Range = {0, 1},
        Increment = 0.01,
        CurrentValue = 0,
        Flag = "SAPred",
        Callback = function(v)
            if Aimbot.SilentAim then
                Aimbot.SilentAim.Prediction = v
            end
        end
    })
end

--// ─────────────────────────────────────────────────────────────────────────
--// VISUALS TAB
--// ─────────────────────────────────────────────────────────────────────────

if WallHack then
    local VisMain = Tabs.Visuals:CreateSection("Main")
    
    Tabs.Visuals:CreateToggle({
        Name = "Enable Visuals",
        CurrentValue = false,
        Flag = "VisEnabled",
        Callback = function(v)
            if WallHack.Settings then
                WallHack.Settings.Enabled = v
            end
        end
    })
    
    Tabs.Visuals:CreateToggle({
        Name = "Team Check",
        CurrentValue = false,
        Flag = "VisTeam",
        Callback = function(v)
            if WallHack.Settings then
                WallHack.Settings.TeamCheck = v
            end
        end
    })
    
    Tabs.Visuals:CreateToggle({
        Name = "Alive Check",
        CurrentValue = true,
        Flag = "VisAlive",
        Callback = function(v)
            if WallHack.Settings then
                WallHack.Settings.AliveCheck = v
            end
        end
    })
    
    Tabs.Visuals:CreateSlider({
        Name = "Max Distance",
        Range = {0, 5000},
        Increment = 10,
        CurrentValue = 1000,
        Flag = "VisDist",
        Callback = function(v)
            if WallHack.Settings then
                WallHack.Settings.MaxDistance = v
            end
        end
    })
    
    -- ESP Section
    local VisESP = Tabs.Visuals:CreateSection("Name Tags")
    
    Tabs.Visuals:CreateToggle({
        Name = "Enable Tags",
        CurrentValue = true,
        Flag = "ESPEnabled",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.ESPSettings then
                WallHack.Visuals.ESPSettings.Enabled = v
            end
        end
    })
    
    Tabs.Visuals:CreateToggle({
        Name = "Show Name",
        CurrentValue = true,
        Flag = "ESPName",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.ESPSettings then
                WallHack.Visuals.ESPSettings.DisplayName = v
            end
        end
    })
    
    Tabs.Visuals:CreateToggle({
        Name = "Show Health",
        CurrentValue = true,
        Flag = "ESPHealth",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.ESPSettings then
                WallHack.Visuals.ESPSettings.DisplayHealth = v
            end
        end
    })
    
    Tabs.Visuals:CreateToggle({
        Name = "Show Distance",
        CurrentValue = true,
        Flag = "ESPDist",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.ESPSettings then
                WallHack.Visuals.ESPSettings.DisplayDistance = v
            end
        end
    })
    
    Tabs.Visuals:CreateColorPicker({
        Name = "Text Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "ESPColor",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.ESPSettings then
                WallHack.Visuals.ESPSettings.TextColor = v
            end
        end
    })
    
    -- Box Section
    local VisBox = Tabs.Visuals:CreateSection("Box ESP")
    
    Tabs.Visuals:CreateToggle({
        Name = "Enable Boxes",
        CurrentValue = true,
        Flag = "BoxEnabled",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.BoxSettings then
                WallHack.Visuals.BoxSettings.Enabled = v
            end
        end
    })
    
    Tabs.Visuals:CreateDropdown({
        Name = "Box Type",
        Options = BoxTypes,
        CurrentOption = "3D Corner",
        Flag = "BoxType",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.BoxSettings then
                WallHack.Visuals.BoxSettings.Type = v == "3D Corner" and 1 or 2
            end
        end
    })
    
    Tabs.Visuals:CreateColorPicker({
        Name = "Box Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "BoxColor",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.BoxSettings then
                WallHack.Visuals.BoxSettings.Color = v
            end
        end
    })
    
    -- Tracers Section
    local VisTracer = Tabs.Visuals:CreateSection("Tracers")
    
    Tabs.Visuals:CreateToggle({
        Name = "Enable Tracers",
        CurrentValue = true,
        Flag = "TracerEnabled",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.TracersSettings then
                WallHack.Visuals.TracersSettings.Enabled = v
            end
        end
    })
    
    Tabs.Visuals:CreateDropdown({
        Name = "Origin",
        Options = TracersType,
        CurrentOption = "Bottom",
        Flag = "TracerOrigin",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.TracersSettings then
                for i, t in ipairs(TracersType) do
                    if t == v then
                        WallHack.Visuals.TracersSettings.Type = i
                        break
                    end
                end
            end
        end
    })
    
    Tabs.Visuals:CreateColorPicker({
        Name = "Tracer Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "TracerColor",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.TracersSettings then
                WallHack.Visuals.TracersSettings.Color = v
            end
        end
    })
    
    -- Head Dot Section
    local VisHD = Tabs.Visuals:CreateSection("Head Dots")
    
    Tabs.Visuals:CreateToggle({
        Name = "Enable Head Dots",
        CurrentValue = true,
        Flag = "HDEnabled",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.HeadDotSettings then
                WallHack.Visuals.HeadDotSettings.Enabled = v
            end
        end
    })
    
    Tabs.Visuals:CreateColorPicker({
        Name = "Head Dot Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "HDColor",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.HeadDotSettings then
                WallHack.Visuals.HeadDotSettings.Color = v
            end
        end
    })
    
    -- Health Bar Section
    local VisHB = Tabs.Visuals:CreateSection("Health Bars")
    
    Tabs.Visuals:CreateToggle({
        Name = "Enable Health Bars",
        CurrentValue = false,
        Flag = "HBEnabled",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.HealthBarSettings then
                WallHack.Visuals.HealthBarSettings.Enabled = v
            end
        end
    })
    
    Tabs.Visuals:CreateDropdown({
        Name = "Position",
        Options = HBPositions,
        CurrentOption = "Left",
        Flag = "HBPos",
        Callback = function(v)
            if WallHack.Visuals and WallHack.Visuals.HealthBarSettings then
                local pos = v == "Top" and 1 or v == "Bottom" and 2 or v == "Left" and 3 or 4
                WallHack.Visuals.HealthBarSettings.Type = pos
            end
        end
    })
end

--// ─────────────────────────────────────────────────────────────────────────
--// CROSSHAIR TAB
--// ─────────────────────────────────────────────────────────────────────────

if WallHack then
    local CrossMain = Tabs.Crosshair:CreateSection("Crosshair")
    
    Tabs.Crosshair:CreateToggle({
        Name = "System Cursor",
        CurrentValue = UserInputService.MouseIconEnabled,
        Flag = "SysCursor",
        Callback = function(v)
            UserInputService.MouseIconEnabled = v
        end
    })
    
    Tabs.Crosshair:CreateToggle({
        Name = "Custom Crosshair",
        CurrentValue = false,
        Flag = "XhairEnabled",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.Enabled = v
            end
        end
    })
    
    Tabs.Crosshair:CreateDropdown({
        Name = "Follow",
        Options = XhairFollow,
        CurrentOption = "Mouse",
        Flag = "XhairFollow",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.Type = v == "Mouse" and 1 or 2
            end
        end
    })
    
    Tabs.Crosshair:CreateSlider({
        Name = "Size",
        Range = {4, 40},
        Increment = 1,
        CurrentValue = 12,
        Flag = "XhairSize",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.Size = v
            end
        end
    })
    
    Tabs.Crosshair:CreateSlider({
        Name = "Thickness",
        Range = {1, 5},
        Increment = 1,
        CurrentValue = 1,
        Flag = "XhairThick",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.Thickness = v
            end
        end
    })
    
    Tabs.Crosshair:CreateSlider({
        Name = "Gap",
        Range = {0, 20},
        Increment = 1,
        CurrentValue = 5,
        Flag = "XhairGap",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.GapSize = v
            end
        end
    })
    
    Tabs.Crosshair:CreateColorPicker({
        Name = "Crosshair Color",
        Color = Color3.fromRGB(0, 255, 0),
        Flag = "XhairColor",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.Color = v
            end
        end
    })
    
    local CrossDot = Tabs.Crosshair:CreateSection("Center Dot")
    
    Tabs.Crosshair:CreateToggle({
        Name = "Enable Dot",
        CurrentValue = false,
        Flag = "DotEnabled",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.CenterDot = v
            end
        end
    })
    
    Tabs.Crosshair:CreateToggle({
        Name = "Filled",
        CurrentValue = true,
        Flag = "DotFilled",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.CenterDotFilled = v
            end
        end
    })
    
    Tabs.Crosshair:CreateSlider({
        Name = "Dot Size",
        Range = {1, 10},
        Increment = 1,
        CurrentValue = 1,
        Flag = "DotSize",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.CenterDotSize = v
            end
        end
    })
    
    Tabs.Crosshair:CreateColorPicker({
        Name = "Dot Color",
        Color = Color3.fromRGB(0, 255, 0),
        Flag = "DotColor",
        Callback = function(v)
            if WallHack.Crosshair and WallHack.Crosshair.Settings then
                WallHack.Crosshair.Settings.CenterDotColor = v
            end
        end
    })
end

--// ─────────────────────────────────────────────────────────────────────────
--// SETTINGS TAB
--// ─────────────────────────────────────────────────────────────────────────

local SettingsMain = Tabs.Settings:CreateSection("Module Controls")

Tabs.Settings:CreateButton({
    Name = "Restart Modules",
    Callback = function()
        Rayfield:Notify({
            Title = "AirHub",
            Content = "Restarting modules...",
            Duration = 2,
            Image = 4483362458
        })
        
        -- Clean up old modules
        if Aimbot and Aimbot.Functions then
            pcall(function() Aimbot.Functions:Exit() end)
        end
        if WallHack and WallHack.Functions then
            pcall(function() WallHack.Functions:Exit() end)
        end
        
        env.AirHub.Aimbot = nil
        env.AirHub.WallHack = nil
        
        -- Reload modules
        loadModules()
        
        -- Refresh references
        Aimbot = env.AirHub and env.AirHub.Aimbot
        WallHack = env.AirHub and env.AirHub.WallHack
        
        Rayfield:Notify({
            Title = "AirHub",
            Content = "Modules restarted",
            Duration = 2,
            Image = 4483362458
        })
    end
})

Tabs.Settings:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        if Aimbot and Aimbot.Functions then
            pcall(function() Aimbot.Functions:ResetSettings() end)
        end
        if WallHack and WallHack.Functions then
            pcall(function() WallHack.Functions:ResetSettings() end)
        end
        Rayfield:Notify({
            Title = "AirHub",
            Content = "Settings reset",
            Duration = 2,
            Image = 4483362458
        })
    end
})

Tabs.Settings:CreateButton({
    Name = "Unload AirHub",
    Callback = function()
        Rayfield:Notify({
            Title = "AirHub",
            Content = "Unloading...",
            Duration = 2,
            Image = 4483362458
        })
        
        if Aimbot and Aimbot.Functions then
            pcall(function() Aimbot.Functions:Exit() end)
        end
        if WallHack and WallHack.Functions then
            pcall(function() WallHack.Functions:Exit() end)
        end
        
        Rayfield:Destroy()
        env.AirHub = nil
        
        task.wait(0.5)
        print("AirHub unloaded")
    end
})

local SettingsTheme = Tabs.Settings:CreateSection("Theme")

Tabs.Settings:CreateColorPicker({
    Name = "Main Color",
    Color = Color3.fromRGB(0, 255, 255),
    Flag = "ThemeColor",
    Callback = function(v)
        -- Rayfield doesn't have built-in theme changing yet
    end
})

--// Initialize
Rayfield:Notify({
    Title = "AirHub",
    Content = "Loaded successfully!",
    Duration = 3,
    Image = 4483362458
})

print("AirHub V3 loaded with Rayfield")
