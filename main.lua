--// Cache

local loadstring, setclipboard, tablefind, UserInputService = loadstring, setclipboard, table.find, game:GetService("UserInputService")
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

--// Load Orion Library

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

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

local function StartBind(callback)
    BindingKey = true
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if BindingKey then
            BindingKey = false
            local keyName = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
            Aimbot.Settings.TriggerKey = keyName
            if callback then callback(keyName) end
            conn:Disconnect()
        end
    end)
end

-- ══════════════════════════════════════════════════
--  ORION WINDOW
-- ══════════════════════════════════════════════════

local Window = OrionLib:MakeWindow({
    Name            = "SORROW  ·  AIRHUB  ·  V3",
    HidePremium     = false,
    SaveConfig      = false,
    ConfigFileName  = "AirHub",
    IntroEnabled    = true,
    IntroText       = "AIRHUB V3",
    CloseCallback   = function()
        Aimbot.Functions:Exit()
        WallHack.Functions:Exit()
        getgenv().AirHub = nil
    end
})

-- ══════════════════════════════════════════════════
--  TABS
-- ══════════════════════════════════════════════════

local AimbotTab    = Window:MakeTab({ Name = "Aimbot",    Icon = "rbxassetid://4483345998", PremiumOnly = false })
local VisualsTab   = Window:MakeTab({ Name = "Visuals",   Icon = "rbxassetid://4483345998", PremiumOnly = false })
local CrosshairTab = Window:MakeTab({ Name = "Crosshair", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local ConfigTab    = Window:MakeTab({ Name = "Config",    Icon = "rbxassetid://4483345998", PremiumOnly = false })

-- ══════════════════════════════════════════════════
--  AIMBOT TAB
-- ══════════════════════════════════════════════════

local AimbotSection = AimbotTab:AddSection({ Name = "Aimbot" })

AimbotSection:AddToggle({
    Name     = "Enable Aimbot",
    Default  = Aimbot.Settings.Enabled,
    Callback = function(v) Aimbot.Settings.Enabled = v end
})

AimbotSection:AddToggle({
    Name     = "Toggle Mode",
    Default  = Aimbot.Settings.Toggle,
    Callback = function(v) Aimbot.Settings.Toggle = v end
})

AimbotSection:AddSlider({
    Name      = "Smoothing",
    Min       = 0,
    Max       = 1,
    Default   = Aimbot.Settings.Sensitivity,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.01,
    Callback  = function(v) Aimbot.Settings.Sensitivity = v end
})

AimbotSection:AddButton({
    Name     = "Bind Key: " .. tostring(Aimbot.Settings.TriggerKey),
    Callback = function() StartBind() end
})

local TargetingSection = AimbotTab:AddSection({ Name = "Targeting" })

TargetingSection:AddDropdown({
    Name     = "Aim Part",
    Default  = 1,
    Options  = Parts,
    Callback = function(v) Aimbot.Settings.LockPart = v end
})

TargetingSection:AddToggle({
    Name     = "Team Check",
    Default  = Aimbot.Settings.TeamCheck,
    Callback = function(v) Aimbot.Settings.TeamCheck = v end
})

TargetingSection:AddToggle({
    Name     = "Wall Check",
    Default  = Aimbot.Settings.WallCheck,
    Callback = function(v) Aimbot.Settings.WallCheck = v end
})

TargetingSection:AddToggle({
    Name     = "Alive Check",
    Default  = Aimbot.Settings.AliveCheck,
    Callback = function(v) Aimbot.Settings.AliveCheck = v end
})

TargetingSection:AddToggle({
    Name     = "Third Person",
    Default  = Aimbot.Settings.ThirdPerson,
    Callback = function(v) Aimbot.Settings.ThirdPerson = v end
})

TargetingSection:AddSlider({
    Name      = "3P Sensitivity",
    Min       = 1,
    Max       = 10,
    Default   = Aimbot.Settings.ThirdPersonSensitivity,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.1,
    Callback  = function(v) Aimbot.Settings.ThirdPersonSensitivity = v end
})

local SilentAimSection = AimbotTab:AddSection({ Name = "Silent Aim" })

SilentAimSection:AddToggle({
    Name     = "Enable Silent Aim",
    Default  = Aimbot.SilentAim.Enabled,
    Callback = function(v) Aimbot.SilentAim.Enabled = v end
})

SilentAimSection:AddDropdown({
    Name     = "Lock Part",
    Default  = 1,
    Options  = Parts,
    Callback = function(v) Aimbot.SilentAim.LockPart = v end
})

SilentAimSection:AddToggle({
    Name     = "Team Check",
    Default  = Aimbot.SilentAim.TeamCheck,
    Callback = function(v) Aimbot.SilentAim.TeamCheck = v end
})

SilentAimSection:AddToggle({
    Name     = "Alive Check",
    Default  = Aimbot.SilentAim.AliveCheck,
    Callback = function(v) Aimbot.SilentAim.AliveCheck = v end
})

SilentAimSection:AddToggle({
    Name     = "Wall Check",
    Default  = Aimbot.SilentAim.WallCheck,
    Callback = function(v) Aimbot.SilentAim.WallCheck = v end
})

SilentAimSection:AddToggle({
    Name     = "Use FOV Limit",
    Default  = Aimbot.SilentAim.UseFOV,
    Callback = function(v) Aimbot.SilentAim.UseFOV = v end
})

SilentAimSection:AddSlider({
    Name      = "FOV Radius",
    Min       = 10,
    Max       = 500,
    Default   = Aimbot.SilentAim.FOVAmount,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) Aimbot.SilentAim.FOVAmount = v end
})

SilentAimSection:AddSlider({
    Name      = "Prediction",
    Min       = 0,
    Max       = 1,
    Default   = Aimbot.SilentAim.Prediction,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.01,
    Callback  = function(v) Aimbot.SilentAim.Prediction = v end
})

local FOVSection = AimbotTab:AddSection({ Name = "FOV Circle" })

FOVSection:AddToggle({
    Name     = "Enable FOV",
    Default  = Aimbot.FOVSettings.Enabled,
    Callback = function(v) Aimbot.FOVSettings.Enabled = v end
})

FOVSection:AddToggle({
    Name     = "Visible",
    Default  = Aimbot.FOVSettings.Visible,
    Callback = function(v) Aimbot.FOVSettings.Visible = v end
})

FOVSection:AddToggle({
    Name     = "Filled",
    Default  = Aimbot.FOVSettings.Filled,
    Callback = function(v) Aimbot.FOVSettings.Filled = v end
})

FOVSection:AddSlider({
    Name      = "Radius",
    Min       = 10,
    Max       = 300,
    Default   = Aimbot.FOVSettings.Amount,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) Aimbot.FOVSettings.Amount = v end
})

FOVSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = Aimbot.FOVSettings.Transparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) Aimbot.FOVSettings.Transparency = v end
})

FOVSection:AddSlider({
    Name      = "Segments",
    Min       = 3,
    Max       = 100,
    Default   = Aimbot.FOVSettings.Sides,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) Aimbot.FOVSettings.Sides = v end
})

FOVSection:AddSlider({
    Name      = "Thickness",
    Min       = 1,
    Max       = 5,
    Default   = Aimbot.FOVSettings.Thickness,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) Aimbot.FOVSettings.Thickness = v end
})

FOVSection:AddColorpicker({
    Name     = "Color",
    Default  = Aimbot.FOVSettings.Color,
    Callback = function(v) Aimbot.FOVSettings.Color = v end
})

FOVSection:AddColorpicker({
    Name     = "Locked Color",
    Default  = Aimbot.FOVSettings.LockedColor,
    Callback = function(v) Aimbot.FOVSettings.LockedColor = v end
})

-- ══════════════════════════════════════════════════
--  VISUALS TAB
-- ══════════════════════════════════════════════════

local ESPSection = VisualsTab:AddSection({ Name = "ESP" })

ESPSection:AddToggle({
    Name     = "Enable ESP",
    Default  = WallHack.Settings.Enabled,
    Callback = function(v) WallHack.Settings.Enabled = v end
})

ESPSection:AddToggle({
    Name     = "Team Check",
    Default  = WallHack.Settings.TeamCheck,
    Callback = function(v) WallHack.Settings.TeamCheck = v end
})

ESPSection:AddToggle({
    Name     = "Alive Check",
    Default  = WallHack.Settings.AliveCheck,
    Callback = function(v) WallHack.Settings.AliveCheck = v end
})

ESPSection:AddSlider({
    Name      = "Max Distance",
    Min       = 0,
    Max       = 5000,
    Default   = WallHack.Settings.MaxDistance,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 50,
    Callback  = function(v) WallHack.Settings.MaxDistance = v end
})

