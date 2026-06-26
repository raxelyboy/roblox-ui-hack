local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Prompts = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- [[ Global States ]]
local speedValue = 16
local noclip = false
local fly = false
local wallhack = false
local astralActive = false
local blinkEnabled = false

local waypointsList = {}
local waypointCount = 0
local cameraRotX, cameraRotY = 0, 0
local speedDragging = false

local fakeCamPart = nil
local markerPart = nil
local ESP_TAG = "AIO_Perfect_ESP"
local WP_FLAG_TAG = "AIO_Waypoint_Flag"

-- ============================
-- 1. UI Setup
-- ============================
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AIO_Ultimate_FixedMenu"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 340, 0, 500)
frame.Position = UDim2.new(0.5, -170, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Drag functionality
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
local destroyBtn = Instance.new("TextButton", frame)
destroyBtn.Size = UDim2.new(0, 26, 0, 26)
destroyBtn.Position = UDim2.new(1, -36, 0, 7)
destroyBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
destroyBtn.Text = "X"
destroyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyBtn.Font = Enum.Font.SourceSansBold
destroyBtn.TextSize = 14
destroyBtn.BorderSizePixel = 0
Instance.new("UICorner", destroyBtn).CornerRadius = UDim.new(0, 5)
destroyBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- ============================
-- 2. Speed Slider
-- ============================
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

-- ============================
-- 3. Button creation helper
-- ============================
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

-- Buttons
local noclipBtn = createMenuButton("NoClip: OFF", Color3.fromRGB(55, 55, 55))
local flyBtn = createMenuButton("Fly System: OFF", Color3.fromRGB(55, 55, 55))
local wallBtn = createMenuButton("Wallhack: OFF", Color3.fromRGB(55, 55, 55))
local astralBtn = createMenuButton("Astral Form: OFF", Color3.fromRGB(55, 55, 55))
local blinkBtn = createMenuButton("Blink (V Key): OFF", Color3.fromRGB(55, 55, 55))
local setWpBtn = createMenuButton("📌 Set Waypoint", Color3.fromRGB(0, 110, 180))
local tpAstralBtn = createMenuButton("⚡ TP to Astral Marker", Color3.fromRGB(0, 150, 90))
tpAstralBtn.Visible = false

-- ============================
-- 4. NoClip & Wallhack
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
    end
end)

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

wallBtn.MouseButton1Click:Connect(function()
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
end)

Players.PlayerAdded:Connect(function(p)
    applyESP(p)
end)

-- ============================
-- 5. Fly System
-- ============================
local function disableFly()
    fly = false
    flyBtn.Text = "Fly System: OFF"
    flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if root and hum then
        hum:ChangeState(Enum.HumanoidStateType.Running)
        local bVel = root:FindFirstChildOfClass("BodyVelocity")
        local bGyro = root:FindFirstChildOfClass("BodyGyro")
        if bVel then bVel:Destroy() end
        if bGyro then bGyro:Destroy() end
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
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        local bg = Instance.new("BodyGyro", root)
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.CFrame = root.CFrame
    else
        disableFly()
    end
    flyBtn.Text = fly and "Fly System: ON" or "Fly System: OFF"
    flyBtn.BackgroundColor3 = fly and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
end

flyBtn.MouseButton1Click:Connect(toggleFly)

-- ============================
-- 6. Astral Form
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
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            cam.CameraSubject = hum
            hum.AutoRotate = true
        end
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
        if fly then
            disableFly()
        end
        -- Set camera to scriptable mode
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
        if rootPart then
            rootPart.Anchored = true
        end
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

tpAstralBtn.MouseButton1Click:Connect(teleportToMarker)

