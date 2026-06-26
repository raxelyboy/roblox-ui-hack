-- ================================================================
--  Developer Sandbox Workspace  v4  |  LocalScript
--  แก้ไข: fly, waypoint freeze, V blink, E interact, freecam warp btn
-- ================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── ค่าคงที่ ────────────────────────────────────────────────────
local DEFAULT_WALK = 16
local MIN_SPEED    = 8
local MAX_SPEED    = 500
local INTERACT_RANGE = 50
local GHOST_INTERVAL = 0.06

-- ── สถานะ ───────────────────────────────────────────────────────
local walkSpeed    = DEFAULT_WALK
local flySpeed     = 60
local camSpeed     = 40

local flyEnabled     = false
local noclipEnabled  = false
local freecamEnabled = false
local auraEnabled    = false

local isDragging     = false
local sliderDragging = false

-- ── Fly ─────────────────────────────────────────────────────────
local flyConn, flyBV, flyBG

-- ── Freecam ─────────────────────────────────────────────────────
local fcPart, fcConn
local fcYaw, fcPitch = 0, 0
local fcRMB = false

-- ── Ghost preview ────────────────────────────────────────────────
local ghostModel
local ghostTimer = 0

-- ── Waypoint ─────────────────────────────────────────────────────
local waypoints     = {}
local waypointCount = 0

-- ── Aura ─────────────────────────────────────────────────────────
local auraHL = {}

-- ================================================================
--  SAFE HELPERS  (ไม่แตะ HumanoidState เลย เพื่อป้องกัน freeze)
-- ================================================================
local function getChar()     return player.Character end
local function getHRP()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end

