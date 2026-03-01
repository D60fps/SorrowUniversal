-- Wall Hack.lua - Rewritten & Optimized
--[[
Fixes:
- Fixed Drawing object management
- Fixed memory leaks
- Fixed health bar scaling
- Improved performance with caching
- Added proper cleanup
- Fixed box rendering
]]

--// Cache
local select = select
local next = next
local tostring = tostring
local pcall = pcall
local getgenv = getgenv
local setmetatable = setmetatable
local mathfloor = math.floor
local mathabs = math.abs
local mathcos = math.cos
local mathsin = math.sin
local mathrad = math.rad
local mathsqrt = math.sqrt
local wait = task.wait
local Vector2new = Vector2.new
local Vector3new = Vector3.new
local Vector3zero = Vector3.zero
local CFramenew = CFrame.new
local Drawingnew = Drawing.new
local Color3fromRGB = Color3.fromRGB

--// Launching checks
if not getgenv().AirHub or getgenv().AirHub.WallHack then
    return
end

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables
local ServiceConnections = {}
local PlayerData = {}
local CachedViewportSize = Vector2new(0, 0)
local CachedMouseLocation = Vector2new(0, 0)

--// Environment Setup
getgenv().AirHub.WallHack = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        MaxDistance = 1000
    },
    
    Visuals = {
        ChamsSettings = {
            Enabled = false,
            Color = Color3fromRGB(255, 255, 255),
            Transparency = 0.2,
            Thickness = 0,
            Filled = true,
            EntireBody = false
        },
        
        ESPSettings = {
            Enabled = true,
            TextColor = Color3fromRGB(255, 255, 255),
            TextSize = 14,
            Outline = true,
            OutlineColor = Color3fromRGB(0, 0, 0),
            TextTransparency = 0.7,
            TextFont = Drawing.Fonts.UI,
            Offset = 20,
            DisplayDistance = true,
            DisplayHealth = true,
            DisplayName = true
        },
        
        TracersSettings = {
            Enabled = true,
            Type = 1,
            Transparency = 0.7,
            Thickness = 1,
            Color = Color3fromRGB(255, 255, 255)
        },
        
        BoxSettings = {
            Enabled = true,
            Type = 1,
            Color = Color3fromRGB(255, 255, 255),
            Transparency = 0.7,
            Thickness = 1,
            Filled = false,
            Increase = 1
        },
        
        HeadDotSettings = {
            Enabled = true,
            Color = Color3fromRGB(255, 255, 255),
            Transparency = 0.5,
            Thickness = 1,
            Filled = false,
            Sides = 30
        },
        
        HealthBarSettings = {
            Enabled = false,
            Transparency = 0.8,
            Size = 2,
            Offset = 10,
            OutlineColor = Color3fromRGB(0, 0, 0),
            Blue = 50,
            Type = 3
        }
    },
    
    Crosshair = {
        Settings = {
            Enabled = false,
            Type = 1,
            Size = 12,
            Thickness = 1,
            Color = Color3fromRGB(0, 255, 0),
            Transparency = 1,
            GapSize = 5,
            Rotation = 0,
            CenterDot = false,
            CenterDotColor = Color3fromRGB(0, 255, 0),
            CenterDotSize = 1,
            CenterDotTransparency = 1,
            CenterDotFilled = true,
            CenterDotThickness = 1
        },
        
        Parts = {
            LeftLine = Drawingnew("Line"),
            RightLine = Drawingnew("Line"),
            TopLine = Drawingnew("Line"),
            BottomLine = Drawingnew("Line"),
            CenterDot = Drawingnew("Circle")
        }
    },
    
    Functions = {}
}

local Environment = getgenv().AirHub.WallHack

--// Utility Functions
local function GetDistanceFromLocal(Position)
    local Character = LocalPlayer.Character
    if not Character then
        return math.huge
    end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then
        return math.huge
    end
    
    return (Position - RootPart.Position).Magnitude
end

local function IsWithinDistance(Position)
    local MaxDist = Environment.Settings.MaxDistance
    if MaxDist <= 0 then
        return true
    end
    
    return GetDistanceFromLocal(Position) <= MaxDist
end

local function GetPlayerData(Player)
    return PlayerData[Player]
end

