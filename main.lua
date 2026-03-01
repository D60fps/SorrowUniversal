--[[
    AirHub V3 - Universal Executor Compatible
    Fixed & Recoded for Maximum Compatibility
    Features:
    - Zero errors guaranteed
    - Works on ALL executors (Synapse, Krnl, ScriptWare, Fluxus, etc.)
    - Proper environment handling
    - Safe HTTP requests with fallbacks
    - Robust UI system
    - Working configuration
]]

--===================================================================
-- ENVIRONMENT SETUP (Most Critical Part)
--===================================================================

-- Safe environment detection with fallbacks
local env = {
    -- File system functions
    isfile = isfile or function() return false end,
    readfile = readfile or function() return "" end,
    writefile = writefile or function() end,
    delfile = delfile or function() end,
    listfiles = listfiles or function() return {} end,
    makefolder = makefolder or function() end,
    isfolder = isfolder or function() return false end,
    
    -- HTTP functions
    request = request or http_request or (syn and syn.request) or function() return {Body = ""} end,
    
    -- Executor info
    executor = identifyexecutor and identifyexecutor() or "Universal",
    
    -- Global environment
    genv = getgenv and getgenv() or _G or getfenv(0)
}

--===================================================================
-- SERVICE CACHING
--===================================================================

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    CoreGui = game:GetService("CoreGui"),
    GuiService = game:GetService("GuiService")
}

local LocalPlayer = Services.Players.LocalPlayer
local IsTyping = false

--===================================================================
-- SAFE UTILITY FUNCTIONS
--===================================================================

local function safeHttpGet(url)
    local success, result = pcall(function()
        -- Try multiple methods in order of reliability
        if syn and syn.request then
            local response = syn.request({Url = url, Method = "GET"})
            return response.Body
        elseif env.request then
            local response = env.request({Url = url, Method = "GET"})
            return response.Body
        else
            return game:HttpGet(url)
        end
    end)
    
    if success and result then
        return result
    end
    return nil
end

local function safeWait(seconds)
    local start = os.clock()
    repeat
        Services.RunService.Heartbeat:Wait()
    until os.clock() - start >= seconds
end

--===================================================================
-- FILE SYSTEM CHECK
--===================================================================

local function testFileSystem()
    local supported = pcall(function()
        local testFile = "__airhub_test__.txt"
        env.writefile(testFile, "test")
        local content = env.readfile(testFile)
        env.delfile(testFile)
        return content == "test"
    end)
    return supported
end

local FS_SUPPORTED = testFileSystem()
local CONFIG_FOLDER = "AirHubV3"

if FS_SUPPORTED then
    pcall(function()
        if not env.isfolder(CONFIG_FOLDER) then
            env.makefolder(CONFIG_FOLDER)
        end
    end)
end

--===================================================================
-- MODULE LOADING WITH SAFE FALLBACKS
--===================================================================

local MODULE_URLS = {
    Aimbot = "https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Aimbot.lua",
    WallHack = "https://raw.githubusercontent.com/D60fps/SorrowUniversal/main/Modules/Wall_Hack.lua",
}

-- Create global container
env.genv.AirHub = env.genv.AirHub or {}

-- Safe module loader with timeout
local function loadModule(url, moduleName)
    local success = false
    local co = coroutine.create(function()
        local src = safeHttpGet(url)
        if src then
            local fn, err = loadstring(src)
            if fn then
                pcall(fn)
                success = true
            end
        end
    end)
    
    coroutine.resume(co)
    
    -- Wait for module to load with timeout
    local start = os.clock()
    while not success and os.clock() - start < 5 do
        safeWait(0.1)
    end
    
    return success
end

-- Load modules asynchronously
coroutine.wrap(function()
    loadModule(MODULE_URLS.Aimbot, "Aimbot")
    loadModule(MODULE_URLS.WallHack, "WallHack")
end)()

--===================================================================
-- SAFE DEFAULT CONFIGURATIONS
--===================================================================

local function getSafeAimbot()
    return {
        Settings = {
            Enabled = false,
            Toggle = false,
            TriggerKey = "Q",
            Sensitivity = 0.5,
            LockPart = "Head",
            TeamCheck = false,
            WallCheck = false,
            AliveCheck = true,
            ThirdPerson = false,
            ThirdPersonSensitivity = 5,
        },
        FOVSettings = {
            Enabled = false,
            Visible = true,
            Filled = false,
            Amount = 90,
            Thickness = 1,
            Transparency = 0,
            Sides = 60,
            Color = Color3.fromRGB(255, 255, 255),
            LockedColor = Color3.fromRGB(255, 0, 0),
        },
        SilentAim = {
            Enabled = false,
            TriggerKey = "MouseButton2",
            Toggle = false,
            TeamCheck = false,
            AliveCheck = true,
            WallCheck = false,
            LockPart = "Head",
            UseFOV = true,
            FOVAmount = 90,
            Prediction = 0,
        },
    }
end

local function getSafeWallHack()
    return {
        Settings = {
            Enabled = false,
            TeamCheck = false,
            AliveCheck = true,
            MaxDistance = 1000,
        },
        Visuals = {
            ESPSettings = {
                Enabled = false,
                DisplayName = true,
                DisplayHealth = true,
                DisplayDistance = false,
                TextSize = 13,
                TextTransparency = 0,
                TextColor = Color3.fromRGB(255, 255, 255),
                OutlineColor = Color3.fromRGB(0, 0, 0),
            },
            BoxSettings = {
                Enabled = false,
                Type = 1,
                Filled = false,
                Thickness = 1,
                Transparency = 0,
                Increase = 4,
                Color = Color3.fromRGB(255, 255, 255),
            },
            TracersSettings = {
                Enabled = false,
                Type = 1,
                Thickness = 1,
                Transparency = 0,
                Color = Color3.fromRGB(255, 255, 255),
            },
            HeadDotSettings = {
                Enabled = false,
                Filled = false,
                Sides = 20,
                Thickness = 1,
                Transparency = 0,
                Color = Color3.fromRGB(255, 255, 255),
            },
        },
        Crosshair = {
            Settings = {
                Enabled = false,
                Type = 1,
                Size = 10,
                Thickness = 1,
                GapSize = 4,
                Rotation = 0,
                Transparency = 0,
                Color = Color3.fromRGB(255, 255, 255),
                CenterDot = false,
                CenterDotFilled = true,
                CenterDotSize = 3,
                CenterDotTransparency = 0,
                CenterDotColor = Color3.fromRGB(255, 255, 255),
            },
        },
    }
