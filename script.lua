local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function CreateESP(player)
    local bg = Instance.new("BillboardGui")
    local container = Instance.new("Frame")
    local nameLabel = Instance.new("TextLabel")
    local infoLabel = Instance.new("TextLabel")
    local healthBarBack = Instance.new("Frame")
    local healthBarFill = Instance.new("Frame")

    -- Setup Billboard (Agar nempel di atas kepala pemain)
    bg.Name = "AlifwagESP"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 200, 0, 100)
    bg.ExtentsOffset = Vector3.new(0, 3, 0)
    bg.Parent = CoreGui -- Atau game.CoreGui

    -- Container Utama
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = bg

    -- Nama Pemain
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.RobotoBold
    nameLabel.Parent = container

    -- Info Detail (Senjata, Speed, Jump, Jarak)
    infoLabel.Size = UDim2.new(1, 0, 0, 60)
    infoLabel.Position = UDim2.new(0, 0, 0, 20)
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextStrokeTransparency = 0
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.Parent = container

    -- Health Bar (Darah)
    healthBarBack.Size = UDim2.new(0.5, 0, 0, 4)
    healthBarBack.Position = UDim2.new(0.25, 0, 0, 18)
    healthBarBack.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBarBack.BorderSizePixel = 0
    healthBarBack.Parent = container

    healthBarFill.Size = UDim2.new(1, 0, 1, 0)
    healthBarFill.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBarFill.BorderSizePixel = 0
    healthBarFill.Parent = healthBarBack

    -- Tembus Tembok (Highlight)
    local highlight = Instance.new("Highlight")
    highlight.Name = "SkeletonESP"
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character

    -- Fungsi Update Real-Time
    local function Update()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                local hum = char.Humanoid
                local hrp = char.HumanoidRootPart
                
                -- Update Jarak & Posisi
                local distance = math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                bg.Adornee = hrp

                -- Update Darah
                healthBarFill.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)
                if hum.Health < 30 then 
                    healthBarFill.BackgroundColor3 = Color3.new(1, 0, 0)
                else 
                    healthBarFill.BackgroundColor3 = Color3.new(0, 1, 0)
                end

                -- Deteksi Senjata
                local tool = char:FindFirstChildOfClass("Tool")
                local toolName = tool and tool.Name or "Tangan Kosong"

                -- Update Teks (Tanpa Simbol - atau //)
                nameLabel.Text = player.Name
                infoLabel.Text = string.format(
                    "Senjata %s\nSpeed %d\nJump %d\nJarak %d Meter",
                    toolName,
                    math.floor(hum.WalkSpeed),
                    math.floor(hum.JumpPower),
                    distance
                )
            else
                bg:Destroy()
                highlight:Destroy()
                connection:Disconnect()
            end
        end)
    end
    Update()
end

-- Menjalankan untuk semua pemain
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function() CreateESP(p) end)
        if p.Character then CreateESP(p) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() CreateESP(p) end)
end)
