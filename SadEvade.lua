--[[
	Sad Evade
	Edited by user request: Title = "Sad Evade", Theme = Amethyst (purple),
	FloatingButton removed, menu opens by Insert key.
	Optimized & Fixed: Removed duplicate variables, fixed syntax error (local registers limit), removed buggy sections.
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

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "solar/home-bold" })
}
local Options = Fluent.Options

Fluent:Notify({
    Title = "Sad Evade",
    Content = "System Loaded...",
    Duration = 3
})

featureStates = {}

local NextbotBillboards = {}
local nextbotLoop = nil
local TicketBillboards = {}
local ExternalESP = nil
local ExternalESPLoaded = false
local ExternalNextbotESP = nil
local ExternalNextbotESPLoaded = false
local playerLoop = nil

local playerTracerElements = {}
local botTracerElements = {}
local playerTracerConnection = nil
local botTracerConnection = nil
local AntiAFKConnection = nil
local autoWhistleHandle = nil

function cleanUpOnlyPlayerESPObjects()
    local cleaned = 0
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            for _, obj in pairs(pl.Character:GetDescendants()) do
                if obj:IsA("BillboardGui") and obj.Name:lower():find("esp") and not obj.Name:lower():find("nextbot") then
                    obj:Destroy()
                    cleaned = cleaned + 1
                end
            end
        end
    end
    return cleaned
end

function isNextbotModel(model)
    if not model or not model.Name then return false end
    return model.Name:lower():find("nextbot") or model.Name:lower():find("scp") or model.Name:lower():find("monster")
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
                if not playerTracerElements[pl] then playerTracerElements[pl] = createTracerObject() end
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
    for pl, tracer in pairs(playerTracerElements) do if tracer and tracer.Remove then tracer:Remove() end end
    playerTracerElements = {}
end

function startBotTracers()
    if botTracerConnection then return end
    botTracerConnection = RunService.RenderStepped:Connect(updateBotTracers)
end

function stopBotTracers()
    if botTracerConnection then botTracerConnection:Disconnect() botTracerConnection = nil end
    for model, tracer in pairs(botTracerElements) do if tracer and tracer.Remove then tracer:Remove() end end
    botTracerElements = {}
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

local AutoWhistleToggle 

local function startAutoWhistle()
    if autoWhistleHandle then stopAutoWhistle() end
    autoWhistleHandle = task.spawn(function()
        while true do
            if not AutoWhistleToggle or not AutoWhistleToggle.Value then break end
            pcall(function() ReplicatedStorage.Events.Character.Whistle:FireServer() end)
            task.wait(1)
        end
        autoWhistleHandle = nil
    end)
end

local function stopAutoWhistle()
    if autoWhistleHandle then
        local handle = autoWhistleHandle
        autoWhistleHandle = nil
        pcall(function() if type(handle) == "table" and handle.cancel then handle:cancel() end end)
    end
end

-- ====== ВКЛАДКА MAIN ======

Tabs.Main:AddSection("Billboard ESP")
local NextbotToggle = Tabs.Main:AddToggle("NextbotToggle", { Title = "ESP Nextbots", Default = false })
local PlayerToggle = Tabs.Main:AddToggle("PlayerToggle", { Title = "ESP Players", Default = false })

Tabs.Main:AddSection("Highlight")
local HighlightDownedPlayers = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Online%20Script/HighlightPlayers.lua"))()
HighlightDownedPlayers:Init(Fluent, Options)
local HighlightDownedToggle = Tabs.Main:AddToggle("HighlightDownedToggle", {
    Title = "Highlight Players", Default = false,
    Callback = function(value) if value then HighlightDownedPlayers:Start() else HighlightDownedPlayers:Stop() end end
})

local HighlightBots = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Online%20Script/HighlightBots.lua"))()
HighlightBots:Init(Fluent, Options)
local HighlightBotsToggle = Tabs.Main:AddToggle("HighlightBotsToggle", {
    Title = "Highlight Bots", Default = false,
    Callback = function(value) if value then HighlightBots:Start() else HighlightBots:Stop() end end
})

LocalPlayer.CharacterAdded:Connect(function() task.wait(2) if HighlightBotsToggle and HighlightBotsToggle.Value then HighlightBots:Refresh() end end)
workspace.ChildAdded:Connect(function(child) task.wait(1) if child.Name == "Game" and HighlightBotsToggle and HighlightBotsToggle.Value then HighlightBots:Refresh() end end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(1) if HighlightDownedToggle and HighlightDownedToggle.Value then HighlightDownedPlayers:Refresh() end end)

Tabs.Main:AddSection("Tracer ESP")
local TracerPlayerToggle = Tabs.Main:AddToggle("TracerPlayerToggle", { Title = "Tracer Players", Default = false })
local TracerBotToggle = Tabs.Main:AddToggle("TracerBotToggle", { Title = "Tracer Bots", Default = false })