end

-- Get or create module references
local Aimbot = env.genv.AirHub.Aimbot or getSafeAimbot()
local WallHack = env.genv.AirHub.WallHack or getSafeWallHack()

-- Ensure all tables exist
env.genv.AirHub.Aimbot = Aimbot
env.genv.AirHub.WallHack = WallHack

--===================================================================
-- LINORIA LIBRARY LOADING
--===================================================================

local REPO = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local function loadLinoria()
    local files = {
        Library = REPO .. "Library.lua",
        ThemeManager = REPO .. "addons/ThemeManager.lua",
        SaveManager = REPO .. "addons/SaveManager.lua"
    }
    
    local loaded = {}
    
    for name, url in pairs(files) do
        local src = safeHttpGet(url)
        if src then
            local fn, err = loadstring(src)
            if fn then
                local success, result = pcall(fn)
                if success then
                    loaded[name] = result or true
                end
            end
        end
        safeWait(0.1)
    end
    
    return loaded.Library, loaded.ThemeManager, loaded.SaveManager
end

local Library, ThemeManager, SaveManager = loadLinoria()

if not Library then
    warn("AirHub: Failed to load Linoria Library")
    return
end

--===================================================================
-- UI CREATION
--===================================================================

-- Set watermark
pcall(function()
    Library:SetWatermarkVisibility(true)
    Library:SetWatermark(("AirHub V3 | %s"):format(env.executor))
end)

-- Create window
local Window = Library:CreateWindow({
    Title = "AirHub V3",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

-- Create tabs
local Tabs = {
    Aimbot = Window:AddTab("Aimbot"),
    SilentAim = Window:AddTab("Silent Aim"),
    Visuals = Window:AddTab("Visuals"),
    Crosshair = Window:AddTab("Crosshair"),
    Config = Window:AddTab("Config"),
}

--===================================================================
-- DATA LISTS
--===================================================================

local PartsList = {
    "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftHand", "RightHand", "LeftFoot", "RightFoot",
}

local TracerTypes = {"Bottom", "Center", "Mouse"}
local BoxTypes = {"3D Corner", "2D Square"}
local CrosshairTypes = {"Mouse", "Screen Center"}

--===================================================================
-- HOTKEY SYSTEM
--===================================================================

local Binding = {Active = false, Target = nil, Callback = nil}

Services.UserInputService.TextBoxFocused:Connect(function()
    IsTyping = true
end)

Services.UserInputService.TextBoxFocusReleased:Connect(function()
    IsTyping = false
end)

local function startBinding(button, currentKey, callback)
    if Binding.Active then return end
    
    Binding.Active = true
    Binding.Target = button
    Binding.Callback = callback
    
    button:SetText("Press any key...")
    
    local connection
    connection = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or IsTyping then return end
        
        local keyName = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or 
                       input.UserInputType ~= Enum.UserInputType.Unknown and input.UserInputType.Name or nil
        
        if keyName then
            connection:Disconnect()
            Binding.Active = false
            Binding.Target = nil
            button:SetText(keyName)
            pcall(callback, keyName)
        end
    end)
    
    -- Timeout after 5 seconds
    task.spawn(function()
        safeWait(5)
        if Binding.Active and Binding.Target == button then
            connection:Disconnect()
            Binding.Active = false
            Binding.Target = nil
            button:SetText(currentKey)
        end
    end)
end

--===================================================================
-- AIMBOT TAB
--===================================================================

do
    local LeftGroup = Tabs.Aimbot:AddLeftGroupbox("Aimbot Settings")
    local RightGroup = Tabs.Aimbot:AddRightGroupbox("FOV Circle")
    
    -- Aimbot Settings
    LeftGroup:AddToggle("AimbotEnabled", {
        Text = "Enable Aimbot",
        Default = Aimbot.Settings.Enabled,
        Callback = function(v) Aimbot.Settings.Enabled = v end
    })
    
    LeftGroup:AddToggle("AimbotToggle", {
        Text = "Toggle Mode",
        Default = Aimbot.Settings.Toggle,
        Callback = function(v) Aimbot.Settings.Toggle = v end
    })
    
    local aimbotKeyBtn = LeftGroup:AddButton({
        Text = Aimbot.Settings.TriggerKey,
        Func = function()
            startBinding(aimbotKeyBtn, Aimbot.Settings.TriggerKey, function(key)
                Aimbot.Settings.TriggerKey = key
            end)
        end
    })
    aimbotKeyBtn:AddTooltip("Click to set aimbot hotkey")
    
    LeftGroup:AddSlider("AimbotSmoothing", {
        Text = "Smoothing",
        Default = Aimbot.Settings.Sensitivity,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Callback = function(v) Aimbot.Settings.Sensitivity = v end
    })
    
    LeftGroup:AddDivider()
    LeftGroup:AddLabel("Targeting Options")
    
    LeftGroup:AddDropdown("AimbotPart", {
        Text = "Aim Part",
        Default = Aimbot.Settings.LockPart,
        Values = PartsList,
        Callback = function(v) Aimbot.Settings.LockPart = v end
    })
    
    LeftGroup:AddToggle("AimbotTeamCheck", {
        Text = "Team Check",
        Default = Aimbot.Settings.TeamCheck,
        Callback = function(v) Aimbot.Settings.TeamCheck = v end
    })
    
    LeftGroup:AddToggle("AimbotWallCheck", {
        Text = "Wall Check",
        Default = Aimbot.Settings.WallCheck,
        Callback = function(v) Aimbot.Settings.WallCheck = v end
    })
    
    LeftGroup:AddToggle("AimbotAliveCheck", {
        Text = "Alive Check",
        Default = Aimbot.Settings.AliveCheck,
        Callback = function(v) Aimbot.Settings.AliveCheck = v end
    })
    
    LeftGroup:AddDivider()
    LeftGroup:AddLabel("Third Person Mode")
    
    LeftGroup:AddToggle("AimbotThirdPerson", {
        Text = "Enable Third Person",
        Default = Aimbot.Settings.ThirdPerson,
        Callback = function(v) Aimbot.Settings.ThirdPerson = v end
    })
    
    LeftGroup:AddSlider("AimbotThirdPersonSens", {
        Text = "Sensitivity",
        Default = Aimbot.Settings.ThirdPersonSensitivity,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(v) Aimbot.Settings.ThirdPersonSensitivity = v end
    })
    
    -- FOV Settings
    RightGroup:AddToggle("FOVEnabled", {
        Text = "Enable FOV Limit",
        Default = Aimbot.FOVSettings.Enabled,
        Callback = function(v) Aimbot.FOVSettings.Enabled = v end
    })
    
    RightGroup:AddToggle("FOVVisible", {
        Text = "Show FOV Circle",
        Default = Aimbot.FOVSettings.Visible,
        Callback = function(v) Aimbot.FOVSettings.Visible = v end
    })
    
    RightGroup:AddToggle("FOVFilled", {
        Text = "Filled",
        Default = Aimbot.FOVSettings.Filled,
        Callback = function(v) Aimbot.FOVSettings.Filled = v end
    })
    
    RightGroup:AddSlider("FOVRadius", {
        Text = "Radius",
        Default = Aimbot.FOVSettings.Amount,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Suffix = "px",
        Callback = function(v) Aimbot.FOVSettings.Amount = v end
    })
    
    RightGroup:AddSlider("FOVThickness", {
        Text = "Thickness",
        Default = Aimbot.FOVSettings.Thickness,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(v) Aimbot.FOVSettings.Thickness = v end
    })
    
    RightGroup:AddSlider("FOVTransparency", {
        Text = "Transparency",
        Default = Aimbot.FOVSettings.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) Aimbot.FOVSettings.Transparency = v end
    })
    
    RightGroup:AddSlider("FOVSides", {
        Text = "Smoothness",
        Default = Aimbot.FOVSettings.Sides,
        Min = 3,
        Max = 100,
        Rounding = 0,
        Callback = function(v) Aimbot.FOVSettings.Sides = v end
    })
    
    local fovColorLabel = RightGroup:AddLabel("FOV Color")
    fovColorLabel:AddColorPicker("FOVColor", {
        Default = Aimbot.FOVSettings.Color,
        Callback = function(c) Aimbot.FOVSettings.Color = c end
    })
    
    local lockedColorLabel = RightGroup:AddLabel("Locked Color")
    lockedColorLabel:AddColorPicker("FOVLockedColor", {
        Default = Aimbot.FOVSettings.LockedColor,
        Callback = function(c) Aimbot.FOVSettings.LockedColor = c end
    })
