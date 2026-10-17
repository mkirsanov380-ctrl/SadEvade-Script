--[[
	Sad Evade
	Edited by user request: Title = "Sad Evade", Theme = Amethyst (purple),
	FloatingButton removed, menu opens by Insert key.
	WARNING: Uses external GitHub loads (Fluent, ESP, Highlight, TimerGUI, ButtonPositions).
	Use only on a throwaway account.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local pgui = LocalPlayer:WaitForChild("PlayerGui")

if pgui:FindFirstChild("DraconicHubGui") then
    pgui.DraconicHubGui:Destroy()
end

-- Уведомления при запуске
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Sad Evade",
    Text = "Thank you for using the Sad Evade script",
    Duration = 7
})

task.delay(1, function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Sad Evade",
        Text = "To open the menu, click on the insert",
        Duration = 7
    })
end)

-- Загрузка Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/Ksndfkssc/87643/releases/download/Fluent/Fluent.lua"))()
local SaveManager = Fluent.SaveManager
local InterfaceManager = Fluent.InterfaceManager
local Window = Fluent:CreateWindow({
    Title = "Sad Evade",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.Insert,
    Search = true
})

pcall(function()
    Fluent:SetTheme("Amethyst")
end)

-- FloatingButton удалён по просьбе

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "solar/home-bold" })
}

local Options = Fluent.Options

Fluent:Notify({
    Title = "Sad Evade",
    Content = "System Loaded...",
    Duration = 3
})

-- Глобальное состояние фич
featureStates = {}

-- Переменные ESP
local NextbotBillboards = {}
local nextbotLoop = nil
local TicketBillboards = {}
local ExternalESP = nil
local ExternalESPLoaded = false
local ExternalNextbotESP = nil
local ExternalNextbotESPLoaded = false
local ExternalTicketESP = nil
local ExternalTicketESPLoaded = false
local playerLoop = nil
local ticketLoop = nil

local function forceCleanAllESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            if obj.Name:find("ESP") or obj.Name:find("Nextbot") or obj.Name:find("Billboard") then
                obj:Destroy()
            end
        end
    end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") or gui:IsA("TextLabel") then
                if gui.Name:find("ESP") or gui.Name:find("Nextbot") then
                    gui:Destroy()
                end
            end
        end
    end
    local coreGui = game:GetService("CoreGui")
    for _, gui in ipairs(coreGui:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            if gui.Name:find("ESP") or gui.Name:find("Nextbot") then
                gui:Destroy()
            end
        end
    end
    pcall(function()
        local drawings = {}
        for _, v in pairs(getgenv() or {}) do
            if type(v) == "table" then
                if v.Visible ~= nil and v.Color ~= nil and v.Thickness ~= nil then
                    table.insert(drawings, v)
                end
            end
        end
        for _, drawing in ipairs(drawings) do
            if drawing.Remove then
                pcall(function() drawing:Remove() end)
            end
        end
    end)
end

local playerTracerElements = {}
local botTracerElements = {}
local playerTracerConnection = nil
local botTracerConnection = nil
local lastSavedPosition = nil
local respawnConnection = nil
local AutoSelfReviveConnection = nil
local hasRevived = false
local SelfReviveMethod = "Spawnpoint"
local AntiAFKConnection = nil
local autoWhistleHandle = nil
local stableCameraInstance = nil

function cleanUpOnlyPlayerESPObjects()
    local cleaned = 0
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            if pl.Character then
                for _, obj in pairs(pl.Character:GetDescendants()) do
                    if obj:IsA("BillboardGui") then
                        local objName = obj.Name:lower()
                        if objName:find("esp") and not objName:find("nextbot") and not objName:find("npc") and not objName:find("bot") and not objName:find("enemy") then
                            obj:Destroy()
                            cleaned = cleaned + 1
                        end
                    end
                end
            end
        end
    end
    local guiContainers = { game:GetService("CoreGui"), LocalPlayer.PlayerGui }
    for _, container in pairs(guiContainers) do
        for _, gui in pairs(container:GetDescendants()) do
            if gui:IsA("BillboardGui") or gui:IsA("ScreenGui") then
                local guiName = gui.Name:lower()
                if (guiName:find("player") or guiName:find("esp")) and not guiName:find("nextbot") and not guiName:find("bot") then
                    gui:Destroy()
                    cleaned = cleaned + 1
                end
            end
        end
    end
    return cleaned
end

local nextBotNames = {}
if ReplicatedStorage:FindFirstChild("NPCs") then
    for _, npc in ipairs(ReplicatedStorage.NPCs:GetChildren()) do
        table.insert(nextBotNames, npc.Name)
    end
end

function isNextbotModel(model)
    if not model or not model.Name then return false end
    for _, name in ipairs(nextBotNames) do
        if model.Name == name then return true end
    end
    return model.Name:lower():find("nextbot") or model.Name:lower():find("scp") or model.Name:lower():find("monster") or
           model.Name:lower():find("creep") or model.Name:lower():find("enemy") or model.Name:lower():find("zombie") or
           model.Name:lower():find("ghost") or model.Name:lower():find("demon")
end

function getDistanceFromPlayer(targetPosition)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return 0
    end
    return math.floor((targetPosition - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
end

local function scanForTickets()
    if ExternalTicketESPLoaded and _G.UpdateTicketESP then
        pcall(_G.UpdateTicketESP)
    else
        local ticketsFound = {}
        local gameFolder = workspace:FindFirstChild("Game")
        if gameFolder then
            local effects = gameFolder:FindFirstChild("Effects")
            if effects then
                local tickets = effects:FindFirstChild("Tickets")
                if tickets then
                    for _, ticket in pairs(tickets:GetChildren()) do
                        if ticket:IsA("BasePart") or ticket:IsA("Model") then
                            local part = ticket:IsA("Model") and
                                       (ticket:FindFirstChild("HumanoidRootPart") or ticket:FindFirstChild("Head") or
                                        ticket.PrimaryPart or ticket:FindFirstChildWhichIsA("BasePart")) or
                                       ticket:IsA("BasePart") and ticket
                            if part then ticketsFound[ticket] = part end
                        end
                    end
                end
            end
        end
        for ticket, data in pairs(TicketBillboards) do
            if not ticketsFound[ticket] or not ticket.Parent then
                if data.esp then data.esp:Destroy() end
                TicketBillboards[ticket] = nil
            end
        end
    end
end

function createTracerObject()
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = 1
    tracer.ZIndex = 1
    return tracer
end

function updatePlayerTracers()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentTargets = {}
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                currentTargets[pl] = true
                if not playerTracerElements[pl] then
                    playerTracerElements[pl] = createTracerObject()
                end
                local tracer = playerTracerElements[pl]
                local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    tracer.Visible = true
                    tracer.From = screenBottomCenter
                    tracer.To = Vector2.new(vector.X, vector.Y)
                    tracer.Color = Color3.fromRGB(255, 255, 255)
                else
                    tracer.Visible = false
                end
            end
        end
    end
    for pl, tracer in pairs(playerTracerElements) do
        if not currentTargets[pl] then
            if tracer and tracer.Remove then tracer:Remove() end
            playerTracerElements[pl] = nil
        end
    end
end

function updateBotTracers()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentTargets = {}
    local playersFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
    if playersFolder then
        for _, model in pairs(playersFolder:GetChildren()) do
            if model:IsA("Model") and isNextbotModel(model) then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp then
                    currentTargets[model] = true
                    if not botTracerElements[model] then botTracerElements[model] = createTracerObject() end
                    local tracer = botTracerElements[model]
                    local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        tracer.Visible = true
                        tracer.From = screenBottomCenter
                        tracer.To = Vector2.new(vector.X, vector.Y)
                        tracer.Color = Color3.fromRGB(255, 0, 0)
                    else
                        tracer.Visible = false
                    end
                end
            end
        end
    end
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, model in pairs(npcsFolder:GetChildren()) do
            if model:IsA("Model") and isNextbotModel(model) then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp then
                    currentTargets[model] = true
                    if not botTracerElements[model] then botTracerElements[model] = createTracerObject() end
                    local tracer = botTracerElements[model]
                    local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        tracer.Visible = true
                        tracer.From = screenBottomCenter
                        tracer.To = Vector2.new(vector.X, vector.Y)
                        tracer.Color = Color3.fromRGB(255, 0, 0)
                    else
                        tracer.Visible = false
                    end
                end
            end
        end
    end
    for model, tracer in pairs(botTracerElements) do
        if not currentTargets[model] then
            if tracer and tracer.Remove then tracer:Remove() end
            botTracerElements[model] = nil
        end
    end
end

function startPlayerTracers()
    if playerTracerConnection then return end
    playerTracerConnection = RunService.RenderStepped:Connect(updatePlayerTracers)
end

function stopPlayerTracers()
    if playerTracerConnection then playerTracerConnection:Disconnect() playerTracerConnection = nil end
    for pl, tracer in pairs(playerTracerElements) do
        if tracer and tracer.Remove then tracer:Remove() end
    end
    playerTracerElements = {}
end

function startBotTracers()
    if botTracerConnection then return end
    botTracerConnection = RunService.RenderStepped:Connect(updateBotTracers)
end

function stopBotTracers()
    if botTracerConnection then botTracerConnection:Disconnect() botTracerConnection = nil end
    for model, tracer in pairs(botTracerElements) do
        if tracer and tracer.Remove then tracer:Remove() end
    end
    botTracerElements = {}
end

local function startAutoRespawn()
    if AutoSelfReviveConnection then AutoSelfReviveConnection:Disconnect() end
    if respawnConnection then respawnConnection:Disconnect() end
    local character = LocalPlayer.Character
    if character then
        AutoSelfReviveConnection = character:GetAttributeChangedSignal("Downed"):Connect(function()
            local isDowned = character:GetAttribute("Downed")
            if isDowned then
                if SelfReviveMethod == "Spawnpoint" then
                    if not hasRevived then
                        hasRevived = true
                        pcall(function()
                            ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                        end)
                        task.delay(0.5, function() hasRevived = false end)
                    end
                elseif SelfReviveMethod == "Fake Revive" then
                    if not hasRevived then
                        hasRevived = true
                        local lastPos = nil
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            lastPos = character.HumanoidRootPart.Position
                        end
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("ChangePlayerMode"):FireServer(true)
                        end)
                        task.spawn(function()
                            for i = 1, 10 do
                                local newChar = LocalPlayer.Character
                                if newChar and newChar ~= character then
                                    local newHRP = newChar:FindFirstChild("HumanoidRootPart")
                                    if newHRP and lastPos then
                                        newHRP.CFrame = CFrame.new(lastPos)
                                        break
                                    end
                                end
                                task.wait(0.05)
                            end
                        end)
                        task.delay(0.5, function() hasRevived = false end)
                    end
                end
            end
        end)
    end
    respawnConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        local newHumanoid = newChar:WaitForChild("Humanoid")
        local newHRP = newChar:WaitForChild("HumanoidRootPart")
        AutoSelfReviveConnection = newChar:GetAttributeChangedSignal("Downed"):Connect(function()
            local isDowned = newChar:GetAttribute("Downed")
            if isDowned then
                if SelfReviveMethod == "Spawnpoint" then
                    if not hasRevived then
                        hasRevived = true
                        pcall(function()
                            ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                        end)
                        task.delay(0.5, function() hasRevived = false end)
                    end
                elseif SelfReviveMethod == "Fake Revive" then
                    if not hasRevived then
                        hasRevived = true
                        local lastPos = nil
                        if newHRP then lastPos = newHRP.Position end
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("ChangePlayerMode"):FireServer(true)
                        end)
                        task.spawn(function()
                            for i = 1, 10 do
                                local freshChar = LocalPlayer.Character
                                if freshChar and freshChar ~= newChar then
                                    local freshHRP = freshChar:FindFirstChild("HumanoidRootPart")
                                    if freshHRP and lastPos then
                                        freshHRP.CFrame = CFrame.new(lastPos)
                                        break
                                    end
                                end
                                task.wait(0.05)
                            end
                        end)
                        task.delay(0.5, function() hasRevived = false end)
                    end
                end
            end
        end)
    end)
end

local function stopAutoRespawn()
    if AutoSelfReviveConnection then AutoSelfReviveConnection:Disconnect() AutoSelfReviveConnection = nil end
    if respawnConnection then respawnConnection:Disconnect() respawnConnection = nil end
    hasRevived = false
    lastSavedPosition = nil
end

local function startAntiAFK()
    if AntiAFKConnection then return end
    AntiAFKConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function stopAntiAFK()
    if AntiAFKConnection then AntiAFKConnection:Disconnect() AntiAFKConnection = nil end
end

local AutoWhistleToggle -- объявляем заранее

local function startAutoWhistle()
    if autoWhistleHandle then stopAutoWhistle() end
    autoWhistleHandle = task.spawn(function()
        while true do
            if not AutoWhistleToggle or not AutoWhistleToggle.Value then break end
            pcall(function()
                local success, result = pcall(function()
                    return ReplicatedStorage.Events.Character.Whistle:FireServer()
                end)
                if not success then warn("Auto Whistle Error:", result) end
            end)
            task.wait(1)
        end
        autoWhistleHandle = nil
    end)
end

local function stopAutoWhistle()
    if autoWhistleHandle then
        local handle = autoWhistleHandle
        autoWhistleHandle = nil
        pcall(function()
            if type(handle) == "table" and handle.cancel then handle:cancel() end
        end)
    end
end

local StableCamera = {}
StableCamera.__index = StableCamera

function StableCamera.new(maxDistance)
    local self = setmetatable({}, StableCamera)
    self.Player = Players.LocalPlayer
    self.MaxDistance = maxDistance or 50
    self._conn = RunService.RenderStepped:Connect(function(dt) self:Update(dt) end)
    return self
end

local function tryResetShake(pl)
    if not pl then return end
    local ok, playerScripts = pcall(function() return pl:FindFirstChild("PlayerScripts") end)
    if not ok or not playerScripts then return end
    local cameraSet = playerScripts:FindFirstChild("Camera") and playerScripts.Camera:FindFirstChild("Set")
    if cameraSet and type(cameraSet.Invoke) == "function" then
        pcall(function() cameraSet:Invoke("CFrameOffset", "Shake", CFrame.new()) end)
    end
end

function StableCamera:Update(dt)
    if Players and Players.LocalPlayer then tryResetShake(Players.LocalPlayer) end
end

function StableCamera:Destroy()
    if self._conn then self._conn:Disconnect() self._conn = nil end
end

local function startNoCameraShake()
    if stableCameraInstance then return end
    stableCameraInstance = StableCamera.new()
end

local function stopNoCameraShake()
    if stableCameraInstance then stableCameraInstance:Destroy() stableCameraInstance = nil end
end

-- ====== ВКЛАДКА MAIN ======

local billboardSection = Tabs.Main:AddSection("Billboard ESP")

local NextbotToggle = Tabs.Main:AddToggle("NextbotToggle", { Title = "ESP Nextbots", Default = false })
local PlayerToggle = Tabs.Main:AddToggle("PlayerToggle", { Title = "ESP Players", Default = false })
local TicketToggle = Tabs.Main:AddToggle("TicketToggle", { Title = "ESP Tickets", Default = false })

Tabs.Main:AddSection("Highlight")

local HighlightDownedPlayers = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Online%20Script/HighlightPlayers.lua"))()
HighlightDownedPlayers:Init(Fluent, Options)

local HighlightDownedToggle = Tabs.Main:AddToggle("HighlightDownedToggle", {
    Title = "Highlight Players", Default = false,
    Callback = function(value)
        if value then HighlightDownedPlayers:Start() else HighlightDownedPlayers:Stop() end
    end
})

local HighlightBots = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Online%20Script/HighlightBots.lua"))()
HighlightBots:Init(Fluent, Options)

local HighlightBotsToggle = Tabs.Main:AddToggle("HighlightBotsToggle", {
    Title = "Highlight Bots", Default = false,
    Callback = function(value)
        if value then HighlightBots:Start() else HighlightBots:Stop() end
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if HighlightBotsToggle and HighlightBotsToggle.Value then HighlightBots:Refresh() end
end)

workspace.ChildAdded:Connect(function(child)
    task.wait(1)
    if child.Name == "Game" and HighlightBotsToggle and HighlightBotsToggle.Value then
        HighlightBots:Refresh()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if HighlightDownedToggle and HighlightDownedToggle.Value then HighlightDownedPlayers:Refresh() end
end)

Tabs.Main:AddSection("Tracer ESP")

local TracerPlayerToggle = Tabs.Main:AddToggle("TracerPlayerToggle", { Title = "Tracer Players", Default = false })
local TracerBotToggle = Tabs.Main:AddToggle("TracerBotToggle", { Title = "Tracer Bots", Default = false })

Tabs.Main:AddSection("Respawn")

local AutoRespawnTypeDropdown = Tabs.Main:AddDropdown("AutoRespawnTypeDropdown", {
    Title = "Auto Respawn Type",
    Values = {"Spawnpoint", "Fake Revive"},
    Multi = false,
    Default = "Spawnpoint",
})

local RespawnButtonSizeInput -- объявляем заранее

local RespawnButton = Tabs.Main:AddButton({
    Title = "Respawn Button",
    Callback = function()
        local CoreGui = game:GetService("CoreGui")
        local existingScreenGui = CoreGui:FindFirstChild("DraconicRespawnButtonGUI")
        if existingScreenGui then
            existingScreenGui:Destroy()
        else
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "DraconicRespawnButtonGUI"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = CoreGui

            local function createGradientButton(parent, position, size, text)
                local button = Instance.new("Frame")
                button.Name = "GradientBtn"
                button.BackgroundTransparency = 0.7
                button.Size = size
                button.Position = position
                button.Draggable = true
                button.Active = true
                button.Selectable = true
                button.Parent = parent
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = button
                local gradient = Instance.new("UIGradient")
                gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                }
                gradient.Rotation = 0
                gradient.Parent = button
                local gradientAnimation
                gradientAnimation = RunService.RenderStepped:Connect(function(delta)
                    gradient.Rotation = (gradient.Rotation + 90 * delta) % 360
                end)
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(139, 0, 0)
                stroke.Thickness = 2
                stroke.Parent = button
                local label = Instance.new("TextLabel")
                label.Text = text
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.TextSize = 16
                label.Font = Enum.Font.GothamBold
                label.Parent = button
                local clicker = Instance.new("TextButton")
                clicker.Size = UDim2.new(1, 0, 1, 0)
                clicker.BackgroundTransparency = 1
                clicker.Text = ""
                clicker.ZIndex = 5
                clicker.Parent = button
                button.Destroying:Connect(function()
                    if gradientAnimation then gradientAnimation:Disconnect() end
                end)
                local activeTouchId = nil
                local startPos = nil
                local startButtonPos = nil
                local function updateButtonPosition(touchPos)
                    if not startPos or not startButtonPos then return end
                    local delta = touchPos - startPos
                    button.Position = UDim2.new(startButtonPos.X.Scale, startButtonPos.X.Offset + delta.X,
                                                startButtonPos.Y.Scale, startButtonPos.Y.Offset + delta.Y)
                end
                local function resetDrag()
                    activeTouchId = nil
                    startPos = nil
                    startButtonPos = nil
                    stroke.Color = Color3.fromRGB(139, 0, 0)
                end
                clicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        if activeTouchId ~= nil then return end
                        activeTouchId = input.UserInputState
                        startPos = input.Position
                        startButtonPos = button.Position
                        stroke.Color = Color3.fromRGB(255, 0, 0)
                        local connection
                        connection = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                resetDrag()
                                connection:Disconnect()
                            end
                        end)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if activeTouchId ~= nil then return end
                        activeTouchId = "mouse"
                        startPos = input.Position
                        startButtonPos = button.Position
                        stroke.Color = Color3.fromRGB(255, 0, 0)
                        local connection
                        connection = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                resetDrag()
                                connection:Disconnect()
                            end
                        end)
                    end
                end)
                clicker.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        if activeTouchId ~= nil then updateButtonPosition(input.Position) end
                    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
                        if activeTouchId ~= nil then updateButtonPosition(input.Position) end
                    end
                end)
                return button, clicker, stroke
            end

            local buttonSize = 190
            if RespawnButtonSizeInput and RespawnButtonSizeInput.Value and tonumber(RespawnButtonSizeInput.Value) then
                buttonSize = tonumber(RespawnButtonSizeInput.Value)
            end
            local btnWidth = math.max(150, math.min(buttonSize, 400))
            local btnHeight = math.max(60, math.min(buttonSize * 0.4, 160))
            local btn, clicker, stroke = createGradientButton(
                screenGui,
                UDim2.new(0.5, -btnWidth/2, 0.5, -btnHeight/2),
                UDim2.new(0, btnWidth, 0, btnHeight),
                "RESPAWN"
            )
            clicker.MouseButton1Click:Connect(function() manualRevive() end)
        end
    end
})

RespawnButtonSizeInput = Tabs.Main:AddInput("RespawnButtonSizeInput", {
    Title = "Button Size",
    Default = "190",
    Placeholder = "Enter size (150-400)",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        if Value and tonumber(Value) then
            local size = tonumber(Value)
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("DraconicRespawnButtonGUI")
            if existingScreenGui then
                local button = existingScreenGui:FindFirstChild("GradientBtn")
                if button then
                    local newWidth = math.max(150, math.min(size, 400))
                    local newHeight = math.max(60, math.min(size * 0.4, 160))
                    button.Size = UDim2.new(0, newWidth, 0, newHeight)
                end
            end
        end
    end
})

local modificationSection = Tabs.Main:AddSection("Things")

local AntiAFKToggle = Tabs.Main:AddToggle("AntiAFKToggle", { Title = "Anti AFK", Default = false })
AutoWhistleToggle = Tabs.Main:AddToggle("AutoWhistleToggle", { Title = "Auto Whistle", Default = false })
local NoCameraShakeToggle = Tabs.Main:AddToggle("NoCameraShakeToggle", { Title = "No Camera Shake", Default = false })

NextbotToggle:OnChanged(function(value)
    if value then
        if not ExternalNextbotESPLoaded then
            local success, errorMsg = pcall(function()
                ExternalNextbotESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Test%20Script/NextbotESP.lua"))()
                ExternalNextbotESPLoaded = true
                _G.NextbotESPRunning = true
                if ExternalNextbotESP and ExternalNextbotESP.Start then ExternalNextbotESP.Start() end
                Fluent:Notify({ Title = "ESP Nextbots", Content = "External Nextbot ESP loaded and running!", Duration = 3 })
            end)
            if not success then
                Fluent:Notify({ Title = "ESP Nextbots Error", Content = "Failed to load external Nextbot ESP: " .. tostring(errorMsg), Duration = 5 })
                Options.NextbotToggle:Set(false)
                return
            end
        else
            if ExternalNextbotESP and ExternalNextbotESP.Start then ExternalNextbotESP.Start() end
            _G.NextbotESPRunning = true
        end
        if not nextbotLoop then
            nextbotLoop = RunService.Heartbeat:Connect(function()
                if Options.NextbotToggle.Value then
                    if _G.NextbotESPRunning == false then
                        _G.NextbotESPRunning = true
                        if ExternalNextbotESP and ExternalNextbotESP.Start then pcall(ExternalNextbotESP.Start) end
                    end
                end
            end)
        end
    else
        if nextbotLoop then nextbotLoop:Disconnect() nextbotLoop = nil end
        if ExternalNextbotESP and ExternalNextbotESPLoaded then
            if ExternalNextbotESP.Stop then pcall(function() ExternalNextbotESP.Stop() end) end
        end
        task.spawn(function()
            task.wait(0.2)
            for model, data in pairs(NextbotBillboards) do
                if data.esp and data.esp:IsDescendantOf(game) then
                    local espName = data.esp.Name:lower()
                    if espName:find("nextbot") or espName:find("bot") or espName:find("npc") then data.esp:Destroy() end
                end
            end
            NextbotBillboards = {}
            for model, tracer in pairs(botTracerElements) do
                if tracer and tracer.Remove then pcall(function() tracer:Remove() end) end
            end
            botTracerElements = {}
            pcall(function()
                for _, drawing in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    if drawing:IsA("BillboardGui") and drawing.Name:find("Nextbot") then drawing:Destroy() end
                end
                for _, obj in pairs(getgc(true)) do
                    if type(obj) == "table" then
                        if obj.__type and obj.__type == "Drawing" and obj.Color then
                            if obj.Color.r == 1 and obj.Color.g == 0 and obj.Color.b == 0 then
                                if obj.Remove then pcall(obj.Remove, obj) end
                            end
                        end
                    end
                end
            end)
        end)
        ExternalNextbotESPLoaded = false
        _G.NextbotESPRunning = false
        Fluent:Notify({ Title = "ESP Nextbots", Content = "Nextbot ESP disabled!", Duration = 3 })
    end
end)