-- teleport ปลอดภัย — anchor ชั่วคราวแล้วปล่อย ไม่ยุ่ง state
local function safeTeleport(cf)
    local hrp = getHRP()
    if not hrp then return end
    -- NoClip ชั่วคราวเผื่อทะลุกำแพง
    local char = getChar()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    hrp.Anchored = true
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = cf
    task.delay(0.1, function()
        local h = getHRP()
        if h then
            h.Anchored = false
            -- คืน collision หลัง 0.4 วินาที
            task.delay(0.4, function()
                if not noclipEnabled then
                    local c2 = getChar()
                    if c2 then
                        for _, p in ipairs(c2:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = true end
                        end
                    end
                end
            end)
        end
    end)
end

-- ================================================================
--  GHOST PREVIEW
-- ================================================================
local function destroyGhost()
    if ghostModel then ghostModel:Destroy(); ghostModel = nil end
end

local function buildGhost(targetCF)
    local char = getChar()
    local hrp  = getHRP()
    if not char or not hrp then return end

    -- ลบอันเก่าก่อน
    if ghostModel then ghostModel:Destroy(); ghostModel = nil end

    ghostModel        = Instance.new("Model")
    ghostModel.Name   = "GhostPreview"
    ghostModel.Parent = workspace

    local hrpCFInv = hrp.CFrame:Inverse()

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local rel    = hrpCFInv * part.CFrame
            local clone  = Instance.new("Part")
            clone.Size        = part.Size
            clone.CFrame      = targetCF * rel
            clone.Anchored    = true
            clone.CanCollide  = false
            clone.CanTouch    = false
            clone.CastShadow  = false
            clone.Color       = Color3.fromRGB(100, 200, 255)
            clone.Transparency = 0.5
            clone.Material    = Enum.Material.SmoothPlastic
            clone.Parent      = ghostModel
        end
    end
end

-- ================================================================
--  FLY SYSTEM
-- ================================================================
local function stopFly()
    flyEnabled = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV   then flyBV:Destroy();   flyBV  = nil end
    if flyBG   then flyBG:Destroy();   flyBG  = nil end
    -- คืน WalkSpeed
    local hum = getHum()
    if hum then hum.WalkSpeed = walkSpeed end
end

local function startFly()
    local hrp = getHRP()
    if not hrp then return end
    flyEnabled = true

    flyBV           = Instance.new("BodyVelocity")
    flyBV.Velocity  = Vector3.zero
    flyBV.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Parent    = hrp

    flyBG           = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P         = 1e4
    flyBG.D         = 400
    flyBG.CFrame    = hrp.CFrame
    flyBG.Parent    = hrp

    -- ปิด Humanoid จัดการ motion เฉยๆ ไม่ lock state
    local hum = getHum()
    if hum then hum.PlatformStand = true end

    flyConn = RunService.Heartbeat:Connect(function()
        if not flyEnabled then return end
        local h = getHRP()
        if not h then return end

        local cf  = camera.CFrame
        local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        local rgt = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
        if fwd.Magnitude > 0 then fwd = fwd.Unit end
        if rgt.Magnitude > 0 then rgt = rgt.Unit end

        local v = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then v += fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then v -= fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then v += rgt end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then v -= rgt end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then v += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then v -= Vector3.new(0,1,0) end

        flyBV.Velocity = if v.Magnitude > 0 then v.Unit * flySpeed else Vector3.zero
        flyBG.CFrame   = CFrame.new(h.Position, h.Position + cf.LookVector)
    end)
end

-- ================================================================
--  NOCLIP
-- ================================================================
local function stopNoclip()
    noclipEnabled = false
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
end

RunService.Stepped:Connect(function()
    if not noclipEnabled then return end
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ================================================================
--  FREECAM SYSTEM
-- ================================================================
local function stopFreecam()
    freecamEnabled = false
    fcRMB = false
    destroyGhost()
    if fcConn then fcConn:Disconnect(); fcConn = nil end
    if fcPart then
        local h = getHRP()
        if h then h.Anchored = false end
        fcPart:Destroy(); fcPart = nil
    end
    camera.CameraType = Enum.CameraType.Custom
    local hum = getHum()
    if hum then camera.CameraSubject = hum end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

local function startFreecam()
    local hrp = getHRP()
    if not hrp then return end
    freecamEnabled = true
    hrp.Anchored   = true
    hrp.AssemblyLinearVelocity = Vector3.zero

    fcPart             = Instance.new("Part")
    fcPart.Size        = Vector3.new(0.1,0.1,0.1)
    fcPart.Transparency = 1
    fcPart.CanCollide  = false
    fcPart.Anchored    = true
    fcPart.CFrame      = camera.CFrame
    fcPart.Parent      = workspace

    camera.CameraType    = Enum.CameraType.Scriptable
    camera.CameraSubject = fcPart

    local _, ry, _ = camera.CFrame:ToEulerAnglesYXZ()
    fcYaw = ry; fcPitch = 0
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    ghostTimer = 0

    fcConn = RunService.RenderStepped:Connect(function(dt)
        if not freecamEnabled then return end

        -- หมุนกล้องด้วย RMB
        if fcRMB then
            local d = UserInputService:GetMouseDelta()
            fcYaw   = fcYaw   - math.rad(d.X * 0.3)
            fcPitch = math.clamp(fcPitch - math.rad(d.Y * 0.3), math.rad(-80), math.rad(80))
        end

        local rot = CFrame.Angles(0, fcYaw, 0) * CFrame.Angles(fcPitch, 0, 0)
        local fwd = rot.LookVector
        local rgt = rot.RightVector
        local mv  = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv += fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv -= fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += rgt end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv -= rgt end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then mv += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
        if mv.Magnitude > 0 then mv = mv.Unit * camSpeed * dt end

        fcPart.CFrame  = CFrame.new(fcPart.CFrame.Position + mv) * rot
        camera.CFrame  = fcPart.CFrame

        -- Ghost preview throttle
        ghostTimer += dt
        if ghostTimer >= GHOST_INTERVAL then
            ghostTimer = 0
            buildGhost(fcPart.CFrame)
        end
    end)
end

-- ── RMB ─────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if freecamEnabled and inp.UserInputType == Enum.UserInputType.MouseButton2 then
        fcRMB = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        fcRMB = false
        if freecamEnabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)

-- ================================================================
--  BLINK  (V)
--  - ถ้าเปิด Freecam → วาร์ปตัวละครมาที่กล้อง
--  - ถ้าปิด Freecam  → วาร์ปไปข้างหน้า 5 studs (แบบเดิม)
-- ================================================================
local function doBlink()
    local hrp = getHRP()
    if not hrp then return end

    if freecamEnabled and fcPart then
        -- Freecam Blink: ตำแหน่งกล้อง + ยก 3 studs
        local target = fcPart.CFrame.Position + Vector3.new(0, 3, 0)
        safeTeleport(CFrame.new(target) * CFrame.Angles(0, fcYaw, 0))
        destroyGhost()
    else
        -- Normal Blink: ไปข้างหน้า 5 studs
        local look = camera.CFrame.LookVector
        local fwd  = Vector3.new(look.X, 0, look.Z)
        if fwd.Magnitude < 0.01 then return end
        fwd = fwd.Unit
        local target = hrp.CFrame.Position + fwd * 5
        safeTeleport(CFrame.new(target + Vector3.new(0,1.2,0)) * hrp.CFrame.Rotation)
    end
end

-- ================================================================
--  INTERACT  (E)
--  ทำงานทุกโหมด — raycast จากกล้อง
-- ================================================================
local interactLogLabel  -- จะกำหนดทีหลัง

local function doInteract()
    local origin, dir
    if freecamEnabled and fcPart then
        origin = fcPart.CFrame.Position
        dir    = fcPart.CFrame.LookVector * INTERACT_RANGE
    else
        origin = camera.CFrame.Position
        dir    = camera.CFrame.LookVector * INTERACT_RANGE
    end

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { getChar() }
    rp.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, dir, rp)
    if not result then
        if interactLogLabel then interactLogLabel.Text = "💬 E: ไม่พบสิ่งที่ interact ได้" end
        return
    end

    local inst = result.Instance
    -- หา ProximityPrompt
    local function findPP(obj)
        local pp = obj:FindFirstChildOfClass("ProximityPrompt")
        if pp then return pp end
        if obj.Parent then return obj.Parent:FindFirstChildOfClass("ProximityPrompt") end
    end
    local function findCD(obj)
        local cd = obj:FindFirstChildOfClass("ClickDetector")
        if cd then return cd end
        if obj.Parent then return obj.Parent:FindFirstChildOfClass("ClickDetector") end
    end

    local pp = findPP(inst)
    if pp then
        -- Studio-safe: ใช้ FireProximityPrompt ถ้ามี
        local ok, err = pcall(function()
            fireproximityprompt(pp)
        end)
        if not ok then
            -- fallback สำหรับ Studio
            pcall(function()
                game:GetService("ProximityPromptService"):TriggerPrompt(pp)
            end)
        end
        if interactLogLabel then interactLogLabel.Text = "✅ ProximityPrompt: " .. inst.Name end
        return
    end

    local cd = findCD(inst)
    if cd then
        local ok, _ = pcall(function() fireclickdetector(cd) end)
        if not ok then
            pcall(function()
                cd.MouseClick:Fire(player)
            end)
        end
        if interactLogLabel then interactLogLabel.Text = "✅ ClickDetector: " .. inst.Name end
        return
    end

    if interactLogLabel then interactLogLabel.Text = "💬 Hit: " .. inst.Name .. " (ไม่มี interact)" end