-- ============================
-- 7. V Teleport & Waypoints
-- ============================
blinkBtn.MouseButton1Click:Connect(function()
    blinkEnabled = not blinkEnabled
    blinkBtn.Text = blinkEnabled and "Blink (V Key): ON" or "Blink (V Key): OFF"
    blinkBtn.BackgroundColor3 = blinkEnabled and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= Enum.KeyCode.V or not blinkEnabled or astralActive then return end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    task.spawn(function()
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        local lookDir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
        for i = 1, 12 do
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
            root.Velocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end)

local function updateWaypointUI()
    -- Clear existing
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    -- Populate with new waypoints
    for id, wpData in pairs(waypointsList) do
        local frameItem = Instance.new("Frame", scrollFrame)
        frameItem.Size = UDim2.new(1, -10, 0, 36)
        frameItem.BackgroundTransparency = 1

        local tpBtn = Instance.new("TextButton", frameItem)
        tpBtn.Size = UDim2.new(0, 205, 1, -4)
        tpBtn.Position = UDim2.new(0, 5, 0, 2)
        tpBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 50)
        tpBtn.Text = "⚡ " .. wpData.Name
        tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpBtn.Font = Enum.Font.SourceSansBold
        tpBtn.TextSize = 13
        tpBtn.BorderSizePixel = 0
        Instance.new("UICorner", tpBtn)

        local delBtn = Instance.new("TextButton", frameItem)
        delBtn.Size = UDim2.new(0, 55, 1, -4)
        delBtn.Position = UDim2.new(0, 215, 0, 2)
        delBtn.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
        delBtn.Text = "Delete"
        delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        delBtn.Font = Enum.Font.SourceSansBold
        delBtn.TextSize = 11
        delBtn.BorderSizePixel = 0
        Instance.new("UICorner", delBtn)

        tpBtn.MouseButton1Click:Connect(function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                if fly then disableFly() end
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.CFrame = wpData.CFrame + Vector3.new(0, 1.2, 0)
                task.wait(0.06)
                root.Anchored = false
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)

        delBtn.MouseButton1Click:Connect(function()
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
    flag.Size = Vector3.new(0.5, 7, 0.5)
    flag.Material = Enum.Material.Neon
    flag.Color = Color3.fromRGB(0, 255, 100)
    flag.Transparency = 0.4
    flag.Anchored = true
    flag.CanCollide = false
    flag.CFrame = root.CFrame * CFrame.new(0, -1, 0)
    local hl = Instance.new("Highlight", flag)
    hl.FillColor = Color3.fromRGB(0, 255, 100)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    table.insert(waypointsList, {Name = "Waypoint " .. waypointCount, CFrame = root.CFrame, VisualPart = flag})
    updateWaypointUI()
end)

-- ============================
-- 8. Reset on Character Spawn
-- ============================
local function onCharacterSpawn(char)
    -- Reset states
    fly = false
    noclip = false
    disableFly()
    disableAstral()

    noclipBtn.Text, flyBtn.Text = "NoClip: OFF", "Fly System: OFF"
    noclipBtn.BackgroundColor3, flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55), Color3.fromRGB(55, 55, 55)

    -- Clear waypoints
    for _, wpData in pairs(waypointsList) do
        if wpData.VisualPart then wpData.VisualPart:Destroy() end
        local flag = Instance.new("Part", workspace)
        flag.Name = WP_FLAG_TAG
        flag.Size = Vector3.new(0.5, 7, 0.5)
        flag.Material = Enum.Material.Neon
        flag.Color = Color3.fromRGB(0, 255, 100)
        flag.Transparency = 0.4
        flag.Anchored = true
        flag.CanCollide = false
        flag.CFrame = wpData.CFrame * CFrame.new(0, -1, 0)
        local hl = Instance.new("Highlight", flag)
        hl.FillColor = Color3.fromRGB(0, 255, 100)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        wpData.VisualPart = flag
    end

    local hum = nil
    if player.Character then
        hum = player.Character:FindFirstChildOfClass("Humanoid")
    end
    if hum then hum.WalkSpeed = speedValue end
end

player.CharacterAdded:Connect(onCharacterSpawn)
if player.Character then
    onCharacterSpawn(player.Character)
end

