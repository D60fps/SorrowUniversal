--// Cache

local tablefind, UserInputService = table.find, game:GetService("UserInputService")
local getgenv = getgenv or genv or (function() return getfenv(0) end)
local HttpService = game:GetService("HttpService")

--// Loaded check

if getgenv().AirHub or getgenv().AirHubV2Loaded then
    return
end

--// Environment

getgenv().AirHub = {}

--// Load Modules

local ok1, err1 = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Aimbot.lua"))()
end)
if not ok1 then warn("[AirHub] Aimbot module failed: " .. tostring(err1)) end

local ok2, err2 = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Wall_Hack.lua"))()
end)
if not ok2 then warn("[AirHub] WallHack module failed: " .. tostring(err2)) end

local Aimbot   = getgenv().AirHub.Aimbot
local WallHack = getgenv().AirHub.WallHack

if not Aimbot   then warn("[AirHub] Aimbot is nil - check module URL") return end
if not WallHack then warn("[AirHub] WallHack is nil - check module URL") return end

--// Load Rayfield

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Variables

local Parts       = {"Head","HumanoidRootPart","Torso","Left Arm","Right Arm","Left Leg","Right Leg","LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftUpperArm","RightUpperArm","LeftFoot","LeftLowerLeg","UpperTorso","LeftUpperLeg","RightFoot","RightLowerLeg","LowerTorso","RightUpperLeg"}
local TracersType = {"Bottom","Center","Mouse"}

-- ══════════════════════════════════════════════════
--  CONFIG SYSTEM
-- ══════════════════════════════════════════════════

local CONFIG_FOLDER = "AirHub"
local CONFIG_FILE   = CONFIG_FOLDER .. "/config.json"

local FS_SUPPORTED = (typeof(isfolder) == "function" and typeof(makefolder) == "function"
    and typeof(readfile) == "function" and typeof(writefile) == "function" and typeof(isfile) == "function")

local function EnsureFolder()
    if not FS_SUPPORTED then return end
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function SerialiseColor(c)
    return {r = c.R, g = c.G, b = c.B}
end

local function DeserialiseColor(t)
    if type(t) ~= "table" then return Color3.new(1,1,1) end
    return Color3.new(t.r or 1, t.g or 1, t.b or 1)
end

local function BuildSnapshot()
    local A  = Aimbot.Settings
    local AF = Aimbot.FOVSettings
    local SA = Aimbot.SilentAim
    local WS = WallHack.Settings
    local WE = WallHack.Visuals.ESPSettings
    local WB = WallHack.Visuals.BoxSettings
    local WC = WallHack.Visuals.ChamsSettings
    local WT = WallHack.Visuals.TracersSettings
    local WH = WallHack.Visuals.HeadDotSettings
    local WR = WallHack.Visuals.HealthBarSettings
    local XS = WallHack.Crosshair.Settings
    return {
        Aim_Enabled=A.Enabled, Aim_Toggle=A.Toggle, Aim_TriggerKey=A.TriggerKey,
        Aim_Sensitivity=A.Sensitivity, Aim_LockPart=A.LockPart, Aim_TeamCheck=A.TeamCheck,
        Aim_WallCheck=A.WallCheck, Aim_AliveCheck=A.AliveCheck, Aim_ThirdPerson=A.ThirdPerson,
        Aim_ThirdPersonSens=A.ThirdPersonSensitivity,
        SA_Enabled=SA.Enabled, SA_TeamCheck=SA.TeamCheck, SA_AliveCheck=SA.AliveCheck,
        SA_WallCheck=SA.WallCheck, SA_LockPart=SA.LockPart, SA_UseFOV=SA.UseFOV,
        SA_FOVAmount=SA.FOVAmount, SA_Prediction=SA.Prediction,
        FOV_Enabled=AF.Enabled, FOV_Visible=AF.Visible, FOV_Amount=AF.Amount,
        FOV_Filled=AF.Filled, FOV_Transparency=AF.Transparency, FOV_Sides=AF.Sides,
        FOV_Thickness=AF.Thickness, FOV_Color=SerialiseColor(AF.Color), FOV_LockedColor=SerialiseColor(AF.LockedColor),
        WH_Enabled=WS.Enabled, WH_TeamCheck=WS.TeamCheck, WH_AliveCheck=WS.AliveCheck, WH_MaxDistance=WS.MaxDistance,
        ESP_Enabled=WE.Enabled, ESP_TextSize=WE.TextSize, ESP_TextTransparency=WE.TextTransparency,
        ESP_DisplayDistance=WE.DisplayDistance, ESP_DisplayHealth=WE.DisplayHealth, ESP_DisplayName=WE.DisplayName,
        ESP_TextColor=SerialiseColor(WE.TextColor), ESP_OutlineColor=SerialiseColor(WE.OutlineColor),
        Box_Enabled=WB.Enabled, Box_Type=WB.Type, Box_Filled=WB.Filled, Box_Thickness=WB.Thickness,
        Box_Transparency=WB.Transparency, Box_Increase=WB.Increase, Box_Color=SerialiseColor(WB.Color),
        Chams_Enabled=WC.Enabled, Chams_Filled=WC.Filled, Chams_EntireBody=WC.EntireBody,
        Chams_Transparency=WC.Transparency, Chams_Thickness=WC.Thickness, Chams_Color=SerialiseColor(WC.Color),
        Tracer_Enabled=WT.Enabled, Tracer_Type=WT.Type, Tracer_Thickness=WT.Thickness,
        Tracer_Transparency=WT.Transparency, Tracer_Color=SerialiseColor(WT.Color),
        HD_Enabled=WH.Enabled, HD_Filled=WH.Filled, HD_Sides=WH.Sides, HD_Thickness=WH.Thickness,
        HD_Transparency=WH.Transparency, HD_Color=SerialiseColor(WH.Color),
        HB_Enabled=WR.Enabled, HB_Type=WR.Type, HB_Size=WR.Size, HB_Offset=WR.Offset,
        HB_Transparency=WR.Transparency, HB_OutlineColor=SerialiseColor(WR.OutlineColor),
        XH_Enabled=XS.Enabled, XH_Type=XS.Type, XH_Size=XS.Size, XH_Thickness=XS.Thickness,
        XH_GapSize=XS.GapSize, XH_Rotation=XS.Rotation, XH_Transparency=XS.Transparency,
        XH_Color=SerialiseColor(XS.Color), XH_CenterDot=XS.CenterDot, XH_CenterDotFilled=XS.CenterDotFilled,
        XH_CenterDotSize=XS.CenterDotSize, XH_CenterDotTransparency=XS.CenterDotTransparency,
        XH_CenterDotColor=SerialiseColor(XS.CenterDotColor),
    }