PlayerToggle:OnChanged(function(value)
    if value then
        cleanUpOnlyPlayerESPObjects()
        local nextbotESPActive = Options.NextbotToggle and Options.NextbotToggle.Value
        if not ExternalESPLoaded then
            local success, errorMsg = pcall(function()
                local espScript = game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Test%20Script/Esp.lua", true)
                espScript = [[
                    if _G.PlayerESP_Loaded == true then return end
                    _G.PlayerESP_Loaded = true
                    local function cleanOldPlayerESP()
                        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                            if p ~= game:GetService("Players").LocalPlayer then
                                if p.Character then
                                    local esp = p.Character:FindFirstChild("PlayerESP")
                                    if esp then esp:Destroy() end
                                end
                            end
                        end
                    end
                    cleanOldPlayerESP()
                ]] .. espScript
                ExternalESP = loadstring(espScript)()
                ExternalESPLoaded = true
                _G.ExternalESPRunning = true
                _G.PlayerESP_Loaded = true
                Fluent:Notify({ Title = "ESP Players", Content = "Player ESP loaded!", Duration = 3 })
            end)
            if not success then
                Fluent:Notify({ Title = "ESP Players Error", Content = "Failed to load ESP: " .. tostring(errorMsg), Duration = 5 })
                Options.PlayerToggle:Set(false)
                return
            end
        else
            _G.ExternalESPRunning = true
            _G.PlayerESP_Loaded = true
        end
        if nextbotESPActive then
            task.wait(0.5)
            if ExternalNextbotESP and ExternalNextbotESPLoaded and ExternalNextbotESP.Start then pcall(ExternalNextbotESP.Start) end
        end
        if not playerLoop then
            playerLoop = RunService.Heartbeat:Connect(function()
                if Options.PlayerToggle.Value then
                    for _, pl in pairs(Players:GetPlayers()) do
                        if pl ~= LocalPlayer and pl.Character then
                            for _, obj in pairs(pl.Character:GetDescendants()) do
                                if obj:IsA("BillboardGui") then
                                    local labelCount = 0
                                    for _, label in pairs(obj:GetDescendants()) do
                                        if label:IsA("TextLabel") then labelCount = labelCount + 1 end
                                    end
                                    if labelCount > 3 then obj:Destroy() end
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if playerLoop then playerLoop:Disconnect() playerLoop = nil end
        cleanUpOnlyPlayerESPObjects()
        if ExternalESP and ExternalESPLoaded then
            if type(ExternalESP) == "table" and ExternalESP.Stop then pcall(ExternalESP.Stop) end
        end
        _G.ExternalESPRunning = false
        _G.PlayerESP_Loaded = false
        ExternalESPLoaded = false
        Fluent:Notify({ Title = "ESP Players", Content = "Player ESP disabled!", Duration = 3 })
    end
end)

TicketToggle:OnChanged(function(value)
    if value then
        if not ExternalTicketESPLoaded then
            local success, errorMsg = pcall(function()
                ExternalTicketESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Online%20Script/TicketESP.lua"))()
                ExternalTicketESPLoaded = true
                _G.TicketESPRunning = true
                Fluent:Notify({ Title = "ESP Tickets", Content = "External Ticket ESP loaded!", Duration = 3 })
            end)
            if not success then
                Fluent:Notify({ Title = "ESP Tickets Error", Content = "Failed to load external Ticket ESP: " .. tostring(errorMsg), Duration = 5 })
            end
        else
            _G.TicketESPRunning = true
        end
        if not ticketLoop then
            ticketLoop = RunService.RenderStepped:Connect(function()
                if Options.TicketToggle.Value then scanForTickets() end
            end)
        end
    else
        if ExternalTicketESPLoaded then
            if _G.StopTicketESP then pcall(_G.StopTicketESP) end
        end
        if ticketLoop then ticketLoop:Disconnect() ticketLoop = nil end
        for ticket, data in pairs(TicketBillboards) do
            if data.esp then data.esp:Destroy() end
        end
        TicketBillboards = {}
        ExternalTicketESPLoaded = false
        _G.TicketESPRunning = false
        Fluent:Notify({ Title = "ESP Tickets", Content = "Ticket ESP disabled!", Duration = 3 })
    end
end)

TracerPlayerToggle:OnChanged(function(value)
    if value then startPlayerTracers() else stopPlayerTracers() end
end)

TracerBotToggle:OnChanged(function(value)
    if value then startBotTracers() else stopBotTracers() end
end)

AutoRespawnTypeDropdown:OnChanged(function(value) SelfReviveMethod = value end)
AntiAFKToggle:OnChanged(function(value) if value then startAntiAFK() else stopAntiAFK() end end)
AutoWhistleToggle:OnChanged(function(value) if value then startAutoWhistle() else stopAutoWhistle() end end)
NoCameraShakeToggle:OnChanged(function(value) if value then startNoCameraShake() else stopNoCameraShake() end end)

local TimerDisplayToggle = Tabs.Main:AddToggle("TimerDisplayToggle", { Title = "Show Timer", Default = false })
local timerDisplayLoop = nil

TimerDisplayToggle:OnChanged(function(state)
    if state then
        if timerDisplayLoop then return end
        timerDisplayLoop = RunService.RenderStepped:Connect(function()
            local pg = LocalPlayer.PlayerGui
            local shared = pg:FindFirstChild("Shared")
            local hud = shared and shared:FindFirstChild("HUD")
            local overlay = hud and hud:FindFirstChild("Overlay")
            local default = overlay and overlay:FindFirstChild("Default")
            local ro = default and default:FindFirstChild("RoundOverlay")
            local round = ro and ro:FindFirstChild("Round")
            local timer = round and round:FindFirstChild("RoundTimer")
            if timer then timer.Visible = true end
            local main = pg:FindFirstChild("MainInterface")
            if main then
                local container = main:FindFirstChild("TimerContainer")
                if container then container.Visible = true end
            end
        end)
    else
        if timerDisplayLoop then timerDisplayLoop:Disconnect() timerDisplayLoop = nil end
        local pg = LocalPlayer.PlayerGui
        local shared = pg:FindFirstChild("Shared")
        local hud = shared and shared:FindFirstChild("HUD")
        local overlay = hud and hud:FindFirstChild("Overlay")
        local default = overlay and overlay:FindFirstChild("Default")
        local ro = default and default:FindFirstChild("RoundOverlay")
        local round = ro and ro:FindFirstChild("Round")
        local timer = round and round:FindFirstChild("RoundTimer")
        if timer then timer.Visible = false end
        local main = pg:FindFirstChild("MainInterface")
        if main then
            local container = main:FindFirstChild("TimerContainer")
            if container then container.Visible = false end
        end
    end
end)

Tabs.Main:AddSection("Player Modification")

local FlyToggle = Tabs.Main:AddToggle("FlyToggle", { Title = "Fly", Default = false })
local FlySpeedInput = Tabs.Main:AddInput("FlySpeedInput", {
    Title = "Fly Speed", Default = "50", Placeholder = "Enter speed value", Numeric = true, Finished = false,
    Callback = function(Value)
        if Value and tonumber(Value) then featureStates.FlySpeed = tonumber(Value) end
    end
})

local flying = false
local bodyVelocity = nil
local bodyGyro = nil
local character = LocalPlayer.Character
local humanoid = character and character:FindFirstChild("Humanoid")
local rootPart = character and character:FindFirstChild("HumanoidRootPart")

featureStates.FlySpeed = 50

local function startFlying()
    if not character or not humanoid or not rootPart then
        character = LocalPlayer.Character
        if not character then return end
        humanoid = character:WaitForChild("Humanoid")
        rootPart = character:WaitForChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
    end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    humanoid.PlatformStand = true
end

local function stopFlying()
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if humanoid then humanoid.PlatformStand = false end
end

local function updateFly()
    if not flying or not bodyVelocity or not bodyGyro then return end
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    local direction = Vector3.new(0, 0, 0)
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        local forwardVector = cameraCFrame.LookVector
        local rightVector = cameraCFrame.RightVector
        local forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
        local rightComponent = moveDirection:Dot(rightVector) * rightVector
        direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    local speed = featureStates.FlySpeed or 50
    bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (speed * 2) or Vector3.new(0, 0, 0)
    bodyGyro.CFrame = cameraCFrame
end

local flyLoop = nil
local characterAddedConnection = nil

FlyToggle:OnChanged(function(state)
    if state then
        if characterAddedConnection then characterAddedConnection:Disconnect() end
        characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
            character = newChar
            task.wait(0.5)
            humanoid = character:WaitForChild("Humanoid")
            rootPart = character:WaitForChild("HumanoidRootPart")
            if Options.FlyToggle.Value and flying == false then startFlying() end
        end)
        character = LocalPlayer.Character
        if character then
            humanoid = character:FindFirstChild("Humanoid")
            rootPart = character:FindFirstChild("HumanoidRootPart")
        end
        startFlying()
        if not flyLoop then
            flyLoop = RunService.RenderStepped:Connect(function()
                if Options.FlyToggle.Value then updateFly() end
            end)
        end
    else
        stopFlying()
        if flyLoop then flyLoop:Disconnect() flyLoop = nil end
        if characterAddedConnection then characterAddedConnection:Disconnect() characterAddedConnection = nil end
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if Options.FlyToggle.Value then
        stopFlying()
        if flyLoop then flyLoop:Disconnect() flyLoop = nil end
    end
end)

Tabs.Main:AddSection("Manual")

function manualRevive()
    local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
    if not gamePlayers then return end
    local charModel = gamePlayers:FindFirstChild(LocalPlayer.Name)
    if not charModel then return end
    local hrp = charModel:FindFirstChild("HumanoidRootPart")
    local isDowned = charModel:GetAttribute("Downed")
    if not isDowned then return end
    local method = Options.AutoRespawnTypeDropdown and Options.AutoRespawnTypeDropdown.Value or "Spawnpoint"
    if method == "Spawnpoint" then
        pcall(function() ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true) end)
    elseif method == "Fake Revive" then
        local lastSavedPosition = nil
        if hrp then lastSavedPosition = hrp.Position end
        pcall(function() ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true) end)
        task.spawn(function()
            for i = 1, 30 do
                task.wait(0.05)
                local newGamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
                if newGamePlayers then
                    local newCharacter = newGamePlayers:FindFirstChild(LocalPlayer.Name)
                    if newCharacter and newCharacter ~= charModel then
                        local newHRP = newCharacter:FindFirstChild("HumanoidRootPart")
                        if newHRP and lastSavedPosition then
                            newHRP.CFrame = CFrame.new(lastSavedPosition)
                            newHRP.Velocity = Vector3.new(0, 0, 0)
                            break
                        end
                    end
                end
            end
        end)
    end
end

local NoclipToggle = Tabs.Main:AddToggle("NoclipToggle", { Title = "Noclip", Default = false })
local noclipEnabled = false
local noclipConnection = nil

local function toggleNoclip(state)
    noclipEnabled = state
    if noclipEnabled then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
        Fluent:Notify({ Title = "Noclip", Content = "Noclip enabled", Duration = 2 })
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        Fluent:Notify({ Title = "Noclip", Content = "Noclip disabled", Duration = 2 })
    end
end

NoclipToggle:OnChanged(function(value) toggleNoclip(value) end)

LocalPlayer.CharacterAdded:Connect(function(character)
    if noclipEnabled then
        task.wait(0.5)
        toggleNoclip(false)
        task.wait(0.1)
        toggleNoclip(true)
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end)

toggleNoclip(false)

local SitToggle = Tabs.Main:AddToggle("SitToggle", { Title = "Bug Emote", Default = false })
local sitLoopConnection = nil

local function updateSit()
    if not SitToggle.Value then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then
        local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
        if gamePlayers then
            local playerModel = gamePlayers:FindFirstChild(player.Name)
            if playerModel then hum = playerModel:FindFirstChild("Humanoid") end
        end
    end
    if hum then hum.Sit = true end
end

SitToggle:OnChanged(function(state)
    if state then
        if sitLoopConnection then sitLoopConnection:Disconnect() end
        sitLoopConnection = RunService.Heartbeat:Connect(updateSit)
        updateSit()
        Fluent:Notify({ Title = "Force Sit", Content = "Character will now sit continuously", Duration = 2 })
    else
        if sitLoopConnection then sitLoopConnection:Disconnect() sitLoopConnection = nil end
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if not hum then
                local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
                if gamePlayers then
                    local playerModel = gamePlayers:FindFirstChild(player.Name)
                    if playerModel then hum = playerModel:FindFirstChild("Humanoid") end
                end
            end
            if hum then hum.Sit = false end
        end
        Fluent:Notify({ Title = "Force Sit", Content = "Sit mode disabled", Duration = 2 })
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if SitToggle and SitToggle.Value then updateSit() end
end)

player.CharacterRemoving:Connect(function()
    if sitLoopConnection then sitLoopConnection:Disconnect() sitLoopConnection = nil end
end)

local NoCollisionToggle = Tabs.Main:AddToggle("NoCollisionToggle", { Title = "Remove Barriers", Default = false })

