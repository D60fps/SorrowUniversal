--// Cache

local next, tostring, pcall, getgenv, setmetatable = next, tostring, pcall, getgenv, setmetatable
local mathfloor, mathabs, mathcos, mathsin, mathrad = math.floor, math.abs, math.cos, math.sin, math.rad
local Vector2new, Vector3new, CFramenew, Drawingnew, Color3fromRGB = Vector2.new, Vector3.new, CFrame.new, Drawing.new, Color3.fromRGB

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

--// Helpers

local function GetDistance(TargetPos)
    local LP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not LP then return math.huge end
    return (TargetPos - LP.Position).Magnitude
end

local function W2V(pos)
    return Camera:WorldToViewportPoint(pos)
end

--// Environment

getgenv().AirHub.WallHack = {
    Settings = {
        Enabled     = false,
        TeamCheck   = false,
        AliveCheck  = true,
        MaxDistance = 1000
    },
    Visuals = {
        ChamsSettings = {
            Enabled=false, Color=Color3fromRGB(255,255,255), Transparency=0.2,
            Thickness=0, Filled=true, EntireBody=false
        },
        ESPSettings = {
            Enabled=true, TextColor=Color3fromRGB(255,255,255), TextSize=14,
            Outline=true, OutlineColor=Color3fromRGB(0,0,0), TextTransparency=0.7,
            TextFont=Drawing.Fonts.UI, Offset=20,
            DisplayDistance=true, DisplayHealth=true, DisplayName=true
        },
        TracersSettings = {
            Enabled=true, Type=1, Transparency=0.7, Thickness=1, Color=Color3fromRGB(255,255,255)
        },
        BoxSettings = {
            Enabled=true, Type=1, Color=Color3fromRGB(255,255,255),
            Transparency=0.7, Thickness=1, Filled=false, Increase=1
        },
        HeadDotSettings = {
            Enabled=true, Color=Color3fromRGB(255,255,255), Transparency=0.5,
            Thickness=1, Filled=false, Sides=30
        },
        HealthBarSettings = {
            Enabled=false, Transparency=0.8, Size=2, Offset=10,
            OutlineColor=Color3fromRGB(0,0,0), Blue=50, Type=3
        }
    },
    Crosshair = {
        Settings = {
            Enabled=false, Type=1, Size=12, Thickness=1,
            Color=Color3fromRGB(0,255,0), Transparency=1, GapSize=5, Rotation=0,
            CenterDot=false, CenterDotColor=Color3fromRGB(0,255,0), CenterDotSize=1,
            CenterDotTransparency=1, CenterDotFilled=true, CenterDotThickness=1
        },
        Parts = {
            LeftLine=Drawingnew("Line"), RightLine=Drawingnew("Line"),
            TopLine=Drawingnew("Line"),  BottomLine=Drawingnew("Line"),
            CenterDot=Drawingnew("Circle")
        }
    },
    WrappedPlayers = {}
}

local Environment = getgenv().AirHub.WallHack

-- ─────────────────────────────────────────────────────────────────────────
-- Rig / Chams  (ZERO YIELDS)
-- ─────────────────────────────────────────────────────────────────────────

local R15_SLIM = {"Head","UpperTorso","LeftLowerArm","LeftUpperArm","RightLowerArm","RightUpperArm","LeftLowerLeg","LeftUpperLeg","RightLowerLeg","RightUpperLeg"}
local R15_FULL = {"Head","UpperTorso","LowerTorso","LeftLowerArm","LeftUpperArm","LeftHand","RightLowerArm","RightUpperArm","RightHand","LeftLowerLeg","LeftUpperLeg","LeftFoot","RightLowerLeg","RightUpperLeg","RightFoot"}
local R6_PARTS = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}

local function DetectRig(char)
    if char and char:FindFirstChild("Torso") and not char:FindFirstChild("LowerTorso") then
        return "R6"
    end
    return "R15"
end

local function BuildChams(ct, rig, full)
    for _, c in next, ct do for i=1,6 do pcall(function() c["Quad"..i]:Remove() end) end end
    for k in next, ct do ct[k] = nil end
    local parts = rig=="R6" and R6_PARTS or (full and R15_FULL or R15_SLIM)
    for _, name in next, parts do
        ct[name] = {}
        for i=1,6 do ct[name]["Quad"..i] = Drawingnew("Quad") end
    end
end

local function HideQuads(ct)
    for _, c in next, ct do for i=1,6 do c["Quad"..i].Visible=false end end
end