local NameTagSection = VisualsTab:AddSection({ Name = "Name / Health Tags" })

NameTagSection:AddToggle({
    Name     = "Enable Tags",
    Default  = WallHack.Visuals.ESPSettings.Enabled,
    Callback = function(v) WallHack.Visuals.ESPSettings.Enabled = v end
})

NameTagSection:AddToggle({
    Name     = "Show Name",
    Default  = WallHack.Visuals.ESPSettings.DisplayName,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayName = v end
})

NameTagSection:AddToggle({
    Name     = "Show Health",
    Default  = WallHack.Visuals.ESPSettings.DisplayHealth,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayHealth = v end
})

NameTagSection:AddToggle({
    Name     = "Show Distance",
    Default  = WallHack.Visuals.ESPSettings.DisplayDistance,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayDistance = v end
})

NameTagSection:AddSlider({
    Name      = "Text Size",
    Min       = 8,
    Max       = 24,
    Default   = WallHack.Visuals.ESPSettings.TextSize,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.ESPSettings.TextSize = v end
})

NameTagSection:AddSlider({
    Name      = "Text Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Visuals.ESPSettings.TextTransparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Visuals.ESPSettings.TextTransparency = v end
})

NameTagSection:AddColorpicker({
    Name     = "Text Color",
    Default  = WallHack.Visuals.ESPSettings.TextColor,
    Callback = function(v) WallHack.Visuals.ESPSettings.TextColor = v end
})

NameTagSection:AddColorpicker({
    Name     = "Outline Color",
    Default  = WallHack.Visuals.ESPSettings.OutlineColor,
    Callback = function(v) WallHack.Visuals.ESPSettings.OutlineColor = v end
})

local BoxSection = VisualsTab:AddSection({ Name = "Box ESP" })

BoxSection:AddToggle({
    Name     = "Enable Boxes",
    Default  = WallHack.Visuals.BoxSettings.Enabled,
    Callback = function(v) WallHack.Visuals.BoxSettings.Enabled = v end
})

BoxSection:AddDropdown({
    Name     = "Box Type",
    Default  = WallHack.Visuals.BoxSettings.Type == 1 and "3D" or "2D",
    Options  = {"3D","2D"},
    Callback = function(v) WallHack.Visuals.BoxSettings.Type = v == "3D" and 1 or 2 end
})

BoxSection:AddToggle({
    Name     = "Filled",
    Default  = WallHack.Visuals.BoxSettings.Filled,
    Callback = function(v) WallHack.Visuals.BoxSettings.Filled = v end
})

BoxSection:AddSlider({
    Name      = "Thickness",
    Min       = 1,
    Max       = 5,
    Default   = WallHack.Visuals.BoxSettings.Thickness,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.BoxSettings.Thickness = v end
})

BoxSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Visuals.BoxSettings.Transparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Visuals.BoxSettings.Transparency = v end
})

BoxSection:AddSlider({
    Name      = "Scale",
    Min       = 1,
    Max       = 5,
    Default   = WallHack.Visuals.BoxSettings.Increase,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.1,
    Callback  = function(v) WallHack.Visuals.BoxSettings.Increase = v end
})

BoxSection:AddColorpicker({
    Name     = "Color",
    Default  = WallHack.Visuals.BoxSettings.Color,
    Callback = function(v) WallHack.Visuals.BoxSettings.Color = v end
})

local ChamsSection = VisualsTab:AddSection({ Name = "Chams" })

ChamsSection:AddToggle({
    Name     = "Enable Chams",
    Default  = WallHack.Visuals.ChamsSettings.Enabled,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Enabled = v end
})

ChamsSection:AddToggle({
    Name     = "Filled",
    Default  = WallHack.Visuals.ChamsSettings.Filled,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Filled = v end
})

ChamsSection:AddToggle({
    Name     = "Full Body (R15)",
    Default  = WallHack.Visuals.ChamsSettings.EntireBody,
    Callback = function(v) WallHack.Visuals.ChamsSettings.EntireBody = v end
})

ChamsSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Visuals.ChamsSettings.Transparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Visuals.ChamsSettings.Transparency = v end
})

ChamsSection:AddSlider({
    Name      = "Outline Width",
    Min       = 0,
    Max       = 3,
    Default   = WallHack.Visuals.ChamsSettings.Thickness,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.ChamsSettings.Thickness = v end
})

ChamsSection:AddColorpicker({
    Name     = "Color",
    Default  = WallHack.Visuals.ChamsSettings.Color,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Color = v end
})