local function toggleInvisPartsCollision(state)
    local invisParts = workspace:FindFirstChild("Game") and
                      workspace.Game:FindFirstChild("Map") and
                      workspace.Game.Map:FindFirstChild("InvisParts")
    if not invisParts then
        Fluent:Notify({ Title = "Remove Barriers", Content = "InvisParts folder not found!", Duration = 3 })
        return
    end
    local objectsChanged = 0
    for _, obj in ipairs(invisParts:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = not state
            obj.CanQuery = not state
            objectsChanged = objectsChanged + 1
        end
    end
    Fluent:Notify({
        Title = "Remove Barriers",
        Content = string.format("%s collision and query for %d objects", state and "Disabled" or "Enabled", objectsChanged),
        Duration = 3
    })
end

NoCollisionToggle:OnChanged(function(state) toggleInvisPartsCollision(state) end)

LocalPlayer.CharacterAdded:Connect(function()
    if Options.NoCollisionToggle and Options.NoCollisionToggle.Value then
        task.wait(1)
        toggleInvisPartsCollision(true)
    end
end)

local InvisPartsTransparencyToggle = Tabs.Main:AddToggle("InvisPartsTransparencyToggle", { Title = "Barriers Visible", Default = false })

local function setInvisPartsTransparency(transparent)
    local invisParts = workspace:FindFirstChild("Game") and
                      workspace.Game:FindFirstChild("Map") and
                      workspace.Game.Map:FindFirstChild("InvisParts")
    if not invisParts then
        Fluent:Notify({ Title = "Barriers Visible", Content = "InvisParts folder not found!", Duration = 3 })
        return
    end
    local changed = 0
    if transparent then
        for _, obj in ipairs(invisParts:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then
                obj.Transparency = 0
                changed = changed + 1
            end
        end
        Fluent:Notify({ Title = "Barriers Visible", Content = string.format("Set Transparency = 0 for %d objects", changed), Duration = 3 })
    else
        for _, obj in ipairs(invisParts:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then
                obj.Transparency = 1
                changed = changed + 1
            end
        end
        Fluent:Notify({ Title = "Barriers Disable", Content = string.format("Set Transparency = 1 for %d objects", changed), Duration = 3 })
    end
end

InvisPartsTransparencyToggle:OnChanged(function(state)
    setInvisPartsTransparency(state)
    if state then
        local invisParts = workspace:FindFirstChild("Game") and
                          workspace.Game:FindFirstChild("Map") and
                          workspace.Game.Map:FindFirstChild("InvisParts")
        if invisParts then
            invisParts.DescendantAdded:Connect(function(obj)
                if state then
                    if obj:IsA("BasePart") or obj:IsA("Decal") then
                        task.wait(0.05)
                        obj.Transparency = 0
                    end
                end
            end)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if Options.InvisPartsTransparencyToggle and Options.InvisPartsTransparencyToggle.Value then
        task.wait(1)
        setInvisPartsTransparency(true)
    end
end)

Players.PlayerRemoving:Connect(function(pl)
    if pl == LocalPlayer and Options.InvisPartsTransparencyToggle and Options.InvisPartsTransparencyToggle.Value then
        setInvisPartsTransparency(false)
    end
end)

local LeaderboardToggle = Tabs.Main:AddButton({
    Title = "Unlock Leaderboard; Zoom; Front View",
    Callback = function()
        local starterGui = game:GetService("StarterGui")
        local playerGui = player:WaitForChild("PlayerGui")
        if playerGui:FindFirstChild("CustomTopGui") then playerGui.CustomTopGui:Destroy() end
        starterGui:SetCore("TopbarEnabled", false)
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "CustomTopGui"
        screenGui.IgnoreGuiInset = false
        screenGui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
        screenGui.DisplayOrder = 100
        screenGui.ResetOnSpawn = false
        screenGui.Parent = playerGui
        local frame = Instance.new("Frame")
        frame.Parent = screenGui
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Position = UDim2.new(0, 0, 0, 0)
        frame.Size = UDim2.new(1, 0, 1, -2)
        local scrollingFrame = Instance.new("ScrollingFrame")
        scrollingFrame.Name = "Right"
        scrollingFrame.Parent = frame
        scrollingFrame.BackgroundTransparency = 1
        scrollingFrame.BorderSizePixel = 0
        scrollingFrame.Position = UDim2.new(0, 12, 0, 0)
        scrollingFrame.Size = UDim2.new(1, -24, 1, 0)
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
        scrollingFrame.ScrollBarThickness = 0
        scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.X
        scrollingFrame.ScrollingEnabled = false
        local uiListLayout = Instance.new("UIListLayout")
        uiListLayout.Parent = scrollingFrame
        uiListLayout.Padding = UDim.new(0, 12)
        uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        uiListLayout.FillDirection = Enum.FillDirection.Horizontal
        uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

        local buttonsConfig = {
            { name = "SecondaryButton", layoutOrder = 999, icon = "rbxassetid://126943351764139", label = "Zoom", width = 100, labelWidth = 45, key = "Secondary" },
            { name = "ReloadButton", layoutOrder = 997, icon = "rbxassetid://78648212535999", label = "Front View / View", width = 173, labelWidth = 118, key = "Reload" },
            { name = "LeaderboardButton", layoutOrder = 998, icon = "rbxassetid://5107166345", label = "Leaderboard", width = 143, labelWidth = 88, key = "Leaderboard" }
        }

        for _, config in ipairs(buttonsConfig) do
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local Button = Instance.new("Frame")
            Button.Name = config.name
            Button.Parent = scrollingFrame
            Button.BackgroundTransparency = 1
            Button.ClipsDescendants = true
            Button.LayoutOrder = config.layoutOrder
            Button.Size = UDim2.new(0, 44, 0, 44)
            Button.ZIndex = 20
            local IconButton = Instance.new("Frame")
            IconButton.Name = "IconButton"
            IconButton.Parent = Button
            IconButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            IconButton.BackgroundTransparency = 0.3
            IconButton.BorderSizePixel = 0
            IconButton.ClipsDescendants = true
            IconButton.Size = UDim2.new(1, 0, 1, 0)
            IconButton.ZIndex = 2
            local UICorner_1 = Instance.new("UICorner")
            UICorner_1.CornerRadius = UDim.new(1, 0)
            UICorner_1.Parent = IconButton
            local Menu = Instance.new("ScrollingFrame")
            Menu.Name = "Menu"
            Menu.Parent = IconButton
            Menu.BackgroundTransparency = 1
            Menu.BorderSizePixel = 0
            Menu.Position = UDim2.new(0, 4, 0, 0)
            Menu.Selectable = false
            Menu.Size = UDim2.new(1, 0, 1, 0)
            Menu.ZIndex = 20
            Menu.BottomImage = ""
            Menu.CanvasSize = UDim2.new(0, 0, 1, -1)
            Menu.HorizontalScrollBarInset = Enum.ScrollBarInset.Always
            Menu.ScrollBarThickness = 3
            Menu.TopImage = ""
            local MenuUIListLayout = Instance.new("UIListLayout")
            MenuUIListLayout.Name = "MenuUIListLayout"
            MenuUIListLayout.Parent = Menu
            MenuUIListLayout.FillDirection = Enum.FillDirection.Horizontal
            MenuUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            MenuUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            local MenuGap = Instance.new("Frame")
            MenuGap.Name = "MenuGap"
            MenuGap.Parent = Menu
            MenuGap.AnchorPoint = Vector2.new(0, 0.5)
            MenuGap.BackgroundTransparency = 1
            MenuGap.Size = UDim2.new(0, 4, 0, 0)
            MenuGap.Visible = false
            MenuGap.ZIndex = 5
            local IconSpot = Instance.new("Frame")
            IconSpot.Name = "IconSpot"
            IconSpot.Parent = Menu
            IconSpot.AnchorPoint = Vector2.new(0, 0.5)
            IconSpot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            IconSpot.BackgroundTransparency = 1
            IconSpot.Position = UDim2.new(0, 4, 0.5, 0)
            IconSpot.Size = UDim2.new(0, 36, 1, -8)
            IconSpot.ZIndex = 5
            local UICorner_2 = Instance.new("UICorner")
            UICorner_2.CornerRadius = UDim.new(1, 0)
            UICorner_2.Parent = IconSpot
            local IconOverlay = Instance.new("Frame")
            IconOverlay.Name = "IconOverlay"
            IconOverlay.Parent = IconSpot
            IconOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            IconOverlay.BackgroundTransparency = 0.925
            IconOverlay.Size = UDim2.new(1, 0, 1, 0)
            IconOverlay.Visible = false
            IconOverlay.ZIndex = 6
            local UICorner_3 = Instance.new("UICorner")
            UICorner_3.CornerRadius = UDim.new(1, 0)
            UICorner_3.Parent = IconOverlay
            local ClickRegion = Instance.new("TextButton")
            ClickRegion.Name = "ClickRegion"
            ClickRegion.Parent = IconSpot
            ClickRegion.BackgroundTransparency = 1
            ClickRegion.Size = UDim2.new(1, 0, 1, 0)
            ClickRegion.ZIndex = 20
            ClickRegion.Text = ""
            local UICorner_4 = Instance.new("UICorner")
            UICorner_4.CornerRadius = UDim.new(1, 0)
            UICorner_4.Parent = ClickRegion
            local Contents = Instance.new("Frame")
            Contents.Name = "Contents"
            Contents.Parent = IconSpot
            Contents.BackgroundTransparency = 1
            Contents.Size = UDim2.new(1, 0, 1, 0)
            local ContentsList = Instance.new("UIListLayout")
            ContentsList.Name = "ContentsList"
            ContentsList.Parent = Contents
            ContentsList.FillDirection = Enum.FillDirection.Horizontal
            ContentsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            ContentsList.SortOrder = Enum.SortOrder.LayoutOrder
            ContentsList.VerticalAlignment = Enum.VerticalAlignment.Center
            ContentsList.Padding = UDim.new(0, 3)
            local PaddingLeft = Instance.new("Frame")
            PaddingLeft.Name = "PaddingLeft"
            PaddingLeft.Parent = Contents
            PaddingLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            PaddingLeft.BackgroundTransparency = 1
            PaddingLeft.BorderColor3 = Color3.fromRGB(0, 0, 0)
            PaddingLeft.BorderSizePixel = 0
            PaddingLeft.LayoutOrder = 1
            PaddingLeft.Size = UDim2.new(0, 9, 1, 0)
            PaddingLeft.ZIndex = 5
            local PaddingCenter = Instance.new("Frame")
            PaddingCenter.Name = "PaddingCenter"
            PaddingCenter.Parent = Contents
            PaddingCenter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            PaddingCenter.BackgroundTransparency = 1
            PaddingCenter.BorderColor3 = Color3.fromRGB(0, 0, 0)
            PaddingCenter.BorderSizePixel = 0
            PaddingCenter.LayoutOrder = 3
            PaddingCenter.Size = UDim2.new(0, 0, 1, 0)
            PaddingCenter.ZIndex = 5
            local PaddingRight = Instance.new("Frame")
            PaddingRight.Name = "PaddingRight"
            PaddingRight.Parent = Contents
            PaddingRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            PaddingRight.BackgroundTransparency = 1
            PaddingRight.BorderColor3 = Color3.fromRGB(0, 0, 0)
            PaddingRight.BorderSizePixel = 0
            PaddingRight.LayoutOrder = 5
            PaddingRight.Size = UDim2.new(0, 11, 1, 0)
            PaddingRight.ZIndex = 5
            local IconLabelContainer = Instance.new("Frame")
            IconLabelContainer.Name = "IconLabelContainer"
            IconLabelContainer.Parent = Contents
            IconLabelContainer.AnchorPoint = Vector2.new(0, 0.5)
            IconLabelContainer.BackgroundTransparency = 1
            IconLabelContainer.LayoutOrder = 4
            IconLabelContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            IconLabelContainer.Size = UDim2.new(0, 0, 1, 0)
            IconLabelContainer.Visible = false
            IconLabelContainer.ZIndex = 3
            local IconLabel = Instance.new("TextLabel")
            IconLabel.Name = "IconLabel"
            IconLabel.Parent = IconLabelContainer
            IconLabel.BackgroundTransparency = 1
            IconLabel.LayoutOrder = 4
            IconLabel.Size = UDim2.new(0, 1306, 1, 0)
            IconLabel.ZIndex = 15
            IconLabel.Font = Enum.Font.GothamMedium
            IconLabel.Text = config.label
            IconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            IconLabel.TextSize = 16
            IconLabel.TextWrapped = true
            IconLabel.TextXAlignment = Enum.TextXAlignment.Left
            IconLabel.Visible = false
            local IconImage = Instance.new("ImageLabel")
            IconImage.Name = "IconImage"
            IconImage.Parent = Contents
            IconImage.AnchorPoint = Vector2.new(0, 0.5)
            IconImage.BackgroundTransparency = 1
            IconImage.LayoutOrder = 2
            IconImage.Position = UDim2.new(0, 11, 0.5, 0)
            IconImage.Size = UDim2.new(0.7, 0, 0.7, 0)
            IconImage.ZIndex = 15
            IconImage.Image = config.icon
            local IconImageCorner = Instance.new("UICorner")
            IconImageCorner.CornerRadius = UDim.new(0, 0)
            IconImageCorner.Name = "IconImageCorner"
            IconImageCorner.Parent = IconImage
            local IconImageRatio = Instance.new("UIAspectRatioConstraint")
            IconImageRatio.Name = "IconImageRatio"
            IconImageRatio.Parent = IconImage
            IconImageRatio.DominantAxis = Enum.DominantAxis.Height
            local IconSpotGradient = Instance.new("UIGradient")
            IconSpotGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(96, 98, 100)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(77, 78, 80))
            }
            IconSpotGradient.Rotation = 45
            IconSpotGradient.Name = "IconSpotGradient"
            IconSpotGradient.Parent = IconSpot
            local IconGradient = Instance.new("UIGradient")
            IconGradient.Name = "IconGradient"
            IconGradient.Parent = IconButton

            local isHovering = false
            local currentTween = nil
            local hideDelay = 0.3
            local isMouseDown = false
            local smallButtonSize = UDim2.new(0, 44, 0, 44)
            local largeButtonSize = UDim2.new(0, config.width, 0, 44)
            local smallIconSpotSize = UDim2.new(0, 36, 1, -8)
            local largeIconSpotSize = UDim2.new(0, config.width - 8, 1, -8)
            local smallLabelSize = UDim2.new(0, 0, 1, 0)
            local largeLabelSize = UDim2.new(0, config.labelWidth, 1, 0)

            local function hideTextWithDelay()
                task.wait(hideDelay)
                if not isHovering then
                    IconLabel.Visible = false
                    IconLabelContainer.Visible = false
                    IconOverlay.Visible = false
                end
            end

            local function expand()
                isHovering = true
                if currentTween then currentTween:Cancel() end
                IconLabel.Visible = true
                IconLabelContainer.Visible = true
                IconOverlay.Visible = true
                currentTween = TweenService:Create(Button, tweenInfo, {Size = largeButtonSize})
                currentTween:Play()
                TweenService:Create(IconSpot, tweenInfo, {Size = largeIconSpotSize}):Play()
                TweenService:Create(IconLabelContainer, tweenInfo, {Size = largeLabelSize}):Play()
            end

            local function contract()
                isHovering = false
                if currentTween then currentTween:Cancel() end
                currentTween = TweenService:Create(Button, tweenInfo, {Size = smallButtonSize})
                currentTween:Play()
                TweenService:Create(IconSpot, tweenInfo, {Size = smallIconSpotSize}):Play()
                TweenService:Create(IconLabelContainer, tweenInfo, {Size = smallLabelSize}):Play()
                hideTextWithDelay()
            end

            ClickRegion.MouseEnter:Connect(function() expand() end)
            ClickRegion.MouseLeave:Connect(function()
                contract()
                if isMouseDown then
                    isMouseDown = false
                    LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({Key = config.key, Down = false})
                end
            end)
            ClickRegion.MouseButton1Down:Connect(function()
                isMouseDown = true
                LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({Key = config.key, Down = true})
            end)
            ClickRegion.MouseButton1Up:Connect(function()
                isMouseDown = false
                LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({Key = config.key, Down = false})
            end)

            player.CharacterAdded:Connect(function()
                task.wait(0.1)
                isHovering = false
                isMouseDown = false
                if currentTween then currentTween:Cancel() currentTween = nil end
                Button.Size = smallButtonSize
                IconSpot.Size = smallIconSpotSize
                IconLabelContainer.Size = smallLabelSize
                IconLabel.Visible = false
                IconLabelContainer.Visible = false
                IconOverlay.Visible = false
            end)
        end

        Fluent:Notify({ Title = "Custom Leaderboard", Content = "Custom leaderboard UI has been created!", Duration = 3 })
    end
})

if not workspace:FindFirstChild("SecurityPart") then
    local SecurityPart = Instance.new("Part")
    SecurityPart.Name = "SecurityPart"
    SecurityPart.Size = Vector3.new(10, 1, 10)
    SecurityPart.Position = Vector3.new(5000, 5000, 5000)
    SecurityPart.Anchored = true
    SecurityPart.CanCollide = true
    SecurityPart.Parent = workspace
end
-- ====== ВКЛАДКА AUTO FARM ======

local AutoTab = Window:AddTab({ Title = "Auto Farm", Icon = "solar/clock-circle-bold" })

AutoTab:AddSection("Farmings")

local AutoMoneyFarmToggle = AutoTab:AddToggle("AutoMoneyFarmToggle", {
    Title = "Auto Farm Money",
    Default = false
})

local AutoTicketFarmToggle = AutoTab:AddToggle("AutoTicketFarmToggle", {
    Title = "Auto Farm Tickets",
    Default = false
})

local AFKFarmToggle = AutoTab:AddToggle("AFKFarmToggle", {
    Title = "AFK Farm",
    Default = false
})

AutoTab:AddSection("Teleports")

AutoTab:AddButton({
    Title = "Custom Server",
    Description = "Create Custom Server",
    Callback = function()
        Fluent:Notify({ Title = "Create", Content = "Create Custom Server", Duration = 3 })
        task.wait(1)
        local success, errorMsg = pcall(function()
            game:GetService("TeleportService"):Teleport(99214917572799)
        end)
        if not success then
            Fluent:Notify({ Title = "Failed Custom Server", Content = "Failed Custom Server: " .. tostring(errorMsg), Duration = 5 })
        end
    end
})

local TeleportObjectiveButton = AutoTab:AddButton({
    Title = "Teleport to Objective",
    Callback = function()
        local objectives = {}
        local gameFolder = workspace:FindFirstChild("Game")
        if not gameFolder then return end
        local mapFolder = gameFolder:FindFirstChild("Map")
        if not mapFolder then return end

        local objectivesFolder = nil
        local partsFolder = mapFolder:FindFirstChild("Parts")
        if partsFolder then objectivesFolder = partsFolder:FindFirstChild("Objectives") end
        if not objectivesFolder then objectivesFolder = mapFolder:FindFirstChild("Objectives") end
        if not objectivesFolder then
            for _, obj in ipairs(mapFolder:GetDescendants()) do
                if obj.Name == "Objectives" and (obj:IsA("Folder") or obj:IsA("Model")) then
                    objectivesFolder = obj
                    break
                end
            end
        end
        if not objectivesFolder then return end

        for _, obj in pairs(objectivesFolder:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
                local teleportPart = nil
                if obj:IsA("BasePart") then
                    teleportPart = obj
                elseif obj:IsA("Model") then
                    teleportPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or
                                  obj:FindFirstChild("Head") or obj:FindFirstChild("Torso") or
                                  obj:FindFirstChildWhichIsA("BasePart")
                end
                if teleportPart then
                    table.insert(objectives, {Name = obj.Name, Part = teleportPart, Position = teleportPart.Position})
                end
            end
        end

        if #objectives == 0 then return end
        local selectedObjective = objectives[math.random(1, #objectives)]
        local character = LocalPlayer.Character
        if not character then return end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        humanoidRootPart.CFrame = CFrame.new(selectedObjective.Position + Vector3.new(0, 5, 0))
    end
})

local TeleportSpawnButton = AutoTab:AddButton({
    Title = "Teleport to Spawn",
    Callback = function()
        local gameFolder = workspace:FindFirstChild("Game")
        if not gameFolder then return end
        local mapFolder = gameFolder:FindFirstChild("Map")
        if not mapFolder then return end
        local partsFolder = mapFolder:FindFirstChild("Parts")
        if not partsFolder then return end
        local spawnsFolder = partsFolder:FindFirstChild("Spawns")
        if not spawnsFolder then return end

        local spawns = {}
        for _, obj in pairs(spawnsFolder:GetChildren()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") then
                table.insert(spawns, obj)
            elseif obj:IsA("Model") then
                local part = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or
                            obj:FindFirstChild("Head") or obj:FindFirstChild("Torso") or
                            obj:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(spawns, part) end
            end
        end

        if #spawns == 0 then return end
        local selectedSpawn = spawns[math.random(1, #spawns)]
        local character = LocalPlayer.Character
        if not character then return end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        humanoidRootPart.CFrame = CFrame.new(selectedSpawn.Position + Vector3.new(0, 3, 0))
    end
})

local AutoMoneyFarmConnection = nil
local AutoWinConnection = nil
local AutoTicketFarmConnection = nil
local AutoReviveModule = nil

character = LocalPlayer.Character
humanoid = character and character:FindFirstChild("Humanoid")
rootPart = character and character:FindFirstChild("HumanoidRootPart")

function startAutoWin()
    if AutoWinConnection then return end
    AutoWinConnection = RunService.Heartbeat:Connect(function()
        local securityPart = workspace:FindFirstChild("SecurityPart")
        if not securityPart then return end
        local currentCharacter = LocalPlayer.Character
        if not currentCharacter then return end
        local currentRootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentRootPart then return end
        if not currentCharacter:GetAttribute("Downed") then
            currentRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

function stopAutoWin()
    if AutoWinConnection then
        AutoWinConnection:Disconnect()
        AutoWinConnection = nil
    end
end

function initAutoReviveModule()
    local reviveRange = 15
    local loopDelay = 0.25
    local autoReviveEnabled = false
    local reviveLoopHandle = nil
    local interactEvent = ReplicatedStorage:FindFirstChild("Events") and
                         ReplicatedStorage.Events:FindFirstChild("Character") and
                         ReplicatedStorage.Events.Character:FindFirstChild("Interact")

    if not interactEvent then
        warn("Auto Revive Module: Interact event not found!")
        return nil
    end

    local function isPlayerDowned(pl)
        if not pl or not pl.Character then return false end
        local char = pl.Character
        if char:GetAttribute("Downed") == true then return true end
        local ragdollsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Ragdolls")
        if ragdollsFolder and ragdollsFolder:FindFirstChild(pl.Name) then return true end
        return false
    end

    local function getDownedRootPart(pl)
        if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            return pl.Character.HumanoidRootPart
        end
        local ragdollsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Ragdolls")
        if ragdollsFolder then
            local ragdoll = ragdollsFolder:FindFirstChild(pl.Name)
            if ragdoll then
                return ragdoll:FindFirstChild("HumanoidRootPart") or
                       ragdoll:FindFirstChild("Torso") or
                       ragdoll:FindFirstChild("Head") or
                       ragdoll:FindFirstChildWhichIsA("BasePart")
            end
        end
        return nil
    end

    function startAutoRevive()
        if reviveLoopHandle then return end
        reviveLoopHandle = task.spawn(function()
            while autoReviveEnabled do
                local currentPlayer = LocalPlayer
                if currentPlayer then
                    local char = currentPlayer.Character
                    local securityPart = workspace:FindFirstChild("SecurityPart")

                    if char and char:GetAttribute("Downed") then
                        pcall(function()
                            ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                        end)
                        if securityPart then
                            task.wait(1)
                            local newChar = currentPlayer.Character
                            if newChar and newChar:FindFirstChild("HumanoidRootPart") then
                                newChar.HumanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                            end
                        end
                        task.wait(1)
                    elseif char and char:FindFirstChild("HumanoidRootPart") then
                        local myHRP = char.HumanoidRootPart
                        local downedFound = false

                        for _, pl in ipairs(Players:GetPlayers()) do
                            if pl ~= currentPlayer and isPlayerDowned(pl) then
                                local targetRoot = getDownedRootPart(pl)
                                if targetRoot then
                                    downedFound = true
                                    local dist = (myHRP.Position - targetRoot.Position).Magnitude
                                    if dist > reviveRange then
                                        local targetPos = targetRoot.Position
                                        myHRP.CFrame = CFrame.new(targetPos.X, targetPos.Y - 5, targetPos.Z)
                                        task.wait(0.1)
                                    end
                                    pcall(function()
                                        interactEvent:FireServer("Revive", true, pl.Name)
                                    end)
                                    task.wait(0.2)
                                end
                            end
                        end

                        if not downedFound and not char:GetAttribute("Downed") and securityPart then
                            myHRP.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                        end
                    end
                end
                task.wait(loopDelay)
            end
            reviveLoopHandle = nil
        end)
    end

    function stopAutoRevive()
        autoReviveEnabled = false
        if reviveLoopHandle then
            task.cancel(reviveLoopHandle)
            reviveLoopHandle = nil
        end
    end

    function ToggleAutoRevive(state)
        autoReviveEnabled = state
        if autoReviveEnabled then
            startAutoRevive()
        else
            stopAutoRevive()
        end
    end

    return {
        Toggle = ToggleAutoRevive,
        Start = function() ToggleAutoRevive(true) end,
        Stop = function() ToggleAutoRevive(false) end,
        IsEnabled = function() return autoReviveEnabled end,
    }
end

function startAutoMoneyFarm()
    if AutoMoneyFarmConnection then stopAutoMoneyFarm() end

    if not AutoReviveModule then
        AutoReviveModule = initAutoReviveModule()
        if not AutoReviveModule then
            Fluent:Notify({ Title = "Auto Farm Money", Content = "Failed to initialize revive module!", Duration = 5 })
            return
        end
    end

    AutoReviveModule.Start()

    AutoMoneyFarmConnection = RunService.Heartbeat:Connect(function()
        if not AutoReviveModule or not AutoReviveModule.IsEnabled() then
            if Options.AutoMoneyFarmToggle and Options.AutoMoneyFarmToggle.Value then
                AutoReviveModule.Start()
            end
        end
    end)
end

function stopAutoMoneyFarm()
    if AutoMoneyFarmConnection then
        AutoMoneyFarmConnection:Disconnect()
        AutoMoneyFarmConnection = nil
    end
    if AutoReviveModule then AutoReviveModule.Stop() end
end

AutoMoneyFarmToggle:OnChanged(function(state)
    if state then startAutoMoneyFarm() else stopAutoMoneyFarm() end
end)

AFKFarmToggle:OnChanged(function(state)
    if state then startAutoWin() else stopAutoWin() end
end)

AutoTicketFarmToggle:OnChanged(function(state)
    local yOffset = 15
    local currentTicket = nil
    local ticketProcessedTime = 0

    if state then
        local securityPart = workspace:FindFirstChild("SecurityPart")
        if not securityPart then return end

        if AutoTicketFarmConnection then AutoTicketFarmConnection:Disconnect() end

        AutoTicketFarmConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end

            local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")

            if char:GetAttribute("Downed") then
                pcall(function()
                    ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                end)
                humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                return
            end

            if tickets then
                local activeTickets = tickets:GetChildren()
                if #activeTickets > 0 then
                    if not currentTicket or not currentTicket.Parent then
                        currentTicket = activeTickets[1]
                        ticketProcessedTime = tick()
                    end
                    if currentTicket and currentTicket.Parent then
                        local ticketPart = currentTicket:FindFirstChild("HumanoidRootPart") or currentTicket:IsA("BasePart") and currentTicket
                        if ticketPart then
                            local targetPosition = ticketPart.Position + Vector3.new(0, yOffset, 0)
                            humanoidRootPart.CFrame = CFrame.new(targetPosition)
                            if tick() - ticketProcessedTime > 0.1 then
                                humanoidRootPart.CFrame = ticketPart.CFrame
                            end
                        else
                            currentTicket = nil
                        end
                    else
                        humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                        currentTicket = nil
                    end
                else
                    humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                    currentTicket = nil
                end
            else
                humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                currentTicket = nil
            end
        end)
    else
        if AutoTicketFarmConnection then
            AutoTicketFarmConnection:Disconnect()
            AutoTicketFarmConnection = nil
        end
        currentTicket = nil
        local char = LocalPlayer.Character
        if char then
            local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
            local securityPart = workspace:FindFirstChild("SecurityPart")
            if humanoidRootPart and securityPart then
                humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- ====== ВКЛАДКА VIP SERVER ======

local VIPTab = Window:AddTab({ Title = "VIP Server", Icon = "solar/crown-bold" })

VIPTab:AddSection("Special Round")

local VIPRoundInput = VIPTab:AddInput("VIPRoundInput", {
    Title = "Special Round Name",
    Default = "",
    Placeholder = "Enter round name",
    Finished = false,
    Callback = function(Value) getgenv().VIPRoundName = Value end
})

local VIPRoundToggle = VIPTab:AddToggle("VIPRoundToggle", {
    Title = "Auto Special Round",
    Default = false,
    Callback = function(Value) getgenv().VIPRoundEnabled = Value end
})

VIPTab:AddSection("Vote System")

local VoteValues = {"1", "2", "3", "4"}

local VoteInput1 = VIPTab:AddDropdown("VoteInput1", {
    Title = "Vote Option 1",
    Values = VoteValues,
    Multi = false,
    Default = "1",
    Callback = function(Value) getgenv().VoteValue1 = tonumber(Value) end
})

local VoteInput2 = VIPTab:AddDropdown("VoteInput2", {
    Title = "Vote Option 2",
    Values = VoteValues,
    Multi = false,
    Default = "1",
    Callback = function(Value) getgenv().VoteValue2 = tonumber(Value) end
})

local VoteToggle = VIPTab:AddToggle("VoteToggle", {
    Title = "Auto Vote",
    Default = false,
    Callback = function(Value) getgenv().VoteEnabled = Value end
})

VIPTab:AddSection("Skip Time")

local TimerCommandToggle = VIPTab:AddToggle("TimerCommandToggle", {
    Title = "Auto Skip Time",
    Default = false,
    Callback = function(Value) getgenv().TimerCommandEnabled = Value end
})

getgenv().VIPRoundName = getgenv().VIPRoundName or ""
getgenv().VIPRoundEnabled = false
getgenv().VIPRoundActivated = false
getgenv().VoteValue1 = 1
getgenv().VoteValue2 = 1
getgenv().VoteEnabled = false
getgenv().VoteActivated = false
getgenv().TimerCommandEnabled = false
getgenv().TimerCommandActivated = false

local timerConnection = RunService.Heartbeat:Connect(function()
    local stats = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats")
    if stats then
        local timerValue = stats:GetAttribute("Timer")
        local roundStarted = stats:GetAttribute("RoundStarted")

        if timerValue == 30 then
            if getgenv().VIPRoundEnabled and not getgenv().VIPRoundActivated then
                local roundName = getgenv().VIPRoundName or ""
                if roundName ~= "" then
                    local args = {[1] = "!specialround " .. roundName}
                    pcall(function()
                        ReplicatedStorage.Events.Admin.VIPCommand:InvokeServer(unpack(args))
                        getgenv().VIPRoundActivated = true
                        task.delay(10, function() getgenv().VIPRoundActivated = false end)
                    end)
                end
            end

            if getgenv().VoteEnabled and not getgenv().VoteActivated then
                local value1 = getgenv().VoteValue1 or 1
                local value2 = getgenv().VoteValue2 or 1
                local args1 = {[1] = value1}
                local args2 = {[1] = value2, [2] = true}
                pcall(function()
                    ReplicatedStorage.Events.Player.Vote:FireServer(unpack(args1))
                    ReplicatedStorage.Events.Player.Vote:FireServer(unpack(args2))
                    getgenv().VoteActivated = true
                    task.delay(10, function() getgenv().VoteActivated = false end)
                end)
            end

            if getgenv().TimerCommandEnabled and not getgenv().TimerCommandActivated then
                if roundStarted == false then
                    local args = {[1] = "!timer 1"}
                    pcall(function()
                        ReplicatedStorage.Events.Admin.VIPCommand:InvokeServer(unpack(args))
                        getgenv().TimerCommandActivated = true
                        task.delay(10, function() getgenv().TimerCommandActivated = false end)
                    end)
                end
            end
        else
            if timerValue ~= 30 then
                getgenv().VIPRoundActivated = false
                getgenv().VoteActivated = false
                getgenv().TimerCommandActivated = false
            end
        end
    end
end)

-- ====== ВКЛАДКА MISC (начало) ======

local MiscTab = Window:AddTab({ Title = "Misc", Icon = "solar/list-bold" })
MiscTab:AddSection("Player Adjustments")

local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187"
}
local appliedOnce = false
local playerModelPresent = false
getgenv().ApplyMode = "Not Optimized"

local requiredFields = {
    Friction = true,
    AirStrafeAcceleration = true,
    JumpHeight = true,
    RunDeaccel = true,
    JumpSpeedMultiplier = true,
    JumpCap = true,
    SprintCap = true,
    WalkSpeedMultiplier = true,
    BhopEnabled = true,
    Speed = true,
    AirAcceleration = true,
    RunAccel = true,
    SprintAcceleration = true
}

local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    for field, _ in pairs(requiredFields) do
        if rawget(tbl, field) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function()
            if hasAllFields(obj) then return obj end
        end)
        if success and result then table.insert(tables, result) end
    end
    return tables
end

local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end

    if getgenv().ApplyMode == "Optimized" then
        task.spawn(function()
            for i, tableObj in ipairs(targets) do
                if tableObj and typeof(tableObj) == "table" then
                    pcall(callback, tableObj)
                end
                if i % 3 == 0 then task.wait() end
            end
        end)
    else
        for i, tableObj in ipairs(targets) do
            if tableObj and typeof(tableObj) == "table" then
                pcall(callback, tableObj)
            end
        end
    end
end

local function applyStoredSettings()
    local settings = {
        {field = "Speed", value = tonumber(currentSettings.Speed)},
        {field = "JumpCap", value = tonumber(currentSettings.JumpCap)},
        {field = "AirStrafeAcceleration", value = tonumber(currentSettings.AirStrafeAcceleration)}
    }
    for _, setting in ipairs(settings) do
        if setting.value and tostring(setting.value) ~= "1500" and tostring(setting.value) ~= "1" and tostring(setting.value) ~= "187" then
            applyToTables(function(obj) obj[setting.field] = setting.value end)
        end
    end
end

local function applySettingsWithDelay()
    if not playerModelPresent or appliedOnce then return end
    appliedOnce = true
    local settings = {
        {field = "Speed", value = tonumber(currentSettings.Speed), delay = math.random(1, 14)},
        {field = "JumpCap", value = tonumber(currentSettings.JumpCap), delay = math.random(1, 14)},
        {field = "AirStrafeAcceleration", value = tonumber(currentSettings.AirStrafeAcceleration), delay = math.random(1, 14)}
    }
    for _, setting in ipairs(settings) do
        if setting.value and tostring(setting.value) ~= "1500" and tostring(setting.value) ~= "1" and tostring(setting.value) ~= "187" then
            task.spawn(function()
                task.wait(setting.delay)
                applyToTables(function(obj) obj[setting.field] = setting.value end)
            end)
        end
    end
end

local function isPlayerModelPresent()
    local GameFolder = workspace:FindFirstChild("Game")
    local PlayersFolder = GameFolder and GameFolder:FindFirstChild("Players")
    return PlayersFolder and PlayersFolder:FindFirstChild(player.Name) ~= nil
end

local SpeedInput = MiscTab:AddInput("SpeedInput", {
    Title = "Player Speed",
    Default = currentSettings.Speed,
    Placeholder = "Default 1500",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local val = tonumber(Value)
        if val and val >= 1450 and val <= 100008888 then
            currentSettings.Speed = tostring(val)
            applyToTables(function(obj) obj.Speed = val end)
        end
    end
})

local JumpPowerInput = MiscTab:AddInput("JumpPowerInput", {
    Title = "Player Jump",
    Default = "3.5",
    Placeholder = "",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        if Value and tonumber(Value) then JumpPowerValue = tonumber(Value) end
    end
})

local JumpCapInput = MiscTab:AddInput("JumpCapInput", {
    Title = "Player Jump Cap",
    Default = currentSettings.JumpCap,
    Placeholder = "Default 1",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local val = tonumber(Value)
        if val and val >= 0.1 and val <= 5088888 then
            currentSettings.JumpCap = tostring(val)
            applyToTables(function(obj) obj.JumpCap = val end)
        end
    end
})

local StrafeInput = MiscTab:AddInput("StrafeInput", {
    Title = "Player Strafe Acceleration",
    Default = currentSettings.AirStrafeAcceleration,
    Placeholder = "Default 187",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local val = tonumber(Value)
        if val and val >= 1 and val <= 1000888888 then
            currentSettings.AirStrafeAcceleration = tostring(val)
            applyToTables(function(obj) obj.AirStrafeAcceleration = val end)
        end
    end
})

local ApplyMethodDropdown = MiscTab:AddDropdown("ApplyMethodDropdown", {
    Title = "Select Apply Method",
    Values = {"Not Optimized", "Optimized"},
    Multi = false,
    Default = getgenv().ApplyMode,
    Callback = function(Value) getgenv().ApplyMode = Value end
})

local EventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
local ChangeSettingRemote = EventsFolder and EventsFolder:WaitForChild("Data", 10) and EventsFolder.Data:WaitForChild("ChangeSetting", 10)

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules", 10)
local ClientFolder = ModulesFolder and ModulesFolder:WaitForChild("Client", 10)
local SettingsFolder = ClientFolder and ClientFolder:WaitForChild("Settings", 10)
local UpdatedEvent = SettingsFolder and SettingsFolder:WaitForChild("Updated", 10)

local FovInput = MiscTab:AddInput("FovInput", {
    Title = "Player FOV",
    Default = "",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and ChangeSettingRemote and UpdatedEvent then
            ChangeSettingRemote:InvokeServer(2, num)
            UpdatedEvent:Fire(2, num)
        end
    end
})

local JumpPowerValue = 3.5
local MaxJumpsValue = math.huge
local CurrentJumpCount = 0
local JumpHumanoid = nil
local JumpRootPart = nil

local function setupJumpPower(character)
    task.wait(0.5)
    JumpHumanoid = character:FindFirstChild("Humanoid")
    JumpRootPart = character:FindFirstChild("HumanoidRootPart")
    if JumpHumanoid and JumpRootPart then
        CurrentJumpCount = 0
        JumpHumanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Landed then CurrentJumpCount = 0 end
        end)
        JumpHumanoid.Jumping:Connect(function(isJumping)
            if isJumping and CurrentJumpCount < MaxJumpsValue then
                CurrentJumpCount = CurrentJumpCount + 1
                JumpHumanoid.JumpHeight = JumpPowerValue
                if CurrentJumpCount > 1 and JumpRootPart then
                    JumpRootPart:ApplyImpulse(Vector3.new(0, JumpPowerValue * JumpRootPart.Mass, 0))
                end
            end
        end)
    end
end

Players.LocalPlayer.CharacterAdded:Connect(setupJumpPower)

if LocalPlayer.Character then
    task.spawn(function() setupJumpPower(LocalPlayer.Character) end)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    task.wait(0.5)
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

MiscTab:AddSection("Bounce")

local BounceToggle = MiscTab:AddToggle("BounceToggle", {
    Title = "Modify Bounce",
    Default = false
})

local BounceInput = MiscTab:AddInput("BounceInput", {
    Title = "Player Bounce",
    Default = "110",
    Placeholder = "Enter bounce speed",
    Numeric = true,
    Finished = false
})

local bounceConnection = nil

local function updateBounce()
    if not BounceToggle.Value then return end
    local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
    if not gamePlayers then return end
    local playerModel = gamePlayers:FindFirstChild(player.Name)
    if not playerModel then return end
    local hum = playerModel:FindFirstChild("Humanoid")
    if not hum then return end
    local speedValue = tonumber(BounceInput.Value) or 110
    hum.WalkSpeed = speedValue
end

BounceToggle:OnChanged(function(state)
    if state then
        if bounceConnection then bounceConnection:Disconnect() end
        bounceConnection = RunService.Heartbeat:Connect(updateBounce)
    else
        if bounceConnection then
            bounceConnection:Disconnect()
            bounceConnection = nil
        end
        local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
        if gamePlayers then
            local playerModel = gamePlayers:FindFirstChild(player.Name)
            if playerModel then
                local hum = playerModel:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = 0 end
            end
        end
    end
end)

BounceInput:OnChanged(function(Value)
    if BounceToggle.Value then
        local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
        if gamePlayers then
            local playerModel = gamePlayers:FindFirstChild(player.Name)
            if playerModel then
                local hum = playerModel:FindFirstChild("Humanoid")
                if hum then
                    local speedValue = tonumber(Value) or 110
                    hum.WalkSpeed = speedValue
                end
            end
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if BounceToggle.Value then
        task.wait(1)
        updateBounce()
    end
end)
MiscTab:AddSection("Revive Players")

local function createGradientButton(parent, position, size, text)
    local button = Instance.new("Frame")
    button.Name = "GradientBtn"
    button.BackgroundTransparency = 0.7
    button.Size = size
    button.Position = position
    button.Draggable = true
    button.Active = true
    button.Selectable = true
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    gradient.Rotation = 0
    gradient.Parent = button

    local gradientAnimation
    gradientAnimation = RunService.RenderStepped:Connect(function(delta)
        gradient.Rotation = (gradient.Rotation + 90 * delta) % 360
    end)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(139, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = button

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.Parent = button

    local clicker = Instance.new("TextButton")
    clicker.Size = UDim2.new(1, 0, 1, 0)
    clicker.BackgroundTransparency = 1
    clicker.Text = ""
    clicker.ZIndex = 5
    clicker.Parent = button

    button.Destroying:Connect(function()
        if gradientAnimation then gradientAnimation:Disconnect() end
    end)

    local activeTouchId = nil
    local startPos = nil
    local startButtonPos = nil

    local function updateButtonPosition(touchPos)
        if not startPos or not startButtonPos then return end
        local delta = touchPos - startPos
        button.Position = UDim2.new(startButtonPos.X.Scale, startButtonPos.X.Offset + delta.X,
                                    startButtonPos.Y.Scale, startButtonPos.Y.Offset + delta.Y)
    end

    local function resetDrag()
        activeTouchId = nil
        startPos = nil
        startButtonPos = nil
        stroke.Color = Color3.fromRGB(139, 0, 0)
    end

    clicker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if activeTouchId ~= nil then return end
            activeTouchId = input.UserInputState
            startPos = input.Position
            startButtonPos = button.Position
            stroke.Color = Color3.fromRGB(255, 0, 0)
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resetDrag()
                    connection:Disconnect()
                end
            end)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            if activeTouchId ~= nil then return end
            activeTouchId = "mouse"
            startPos = input.Position
            startButtonPos = button.Position
            stroke.Color = Color3.fromRGB(255, 0, 0)
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resetDrag()
                    connection:Disconnect()
                end
            end)
        end
    end)

    clicker.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if activeTouchId ~= nil then updateButtonPosition(input.Position) end
        elseif input.UserInputType == Enum.UserInputType.MouseMovement then
            if activeTouchId ~= nil then updateButtonPosition(input.Position) end
        end
    end)

    return button, clicker, stroke
end

local InstantReviveToggle = MiscTab:AddToggle("InstantReviveToggle", {
    Title = "Instant Revive",
    Default = false
})

local ReviveWhileEmoteToggle = MiscTab:AddToggle("ReviveWhileEmoteToggle", {
    Title = "Instant Revive While Emoting",
    Default = false
})

local ReviveDelaySlider = MiscTab:AddSlider("ReviveDelaySlider", {
    Title = "Revive Delay",
    Min = 0,
    Max = 1,
    Default = 0.15,
    Rounding = 2,
    Callback = function(value) getgenv().InstantReviveDelay = value end
})
getgenv().InstantReviveDelay = 0.15

local InstantReviveModule = (function()
    local reviveRange = 10
    local loopDelay = getgenv().InstantReviveDelay or 0.15
    local enabled = false
    local handle = nil
    local stateConnection = nil
    local charAddedConn = nil
    local isCurrentlyEmoting = false

    local interactEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")

    local function updateEmoteStatus()
        if not LocalPlayer.Character then
            isCurrentlyEmoting = false
            return
        end
        local state = LocalPlayer.Character:GetAttribute("State")
        isCurrentlyEmoting = state and string.find(state, "Emoting")
    end

    local function isPlayerDowned(pl)
        if not pl or not pl.Character then return false end
        local char = pl.Character
        if char:GetAttribute("Downed") then return true end
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then return true end
        return false
    end

    local function reviveLoop()
        while enabled do
            if isCurrentlyEmoting and ReviveWhileEmoteToggle and not ReviveWhileEmoteToggle.Value then
                task.wait(0.3)
                continue
            end

            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myHRP = myChar.HumanoidRootPart
                for _, pl in Players:GetPlayers() do
                    if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                        if isPlayerDowned(pl) then
                            local dist = (myHRP.Position - pl.Character.HumanoidRootPart.Position).Magnitude
                            if dist <= reviveRange then
                                pcall(function()
                                    interactEvent:FireServer("Revive", true, pl.Name)
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(loopDelay)
        end
    end

    local function start()
        if handle then return end
        enabled = true
        updateEmoteStatus()
        if LocalPlayer.Character then
            stateConnection = LocalPlayer.Character:GetAttributeChangedSignal("State"):Connect(updateEmoteStatus)
        end
        if charAddedConn then charAddedConn:Disconnect() end
        charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
            if stateConnection then stateConnection:Disconnect() end
            stateConnection = char:GetAttributeChangedSignal("State"):Connect(updateEmoteStatus)
            updateEmoteStatus()
        end)
        handle = task.spawn(reviveLoop)
    end

    local function stop()
        enabled = false
        if handle then task.cancel(handle) handle = nil end
        if stateConnection then stateConnection:Disconnect() stateConnection = nil end
        if charAddedConn then charAddedConn:Disconnect() charAddedConn = nil end
        isCurrentlyEmoting = false
    end

    return {
        Start = start,
        Stop = stop,
        SetDelay = function(d) loopDelay = d end,
    }
end)()

InstantReviveToggle:OnChanged(function(state)
    if state then
        InstantReviveModule.SetDelay(getgenv().InstantReviveDelay)
        InstantReviveModule.Start()
    else
        InstantReviveModule.Stop()
    end
end)

ReviveDelaySlider:OnChanged(function(value)
    getgenv().InstantReviveDelay = value
    InstantReviveModule.SetDelay(value)
end)

local instantReviveButtonScreenGui = nil
local instantReviveButton = nil
local instantReviveKeybindValue = "R"
local instantReviveButtonState = false

local function createInstantReviveButton()
    local CoreGui = game:GetService("CoreGui")
    if instantReviveButtonScreenGui then
        instantReviveButtonScreenGui:Destroy()
        instantReviveButtonScreenGui = nil
    end

    instantReviveButtonScreenGui = Instance.new("ScreenGui")
    instantReviveButtonScreenGui.Name = "InstantReviveButtonGUI"
    instantReviveButtonScreenGui.ResetOnSpawn = false
    instantReviveButtonScreenGui.Parent = CoreGui

    local buttonSize = 190
    local btnWidth = math.max(150, math.min(buttonSize, 400))
    local btnHeight = math.max(60, math.min(buttonSize * 0.4, 160))

    local btn, clicker, stroke = createGradientButton(
        instantReviveButtonScreenGui,
        UDim2.new(0.5, -btnWidth/2, 0.5, 0),
        UDim2.new(0, btnWidth, 0, btnHeight),
        instantReviveButtonState and "Instant Revive:On" or "Instant Revive:Off"
    )

    clicker.MouseButton1Click:Connect(function()
        instantReviveButtonState = not instantReviveButtonState
        if btn:FindFirstChild("TextLabel") then
            btn.TextLabel.Text = instantReviveButtonState and "Instant Revive:On" or "Instant Revive:Off"
        end
        if instantReviveButtonState then
            InstantReviveModule.SetDelay(getgenv().InstantReviveDelay)
            InstantReviveModule.Start()
        else
            InstantReviveModule.Stop()
        end
        if Options.InstantReviveToggle then
            Options.InstantReviveToggle:SetValue(instantReviveButtonState)
        end
    end)

    instantReviveButton = btn
    return instantReviveButtonScreenGui
end

local InstantReviveButtonToggle = MiscTab:AddToggle("InstantReviveButtonToggle", {
    Title = "Instant Revive Button GUI",
    Default = false,
    Callback = function(Value)
        if Value then
            createInstantReviveButton()
        else
            if instantReviveButtonScreenGui then
                instantReviveButtonScreenGui:Destroy()
                instantReviveButtonScreenGui = nil
            end
        end
    end
})

local InstantReviveKeybind = MiscTab:AddKeybind("InstantReviveKeybind", {
    Title = "Instant Revive Keybind",
    Mode = "Toggle",
    Default = "R",
    ChangedCallback = function(New) instantReviveKeybindValue = New end,
    Callback = function()
        instantReviveButtonState = not instantReviveButtonState
        if instantReviveButtonState then
            InstantReviveModule.SetDelay(getgenv().InstantReviveDelay)
            InstantReviveModule.Start()
        else
            InstantReviveModule.Stop()
        end
        if instantReviveButtonScreenGui and instantReviveButtonScreenGui:FindFirstChild("GradientBtn") then
            local button = instantReviveButtonScreenGui:FindFirstChild("GradientBtn")
            if button and button:FindFirstChild("TextLabel") then
                button.TextLabel.Text = instantReviveButtonState and "Instant Revive:On" or "Instant Revive:Off"
            end
        end
        if Options.InstantReviveToggle then
            Options.InstantReviveToggle:SetValue(instantReviveButtonState)
        end
    end
})

local InstantReviveButtonSizeInput = MiscTab:AddInput("InstantReviveButtonSizeInput", {
    Title = "Instant Revive Button Scale",
    Default = "1.0",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        if Value and tonumber(Value) then
            local scale = tonumber(Value)
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("InstantReviveButtonGUI")
            if existingScreenGui then
                local button = existingScreenGui:FindFirstChild("GradientBtn")
                if button then
                    local uiScale = button:FindFirstChild("UIScale") or Instance.new("UIScale")
                    uiScale.Scale = math.max(0.5, math.min(scale, 3.0))
                    uiScale.Parent = button
                end
            end
        end
    end
})

InstantReviveToggle:OnChanged(function(Value)
    instantReviveButtonState = Value
    if instantReviveButtonScreenGui and instantReviveButtonScreenGui:FindFirstChild("GradientBtn") then
        local button = instantReviveButtonScreenGui:FindFirstChild("GradientBtn")
        if button and button:FindFirstChild("TextLabel") then
            button.TextLabel.Text = instantReviveButtonState and "Instant Revive: On" or "Instant Revive: Off"
        end
    end
end)

InstantReviveButtonToggle:OnChanged(function(Value)
    if Value then
        createInstantReviveButton()
    else
        if instantReviveButtonScreenGui then
            instantReviveButtonScreenGui:Destroy()
            instantReviveButtonScreenGui = nil
        end
    end
end)

MiscTab:AddSection("Carry Players")

local AutoCarryToggle = MiscTab:AddToggle("AutoCarryToggle", { Title = "Auto Carry", Default = false })
local CarryGUIToggle = MiscTab:AddToggle("CarryGUIToggle", { Title = "Carry GUI Button", Default = false })

local CarryButtonSizeInput = MiscTab:AddInput("CarryButtonSizeInput", {
    Title = "Carry Button Size",
    Default = "190",
    Placeholder = "Enter size (150-400)",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        if Value and tonumber(Value) then
            local size = tonumber(Value)
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("AutoCarryButtonGUI")
            if existingScreenGui then
                local button = existingScreenGui:FindFirstChild("GradientBtn")
                if button then
                    local newWidth = math.max(150, math.min(size, 400))
                    local newHeight = math.max(60, math.min(size * 0.4, 160))
                    button.Size = UDim2.new(0, newWidth, 0, newHeight)
                end
            end
        end
    end
})

local CarryKeybind = MiscTab:AddKeybind("CarryKeybind", {
    Title = "Auto Carry Keybind",
    Mode = "Toggle",
    Default = "F3",
    ChangedCallback = function(New)
        Options.AutoCarryToggle:SetValue(not Options.AutoCarryToggle.Value)
    end
})

local AutoCarryConnection = nil

local function startAutoCarry()
    if AutoCarryConnection then return end
    AutoCarryConnection = RunService.Heartbeat:Connect(function()
        if not featureStates.AutoCarry then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (hrp.Position - other.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= 20 then
                        local args = { "Carry", [3] = other.Name }
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer(unpack(args))
                        end)
                        task.wait(0.01)
                    end
                end
            end
        end
    end)
end

local function stopAutoCarry()
    if AutoCarryConnection then
        AutoCarryConnection:Disconnect()
        AutoCarryConnection = nil
    end
end

local function toggleAutoCarryGUI()
    local CoreGui = game:GetService("CoreGui")
    local existingScreenGui = CoreGui:FindFirstChild("AutoCarryButtonGUI")

    if existingScreenGui then
        existingScreenGui:Destroy()
    else
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AutoCarryButtonGUI"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = CoreGui

        local buttonSize = 190
        if CarryButtonSizeInput and tonumber(CarryButtonSizeInput.Value) then
            buttonSize = tonumber(CarryButtonSizeInput.Value)
        end

        local btnWidth = math.max(150, math.min(buttonSize, 400))
        local btnHeight = math.max(60, math.min(buttonSize * 0.4, 160))

        local btn, clicker, stroke = createGradientButton(
            screenGui,
            UDim2.new(0.5, -btnWidth/2, 0.5, -btnHeight/2),
            UDim2.new(0, btnWidth, 0, btnHeight),
            "Auto Carry: Off"
        )

        local function updateButtonText()
            if btn and btn:FindFirstChild("TextLabel") then
                btn.TextLabel.Text = featureStates.AutoCarry and "Auto Carry: On" or "Auto Carry: Off"
            end
        end

        updateButtonText()

        clicker.MouseButton1Click:Connect(function()
            featureStates.AutoCarry = not featureStates.AutoCarry
            updateButtonText()
            if featureStates.AutoCarry then
                startAutoCarry()
            else
                stopAutoCarry()
            end
        end)

        AutoCarryToggle:OnChanged(function(state)
            featureStates.AutoCarry = state
            updateButtonText()
            if state then
                startAutoCarry()
            else
                stopAutoCarry()
            end
        end)
    end
end

AutoCarryToggle:OnChanged(function(state)
    featureStates.AutoCarry = state
    if state then
        startAutoCarry()
    else
        stopAutoCarry()
    end
end)

CarryGUIToggle:OnChanged(function(state)
    if state then
        toggleAutoCarryGUI()
    else
        local CoreGui = game:GetService("CoreGui")
        local existingScreenGui = CoreGui:FindFirstChild("AutoCarryButtonGUI")
        if existingScreenGui then existingScreenGui:Destroy() end
    end
end)

MiscTab:AddSection("Emote Speed")

local originalEmoteSpeeds = {}
local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
if itemsFolder then
    local emotesFolder = itemsFolder:FindFirstChild("Emotes")
    if emotesFolder then
        for _, emoteModule in ipairs(emotesFolder:GetChildren()) do
            if emoteModule:IsA("ModuleScript") then
                local success, emoteData = pcall(require, emoteModule)
                if success and emoteData and emoteData.EmoteInfo then
                    originalEmoteSpeeds[emoteModule.Name] = emoteData.EmoteInfo.SpeedMult
                end
            end
        end
    end
end

local function applyEmoteSpeed(speedValue)
    if not itemsFolder then return end
    local emotesFolder = itemsFolder:FindFirstChild("Emotes")
    if not emotesFolder then return end
    for _, emoteModule in ipairs(emotesFolder:GetChildren()) do
        if emoteModule:IsA("ModuleScript") then
            local success, emoteData = pcall(require, emoteModule)
            if success and emoteData and emoteData.EmoteInfo and emoteData.EmoteInfo.SpeedMult ~= 0 then
                emoteData.EmoteInfo.SpeedMult = speedValue
            end
        end
    end
end

local function restoreOriginalEmoteSpeeds()
    if not itemsFolder then return end
    local emotesFolder = itemsFolder:FindFirstChild("Emotes")
    if not emotesFolder then return end
    for _, emoteModule in ipairs(emotesFolder:GetChildren()) do
        if emoteModule:IsA("ModuleScript") then
            local originalSpeed = originalEmoteSpeeds[emoteModule.Name]
            if originalSpeed then
                local success, emoteData = pcall(require, emoteModule)
                if success and emoteData and emoteData.EmoteInfo then
                    emoteData.EmoteInfo.SpeedMult = originalSpeed
                end
            end
        end
    end
end

local function getMatchingTables()
    local matched = {}
    for _, obj in pairs(getgc(true)) do
        if typeof(obj) == "table" then
            local ok = true
            for field in pairs(requiredFields) do
                if rawget(obj, field) == nil then
                    ok = false
                    break
                end
            end
            if ok then table.insert(matched, obj) end
        end
    end
    return matched
end

local function applySpeedMultiplier(speedMultiplier)
    local targets = getMatchingTables()
    for _, tableObj in ipairs(targets) do
        if tableObj and typeof(tableObj) == "table" then
            pcall(function() tableObj.WalkSpeedMultiplier = speedMultiplier end)
        end
    end
end

local function getPlayerObj()
    local gamePlayers = workspace.Game and workspace.Game.Players
    if not gamePlayers then return nil end
    return gamePlayers:FindFirstChild(player.Name)
end

local playerObj = nil
local connection = nil
local emotingSpeed = 1.5

local function setupConnection(obj)
    if connection then connection:Disconnect() connection = nil end
    playerObj = obj
    if not obj then return end
    local function onStateChanged()
        local state = obj:GetAttribute("State")
        local targetSpeed = (state == "Emoting") and emotingSpeed or 1.5
        applySpeedMultiplier(targetSpeed)
    end
    onStateChanged()
    connection = obj:GetAttributeChangedSignal("State"):Connect(onStateChanged)
end

local function resetMultiplierSpeed()
    emotingSpeed = 1.5
    applySpeedMultiplier(1.5)
end

local EmoteSpeedModeDropdown = MiscTab:AddDropdown("EmoteSpeedModeDropdown", {
    Title = "Emote speed mode",
    Values = {"Nah", "Legit", "Multiplier speed"},
    Multi = false,
    Default = "Nah",
    Callback = function(Value)
        if Value == "Nah" then
            resetMultiplierSpeed()
            restoreOriginalEmoteSpeeds()
            if connection then connection:Disconnect() connection = nil end
        elseif Value == "Multiplier speed" then
            restoreOriginalEmoteSpeeds()
            setupConnection(getPlayerObj())
            task.spawn(function()
                while Options.EmoteSpeedModeDropdown and Options.EmoteSpeedModeDropdown.Value == "Multiplier speed" do
                    task.wait(2)
                    local current = getPlayerObj()
                    if current ~= playerObj then
                        setupConnection(current)
                    elseif playerObj then
                        local state = playerObj:GetAttribute("State")
                        local targetSpeed = (state == "Emoting") and emotingSpeed or 1.5
                        applySpeedMultiplier(targetSpeed)
                    end
                end
            end)
        elseif Value == "Legit" then
            resetMultiplierSpeed()
            if connection then connection:Disconnect() connection = nil end
            local speedValue = featureStates.EmoteSpeedValue or 2
            applyEmoteSpeed(speedValue)
        end
    end
})

local EmoteSpeedInput = MiscTab:AddInput("EmoteSpeedInput", {
    Title = "Emote Speed Value",
    Default = "1500",
    Placeholder = "Enter speed value",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            featureStates.EmoteSpeedValue = num
            local appliedValue = num / 1000
            if Options.EmoteSpeedModeDropdown and Options.EmoteSpeedModeDropdown.Value == "Legit" then
                applyEmoteSpeed(appliedValue)
            elseif Options.EmoteSpeedModeDropdown and Options.EmoteSpeedModeDropdown.Value == "Multiplier speed" then
                emotingSpeed = appliedValue
            end
        end
    end
})

local ApplyUnwalkableButton = MiscTab:AddButton({
    Title = "Apply Speed to Unwalkable Emotes",
    Callback = function()
        if not itemsFolder then return end
        local emotesFolder = itemsFolder:FindFirstChild("Emotes")
        if not emotesFolder then return end
        local speedValue = featureStates.EmoteSpeedValue or 2
        for _, emoteModule in ipairs(emotesFolder:GetChildren()) do
            if emoteModule:IsA("ModuleScript") then
                local success, emoteData = pcall(require, emoteModule)
                if success and emoteData and emoteData.EmoteInfo and emoteData.EmoteInfo.SpeedMult == 0 then
                    emoteData.EmoteInfo.SpeedMult = speedValue
                end
            end
        end
    end
})

local ResetEmoteSpeedButton = MiscTab:AddButton({
    Title = "Reset Emote Speed",
    Callback = function()
        Fluent:Notify({ Title = "Emote Speed", Content = "Resetting emote speeds...", Duration = 3 })
        restoreOriginalEmoteSpeeds()
        resetMultiplierSpeed()
    end
})

MiscTab:AddSection("Gun Functions")

local GrappleHookToggle = MiscTab:AddButton({
    Title = "Grapplehook",
    Callback = function()
        local success, result = pcall(function()
            local GrappleHook = require(ReplicatedStorage.Tools["GrappleHook"])
            local grappleTask = GrappleHook.Tasks[2]
            local shootMethod = grappleTask.Functions[1].Activations[1].Methods[1]
            shootMethod.Info.Speed = 10000
            shootMethod.Info.Lifetime = 10.0
            shootMethod.Info.Gravity = Vector3.new(0, 0, 0)
            shootMethod.Info.SpreadIncrease = 0
            shootMethod.Info.Cooldown = 0.1
            grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MaxSpread = 0
            grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MinSpread = 0
            grappleTask.MethodReferences.Projectile.Info.SpreadInfo.ReductionRate = 100
            local checkMethod = grappleTask.AutomaticFunctions[1].Methods[1]
            checkMethod.Info.Cooldown = 0.1
            checkMethod.CooldownInfo.TestCooldown = 0.1
            grappleTask.ResourceInfo.Cap = 999999
            GrappleHook.Adjustments.ToolViewbob = false
            GrappleHook.Actions.LookBack.Enabled = true
            GrappleHook.Actions.ADS.Enabled = true
            GrappleHook.Actions.ADS.Zoom = 0.5
            shootMethod.GlobalPriority = 500
            return true
        end)
        if success then
            Fluent:Notify({ Title = "GrappleHook", Content = "GrappleHook успешно улучшен!", Duration = 5 })
        else
            Fluent:Notify({ Title = "GrappleHook Error", Content = "Ошибка: " .. tostring(result), Duration = 5 })
        end
    end
})

local BreacherToggle = MiscTab:AddButton({
    Title = "Breacher (Portal Gun)",
    Callback = function()
        local success, result = pcall(function()
            local Breacher = require(ReplicatedStorage.Tools.Breacher)
            local portalTask
            for i, task in ipairs(Breacher.Tasks) do
                if task.ResourceInfo and task.ResourceInfo.Type == "Clip" then
                    portalTask = task
                    break
                end
            end
            if not portalTask then portalTask = Breacher.Tasks[2] end
            portalTask.ResourceInfo.Cap = 999999
            local blueShoot = portalTask.Functions[1].Activations[1].Methods[1]
            local yellowShoot = portalTask.Functions[2].Activations[1].Methods[1]
            blueShoot.Info.Range = 999999
            yellowShoot.Info.Range = 999999
            blueShoot.Info.SpreadIncrease = 0
            yellowShoot.Info.SpreadIncrease = 0
            portalTask.MethodReferences.Portal.Info.SpreadInfo.MaxSpread = 0
            portalTask.MethodReferences.Portal.Info.SpreadInfo.MinSpread = 0
            portalTask.MethodReferences.Portal.Info.SpreadInfo.ReductionRate = 100
            blueShoot.Info.Cooldown = 0.1
            yellowShoot.Info.Cooldown = 0.1
            blueShoot.CooldownInfo = {}
            yellowShoot.CooldownInfo = {}
            blueShoot.Requirements = {}
            yellowShoot.Requirements = {}
            Breacher.Actions.ADS.Enabled = false
            local unequipMethod = Breacher.Tasks[1].AutomaticFunctions[2].Methods[1]
            unequipMethod.CooldownInfo = {}
            if blueShoot.CooldownInfo and blueShoot.CooldownInfo.DisabledActions then
                local newDisabled = {}
                for _, action in ipairs(blueShoot.CooldownInfo.DisabledActions) do
                    if action ~= "ADS" then table.insert(newDisabled, action) end
                end
                blueShoot.CooldownInfo.DisabledActions = newDisabled
            end
            if yellowShoot.CooldownInfo and yellowShoot.CooldownInfo.DisabledActions then
                local newDisabled = {}
                for _, action in ipairs(yellowShoot.CooldownInfo.DisabledActions) do
                    if action ~= "ADS" then table.insert(newDisabled, action) end
                end
                yellowShoot.CooldownInfo.DisabledActions = newDisabled
            end
            blueShoot.GlobalPriority = 500
            yellowShoot.GlobalPriority = 500
            blueShoot.Priority = 1
            yellowShoot.Priority = 1
            blueShoot.ResourceAboveZero = false
            yellowShoot.ResourceAboveZero = false
            portalTask.Functions[1].Activations[1].CanHoldDown = true
            portalTask.Functions[2].Activations[1].CanHoldDown = true
            if not blueShoot.Info.Speed then
                blueShoot.Info.Speed = 5000
                yellowShoot.Info.Speed = 5000
            end
            local baseTask = Breacher.Tasks[1]
            baseTask.AutomaticFunctions[1].Methods[1].Info.Cooldown = 0.1
            baseTask.AutomaticFunctions[2].Methods[1].Info.Cooldown = 0.1
            Breacher.Actions.LookBack.Enabled = true
            Breacher.Adjustments.ToolViewbob = true
            Breacher.Adjustments.AnimationRootStraight = true
            Breacher.Adjustments.TurnWaist = true
            Breacher.HUD.CrosshairType = "Accurate"
            Breacher.HUD.Colored = true
            if Breacher.Actions.ADS.Zoom then Breacher.Actions.ADS.Zoom = nil end
            return true
        end)
        if success then
            Fluent:Notify({ Title = "Breacher (Portal Gun)", Content = "Portal Gun Successfully upgraded! \n✓ Infinite charges \n✓ Maximum range \n✓ Instant reload", Duration = 6 })
        else
            Fluent:Notify({ Title = "Breacher Error", Content = "Error: " .. tostring(result), Duration = 5 })
        end
    end
})

local SmokeGrenadeToggle = MiscTab:AddButton({
    Title = "Smoke Grenade",
    Callback = function()
        local success, result = pcall(function()
            local SmokeGrenade = require(ReplicatedStorage.Tools["SmokeGrenade"])
            SmokeGrenade.RequiresOwnedItem = false
            local throwMethod = SmokeGrenade.Tasks[1].Functions[1].Activations[1].Methods[1]
            throwMethod.ItemUseIncrement = {"SmokeGrenade", 0}
            throwMethod.Info.Cooldown = 0.1
            throwMethod.Info.ThrowVelocity = 200
            SmokeGrenade.Tasks[1].Functions[1].Activations[1].CanHoldDown = true
            throwMethod.Info.SmokeDuration = 999
            throwMethod.Info.SmokeRadius = 100
            throwMethod.Info.FadeTime = 60
            local equipMethod = SmokeGrenade.Tasks[1].AutomaticFunctions[1].Methods[1]
            local unequipMethod = SmokeGrenade.Tasks[1].AutomaticFunctions[2].Methods[1]
            equipMethod.Info.Cooldown = 0.1
            unequipMethod.Info.Cooldown = 0.1
            throwMethod.GlobalPriority = 500
            throwMethod.CooldownInfo = {}
            SmokeGrenade.HUD.ShowAmount = false
            throwMethod.Info.Density = 0.9
            throwMethod.Info.Color = Color3.new(0.7, 0.7, 0.7)
            throwMethod.Info.ExplosionRadius = 20
            throwMethod.CooldownInfo.ActivatePhrase = nil
            throwMethod.Info.Cooldown = 0.05
            SmokeGrenade.KeybindInfo.UnequipKeybind = "Backspace"
            local args = {[1] = 0, [2] = 20}
            ReplicatedStorage.Events.Character.ToolAction:FireServer(unpack(args))
            return true
        end)
        if success then
            Fluent:Notify({ Title = "Smoke Grenade", Content = "Smoke Grenade Improved! \n✓ Infinite Grenades \n✓ Instant Reload", Duration = 6 })
        else
            Fluent:Notify({ Title = "Smoke Grenade Error", Content = "Error: " .. tostring(result), Duration = 5 })
        end
    end
})

local StunBatonToggle = MiscTab:AddButton({
    Title = "Stun Baton",
    Callback = function()
        local success, result = pcall(function()
            local StunBaton = require(ReplicatedStorage.Tools.StunBaton)
            local task = StunBaton.Tasks[1]
            local meleeStart = task.Functions[1].Activations[2].Methods[1]
            meleeStart.Info.Cooldown = 0.05
            meleeStart.Info.LungeRange = 0
            meleeStart.Info.ImmortalLength = 5
            meleeStart.Info.SuccessStunLength = 5
            meleeStart.CooldownInfo = {}
            meleeStart.Requirements = {}
            local meleeStartFail = task.Functions[1].Activations[1].Methods[1]
            meleeStartFail.Info.Cooldown = 0.05
            meleeStartFail.Info.LungeRange = 0
            meleeStartFail.Info.ImmortalLength = 5
            meleeStartFail.CooldownInfo = {}
            local meleeEnd = task.AutomaticFunctions[2].Methods[1]
            meleeEnd.Info.Cooldown = 0.1
            meleeEnd.Info.Damage = 999
            meleeEnd.Info.Range = 0
            meleeEnd.CooldownInfo = {}
            local meleeEndFail = task.AutomaticFunctions[1].Methods[1]
            meleeEndFail.Info.Cooldown = 0.1
            meleeEndFail.Info.SelfDamage = 0
            meleeEndFail.Info.Range = 0
            meleeEndFail.CooldownInfo = {}
            local equip = task.AutomaticFunctions[3].Methods[1]
            local unequip = task.AutomaticFunctions[4].Methods[1]
            equip.Info.Cooldown = 0.1
            unequip.Info.Cooldown = 0.1
            unequip.CooldownInfo = {}
            StunBaton.Actions.ADS.Enabled = false
            StunBaton.Actions.LookBack.Enabled = true
            return true
        end)
        if success then
            Fluent:Notify({ Title = "Stun Baton", Content = "Stun Baton Successfully upgraded!\n✓ Instant attacks\n✓ 999 damage\n✓ No self damage\n✓ Long stun", Duration = 6 })
        else
            Fluent:Notify({ Title = "Stun Baton Error", Content = "Error: " .. tostring(result), Duration = 5 })
        end
    end
})

MiscTab:AddSection("Infinity Slide")

local infiniteSlideEnabled = false
local slideFrictionValue = -8
local movementTables = {}
local infiniteSlideHeartbeat = nil
local infiniteSlideCharacterConn = nil

local requiredKeys = {
    "Friction","AirStrafeAcceleration","JumpHeight","RunDeaccel",
    "JumpSpeedMultiplier","JumpCap","SprintCap","WalkSpeedMultiplier",
    "BhopEnabled","Speed","AirAcceleration","RunAccel","SprintAcceleration"
}

local function hasRequiredFields(tbl)
    if typeof(tbl) ~= "table" then return false end
    for _, key in ipairs(requiredKeys) do
        if rawget(tbl, key) == nil then return false end
    end
    return true
end

local function findMovementTables()
    movementTables = {}
    for _, obj in ipairs(getgc(true)) do
        if hasRequiredFields(obj) then table.insert(movementTables, obj) end
    end
    return #movementTables > 0
end

local function setSlideFriction(value)
    local appliedCount = 0
    for _, tbl in ipairs(movementTables) do
        pcall(function()
            tbl.Friction = value
            appliedCount = appliedCount + 1
        end)
    end
    if appliedCount == 0 then
        for _, obj in ipairs(getgc(true)) do
            if hasRequiredFields(obj) then
                pcall(function() obj.Friction = value end)
            end
        end
    end
end

local function updatePlayerModel()
    local gameFolder = workspace:FindFirstChild("Game")
    if not gameFolder then return false end
    local playersFolder = gameFolder:FindFirstChild("Players")
    if not playersFolder then return false end
    return playersFolder:FindFirstChild(player.Name)
end

local function infiniteSlideHeartbeatFunc()
    if not infiniteSlideEnabled then return end
    local playerModel = updatePlayerModel()
    if not playerModel then return end
    local state = playerModel:GetAttribute("State")
    if state == "Slide" then
        pcall(function() playerModel:SetAttribute("State", "EmotingSlide") end)
    elseif state == "EmotingSlide" then
        setSlideFriction(slideFrictionValue)
    else
        setSlideFriction(5)
    end
end

local function onCharacterAddedSlide(character)
    if not infiniteSlideEnabled then return end
    for i = 1, 5 do
        task.wait(0.5)
        if updatePlayerModel() then break end
    end
    task.wait(0.5)
    findMovementTables()
end

local function setInfiniteSlide(enabled)
    infiniteSlideEnabled = enabled
    if enabled then
        findMovementTables()
        updatePlayerModel()
        if not infiniteSlideCharacterConn then
            infiniteSlideCharacterConn = player.CharacterAdded:Connect(onCharacterAddedSlide)
        end
        if player.Character then
            task.spawn(function() onCharacterAddedSlide(player.Character) end)
        end
        if infiniteSlideHeartbeat then infiniteSlideHeartbeat:Disconnect() end
        infiniteSlideHeartbeat = RunService.Heartbeat:Connect(infiniteSlideHeartbeatFunc)
    else
        if infiniteSlideHeartbeat then
            infiniteSlideHeartbeat:Disconnect()
            infiniteSlideHeartbeat = nil
        end
        if infiniteSlideCharacterConn then
            infiniteSlideCharacterConn:Disconnect()
            infiniteSlideCharacterConn = nil
        end
        setSlideFriction(5)
        movementTables = {}
    end
end

local InfiniteSlideToggle = MiscTab:AddToggle("InfiniteSlideToggle", {
    Title = "Sprint Slide",
    Default = false,
    Callback = function(Value) setInfiniteSlide(Value) end
})

local SlideFrictionInput = MiscTab:AddInput("SlideFrictionInput", {
    Title = "Slide Speed (Negative only)",
    Default = "-8",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            slideFrictionValue = num
            if infiniteSlideEnabled then setSlideFriction(slideFrictionValue) end
        end
    end
})

local slideButtonScreenGui = nil

local function createSlideGradientButton()
    local CoreGui = game:GetService("CoreGui")
    if slideButtonScreenGui then
        slideButtonScreenGui:Destroy()
        slideButtonScreenGui = nil
    end
    slideButtonScreenGui = Instance.new("ScreenGui")
    slideButtonScreenGui.Name = "SlideButtonGUI"
    slideButtonScreenGui.ResetOnSpawn = false
    slideButtonScreenGui.Parent = CoreGui

    local buttonSize = 190
    local btnWidth = math.max(150, math.min(buttonSize, 400))
    local btnHeight = math.max(60, math.min(buttonSize * 0.4, 160))

    local btn, clicker, stroke = createGradientButton(
        slideButtonScreenGui,
        UDim2.new(0.5, -btnWidth/2, 0.5, 0),
        UDim2.new(0, btnWidth, 0, btnHeight),
        infiniteSlideEnabled and "Sprint Slide: On" or "Sprint Slide: Off"
    )

    if SlideButtonScaleInput and SlideButtonScaleInput.Value then
        local scaleValue = tonumber(SlideButtonScaleInput.Value) or 1.0
        local uiScale = Instance.new("UIScale")
        uiScale.Scale = math.max(0.5, math.min(scaleValue, 3.0))
        uiScale.Parent = btn
    end

    clicker.MouseButton1Click:Connect(function()
        infiniteSlideEnabled = not infiniteSlideEnabled
        setInfiniteSlide(infiniteSlideEnabled)
        if btn:FindFirstChild("TextLabel") then
            btn.TextLabel.Text = infiniteSlideEnabled and "Sprint Slide: On" or "Sprint Slide: Off"
        end
        if Options.InfiniteSlideToggle then
            Options.InfiniteSlideToggle:SetValue(infiniteSlideEnabled)
        end
    end)
    return slideButtonScreenGui
end

local function updateSlideButtonText()
    if slideButtonScreenGui and slideButtonScreenGui:FindFirstChild("GradientBtn") then
        local button = slideButtonScreenGui:FindFirstChild("GradientBtn")
        if button and button:FindFirstChild("TextLabel") then
            button.TextLabel.Text = infiniteSlideEnabled and "Sprint Slide: On" or "Sprint Slide: Off"
        end
    end
end

local SlideButtonToggle = MiscTab:AddToggle("SlideButtonToggle", {
    Title = "Sprint Slide Button GUI",
    Default = false,
    Callback = function(Value)
        if Value then
            createSlideGradientButton()
        else
            if slideButtonScreenGui then
                slideButtonScreenGui:Destroy()
                slideButtonScreenGui = nil
            end
        end
    end
})

local SlideButtonScaleInput = MiscTab:AddInput("SlideButtonScaleInput", {
    Title = "Sprint Slide Button Scale",
    Default = "1.0",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        if Value and tonumber(Value) then
            local scale = tonumber(Value)
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("SlideButtonGUI")
            if existingScreenGui then
                local button = existingScreenGui:FindFirstChild("GradientBtn")
                if button then
                    local uiScale = button:FindFirstChild("UIScale") or Instance.new("UIScale")
                    uiScale.Scale = math.max(0.5, math.min(scale, 3.0))
                    uiScale.Parent = button
                    Fluent:Notify({ Title = "Sprint Slide Button", Content = string.format("Button scale set to %.1f", scale), Duration = 3 })
                end
            end
        end
    end
})

local SlideKeybind = MiscTab:AddKeybind("SlideKeybind", {
    Title = "Sprint Slide Keybind",
    Mode = "Toggle",
    Default = "X",
    ChangedCallback = function(New) end,
    Callback = function()
        infiniteSlideEnabled = not infiniteSlideEnabled
        setInfiniteSlide(infiniteSlideEnabled)
        if Options.InfiniteSlideToggle then
            Options.InfiniteSlideToggle:SetValue(infiniteSlideEnabled)
        end
        updateSlideButtonText()
    end
})

MiscTab:AddSection("Gravity")

local gravityEnabled = false
local originalGravity = workspace.Gravity
local gravityValue = 10
local gravityHeartbeat = nil
local gravityKeybindValue = "G"

local function createGravityButton()
    local CoreGui = game:GetService("CoreGui")
    local existingScreenGui = CoreGui:FindFirstChild("GravityButtonGUI")
    if existingScreenGui then
        existingScreenGui:Destroy()
    else
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "GravityButtonGUI"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = CoreGui

        local buttonSize = 190
        local btnWidth = math.max(150, math.min(buttonSize, 400))
        local btnHeight = math.max(60, math.min(buttonSize * 0.4, 160))

        local btn, clicker, stroke = createGradientButton(
            screenGui,
            UDim2.new(0.5, -btnWidth/2, 0.5, 60),
            UDim2.new(0, btnWidth, 0, btnHeight),
            gravityEnabled and "Gravity: On" or "Gravity: Off"
        )

        clicker.MouseButton1Click:Connect(function()
            gravityEnabled = not gravityEnabled
            if btn:FindFirstChild("TextLabel") then
                btn.TextLabel.Text = gravityEnabled and "Gravity: On" or "Gravity: Off"
            end
            if gravityEnabled then
                workspace.Gravity = gravityValue
            else
                workspace.Gravity = originalGravity
            end
        end)
    end
end

local GravityToggle = MiscTab:AddToggle("GravityToggle", {
    Title = "Gravity",
    Default = false,
    Callback = function(Value)
        gravityEnabled = Value
        if Value then
            workspace.Gravity = gravityValue
        else
            workspace.Gravity = originalGravity
        end
    end
})

local GravityButtonToggle = MiscTab:AddToggle("GravityButtonToggle", {
    Title = "Gravity Button GUI",
    Default = false,
    Callback = function(Value)
        if Value then
            createGravityButton()
        else
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("GravityButtonGUI")
            if existingScreenGui then existingScreenGui:Destroy() end
        end
    end
})

local GravityKeybind = MiscTab:AddKeybind("GravityKeybind", {
    Title = "Gravity Keybind",
    Mode = "Toggle",
    Default = "G",
    ChangedCallback = function(New) gravityKeybindValue = New end,
    Callback = function()
        if GravityToggle then
            GravityToggle:SetValue(not GravityToggle.Value)
        end
    end
})

local GravityAdjustmentInput = MiscTab:AddInput("GravityAdjustmentInput", {
    Title = "Gravity Adjustment",
    Default = "10",
    Placeholder = "Enter gravity value",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            gravityValue = num
            if gravityEnabled then workspace.Gravity = gravityValue end
        end
    end
})

originalGravity = workspace.Gravity

GravityToggle:OnChanged(function(state)
    if Options.GravityButtonToggle and Options.GravityButtonToggle.Value then
        local CoreGui = game:GetService("CoreGui")
        local screenGui = CoreGui:FindFirstChild("GravityButtonGUI")
        if screenGui then
            local button = screenGui:FindFirstChild("GradientBtn")
            if button and button:FindFirstChild("TextLabel") then
                button.TextLabel.Text = state and "Gravity: On" or "Gravity: Off"
            end
        end
    end
end)

local GravityButtonSizeInput = MiscTab:AddInput("GravityButtonSizeInput", {
    Title = "Gravity Button Size",
    Default = "1",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        if Value and tonumber(Value) then
            local scale = tonumber(Value)
            scale = math.max(0.5, math.min(scale, 3.0))
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("GravityButtonGUI")
            if existingScreenGui then
                local button = existingScreenGui:FindFirstChild("GradientBtn")
                if button then
                    local uiScale = button:FindFirstChild("UIScale") or Instance.new("UIScale")
                    uiScale.Scale = scale
                    uiScale.Parent = button
                end
            end
        end
    end
})
MiscTab:AddSection("Auto Jump")

getgenv().autoJumpType = "Bounce"
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.5
getgenv().bhopHoldActive = false
getgenv().autoJumpEnabled = false
getgenv().jumpCooldown = 0.7
getgenv().rotationEnabled = false

featureStates.Bhop = false
featureStates.BhopHold = false

local bhopConnection = nil
local bhopLoaded = false
local characterConnection = nil
local frictionTables = {}
local Character = nil
local Humanoid = nil
local HumanoidRootPart = nil
local LastJump = 0
local GROUND_CHECK_OFFSET = 3.5
local GROUND_CHECK_RAY_LENGTH = 4
local MAX_SLOPE_ANGLE = 45
local bhopButtonScreenGui = nil
local rotationConnection = nil
local rotationSpeed = 100000

local function startRotation()
    if rotationConnection then
        rotationConnection:Disconnect()
        rotationConnection = nil
    end
    if not getgenv().rotationEnabled or not HumanoidRootPart then return end
    rotationConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if HumanoidRootPart and HumanoidRootPart.Parent then
            local currentRotation = HumanoidRootPart.Orientation
            local newRotation = Vector3.new(
                currentRotation.X,
                currentRotation.Y + (rotationSpeed * deltaTime),
                currentRotation.Z
            )
            HumanoidRootPart.Orientation = newRotation
        else
            if rotationConnection then
                rotationConnection:Disconnect()
                rotationConnection = nil
            end
        end
    end)
end

local function stopRotation()
    if rotationConnection then
        rotationConnection:Disconnect()
        rotationConnection = nil
    end
end

local function updateRotationState()
    if getgenv().rotationEnabled and getgenv().autoJumpEnabled then
        startRotation()
    else
        stopRotation()
    end
end

local function createBhopGradientButton()
    local CoreGui = game:GetService("CoreGui")
    if bhopButtonScreenGui then
        bhopButtonScreenGui:Destroy()
        bhopButtonScreenGui = nil
    end
    bhopButtonScreenGui = Instance.new("ScreenGui")
    bhopButtonScreenGui.Name = "BhopButtonGUI"
    bhopButtonScreenGui.ResetOnSpawn = false
    bhopButtonScreenGui.Parent = CoreGui

    local buttonSize = 190
    local btnWidth = math.max(150, math.min(buttonSize, 400))
    local btnHeight = math.max(60, math.min(buttonSize * 0.4, 160))

    local btn, clicker, stroke = createGradientButton(
        bhopButtonScreenGui,
        UDim2.new(0.5, -btnWidth/2, 0.5, 120),
        UDim2.new(0, btnWidth, 0, btnHeight),
        getgenv().autoJumpEnabled and "Auto Jump: On" or "Auto Jump: Off"
    )

    clicker.MouseButton1Click:Connect(function()
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        featureStates.Bhop = getgenv().autoJumpEnabled
        if btn:FindFirstChild("TextLabel") then
            btn.TextLabel.Text = getgenv().autoJumpEnabled and "Auto Jump: On" or "Auto Jump: Off"
        end
        if Options.BhopToggle then
            Options.BhopToggle:SetValue(getgenv().autoJumpEnabled)
        end
        checkBhopState()
    end)
    return bhopButtonScreenGui
end

local function updateBhopButtonText()
    if bhopButtonScreenGui and bhopButtonScreenGui:FindFirstChild("GradientBtn") then
        local button = bhopButtonScreenGui:FindFirstChild("GradientBtn")
        if button and button:FindFirstChild("TextLabel") then
            button.TextLabel.Text = getgenv().autoJumpEnabled and "Auto Jump: On" or "Auto Jump: Off"
        end
    end
end

local function IsOnGround()
    if not Character or not HumanoidRootPart or not Humanoid then return false end
    local state = Humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping or
       state == Enum.HumanoidStateType.Freefall or
       state == Enum.HumanoidStateType.Swimming then
        return false
    end
    if Humanoid:GetState() == Enum.HumanoidStateType.Running then return true end
    local rayOrigin = HumanoidRootPart.Position
    local rayDirection = Vector3.new(0, -GROUND_CHECK_RAY_LENGTH, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.IgnoreWater = true
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if raycastResult then
        local surfaceNormal = raycastResult.Normal
        local angle = math.deg(math.acos(surfaceNormal:Dot(Vector3.new(0, 1, 0))))
        if angle <= MAX_SLOPE_ANGLE then
            local heightDiff = math.abs(rayOrigin.Y - raycastResult.Position.Y)
            return heightDiff <= GROUND_CHECK_OFFSET
        end
    end
    if HumanoidRootPart.Velocity.Y > -1 and HumanoidRootPart.Velocity.Y < 1 then return true end
    return false
end

local function findFrictionTables()
    frictionTables = {}
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and rawget(obj, "Friction") then
            table.insert(frictionTables, { obj = obj, original = obj.Friction })
        end
    end
end

local function applyBhopFriction()
    local isActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if isActive and getgenv().bhopMode == "Acceleration" then
        if #frictionTables == 0 then findFrictionTables() end
        for _, tableData in ipairs(frictionTables) do
            if tableData.obj and type(tableData.obj) == "table" then
                pcall(function() tableData.obj.Friction = getgenv().bhopAccelValue or -0.5 end)
            end
        end
    else
        for _, tableData in ipairs(frictionTables) do
            if tableData.obj and type(tableData.obj) == "table" and tableData.original then
                pcall(function() tableData.obj.Friction = tableData.original end)
            end
        end
    end
end

local function updateBhop()
    if not bhopLoaded then return end
    local isActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if isActive then
        if not Character or not Humanoid or not HumanoidRootPart then
            Character = player.Character
            if Character then
                Humanoid = Character:FindFirstChildOfClass("Humanoid")
                HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            end
            if not Humanoid or not HumanoidRootPart then return end
        end
        if Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
        local now = tick()
        if getgenv().autoJumpType == "Realistic" then
            pcall(function()
                player.PlayerScripts.Events.temporary_events.JumpReact:Fire()
                player.PlayerScripts.Events.temporary_events.EndJump:Fire()
            end)
        else
            if IsOnGround() and (now - LastJump) > 0.25 then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                LastJump = now
            end
        end
    end
end

local function loadBhop()
    if bhopLoaded then return end
    bhopLoaded = true
    findFrictionTables()
    applyBhopFriction()
    if bhopConnection then bhopConnection:Disconnect() end
    bhopConnection = RunService.Heartbeat:Connect(function(deltaTime) updateBhop() end)
end

local function unloadBhop()
    if not bhopLoaded then return end
    bhopLoaded = false
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    getgenv().bhopHoldActive = false
    applyBhopFriction()
end

function checkBhopState()
    local shouldLoad = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if shouldLoad then
        loadBhop()
        updateRotationState()
    else
        unloadBhop()
        stopRotation()
    end
end

local function reapplyBhopOnRespawn()
    if getgenv().autoJumpEnabled or getgenv().bhopHoldActive then
        task.wait(1)
        Character = player.Character
        if Character then
            Humanoid = Character:FindFirstChildOfClass("Humanoid")
            HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        end
        checkBhopState()
    end
end

local function setupJumpButton()
    local isMobile = UserInputService.TouchEnabled
    if isMobile then
        task.spawn(function()
            task.wait(2)
            local success, err = pcall(function()
                local touchGui = player:WaitForChild("PlayerGui"):WaitForChild("TouchGui")
                if not touchGui then return end
                local touchControlFrame = touchGui:WaitForChild("TouchControlFrame")
                if not touchControlFrame then return end
                local jumpButton = touchControlFrame:WaitForChild("JumpButton")
                if not jumpButton then return end
                jumpButton.MouseButton1Down:Connect(function()
                    if featureStates.BhopHold then
                        getgenv().bhopHoldActive = true
                        checkBhopState()
                    end
                end)
                jumpButton.MouseButton1Up:Connect(function()
                    getgenv().bhopHoldActive = false
                    checkBhopState()
                end)
            end)
            if not success then end
        end)
    end
end

local AutoJumpTypeDropdown = MiscTab:AddDropdown("AutoJumpTypeDropdown", {
    Title = "Auto Jump Type",
    Values = {"Bounce", "Realistic"},
    Multi = false,
    Default = "Bounce",
    Callback = function(Value) getgenv().autoJumpType = Value end
})

local RotationToggle = MiscTab:AddToggle("RotationToggle", {
    Title = "Rotation 360",
    Description = "Do not use with emotions!",
    Default = false,
    Callback = function(Value)
        getgenv().rotationEnabled = Value
        updateRotationState()
    end
})

local BhopToggle = MiscTab:AddToggle("BhopToggle", {
    Title = "Bunny Hop",
    Default = false,
    Callback = function(Value)
        featureStates.Bhop = Value
        getgenv().autoJumpEnabled = Value
        updateBhopButtonText()
        updateRotationState()
        checkBhopState()
    end
})

local BhopHoldToggle = MiscTab:AddToggle("BhopHoldToggle", {
    Title = "Bhop Hold (Hold Space/Jump)",
    Default = false,
    Callback = function(Value)
        featureStates.BhopHold = Value
        if not Value then
            getgenv().bhopHoldActive = false
            checkBhopState()
        end
    end
})

local BhopButtonToggle = MiscTab:AddToggle("BhopButtonToggle", {
    Title = "Bhop Button GUI",
    Default = false,
    Callback = function(Value)
        if Value then
            createBhopGradientButton()
        else
            if bhopButtonScreenGui then
                bhopButtonScreenGui:Destroy()
                bhopButtonScreenGui = nil
            end
        end
    end
})

local BhopKeybind = MiscTab:AddKeybind("BhopKeybind", {
    Title = "Bhop Keybind",
    Mode = "Toggle",
    Default = "B",
    ChangedCallback = function(New) end,
    Callback = function()
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        featureStates.Bhop = getgenv().autoJumpEnabled
        if Options.BhopToggle then
            Options.BhopToggle:SetValue(getgenv().autoJumpEnabled)
        end
        updateBhopButtonText()
        checkBhopState()
    end
})

local BhopModeDropdown = MiscTab:AddDropdown("BhopModeDropdown", {
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Multi = false,
    Default = "Acceleration",
    Callback = function(Value)
        getgenv().bhopMode = Value
        checkBhopState()
    end
})

local BhopAccelInput = MiscTab:AddInput("BhopAccelInput", {
    Title = "Bhop Acceleration",
    Default = "-0.5",
    Placeholder = "Enter negative value (e.g., -0.5)",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and string.sub(Value, 1, 1) == "-" then
            getgenv().bhopAccelValue = num
            if getgenv().autoJumpEnabled or getgenv().bhopHoldActive then
                applyBhopFriction()
            end
        end
    end
})

local JumpCooldownInput = MiscTab:AddInput("JumpCooldownInput", {
    Title = "Jump Cooldown (Seconds)",
    Default = "0.7",
    Placeholder = "Enter cooldown in seconds",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then getgenv().jumpCooldown = num end
    end
})

RunService.Heartbeat:Connect(function()
    if not Character or not Character:IsDescendantOf(workspace) then
        Character = player.Character
        if Character then
            Humanoid = Character:FindFirstChildOfClass("Humanoid")
            HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            updateRotationState()
        else
            Humanoid = nil
            HumanoidRootPart = nil
            stopRotation()
        end
    end
end)

if characterConnection then characterConnection:Disconnect() end

characterConnection = player.CharacterAdded:Connect(function(character)
    Character = character
    task.wait(0.5)
    Humanoid = character:WaitForChild("Humanoid")
    HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    setupJumpButton()
    reapplyBhopOnRespawn()
    updateRotationState()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
        checkBhopState()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
        checkBhopState()
    end
end)

task.spawn(function()
    task.wait(2)
    if player.Character then
        Character = player.Character
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    end
    setupJumpButton()
    if featureStates.Bhop then checkBhopState() end
    task.wait(1)
    if Options.BhopButtonToggle and Options.BhopButtonToggle.Value then
        createBhopGradientButton()
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        unloadBhop()
        stopRotation()
        if characterConnection then
            characterConnection:Disconnect()
            characterConnection = nil
        end
    end
end)

MiscTab:AddSection("Lag Switch")

local lagSwitchEnabled = false
local lagSwitchKeybindValue = "F12"
local lagDelayValue = 0.1
local lagIntensity = 1000000
local lagSwitchMode = "Normal"
local isLagActive = false

local DemonRiseHeightInput
local DemonRiseSpeedInput

local function performMathLag()
    local startTime = tick()
    local duration = lagDelayValue
    while tick() - startTime < duration do
        for i = 1, lagIntensity do
            local a = math.random(1, 1000000) * math.random(1, 1000000)
            a = a / math.random(1, 10000)
            local b = math.sqrt(math.random(1, 1000000))
            b = b * math.pi * math.exp(1)
            local c = math.sin(math.rad(math.random(1, 360))) * math.cos(math.rad(math.random(1, 360)))
        end
    end
end

local function performDemonLag()
    local startTime = tick()
    local duration = lagDelayValue
    local currentHeightInput = DemonRiseHeightInput and DemonRiseHeightInput.Value or "100"
    local currentSpeedInput = DemonRiseSpeedInput and DemonRiseSpeedInput.Value or "80"
    local RISE_HEIGHT = tonumber(currentHeightInput) or 10
    local BOOST_SPEED = tonumber(currentSpeedInput) or 80

    task.spawn(function()
        local startLagTime = tick()
        while tick() - startLagTime < duration do
            for i = 1, math.floor(lagIntensity / 2) do
                local a = math.random(1, 1000000) * math.random(1, 1000000)
                a = a / math.random(1, 10000)
                local b = math.sqrt(math.random(1, 1000000))
                b = b * math.pi * math.exp(1)
            end
        end
    end)

    local char = player.Character
    if char then
        local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if humanoidRootPart and hum then
            local startHeight = humanoidRootPart.Position.Y
            local bodyThrust = Instance.new("BodyThrust")
            bodyThrust.Name = "DemonRiseThrust"
            bodyThrust.Force = Vector3.new(0, BOOST_SPEED * 500, 0)
            bodyThrust.Location = Vector3.new(0, 0, 0)
            bodyThrust.Parent = humanoidRootPart
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "DemonRiseVelocity"
            bodyVelocity.MaxForce = Vector3.new(0, 500000, 0)
            bodyVelocity.Velocity = Vector3.new(0, BOOST_SPEED, 0)
            bodyVelocity.Parent = humanoidRootPart
            local waitTime = 0
            local maxWaitTime = 5
            while waitTime < maxWaitTime do
                local currentHeight = humanoidRootPart.Position.Y
                local heightGained = currentHeight - startHeight
                if heightGained >= RISE_HEIGHT then break end
                task.wait(0.1)
                waitTime = waitTime + 0.1
            end
            if bodyThrust then bodyThrust:Destroy() end
            if bodyVelocity then bodyVelocity:Destroy() end
            local finalHeight = humanoidRootPart.Position.Y
            local heightGained = finalHeight - startHeight
            Fluent:Notify({ Title = "Demon Mode", Content = string.format("Lifted %.1f meters", heightGained), Duration = 3 })
        end
    end
    isLagActive = false
end

local function toggleLagSwitch()
    if not isLagActive then
        isLagActive = true
        if lagSwitchMode == "Normal" then
            task.spawn(function()
                performMathLag()
                isLagActive = false
            end)
        elseif lagSwitchMode == "Demon" then
            task.spawn(function()
                performDemonLag()
                isLagActive = false
            end)
        end
    end
end

getgenv().DemonRiseHeight = 10
getgenv().DemonRiseSpeed = 80
getgenv().DemonSoftLanding = true

local function createLagSwitchButton()
    local CoreGui = game:GetService("CoreGui")
    local existingScreenGui = CoreGui:FindFirstChild("LagSwitchButtonGUI")
    if existingScreenGui then
        existingScreenGui:Destroy()
    else
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "LagSwitchButtonGUI"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = CoreGui

        local buttonSize = 190
        local btnWidth = math.max(150, math.min(buttonSize, 400))
        local btnHeight = math.max(60, math.min(buttonSize * 0.4, 160))

        local btn, clicker, stroke = createGradientButton(
            screenGui,
            UDim2.new(0.5, -btnWidth/2, 0.5, 1),
            UDim2.new(0, btnWidth, 0, btnHeight),
            "Lag Switch"
        )

        clicker.MouseButton1Click:Connect(function()
            if lagSwitchEnabled then toggleLagSwitch() end
        end)
    end
end

local LagSwitchToggle = MiscTab:AddToggle("LagSwitchToggle", {
    Title = "Lag Switch",
    Default = false,
    Callback = function(Value) lagSwitchEnabled = Value end
})

local LagSwitchModeDropdown = MiscTab:AddDropdown("LagSwitchModeDropdown", {
    Title = "Lag Switch Mode",
    Values = {"Normal", "Demon"},
    Multi = false,
    Default = "Normal",
    Callback = function(Value) lagSwitchMode = Value end
})

local LagDelayInput = MiscTab:AddInput("LagDelayInput", {
    Title = "Lag Delay (Seconds)",
    Default = "0.1",
    Placeholder = "Enter delay in seconds (0.1-5)",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 and num <= 5 then lagDelayValue = num end
    end
})

local LagIntensityInput = MiscTab:AddInput("LagIntensityInput", {
    Title = "Lag Intensity",
    Default = "1000000",
    Placeholder = "Enter intensity (1000-10000000)",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 1000 and num <= 10000000 then lagIntensity = num end
    end
})

DemonRiseHeightInput = MiscTab:AddInput("DemonRiseHeightInput", {
    Title = "Demon Rise Height (meters)",
    Default = "10",
    Placeholder = "Enter rise height in meters (10-500)",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 10 and num <= 500 then
            getgenv().DemonRiseHeight = num
            Fluent:Notify({ Title = "Demon Mode", Content = string.format("Rise height set to %d meters", num), Duration = 3 })
        else
            Fluent:Notify({ Title = "Demon Mode", Content = "Height must be between 10 and 500 meters", Duration = 3 })
        end
    end
})

DemonRiseSpeedInput = MiscTab:AddInput("DemonRiseSpeedInput", {
    Title = "Demon Rise Speed",
    Default = "80",
    Placeholder = "Enter rise speed (20-200)",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 20 and num <= 200 then
            getgenv().DemonRiseSpeed = num
            Fluent:Notify({ Title = "Demon Mode", Content = string.format("Rise speed set to %d", num), Duration = 3 })
        else
            Fluent:Notify({ Title = "Demon Mode", Content = "Speed must be between 20 and 200", Duration = 3 })
        end
    end
})

local LagSwitchButtonToggle = MiscTab:AddToggle("LagSwitchButtonToggle", {
    Title = "Lag Switch Button",
    Default = false,
    Callback = function(Value)
        if Value then
            createLagSwitchButton()
        else
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("LagSwitchButtonGUI")
            if existingScreenGui then existingScreenGui:Destroy() end
        end
    end
})

local LagSwitchKeybind = MiscTab:AddKeybind("LagSwitchKeybind", {
    Title = "Lag Switch Keybind",
    Mode = "Toggle",
    Default = "F12",
    ChangedCallback = function(New)
        lagSwitchKeybindValue = New
        local CoreGui = game:GetService("CoreGui")
        local screenGui = CoreGui:FindFirstChild("LagSwitchButtonGUI")
        if screenGui then
            local button = screenGui:FindFirstChild("GradientBtn")
            if button and button:FindFirstChild("TextLabel") then
                button.TextLabel.Text = "Lag Switch"
            end
        end
    end,
    Callback = function()
        if lagSwitchEnabled then toggleLagSwitch() end
    end
})

LagSwitchKeybind:OnChanged(function()
    if Options.LagSwitchButtonToggle and Options.LagSwitchButtonToggle.Value then
        local CoreGui = game:GetService("CoreGui")
        local screenGui = CoreGui:FindFirstChild("LagSwitchButtonGUI")
        if screenGui then
            local button = screenGui:FindFirstChild("GradientBtn")
            if button and button:FindFirstChild("TextLabel") then
                button.TextLabel.Text = "Lag Switch"
            end
        end
    end
end)

local LagSwitchScaleInput = MiscTab:AddInput("LagSwitchScaleInput", {
    Title = "Lag Switch Button Scale",
    Default = "1.0",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        if Value and tonumber(Value) then
            local scale = tonumber(Value)
            local CoreGui = game:GetService("CoreGui")
            local existingScreenGui = CoreGui:FindFirstChild("LagSwitchButtonGUI")
            if existingScreenGui then
                local button = existingScreenGui:FindFirstChild("GradientBtn")
                if button then
                    local uiScale = button:FindFirstChild("UIScale") or Instance.new("UIScale")
                    uiScale.Scale = math.max(0.5, math.min(scale, 3.0))
                    uiScale.Parent = button
                end
            end
        end
    end
})

task.spawn(function()
    task.wait(1)
    if DemonRiseHeightInput then DemonRiseHeightInput:SetValue("100") end
    if DemonRiseSpeedInput then DemonRiseSpeedInput:SetValue("80") end
end)

MiscTab:AddParagraph({
    Title = "Demon Mode Features",
    Content = "Demon mode combines lag switch with character elevation. Default height: 100 meters. You can adjust height and speed settings."
})

MiscTab:AddSection("Camera Adjustments")

local cameraStretchConnection = nil
local stretchHorizontal = 0.80
local stretchVertical = 0.80

local function setupCameraStretch()
    if cameraStretchConnection then
        cameraStretchConnection:Disconnect()
        cameraStretchConnection = nil
    end
    cameraStretchConnection = RunService.RenderStepped:Connect(function()
        local Camera = workspace.CurrentCamera
        if Camera then
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
        end
    end)
end

local CameraStretchToggle = MiscTab:AddToggle("CameraStretchToggle", {
    Title = "Camera Stretch",
    Default = false,
    Callback = function(Value)
        if Value then
            setupCameraStretch()
        else
            if cameraStretchConnection then
                cameraStretchConnection:Disconnect()
                cameraStretchConnection = nil
            end
        end
    end
})

local CameraStretchHorizontalInput = MiscTab:AddInput("CameraStretchHorizontalInput", {
    Title = "Camera Stretch Horizontal",
    Default = "0.80",
    Placeholder = "Enter horizontal stretch value",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            stretchHorizontal = num
            if Options.CameraStretchToggle and Options.CameraStretchToggle.Value then setupCameraStretch() end
        end
    end
})

local CameraStretchVerticalInput = MiscTab:AddInput("CameraStretchVerticalInput", {
    Title = "Camera Stretch Vertical",
    Default = "0.80",
    Placeholder = "Enter vertical stretch value",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            stretchVertical = num
            if Options.CameraStretchToggle and Options.CameraStretchToggle.Value then setupCameraStretch() end
        end
    end
})

MiscTab:AddSection("Client Modification")

local FullBrightToggle = MiscTab:AddToggle("FullBrightToggle", {
    Title = "Full Bright",
    Default = false,
    Callback = function(state)
        featureStates.FullBright = state
        if state then
            local Lighting = game:GetService("Lighting")
            featureStates.originalBrightness = Lighting.Brightness
            featureStates.originalAmbient = Lighting.Ambient
            featureStates.originalOutdoorAmbient = Lighting.OutdoorAmbient
            featureStates.originalColorShiftBottom = Lighting.ColorShift_Bottom
            featureStates.originalColorShiftTop = Lighting.ColorShift_Top

            local function applyFullBright()
                if Lighting.Brightness ~= 1 then Lighting.Brightness = 1 end
                if Lighting.Ambient ~= Color3.new(1, 1, 1) then Lighting.Ambient = Color3.new(1, 1, 1) end
                if Lighting.OutdoorAmbient ~= Color3.new(1, 1, 1) then Lighting.OutdoorAmbient = Color3.new(1, 1, 1) end
                if Lighting.ColorShift_Bottom ~= Color3.new(1, 1, 1) then Lighting.ColorShift_Bottom = Color3.new(1, 1, 1) end
                if Lighting.ColorShift_Top ~= Color3.new(1, 1, 1) then Lighting.ColorShift_Top = Color3.new(1, 1, 1) end
            end

            applyFullBright()
            if featureStates.fullBrightConnection then featureStates.fullBrightConnection:Disconnect() end
            featureStates.fullBrightConnection = RunService.Heartbeat:Connect(function()
                if featureStates.FullBright then applyFullBright() end
            end)
            featureStates.fullBrightCharConnection = player.CharacterAdded:Connect(function()
                task.wait(1)
                if featureStates.FullBright then applyFullBright() end
            end)
        else
            if featureStates.fullBrightConnection then
                featureStates.fullBrightConnection:Disconnect()
                featureStates.fullBrightConnection = nil
            end
            if featureStates.fullBrightCharConnection then
                featureStates.fullBrightCharConnection:Disconnect()
                featureStates.fullBrightCharConnection = nil
            end
            if featureStates.originalBrightness then
                local Lighting = game:GetService("Lighting")
                Lighting.Brightness = featureStates.originalBrightness
                Lighting.Ambient = featureStates.originalAmbient
                Lighting.OutdoorAmbient = featureStates.originalOutdoorAmbient
                Lighting.ColorShift_Bottom = featureStates.originalColorShiftBottom
                Lighting.ColorShift_Top = featureStates.originalColorShiftTop
            end
        end
    end
})

MiscTab:AddButton({
    Title = "Anti lag 1",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 1
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj:Destroy()
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end
        for _, pl in ipairs(Players:GetPlayers()) do
            local char = pl.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("Accessory") or part:IsA("Clothing") then part:Destroy() end
                end
            end
        end
    end
})

MiscTab:AddButton({
    Title = "Anti lag 2",
    Callback = function()
        local ToDisable = {Textures = true, VisualEffects = true, Parts = true, Particles = true, Sky = true}
        local ToEnable = {FullBright = false}
        for _, v in next, game:GetDescendants() do
            if ToDisable.Parts then
                if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                end
            end
            if ToDisable.Particles then
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
                    v.Enabled = false
                end
            end
            if ToDisable.VisualEffects then
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                end
            end
            if ToDisable.Textures then
                if v:IsA("Decal") or v:IsA("Texture") then v.Texture = "" end
            end
            if ToDisable.Sky then
                if v:IsA("Sky") then v.Parent = nil end
            end
        end
        if ToEnable.FullBright then
            local Lighting = game:GetService("Lighting")
            Lighting.FogColor = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = math.huge
            Lighting.FogStart = math.huge
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 5
            Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
            Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Outlines = true
        end
    end
})

MiscTab:AddButton({
    Title = "Remove Texture",
    Callback = function()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
                if part:IsA("Part") then part.Material = Enum.Material.SmoothPlastic end
                if part:FindFirstChildWhichIsA("Texture") then
                    local texture = part:FindFirstChildWhichIsA("Texture")
                    texture.Texture = "rbxassetid://0"
                end
                if part:FindFirstChildWhichIsA("Decal") then
                    local decal = part:FindFirstChildWhichIsA("Decal")
                    decal.Texture = "rbxassetid://0"
                end
            end
        end
    end
})

local NoFogToggle = MiscTab:AddToggle("NoFogToggle", {
    Title = "Remove fog",
    Default = false,
    Callback = function(state)
        local Lighting = game:GetService("Lighting")
        if state then
            featureStates.originalFogEnd = Lighting.FogEnd
            featureStates.originalAtmospheres = {}
            for _, atmosphere in ipairs(Lighting:GetChildren()) do
                if atmosphere:IsA("Atmosphere") then
                    table.insert(featureStates.originalAtmospheres, atmosphere:Clone())
                end
            end
            Lighting.FogEnd = 1000000
            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("Atmosphere") then v:Destroy() end
            end
        else
            if featureStates.originalFogEnd then Lighting.FogEnd = featureStates.originalFogEnd end
            if featureStates.originalAtmospheres then
                for _, atmosphere in ipairs(featureStates.originalAtmospheres) do
                    if not atmosphere.Parent then
                        local newAtmosphere = Instance.new("Atmosphere")
                        for _, prop in pairs({"Density", "Offset", "Color", "Decay", "Glare", "Haze"}) do
                            if atmosphere[prop] then newAtmosphere[prop] = atmosphere[prop] end
                        end
                        newAtmosphere.Parent = Lighting
                    end
                end
            end
        end
    end
})

-- ====== ВКЛАДКА VISUALS ======

local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "solar/folder-bold" })
VisualsTab:AddSection("Cosmetics Changer")

