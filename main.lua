local loadstring, getgenv, setclipboard, tablefind, UserInputService = loadstring, getgenv, setclipboard, table.find, game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

--// Loaded check

if AirHub or AirHubV2Loaded then
    return
end

--// Environment

getgenv().AirHub = {}

--// Load Modules
-- Loads from AirHub/ folder in your executor workspace.
-- Place Aimbot.lua and Wall_Hack.lua in the AirHub folder alongside config.json.

if not isfolder("AirHub") then makefolder("AirHub") end

local function LoadModule(filename)
    local path = "AirHub/" .. filename
    if not isfile(path) then
        error("[AirHub] Missing module: " .. path .. "\nMake sure Aimbot.lua and Wall_Hack.lua are inside your AirHub folder.", 2)
    end
    loadstring(readfile(path))()
end

LoadModule("Aimbot.lua")
LoadModule("Wall_Hack.lua")

--// Variables

local Library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)()
local Aimbot, WallHack = getgenv().AirHub.Aimbot, getgenv().AirHub.WallHack
local Parts, Fonts, TracersType = {"Head","HumanoidRootPart","Torso","Left Arm","Right Arm","Left Leg","Right Leg","LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftUpperArm","RightUpperArm","LeftFoot","LeftLowerLeg","UpperTorso","LeftUpperLeg","RightFoot","RightLowerLeg","LowerTorso","RightUpperLeg"}, {"UI","System","Plex","Monospace"}, {"Bottom","Center","Mouse"}

-- ══════════════════════════════════════════════════
--  CONFIG SYSTEM  (executor filesystem)
--  Saves to: <executor workspace>/AirHub/config.json
-- ══════════════════════════════════════════════════

local CONFIG_FOLDER = "AirHub"
local CONFIG_FILE   = CONFIG_FOLDER .. "/config.json"

-- Ensure folder exists safely
local function EnsureFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

-- Serialise Color3 → {r,g,b}
local function SerialiseColor(c)
    return {r = c.R, g = c.G, b = c.B}
end

-- Deserialise {r,g,b} → Color3
local function DeserialiseColor(t)
    if type(t) ~= "table" then return Color3.new(1, 1, 1) end
    return Color3.new(t.r or 1, t.g or 1, t.b or 1)
end

-- Build a flat snapshot of every setting we want to persist
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
        -- Aimbot
        Aim_Enabled            = A.Enabled,
        Aim_Toggle             = A.Toggle,
        Aim_TriggerKey         = A.TriggerKey,
        Aim_Sensitivity        = A.Sensitivity,
        Aim_LockPart           = A.LockPart,
        Aim_TeamCheck          = A.TeamCheck,
        Aim_WallCheck          = A.WallCheck,
        Aim_AliveCheck         = A.AliveCheck,
        Aim_ThirdPerson        = A.ThirdPerson,
        Aim_ThirdPersonSens    = A.ThirdPersonSensitivity,
        -- Silent Aim
        SA_Enabled             = SA.Enabled,
        SA_TeamCheck           = SA.TeamCheck,
        SA_AliveCheck          = SA.AliveCheck,
        SA_WallCheck           = SA.WallCheck,
        SA_LockPart            = SA.LockPart,
        SA_UseFOV              = SA.UseFOV,
        SA_FOVAmount           = SA.FOVAmount,
        SA_Prediction          = SA.Prediction,
        -- FOV
        FOV_Enabled            = AF.Enabled,
        FOV_Visible            = AF.Visible,
        FOV_Amount             = AF.Amount,
        FOV_Filled             = AF.Filled,
        FOV_Transparency       = AF.Transparency,
        FOV_Sides              = AF.Sides,
        FOV_Thickness          = AF.Thickness,
        FOV_Color              = SerialiseColor(AF.Color),
        FOV_LockedColor        = SerialiseColor(AF.LockedColor),
        -- WallHack global
        WH_Enabled             = WS.Enabled,
        WH_TeamCheck           = WS.TeamCheck,
        WH_AliveCheck          = WS.AliveCheck,
        WH_MaxDistance         = WS.MaxDistance,
        -- ESP
        ESP_Enabled            = WE.Enabled,
        ESP_TextSize           = WE.TextSize,
        ESP_TextTransparency   = WE.TextTransparency,
        ESP_DisplayDistance    = WE.DisplayDistance,
        ESP_DisplayHealth      = WE.DisplayHealth,
        ESP_DisplayName        = WE.DisplayName,
        ESP_TextColor          = SerialiseColor(WE.TextColor),
        ESP_OutlineColor       = SerialiseColor(WE.OutlineColor),
        -- Box
        Box_Enabled            = WB.Enabled,
        Box_Type               = WB.Type,
        Box_Filled             = WB.Filled,
        Box_Thickness          = WB.Thickness,
        Box_Transparency       = WB.Transparency,
        Box_Increase           = WB.Increase,
        Box_Color              = SerialiseColor(WB.Color),
        -- Chams
        Chams_Enabled          = WC.Enabled,
        Chams_Filled           = WC.Filled,
        Chams_EntireBody       = WC.EntireBody,
        Chams_Transparency     = WC.Transparency,
        Chams_Thickness        = WC.Thickness,
        Chams_Color            = SerialiseColor(WC.Color),
        -- Tracers
        Tracer_Enabled         = WT.Enabled,
        Tracer_Type            = WT.Type,
        Tracer_Thickness       = WT.Thickness,
        Tracer_Transparency    = WT.Transparency,
        Tracer_Color           = SerialiseColor(WT.Color),
        -- HeadDot
        HD_Enabled             = WH.Enabled,
        HD_Filled              = WH.Filled,
        HD_Sides               = WH.Sides,
        HD_Thickness           = WH.Thickness,
        HD_Transparency        = WH.Transparency,
        HD_Color               = SerialiseColor(WH.Color),
        -- HealthBar
        HB_Enabled             = WR.Enabled,
        HB_Type                = WR.Type,
        HB_Size                = WR.Size,
        HB_Offset              = WR.Offset,
        HB_Transparency        = WR.Transparency,
        HB_OutlineColor        = SerialiseColor(WR.OutlineColor),
        -- Crosshair
        XH_Enabled             = XS.Enabled,
        XH_Type                = XS.Type,
        XH_Size                = XS.Size,
        XH_Thickness           = XS.Thickness,
        XH_GapSize             = XS.GapSize,
        XH_Rotation            = XS.Rotation,
        XH_Transparency        = XS.Transparency,
        XH_Color               = SerialiseColor(XS.Color),
        XH_CenterDot           = XS.CenterDot,
        XH_CenterDotFilled     = XS.CenterDotFilled,
        XH_CenterDotSize       = XS.CenterDotSize,
        XH_CenterDotTransparency = XS.CenterDotTransparency,
        XH_CenterDotColor      = SerialiseColor(XS.CenterDotColor),
    }