end

local function ApplySnapshot(S)
    local A  = Aimbot.Settings
    local AF = Aimbot.FOVSettings
    local SA = Aimbot.SilentAim
    local WS = WallHack.Settings
    local WE = WallHack.Visuals.ESPSettings
    local WB = WallHack.Visuals.BoxSettings
    local WC = WallHack.Visuals.ChamsSettings
    local WT = WallHack.Visuals.TracersSettings
    local WH = WallHack.Visuals.HeadDotSettings
    local WR = WallHack.Visuals.HealthBarSettings
    local XS = WallHack.Crosshair.Settings
    local function set(t,k,v) if v ~= nil then t[k]=v end end
    local function setC(t,k,v) if v ~= nil then t[k]=DeserialiseColor(v) end end
    set(A,"Enabled",S.Aim_Enabled) set(A,"Toggle",S.Aim_Toggle) set(A,"TriggerKey",S.Aim_TriggerKey)
    set(A,"Sensitivity",S.Aim_Sensitivity) set(A,"LockPart",S.Aim_LockPart) set(A,"TeamCheck",S.Aim_TeamCheck)
    set(A,"WallCheck",S.Aim_WallCheck) set(A,"AliveCheck",S.Aim_AliveCheck) set(A,"ThirdPerson",S.Aim_ThirdPerson)
    set(A,"ThirdPersonSensitivity",S.Aim_ThirdPersonSens)
    set(SA,"Enabled",S.SA_Enabled) set(SA,"TeamCheck",S.SA_TeamCheck) set(SA,"AliveCheck",S.SA_AliveCheck)
    set(SA,"WallCheck",S.SA_WallCheck) set(SA,"LockPart",S.SA_LockPart) set(SA,"UseFOV",S.SA_UseFOV)
    set(SA,"FOVAmount",S.SA_FOVAmount) set(SA,"Prediction",S.SA_Prediction)
    set(AF,"Enabled",S.FOV_Enabled) set(AF,"Visible",S.FOV_Visible) set(AF,"Amount",S.FOV_Amount)
    set(AF,"Filled",S.FOV_Filled) set(AF,"Transparency",S.FOV_Transparency) set(AF,"Sides",S.FOV_Sides)
    set(AF,"Thickness",S.FOV_Thickness) setC(AF,"Color",S.FOV_Color) setC(AF,"LockedColor",S.FOV_LockedColor)
    set(WS,"Enabled",S.WH_Enabled) set(WS,"TeamCheck",S.WH_TeamCheck) set(WS,"AliveCheck",S.WH_AliveCheck) set(WS,"MaxDistance",S.WH_MaxDistance)
    set(WE,"Enabled",S.ESP_Enabled) set(WE,"TextSize",S.ESP_TextSize) set(WE,"TextTransparency",S.ESP_TextTransparency)
    set(WE,"DisplayDistance",S.ESP_DisplayDistance) set(WE,"DisplayHealth",S.ESP_DisplayHealth) set(WE,"DisplayName",S.ESP_DisplayName)
    setC(WE,"TextColor",S.ESP_TextColor) setC(WE,"OutlineColor",S.ESP_OutlineColor)
    set(WB,"Enabled",S.Box_Enabled) set(WB,"Type",S.Box_Type) set(WB,"Filled",S.Box_Filled)
    set(WB,"Thickness",S.Box_Thickness) set(WB,"Transparency",S.Box_Transparency) set(WB,"Increase",S.Box_Increase) setC(WB,"Color",S.Box_Color)
    set(WC,"Enabled",S.Chams_Enabled) set(WC,"Filled",S.Chams_Filled) set(WC,"EntireBody",S.Chams_EntireBody)
    set(WC,"Transparency",S.Chams_Transparency) set(WC,"Thickness",S.Chams_Thickness) setC(WC,"Color",S.Chams_Color)
    set(WT,"Enabled",S.Tracer_Enabled) set(WT,"Type",S.Tracer_Type) set(WT,"Thickness",S.Tracer_Thickness)
    set(WT,"Transparency",S.Tracer_Transparency) setC(WT,"Color",S.Tracer_Color)
    set(WH,"Enabled",S.HD_Enabled) set(WH,"Filled",S.HD_Filled) set(WH,"Sides",S.HD_Sides)
    set(WH,"Thickness",S.HD_Thickness) set(WH,"Transparency",S.HD_Transparency) setC(WH,"Color",S.HD_Color)
    set(WR,"Enabled",S.HB_Enabled) set(WR,"Type",S.HB_Type) set(WR,"Size",S.HB_Size)
    set(WR,"Offset",S.HB_Offset) set(WR,"Transparency",S.HB_Transparency) setC(WR,"OutlineColor",S.HB_OutlineColor)
    set(XS,"Enabled",S.XH_Enabled) set(XS,"Type",S.XH_Type) set(XS,"Size",S.XH_Size)
    set(XS,"Thickness",S.XH_Thickness) set(XS,"GapSize",S.XH_GapSize) set(XS,"Rotation",S.XH_Rotation)
    set(XS,"Transparency",S.XH_Transparency) setC(XS,"Color",S.XH_Color) set(XS,"CenterDot",S.XH_CenterDot)
    set(XS,"CenterDotFilled",S.XH_CenterDotFilled) set(XS,"CenterDotSize",S.XH_CenterDotSize)
    set(XS,"CenterDotTransparency",S.XH_CenterDotTransparency) setC(XS,"CenterDotColor",S.XH_CenterDotColor)
