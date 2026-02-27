--// Cache

local select, next, tostring, pcall, getgenv, setmetatable = select, next, tostring, pcall, getgenv, setmetatable
local mathfloor, mathabs, mathcos, mathsin, mathrad, mathsqrt = math.floor, math.abs, math.cos, math.sin, math.rad, math.sqrt
local wait = task.wait
local Vector2new, Vector3new, Vector3zero, CFramenew, Drawingnew, Color3fromRGB = Vector2.new, Vector3.new, Vector3.zero, CFrame.new, Drawing.new, Color3.fromRGB

--// Launching checks

if not getgenv().AirHub or getgenv().AirHub.WallHack then return end

--// Services

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

--// Variables

local ServiceConnections = {}
local WorldToViewportPoint

--// Helper

local function GetDistance(TargetPos)
    local LP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not LP then return math.huge end
    return (TargetPos - LP.Position).Magnitude
end

--// Environment

getgenv().AirHub.WallHack = {
    Settings = {
        Enabled    = false,
        TeamCheck  = false,
        AliveCheck = true,
        MaxDistance = 1000
    },

    Visuals = {
        ChamsSettings = {
            Enabled      = false,
            Color        = Color3fromRGB(255, 255, 255),
            Transparency = 0.2,
            Thickness    = 0,
            Filled       = true,
            EntireBody   = false
        },

        ESPSettings = {
            Enabled          = true,
            TextColor        = Color3fromRGB(255, 255, 255),
            TextSize         = 14,
            Outline          = true,
            OutlineColor     = Color3fromRGB(0, 0, 0),
            TextTransparency = 0.7,
            TextFont         = Drawing.Fonts.UI,
            Offset           = 20,
            DisplayDistance  = true,
            DisplayHealth    = true,
            DisplayName      = true
        },

        TracersSettings = {
            Enabled      = true,
            Type         = 1,
            Transparency = 0.7,
            Thickness    = 1,
            Color        = Color3fromRGB(255, 255, 255)
        },

        BoxSettings = {
            Enabled      = true,
            Type         = 1,
            Color        = Color3fromRGB(255, 255, 255),
            Transparency = 0.7,
            Thickness    = 1,
            Filled       = false,
            Increase     = 1
        },

        HeadDotSettings = {
            Enabled      = true,
            Color        = Color3fromRGB(255, 255, 255),
            Transparency = 0.5,
            Thickness    = 1,
            Filled       = false,
            Sides        = 30
        },

        HealthBarSettings = {
            Enabled      = false,
            Transparency = 0.8,
            Size         = 2,
            Offset       = 10,
            OutlineColor = Color3fromRGB(0, 0, 0),
            Blue         = 50,
            Type         = 3
        }
    },

    Crosshair = {
        Settings = {
            Enabled               = false,
            Type                  = 1,
            Size                  = 12,
            Thickness             = 1,
            Color                 = Color3fromRGB(0, 255, 0),
            Transparency          = 1,
            GapSize               = 5,
            Rotation              = 0,
            CenterDot             = false,
            CenterDotColor        = Color3fromRGB(0, 255, 0),
            CenterDotSize         = 1,
            CenterDotTransparency = 1,
            CenterDotFilled       = true,
            CenterDotThickness    = 1
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

--// Core

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
        if v.Name == Player.Name then return v end
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

--// Cham helpers

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

--// ─────────────────────────────────────────────────────────────────────────
--// Wrap – all visuals in ONE RenderStepped per player
--// ─────────────────────────────────────────────────────────────────────────

local function Wrap(Player)
    if GetPlayerTable(Player) then return end

    -- Drawing objects
    local ESP     = Drawingnew("Text")
    local Tracer  = Drawingnew("Line")
    local HeadDot = Drawingnew("Circle")
    local HBMain  = Drawingnew("Square")
    local HBOutline = Drawingnew("Square")
    local Box2D   = Drawingnew("Square")

    -- Corner box: 8 lines (2 per corner = top-left, top-right, bottom-left, bottom-right)
    -- Each corner has a horizontal arm and a vertical arm
    local CornerLines = {}
    for i = 1, 8 do CornerLines[i] = Drawingnew("Line") end

    local Value = {
        Name    = Player.Name,
        Checks  = {Alive = true, Team = true, Distance = true},
        Connections = {},
        RigType = nil,
        ESP      = ESP,
        Tracer   = Tracer,
        HeadDot  = HeadDot,
        HealthBar = {Main = HBMain, Outline = HBOutline},
        Box       = {Square = Box2D, Corners = CornerLines},
        Chams     = {}
    }

    Environment.WrappedPlayers[#Environment.WrappedPlayers + 1] = Value

    -- Build chams rig
    local function BuildRig()
        for _, v in next, Value.Chams do
            for i = 1, 6 do local q = v["Quad"..i]; if q and q.Remove then q:Remove() end end
        end
        local parts = {}
        if Value.RigType == "R15" then
            if not Environment.Visuals.ChamsSettings.EntireBody then
                parts = {"Head","UpperTorso","LeftLowerArm","LeftUpperArm","RightLowerArm","RightUpperArm","LeftLowerLeg","LeftUpperLeg","RightLowerLeg","RightUpperLeg"}
            else
                parts = {"Head","UpperTorso","LowerTorso","LeftLowerArm","LeftUpperArm","LeftHand","RightLowerArm","RightUpperArm","RightHand","LeftLowerLeg","LeftUpperLeg","LeftFoot","RightLowerLeg","RightUpperLeg","RightFoot"}
            end
        else
            parts = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
        end
        Value.Chams = {}
        for _, name in next, parts do
            Value.Chams[name] = {}
            for i = 1, 6 do Value.Chams[name]["Quad"..i] = Drawingnew("Quad") end
        end
    end

    local oldEntireBody = Environment.Visuals.ChamsSettings.EntireBody

    -- AssignRigType yields (repeat wait), must run in a separate thread
    task.spawn(function()
        AssignRigType(Player)
        BuildRig()
    end)

    local function HideAll()
        ESP.Visible       = false
        Tracer.Visible    = false
        HeadDot.Visible   = false
        HBMain.Visible    = false
        HBOutline.Visible = false
        Box2D.Visible     = false
        for i = 1, 8 do CornerLines[i].Visible = false end
        for _, cham in next, Value.Chams do
            for i = 1, 6 do cham["Quad"..i].Visible = false end
        end
    end

    -- Check updates on Heartbeat (cheap, no drawing)
    Value.Connections.Checks = RunService.Heartbeat:Connect(function()
        if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
            Value.Checks.Alive = not Environment.Settings.AliveCheck
                or Player.Character:FindFirstChildOfClass("Humanoid").Health > 0
            Value.Checks.Team = not Environment.Settings.TeamCheck
                or Player.TeamColor ~= LocalPlayer.TeamColor
            local HRP = Player.Character:FindFirstChild("HumanoidRootPart")
            Value.Checks.Distance = HRP and IsWithinDistance(HRP.Position) or false
        else
            Value.Checks.Alive    = false
            Value.Checks.Team     = false
            Value.Checks.Distance = false
        end
    end)

    -- Single RenderStepped for all drawing
    Value.Connections.Render = RunService.RenderStepped:Connect(function()
        local Enabled = Environment.Settings.Enabled
        local char    = Player.Character
        local pass    = Value.Checks.Alive and Value.Checks.Team and Value.Checks.Distance

        if not (Enabled and char and pass) then
            HideAll(); return
        end

        local HRP  = char:FindFirstChild("HumanoidRootPart")
        local Head = char:FindFirstChild("Head")
        local Hum  = char:FindFirstChildOfClass("Humanoid")
        if not (HRP and Head and Hum) then HideAll(); return end

        local hrpVec, onScreen = WorldToViewportPoint(HRP.Position)
        if not onScreen then HideAll(); return end

        local headVec  = WorldToViewportPoint(Head.Position + Vector3new(0, 0.5, 0))
        local legsVec  = WorldToViewportPoint(HRP.Position  - Vector3new(0, 3, 0))
        local hrpCF    = HRP.CFrame
        local boxH     = mathabs(headVec.Y - legsVec.Y)
        local boxW     = 2000 / hrpVec.Z
        local leftX    = hrpVec.X - boxW / 2
        local rightX   = hrpVec.X + boxW / 2
        local topY     = headVec.Y
        local botY     = legsVec.Y

        -- ── ESP Text ──────────────────────────────────────────────────────
        local ES = Environment.Visuals.ESPSettings
        if ES.Enabled then
            local dist    = mathfloor(GetDistance(HRP.Position))
            local Tool    = char:FindFirstChildOfClass("Tool")
            local nameStr = Player.DisplayName == Player.Name and Player.Name
                            or Player.DisplayName.." {"..Player.Name.."}"
            local content = ""
            if ES.DisplayName     then content = nameStr end
            if ES.DisplayHealth   then
                local hp = "("..tostring(mathfloor(Hum.Health))..")"
                content = hp..(content ~= "" and " "..content or "")
            end
            if ES.DisplayDistance then content = content.." ["..dist.."m]" end

            ESP.Center       = true
            ESP.Size         = ES.TextSize
            ESP.Outline      = ES.Outline
            ESP.OutlineColor = ES.OutlineColor
            ESP.Color        = ES.TextColor
            ESP.Transparency = ES.TextTransparency
            ESP.Font         = ES.TextFont
            ESP.Text         = (Tool and "["..Tool.Name.."]\n" or "")..content
            ESP.Position     = Vector2new(hrpVec.X, topY - ES.Offset)
            ESP.Visible      = true
        else
            ESP.Visible = false
        end

        -- ── Box ───────────────────────────────────────────────────────────
        local BS = Environment.Visuals.BoxSettings
        if BS.Enabled then
            if BS.Type == 2 then
                -- 2D full square
                for i = 1, 8 do CornerLines[i].Visible = false end
                Box2D.Visible      = true
                Box2D.Thickness    = BS.Thickness
                Box2D.Color        = BS.Color
                Box2D.Transparency = BS.Transparency
                Box2D.Filled       = BS.Filled
                Box2D.Size         = Vector2new(boxW, boxH)
                Box2D.Position     = Vector2new(leftX, topY)
            else
                -- 3D Corner box: 4 corners × 2 lines each = 8 lines
                Box2D.Visible = false

                -- Project the 4 screen-space corners
                local TL = Vector2new(leftX,  topY)
                local TR = Vector2new(rightX, topY)
                local BL = Vector2new(leftX,  botY)
                local BR = Vector2new(rightX, botY)

                -- Corner arm length = 25% of box dimension
                local cw = (rightX - leftX) * 0.25
                local ch = (botY - topY) * 0.25

                local function setLine(line, x1, y1, x2, y2)
                    line.Visible      = true
                    line.Color        = BS.Color
                    line.Thickness    = BS.Thickness
                    line.Transparency = BS.Transparency
                    line.From         = Vector2new(x1, y1)
                    line.To           = Vector2new(x2, y2)
                end

                -- Top-Left corner: horizontal right, vertical down
                setLine(CornerLines[1], TL.X, TL.Y, TL.X + cw, TL.Y)
                setLine(CornerLines[2], TL.X, TL.Y, TL.X,       TL.Y + ch)
                -- Top-Right corner: horizontal left, vertical down
                setLine(CornerLines[3], TR.X, TR.Y, TR.X - cw, TR.Y)
                setLine(CornerLines[4], TR.X, TR.Y, TR.X,       TR.Y + ch)
                -- Bottom-Left corner: horizontal right, vertical up
                setLine(CornerLines[5], BL.X, BL.Y, BL.X + cw, BL.Y)
                setLine(CornerLines[6], BL.X, BL.Y, BL.X,       BL.Y - ch)
                -- Bottom-Right corner: horizontal left, vertical up
                setLine(CornerLines[7], BR.X, BR.Y, BR.X - cw, BR.Y)
                setLine(CornerLines[8], BR.X, BR.Y, BR.X,       BR.Y - ch)
            end
        else
            Box2D.Visible = false
            for i = 1, 8 do CornerLines[i].Visible = false end
        end

        -- ── Tracer ────────────────────────────────────────────────────────
        local TS = Environment.Visuals.TracersSettings
        if TS.Enabled then
            Tracer.Thickness    = TS.Thickness
            Tracer.Color        = TS.Color
            Tracer.Transparency = TS.Transparency
            Tracer.To           = Vector2new(hrpVec.X, botY)
            if TS.Type == 2 then
                Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            elseif TS.Type == 3 then
                local ml = UserInputService:GetMouseLocation()
                Tracer.From = Vector2new(ml.X, ml.Y)
            else
                Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            end
            Tracer.Visible = true
        else
            Tracer.Visible = false
        end

        -- ── Head Dot ──────────────────────────────────────────────────────
        local HS = Environment.Visuals.HeadDotSettings
        if HS.Enabled then
            local hTop = WorldToViewportPoint((Head.CFrame * CFramenew(0,  Head.Size.Y / 2, 0)).Position)
            local hBot = WorldToViewportPoint((Head.CFrame * CFramenew(0, -Head.Size.Y / 2, 0)).Position)
            local hVec = WorldToViewportPoint(Head.Position)
            HeadDot.Thickness    = HS.Thickness
            HeadDot.Color        = HS.Color
            HeadDot.Transparency = HS.Transparency
            HeadDot.NumSides     = HS.Sides
            HeadDot.Filled       = HS.Filled
            HeadDot.Position     = Vector2new(hVec.X, hVec.Y)
            HeadDot.Radius       = mathabs((hTop - hBot).Y) - 3
            HeadDot.Visible      = true
        else
            HeadDot.Visible = false
        end

        -- ── Health Bar ────────────────────────────────────────────────────
        local HB = Environment.Visuals.HealthBarSettings
        if HB.Enabled then
            local healthRatio = math.clamp(Hum.Health / math.max(Hum.MaxHealth, 1), 0, 1)
            local hpColor     = Color3fromRGB(mathfloor((1 - healthRatio) * 255), mathfloor(healthRatio * 255), HB.Blue)

            HBMain.Thickness    = 1
            HBMain.Color        = hpColor
            HBMain.Transparency = HB.Transparency
            HBMain.Filled       = true
            HBMain.ZIndex       = 2

            HBOutline.Thickness    = 3
            HBOutline.Color        = HB.OutlineColor
            HBOutline.Transparency = HB.Transparency
            HBOutline.Filled       = false
            HBOutline.ZIndex       = 1

            local LeftPos  = WorldToViewportPoint((HRP.CFrame * CFramenew( HRP.Size.X, HRP.Size.Y / 2, 0)).Position)
            local RightPos = WorldToViewportPoint((HRP.CFrame * CFramenew(-HRP.Size.X, HRP.Size.Y / 2, 0)).Position)

            if HB.Type == 1 then
                HBOutline.Size     = Vector2new(boxW, HB.Size)
                HBMain.Size        = Vector2new(boxW * healthRatio, HB.Size)
                HBMain.Position    = Vector2new(leftX, topY - HB.Offset)
            elseif HB.Type == 2 then
                HBOutline.Size     = Vector2new(boxW, HB.Size)
                HBMain.Size        = Vector2new(boxW * healthRatio, HB.Size)
                HBMain.Position    = Vector2new(leftX, botY + HB.Offset)
            elseif HB.Type == 3 then
                HBOutline.Size     = Vector2new(HB.Size, boxH)
                HBMain.Size        = Vector2new(HB.Size, boxH * healthRatio)
                HBMain.Position    = Vector2new(LeftPos.X - HB.Offset, topY)
            elseif HB.Type == 4 then
                HBOutline.Size     = Vector2new(HB.Size, boxH)
                HBMain.Size        = Vector2new(HB.Size, boxH * healthRatio)
                HBMain.Position    = Vector2new(RightPos.X + HB.Offset, topY)
            end

            HBOutline.Position = HBMain.Position
            HBMain.Visible     = true
            HBOutline.Visible  = true
        else
            HBMain.Visible    = false
            HBOutline.Visible = false
        end

        -- ── Chams ─────────────────────────────────────────────────────────
        local CS = Environment.Visuals.ChamsSettings
        if CS.Enabled then
            if CS.EntireBody ~= oldEntireBody then
                BuildRig(); oldEntireBody = CS.EntireBody
            end
            for name, cham in next, Value.Chams do
                local part = char:FindFirstChild(name)
                if part then UpdateCham(part, cham) end
            end
        else
            for _, cham in next, Value.Chams do
                for i = 1, 6 do cham["Quad"..i].Visible = false end
            end
        end
    end)
end

local function UnWrap(Player)
    local Table, Index = nil, nil
    for i, v in next, Environment.WrappedPlayers do
        if v.Name == Player.Name then Table, Index = v, i end
    end
    if not Table then return end

    for _, conn in next, Table.Connections do conn:Disconnect() end

    pcall(function() Table.ESP:Remove() end)
    pcall(function() Table.Tracer:Remove() end)
    pcall(function() Table.HeadDot:Remove() end)
    pcall(function() Table.HealthBar.Main:Remove() end)
    pcall(function() Table.HealthBar.Outline:Remove() end)
    pcall(function() Table.Box.Square:Remove() end)
    for i = 1, 8 do
        if Table.Box.Corners[i] then pcall(function() Table.Box.Corners[i]:Remove() end) end
    end
    for _, chamParts in next, Table.Chams do
        for i = 1, 6 do
            local q = chamParts["Quad"..i]
            if q and q.Remove then pcall(function() q:Remove() end) end
        end
    end

    Environment.WrappedPlayers[Index] = nil
end

--// Crosshair (single RenderStepped, unchanged logic)

local function AddCrosshair()
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
            line.Visible      = true
            line.Color        = CS.Color
            line.Thickness    = CS.Thickness
            line.Transparency = CS.Transparency
            line.From         = Vector2new(fromX, fromY)
            line.To           = Vector2new(toX, toY)
        end

        applyLine(CP.LeftLine,
            AxisX - cosR * gap,        AxisY - sinR * gap,
            AxisX - cosR * (sz + gap), AxisY - sinR * (sz + gap))
        applyLine(CP.RightLine,
            AxisX + cosR * gap,        AxisY + sinR * gap,
            AxisX + cosR * (sz + gap), AxisY + sinR * (sz + gap))
        applyLine(CP.TopLine,
            AxisX - sinR * gap,        AxisY - cosR * gap,
            AxisX - sinR * (sz + gap), AxisY - cosR * (sz + gap))
        applyLine(CP.BottomLine,
            AxisX + sinR * gap,        AxisY + cosR * gap,
            AxisX + sinR * (sz + gap), AxisY + cosR * (sz + gap))

        CP.CenterDot.Visible      = CS.CenterDot
        CP.CenterDot.Color        = CS.CenterDotColor
        CP.CenterDot.Radius       = CS.CenterDotSize
        CP.CenterDot.Transparency = CS.CenterDotTransparency
        CP.CenterDot.Filled       = CS.CenterDotFilled
        CP.CenterDot.Thickness    = CS.CenterDotThickness
        CP.CenterDot.Position     = Vector2new(AxisX, AxisY)
    end)
end

--// Load

local function Load()
    AddCrosshair()

    ServiceConnections.PlayerAdded    = Players.PlayerAdded:Connect(Wrap)
    ServiceConnections.PlayerRemoving = Players.PlayerRemoving:Connect(UnWrap)

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
    Load = nil; GetPlayerTable = nil; AssignRigType = nil
    UpdateCham = nil; Wrap = nil; UnWrap = nil
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
        ChamsSettings     = {Enabled=false, Color=Color3fromRGB(255,255,255), Transparency=0.2, Thickness=0, Filled=true, EntireBody=false},
        ESPSettings       = {Enabled=true, TextColor=Color3fromRGB(255,255,255), TextSize=14, Outline=true, OutlineColor=Color3fromRGB(0,0,0), TextTransparency=0.7, TextFont=Drawing.Fonts.UI, Offset=20, DisplayDistance=true, DisplayHealth=true, DisplayName=true},
        TracersSettings   = {Enabled=true, Type=1, Transparency=0.7, Thickness=1, Color=Color3fromRGB(255,255,255)},
        BoxSettings       = {Enabled=true, Type=1, Color=Color3fromRGB(255,255,255), Transparency=0.7, Thickness=1, Filled=false, Increase=1},
        HeadDotSettings   = {Enabled=true, Color=Color3fromRGB(255,255,255), Transparency=0.5, Thickness=1, Filled=false, Sides=30},
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