local cosmetic1 = ""
local cosmetic2 = ""
local originalCosmetic1 = ""
local originalCosmetic2 = ""
local isSwapped = false

local CurrentCosmeticsInput = VisualsTab:AddInput("CurrentCosmeticsInput", {
    Title = "Current Cosmetics",
    Default = "",
    Placeholder = "Enter current cosmetic name",
    Finished = false,
    Callback = function(Value)
        cosmetic1 = Value
        if not isSwapped then originalCosmetic1 = Value end
    end
})

local SelectCosmeticsInput = VisualsTab:AddInput("SelectCosmeticsInput", {
    Title = "Select Cosmetics",
    Default = "",
    Placeholder = "Enter cosmetic to swap with",
    Finished = false,
    Callback = function(Value)
        cosmetic2 = Value
        if not isSwapped then originalCosmetic2 = Value end
    end
})

local ApplyCosmeticsButton = VisualsTab:AddButton({
    Title = "Apply Cosmetics",
    Callback = function()
        pcall(function()
            if cosmetic1 == "" or cosmetic2 == "" or cosmetic1 == cosmetic2 then return end
            local Cosmetics = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Cosmetics")
            local function normalize(str) return str:gsub("%s+", ""):lower() end
            local function levenshtein(s, t)
                local m, n = #s, #t
                local d = {}
                for i = 0, m do d[i] = {[0] = i} end
                for j = 0, n do d[0][j] = j end
                for i = 1, m do
                    for j = 1, n do
                        local cost = (s:sub(i,i) == t:sub(j,j)) and 0 or 1
                        d[i][j] = math.min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + cost)
                    end
                end
                return d[m][n]
            end
            local function similarity(s, t)
                local nS, nT = normalize(s), normalize(t)
                local dist = levenshtein(nS, nT)
                return 1 - dist / math.max(#nS, #nT)
            end
            local function findSimilar(name)
                local bestMatch = name
                local bestScore = 0.5
                for _, c in ipairs(Cosmetics:GetChildren()) do
                    local score = similarity(name, c.Name)
                    if score > bestScore then bestScore = score bestMatch = c.Name end
                end
                return bestMatch
            end
            cosmetic1 = findSimilar(cosmetic1)
            cosmetic2 = findSimilar(cosmetic2)
            local a = Cosmetics:FindFirstChild(cosmetic1)
            local b = Cosmetics:FindFirstChild(cosmetic2)
            if not a or not b then return end
            if not isSwapped then
                originalCosmetic1 = cosmetic1
                originalCosmetic2 = cosmetic2
            end
            local tempRoot = Instance.new("Folder", Cosmetics)
            tempRoot.Name = "__temp_swap_" .. tostring(tick()):gsub("%.", "_")
            local tempA = Instance.new("Folder", tempRoot)
            local tempB = Instance.new("Folder", tempRoot)
            for _, c in ipairs(a:GetChildren()) do c.Parent = tempA end
            for _, c in ipairs(b:GetChildren()) do c.Parent = tempB end
            for _, c in ipairs(tempA:GetChildren()) do c.Parent = b end
            for _, c in ipairs(tempB:GetChildren()) do c.Parent = a end
            tempRoot:Destroy()
            isSwapped = true
            Fluent:Notify({ Title = "Cosmetics Changer", Content = "Successfully swapped " .. cosmetic1 .. " with " .. cosmetic2, Duration = 3 })
        end)
    end
})