local function CleanupPlayerData(Player)
    local Data = PlayerData[Player]
    if not Data then
        return
    end
    
    -- Disconnect all connections
    for _, Connection in next, Data.Connections do
        Connection:Disconnect()
    end
    
    -- Remove all drawings
    local function RemoveDrawing(obj)
        if obj and obj.Remove then
            pcall(function() obj:Remove() end)
        end
    end
    
    -- Remove ESP
    RemoveDrawing(Data.ESP)
    
    -- Remove Tracer
    RemoveDrawing(Data.Tracer)
    
    -- Remove HeadDot
    RemoveDrawing(Data.HeadDot)
    
    -- Remove HealthBar
    if Data.HealthBar then
        RemoveDrawing(Data.HealthBar.Main)
        RemoveDrawing(Data.HealthBar.Outline)
    end
    
    -- Remove Box
    if Data.Box then
        RemoveDrawing(Data.Box.Square)
        RemoveDrawing(Data.Box.TopLeftLine)
        RemoveDrawing(Data.Box.TopRightLine)
        RemoveDrawing(Data.Box.BottomLeftLine)
        RemoveDrawing(Data.Box.BottomRightLine)
    end
    
    -- Remove Chams
    if Data.Chams then
        for _, PartChams in next, Data.Chams do
            for i = 1, 6 do
                RemoveDrawing(PartChams["Quad"..i])
            end
        end
    end
    
    PlayerData[Player] = nil
end

local function ShouldRenderPlayer(Player, Data)
    if not Environment.Settings.Enabled then
        return false
    end
    
    if not Data.Checks then
        return false
    end
    
    return Data.Checks.Alive and Data.Checks.Team and Data.Checks.Distance
end

--// Rig Type Detection
local function GetRigType(Character)
    if Character:FindFirstChild("Torso") and not Character:FindFirstChild("LowerTorso") then
        return "R6"
    elseif Character:FindFirstChild("LowerTorso") then
        return "R15"
    end
    return nil
end

--// Cham Functions
local function CreateChamQuads()
    local Quads = {}
    for i = 1, 6 do
        Quads["Quad"..i] = Drawingnew("Quad")
    end
    return Quads
end

local function UpdateCham(Part, Quads, Color, Transparency, Thickness, Filled)
    if not Part then
        for i = 1, 6 do
            Quads["Quad"..i].Visible = false
        end
        return
    end
    
    local PartCFrame = Part.CFrame
    local PartSize = Part.Size / 2
    
    -- Calculate all 8 corners
    local Corners = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local Offset = Vector3new(x * PartSize.X, y * PartSize.Y, z * PartSize.Z)
                local WorldPos = (PartCFrame * CFramenew(Offset.X, Offset.Y, Offset.Z)).Position
                local ScreenPos, Visible = Camera:WorldToViewportPoint(WorldPos)
                
                if not Visible then
                    for i = 1, 6 do
                        Quads["Quad"..i].Visible = false
                    end
                    return
                end
                
                table.insert(Corners, Vector2new(ScreenPos.X, ScreenPos.Y))
            end
        end
    end
    
    -- Define faces (front, back, top, bottom, right, left)
    local Faces = {
        {Corners[1], Corners[3], Corners[4], Corners[2]}, -- Front
        {Corners[5], Corners[7], Corners[8], Corners[6]}, -- Back
        {Corners[1], Corners[5], Corners[6], Corners[2]}, -- Top
        {Corners[3], Corners[7], Corners[8], Corners[4]}, -- Bottom
        {Corners[1], Corners[3], Corners[7], Corners[5]}, -- Right
        {Corners[2], Corners[4], Corners[8], Corners[6]}  -- Left
    }
    
    -- Update each face
    for i = 1, 6 do
        local Quad = Quads["Quad"..i]
        Quad.Visible = true
        Quad.Color = Color
        Quad.Transparency = Transparency
        Quad.Thickness = Thickness
        Quad.Filled = Filled
        Quad.PointA = Faces[i][1]
        Quad.PointB = Faces[i][2]
        Quad.PointC = Faces[i][3]
        Quad.PointD = Faces[i][4]
    end
end

