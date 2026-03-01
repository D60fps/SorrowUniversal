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

-- ══════════════════════════════════════════════════
--  AIMBOT MODULE (inlined)
-- ══════════════════════════════════════════════════


--// Cache

local getgenv = getgenv or genv or (function() return getfenv(0) end)
local pcall, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel = pcall, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper, mousemoverel or (Input and Input.MouseMove)

--// Launching checks

-- (inlined)

--// Services

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

--// Variables

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}

--// Environment

getgenv().AirHub.Aimbot = {
	Settings = {
		Enabled                = false,
		TeamCheck              = false,
		AliveCheck             = true,
		WallCheck              = false,
		Sensitivity            = 0,             -- Tween duration (seconds) before fully locking
		ThirdPerson            = false,          -- Use mousemoverel for third-person support
		ThirdPersonSensitivity = 3,
		TriggerKey             = "MouseButton2",
		Toggle                 = false,
		LockPart               = "Head"
	},

	FOVSettings = {
		Enabled      = true,
		Visible      = true,
		Amount       = 90,
		Color        = Color3fromRGB(255, 255, 255),
		LockedColor  = Color3fromRGB(255, 70, 70),
		Transparency = 0.5,
		Sides        = 60,
		Thickness    = 1,
		Filled       = false
	},

	-- Silent Aim
	-- Hooks Camera:ScreenPointToRay / ViewportPointToRay — the two methods most
	-- projectile systems use to turn screen coords into a world ray.  We replace
	-- the returned Ray with one that points at the closest valid target instead of
	-- the real crosshair position.  The camera never moves, so locally everything
	-- looks completely normal while the bullet flies toward the target.
	SilentAim = {
		Enabled    = false,
		TeamCheck  = false,
		AliveCheck = true,
		WallCheck  = false,
		LockPart   = "Head",
		UseFOV     = true,  -- Only redirect shots fired from within the FOV radius
		FOVAmount  = 180,   -- Independent pixel-radius for silent-aim FOV
		Prediction = 0,     -- Velocity lead multiplier (0 = disabled)
	},

	FOVCircle = Drawingnew("Circle")
}

local Environment = getgenv().AirHub.Aimbot

--// ─────────────────────────────────────────────────────────────────────────
--// Core Functions
--// ─────────────────────────────────────────────────────────────────────────

local function ConvertVector(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

local function CancelLock()
	Environment.Locked = nil
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
	UserInputService.MouseDeltaSensitivity = OriginalSensitivity

	if Animation then
		Animation:Cancel()
	end
end

local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer
				and v.Character
				and v.Character:FindFirstChild(Environment.Settings.LockPart)
				and v.Character:FindFirstChildOfClass("Humanoid") then

				if Environment.Settings.TeamCheck  and v.TeamColor == LocalPlayer.TeamColor then continue end
				if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
				if Environment.Settings.WallCheck  and #(Camera:GetPartsObscuringTarget(
						{v.Character[Environment.Settings.LockPart].Position},
						v.Character:GetDescendants())) > 0 then continue end

				local Vec, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
				Vec = ConvertVector(Vec)
				local Distance = (UserInputService:GetMouseLocation() - Vec).Magnitude

				if Distance < RequiredDistance and OnScreen then
					RequiredDistance = Distance
					Environment.Locked = v
				end
			end
		end
	elseif (UserInputService:GetMouseLocation() - ConvertVector(Camera:WorldToViewportPoint(
				Environment.Locked.Character[Environment.Settings.LockPart].Position))).Magnitude > RequiredDistance then
		CancelLock()
	end
end

--// ─────────────────────────────────────────────────────────────────────────
--// Silent Aim
--// ─────────────────────────────────────────────────────────────────────────

local SAHooked   = false
local SA_orig_SP = nil
local SA_orig_VP = nil

-- Find the closest valid player for silent aim and return the world position
-- we want the bullet to travel toward.
local function GetSilentTarget()
	local SA    = Environment.SilentAim
	local mouse = UserInputService:GetMouseLocation()
	local limit = SA.UseFOV and SA.FOVAmount or math.huge

	local bestDist   = limit
	local bestTarget = nil

	for _, v in next, Players:GetPlayers() do
		if v == LocalPlayer then continue end
		if not (v.Character
			and v.Character:FindFirstChild(SA.LockPart)
			and v.Character:FindFirstChildOfClass("Humanoid")) then continue end

		if SA.TeamCheck  and v.TeamColor == LocalPlayer.TeamColor then continue end
		if SA.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
		if SA.WallCheck  and #(Camera:GetPartsObscuringTarget(
				{v.Character[SA.LockPart].Position},
				v.Character:GetDescendants())) > 0 then continue end

		local screenVec, onScreen = Camera:WorldToViewportPoint(v.Character[SA.LockPart].Position)
		if not onScreen then continue end

		local dist = (mouse - Vector2new(screenVec.X, screenVec.Y)).Magnitude
		if dist < bestDist then
			bestDist   = dist
			bestTarget = v
		end
	end

	if not bestTarget then return nil end

	local pos  = bestTarget.Character[SA.LockPart].Position
	local pred = SA.Prediction

	-- Velocity prediction: lead the target by its current velocity * multiplier
	if pred > 0 then
		local hrp = bestTarget.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			pos = pos + hrp.AssemblyLinearVelocity * pred
		end
	end

	return pos
end

