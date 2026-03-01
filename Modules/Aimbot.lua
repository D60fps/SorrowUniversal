-- Aimbot.lua - Rewritten & Optimized
--[[
Fixes:
- Fixed missing mousemoverel fallback
- Fixed Input handling for keys
- Fixed animation cleanup
- Added proper error handling
- Optimized performance
]]

--// Cache
local pcall = pcall
local getgenv = getgenv
local next = next
local setmetatable = setmetatable
local Vector2new = Vector2.new
local CFramenew = CFrame.new
local Color3fromRGB = Color3.fromRGB
local Drawingnew = Drawing.new
local TweenInfonew = TweenInfo.new
local stringupper = string.upper
local mousemoverel = mousemoverel or (Input and Input.MouseMove) or function() end

--// Launching checks
if not getgenv().AirHub or getgenv().AirHub.Aimbot then 
    return 
end

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
local OriginalSensitivity = 1
local CurrentTarget = nil

--// Environment Setup
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
        Enabled = true,
        Visible = true,
        Amount = 90,
        Color = Color3fromRGB(255, 255, 255),
        LockedColor = Color3fromRGB(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    },
    
    FOVCircle = Drawingnew("Circle"),
    Locked = nil,
    Functions = {}
}

local Environment = getgenv().AirHub.Aimbot

--// Utility Functions
local function ConvertVector(Vector)
    return Vector2new(Vector.X, Vector.Y)
end

local function CancelLock()
    Environment.Locked = nil
    Environment.FOVCircle.Color = Environment.FOVSettings.Color
    
    if OriginalSensitivity then
        UserInputService.MouseDeltaSensitivity = OriginalSensitivity
    end
    
    if Animation then
        Animation:Cancel()
        Animation = nil
    end
end

local function IsPlayerValid(Player)
    if not Player or Player == LocalPlayer then
        return false
    end
    
    local Character = Player.Character
    if not Character then
        return false
    end
    
    local LockPart = Character:FindFirstChild(Environment.Settings.LockPart)
    if not LockPart then
        return false
    end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        return false
    end
    
    -- Team Check
    if Environment.Settings.TeamCheck and Player.TeamColor == LocalPlayer.TeamColor then
        return false
    end
    
    -- Alive Check
    if Environment.Settings.AliveCheck and Humanoid.Health <= 0 then
        return false
    end
    
    -- Wall Check
    if Environment.Settings.WallCheck then
        local PartPosition = LockPart.Position
        local ObscuringParts = Camera:GetPartsObscuringTarget({PartPosition}, Character:GetDescendants())
        if #ObscuringParts > 0 then
            return false
        end
    end
    
    return true
end

local function GetClosestPlayer()
    if not Environment.Locked then
        RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000
        
        for _, Player in next, Players:GetPlayers() do
            if IsPlayerValid(Player) then
                local Character = Player.Character
                local LockPart = Character[Environment.Settings.LockPart]
                
                local Vector, OnScreen = Camera:WorldToViewportPoint(LockPart.Position)
                if OnScreen then
                    local Vector2D = ConvertVector(Vector)
                    local Distance = (UserInputService:GetMouseLocation() - Vector2D).Magnitude
                    
                    if Distance < RequiredDistance then
                        RequiredDistance = Distance
                        Environment.Locked = Player
                    end
                end
            end
        end
    elseif Environment.Locked and Environment.Locked.Character then
        local LockPart = Environment.Locked.Character:FindFirstChild(Environment.Settings.LockPart)
        if LockPart then
            local Vector = ConvertVector(Camera:WorldToViewportPoint(LockPart.Position))
            local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude
            
            if Distance > RequiredDistance then
                CancelLock()
            end
        else
            CancelLock()
        end
    else
        CancelLock()
    end
end

local function UpdateFOVCircle()
    local FOV = Environment.FOVCircle
    local Settings = Environment.FOVSettings
    
    if Settings.Enabled and Environment.Settings.Enabled then
        FOV.Radius = Settings.Amount
        FOV.Thickness = Settings.Thickness
        FOV.Filled = Settings.Filled
        FOV.NumSides = Settings.Sides
        FOV.Color = Environment.Locked and Settings.LockedColor or Settings.Color
        FOV.Transparency = Settings.Transparency
        FOV.Visible = Settings.Visible
        FOV.Position = ConvertVector(UserInputService:GetMouseLocation())
    else
        FOV.Visible = false
    end