end

-- ================================================================
--  GLOBAL HOTKEYS
-- ================================================================
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.V then doBlink()    end
    if inp.KeyCode == Enum.KeyCode.E then doInteract() end
end)

-- ================================================================
--  GUI BUILD
-- ================================================================
local sg = Instance.new("ScreenGui")
sg.Name           = "DevSandbox"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.Parent         = player.PlayerGui

local mf = Instance.new("Frame")
mf.Name             = "Main"
mf.Size             = UDim2.new(0, 360, 0, 650)
mf.Position         = UDim2.new(0, 20, 0, 20)
mf.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
mf.BorderSizePixel  = 0
mf.ClipsDescendants = true
mf.Parent           = sg
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = mf end

-- Title Bar
local tb = Instance.new("Frame")
tb.Size             = UDim2.new(1,0,0,36)
tb.BackgroundColor3 = Color3.fromRGB(30,30,46)
tb.BorderSizePixel  = 0
tb.ZIndex           = 2
tb.Parent           = mf
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = tb
    local fix = Instance.new("Frame")
    fix.Size = UDim2.new(1,0,0,10); fix.Position = UDim2.new(0,0,1,-10)
    fix.BackgroundColor3 = Color3.fromRGB(30,30,46); fix.BorderSizePixel = 0; fix.ZIndex = 2; fix.Parent = tb
end

local tl = Instance.new("TextLabel")
tl.Size = UDim2.new(1,-50,1,0); tl.Position = UDim2.new(0,12,0,0)
tl.BackgroundTransparency = 1; tl.Text = "🛠  Developer Sandbox  v4"
tl.TextColor3 = Color3.fromRGB(220,220,255); tl.TextSize = 12
tl.Font = Enum.Font.GothamBold; tl.TextXAlignment = Enum.TextXAlignment.Left
tl.ZIndex = 3; tl.Parent = tb