local TracersSection = VisualsTab:AddSection({ Name = "Tracers" })

TracersSection:AddToggle({
    Name     = "Enable Tracers",
    Default  = WallHack.Visuals.TracersSettings.Enabled,
    Callback = function(v) WallHack.Visuals.TracersSettings.Enabled = v end
})

TracersSection:AddDropdown({
    Name     = "Start Position",
    Default  = TracersType[WallHack.Visuals.TracersSettings.Type],
    Options  = TracersType,
    Callback = function(v) WallHack.Visuals.TracersSettings.Type = tablefind(TracersType, v) end
})

TracersSection:AddSlider({
    Name      = "Thickness",
    Min       = 1,
    Max       = 5,
    Default   = WallHack.Visuals.TracersSettings.Thickness,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.TracersSettings.Thickness = v end
})

TracersSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Visuals.TracersSettings.Transparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Visuals.TracersSettings.Transparency = v end
})

TracersSection:AddColorpicker({
    Name     = "Color",
    Default  = WallHack.Visuals.TracersSettings.Color,
    Callback = function(v) WallHack.Visuals.TracersSettings.Color = v end
})

local HeadDotSection = VisualsTab:AddSection({ Name = "Head Dots" })

HeadDotSection:AddToggle({
    Name     = "Enable Head Dots",
    Default  = WallHack.Visuals.HeadDotSettings.Enabled,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Enabled = v end
})

HeadDotSection:AddToggle({
    Name     = "Filled",
    Default  = WallHack.Visuals.HeadDotSettings.Filled,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Filled = v end
})

HeadDotSection:AddSlider({
    Name      = "Segments",
    Min       = 3,
    Max       = 60,
    Default   = WallHack.Visuals.HeadDotSettings.Sides,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.HeadDotSettings.Sides = v end
})

HeadDotSection:AddSlider({
    Name      = "Thickness",
    Min       = 1,
    Max       = 5,
    Default   = WallHack.Visuals.HeadDotSettings.Thickness,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.HeadDotSettings.Thickness = v end
})

HeadDotSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Visuals.HeadDotSettings.Transparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Visuals.HeadDotSettings.Transparency = v end
})

HeadDotSection:AddColorpicker({
    Name     = "Color",
    Default  = WallHack.Visuals.HeadDotSettings.Color,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Color = v end
})

local HealthBarSection = VisualsTab:AddSection({ Name = "Health Bars" })

HealthBarSection:AddToggle({
    Name     = "Enable Health Bars",
    Default  = WallHack.Visuals.HealthBarSettings.Enabled,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Enabled = v end
})

HealthBarSection:AddDropdown({
    Name    = "Position",
    Default = WallHack.Visuals.HealthBarSettings.Type == 1 and "Top"
           or WallHack.Visuals.HealthBarSettings.Type == 2 and "Bottom"
           or WallHack.Visuals.HealthBarSettings.Type == 3 and "Left" or "Right",
    Options  = {"Top","Bottom","Left","Right"},
    Callback = function(v)
        WallHack.Visuals.HealthBarSettings.Type = v=="Top" and 1 or v=="Bottom" and 2 or v=="Left" and 3 or 4
    end
})

HealthBarSection:AddSlider({
    Name      = "Width",
    Min       = 2,
    Max       = 10,
    Default   = WallHack.Visuals.HealthBarSettings.Size,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.HealthBarSettings.Size = v end
})

HealthBarSection:AddSlider({
    Name      = "Offset",
    Min       = -30,
    Max       = 30,
    Default   = WallHack.Visuals.HealthBarSettings.Offset,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Visuals.HealthBarSettings.Offset = v end
})

HealthBarSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Visuals.HealthBarSettings.Transparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Visuals.HealthBarSettings.Transparency = v end
})

HealthBarSection:AddColorpicker({
    Name     = "Outline Color",
    Default  = WallHack.Visuals.HealthBarSettings.OutlineColor,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.OutlineColor = v end
})

-- ══════════════════════════════════════════════════
--  CROSSHAIR TAB
-- ══════════════════════════════════════════════════

local XhairSection = CrosshairTab:AddSection({ Name = "Crosshair" })

XhairSection:AddToggle({
    Name     = "System Cursor",
    Default  = UserInputService.MouseIconEnabled,
    Callback = function(v) UserInputService.MouseIconEnabled = v end
})