-- Build a Ray from the camera that points at a world-space position.
local function MakeRayTowards(worldPos)
	local origin    = Camera.CFrame.Position
	local direction = (worldPos - origin).Unit * 5000
	return Ray.new(origin, direction)
end

local function InstallSilentAimHooks()
	if SAHooked then return end
	SAHooked = true

	SA_orig_SP = Camera.ScreenPointToRay
	SA_orig_VP = Camera.ViewportPointToRay

	Camera.ScreenPointToRay = function(self, x, y, depth)
		if Environment.SilentAim.Enabled then
			local target = GetSilentTarget()
			if target then return MakeRayTowards(target) end
		end
		return SA_orig_SP(self, x, y, depth)
	end

	Camera.ViewportPointToRay = function(self, x, y, depth)
		if Environment.SilentAim.Enabled then
			local target = GetSilentTarget()
			if target then return MakeRayTowards(target) end
		end
		return SA_orig_VP(self, x, y, depth)
	end
end

local function RemoveSilentAimHooks()
	if not SAHooked then return end
	SAHooked = false

	if SA_orig_SP then Camera.ScreenPointToRay   = SA_orig_SP; SA_orig_SP = nil end
	if SA_orig_VP then Camera.ViewportPointToRay = SA_orig_VP; SA_orig_VP = nil end
end

--// ─────────────────────────────────────────────────────────────────────────
--// Main Loop
--// ─────────────────────────────────────────────────────────────────────────

