--// Services

local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

local getgenv = getgenv or genv or (function() return getfenv(0) end)

--// Loaded check

if getgenv().AirHub or getgenv().AirHubV2Loaded then return end
getgenv().AirHub = {}

-- ══════════════════════════════════════════════════
--  MODULE URLS
-- ══════════════════════════════════════════════════

local MODULE_URLS = {
    Aimbot   = "https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Aimbot.lua",
    WallHack = "https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Wall_Hack.lua",
}

-- ══════════════════════════════════════════════════
--  LOAD MODULES
-- ══════════════════════════════════════════════════

local function safeLoad(url, name)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not ok then warn("[AirHub] " .. name .. " failed: " .. tostring(err)) end
end

safeLoad(MODULE_URLS.Aimbot,   "Aimbot")
safeLoad(MODULE_URLS.WallHack, "WallHack")

local Aimbot   = getgenv().AirHub.Aimbot
local WallHack = getgenv().AirHub.WallHack

if not Aimbot   then warn("[AirHub] Aimbot nil") return end
if not WallHack then warn("[AirHub] WallHack nil") return end

-- ══════════════════════════════════════════════════
--  LOAD LINORIA
-- ══════════════════════════════════════════════════

local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- ══════════════════════════════════════════════════
--  VARIABLES
-- ══════════════════════════════════════════════════

local Parts       = {
    "Head", "HumanoidRootPart", "Torso",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftHand", "RightHand",
    "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm",
    "LeftFoot", "LeftLowerLeg", "UpperTorso", "LeftUpperLeg",
    "RightFoot", "RightLowerLeg", "LowerTorso", "RightUpperLeg"
}
local TracersType = {"Bottom", "Center", "Mouse"}
local BoxTypes    = {"3D Corner", "2D Square"}
local HBPositions = {"Top", "Bottom", "Left", "Right"}
local XhairFollow = {"Mouse", "Screen Center"}

-- ══════════════════════════════════════════════════
--  CONFIG SYSTEM  (named configs, no auto-save)
-- ══════════════════════════════════════════════════

local CONFIG_FOLDER = "AirHub"

local FS_SUPPORTED = (
    typeof(isfolder)   == "function" and typeof(makefolder) == "function" and
    typeof(readfile)   == "function" and typeof(writefile)  == "function" and
    typeof(isfile)     == "function"  and typeof(listfiles) == "function"
)

local function EnsureFolder()
    if FS_SUPPORTED and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function ConfigPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end

local function SC(c) return {r=c.R, g=c.G, b=c.B} end
local function DC(t)
    if type(t) ~= "table" then return Color3.new(1,1,1) end
    return Color3.new(t.r or 1, t.g or 1, t.b or 1)
end

local function BuildSnapshot()
    local A, AF, SA = Aimbot.Settings, Aimbot.FOVSettings, Aimbot.SilentAim
    local WS, WE, WB = WallHack.Settings, WallHack.Visuals.ESPSettings, WallHack.Visuals.BoxSettings
    local WC, WT, WH, WR = WallHack.Visuals.ChamsSettings, WallHack.Visuals.TracersSettings,
                            WallHack.Visuals.HeadDotSettings, WallHack.Visuals.HealthBarSettings
    local XS = WallHack.Crosshair.Settings
    return {
        Aim_Enabled=A.Enabled, Aim_Toggle=A.Toggle, Aim_TriggerKey=A.TriggerKey,
        Aim_Sensitivity=A.Sensitivity, Aim_LockPart=A.LockPart, Aim_TeamCheck=A.TeamCheck,
        Aim_WallCheck=A.WallCheck, Aim_AliveCheck=A.AliveCheck, Aim_ThirdPerson=A.ThirdPerson,
        Aim_ThirdPersonSens=A.ThirdPersonSensitivity,
        SA_Enabled=SA.Enabled, SA_TriggerKey=SA.TriggerKey, SA_Toggle=SA.Toggle,
        SA_TeamCheck=SA.TeamCheck, SA_AliveCheck=SA.AliveCheck, SA_WallCheck=SA.WallCheck,
        SA_LockPart=SA.LockPart, SA_UseFOV=SA.UseFOV, SA_FOVAmount=SA.FOVAmount, SA_Prediction=SA.Prediction,
        FOV_Enabled=AF.Enabled, FOV_Visible=AF.Visible, FOV_Amount=AF.Amount,
        FOV_Filled=AF.Filled, FOV_Transparency=AF.Transparency, FOV_Sides=AF.Sides,
        FOV_Thickness=AF.Thickness, FOV_Color=SC(AF.Color), FOV_LockedColor=SC(AF.LockedColor),
        WH_Enabled=WS.Enabled, WH_TeamCheck=WS.TeamCheck, WH_AliveCheck=WS.AliveCheck, WH_MaxDistance=WS.MaxDistance,
        ESP_Enabled=WE.Enabled, ESP_TextSize=WE.TextSize, ESP_TextTransparency=WE.TextTransparency,
        ESP_DisplayDistance=WE.DisplayDistance, ESP_DisplayHealth=WE.DisplayHealth, ESP_DisplayName=WE.DisplayName,
        ESP_TextColor=SC(WE.TextColor), ESP_OutlineColor=SC(WE.OutlineColor),
        Box_Enabled=WB.Enabled, Box_Type=WB.Type, Box_Filled=WB.Filled, Box_Thickness=WB.Thickness,
        Box_Transparency=WB.Transparency, Box_Increase=WB.Increase, Box_Color=SC(WB.Color),
        Chams_Enabled=WC.Enabled, Chams_Filled=WC.Filled, Chams_EntireBody=WC.EntireBody,
        Chams_Transparency=WC.Transparency, Chams_Thickness=WC.Thickness, Chams_Color=SC(WC.Color),
        Tracer_Enabled=WT.Enabled, Tracer_Type=WT.Type, Tracer_Thickness=WT.Thickness,
        Tracer_Transparency=WT.Transparency, Tracer_Color=SC(WT.Color),
        HD_Enabled=WH.Enabled, HD_Filled=WH.Filled, HD_Sides=WH.Sides,
        HD_Thickness=WH.Thickness, HD_Transparency=WH.Transparency, HD_Color=SC(WH.Color),
        HB_Enabled=WR.Enabled, HB_Type=WR.Type, HB_Size=WR.Size, HB_Offset=WR.Offset,
        HB_Transparency=WR.Transparency, HB_OutlineColor=SC(WR.OutlineColor),
        XH_Enabled=XS.Enabled, XH_Type=XS.Type, XH_Size=XS.Size, XH_Thickness=XS.Thickness,
        XH_GapSize=XS.GapSize, XH_Rotation=XS.Rotation, XH_Transparency=XS.Transparency,
        XH_Color=SC(XS.Color), XH_CenterDot=XS.CenterDot, XH_CenterDotFilled=XS.CenterDotFilled,
        XH_CenterDotSize=XS.CenterDotSize, XH_CenterDotTransparency=XS.CenterDotTransparency,
        XH_CenterDotColor=SC(XS.CenterDotColor),
    }