local function UpdateCham(Part, Cham)
    local CS = Environment.Visuals.ChamsSettings
    local cf, sz = Part.CFrame, Part.Size/2
    local _, vis = W2V((cf*CFramenew(sz.X,sz.Y,sz.Z)).Position)
    if not (vis and CS.Enabled) then for i=1,6 do Cham["Quad"..i].Visible=false end return end
    local c = {
        W2V((cf*CFramenew( sz.X, sz.Y, sz.Z)).Position), W2V((cf*CFramenew(-sz.X, sz.Y, sz.Z)).Position),
        W2V((cf*CFramenew( sz.X,-sz.Y, sz.Z)).Position), W2V((cf*CFramenew(-sz.X,-sz.Y, sz.Z)).Position),
        W2V((cf*CFramenew( sz.X, sz.Y,-sz.Z)).Position), W2V((cf*CFramenew(-sz.X, sz.Y,-sz.Z)).Position),
        W2V((cf*CFramenew( sz.X,-sz.Y,-sz.Z)).Position), W2V((cf*CFramenew(-sz.X,-sz.Y,-sz.Z)).Position),
    }
    local v2=function(p) return Vector2new(p.X,p.Y) end
    local faces={{c[1],c[3],c[4],c[2]},{c[5],c[7],c[8],c[6]},{c[1],c[5],c[6],c[2]},{c[3],c[7],c[8],c[4]},{c[1],c[3],c[7],c[5]},{c[2],c[4],c[8],c[6]}}
    for i=1,6 do
        local q=Cham["Quad"..i]
        q.Transparency=CS.Transparency;q.Color=CS.Color;q.Thickness=CS.Thickness;q.Filled=CS.Filled;q.Visible=true
        q.PointA=v2(faces[i][1]);q.PointB=v2(faces[i][2]);q.PointC=v2(faces[i][3]);q.PointD=v2(faces[i][4])
    end
end

-- ─────────────────────────────────────────────────────────────────────────
-- GetPlayerTable
-- ─────────────────────────────────────────────────────────────────────────

local function GetPlayerTable(Player)
    for _, v in next, Environment.WrappedPlayers do
        if v.Name == Player.Name then return v end
    end
end

-- ─────────────────────────────────────────────────────────────────────────
-- Wrap  (zero yields, all drawings on Entry table)
-- ─────────────────────────────────────────────────────────────────────────

