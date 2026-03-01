-- Aimbot.lua - Recoded Version
-- Camera & Mouse Aim Support with True Mouse Tracking

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
local MATH_ABS = math.abs
local MATH_FLOOR = math.floor
local MATH_MIN = math.min
local MATH_MAX = math.max

--// Module Setup
local AIRHUB = GENV.AirHub or {}
if AIRHUB.Aimbot then return end

--// Mouse Movement Compatibility
local MOUSE_MOVE = (mousemoverel or (Input and Input.MouseMove) or function(dx, dy)
    if Input and Input.MouseMove then
        Input.MouseMove(dx, dy)
    end
end)

--// Class: Aimbot
local Aimbot = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        VisibleCheck = false,
        IgnoreFriends = false,
        MaxDistance = 1000,
        
        -- Camera Mode Settings
        Camera = {
            Sensitivity = 0, -- Animation length in seconds (0 = instant)
            Smoothness = 1, -- Multiplier for camera movement (0-1)
        },
        
        -- Mouse Mode Settings (True Cursor Tracking)
        Mouse = {
            Speed = 3, -- Mouse movement speed multiplier
            Smoothness = 0.5, -- Smoothing factor (0-1)
            MaxStep = 50, -- Maximum pixels per frame to move
            Prediction = false, -- Predict target movement
            PredictionAmount = 0.2, -- How much to predict
        },
        
        -- Common Settings
        AimMode = "Camera", -- "Camera" or "Mouse"
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head",
        ThirdPerson = false,
        ThirdPersonOffset = -50, -- Pixels to offset for third person
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
    
    Triggerbot = {
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
        Toggled = false,
        Active = false,
        LastShot = 0,
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
        TargetVelocity = VECTOR2_NEW(0, 0),
        LastTargetUpdate = TICK(),
    }
}

--// Create FOV Circle
Aimbot.FOVCircle = DRAWING_NEW("Circle")
Aimbot.FOVCircle.Visible = false

--// Helper Functions
local function IsTargetValid(target, settings)
    settings = settings or Aimbot.Settings
    
    if not target or target == LOCAL_PLAYER then return false end
    
    -- Friend check
    if settings.IgnoreFriends and target:IsFriendsWith(LOCAL_PLAYER.UserId) then
        return false
    end
    
    local character = target.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if settings.AliveCheck and (not humanoid or humanoid.Health <= 0) then return false end
    
    -- Distance check
    if settings.MaxDistance and settings.MaxDistance > 0 then
        local distance = (character:GetPivot().Position - LOCAL_PLAYER.Character:GetPivot().Position).Magnitude
        if distance > settings.MaxDistance then return false end
    end
    
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

local function CheckVisible(part)
    if not Aimbot.Settings.VisibleCheck then return true end
    
    local vector, onScreen = CAMERA:WorldToViewportPoint(part.Position)
    return onScreen
end

local function GetTargetScreenPosition(target, usePrediction)
    local part = target.Character and target.Character:FindFirstChild(Aimbot.Settings.LockPart)
    if not part then return nil end
    
    local targetPos = part.Position
    
    -- Apply prediction if enabled
    if usePrediction and Aimbot.Settings.Mouse.Prediction then
        local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local velocity = rootPart.Velocity
                targetPos = targetPos + velocity * Aimbot.Settings.Mouse.PredictionAmount
            end
        end
    end
    
    local vector, onScreen = CAMERA:WorldToViewportPoint(targetPos)
    if not onScreen and Aimbot.Settings.VisibleCheck then return nil end
    
    return VECTOR2_NEW(vector.X, vector.Y)
end

local function GetTargetDistance(target)
    local screenPos = GetTargetScreenPosition(target, false)
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
                if part and CheckWall(player, part) and CheckVisible(part) then
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
        Aimbot.State.TargetVelocity = VECTOR2_NEW(0, 0)
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