local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0,28,0,28); xBtn.Position = UDim2.new(1,-34,0,4)
xBtn.BackgroundColor3 = Color3.fromRGB(200,50,50); xBtn.Text = "✕"
xBtn.TextColor3 = Color3.fromRGB(255,255,255); xBtn.TextSize = 14
xBtn.Font = Enum.Font.GothamBold; xBtn.BorderSizePixel = 0; xBtn.ZIndex = 4; xBtn.Parent = tb
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = xBtn end

-- Scroll
local sf = Instance.new("ScrollingFrame")
sf.Size = UDim2.new(1,0,1,-36); sf.Position = UDim2.new(0,0,0,36)
sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
sf.ScrollBarThickness = 4; sf.ScrollBarImageColor3 = Color3.fromRGB(100,100,160)
sf.CanvasSize = UDim2.new(0,0,0,0); sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
sf.Parent = mf
do
    local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0,6); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = sf
    local lp = Instance.new("UIPadding")
    lp.PaddingLeft = UDim.new(0,10); lp.PaddingRight = UDim.new(0,10)
    lp.PaddingTop = UDim.new(0,8); lp.PaddingBottom = UDim.new(0,10); lp.Parent = sf
end

-- ── Factories ────────────────────────────────────────────────────
local function hdr(txt, ord)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,22); l.BackgroundColor3 = Color3.fromRGB(40,40,62)
    l.Text = txt; l.TextColor3 = Color3.fromRGB(160,160,220); l.TextSize = 11
    l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left
    l.BorderSizePixel = 0; l.LayoutOrder = ord; l.Parent = sf
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = l end
    do local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,8); p.Parent = l end
    return l
end

local function togBtn(txt, ord)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,36); b.BackgroundColor3 = Color3.fromRGB(50,50,75)
    b.Text = txt .. "  [ OFF ]"; b.TextColor3 = Color3.fromRGB(200,200,200)
    b.TextSize = 13; b.Font = Enum.Font.Gotham; b.BorderSizePixel = 0
    b.LayoutOrder = ord; b.Parent = sf
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = b end
    return b
end

local function actBtn(txt, ord, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,36); b.BackgroundColor3 = col or Color3.fromRGB(50,80,130)
    b.Text = txt; b.TextColor3 = Color3.fromRGB(220,230,255)
    b.TextSize = 13; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0
    b.LayoutOrder = ord; b.Parent = sf
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = b end
    return b
end