XhairSection:AddToggle({
    Name     = "Custom Crosshair",
    Default  = WallHack.Crosshair.Settings.Enabled,
    Callback = function(v) WallHack.Crosshair.Settings.Enabled = v end
})

XhairSection:AddDropdown({
    Name     = "Position",
    Default  = WallHack.Crosshair.Settings.Type == 1 and "Mouse" or "Center",
    Options  = {"Mouse","Center"},
    Callback = function(v) WallHack.Crosshair.Settings.Type = v == "Mouse" and 1 or 2 end
})

XhairSection:AddSlider({
    Name      = "Size",
    Min       = 4,
    Max       = 40,
    Default   = WallHack.Crosshair.Settings.Size,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Crosshair.Settings.Size = v end
})

XhairSection:AddSlider({
    Name      = "Thickness",
    Min       = 1,
    Max       = 5,
    Default   = WallHack.Crosshair.Settings.Thickness,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Crosshair.Settings.Thickness = v end
})

XhairSection:AddSlider({
    Name      = "Gap",
    Min       = 0,
    Max       = 20,
    Default   = WallHack.Crosshair.Settings.GapSize,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Crosshair.Settings.GapSize = v end
})

XhairSection:AddSlider({
    Name      = "Rotation",
    Min       = -180,
    Max       = 180,
    Default   = WallHack.Crosshair.Settings.Rotation,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Crosshair.Settings.Rotation = v end
})

XhairSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Crosshair.Settings.Transparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Crosshair.Settings.Transparency = v end
})

XhairSection:AddColorpicker({
    Name     = "Color",
    Default  = WallHack.Crosshair.Settings.Color,
    Callback = function(v) WallHack.Crosshair.Settings.Color = v end
})

local DotSection = CrosshairTab:AddSection({ Name = "Center Dot" })

DotSection:AddToggle({
    Name     = "Enable Dot",
    Default  = WallHack.Crosshair.Settings.CenterDot,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDot = v end
})

DotSection:AddToggle({
    Name     = "Filled",
    Default  = WallHack.Crosshair.Settings.CenterDotFilled,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotFilled = v end
})

DotSection:AddSlider({
    Name      = "Size",
    Min       = 1,
    Max       = 10,
    Default   = WallHack.Crosshair.Settings.CenterDotSize,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 1,
    Callback  = function(v) WallHack.Crosshair.Settings.CenterDotSize = v end
})

DotSection:AddSlider({
    Name      = "Transparency",
    Min       = 0,
    Max       = 1,
    Default   = WallHack.Crosshair.Settings.CenterDotTransparency,
    Color     = Color3.fromRGB(255, 51, 17),
    Increment = 0.05,
    Callback  = function(v) WallHack.Crosshair.Settings.CenterDotTransparency = v end
})

DotSection:AddColorpicker({
    Name     = "Color",
    Default  = WallHack.Crosshair.Settings.CenterDotColor,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotColor = v end
})

-- ══════════════════════════════════════════════════
--  CONFIG TAB
-- ══════════════════════════════════════════════════

local ConfigSection = ConfigTab:AddSection({ Name = "Save / Load" })

local AutoSaveEnabled = false

task.spawn(function()
    while task.wait(5) do
        if AutoSaveEnabled then SaveConfig() end
    end
end)

ConfigSection:AddToggle({
    Name     = "Auto-Save (every 5s)",
    Default  = false,
    Callback = function(v)
        AutoSaveEnabled = v
        if v then SaveConfig() end
    end
})

ConfigSection:AddButton({
    Name     = "Save Config",
    Callback = function() SaveConfig() end
})

ConfigSection:AddButton({
    Name     = "Load Config",
    Callback = function() LoadConfig() end
})

local ControlSection = ConfigTab:AddSection({ Name = "Controls" })

ControlSection:AddButton({
    Name     = "Reset All Settings",
    Callback = function()
        Aimbot.Functions:ResetSettings()
        WallHack.Functions:ResetSettings()
    end
})

ControlSection:AddButton({
    Name     = "Restart Modules",
    Callback = function()
        Aimbot.Functions:Restart()
        WallHack.Functions:Restart()
    end
})

ControlSection:AddButton({
    Name     = "Unload",
    Callback = function()
        OrionLib:Destroy()
        Aimbot.Functions:Exit()
        WallHack.Functions:Exit()
        getgenv().AirHub = nil
    end
})

OrionLib:Init()
