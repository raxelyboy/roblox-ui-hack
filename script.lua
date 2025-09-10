--// Roblox Exploit UI Script: Red-Black Theme
--// รวม Speed, Fly, Noclip, ESP (ชื่อ+สีเพื่อน), Godmode Ultimate
--// ปรับ mainFrame ให้ใหญ่พอสำหรับปุ่มใหญ่ + ช่องว่าง

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- สร้าง ScreenGui
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.ResetOnSpawn = false

-- ปุ่มหลักเปิด/ปิด UI
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = ScreenGui
toggleButton.Size = UDim2.new(0, 200, 0, 40)
toggleButton.Position = UDim2.new(0.5, -100, 0, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
toggleButton.BackgroundTransparency = 0.3
toggleButton.Text = "ราเชนทร์"
toggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleButton.Font = Enum.Font.Arial
toggleButton.TextSize = 22

-- UI หลัก (ขยายให้พอดีกับปุ่มใหญ่ + เหลือพื้นที่ด้านบน-ล่าง)
local buttonCount = 5
local buttonHeight = 40 * 1.4
local buttonSpacing = 10
local framePadding = 20

local mainFrame = Instance.new("Frame")
mainFrame.Parent = ScreenGui
mainFrame.Size = UDim2.new(0, 475, 0, buttonCount * (buttonHeight + buttonSpacing) + framePadding * 2)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -(mainFrame.Size.Y.Offset / 2))
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
mainFrame.BackgroundTransparency = 0.2
mainFrame.Visible = false

-- ทำให้ลากได้
local dragging, dragStart, startPos
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ฟังก์ชันสร้างปุ่ม
local function createButton(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = mainFrame
    btn.Size = UDim2.new(0, 260*1.4, 0, buttonHeight)
    btn.Position = UDim2.new(0.5, -182, 0, framePadding + (order-1) * (buttonHeight + buttonSpacing))
    btn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Arial
    btn.TextSize = 22
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        end
        callback(state)
    end)
end

-- Toggle UI
toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-------------------------------------------------------------------
-- ฟังก์ชันจริง

-- Speed
local function setSpeed(on)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = on and 100 or 16
    end
end

-- Fly
local flyConn, flyBV
local function setFly(on)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if on then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = hrp
        flyConn = RunService.RenderStepped:Connect(function()
            local vel = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                vel = vel + (workspace.CurrentCamera.CFrame.LookVector * 60)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                vel = vel - (workspace.CurrentCamera.CFrame.LookVector * 60)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                vel = vel + Vector3.new(0,60,0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                vel = vel - Vector3.new(0,60,0)
            end
            flyBV.Velocity = vel
        end)
    else
        if flyConn then flyConn:Disconnect() flyConn=nil end
        if flyBV then flyBV:Destroy() flyBV=nil end
    end
end

-- Noclip
local noclipConn
local function setNoclip(on)
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            if player.Character then
                for _,v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() noclipConn=nil end
    end
end

-- ESP
local espConn
local function setESP(on)
    if on then
        espConn = RunService.RenderStepped:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    if not plr.Character:FindFirstChild("ESP") then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Name = "ESP"
                        box.Adornee = plr.Character.HumanoidRootPart
                        box.AlwaysOnTop = true
                        box.ZIndex = 0
                        box.Size = Vector3.new(4,6,1)
                        box.Transparency = 0.5
                        if player:IsFriendsWith(plr.UserId) then
                            box.Color3 = Color3.fromRGB(0,0,255) -- เพื่อน = ฟ้า
                        else
                            box.Color3 = Color3.fromRGB(255,0,0)
                        end
                        box.Parent = plr.Character

                        local billboard = Instance.new("BillboardGui", plr.Character)
                        billboard.Name = "ESPName"
                        billboard.Size = UDim2.new(0,200,0,50)
                        billboard.AlwaysOnTop = true
                        billboard.Adornee = plr.Character.Head

                        local textLabel = Instance.new("TextLabel", billboard)
                        textLabel.Size = UDim2.new(1,0,1,0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.Text = plr.Name
                        textLabel.TextColor3 = Color3.new(1,1,1)
                        textLabel.Font = Enum.Font.Arial
                        textLabel.TextSize = 14
                    end
                end
            end
        end)
    else
        if espConn then espConn:Disconnect() espConn=nil end
        for _,plr in pairs(Players:GetPlayers()) do
            if plr.Character then
                if plr.Character:FindFirstChild("ESP") then
                    plr.Character.ESP:Destroy()
                end
                if plr.Character:FindFirstChild("ESPName") then
                    plr.Character.ESPName:Destroy()
                end
            end
        end
    end
end

-- GODMODE ULTIMATE
local godConn, humDiedConn, hbConn, ancestryConn
local function setGodmode(on)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if on then
        godConn = RunService.Heartbeat:Connect(function()
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
        humDiedConn = hum.Died:Connect(function()
            task.wait()
            hum.Health = hum.MaxHealth
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end)
        ancestryConn = hum.AncestryChanged:Connect(function(_, parent)
            if not parent then
                local newHum = Instance.new("Humanoid")
                newHum.Parent = char
                hum = newHum
            end
        end)
        hbConn = RunService.Heartbeat:Connect(function()
            if not char:FindFirstChildOfClass("Humanoid") then
                local newHum = Instance.new("Humanoid")
                newHum.Health, newHum.MaxHealth = 100,100
                newHum.Parent = char
                hum = newHum
            end
        end)
    else
        if godConn then godConn:Disconnect() godConn=nil end
        if humDiedConn then humDiedConn:Disconnect() humDiedConn=nil end
        if hbConn then hbConn:Disconnect() hbConn=nil end
        if ancestryConn then ancestryConn:Disconnect() ancestryConn=nil end
    end
end

-------------------------------------------------------------------
-- สร้างปุ่มทั้งหมด
createButton("วิ่งเร็ว", 1, setSpeed)
createButton("บิน", 2, setFly)
createButton("NoClip", 3, setNoclip)
createButton("ESP Player", 4, setESP)
createButton("อมตะ", 5, setGodmode)