local function mkSlider(label, ord, mn, mx, init, cb)
    local con = Instance.new("Frame")
    con.Size = UDim2.new(1,0,0,54); con.BackgroundColor3 = Color3.fromRGB(28,28,42)
    con.BorderSizePixel = 0; con.LayoutOrder = ord; con.Parent = sf
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = con end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-12,0,22); lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1; lbl.Text = label .. ": " .. math.floor(init)
    lbl.TextColor3 = Color3.fromRGB(200,220,255); lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = con

    local trk = Instance.new("Frame")
    trk.Size = UDim2.new(1,-20,0,8); trk.Position = UDim2.new(0,10,0,34)
    trk.BackgroundColor3 = Color3.fromRGB(60,60,90); trk.BorderSizePixel = 0; trk.Parent = con
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = trk end

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(100,160,255); fill.BorderSizePixel = 0; fill.Parent = trk
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = fill end

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0,16,0,16); knob.BackgroundColor3 = Color3.fromRGB(180,200,255)
    knob.Text = ""; knob.BorderSizePixel = 0; knob.ZIndex = 5; knob.Parent = trk
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = knob end

    local r0 = (init - mn) / (mx - mn)
    fill.Size = UDim2.new(r0,0,1,0); knob.Position = UDim2.new(r0,-8,0.5,-8)

    local drag = false
    knob.MouseButton1Down:Connect(function() drag = true; sliderDragging = true end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((inp.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
            local v = math.floor(mn + r * (mx - mn))
            fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,-8,0.5,-8)
            lbl.Text = label .. ": " .. v
            if cb then cb(v) end
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and drag then
            drag = false; sliderDragging = false
        end
    end)
end

-- ================================================================
--  SECTION 1 — SPEED PANEL รวม
-- ================================================================
hdr("⚡  Speed Panel", 10)
mkSlider("WalkSpeed", 11, MIN_SPEED, MAX_SPEED, DEFAULT_WALK, function(v)
    walkSpeed = v
    local hum = getHum(); if hum then hum.WalkSpeed = v end
end)
mkSlider("Fly Speed", 12, 10, 500, 60, function(v) flySpeed = v end)
mkSlider("Cam Speed", 13, 5, 300, 40, function(v) camSpeed = v end)

-- ================================================================
--  SECTION 2 — FLY
-- ================================================================
hdr("✈  Map Fly", 20)
local flyBtn = togBtn("Map Fly", 21)
flyBtn.MouseButton1Click:Connect(function()
    if flyEnabled then
        stopFly()
        flyBtn.Text = "Map Fly  [ OFF ]"; flyBtn.BackgroundColor3 = Color3.fromRGB(50,50,75)
    else
        startFly()
        flyBtn.Text = "Map Fly  [ ON ]";  flyBtn.BackgroundColor3 = Color3.fromRGB(40,100,60)
    end
end)

-- ================================================================
--  SECTION 3 — NOCLIP
-- ================================================================
hdr("👻  NoClip", 30)
local ncBtn = togBtn("NoClip", 31)
ncBtn.MouseButton1Click:Connect(function()
    if noclipEnabled then
        stopNoclip()
        ncBtn.Text = "NoClip  [ OFF ]"; ncBtn.BackgroundColor3 = Color3.fromRGB(50,50,75)
    else
        noclipEnabled = true
        ncBtn.Text = "NoClip  [ ON ]";  ncBtn.BackgroundColor3 = Color3.fromRGB(40,100,60)
    end
end)

-- ================================================================
--  SECTION 4 — FREECAM + WARP BTN + INTERACT LOG
-- ================================================================
hdr("🎥  Freecam  |  V = Blink  |  E = Interact", 40)
local fcBtn = togBtn("Freecam", 41)

-- ปุ่ม Warp Here (เหมือน Omen)
local warpBtn = actBtn("🌀  Warp Here (V)", 42, Color3.fromRGB(60,30,120))

-- Interact log
local iLog = Instance.new("TextLabel")
iLog.Size = UDim2.new(1,0,0,24); iLog.BackgroundColor3 = Color3.fromRGB(18,36,18)
iLog.Text = "💬 กด E เพื่อ interact"; iLog.TextColor3 = Color3.fromRGB(100,255,100)
iLog.TextSize = 10; iLog.Font = Enum.Font.Gotham; iLog.TextWrapped = true
iLog.TextXAlignment = Enum.TextXAlignment.Left; iLog.BorderSizePixel = 0
iLog.LayoutOrder = 43; iLog.Parent = sf
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = iLog
    local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,6); p.PaddingRight = UDim.new(0,6); p.Parent = iLog
end
interactLogLabel = iLog  -- เชื่อมกับฟังก์ชัน doInteract

-- hint
local fcHint = Instance.new("TextLabel")
fcHint.Size = UDim2.new(1,0,0,28); fcHint.BackgroundColor3 = Color3.fromRGB(28,28,42)
fcHint.Text = "RMB ค้าง = หมุนกล้อง | WASD/Space/Ctrl = เคลื่อนกล้อง"
fcHint.TextColor3 = Color3.fromRGB(140,160,190); fcHint.TextSize = 10
fcHint.Font = Enum.Font.Gotham; fcHint.TextWrapped = true
fcHint.BorderSizePixel = 0; fcHint.LayoutOrder = 44; fcHint.Parent = sf
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = fcHint
    local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,6); p.PaddingRight = UDim.new(0,6); p.Parent = fcHint
end

fcBtn.MouseButton1Click:Connect(function()
    if freecamEnabled then
        stopFreecam()
        fcBtn.Text = "Freecam  [ OFF ]"; fcBtn.BackgroundColor3 = Color3.fromRGB(50,50,75)
    else
        startFreecam()
        fcBtn.Text = "Freecam  [ ON ]";  fcBtn.BackgroundColor3 = Color3.fromRGB(40,100,60)
    end
end)

warpBtn.MouseButton1Click:Connect(function() doBlink() end)

-- ================================================================
--  SECTION 5 — WAYPOINT SAVER
-- ================================================================
hdr("📌  Waypoint Saver", 50)
local wpAddBtn = actBtn("📌  Set Waypoint", 51, Color3.fromRGB(50,80,130))

