-- Aimbot.lua - Recoded Version
-- Camera & Mouse Aim Support

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--// Constants
local LOCAL_PLAYER = Players.LocalPlayer
local CAMERA = Workspace.CurrentCamera
local GENV = getgenv()
local DRAWING_NEW = Drawing.new
local VECTOR2_NEW = Vector2.new
local CFrame_NEW = CFrame.new
local COLOR3_NEW = Color3.fromRGB
local TWEEN_INFO = TweenInfo.new
local NEXT = next
local PCALL = pcall
local STRING_UPPER = string.upper
local MATH_CLAMP = math.clamp
local TICK = tick

--// Module Setup
local AIRHUB = GENV.AirHub or {}
if AIRHUB.Aimbot then return end

--// Mouse Movement Compatibility
local MOUSE_MOVE = (mousemoverel or (Input and Input.MouseMove) or function() end)

--// Class: Aimbot
local Aimbot = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        
        -- Camera Mode Settings
        Camera = {
            Sensitivity = 0, -- Animation length in seconds (0 = instant)
            Smoothness = 1, -- Multiplier for camera movement (0-1)
        },
        
        -- Mouse Mode Settings
        Mouse = {
            Speed = 3, -- Mouse movement speed multiplier
            Smoothness = 0.5, -- Smoothing factor (0-1)
            MaxStep = 50, -- Maximum pixels per frame to move
        },
        
        -- Common Settings
        AimMode = "Camera", -- "Camera" or "Mouse"
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head",
        ThirdPerson = false, -- Only affects Mouse mode
    },
    
    FOVSettings = {
        Enabled = true,
        Visible = true,
        Amount = 90,
        Color = COLOR3_NEW(255, 255, 255),
        LockedColor = COLOR3_NEW(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    },
    
    State = {
        Running = false,
        Typing = false,
        Locked = nil,
        Connections = {},
        Animation = nil,
        OriginalSensitivity = 0,
        LastTargetPosition = nil,
        CurrentSmoothPosition = nil,
    }
}

--// Create FOV Circle
Aimbot.FOVCircle = DRAWING_NEW("Circle")
Aimbot.FOVCircle.Visible = false

--// Helper Functions
local function IsTargetValid(target)
    if not target or target == LOCAL_PLAYER then return false end
    
    local character = target.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

local function CheckTeam(target)
    if not Aimbot.Settings.TeamCheck then return true end
    return target.TeamColor ~= LOCAL_PLAYER.TeamColor
end

local function CheckWall(target, part)
    if not Aimbot.Settings.WallCheck then return true end
    
    local origin = CAMERA.CFrame.Position
    local direction = (part.Position - origin).Unit
    local ray = Ray.new(origin, direction * 1000)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LOCAL_PLAYER.Character, target.Character})
    
    return hit == nil
end

local function GetTargetScreenPosition(target)
    local part = target.Character and target.Character:FindFirstChild(Aimbot.Settings.LockPart)
    if not part then return nil end
    
    local vector, onScreen = CAMERA:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    
    return VECTOR2_NEW(vector.X, vector.Y)
end

local function GetTargetDistance(target)
    local screenPos = GetTargetScreenPosition(target)
    if not screenPos then return math.huge end
    
    local mousePos = UserInputService:GetMouseLocation()
    return (screenPos - mousePos).Magnitude
end

local function FindClosestTarget()
    local maxDistance = Aimbot.FOVSettings.Enabled and Aimbot.FOVSettings.Amount or 2000
    local closestTarget = nil
    local closestDistance = maxDistance
    
    for _, player in NEXT, Players:GetPlayers() do
        if IsTargetValid(player) and CheckTeam(player) then
            local distance = GetTargetDistance(player)
            
            if distance < closestDistance then
                local part = player.Character[Aimbot.Settings.LockPart]
                if CheckWall(player, part) then
                    closestDistance = distance
                    closestTarget = player
                end
            end
        end
    end
    
    return closestTarget
end

local function UpdateFOVCircle()
    if not Aimbot.FOVSettings.Enabled or not Aimbot.Settings.Enabled then
        Aimbot.FOVCircle.Visible = false
        return
    end
    
    local mousePos = UserInputService:GetMouseLocation()
    
    Aimbot.FOVCircle.Radius = Aimbot.FOVSettings.Amount
    Aimbot.FOVCircle.Thickness = Aimbot.FOVSettings.Thickness
    Aimbot.FOVCircle.Filled = Aimbot.FOVSettings.Filled
    Aimbot.FOVCircle.NumSides = Aimbot.FOVSettings.Sides
    Aimbot.FOVCircle.Color = Aimbot.State.Locked and Aimbot.FOVSettings.LockedColor or Aimbot.FOVSettings.Color
    Aimbot.FOVCircle.Transparency = Aimbot.FOVSettings.Transparency
    Aimbot.FOVCircle.Visible = Aimbot.FOVSettings.Visible
    Aimbot.FOVCircle.Position = VECTOR2_NEW(mousePos.X, mousePos.Y)