end

local function ApplySnapshot(S)
    local A, AF, SA = Aimbot.Settings, Aimbot.FOVSettings, Aimbot.SilentAim
    local WS, WE, WB = WallHack.Settings, WallHack.Visuals.ESPSettings, WallHack.Visuals.BoxSettings
    local WC, WT, WH, WR = WallHack.Visuals.ChamsSettings, WallHack.Visuals.TracersSettings,
                            WallHack.Visuals.HeadDotSettings, WallHack.Visuals.HealthBarSettings
    local XS = WallHack.Crosshair.Settings
    local function s(t,k,v) if v~=nil then t[k]=v end end
    local function c(t,k,v) if v~=nil then t[k]=DC(v) end end
    s(A,"Enabled",S.Aim_Enabled) s(A,"Toggle",S.Aim_Toggle) s(A,"TriggerKey",S.Aim_TriggerKey)
    s(A,"Sensitivity",S.Aim_Sensitivity) s(A,"LockPart",S.Aim_LockPart) s(A,"TeamCheck",S.Aim_TeamCheck)
    s(A,"WallCheck",S.Aim_WallCheck) s(A,"AliveCheck",S.Aim_AliveCheck) s(A,"ThirdPerson",S.Aim_ThirdPerson)
    s(A,"ThirdPersonSensitivity",S.Aim_ThirdPersonSens)
    s(SA,"Enabled",S.SA_Enabled) s(SA,"TriggerKey",S.SA_TriggerKey) s(SA,"Toggle",S.SA_Toggle)
    s(SA,"TeamCheck",S.SA_TeamCheck) s(SA,"AliveCheck",S.SA_AliveCheck) s(SA,"WallCheck",S.SA_WallCheck)
    s(SA,"LockPart",S.SA_LockPart) s(SA,"UseFOV",S.SA_UseFOV) s(SA,"FOVAmount",S.SA_FOVAmount) s(SA,"Prediction",S.SA_Prediction)
    s(AF,"Enabled",S.FOV_Enabled) s(AF,"Visible",S.FOV_Visible) s(AF,"Amount",S.FOV_Amount)
    s(AF,"Filled",S.FOV_Filled) s(AF,"Transparency",S.FOV_Transparency) s(AF,"Sides",S.FOV_Sides)
    s(AF,"Thickness",S.FOV_Thickness) c(AF,"Color",S.FOV_Color) c(AF,"LockedColor",S.FOV_LockedColor)
    s(WS,"Enabled",S.WH_Enabled) s(WS,"TeamCheck",S.WH_TeamCheck) s(WS,"AliveCheck",S.WH_AliveCheck) s(WS,"MaxDistance",S.WH_MaxDistance)
    s(WE,"Enabled",S.ESP_Enabled) s(WE,"TextSize",S.ESP_TextSize) s(WE,"TextTransparency",S.ESP_TextTransparency)
    s(WE,"DisplayDistance",S.ESP_DisplayDistance) s(WE,"DisplayHealth",S.ESP_DisplayHealth) s(WE,"DisplayName",S.ESP_DisplayName)
    c(WE,"TextColor",S.ESP_TextColor) c(WE,"OutlineColor",S.ESP_OutlineColor)
    s(WB,"Enabled",S.Box_Enabled) s(WB,"Type",S.Box_Type) s(WB,"Filled",S.Box_Filled)
    s(WB,"Thickness",S.Box_Thickness) s(WB,"Transparency",S.Box_Transparency) s(WB,"Increase",S.Box_Increase) c(WB,"Color",S.Box_Color)
    s(WC,"Enabled",S.Chams_Enabled) s(WC,"Filled",S.Chams_Filled) s(WC,"EntireBody",S.Chams_EntireBody)
    s(WC,"Transparency",S.Chams_Transparency) s(WC,"Thickness",S.Chams_Thickness) c(WC,"Color",S.Chams_Color)
    s(WT,"Enabled",S.Tracer_Enabled) s(WT,"Type",S.Tracer_Type) s(WT,"Thickness",S.Tracer_Thickness)
    s(WT,"Transparency",S.Tracer_Transparency) c(WT,"Color",S.Tracer_Color)
    s(WH,"Enabled",S.HD_Enabled) s(WH,"Filled",S.HD_Filled) s(WH,"Sides",S.HD_Sides)
    s(WH,"Thickness",S.HD_Thickness) s(WH,"Transparency",S.HD_Transparency) c(WH,"Color",S.HD_Color)
    s(WR,"Enabled",S.HB_Enabled) s(WR,"Type",S.HB_Type) s(WR,"Size",S.HB_Size)
    s(WR,"Offset",S.HB_Offset) s(WR,"Transparency",S.HB_Transparency) c(WR,"OutlineColor",S.HB_OutlineColor)
    s(XS,"Enabled",S.XH_Enabled) s(XS,"Type",S.XH_Type) s(XS,"Size",S.XH_Size)
    s(XS,"Thickness",S.XH_Thickness) s(XS,"GapSize",S.XH_GapSize) s(XS,"Rotation",S.XH_Rotation)
    s(XS,"Transparency",S.XH_Transparency) c(XS,"Color",S.XH_Color) s(XS,"CenterDot",S.XH_CenterDot)
    s(XS,"CenterDotFilled",S.XH_CenterDotFilled) s(XS,"CenterDotSize",S.XH_CenterDotSize)
    s(XS,"CenterDotTransparency",S.XH_CenterDotTransparency) c(XS,"CenterDotColor",S.XH_CenterDotColor)