end

local SaveConfig, LoadConfig

SaveConfig = function()
    if not FS_SUPPORTED then warn("[AirHub] Filesystem not supported") return end
    local ok, err = pcall(function()
        EnsureFolder()
        writefile(CONFIG_FILE, HttpService:JSONEncode(BuildSnapshot()))
    end)
    if not ok then warn("[AirHub] Save failed: " .. tostring(err)) end
end

LoadConfig = function()
    if not FS_SUPPORTED then return end
    local ok, err = pcall(function()
        if not isfile(CONFIG_FILE) then return end
        ApplySnapshot(HttpService:JSONDecode(readfile(CONFIG_FILE)))
    end)
    if not ok then warn("[AirHub] Load failed: " .. tostring(err)) end
end

task.defer(function()
    if FS_SUPPORTED and isfolder(CONFIG_FOLDER) and isfile(CONFIG_FILE) then
        LoadConfig()
    end
end)

--// Keybind

local BindingKey = false

local function StartBind()
    BindingKey = true
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if BindingKey then
            BindingKey = false
            local keyName = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
            Aimbot.Settings.TriggerKey = keyName
            conn:Disconnect()
        end
    end)
end

-- ══════════════════════════════════════════════════
--  RAYFIELD WINDOW
-- ══════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name               = "AirHub V3",
    LoadingTitle       = "AirHub V3",
    LoadingSubtitle    = "sorrow.cc",
    ConfigurationSaving = { Enabled = false },
    Discord            = { Enabled = false },
    KeySystem          = false
})

-- ══════════════════════════════════════════════════
--  TABS
-- ══════════════════════════════════════════════════

local AimbotTab    = Window:CreateTab("Aimbot",    "crosshair")
local VisualsTab   = Window:CreateTab("Visuals",   "eye")
local CrosshairTab = Window:CreateTab("Crosshair", "circle-dot")
local ConfigTab    = Window:CreateTab("Config",    "settings")

-- ══════════════════════════════════════════════════
--  AIMBOT
-- ══════════════════════════════════════════════════

local AimbotSection = AimbotTab:CreateSection("Aimbot")

