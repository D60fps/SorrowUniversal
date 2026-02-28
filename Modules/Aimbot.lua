--// Cache
local pcall, getgenv, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel = pcall, getgenv, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper, mousemoverel or (Input and Input.MouseMove)

--// Launching checks
if not getgenv().AirHub then 
    getgenv().AirHub = {}
end
if getgenv().AirHub.Aimbot then return end

--// Services
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

--// Variables
local RequiredDistance = 2000
local Typing = false
local Running = false
local ServiceConnections = {}
local Animation = nil
local OriginalSensitivity = nil

--// Environment
getgenv().AirHub.Aimbot = {
    Settings = {
        Enabled                = false,
        TeamCheck              = false,
        AliveCheck             = true,
        WallCheck              = false,
        Sensitivity            = 0,
        ThirdPerson            = false,
        ThirdPersonSensitivity = 3,
        TriggerKey             = "MouseButton2",
        Toggle                 = false,
        LockPart               = "Head"
    },

    FOVSettings = {
        Enabled      = false,
        Visible      = false,
        Amount       = 90,
        Color        = Color3fromRGB(255, 255, 255),
        LockedColor  = Color3fromRGB(255, 70, 70),
        Transparency = 0.5,
        Sides        = 60,
        Thickness    = 1,
        Filled       = false
    },

    SilentAim = {
        Enabled    = false,
        Toggle     = false,
        TriggerKey = "MouseButton2",
        TeamCheck  = false,
        AliveCheck = true,
        WallCheck  = false,
        LockPart   = "Head",
        UseFOV     = true,
        FOVAmount  = 180,
        Prediction = 0,
    },

    FOVCircle = Drawingnew("Circle"),
    Locked = nil,
    Functions = {}
}

local Environment = getgenv().AirHub.Aimbot
Environment.FOVCircle.Visible = false

--// Safe wrapper for all operations
local function safe(fn, ...)
    local success, result = pcall(fn, ...)
    if success then
        return result
    end
    return nil
end

--// Convert Vector
local function ConvertVector(Vector)
    return safe(function()
        return Vector2new(Vector.X, Vector.Y)
    end) or Vector2new--// Cache
local pcall, getgenv, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel = pcall, getgenv, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper, mousemoverel or (Input and Input.MouseMove)

--// Launching checks
if not getgenv().AirHub then 
    getgenv().AirHub = {}
end
if getgenv().AirHub.Aimbot then return end

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables
local RequiredDistance = 2000
local Typing = false
local Running = false
local ServiceConnections = {}
local Animation = nil
local OriginalSensitivity = nil

--// Environment
getgenv().AirHub.Aimbot = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        Sensitivity = 0,
        ThirdPerson = false,
        ThirdPersonSensitivity = 3,
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head"
    },
    FOVSettings = {
        Enabled = false,
        Visible = false,
        Amount = 90,
        Color = Color3fromRGB(255, 255, 255),
        LockedColor = Color3fromRGB(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    },
    SilentAim = {
        Enabled = false,
        Toggle = false,
        TriggerKey = "MouseButton2",
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        LockPart = "Head",
        UseFOV = true,
        FOVAmount = 180,
        Prediction = 0,
    },
    FOVCircle = Drawingnew and Drawingnew("Circle"),
    Locked = nil
}

local Environment = getgenv().AirHub.Aimbot

-- Make sure circle exists and is hidden
if Environment.FOVCircle then
    Environment.FOVCircle.Visible = false
end

--// Core Functions
local function ConvertVector(Vector)
    return Vector2new(Vector.X, Vector.Y)
end

local function CancelLock()
    Environment.Locked = nil
    if Environment.FOVCircle and Environment.FOVSettings then
        Environment.FOVCircle.Color = Environment.FOVSettings.Color
    end
    if OriginalSensitivity then
        pcall(function()
            UserInputService.MouseDeltaSensitivity = OriginalSensitivity
        end)
    end
    if Animation then
        pcall(function()
            Animation:Cancel()
            Animation = nil
        end)
    end
end

