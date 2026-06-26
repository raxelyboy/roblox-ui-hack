-- [[ AIO ULTIMATE PLAYER CONTROLS - FIXED VERSION ]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Prompts = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- [[ Global States ]]
local speedValue = 16
local noclip = false
local fly = false
local wallhack = false
local waypointsList = {}
local waypointCount = 0

local bodyVelocity, bodyGyro
local ESP_TAG = "AIO_Ultra_ESP"
local WP_FLAG_TAG = "AIO_Waypoint_Flag"
local speedDragging = false

-- ==========================================
-- 1. โครงสร้างหน้าต่างเมนูหลัก (UI Setup)
-- ==========================================
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AIO_Perfect_Controls"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 340, 0, 460)
frame.Position = UDim2.new(0.5, -170, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- ระบบลากหน้าต่าง UI (แยกส่วนเด็ดขาดไม่แย่งเมาส์)
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input, gp)
	if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dragStart = input.Position; startPos = frame.Position
	end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ PERFECT CONTROL MENU"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

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

-- ==========================================
-- 2. ระบบสไลเดอร์ปรับความเร็ว (Speed Slider)
-- ==========================================
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
slider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then speedDragging = true end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then speedDragging = false end end)
UIS.InputChanged:Connect(function(input) if speedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSpeed(input.Position.X) end end)

-- ฟังก์ชันสร้างปุ่มเมนูให้จัดวางแบบ Grid
local bCount = 0
local function createMenuButton(txt, col)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0, 145, 0, 36)
	b.Position = UDim2.new(0, (bCount % 2 == 0) and 15 or 180, 0, 85 + (math.floor(bCount / 2) * 42))
	b.BackgroundColor3 = col
	b.Text = txt
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 14
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	bCount = bCount + 1
	return b
end

local noclipBtn = createMenuButton("NoClip: OFF", Color3.fromRGB(55, 55, 55))
local flyBtn    = createMenuButton("Fly System: OFF", Color3.fromRGB(55, 55, 55))
local wallBtn   = createMenuButton("Wallhack: OFF", Color3.fromRGB(55, 55, 55))
local setWpBtn  = createMenuButton("📌 Set Waypoint", Color3.fromRGB(0, 110, 180))

-- ส่วนแสดงรายการจุดวาร์ป (ScrollingFrame)
local scrollTitle = Instance.new("TextLabel", frame)
scrollTitle.Size = UDim2.new(1, -30, 0, 20)
scrollTitle.Position = UDim2.new(0, 15, 0, 175)
scrollTitle.BackgroundTransparency = 1
scrollTitle.Text = "Saved Locations List:"
scrollTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
scrollTitle.Font = Enum.Font.SourceSansBold
scrollTitle.TextSize = 13
scrollTitle.TextXAlignment = Enum.TextXAlignment.Left

local scrollFrame = Instance.new("ScrollingFrame", frame)
scrollFrame.Size = UDim2.new(1, -30, 0, 245)
scrollFrame.Position = UDim2.new(0, 15, 0, 200)
scrollFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
Instance.new("UICorner", scrollFrame)

local listLayout = Instance.new("UIListLayout", scrollFrame)
listLayout.Padding = UDim.new(0, 5)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- ==========================================
-- 3. ฟังก์ชันการทำงาน: NoClip & Fly (แก้ไขปิดคอลลิชันได้จริง + บินตัวไม่แข็ง)
-- ==========================================
noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.Text = noclip and "NoClip: ON" or "NoClip: OFF"
	noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)
end)

RunService.Stepped:Connect(function()
	if player.Character then
		for _, v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = not noclip -- ปิดเมื่อเป็น true คืนค่าชนปกติเมื่อเป็น false
			end
		end
	end
end)

local function disableFly()
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
end

flyBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	if not root or not hum then return end

	fly = not fly
	flyBtn.Text = fly and "Fly System: ON" or "Fly System: OFF"
	flyBtn.BackgroundColor3 = fly and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(55, 55, 55)

	if fly then
		hum:ChangeState(Enum.HumanoidStateType.Physics) -- ปล่อยสถานะให้เคลื่อนไหว W,A,S,D ได้ปกติ
		bodyVelocity = Instance.new("BodyVelocity", root)
		bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyGyro = Instance.new("BodyGyro", root)
		bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		bodyGyro.CFrame = root.CFrame
	else
		disableFly()
	end
end)

