local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Prompts = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- สถานะต่างๆ
local speedValue = 16
local noclip = false
local fly = false
local wallhack = false
local astralActive = false
local blinkEnabled = false
local vBlinkActive = false -- สำหรับปุ่ม V พุ่ง
local waypointsList = {}
local waypointCount = 0
local cameraRotX, cameraRotY = 0, 0
local speedDragging = false
local V_Blink_Toggle = false -- ควบคุมเปิด-ปิด V Blink

-- UI และโครงสร้าง
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AIO_Ultimate_Control"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 340, 0, 500)
frame.Position = UDim2.new(0.5, -170, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Drag
local dragDragging, dragStart, startPos
frame.InputBegan:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragDragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragDragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ ULTIMATE CONTROL MENU"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -36, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Speed Slider
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Position = UDim2.new(0, 15, 0, 45)
speedLabel.Size = UDim2.new(1, -30, 0, 20)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Text = "Speed: 16"
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextSize = 14

local sliderBG = Instance.new("Frame", frame)
sliderBG.Position = UDim2.new(0, 15, 0, 68)
sliderBG.Size = UDim2.new(1, -30, 0, 6)
sliderBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderBG.BorderSizePixel = 0
Instance.new("UICorner", sliderBG)

local slider = Instance.new("ImageButton", sliderBG)
slider.Size = UDim2.new(0, 14, 0, 16)
slider.Position = UDim2.new(0, 0, -0.5, 0)
slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
slider.BorderSizePixel = 0
Instance.new("UICorner", slider)

local function updateSpeed(x)
    local rel = math.clamp(x - sliderBG.AbsolutePosition.X, 0, sliderBG.AbsoluteSize.X)
    local percent = rel / sliderBG.AbsoluteSize.X
    speedValue = math.floor(16 + (484 * percent))
    slider.Position = UDim2.new(percent, -7, -0.5, 0)
    speedLabel.Text = "Speed: " .. speedValue
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = speedValue
    end
end

local speedDrag = false
slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDrag = true
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDrag = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if speedDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSpeed(input.Position.X)
    end
end)

-- Helper function to create buttons
local buttonCount = 0
local function createMenuButton(txt, col)
    buttonCount = buttonCount + 1
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 145, 0, 36)
    btn.Position = UDim2.new(0, (buttonCount % 2 == 0) and 180 or 15,
        0, 85 + math.floor((buttonCount - 1) / 2) * 42)
    btn.BackgroundColor3 = col
    btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

-- สร้างปุ่ม
local noclipBtn = createMenuButton("NoClip: OFF", Color3.fromRGB(55, 55, 55))
local flyBtn = createMenuButton("Fly System: OFF", Color3.fromRGB(55, 55, 55))
local wallBtn = createMenuButton("Wallhack: OFF", Color3.fromRGB(55, 55, 55))
local astralBtn = createMenuButton("Astral Form: OFF", Color3.fromRGB(55, 55, 55))
local blinkBtn = createMenuButton("Blink (V Key): OFF", Color3.fromRGB(55, 55, 55))
local setWpBtn = createMenuButton("📌 Set Waypoint", Color3.fromRGB(0, 110, 180))
local tpAstralBtn = createMenuButton("⚡ TP to Astral Marker", Color3.fromRGB(0, 150, 90))
tpAstralBtn.Visible = false

-- ============================
-- 3. ระบบ NoClip
-- ============================
local function toggleNoClip()
    noclip = not noclip
    noclipBtn.Text = noclip and "NoClip: ON" or "NoClip: OFF"
    noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
end
noclipBtn.MouseButton1Click:Connect(toggleNoClip)

RunService.Stepped:Connect(function()
    if noclip and player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    else
        -- ถ้าปิด ให้คืนค่า CanCollide = true สำหรับทุกส่วน
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end
end)

-- ============================
-- 4. Wallhack (ESP)
-- ============================
local function removeAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild(ESP_TAG) then
            p.Character[ESP_TAG]:Destroy()
        end
    end
end

local function applyESP(targetPlayer)
    if targetPlayer == player then return end
    local function setupHighlight(char)
        if not wallhack or not char then return end
        if char:FindFirstChild(ESP_TAG) then char[ESP_TAG]:Destroy() end
        local hl = Instance.new("Highlight", char)
        hl.Name = ESP_TAG
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    targetPlayer.CharacterAppearanceLoaded:Connect(setupHighlight)
    if targetPlayer.Character then setupHighlight(targetPlayer.Character) end
end

local function toggleWallHack()
    wallhack = not wallhack
    wallBtn.Text = wallhack and "Wallhack: ON" or "Wallhack: OFF"
    wallBtn.BackgroundColor3 = wallhack and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
    if wallhack then
        for _, p in pairs(Players:GetPlayers()) do
            applyESP(p)
        end
    else
        removeAllESP()
    end
end
wallBtn.MouseButton1Click:Connect(toggleWallHack)
Players.PlayerAdded:Connect(function(p)
    applyESP(p)
end)