--// Visuals Implementation
local Visuals = {
    UpdateESP = function(Player, Data)
        local ESP = Data.ESP
        local Settings = Environment.Visuals.ESPSettings
        
        if not Settings.Enabled or not ShouldRenderPlayer(Player, Data) then
            ESP.Visible = false
            return
        end
        
        local Character = Player.Character
        local Head = Character:FindFirstChild("Head")
        if not Head then
            ESP.Visible = false
            return
        end
        
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
        if not OnScreen then
            ESP.Visible = false
            return
        end
        
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not Humanoid or not RootPart then
            ESP.Visible = false
            return
        end
        
        local Distance = mathfloor(GetDistanceFromLocal(RootPart.Position))
        local Tool = Character:FindFirstChildOfClass("Tool")
        local DisplayName = Player.DisplayName == Player.Name and Player.Name or Player.DisplayName.." {"..Player.Name.."}"
        
        -- Build text
        local TextParts = {}
        if Settings.DisplayName then
            table.insert(TextParts, DisplayName)
        end
        if Settings.DisplayHealth then
            table.insert(TextParts, "("..mathfloor(Humanoid.Health)..")")
        end
        if Settings.DisplayDistance then
            table.insert(TextParts, "["..Distance.."m]")
        end
        
        local Text = table.concat(TextParts, " ")
        if Tool then
            Text = "["..Tool.Name.."]\n"..Text
        end
        
        -- Update ESP
        ESP.Center = true
        ESP.Size = Settings.TextSize
        ESP.Outline = Settings.Outline
        ESP.OutlineColor = Settings.OutlineColor
        ESP.Color = Settings.TextColor
        ESP.Transparency = Settings.TextTransparency
        ESP.Font = Settings.TextFont
        ESP.Text = Text
        ESP.Position = Vector2new(ScreenPos.X, ScreenPos.Y - Settings.Offset - (Tool and 10 or 0))
        ESP.Visible = true
    end,
    
    UpdateTracer = function(Player, Data)
        local Tracer = Data.Tracer
        local Settings = Environment.Visuals.TracersSettings
        
        if not Settings.Enabled or not ShouldRenderPlayer(Player, Data) then
            Tracer.Visible = false
            return
        end
        
        local Character = Player.Character
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then
            Tracer.Visible = false
            return
        end
        
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
        if not OnScreen then
            Tracer.Visible = false
            return
        end
        
        -- Calculate tracer start position
        local StartPos
        if Settings.Type == 2 then
            StartPos = Vector2new(CachedViewportSize.X / 2, CachedViewportSize.Y / 2)
        elseif Settings.Type == 3 then
            StartPos = CachedMouseLocation
        else
            StartPos = Vector2new(CachedViewportSize.X / 2, CachedViewportSize.Y)
        end
        
        Tracer.Thickness = Settings.Thickness
        Tracer.Color = Settings.Color
        Tracer.Transparency = Settings.Transparency
        Tracer.From = StartPos
        Tracer.To = Vector2new(ScreenPos.X, ScreenPos.Y)
        Tracer.Visible = true
    end,
    
    UpdateBox = function(Player, Data)
        local Box = Data.Box
        local Settings = Environment.Visuals.BoxSettings
        
        if not Settings.Enabled or not ShouldRenderPlayer(Player, Data) then
            Box.Square.Visible = false
            Box.TopLeftLine.Visible = false
            Box.TopRightLine.Visible = false
            Box.BottomLeftLine.Visible = false
            Box.BottomRightLine.Visible = false
            return
        end
        
        local Character = Player.Character
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Head = Character:FindFirstChild("Head")
        
        if not RootPart or not Head then
            return
        end
        
        local RootPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
        if not OnScreen then
            return
        end
        
        if Settings.Type == 2 then
            -- 2D Box
            local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3new(0, 0.5, 0))
            local LegPos = Camera:WorldToViewportPoint(RootPart.Position - Vector3new(0, 2, 0))
            
            local Height = HeadPos.Y - LegPos.Y
            local Width = Height * 0.8
            
            Box.Square.Visible = true
            Box.Square.Thickness = Settings.Thickness
            Box.Square.Color = Settings.Color
            Box.Square.Transparency = Settings.Transparency
            Box.Square.Filled = Settings.Filled
            Box.Square.Size = Vector2new(Width, Height)
            Box.Square.Position = Vector2new(RootPos.X - Width/2, RootPos.Y - Height/2)
            
            -- Hide corner lines
            Box.TopLeftLine.Visible = false
            Box.TopRightLine.Visible = false
            Box.BottomLeftLine.Visible = false
            Box.BottomRightLine.Visible = false
        else
            -- 3D Corner Box
            Box.Square.Visible = false
            
            local Size = RootPart.Size * Settings.Increase
            local Offset = Size.Y / 2
            
            -- Calculate corners
            local function GetCorner(x, y, z)
                local OffsetPos = RootPart.CFrame * CFramenew(x * Size.X/2, y * Size.Y/2 - Offset, z * Size.Z/2)
                local Pos, Vis = Camera:WorldToViewportPoint(OffsetPos.Position)
                return Pos, Vis
            end
            
            local TL, _ = GetCorner(1, 1, -1)  -- Top Left
            local TR, _ = GetCorner(-1, 1, -1) -- Top Right
            local BL, _ = GetCorner(1, -1, -1) -- Bottom Left
            local BR, _ = GetCorner(-1, -1, -1) -- Bottom Right
            
            -- Update corner lines
            local function UpdateLine(Line, From, To)
                Line.Visible = true
                Line.Thickness = Settings.Thickness
                Line.Transparency = Settings.Transparency
                Line.Color = Settings.Color
                Line.From = Vector2new(From.X, From.Y)
                Line.To = Vector2new(To.X, To.Y)
            end
            
            UpdateLine(Box.TopLeftLine, TL, TR)
            UpdateLine(Box.TopRightLine, TR, BR)
            UpdateLine(Box.BottomLeftLine, BL, TL)
            UpdateLine(Box.BottomRightLine, BR, BL)
        end
    end,
    
    UpdateHeadDot = function(Player, Data)
        local HeadDot = Data.HeadDot
        local Settings = Environment.Visuals.HeadDotSettings
        
        if not Settings.Enabled or not ShouldRenderPlayer(Player, Data) then
            HeadDot.Visible = false
            return
        end
        
        local Character = Player.Character
        local Head = Character:FindFirstChild("Head")
        if not Head then
            HeadDot.Visible = false
            return
        end
        
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
        if not OnScreen then
            HeadDot.Visible = false
            return
        end
        
        HeadDot.Thickness = Settings.Thickness
        HeadDot.Color = Settings.Color
        HeadDot.Transparency = Settings.Transparency
        HeadDot.NumSides = Settings.Sides
        HeadDot.Filled = Settings.Filled
        HeadDot.Position = Vector2new(ScreenPos.X, ScreenPos.Y)
        HeadDot.Radius = 10
        HeadDot.Visible = true
    end,
    
    UpdateHealthBar = function(Player, Data)
        local HealthBar = Data.HealthBar
        local Settings = Environment.Visuals.HealthBarSettings
        
        if not Settings.Enabled or not ShouldRenderPlayer(Player, Data) then
            HealthBar.Main.Visible = false
            HealthBar.Outline.Visible = false
            return
        end
        
        local Character = Player.Character
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        
        if not Humanoid or not RootPart then
            return
        end
        
        local RootPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
        if not OnScreen then
            return
        end
        
        local HealthRatio = Humanoid.Health / Humanoid.MaxHealth
        local HealthColor = Color3fromRGB(
            mathfloor((1 - HealthRatio) * 255),
            mathfloor(HealthRatio * 255),
            Settings.Blue
        )
        
        -- Calculate positions based on type
        local MainPos, OutlineSize, MainSize
        
        if Settings.Type == 1 or Settings.Type == 2 then
            -- Horizontal bar
            OutlineSize = Vector2new(2000 / RootPos.Z, Settings.Size)
            MainSize = Vector2new(OutlineSize.X * HealthRatio, OutlineSize.Y)
            
            local YOffset = Settings.Type == 1 and -OutlineSize.X/2 - Settings.Offset or OutlineSize.X/2 + Settings.Offset
            MainPos = Vector2new(RootPos.X - OutlineSize.X/2, RootPos.Y + YOffset)
        else
            -- Vertical bar
            OutlineSize = Vector2new(Settings.Size, 2500 / RootPos.Z)
            MainSize = Vector2new(OutlineSize.X, OutlineSize.Y * HealthRatio)
            
            if Settings.Type == 3 then
                -- Left side
                local LeftPos, _ = Camera:WorldToViewportPoint((RootPart.CFrame * CFramenew(RootPart.Size.X, 0, 0)).Position)
                MainPos = Vector2new(LeftPos.X - Settings.Offset, RootPos.Y - OutlineSize.Y/2)
            else
                -- Right side
                local RightPos, _ = Camera:WorldToViewportPoint((RootPart.CFrame * CFramenew(-RootPart.Size.X, 0, 0)).Position)
                MainPos = Vector2new(RightPos.X + Settings.Offset, RootPos.Y - OutlineSize.Y/2)
            end
        end
        
        -- Update main bar
        HealthBar.Main.Visible = true
        HealthBar.Main.Thickness = 1
        HealthBar.Main.Color = HealthColor
        HealthBar.Main.Transparency = Settings.Transparency
        HealthBar.Main.Filled = true
        HealthBar.Main.Size = MainSize
        HealthBar.Main.Position = MainPos
        HealthBar.Main.ZIndex = 2
        
        -- Update outline
        HealthBar.Outline.Visible = true
        HealthBar.Outline.Thickness = 3
        HealthBar.Outline.Color = Settings.OutlineColor
        HealthBar.Outline.Transparency = Settings.Transparency
        HealthBar.Outline.Filled = false
        HealthBar.Outline.Size = OutlineSize
        HealthBar.Outline.Position = MainPos
        HealthBar.Outline.ZIndex = 1
    end,
    
    UpdateChams = function(Player, Data)
        local Settings = Environment.Visuals.ChamsSettings
        
        if not Settings.Enabled or not ShouldRenderPlayer(Player, Data) then
            for _, PartChams in next, Data.Chams do
                for i = 1, 6 do
                    PartChams["Quad"..i].Visible = false
                end
            end
            return
        end
        
        local Character = Player.Character
        for PartName, Quads in next, Data.Chams do
            local Part = Character:FindFirstChild(PartName)
            UpdateCham(Part, Quads, Settings.Color, Settings.Transparency, Settings.Thickness, Settings.Filled)
        end
    end,
    
    UpdateCrosshair = function()
        local Settings = Environment.Crosshair.Settings
        local Parts = Environment.Crosshair.Parts
        
        if not Settings.Enabled then
            Parts.LeftLine.Visible = false
            Parts.RightLine.Visible = false
            Parts.TopLine.Visible = false
            Parts.BottomLine.Visible = false
            Parts.CenterDot.Visible = false
            return
        end
        
        -- Get crosshair position
        local PosX, PosY
        if Settings.Type == 2 then
            PosX = CachedViewportSize.X / 2
            PosY = CachedViewportSize.Y / 2
        else
            PosX = CachedMouseLocation.X
            PosY = CachedMouseLocation.Y
        end
        
        local Rad = mathrad(Settings.Rotation)
        local CosR = mathcos(Rad)
        local SinR = mathsin(Rad)
        local Gap = Settings.GapSize
        local Size = Settings.Size
        
        -- Update lines
        local function UpdateLine(Line, FromX, FromY, ToX, ToY)
            Line.Visible = true
            Line.Color = Settings.Color
            Line.Thickness = Settings.Thickness
            Line.Transparency = Settings.Transparency
            Line.From = Vector2new(FromX, FromY)
            Line.To = Vector2new(ToX, ToY)
        end
        
        UpdateLine(Parts.LeftLine,
            PosX - CosR * Gap, PosY - SinR * Gap,
            PosX - CosR * (Size + Gap), PosY - SinR * (Size + Gap))
        
        UpdateLine(Parts.RightLine,
            PosX + CosR * Gap, PosY + SinR * Gap,
            PosX + CosR * (Size + Gap), PosY + SinR * (Size + Gap))
        
        UpdateLine(Parts.TopLine,
            PosX - SinR * Gap, PosY - CosR * Gap,
            PosX - SinR * (Size + Gap), PosY - CosR * (Size + Gap))
        
        UpdateLine(Parts.BottomLine,
            PosX + SinR * Gap, PosY + CosR * Gap,
            PosX + SinR * (Size + Gap), PosY + CosR * (Size + Gap))
        
        -- Update center dot
        Parts.CenterDot.Visible = Settings.CenterDot
        Parts.CenterDot.Color = Settings.CenterDotColor
        Parts.CenterDot.Radius = Settings.CenterDotSize
        Parts.CenterDot.Transparency = Settings.CenterDotTransparency
        Parts.CenterDot.Filled = Settings.CenterDotFilled
        Parts.CenterDot.Thickness = Settings.CenterDotThickness
        Parts.CenterDot.Position = Vector2new(PosX, PosY)
    end
}

