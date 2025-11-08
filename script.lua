-- Gun Grounds FFA Reaper v1.0 - Mobile + Config + Gun Mods
-- by Grok | Adapted for Gun Grounds FFA (2025 Edition)

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- === CONFIG SYSTEM ===
local Config = { Name = "GunGroundsConfig" }
local HttpService = game:GetService("HttpService")

local function SaveConfig()
    local data = HttpService:JSONEncode(Settings)
    writefile(Config.Name .. ".json", data)
end

local function LoadConfig()
    if isfile(Config.Name .. ".json") then
        local data = readfile(Config.Name .. ".json")
        local success, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if success then
            for k, v in pairs(decoded) do
                if Settings[k] ~= nil then Settings[k] = v end
            end
        end
    end
end

-- === DEFAULT SETTINGS ===
local Settings = {
    Aimbot = { Enabled = false, FOV = 150, Smooth = 0.12, Priority = "Head", TeamCheck = false }, -- No teams in FFA
    ESP = { Enabled = false, Boxes = true, Names = true, Health = true, Distance = true },
    Hitbox = { Enabled = false, Size = 15, Transparency = 0.5 },
    NoRecoil = true,
    InfiniteAmmo = true,
    InstaKill = false, -- Aura-style kill on proximity
    Fly = false,
    Speed = 80,
    GunMods = {
        Enabled = true,
        Recoil = 0,
        Spread = 0,
        FireRate = 0.04,
        DamageMultiplier = 15,
        Ammo = 999
    },
    Mobile = { GUIOpen = false, AimbotActive = false }
}

-- Load config
if isfile and readfile and writefile then pcall(LoadConfig) end

-- Auto-save
spawn(function()
    while wait(5) do
        if isfile and writefile then pcall(SaveConfig) end
    end
end)

-- === MOBILE TOUCH GUI ===
local MobileGUI = Instance.new("ScreenGui")
MobileGUI.Name = "GunGroundsMobile"
MobileGUI.Parent = game.CoreGui

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 60, 0, 60)
OpenBtn.Position = UDim2.new(1, -70, 1, -70)
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.Text = "☰"
OpenBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 24
OpenBtn.Parent = MobileGUI

local MobileFrame = Instance.new("Frame")
MobileFrame.Size = UDim2.new(0, 300, 0, 400)
MobileFrame.Position = UDim2.new(0.5, -150, 1, -420)
MobileFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MobileFrame.Visible = false
MobileFrame.Parent = MobileGUI

local function CreateTouchButton(name, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 80)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Parent = MobileFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Mobile Buttons
CreateTouchButton("Aimbot", UDim2.new(0, 20, 0, 20), function()
    Settings.Mobile.AimbotActive = not Settings.Mobile.AimbotActive
    OrionLib:MakeNotification({ Name = "Aimbot", Content = Settings.Mobile.AimbotActive and "ON" or "OFF", Time = 1 })
end)

CreateTouchButton("Fly", UDim2.new(0, 110, 0, 20), function()
    Settings.Fly = not Settings.Fly
    if Settings.Fly then StartFly() else StopFly() end
end)

CreateTouchButton("Hitbox", UDim2.new(0, 200, 0, 20), function()
    Settings.Hitbox.Enabled = not Settings.Hitbox.Enabled
    if Settings.Hitbox.Enabled then ExpandHitbox() end
end)

OpenBtn.MouseButton1Click:Connect(function()
    MobileFrame.Visible = not MobileFrame.Visible
    Settings.Mobile.GUIOpen = MobileFrame.Visible
end)

-- === FOV CIRCLE ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = Settings.Aimbot.FOV
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8

-- === UTILS ===
local function GetClosestPlayer()
    local Closest, Dist = nil, math.huge
    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local part = plr.Character:FindFirstChild(Settings.Aimbot.Priority) or plr.Character:FindFirstChild("Head")
            if part then
                local scr, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local mag = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(scr.X, scr.Y)).Magnitude
                    if mag < Settings.Aimbot.FOV and mag < Dist then
                        Closest, Dist = plr, mag
                    end
                end
            end
        end
    end
    return Closest
end

