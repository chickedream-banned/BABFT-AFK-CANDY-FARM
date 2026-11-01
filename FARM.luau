local SCRIPT_SOURCE = [==[
repeat task.wait(0.1) until game:IsLoaded()
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Teams = game:GetService("Teams")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
if not player then
repeat task.wait(0.1) player = Players.LocalPlayer until player
end
local existingGui = CoreGui:FindFirstChild("BABFT_CandyFarm") or (player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("BABFT_CandyFarm"))
if existingGui then
pcall(function() existingGui:Destroy() end)
end
getgenv().BABFT_FarmActiveInstance = true
local existingBlur = Lighting:FindFirstChild("BABFT_FarmBlur")
if existingBlur then existingBlur:Destroy() end
local targetParent = nil
pcall(function()
if gethui then targetParent = gethui() elseif CoreGui then targetParent = CoreGui end
end)
if not targetParent then targetParent = player:WaitForChild("PlayerGui", 25) end
local stateFilePath = "BABFT_FarmState.json"
local visitedPath = "BABFT_VisitedServers.json"
local function loadSettings()
if readfile and isfile and isfile(stateFilePath) then
local s, res = pcall(function() return HttpService:JSONDecode(readfile(stateFilePath)) end)
if s and type(res) == "table" then return res end
end
return nil
end
local savedSettings = loadSettings() or {}
local isRunning = false
local isGoldRunning = savedSettings.goldEnabled or false
local farmStartTime = savedSettings.startTime or 0
local housesCount = savedSettings.housesCount or 0
local goldRunsCount = savedSettings.goldRunsCount or 0
local totalGoldEarned = savedSettings.totalGoldEarned or 0
local stageDelay = savedSettings.stageDelay or 1.6
local soundMuted = savedSettings.soundMuted or false
local optEnabled = savedSettings.optEnabled or false
local antiAfkEnabled = (savedSettings.antiAfkEnabled ~= nil) and savedSettings.antiAfkEnabled or true
local walkOnWaterEnabled = savedSettings.walkOnWaterEnabled or false
local godModeEnabled = savedSettings.godModeEnabled or false
local infJumpEnabled = savedSettings.infJumpEnabled or false
local noclipEnabled = false
local flyEnabled = false
local espEnabled = savedSettings.espEnabled or false
local fullbrightEnabled = savedSettings.fullbrightEnabled or false
local boatBoostEnabled = false
local autoChestEnabled = false
local selectedChestName = savedSettings.selectedChestName or "Common Chest"
local selectedChestQty = savedSettings.selectedChestQty or 1
local customWalkSpeed = savedSettings.customWalkSpeed or 16
local customJumpPower = savedSettings.customJumpPower or 50
local customFlySpeed = savedSettings.customFlySpeed or 85
local customBoatSpeed = savedSettings.customBoatSpeed or 150
local speedLockEnabled = false
local selectedBlockType = "WoodBlock"
local sphereRadius = 7
local sphereHollow = true
local selectedBasePlayer = nil
local copiedBuildData = nil
local isBuildingBusy = false
local farmThread = nil
local goldFarmThread = nil
local isHopping = false
local function create(className, props, parent)
local inst = Instance.new(className)
for k, v in pairs(props) do inst[k] = v end
if parent then inst.Parent = parent end
return inst
end
local screenGui = create("ScreenGui", { Name = "BABFT_CandyFarm", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, targetParent)
local vfxBlur = create("BlurEffect", { Name = "BABFT_FarmBlur", Size = 0 }, Lighting)
local function triggerMotionBlur(peakSize, duration)
task.spawn(function()
local tIn = TweenService:Create(vfxBlur, TweenInfo.new(duration * 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = peakSize })
tIn:Play()
tIn.Completed:Wait()
TweenService:Create(vfxBlur, TweenInfo.new(duration * 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = 0 }):Play()
end)
end
local defaultPos = UDim2.new(0.5, 0, 0.48, 0)
if savedSettings.posX and savedSettings.posY then
defaultPos = UDim2.new(savedSettings.posX.Scale or 0.5, savedSettings.posX.Offset or 0, savedSettings.posY.Scale or 0.48, savedSettings.posY.Offset or 0)
end
local windowRoot = create("Frame", { Name = "WindowRoot", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 320, 0, 220), Position = defaultPos, BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ZIndex = 1 }, screenGui)
local function saveCurrentSettings()
if writefile then
local data = {
enabled = isRunning, goldEnabled = isGoldRunning, startTime = farmStartTime, housesCount = housesCount,
goldRunsCount = goldRunsCount, totalGoldEarned = totalGoldEarned, stageDelay = stageDelay,
soundMuted = soundMuted, optEnabled = optEnabled, antiAfkEnabled = antiAfkEnabled,
walkOnWaterEnabled = walkOnWaterEnabled, godModeEnabled = godModeEnabled, infJumpEnabled = infJumpEnabled,
espEnabled = espEnabled, fullbrightEnabled = fullbrightEnabled, selectedChestName = selectedChestName,
selectedChestQty = selectedChestQty, customWalkSpeed = customWalkSpeed, customJumpPower = customJumpPower,
customFlySpeed = customFlySpeed, customBoatSpeed = customBoatSpeed,
posX = { Scale = windowRoot.Position.X.Scale, Offset = windowRoot.Position.X.Offset },
posY = { Scale = windowRoot.Position.Y.Scale, Offset = windowRoot.Position.Y.Offset }
}
pcall(function() writefile(stateFilePath, HttpService:JSONDecode(data)) end)
end
end
local function applySoundSetting(muted)
soundMuted = muted
pcall(function() game:GetService("SoundService").Volume = muted and 0 or 1 end)
pcall(function()
local ugs = UserSettings():GetService("UserGameSettings")
if ugs then ugs.MasterVolume = muted and 0 or 1 end
end)
for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA("Sound") then pcall(function() obj.Volume = muted and 0 or 0.5 end) end
end
end
Workspace.DescendantAdded:Connect(function(obj)
if soundMuted and obj:IsA("Sound") then pcall(function() obj.Volume = 0 end) end
end)
local function applyOptSetting(enabled)
optEnabled = enabled
pcall(function() RunService:Set3dRenderingEnabled(not enabled) end)
pcall(function() if setfpscap then setfpscap(enabled and 15 or 60) end end)
pcall(function()
Lighting.GlobalShadows = not enabled
Lighting.Brightness = enabled and 0 or 2
if enabled then Lighting.FogEnd = 9e9 end
end)
pcall(function()
local terrain = Workspace:FindFirstChildOfClass("Terrain")
if terrain then terrain.Decoration = not enabled end
end)
end
local glowHolder = create("Frame", { Name = "GlowHolder", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 1 }, windowRoot)
local glowGradients = {}
local gradSeq = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 0)),
ColorSequenceKeypoint.new(0.3, Color3.fromRGB(180, 0, 255)),
ColorSequenceKeypoint.new(0.65, Color3.fromRGB(0, 185, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0))
})
local softShadow = create("ImageLabel", { Name = "SoftShadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 64, 1, 64), BackgroundTransparency = 1, Image = "rbxassetid://6015897843", ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1 }, glowHolder)
table.insert(glowGradients, create("UIGradient", { Color = gradSeq }, softShadow))
for _, layer in ipairs({ {2, 0.2}, {6, 0.4}, {11, 0.65}, {18, 0.8}, {26, 0.92} }) do
local lf = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 1 }, glowHolder)
create("UICorner", { CornerRadius = UDim.new(0, 14) }, lf)
local st = create("UIStroke", { Thickness = layer[1], Transparency = layer[2], ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.new(1, 1, 1) }, lf)
table.insert(glowGradients, create("UIGradient", { Color = gradSeq }, st))
end
local glowConnection = RunService.RenderStepped:Connect(function()
local rot = (tick() * 100) % 360
for _, grad in ipairs(glowGradients) do grad.Rotation = rot end
end)
local mainFrame = create("CanvasGroup", { Name = "MainFrame", Size = UDim2.new(1, 0, 1, 0), GroupTransparency = 1, BackgroundColor3 = Color3.fromRGB(14, 14, 18), BorderSizePixel = 0, Active = true, ZIndex = 5 }, windowRoot)
create("UICorner", { CornerRadius = UDim.new(0, 14) }, mainFrame)
local titleBar = create("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(20, 20, 26), BorderSizePixel = 0, ZIndex = 6 }, mainFrame)
create("TextLabel", { Name = "TitleLabel", Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = "BABFT SWISS ARMY HUB | Chickedream", TextColor3 = Color3.fromRGB(245, 245, 250), TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }, titleBar)
local minBtn = create("TextButton", { Name = "MinButton", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -62, 0, 6), BackgroundColor3 = Color3.fromRGB(32, 32, 42), BorderSizePixel = 0, Text = "-", TextColor3 = Color3.fromRGB(210, 210, 220), TextSize = 14, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 8 }, titleBar)
create("UICorner", { CornerRadius = UDim.new(0, 7) }, minBtn)
local closeBtn = create("TextButton", { Name = "CloseButton", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -32, 0, 6), BackgroundColor3 = Color3.fromRGB(48, 22, 26), BorderSizePixel = 0, Text = "X", TextColor3 = Color3.fromRGB(255, 140, 150), TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 8 }, titleBar)
create("UICorner", { CornerRadius = UDim.new(0, 7) }, closeBtn)
local sidebar = create("Frame", { Name = "Sidebar", Size = UDim2.new(0, 118, 1, -36), Position = UDim2.new(0, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(18, 18, 24), BorderSizePixel = 0, ZIndex = 6 }, mainFrame)
create("UIListLayout", { Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
create("UIPadding", { PaddingTop = UDim.new(0, 10) }, sidebar)
local pageContainer = create("Frame", { Name = "PageContainer", Size = UDim2.new(1, -118, 1, -36), Position = UDim2.new(0, 118, 0, 36), BackgroundTransparency = 1, ZIndex = 6 }, mainFrame)
local pages = {}
local tabButtons = {}
local function switchTab(name)
for k, p in pairs(pages) do p.Visible = (k == name) end
for k, b in pairs(tabButtons) do
TweenService:Create(b, TweenInfo.new(0.2), {
BackgroundColor3 = (k == name) and Color3.fromRGB(38, 46, 68) or Color3.fromRGB(24, 24, 32),
TextColor3 = (k == name) and Color3.fromRGB(130, 195, 255) or Color3.fromRGB(160, 165, 180)
}):Play()
end
end
local tabList = { { "Farms", "AUTO FARMS" }, { "Player", "PLAYER & BOAT" }, { "World", "WORLD & TEAMS" }, { "Shop", "SHOP & QUESTS" }, { "Builder", "BUILD & CLONE" }, { "System", "SYSTEM & HOP" } }
for idx, t in ipairs(tabList) do
local page = create("ScrollingFrame", { Name = t[1] .. "Page", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(90, 120, 255), Visible = false, ZIndex = 7 }, pageContainer)
local layout = create("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, page)
create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, page)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24) end)
pages[t[1]] = page
local tBtn = create("TextButton", { Name = t[1] .. "Tab", LayoutOrder = idx, Size = UDim2.new(1, -14, 0, 32), BackgroundColor3 = Color3.fromRGB(24, 24, 32), BorderSizePixel = 0, Text = t[2], TextColor3 = Color3.fromRGB(160, 165, 180), TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 7 }, sidebar)
create("UICorner", { CornerRadius = UDim.new(0, 7) }, tBtn)
tBtn.MouseButton1Click:Connect(function() switchTab(t[1]) end)
tabButtons[t[1]] = tBtn
end
local function createHeader(parent, text, order)
return create("TextLabel", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(115, 145, 215), TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, parent)
end
local function createBtn(parent, text, bg, tc, order, cb)
local b = create("TextButton", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = bg or Color3.fromRGB(26, 30, 40), BorderSizePixel = 0, Text = text, TextColor3 = tc or Color3.fromRGB(220, 225, 240), TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 8 }, parent)
create("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
local s = create("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.fromRGB(48, 56, 75) }, b)
b.MouseButton1Click:Connect(function() cb(b, s) end)
return b, s
end
local function createRow(parent, t1, cb1, t2, cb2, order)
local row = create("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 8 }, parent)
local b1 = create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Color3.fromRGB(25, 30, 40), BorderSizePixel = 0, Text = t1, TextColor3 = Color3.fromRGB(205, 215, 235), TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 8 }, row)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, b1)
local s1 = create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(45, 55, 75) }, b1)
local b2 = create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), Position = UDim2.new(0.5, 3, 0, 0), BackgroundColor3 = Color3.fromRGB(25, 30, 40), BorderSizePixel = 0, Text = t2, TextColor3 = Color3.fromRGB(205, 215, 235), TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 8 }, row)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, b2)
local s2 = create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(45, 55, 75) }, b2)
b1.MouseButton1Click:Connect(function() cb1(b1, s1) end)
b2.MouseButton1Click:Connect(function() cb2(b2, s2) end)
return b1, b2, s1, s2
end
local function styleToggle(btn, stroke, label, state)
btn.Text = label .. (state and ": ON" or ": OFF")
btn.BackgroundColor3 = state and Color3.fromRGB(22, 44, 32) or Color3.fromRGB(25, 30, 40)
btn.TextColor3 = state and Color3.fromRGB(120, 245, 155) or Color3.fromRGB(185, 195, 215)
if stroke then stroke.Color = state and Color3.fromRGB(45, 110, 68) or Color3.fromRGB(45, 55, 75) end
end
createHeader(pages.Farms, "DASHBOARD & STATS", 1)
local statsGrid = create("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, ZIndex = 8 }, pages.Farms)
local timerLabel = create("TextLabel", { Name = "TimerLabel", Size = UDim2.new(0.5, -3, 0, 20), BackgroundColor3 = Color3.fromRGB(20, 22, 30), BorderSizePixel = 0, Text = "Time: 00:00:00", TextColor3 = Color3.fromRGB(150, 205, 255), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, statsGrid)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, timerLabel)
local housesLabel = create("TextLabel", { Name = "HousesLabel", Size = UDim2.new(0.5, -3, 0, 20), Position = UDim2.new(0.5, 3, 0, 0), BackgroundColor3 = Color3.fromRGB(20, 22, 30), BorderSizePixel = 0, Text = "Houses: 0", TextColor3 = Color3.fromRGB(255, 205, 120), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, statsGrid)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, housesLabel)
local goldStatsLabel = create("TextLabel", { Name = "GoldStatsLabel", Size = UDim2.new(0.5, -3, 0, 20), Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = Color3.fromRGB(20, 22, 30), BorderSizePixel = 0, Text = "Gold Runs: 0", TextColor3 = Color3.fromRGB(255, 235, 110), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, statsGrid)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, goldStatsLabel)
local gphLabel = create("TextLabel", { Name = "GphLabel", Size = UDim2.new(0.5, -3, 0, 20), Position = UDim2.new(0.5, 3, 0, 24), BackgroundColor3 = Color3.fromRGB(20, 22, 30), BorderSizePixel = 0, Text = "Est Gold: 0", TextColor3 = Color3.fromRGB(130, 245, 165), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, statsGrid)
create("UICorner", { CornerRadius = UDim.new(0, 5) }, gphLabel)
createHeader(pages.Farms, "HALLOWEEN CANDY FARM (30s HOP)", 3)
local toggleBtn, toggleStroke = createBtn(pages.Farms, "START CANDY FARM", Color3.fromRGB(24, 32, 38), Color3.fromRGB(120, 235, 140), 4, function() end)
createHeader(pages.Farms, "OP RIVER GOLD & TREASURE FARM", 5)
local goldFarmBtn, goldFarmStroke = createBtn(pages.Farms, "START GOLD FARM", Color3.fromRGB(24, 32, 38), Color3.fromRGB(255, 220, 110), 6, function() end)
local delayLabel = create("TextLabel", { LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.format("Stage Teleport Delay: %.1fs per stage", stageDelay), TextColor3 = Color3.fromRGB(185, 195, 215), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, pages.Farms)
createRow(pages.Farms, "STAGE DELAY -0.2s", function()
stageDelay = math.max(0.4, math.floor((stageDelay - 0.2) * 10 + 0.5) / 10)
delayLabel.Text = string.format("Stage Teleport Delay: %.1fs per stage", stageDelay)
saveCurrentSettings()
end, "STAGE DELAY +0.2s", function()
stageDelay = math.min(4.0, math.floor((stageDelay + 0.2) * 10 + 0.5) / 10)
delayLabel.Text = string.format("Stage Teleport Delay: %.1fs per stage", stageDelay)
saveCurrentSettings()
end, 8)
createBtn(pages.Farms, "INSTANT CLAIM CHEST + RIVER GOLD", Color3.fromRGB(30, 36, 52), Color3.fromRGB(165, 210, 255), 9, function()
pcall(function()
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
local ns = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
local trig = ns and ns:FindFirstChild("TheEnd") and ns.TheEnd:FindFirstChild("GoldenChest") and ns.TheEnd.GoldenChest:FindFirstChild("Trigger")
if hrp and trig then
hrp.CFrame = trig.CFrame
if firetouchinterest then firetouchinterest(hrp, trig, 0) firetouchinterest(hrp, trig, 1) end
end
if Workspace:FindFirstChild("ClaimRiverResultsGold") then Workspace.ClaimRiverResultsGold:FireServer() end
end)
end)
local function updateTimerDisplay()
if (isRunning or isGoldRunning) and farmStartTime > 0 then
local elapsed = os.time() - farmStartTime
timerLabel.Text = string.format("Time: %02d:%02d:%02d", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60)
else
timerLabel.Text = "Time: 00:00:00"
end
housesLabel.Text = string.format("Houses: %d", housesCount)
goldStatsLabel.Text = string.format("Gold Runs: %d", goldRunsCount)
gphLabel.Text = string.format("Est Gold: %d", totalGoldEarned)
end
task.spawn(function()
while screenGui and screenGui.Parent do updateTimerDisplay() task.wait(1) end
end)
local autoExecPaths = { "autoexec/BABFT_CandyFarm_Auto.lua", "autoexecute/BABFT_CandyFarm_Auto.lua" }
local persistentLoader = [=[
repeat task.wait(0.2) until game:IsLoaded()
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer or plrs:GetPropertyChangedSignal("LocalPlayer"):Wait()
if not lp then repeat task.wait(0.2) lp = plrs.LocalPlayer until lp end
lp:WaitForChild("PlayerGui", 30)
task.wait(1)
pcall(function()
if readfile and isfile and isfile("BABFT_Farm_Chickedream.lua") then
loadstring(readfile("BABFT_Farm_Chickedream.lua"))()
end
end)
]=]
local function installAutoExec()
for _, dir in ipairs({"autoexec", "autoexecute"}) do
pcall(function() if makefolder and isfolder and not isfolder(dir) then makefolder(dir) end end)
end
for _, path in ipairs(autoExecPaths) do
pcall(function() if writefile then writefile(path, persistentLoader) end end)
end
end
local function removeAutoExec()
for _, path in ipairs(autoExecPaths) do
pcall(function() if delfile and isfile and isfile(path) then delfile(path) end end)
end
end
local function getCleanVisited()
local list = (getgenv().BABFT_VisitedList and type(getgenv().BABFT_VisitedList) == "table") and getgenv().BABFT_VisitedList or {}
local now = os.time()
if readfile and isfile and isfile(visitedPath) then
pcall(function()
local decoded = HttpService:JSONDecode(readfile(visitedPath))
if type(decoded) == "table" then for k, v in pairs(decoded) do list[k] = v end end
end)
end
local cleaned = {}
for id, t in pairs(list) do
if type(t) == "number" and (now - t) < 1200 then cleaned[id] = t end
end
cleaned[game.JobId] = now
getgenv().BABFT_VisitedList = cleaned
if writefile then pcall(function() writefile(visitedPath, HttpService:JSONEncode(cleaned)) end) end
return cleaned
end
local function markVisited(jobId)
local visited = getCleanVisited()
visited[jobId] = os.time()
getgenv().BABFT_VisitedList = visited
if writefile then pcall(function() writefile(visitedPath, HttpService:JSONEncode(visited)) end) end
end
local function queueNextHop()
local qot = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
if qot then pcall(function() qot(persistentLoader) end) end
end
local function requestHttp(url)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if httpRequest then
local res = httpRequest({ Url = url, Method = "GET" })
if type(res) == "table" and res.Body then return res.Body end
end
return game:HttpGet(url)
end
local function findDistinctServer()
local placeId = game.PlaceId
local currentJobId = game.JobId
local visited = getCleanVisited()
for _, sortOrder in ipairs({"Asc", "Desc"}) do
local cursor = ""
local pagesChecked = 0
while pagesChecked < 4 do
pagesChecked = pagesChecked + 1
local proto = "https" .. "://" .. "games." .. "roblox." .. "com/v1/games/"
local url = proto .. tostring(placeId) .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100" .. (cursor ~= "" and ("&cursor=" .. cursor) or "")
local success, raw = pcall(requestHttp, url)
if success and raw and #raw > 10 then
local parseSuccess, data = pcall(function() return HttpService:JSONDecode(raw) end)
if parseSuccess and data and data.data then
local pool = {}
for _, s in ipairs(data.data) do
if type(s) == "table" and s.id and s.id ~= currentJobId and not visited[s.id] and s.playing and s.maxPlayers then
if (s.maxPlayers - s.playing) >= 1 and s.playing > 0 then table.insert(pool, s.id) end
end
end
if #pool > 0 then return pool[math.random(1, #pool)] end
if data.nextPageCursor and data.nextPageCursor ~= "" then cursor = data.nextPageCursor else break end
end
end
end
end
return nil
end
local function serverHop()
if isHopping then return end
isHopping = true
installAutoExec()
queueNextHop()
markVisited(game.JobId)
saveCurrentSettings()
local placeId = game.PlaceId
local currentJob = game.JobId
local chosenTarget = nil
local attempts = 0
while attempts < 5 and not chosenTarget do
attempts = attempts + 1
chosenTarget = findDistinctServer()
if not chosenTarget then task.wait(1.5) end
end
if not chosenTarget then
local freshVisited = { [currentJob] = os.time() }
getgenv().BABFT_VisitedList = freshVisited
if writefile then pcall(function() writefile(visitedPath, HttpService:JSONEncode(freshVisited)) end) end
chosenTarget = findDistinctServer()
end
if not chosenTarget then
isHopping = false
task.wait(2)
return serverHop()
end
markVisited(chosenTarget)
local initFailedConn
pcall(function()
if TeleportService.TeleportInitFailed then
initFailedConn = TeleportService.TeleportInitFailed:Connect(function()
if initFailedConn then pcall(function() initFailedConn:Disconnect() end) end
isHopping = false
task.wait(1)
serverHop()
end)
end
end)
task.spawn(function()
task.wait(12)
if isHopping and game.JobId == currentJob then
if initFailedConn then pcall(function() initFailedConn:Disconnect() end) end
isHopping = false
serverHop()
end
end)
pcall(function() TeleportService:TeleportToPlaceInstance(placeId, chosenTarget, player) end)
end
local function getTargetCFrame(instance)
if instance:IsA("BasePart") then return instance.CFrame elseif instance:IsA("Model") then return instance:GetPivot() end
return nil
end
local function teleportExact(targetCFrame)
local character = player.Character
local rootPart = character and character:FindFirstChild("HumanoidRootPart")
if not rootPart then return end
rootPart.AssemblyLinearVelocity = Vector3.zero
rootPart.AssemblyAngularVelocity = Vector3.zero
character:PivotTo(targetCFrame)
end
local function scanDoors()
local found = {}
local housesFolder = Workspace:FindFirstChild("Houses")
if not housesFolder then return found end
for _, obj in ipairs(housesFolder:GetDescendants()) do
if obj.Name == "Door" and obj.Parent and obj.Parent.Name == "TrickOrTreatHouse" then
table.insert(found, obj)
end
end
return found
end
local function runFarmLoop()
local serverArrivedTime = tick()
local visitedHousesOnServer = {}
while isRunning do
local housesFolder = Workspace:FindFirstChild("Houses")
local doors = scanDoors()
local isEmpty = not housesFolder or #housesFolder:GetChildren() == 0 or #doors == 0
if isEmpty then
task.wait(1.5)
doors = scanDoors()
housesFolder = Workspace:FindFirstChild("Houses")
isEmpty = not housesFolder or #housesFolder:GetChildren() == 0 or #doors == 0
if isEmpty and isRunning then
toggleBtn.Text = "HOPPING SERVER..."
toggleBtn.TextColor3 = Color3.fromRGB(255, 205, 110)
serverHop()
break
end
else
if (tick() - serverArrivedTime) >= 30 and isRunning then
toggleBtn.Text = "TIMEOUT (30s) -> HOPPING..."
toggleBtn.TextColor3 = Color3.fromRGB(255, 205, 110)
serverHop()
break
end
for _, door in ipairs(doors) do
if not isRunning then break end
if (tick() - serverArrivedTime) >= 30 and isRunning then
toggleBtn.Text = "TIMEOUT (30s) -> HOPPING..."
toggleBtn.TextColor3 = Color3.fromRGB(255, 205, 110)
serverHop()
return
end
if door and door.Parent then
local targetCFrame = getTargetCFrame(door)
if targetCFrame then
local houseObj = door.Parent
if not visitedHousesOnServer[houseObj] then
visitedHousesOnServer[houseObj] = true
housesCount = housesCount + 1
updateTimerDisplay()
saveCurrentSettings()
end
teleportExact(targetCFrame)
if firetouchinterest and door:IsA("BasePart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
pcall(function()
firetouchinterest(player.Character.HumanoidRootPart, door, 0)
firetouchinterest(player.Character.HumanoidRootPart, door, 1)
end)
end
end
end
task.wait(0.5)
end
end
task.wait(0.5)
end
end
local function resetPlayerCharacter()
local character = player.Character
if character then
local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid then humanoid.Health = 0 else character:BreakJoints() end
end
end
local function isCharAlive(char)
return char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and char:FindFirstChild("HumanoidRootPart")
end
local function runGoldFarmLoop()
while isGoldRunning do
repeat task.wait(0.1) until not isGoldRunning or isCharAlive(player.Character)
if not isGoldRunning then break end
local char = player.Character
local hrp = char:FindFirstChild("HumanoidRootPart")
local stages = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
local claimRemote = Workspace:FindFirstChild("ClaimRiverResultsGold")
if stages and hrp then
local supportPlat = create("Part", { Name = "BABFT_GoldSupport", Size = Vector3.new(12, 1, 12), Anchored = true, CanCollide = true, Transparency = 0.6, Color = Color3.fromRGB(255, 215, 0) }, Workspace)
for i = 1, 10 do
if not isGoldRunning or not isCharAlive(player.Character) then break end
char = player.Character
hrp = char:FindFirstChild("HumanoidRootPart")
local st = stages:FindFirstChild("CaveStage" .. i)
local dp = st and st:FindFirstChild("DarknessPart")
if dp and hrp then
goldFarmBtn.Text = string.format("GOLD FARM: STAGE %d/10", i)
local startStageTick = tick()
while (tick() - startStageTick) < stageDelay and isGoldRunning and isCharAlive(player.Character) do
hrp.AssemblyLinearVelocity = Vector3.zero
hrp.AssemblyAngularVelocity = Vector3.zero
hrp.CFrame = dp.CFrame
supportPlat.Position = hrp.Position - Vector3.new(0, 3.5, 0)
task.wait(0.05)
end
if claimRemote and isGoldRunning then pcall(function() claimRemote:FireServer() end) end
end
end
pcall(function() supportPlat:Destroy() end)
if isGoldRunning and isCharAlive(player.Character) then
goldFarmBtn.Text = "GOLD FARM: CLAIMING CHEST..."
local theEnd = stages:FindFirstChild("TheEnd")
local trig = theEnd and theEnd:FindFirstChild("GoldenChest") and theEnd.GoldenChest:FindFirstChild("Trigger")
if trig then
local waitChestTick = tick()
while (tick() - waitChestTick) < 12 and isGoldRunning and isCharAlive(player.Character) do
hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if hrp then
hrp.AssemblyLinearVelocity = Vector3.zero
hrp.CFrame = trig.CFrame
if firetouchinterest then pcall(function() firetouchinterest(hrp, trig, 0) firetouchinterest(hrp, trig, 1) end) end
end
if Lighting.ClockTime ~= 14 then break end
task.wait(0.1)
end
end
if claimRemote then pcall(function() claimRemote:FireServer() end) end
goldRunsCount = goldRunsCount + 1
totalGoldEarned = totalGoldEarned + 105
updateTimerDisplay()
saveCurrentSettings()
local respawned = false
local conn = player.CharacterAdded:Connect(function() respawned = true end)
local rTick = tick()
while not respawned and (tick() - rTick) < 14 and isGoldRunning do task.wait(0.2) end
pcall(function() conn:Disconnect() end)
task.wait(1.2)
end
else
task.wait(1)
end
end
end
local function stopGoldFarm()
isGoldRunning = false
if not isRunning then farmStartTime = 0 end
saveCurrentSettings()
updateTimerDisplay()
goldFarmBtn.Text = "START GOLD FARM"
goldFarmBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 38)
goldFarmBtn.TextColor3 = Color3.fromRGB(255, 220, 110)
goldFarmStroke.Color = Color3.fromRGB(48, 56, 75)
if goldFarmThread then pcall(function() task.cancel(goldFarmThread) end) goldFarmThread = nil end
end
local function startFarm()
if isGoldRunning then stopGoldFarm() end
isRunning = true
if farmStartTime == 0 then farmStartTime = os.time() end
saveCurrentSettings()
installAutoExec()
toggleBtn.Text = "STOP CANDY FARM"
toggleBtn.BackgroundColor3 = Color3.fromRGB(48, 22, 26)
toggleBtn.TextColor3 = Color3.fromRGB(255, 115, 115)
toggleStroke.Color = Color3.fromRGB(120, 45, 52)
farmThread = task.spawn(runFarmLoop)
end
local function stopFarm()
isRunning = false
if not isGoldRunning then farmStartTime = 0 housesCount = 0 end
saveCurrentSettings()
removeAutoExec()
updateTimerDisplay()
toggleBtn.Text = "START CANDY FARM"
toggleBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 38)
toggleBtn.TextColor3 = Color3.fromRGB(120, 235, 140)
toggleStroke.Color = Color3.fromRGB(50, 75, 60)
if farmThread then pcall(function() task.cancel(farmThread) end) farmThread = nil end
resetPlayerCharacter()
end
local function startGoldFarm()
if isRunning then stopFarm() end
isGoldRunning = true
if farmStartTime == 0 then farmStartTime = os.time() end
saveCurrentSettings()
goldFarmBtn.Text = "STOP GOLD FARM"
goldFarmBtn.BackgroundColor3 = Color3.fromRGB(48, 22, 26)
goldFarmBtn.TextColor3 = Color3.fromRGB(255, 115, 115)
goldFarmStroke.Color = Color3.fromRGB(120, 45, 52)
goldFarmThread = task.spawn(runGoldFarmLoop)
end
toggleBtn.MouseButton1Click:Connect(function() if isRunning then stopFarm() else startFarm() end end)
goldFarmBtn.MouseButton1Click:Connect(function() if isGoldRunning then stopGoldFarm() else startGoldFarm() end end
createHeader(pages.Player, "CHARACTER MOVEMENT & COMBAT", 1)
local speedLabel = create("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.format("WalkSpeed: %d | JumpPower: %d | Fly: %d", customWalkSpeed, customJumpPower, customFlySpeed), TextColor3 = Color3.fromRGB(180, 200, 230), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, pages.Player)
local function refreshSpeedText()
speedLabel.Text = string.format("WalkSpeed: %d | JumpPower: %d | Fly: %d", customWalkSpeed, customJumpPower, customFlySpeed)
saveCurrentSettings()
end
createBtn(pages.Player, "LOCK SPEED & JUMP: OFF", nil, nil, 3, function(b, s)
speedLockEnabled = not speedLockEnabled
styleToggle(b, s, "LOCK SPEED & JUMP", speedLockEnabled)
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum.WalkSpeed = speedLockEnabled and customWalkSpeed or 16
hum.UseJumpPower = true
hum.JumpPower = speedLockEnabled and customJumpPower or 50
end
end)
createRow(pages.Player, "WALKSPEED -20", function() customWalkSpeed = math.max(16, customWalkSpeed - 20) refreshSpeedText() end, "WALKSPEED +20", function() customWalkSpeed = math.min(500, customWalkSpeed + 20) refreshSpeedText() end, 4)
createRow(pages.Player, "JUMPPOWER -25", function() customJumpPower = math.max(50, customJumpPower - 25) refreshSpeedText() end, "JUMPPOWER +25", function() customJumpPower = math.min(500, customJumpPower + 25) refreshSpeedText() end, 5)
local flyBV = nil
local flyDir = { f = 0, b = 0, l = 0, r = 0, u = 0, d = 0 }
UserInputService.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.W then flyDir.f = 1 elseif input.KeyCode == Enum.KeyCode.S then flyDir.b = -1 elseif input.KeyCode == Enum.KeyCode.A then flyDir.l = -1 elseif input.KeyCode == Enum.KeyCode.D then flyDir.r = 1 elseif input.KeyCode == Enum.KeyCode.LeftControl then flyDir.d = -1 elseif input.KeyCode == Enum.KeyCode.Space then
flyDir.u = 1
if infJumpEnabled and player.Character then
local hum = player.Character:FindFirstChildOfClass("Humanoid")
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end
end)
UserInputService.InputEnded:Connect(function(input)
if input.KeyCode == Enum.KeyCode.W then flyDir.f = 0 elseif input.KeyCode == Enum.KeyCode.S then flyDir.b = 0 elseif input.KeyCode == Enum.KeyCode.A then flyDir.l = 0 elseif input.KeyCode == Enum.KeyCode.D then flyDir.r = 0 elseif input.KeyCode == Enum.KeyCode.Space then flyDir.u = 0 elseif input.KeyCode == Enum.KeyCode.LeftControl then flyDir.d = 0 end
end)
createRow(pages.Player, "FLY (WASD): OFF", function(b, s)
flyEnabled = not flyEnabled
styleToggle(b, s, "FLY (WASD)", flyEnabled)
if not flyEnabled and flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
end, "NOCLIP: OFF", function(b, s)
noclipEnabled = not noclipEnabled
styleToggle(b, s, "NOCLIP", noclipEnabled)
end, 6)
local infJumpBtn, godBtn, infJumpStroke, godStroke = createRow(pages.Player, "INF JUMP: OFF", function(b, s)
infJumpEnabled = not infJumpEnabled
styleToggle(b, s, "INF JUMP", infJumpEnabled)
saveCurrentSettings()
end, "GOD MODE: OFF", function(b, s)
godModeEnabled = not godModeEnabled
styleToggle(b, s, "GOD MODE", godModeEnabled)
saveCurrentSettings()
end, 7)
styleToggle(infJumpBtn, infJumpStroke, "INF JUMP", infJumpEnabled)
styleToggle(godBtn, godStroke, "GOD MODE", godModeEnabled)
createHeader(pages.Player, "VEHICLE & BOAT OVERDRIVE", 8)
local boatSpeedLabel = create("TextLabel", { LayoutOrder = 9, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.format("Boat Overdrive Speed: %d studs/s", customBoatSpeed), TextColor3 = Color3.fromRGB(180, 200, 230), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, pages.Player)
createBtn(pages.Player, "BOAT SPEED BOOST: OFF", nil, nil, 10, function(b, s)
boatBoostEnabled = not boatBoostEnabled
styleToggle(b, s, "BOAT SPEED BOOST", boatBoostEnabled)
if not boatBoostEnabled and player.Character then
local hum = player.Character:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart
if seat and seat.Parent then
for _, p in ipairs(seat.Parent:GetDescendants()) do
if p.Name == "BABFT_BoatBV" then pcall(function() p:Destroy() end) end
end
end
end
end)
createRow(pages.Player, "BOAT SPEED -30", function() customBoatSpeed = math.max(30, customBoatSpeed - 30) boatSpeedLabel.Text = string.format("Boat Overdrive Speed: %d studs/s", customBoatSpeed) saveCurrentSettings() end, "BOAT SPEED +30", function() customBoatSpeed = math.min(600, customBoatSpeed + 30) boatSpeedLabel.Text = string.format("Boat Overdrive Speed: %d studs/s", customBoatSpeed) saveCurrentSettings() end, 11)
createHeader(pages.Player, "CHARACTER MORPHS", 12)
createRow(pages.Player, "FOX MORPH", function() pcall(function() Workspace.ChangeCharacter:FireServer("FoxCharacter") end) end, "PENGUIN MORPH", function() pcall(function() Workspace.ChangeCharacter:FireServer("PenguinCharacter") end) end, 13)
createRow(pages.Player, "CHICKEN MORPH", function() pcall(function() Workspace.ChangeCharacter:FireServer("ChickenCharacter") end) end, "FIX / RESET SPAWN", function() resetPlayerCharacter() end, 14)
createHeader(pages.World, "ENVIRONMENT & WATER PROTECTION", 1)
local function applyWaterState(enabled)
walkOnWaterEnabled = enabled
pcall(function()
for _, obj in ipairs(Workspace:GetDescendants()) do
if obj.Name == "Water" and obj:IsA("BasePart") then
obj.CanCollide = enabled
if enabled then
local ti = obj:FindFirstChildOfClass("TouchTransmitter")
if ti then ti:Destroy() end
end
end
end
end)
end
local waterBtn, waterStroke = createBtn(pages.World, "WALK ON WATER + GOD WATER: OFF", nil, nil, 2, function(b, s)
applyWaterState(not walkOnWaterEnabled)
styleToggle(b, s, "WALK ON WATER + GOD WATER", walkOnWaterEnabled)
saveCurrentSettings()
end)
styleToggle(waterBtn, waterStroke, "WALK ON WATER + GOD WATER", walkOnWaterEnabled)
local fbBtn, espBtn, fbStroke, espStroke = createRow(pages.World, "FULLBRIGHT: OFF", function(b, s)
fullbrightEnabled = not fullbrightEnabled
styleToggle(b, s, "FULLBRIGHT", fullbrightEnabled)
if fullbrightEnabled then Lighting.Brightness = 3 Lighting.ClockTime = 14 Lighting.FogEnd = 100000 Lighting.GlobalShadows = false end
saveCurrentSettings()
end, "PLAYER ESP: OFF", function(b, s)
espEnabled = not espEnabled
styleToggle(b, s, "PLAYER ESP", espEnabled)
if not espEnabled then
for _, p in ipairs(Players:GetPlayers()) do
local h = p.Character and p.Character:FindFirstChild("BABFT_ESP")
if h then h:Destroy() end
end
end
saveCurrentSettings()
end, 3)
styleToggle(fbBtn, fbStroke, "FULLBRIGHT", fullbrightEnabled)
styleToggle(espBtn, espStroke, "PLAYER ESP", espEnabled)
createHeader(pages.World, "TELEPORTS & STAGES", 4)
local function getPlayerTeamZone(plr)
local tc = plr.TeamColor
for _, v in ipairs(Workspace:GetChildren()) do
if v:FindFirstChild("TeamColor") and v.TeamColor.Value == tc then return v end
end
return nil
end
createRow(pages.World, "TP TO MY PLOT", function()
local z = getPlayerTeamZone(player)
if z then teleportExact(z.CFrame + Vector3.new(0, 6, 0)) end
end, "TP GOLDEN CHEST", function()
local ns = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
local trig = ns and ns:FindFirstChild("TheEnd") and ns.TheEnd:FindFirstChild("GoldenChest") and ns.TheEnd.GoldenChest:FindFirstChild("Trigger")
if trig then teleportExact(trig.CFrame + Vector3.new(0, 4, 0)) end
end, 5)
local selectedStageNum = 1
createBtn(pages.World, "TP TO STAGE 1 (CLICK TO CYCLE 1-10)", nil, nil, 6, function(b)
local ns = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
local st = ns and ns:FindFirstChild("CaveStage" .. selectedStageNum)
local dp = st and st:FindFirstChild("DarknessPart")
if dp then teleportExact(dp.CFrame) end
selectedStageNum = (selectedStageNum % 10) + 1
b.Text = string.format("TP TO STAGE %d (CLICK TO CYCLE 1-10)", selectedStageNum)
end)
createHeader(pages.World, "INSTANT TEAM SWITCHER", 7)
local function switchToTeam(teamName)
pcall(function()
local t = Teams:FindFirstChild(teamName)
if t and Workspace:FindFirstChild("ChangeTeam") then Workspace.ChangeTeam:FireServer(t) end
end)
end
createRow(pages.World, "WHITE TEAM", function() switchToTeam("white") end, "BLACK TEAM", function() switchToTeam("black") end, 8)
createRow(pages.World, "RED TEAM", function() switchToTeam("red") end, "BLUE TEAM", function() switchToTeam("blue") end, 9)
createRow(pages.World, "GREEN TEAM", function() switchToTeam("green") end, "YELLOW TEAM", function() switchToTeam("yellow") end, 10)
createBtn(pages.World, "MAGENTA TEAM", nil, nil, 11, function() switchToTeam("magenta") end)
createHeader(pages.Shop, "CHEST BUYER & AUTO OPENER", 1)
local chestTypes = { "Common Chest", "Uncommon Chest", "Rare Chest", "Epic Chest", "Legendary Chest" }
local chestIdx = 1
for i, v in ipairs(chestTypes) do if v == selectedChestName then chestIdx = i end end
createBtn(pages.Shop, "CHEST: " .. selectedChestName:upper(), Color3.fromRGB(32, 36, 52), Color3.fromRGB(255, 215, 115), 2, function(b)
chestIdx = (chestIdx % #chestTypes) + 1
selectedChestName = chestTypes[chestIdx]
b.Text = "CHEST: " .. selectedChestName:upper()
saveCurrentSettings()
end)
local qtyOptions = { 1, 5, 10, 25, 50, 100 }
local qtyIdx = 1
for i, v in ipairs(qtyOptions) do if v == selectedChestQty then qtyIdx = i end end
createBtn(pages.Shop, "BUY AMOUNT: x" .. tostring(selectedChestQty), nil, nil, 3, function(b)
qtyIdx = (qtyIdx % #qtyOptions) + 1
selectedChestQty = qtyOptions[qtyIdx]
b.Text = "BUY AMOUNT: x" .. tostring(selectedChestQty)
saveCurrentSettings()
end)
local function buySelectedChest()
pcall(function()
local sr = Workspace:FindFirstChild("ItemPickedFromShop")
if sr then
if sr:IsA("RemoteFunction") then sr:InvokeServer(selectedChestName, selectedChestQty)
elseif sr:IsA("RemoteEvent") then sr:FireServer(selectedChestName, selectedChestQty) end
end
end)
end
createBtn(pages.Shop, "BUY SELECTED CHEST NOW", Color3.fromRGB(26, 48, 36), Color3.fromRGB(130, 245, 165), 4, buySelectedChest)
createBtn(pages.Shop, "AUTO BUY CHEST LOOP: OFF", nil, nil, 5, function(b, s)
autoChestEnabled = not autoChestEnabled
styleToggle(b, s, "AUTO BUY CHEST LOOP", autoChestEnabled)
end)
task.spawn(function()
while screenGui and screenGui.Parent do
if autoChestEnabled then buySelectedChest() end
task.wait(1.5)
end
end)
createHeader(pages.Shop, "QUEST MAKER & LAUNCHER", 6)
local questList = { { "Cloud Quest", 1 }, { "Target Quest", 2 }, { "Ramp Quest", 3 }, { "Find Me Quest", 4 }, { "Dragon Quest", 5 }, { "The Box Quest", 6 }, { "Thin Ice Quest", 7 }, { "Soccer Quest", 8 }, { "Nutcracker Quest", 101 } }
local qIdx = 1
createBtn(pages.Shop, "QUEST: " .. questList[qIdx][1]:upper(), nil, nil, 7, function(b)
qIdx = (qIdx % #questList) + 1
b.Text = "QUEST: " .. questList[qIdx][1]:upper()
end)
createRow(pages.Shop, "START QUEST", function()
pcall(function() if Workspace:FindFirstChild("QuestMakerEvent") then Workspace.QuestMakerEvent:FireServer(questList[qIdx][2]) end end)
end, "STOP / CANCEL QUEST", function()
pcall(function() if Workspace:FindFirstChild("QuestMakerEvent") then Workspace.QuestMakerEvent:FireServer(0) end end)
end, 8)
createRow(pages.Shop, "CLEAR MY PLOT", function()
pcall(function() if Workspace:FindFirstChild("ClearAllPlayersBoatParts") then Workspace.ClearAllPlayersBoatParts:FireServer() end end)
end, "INSTANT LAUNCH BOAT", function()
pcall(function()
local z = getPlayerTeamZone(player)
if z and z:FindFirstChild("VoteLaunchRE") then z.VoteLaunchRE:FireServer() end
end)
end, 9)
createHeader(pages.Builder, "PROCEDURAL 3D SPHERE & SHAPES", 1)
local buildMaterials = { "WoodBlock", "StoneBlock", "GoldBlock", "TitaniumBlock", "ObsidianBlock", "IronBlock", "MarbleBlock", "ConcreteBlock", "BrickBlock", "GlassBlock", "NeonBlock", "PlasticBlock" }
local matIdx = 1
createBtn(pages.Builder, "MATERIAL: WOODBLOCK", Color3.fromRGB(32, 36, 52), Color3.fromRGB(160, 210, 255), 2, function(b)
matIdx = (matIdx % #buildMaterials) + 1
selectedBlockType = buildMaterials[matIdx]
b.Text = "MATERIAL: " .. selectedBlockType:upper()
end)
local function placeSingleBlock(bName, worldCFrame, anchored)
local char = player.Character
if not char then return end
local tool = char:FindFirstChild("BuildingTool")
if not tool then
local bpTool = player.Backpack:FindFirstChild("BuildingTool")
if bpTool and char:FindFirstChildOfClass("Humanoid") then
char:FindFirstChildOfClass("Humanoid"):EquipTool(bpTool)
task.wait(0.05)
tool = char:FindFirstChild("BuildingTool")
end
end
if not tool or not tool:FindFirstChild("RF") then return end
local myZone = getPlayerTeamZone(player)
if not myZone then return end
local d = player:FindFirstChild("Data")
local idVal = (d and d:FindFirstChild(bName)) and d[bName].Value or 1
local args = { bName, idVal, myZone, myZone.CFrame:ToObjectSpace(worldCFrame), anchored ~= false, worldCFrame, false }
task.spawn(function() pcall(function() tool.RF:InvokeServer(unpack(args)) end) end)
end
local radLabel = create("TextLabel", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.format("Sphere Radius: %d blocks | Hollow: %s", sphereRadius, sphereHollow and "YES" or "NO"), TextColor3 = Color3.fromRGB(185, 195, 215), TextSize = 10, Font = Enum.Font.GothamMedium, ZIndex = 8 }, pages.Builder)
createRow(pages.Builder, "RADIUS +1 (CYCLE 3-14)", function()
sphereRadius = (sphereRadius - 2) % 12 + 3
radLabel.Text = string.format("Sphere Radius: %d blocks | Hollow: %s", sphereRadius, sphereHollow and "YES" or "NO")
end, "TOGGLE HOLLOW / SOLID", function()
sphereHollow = not sphereHollow
radLabel.Text = string.format("Sphere Radius: %d blocks | Hollow: %s", sphereRadius, sphereHollow and "YES" or "NO")
end, 4)
createBtn(pages.Builder, "BUILD 3D SPHERE ABOVE MY PLOT", Color3.fromRGB(26, 46, 36), Color3.fromRGB(130, 245, 165), 5, function(b)
if isBuildingBusy then return end
local myZone = getPlayerTeamZone(player)
if not myZone then return end
isBuildingBusy = true
task.spawn(function()
local center = myZone.Position + Vector3.new(0, sphereRadius * 2 + 12, 0)
local count = 0
for x = -sphereRadius, sphereRadius do
for y = -sphereRadius, sphereRadius do
for z = -sphereRadius, sphereRadius do
local dist = math.sqrt(x*x + y*y + z*z)
if (sphereHollow and dist <= sphereRadius and dist >= (sphereRadius - 1.15)) or (not sphereHollow and dist <= sphereRadius) then
placeSingleBlock(selectedBlockType, CFrame.new(center + Vector3.new(x * 2, y * 2, z * 2)), true)
count = count + 1
b.Text = string.format("BUILDING SPHERE... (%d blocks)", count)
if count % 25 == 0 then task.wait(0.06) end
end
end
end
end
b.Text = "BUILD 3D SPHERE ABOVE MY PLOT"
isBuildingBusy = false
end)
end)
createBtn(pages.Builder, "BUILD PROTECTIVE FLOOR PLATFORM", nil, nil, 6, function()
if isBuildingBusy then return end
local myZone = getPlayerTeamZone(player)
if not myZone then return end
isBuildingBusy = true
task.spawn(function()
local basePos = myZone.Position + Vector3.new(0, 6, 0)
local count = 0
for x = -6, 6 do
for z = -6, 6 do
placeSingleBlock(selectedBlockType, CFrame.new(basePos + Vector3.new(x * 2, 0, z * 2)), true)
count = count + 1
if count % 20 == 0 then task.wait(0.05) end
end
end
isBuildingBusy = false
end)
end)
createHeader(pages.Builder, "PLOT CLONER (COPY / PASTE BOATS)", 7)
local targetPlrIdx = 1
createBtn(pages.Builder, "TARGET PLAYER: CLICK TO SELECT", nil, nil, 8, function(b)
local list = Players:GetPlayers()
if #list == 0 then return end
targetPlrIdx = (targetPlrIdx % #list) + 1
selectedBasePlayer = list[targetPlrIdx]
b.Text = "TARGET: " .. selectedBasePlayer.DisplayName:upper()
end)
createRow(pages.Builder, "COPY TARGET PLOT", function(b)
if not selectedBasePlayer then return end
local blocksFolder = Workspace:FindFirstChild("Blocks")
local targetFolder = blocksFolder and blocksFolder:FindFirstChild(selectedBasePlayer.Name)
local hisZone = getPlayerTeamZone(selectedBasePlayer)
local myZone = getPlayerTeamZone(player)
if not targetFolder or not hisZone or not myZone then
b.Text = "NO BLOCKS FOUND" task.wait(1) b.Text = "COPY TARGET PLOT" return
end
copiedBuildData = {}
for _, blk in ipairs(targetFolder:GetChildren()) do
local pp = blk:FindFirstChild("PPart")
if pp and pp:IsA("BasePart") then
table.insert(copiedBuildData, { Name = blk.Name, Offset = hisZone.CFrame:ToObjectSpace(pp.CFrame), Anchored = pp.Anchored })
end
end
b.Text = string.format("COPIED (%d BLKS)", #copiedBuildData)
end, "PASTE ON MY PLOT", function(b)
if isBuildingBusy or not copiedBuildData or #copiedBuildData == 0 then return end
local myZone = getPlayerTeamZone(player)
if not myZone then return end
isBuildingBusy = true
task.spawn(function()
for i, item in ipairs(copiedBuildData) do
placeSingleBlock(item.Name, myZone.CFrame * item.Offset, item.Anchored)
b.Text = string.format("PASTING %d/%d", i, #copiedBuildData)
if i % 20 == 0 then task.wait(0.06) end
end
b.Text = "PASTE ON MY PLOT"
isBuildingBusy = false
end)
end, 9)
createHeader(pages.System, "DEVICE OPTIMIZATION & AUDIO", 1)
local soundBtn, optBtn, soundStroke, optStroke = createRow(pages.System, "MUTE: OFF", function(b, s)
soundMuted = not soundMuted
applySoundSetting(soundMuted)
styleToggle(b, s, "MUTE", soundMuted)
saveCurrentSettings()
end, "OPTIMIZE: OFF", function(b, s)
optEnabled = not optEnabled
applyOptSetting(optEnabled)
styleToggle(b, s, "OPTIMIZE", optEnabled)
saveCurrentSettings()
end, 2)
styleToggle(soundBtn, soundStroke, "MUTE", soundMuted)
styleToggle(optBtn, optStroke, "OPTIMIZE", optEnabled)
local afkBtn, afkStroke = createBtn(pages.System, "ANTI-AFK PROTECTION: ON", nil, nil, 3, function(b, s)
antiAfkEnabled = not antiAfkEnabled
styleToggle(b, s, "ANTI-AFK PROTECTION", antiAfkEnabled)
saveCurrentSettings()
end)
styleToggle(afkBtn, afkStroke, "ANTI-AFK PROTECTION", antiAfkEnabled)
player.Idled:Connect(function()
if antiAfkEnabled then pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end) end
end)
createHeader(pages.System, "SERVER MANAGEMENT", 4)
createRow(pages.System, "FORCE SERVER HOP", function(b) b.Text = "HOPPING..." serverHop() end, "REJOIN CURRENT SERVER", function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end) end, 5)
createBtn(pages.System, "RESET SAVED CONFIG & STATS", Color3.fromRGB(42, 24, 28), Color3.fromRGB(255, 135, 145), 6, function(b)
housesCount = 0 goldRunsCount = 0 totalGoldEarned = 0 farmStartTime = 0
updateTimerDisplay() saveCurrentSettings()
b.Text = "STATS & CONFIG RESET!" task.wait(1) b.Text = "RESET SAVED CONFIG & STATS"
end)
RunService.Stepped:Connect(function()
local char = player.Character
if not char then return end
local hum = char:FindFirstChildOfClass("Humanoid")
local hrp = char:FindFirstChild("HumanoidRootPart")
if speedLockEnabled and hum then hum.WalkSpeed = customWalkSpeed hum.UseJumpPower = true hum.JumpPower = customJumpPower end
if godModeEnabled and hum then pcall(function() hum.MaxHealth = 9e9 hum.Health = 9e9 end) end
if noclipEnabled then
for _, part in ipairs(char:GetDescendants()) do
if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
end
end
if flyEnabled and hrp then
if not flyBV or flyBV.Parent ~= hrp then
if flyBV then pcall(function() flyBV:Destroy() end) end
flyBV = create("BodyVelocity", { Name = "BABFT_FlyBV", MaxForce = Vector3.new(9e9, 9e9, 9e9) }, hrp)
end
local cam = Workspace.CurrentCamera
if cam then
local moveVec = (cam.CFrame.LookVector * (flyDir.f + flyDir.b)) + (cam.CFrame.RightVector * (flyDir.r + flyDir.l)) + Vector3.new(0, flyDir.u + flyDir.d, 0)
flyBV.Velocity = (moveVec.Magnitude > 0) and (moveVec.Unit * customFlySpeed) or Vector3.zero
end
end
if boatBoostEnabled and hum and hum.SeatPart then
local seat = hum.SeatPart
if seat:IsA("VehicleSeat") or seat:IsA("Seat") then
local bv = seat:FindFirstChild("BABFT_BoatBV") or create("BodyVelocity", { Name = "BABFT_BoatBV", MaxForce = Vector3.new(9e9, 0, 9e9) }, seat)
bv.Velocity = (hum.MoveDirection.Magnitude > 0) and (seat.CFrame.LookVector * customBoatSpeed) or Vector3.zero
end
end
end)
task.spawn(function()
while screenGui and screenGui.Parent do
if espEnabled then
for _, p in ipairs(Players:GetPlayers()) do
if p ~= player and p.Character then
local hl = p.Character:FindFirstChild("BABFT_ESP") or create("Highlight", { Name = "BABFT_ESP", OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.55 }, p.Character)
hl.FillColor = p.TeamColor and p.TeamColor.Color or Color3.fromRGB(255, 80, 80)
end
end
end
task.wait(1.5)
end
end)
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
titleBar.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true dragStart = input.Position startPos = windowRoot.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then dragging = false saveCurrentSettings() end
end)
end
end)
titleBar.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
windowRoot.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end)
switchTab("Farms")
triggerMotionBlur(16, 0.45)
TweenService:Create(windowRoot, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 460, 0, 310), Position = defaultPos }):Play()
TweenService:Create(mainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
local isMinimized = false
minBtn.MouseButton1Click:Connect(function()
isMinimized = not isMinimized
triggerMotionBlur(10, 0.3)
minBtn.Text = isMinimized and "+" or "-"
sidebar.Visible = not isMinimized
pageContainer.Visible = not isMinimized
TweenService:Create(windowRoot, TweenInfo.new(0.35, isMinimized and Enum.EasingStyle.Quart or Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
Size = isMinimized and UDim2.new(0, 460, 0, 36) or UDim2.new(0, 460, 0, 310)
}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
if isRunning then stopFarm() end
if isGoldRunning then stopGoldFarm() end
getgenv().BABFT_FarmActiveInstance = nil
triggerMotionBlur(16, 0.35)
local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { GroupTransparency = 1 })
TweenService:Create(windowRoot, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = UDim2.new(0, 320, 0, 180) }):Play()
closeTween:Play()
closeTween.Completed:Connect(function() glowConnection:Disconnect() vfxBlur:Destroy() screenGui:Destroy() end)
end)
if soundMuted then applySoundSetting(true) end
if optEnabled then applyOptSetting(true) end
if walkOnWaterEnabled then applyWaterState(true) end
if fullbrightEnabled then Lighting.Brightness = 3 Lighting.ClockTime = 14 Lighting.FogEnd = 100000 Lighting.GlobalShadows = false end
updateTimerDisplay()
if savedSettings.enabled == true then
task.spawn(function() task.wait(1) startFarm() end)
elseif savedSettings.goldEnabled == true then
task.spawn(function() task.wait(1) startGoldFarm() end)
end
]==]
pcall(function()
if writefile then
writefile("BABFT_Farm_Chickedream.lua", SCRIPT_SOURCE)
end
end)
local chunk, err = loadstring(SCRIPT_SOURCE)
if chunk then
chunk()
else
warn(err)
end