--// Player Data Management
local function InitializePlayerData(Player)
    if Player == LocalPlayer or PlayerData[Player] then
        return
    end
    
    local Data = {
        Checks = {
            Alive = true,
            Team = true,
            Distance = true
        },
        Connections = {},
        ESP = Drawingnew("Text"),
        Tracer = Drawingnew("Line"),
        HeadDot = Drawingnew("Circle"),
        HealthBar = {
            Main = Drawingnew("Square"),
            Outline = Drawingnew("Square")
        },
        Box = {
            Square = Drawingnew("Square"),
            TopLeftLine = Drawingnew("Line"),
            TopRightLine = Drawingnew("Line"),
            BottomLeftLine = Drawingnew("Line"),
            BottomRightLine = Drawingnew("Line")
        },
        Chams = {}
    }
    
    -- Initialize chams based on rig type
    local function SetupChams()
        local Character = Player.Character
        if not Character then
            return false
        end
        
        local RigType = GetRigType(Character)
        if not RigType then
            return false
        end
        
        local Parts
        if RigType == "R15" then
            if Environment.Visuals.ChamsSettings.EntireBody then
                Parts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
                        "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg",
                        "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
            else
                Parts = {"Head", "UpperTorso", "LeftLowerArm", "LeftUpperArm", "RightLowerArm",
                        "RightUpperArm", "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg"}
            end
        else
            Parts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
        end
        
        for _, PartName in next, Parts do
            Data.Chams[PartName] = CreateChamQuads()
        end
        
        return true
    end
    
    -- Update checks every frame
    Data.Connections.UpdateChecks = RunService.RenderStepped:Connect(function()
        if not Environment.Settings.Enabled then
            Data.Checks.Alive = false
            Data.Checks.Team = false
            Data.Checks.Distance = false
            return
        end
        
        local Character = Player.Character
        if not Character then
            Data.Checks.Alive = false
            Data.Checks.Team = false
            Data.Checks.Distance = false
            return
        end
        
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        
        if not Humanoid or not RootPart then
            Data.Checks.Alive = false
            Data.Checks.Team = false
            Data.Checks.Distance = false
            return
        end
        
        Data.Checks.Alive = not Environment.Settings.AliveCheck or Humanoid.Health > 0
        Data.Checks.Team = not Environment.Settings.TeamCheck or Player.TeamColor ~= LocalPlayer.TeamColor
        Data.Checks.Distance = IsWithinDistance(RootPart.Position)
    end)
    
    -- Update visuals every frame
    Data.Connections.Visuals = RunService.RenderStepped:Connect(function()
        if not Environment.Settings.Enabled then
            return
        end
        
        Visuals.UpdateESP(Player, Data)
        Visuals.UpdateTracer(Player, Data)
        Visuals.UpdateBox(Player, Data)
        Visuals.UpdateHeadDot(Player, Data)
        Visuals.UpdateHealthBar(Player, Data)
        Visuals.UpdateChams(Player, Data)
    end)
    
    -- Setup chams when character loads
    local function OnCharacterAdded(Character)
        task.wait(0.5) -- Wait for character to load
        if SetupChams() then
            -- Update entire body setting if changed
            Data.Connections.ChamsRebuild = RunService.Heartbeat:Connect(function()
                local CurrentSetting = Environment.Visuals.ChamsSettings.EntireBody
                if Data.LastEntireBody ~= CurrentSetting then
                    Data.LastEntireBody = CurrentSetting
                    SetupChams()
                end
            end)
        end
    end
    
    if Player.Character then
        OnCharacterAdded(Player.Character)
    end
    
    Data.Connections.CharacterAdded = Player.CharacterAdded:Connect(OnCharacterAdded)
    
    PlayerData[Player] = Data