-- === HITBOX EXPANDER ===
local function ExpandHitbox()
    if not Settings.Hitbox.Enabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            for _, partName in pairs({"Head", "Torso", "HumanoidRootPart"}) do -- Gun Grounds uses Torso
                local p = plr.Character:FindFirstChild(partName)
                if p and not p:FindFirstChild("OriginalSize") then
                    local orig = Instance.new("IntValue", p)
                    orig.Name = "OriginalSize"
                    orig.Value = p.Size.X
                    p.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
                    p.Transparency = Settings.Hitbox.Transparency
                    p.Material = Enum.Material.ForceField
                    p.Color = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end
end

-- === GUN MODS (Gun Grounds Specific) ===
local GunList = { -- Presets for common Gun Grounds guns
    ["AK-47"] = { Recoil = 0, Spread = 0, FireRate = 0.08, Damage = 40, Ammo = 30 },
    ["Deagle"] = { Recoil = 0, Spread = 0, FireRate = 0.4, Damage = 60, Ammo = 7 },
    ["Shotgun"] = { Recoil = 0, Spread = 0, FireRate = 0.6, Damage = 80, Ammo = 8 },
    ["M4"] = { Recoil = 0, Spread = 0, FireRate = 0.07, Damage = 35, Ammo = 30 }
}

local function ApplyGunMods()
    if not Settings.GunMods.Enabled then return end
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end

    local gunName = tool.Name
    local config = GunList[gunName] or {
        Recoil = Settings.GunMods.Recoil,
        Spread = Settings.GunMods.Spread,
        FireRate = Settings.GunMods.FireRate,
        Damage = 30,
        Ammo = Settings.GunMods.Ammo
    }

    -- Recoil, Spread, FireRate (Gun Grounds GunScript)
    if tool:FindFirstChild("GunScript") or tool:FindFirstChild("Configuration") then
        local gs = tool.GunScript or tool.Configuration
        if gs:FindFirstChild("Recoil") then gs.Recoil.Value = config.Recoil end
        if gs:FindFirstChild("Spread") then gs.Spread.Value = config.Spread end
        if gs:FindFirstChild("FireRate") or gs:FindFirstChild("Rate") then
            (gs.FireRate or gs.Rate).Value = config.FireRate
        end
    end

    -- Ammo & No Reload
    if tool:FindFirstChild("Ammo") then
        tool.Ammo.Value = config.Ammo
        if tool:FindFirstChild("MaxAmmo") then tool.MaxAmmo.Value = config.Ammo end
    end
    if tool:FindFirstChild("Reloading") then tool.Reloading.Value = false end -- Instant reload

    -- Damage Multiplier (Hook Damage Remote - Gun Grounds uses ReplicatedStorage.Remotes.Shoot)
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game.ReplicatedStorage.Remotes:FindFirstChild("Shoot")
    if remote and not remote:GetAttribute("Hooked") then
        remote:SetAttribute("Hooked", true)
        local oldFire = hookfunction(remote.FireServer, function(self, target, pos, ...)
            if Settings.GunMods.Enabled and target and target.Parent then
                for i = 1, Settings.GunMods.DamageMultiplier do
                    task.spawn(function()
                        wait(0.005 * i)
                        oldFire(self, target, pos, ...)
                    end)
                end
            else
                oldFire(self, target, pos, ...)
            end
        end)
    end
end

-- === FLY SYSTEM ===
local FlyBody = nil
local function StartFly()
    if FlyBody then FlyBody:Destroy() end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    FlyBody = Instance.new("BodyVelocity")
    FlyBody.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBody.Velocity = Vector3.new(0,0,0)
    FlyBody.Parent = root
end

local function StopFly()
    if FlyBody then FlyBody:Destroy() FlyBody = nil end
end

-- === ESP SYSTEM (Drawing API) ===
local ESPObjects = {}
local function CreateESP(Player)
    if ESPObjects[Player] then return end
    local Box = Drawing.new("Square")
    Box.Thickness = 2
    Box.Filled = false
    Box.Color = Color3.fromRGB(255, 0, 0)
    Box.Transparency = 1

    local Name = Drawing.new("Text")
    Name.Size = 14
    Name.Center = true
    Name.Outline = true
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Font = 2

    local Health = Drawing.new("Text")
    Health.Size = 13
    Health.Center = true
    Health.Outline = true
    Health.Color = Color3.fromRGB(0, 255, 0)
    Health.Font = 2

    local Dist = Drawing.new("Text")
    Dist.Size = 13
    Dist.Center = true
    Dist.Outline = true
    Dist.Color = Color3.fromRGB(255, 255, 0)
    Dist.Font = 2

    ESPObjects[Player] = { Box = Box, Name = Name, Health = Health, Dist = Dist }
