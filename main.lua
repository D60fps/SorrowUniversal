--// Cache
local getgenv = getgenv or genv or (function() return getfenv(0) end)
local Color3fromRGB = Color3.fromRGB
local mathclamp = math.clamp
local tick = tick
local Vector2new = Vector2.new

--// Services
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

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
local TriggerTab  = Window:CreateTab("Triggerbot",4483362458)
local VisualsTab  = Window:CreateTab("Visuals",   4483362458)
local UtilityTab  = Window:CreateTab("Utility",   4483362458)

-- ══════════════════════════════════════════════════
--  GLOBAL VARIABLES FOR TRIGGERBOT
-- ══════════════════════════════════════════════════
local Triggerbot = {
    Enabled = false,
    Key = "MouseButton2",
    Mode = "Hold", -- "Hold" or "Toggle"
    Delay = 0,
    HitPart = "Head",
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    FOVCheck = true,
    FOVAmount = 90,
    Prediction = 0,
    ShootKey = "MouseButton1",
    Silent = false,
    Connections = {},
    LastShot = 0,
    Running = false
}

-- ══════════════════════════════════════════════════
--  TRIGGERBOT FUNCTIONS
-- ══════════════════════════════════════════════════
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function IsTargetValid(player)
    if not player or player == LocalPlayer then return false end
    if Triggerbot.TeamCheck and player.TeamColor == LocalPlayer.TeamColor then return false end
    
    local character = player.Character
    if not character then return false end
    
    if Triggerbot.AliveCheck then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
    end
    
    return true
end

local function CheckWall(part)
    if not Triggerbot.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local ray = Ray.new(origin, direction * 1000)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    
    return hit == nil
end

local function GetTargetUnderCursor()
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local closestDistance = Triggerbot.FOVCheck and Triggerbot.FOVAmount or 2000
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsTargetValid(player) and player.Character then
            local part = player.Character:FindFirstChild(Triggerbot.HitPart)
            if part then
                local vector, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local distance = (Vector2new(vector.X, vector.Y) - mousePos).Magnitude
                    
                    if distance < closestDistance then
                        if CheckWall(part) then
                            closestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function ShootTarget(target)
    if not target or not target.Character then return end
    
    local part = target.Character:FindFirstChild(Triggerbot.HitPart)
    if not part then return end
    
    -- Check if enough time has passed since last shot
    if tick() - Triggerbot.LastShot < Triggerbot.Delay then return end
    
    Triggerbot.LastShot = tick()
    
    if Triggerbot.Silent then
        -- Silent aim shot
        local args = {
            [1] = {
                [1] = {
                    ["RayObject"] = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
                }
            }
        }
        
        -- Find remote event (common tool remote names)
        local remote = nil
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            remote = tool:FindFirstChild("Remote") or tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("Remote")
        end
        
        if remote then
            remote:FireServer(unpack(args))
        end
    else
        -- Simulate mouse click
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            tool:Activate()
        else
            -- Virtual click
            mouse1press()
            wait(0.05)
            mouse1release()
        end
    end
end

local function TriggerbotLoop()
    while Triggerbot.Running do
        if Triggerbot.Enabled and (Triggerbot.Mode == "Hold" or (Triggerbot.Mode == "Toggle" and Triggerbot.Toggled)) then
            local target = GetTargetUnderCursor()
            if target then
                ShootTarget(target)
            end
        end
        RunService.RenderStepped:Wait()
    end
end

-- Start triggerbot loop
Triggerbot.Running = true
task.spawn(TriggerbotLoop)

-- Input handling for triggerbot
Triggerbot.Connections.InputBegan = UserInputService.InputBegan:Connect(function(input)
    if not Triggerbot.Enabled then return end
    
    local keyMatch = false
    if input.UserInputType == Enum.UserInputType.Keyboard then
        keyMatch = input.KeyCode.Name == Triggerbot.Key
    else
        keyMatch = input.UserInputType.Name == Triggerbot.Key
    end
    
    if keyMatch then
        if Triggerbot.Mode == "Toggle" then
            Triggerbot.Toggled = not Triggerbot.Toggled
        else
            Triggerbot.Active = true
        end
    end
end)

