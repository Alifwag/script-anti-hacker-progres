local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Global States
local ESP_ENABLED = false
local DETECTOR_ENABLED = false
local trackData = {}

----------------------------------------------------------------
-- 1. LOADING SCREEN
----------------------------------------------------------------
local loaderGui = Instance.new("ScreenGui", CoreGui)
local loadFrame = Instance.new("Frame", loaderGui)
loadFrame.Size = UDim2.new(0, 300, 0, 100)
loadFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
loadFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
loadFrame.BorderSizePixel = 0

local loadLabel = Instance.new("TextLabel", loadFrame)
loadLabel.Size = UDim2.new(1, 0, 1, 0)
loadLabel.Text = "Alifwag Shield Loading..."
loadLabel.TextColor3 = Color3.new(1, 1, 1)
loadLabel.BackgroundTransparency = 1
loadLabel.TextSize = 20

local barBackground = Instance.new("Frame", loadFrame)
barBackground.Size = UDim2.new(0.8, 0, 0, 10)
barBackground.Position = UDim2.new(0.1, 0, 0.8, 0)
barBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

local barFill = Instance.new("Frame", barBackground)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 127)

-- Animasi Loading
for i = 0, 1, 0.1 do
    barFill.Size = UDim2.new(i, 0, 1, 0)
    task.wait(0.2)
end
loaderGui:Destroy()

----------------------------------------------------------------
-- 2. MENU GUI (MAIN)
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "AlifwagMenu"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 250)
mainFrame.Position = UDim2.new(0.1, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true -- Bisa digeser di layar HP

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "SHIELD MENU"
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18

-- Fungsi Buat Tombol
local function createButton(name, pos, color)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Name = name
    btn.Size = UDim2.new(0.8, 0, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = name .. ": OFF"
    btn.AutoButtonColor = true
    return btn
end

local espBtn = createButton("ESP", UDim2.new(0.1, 0, 0.25, 0), Color3.fromRGB(150, 0, 0))
local detBtn = createButton("DETECTOR", UDim2.new(0.1, 0, 0.5, 0), Color3.fromRGB(150, 0, 0))

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0.8, 0, 0, 30)
closeBtn.Position = UDim2.new(0.1, 0, 0.8, 0)
closeBtn.Text = "CLOSE MENU"
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeBtn.TextColor3 = Color3.new(1, 1, 1)

----------------------------------------------------------------
-- 3. LOGIKA FITUR
----------------------------------------------------------------

-- Toggle ESP
espBtn.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    espBtn.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
    espBtn.BackgroundColor3 = ESP_ENABLED and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    
    if not ESP_ENABLED then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("DetectorESP") then
                p.Character.DetectorESP:Destroy()
            end
        end
    end
end)

-- Toggle Detector
detBtn.MouseButton1Click:Connect(function()
    DETECTOR_ENABLED = not DETECTOR_ENABLED
    detBtn.Text = "DETECTOR: " .. (DETECTOR_ENABLED and "ON" or "OFF")
    detBtn.BackgroundColor3 = DETECTOR_ENABLED and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
    print("Ketik reload script di executor untuk buka lagi.")
end)

-- Fungsi ESP Bone
local function applyESP(player)
    if not ESP_ENABLED then return end
    local char = player.Character
    if char and not char:FindFirstChild("DetectorESP") then
        local hl = Instance.new("Highlight", char)
        hl.Name = "DetectorESP"
        hl.FillTransparency = 0.5
        hl.FillColor = Color3.new(0, 1, 0)
    end
end

-- Main Loop
RunService.Heartbeat:Connect(function()
    if not DETECTOR_ENABLED and not ESP_ENABLED then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local hrp = char.HumanoidRootPart
            
            -- Jalankan ESP jika ON
            if ESP_ENABLED then applyESP(player) end
            
            -- Jalankan Deteksi jika ON
            if DETECTOR_ENABLED then
                if not trackData[player.Name] then
                    trackData[player.Name] = {airTime = 0, lastPos = hrp.Position, isHacker = false}
                end

                -- Deteksi Fly
                local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0))
                if not ray and math.abs(hrp.Velocity.Y) < 5 then
                    trackData[player.Name].airTime = trackData[player.Name].airTime + 1
                else
                    trackData[player.Name].airTime = 0
                end

                -- Update Warna
                local esp = char:FindFirstChild("DetectorESP")
                if esp then
                    if trackData[player.Name].airTime > 50 then
                        esp.FillColor = Color3.new(1, 0, 0) -- MERAH (HACKER)
                    else
                        esp.FillColor = Color3.new(0, 1, 0) -- HIJAU (AMAN)
                    end
                end
            end
        end
    end
end)