end

local function ListConfigs()
    if not FS_SUPPORTED then return {} end
    EnsureFolder()
    local names = {}
    local ok, files = pcall(listfiles, CONFIG_FOLDER)
    if ok and files then
        for _, path in ipairs(files) do
            local name = path:match("[/\\]([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
    end
    return names
end

local function SaveNamedConfig(name)
    if not FS_SUPPORTED or not name or name == "" then
        Library:Notify("Enter a config name first.", 3) return
    end
    EnsureFolder()
    local ok, err = pcall(writefile, ConfigPath(name), HttpService:JSONEncode(BuildSnapshot()))
    if ok then Library:Notify("Saved: " .. name, 3)
    else warn("[AirHub] Save failed: " .. tostring(err)); Library:Notify("Save failed!", 3) end
end

local function LoadNamedConfig(name)
    if not FS_SUPPORTED or not name or name == "" then
        Library:Notify("Select a config first.", 3) return
    end
    if not isfile(ConfigPath(name)) then Library:Notify("Not found: " .. name, 3) return end
    local ok, err = pcall(function()
        ApplySnapshot(HttpService:JSONDecode(readfile(ConfigPath(name))))
    end)
    if ok then Library:Notify("Loaded: " .. name, 3)
    else warn("[AirHub] Load failed: " .. tostring(err)); Library:Notify("Load failed!", 3) end
end

local function DeleteNamedConfig(name)
    if not FS_SUPPORTED or not name or name == "" then return end
    if isfile(ConfigPath(name)) then
        pcall(delfile, ConfigPath(name))
        Library:Notify("Deleted: " .. name, 3)
    end
end

-- ══════════════════════════════════════════════════
--  HOTKEY BIND HELPER
--  Works by capturing the next InputBegan event.
--  Does NOT use LinoriaLib's AddKeybind (incompatible).
-- ══════════════════════════════════════════════════

local BindingTyping = false
UserInputService.TextBoxFocused:Connect(function()        BindingTyping = true  end)
UserInputService.TextBoxFocusReleased:Connect(function()  BindingTyping = false end)

local function StartBind(btn, labelPrefix, onDone)
    btn:SetText(labelPrefix .. "[ PRESS A KEY ]")
    -- Defer so the click that opened the bind doesn't immediately count as the key
    task.delay(0.1, function()
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            -- Accept keyboard keys or mouse buttons; ignore game-processed GUI events
            local keyName
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                keyName = input.KeyCode.Name
            elseif input.UserInputType ~= Enum.UserInputType.Unknown then
                keyName = input.UserInputType.Name
            else
                return
            end
            conn:Disconnect()
            onDone(keyName)
            btn:SetText(labelPrefix .. keyName)
        end)
    end)