end

-- Apply a loaded snapshot back onto every live setting table
local function ApplySnapshot(S)
    local A  = Aimbot.Settings
    local AF = Aimbot.FOVSettings
    local WS = WallHack.Settings
    local WE = WallHack.Visuals.ESPSettings
    local WB = WallHack.Visuals.BoxSettings
    local WC = WallHack.Visuals.ChamsSettings
    local WT = WallHack.Visuals.TracersSettings
    local WH = WallHack.Visuals.HeadDotSettings
    local WR = WallHack.Visuals.HealthBarSettings
    local XS = WallHack.Crosshair.Settings

    -- Helper: only assign if key exists in snapshot (safe for partial configs)
    local function set(tbl, key, val) if val ~= nil then tbl[key] = val end end
    local function setC(tbl, key, val) if val ~= nil then tbl[key] = DeserialiseColor(val) end end

    set(A,  "Enabled",                S.Aim_Enabled)
    set(A,  "Toggle",                 S.Aim_Toggle)
    set(A,  "TriggerKey",             S.Aim_TriggerKey)
    set(A,  "Sensitivity",            S.Aim_Sensitivity)
    set(A,  "LockPart",               S.Aim_LockPart)
    set(A,  "TeamCheck",              S.Aim_TeamCheck)
    set(A,  "WallCheck",              S.Aim_WallCheck)
    set(A,  "AliveCheck",             S.Aim_AliveCheck)
    set(A,  "ThirdPerson",            S.Aim_ThirdPerson)
    set(A,  "ThirdPersonSensitivity", S.Aim_ThirdPersonSens)

    set(SA, "Enabled",    S.SA_Enabled)
    set(SA, "TeamCheck",  S.SA_TeamCheck)
    set(SA, "AliveCheck", S.SA_AliveCheck)
    set(SA, "WallCheck",  S.SA_WallCheck)
    set(SA, "LockPart",   S.SA_LockPart)
    set(SA, "UseFOV",     S.SA_UseFOV)
    set(SA, "FOVAmount",  S.SA_FOVAmount)
    set(SA, "Prediction", S.SA_Prediction)

    set(AF, "Enabled",     S.FOV_Enabled)
    set(AF, "Visible",     S.FOV_Visible)
    set(AF, "Amount",      S.FOV_Amount)
    set(AF, "Filled",      S.FOV_Filled)
    set(AF, "Transparency",S.FOV_Transparency)
    set(AF, "Sides",       S.FOV_Sides)
    set(AF, "Thickness",   S.FOV_Thickness)
    setC(AF,"Color",       S.FOV_Color)
    setC(AF,"LockedColor", S.FOV_LockedColor)

    set(WS, "Enabled",     S.WH_Enabled)
    set(WS, "TeamCheck",   S.WH_TeamCheck)
    set(WS, "AliveCheck",  S.WH_AliveCheck)
    set(WS, "MaxDistance", S.WH_MaxDistance)

    set(WE, "Enabled",          S.ESP_Enabled)
    set(WE, "TextSize",         S.ESP_TextSize)
    set(WE, "TextTransparency", S.ESP_TextTransparency)
    set(WE, "DisplayDistance",  S.ESP_DisplayDistance)
    set(WE, "DisplayHealth",    S.ESP_DisplayHealth)
    set(WE, "DisplayName",      S.ESP_DisplayName)
    setC(WE,"TextColor",        S.ESP_TextColor)
    setC(WE,"OutlineColor",     S.ESP_OutlineColor)

    set(WB, "Enabled",     S.Box_Enabled)
    set(WB, "Type",        S.Box_Type)
    set(WB, "Filled",      S.Box_Filled)
    set(WB, "Thickness",   S.Box_Thickness)
    set(WB, "Transparency",S.Box_Transparency)
    set(WB, "Increase",    S.Box_Increase)
    setC(WB,"Color",       S.Box_Color)

    set(WC, "Enabled",     S.Chams_Enabled)
    set(WC, "Filled",      S.Chams_Filled)
    set(WC, "EntireBody",  S.Chams_EntireBody)
    set(WC, "Transparency",S.Chams_Transparency)
    set(WC, "Thickness",   S.Chams_Thickness)
    setC(WC,"Color",       S.Chams_Color)

    set(WT, "Enabled",     S.Tracer_Enabled)
    set(WT, "Type",        S.Tracer_Type)
    set(WT, "Thickness",   S.Tracer_Thickness)
    set(WT, "Transparency",S.Tracer_Transparency)
    setC(WT,"Color",       S.Tracer_Color)

    set(WH, "Enabled",     S.HD_Enabled)
    set(WH, "Filled",      S.HD_Filled)
    set(WH, "Sides",       S.HD_Sides)
    set(WH, "Thickness",   S.HD_Thickness)
    set(WH, "Transparency",S.HD_Transparency)
    setC(WH,"Color",       S.HD_Color)

    set(WR, "Enabled",     S.HB_Enabled)
    set(WR, "Type",        S.HB_Type)
    set(WR, "Size",        S.HB_Size)
    set(WR, "Offset",      S.HB_Offset)
    set(WR, "Transparency",S.HB_Transparency)
    setC(WR,"OutlineColor",S.HB_OutlineColor)

    set(XS, "Enabled",              S.XH_Enabled)
    set(XS, "Type",                 S.XH_Type)
    set(XS, "Size",                 S.XH_Size)
    set(XS, "Thickness",            S.XH_Thickness)
    set(XS, "GapSize",              S.XH_GapSize)
    set(XS, "Rotation",             S.XH_Rotation)
    set(XS, "Transparency",         S.XH_Transparency)
    setC(XS,"Color",                S.XH_Color)
    set(XS, "CenterDot",            S.XH_CenterDot)
    set(XS, "CenterDotFilled",      S.XH_CenterDotFilled)
    set(XS, "CenterDotSize",        S.XH_CenterDotSize)
    set(XS, "CenterDotTransparency",S.XH_CenterDotTransparency)
    setC(XS,"CenterDotColor",       S.XH_CenterDotColor)