--// Mouse Aim Mode (True Cursor Tracking)
local function ApplyMouseAim(target)
    if not target or not target.Character then return end
    
    local part = target.Character:FindFirstChild(Aimbot.Settings.LockPart)
    if not part then return end
    
    -- Get target screen position with prediction
    local targetScreenPos = GetTargetScreenPosition(target, true)
    if not targetScreenPos then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local mouseSettings = Aimbot.Settings.Mouse
    local now = TICK()
    
    -- Update target velocity for prediction
    if Aimbot.State.LastTargetPosition then
        local dt = now - Aimbot.State.LastTargetUpdate
        if dt > 0 then
            local newVelocity = (targetScreenPos - Aimbot.State.LastTargetPosition) / dt
            Aimbot.State.TargetVelocity = Aimbot.State.TargetVelocity:Lerp(newVelocity, 0.5)
        end
    end
    Aimbot.State.LastTargetPosition = targetScreenPos
    Aimbot.State.LastTargetUpdate = now
    
    -- Initialize smooth position if needed
    if not Aimbot.State.CurrentSmoothPosition then
        Aimbot.State.CurrentSmoothPosition = mousePos
    end
    
    -- Calculate target position with third person offset
    local targetPos = targetScreenPos
    if Aimbot.Settings.ThirdPerson then
        targetPos = VECTOR2_NEW(targetScreenPos.X, targetScreenPos.Y + Aimbot.Settings.ThirdPersonOffset)
    end
    
    -- Add prediction velocity to target position
    if mouseSettings.Prediction then
        targetPos = targetPos + Aimbot.State.TargetVelocity * mouseSettings.PredictionAmount
    end
    
    -- Calculate movement delta with smoothing
    local targetDelta = targetPos - Aimbot.State.CurrentSmoothPosition
    local smoothFactor = MATH_CLAMP(mouseSettings.Smoothness, 0.1, 0.9)
    
    -- Apply exponential smoothing
    Aimbot.State.CurrentSmoothPosition = VECTOR2_NEW(
        Aimbot.State.CurrentSmoothPosition.X + targetDelta.X * smoothFactor,
        Aimbot.State.CurrentSmoothPosition.Y + targetDelta.Y * smoothFactor
    )
    
    -- Calculate final movement
    local dx = (targetPos.X - mousePos.X) * mouseSettings.Speed
    local dy = (targetPos.Y - mousePos.Y) * mouseSettings.Speed
    
    -- Clamp maximum movement per frame
    dx = MATH_CLAMP(dx, -mouseSettings.MaxStep, mouseSettings.MaxStep)
    dy = MATH_CLAMP(dy, -mouseSettings.MaxStep, mouseSettings.MaxStep)
    
    -- Only move if significant
    if MATH_ABS(dx) + MATH_ABS(dy) > 0.5 then
        MOUSE_MOVE(dx, dy)
    end
end

--// Triggerbot Functions
local function IsTriggerTargetValid(player)
    if not player or player == LOCAL_PLAYER then return false end
    
    if Aimbot.Triggerbot.TeamCheck and player.TeamColor == LOCAL_PLAYER.TeamColor then
        return false
    end
    
    local character = player.Character
    if not character then return false end
    
    if Aimbot.Triggerbot.AliveCheck then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
    end
    
    return true
end

local function CheckTriggerWall(part)
    if not Aimbot.Triggerbot.WallCheck then return true end
    
    local origin = CAMERA.CFrame.Position
    local direction = (part.Position - origin).Unit
    local ray = Ray.new(origin, direction * 1000)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LOCAL_PLAYER.Character})
    
    return hit == nil
end

local function GetTriggerTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local closestDistance = Aimbot.Triggerbot.FOVCheck and Aimbot.Triggerbot.FOVAmount or 2000
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsTriggerTargetValid(player) and player.Character then
            local part = player.Character:FindFirstChild(Aimbot.Triggerbot.HitPart)
            if part then
                -- Apply prediction
                local targetPos = part.Position
                if Aimbot.Triggerbot.Prediction > 0 then
                    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        targetPos = targetPos + rootPart.Velocity * Aimbot.Triggerbot.Prediction
                    end
                end
                
                local vector, onScreen = CAMERA:WorldToViewportPoint(targetPos)
                if onScreen then
                    local distance = (VECTOR2_NEW(vector.X, vector.Y) - mousePos).Magnitude
                    
                    if distance < closestDistance then
                        if CheckTriggerWall(part) then
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
    
    local part = target.Character:FindFirstChild(Aimbot.Triggerbot.HitPart)
    if not part then return end
    
    -- Check shot delay
    if TICK() - Aimbot.Triggerbot.LastShot < Aimbot.Triggerbot.Delay then
        return
    end
    
    Aimbot.Triggerbot.LastShot = TICK()
    
    if Aimbot.Triggerbot.Silent then
        -- Silent aim shot (bypass visual aim)
        local remote = nil
        local tool = LOCAL_PLAYER.Character and LOCAL_PLAYER.Character:FindFirstChildOfClass("Tool")
        
        if tool then
            -- Common remote names
            local remoteNames = {"Remote", "RemoteEvent", "ShootRemote", "FireRemote", "ActivateRemote"}
            for _, name in ipairs(remoteNames) do
                remote = tool:FindFirstChild(name) or (tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild(name))
                if remote then break end
            end
        end
        
        if remote then
            -- Create ray arguments
            local ray = Ray.new(CAMERA.CFrame.Position, (part.Position - CAMERA.CFrame.Position).Unit * 1000)
            remote:FireServer(ray)
        end
    else
        -- Simulate mouse click
        local tool = LOCAL_PLAYER.Character and LOCAL_PLAYER.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        else
            -- Virtual click
            mouse1press()
            task.wait(0.05)
            mouse1release()
        end
    end