-- ============================
-- 9. Render Loop (Main)
-- ============================
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    -- Fly movement
    if fly and root and hum and hum.Health > 0 then
        local bVel = root:FindFirstChildOfClass("BodyVelocity")
        local bGyro = root:FindFirstChildOfClass("BodyGyro")
        if bVel and bGyro then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
            local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit
            local mX, mZ = 0, 0
            if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then mZ = mZ + 1 end
            if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then mZ = mZ - 1 end
            if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then mX = mX - 1 end
            if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then mX = mX + 1 end
            local hVel = (mX ~= 0 or mZ ~= 0) and ((look * mZ) + (right * mX)).Unit or Vector3.new(0, 0, 0)
            bGyro.CFrame = CFrame.lookAt(root.Position, root.Position + (hVel.Magnitude > 0 and hVel or look))
            local vVel = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
            bVel.Velocity = (hVel * speedValue) + Vector3.new(0, vVel * speedValue, 0)
        end
    end

    -- Astral control
    if astralActive and fakeCamPart then
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            local mouseDelta = UIS:GetMouseDelta()
            cameraRotX = cameraRotX - (mouseDelta.X * (MOUSE_SENSITIVITY / 100))
            cameraRotY = cameraRotY - (mouseDelta.Y * (MOUSE_SENSITIVITY / 100))
            cameraRotY = math.clamp(cameraRotY, math.rad(-89), math.rad(89))
        else
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
        camera.CFrame = CFrame.new(camera.CFrame.Position) *
            CFrame.Angles(0, cameraRotX, 0) *
            CFrame.Angles(cameraRotY, 0, 0)

        -- Move camera
        local moveVector = Vector3.new(0, 0, 0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector = moveVector - Vector3.new(0, 1, 0) end

        if moveVector.Magnitude > 0 then
            camera.CFrame = camera.CFrame + (moveVector.Unit * CAM_SPEED)
            if fakeCamPart then fakeCamPart.CFrame = camera.CFrame end
        end

        -- Update marker position
        if markerPart then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {char, markerPart}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local raycastResult = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, -600, 0), raycastParams)
            local targetY = camera.CFrame.Position.Y - 3
            if raycastResult then
                targetY = raycastResult.Position.Y + 1.75
            end
            markerPart.CFrame = CFrame.lookAt(Vector3.new(camera.CFrame.Position.X, targetY, camera.CFrame.Position.Z),
                Vector3.new(camera.CFrame.Position.X, targetY, camera.CFrame.Position.Z) + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)) * CFrame.Angles(0, 0, math.rad(90))
        end
    end
end)

-- ============================
-- 10. Additional: Character Spawn Handling
-- ============================
local function onCharacterSpawn(char)
    -- Reset states
    fly = false
    noclip = false
    disableFly()
    disableAstral()

    noclipBtn.Text, flyBtn.Text = "NoClip: OFF", "Fly System: OFF"
    noclipBtn.BackgroundColor3, flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55), Color3.fromRGB(55, 55, 55)

    -- Clear waypoints
    for _, wpData in pairs(waypointsList) do
        if wpData.VisualPart then wpData.VisualPart:Destroy() end
        local flag = Instance.new("Part", workspace)
        flag.Name = WP_FLAG_TAG
        flag.Size = Vector3.new(0.5, 7, 0.5)
        flag.Material = Enum.Material.Neon
        flag.Color = Color3.fromRGB(0, 255, 100)
        flag.Transparency = 0.4
        flag.Anchored = true
        flag.CanCollide = false
        flag.CFrame = wpData.CFrame * CFrame.new(0, -1, 0)
        local hl = Instance.new("Highlight", flag)
        hl.FillColor = Color3.fromRGB(0, 255, 100)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        wpData.VisualPart = flag
    end

    local hum = nil
    if player.Character then
        hum = player.Character:FindFirstChildOfClass("Humanoid")
    end
    if hum then hum.WalkSpeed = speedValue end
end

player.CharacterAdded:Connect(onCharacterSpawn)
if player.Character then
    onCharacterSpawn(player.Character)
end