local ResetCosmeticsButton = VisualsTab:AddButton({
    Title = "Reset Cosmetics",
    Callback = function()
        pcall(function()
            if not isSwapped then
                Fluent:Notify({ Title = "Cosmetics Changer", Content = "No cosmetics have been swapped yet", Duration = 3 })
                return
            end
            if originalCosmetic1 == "" or originalCosmetic2 == "" then
                Fluent:Notify({ Title = "Cosmetics Changer", Content = "Original cosmetic names not found", Duration = 3 })
                return
            end
            local Cosmetics = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Cosmetics")
            local function normalize(str) return str:gsub("%s+", ""):lower() end
            local function findSimilar(name)
                local bestMatch = name
                local bestScore = 0.5
                for _, c in ipairs(Cosmetics:GetChildren()) do
                    local normalizedInput = normalize(name)
                    local normalizedCosmetic = normalize(c.Name)
                    if normalizedInput == normalizedCosmetic then return c.Name end
                end
                return name
            end
            local a = Cosmetics:FindFirstChild(cosmetic1)
            local b = Cosmetics:FindFirstChild(cosmetic2)
            if a and b then
                local tempRoot = Instance.new("Folder", Cosmetics)
                tempRoot.Name = "__temp_reset_" .. tostring(tick()):gsub("%.", "_")
                local tempA = Instance.new("Folder", tempRoot)
                local tempB = Instance.new("Folder", tempRoot)
                for _, c in ipairs(a:GetChildren()) do c.Parent = tempA end
                for _, c in ipairs(b:GetChildren()) do c.Parent = tempB end
                for _, c in ipairs(tempA:GetChildren()) do c.Parent = b end
                for _, c in ipairs(tempB:GetChildren()) do c.Parent = a end
                tempRoot:Destroy()
                isSwapped = false
                Fluent:Notify({ Title = "Cosmetics Changer", Content = "Successfully reset cosmetics to original state", Duration = 3 })
            else
                Fluent:Notify({ Title = "Cosmetics Changer", Content = "Could not find swapped cosmetics to reset", Duration = 3 })
            end
        end)
    end
})

