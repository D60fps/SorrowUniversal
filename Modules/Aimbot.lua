--// Cache

local pcall, getgenv, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel = pcall, getgenv, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper, mousemoverel or (Input and Input.MouseMove)

--// Launching checks

if not getgenv().AirHub or getgenv().AirHub.Aimbot then return end

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
	RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)
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
