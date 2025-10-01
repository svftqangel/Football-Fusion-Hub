-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ===== RAYFIELD =====
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Football Fusion 🏈",
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by Svderr2",
    ShowText = "Rayfield",
    Theme = "Default",
    ToggleUIKeybind = Enum.KeyCode.K,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FootballFusionHub",
        FileName = "BigHub"
    }
})

local CatchingTab = Window:CreateTab("Catching", 4483362458)

-- ===== GLOBAL SETTINGS =====
getgenv().g = getgenv().g or {}
-- Magnet/Hitbox
g.magnetEnabled = false
g.magnetRange = 13
g.currentMode = "Regular"
g.hitboxEnabled = false
g.hitboxType = "Forcefield"
g.rainbowHitboxEnabled = false
g.rainbowSpeed = 0.5
g.ping = 0.12
-- Pull Vector / Long Arm
getgenv().PullVectorOn = false
getgenv().PullVectorSpeed = 2
getgenv().PullVectorRadius = 35
getgenv().pullVectoredBalls = {}
-- Void Arm
getgenv().voidArmOn = false
getgenv().voidArmSize = 4

local hitboxes, velocities, lastPositions = {}, {}, {}
local rainbowHue = 0
local modeRanges = {Regular = 13, League = 6, Legit = 10, Rage = 25, Custom = 0}

-- ===== FUNCTIONS =====
local function getRange()
    if g.currentMode == "Custom" then return g.magnetRange end
    return modeRanges[g.currentMode] or 13
end

local function findFootballs()
    local balls = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Football" and not obj.Anchored then
            balls[#balls+1] = obj
        end
    end
    return balls
end

local function nearestPart(ref, parts)
    local closest, dist = nil, math.huge
    if not ref or not ref.Position then return nil end
    for _, p in ipairs(parts) do
        local d = (ref.Position - p.Position).Magnitude
        if d < dist then dist, closest = d, p end
    end
    return closest
end

local function rainbowUpdate()
    rainbowHue = (rainbowHue + (g.rainbowSpeed / 255)) % 1
    return Color3.fromHSV(rainbowHue, 1, 1)
end

local function createOrUpdateHitbox(ball)
    local size = getRange()
    local hb = hitboxes[ball]
    if not hb or not hb.Parent then
        hb = Instance.new("Part")
        hb.Name = "Croom_Hitbox"
        hb.Anchored = true
        hb.CanCollide = false
        hb.Size = Vector3.new(size, size, size)
        hb.CFrame = ball.CFrame
        hb.Parent = Workspace
        hitboxes[ball] = hb
    end
    hb.Size = Vector3.new(size, size, size)
    hb.CFrame = ball.CFrame
    for _,child in ipairs(hb:GetChildren()) do
        if child:IsA("SelectionBox") or child:IsA("SelectionSphere") then child:Destroy() end
    end
    if g.rainbowHitboxEnabled then
        hb.Shape = Enum.PartType.Ball
        hb.Material = Enum.Material.ForceField
        hb.Color = rainbowUpdate()
        hb.Transparency = 0.3
    elseif g.hitboxType == "Forcefield" then
        hb.Shape = Enum.PartType.Ball
        hb.Material = Enum.Material.ForceField
        hb.Color = Color3.fromRGB(50,205,50)
        hb.Transparency = 0.3
    elseif g.hitboxType == "Sphere" then
        hb.Shape = Enum.PartType.Ball
        hb.Material = Enum.Material.SmoothPlastic
        hb.Color = Color3.fromRGB(255,105,180)
        hb.Transparency = 0.4
        local outline = Instance.new("SelectionSphere", hb)
        outline.Adornee = hb
        outline.SurfaceColor3 = Color3.fromRGB(137,207,240)
        outline.SurfaceTransparency = 0.3
    else
        hb.Shape = Enum.PartType.Block
        hb.Material = Enum.Material.SmoothPlastic
        hb.Color = Color3.fromRGB(120,120,120)
        hb.Transparency = 0.65
        local outline = Instance.new("SelectionBox", hb)
        outline.Adornee = hb
        outline.LineThickness = 0.05
        outline.Color3 = Color3.fromRGB(120,120,120)
        outline.Transparency = 0.6
    end
end

local function clearHitbox(ball)
    if hitboxes[ball] then
        hitboxes[ball]:Destroy()
        hitboxes[ball] = nil
    end
    velocities[ball], lastPositions[ball] = nil, nil
end

Workspace.ChildRemoved:Connect(function(obj)
    if hitboxes[obj] then clearHitbox(obj) end
end)

-- ===== HEARTBEAT LOOP =====
RunService.Heartbeat:Connect(function(dt)
    local balls = findFootballs()
    if #balls == 0 then return end
    local char = LocalPlayer.Character
    local leftCatch = char and (char:FindFirstChild("LeftCatch") or char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm"))
    local rightCatch = char and (char:FindFirstChild("RightCatch") or char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))

    for _, ball in ipairs(balls) do
        local last = lastPositions[ball] or ball.Position
        velocities[ball] = (ball.Position - last) / (dt > 0 and dt or 0.016)
        lastPositions[ball] = ball.Position

        -- Hitbox
        if g.hitboxEnabled or g.rainbowHitboxEnabled then
            createOrUpdateHitbox(ball)
        else
            clearHitbox(ball)
        end

        -- Magnet + Pull Vector
        if leftCatch and rightCatch then
            local predictedPos = ball.Position + (velocities[ball] or Vector3.new()) * g.ping

            -- Pull Vector / Long Arm
            if PullVectorOn then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - ball.Position).Magnitude <= PullVectorRadius then
                    local dir = (ball.Position - root.Position).Unit
                    root.AssemblyLinearVelocity = dir * PullVectorSpeed * 25
                end
            end

            -- Magnet
            if g.magnetEnabled then
                local nearest = nearestPart(ball, {leftCatch, rightCatch})
                if nearest and (nearest.Position - predictedPos).Magnitude <= getRange() then
                    pcall(function()
                        firetouchinterest(leftCatch, ball, 0)
                        firetouchinterest(leftCatch, ball, 1)
                        firetouchinterest(rightCatch, ball, 0)
                        firetouchinterest(rightCatch, ball, 1)
                    end)
                end
            end
        end
    end

    -- Void Arm
    if voidArmOn and char then
        local l = char:FindFirstChild("Left Arm")
        local r = char:FindFirstChild("Right Arm")
        if l and r then
            l.Size = Vector3.new(1, voidArmSize, 1)
            r.Size = Vector3.new(1, voidArmSize, 1)
        end
    elseif char then
        local l = char:FindFirstChild("Left Arm")
        local r = char:FindFirstChild("Right Arm")
        if l and r then
            l.Size = Vector3.new(1, 2, 1)
            r.Size = Vector3.new(1, 2, 1)
        end
    end
end)