-- ============================
-- 5. ระบบบิน (Fly)
-- ============================
local function disableFly()
    fly = false
    flyBtn.Text = "Fly System: OFF"
    flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if root and hum then
        hum:ChangeState(Enum.HumanoidStateType.Running)
        -- ลบ BodyVelocity / BodyGyro
        for _, v in pairs(root:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
        end
    end
end

local function toggleFly()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    fly = not fly
    if fly then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        local bv = Instance.new("BodyVelocity", root)
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.new(0, 0, 0)
        local bg = Instance.new("BodyGyro", root)
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.CFrame = root.CFrame
    else
        disableFly()
    end
    flyBtn.Text = fly and "Fly System: ON" or "Fly System: OFF"
    flyBtn.BackgroundColor3 = fly and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
end
flyBtn.MouseButton1Click:Connect(toggleFly)

-- ============================
-- 6. Astral Form & TP
-- ============================
local function removeMarker()
    if markerPart then
        markerPart:Destroy()
        markerPart = nil
    end
end

local function createMarker()
    removeMarker()
    markerPart = Instance.new("Part", workspace)
    markerPart.Name = "Astral_Marker"
    markerPart.Shape = Enum.PartType.Cylinder
    markerPart.Size = Vector3.new(5, 3.5, 3.5)
    markerPart.Rotation = Vector3.new(0, 0, 90)
    markerPart.Material = Enum.Material.Neon
    markerPart.Color = Color3.fromRGB(0, 170, 255)
    markerPart.Transparency = 0.4
    markerPart.CanCollide = false
    markerPart.Anchored = true
    local hl = Instance.new("Highlight", markerPart)
    hl.FillColor = Color3.fromRGB(0, 170, 255)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function disableAstral()
    astralActive = false
    astralBtn.Text = "Astral Form: OFF"
    astralBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    tpAstralBtn.Visible = false
    removeMarker()

    if fakeCamPart then
        fakeCamPart:Destroy()
        fakeCamPart = nil
    end
    -- Reset camera
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            cam.CameraSubject = hum
            hum.AutoRotate = true
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
    end
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function toggleAstral()
    if not player.Character then return end
    local char = player.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    astralActive = not astralActive
    astralBtn.Text = astralActive and "Astral Form: ON" or "Astral Form: OFF"
    astralBtn.BackgroundColor3 = astralActive and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
    tpAstralBtn.Visible = astralActive

    if astralActive then
        if fly then disableFly() end
        local look = camera.CFrame.LookVector
        cameraRotX = math.atan2(-look.X, -look.Z)
        cameraRotY = math.asin(look.Y)
        if not fakeCamPart then
            fakeCamPart = Instance.new("Part", workspace)
            fakeCamPart.Size = Vector3.new(1, 1, 1)
            fakeCamPart.Transparency = 1
            fakeCamPart.CanCollide = false
            fakeCamPart.Anchored = true
            fakeCamPart.CFrame = camera.CFrame
        end
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = fakeCamPart
        local rootPart = root
        if rootPart then rootPart.Anchored = true end
        UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    else
        disableAstral()
    end
end

local function teleportToMarker()
    if not (astralActive and markerPart) then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum then
        root.Anchored = true
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        root.CFrame = markerPart.CFrame * CFrame.new(0, 0.4, 0)
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        disableAstral()
    end
end
tpAstralBtn.MouseButton1Click = teleportToMarker

-- ============================
-- 7. V Blink & Waypoints
-- ============================
local function toggleVBlink()
    V_Blink_Toggle = not V_Blink_Toggle
    blinkBtn.Text = V_Blink_Toggle and "V Blink: ON" or "V Blink: OFF"
    blinkBtn.BackgroundColor3 = V_Blink_Toggle and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
end
blinkBtn.MouseButton1Click = toggleVBlink

UIS.InputBegan:Connect(function(input, gp)
    if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= Enum.KeyCode.V or not V_Blink_Toggle or astralActive then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    task.spawn(function()
        root.Velocity = Vector3.new(0,0,0)
        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        local lookDir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
        for i=1,12 do
            if not root then break end
            root.CFrame = root.CFrame + (lookDir * 1.5) + Vector3.new(0, 0.05, 0)
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            RunService.Heartbeat:Wait()
        end
        task.wait(0.02)
        if root and hum then
            root.Velocity = Vector3.new(0,0,0)
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end)

-- ============================
-- 8. Waypoint System
-- ============================
local function updateWaypointUI()
    -- Clear existing
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    -- Populate new
    for id, wpData in pairs(waypointsList) do
        local r = Instance.new("Frame", scrollFrame)
        r.Size = UDim2.new(1, -10, 0, 36)
        r.BackgroundTransparency = 1

        local tp = Instance.new("TextButton", r)
        tp.Size = UDim2.new(0, 205, 1, -4)
        tp.Position = UDim2.new(0, 5, 0, 2)
        tp.BackgroundColor3 = Color3.fromRGB(45, 55, 50)
        tp.Text = "⚡ " .. wpData.Name
        tp.TextColor3 = Color3.fromRGB(255, 255, 255)
        tp.Font = Enum.Font.SourceSansBold
        tp.TextSize = 13
        tp.BorderSizePixel = 0
        Instance.new("UICorner", tp)

        local del = Instance.new("TextButton", r)
        del.Size = UDim2.new(0, 55, 1, -4)
        del.Position = UDim2.new(0, 215, 0, 2)
        del.BackgroundColor3 = Color3.fromRGB(130,40,40)
        del.Text = "Delete"
        del.TextColor3 = Color3.fromRGB(255,255,255)
        del.Font = Enum.Font.SourceSansBold
        del.TextSize = 11
        del.BorderSizePixel = 0
        Instance.new("UICorner", del)

        tp.MouseButton1Click:Connect(function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                if fly then disableFly() end
                root.Velocity = Vector3.new(0,0,0)
                root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                root.CFrame = wpData.CFrame + Vector3.new(0,1.2,0)
                task.wait(0.06)
                root.Anchored = false
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)

        del.MouseButton1Click:Connect(function()
            if wpData.VisualPart then wpData.VisualPart:Destroy() end
            table.remove(waypointsList, id)
            updateWaypointUI()
        end)
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

setWpBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    waypointCount = waypointCount + 1
    local flag = Instance.new("Part", workspace)
    flag.Name = WP_FLAG_TAG
    flag.Size = Vector3.new(0.5,7,0.5)
    flag.Material = Enum.Material.Neon
    flag.Color = Color3.fromRGB(0,255,100)
    flag.Transparency = 0.4
    flag.Anchored = true
    flag.CanCollide = false
    flag.CFrame = root.CFrame * CFrame.new(0, -1, 0)
    local hl = Instance.new("Highlight", flag)
    hl.FillColor = Color3.fromRGB(0,255,100)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    table.insert(waypointsList, {Name="Waypoint "..waypointCount, CFrame=root.CFrame, VisualPart=flag})
    updateWaypointUI()
end)

-- ============================
-- 9. Reset on spawn
-- ============================
local function resetAll()
    -- ปิดระบบ
    if fly then disableFly() end
    if noclip then
        noclip = false
        noclipBtn.Text = "NoClip: OFF"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    end
    if wallhack then
        wallhack = false
        wallBtn.Text = "Wallhack: OFF"
        wallBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
        removeAllESP()
    end
    -- ล้างค่าฟิสิกส์และกล้อง
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if root and hum then
            hum:ChangeState(Enum.HumanoidStateType.Running)
            -- ลบ BodyVelocity / BodyGyro
            for _, v in pairs(root:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
            end
            root.Anchored = false
        end
        -- Reset speed
        if hum then hum.WalkSpeed = 16 end
    end
    -- ล้าง waypoint
    for _, wp in pairs(waypointsList) do
        if wp.VisualPart then wp.VisualPart:Destroy() end
    end
    waypointsList = {}
    waypointCount = 0
    updateWaypointUI()
end

player.CharacterAdded:Connect(function()
    -- รอให้ตัวละคร spawn ก่อน
    local function onChar(char)
        resetAll()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speedValue end
    end
    onChar(player.Character)
end)

-- ============================
-- 10. Render Loop
-- ============================
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- ระบบบิน
    if fly then
        local bVel = root:FindFirstChildOfClass("BodyVelocity")
        local bGyro = root:FindFirstChildOfClass("BodyGyro")
        if bVel and bGyro then
            hum:ChangeState(Enum.HumanoidStateType.Physics) -- Lock model
            local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
            local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit
            local mX, mZ = 0, 0
            if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then mZ = mZ + 1 end
            if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then mZ = mZ - 1 end
            if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then mX = mX - 1 end
            if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then mX = mX + 1 end
            local hVel = (mX ~= 0 or mZ ~= 0) and ((forward * mZ) + (right * mX)).Unit or Vector3.new(0,0,0)
            bGyro.CFrame = CFrame.lookAt(root.Position, root.Position + (hVel.Magnitude > 0 and hVel or forward))
            local vVel = 0
            if UIS:IsKeyDown(Enum.KeyCode.Space) then vVel = 1 end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vVel = -1 end
            bVel.Velocity = (hVel * speedValue) + Vector3.new(0, vVel * speedValue, 0)
        end
    end

    -- ระบบ V Blink
    if V_Blink_Toggle then
        -- พุ่งทะลุ 5 เมตร
        local rootPos = root.Position
        local lookDir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
        if UIS:IsKeyDown(Enum.KeyCode.V) then
            -- ใช้ AssemblyLinearVelocity ล้างค่า
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
            root.Velocity = Vector3.new(0,0,0)
            root.CFrame = root.CFrame * CFrame.new(lookDir * 5)
        end
    end

    -- ระบบกล้องและวาร์ปผ่านจุด Waypoint
    -- (ถ้าคุณต้องการให้เป็น optional ก็แค่เปิด/ปิดตาม)
end)

-- เพิ่มกลไกใน CharacterAdded เพื่อรีเซ็ตสถานะทุกอย่าง
player.CharacterAdded:Connect(function()
    wait(0.1) -- รอให้ตัวละคร spawn เสร็จ
    resetAll()
    -- ตั้งค่าความเร็วให้ทันที
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speedValue end
end)
