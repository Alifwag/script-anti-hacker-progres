-- script.lua
-- LETAKKAN: ServerScriptService (sebagai Script)
-- Fungsi: Deteksi server-side (fly / teleport/speed) + punishment,
--         dan inject LocalScript GUI/ESP ke setiap player's PlayerGui.
-- UJI DI STUDIO TERLEBIH DAHULU.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ========== KONFIGURASI ==========
local DETECTION_AIR_SECONDS = 2        -- detik melayang untuk dikategorikan mencurigakan
local SPEED_THRESHOLD = 80             -- studs per detik, threshold teleport/speed tinggi
local SAFE_RESET_SECONDS = 5           -- detik normal agar tag bisa dihapus
local PUNISH_ACTION = "kill"           -- "kill", "kick", atau "warn"
local PUNISH_MESSAGE = "Removed for cheating." -- pesan untuk kick
local PUNISH_COOLDOWN = 5              -- detik minimal antara punish berulang untuk pemain yang sama

-- Optional: whitelist userIds (admins/devs) yang tidak dipunish
local WHITELIST = {
    -- [12345678] = true,
}
-- ==================================

local track = {} -- track[userId] = { lastPos = Vector3, airTime = number, lastNormal = os.clock(), punishedAt = 0 }

local function ensureTrack(player)
    local id = player.UserId
    if not track[id] then
        track[id] = {
            lastPos = nil,
            airTime = 0,
            lastNormal = os.clock(),
            punishedAt = 0
        }
    end
    return track[id]
end

local function createHackerTag(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp:FindFirstChild("HackerTag") then return end

    local bbg = Instance.new("BillboardGui")
    bbg.Name = "HackerTag"
    bbg.Size = UDim2.new(4, 0, 1, 0)
    bbg.AlwaysOnTop = true
    bbg.ExtentsOffset = Vector3.new(0, 3, 0)
    bbg.Parent = hrp

    local txt = Instance.new("TextLabel", bbg)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Text = "!! HACKER DETECTED !!"
    txt.TextColor3 = Color3.new(1, 0, 0)
    txt.BackgroundTransparency = 1
    txt.TextScaled = true
end

local function removeHackerTag(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local tag = hrp:FindFirstChild("HackerTag")
    if tag then tag:Destroy() end
end

local function punishPlayer(player, reason)
    if not player or not player.Parent then return end
    if WHITELIST[player.UserId] then
        warn(("Shield: player %s is whitelisted, skipping punish."):format(player.Name))
        return
    end

    local data = ensureTrack(player)
    local now = os.time()
    if now - (data.punishedAt or 0) < PUNISH_COOLDOWN then
        return
    end
    data.punishedAt = now

    if PUNISH_ACTION == "kill" then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid.Health = 0
            end
        end
        createHackerTag(player)
        warn(("Shield: killed %s for %s"):format(player.Name, reason or "suspicious behavior"))
    elseif PUNISH_ACTION == "kick" then
        local ok, err = pcall(function()
            player:Kick(PUNISH_MESSAGE .. " (" .. tostring(reason or "cheating") .. ")")
        end)
        if not ok then
            warn("Shield: failed to kick", player.Name, err)
        else
            warn(("Shield: kicked %s for %s"):format(player.Name, reason or "suspicious behavior"))
        end
    elseif PUNISH_ACTION == "warn" then
        createHackerTag(player)
        warn(("Shield: warned %s for %s"):format(player.Name, reason or "suspicious behavior"))
    else
        warn("Shield: unknown PUNISH_ACTION:", PUNISH_ACTION)
    end
end

-- MAIN DETECTION LOOP (server authoritative)
RunService.Heartbeat:Connect(function(dt)
    if dt <= 0 then return end
    for _, player in pairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then
            ensureTrack(player)
        else
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid then
                local data = ensureTrack(player)

                -- Raycast ke bawah (blacklist character)
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {char}
                params.FilterType = Enum.RaycastFilterType.Blacklist
                local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), params)

                local vy = hrp.Velocity.Y

                -- Cek melayang: tidak kena ray di bawah & vertical velocity kecil
                if (not ray) and math.abs(vy) < 5 then
                    data.airTime = data.airTime + dt
                else
                    data.airTime = 0
                end

                -- Hitung kecepatan horizontal (studs/detik)
                local speed = 0
                if data.lastPos then
                    local curr = hrp.Position
                    local prev = data.lastPos
                    local horizDist = (Vector2.new(curr.X, curr.Z) - Vector2.new(prev.X, prev.Z)).Magnitude
                    if dt > 0 then speed = horizDist / dt end
                end

                local flagged = false
                if data.airTime >= DETECTION_AIR_SECONDS then
                    flagged = true
                end
                if speed >= SPEED_THRESHOLD then
                    flagged = true
                end

                if flagged then
                    punishPlayer(player, (data.airTime >= DETECTION_AIR_SECONDS and "airTime") or ("speed:" .. math.floor(speed)))
                    data.lastNormal = os.clock()
                else
                    -- normal behavior
                    data.lastNormal = os.clock()
                    if os.clock() - data.lastNormal >= SAFE_RESET_SECONDS then
                        removeHackerTag(player)
                    end
                end

                data.lastPos = hrp.Position
            end
        end
    end
end)