local function Load()
	OriginalSensitivity = UserInputService.MouseDeltaSensitivity

	-- Hooks gate on SilentAim.Enabled so they're safe to install immediately
	InstallSilentAimHooks()

	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		-- FOV Circle
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius       = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness    = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled       = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides     = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color        = Environment.FOVSettings.Color
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible      = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position     = UserInputService:GetMouseLocation()
		else
			Environment.FOVCircle.Visible = false
		end

		-- Standard Aimbot
		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Locked then
				if Environment.Settings.ThirdPerson then
					local Vec = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
					mousemoverel(
						(Vec.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity,
						(Vec.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity
					)
				else
					if Environment.Settings.Sensitivity > 0 then
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

				Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor
			end
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing then
			pcall(function()
				if (Input.UserInputType == Enum.UserInputType.Keyboard
						and Input.KeyCode == Enum.KeyCode[#Environment.Settings.TriggerKey == 1
							and stringupper(Environment.Settings.TriggerKey)
							or  Environment.Settings.TriggerKey])
					or Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then

					if Environment.Settings.Toggle then
						Running = not Running
						if not Running then CancelLock() end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing then
			if not Environment.Settings.Toggle then
				pcall(function()
					if (Input.UserInputType == Enum.UserInputType.Keyboard
							and Input.KeyCode == Enum.KeyCode[#Environment.Settings.TriggerKey == 1
								and stringupper(Environment.Settings.TriggerKey)
								or  Environment.Settings.TriggerKey])
						or Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)
			end
		end
	end)
end

--// Typing Check

ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// ─────────────────────────────────────────────────────────────────────────
--// Functions
--// ─────────────────────────────────────────────────────────────────────────

Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	RemoveSilentAimHooks()
	Environment.FOVCircle:Remove()

	getgenv().AirHub.Aimbot.Functions = nil
	getgenv().AirHub.Aimbot           = nil

	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil
	GetSilentTarget = nil; MakeRayTowards = nil
	InstallSilentAimHooks = nil; RemoveSilentAimHooks = nil
end

function Environment.Functions:Restart()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	RemoveSilentAimHooks()
	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
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
	}

	Environment.FOVSettings = {
		Enabled      = true,
		Visible      = true,
		Amount       = 90,
		Color        = Color3fromRGB(255, 255, 255),
		LockedColor  = Color3fromRGB(255, 70, 70),
		Transparency = 0.5,
		Sides        = 60,
		Thickness    = 1,
		Filled       = false
	}

	Environment.SilentAim = {
		Enabled    = false,
		TeamCheck  = false,
		AliveCheck = true,
		WallCheck  = false,
		LockPart   = "Head",
		UseFOV     = true,
		FOVAmount  = 180,
		Prediction = 0,
	}
end

setmetatable(Environment.Functions, {
	__newindex = warn
})

--// Load

Load()


-- ══════════════════════════════════════════════════
--  WALL HACK MODULE (inlined)
-- ══════════════════════════════════════════════════



local getgenv = getgenv or genv or (function() return getfenv(0) end)
--// Cache

local select, next, tostring, pcall, setmetatable = select, next, tostring, pcall, setmetatable
local mathfloor, mathabs, mathcos, mathsin, mathrad, mathsqrt = math.floor, math.abs, math.cos, math.sin, math.rad, math.sqrt
local wait = task.wait
local Vector2new, Vector3new, Vector3zero, CFramenew, Drawingnew, Color3fromRGB = Vector2.new, Vector3.new, Vector3.zero, CFrame.new, Drawing.new, Color3.fromRGB

--// Launching checks

-- (inlined)

--// Services

local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players       = game:GetService("Players")
local LocalPlayer   = Players.LocalPlayer
local Camera        = workspace.CurrentCamera

--// Variables

local ServiceConnections = {}
local WorldToViewportPoint

--// Helper: Get distance from local player to target

local function GetDistance(TargetPos)
    local LP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not LP then return math.huge end
    return (TargetPos - LP.Position).Magnitude
end

--// Environment

getgenv().AirHub.WallHack = {
    Settings = {
        Enabled   = false,
        TeamCheck = false,
        AliveCheck = true,
        MaxDistance = 1000 -- studs; 0 = unlimited
    },

    Visuals = {
        ChamsSettings = {
            Enabled   = false,
            Color     = Color3fromRGB(255, 255, 255),
            Transparency = 0.2,
            Thickness = 0,
            Filled    = true,
            EntireBody = false
        },

        ESPSettings = {
            Enabled         = true,
            TextColor       = Color3fromRGB(255, 255, 255),
            TextSize        = 14,
            Outline         = true,
            OutlineColor    = Color3fromRGB(0, 0, 0),
            TextTransparency = 0.7,
            TextFont        = Drawing.Fonts.UI,
            Offset          = 20,
            DisplayDistance = true,
            DisplayHealth   = true,
            DisplayName     = true
        },

        TracersSettings = {
            Enabled     = true,
            Type        = 1, -- 1=Bottom 2=Center 3=Mouse
            Transparency = 0.7,
            Thickness   = 1,
            Color       = Color3fromRGB(255, 255, 255)
        },

        BoxSettings = {
            Enabled     = true,
            Type        = 1, -- 1=3D 2=2D
            Color       = Color3fromRGB(255, 255, 255),
            Transparency = 0.7,
            Thickness   = 1,
            Filled      = false,
            Increase    = 1
        },

        HeadDotSettings = {
            Enabled     = true,
            Color       = Color3fromRGB(255, 255, 255),
            Transparency = 0.5,
            Thickness   = 1,
            Filled      = false,
            Sides       = 30
        },

        HealthBarSettings = {
            Enabled     = false,
            Transparency = 0.8,
            Size        = 2,
            Offset      = 10,
            OutlineColor = Color3fromRGB(0, 0, 0),
            Blue        = 50,
            Type        = 3 -- 1=Top 2=Bottom 3=Left 4=Right
        }
    },

    Crosshair = {
        Settings = {
            Enabled             = false,
            Type                = 1, -- 1=Mouse 2=Center
            Size                = 12,
            Thickness           = 1,
            Color               = Color3fromRGB(0, 255, 0),
            Transparency        = 1,
            GapSize             = 5,
            Rotation            = 0,
            CenterDot           = false,
            CenterDotColor      = Color3fromRGB(0, 255, 0),
            CenterDotSize       = 1,
            CenterDotTransparency = 1,
            CenterDotFilled     = true,
            CenterDotThickness  = 1
        },

        Parts = {
            LeftLine   = Drawingnew("Line"),
            RightLine  = Drawingnew("Line"),
            TopLine    = Drawingnew("Line"),
            BottomLine = Drawingnew("Line"),
            CenterDot  = Drawingnew("Circle")
        }
    },

    WrappedPlayers = {}
}

local Environment = getgenv().AirHub.WallHack

--// Core Functions

WorldToViewportPoint = function(...)
    return Camera:WorldToViewportPoint(...)
end

local function IsWithinDistance(TargetPos)
    local max = Environment.Settings.MaxDistance
    if max == nil or max <= 0 then return true end
    return GetDistance(TargetPos) <= max
end

local function GetPlayerTable(Player)
    for _, v in next, Environment.WrappedPlayers do
        if v.Name == Player.Name then
            return v
        end
    end
end

local function AssignRigType(Player)
    local PlayerTable = GetPlayerTable(Player)
    repeat wait(0) until Player.Character
    if Player.Character:FindFirstChild("Torso") and not Player.Character:FindFirstChild("LowerTorso") then
        PlayerTable.RigType = "R6"
    elseif Player.Character:FindFirstChild("LowerTorso") and not Player.Character:FindFirstChild("Torso") then
        PlayerTable.RigType = "R15"
    else
        repeat AssignRigType(Player) until PlayerTable.RigType
    end
end

local function InitChecks(Player)
    local PlayerTable = GetPlayerTable(Player)
    PlayerTable.Connections.UpdateChecks = RunService.RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
            PlayerTable.Checks.Alive = Environment.Settings.AliveCheck
                and Player.Character:FindFirstChildOfClass("Humanoid").Health > 0
                or true
            PlayerTable.Checks.Team = Environment.Settings.TeamCheck
                and Player.TeamColor ~= LocalPlayer.TeamColor
                or true

            -- Distance check
            local HRP = Player.Character:FindFirstChild("HumanoidRootPart")
            PlayerTable.Checks.Distance = HRP and IsWithinDistance(HRP.Position) or false
        else
            PlayerTable.Checks.Alive    = false
            PlayerTable.Checks.Team     = false
            PlayerTable.Checks.Distance = false
        end
    end)
end

--// Cham helper: applies shared settings to a Quad drawing

local function ApplyQuadSettings(Quad, Visible)
    local CS = Environment.Visuals.ChamsSettings
    Quad.Transparency = CS.Transparency
    Quad.Color        = CS.Color
    Quad.Thickness    = CS.Thickness
    Quad.Filled       = CS.Filled
    Quad.Visible      = Visible and CS.Enabled
end

