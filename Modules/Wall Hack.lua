local getgenv = getgenv or genv or (function() return getfenv(0) end)
--// Cache

local select, next, tostring, pcall, setmetatable = select, next, tostring, pcall, setmetatable
local mathfloor, mathabs, mathcos, mathsin, mathrad, mathsqrt = math.floor, math.abs, math.cos, math.sin, math.rad, math.sqrt
local wait = task.wait
local Vector2new, Vector3new, Vector3zero, CFramenew, Drawingnew, Color3fromRGB = Vector2.new, Vector3.new, Vector3.zero, CFrame.new, Drawing.new, Color3.fromRGB

--// Launching checks

if not getgenv().AirHub or getgenv().AirHub.WallHack then return end

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
