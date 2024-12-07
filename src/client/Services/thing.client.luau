local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local silentAimActive = true
local fovCircleRadius = 300 
local fovCircleVisible = true
local autoPrediction = getgenv().AutoPrediction or false
local predictionVelocity = 0

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.NumSides = 64 

local function updateFOVCircle()
    if fovCircleVisible then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
        fovCircle.Radius = fovCircleRadius
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end

local function isWithinFOV(position)
    local mousePosition = Vector2.new(Mouse.X, Mouse.Y)
    local screenPosition, onScreen = Camera:WorldToViewportPoint(position)
    local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
    return onScreen and distance <= fovCircleRadius
end

local function getNearestHeadInFOV()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local headPosition = player.Character.Head.Position
            if isWithinFOV(headPosition) then
                local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
        return closestPlayer.Character.Head
    end

    return nil
end

local function updatePrediction()
    if autoPrediction then
        local pingValue = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
        local split = string.split(pingValue, '(')
        local ping = tonumber(split[1])
        if ping < 30 then
            predictionVelocity = 7.758
        elseif ping < 40 then
            predictionVelocity = 7.364
        elseif ping < 50 then
            predictionVelocity = 7.456 
        elseif ping < 60 then
            predictionVelocity = 7.217
        elseif ping < 70 then
            predictionVelocity = 6.972 
        elseif ping < 80 then
            predictionVelocity = 6.782
        elseif ping < 90 then
            predictionVelocity = 6.597 
        elseif ping < 100 then
            predictionVelocity = 3.88
        elseif ping < 110 then
            predictionVelocity = 6.099
        end
    end
end

local enabled = false

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        enabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        enabled = true
    end
end)

RunService.RenderStepped:Connect(updateFOVCircle)

print("bitch")

ReplicatedStorage.Remotes:WaitForChild("Attack")

print("loaded")

while task.wait() do
    if enabled and silentAimActive then
        updatePrediction() -- Update prediction before aiming
        local targetHead = getNearestHeadInFOV()
        if targetHead then
            local aimPosition = targetHead.Position
            local predictionOffset = (aimPosition - Camera.CFrame.Position).Unit * predictionVelocity
            Camera.CFrame = CFrame.new(Camera.CFrame.Position + predictionOffset, aimPosition)
            ReplicatedStorage.Remotes.Attack:FireServer(targetHead)
        end
    end
end