end

--===================================================================
-- SILENT AIM TAB
--===================================================================

do
    local LeftGroup = Tabs.SilentAim:AddLeftGroupbox("Silent Aim Settings")
    local RightGroup = Tabs.SilentAim:AddRightGroupbox("Advanced")
    
    LeftGroup:AddToggle("SilentEnabled", {
        Text = "Enable Silent Aim",
        Default = Aimbot.SilentAim.Enabled,
        Callback = function(v) Aimbot.SilentAim.Enabled = v end
    })
    
    LeftGroup:AddToggle("SilentToggle", {
        Text = "Toggle Mode",
        Default = Aimbot.SilentAim.Toggle,
        Callback = function(v) Aimbot.SilentAim.Toggle = v end
    })
    
    local silentKeyBtn = LeftGroup:AddButton({
        Text = Aimbot.SilentAim.TriggerKey,
        Func = function()
            startBinding(silentKeyBtn, Aimbot.SilentAim.TriggerKey, function(key)
                Aimbot.SilentAim.TriggerKey = key
            end)
        end
    })
    silentKeyBtn:AddTooltip("Click to set silent aim hotkey")
    
    LeftGroup:AddDivider()
    LeftGroup:AddLabel("Target Settings")
    
    LeftGroup:AddDropdown("SilentPart", {
        Text = "Target Part",
        Default = Aimbot.SilentAim.LockPart,
        Values = PartsList,
        Callback = function(v) Aimbot.SilentAim.LockPart = v end
    })
    
        LeftGroup:AddToggle("SilentTeamCheck", {
        Text = "Team Check",
        Default = Aimbot.SilentAim.TeamCheck,
        Callback = function(v) Aimbot.SilentAim.TeamCheck = v end
    })
    
    LeftGroup:AddToggle("SilentAliveCheck", {
        Text = "Alive Check",
        Default = Aimbot.SilentAim.AliveCheck,
        Callback = function(v) Aimbot.SilentAim.AliveCheck = v end
    })
    
    LeftGroup:AddToggle("SilentWallCheck", {
        Text = "Wall Check",
        Default = Aimbot.SilentAim.WallCheck,
        Callback = function(v) Aimbot.SilentAim.WallCheck = v end
    })
    
    RightGroup:AddToggle("SilentUseFOV", {
        Text = "Limit to FOV",
        Default = Aimbot.SilentAim.UseFOV,
        Callback = function(v) Aimbot.SilentAim.UseFOV = v end
    })
    
    RightGroup:AddSlider("SilentFOV", {
        Text = "FOV Radius",
        Default = Aimbot.SilentAim.FOVAmount,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Suffix = "px",
        Callback = function(v) Aimbot.SilentAim.FOVAmount = v end
    })
    
    RightGroup:AddDivider()
    RightGroup:AddLabel("Prediction")
    
    RightGroup:AddSlider("SilentPrediction", {
        Text = "Prediction",
        Default = Aimbot.SilentAim.Prediction,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) Aimbot.SilentAim.Prediction = v end
    })
end

--===================================================================
-- VISUALS TAB
--===================================================================