-- CLIENT GUI/ESP source (will be injected as LocalScript into each player's PlayerGui)
local clientSource = [[
-- Injected LocalScript: Client GUI + ESP (runs on client)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Parent adalah PlayerGui ketika script di-inject oleh server
local parentGui = script.Parent

-- Simple GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AlifwagMenu"
screenGui.Parent = parentGui

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 220)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1,0,0,40)
title.Position = UDim2.new(0,0,0,0)
title.Text = "SHIELD (Client)"
title.BackgroundColor3 = Color3.fromRGB(45,45,45)
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold

local espBtn = Instance.new("TextButton", mainFrame)
espBtn.Size = UDim2.new(0.8,0,0,40)
espBtn.Position = UDim2.new(0.1,0,0.2,0)
espBtn.Text = "ESP: OFF"
espBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
espBtn.TextColor3 = Color3.new(1,1,1)

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0.8,0,0,30)
closeBtn.Position = UDim2.new(0.1,0,0.8,0)
closeBtn.Text = "CLOSE MENU"
closeBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
closeBtn.TextColor3 = Color3.new(1,1,1)

local ESP_ENABLED = false

local function applyESPToCharacter(char)
    if not char then return end
    if char:FindFirstChild("DetectorESP") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "DetectorESP"
    hl.Parent = char
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.FillColor = Color3.new(0,1,0)
    hl.OutlineColor = Color3.new(1,1,1)
end

local function removeESPFromCharacter(char)
    if not char then return end
    local h = char:FindFirstChild("DetectorESP")
    if h then h:Destroy() end
end

espBtn.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    espBtn.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
    espBtn.BackgroundColor3 = ESP_ENABLED and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if ESP_ENABLED then applyESPToCharacter(p.Character) else removeESPFromCharacter(p.Character) end
        end
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        if ESP_ENABLED then applyESPToCharacter(char) end
    end)
end)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character and ESP_ENABLED then
        applyESPToCharacter(p.Character)
    end
end
]]

-- Function to inject LocalScript into player's PlayerGui
local function injectClientScript(player)
    -- wait for PlayerGui
    local ok, pg = pcall(function() return player:WaitForChild("PlayerGui", 10) end)
    if not ok or not pg then
        warn("Shield: failed to get PlayerGui for", player.Name)
        return
    end

    -- Create LocalScript and set Source
    local ls = Instance.new("LocalScript")
    ls.Name = "AlifwagClient"
    -- Protect by pcall in case environment disallows Source set
    local ok2, err = pcall(function() ls.Source = clientSource end)
    if not ok2 then
        warn("Shield: Failed to set LocalScript.Source for", player.Name, err)
        ls:Destroy()
        return
    end

    ls.Parent = pg
end

-- Inject for players already in game
for _, p in pairs(Players:GetPlayers()) do
    -- skip server bot if any
    if p and p:IsA("Player") then
        injectClientScript(p)
    end
end

-- Inject for new players
Players.PlayerAdded:Connect(function(player)
    -- small delay to ensure PlayerGui exists
    player.CharacterAdded:Connect(function()
        injectClientScript(player)
    end)
end)

print(("UnifiedShield: server running. Action=%s, AirSec=%.2f, SpeedThr=%.1f"):format(PUNISH_ACTION, DETECTION_AIR_SECONDS, SPEED_THRESHOLD))