Tabs.Main:AddSection("Respawn")
local AntiAFKToggle = Tabs.Main:AddToggle("AntiAFKToggle", { Title = "Anti AFK", Default = false })
AutoWhistleToggle = Tabs.Main:AddToggle("AutoWhistleToggle", { Title = "Auto Whistle", Default = false })

NextbotToggle:OnChanged(function(value)
    if value then
        if not ExternalNextbotESPLoaded then
            local success = pcall(function()
                ExternalNextbotESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Test%20Script/NextbotESP.lua"))()
                ExternalNextbotESPLoaded = true
                _G.NextbotESPRunning = true
                if ExternalNextbotESP and ExternalNextbotESP.Start then ExternalNextbotESP.Start() end
            end)
            if not success then Options.NextbotToggle:Set(false) return end
        else
            if ExternalNextbotESP and ExternalNextbotESP.Start then ExternalNextbotESP.Start() end
            _G.NextbotESPRunning = true
        end
    else
        if ExternalNextbotESP and ExternalNextbotESPLoaded then
            if ExternalNextbotESP.Stop then pcall(function() ExternalNextbotESP.Stop() end) end
        end
        ExternalNextbotESPLoaded = false
        _G.NextbotESPRunning = false
    end
end)

PlayerToggle:OnChanged(function(value)
    if value then
        cleanUpOnlyPlayerESPObjects()
        if not ExternalESPLoaded then
            pcall(function()
                local espScript = game:HttpGet("https://raw.githubusercontent.com/Ksndfkssc/87643/refs/heads/main/Test%20Script/Esp.lua", true)
                ExternalESP = loadstring(espScript)()
                ExternalESPLoaded = true
                _G.ExternalESPRunning = true
                _G.PlayerESP_Loaded = true
            end)
        else
            _G.ExternalESPRunning = true
            _G.PlayerESP_Loaded = true
        end
    else
        cleanUpOnlyPlayerESPObjects()
        _G.ExternalESPRunning = false
        _G.PlayerESP_Loaded = false
        ExternalESPLoaded = false
    end
end)

TracerPlayerToggle:OnChanged(function(value) if value then startPlayerTracers() else stopPlayerTracers() end end)
TracerBotToggle:OnChanged(function(value) if value then startBotTracers() else stopBotTracers() end end)
AntiAFKToggle:OnChanged(function(value) if value then startAntiAFK() else stopAntiAFK() end end)
AutoWhistleToggle:OnChanged(function(value) if value then startAutoWhistle() else stopAutoWhistle() end end)

Tabs.Main:AddSection("Player Modification")
local FlyToggle = Tabs.Main:AddToggle("FlyToggle", { Title = "Fly", Default = false })
local FlySpeedInput = Tabs.Main:AddInput("FlySpeedInput", {
    Title = "Fly Speed", Default = "50", Placeholder = "Enter speed value", Numeric = true, Finished = false,
    Callback = function(Value) if Value and tonumber(Value) then featureStates.FlySpeed = tonumber(Value) end end
})

local flying = false
local bodyVelocity = nil
local bodyGyro = nil
local character = LocalPlayer.Character
local humanoid = character and character:FindFirstChild("Humanoid")
local rootPart = character and character:FindFirstChild("HumanoidRootPart")

featureStates.FlySpeed = 50

local function startFlying()
    if not character or not humanoid or not rootPart then return end
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
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then direction = direction + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end
    local speed = featureStates.FlySpeed or 50
    bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (speed * 2) or Vector3.new(0, 0, 0)
    bodyGyro.CFrame = cameraCFrame
end

local flyLoop = nil

FlyToggle:OnChanged(function(state)
    if state then
        character = LocalPlayer.Character
        if character then
            humanoid = character:FindFirstChild("Humanoid")
            rootPart = character:FindFirstChild("HumanoidRootPart")
        end
        startFlying()
        if not flyLoop then
            flyLoop = RunService.RenderStepped:Connect(function() if Options.FlyToggle.Value then updateFly() end end)
        end
    else
        stopFlying()
        if flyLoop then flyLoop:Disconnect() flyLoop = nil end
    end
end)

local NoclipToggle = Tabs.Main:AddToggle("NoclipToggle", { Title = "Noclip", Default = false })
local noclipConnection = nil
NoclipToggle:OnChanged(function(state)
    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end)

local MiscTab = Window:AddTab({ Title = "Misc", Icon = "solar/list-bold" })
MiscTab:AddSection("Gravity")
local GravityToggle = MiscTab:AddToggle("GravityToggle", { Title = "Gravity", Default = false })
local GravityInput = MiscTab:AddInput("GravityInput", { Title = "Gravity Value", Default = "10", Numeric = true })
GravityToggle:OnChanged(function(state)
    if state then workspace.Gravity = tonumber(GravityInput.Value) or 10
    else workspace.Gravity = 196.2 end
end)