AimbotTab:CreateToggle({
    Name         = "Enable Aimbot",
    CurrentValue = Aimbot.Settings.Enabled,
    Flag         = "AimEnabled",
    Callback     = function(v) Aimbot.Settings.Enabled = v end
})

AimbotTab:CreateToggle({
    Name         = "Toggle Mode",
    CurrentValue = Aimbot.Settings.Toggle,
    Flag         = "AimToggle",
    Callback     = function(v) Aimbot.Settings.Toggle = v end
})

AimbotTab:CreateSlider({
    Name         = "Smoothing",
    Range        = {0, 1},
    Increment    = 0.01,
    Suffix       = "",
    CurrentValue = Aimbot.Settings.Sensitivity,
    Flag         = "AimSmoothing",
    Callback     = function(v) Aimbot.Settings.Sensitivity = v end
})

AimbotTab:CreateButton({
    Name     = "Bind Key: " .. tostring(Aimbot.Settings.TriggerKey),
    Callback = function() StartBind() end
})

local TargetingSection = AimbotTab:CreateSection("Targeting")

AimbotTab:CreateDropdown({
    Name         = "Aim Part",
    Options      = Parts,
    CurrentOption = {"Head"},
    Flag         = "AimPart",
    Callback     = function(v) Aimbot.Settings.LockPart = v[1] or v end
})

AimbotTab:CreateToggle({
    Name         = "Team Check",
    CurrentValue = Aimbot.Settings.TeamCheck,
    Flag         = "AimTeamCheck",
    Callback     = function(v) Aimbot.Settings.TeamCheck = v end
})

AimbotTab:CreateToggle({
    Name         = "Wall Check",
    CurrentValue = Aimbot.Settings.WallCheck,
    Flag         = "AimWallCheck",
    Callback     = function(v) Aimbot.Settings.WallCheck = v end
})

AimbotTab:CreateToggle({
    Name         = "Alive Check",
    CurrentValue = Aimbot.Settings.AliveCheck,
    Flag         = "AimAliveCheck",
    Callback     = function(v) Aimbot.Settings.AliveCheck = v end
})

AimbotTab:CreateToggle({
    Name         = "Third Person",
    CurrentValue = Aimbot.Settings.ThirdPerson,
    Flag         = "AimThirdPerson",
    Callback     = function(v) Aimbot.Settings.ThirdPerson = v end
})

AimbotTab:CreateSlider({
    Name         = "3P Sensitivity",
    Range        = {1, 10},
    Increment    = 0.1,
    Suffix       = "x",
    CurrentValue = Aimbot.Settings.ThirdPersonSensitivity,
    Flag         = "Aim3PSens",
    Callback     = function(v) Aimbot.Settings.ThirdPersonSensitivity = v end
})

local SilentAimSection = AimbotTab:CreateSection("Silent Aim")

AimbotTab:CreateToggle({
    Name         = "Enable Silent Aim",
    CurrentValue = Aimbot.SilentAim.Enabled,
    Flag         = "SAEnabled",
    Callback     = function(v) Aimbot.SilentAim.Enabled = v end
})

AimbotTab:CreateDropdown({
    Name          = "SA Lock Part",
    Options       = Parts,
    CurrentOption = {"Head"},
    Flag          = "SALockPart",
    Callback      = function(v) Aimbot.SilentAim.LockPart = v[1] or v end
})

AimbotTab:CreateToggle({
    Name         = "SA Team Check",
    CurrentValue = Aimbot.SilentAim.TeamCheck,
    Flag         = "SATeamCheck",
    Callback     = function(v) Aimbot.SilentAim.TeamCheck = v end
})

AimbotTab:CreateToggle({
    Name         = "SA Alive Check",
    CurrentValue = Aimbot.SilentAim.AliveCheck,
    Flag         = "SAAliveCheck",
    Callback     = function(v) Aimbot.SilentAim.AliveCheck = v end
})

AimbotTab:CreateToggle({
    Name         = "SA Wall Check",
    CurrentValue = Aimbot.SilentAim.WallCheck,
    Flag         = "SAWallCheck",
    Callback     = function(v) Aimbot.SilentAim.WallCheck = v end
})

AimbotTab:CreateToggle({
    Name         = "Use FOV Limit",
    CurrentValue = Aimbot.SilentAim.UseFOV,
    Flag         = "SAUseFOV",
    Callback     = function(v) Aimbot.SilentAim.UseFOV = v end
})

AimbotTab:CreateSlider({
    Name         = "SA FOV Radius",
    Range        = {10, 500},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = Aimbot.SilentAim.FOVAmount,
    Flag         = "SAFOVAmount",
    Callback     = function(v) Aimbot.SilentAim.FOVAmount = v end
})