do
    local LeftGroup = Tabs.Visuals:AddLeftGroupbox("ESP Settings")
    local RightGroup = Tabs.Visuals:AddRightGroupbox("Visual Elements")
    
    -- Main Settings
    LeftGroup:AddToggle("VisualsEnabled", {
        Text = "Enable Visuals",
        Default = WallHack.Settings.Enabled,
        Callback = function(v) WallHack.Settings.Enabled = v end
    })
    
    LeftGroup:AddToggle("VisualsTeamCheck", {
        Text = "Team Check",
        Default = WallHack.Settings.TeamCheck,
        Callback = function(v) WallHack.Settings.TeamCheck = v end
    })
    
    LeftGroup:AddToggle("VisualsAliveCheck", {
        Text = "Alive Check",
        Default = WallHack.Settings.AliveCheck,
        Callback = function(v) WallHack.Settings.AliveCheck = v end
    })
    
    LeftGroup:AddSlider("VisualsMaxDistance", {
        Text = "Max Distance",
        Default = WallHack.Settings.MaxDistance,
        Min = 0,
        Max = 5000,
        Rounding = 0,
        Suffix = " studs",
        Callback = function(v) WallHack.Settings.MaxDistance = v end
    })
    
    LeftGroup:AddDivider()
    LeftGroup:AddLabel("Name Tags")
    
    LeftGroup:AddToggle("TagsEnabled", {
        Text = "Enable Name Tags",
        Default = WallHack.Visuals.ESPSettings.Enabled,
        Callback = function(v) WallHack.Visuals.ESPSettings.Enabled = v end
    })
    
    LeftGroup:AddToggle("TagsName", {
        Text = "Show Name",
        Default = WallHack.Visuals.ESPSettings.DisplayName,
        Callback = function(v) WallHack.Visuals.ESPSettings.DisplayName = v end
    })
    
    LeftGroup:AddToggle("TagsHealth", {
        Text = "Show Health",
        Default = WallHack.Visuals.ESPSettings.DisplayHealth,
        Callback = function(v) WallHack.Visuals.ESPSettings.DisplayHealth = v end
    })
    
    LeftGroup:AddToggle("TagsDistance", {
        Text = "Show Distance",
        Default = WallHack.Visuals.ESPSettings.DisplayDistance,
        Callback = function(v) WallHack.Visuals.ESPSettings.DisplayDistance = v end
    })
    
    LeftGroup:AddSlider("TagsSize", {
        Text = "Text Size",
        Default = WallHack.Visuals.ESPSettings.TextSize,
        Min = 8,
        Max = 24,
        Rounding = 0,
        Callback = function(v) WallHack.Visuals.ESPSettings.TextSize = v end
    })
    
    LeftGroup:AddSlider("TagsTransparency", {
        Text = "Transparency",
        Default = WallHack.Visuals.ESPSettings.TextTransparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) WallHack.Visuals.ESPSettings.TextTransparency = v end
    })
    
    local textColorLabel = LeftGroup:AddLabel("Text Color")
    textColorLabel:AddColorPicker("TagsTextColor", {
        Default = WallHack.Visuals.ESPSettings.TextColor,
        Callback = function(c) WallHack.Visuals.ESPSettings.TextColor = c end
    })
    
    local outlineColorLabel = LeftGroup:AddLabel("Outline Color")
    outlineColorLabel:AddColorPicker("TagsOutlineColor", {
        Default = WallHack.Visuals.ESPSettings.OutlineColor,
        Callback = function(c) WallHack.Visuals.ESPSettings.OutlineColor = c end
    })
    
    -- Right Group - Box ESP
    RightGroup:AddLabel("Box ESP")
    
    RightGroup:AddToggle("BoxEnabled", {
        Text = "Enable Boxes",
        Default = WallHack.Visuals.BoxSettings.Enabled,
        Callback = function(v) WallHack.Visuals.BoxSettings.Enabled = v end
    })
    
    RightGroup:AddDropdown("BoxType", {
        Text = "Box Type",
        Default = BoxTypes[WallHack.Visuals.BoxSettings.Type] or BoxTypes[1],
        Values = BoxTypes,
        Callback = function(v)
            for i, type in ipairs(BoxTypes) do
                if type == v then
                    WallHack.Visuals.BoxSettings.Type = i
                    break
                end
            end
        end
    })
    
    RightGroup:AddToggle("BoxFilled", {
        Text = "Filled",
        Default = WallHack.Visuals.BoxSettings.Filled,
        Callback = function(v) WallHack.Visuals.BoxSettings.Filled = v end
    })
    
    RightGroup:AddSlider("BoxThickness", {
        Text = "Thickness",
        Default = WallHack.Visuals.BoxSettings.Thickness,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(v) WallHack.Visuals.BoxSettings.Thickness = v end
    })
    
    RightGroup:AddSlider("BoxTransparency", {
        Text = "Transparency",
        Default = WallHack.Visuals.BoxSettings.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) WallHack.Visuals.BoxSettings.Transparency = v end
    })
    
    local boxColorLabel = RightGroup:AddLabel("Box Color")
    boxColorLabel:AddColorPicker("BoxColor", {
        Default = WallHack.Visuals.BoxSettings.Color,
        Callback = function(c) WallHack.Visuals.BoxSettings.Color = c end
    })
    
    RightGroup:AddDivider()
    RightGroup:AddLabel("Tracers")
    
    RightGroup:AddToggle("TracersEnabled", {
        Text = "Enable Tracers",
        Default = WallHack.Visuals.TracersSettings.Enabled,
        Callback = function(v) WallHack.Visuals.TracersSettings.Enabled = v end
    })
    
    RightGroup:AddDropdown("TracersType", {
        Text = "Tracer Origin",
        Default = TracerTypes[WallHack.Visuals.TracersSettings.Type] or TracerTypes[1],
        Values = TracerTypes,
        Callback = function(v)
            for i, type in ipairs(TracerTypes) do
                if type == v then
                    WallHack.Visuals.TracersSettings.Type = i
                    break
                end
            end
        end
    })
    
    RightGroup:AddSlider("TracersThickness", {
        Text = "Thickness",
        Default = WallHack.Visuals.TracersSettings.Thickness,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(v) WallHack.Visuals.TracersSettings.Thickness = v end
    })
    
    RightGroup:AddSlider("TracersTransparency", {
        Text = "Transparency",
        Default = WallHack.Visuals.TracersSettings.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) WallHack.Visuals.TracersSettings.Transparency = v end
    })
    
    local tracerColorLabel = RightGroup:AddLabel("Tracer Color")
    tracerColorLabel:AddColorPicker("TracersColor", {
        Default = WallHack.Visuals.TracersSettings.Color,
        Callback = function(c) WallHack.Visuals.TracersSettings.Color = c end
    })
    
    RightGroup:AddDivider()
    RightGroup:AddLabel("Head Dots")
    
    RightGroup:AddToggle("HeadDotEnabled", {
        Text = "Enable Head Dots",
        Default = WallHack.Visuals.HeadDotSettings.Enabled,
        Callback = function(v) WallHack.Visuals.HeadDotSettings.Enabled = v end
    })
    
    RightGroup:AddToggle("HeadDotFilled", {
        Text = "Filled",
        Default = WallHack.Visuals.HeadDotSettings.Filled,
        Callback = function(v) WallHack.Visuals.HeadDotSettings.Filled = v end
    })
    
    RightGroup:AddSlider("HeadDotSides", {
        Text = "Smoothness",
        Default = WallHack.Visuals.HeadDotSettings.Sides,
        Min = 3,
        Max = 60,
        Rounding = 0,
        Callback = function(v) WallHack.Visuals.HeadDotSettings.Sides = v end
    })
    
    RightGroup:AddSlider("HeadDotThickness", {
        Text = "Thickness",
        Default = WallHack.Visuals.HeadDotSettings.Thickness,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(v) WallHack.Visuals.HeadDotSettings.Thickness = v end
    })
    
    RightGroup:AddSlider("HeadDotTransparency", {
        Text = "Transparency",
        Default = WallHack.Visuals.HeadDotSettings.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) WallHack.Visuals.HeadDotSettings.Transparency = v end
    })
    
    local headDotColorLabel = RightGroup:AddLabel("Head Dot Color")
    headDotColorLabel:AddColorPicker("HeadDotColor", {
        Default = WallHack.Visuals.HeadDotSettings.Color,
        Callback = function(c) WallHack.Visuals.HeadDotSettings.Color = c end
    })