local function UpdateCham(Part, Cham)
    local CS = Environment.Visuals.ChamsSettings
    local CorFrame, PartSize = Part.CFrame, Part.Size / 2
    local _, vis = WorldToViewportPoint(CorFrame * CFramenew(PartSize.X / 2, PartSize.Y / 2, PartSize.Z / 2).Position)

    if vis and CS.Enabled then
        -- Build the 8 corners once
        local corners = {
            WorldToViewportPoint(CorFrame * CFramenew( PartSize.X,  PartSize.Y,  PartSize.Z).Position),
            WorldToViewportPoint(CorFrame * CFramenew(-PartSize.X,  PartSize.Y,  PartSize.Z).Position),
            WorldToViewportPoint(CorFrame * CFramenew( PartSize.X, -PartSize.Y,  PartSize.Z).Position),
            WorldToViewportPoint(CorFrame * CFramenew(-PartSize.X, -PartSize.Y,  PartSize.Z).Position),
            WorldToViewportPoint(CorFrame * CFramenew( PartSize.X,  PartSize.Y, -PartSize.Z).Position),
            WorldToViewportPoint(CorFrame * CFramenew(-PartSize.X,  PartSize.Y, -PartSize.Z).Position),
            WorldToViewportPoint(CorFrame * CFramenew( PartSize.X, -PartSize.Y, -PartSize.Z).Position),
            WorldToViewportPoint(CorFrame * CFramenew(-PartSize.X, -PartSize.Y, -PartSize.Z).Position),
        }

        local function v2(p) return Vector2new(p.X, p.Y) end

        -- Front (0,1,2,3) | Back (4,5,6,7) | Top (0,1,4,5) | Bottom (2,3,6,7) | Right (0,2,4,6) | Left (1,3,5,7)
        local faces = {
            {corners[1], corners[3], corners[4], corners[2]},
            {corners[5], corners[7], corners[8], corners[6]},
            {corners[1], corners[5], corners[6], corners[2]},
            {corners[3], corners[7], corners[8], corners[4]},
            {corners[1], corners[3], corners[7], corners[5]},
            {corners[2], corners[4], corners[8], corners[6]},
        }

        for i = 1, 6 do
            local q = Cham["Quad"..i]
            ApplyQuadSettings(q, true)
            q.PointA = v2(faces[i][1]); q.PointB = v2(faces[i][2])
            q.PointC = v2(faces[i][3]); q.PointD = v2(faces[i][4])
        end
    else
        for i = 1, 6 do Cham["Quad"..i].Visible = false end
    end
end

--// Visuals