AimbotTab:CreateSlider({
    Name         = "Prediction",
    Range        = {0, 1},
    Increment    = 0.01,
    Suffix       = "",
    CurrentValue = Aimbot.SilentAim.Prediction,
    Flag         = "SAPrediction",
    Callback     = function(v) Aimbot.SilentAim.Prediction = v end
})

local FOVSection = AimbotTab:CreateSection("FOV Circle")

AimbotTab:CreateToggle({
    Name         = "Enable FOV",
    CurrentValue = Aimbot.FOVSettings.Enabled,
    Flag         = "FOVEnabled",
    Callback     = function(v) Aimbot.FOVSettings.Enabled = v end
})

AimbotTab:CreateToggle({
    Name         = "Visible",
    CurrentValue = Aimbot.FOVSettings.Visible,
    Flag         = "FOVVisible",
    Callback     = function(v) Aimbot.FOVSettings.Visible = v end
})

AimbotTab:CreateToggle({
    Name         = "Filled",
    CurrentValue = Aimbot.FOVSettings.Filled,
    Flag         = "FOVFilled",
    Callback     = function(v) Aimbot.FOVSettings.Filled = v end
})

AimbotTab:CreateSlider({
    Name         = "Radius",
    Range        = {10, 300},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = Aimbot.FOVSettings.Amount,
    Flag         = "FOVAmount",
    Callback     = function(v) Aimbot.FOVSettings.Amount = v end
})

AimbotTab:CreateSlider({
    Name         = "Transparency",
    Range        = {0, 1},
    Increment    = 0.05,
    Suffix       = "",
    CurrentValue = Aimbot.FOVSettings.Transparency,
    Flag         = "FOVTransparency",
    Callback     = function(v) Aimbot.FOVSettings.Transparency = v end
})

AimbotTab:CreateSlider({
    Name         = "Segments",
    Range        = {3, 100},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = Aimbot.FOVSettings.Sides,
    Flag         = "FOVSides",
    Callback     = function(v) Aimbot.FOVSettings.Sides = v end
})

AimbotTab:CreateSlider({
    Name         = "Thickness",
    Range        = {1, 5},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = Aimbot.FOVSettings.Thickness,
    Flag         = "FOVThickness",
    Callback     = function(v) Aimbot.FOVSettings.Thickness = v end
})

AimbotTab:CreateColorPicker({
    Name         = "FOV Color",
    Color        = Aimbot.FOVSettings.Color,
    Flag         = "FOVColor",
    Callback     = function(v) Aimbot.FOVSettings.Color = v end
})

AimbotTab:CreateColorPicker({
    Name         = "Locked Color",
    Color        = Aimbot.FOVSettings.LockedColor,
    Flag         = "FOVLockedColor",
    Callback     = function(v) Aimbot.FOVSettings.LockedColor = v end
})

-- ══════════════════════════════════════════════════
--  VISUALS
-- ══════════════════════════════════════════════════

local ESPSection = VisualsTab:CreateSection("ESP")

VisualsTab:CreateToggle({
    Name         = "Enable ESP",
    CurrentValue = WallHack.Settings.Enabled,
    Flag         = "ESPEnabled",
    Callback     = function(v) WallHack.Settings.Enabled = v end
})

VisualsTab:CreateToggle({
    Name         = "Team Check",
    CurrentValue = WallHack.Settings.TeamCheck,
    Flag         = "ESPTeamCheck",
    Callback     = function(v) WallHack.Settings.TeamCheck = v end
})

VisualsTab:CreateToggle({
    Name         = "Alive Check",
    CurrentValue = WallHack.Settings.AliveCheck,
    Flag         = "ESPAliveCheck",
    Callback     = function(v) WallHack.Settings.AliveCheck = v end
})

VisualsTab:CreateSlider({
    Name         = "Max Distance",
    Range        = {0, 5000},
    Increment    = 50,
    Suffix       = "studs",
    CurrentValue = WallHack.Settings.MaxDistance,
    Flag         = "ESPMaxDist",
    Callback     = function(v) WallHack.Settings.MaxDistance = v end
})

local NameTagSection = VisualsTab:CreateSection("Name / Health Tags")

VisualsTab:CreateToggle({
    Name         = "Enable Tags",
    CurrentValue = WallHack.Visuals.ESPSettings.Enabled,
    Flag         = "TagsEnabled",
    Callback     = function(v) WallHack.Visuals.ESPSettings.Enabled = v end
})

VisualsTab:CreateToggle({
    Name         = "Show Name",
    CurrentValue = WallHack.Visuals.ESPSettings.DisplayName,
    Flag         = "TagsName",
    Callback     = function(v) WallHack.Visuals.ESPSettings.DisplayName = v end
})

VisualsTab:CreateToggle({
    Name         = "Show Health",
    CurrentValue = WallHack.Visuals.ESPSettings.DisplayHealth,
    Flag         = "TagsHealth",
    Callback     = function(v) WallHack.Visuals.ESPSettings.DisplayHealth = v end
})