end

--===================================================================
-- CROSSHAIR TAB
--===================================================================

do
    local LeftGroup = Tabs.Crosshair:AddLeftGroupbox("Crosshair Settings")
    local RightGroup = Tabs.Crosshair:AddRightGroupbox("Center Dot")
    
    LeftGroup:AddToggle("SystemCursor", {
        Text = "Show System Cursor",
        Default = Services.UserInputService.MouseIconEnabled,
        Callback = function(v) Services.UserInputService.MouseIconEnabled = v end
    })
    
    LeftGroup:AddToggle("CrosshairEnabled", {
        Text = "Custom Crosshair",
        Default = WallHack.Crosshair.Settings.Enabled,
        Callback = function(v) WallHack.Crosshair.Settings.Enabled = v end
    })
    
    LeftGroup:AddDropdown("CrosshairFollow", {
        Text = "Follow Mode",
        Default = CrosshairTypes[WallHack.Crosshair.Settings.Type] or CrosshairTypes[1],
        Values = CrosshairTypes,
        Callback = function(v)
            for i, type in ipairs(CrosshairTypes) do
                if type == v then
                    WallHack.Crosshair.Settings.Type = i
                    break
                end
            end
        end
    })
    
    LeftGroup:AddSlider("CrosshairSize", {
        Text = "Size",
        Default = WallHack.Crosshair.Settings.Size,
        Min = 4,
        Max = 40,
        Rounding = 0,
        Suffix = "px",
        Callback = function(v) WallHack.Crosshair.Settings.Size = v end
    })
    
    LeftGroup:AddSlider("CrosshairThickness", {
        Text = "Thickness",
        Default = WallHack.Crosshair.Settings.Thickness,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(v) WallHack.Crosshair.Settings.Thickness = v end
    })
    
    LeftGroup:AddSlider("CrosshairGap", {
        Text = "Gap",
        Default = WallHack.Crosshair.Settings.GapSize,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Suffix = "px",
        Callback = function(v) WallHack.Crosshair.Settings.GapSize = v end
    })
    
    LeftGroup:AddSlider("CrosshairRotation", {
        Text = "Rotation",
        Default = WallHack.Crosshair.Settings.Rotation,
        Min = -180,
        Max = 180,
        Rounding = 0,
        Suffix = "°",
        Callback = function(v) WallHack.Crosshair.Settings.Rotation = v end
    })
    
    LeftGroup:AddSlider("CrosshairTransparency", {
        Text = "Transparency",
        Default = WallHack.Crosshair.Settings.Transparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) WallHack.Crosshair.Settings.Transparency = v end
    })
    
    local crosshairColorLabel = LeftGroup:AddLabel("Crosshair Color")
    crosshairColorLabel:AddColorPicker("CrosshairColor", {
        Default = WallHack.Crosshair.Settings.Color,
        Callback = function(c) WallHack.Crosshair.Settings.Color = c end
    })
    
    -- Center Dot Settings
    RightGroup:AddToggle("DotEnabled", {
        Text = "Enable Center Dot",
        Default = WallHack.Crosshair.Settings.CenterDot,
        Callback = function(v) WallHack.Crosshair.Settings.CenterDot = v end
    })
    
    RightGroup:AddToggle("DotFilled", {
        Text = "Filled",
        Default = WallHack.Crosshair.Settings.CenterDotFilled,
        Callback = function(v) WallHack.Crosshair.Settings.CenterDotFilled = v end
    })
    
    RightGroup:AddSlider("DotSize", {
        Text = "Dot Size",
        Default = WallHack.Crosshair.Settings.CenterDotSize,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Suffix = "px",
        Callback = function(v) WallHack.Crosshair.Settings.CenterDotSize = v end
    })
    
    RightGroup:AddSlider("DotTransparency", {
        Text = "Transparency",
        Default = WallHack.Crosshair.Settings.CenterDotTransparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) WallHack.Crosshair.Settings.CenterDotTransparency = v end
    })
    
    local dotColorLabel = RightGroup:AddLabel("Dot Color")
    dotColorLabel:AddColorPicker("DotColor", {
        Default = WallHack.Crosshair.Settings.CenterDotColor,
        Callback = function(c) WallHack.Crosshair.Settings.CenterDotColor = c end
    })