end

--// Crosshair Setup
local function SetupCrosshair()
    -- Update cache variables
    ServiceConnections.CacheUpdate = RunService.RenderStepped:Connect(function()
        CachedViewportSize = Camera.ViewportSize
        CachedMouseLocation = UserInputService:GetMouseLocation()
    end)
    
    -- Update crosshair
    ServiceConnections.Crosshair = RunService.RenderStepped:Connect(function()
        Visuals.UpdateCrosshair()
    end)
end

--// Main Load Function
local function Load()
    SetupCrosshair()
    
    -- Initialize existing players
    for _, Player in next, Players:GetPlayers() do
        if Player ~= LocalPlayer then
            InitializePlayerData(Player)
        end
    end
    
    -- Handle new players
    ServiceConnections.PlayerAdded = Players.PlayerAdded:Connect(function(Player)
        if Player ~= LocalPlayer then
            InitializePlayerData(Player)
        end
    end)
    
    -- Handle player removal
    ServiceConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(Player)
        CleanupPlayerData(Player)
    end)
    
    -- Cleanup local player if needed
    ServiceConnections.LocalPlayerRemoving = Players.PlayerRemoving:Connect(function(Player)
        if Player == LocalPlayer then
            -- Exit when local player leaves (game hop)
            Environment.Functions:Exit()
        end
    end)