local wpOuter = Instance.new("Frame")
wpOuter.Size = UDim2.new(1,0,0,120); wpOuter.BackgroundColor3 = Color3.fromRGB(22,22,34)
wpOuter.BorderSizePixel = 0; wpOuter.LayoutOrder = 52; wpOuter.Parent = sf
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = wpOuter end

local wpSc = Instance.new("ScrollingFrame")
wpSc.Size = UDim2.new(1,-4,1,-4); wpSc.Position = UDim2.new(0,2,0,2)
wpSc.BackgroundTransparency = 1; wpSc.BorderSizePixel = 0; wpSc.ScrollBarThickness = 3
wpSc.ScrollBarImageColor3 = Color3.fromRGB(100,100,160)
wpSc.CanvasSize = UDim2.new(0,0,0,0); wpSc.AutomaticCanvasSize = Enum.AutomaticSize.Y
wpSc.Parent = wpOuter
do
    local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0,4); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = wpSc
    local lp = Instance.new("UIPadding")
    lp.PaddingLeft = UDim.new(0,4); lp.PaddingRight = UDim.new(0,4)
    lp.PaddingTop = UDim.new(0,4); lp.PaddingBottom = UDim.new(0,4); lp.Parent = wpSc
end

local function makeMarker(cf, name)
    local pole = Instance.new("Part")
    pole.Size = Vector3.new(0.4,4,0.4); pole.CFrame = cf * CFrame.new(0,2,0)
    pole.Anchored = true; pole.CanCollide = false; pole.Material = Enum.Material.Neon
    pole.Color = Color3.fromRGB(0,220,100); pole.Name = "WP_"..name; pole.Parent = workspace

    local cap = Instance.new("Part")
    cap.Size = Vector3.new(1.2,0.3,1.2); cap.CFrame = cf * CFrame.new(0,4.15,0)
    cap.Anchored = true; cap.CanCollide = false; cap.Material = Enum.Material.Neon
    cap.Color = Color3.fromRGB(0,255,120); cap.Parent = workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0,100,0,28); bb.StudsOffset = Vector3.new(0,3.2,0)
    bb.AlwaysOnTop = true; bb.Parent = pole

    local bl = Instance.new("TextLabel")
    bl.Size = UDim2.new(1,0,1,0); bl.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bl.BackgroundTransparency = 0.4; bl.Text = "📌 " .. name
    bl.TextColor3 = Color3.fromRGB(255,255,255); bl.TextSize = 13
    bl.Font = Enum.Font.GothamBold; bl.Parent = bb
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = bl end

    return { pole = pole, cap = cap }
end

local function addWpRow(wpData)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,28); row.BackgroundColor3 = Color3.fromRGB(35,35,55)
    row.BorderSizePixel = 0; row.LayoutOrder = wpData.idx; row.Parent = wpSc
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = row end

    local tpB = Instance.new("TextButton")
    tpB.Size = UDim2.new(1,-44,1,0); tpB.BackgroundTransparency = 1
    tpB.Text = "📍 " .. wpData.name; tpB.TextColor3 = Color3.fromRGB(180,220,255)
    tpB.TextSize = 12; tpB.Font = Enum.Font.Gotham; tpB.TextXAlignment = Enum.TextXAlignment.Left
    tpB.Parent = row
    do local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,6); p.Parent = tpB end

    local dB = Instance.new("TextButton")
    dB.Size = UDim2.new(0,38,1,0); dB.Position = UDim2.new(1,-40,0,0)
    dB.BackgroundColor3 = Color3.fromRGB(160,40,40); dB.Text = "Del"
    dB.TextColor3 = Color3.fromRGB(255,220,220); dB.TextSize = 11
    dB.Font = Enum.Font.GothamBold; dB.BorderSizePixel = 0; dB.Parent = row
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = dB end

    tpB.MouseButton1Click:Connect(function()
        -- วาร์ปไปยัง waypoint โดยวางตัวละครเหนือจุด 1.2 studs
        local target = wpData.cf.Position + Vector3.new(0, 1.2, 0)
        safeTeleport(CFrame.new(target) * wpData.cf.Rotation)
    end)
    dB.MouseButton1Click:Connect(function()
        local m = wpData.marker
        if m then
            if m.pole and m.pole.Parent then m.pole:Destroy() end
            if m.cap  and m.cap.Parent  then m.cap:Destroy()  end
        end
        for i,v in ipairs(waypoints) do if v.name == wpData.name then table.remove(waypoints,i); break end end
        row:Destroy()
    end)