local function Wrap(Player)
    if GetPlayerTable(Player) then return end

    local D = {
        ESP=Drawingnew("Text"), Tracer=Drawingnew("Line"),
        HeadDot=Drawingnew("Circle"), HBMain=Drawingnew("Square"),
        HBOutline=Drawingnew("Square"), Box2D=Drawingnew("Square"),
    }
    for i=1,8 do D["C"..i]=Drawingnew("Line") end

    local Chams     = {}
    local rigType   = DetectRig(Player.Character)
    local oldEntire = Environment.Visuals.ChamsSettings.EntireBody
    BuildChams(Chams, rigType, oldEntire)

    local Entry = { Name=Player.Name, Connections={}, Drawings=D, Chams=Chams }
    Environment.WrappedPlayers[#Environment.WrappedPlayers+1] = Entry

    Entry.Connections.CharAdded = Player.CharacterAdded:Connect(function(char)
        task.defer(function()
            rigType   = DetectRig(char)
            oldEntire = Environment.Visuals.ChamsSettings.EntireBody
            BuildChams(Chams, rigType, oldEntire)
        end)
    end)

    local function HideAll()
        D.ESP.Visible=false;D.Tracer.Visible=false;D.HeadDot.Visible=false
        D.HBMain.Visible=false;D.HBOutline.Visible=false;D.Box2D.Visible=false
        for i=1,8 do D["C"..i].Visible=false end
        HideQuads(Chams)
    end

    Entry.Connections.Render = RunService.RenderStepped:Connect(function()
        local S    = Environment.Settings
        local char = Player.Character
        if not (S.Enabled and char) then HideAll(); return end

        local HRP  = char:FindFirstChild("HumanoidRootPart")
        local Head = char:FindFirstChild("Head")
        local Hum  = char:FindFirstChildOfClass("Humanoid")
        if not (HRP and Head and Hum)                              then HideAll(); return end
        if S.AliveCheck and Hum.Health <= 0                        then HideAll(); return end
        if S.TeamCheck  and Player.TeamColor==LocalPlayer.TeamColor then HideAll(); return end
        local maxD=S.MaxDistance
        if maxD>0 and GetDistance(HRP.Position)>maxD               then HideAll(); return end

        local hrpV,onScreen = W2V(HRP.Position)
        if not onScreen then HideAll(); return end

        local headV  = W2V(Head.Position+Vector3new(0,Head.Size.Y*0.5,0))
        local legsV  = W2V(HRP.Position -Vector3new(0,3,0))
        local boxW   = 2000/hrpV.Z
        local leftX  = hrpV.X-boxW*0.5
        local rightX = hrpV.X+boxW*0.5
        local topY   = headV.Y
        local botY   = legsV.Y
        local boxH   = mathabs(botY-topY)

        local newRig    = DetectRig(char)
        local newEntire = Environment.Visuals.ChamsSettings.EntireBody
        if newRig~=rigType or newEntire~=oldEntire then
            rigType=newRig;oldEntire=newEntire
            BuildChams(Chams,rigType,oldEntire)
        end

        -- ESP
        local ES=Environment.Visuals.ESPSettings
        if ES.Enabled then
            local dist=mathfloor(GetDistance(HRP.Position))
            local Tool=char:FindFirstChildOfClass("Tool")
            local nm=Player.DisplayName==Player.Name and Player.Name or Player.DisplayName.." {"..Player.Name.."}"
            local txt=""
            if ES.DisplayName     then txt=nm end
            if ES.DisplayHealth   then txt="("..mathfloor(Hum.Health)..")".. (txt~="" and " "..txt or "") end
            if ES.DisplayDistance then txt=txt.." ["..dist.."m]" end
            D.ESP.Text=(Tool and "["..Tool.Name.."]\n" or "")..txt
            D.ESP.Center=true;D.ESP.Size=ES.TextSize;D.ESP.Outline=ES.Outline
            D.ESP.OutlineColor=ES.OutlineColor;D.ESP.Color=ES.TextColor
            D.ESP.Transparency=ES.TextTransparency;D.ESP.Font=ES.TextFont
            D.ESP.Position=Vector2new(hrpV.X,topY-ES.Offset);D.ESP.Visible=true
        else D.ESP.Visible=false end

        -- Box
        local BS=Environment.Visuals.BoxSettings
        if BS.Enabled then
            if BS.Type==2 then
                for i=1,8 do D["C"..i].Visible=false end
                D.Box2D.Visible=true;D.Box2D.Thickness=BS.Thickness;D.Box2D.Color=BS.Color
                D.Box2D.Transparency=BS.Transparency;D.Box2D.Filled=BS.Filled
                D.Box2D.Size=Vector2new(boxW,boxH);D.Box2D.Position=Vector2new(leftX,topY)
            else
                D.Box2D.Visible=false
                local cw,ch=boxW*0.25,boxH*0.25
                local function L(i,x1,y1,x2,y2)
                    local l=D["C"..i];l.Visible=true;l.Color=BS.Color
                    l.Thickness=BS.Thickness;l.Transparency=BS.Transparency
                    l.From=Vector2new(x1,y1);l.To=Vector2new(x2,y2)
                end
                L(1,leftX, topY,leftX+cw,topY);  L(2,leftX, topY,leftX,    topY+ch)
                L(3,rightX,topY,rightX-cw,topY); L(4,rightX,topY,rightX,   topY+ch)
                L(5,leftX, botY,leftX+cw,botY);  L(6,leftX, botY,leftX,    botY-ch)
                L(7,rightX,botY,rightX-cw,botY); L(8,rightX,botY,rightX,   botY-ch)
            end
        else D.Box2D.Visible=false;for i=1,8 do D["C"..i].Visible=false end end

        -- Tracer
        local TS=Environment.Visuals.TracersSettings
        if TS.Enabled then
            D.Tracer.Thickness=TS.Thickness;D.Tracer.Color=TS.Color;D.Tracer.Transparency=TS.Transparency
            D.Tracer.To=Vector2new(hrpV.X,botY)
            if TS.Type==2 then D.Tracer.From=Vector2new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            elseif TS.Type==3 then local ml=UserInputService:GetMouseLocation();D.Tracer.From=Vector2new(ml.X,ml.Y)
            else D.Tracer.From=Vector2new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y) end
            D.Tracer.Visible=true
        else D.Tracer.Visible=false end

        -- Head Dot
        local HS=Environment.Visuals.HeadDotSettings
        if HS.Enabled then
            local hV=W2V(Head.Position)
            local hT=W2V((Head.CFrame*CFramenew(0, Head.Size.Y/2,0)).Position)
            local hB=W2V((Head.CFrame*CFramenew(0,-Head.Size.Y/2,0)).Position)
            D.HeadDot.Thickness=HS.Thickness;D.HeadDot.Color=HS.Color;D.HeadDot.Transparency=HS.Transparency
            D.HeadDot.NumSides=HS.Sides;D.HeadDot.Filled=HS.Filled
            D.HeadDot.Position=Vector2new(hV.X,hV.Y);D.HeadDot.Radius=mathabs((hT-hB).Y)-3
            D.HeadDot.Visible=true
        else D.HeadDot.Visible=false end

        -- Health Bar
        local HB=Environment.Visuals.HealthBarSettings
        if HB.Enabled then
            local ratio=math.clamp(Hum.Health/math.max(Hum.MaxHealth,1),0,1)
            local hpC=Color3fromRGB(mathfloor((1-ratio)*255),mathfloor(ratio*255),HB.Blue)
            D.HBMain.Thickness=1;D.HBMain.Color=hpC;D.HBMain.Transparency=HB.Transparency;D.HBMain.Filled=true;D.HBMain.ZIndex=2
            D.HBOutline.Thickness=3;D.HBOutline.Color=HB.OutlineColor;D.HBOutline.Transparency=HB.Transparency;D.HBOutline.Filled=false;D.HBOutline.ZIndex=1
            local lP=W2V((HRP.CFrame*CFramenew( HRP.Size.X,0,0)).Position)
            local rP=W2V((HRP.CFrame*CFramenew(-HRP.Size.X,0,0)).Position)
            if HB.Type==1 then
                D.HBOutline.Size=Vector2new(boxW,HB.Size);D.HBMain.Size=Vector2new(boxW*ratio,HB.Size)
                D.HBMain.Position=Vector2new(leftX,topY-HB.Offset-HB.Size)
            elseif HB.Type==2 then
                D.HBOutline.Size=Vector2new(boxW,HB.Size);D.HBMain.Size=Vector2new(boxW*ratio,HB.Size)
                D.HBMain.Position=Vector2new(leftX,botY+HB.Offset)
            elseif HB.Type==3 then
                D.HBOutline.Size=Vector2new(HB.Size,boxH);D.HBMain.Size=Vector2new(HB.Size,boxH*ratio)
                D.HBMain.Position=Vector2new(lP.X-HB.Offset-HB.Size,topY)
            else
                D.HBOutline.Size=Vector2new(HB.Size,boxH);D.HBMain.Size=Vector2new(HB.Size,boxH*ratio)
                D.HBMain.Position=Vector2new(rP.X+HB.Offset,topY)
            end
            D.HBOutline.Position=D.HBMain.Position;D.HBMain.Visible=true;D.HBOutline.Visible=true
        else D.HBMain.Visible=false;D.HBOutline.Visible=false end

        -- Chams
        local CS=Environment.Visuals.ChamsSettings
        if CS.Enabled then
            for partName,cham in next,Chams do
                local part=char:FindFirstChild(partName)
                if part then UpdateCham(part,cham) end
            end
        else HideQuads(Chams) end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────
-- UnWrap
-- ─────────────────────────────────────────────────────────────────────────

local function UnWrap(Player)
    local Table,Index=nil,nil
    for i,v in next,Environment.WrappedPlayers do
        if v.Name==Player.Name then Table,Index=v,i end
    end
    if not Table then return end
    for _,conn in next,Table.Connections do pcall(function() conn:Disconnect() end) end
    if Table.Drawings then
        for _,d in next,Table.Drawings do pcall(function() d:Remove() end) end
    end
    if Table.Chams then
        for _,cham in next,Table.Chams do
            for i=1,6 do pcall(function() cham["Quad"..i]:Remove() end) end
        end
    end
    Environment.WrappedPlayers[Index]=nil
end

-- ─────────────────────────────────────────────────────────────────────────
-- Crosshair
-- ─────────────────────────────────────────────────────────────────────────

local function AddCrosshair()
    local CS=Environment.Crosshair.Settings
    local CP=Environment.Crosshair.Parts
    ServiceConnections.CrosshairConnection=RunService.RenderStepped:Connect(function()
        if not CS.Enabled then
            CP.LeftLine.Visible=false;CP.RightLine.Visible=false
            CP.TopLine.Visible=false;CP.BottomLine.Visible=false;CP.CenterDot.Visible=false
            return
        end
        local ax,ay
        if CS.Type==2 then ax,ay=Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2
        else local ml=UserInputService:GetMouseLocation();ax,ay=ml.X,ml.Y end
        local rot,gap,sz=CS.Rotation,CS.GapSize,CS.Size
        local cosR,sinR=mathcos(mathrad(rot)),mathsin(mathrad(rot))
        local function applyLine(line,x1,y1,x2,y2)
            line.Visible=true;line.Color=CS.Color;line.Thickness=CS.Thickness;line.Transparency=CS.Transparency
            line.From=Vector2new(x1,y1);line.To=Vector2new(x2,y2)
        end
        applyLine(CP.LeftLine,  ax-cosR*gap,ay-sinR*gap,ax-cosR*(sz+gap),ay-sinR*(sz+gap))
        applyLine(CP.RightLine, ax+cosR*gap,ay+sinR*gap,ax+cosR*(sz+gap),ay+sinR*(sz+gap))
        applyLine(CP.TopLine,   ax-sinR*gap,ay-cosR*gap,ax-sinR*(sz+gap),ay-cosR*(sz+gap))
        applyLine(CP.BottomLine,ax+sinR*gap,ay+cosR*gap,ax+sinR*(sz+gap),ay+cosR*(sz+gap))
        CP.CenterDot.Visible=CS.CenterDot;CP.CenterDot.Color=CS.CenterDotColor
        CP.CenterDot.Radius=CS.CenterDotSize;CP.CenterDot.Transparency=CS.CenterDotTransparency
        CP.CenterDot.Filled=CS.CenterDotFilled;CP.CenterDot.Thickness=CS.CenterDotThickness
        CP.CenterDot.Position=Vector2new(ax,ay)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────
-- Load
-- ─────────────────────────────────────────────────────────────────────────

local function Load()
    AddCrosshair()
    for _,v in next,Players:GetPlayers() do if v~=LocalPlayer then Wrap(v) end end
    ServiceConnections.PlayerAdded    = Players.PlayerAdded:Connect(function(p) Wrap(p) end)
    ServiceConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(p) UnWrap(p) end)
    local lastRewrap=0
    ServiceConnections.ReWrap=RunService.Heartbeat:Connect(function()
        local now=tick()
        if now-lastRewrap<30 then return end
        lastRewrap=now
        for _,v in next,Players:GetPlayers() do if v~=LocalPlayer then Wrap(v) end end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────
-- Functions
-- ─────────────────────────────────────────────────────────────────────────

Environment.Functions={}

function Environment.Functions:Exit()
    for _,v in next,ServiceConnections do pcall(function() v:Disconnect() end) end
    for _,v in next,Environment.Crosshair.Parts do pcall(function() v:Remove() end) end
    for _,v in next,Players:GetPlayers() do if v~=LocalPlayer then UnWrap(v) end end
    getgenv().AirHub.WallHack.Functions=nil
    getgenv().AirHub.WallHack=nil
end

function Environment.Functions:Restart()
    for _,v in next,Players:GetPlayers() do if v~=LocalPlayer then UnWrap(v) end end
    for _,v in next,ServiceConnections do pcall(function() v:Disconnect() end) end
    for k in next,ServiceConnections do ServiceConnections[k]=nil end
    Load()
end

function Environment.Functions:ResetSettings()
    Environment.Settings={Enabled=false,TeamCheck=false,AliveCheck=true,MaxDistance=1000}
    Environment.Visuals={
        ChamsSettings={Enabled=false,Color=Color3fromRGB(255,255,255),Transparency=0.2,Thickness=0,Filled=true,EntireBody=false},
        ESPSettings={Enabled=true,TextColor=Color3fromRGB(255,255,255),TextSize=14,Outline=true,OutlineColor=Color3fromRGB(0,0,0),TextTransparency=0.7,TextFont=Drawing.Fonts.UI,Offset=20,DisplayDistance=true,DisplayHealth=true,DisplayName=true},
        TracersSettings={Enabled=true,Type=1,Transparency=0.7,Thickness=1,Color=Color3fromRGB(255,255,255)},
        BoxSettings={Enabled=true,Type=1,Color=Color3fromRGB(255,255,255),Transparency=0.7,Thickness=1,Filled=false,Increase=1},
        HeadDotSettings={Enabled=true,Color=Color3fromRGB(255,255,255),Transparency=0.5,Thickness=1,Filled=false,Sides=30},
        HealthBarSettings={Enabled=false,Transparency=0.8,Size=2,Offset=10,OutlineColor=Color3fromRGB(0,0,0),Blue=50,Type=3}
    }
    Environment.Crosshair.Settings={
        Enabled=false,Type=1,Size=12,Thickness=1,Color=Color3fromRGB(0,255,0),Transparency=1,GapSize=5,
        Rotation=0,CenterDot=false,CenterDotColor=Color3fromRGB(0,255,0),CenterDotSize=1,
        CenterDotTransparency=1,CenterDotFilled=true,CenterDotThickness=1
    }
end

setmetatable(Environment.Functions,{__newindex=warn})

Load()
