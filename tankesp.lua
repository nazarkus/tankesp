local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "Tank_ESP" then
        v:Destroy()
    end
end

local TankESPfolder = Instance.new("Folder")
TankESPfolder.Name = "Tank_ESP"
TankESPfolder.Parent = CoreGui

local function getTankWorkspace()
    local gameSystems = workspace:FindFirstChild("Game Systems")
    if not gameSystems then return nil end
    return gameSystems:FindFirstChild("Tank Workspace")
end

local function findAllTanks()
    local tankWorkspace = getTankWorkspace()
    if not tankWorkspace then return {} end
    
    local foundTanks = {}
    
    for _, tankModel in pairs(tankWorkspace:GetChildren()) do
        if tankModel:IsA("Model") then
            local primaryPart = tankModel.PrimaryPart or tankModel:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                table.insert(foundTanks, {
                    model = tankModel,
                    name = tankModel.Name,
                    primaryPart = primaryPart
                })
            end
        end
    end
    
    return foundTanks
end

local function createTankESP(tankData)
    if not tankData.model or not tankData.primaryPart then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "Tank_Highlight"
    highlight.Adornee = tankData.model
    highlight.FillColor = Color3.fromRGB(150, 100, 50)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = tankData.model
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = tankData.name .. "_ESP"
    billboard.Adornee = tankData.primaryPart
    billboard.Size = UDim2.new(0, 200, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 8, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 10000
    billboard.Parent = TankESPfolder
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "🛡️ " .. tankData.name .. "\nLoading..."
    textLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextStrokeTransparency = 0.2
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextWrapped = true
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Parent = billboard
    
    return {
        highlight = highlight,
        billboard = billboard,
        textLabel = textLabel,
        model = tankData.model,
        primaryPart = tankData.primaryPart,
        name = tankData.name
    }
end

local function findTankHealth(tankModel)
    local healthValue = 0
    local maxHealthValue = 0
    
    local function checkHealth(obj)
        if obj:IsA("Humanoid") then
            return obj.Health, obj.MaxHealth
        elseif obj:IsA("NumberValue") and obj.Name == "Health" then
            return obj.Value, 100
        elseif obj:IsA("IntValue") and obj.Name == "Health" then
            return obj.Value, 100
        end
        return nil, nil
    end
    
    for _, child in ipairs(tankModel:GetChildren()) do
        local hp, maxHP = checkHealth(child)
        if hp then
            healthValue = hp
            maxHealthValue = maxHP or 100
            break
        end
        
        if child:IsA("Folder") or child:IsA("Model") then
            for _, subChild in ipairs(child:GetChildren()) do
                local hp2, maxHP2 = checkHealth(subChild)
                if hp2 then
                    healthValue = hp2
                    maxHealthValue = maxHP2 or 100
                    break
                end
            end
        end
    end
    
    if healthValue > 0 and maxHealthValue == 0 then
        local maxHealth = tankModel:FindFirstChild("MaxHealth")
        if maxHealth and (maxHealth:IsA("NumberValue") or maxHealth:IsA("IntValue")) then
            maxHealthValue = maxHealth.Value
        else
            maxHealthValue = 100
        end
    end
    
    return healthValue, maxHealthValue
end

local function updateTankESP(espData)
    if not espData.model or not espData.model.Parent then
        if espData.highlight then espData.highlight:Destroy() end
        if espData.billboard then espData.billboard:Destroy() end
        return false
    end
    
    local healthValue, maxHealthValue = findTankHealth(espData.model)
    
    local distance = 0
    if LocalPlayer.Character then
        local charRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart
        if charRoot and espData.primaryPart then
            distance = (charRoot.Position - espData.primaryPart.Position).Magnitude
        end
    end
    
    local displayText = ""
    
    if healthValue > 0 and maxHealthValue > 0 then
        local healthPercent = math.floor((healthValue / maxHealthValue) * 100)
        displayText = string.format("🛡️ %s\n❤ HP: %d/%d (%d%%)\n📏 Дистанция: %d studs", 
            espData.name,
            math.floor(healthValue), 
            math.floor(maxHealthValue),
            healthPercent,
            math.floor(distance)
        )
        
        if healthPercent < 30 then
            espData.textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            espData.highlight.FillColor = Color3.fromRGB(255, 50, 50)
        elseif healthPercent < 60 then
            espData.textLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
            espData.highlight.FillColor = Color3.fromRGB(255, 255, 50)
        else
            espData.textLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            espData.highlight.FillColor = Color3.fromRGB(150, 100, 50)
        end
    else
        displayText = string.format("🛡️ %s\n📏 Дистанция: %d studs\nℹ️ HP: Не найдено", 
            espData.name,
            math.floor(distance)
        )
        espData.textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        espData.highlight.FillColor = Color3.fromRGB(150, 150, 150)
    end
    
    espData.textLabel.Text = displayText
    
    return true
end

local trackedTanks = {}

local function mainTankESP()
    local foundTanks = findAllTanks()
    
    for _, tankData in ipairs(foundTanks) do
        if not trackedTanks[tankData.model] then
            local espData = createTankESP(tankData)
            if espData then
                trackedTanks[tankData.model] = espData
            end
        end
    end
    
    for model, espData in pairs(trackedTanks) do
        if not updateTankESP(espData) then
            trackedTanks[model] = nil
        end
    end
end

local connection
local function startTankESP()
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function()
        pcall(mainTankESP)
    end)
end

wait(1)
startTankESP()

print("tank esp loaded")