VisualsTab:CreateToggle({
    Name         = "Show Distance",
    CurrentValue = WallHack.Visuals.ESPSettings.DisplayDistance,
    Flag         = "TagsDist",
    Callback     = function(v) WallHack.Visuals.ESPSettings.DisplayDistance = v end
})

VisualsTab:CreateSlider({
    Name         = "Text Size",
    Range        = {8, 24},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Visuals.ESPSettings.TextSize,
    Flag         = "TagsTextSize",
    Callback     = function(v) WallHack.Visuals.ESPSettings.TextSize = v end
})

VisualsTab:CreateColorPicker({
    Name         = "Text Color",
    Color        = WallHack.Visuals.ESPSettings.TextColor,
    Flag         = "TagsTextColor",
    Callback     = function(v) WallHack.Visuals.ESPSettings.TextColor = v end
})

VisualsTab:CreateColorPicker({
    Name         = "Outline Color",
    Color        = WallHack.Visuals.ESPSettings.OutlineColor,
    Flag         = "TagsOutlineColor",
    Callback     = function(v) WallHack.Visuals.ESPSettings.OutlineColor = v end
})

local BoxSection = VisualsTab:CreateSection("Box ESP")

VisualsTab:CreateToggle({
    Name         = "Enable Boxes",
    CurrentValue = WallHack.Visuals.BoxSettings.Enabled,
    Flag         = "BoxEnabled",
    Callback     = function(v) WallHack.Visuals.BoxSettings.Enabled = v end
})

VisualsTab:CreateDropdown({
    Name          = "Box Type",
    Options       = {"3D", "2D"},
    CurrentOption = {WallHack.Visuals.BoxSettings.Type == 1 and "3D" or "2D"},
    Flag          = "BoxType",
    Callback      = function(v)
        local val = v[1] or v
        WallHack.Visuals.BoxSettings.Type = val == "3D" and 1 or 2
    end
})

VisualsTab:CreateToggle({
    Name         = "Filled",
    CurrentValue = WallHack.Visuals.BoxSettings.Filled,
    Flag         = "BoxFilled",
    Callback     = function(v) WallHack.Visuals.BoxSettings.Filled = v end
})

VisualsTab:CreateSlider({
    Name         = "Thickness",
    Range        = {1, 5},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Visuals.BoxSettings.Thickness,
    Flag         = "BoxThickness",
    Callback     = function(v) WallHack.Visuals.BoxSettings.Thickness = v end
})

VisualsTab:CreateSlider({
    Name         = "Transparency",
    Range        = {0, 1},
    Increment    = 0.05,
    Suffix       = "",
    CurrentValue = WallHack.Visuals.BoxSettings.Transparency,
    Flag         = "BoxTransparency",
    Callback     = function(v) WallHack.Visuals.BoxSettings.Transparency = v end
})

VisualsTab:CreateColorPicker({
    Name         = "Box Color",
    Color        = WallHack.Visuals.BoxSettings.Color,
    Flag         = "BoxColor",
    Callback     = function(v) WallHack.Visuals.BoxSettings.Color = v end
})

local ChamsSection = VisualsTab:CreateSection("Chams")

VisualsTab:CreateToggle({
    Name         = "Enable Chams",
    CurrentValue = WallHack.Visuals.ChamsSettings.Enabled,
    Flag         = "ChamsEnabled",
    Callback     = function(v) WallHack.Visuals.ChamsSettings.Enabled = v end
})

VisualsTab:CreateToggle({
    Name         = "Filled",
    CurrentValue = WallHack.Visuals.ChamsSettings.Filled,
    Flag         = "ChamsFilled",
    Callback     = function(v) WallHack.Visuals.ChamsSettings.Filled = v end
})

VisualsTab:CreateToggle({
    Name         = "Full Body (R15)",
    CurrentValue = WallHack.Visuals.ChamsSettings.EntireBody,
    Flag         = "ChamsFullBody",
    Callback     = function(v) WallHack.Visuals.ChamsSettings.EntireBody = v end
})

VisualsTab:CreateSlider({
    Name         = "Transparency",
    Range        = {0, 1},
    Increment    = 0.05,
    Suffix       = "",
    CurrentValue = WallHack.Visuals.ChamsSettings.Transparency,
    Flag         = "ChamsTransparency",
    Callback     = function(v) WallHack.Visuals.ChamsSettings.Transparency = v end
})

VisualsTab:CreateColorPicker({
    Name         = "Color",
    Color        = WallHack.Visuals.ChamsSettings.Color,
    Flag         = "ChamsColor",
    Callback     = function(v) WallHack.Visuals.ChamsSettings.Color = v end
})

local TracersSection = VisualsTab:CreateSection("Tracers")