Triggerbot.Connections.InputEnded = UserInputService.InputEnded:Connect(function(input)
    if not Triggerbot.Enabled or Triggerbot.Mode == "Toggle" then return end
    
    local keyMatch = false
    if input.UserInputType == Enum.UserInputType.Keyboard then
        keyMatch = input.KeyCode.Name == Triggerbot.Key
    else
        keyMatch = input.UserInputType.Name == Triggerbot.Key
    end
    
    if keyMatch then
        Triggerbot.Active = false
    end
end)

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
    Name = "Enable Triggerbot",
    CurrentValue = false,
    Flag = "Triggerbot_Enabled",
    Callback = function(v)
        Triggerbot.Enabled = v
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

MainTab:CreateSection("Aim Mode Selection")

MainTab:CreateDropdown({
    Name = "Aim Mode",
    Options = {"Camera Mode (CFrame)", "Mouse Mode (Cursor Follows Target)"},
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

-- ══════════════════════════════════════════════════
--  AIMBOT TAB - FULL CUSTOMIZATION
-- ══════════════════════════════════════════════════
AimbotTab:CreateSection("General Settings")

AimbotTab:CreateDropdown({
    Name = "Lock Part",
    Options = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso", 
               "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Neck", "Waist"},
    CurrentOption = {"Head"},
    Flag = "Aimbot_LockPart",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.LockPart = v[1]
        end
    end
})

AimbotTab:CreateDropdown({
    Name = "Trigger Key",
    Options = {"MouseButton1", "MouseButton2", "MouseButton3", "LeftAlt", "RightAlt", 
               "LeftShift", "RightShift", "LeftControl", "RightControl", "E", "Q", "F", 
               "C", "X", "Z", "V", "B", "G", "T", "R"},
    CurrentOption = {"MouseButton2"},
    Flag = "Aimbot_TriggerKey",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.TriggerKey = v[1]
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Toggle Mode (Hold otherwise)",
    CurrentValue = false,
    Flag = "Aimbot_Toggle",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.Toggle = v
        end
    end
})

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

AimbotTab:CreateSection("Mouse Mode Settings (Cursor Follows Target)")

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
    Name = "Max Movement Per Frame",
    Range = {1, 100},
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
    Name = "Predict Movement",
    CurrentValue = false,
    Flag = "Mouse_Prediction",
    Callback = function(v)
        if Aimbot and Aimbot.Settings and Aimbot.Settings.Mouse then
            Aimbot.Settings.Mouse.Prediction = v
        end
    end
})

AimbotTab:CreateSlider({
    Name = "Prediction Amount",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.2,
    Flag = "Mouse_PredictionAmount",
    Callback = function(v)
        if Aimbot and Aimbot.Settings and Aimbot.Settings.Mouse then
            Aimbot.Settings.Mouse.PredictionAmount = v
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Third Person Mode",
    CurrentValue = false,
    Flag = "Aimbot_ThirdPerson",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.ThirdPerson = v
        end
    end
})