end

local function PerformLock()
    if not (Running and Environment.Settings.Enabled and Environment.Locked) then
        return
    end
    
    local Target = Environment.Locked
    local Character = Target.Character
    if not Character then
        CancelLock()
        return
    end
    
    local LockPart = Character:FindFirstChild(Environment.Settings.LockPart)
    if not LockPart then
        CancelLock()
        return
    end
    
    if Environment.Settings.ThirdPerson then
        local Vector = Camera:WorldToViewportPoint(LockPart.Position)
        local MousePos = UserInputService:GetMouseLocation()
        local DeltaX = (Vector.X - MousePos.X) * Environment.Settings.ThirdPersonSensitivity
        local DeltaY = (Vector.Y - MousePos.Y) * Environment.Settings.ThirdPersonSensitivity
        
        pcall(mousemoverel, DeltaX, DeltaY)
    else
        if Environment.Settings.Sensitivity > 0 then
            if Animation then
                Animation:Cancel()
            end
            
            Animation = TweenService:Create(
                Camera, 
                TweenInfonew(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {CFrame = CFramenew(Camera.CFrame.Position, LockPart.Position)}
            )
            Animation:Play()
        else
            Camera.CFrame = CFramenew(Camera.CFrame.Position, LockPart.Position)
        end
        
        UserInputService.MouseDeltaSensitivity = 0
    end
end

local function HandleInput(Input, IsBeginning)
    if Typing then
        return
    end
    
    local TriggerKey = Environment.Settings.TriggerKey
    local IsKeyMatch = false
    
    -- Check if input matches trigger key
    pcall(function()
        if Input.UserInputType == Enum.UserInputType.Keyboard then
            local KeyCode = tostring(Input.KeyCode):gsub("Enum.KeyCode.", "")
            if #TriggerKey == 1 then
                IsKeyMatch = KeyCode == stringupper(TriggerKey)
            else
                IsKeyMatch = KeyCode == TriggerKey
            end
        else
            IsKeyMatch = Input.UserInputType == Enum.UserInputType[TriggerKey]
        end
    end)
    
    if not IsKeyMatch then
        return
    end
    
    if Environment.Settings.Toggle then
        if IsBeginning then
            Running = not Running
            if not Running then
                CancelLock()
            end
        end
    elseif IsBeginning then
        Running = true
    else
        Running = false
        CancelLock()
    end
end

--// Main Load Function
local function Load()
    -- Store original sensitivity
    OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    
    -- RenderStepped connection
    ServiceConnections.RenderStepped = RunService.RenderStepped:Connect(function()
        UpdateFOVCircle()
        
        if Running and Environment.Settings.Enabled then
            GetClosestPlayer()
            PerformLock()
        end
    end)
    
    -- Input connections
    ServiceConnections.InputBegan = UserInputService.InputBegan:Connect(function(Input)
        HandleInput(Input, true)
    end)
    
    ServiceConnections.InputEnded = UserInputService.InputEnded:Connect(function(Input)
        HandleInput(Input, false)
    end)
    
    -- Typing connections
    ServiceConnections.TypingStarted = UserInputService.TextBoxFocused:Connect(function()
        Typing = true
    end)
    
    ServiceConnections.TypingEnded = UserInputService.TextBoxFocusReleased:Connect(function()
        Typing = false
    end)
end

--// Public Functions
function Environment.Functions:Exit()
    CancelLock()
    
    for _, Connection in next, ServiceConnections do
        Connection:Disconnect()
    end
    
    Environment.FOVCircle:Remove()
    Environment.Functions = nil
    getgenv().AirHub.Aimbot = nil
end

function Environment.Functions:Restart()
    CancelLock()
    
    for _, Connection in next, ServiceConnections do
        Connection:Disconnect()
    end
    
    Load()
end

function Environment.Functions:ResetSettings()
    Environment.Settings = {
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
    }
    
    Environment.FOVSettings = {
        Enabled = true,
        Visible = true,
        Amount = 90,
        Color = Color3fromRGB(255, 255, 255),
        LockedColor = Color3fromRGB(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    }
end

--// Metatable protection
setmetatable(Environment.Functions, {
    __newindex = function()
        warn("Cannot modify Aimbot functions table")
    end
})

--// Initialize
Load()
