local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Konfigurasi
local DETECTION_THRESHOLD = 50 -- Semakin tinggi semakin tidak sensitif (mencegah salah deteksi)
local SPEED_THRESHOLD = 80    -- Batas jarak perpindahan instan

local trackData = {}

-- Fungsi untuk membuat Skeleton ESP
local function applyESP(player)
    local char = player.Character or player.CharacterAdded:Wait()
    
    -- Menghapus ESP lama jika ada
    if char:FindFirstChild("DetectorESP") then
        char.DetectorESP:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "DetectorESP"
    highlight.Parent = char
    highlight.FillTransparency = 0.5 -- Transparansi tubuh
    highlight.OutlineTransparency = 0 -- Garis tepi (tulang) tebal
    highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Default Hijau
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
end

-- Jalankan ESP saat pemain masuk atau respawn
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function() applyESP(p) end)
        if p.Character then applyESP(p) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() applyESP(p) end)
end)

-- Loop Utama Deteksi
RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChild("Humanoid")
            local esp = char:FindFirstChild("DetectorESP")
            
            if not trackData[player.Name] then
                trackData[player.Name] = {airTime = 0, lastPos = hrp.Position, isHacker = false}
            end

            -- 1. LOGIKA DETEKSI FLY
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {char}
            local raycastResult = workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), raycastParams)

            -- Cek apakah melayang (bukan jatuh atau naik tangga)
            if not raycastResult and math.abs(hrp.Velocity.Y) < 5 then
                trackData[player.Name].airTime = trackData[player.Name].airTime + 1
            else
                trackData[player.Name].airTime = 0
            end

            -- 2. LOGIKA DETEKSI SPEED/TP
            local currentPos = hrp.Position
            local distance = (Vector2.new(currentPos.X, currentPos.Z) - Vector2.new(trackData[player.Name].lastPos.X, trackData[player.Name].lastPos.Z)).Magnitude
            
            -- Penentuan Status Hacker
            if trackData[player.Name].airTime > DETECTION_THRESHOLD or distance > SPEED_THRESHOLD then
                trackData[player.Name].isHacker = true
            else
                -- Jangan langsung hapus status hacker agar Anda sempat melihatnya
                -- Status akan reset jika mereka berperilaku normal selama 5 detik
            end

            -- Update Warna ESP (Hijau = Aman, Merah = Hacker)
            if esp then
                if trackData[player.Name].isHacker then
                    esp.FillColor = Color3.fromRGB(255, 0, 0)
                    esp.OutlineColor = Color3.fromRGB(255, 255, 0) -- Kuning terang untuk tulang hacker
                    
                    if not hrp:FindFirstChild("HackerTag") then
                        local bbg = Instance.new("BillboardGui", hrp)
                        bbg.Name = "HackerTag"
                        bbg.Size = UDim2.new(4, 0, 1, 0)
                        bbg.AlwaysOnTop = true
                        bbg.ExtentsOffset = Vector3.new(0, 3, 0)
                        local txt = Instance.new("TextLabel", bbg)
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.Text = "!! HACKER DETECTED !!"
                        txt.TextColor3 = Color3.new(1, 0, 0)
                        txt.BackgroundTransparency = 1
                        txt.TextScaled = true
                    end
                else
                    esp.FillColor = Color3.fromRGB(0, 255, 0)
                    esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
            end
            
            trackData[player.Name].lastPos = hrp.Position
        end
    end
end)

print("Shield Active: Green = Safe, Red = Hacker")