AimbotTab:CreateSlider({
    Name = "Third Person Offset",
    Range = {-100, 100},
    Increment = 5,
    Suffix = "px",
    CurrentValue = -50,
    Flag = "ThirdPerson_Offset",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.ThirdPersonOffset = v
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

AimbotTab:CreateToggle({
    Name = "Visible Check",
    CurrentValue = false,
    Flag = "Aimbot_VisibleCheck",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.VisibleCheck = v
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = false,
    Flag = "Aimbot_IgnoreFriends",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.IgnoreFriends = v
        end
    end
})

AimbotTab:CreateSlider({
    Name = "Max Aim Distance",
    Range = {100, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "Aimbot_MaxDistance",
    Callback = function(v)
        if Aimbot and Aimbot.Settings then
            Aimbot.Settings.MaxDistance = v
        end
    end
})

-- ══════════════════════════════════════════════════
--  TRIGGERBOT TAB - FULL CUSTOMIZATION
-- ══════════════════════════════════════════════════
TriggerTab:CreateSection("Triggerbot Settings")

TriggerTab:CreateToggle({
    Name = "Enable Triggerbot",
    CurrentValue = false,
    Flag = "Triggerbot_Enabled",
    Callback = function(v)
        Triggerbot.Enabled = v
    end
})

TriggerTab:CreateDropdown({
    Name = "Activation Key",
    Options = {"MouseButton1", "MouseButton2", "MouseButton3", "LeftAlt", "RightAlt", 
               "LeftShift", "RightShift", "LeftControl", "RightControl", "E", "Q", "F", 
               "C", "X", "Z", "V", "B", "G", "T", "R", "Always On"},
    CurrentOption = {"MouseButton2"},
    Flag = "Triggerbot_Key",
    Callback = function(v)
        Triggerbot.Key = v[1]
    end
})

TriggerTab:CreateDropdown({
    Name = "Activation Mode",
    Options = {"Hold", "Toggle"},
    CurrentOption = {"Hold"},
    Flag = "Triggerbot_Mode",
    Callback = function(v)
        Triggerbot.Mode = v[1]
    end
})

TriggerTab:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso", 
               "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    CurrentOption = {"Head"},
    Flag = "Triggerbot_HitPart",
    Callback = function(v)
        Triggerbot.HitPart = v[1]
    end
})

TriggerTab:CreateSlider({
    Name = "Shot Delay",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0,
    Flag = "Triggerbot_Delay",
    Callback = function(v)
        Triggerbot.Delay = v
    end
})

TriggerTab:CreateSlider({
    Name = "Prediction",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0,
    Flag = "Triggerbot_Prediction",
    Callback = function(v)
        Triggerbot.Prediction = v
    end
})

TriggerTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "Triggerbot_Silent",
    Callback = function(v)
        Triggerbot.Silent = v
    end
})

TriggerTab:CreateSection("Triggerbot Filters")

TriggerTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "Triggerbot_TeamCheck",
    Callback = function(v)
        Triggerbot.TeamCheck = v
    end
})

TriggerTab:CreateToggle({
    Name = "Alive Check",
    CurrentValue = true,
    Flag = "Triggerbot_AliveCheck",
    Callback = function(v)
        Triggerbot.AliveCheck = v
    end
})

TriggerTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "Triggerbot_WallCheck",
    Callback = function(v)
        Triggerbot.WallCheck = v
    end
})

TriggerTab:CreateToggle({
    Name = "Use FOV Limit",
    CurrentValue = true,
    Flag = "Triggerbot_UseFOV",
    Callback = function(v)
        Triggerbot.FOVCheck = v
    end
})

TriggerTab:CreateSlider({
    Name = "FOV Size",
    Range = {10, 360},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 90,
    Flag = "Triggerbot_FOV",
    Callback = function(v)
        Triggerbot.FOVAmount = v
    end
})

TriggerTab:CreateSection("Shoot Settings")

TriggerTab:CreateDropdown({
    Name = "Shoot Key",
    Options = {"MouseButton1", "MouseButton2", "MouseButton3", "E", "F", "G", "Space"},
    CurrentOption = {"MouseButton1"},
    Flag = "Triggerbot_ShootKey",
    Callback = function(v)
        Triggerbot.ShootKey = v[1]
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

-- ... (ESP, Tracers, Box, Head Dot, Health Bar, Crosshair sections from previous version remain the same)

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
        Triggerbot.Running = false
        for _, connection in pairs(Triggerbot.Connections) do
            connection:Disconnect()
        end
        
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

-- Initialize with default mode
if Aimbot and Aimbot.Functions and Aimbot.Functions.SetMode then
    Aimbot.Functions:SetMode("Camera")
end