end

-- ══════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════

local Window = Library:CreateWindow({
    Title        = "AirHub V3",
    Center       = true,
    AutoShow     = true,
    TabPadding   = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Aimbot    = Window:AddTab("Aimbot"),
    SilentAim = Window:AddTab("Silent Aim"),
    Visuals   = Window:AddTab("Visuals"),
    Crosshair = Window:AddTab("Crosshair"),
    Config    = Window:AddTab("Config"),
}

-- ══════════════════════════════════════════════════
--  AIMBOT TAB
-- ══════════════════════════════════════════════════

local AimLeft  = Tabs.Aimbot:AddLeftGroupbox("Main")
local AimRight = Tabs.Aimbot:AddRightGroupbox("FOV Circle")

AimLeft:AddToggle("AimEnabled", {
    Text    = "Enable Aimbot",
    Default = Aimbot.Settings.Enabled,
    Callback = function(v) Aimbot.Settings.Enabled = v end,
})

AimLeft:AddToggle("AimToggle", {
    Text    = "Toggle Mode",
    Default = Aimbot.Settings.Toggle,
    Callback = function(v) Aimbot.Settings.Toggle = v end,
})

AimLeft:AddSlider("AimSmoothing", {
    Text    = "Smoothing",
    Default = Aimbot.Settings.Sensitivity,
    Min = 0, Max = 1, Rounding = 2,
    Suffix  = "s",
    Callback = function(v) Aimbot.Settings.Sensitivity = v end,
})

-- Aim Hotkey button
local aimKeyBtn = AimLeft:AddButton({
    Text    = "Hotkey: " .. tostring(Aimbot.Settings.TriggerKey),
    Func    = function() end,
})
aimKeyBtn.Func = function()
    StartBind(aimKeyBtn, "Hotkey: ", function(key)
        Aimbot.Settings.TriggerKey = key
    end)
end

AimLeft:AddDivider()
AimLeft:AddLabel("Targeting")

AimLeft:AddDropdown("AimPart", {
    Text    = "Aim Part",
    Default = "Head",
    Values  = Parts,
    Callback = function(v) Aimbot.Settings.LockPart = v end,
})

AimLeft:AddToggle("AimTeamCheck", {
    Text    = "Team Check",
    Default = Aimbot.Settings.TeamCheck,
    Callback = function(v) Aimbot.Settings.TeamCheck = v end,
})

AimLeft:AddToggle("AimWallCheck", {
    Text    = "Wall Check",
    Default = Aimbot.Settings.WallCheck,
    Callback = function(v) Aimbot.Settings.WallCheck = v end,
})

AimLeft:AddToggle("AimAliveCheck", {
    Text    = "Alive Check",
    Default = Aimbot.Settings.AliveCheck,
    Callback = function(v) Aimbot.Settings.AliveCheck = v end,
})

AimLeft:AddDivider()
AimLeft:AddLabel("Third Person")

AimLeft:AddToggle("AimThirdPerson", {
    Text    = "Third Person Mode",
    Default = Aimbot.Settings.ThirdPerson,
    Callback = function(v) Aimbot.Settings.ThirdPerson = v end,
})

AimLeft:AddSlider("Aim3PSens", {
    Text    = "3P Sensitivity",
    Default = Aimbot.Settings.ThirdPersonSensitivity,
    Min = 1, Max = 10, Rounding = 1,
    Callback = function(v) Aimbot.Settings.ThirdPersonSensitivity = v end,
})

-- FOV --

AimRight:AddToggle("FOVEnabled", {
    Text    = "Restrict Aim to FOV",
    Default = Aimbot.FOVSettings.Enabled,
    Callback = function(v) Aimbot.FOVSettings.Enabled = v end,
})

AimRight:AddToggle("FOVVisible", {
    Text    = "Show FOV Circle",
    Default = Aimbot.FOVSettings.Visible,
    Callback = function(v) Aimbot.FOVSettings.Visible = v end,
})

AimRight:AddToggle("FOVFilled", {
    Text    = "Filled",
    Default = Aimbot.FOVSettings.Filled,
    Callback = function(v) Aimbot.FOVSettings.Filled = v end,
})

AimRight:AddSlider("FOVRadius", {
    Text    = "Radius",
    Default = Aimbot.FOVSettings.Amount,
    Min = 10, Max = 500, Rounding = 0,
    Suffix  = "px",
    Callback = function(v) Aimbot.FOVSettings.Amount = v end,
})

AimRight:AddSlider("FOVTransparency", {
    Text    = "Transparency",
    Default = Aimbot.FOVSettings.Transparency,
    Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) Aimbot.FOVSettings.Transparency = v end,
})

AimRight:AddSlider("FOVThickness", {
    Text    = "Thickness",
    Default = Aimbot.FOVSettings.Thickness,
    Min = 1, Max = 5, Rounding = 0,
    Suffix  = "px",
    Callback = function(v) Aimbot.FOVSettings.Thickness = v end,
})