local Visuals = {
    AddChams = function(Player)
        local PlayerTable = GetPlayerTable(Player)

        local function BuildRig()
            -- Remove old quads
            for _, v in next, PlayerTable.Chams do
                for i = 1, 6 do
                    local q = v["Quad"..i]
                    if q and q.Remove then q:Remove() end
                end
            end

            local parts = {}
            if PlayerTable.RigType == "R15" then
                if not Environment.Visuals.ChamsSettings.EntireBody then
                    parts = {"Head","UpperTorso","LeftLowerArm","LeftUpperArm","RightLowerArm","RightUpperArm","LeftLowerLeg","LeftUpperLeg","RightLowerLeg","RightUpperLeg"}
                else
                    parts = {"Head","UpperTorso","LowerTorso","LeftLowerArm","LeftUpperArm","LeftHand","RightLowerArm","RightUpperArm","RightHand","LeftLowerLeg","LeftUpperLeg","LeftFoot","RightLowerLeg","RightUpperLeg","RightFoot"}
                end
            else
                parts = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
            end

            PlayerTable.Chams = {}
            for _, name in next, parts do
                PlayerTable.Chams[name] = {}
                for i = 1, 6 do
                    PlayerTable.Chams[name]["Quad"..i] = Drawingnew("Quad")
                end
            end
        end

        local oldEntireBody = Environment.Visuals.ChamsSettings.EntireBody
        BuildRig()

        PlayerTable.Connections.Chams = RunService.RenderStepped:Connect(function()
            if not (PlayerTable.Checks.Alive and PlayerTable.Checks.Team and PlayerTable.Checks.Distance) then
                for _, cham in next, PlayerTable.Chams do
                    for i = 1, 6 do cham["Quad"..i].Visible = false end
                end
                return
            end

            if Environment.Visuals.ChamsSettings.Enabled then
                if Environment.Visuals.ChamsSettings.EntireBody ~= oldEntireBody then
                    BuildRig(); oldEntireBody = Environment.Visuals.ChamsSettings.EntireBody
                end
                for name, cham in next, PlayerTable.Chams do
                    local part = Player.Character:WaitForChild(name, math.huge)
                    UpdateCham(part, cham)
                end
            else
                for _, cham in next, PlayerTable.Chams do
                    for i = 1, 6 do cham["Quad"..i].Visible = false end
                end
            end
        end)
    end,

    AddESP = function(Player)
        local PlayerTable = GetPlayerTable(Player)
        PlayerTable.ESP = Drawingnew("Text")

        PlayerTable.Connections.ESP = RunService.RenderStepped:Connect(function()
            local ES = Environment.Visuals.ESPSettings
            if not (Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                and Player.Character:FindFirstChild("HumanoidRootPart")
                and Player.Character:FindFirstChild("Head")
                and Environment.Settings.Enabled and ES.Enabled) then
                PlayerTable.ESP.Visible = false
                return
            end

            local Vector, OnScreen = WorldToViewportPoint(Player.Character.Head.Position)
            local passChecks = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and PlayerTable.Checks.Distance

            if not (OnScreen and passChecks) then
                PlayerTable.ESP.Visible = false
                return
            end

            local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
            local HRP = Player.Character.HumanoidRootPart
            local dist = mathfloor(GetDistance(HRP.Position))

            local Tool = Player.Character:FindFirstChildOfClass("Tool")
            local namePart = Player.DisplayName == Player.Name and Player.Name or Player.DisplayName.." {"..Player.Name.."}"
            local healthPart = "("..tostring(mathfloor(Humanoid.Health))..")"
            local distPart   = "["..dist.."m]"

            local content = ""
            if ES.DisplayName     then content = namePart..content end
            if ES.DisplayHealth   then content = healthPart..(ES.DisplayName and " " or "")..content end
            if ES.DisplayDistance then content = content.." "..distPart end

            PlayerTable.ESP.Center       = true
            PlayerTable.ESP.Size         = ES.TextSize
            PlayerTable.ESP.Outline      = ES.Outline
            PlayerTable.ESP.OutlineColor = ES.OutlineColor
            PlayerTable.ESP.Color        = ES.TextColor
            PlayerTable.ESP.Transparency = ES.TextTransparency
            PlayerTable.ESP.Font         = ES.TextFont
            PlayerTable.ESP.Text         = (Tool and "["..Tool.Name.."]\n" or "")..content
            PlayerTable.ESP.Position     = Vector2new(Vector.X, Vector.Y - ES.Offset - (Tool and 10 or 0))
            PlayerTable.ESP.Visible      = true
        end)
    end,

    AddTracer = function(Player)
        local PlayerTable = GetPlayerTable(Player)
        PlayerTable.Tracer = Drawingnew("Line")

        PlayerTable.Connections.Tracer = RunService.RenderStepped:Connect(function()
            local TS = Environment.Visuals.TracersSettings
            if not (Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                and Player.Character:FindFirstChild("HumanoidRootPart")
                and Player.Character:FindFirstChild("Head")
                and Environment.Settings.Enabled and TS.Enabled) then
                PlayerTable.Tracer.Visible = false
                return
            end

            local passChecks = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and PlayerTable.Checks.Distance
            if not passChecks then
                PlayerTable.Tracer.Visible = false
                return
            end

            local HRPCFrame, HRPSize = Player.Character.HumanoidRootPart.CFrame, Player.Character.HumanoidRootPart.Size
            local _3DVector, OnScreen = WorldToViewportPoint((HRPCFrame * CFramenew(0, -HRPSize.Y - 0.5, 0)).Position)
            local _2DVector           = WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
            local HeadOff             = WorldToViewportPoint(Player.Character.Head.Position + Vector3new(0, 0.5, 0))
            local LegsOff             = WorldToViewportPoint(Player.Character.HumanoidRootPart.Position - Vector3new(0, 1.5, 0))

            if not OnScreen then
                PlayerTable.Tracer.Visible = false
                return
            end

            PlayerTable.Tracer.Thickness    = TS.Thickness
            PlayerTable.Tracer.Color        = TS.Color
            PlayerTable.Tracer.Transparency = TS.Transparency
            PlayerTable.Tracer.To           = Environment.Visuals.BoxSettings.Type == 1
                and Vector2new(_3DVector.X, _3DVector.Y)
                or  Vector2new(_2DVector.X, _2DVector.Y - (HeadOff.Y - LegsOff.Y) * 0.75)

            if TS.Type == 2 then
                PlayerTable.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            elseif TS.Type == 3 then
                local ml = UserInputService:GetMouseLocation()
                PlayerTable.Tracer.From = Vector2new(ml.X, ml.Y)
            else
                PlayerTable.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            end

            PlayerTable.Tracer.Visible = true
        end)
    end,

    AddBox = function(Player)
        local PlayerTable = GetPlayerTable(Player)

        PlayerTable.Box.Square         = Drawingnew("Square")
        PlayerTable.Box.TopLeftLine    = Drawingnew("Line")
        PlayerTable.Box.TopRightLine   = Drawingnew("Line")
        PlayerTable.Box.BottomLeftLine = Drawingnew("Line")
        PlayerTable.Box.BottomRightLine = Drawingnew("Line")

        local function HideAll()
            PlayerTable.Box.Square.Visible          = false
            PlayerTable.Box.TopLeftLine.Visible     = false
            PlayerTable.Box.TopRightLine.Visible    = false
            PlayerTable.Box.BottomLeftLine.Visible  = false
            PlayerTable.Box.BottomRightLine.Visible = false
        end

        local function ApplyLineStyle(line)
            local BS = Environment.Visuals.BoxSettings
            line.Thickness    = BS.Thickness
            line.Transparency = BS.Transparency
            line.Color        = BS.Color
        end

        PlayerTable.Connections.Box = RunService.RenderStepped:Connect(function()
            local BS = Environment.Visuals.BoxSettings
            if not (Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                and Player.Character:FindFirstChild("HumanoidRootPart")
                and Player.Character:FindFirstChild("Head")
                and Environment.Settings.Enabled and BS.Enabled) then
                HideAll(); return
            end

            local passChecks = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and PlayerTable.Checks.Distance
            if not passChecks then HideAll(); return end

            local Vector, OnScreen = WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
            if not OnScreen then HideAll(); return end

            local HRPCFrame = Player.Character.HumanoidRootPart.CFrame
            local HRPSize   = Player.Character.HumanoidRootPart.Size * BS.Increase

            local HeadOff = WorldToViewportPoint(Player.Character.Head.Position + Vector3new(0, 0.5, 0))
            local LegsOff = WorldToViewportPoint(Player.Character.HumanoidRootPart.Position - Vector3new(0, 3, 0))

            if BS.Type == 2 then
                -- 2D Square
                PlayerTable.Box.TopLeftLine.Visible    = false
                PlayerTable.Box.TopRightLine.Visible   = false
                PlayerTable.Box.BottomLeftLine.Visible = false
                PlayerTable.Box.BottomRightLine.Visible = false

                local sq = PlayerTable.Box.Square
                sq.Visible      = true
                sq.Thickness    = BS.Thickness
                sq.Color        = BS.Color
                sq.Transparency = BS.Transparency
                sq.Filled       = BS.Filled
                sq.Size         = Vector2new(2000 / Vector.Z, HeadOff.Y - LegsOff.Y)
                sq.Position     = Vector2new(Vector.X - sq.Size.X / 2, Vector.Y - sq.Size.Y / 2)
            else
                -- 3D Corner Box
                PlayerTable.Box.Square.Visible = false

                local TL = WorldToViewportPoint((HRPCFrame * CFramenew( HRPSize.X,  HRPSize.Y, 0)).Position)
                local TR = WorldToViewportPoint((HRPCFrame * CFramenew(-HRPSize.X,  HRPSize.Y, 0)).Position)
                local BL = WorldToViewportPoint((HRPCFrame * CFramenew( HRPSize.X, -HRPSize.Y - 0.5, 0)).Position)
                local BR = WorldToViewportPoint((HRPCFrame * CFramenew(-HRPSize.X, -HRPSize.Y - 0.5, 0)).Position)

                local lines = {
                    {PlayerTable.Box.TopLeftLine,    TL, TR},
                    {PlayerTable.Box.TopRightLine,   TR, BR},
                    {PlayerTable.Box.BottomLeftLine, BL, TL},
                    {PlayerTable.Box.BottomRightLine,BR, BL},
                }

                for _, l in next, lines do
                    l[1].Visible = true
                    ApplyLineStyle(l[1])
                    l[1].From = Vector2new(l[2].X, l[2].Y)
                    l[1].To   = Vector2new(l[3].X, l[3].Y)
                end
            end
        end)
    end,

    AddHeadDot = function(Player)
        local PlayerTable = GetPlayerTable(Player)
        PlayerTable.HeadDot = Drawingnew("Circle")

        PlayerTable.Connections.HeadDot = RunService.RenderStepped:Connect(function()
            local HS = Environment.Visuals.HeadDotSettings
            if not (Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                and Player.Character:FindFirstChild("Head")
                and Environment.Settings.Enabled and HS.Enabled) then
                PlayerTable.HeadDot.Visible = false
                return
            end

            local Vector, OnScreen = WorldToViewportPoint(Player.Character.Head.Position)
            local passChecks = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and PlayerTable.Checks.Distance

            if not (OnScreen and passChecks) then
                PlayerTable.HeadDot.Visible = false
                return
            end

            local Top    = WorldToViewportPoint((Player.Character.Head.CFrame * CFramenew(0,  Player.Character.Head.Size.Y / 2, 0)).Position)
            local Bottom = WorldToViewportPoint((Player.Character.Head.CFrame * CFramenew(0, -Player.Character.Head.Size.Y / 2, 0)).Position)

            PlayerTable.HeadDot.Thickness    = HS.Thickness
            PlayerTable.HeadDot.Color        = HS.Color
            PlayerTable.HeadDot.Transparency = HS.Transparency
            PlayerTable.HeadDot.NumSides     = HS.Sides
            PlayerTable.HeadDot.Filled       = HS.Filled
            PlayerTable.HeadDot.Position     = Vector2new(Vector.X, Vector.Y)
            PlayerTable.HeadDot.Radius       = mathabs((Top - Bottom).Y) - 3
            PlayerTable.HeadDot.Visible      = true
        end)
    end,

    AddHealthBar = function(Player)
        local PlayerTable = GetPlayerTable(Player)
        PlayerTable.HealthBar.Main    = Drawingnew("Square")
        PlayerTable.HealthBar.Outline = Drawingnew("Square")

        PlayerTable.Connections.HealthBar = RunService.RenderStepped:Connect(function()
            local HB = Environment.Visuals.HealthBarSettings
            if not (Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                and Player.Character:FindFirstChild("HumanoidRootPart")
                and Environment.Settings.Enabled and HB.Enabled) then
                PlayerTable.HealthBar.Main.Visible    = false
                PlayerTable.HealthBar.Outline.Visible = false
                return
            end

            local passChecks = PlayerTable.Checks.Alive and PlayerTable.Checks.Team and PlayerTable.Checks.Distance
            if not passChecks then
                PlayerTable.HealthBar.Main.Visible    = false
                PlayerTable.HealthBar.Outline.Visible = false
                return
            end

            local Vector, OnScreen = WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
            if not OnScreen then
                PlayerTable.HealthBar.Main.Visible    = false
                PlayerTable.HealthBar.Outline.Visible = false
                return
            end

            local Humanoid    = Player.Character:FindFirstChildOfClass("Humanoid")
            local HRP         = Player.Character.HumanoidRootPart
            local LeftPos     = WorldToViewportPoint((HRP.CFrame * CFramenew( HRP.Size.X, HRP.Size.Y / 2, 0)).Position)
            local RightPos    = WorldToViewportPoint((HRP.CFrame * CFramenew(-HRP.Size.X, HRP.Size.Y / 2, 0)).Position)
            local healthRatio = Humanoid.Health / Humanoid.MaxHealth

            local main    = PlayerTable.HealthBar.Main
            local outline = PlayerTable.HealthBar.Outline

            main.Thickness    = 1
            main.Color        = Color3fromRGB(mathfloor((1 - healthRatio) * 255), mathfloor(healthRatio * 255), HB.Blue)
            main.Transparency = HB.Transparency
            main.Filled       = true
            main.ZIndex       = 2

            outline.Thickness    = 3
            outline.Color        = HB.OutlineColor
            outline.Transparency = HB.Transparency
            outline.Filled       = false
            outline.ZIndex       = 1

            if HB.Type == 1 then
                outline.Size     = Vector2new(2000 / Vector.Z, HB.Size)
                main.Size        = Vector2new(outline.Size.X * healthRatio, outline.Size.Y)
                main.Position    = Vector2new(Vector.X - outline.Size.X / 2, Vector.Y - outline.Size.X / 2 - HB.Offset)
            elseif HB.Type == 2 then
                outline.Size     = Vector2new(2000 / Vector.Z, HB.Size)
                main.Size        = Vector2new(outline.Size.X * healthRatio, outline.Size.Y)
                main.Position    = Vector2new(Vector.X - outline.Size.X / 2, Vector.Y + outline.Size.X / 2 + HB.Offset)
            elseif HB.Type == 3 then
                outline.Size     = Vector2new(HB.Size, 2500 / Vector.Z)
                main.Size        = Vector2new(outline.Size.X, outline.Size.Y * healthRatio)
                main.Position    = Vector2new(LeftPos.X - HB.Offset, Vector.Y - outline.Size.Y / 2)
            elseif HB.Type == 4 then
                outline.Size     = Vector2new(HB.Size, 2500 / Vector.Z)
                main.Size        = Vector2new(outline.Size.X, outline.Size.Y * healthRatio)
                main.Position    = Vector2new(RightPos.X + HB.Offset, Vector.Y - outline.Size.Y / 2)
            end

            outline.Position = main.Position
            main.Visible     = true
            outline.Visible  = true
        end)
    end,

    AddCrosshair = function()
        local AxisX, AxisY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
        local CS = Environment.Crosshair.Settings
        local CP = Environment.Crosshair.Parts

        ServiceConnections.AxisConnection = RunService.RenderStepped:Connect(function()
            if CS.Type == 2 then
                AxisX, AxisY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
            else
                local ml = UserInputService:GetMouseLocation()
                AxisX, AxisY = ml.X, ml.Y
            end
        end)

        ServiceConnections.CrosshairConnection = RunService.RenderStepped:Connect(function()
            if not CS.Enabled then
                CP.LeftLine.Visible = false; CP.RightLine.Visible = false
                CP.TopLine.Visible  = false; CP.BottomLine.Visible = false
                CP.CenterDot.Visible = false
                return
            end

            local rot, gap, sz = CS.Rotation, CS.GapSize, CS.Size
            local cosR, sinR = mathcos(mathrad(rot)), mathsin(mathrad(rot))

            local function applyLine(line, fromX, fromY, toX, toY)
                line.Visible     = true
                line.Color       = CS.Color
                line.Thickness   = CS.Thickness
                line.Transparency = CS.Transparency
                line.From        = Vector2new(fromX, fromY)
                line.To          = Vector2new(toX, toY)
            end

            applyLine(CP.LeftLine,
                AxisX - cosR * gap,         AxisY - sinR * gap,
                AxisX - cosR * (sz + gap),  AxisY - sinR * (sz + gap))

            applyLine(CP.RightLine,
                AxisX + cosR * gap,         AxisY + sinR * gap,
                AxisX + cosR * (sz + gap),  AxisY + sinR * (sz + gap))

            applyLine(CP.TopLine,
                AxisX - sinR * gap,         AxisY - cosR * gap,
                AxisX - sinR * (sz + gap),  AxisY - cosR * (sz + gap))

            applyLine(CP.BottomLine,
                AxisX + sinR * gap,         AxisY + cosR * gap,
                AxisX + sinR * (sz + gap),  AxisY + cosR * (sz + gap))

            -- Center Dot
            CP.CenterDot.Visible     = CS.CenterDot
            CP.CenterDot.Color       = CS.CenterDotColor
            CP.CenterDot.Radius      = CS.CenterDotSize
            CP.CenterDot.Transparency = CS.CenterDotTransparency
            CP.CenterDot.Filled      = CS.CenterDotFilled
            CP.CenterDot.Thickness   = CS.CenterDotThickness
            CP.CenterDot.Position    = Vector2new(AxisX, AxisY)
        end)
    end
}