VisualsTab:AddSection("CarryAnimation Replacer")

currentCarryAnim = ""
selectedCarryAnim = ""
lastCurrentCarryAnim = ""
lastSelectedCarryAnim = ""
isSwapped = false

function normalizeString(str) return str:gsub("%s+", ""):lower() end

function isValidCarryAnimation(name)
    local carryAnimations = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
    if not carryAnimations then return false end
    carryAnimations = carryAnimations:FindFirstChild("CarryAnimations")
    if not carryAnimations then return false end
    local normalizedInput = normalizeString(name)
    for _, anim in ipairs(carryAnimations:GetChildren()) do
        if normalizeString(anim.Name) == normalizedInput then return true, anim.Name end
    end
    return false
end

function revertPreviousSwap()
    if lastCurrentCarryAnim ~= "" and lastSelectedCarryAnim ~= "" and isSwapped then
        local carryAnimations = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
        if carryAnimations then
            carryAnimations = carryAnimations:FindFirstChild("CarryAnimations")
            if carryAnimations then
                local lastCurrentValid, lastCurrentActual = isValidCarryAnimation(lastCurrentCarryAnim)
                local lastSelectedValid, lastSelectedActual = isValidCarryAnimation(lastSelectedCarryAnim)
                if lastCurrentValid and lastSelectedValid then
                    pcall(function()
                        local currentFolder = carryAnimations:FindFirstChild(lastCurrentActual)
                        local selectedFolder = carryAnimations:FindFirstChild(lastSelectedActual)
                        if currentFolder and selectedFolder then
                            local tempRoot = Instance.new("Folder")
                            tempRoot.Name = "__temp_revert_swap_" .. tostring(tick()):gsub("%.", "_")
                            tempRoot.Parent = carryAnimations
                            local tempCurrent = Instance.new("Folder")
                            tempCurrent.Name = "tempCurrent"
                            tempCurrent.Parent = tempRoot
                            local tempSelected = Instance.new("Folder")
                            tempSelected.Name = "tempSelected"
                            tempSelected.Parent = tempRoot
                            for _, child in ipairs(currentFolder:GetChildren()) do child.Parent = tempCurrent end
                            for _, child in ipairs(selectedFolder:GetChildren()) do child.Parent = tempSelected end
                            for _, child in ipairs(tempCurrent:GetChildren()) do child.Parent = selectedFolder end
                            for _, child in ipairs(tempSelected:GetChildren()) do child.Parent = currentFolder end
                            tempRoot:Destroy()
                        end
                    end)
                end
            end
        end
        isSwapped = false
    end