VisualsTab:CreateToggle({
    Name         = "Enable Tracers",
    CurrentValue = WallHack.Visuals.TracersSettings.Enabled,
    Flag         = "TracersEnabled",
    Callback     = function(v) WallHack.Visuals.TracersSettings.Enabled = v end
})

VisualsTab:CreateDropdown({
    Name          = "Start Position",
    Options       = TracersType,
    CurrentOption = {TracersType[WallHack.Visuals.TracersSettings.Type]},
    Flag          = "TracersType",
    Callback      = function(v)
        local val = v[1] or v
        WallHack.Visuals.TracersSettings.Type = tablefind(TracersType, val)
    end
})

VisualsTab:CreateSlider({
    Name         = "Thickness",
    Range        = {1, 5},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Visuals.TracersSettings.Thickness,
    Flag         = "TracersThickness",
    Callback     = function(v) WallHack.Visuals.TracersSettings.Thickness = v end
})

VisualsTab:CreateColorPicker({
    Name         = "Color",
    Color        = WallHack.Visuals.TracersSettings.Color,
    Flag         = "TracersColor",
    Callback     = function(v) WallHack.Visuals.TracersSettings.Color = v end
})

local HeadDotSection = VisualsTab:CreateSection("Head Dots")

VisualsTab:CreateToggle({
    Name         = "Enable Head Dots",
    CurrentValue = WallHack.Visuals.HeadDotSettings.Enabled,
    Flag         = "HDEnabled",
    Callback     = function(v) WallHack.Visuals.HeadDotSettings.Enabled = v end
})

VisualsTab:CreateToggle({
    Name         = "Filled",
    CurrentValue = WallHack.Visuals.HeadDotSettings.Filled,
    Flag         = "HDFilled",
    Callback     = function(v) WallHack.Visuals.HeadDotSettings.Filled = v end
})

VisualsTab:CreateSlider({
    Name         = "Segments",
    Range        = {3, 60},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = WallHack.Visuals.HeadDotSettings.Sides,
    Flag         = "HDSides",
    Callback     = function(v) WallHack.Visuals.HeadDotSettings.Sides = v end
})

VisualsTab:CreateSlider({
    Name         = "Thickness",
    Range        = {1, 5},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Visuals.HeadDotSettings.Thickness,
    Flag         = "HDThickness",
    Callback     = function(v) WallHack.Visuals.HeadDotSettings.Thickness = v end
})

VisualsTab:CreateColorPicker({
    Name         = "Color",
    Color        = WallHack.Visuals.HeadDotSettings.Color,
    Flag         = "HDColor",
    Callback     = function(v) WallHack.Visuals.HeadDotSettings.Color = v end
})

local HealthBarSection = VisualsTab:CreateSection("Health Bars")

VisualsTab:CreateToggle({
    Name         = "Enable Health Bars",
    CurrentValue = WallHack.Visuals.HealthBarSettings.Enabled,
    Flag         = "HBEnabled",
    Callback     = function(v) WallHack.Visuals.HealthBarSettings.Enabled = v end
})

VisualsTab:CreateDropdown({
    Name          = "Position",
    Options       = {"Top","Bottom","Left","Right"},
    CurrentOption = {WallHack.Visuals.HealthBarSettings.Type == 1 and "Top"
                  or WallHack.Visuals.HealthBarSettings.Type == 2 and "Bottom"
                  or WallHack.Visuals.HealthBarSettings.Type == 3 and "Left" or "Right"},
    Flag          = "HBType",
    Callback      = function(v)
        local val = v[1] or v
        WallHack.Visuals.HealthBarSettings.Type = val=="Top" and 1 or val=="Bottom" and 2 or val=="Left" and 3 or 4
    end
})

VisualsTab:CreateSlider({
    Name         = "Width",
    Range        = {2, 10},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Visuals.HealthBarSettings.Size,
    Flag         = "HBSize",
    Callback     = function(v) WallHack.Visuals.HealthBarSettings.Size = v end
})

VisualsTab:CreateSlider({
    Name         = "Offset",
    Range        = {-30, 30},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Visuals.HealthBarSettings.Offset,
    Flag         = "HBOffset",
    Callback     = function(v) WallHack.Visuals.HealthBarSettings.Offset = v end
})

VisualsTab:CreateColorPicker({
    Name         = "Outline Color",
    Color        = WallHack.Visuals.HealthBarSettings.OutlineColor,
    Flag         = "HBOutlineColor",
    Callback     = function(v) WallHack.Visuals.HealthBarSettings.OutlineColor = v end
})

-- ══════════════════════════════════════════════════
--  CROSSHAIR
-- ══════════════════════════════════════════════════

local XhairSection = CrosshairTab:CreateSection("Crosshair")

CrosshairTab:CreateToggle({
    Name         = "System Cursor",
    CurrentValue = UserInputService.MouseIconEnabled,
    Flag         = "SysCursor",
    Callback     = function(v) UserInputService.MouseIconEnabled = v end
})