--// Wrap / UnWrap

local function Wrap(Player)
    if GetPlayerTable(Player) then return end

    local Value = {
        Name    = Player.Name,
        Checks  = {Alive = true, Team = true, Distance = true},
        Connections = {},
        ESP     = nil, Tracer = nil, HeadDot = nil,
        HealthBar = {Main = nil, Outline = nil},
        Box     = {Square = nil, TopLeftLine = nil, TopRightLine = nil, BottomLeftLine = nil, BottomRightLine = nil},
        Chams   = {}
    }

    Environment.WrappedPlayers[#Environment.WrappedPlayers + 1] = Value
    AssignRigType(Player)
    InitChecks(Player)

    Visuals.AddChams(Player)
    Visuals.AddESP(Player)
    Visuals.AddTracer(Player)
    Visuals.AddBox(Player)
    Visuals.AddHeadDot(Player)
    Visuals.AddHealthBar(Player)
end

local function UnWrap(Player)
    local Table, Index = nil, nil
    for i, v in next, Environment.WrappedPlayers do
        if v.Name == Player.Name then Table, Index = v, i end
    end
    if not Table then return end

    for _, conn in next, Table.Connections do conn:Disconnect() end

    pcall(function()
        Table.ESP:Remove()
        Table.Tracer:Remove()
        Table.HeadDot:Remove()
        Table.HealthBar.Main:Remove()
        Table.HealthBar.Outline:Remove()
    end)

    for _, v in next, Table.Box do
        if v and v.Remove then v:Remove() end
    end

    for _, chamParts in next, Table.Chams do
        for i = 1, 6 do
            local q = chamParts["Quad"..i]
            if q and q.Remove then q:Remove() end
        end
    end

    Environment.WrappedPlayers[Index] = nil
end

local function Load()
    Visuals.AddCrosshair()
    ServiceConnections.PlayerAdded    = Players.PlayerAdded:Connect(Wrap)
    ServiceConnections.PlayerRemoving = Players.PlayerRemoving:Connect(UnWrap)

    -- Periodic re-wrap to catch any missed players
    local lastRewrap = 0
    ServiceConnections.ReWrapPlayers = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastRewrap < 30 then return end
        lastRewrap = now
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer then Wrap(v) end
        end
    end)