-- ===== RAYFIELD UI =====
-- Magnet Section
CatchingTab:CreateSection("Magnet Settings")
CatchingTab:CreateToggle({Name="Magnets",CurrentValue=false,Flag="Magnets",Callback=function(v) g.magnetEnabled=v end})
CatchingTab:CreateSlider({Name="Magnet Range",Range={0,40},Increment=1,Suffix=" studs",CurrentValue=13,Flag="MagnetRange",Callback=function(v) g.magnetRange=v end})
CatchingTab:CreateDropdown({Name="Magnet Type",Options={"Regular","League","Legit","Rage","Custom"},CurrentOption={"Regular"},MultipleOptions=false,Flag="MagnetType",Callback=function(o) g.currentMode=o[1] end})

-- Hitbox Section
CatchingTab:CreateSection("Hitbox Settings")
CatchingTab:CreateToggle({Name="Magnet Hitbox",CurrentValue=false,Flag="MagnetHitbox",Callback=function(v) g.hitboxEnabled=v end})
CatchingTab:CreateDropdown({Name="Hitbox Type",Options={"Forcefield","Sphere","Box"},CurrentOption={"Forcefield"},MultipleOptions=false,Flag="HitboxType",Callback=function(o) g.hitboxType=o[1] end})
CatchingTab:CreateToggle({Name="Rainbow Hitbox",CurrentValue=false,Flag="RainbowHitbox",Callback=function(v) g.rainbowHitboxEnabled=v end})
CatchingTab:CreateSlider({Name="Rainbow Speed",Range={0.01,2},Increment=0.01,CurrentValue=0.5,Flag="RainbowSpeed",Callback=function(v) g.rainbowSpeed=v end})

-- Long Arm / Pull Vector Section
CatchingTab:CreateSection("Long Arm Settings")
CatchingTab:CreateToggle({Name="Enable Long Arm",CurrentValue=false,Flag="PullVectorToggle",Callback=function(v) PullVectorOn=v end})
CatchingTab:CreateSlider({Name="Arm Speed",Range={1,5},Increment=0.1,CurrentValue=2,Flag="PullVectorSpeed",Callback=function(v) PullVectorSpeed=v end})
CatchingTab:CreateSlider({Name="Arm Radius",Range={10,50},Increment=1,CurrentValue=35,Flag="PullVectorRadius",Callback=function(v) PullVectorRadius=v end})

-- Void Arm Section
CatchingTab:CreateSection("Void Arm Settings")
CatchingTab:CreateToggle({Name="Enable Void Arm",CurrentValue=false,Flag="VoidArmToggle",Callback=function(v) voidArmOn=v end})
CatchingTab:CreateSlider({Name="Arm Length",Range={2,20},Increment=0.1,CurrentValue=4,Flag="VoidArmSize",Callback=function(v) voidArmSize=v end})

-- Notification
Rayfield:Notify({Title="Football Fusion Loaded",Content="Magnet, Hitbox, Long Arm, and Void Arm ready.",Duration=5,Image="rewind"})