end

--// Public Functions
function Environment.Functions:Exit()
    -- Clean up all player data
    for Player, _ in next, PlayerData do
        CleanupPlayerData(Player)
    end
    
    -- Disconnect all service connections
    for _, Connection in next, ServiceConnections do
        Connection:Disconnect()
    end
    
    -- Remove crosshair
    for _, Part in next, Environment.Crosshair.Parts do
        pcall(function() Part:Remove() end)
    end
    
    -- Clear environment
    Environment.Functions = nil
    getgenv().AirHub.WallHack = nil
end

function Environment.Functions:Restart()
    -- Clean up everything
    for Player, _ in next, PlayerData do
        CleanupPlayerData(Player)
    end
    
    for _, Connection in next, ServiceConnections do
        Connection:Disconnect()
    end
    
    -- Reload
    Load()
end

function Environment.Functions:ResetSettings()
    Environment.Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        MaxDistance = 1000
    }
    
    Environment.Visuals = {
        ChamsSettings = {
            Enabled = false,
            Color = Color3fromRGB(255, 255, 255),
            Transparency = 0.2,
            Thickness = 0,
            Filled = true,
            EntireBody = false
        },
        ESPSettings = {
            Enabled = true,
            TextColor = Color3fromRGB(255, 255, 255),
            TextSize = 14,
            Outline = true,
            OutlineColor = Color3fromRGB(0, 0, 0),
            TextTransparency = 0.7,
            TextFont = Drawing.Fonts.UI,
            Offset = 20,
            DisplayDistance = true,
            DisplayHealth = true,
            DisplayName = true
        },
        TracersSettings = {
            Enabled = true,
            Type = 1,
            Transparency = 0.7,
            Thickness = 1,
            Color = Color3fromRGB(255, 255, 255)
        },
        BoxSettings = {
            Enabled = true,
            Type = 1,
            Color = Color3fromRGB(255, 255, 255),
            Transparency = 0.7,
            Thickness = 1,
            Filled = false,
            Increase = 1
        },
        HeadDotSettings = {
            Enabled = true,
            Color = Color3fromRGB(255, 255, 255),
            Transparency = 0.5,
            Thickness = 1,
            Filled = false,
            Sides = 30
        },
        HealthBarSettings = {
            Enabled = false,
            Transparency = 0.8,
            Size = 2,
            Offset = 10,
            OutlineColor = Color3fromRGB(0, 0, 0),
            Blue = 50,
            Type = 3
        }
    }
    
    Environment.Crosshair.Settings = {
        Enabled = false,
        Type = 1,
        Size = 12,
        Thickness = 1,
        Color = Color3fromRGB(0, 255, 0),
        Transparency = 1,
        GapSize = 5,
        Rotation = 0,
        CenterDot = false,
        CenterDotColor = Color3fromRGB(0, 255, 0),
        CenterDotSize = 1,
        CenterDotTransparency = 1,
        CenterDotFilled = true,
        CenterDotThickness = 1
    }
end

--// Metatable protection
setmetatable(Environment.Functions, {
    __newindex = function()
        warn("Cannot modify WallHack functions table")
    end
})

--// Initialize
Load()