end

-- Public save
local function SaveConfig()
    local ok, err = pcall(function()
        EnsureFolder()
        local snapshot = BuildSnapshot()
        local json = HttpService:JSONEncode(snapshot)
        writefile(CONFIG_FILE, json)
    end)
    if not ok then
        warn("[AirHub] Config save failed: " .. tostring(err))
    end
end

-- Public load — applies settings then calls Library.ResetAll() so the UI reflects them
local function LoadConfig()
    local ok, err = pcall(function()
        if not isfile(CONFIG_FILE) then
            warn("[AirHub] No config found at " .. CONFIG_FILE)
            return
        end
        local json = readfile(CONFIG_FILE)
        local snapshot = HttpService:JSONDecode(json)
        ApplySnapshot(snapshot)
        -- Refresh UI widgets to match newly applied values
        Library.ResetAll()
    end)
    if not ok then
        warn("[AirHub] Config load failed: " .. tostring(err))
    end
end

-- Auto-load on startup if a config already exists
task.defer(function()
    if isfolder(CONFIG_FOLDER) and isfile(CONFIG_FILE) then
        LoadConfig()
    end
end)

--// Keybind state

local BindingKey = false
local CurrentKeyLabel = nil

local function StartBind(labelElement)
    BindingKey = true
    if labelElement then
        labelElement.Name = "[ PRESS ANY KEY ]"
    end

    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if BindingKey then
            BindingKey = false
            local keyName = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
            Aimbot.Settings.TriggerKey = keyName
            if labelElement then
                labelElement.Name = "Hotkey: "..keyName
            end
            conn:Disconnect()
        end
    end)
end

--// Unload

Library.UnloadCallback = function()
    Aimbot.Functions:Exit()
    WallHack.Functions:Exit()
    getgenv().AirHub = nil
end

--// ────────────────────────────────────────────────
--//  DEEP BLACK / CRIMSON ACCENT THEME
--// ────────────────────────────────────────────────

local MainFrame = Library:CreateWindow({
    Name = "SORROW  ·  AIRHUB  ·  V3",
    Themeable = {
        Image  = "7059346386",
        Info   = "sorrow.cc  |  build 2026",
        Credit = false
    },
    Background = "",
    Theme = [[{
        "__Designer.Colors.topGradient":"0D0D0D",
        "__Designer.Colors.section":"1C1C1C",
        "__Designer.Colors.hoveredOptionBottom":"CC2200",
        "__Designer.Background.ImageAssetID":"rbxassetid://4427304036",
        "__Designer.Colors.selectedOption":"FFFFFF",
        "__Designer.Colors.unselectedOption":"666666",
        "__Designer.Files.WorkspaceFile":"AirHub",
        "__Designer.Colors.unhoveredOptionTop":"1A1A1A",
        "__Designer.Colors.outerBorder":"050505",
        "__Designer.Background.ImageColor":"000000",
        "__Designer.Colors.tabText":"DDDDDD",
        "__Designer.Colors.elementBorder":"252525",
        "__Designer.Background.ImageTransparency":100,
        "__Designer.Colors.background":"0A0A0A",
        "__Designer.Colors.innerBorder":"181818",
        "__Designer.Colors.bottomGradient":"101010",
        "__Designer.Colors.sectionBackground":"111111",
        "__Designer.Colors.hoveredOptionTop":"FF3311",
        "__Designer.Colors.otherElementText":"999999",
        "__Designer.Colors.main":"FF3311",
        "__Designer.Colors.elementText":"EFEFEF",
        "__Designer.Colors.unhoveredOptionBottom":"151515",
        "__Designer.Background.UseBackgroundImage":false
    }]]
})

--// ────────────────────────────────────────────────
--//  TABS
--// ────────────────────────────────────────────────

local AimbotTab   = MainFrame:CreateTab({ Name = "  AIM  " })
local VisualsTab  = MainFrame:CreateTab({ Name = " VISUALS " })
local CrosshairTab = MainFrame:CreateTab({ Name = " XHAIR " })
local ConfigTab   = MainFrame:CreateTab({ Name = " CONFIG " })

--// ────────────────────────────────────────────────
--//  AIMBOT SECTIONS
--// ────────────────────────────────────────────────

local AimbotMain     = AimbotTab:CreateSection({ Name = "AIMBOT",       Side = "Left"  })
local AimbotTargeting = AimbotTab:CreateSection({ Name = "TARGETING",    Side = "Left"  })
local SilentAimSection = AimbotTab:CreateSection({ Name = "SILENT AIM",   Side = "Left"  })
local FOVSection     = AimbotTab:CreateSection({ Name = "FIELD OF VIEW", Side = "Right" })
local FOVVisuals     = AimbotTab:CreateSection({ Name = "FOV VISUALS",   Side = "Right" })