local function GetClosestPlayer()
    if not Environment.Locked then
        RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)

        for _, v in next, Players:GetPlayers() do
            pcall(function()
                if v ~= LocalPlayer
                    and v.Character
                    and v.Character:FindFirstChild(Environment.Settings.LockPart)
                    and v.Character:FindFirstChildOfClass("Humanoid") then

                    if Environment.Settings.TeamCheck and v.TeamColor == LocalPlayer.TeamColor then return end
                    if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then return end

                    local Vec, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
                    if OnScreen then
                        Vec = ConvertVector(Vec)
                        local Distance = (UserInputService:GetMouseLocation() - Vec).Magnitude

                        if Distance < RequiredDistance then
                            RequiredDistance = Distance
                            Environment.Locked = v
                        end
                    end
                end
            end)
        end
    elseif Environment.Locked and Environment.Locked.Character and Environment.Locked.Character[Environment.Settings.LockPart] then
        pcall(function()
            local screenPos, onScreen = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
            if not onScreen or (UserInputService:GetMouseLocation() - ConvertVector(screenPos)).Magnitude > RequiredDistance then
                CancelLock()
            end
        end)
    else
        CancelLock()
    end
end

--// Silent Aim
local SAHooked = false
local SA_orig_SP = nil
local SA_orig_VP = nil
local SA_Running = false

local function GetSilentTarget()
    local SA = Environment.SilentAim
    local mouse = UserInputService:GetMouseLocation()
    local limit = SA.UseFOV and SA.FOVAmount or math.huge
    local bestDist = limit
    local bestTarget = nil

    for _, v in next, Players:GetPlayers() do
        pcall(function()
            if v == LocalPlayer then return end
            if not (v.Character
                and v.Character:FindFirstChild(SA.LockPart)
                and v.Character:FindFirstChildOfClass("Humanoid")) then return end

            if SA.TeamCheck and v.TeamColor == LocalPlayer.TeamColor then return end
            if SA.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then return end

            local screenVec, onScreen = Camera:WorldToViewportPoint(v.Character[SA.LockPart].Position)
            if not onScreen then return end

            local dist = (mouse - Vector2new(screenVec.X, screenVec.Y)).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestTarget = v
            end
        end)
    end

    if not bestTarget then return nil end

    local pos = bestTarget.Character[SA.LockPart].Position
    if SA.Prediction > 0 then
        local hrp = bestTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pos = pos + hrp.AssemblyLinearVelocity * SA.Prediction
        end
    end
    return pos
end

local function MakeRayTowards(worldPos)
    local origin = Camera.CFrame.Position
    local direction = (worldPos - origin).Unit * 5000
    return Ray.new(origin, direction)
end

local function InstallSilentAimHooks()
    if SAHooked then return end
    SAHooked = true

    SA_orig_SP = Camera.ScreenPointToRay
    SA_orig_VP = Camera.ViewportPointToRay

    Camera.ScreenPointToRay = function(self, x, y, depth)
        if Environment.SilentAim.Enabled and SA_Running then
            local target = GetSilentTarget()
            if target then return MakeRayTowards(target) end
        end
        return SA_orig_SP and SA_orig_SP(self, x, y, depth) or Ray.new(Vector3.new(0,0,0), Vector3.new(0,0,0))
    end

    Camera.ViewportPointToRay = function(self, x, y, depth)
        if Environment.SilentAim.Enabled and SA_Running then
            local target = GetSilentTarget()
            if target then return MakeRayTowards(target) end
        end
        return SA_orig_VP and SA_orig_VP(self, x, y, depth) or Ray.new(Vector3.new(0,0,0), Vector3.new(0,0,0))
    end
end

local function RemoveSilentAimHooks()
    if not SAHooked then return end
    SAHooked = false

    if SA_orig_SP then Camera.ScreenPointToRay = SA_orig_SP end
    if SA_orig_VP then Camera.ViewportPointToRay = SA_orig_VP end
    SA_orig_SP = nil
    SA_orig_VP = nil
end