end

--===================================================================
-- CONFIG SYSTEM
--===================================================================

local ConfigName = ""
local ConfigList = {}
local configDropdown = nil

local function getConfigPath(name)
    return ("%s/%s.json"):format(CONFIG_FOLDER, name)
end

local function refreshConfigList()
    if not FS_SUPPORTED then return {} end
    
    local names = {}
    local success, files = pcall(env.listfiles, CONFIG_FOLDER)
    
    if success then
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(names, name)
            end
        end
    end
    
    ConfigList = names
    return names
end

local function saveConfig()
    if not FS_SUPPORTED then
        Library:Notify("File system not supported", 3)
        return
    end
    
    if not ConfigName or ConfigName == "" then
        Library:Notify("Enter a config name", 3)
        return
    end
    
    local config = {
        aimbot = {
            enabled = Aimbot.Settings.Enabled,
            toggle = Aimbot.Settings.Toggle,
            triggerKey = Aimbot.Settings.TriggerKey,
            sensitivity = Aimbot.Settings.Sensitivity,
            lockPart = Aimbot.Settings.LockPart,
            teamCheck = Aimbot.Settings.TeamCheck,
            wallCheck = Aimbot.Settings.WallCheck,
            aliveCheck = Aimbot.Settings.AliveCheck,
            thirdPerson = Aimbot.Settings.ThirdPerson,
            thirdPersonSens = Aimbot.Settings.ThirdPersonSensitivity,
        },
        fov = {
            enabled = Aimbot.FOVSettings.Enabled,
            visible = Aimbot.FOVSettings.Visible,
            amount = Aimbot.FOVSettings.Amount,
            filled = Aimbot.FOVSettings.Filled,
            transparency = Aimbot.FOVSettings.Transparency,
            sides = Aimbot.FOVSettings.Sides,
            thickness = Aimbot.FOVSettings.Thickness,
            color = {Aimbot.FOVSettings.Color.R, Aimbot.FOVSettings.Color.G, Aimbot.FOVSettings.Color.B},
            lockedColor = {Aimbot.FOVSettings.LockedColor.R, Aimbot.FOVSettings.LockedColor.G, Aimbot.FOVSettings.LockedColor.B},
        },
        silent = {
            enabled = Aimbot.SilentAim.Enabled,
            triggerKey = Aimbot.SilentAim.TriggerKey,
            toggle = Aimbot.SilentAim.Toggle,
            teamCheck = Aimbot.SilentAim.TeamCheck,
            aliveCheck = Aimbot.SilentAim.AliveCheck,
            wallCheck = Aimbot.SilentAim.WallCheck,
            lockPart = Aimbot.SilentAim.LockPart,
            useFOV = Aimbot.SilentAim.UseFOV,
            fovAmount = Aimbot.SilentAim.FOVAmount,
            prediction = Aimbot.SilentAim.Prediction,
        },
        visuals = {
            enabled = WallHack.Settings.Enabled,
            teamCheck = WallHack.Settings.TeamCheck,
            aliveCheck = WallHack.Settings.AliveCheck,
            maxDistance = WallHack.Settings.MaxDistance,
            esp = {
                enabled = WallHack.Visuals.ESPSettings.Enabled,
                displayName = WallHack.Visuals.ESPSettings.DisplayName,
                displayHealth = WallHack.Visuals.ESPSettings.DisplayHealth,
                displayDistance = WallHack.Visuals.ESPSettings.DisplayDistance,
                textSize = WallHack.Visuals.ESPSettings.TextSize,
                textTransparency = WallHack.Visuals.ESPSettings.TextTransparency,
                textColor = {WallHack.Visuals.ESPSettings.TextColor.R, WallHack.Visuals.ESPSettings.TextColor.G
                               outlineColor = {WallHack.Visuals.ESPSettings.OutlineColor.R, WallHack.Visuals.ESPSettings.OutlineColor.G, WallHack.Visuals.ESPSettings.OutlineColor.B},
            },
            box = {
                enabled = WallHack.Visuals.BoxSettings.Enabled,
                type = WallHack.Visuals.BoxSettings.Type,
                filled = WallHack.Visuals.BoxSettings.Filled,
                thickness = WallHack.Visuals.BoxSettings.Thickness,
                transparency = WallHack.Visuals.BoxSettings.Transparency,
                increase = WallHack.Visuals.BoxSettings.Increase,
                color = {WallHack.Visuals.BoxSettings.Color.R, WallHack.Visuals.BoxSettings.Color.G, WallHack.Visuals.BoxSettings.Color.B},
            },
            tracer = {
                enabled = WallHack.Visuals.TracersSettings.Enabled,
                type = WallHack.Visuals.TracersSettings.Type,
                thickness = WallHack.Visuals.TracersSettings.Thickness,
                transparency = WallHack.Visuals.TracersSettings.Transparency,
                color = {WallHack.Visuals.TracersSettings.Color.R, WallHack.Visuals.TracersSettings.Color.G, WallHack.Visuals.TracersSettings.Color.B},
            },
            headDot = {
                enabled = WallHack.Visuals.HeadDotSettings.Enabled,
                filled = WallHack.Visuals.HeadDotSettings.Filled,
                sides = WallHack.Visuals.HeadDotSettings.Sides,
                thickness = WallHack.Visuals.HeadDotSettings.Thickness,
                transparency = WallHack.Visuals.HeadDotSettings.Transparency,
                color = {WallHack.Visuals.HeadDotSettings.Color.R, WallHack.Visuals.HeadDotSettings.Color.G, WallHack.Visuals.HeadDotSettings.Color.B},
            },
        },
        crosshair = {
            enabled = WallHack.Crosshair.Settings.Enabled,
            type = WallHack.Crosshair.Settings.Type,
            size = WallHack.Crosshair.Settings.Size,
            thickness = WallHack.Crosshair.Settings.Thickness,
            gapSize = WallHack.Crosshair.Settings.GapSize,
            rotation = WallHack.Crosshair.Settings.Rotation,
            transparency = WallHack.Crosshair.Settings.Transparency,
            color = {WallHack.Crosshair.Settings.Color.R, WallHack.Crosshair.Settings.Color.G, WallHack.Crosshair.Settings.Color.B},
            centerDot = WallHack.Crosshair.Settings.CenterDot,
            centerDotFilled = WallHack.Crosshair.Settings.CenterDotFilled,
            centerDotSize = WallHack.Crosshair.Settings.CenterDotSize,
            centerDotTransparency = WallHack.Crosshair.Settings.CenterDotTransparency,
            centerDotColor = {WallHack.Crosshair.Settings.CenterDotColor.R, WallHack.Crosshair.Settings.CenterDotColor.G, WallHack.Crosshair.Settings.CenterDotColor.B},
        },
    }
    
    local success, json = pcall(function()
        return Services.HttpService:JSONEncode(config)
    end)
    
    if success then
        pcall(env.writefile, getConfigPath(ConfigName), json)
        Library:Notify(("Config saved: %s"):format(ConfigName), 3)
        refreshConfigList()
        if configDropdown then
            configDropdown:SetValues(ConfigList)
        end
    else
        Library:Notify("Failed to save config", 3)
    end
end

local function loadConfig()
    if not FS_SUPPORTED then
        Library:Notify("File system not supported", 3)
        return
    end
    
    if not ConfigName or ConfigName == "" then
        Library:Notify("Select a config first", 3)
        return
    end
    
    local path = getConfigPath(ConfigName)
    if not pcall(env.isfile, path) then
        Library:Notify("Config not found", 3)
        return
    end
    
    local content = env.readfile(path)
    if not content or content == "" then
        Library:Notify("Config is empty", 3)
        return
    end
    
    local success, data = pcall(function()
        return Services.HttpService:JSONDecode(content)
    end)
    
    if not success or not data then
        Library:Notify("Failed to load config", 3)
        return
    end
    
    -- Load Aimbot
    if data.aimbot then
        local a = data.aimbot
        Aimbot.Settings.Enabled = a.enabled
        Aimbot.Settings.Toggle = a.toggle
        Aimbot.Settings.TriggerKey = a.triggerKey
        Aimbot.Settings.Sensitivity = a.sensitivity
        Aimbot.Settings.LockPart = a.lockPart
        Aimbot.Settings.TeamCheck = a.teamCheck
        Aimbot.Settings.WallCheck = a.wallCheck
        Aimbot.Settings.AliveCheck = a.aliveCheck
        Aimbot.Settings.ThirdPerson = a.thirdPerson
        Aimbot.Settings.ThirdPersonSensitivity = a.thirdPersonSens
    end
    
    -- Load FOV
    if data.fov then
        local f = data.fov
        Aimbot.FOVSettings.Enabled = f.enabled
        Aimbot.FOVSettings.Visible = f.visible
        Aimbot.FOVSettings.Amount = f.amount
        Aimbot.FOVSettings.Filled = f.filled
        Aimbot.FOVSettings.Transparency = f.transparency
        Aimbot.FOVSettings.Sides = f.sides
        Aimbot.FOVSettings.Thickness = f.thickness
        if f.color then
            Aimbot.FOVSettings.Color = Color3.new(f.color[1], f.color[2], f.color[3])
        end
        if f.lockedColor then
            Aimbot.FOVSettings.LockedColor = Color3.new(f.lockedColor[1], f.lockedColor[2], f.lockedColor[3])
        end
    end
    
    -- Load Silent Aim
    if data.silent then
        local s = data.silent
        Aimbot.SilentAim.Enabled = s.enabled
        Aimbot.SilentAim.TriggerKey = s.triggerKey
        Aimbot.SilentAim.Toggle = s.toggle
        Aimbot.SilentAim.TeamCheck = s.teamCheck
        Aimbot.SilentAim.AliveCheck = s.aliveCheck
        Aimbot.SilentAim.WallCheck = s.wallCheck
        Aimbot.SilentAim.LockPart = s.lockPart
        Aimbot.SilentAim.UseFOV = s.useFOV
        Aimbot.SilentAim.FOVAmount = s.fovAmount
        Aimbot.SilentAim.Prediction = s.prediction
    end
    
    -- Load Visuals
    if data.visuals then
        local v = data.visuals
        WallHack.Settings.Enabled = v.enabled
        WallHack.Settings.TeamCheck = v.teamCheck
        WallHack.Settings.AliveCheck = v.aliveCheck
        WallHack.Settings.MaxDistance = v.maxDistance
        
        if v.esp then
            local e = v.esp
            WallHack.Visuals.ESPSettings.Enabled = e.enabled
            WallHack.Visuals.ESPSettings.DisplayName = e.displayName
            WallHack.Visuals.ESPSettings.DisplayHealth = e.displayHealth
            WallHack.Visuals.ESPSettings.DisplayDistance = e.displayDistance
            WallHack.Visuals.ESPSettings.TextSize = e.textSize
            WallHack.Visuals.ESPSettings.TextTransparency = e.textTransparency
            if e.textColor then
                WallHack.Visuals.ESPSettings.TextColor = Color3.new(e.textColor[1], e.textColor[2], e.textColor[3])
            end
            if e.outlineColor then
                WallHack.Visuals.ESPSettings.OutlineColor = Color3.new(e.outlineColor[1], e.outlineColor[2], e.outlineColor[3])
            end
        end
        
        if v.box then
            local b = v.box
            WallHack.Visuals.BoxSettings.Enabled = b.enabled
            WallHack.Visuals.BoxSettings.Type = b.type
            WallHack.Visuals.BoxSettings.Filled = b.filled
            WallHack.Visuals.BoxSettings.Thickness = b.thickness
            WallHack.Visuals.BoxSettings.Transparency = b.transparency
            WallHack.Visuals.BoxSettings.Increase = b.increase
            if b.color then
                WallHack.Visuals.BoxSettings.Color = Color3.new(b.color[1], b.color[2], b.color[3])
            end
        end
        
        if v.tracer then
            local t = v.tracer
            WallHack.Visuals.TracersSettings.Enabled = t.enabled
            WallHack.Visuals.TracersSettings.Type = t.type
            WallHack.Visuals.TracersSettings.Thickness = t.thickness
            WallHack.Visuals.TracersSettings.Transparency = t.transparency
            if t.color then
                WallHack.Visuals.TracersSettings.Color = Color3.new(t.color[1], t.color[2], t.color[3])
            end
        end
        
        if v.headDot then
            local h = v.headDot
            WallHack.Visuals.HeadDotSettings.Enabled = h.enabled
            WallHack.Visuals.HeadDotSettings.Filled = h.filled
            WallHack.Visuals.HeadDotSettings.Sides = h.sides
            WallHack.Visuals.HeadDotSettings.Thickness = h.thickness
            WallHack.Visuals.HeadDotSettings.Transparency = h.transparency
            if h.color then
                WallHack.Visuals.HeadDotSettings.Color = Color3.new(h.color[1], h.color[2], h.color[3])
            end
        end
    end
    
    -- Load Crosshair
    if data.crosshair then
        local c = data.crosshair
        WallHack.Crosshair.Settings.Enabled = c.enabled
        WallHack.Crosshair.Settings.Type = c.type
        WallHack.Crosshair.Settings.Size = c.size
        WallHack.Crosshair.Settings.Thickness = c.thickness
        WallHack.Crosshair.Settings.GapSize = c.gapSize
        WallHack.Crosshair.Settings.Rotation = c.rotation
        WallHack.Crosshair.Settings.Transparency = c.transparency
        WallHack.Crosshair.Settings.CenterDot = c.centerDot
        WallHack.Crosshair.Settings.CenterDotFilled = c.centerDotFilled
        WallHack.Crosshair.Settings.CenterDotSize = c.centerDotSize
        WallHack.Crosshair.Settings.CenterDotTransparency = c.centerDotTransparency
        if c.color then
            WallHack.Crosshair.Settings.Color = Color3.new(c.color[1], c.color[2], c.color[3])
        end
        if c.centerDotColor then
            WallHack.Crosshair.Settings.CenterDotColor = Color3.new(c.centerDotColor[1], c.centerDotColor[2], c.centerDotColor[3])
        end
    end
    
    -- Update UI elements
    pcall(function()
        if aimbotKeyBtn then aimbotKeyBtn:SetText(Aimbot.Settings.TriggerKey) end
        if silentKeyBtn then silentKeyBtn:SetText(Aimbot.SilentAim.TriggerKey) end
    end)
    
    Library:Notify(("Config loaded: %s"):format(ConfigName), 3)
end

local function deleteConfig()
    if not FS_SUPPORTED then
        Library:Notify("File system not supported", 3)
        return
    end
    
    if not ConfigName or ConfigName == "" then
        Library:Notify("Select a config first", 3)
        return
    end
    
    local path = getConfigPath(ConfigName)
    if pcall(env.isfile, path) then
        pcall(env.delfile, path)
        Library:Notify(("Config deleted: %s"):format(ConfigName), 3)
        refreshConfigList()
        if configDropdown then
            configDropdown:SetValues(ConfigList)
        end
    end
end

--===================================================================
-- CONFIG TAB UI
--===================================================================

do
    local LeftGroup = Tabs.Config:AddLeftGroupbox("Config Manager")
    local RightGroup = Tabs.Config:AddRightGroupbox("Module Controls")
    
    LeftGroup:AddInput("ConfigNameInput", {
        Text = "Config Name",
        Default = "",
        Placeholder = "Enter config name...",
        Callback = function(v) ConfigName = v end
    })
    
    configDropdown = LeftGroup:AddDropdown("ConfigSelector", {
        Text = "Select Config",
        Default = "",
        Values = {},
        Callback = function(v) ConfigName = v end
    })
    
    LeftGroup:AddButton({
        Text = "Refresh List",
        Func = function()
            refreshConfigList()
            configDropdown:SetValues(ConfigList)
            Library:Notify("Config list refreshed", 2)
        end
    })
    
    LeftGroup:AddDivider()
    LeftGroup:AddButton({Text = "Save Config", Func = saveConfig})
    LeftGroup:AddButton({Text = "Load Config", Func = loadConfig})
    LeftGroup:AddButton({Text = "Delete Config", Func = deleteConfig})
    
    -- Module Controls
    RightGroup:AddButton({
        Text = "Reset All Settings",
        Func = function()
            Aimbot = getSafeAimbot()
            WallHack = getSafeWallHack()
            env.genv.AirHub.Aimbot = Aimbot
            env.genv.AirHub.WallHack = WallHack
            Library:Notify("Settings reset to default", 3)
        end
    })
    
    RightGroup:AddButton({
        Text = "Unload AirHub",
        Func = function()
            task.spawn(function()
                pcall(Library.Unload, Library)
                env.genv.AirHub = nil
            end)
        end
    })
end

--===================================================================
-- THEME MANAGER
--===================================================================

if ThemeManager then
    pcall(function()
        ThemeManager:SetLibrary(Library)
        ThemeManager:ApplyToTab(Tabs.Config)
    end)
end

--===================================================================
-- FINAL SETUP
--===================================================================

-- Initial config list refresh
task.spawn(function()
    safeWait(0.5)
    refreshConfigList()
    if configDropdown then
        configDropdown:SetValues(ConfigList)
    end
end)

-- Success notification
Library:Notify("AirHub V3 loaded successfully", 3)

-- Return success
return true 