--// ────────────────────────────────────────────────
--//  VISUALS SECTIONS
--// ────────────────────────────────────────────────

local ESPMain        = VisualsTab:CreateSection({ Name = "ESP",          Side = "Left"  })
local ESPRange       = VisualsTab:CreateSection({ Name = "RANGE",        Side = "Left"  })
local BoxESP         = VisualsTab:CreateSection({ Name = "BOX ESP",      Side = "Left"  })
local ChamsSection   = VisualsTab:CreateSection({ Name = "CHAMS",        Side = "Left"  })
local TracersSection = VisualsTab:CreateSection({ Name = "TRACERS",      Side = "Right" })
local HeadDotsSection = VisualsTab:CreateSection({ Name = "HEAD DOTS",   Side = "Right" })
local HealthSection  = VisualsTab:CreateSection({ Name = "HEALTH BARS",  Side = "Right" })

--// ────────────────────────────────────────────────
--//  CROSSHAIR SECTIONS
--// ────────────────────────────────────────────────

local CrosshairMain = CrosshairTab:CreateSection({ Name = "CROSSHAIR",   Side = "Left"  })
local CrosshairDot  = CrosshairTab:CreateSection({ Name = "CENTER DOT",  Side = "Right" })

--// Config sections are declared inline at the bottom of the file

-- ══════════════════════════════════════════════════
--  AIMBOT — MAIN
-- ══════════════════════════════════════════════════

AimbotMain:AddToggle({
    Name  = "Enable Aimbot",
    Value = Aimbot.Settings.Enabled,
    Callback = function(v) Aimbot.Settings.Enabled = v end
}).Default = Aimbot.Settings.Enabled

AimbotMain:AddToggle({
    Name  = "Toggle Mode",
    Value = Aimbot.Settings.Toggle,
    Callback = function(v) Aimbot.Settings.Toggle = v end
}).Default = Aimbot.Settings.Toggle