AimRight:AddSlider("FOVSides", {
    Text    = "Segments",
    Default = Aimbot.FOVSettings.Sides,
    Min = 3, Max = 100, Rounding = 0,
    Callback = function(v) Aimbot.FOVSettings.Sides = v end,
})

AimRight:AddLabel("FOV Color"):AddColorPicker("FOVColor", {
    Default  = Aimbot.FOVSettings.Color,
    Callback = function(v) Aimbot.FOVSettings.Color = v end,
})

AimRight:AddLabel("Locked Color"):AddColorPicker("FOVLockedColor", {
    Default  = Aimbot.FOVSettings.LockedColor,
    Callback = function(v) Aimbot.FOVSettings.LockedColor = v end,
})

-- ══════════════════════════════════════════════════
--  SILENT AIM TAB
-- ══════════════════════════════════════════════════

local SALeft  = Tabs.SilentAim:AddLeftGroupbox("Silent Aim")
local SARight = Tabs.SilentAim:AddRightGroupbox("Settings")

SALeft:AddToggle("SAEnabled", {
    Text    = "Enable Silent Aim",
    Default = Aimbot.SilentAim.Enabled,
    Callback = function(v) Aimbot.SilentAim.Enabled = v end,
})

SALeft:AddToggle("SAToggle", {
    Text    = "Toggle Mode",
    Default = Aimbot.SilentAim.Toggle,
    Callback = function(v) Aimbot.SilentAim.Toggle = v end,
})

local saKeyBtn = SALeft:AddButton({
    Text = "Hotkey: " .. tostring(Aimbot.SilentAim.TriggerKey or "None"),
    Func = function() end,
})
saKeyBtn.Func = function()
    StartBind(saKeyBtn, "Hotkey: ", function(key)
        Aimbot.SilentAim.TriggerKey = key
    end)
end

SALeft:AddDivider()
SALeft:AddLabel("Target")

SALeft:AddDropdown("SALockPart", {
    Text    = "Lock Part",
    Default = "Head",
    Values  = Parts,
    Callback = function(v) Aimbot.SilentAim.LockPart = v end,
})

SALeft:AddToggle("SATeamCheck", {
    Text    = "Team Check",
    Default = Aimbot.SilentAim.TeamCheck,
    Callback = function(v) Aimbot.SilentAim.TeamCheck = v end,
})

SALeft:AddToggle("SAAliveCheck", {
    Text    = "Alive Check",
    Default = Aimbot.SilentAim.AliveCheck,
    Callback = function(v) Aimbot.SilentAim.AliveCheck = v end,
})

SALeft:AddToggle("SAWallCheck", {
    Text    = "Wall Check",
    Default = Aimbot.SilentAim.WallCheck,
    Callback = function(v) Aimbot.SilentAim.WallCheck = v end,
})

SARight:AddToggle("SAUseFOV", {
    Text    = "Limit to FOV",
    Default = Aimbot.SilentAim.UseFOV,
    Callback = function(v) Aimbot.SilentAim.UseFOV = v end,
})

SARight:AddSlider("SAFOVRadius", {
    Text    = "FOV Radius",
    Default = Aimbot.SilentAim.FOVAmount,
    Min = 10, Max = 800, Rounding = 0,
    Suffix  = "px",
    Callback = function(v) Aimbot.SilentAim.FOVAmount = v end,
})

SARight:AddDivider()
SARight:AddLabel("Prediction")

SARight:AddSlider("SAPrediction", {
    Text    = "Velocity Lead",
    Default = Aimbot.SilentAim.Prediction,
    Min = 0, Max = 1, Rounding = 2,
    Tooltip = "0 = off.",
    Callback = function(v) Aimbot.SilentAim.Prediction = v end,
})

-- ══════════════════════════════════════════════════
--  VISUALS TAB
-- ══════════════════════════════════════════════════

local VLeft  = Tabs.Visuals:AddLeftGroupbox("ESP & Tags")
local VRight = Tabs.Visuals:AddRightGroupbox("Drawings")

VLeft:AddToggle("ESPGlobal", {
    Text    = "Enable Visuals",
    Default = WallHack.Settings.Enabled,
    Callback = function(v) WallHack.Settings.Enabled = v end,
})

VLeft:AddToggle("ESPTeamCheck", {
    Text    = "Team Check",
    Default = WallHack.Settings.TeamCheck,
    Callback = function(v) WallHack.Settings.TeamCheck = v end,
})

VLeft:AddToggle("ESPAliveCheck", {
    Text    = "Alive Check",
    Default = WallHack.Settings.AliveCheck,
    Callback = function(v) WallHack.Settings.AliveCheck = v end,
})

VLeft:AddSlider("ESPMaxDist", {
    Text    = "Max Distance",
    Default = WallHack.Settings.MaxDistance,
    Min = 0, Max = 5000, Rounding = 0,
    Suffix  = " studs",
    Tooltip = "0 = unlimited",
    Callback = function(v) WallHack.Settings.MaxDistance = v end,
})

VLeft:AddDivider()
VLeft:AddLabel("Name / Health Tags")