end

--// Functions

Environment.Functions = {}

function Environment.Functions:Exit()
    for _, v in next, ServiceConnections do v:Disconnect() end
    for _, v in next, Environment.Crosshair.Parts do v:Remove() end
    for _, v in next, Players:GetPlayers() do
        if v ~= LocalPlayer then UnWrap(v) end
    end
    getgenv().AirHub.WallHack.Functions = nil
    getgenv().AirHub.WallHack = nil
    Load = nil; GetPlayerTable = nil; AssignRigType = nil; InitChecks = nil
    UpdateCham = nil; Visuals = nil; Wrap = nil; UnWrap = nil
end

function Environment.Functions:Restart()
    for _, v in next, Players:GetPlayers() do
        if v ~= LocalPlayer then UnWrap(v) end
    end
    for _, v in next, ServiceConnections do v:Disconnect() end
    Load()
end

function Environment.Functions:ResetSettings()
    Environment.Settings = {
        Enabled = false, TeamCheck = false, AliveCheck = true, MaxDistance = 1000
    }

    Environment.Visuals = {
        ChamsSettings = {Enabled=false, Color=Color3fromRGB(255,255,255), Transparency=0.2, Thickness=0, Filled=true, EntireBody=false},
        ESPSettings   = {Enabled=true, TextColor=Color3fromRGB(255,255,255), TextSize=14, Outline=true, OutlineColor=Color3fromRGB(0,0,0), TextTransparency=0.7, TextFont=Drawing.Fonts.UI, Offset=20, DisplayDistance=true, DisplayHealth=true, DisplayName=true},
        TracersSettings = {Enabled=true, Type=1, Transparency=0.7, Thickness=1, Color=Color3fromRGB(255,255,255)},
        BoxSettings   = {Enabled=true, Type=1, Color=Color3fromRGB(255,255,255), Transparency=0.7, Thickness=1, Filled=false, Increase=1},
        HeadDotSettings = {Enabled=true, Color=Color3fromRGB(255,255,255), Transparency=0.5, Thickness=1, Filled=false, Sides=30},
        HealthBarSettings = {Enabled=false, Transparency=0.8, Size=2, Offset=10, OutlineColor=Color3fromRGB(0,0,0), Blue=50, Type=3}
    }

    Environment.Crosshair.Settings = {
        Enabled=false, Type=1, Size=12, Thickness=1, Color=Color3fromRGB(0,255,0), Transparency=1, GapSize=5,
        Rotation=0, CenterDot=false, CenterDotColor=Color3fromRGB(0,255,0), CenterDotSize=1,
        CenterDotTransparency=1, CenterDotFilled=true, CenterDotThickness=1
    }
end

setmetatable(Environment.Functions, {__newindex = warn})

--// Main

Load()


-- ══════════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════════

local Aimbot   = getgenv().AirHub.Aimbot
local WallHack = getgenv().AirHub.WallHack

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
local MainTab     = Window:CreateTab("Main",     4483362458)
local AimbotTab   = Window:CreateTab("Aimbot",   4483362458)
local WallhackTab = Window:CreateTab("Wallhack", 4483362458)
local UtilityTab  = Window:CreateTab("Utility",  4483362458)

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

-- Keybind button: supports ANY key or mouse button including side buttons
local _bindingKey = false
local _keybindBtn
_keybindBtn = MainTab:CreateButton({ Name="Hotkey: MouseButton2",
    Callback=function()
        if _bindingKey then return end
        _bindingKey = true
        _keybindBtn.Name = "[ PRESS ANY KEY / BUTTON... ]"
        local conn
        conn = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if not _bindingKey then return end
            _bindingKey = false
            local key
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode.Name
            else
                key = input.UserInputType.Name
            end
            if Aimbot and Aimbot.Settings then Aimbot.Settings.TriggerKey = key end
            _keybindBtn.Name = "Hotkey: " .. key
            conn:Disconnect()
        end)
    end
})

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