AimbotMain:AddSlider({
    Name     = "Smoothing",
    Value    = Aimbot.Settings.Sensitivity,
    Callback = function(v) Aimbot.Settings.Sensitivity = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = Aimbot.Settings.Sensitivity

--// Keybind button — click to rebind

do
    local keyLabel = "Hotkey: " .. tostring(Aimbot.Settings.TriggerKey)

    AimbotMain:AddButton({
        Name     = keyLabel,
        Callback = function()
            -- The button element reference isn't directly accessible in all libs,
            -- so we toggle a flag and update via the button's own name if supported.
            -- Works with Pepsi UI Library button Name mutation:
            StartBind(nil)
        end
    })

    -- Provide a cleaner live-update label above the bind button
    AimbotMain:AddLabel({
        Name = "Press button above, then press any key to bind"
    })

    -- Update displayed key in real time
    task.spawn(function()
        while task.wait(0.25) do
            if BindingKey then
                -- waiting for input; nothing to update yet
            end
        end
    end)
end

-- ══════════════════════════════════════════════════
--  AIMBOT — TARGETING
-- ══════════════════════════════════════════════════

AimbotTargeting:AddDropdown({
    Name     = "Aim Part",
    Value    = Parts[1],
    Callback = function(v) Aimbot.Settings.LockPart = v end,
    List     = Parts,
    Nothing  = "Head"
}).Default = Parts[1]

AimbotTargeting:AddToggle({
    Name     = "Team Check",
    Value    = Aimbot.Settings.TeamCheck,
    Callback = function(v) Aimbot.Settings.TeamCheck = v end
}).Default = Aimbot.Settings.TeamCheck

AimbotTargeting:AddToggle({
    Name     = "Wall Check",
    Value    = Aimbot.Settings.WallCheck,
    Callback = function(v) Aimbot.Settings.WallCheck = v end
}).Default = Aimbot.Settings.WallCheck

AimbotTargeting:AddToggle({
    Name     = "Alive Check",
    Value    = Aimbot.Settings.AliveCheck,
    Callback = function(v) Aimbot.Settings.AliveCheck = v end
}).Default = Aimbot.Settings.AliveCheck

AimbotTargeting:AddToggle({
    Name     = "Third Person",
    Value    = Aimbot.Settings.ThirdPerson,
    Callback = function(v) Aimbot.Settings.ThirdPerson = v end
}).Default = Aimbot.Settings.ThirdPerson

AimbotTargeting:AddSlider({
    Name     = "3P Sensitivity",
    Value    = Aimbot.Settings.ThirdPersonSensitivity,
    Callback = function(v) Aimbot.Settings.ThirdPersonSensitivity = v end,
    Min      = 0.1,
    Max      = 5,
    Decimals = 1,
    Format   = "%.1f"
}).Default = Aimbot.Settings.ThirdPersonSensitivity

-- ══════════════════════════════════════════════════
--  AIMBOT — SILENT AIM
-- ══════════════════════════════════════════════════

SilentAimSection:AddToggle({
    Name     = "Enable Silent Aim",
    Value    = Aimbot.SilentAim.Enabled,
    Callback = function(v) Aimbot.SilentAim.Enabled = v end
}).Default = Aimbot.SilentAim.Enabled

SilentAimSection:AddDropdown({
    Name     = "Lock Part",
    Value    = Aimbot.SilentAim.LockPart,
    Callback = function(v) Aimbot.SilentAim.LockPart = v end,
    List     = Parts,
    Nothing  = "Head"
}).Default = Aimbot.SilentAim.LockPart

SilentAimSection:AddToggle({
    Name     = "Team Check",
    Value    = Aimbot.SilentAim.TeamCheck,
    Callback = function(v) Aimbot.SilentAim.TeamCheck = v end
}).Default = Aimbot.SilentAim.TeamCheck

SilentAimSection:AddToggle({
    Name     = "Alive Check",
    Value    = Aimbot.SilentAim.AliveCheck,
    Callback = function(v) Aimbot.SilentAim.AliveCheck = v end
}).Default = Aimbot.SilentAim.AliveCheck

SilentAimSection:AddToggle({
    Name     = "Wall Check",
    Value    = Aimbot.SilentAim.WallCheck,
    Callback = function(v) Aimbot.SilentAim.WallCheck = v end
}).Default = Aimbot.SilentAim.WallCheck

SilentAimSection:AddToggle({
    Name     = "Use FOV Limit",
    Value    = Aimbot.SilentAim.UseFOV,
    Callback = function(v) Aimbot.SilentAim.UseFOV = v end
}).Default = Aimbot.SilentAim.UseFOV

SilentAimSection:AddSlider({
    Name     = "FOV Radius",
    Value    = Aimbot.SilentAim.FOVAmount,
    Callback = function(v) Aimbot.SilentAim.FOVAmount = v end,
    Min      = 10,
    Max      = 500,
    Format   = "%dpx"
}).Default = Aimbot.SilentAim.FOVAmount

SilentAimSection:AddSlider({
    Name     = "Prediction",
    Value    = Aimbot.SilentAim.Prediction,
    Callback = function(v) Aimbot.SilentAim.Prediction = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = Aimbot.SilentAim.Prediction

-- ══════════════════════════════════════════════════
--  FOV SECTION
-- ══════════════════════════════════════════════════

FOVSection:AddToggle({
    Name     = "Enable FOV",
    Value    = Aimbot.FOVSettings.Enabled,
    Callback = function(v) Aimbot.FOVSettings.Enabled = v end
}).Default = Aimbot.FOVSettings.Enabled

FOVSection:AddToggle({
    Name     = "Show FOV Circle",
    Value    = Aimbot.FOVSettings.Visible,
    Callback = function(v) Aimbot.FOVSettings.Visible = v end
}).Default = Aimbot.FOVSettings.Visible

FOVSection:AddSlider({
    Name     = "FOV Radius",
    Value    = Aimbot.FOVSettings.Amount,
    Callback = function(v) Aimbot.FOVSettings.Amount = v end,
    Min      = 10,
    Max      = 300,
    Format   = "%dpx"
}).Default = Aimbot.FOVSettings.Amount

-- ══════════════════════════════════════════════════
--  FOV VISUALS
-- ══════════════════════════════════════════════════

FOVVisuals:AddToggle({
    Name     = "Filled",
    Value    = Aimbot.FOVSettings.Filled,
    Callback = function(v) Aimbot.FOVSettings.Filled = v end
}).Default = Aimbot.FOVSettings.Filled

FOVVisuals:AddSlider({
    Name     = "Transparency",
    Value    = Aimbot.FOVSettings.Transparency,
    Callback = function(v) Aimbot.FOVSettings.Transparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 1,
    Format   = "%.1f"
}).Default = Aimbot.FOVSettings.Transparency

FOVVisuals:AddSlider({
    Name     = "Segments",
    Value    = Aimbot.FOVSettings.Sides,
    Callback = function(v) Aimbot.FOVSettings.Sides = v end,
    Min      = 3,
    Max      = 60,
    Format   = "%d"
}).Default = Aimbot.FOVSettings.Sides

FOVVisuals:AddSlider({
    Name     = "Line Width",
    Value    = Aimbot.FOVSettings.Thickness,
    Callback = function(v) Aimbot.FOVSettings.Thickness = v end,
    Min      = 1,
    Max      = 5,
    Format   = "%dpx"
}).Default = Aimbot.FOVSettings.Thickness

FOVVisuals:AddColorpicker({
    Name     = "Color",
    Value    = Aimbot.FOVSettings.Color,
    Callback = function(v) Aimbot.FOVSettings.Color = v end
}).Default = Aimbot.FOVSettings.Color

FOVVisuals:AddColorpicker({
    Name     = "Locked Color",
    Value    = Aimbot.FOVSettings.LockedColor,
    Callback = function(v) Aimbot.FOVSettings.LockedColor = v end
}).Default = Aimbot.FOVSettings.LockedColor

-- ══════════════════════════════════════════════════
--  ESP — MAIN
-- ══════════════════════════════════════════════════

ESPMain:AddToggle({
    Name     = "Enable ESP",
    Value    = WallHack.Settings.Enabled,
    Callback = function(v) WallHack.Settings.Enabled = v end
}).Default = WallHack.Settings.Enabled

ESPMain:AddToggle({
    Name     = "Team Check",
    Value    = WallHack.Settings.TeamCheck,
    Callback = function(v) WallHack.Settings.TeamCheck = v end
}).Default = WallHack.Settings.TeamCheck

ESPMain:AddToggle({
    Name     = "Alive Check",
    Value    = WallHack.Settings.AliveCheck,
    Callback = function(v) WallHack.Settings.AliveCheck = v end
}).Default = WallHack.Settings.AliveCheck

ESPMain:AddToggle({
    Name     = "Show Distance",
    Value    = WallHack.Visuals.ESPSettings.DisplayDistance,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayDistance = v end
}).Default = WallHack.Visuals.ESPSettings.DisplayDistance

ESPMain:AddToggle({
    Name     = "Show Health",
    Value    = WallHack.Visuals.ESPSettings.DisplayHealth,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayHealth = v end
}).Default = WallHack.Visuals.ESPSettings.DisplayHealth

ESPMain:AddToggle({
    Name     = "Show Name",
    Value    = WallHack.Visuals.ESPSettings.DisplayName,
    Callback = function(v) WallHack.Visuals.ESPSettings.DisplayName = v end
}).Default = WallHack.Visuals.ESPSettings.DisplayName

ESPMain:AddSlider({
    Name     = "Text Size",
    Value    = WallHack.Visuals.ESPSettings.TextSize,
    Callback = function(v) WallHack.Visuals.ESPSettings.TextSize = v end,
    Min      = 8,
    Max      = 24,
    Format   = "%dpt"
}).Default = WallHack.Visuals.ESPSettings.TextSize

ESPMain:AddSlider({
    Name     = "Text Alpha",
    Value    = WallHack.Visuals.ESPSettings.TextTransparency,
    Callback = function(v) WallHack.Visuals.ESPSettings.TextTransparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Visuals.ESPSettings.TextTransparency

ESPMain:AddColorpicker({
    Name     = "Text Color",
    Value    = WallHack.Visuals.ESPSettings.TextColor,
    Callback = function(v) WallHack.Visuals.ESPSettings.TextColor = v end
}).Default = WallHack.Visuals.ESPSettings.TextColor

-- ══════════════════════════════════════════════════
--  ESP — MAX DISTANCE
-- ══════════════════════════════════════════════════

ESPRange:AddSlider({
    Name     = "Max Distance (studs)",
    Value    = WallHack.Settings.MaxDistance,
    Callback = function(v) WallHack.Settings.MaxDistance = v end,
    Min      = 0,
    Max      = 5000,
    Format   = "%d studs"
}).Default = WallHack.Settings.MaxDistance

ESPRange:AddLabel({
    Name = "0 = Unlimited range"
})

-- ══════════════════════════════════════════════════
--  BOX ESP
-- ══════════════════════════════════════════════════

BoxESP:AddToggle({
    Name     = "Enable Boxes",
    Value    = WallHack.Visuals.BoxSettings.Enabled,
    Callback = function(v) WallHack.Visuals.BoxSettings.Enabled = v end
}).Default = WallHack.Visuals.BoxSettings.Enabled

BoxESP:AddDropdown({
    Name     = "Box Type",
    Value    = WallHack.Visuals.BoxSettings.Type == 1 and "3D" or "2D",
    Callback = function(v) WallHack.Visuals.BoxSettings.Type = v == "3D" and 1 or 2 end,
    List     = {"3D", "2D"},
    Nothing  = "3D"
}).Default = WallHack.Visuals.BoxSettings.Type == 1 and "3D" or "2D"

BoxESP:AddToggle({
    Name     = "Filled (2D only)",
    Value    = WallHack.Visuals.BoxSettings.Filled,
    Callback = function(v) WallHack.Visuals.BoxSettings.Filled = v end
}).Default = WallHack.Visuals.BoxSettings.Filled

BoxESP:AddSlider({
    Name     = "Line Width",
    Value    = WallHack.Visuals.BoxSettings.Thickness,
    Callback = function(v) WallHack.Visuals.BoxSettings.Thickness = v end,
    Min      = 1,
    Max      = 5,
    Format   = "%dpx"
}).Default = WallHack.Visuals.BoxSettings.Thickness

BoxESP:AddSlider({
    Name     = "Box Alpha",
    Value    = WallHack.Visuals.BoxSettings.Transparency,
    Callback = function(v) WallHack.Visuals.BoxSettings.Transparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Visuals.BoxSettings.Transparency

BoxESP:AddSlider({
    Name     = "Scale",
    Value    = WallHack.Visuals.BoxSettings.Increase,
    Callback = function(v) WallHack.Visuals.BoxSettings.Increase = v end,
    Min      = 1,
    Max      = 5,
    Format   = "%.1fx"
}).Default = WallHack.Visuals.BoxSettings.Increase

BoxESP:AddColorpicker({
    Name     = "Box Color",
    Value    = WallHack.Visuals.BoxSettings.Color,
    Callback = function(v) WallHack.Visuals.BoxSettings.Color = v end
}).Default = WallHack.Visuals.BoxSettings.Color

-- ══════════════════════════════════════════════════
--  CHAMS
-- ══════════════════════════════════════════════════

ChamsSection:AddToggle({
    Name     = "Enable Chams",
    Value    = WallHack.Visuals.ChamsSettings.Enabled,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Enabled = v end
}).Default = WallHack.Visuals.ChamsSettings.Enabled

ChamsSection:AddToggle({
    Name     = "Filled",
    Value    = WallHack.Visuals.ChamsSettings.Filled,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Filled = v end
}).Default = WallHack.Visuals.ChamsSettings.Filled

ChamsSection:AddToggle({
    Name     = "Full Body (R15)",
    Value    = WallHack.Visuals.ChamsSettings.EntireBody,
    Callback = function(v) WallHack.Visuals.ChamsSettings.EntireBody = v end
}).Default = WallHack.Visuals.ChamsSettings.EntireBody

ChamsSection:AddSlider({
    Name     = "Alpha",
    Value    = WallHack.Visuals.ChamsSettings.Transparency,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Transparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Visuals.ChamsSettings.Transparency

ChamsSection:AddSlider({
    Name     = "Outline Width",
    Value    = WallHack.Visuals.ChamsSettings.Thickness,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Thickness = v end,
    Min      = 0,
    Max      = 3,
    Format   = "%dpx"
}).Default = WallHack.Visuals.ChamsSettings.Thickness

ChamsSection:AddColorpicker({
    Name     = "Color",
    Value    = WallHack.Visuals.ChamsSettings.Color,
    Callback = function(v) WallHack.Visuals.ChamsSettings.Color = v end
}).Default = WallHack.Visuals.ChamsSettings.Color

-- ══════════════════════════════════════════════════
--  TRACERS
-- ══════════════════════════════════════════════════

TracersSection:AddToggle({
    Name     = "Enable Tracers",
    Value    = WallHack.Visuals.TracersSettings.Enabled,
    Callback = function(v) WallHack.Visuals.TracersSettings.Enabled = v end
}).Default = WallHack.Visuals.TracersSettings.Enabled

TracersSection:AddDropdown({
    Name     = "Start Position",
    Value    = TracersType[WallHack.Visuals.TracersSettings.Type],
    Callback = function(v) WallHack.Visuals.TracersSettings.Type = tablefind(TracersType, v) end,
    List     = TracersType,
    Nothing  = "Bottom"
}).Default = TracersType[WallHack.Visuals.TracersSettings.Type]

TracersSection:AddSlider({
    Name     = "Line Width",
    Value    = WallHack.Visuals.TracersSettings.Thickness,
    Callback = function(v) WallHack.Visuals.TracersSettings.Thickness = v end,
    Min      = 1,
    Max      = 5,
    Format   = "%dpx"
}).Default = WallHack.Visuals.TracersSettings.Thickness

TracersSection:AddSlider({
    Name     = "Alpha",
    Value    = WallHack.Visuals.TracersSettings.Transparency,
    Callback = function(v) WallHack.Visuals.TracersSettings.Transparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Visuals.TracersSettings.Transparency

TracersSection:AddColorpicker({
    Name     = "Color",
    Value    = WallHack.Visuals.TracersSettings.Color,
    Callback = function(v) WallHack.Visuals.TracersSettings.Color = v end
}).Default = WallHack.Visuals.TracersSettings.Color

-- ══════════════════════════════════════════════════
--  HEAD DOTS
-- ══════════════════════════════════════════════════

HeadDotsSection:AddToggle({
    Name     = "Enable Head Dots",
    Value    = WallHack.Visuals.HeadDotSettings.Enabled,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Enabled = v end
}).Default = WallHack.Visuals.HeadDotSettings.Enabled

HeadDotsSection:AddToggle({
    Name     = "Filled",
    Value    = WallHack.Visuals.HeadDotSettings.Filled,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Filled = v end
}).Default = WallHack.Visuals.HeadDotSettings.Filled

HeadDotsSection:AddSlider({
    Name     = "Segments",
    Value    = WallHack.Visuals.HeadDotSettings.Sides,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Sides = v end,
    Min      = 3,
    Max      = 60,
    Format   = "%d"
}).Default = WallHack.Visuals.HeadDotSettings.Sides

HeadDotsSection:AddSlider({
    Name     = "Outline Width",
    Value    = WallHack.Visuals.HeadDotSettings.Thickness,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Thickness = v end,
    Min      = 1,
    Max      = 5,
    Format   = "%dpx"
}).Default = WallHack.Visuals.HeadDotSettings.Thickness

HeadDotsSection:AddSlider({
    Name     = "Alpha",
    Value    = WallHack.Visuals.HeadDotSettings.Transparency,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Transparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Visuals.HeadDotSettings.Transparency

HeadDotsSection:AddColorpicker({
    Name     = "Color",
    Value    = WallHack.Visuals.HeadDotSettings.Color,
    Callback = function(v) WallHack.Visuals.HeadDotSettings.Color = v end
}).Default = WallHack.Visuals.HeadDotSettings.Color

-- ══════════════════════════════════════════════════
--  HEALTH BARS
-- ══════════════════════════════════════════════════

HealthSection:AddToggle({
    Name     = "Enable Health Bars",
    Value    = WallHack.Visuals.HealthBarSettings.Enabled,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Enabled = v end
}).Default = WallHack.Visuals.HealthBarSettings.Enabled

HealthSection:AddDropdown({
    Name     = "Position",
    Value    = WallHack.Visuals.HealthBarSettings.Type == 1 and "Top" or WallHack.Visuals.HealthBarSettings.Type == 2 and "Bottom" or WallHack.Visuals.HealthBarSettings.Type == 3 and "Left" or "Right",
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Type = v == "Top" and 1 or v == "Bottom" and 2 or v == "Left" and 3 or 4 end,
    List     = {"Top","Bottom","Left","Right"},
    Nothing  = "Left"
}).Default = WallHack.Visuals.HealthBarSettings.Type == 1 and "Top" or WallHack.Visuals.HealthBarSettings.Type == 2 and "Bottom" or WallHack.Visuals.HealthBarSettings.Type == 3 and "Left" or "Right"

HealthSection:AddSlider({
    Name     = "Width",
    Value    = WallHack.Visuals.HealthBarSettings.Size,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Size = v end,
    Min      = 2,
    Max      = 10,
    Format   = "%dpx"
}).Default = WallHack.Visuals.HealthBarSettings.Size

HealthSection:AddSlider({
    Name     = "Alpha",
    Value    = WallHack.Visuals.HealthBarSettings.Transparency,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Transparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Visuals.HealthBarSettings.Transparency

HealthSection:AddSlider({
    Name     = "Offset",
    Value    = WallHack.Visuals.HealthBarSettings.Offset,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.Offset = v end,
    Min      = -30,
    Max      = 30,
    Format   = "%dpx"
}).Default = WallHack.Visuals.HealthBarSettings.Offset

HealthSection:AddColorpicker({
    Name     = "Outline Color",
    Value    = WallHack.Visuals.HealthBarSettings.OutlineColor,
    Callback = function(v) WallHack.Visuals.HealthBarSettings.OutlineColor = v end
}).Default = WallHack.Visuals.HealthBarSettings.OutlineColor

-- ══════════════════════════════════════════════════
--  CROSSHAIR — MAIN
-- ══════════════════════════════════════════════════

CrosshairMain:AddToggle({
    Name     = "System Cursor",
    Value    = UserInputService.MouseIconEnabled,
    Callback = function(v) UserInputService.MouseIconEnabled = v end
}).Default = UserInputService.MouseIconEnabled

CrosshairMain:AddToggle({
    Name     = "Custom Crosshair",
    Value    = WallHack.Crosshair.Settings.Enabled,
    Callback = function(v) WallHack.Crosshair.Settings.Enabled = v end
}).Default = WallHack.Crosshair.Settings.Enabled

CrosshairMain:AddDropdown({
    Name     = "Position",
    Value    = WallHack.Crosshair.Settings.Type == 1 and "Mouse" or "Center",
    Callback = function(v) WallHack.Crosshair.Settings.Type = v == "Mouse" and 1 or 2 end,
    List     = {"Mouse","Center"},
    Nothing  = "Mouse"
}).Default = WallHack.Crosshair.Settings.Type == 1 and "Mouse" or "Center"

CrosshairMain:AddSlider({
    Name     = "Size",
    Value    = WallHack.Crosshair.Settings.Size,
    Callback = function(v) WallHack.Crosshair.Settings.Size = v end,
    Min      = 8,
    Max      = 24,
    Format   = "%dpx"
}).Default = WallHack.Crosshair.Settings.Size

CrosshairMain:AddSlider({
    Name     = "Thickness",
    Value    = WallHack.Crosshair.Settings.Thickness,
    Callback = function(v) WallHack.Crosshair.Settings.Thickness = v end,
    Min      = 1,
    Max      = 5,
    Format   = "%dpx"
}).Default = WallHack.Crosshair.Settings.Thickness

CrosshairMain:AddSlider({
    Name     = "Gap",
    Value    = WallHack.Crosshair.Settings.GapSize,
    Callback = function(v) WallHack.Crosshair.Settings.GapSize = v end,
    Min      = 0,
    Max      = 20,
    Format   = "%dpx"
}).Default = WallHack.Crosshair.Settings.GapSize

CrosshairMain:AddSlider({
    Name     = "Rotation",
    Value    = WallHack.Crosshair.Settings.Rotation,
    Callback = function(v) WallHack.Crosshair.Settings.Rotation = v end,
    Min      = -180,
    Max      = 180,
    Format   = "%d°"
}).Default = WallHack.Crosshair.Settings.Rotation

CrosshairMain:AddSlider({
    Name     = "Alpha",
    Value    = WallHack.Crosshair.Settings.Transparency,
    Callback = function(v) WallHack.Crosshair.Settings.Transparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Crosshair.Settings.Transparency

CrosshairMain:AddColorpicker({
    Name     = "Color",
    Value    = WallHack.Crosshair.Settings.Color,
    Callback = function(v) WallHack.Crosshair.Settings.Color = v end
}).Default = WallHack.Crosshair.Settings.Color

-- ══════════════════════════════════════════════════
--  CENTER DOT
-- ══════════════════════════════════════════════════

CrosshairDot:AddToggle({
    Name     = "Enable Dot",
    Value    = WallHack.Crosshair.Settings.CenterDot,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDot = v end
}).Default = WallHack.Crosshair.Settings.CenterDot

CrosshairDot:AddToggle({
    Name     = "Filled",
    Value    = WallHack.Crosshair.Settings.CenterDotFilled,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotFilled = v end
}).Default = WallHack.Crosshair.Settings.CenterDotFilled

CrosshairDot:AddSlider({
    Name     = "Size",
    Value    = WallHack.Crosshair.Settings.CenterDotSize,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotSize = v end,
    Min      = 1,
    Max      = 6,
    Format   = "%dpx"
}).Default = WallHack.Crosshair.Settings.CenterDotSize

CrosshairDot:AddSlider({
    Name     = "Alpha",
    Value    = WallHack.Crosshair.Settings.CenterDotTransparency,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotTransparency = v end,
    Min      = 0,
    Max      = 1,
    Decimals = 2,
    Format   = "%.2f"
}).Default = WallHack.Crosshair.Settings.CenterDotTransparency

CrosshairDot:AddColorpicker({
    Name     = "Color",
    Value    = WallHack.Crosshair.Settings.CenterDotColor,
    Callback = function(v) WallHack.Crosshair.Settings.CenterDotColor = v end
}).Default = WallHack.Crosshair.Settings.CenterDotColor

-- ══════════════════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════════════════

local ConfigSave    = ConfigTab:CreateSection({ Name = "SAVE / LOAD",  Side = "Left"  })
local ConfigControl = ConfigTab:CreateSection({ Name = "CONTROLS",     Side = "Right" })

--// Auto-save toggle (saves on every setting change when enabled)
local AutoSaveEnabled = false

-- Wrap every Callback above to also trigger auto-save.
-- Since Pepsi lib doesn't expose a global onChange, we poll every 5s when autosave is on.
task.spawn(function()
    while task.wait(5) do
        if AutoSaveEnabled then
            SaveConfig()
        end
    end
end)

ConfigSave:AddToggle({
    Name     = "Auto-Save  (every 5s)",
    Value    = false,
    Callback = function(v)
        AutoSaveEnabled = v
        if v then SaveConfig() end   -- immediate save when turned on
    end
}).Default = false

ConfigSave:AddButton({
    Name     = "💾  SAVE CONFIG",
    Callback = function()
        SaveConfig()
    end
})

ConfigSave:AddButton({
    Name     = "📂  LOAD CONFIG",
    Callback = function()
        LoadConfig()
    end
})

ConfigSave:AddLabel({
    Name = "Saves to: AirHub/config.json"
})

--// Module / session controls

ConfigControl:AddButton({
    Name     = "RESET ALL SETTINGS",
    Callback = function()
        Aimbot.Functions:ResetSettings()
        WallHack.Functions:ResetSettings()
        Library.ResetAll()
    end
})

ConfigControl:AddButton({
    Name     = "RESTART MODULES",
    Callback = function()
        Aimbot.Functions:Restart()
        WallHack.Functions:Restart()
    end
})

ConfigControl:AddButton({
    Name     = "UNLOAD",
    Callback = Library.Unload
})