--// Main Loop
local function Load()
    OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    InstallSilentAimHooks()

    ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            local AF = Environment.FOVSettings

            -- FOV Circle
            if AF.Visible and Environment.FOVCircle then
                Environment.FOVCircle.Radius = AF.Amount
                Environment.FOVCircle.Thickness = AF.Thickness
                Environment.FOVCircle.Filled = AF.Filled
                Environment.FOVCircle.NumSides = AF.Sides
                Environment.FOVCircle.Transparency = AF.Transparency
                Environment.FOVCircle.Position = UserInputService:GetMouseLocation()
                Environment.FOVCircle.Color = Environment.Locked and AF.LockedColor or AF.Color
                Environment.FOVCircle.Visible = true
            elseif Environment.FOVCircle then
                Environment.FOVCircle.Visible = false
            end

            -- Standard Aimbot
            if Running and Environment.Settings.Enabled then
                GetClosestPlayer()

                if Environment.Locked and Environment.Locked.Character and Environment.Locked.Character[Environment.Settings.LockPart] then
                    if Environment.Settings.ThirdPerson then
                        if mousemoverel then
                            local Vec = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
                            mousemoverel(
                                (Vec.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity,
                                (Vec.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity
                            )
                        end
                    else
                        if Environment.Settings.Sensitivity > 0 then
                            if Animation then Animation:Cancel() end
                            Animation = TweenService:Create(Camera,
                                TweenInfonew(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                                {CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)}
                            )
                            Animation:Play()
                        else
                            Camera.CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
                        end
                        UserInputService.MouseDeltaSensitivity = 0
                    end
                end
            end
        end)
    end)

    ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
        if Typing then return end
        pcall(function()
            -- Aimbot trigger
            local key = Environment.Settings.TriggerKey
            if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[key])
                or Input.UserInputType == Enum.UserInputType[key] then
                if Environment.Settings.Toggle then
                    Running = not Running
                    if not Running then CancelLock() end
                else
                    Running = true
                end
            end

            -- Silent Aim trigger
            local saKey = Environment.SilentAim.TriggerKey
            if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[saKey])
                or Input.UserInputType == Enum.UserInputType[saKey] then
                if Environment.SilentAim.Toggle then
                    SA_Running = not SA_Running
                else
                    SA_Running = true
                end
            end
        end)
    end)

    ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
        if Typing then return end
        pcall(function()
            -- Aimbot release
            if not Environment.Settings.Toggle then
                local key = Environment.Settings.TriggerKey
                if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[key])
                    or Input.UserInputType == Enum.UserInputType[key] then
                    Running = false
                    CancelLock()
                end
            end

            -- Silent Aim release
            if not Environment.SilentAim.Toggle then
                local saKey = Environment.SilentAim.TriggerKey
                if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[saKey])
                    or Input.UserInputType == Enum.UserInputType[saKey] then
                    SA_Running = false
                end
            end
        end)
    end)

    -- Typing Check
    ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
        Typing = true
    end)

    ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
        Typing = false
    end)
end

--// Functions
Environment.Functions = {}

function Environment.Functions:Exit()
    for _, v in next, ServiceConnections do
        pcall(function() v:Disconnect() end)
    end
    RemoveSilentAimHooks()
    if Environment.FOVCircle then
        pcall(function() Environment.FOVCircle:Remove() end)
    end
    getgenv().AirHub.Aimbot = nil
end

function Environment.Functions:Restart()
    for _, v in next, ServiceConnections do
        pcall(function() v:Disconnect() end)
    end
    RemoveSilentAimHooks()
    Load()
end

function Environment.Functions:ResetSettings()
    Environment.Settings = {
        Enabled = false, TeamCheck = false, AliveCheck = true, WallCheck = false,
        Sensitivity = 0, ThirdPerson = false, ThirdPersonSensitivity = 3,
        TriggerKey = "MouseButton2", Toggle = false, LockPart = "Head"
    }
    Environment.FOVSettings = {
        Enabled = false, Visible = false, Amount = 90,
        Color = Color3fromRGB(255, 255, 255), LockedColor = Color3fromRGB(255, 70, 70),
        Transparency = 0.5, Sides = 60, Thickness = 1, Filled = false
    }
    Environment.SilentAim = {
        Enabled = false, Toggle = false, TriggerKey = "MouseButton2",
        TeamCheck = false, AliveCheck = true, WallCheck = false,
        LockPart = "Head", UseFOV = true, FOVAmount = 180, Prediction = 0,
    }
end

--// Load
local success, err = pcall(Load)
if not success then
    warn("Aimbot failed to load: " .. tostring(err))
end