end

--// Triggerbot Loop
local function TriggerbotLoop()
    while Aimbot.State.Running do
        if Aimbot.Triggerbot.Enabled then
            local shouldShoot = false
            
            if Aimbot.Triggerbot.Mode == "Hold" and Aimbot.Triggerbot.Active then
                shouldShoot = true
            elseif Aimbot.Triggerbot.Mode == "Toggle" and Aimbot.Triggerbot.Toggled then
                shouldShoot = true
            end
            
            if shouldShoot then
                local target = GetTriggerTarget()
                if target then
                    ShootTarget(target)
                end
            end
        end
        RunService.RenderStepped:Wait()
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
            Aimbot.State.LastTargetUpdate = TICK()
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
    
    -- Aimbot trigger
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
    
    -- Triggerbot activation
    local triggerbotMatch = false
    PCALL(function()
        if input.UserInputType == Enum.UserInputType.Keyboard then
            triggerbotMatch = input.KeyCode.Name == Aimbot.Triggerbot.Key
        else
            triggerbotMatch = input.UserInputType.Name == Aimbot.Triggerbot.Key
        end
    end)
    
    if triggerbotMatch and Aimbot.Triggerbot.Enabled then
        if Aimbot.Triggerbot.Mode == "Toggle" then
            Aimbot.Triggerbot.Toggled = not Aimbot.Triggerbot.Toggled
        else
            Aimbot.Triggerbot.Active = true
        end
    end
end

local function HandleInputEnded(input)
    if Aimbot.State.Typing then return end
    
    -- Aimbot trigger release
    if not Aimbot.Settings.Toggle then
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
    
    -- Triggerbot deactivation
    if Aimbot.Triggerbot.Mode ~= "Toggle" then
        PCALL(function()
            local triggerbotMatch = false
            if input.UserInputType == Enum.UserInputType.Keyboard then
                triggerbotMatch = input.KeyCode.Name == Aimbot.Triggerbot.Key
            else
                triggerbotMatch = input.UserInputType.Name == Aimbot.Triggerbot.Key
            end
            
            if triggerbotMatch then
                Aimbot.Triggerbot.Active = false
            end
        end)
    end
end

--// Public API
Aimbot.Functions = {}

function Aimbot.Functions:Start()
    if Aimbot.State.Connections.RenderStepped then return end
    
    Aimbot.State.OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    Aimbot.State.Running = true
    
    Aimbot.State.Connections.RenderStepped = RunService.RenderStepped:Connect(HandleRenderStep)
    Aimbot.State.Connections.InputBegan = UserInputService.InputBegan:Connect(HandleInputBegan)
    Aimbot.State.Connections.InputEnded = UserInputService.InputEnded:Connect(HandleInputEnded)
    Aimbot.State.Connections.TypingStarted = UserInputService.TextBoxFocused:Connect(function()
        Aimbot.State.Typing = true
    end)
    Aimbot.State.Connections.TypingEnded = UserInputService.TextBoxFocusReleased:Connect(function()
        Aimbot.State.Typing = false
    end)
    
    -- Start triggerbot thread
    task.spawn(TriggerbotLoop)
    
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
    print("Aimbot mode switched to: " .. mode .. " | Mouse mode now follows cursor")
end

function Aimbot.Functions:SetTriggerbotSettings(settings)
    for k, v in pairs(settings) do
        if Aimbot.Triggerbot[k] ~= nil then
            Aimbot.Triggerbot[k] = v
        end
    end
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
        VisibleCheck = false,
        IgnoreFriends = false,
        MaxDistance = 1000,
        
        Camera = {
            Sensitivity = 0,
            Smoothness = 1,
        },
        
        Mouse = {
            Speed = 3,
            Smoothness = 0.5,
            MaxStep = 50,
            Prediction = false,
            PredictionAmount = 0.2,
        },
        
        AimMode = "Camera",
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head",
        ThirdPerson = false,
        ThirdPersonOffset = -50,
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
    
    Aimbot.Triggerbot = {
        Enabled = false,
        Key = "MouseButton2",
        Mode = "Hold",
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
        Toggled = false,
        Active = false,
        LastShot = 0,
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