end

wpAddBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP(); if not hrp then return end
    waypointCount += 1
    local name   = "WP " .. waypointCount
    local cf     = hrp.CFrame
    local marker = makeMarker(cf, name)
    local wpData = { idx = waypointCount, name = name, cf = cf, marker = marker }
    table.insert(waypoints, wpData)
    addWpRow(wpData)
end)

-- ================================================================
--  SECTION 6 — PLAYER AURA
-- ================================================================
hdr("🔴  Player Aura", 60)
local aBtn = togBtn("Show Aura", 61)

local function addAura(p)
    if p == player or auraHL[p] then return end
    local char = p.Character; if not char then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3 = Color3.fromRGB(255,60,60); hl.LineThickness = 0.06
    hl.SurfaceTransparency = 0.7; hl.SurfaceColor3 = Color3.fromRGB(255,40,40)
    hl.Adornee = char; hl.Parent = workspace; auraHL[p] = hl
    p.CharacterAdded:Connect(function(nc) if auraEnabled and auraHL[p] then auraHL[p].Adornee = nc end end)
end
local function remAura(p) if auraHL[p] then auraHL[p]:Destroy(); auraHL[p] = nil end end
local function clearAuras() for _, hl in pairs(auraHL) do if hl and hl.Parent then hl:Destroy() end end; auraHL = {} end

Players.PlayerAdded:Connect(function(p)   if auraEnabled then addAura(p) end end)
Players.PlayerRemoving:Connect(function(p) remAura(p) end)

aBtn.MouseButton1Click:Connect(function()
    if auraEnabled then
        auraEnabled = false; clearAuras()
        aBtn.Text = "Show Aura  [ OFF ]"; aBtn.BackgroundColor3 = Color3.fromRGB(50,50,75)
    else
        auraEnabled = true
        for _, p in ipairs(Players:GetPlayers()) do addAura(p) end
        aBtn.Text = "Show Aura  [ ON ]"; aBtn.BackgroundColor3 = Color3.fromRGB(140,40,40)
    end
end)

-- ================================================================
--  DRAGGABLE TITLE BAR
-- ================================================================
local ds, fs
tb.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true; ds = i.Position; fs = mf.Position
    end
end)
tb.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if isDragging and not sliderDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds
        mf.Position = UDim2.new(fs.X.Scale, fs.X.Offset+d.X, fs.Y.Scale, fs.Y.Offset+d.Y)
    end
end)

-- ================================================================
--  CLOSE BUTTON
-- ================================================================
xBtn.MouseButton1Click:Connect(function()
    stopFly(); stopNoclip(); stopFreecam(); clearAuras(); destroyGhost()
    local hum = getHum(); if hum then hum.WalkSpeed = DEFAULT_WALK; hum.PlatformStand = false end
    local c = getChar()
    if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    for _, wd in ipairs(waypoints) do
        if wd.marker then
            if wd.marker.pole and wd.marker.pole.Parent then wd.marker.pole:Destroy() end
            if wd.marker.cap  and wd.marker.cap.Parent  then wd.marker.cap:Destroy()  end
        end
    end
    sg:Destroy()
end)

-- ================================================================
--  CHARACTER ADDED
-- ================================================================
local function onCharAdded(char)
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Humanoid")

    flyEnabled = false; noclipEnabled = false; freecamEnabled = false; fcRMB = false
    destroyGhost()

    flyBtn.Text = "Map Fly  [ OFF ]";  flyBtn.BackgroundColor3 = Color3.fromRGB(50,50,75)
    ncBtn.Text  = "NoClip  [ OFF ]";   ncBtn.BackgroundColor3  = Color3.fromRGB(50,50,75)
    fcBtn.Text  = "Freecam  [ OFF ]";  fcBtn.BackgroundColor3  = Color3.fromRGB(50,50,75)

    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV   then flyBV:Destroy();   flyBV  = nil end
    if flyBG   then flyBG:Destroy();   flyBG  = nil end
    if fcConn  then fcConn:Disconnect(); fcConn = nil end
    if fcPart  then fcPart:Destroy();  fcPart = nil end

    camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        camera.CameraSubject = hum
        hum.WalkSpeed        = walkSpeed
        hum.PlatformStand    = false
    end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
end

player.CharacterAdded:Connect(onCharAdded)
if player.Character then onCharAdded(player.Character) end