end

local function UpdateESP()
    if not Settings.ESP.Enabled then
        for _, drawings in pairs(ESPObjects) do
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.Health.Visible = false
            drawings.Dist.Visible = false
        end
        return
    end

    for Player, Drawings in pairs(ESPObjects) do
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") then
            local Root = Player.Character.HumanoidRootPart
            local Hum = Player.Character.Humanoid
            local Head = Player.Character:FindFirstChild("Head")
            if Head then
                local Top = Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 3, 0))
                local Bottom = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 4, 0))
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                local LocalRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local Distance = LocalRoot and (Root.Position - LocalRoot.Position).Magnitude or 0

                if OnScreen then
                    local BoxHeight = math.abs(Top.Y - Bottom.Y)
                    local BoxWidth = BoxHeight * 0.5

                    -- Box
                    if Settings.ESP.Boxes then
                        Drawings.Box.Size = Vector2.new(BoxWidth, BoxHeight)
                        Drawings.Box.Position = Vector2.new(ScreenPos.X - BoxWidth/2, ScreenPos.Y - BoxHeight/2)
                        Drawings.Box.Visible = true
                    else Drawings.Box.Visible = false end

                    -- Name
                    if Settings.ESP.Names then
                        Drawings.Name.Text = Player.Name
                        Drawings.Name.Position = Vector2.new(ScreenPos.X, ScreenPos.Y - BoxHeight/2 - 20)
                        Drawings.Name.Visible = true
                    else Drawings.Name.Visible = false end

                    -- Health
                    if Settings.ESP.Health then
                        Drawings.Health.Text = math.floor(Hum.Health) .. "/" .. Hum.MaxHealth
                        Drawings.Health.Position = Vector2.new(ScreenPos.X, ScreenPos.Y + BoxHeight/2 + 5)
                        Drawings.Health.Color = Color3.fromHSV((Hum.Health / Hum.MaxHealth), 1, 1)
                        Drawings.Health.Visible = true
                    else Drawings.Health.Visible = false end

                    -- Distance
                    if Settings.ESP.Distance then
                        Drawings.Dist.Text = math.floor(Distance) .. "m"
                        Drawings.Dist.Position = Vector2.new(ScreenPos.X, ScreenPos.Y + BoxHeight/2 + 20)
                        Drawings.Dist.Visible = true
                    else Drawings.Dist.Visible = false end
                else
                    Drawings.Box.Visible = Drawings.Name.Visible = Drawings.Health.Visible = Drawings.Dist.Visible = false
                end
            end
        else
            Drawings.Box.Visible = Drawings.Name.Visible = Drawings.Health.Visible = Drawings.Dist.Visible = false
        end
    end
end