VLeft:AddToggle("TagsEnabled", {
    Text    = "Enable Tags",
    Default = WallHack.Visuals.ESPSettings.Enabled,
    Callback = function(v) WallHack.Visuals.ESPSettings.Enabled = v end,
})

VLeft:AddToggle("TagsName", {
    Text    = "Show Name",
    Default = WallHack.Visuals.ESPSettings.DisplayName,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayName = v end,
})

VLeft:AddToggle("TagsHealth", {
    Text    = "Show Health",
    Default = WallHack.Visuals.ESPSettings.DisplayHealth,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayHealth = v end,
})

VLeft:AddToggle("TagsDist", {
    Text    = "Show Distance",
    Default = WallHack.Visuals.ESPSettings.DisplayDistance,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayDistance = v end,
})

VLeft:AddSlider("TagsTextSize", {
    Text    = "Text Size",
    Default = WallHack.Visuals.ESPSettings.TextSize,
    Min = 8, Max = 24, Rounding = 0,
    Callback = function(v) WallHack.Visuals.ESPSettings.TextSize = v end,
})

VLeft:AddLabel("Text Color"):AddColorPicker("TagsTextColor", {
    Default  = WallHack.Visuals.ESPSettings.TextColor,
    Callback = function(v) WallHack.Visuals.ESPSettings.TextColor = v end,
})

VLeft:AddLabel("Outline Color"):AddColorPicker("TagsOutlineColor", {
    Default  = WallHack.Visuals.ESPSettings.OutlineColor,
    Callback = function(v) WallHack.Visuals.ESPSettings.OutlineColor = v end,
})

-- Box --
VRight:AddLabel("Box ESP")

VRight:AddToggle("BoxEnabled", {
    Text    = "Enable Boxes",
    Default = WallHack.Visuals.BoxSettings.Enabled,
    Callback = function(v) WallHack.Visuals.BoxSettings.Enabled = v end,
})

VRight:AddDropdown("BoxType", {
    Text    = "Box Type",
    Default = WallHack.Visuals.BoxSettings.Type == 1 and "3D Corner" or "2D Square",
    Values  = BoxTypes,
    Callback = function(v) WallHack.Visuals.BoxSettings.Type = v == "3D Corner" and 1 or 2 end,
})

VRight:AddToggle("BoxFilled", {
    Text    = "Filled (2D only)",
    Default = WallHack.Visuals.BoxSettings.Filled,
    Callback = function(v) WallHack.Visuals.BoxSettings.Filled = v end,
})

VRight:AddSlider("BoxThickness", {
    Text    = "Thickness",
    Default = WallHack.Visuals.BoxSettings.Thickness,
    Min = 1, Max = 5, Rounding = 0,
    Callback = function(v) WallHack.Visuals.BoxSettings.Thickness = v end,
})

VRight:AddSlider("BoxTransparency", {
    Text    = "Transparency",
    Default = WallHack.Visuals.BoxSettings.Transparency,
    Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) WallHack.Visuals.BoxSettings.Transparency = v end,
})

VRight:AddLabel("Box Color"):AddColorPicker("BoxColor", {
    Default  = WallHack.Visuals.BoxSettings.Color,
    Callback = function(v) WallHack.Visuals.BoxSettings.Color = v end,
})

VRight:AddDivider()
VRight:AddLabel("Chams")

VRight:AddToggle("ChamsEnabled", {
    Text    = "Enable Chams",
    Default = WallHack.Visuals.ChamsSettings.Enabled,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Enabled = v end,
})

VRight:AddToggle("ChamsFilled", {
    Text    = "Filled",
    Default = WallHack.Visuals.ChamsSettings.Filled,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Filled = v end,
})

VRight:AddToggle("ChamsFullBody", {
    Text    = "Full Body (R15)",
    Default = WallHack.Visuals.ChamsSettings.EntireBody,
    Callback = function(v) WallHack.Visuals.ChamsSettings.EntireBody = v end,
})

VRight:AddSlider("ChamsTransparency", {
    Text    = "Transparency",
    Default = WallHack.Visuals.ChamsSettings.Transparency,
    Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Transparency = v end,
})

VRight:AddLabel("Chams Color"):AddColorPicker("ChamsColor", {
    Default  = WallHack.Visuals.ChamsSettings.Color,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Color = v end,
})

VRight:AddDivider()
VRight:AddLabel("Tracers")

VRight:AddToggle("TracersEnabled", {
    Text    = "Enable Tracers",
    Default = WallHack.Visuals.TracersSettings.Enabled,
    Callback = function(v) WallHack.Visuals.TracersSettings.Enabled = v end,
})

VRight:AddDropdown("TracersOrigin", {
    Text    = "Origin",
    Default = TracersType[WallHack.Visuals.TracersSettings.Type] or "Bottom",
    Values  = TracersType,
    Callback = function(v)
        for i, t in ipairs(TracersType) do
            if t == v then WallHack.Visuals.TracersSettings.Type = i break end
        end
    end,
})

VRight:AddSlider("TracersThickness", {
    Text    = "Thickness",
    Default = WallHack.Visuals.TracersSettings.Thickness,
    Min = 1, Max = 5, Rounding = 0,
    Callback = function(v) WallHack.Visuals.TracersSettings.Thickness = v end,
})