end

local CurrentCarryAnimInput = VisualsTab:AddInput("CurrentCarryAnimInput", {
    Title = "Current CarryAnimation",
    Default = "",
    Placeholder = "Enter current carry animation name",
    Finished = false,
    Callback = function(Value)
        if Value ~= currentCarryAnim and currentCarryAnim ~= "" then revertPreviousSwap() end
        currentCarryAnim = Value
    end
})

local SelectedCarryAnimInput = VisualsTab:AddInput("SelectedCarryAnimInput", {
    Title = "Selected CarryAnimation",
    Default = "",
    Placeholder = "Enter selected carry animation name",
    Finished = false,
    Callback = function(Value)
        if Value ~= selectedCarryAnim and selectedCarryAnim ~= "" then revertPreviousSwap() end
        selectedCarryAnim = Value
    end
})

local ApplyCarryAnimButton = VisualsTab:AddButton({
    Title = "Apply CarryAnimation Swap",
    Callback = function()
        local currentNorm = normalizeString(currentCarryAnim)
        local selectedNorm = normalizeString(selectedCarryAnim)
        if currentNorm == "" or selectedNorm == "" then
            Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "Both animation names must be filled", Duration = 3 })
            return
        end
        if currentNorm == selectedNorm then
            Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "Animation names cannot be the same", Duration = 3 })
            return
        end
        local carryAnimations = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
        if not carryAnimations then
            Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "CarryAnimations folder not found", Duration = 3 })
            return
        end
        carryAnimations = carryAnimations:FindFirstChild("CarryAnimations")
        if not carryAnimations then
            Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "CarryAnimations folder not found", Duration = 3 })
            return
        end
        local currentAnim, currentActualName = isValidCarryAnimation(currentCarryAnim)
        local selectedAnim, selectedActualName = isValidCarryAnimation(selectedCarryAnim)
        if not currentAnim then
            Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "Current animation not found: " .. currentCarryAnim, Duration = 3 })
            return
        end
        if not selectedAnim then
            Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "Selected animation not found: " .. selectedCarryAnim, Duration = 3 })
            return
        end
        pcall(function()
            revertPreviousSwap()
            local currentFolder = carryAnimations:FindFirstChild(currentActualName)
            local selectedFolder = carryAnimations:FindFirstChild(selectedActualName)
            if not currentFolder or not selectedFolder then
                Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "One or both animations not found in folder", Duration = 3 })
                return
            end
            local tempRoot = Instance.new("Folder")
            tempRoot.Name = "__temp_carry_swap_" .. tostring(tick()):gsub("%.", "_")
            tempRoot.Parent = carryAnimations
            local tempCurrent = Instance.new("Folder")
            tempCurrent.Name = "tempCurrent"
            tempCurrent.Parent = tempRoot
            local tempSelected = Instance.new("Folder")
            tempSelected.Name = "tempSelected"
            tempSelected.Parent = tempRoot
            for _, child in ipairs(currentFolder:GetChildren()) do child.Parent = tempCurrent end
            for _, child in ipairs(selectedFolder:GetChildren()) do child.Parent = tempSelected end
            for _, child in ipairs(tempCurrent:GetChildren()) do child.Parent = selectedFolder end
            for _, child in ipairs(tempSelected:GetChildren()) do child.Parent = currentFolder end
            tempRoot:Destroy()
            lastCurrentCarryAnim = currentCarryAnim
            lastSelectedCarryAnim = selectedCarryAnim
            isSwapped = true
            Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "Successfully swapped " .. currentActualName .. " with " .. selectedActualName, Duration = 3 })
        end)
    end
})

local ResetCarryAnimButton = VisualsTab:AddButton({
    Title = "Reset All CarryAnimations",
    Callback = function()
        revertPreviousSwap()
        currentCarryAnim = ""
        selectedCarryAnim = ""
        lastCurrentCarryAnim = ""
        lastSelectedCarryAnim = ""
        isSwapped = false
        CurrentCarryAnimInput:SetValue("")
        SelectedCarryAnimInput:SetValue("")
        Fluent:Notify({ Title = "CarryAnimation Replacer", Content = "All animations reset to original", Duration = 3 })
    end
})

VisualsTab:AddSection("NameTag Changers")

function updateNametagList()
    local nametagValues = {"Ignore", "None"}
    local nametagsFolder = game:GetService("ReplicatedStorage").Items.Nametags
    if nametagsFolder then
        for _, nametagModule in ipairs(nametagsFolder:GetChildren()) do
            if nametagModule:IsA("ModuleScript") then
                local success, nametagData = pcall(require, nametagModule)
                if success and nametagData and nametagData.AppearanceInfo then
                    table.insert(nametagValues, nametagData.AppearanceInfo.Name)
                end
            end
        end
    end
    return nametagValues
end

local VisualNametagDropdown = VisualsTab:AddDropdown("VisualNametagDropdown", {
    Title = "Visual Nametag",
    Description = "Select nametag appearance",
    Values = updateNametagList(),
    Multi = false,
    Default = "Ignore",
    Callback = function(Value)
        local playerFolder = workspace.Game.Players:FindFirstChild(game.Players.LocalPlayer.Name)
        if playerFolder then
            if Value == "None" then
                playerFolder:SetAttribute("Nametag", nil)
            elseif Value ~= "Ignore" then
                local cleanValue = Value:gsub("%s+", "")
                playerFolder:SetAttribute("Nametag", cleanValue)
            end
        end
    end
})

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    local playerFolder = workspace.Game.Players:FindFirstChild(game.Players.LocalPlayer.Name)
    if playerFolder and Options.VisualNametagDropdown and Options.VisualNametagDropdown.Value ~= "Ignore" then
        if Options.VisualNametagDropdown.Value == "None" then
            playerFolder:SetAttribute("Nametag", nil)
        else
            local cleanValue = Options.VisualNametagDropdown.Value:gsub("%s+", "")
            playerFolder:SetAttribute("Nametag", cleanValue)
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    local playerFolder = workspace.Game.Players:FindFirstChild(game.Players.LocalPlayer.Name)
    if playerFolder and Options.VisualNametagDropdown and Options.VisualNametagDropdown.Value ~= "Ignore" then
        if Options.VisualNametagDropdown.Value == "None" then
            playerFolder:SetAttribute("Nametag", nil)
        else
            local cleanValue = Options.VisualNametagDropdown.Value:gsub("%s+", "")
            local currentTag = playerFolder:GetAttribute("Nametag")
            if currentTag ~= cleanValue then
                playerFolder:SetAttribute("Nametag", cleanValue)
            end
        end
    end
end)

VisualsTab:AddSection("Fake Streaks")

local FakeStreaksInput = VisualsTab:AddInput("FakeStreaksInput", {
    Title = "Fake Streaks",
    Default = "",
    Placeholder = "Enter streak value",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            game:GetService("Players").LocalPlayer:SetAttribute("Streak", num)
        end
    end
})

task.spawn(function()
    task.wait(1)
    local currentStreak = game:GetService("Players").LocalPlayer:GetAttribute("Streak")
    if currentStreak then
        FakeStreaksInput:SetValue(tostring(currentStreak))
    end
end)

VisualsTab:AddSection("Emote Changer")

local player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events", 10)
local CharacterFolder = Events and Events:WaitForChild("Character", 10)
local EmoteRemote = CharacterFolder and CharacterFolder:WaitForChild("Emote", 10)
local PassCharacterInfo = CharacterFolder and CharacterFolder:WaitForChild("PassCharacterInfo", 10)
local remoteSignal = PassCharacterInfo and PassCharacterInfo.OnClientEvent
local currentTag = nil
local currentEmotes = {}
local selectEmotes = {}
local emoteEnabled = {}
local currentEmoteInputs = {}
local selectEmoteInputs = {}

for i = 1, 12 do
    currentEmotes[i] = ""
    selectEmotes[i] = ""
    emoteEnabled[i] = false
end

function readTagFromFolder(f)
    if not f then return nil end
    local tagAttribute = f:GetAttribute("Tag")
    if tagAttribute ~= nil then return tagAttribute end
    local tagChild = f:FindFirstChild("Tag")
    if tagChild and tagChild:IsA("ValueBase") then return tagChild.Value end
    return nil
end