-- ==========================================
-- 4. ฟังก์ชันการทำงาน: Wallhack ESP เห็นทุกคน
-- ==========================================
local function removeAllESP()
	for _, p in pairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild(ESP_TAG) then p.Character[ESP_TAG]:Destroy() end
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
		for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
	else
		removeAllESP()
	end
end)
Players.PlayerAdded:Connect(applyESP)

-- ==========================================
-- 5. ฟังก์ชันการทำงาน: ระบบเซฟจุดวาร์ปได้หลายที่ (Multi-Waypoint List)
-- ==========================================
local function updateWaypointListUI()
	for _, child in pairs(scrollFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
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
Instance.new("UICorner", tp).CornerRadius = UDim.new(0, 5)

local del = Instance.new("TextButton", r)
del.Size = UDim2.new(0, 55, 1, -4)
del.Position = UDim2.new(0, 215, 0, 2)
del.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
del.Text = "Delete"
del.TextColor3 = Color3.fromRGB(255, 255, 255)
del.Font = Enum.Font.SourceSansBold
del.TextSize = 11
del.BorderSizePixel = 0
Instance.new("UICorner", del).CornerRadius = UDim.new(0, 5)

tp.MouseButton1Click:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if root and hum and hum.Health > 0 then
        if fly then
            fly = false
            disableFly()
            flyBtn.Text = "Fly System: OFF"
            flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        end

        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

        root.Anchored = true
        root.CFrame = wpData.CFrame + Vector3.new(0, 1.2, 0)

        task.wait(0.06)

        root.Anchored = false
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end)

del.MouseButton1Click:Connect(function()
    if wpData.VisualPart then
        wpData.VisualPart:Destroy()
    end

    table.remove(waypointsList, id)
    updateWaypointListUI()
end)

end

scrollFrame.CanvasSize = UDim2.new(
    0,
    0,
    0,
    listLayout.AbsoluteContentSize.Y + 10
)

end

setWpBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

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

    table.insert(waypointsList, {
        Name = "Waypoint " .. waypointCount,
        CFrame = root.CFrame,
        VisualPart = flag
    })

    updateWaypointListUI()
end)

-- ==========================================
-- 6. ฟังก์ชันการทำงาน: ปุ่ม V ดับเบิ้ลวาร์ปทะลุกำแพงหนา 5 เมตร
-- ==========================================

local isBlinking = false

UIS.InputBegan:Connect(function(input, gp)
    if gp
        or input.KeyCode ~= Enum.KeyCode.V
        or fly
        or astralActive
        or isBlinking then
        return
    end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if not root or not hum or hum.Health <= 0 then
        return
    end

    isBlinking = true

    local forwardDirection =
        Vector3.new(
            root.CFrame.LookVector.X,
            0,
            root.CFrame.LookVector.Z
        ).Unit

    local targetPosition =
        root.Position + (forwardDirection * 16.4)

    local oldCollision = {}

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            oldCollision[v] = true
            v.CanCollide = false
        end
    end

    root.Velocity = Vector3.new(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

    hum:ChangeState(Enum.HumanoidStateType.Physics)

    local targetCFrame =
        CFrame.new(
            targetPosition + Vector3.new(0, 0.3, 0),
            targetPosition + forwardDirection
        )

    local tween = TweenService:Create(
        root,
        TweenInfo.new(0.08, Enum.EasingStyle.QuadOut),
        {
            CFrame = targetCFrame
        }
    )

    tween:Play()
    tween.Completed:Wait()

    root.Velocity = Vector3.new(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

    hum:ChangeState(Enum.HumanoidStateType.Running)

    for part, _ in pairs(oldCollision) do
        if part and part.Parent then
            part.CanCollide = true
        end
    end

    isBlinking = false
end)

Prompts.PromptAdded:Connect(function(p)
    if p then
        p.RequiresLineOfSight = false
    end
end)

-- ==========================================
-- 7. Reset On Spawn
-- ==========================================

local function onCharacterSpawn(char)
    fly = false
    noclip = false

    disableFly()

    noclipBtn.Text = "NoClip: OFF"
    noclipBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)

    flyBtn.Text = "Fly System: OFF"
    flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)

    for _, wpData in pairs(waypointsList) do
        if wpData.CFrame then
            if wpData.VisualPart then
                wpData.VisualPart:Destroy()
            end

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
    end

    local hum = char:WaitForChild("Humanoid", 6)

    if hum then
        hum.WalkSpeed = speedValue
    end
end

if player.Character then
    onCharacterSpawn(player.Character)
end

player.CharacterAdded:Connect(onCharacterSpawn)