VRight:AddSlider("TracersTransparency", {
    Text    = "Transparency",
    Default = WallHack.Visuals.TracersSettings.Transparency,
    Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) WallHack.Visuals.TracersSettings.Transparency = v end,
})

VRight:AddLabel("Tracers Color"):AddColorPicker("TracersColor", {
    Default  = WallHack.Visuals.TracersSettings.Color,
    Callback = function(v) WallHack.Visuals.TracersSettings.Color = v end,
})

VRight:AddDivider()
VRight:AddLabel("Head Dots")

VRight:AddToggle("HDEnabled", {
    Text    = "Enable Head Dots",
    Default = WallHack.Visuals.HeadDotSettings.Enabled,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Enabled = v end,
})

VRight:AddToggle("HDFilled", {
    Text    = "Filled",
    Default = WallHack.Visuals.HeadDotSettings.Filled,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Filled = v end,
})

VRight:AddSlider("HDSegments", {
    Text    = "Segments",
    Default = WallHack.Visuals.HeadDotSettings.Sides,
    Min = 3, Max = 60, Rounding = 0,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Sides = v end,
})

VRight:AddSlider("HDThickness", {
    Text    = "Thickness",
    Default = WallHack.Visuals.HeadDotSettings.Thickness,
    Min = 1, Max = 5, Rounding = 0,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Thickness = v end,
})

VRight:AddLabel("Head Dot Color"):AddColorPicker("HDColor", {
    Default  = WallHack.Visuals.HeadDotSettings.Color,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Color = v end,
})

VRight:AddDivider()
VRight:AddLabel("Health Bars")

VRight:AddToggle("HBEnabled", {
    Text    = "Enable Health Bars",
    Default = WallHack.Visuals.HealthBarSettings.Enabled,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Enabled = v end,
})

VRight:AddDropdown("HBPosition", {
    Text    = "Position",
    Default = WallHack.Visuals.HealthBarSettings.Type == 1 and "Top"
           or WallHack.Visuals.HealthBarSettings.Type == 2 and "Bottom"
           or WallHack.Visuals.HealthBarSettings.Type == 3 and "Left" or "Right",
    Values  = HBPositions,
    Callback = function(v)
        WallHack.Visuals.HealthBarSettings.Type = v=="Top" and 1 or v=="Bottom" and 2 or v=="Left" and 3 or 4
    end,
})

VRight:AddSlider("HBWidth", {
    Text    = "Width",
    Default = WallHack.Visuals.HealthBarSettings.Size,
    Min = 2, Max = 10, Rounding = 0,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Size = v end,
})

VRight:AddSlider("HBOffset", {
    Text    = "Offset",
    Default = WallHack.Visuals.HealthBarSettings.Offset,
    Min = -30, Max = 30, Rounding = 0,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Offset = v end,
})

VRight:AddSlider("HBTransparency", {
    Text    = "Transparency",
    Default = WallHack.Visuals.HealthBarSettings.Transparency,
    Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Transparency = v end,
})

VRight:AddLabel("Outline Color"):AddColorPicker("HBOutlineColor", {
    Default  = WallHack.Visuals.HealthBarSettings.OutlineColor,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.OutlineColor = v end,
})

-- ══════════════════════════════════════════════════
--  CROSSHAIR TAB
-- ══════════════════════════════════════════════════

local XLeft  = Tabs.Crosshair:AddLeftGroupbox("Crosshair")
local XRight = Tabs.Crosshair:AddRightGroupbox("Center Dot")

XLeft:AddToggle("SysCursor", {
    Text    = "System Cursor",
    Default = UserInputService.MouseIconEnabled,
    Callback = function(v) UserInputService.MouseIconEnabled = v end,
})

XLeft:AddToggle("XhairEnabled", {
    Text    = "Custom Crosshair",
    Default = WallHack.Crosshair.Settings.Enabled,
    Callback = function(v) WallHack.Crosshair.Settings.Enabled = v end,
})

XLeft:AddDropdown("XhairFollow", {
    Text    = "Follow",
    Default = WallHack.Crosshair.Settings.Type == 1 and "Mouse" or "Screen Center",
    Values  = XhairFollow,
    Callback = function(v) WallHack.Crosshair.Settings.Type = v == "Mouse" and 1 or 2 end,
})

XLeft:AddSlider("XhairSize", {
    Text    = "Size",
    Default = WallHack.Crosshair.Settings.Size,
    Min = 4, Max = 40, Rounding = 0,
    Suffix  = "px",
    Callback = function(v) WallHack.Crosshair.Settings.Size = v end,
})

XLeft:AddSlider("XhairThickness", {
    Text    = "Thickness",
    Default = WallHack.Crosshair.Settings.Thickness,
    Min = 1, Max = 5, Rounding = 0,
    Suffix  = "px",
    Callback = function(v) WallHack.Crosshair.Settings.Thickness = v end,
})