function onRespawn()
    currentTag = nil
    pendingSlot = nil
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < 10 do
            if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players") then
                local playerFolder = workspace.Game.Players:FindFirstChild(player.Name)
                if playerFolder then
                    currentTag = readTagFromFolder(playerFolder)
                    if currentTag then
                        local tagNumber = tonumber(currentTag)
                        if tagNumber and tagNumber >= 0 and tagNumber <= 255 then break
                        else currentTag = nil end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

pendingSlot = nil
blockOriginalEmote = false

function fireSelect(slot)
    if not currentTag then return end
    local tagNumber = tonumber(currentTag)
    if not tagNumber or tagNumber < 0 or tagNumber > 255 then return end
    if not selectEmotes[slot] or selectEmotes[slot] == "" then return end
    if remoteSignal then
        pcall(function()
            local buf = buffer.create(2)
            buffer.writeu8(buf, 0, tagNumber)
            buffer.writeu8(buf, 1, 17)
            firesignal(remoteSignal, buf, {selectEmotes[slot]})
        end)
    end
end

if PassCharacterInfo and EmoteRemote then
    PassCharacterInfo.OnClientEvent:Connect(function(...)
        if not pendingSlot then return end
        local slot = pendingSlot
        pendingSlot = nil
        task.wait(0.1)
        fireSelect(slot)
    end)
    local success, oldNamecall = pcall(function()
        local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local methodName = getnamecallmethod()
            local args = {...}
            if methodName == "FireServer" and self == EmoteRemote and type(args[1]) == "string" then
                for i = 1, 12 do
                    if emoteEnabled[i] and currentEmotes[i] ~= "" and args[1] == currentEmotes[i] then
                        pendingSlot = i
                        blockOriginalEmote = true
                        task.spawn(function()
                            task.wait(0.1)
                            blockOriginalEmote = false
                            if pendingSlot == i then
                                pendingSlot = nil
                                fireSelect(i)
                            end
                        end)
                        if blockOriginalEmote then return nil end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        return oldNamecall
    end)
    if player.Character then task.spawn(onRespawn) end
    player.CharacterAdded:Connect(function()
        task.wait(1)
        onRespawn()
    end)
    if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players") then
        workspace.Game.Players.ChildAdded:Connect(function(child)
            if child.Name == player.Name then
                task.wait(0.5)
                onRespawn()
            end
        end)
        workspace.Game.Players.ChildRemoved:Connect(function(child)
            if child.Name == player.Name then
                currentTag = nil
                pendingSlot = nil
            end
        end)
    end
end

for i = 1, 12 do
    currentEmoteInputs[i] = VisualsTab:AddInput("CurrentEmoteInput" .. i, {
        Title = "Current Emote " .. i,
        Default = "",
        Placeholder = "Enter current emote name",
        Finished = false,
        Callback = function(Value) currentEmotes[i] = Value:gsub("%s+", "") end
    })
end

VisualsTab:AddParagraph({ Title = "", Content = "" })

for i = 1, 12 do
    selectEmoteInputs[i] = VisualsTab:AddInput("SelectEmoteInput" .. i, {
        Title = "Select Emote " .. i,
        Default = "",
        Placeholder = "Enter select emote name",
        Finished = false,
        Callback = function(Value) selectEmotes[i] = Value:gsub("%s+", "") end
    })
end

local VisualsEmoteApply = VisualsTab:AddButton({
    Title = "Apply Emote Mappings",
    Callback = function()
        local hasAnyEmote = false
        for i = 1, 12 do
            if currentEmotes[i] ~= "" or selectEmotes[i] ~= "" then hasAnyEmote = true break end
        end
        if not hasAnyEmote then
            Fluent:Notify({ Title = "Emote Changer", Content = "Please enter your emote", Duration = 3 })
            return
        end
        local function normalizeEmoteName(name) return name:gsub("%s+", ""):lower() end
        local function isValidEmote(emoteName)
            if emoteName == "" then return false, "" end
            local normalizedInput = normalizeEmoteName(emoteName)
            local ItemsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
            if ItemsFolder then
                local emotesFolder = ItemsFolder:FindFirstChild("Emotes")
                if emotesFolder then
                    for _, emoteModule in ipairs(emotesFolder:GetChildren()) do
                        if emoteModule:IsA("ModuleScript") then
                            local normalizedEmote = normalizeEmoteName(emoteModule.Name)
                            if normalizedEmote == normalizedInput then return true, emoteModule.Name end
                        end
                    end
                end
            end
            return false, ""
        end
        local sameEmoteSlots = {}
        local missingEmoteSlots = {}
        local invalidEmoteSlots = {}
        local successfulSlots = {}
        for i = 1, 12 do
            if currentEmotes[i] ~= "" and selectEmotes[i] ~= "" then
                local currentValid, currentActual = isValidEmote(currentEmotes[i])
                local selectValid, selectActual = isValidEmote(selectEmotes[i])
                if not currentValid and not selectValid then
                    table.insert(invalidEmoteSlots, {slot = i, currentInvalid = true, currentName = currentEmotes[i], selectInvalid = true, selectName = selectEmotes[i]})
                elseif not currentValid then
                    table.insert(invalidEmoteSlots, {slot = i, currentInvalid = true, currentName = currentEmotes[i], selectInvalid = false, selectName = selectEmotes[i]})
                elseif not selectValid then
                    table.insert(invalidEmoteSlots, {slot = i, currentInvalid = false, currentName = currentEmotes[i], selectInvalid = true, selectName = selectEmotes[i]})
                elseif currentActual:lower() == selectActual:lower() then
                    table.insert(sameEmoteSlots, i)
                else
                    table.insert(successfulSlots, {slot = i, current = currentActual, select = selectActual})
                end
            elseif currentEmotes[i] ~= "" or selectEmotes[i] ~= "" then
                table.insert(missingEmoteSlots, i)
            end
        end
        local message = ""
        if #successfulSlots > 0 then
            message = message .. "✓ Successfully applied emote on:\n"
            for _, data in ipairs(successfulSlots) do
                message = message .. "Slot " .. data.slot .. " Emote: " .. data.current .. " → " .. data.select .. "\n"
                emoteEnabled[data.slot] = true
            end
            message = message .. "\n"
        end
        if #sameEmoteSlots > 0 then
            message = message .. "✗ Failed to apply emote on:\n"
            for _, slot in ipairs(sameEmoteSlots) do
                message = message .. "Slot " .. slot .. " - Cannot change emote with the same name\n"
                emoteEnabled[slot] = false
            end
            message = message .. "\n"
        end
        if #invalidEmoteSlots > 0 then
            message = message .. "✗ Failed to apply emote on:\n"
            for _, data in ipairs(invalidEmoteSlots) do
                message = message .. "Slot " .. data.slot .. " - "
                if data.currentInvalid and data.selectInvalid then
                    message = message .. "Invalid current emote: \"" .. data.currentName .. "\", Invalid select emote: \"" .. data.selectName .. "\"\n"
                elseif data.currentInvalid then
                    message = message .. "Invalid current emote: \"" .. data.currentName .. "\", Select emote: \"" .. data.selectName .. "\"\n"
                else
                    message = message .. "Current emote: \"" .. data.currentName .. "\", Invalid select emote: \"" .. data.selectName .. "\"\n"
                end
                emoteEnabled[data.slot] = false
            end
            message = message .. "\n"
        end
        if #missingEmoteSlots > 0 then
            message = message .. "✗ Failed to apply emote on:\n"
            for _, slot in ipairs(missingEmoteSlots) do
                if currentEmotes[slot] == "" then
                    message = message .. "Slot " .. slot .. " - Current emote slot is missing text\n"
                else
                    message = message .. "Slot " .. slot .. " - Select emote slot is missing text\n"
                end
                emoteEnabled[slot] = false
            end
        end
        Fluent:Notify({ Title = "Emote Changer", Content = message, Duration = 8 })
    end
})

local VisualsEmoteReset = VisualsTab:AddButton({
    Title = "Reset All Emotes",
    Callback = function()
        for i = 1, 12 do
            currentEmotes[i] = ""
            selectEmotes[i] = ""
            emoteEnabled[i] = false
            if currentEmoteInputs[i] then currentEmoteInputs[i]:SetValue("") end
            if selectEmoteInputs[i] then selectEmoteInputs[i]:SetValue("") end
        end
        Fluent:Notify({ Title = "Emote Changer", Content = "All emotes have been reset!", Duration = 3 })
    end
})

VisualsTab:AddSection("Emote Replacer (very buggy)")

local EmoteReplacer = {
    CurrentEmotes = {},
    SelectedEmotes = {},
    SwappedPairs = {},
    InputFields = {}
}

for i = 1, 12 do
    EmoteReplacer.CurrentEmotes[i] = ""
    EmoteReplacer.SelectedEmotes[i] = ""
end

VisualsTab:AddParagraph({ Title = "This Script is for bad executor", Content = "" })
VisualsTab:AddParagraph({ Title = "Current Emotes", Content = "" })

for i = 1, 12 do
    EmoteReplacer.InputFields["CurrentEmote" .. i] = VisualsTab:AddInput("CurrentEmote" .. i, {
        Title = "Current Emote " .. i,
        Default = "",
        Placeholder = "Enter current emote name",
        Finished = false,
        Callback = function(Value) EmoteReplacer.CurrentEmotes[i] = Value end
    })
end

VisualsTab:AddParagraph({ Title = "Selected Emotes", Content = "" })

for i = 1, 12 do
    EmoteReplacer.InputFields["SelectedEmote" .. i] = VisualsTab:AddInput("SelectedEmote" .. i, {
        Title = "Select Emote " .. i,
        Default = "",
        Placeholder = "Enter replacement emote name",
        Finished = false,
        Callback = function(Value) EmoteReplacer.SelectedEmotes[i] = Value end
    })
end

function SwapEmoteNames(currentName, selectedName)
    local Items = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
    if not Items then return false end
    local EmotesFolder = Items:FindFirstChild("Emotes")
    if not EmotesFolder then return false end
    local currentEmoteObj = EmotesFolder:FindFirstChild(currentName)
    local selectedEmoteObj = EmotesFolder:FindFirstChild(selectedName)
    if currentEmoteObj and selectedEmoteObj then
        local tempName = selectedName .. "_EmoteSwapTemp"
        while EmotesFolder:FindFirstChild(tempName) do tempName = tempName .. "_" end
        currentEmoteObj.Name = tempName
        selectedEmoteObj.Name = currentName
        currentEmoteObj.Name = selectedName
        return true
    else
        return false
    end
end

function ResetEmoteNames()
    if not EmoteReplacer.SwappedPairs then return false end
    local Items = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
    if not Items then return false end
    local EmotesFolder = Items:FindFirstChild("Emotes")
    if not EmotesFolder then return false end
    for currentEmote, selectedEmote in pairs(EmoteReplacer.SwappedPairs) do
        local currentEmoteObj = EmotesFolder:FindFirstChild(selectedEmote)
        local selectedEmoteObj = EmotesFolder:FindFirstChild(currentEmote)
        if currentEmoteObj and selectedEmoteObj then
            local tempName = currentEmote .. "_EmoteSwapTemp"
            while EmotesFolder:FindFirstChild(tempName) do tempName = tempName .. "_" end
            currentEmoteObj.Name = tempName
            selectedEmoteObj.Name = selectedEmote
            currentEmoteObj.Name = currentEmote
        end
    end
    return true
end

local EmoteSwapApplyButton = VisualsTab:AddButton({
    Title = "Apply Emote Swap",
    Callback = function()
        local swappedCount = 0
        local failedCount = 0
        for i = 1, 12 do
            local currentEmote = EmoteReplacer.CurrentEmotes[i]
            local selectedEmote = EmoteReplacer.SelectedEmotes[i]
            if currentEmote ~= "" and selectedEmote ~= "" then
                if SwapEmoteNames(currentEmote, selectedEmote) then
                    EmoteReplacer.SwappedPairs[currentEmote] = selectedEmote
                    swappedCount = swappedCount + 1
                else
                    failedCount = failedCount + 1
                end
            end
        end
        local message = ""
        if swappedCount > 0 then message = "Successfully swapped " .. tostring(swappedCount) .. " emote(s)" end
        if failedCount > 0 then
            if message ~= "" then message = message .. " | " end
            message = message .. "Failed to swap " .. tostring(failedCount) .. " emote(s)"
        end
        if message == "" then message = "No emotes specified to swap" end
        Fluent:Notify({ Title = "Emote Replacer", Content = message, Duration = 3 })
    end
})

local EmoteSwapResetButton = VisualsTab:AddButton({
    Title = "Reset Emote Module",
    Callback = function()
        if ResetEmoteNames() then
            EmoteReplacer.SwappedPairs = {}
            for i = 1, 12 do
                EmoteReplacer.CurrentEmotes[i] = ""
                EmoteReplacer.SelectedEmotes[i] = ""
                if EmoteReplacer.InputFields["CurrentEmote" .. i] then EmoteReplacer.InputFields["CurrentEmote" .. i]:SetValue("") end
                if EmoteReplacer.InputFields["SelectedEmote" .. i] then EmoteReplacer.InputFields["SelectedEmote" .. i]:SetValue("") end
            end
            Fluent:Notify({ Title = "Emote Replacer", Content = "All emotes have been restored to original names!", Duration = 3 })
        else
            Fluent:Notify({ Title = "Emote Replacer", Content = "Failed to reset emotes!", Duration = 3 })
        end
    end
})

player.CharacterRemoving:Connect(function()
    if next(EmoteReplacer.SwappedPairs) then ResetEmoteNames() end
end)

player.CharacterAdded:Connect(function(character)
    task.wait(1)
    if character:GetAttribute("Downed") then return end
    if next(EmoteReplacer.SwappedPairs) then
        for currentEmote, selectedEmote in pairs(EmoteReplacer.SwappedPairs) do
            SwapEmoteNames(currentEmote, selectedEmote)
        end
    end
end)

-- ====== ВКЛАДКА SETTINGS ======

local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "solar/settings-bold" })

SettingsTab:AddSection("Configuration")

SettingsTab:AddSection("FPS Timer Settings")

local FPSTimerToggle = SettingsTab:AddToggle("FPSTimerToggle", {
    Title = "Show FPS Timer",
    Description = "Display FPS and session timer",
    Default = true,
    Callback = function(state)
        local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local timerGUI = PlayerGui:FindFirstChild("DraconicFPS")
        if state then
            if not timerGUI then createSimpleTimer() else timerGUI.Enabled = true end
        else
            if timerGUI then timerGUI.Enabled = false end
        end
    end
})

SettingsTab:AddButton({
    Title = "Save Configuration",
    Description = "Save current settings to config file",
    Callback = function()
        SaveManager:Save()
        Fluent:Notify({ Title = "Settings", Content = "Configuration saved successfully!", Duration = 3 })
    end
})

SettingsTab:AddButton({
    Title = "Load Configuration",
    Description = "Load settings from config file",
    Callback = function()
        SaveManager:Load()
        Fluent:Notify({ Title = "Settings", Content = "Configuration loaded successfully!", Duration = 3 })
    end
})

SettingsTab:AddButton({
    Title = "Reset Configuration",
    Description = "Reset all settings to default",
    Callback = function()
        Window:Dialog({
            Title = "Reset Configuration",
            Content = "Are you sure you want to reset all settings to default?",
            Buttons = {
                { Title = "Confirm", Callback = function()
                    SaveManager:Reset()
                    Fluent:Notify({ Title = "Settings", Content = "Configuration reset to default!", Duration = 3 })
                end },
                { Title = "Cancel", Callback = function() end }
            }
        })
    end
})

SettingsTab:AddParagraph({
    Title = "Auto Load",
    Content = "The configuration will automatically load when the script starts."
})

SettingsTab:AddSection("Interface Manager")
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("SadEvade")
InterfaceManager:BuildInterfaceSection(SettingsTab)

SettingsTab:AddSection("Save Manager")
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("SadEvade/Config")
SaveManager:BuildConfigSection(SettingsTab)

task.spawn(function()
    task.wait(1)
    SaveManager:LoadAutoloadConfig()
end)

SettingsTab:AddSection("Button Positions")

local ButtonPositions = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Online%20Script/ButtonPositions.lua"))()

SettingsTab:AddButton({
    Title = "Save Button Positions",
    Description = "Save current positions of all GUI buttons",
    Callback = function()
        local success, msg = ButtonPositions:Save()
        Fluent:Notify({ Title = "Button Positions", Content = msg, Duration = 3 })
    end
})

SettingsTab:AddButton({
    Title = "Load Button Positions",
    Description = "Load saved button positions from file",
    Callback = function()
        local success, msg = ButtonPositions:Load()
        Fluent:Notify({ Title = "Button Positions", Content = msg, Duration = 3 })
    end
})

SettingsTab:AddButton({
    Title = "Reset Button Positions",
    Description = "Reset all buttons to default positions",
    Callback = function()
        Window:Dialog({
            Title = "Reset Button Positions",
            Content = "Are you sure you want to reset all button positions to default?",
            Buttons = {
                { Title = "Confirm", Callback = function()
                    ButtonPositions:Reset()
                    Fluent:Notify({ Title = "Button Positions", Content = "All buttons reset to default positions!", Duration = 3 })
                end },
                { Title = "Cancel", Callback = function() end }
            }
        })
    end
})

-- ====== ВКЛАДКА INFO (БЕЗ ССЫЛОК НА TG/DISCORD) ======

local InfoTab = Window:AddTab({ Title = "Info", Icon = "solar/info-circle-bold" })

InfoTab:AddSection("Information")

InfoTab:AddParagraph({
    Title = "Sad Evade",
    Content = "Thank you for using the Sad Evade script.\n\nThis script is provided for educational purposes only.\nUse only on a throwaway account."
})

InfoTab:AddParagraph({
    Title = "Disclaimer",
    Content = "Using third-party scripts in Roblox violates the Terms of Service and may result in a ban.\nThe author is not responsible for any consequences."
})

-- ====== TIMER GUI ======

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
loadstring(game:HttpGet('https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Online%20Script/TimerGUI.lua'))()

local function createSimpleTimer()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local StatsService = game:GetService("Stats")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DraconicFPS"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 165, 0, 48)
    container.Position = UDim2.new(0, 10, 0, 10)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 0.7
    mainFrame.Parent = container

    local backgroundGradient = Instance.new("UIGradient")
    backgroundGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    backgroundGradient.Rotation = 0
    backgroundGradient.Parent = mainFrame

    local gradientAnimation
    gradientAnimation = RunService.RenderStepped:Connect(function(delta)
        backgroundGradient.Rotation = (backgroundGradient.Rotation + 90 * delta) % 360
    end)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(139, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local textFrame = Instance.new("Frame")
    textFrame.Size = UDim2.new(1, -8, 1, -8)
    textFrame.Position = UDim2.new(0, 4, 0, 4)
    textFrame.BackgroundTransparency = 1
    textFrame.Parent = mainFrame

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                      startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = container.Position
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    local statsText = Instance.new("TextLabel")
    statsText.Size = UDim2.new(1, -10, 0.5, 0)
    statsText.Position = UDim2.new(0, 5, 0, 0)
    statsText.BackgroundTransparency = 1
    statsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsText.Font = Enum.Font.GothamBold
    statsText.TextSize = 13
    statsText.TextXAlignment = Enum.TextXAlignment.Center
    statsText.Text = "FPS: 60 | Ping: 0ms"
    statsText.Parent = textFrame

    local timerText = Instance.new("TextLabel")
    timerText.Size = UDim2.new(1, -10, 0.5, 0)
    timerText.Position = UDim2.new(0, 5, 0.5, 0)
    timerText.BackgroundTransparency = 1
    timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerText.Font = Enum.Font.GothamBold
    timerText.TextSize = 13
    timerText.TextXAlignment = Enum.TextXAlignment.Center
    timerText.Text = "Time: 0h 0m 0s"
    timerText.Parent = textFrame

    mainFrame.MouseEnter:Connect(function()
        stroke.Color = Color3.fromRGB(255, 50, 50)
        backgroundGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 20, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))
        }
    end)

    mainFrame.MouseLeave:Connect(function()
        stroke.Color = Color3.fromRGB(139, 0, 0)
        backgroundGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        }
    end)

    local startTime = tick()
    local frameCount = 0
    local lastUpdate = tick()
    local currentFPS = 0

    local function getPing()
        local ping = 0
        pcall(function()
            local networkStats = StatsService:FindFirstChild("Network")
            if networkStats then
                local serverStats = networkStats:FindFirstChild("ServerStatsItem")
                if serverStats then ping = math.floor(serverStats:GetValue()) end
            end
        end)
        if ping == 0 then
            pcall(function()
                local performanceStats = StatsService:FindFirstChild("PerformanceStats")
                if performanceStats then
                    local pingStat = performanceStats:FindFirstChild("Ping")
                    if pingStat then ping = math.floor(pingStat:GetValue()) end
                end
            end)
        end
        if ping == 0 then ping = 50 end
        return ping
    end

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        if currentTime - lastUpdate >= 0.5 then
            currentFPS = math.floor(frameCount / (currentTime - lastUpdate))
            frameCount = 0
            lastUpdate = currentTime
            local ping = getPing()
            statsText.Text = string.format("FPS: %d | Ping: %dms", currentFPS, ping)
        end
        local elapsed = currentTime - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        timerText.Text = string.format("Time: %dh %dm %ds", hours, minutes, seconds)
    end)

    container.Destroying:Connect(function()
        if gradientAnimation then gradientAnimation:Disconnect() end
    end)

    function screenGui:SetPosition(x, y)
        container.Position = UDim2.new(0, x, 0, y)
    end

    function screenGui:SetVisible(visible)
        screenGui.Enabled = visible
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if not screenGui or not screenGui.Parent then
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end)

    return screenGui
end

createSimpleTimer()

-- ====== ФИНАЛЬНЫЕ ПОДКЛЮЧЕНИЯ ======

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if Options.PlayerToggle and Options.PlayerToggle.Value then
        if not ExternalESPLoaded or not _G.ExternalESPRunning then
            Fluent:Notify({ Title = "ESP Players", Content = "Restoring Player ESP after respawn...", Duration = 3 })
            cleanUpOnlyPlayerESPObjects()
            ExternalESPLoaded = false
            ExternalESP = nil
            _G.ExternalESPRunning = false
            local success = pcall(function()
                ExternalESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Test%20Script/Esp.lua"))()
                ExternalESPLoaded = true
                _G.ExternalESPRunning = true
            end)
            if success then
                Fluent:Notify({ Title = "ESP Players", Content = "Player ESP restored successfully!", Duration = 3 })
            else
                Fluent:Notify({ Title = "ESP Players Error", Content = "Failed to restore Player ESP", Duration = 3 })
                Options.PlayerToggle:Set(false)
            end
        end
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if Options.NextbotToggle and Options.NextbotToggle.Value then
        if ExternalNextbotESPLoaded and ExternalNextbotESP then
            if ExternalNextbotESP.Stop then pcall(ExternalNextbotESP.Stop) end
        end
        for model, data in pairs(NextbotBillboards) do
            if data.esp then data.esp:Destroy() end
        end
        NextbotBillboards = {}
        for model, tracer in pairs(botTracerElements) do
            if tracer and tracer.Remove then tracer:Remove() end
        end
        botTracerElements = {}
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if Options.NextbotToggle and Options.NextbotToggle.Value then
        if ExternalNextbotESPLoaded and ExternalNextbotESP then
            if ExternalNextbotESP.Start then
                pcall(function()
                    ExternalNextbotESP.Start()
                    _G.NextbotESPRunning = true
                    Fluent:Notify({ Title = "ESP Nextbots", Content = "Nextbot ESP restored after respawn!", Duration = 3 })
                end)
            end
        end
    end
end)