CrosshairTab:CreateToggle({
    Name         = "Custom Crosshair",
    CurrentValue = WallHack.Crosshair.Settings.Enabled,
    Flag         = "XhairEnabled",
    Callback     = function(v) WallHack.Crosshair.Settings.Enabled = v end
})

CrosshairTab:CreateDropdown({
    Name          = "Position",
    Options       = {"Mouse","Center"},
    CurrentOption = {WallHack.Crosshair.Settings.Type == 1 and "Mouse" or "Center"},
    Flag          = "XhairType",
    Callback      = function(v)
        local val = v[1] or v
        WallHack.Crosshair.Settings.Type = val == "Mouse" and 1 or 2
    end
})

CrosshairTab:CreateSlider({
    Name         = "Size",
    Range        = {4, 40},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Crosshair.Settings.Size,
    Flag         = "XhairSize",
    Callback     = function(v) WallHack.Crosshair.Settings.Size = v end
})

CrosshairTab:CreateSlider({
    Name         = "Thickness",
    Range        = {1, 5},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Crosshair.Settings.Thickness,
    Flag         = "XhairThickness",
    Callback     = function(v) WallHack.Crosshair.Settings.Thickness = v end
})

CrosshairTab:CreateSlider({
    Name         = "Gap",
    Range        = {0, 20},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Crosshair.Settings.GapSize,
    Flag         = "XhairGap",
    Callback     = function(v) WallHack.Crosshair.Settings.GapSize = v end
})

CrosshairTab:CreateSlider({
    Name         = "Rotation",
    Range        = {-180, 180},
    Increment    = 1,
    Suffix       = "°",
    CurrentValue = WallHack.Crosshair.Settings.Rotation,
    Flag         = "XhairRotation",
    Callback     = function(v) WallHack.Crosshair.Settings.Rotation = v end
})

CrosshairTab:CreateColorPicker({
    Name         = "Color",
    Color        = WallHack.Crosshair.Settings.Color,
    Flag         = "XhairColor",
    Callback     = function(v) WallHack.Crosshair.Settings.Color = v end
})

local DotSection = CrosshairTab:CreateSection("Center Dot")

CrosshairTab:CreateToggle({
    Name         = "Enable Dot",
    CurrentValue = WallHack.Crosshair.Settings.CenterDot,
    Flag         = "DotEnabled",
    Callback     = function(v) WallHack.Crosshair.Settings.CenterDot = v end
})

CrosshairTab:CreateToggle({
    Name         = "Filled",
    CurrentValue = WallHack.Crosshair.Settings.CenterDotFilled,
    Flag         = "DotFilled",
    Callback     = function(v) WallHack.Crosshair.Settings.CenterDotFilled = v end
})

CrosshairTab:CreateSlider({
    Name         = "Size",
    Range        = {1, 10},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = WallHack.Crosshair.Settings.CenterDotSize,
    Flag         = "DotSize",
    Callback     = function(v) WallHack.Crosshair.Settings.CenterDotSize = v end
})

CrosshairTab:CreateColorPicker({
    Name         = "Color",
    Color        = WallHack.Crosshair.Settings.CenterDotColor,
    Flag         = "DotColor",
    Callback     = function(v) WallHack.Crosshair.Settings.CenterDotColor = v end
})

-- ══════════════════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════════════════

local ConfigSection = ConfigTab:CreateSection("Save / Load")

local AutoSaveEnabled = false

task.spawn(function()
    while task.wait(5) do
        if AutoSaveEnabled then SaveConfig() end
    end
end)

ConfigTab:CreateToggle({
    Name         = "Auto-Save (every 5s)",
    CurrentValue = false,
    Flag         = "AutoSave",
    Callback     = function(v)
        AutoSaveEnabled = v
        if v then SaveConfig() end
    end
})

ConfigTab:CreateButton({
    Name     = "Save Config",
    Callback = function() SaveConfig() end
})

ConfigTab:CreateButton({
    Name     = "Load Config",
    Callback = function() LoadConfig() end
})

local ControlSection = ConfigTab:CreateSection("Controls")

ConfigTab:CreateButton({
    Name     = "Reset All Settings",
    Callback = function()
        Aimbot.Functions:ResetSettings()
        WallHack.Functions:ResetSettings()
    end
})

ConfigTab:CreateButton({
    Name     = "Restart Modules",
    Callback = function()
        Aimbot.Functions:Restart()
        WallHack.Functions:Restart()
    end
})

ConfigTab:CreateButton({
    Name     = "Unload",
    Callback = function()
        Rayfield:Destroy()
        Aimbot.Functions:Exit()
        WallHack.Functions:Exit()
        getgenv().AirHub = nil
    end
})