XLeft:AddSlider("XhairGap", {
    Text    = "Gap",
    Default = WallHack.Crosshair.Settings.GapSize,
    Min = 0, Max = 20, Rounding = 0,
    Suffix  = "px",
    Callback = function(v) WallHack.Crosshair.Settings.GapSize = v end,
})

XLeft:AddSlider("XhairRotation", {
    Text    = "Rotation",
    Default = WallHack.Crosshair.Settings.Rotation,
    Min = -180, Max = 180, Rounding = 0,
    Suffix  = "°",
    Callback = function(v) WallHack.Crosshair.Settings.Rotation = v end,
})

XLeft:AddSlider("XhairTransparency", {
    Text    = "Transparency",
    Default = WallHack.Crosshair.Settings.Transparency,
    Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) WallHack.Crosshair.Settings.Transparency = v end,
})

XLeft:AddLabel("Color"):AddColorPicker("XhairColor", {
    Default  = WallHack.Crosshair.Settings.Color,
    Callback = function(v) WallHack.Crosshair.Settings.Color = v end,
})

XRight:AddToggle("DotEnabled", {
    Text    = "Enable Dot",
    Default = WallHack.Crosshair.Settings.CenterDot,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDot = v end,
})

XRight:AddToggle("DotFilled", {
    Text    = "Filled",
    Default = WallHack.Crosshair.Settings.CenterDotFilled,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotFilled = v end,
})

XRight:AddSlider("DotSize", {
    Text    = "Size",
    Default = WallHack.Crosshair.Settings.CenterDotSize,
    Min = 1, Max = 10, Rounding = 0,
    Suffix  = "px",
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotSize = v end,
})

XRight:AddSlider("DotTransparency", {
    Text    = "Transparency",
    Default = WallHack.Crosshair.Settings.CenterDotTransparency,
    Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotTransparency = v end,
})

XRight:AddLabel("Color"):AddColorPicker("DotColor", {
    Default  = WallHack.Crosshair.Settings.CenterDotColor,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotColor = v end,
})

-- ══════════════════════════════════════════════════
--  CONFIG TAB
-- ══════════════════════════════════════════════════

local CLeft  = Tabs.Config:AddLeftGroupbox("Save / Load")
local CRight = Tabs.Config:AddRightGroupbox("Controls")

local currentConfigName = ""

CLeft:AddInput("ConfigNameInput", {
    Text        = "Config Name",
    Default     = "",
    Placeholder = "Enter config name...",
    Callback    = function(v) currentConfigName = v end,
})

local configDropdown

local function RefreshConfigList()
    local names = ListConfigs()
    if #names == 0 then names = {"(none)"} end
    if configDropdown then
        configDropdown:SetValues(names)
        configDropdown:SetValue(names[1])
        if names[1] ~= "(none)" then currentConfigName = names[1] end
    end
end

configDropdown = CLeft:AddDropdown("ConfigSelector", {
    Text    = "Select Config",
    Default = "(none)",
    Values  = {"(none)"},
    Callback = function(v)
        if v ~= "(none)" then currentConfigName = v end
    end,
})

CLeft:AddButton({ Text = "Refresh List", Func = RefreshConfigList })
CLeft:AddDivider()
CLeft:AddButton({ Text = "Save Config",   Func = function() SaveNamedConfig(currentConfigName) RefreshConfigList() end })
CLeft:AddButton({ Text = "Load Config",   Func = function() LoadNamedConfig(currentConfigName) end })
CLeft:AddButton({ Text = "Delete Config", Func = function() DeleteNamedConfig(currentConfigName) RefreshConfigList() end })

-- Controls --

CRight:AddButton({
    Text = "Reset All Settings",
    Func = function()
        pcall(function() Aimbot.Functions:ResetSettings() end)
        pcall(function() WallHack.Functions:ResetSettings() end)
        Library:Notify("Settings reset.", 3)
    end,
})

CRight:AddButton({
    Text = "Restart Modules",
    Func = function()
        -- Exit old instances
        pcall(function() Aimbot.Functions:Exit() end)
        pcall(function() WallHack.Functions:Exit() end)

        -- Clear so modules re-register
        getgenv().AirHub.Aimbot   = nil
        getgenv().AirHub.WallHack = nil

        -- Re-load
        safeLoad(MODULE_URLS.Aimbot,   "Aimbot")
        safeLoad(MODULE_URLS.WallHack, "WallHack")

        -- Update references
        Aimbot   = getgenv().AirHub.Aimbot
        WallHack = getgenv().AirHub.WallHack

        if Aimbot and WallHack then
            Library:Notify("Modules restarted.", 3)
        else
            Library:Notify("Restart failed – check console.", 5)
        end
    end,
})

CRight:AddButton({
    Text = "Unload",
    Func = function()
        pcall(function() Aimbot.Functions:Exit() end)
        pcall(function() WallHack.Functions:Exit() end)
        Library:Destroy()
        getgenv().AirHub         = nil
        getgenv().AirHubV2Loaded = nil
    end,
})

-- ══════════════════════════════════════════════════
--  THEME MANAGER
-- ══════════════════════════════════════════════════

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs.Config)

RefreshConfigList()