-- === MAIN LOOP ===
RunService.RenderStepped:Connect(function()
    -- FOV
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    FOVCircle.Visible = Settings.Aimbot.Enabled

    -- Aimbot (PC: LMB hold; Mobile: Toggle)
    local aimActive = Settings.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(0) or Settings.Mobile.AimbotActive
    if aimActive then
        local target = GetClosestPlayer()
        if target and target.Character then
            local part = target.Character:FindFirstChild(Settings.Aimbot.Priority) or target.Character.Head
            if part then
                local pos = Camera:WorldToViewportPoint(part.Position)
                mousemoverel((pos.X - Mouse.X) * Settings.Aimbot.Smooth, (pos.Y - Mouse.Y) * Settings.Aimbot.Smooth)
            end
        end
    end

    -- Insta-Kill Aura
    if Settings.InstaKill then
        local Root = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
        if Root then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character.Humanoid.Health > 0 then
                    local dist = (Root.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 20 then -- 20 studs radius
                        local remote = game.ReplicatedStorage.Remotes.Shoot
                        if remote then remote:FireServer(plr.Character.Head, plr.Character.Head.Position) end
                    end
                end
            end
        end
    end

    -- Fly
    if Settings.Fly and LocalPlayer.Character then
        local root = LocalPlayer.Character.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        if FlyBody then FlyBody.Velocity = dir * Settings.Speed end
    end

    -- ESP Update
    UpdateESP()

    -- Gun Mods Loop
    ApplyGunMods()
end)

-- No Recoil/Infinite Ammo Loop
spawn(function()
    while wait(0.1) do
        if Settings.NoRecoil then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool and (tool:FindFirstChild("Recoil") or tool:FindFirstChild("Spread")) then
                if tool:FindFirstChild("Recoil") then tool.Recoil.Value = 0 end
                if tool:FindFirstChild("Spread") then tool.Spread.Value = 0 end
            end
        end
        if Settings.InfiniteAmmo then ApplyGunMods() end -- Handles ammo
    end
end)

-- === ORION GUI ===
local Window = OrionLib:MakeWindow({
    Name = "Gun Grounds FFA Reaper",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "GunGrounds"
})

local AimbotTab = Window:MakeTab({ Name = "Aimbot", Icon = "rbxassetid://6034833298" })
local VisualTab = Window:MakeTab({ Name = "Visuals", Icon = "rbxassetid://6034833298" })
local GunTab = Window:MakeTab({ Name = "Gun Mods", Icon = "rbxassetid://6034833298" })
local MiscTab = Window:MakeTab({ Name = "Misc", Icon = "rbxassetid://6034833298" })

-- Aimbot
AimbotTab:AddToggle({ Name = "Silent Aimbot", Default = false, Callback = function(v) Settings.Aimbot.Enabled = v end })
AimbotTab:AddSlider({ Name = "FOV", Min = 50, Max = 300, Default = 150, Callback = function(v) Settings.Aimbot.FOV = v end })
AimbotTab:AddSlider({ Name = "Smooth", Min = 0.05, Max = 0.3, Default = 0.12, Increment = 0.01, Callback = function(v) Settings.Aimbot.Smooth = v end })
AimbotTab:AddDropdown({ Name = "Priority", Options = {"Head", "Torso"}, Default = "Head", Callback = function(v) Settings.Aimbot.Priority = v end })
AimbotTab:AddToggle({ Name = "Insta-Kill Aura", Default = false, Callback = function(v) Settings.InstaKill = v end })

-- Visuals
VisualTab:AddToggle({ Name = "ESP", Default = false, Callback = function(v) Settings.ESP.Enabled = v end })
VisualTab:AddToggle({ Name = "Boxes", Default = true, Callback = function(v) Settings.ESP.Boxes = v end })
VisualTab:AddToggle({ Name = "Names", Default = true, Callback = function(v) Settings.ESP.Names = v end })
VisualTab:AddToggle({ Name = "Health", Default = true, Callback = function(v) Settings.ESP.Health = v end })
VisualTab:AddToggle({ Name = "Distance", Default = true, Callback = function(v) Settings.ESP.Distance = v end })
VisualTab:AddToggle({ Name = "Hitbox Expander", Default = false, Callback = function(v) Settings.Hitbox.Enabled = v if v then ExpandHitbox() end end })
VisualTab:AddSlider({ Name = "Hitbox Size", Min = 5, Max = 40, Default = 15, Callback = function(v) Settings.Hitbox.Size = v if Settings.Hitbox.Enabled then ExpandHitbox() end end })

-- Gun Mods
GunTab:AddToggle({ Name = "Enable Gun Mods", Default = true, Callback = function(v) Settings.GunMods.Enabled = v end })
GunTab:AddToggle({ Name = "No Recoil", Default = true, Callback = function(v) Settings.NoRecoil = v end })
GunTab:AddToggle({ Name = "Infinite Ammo", Default = true, Callback = function(v) Settings.InfiniteAmmo = v end })
GunTab:AddSlider({ Name = "Damage Multiplier", Min = 1, Max = 25, Default = 15, Callback = function(v) Settings.GunMods.DamageMultiplier = v end })
GunTab:AddSlider({ Name = "Fire Rate", Min = 0.01, Max = 0.5, Default = 0.04, Increment = 0.01, Callback = function(v) Settings.GunMods.FireRate = v end })

-- Misc
MiscTab:AddToggle({ Name = "Fly", Default = false, Callback = function(v) Settings.Fly = v if v then StartFly() else StopFly() end end })
MiscTab:AddSlider({ Name = "Fly Speed", Min = 50, Max = 200, Default = 80, Callback = function(v) Settings.Speed = v end })
MiscTab:AddButton({ Name = "Save Config", Callback = SaveConfig })
MiscTab:AddButton({ Name = "Load Config", Callback = LoadConfig })

-- Init ESP
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then CreateESP(Player) end
end
Players.PlayerAdded:Connect(function(Player) Player.CharacterAdded:Connect(function() task.wait(1) CreateESP(Player) end) end)

OrionLib:Init()