end

local function CancelLock()
    if Aimbot.State.Locked then
        Aimbot.State.Locked = nil
        Aimbot.State.LastTargetPosition = nil
        Aimbot.State.CurrentSmoothPosition = nil
        UserInputService.MouseDeltaSensitivity = Aimbot.State.OriginalSensitivity
        
        if Aimbot.State.Animation then
            Aimbot.State.Animation:Cancel()
            Aimbot.State.Animation = nil
        end
    end
end

--// Camera Aim Mode
local function ApplyCameraAim(target)
    if not target or not target.Character then return end
    
    local part = target.Character:FindFirstChild(Aimbot.Settings.LockPart)
    if not part then return end
    
    local targetPos = part.Position
    local cameraPos = CAMERA.CFrame.Position
    local cameraSettings = Aimbot.Settings.Camera
    
    if cameraSettings.Sensitivity > 0 then
        -- Smooth camera movement with tween
        local tweenInfo = TWEEN_INFO(cameraSettings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local goal = {CFrame = CFrame_NEW(cameraPos, targetPos)}
        Aimbot.State.Animation = TweenService:Create(CAMERA, tweenInfo, goal)
        Aimbot.State.Animation:Play()
    else
        -- Instant camera lock
        CAMERA.CFrame = CFrame_NEW(cameraPos, targetPos)
    end
    
    -- Disable mouse look while aiming
    UserInputService.MouseDeltaSensitivity = 0
end

--// Mouse Aim Mode
local function ApplyMouseAim(target)
    if not target or not target.Character then return end
    
    local part = target.Character:FindFirstChild(Aimbot.Settings.LockPart)
    if not part then return end
    
    -- Get target screen position
    local targetScreenPos = GetTargetScreenPosition(target)
    if not targetScreenPos then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local mouseSettings = Aimbot.Settings.Mouse
    
    -- Initialize smooth position if needed
    if not Aimbot.State.CurrentSmoothPosition then
        Aimbot.State.CurrentSmoothPosition = mousePos
    end
    
    -- Calculate target position (with third person adjustment if needed)
    local targetPos = targetScreenPos
    if Aimbot.Settings.ThirdPerson then
        -- In third person, we want to aim slightly above for better visibility
        targetPos = VECTOR2_NEW(targetScreenPos.X, targetScreenPos.Y - 50)
    end
    
    -- Calculate movement delta
    local dx = targetPos.X - Aimbot.State.CurrentSmoothPosition.X
    local dy = targetPos.Y - Aimbot.State.CurrentSmoothPosition.Y
    
    -- Apply smoothing
    local smoothFactor = MATH_CLAMP(mouseSettings.Smoothness, 0, 1)
    dx = dx * smoothFactor * mouseSettings.Speed
    dy = dy * smoothFactor * mouseSettings.Speed
    
    -- Clamp maximum movement per frame
    dx = MATH_CLAMP(dx, -mouseSettings.MaxStep, mouseSettings.MaxStep)
    dy = MATH_CLAMP(dy, -mouseSettings.MaxStep, mouseSettings.MaxStep)
    
    -- Update smooth position
    Aimbot.State.CurrentSmoothPosition = VECTOR2_NEW(
        Aimbot.State.CurrentSmoothPosition.X + dx,
        Aimbot.State.CurrentSmoothPosition.Y + dy
    )
    
    -- Apply mouse movement
    if MATH_CLAMP(math.abs(dx) + math.abs(dy), 0, 1) > 0 then
        MOUSE_MOVE(dx, dy)
    end
end

--// Main Render Step Handler
local function HandleRenderStep()
    UpdateFOVCircle()
    
    if not Aimbot.State.Running or not Aimbot.Settings.Enabled then
        if Aimbot.State.Locked then
            CancelLock()
        end
        return
    end
    
    -- Find target if not locked
    if not Aimbot.State.Locked then
        local target = FindClosestTarget()
        if target then
            Aimbot.State.Locked = target
            Aimbot.State.LastTargetPosition = TICK()
        end
        return
    end
    
    -- Verify locked target
    if not IsTargetValid(Aimbot.State.Locked) then
        CancelLock()
        return
    end
    
    -- Check if target is still in FOV
    local distance = GetTargetDistance(Aimbot.State.Locked)
    if distance > (Aimbot.FOVSettings.Enabled and Aimbot.FOVSettings.Amount or 2000) then
        CancelLock()
        return
    end
    
    -- Apply aim based on selected mode
    if Aimbot.Settings.AimMode == "Camera" then
        ApplyCameraAim(Aimbot.State.Locked)
    else -- Mouse mode
        ApplyMouseAim(Aimbot.State.Locked)
    end
end

--// Input Handlers
local function HandleInputBegan(input)
    if Aimbot.State.Typing then return end
    
    local triggerMatch = false
    PCALL(function()
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyCode = input.KeyCode.Name
            triggerMatch = keyCode == STRING_UPPER(Aimbot.Settings.TriggerKey)
        else
            triggerMatch = input.UserInputType.Name == Aimbot.Settings.TriggerKey
        end
    end)
    
    if triggerMatch then
        if Aimbot.Settings.Toggle then
            Aimbot.State.Running = not Aimbot.State.Running
            if not Aimbot.State.Running then
                CancelLock()
            end
        else
            Aimbot.State.Running = true
        end
    end
end

local function HandleInputEnded(input)
    if Aimbot.State.Typing or Aimbot.Settings.Toggle then return end
    
    PCALL(function()
        local triggerMatch = false
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyCode = input.KeyCode.Name
            triggerMatch = keyCode == STRING_UPPER(Aimbot.Settings.TriggerKey)
        else
            triggerMatch = input.UserInputType.Name == Aimbot.Settings.TriggerKey
        end
        
        if triggerMatch then
            Aimbot.State.Running = false
            CancelLock()
        end
    end)
end

--// Public API
Aimbot.Functions = {}

function Aimbot.Functions:Start()
    if Aimbot.State.Connections.RenderStepped then return end
    
    Aimbot.State.OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    
    Aimbot.State.Connections.RenderStepped = RunService.RenderStepped:Connect(HandleRenderStep)
    Aimbot.State.Connections.InputBegan = UserInputService.InputBegan:Connect(HandleInputBegan)
    Aimbot.State.Connections.InputEnded = UserInputService.InputEnded:Connect(HandleInputEnded)
    Aimbot.State.Connections.TypingStarted = UserInputService.TextBoxFocused:Connect(function()
        Aimbot.State.Typing = true
    end)
    Aimbot.State.Connections.TypingEnded = UserInputService.TextBoxFocusReleased:Connect(function()
        Aimbot.State.Typing = false
    end)
    
    print("Aimbot started successfully | Mode: " .. Aimbot.Settings.AimMode)
end

function Aimbot.Functions:Stop()
    for _, connection in NEXT, Aimbot.State.Connections do
        connection:Disconnect()
    end
    
    Aimbot.State.Connections = {}
    Aimbot.State.Running = false
    CancelLock()
    Aimbot.FOVCircle.Visible = false
    
    print("Aimbot stopped")
end

function Aimbot.Functions:SetMode(mode)
    if mode ~= "Camera" and mode ~= "Mouse" then
        warn("Invalid mode. Use 'Camera' or 'Mouse'")
        return
    end
    
    Aimbot.Settings.AimMode = mode
    CancelLock() -- Reset any current lock when switching modes
    print("Aimbot mode switched to: " .. mode)
end

function Aimbot.Functions:Restart()
    self:Stop()
    self:Start()
end

function Aimbot.Functions:ResetSettings()
    Aimbot.Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        
        Camera = {
            Sensitivity = 0,
            Smoothness = 1,
        },
        
        Mouse = {
            Speed = 3,
            Smoothness = 0.5,
            MaxStep = 50,
        },
        
        AimMode = "Camera",
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head",
        ThirdPerson = false,
    }
    
    Aimbot.FOVSettings = {
        Enabled = true,
        Visible = true,
        Amount = 90,
        Color = COLOR3_NEW(255, 255, 255),
        LockedColor = COLOR3_NEW(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    }
end

function Aimbot.Functions:Destroy()
    self:Stop()
    Aimbot.FOVCircle:Remove()
    GENV.AirHub.Aimbot = nil
end

--// Store in global environment
AIRHUB.Aimbot = Aimbot
GENV.AirHub = AIRHUB

--// Auto-start
Aimbot.Functions:Start()

return Aimbot
