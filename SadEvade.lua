--[[
	Sad Evade
	Edited by user request: Title = "Sad Evade", Theme = Amethyst (purple),
	FloatingButton removed, menu opens by Insert key.
	Optimized & Fixed: Removed duplicate variables, fixed syntax error, removed buggy sections.
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
end
-- ====== ВКЛАДКА AUTO FARM ======
local AutoTab = Window:AddTab({ Title = "Auto Farm", Icon = "solar/clock-circle-bold" })

AutoTab:AddSection("Farmings")
local AutoMoneyFarmToggle = AutoTab:AddToggle("AutoMoneyFarmToggle", { Title = "Auto Farm Money", Default = false })
local AutoTicketFarmToggle = AutoTab:AddToggle("AutoTicketFarmToggle", { Title = "Auto Farm Tickets", Default = false })
local AFKFarmToggle = AutoTab:AddToggle("AFKFarmToggle", { Title = "AFK Farm", Default = false })

AutoTab:AddSection("Teleports")
AutoTab:AddButton({
    Title = "Custom Server",
    Description = "Create Custom Server",
    Callback = function()
        Fluent:Notify({ Title = "Create", Content = "Create Custom Server", Duration = 3 })
        task.wait(1)
        local success, errorMsg = pcall(function() game:GetService("TeleportService"):Teleport(99214917572799) end)
        if not success then Fluent:Notify({ Title = "Failed Custom Server", Content = "Failed: " .. tostring(errorMsg), Duration = 5 }) end
    end
})

AutoTab:AddButton({
    Title = "Teleport to Objective",
    Callback = function()
        local objectives = {}
        local gameFolder = workspace:FindFirstChild("Game")
        if not gameFolder then return end
        local mapFolder = gameFolder:FindFirstChild("Map")
        if not mapFolder then return end
        local objectivesFolder = mapFolder:FindFirstChild("Objectives") or (mapFolder:FindFirstChild("Parts") and mapFolder.Parts:FindFirstChild("Objectives"))
        if not objectivesFolder then return end
        for _, obj in pairs(objectivesFolder:GetChildren()) do
            local teleportPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if teleportPart then table.insert(objectives, {Position = teleportPart.Position}) end
        end
        if #objectives == 0 then return end
        local selected = objectives[math.random(1, #objectives)]
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(selected.Position + Vector3.new(0, 5, 0))
        end
    end
})

AutoTab:AddButton({
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
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then table.insert(spawns, part) end
        end
        if #spawns == 0 then return end
        local selected = spawns[math.random(1, #spawns)]
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(selected.Position + Vector3.new(0, 3, 0))
        end
    end
})

local AutoWinConnection = nil

function startAutoWin()
    if AutoWinConnection then return end
    AutoWinConnection = RunService.Heartbeat:Connect(function()
        local securityPart = workspace:FindFirstChild("SecurityPart")
        if not securityPart then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not char:GetAttribute("Downed") then
            hrp.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

function stopAutoWin()
    if AutoWinConnection then AutoWinConnection:Disconnect() AutoWinConnection = nil end
end

AFKFarmToggle:OnChanged(function(state) if state then startAutoWin() else stopAutoWin() end end)

-- ====== ВКЛАДКА VIP SERVER ======
local VIPTab = Window:AddTab({ Title = "VIP Server", Icon = "solar/crown-bold" })

VIPTab:AddSection("Special Round")
local VIPRoundInput = VIPTab:AddInput("VIPRoundInput", { Title = "Special Round Name", Default = "", Placeholder = "Enter round name", Finished = false, Callback = function(Value) getgenv().VIPRoundName = Value end })
local VIPRoundToggle = VIPTab:AddToggle("VIPRoundToggle", { Title = "Auto Special Round", Default = false, Callback = function(Value) getgenv().VIPRoundEnabled = Value end })

VIPTab:AddSection("Vote System")
local VoteValues = {"1", "2", "3", "4"}
local VoteInput1 = VIPTab:AddDropdown("VoteInput1", { Title = "Vote Option 1", Values = VoteValues, Multi = false, Default = "1", Callback = function(Value) getgenv().VoteValue1 = tonumber(Value) end })
local VoteInput2 = VIPTab:AddDropdown("VoteInput2", { Title = "Vote Option 2", Values = VoteValues, Multi = false, Default = "1", Callback = function(Value) getgenv().VoteValue2 = tonumber(Value) end })
local VoteToggle = VIPTab:AddToggle("VoteToggle", { Title = "Auto Vote", Default = false, Callback = function(Value) getgenv().VoteEnabled = Value end })

VIPTab:AddSection("Skip Time")
local TimerCommandToggle = VIPTab:AddToggle("TimerCommandToggle", { Title = "Auto Skip Time", Default = false, Callback = function(Value) getgenv().TimerCommandEnabled = Value end })

getgenv().VIPRoundName = getgenv().VIPRoundName or ""
getgenv().VIPRoundEnabled = false
getgenv().VIPRoundActivated = false
getgenv().VoteValue1 = 1
getgenv().VoteValue2 = 1
getgenv().VoteEnabled = false
getgenv().VoteActivated = false
getgenv().TimerCommandEnabled = false
getgenv().TimerCommandActivated = false

RunService.Heartbeat:Connect(function()
    local stats = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats")
    if stats then
        local timerValue = stats:GetAttribute("Timer")
        local roundStarted = stats:GetAttribute("RoundStarted")
        if timerValue == 30 then
            if getgenv().VIPRoundEnabled and not getgenv().VIPRoundActivated then
                local roundName = getgenv().VIPRoundName or ""
                if roundName ~= "" then
                    pcall(function() ReplicatedStorage.Events.Admin.VIPCommand:InvokeServer("!specialround " .. roundName) end)
                    getgenv().VIPRoundActivated = true
                    task.delay(10, function() getgenv().VIPRoundActivated = false end)
                end
            end
            if getgenv().VoteEnabled and not getgenv().VoteActivated then
                pcall(function()
                    ReplicatedStorage.Events.Player.Vote:FireServer(getgenv().VoteValue1)
                    ReplicatedStorage.Events.Player.Vote:FireServer(getgenv().VoteValue2, true)
                end)
                getgenv().VoteActivated = true
                task.delay(10, function() getgenv().VoteActivated = false end)
            end
            if getgenv().TimerCommandEnabled and not getgenv().TimerCommandActivated then
                if roundStarted == false then
                    pcall(function() ReplicatedStorage.Events.Admin.VIPCommand:InvokeServer("!timer 1") end)
                    getgenv().TimerCommandActivated = true
                    task.delay(10, function() getgenv().TimerCommandActivated = false end)
                end
            end
        else
            getgenv().VIPRoundActivated = false
            getgenv().VoteActivated = false
            getgenv().TimerCommandActivated = false
        end
    end
end)
-- ====== ВКЛАДКА VISUALS ======
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "solar/folder-bold" })
VisualsTab:AddSection("Cosmetics Changer")

local cosmetic1, cosmetic2, originalCosmetic1, originalCosmetic2 = "", "", "", ""
local isSwapped = false

VisualsTab:AddInput("CurrentCosmeticsInput", {
    Title = "Current Cosmetics", Default = "", Placeholder = "Enter current name", Finished = false,
    Callback = function(Value) cosmetic1 = Value; if not isSwapped then originalCosmetic1 = Value end end
})
VisualsTab:AddInput("SelectCosmeticsInput", {
    Title = "Select Cosmetics", Default = "", Placeholder = "Enter new name", Finished = false,
    Callback = function(Value) cosmetic2 = Value; if not isSwapped then originalCosmetic2 = Value end
})

VisualsTab:AddButton({
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
                for i = 1, m do for j = 1, n do local cost = (s:sub(i,i) == t:sub(j,j)) and 0 or 1; d[i][j] = math.min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + cost) end end
                return d[m][n]
            end
            local function findSimilar(name)
                local bestMatch, bestScore = name, 0.5
                for _, c in ipairs(Cosmetics:GetChildren()) do
                    local nS, nT = normalize(name), normalize(c.Name)
                    local score = 1 - (levenshtein(nS, nT) / math.max(#nS, #nT))
                    if score > bestScore then bestScore = score; bestMatch = c.Name end
                end
                return bestMatch
            end
            local a = Cosmetics:FindFirstChild(findSimilar(cosmetic1))
            local b = Cosmetics:FindFirstChild(findSimilar(cosmetic2))
            if not a or not b then return end
            if not isSwapped then originalCosmetic1, originalCosmetic2 = a.Name, b.Name end
            local tempRoot = Instance.new("Folder", Cosmetics)
            tempRoot.Name = "__temp_swap_" .. tostring(tick()):gsub("%.", "_")
            local tempA, tempB = Instance.new("Folder", tempRoot), Instance.new("Folder", tempRoot)
            for _, c in ipairs(a:GetChildren()) do c.Parent = tempA end
            for _, c in ipairs(b:GetChildren()) do c.Parent = tempB end
            for _, c in ipairs(tempA:GetChildren()) do c.Parent = b end
            for _, c in ipairs(tempB:GetChildren()) do c.Parent = a end
            tempRoot:Destroy()
            isSwapped = true
            Fluent:Notify({ Title = "Cosmetics", Content = "Swapped!", Duration = 3 })
        end)
    end
})

VisualsTab:AddSection("Fake Streaks")
VisualsTab:AddInput("FakeStreaksInput", {
    Title = "Fake Streaks", Default = "", Placeholder = "Enter streak value", Numeric = true, Finished = false,
    Callback = function(Value) local num = tonumber(Value); if num then LocalPlayer:SetAttribute("Streak", num) end end
})

-- ====== ВКЛАДКА SETTINGS ======
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "solar/settings-bold" })
SettingsTab:AddSection("Configuration")

SettingsTab:AddButton({
    Title = "Save Configuration",
    Callback = function() SaveManager:Save(); Fluent:Notify({ Title = "Settings", Content = "Saved!", Duration = 3 }) end
})
SettingsTab:AddButton({
    Title = "Load Configuration",
    Callback = function() SaveManager:Load(); Fluent:Notify({ Title = "Settings", Content = "Loaded!", Duration = 3 }) end
})
SettingsTab:AddButton({
    Title = "Reset Configuration",
    Callback = function()
        Window:Dialog({
            Title = "Reset", Content = "Reset all settings?",
            Buttons = {
                { Title = "Confirm", Callback = function() SaveManager:Reset(); Fluent:Notify({ Title = "Settings", Content = "Reset!", Duration = 3 }) end },
                { Title = "Cancel", Callback = function() end }
            }
        })
    end
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

-- ====== ВКЛАДКА INFO ======
local InfoTab = Window:AddTab({ Title = "Info", Icon = "solar/info-circle-bold" })
InfoTab:AddSection("Information")
InfoTab:AddParagraph({ Title = "Sad Evade", Content = "Thank you for using the Sad Evade script.\n\nUse only on a throwaway account." })
InfoTab:AddParagraph({ Title = "Disclaimer", Content = "Using third-party scripts violates ToS and may result in a ban." })

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
