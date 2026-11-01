local SCRIPT_SOURCE = [==[
repeat task.wait(0.1) until game:IsLoaded()

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
a
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
if not player then
	repeat task.wait(0.1) player = Players.LocalPlayer until player
end

local existingGui = CoreGui:FindFirstChild("BABFT_CandyFarm") or (player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("BABFT_CandyFarm"))
if existingGui or getgenv().BABFT_FarmActiveInstance then
	return
end
getgenv().BABFT_FarmActiveInstance = true

local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local existingBlur = Lighting:FindFirstChild("BABFT_FarmBlur")
if existingBlur then
	existingBlur:Destroy()
end

local targetParent = nil
pcall(function()
	if gethui then
		targetParent = gethui()
	elseif CoreGui then
		targetParent = CoreGui
	end
end)

if not targetParent then
	targetParent = player:WaitForChild("PlayerGui", 25)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BABFT_CandyFarm"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = targetParent

local vfxBlur = Instance.new("BlurEffect")
vfxBlur.Name = "BABFT_FarmBlur"
vfxBlur.Size = 0
vfxBlur.Parent = Lighting

local function triggerMotionBlur(peakSize, duration)
	task.spawn(function()
		local tIn = TweenService:Create(vfxBlur, TweenInfo.new(duration * 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = peakSize
		})
		tIn:Play()
		tIn.Completed:Wait()
		local tOut = TweenService:Create(vfxBlur, TweenInfo.new(duration * 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Size = 0
		})
		tOut:Play()
	end)
end

local windowRoot = Instance.new("Frame")
windowRoot.Name = "WindowRoot"
windowRoot.AnchorPoint = Vector2.new(0.5, 0.5)
windowRoot.Size = UDim2.new(0, 220, 0, 120)
windowRoot.Position = UDim2.new(0.5, 0, 0.45, 20)
windowRoot.BackgroundTransparency = 1
windowRoot.BorderSizePixel = 0
windowRoot.Active = false
windowRoot.ZIndex = 1
windowRoot.Parent = screenGui

local glowHolder = Instance.new("Frame")
glowHolder.Name = "GlowHolder"
glowHolder.Size = UDim2.new(1, 0, 1, 0)
glowHolder.Position = UDim2.new(0, 0, 0, 0)
glowHolder.BackgroundTransparency = 1
glowHolder.BorderSizePixel = 0
glowHolder.Active = false
glowHolder.ZIndex = 1
glowHolder.Parent = windowRoot

local glowGradients = {}

local softShadow = Instance.new("ImageLabel")
softShadow.Name = "SoftShadow"
softShadow.AnchorPoint = Vector2.new(0.5, 0.5)
softShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
softShadow.Size = UDim2.new(1, 64, 1, 64)
softShadow.BackgroundTransparency = 1
softShadow.Image = "rbxassetid://6015897843"
softShadow.ImageTransparency = 0.35
softShadow.ScaleType = Enum.ScaleType.Slice
softShadow.SliceCenter = Rect.new(49, 49, 450, 450)
softShadow.Active = false
softShadow.ZIndex = 1
softShadow.Parent = glowHolder

local shadowGradient = Instance.new("UIGradient")
shadowGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 0)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(180, 0, 255)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(0, 185, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0))
})
shadowGradient.Parent = softShadow
table.insert(glowGradients, shadowGradient)

local glowLayers = {
	{ thickness = 2, transparency = 0.2 },
	{ thickness = 6, transparency = 0.4 },
	{ thickness = 11, transparency = 0.65 },
	{ thickness = 18, transparency = 0.8 },
	{ thickness = 26, transparency = 0.92 }
}

for _, layer in ipairs(glowLayers) do
	local layerFrame = Instance.new("Frame")
	layerFrame.Name = "GlowLayer"
	layerFrame.Size = UDim2.new(1, 0, 1, 0)
	layerFrame.BackgroundTransparency = 1
	layerFrame.BorderSizePixel = 0
	layerFrame.Active = false
	layerFrame.ZIndex = 1
	layerFrame.Parent = glowHolder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = layerFrame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = layer.thickness
	stroke.Transparency = layer.transparency
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = layerFrame

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 0)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(180, 0, 255)),
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(0, 185, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0))
	})
	gradient.Parent = stroke
	table.insert(glowGradients, gradient)
end

local glowConnection = RunService.RenderStepped:Connect(function()
	local rot = (tick() * 100) % 360
	for _, grad in ipairs(glowGradients) do
		grad.Rotation = rot
	end
end)

local mainFrame = Instance.new("CanvasGroup")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.GroupTransparency = 1
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ZIndex = 5
mainFrame.Parent = windowRoot

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 6
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BABFT OP Candy Farm"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 7
titleLabel.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Name = "MinButton"
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -62, 0, 6)
minBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
minBtn.BorderSizePixel = 0
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(210, 210, 220)
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.AutoButtonColor = false
minBtn.ZIndex = 8
minBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 7)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(48, 22, 26)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 140, 150)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 8
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeBtn

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -36)
contentFrame.Position = UDim2.new(0, 0, 0, 36)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 6
contentFrame.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(1, -28, 0, 46)
toggleBtn.Position = UDim2.new(0, 14, 0, 16)
toggleBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "START FARM"
toggleBtn.TextColor3 = Color3.fromRGB(120, 235, 140)
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 7
toggleBtn.Parent = contentFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Thickness = 1.2
toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
toggleStroke.Color = Color3.fromRGB(50, 75, 60)
toggleStroke.Parent = toggleBtn

local authorLabel = Instance.new("TextLabel")
authorLabel.Name = "AuthorLabel"
authorLabel.Size = UDim2.new(1, 0, 0, 16)
authorLabel.Position = UDim2.new(0, 0, 1, -22)
authorLabel.BackgroundTransparency = 1
authorLabel.Text = "Made By Chickedream"
authorLabel.TextColor3 = Color3.fromRGB(75, 75, 90)
authorLabel.TextSize = 10
authorLabel.Font = Enum.Font.GothamMedium
authorLabel.ZIndex = 7
authorLabel.Parent = contentFrame

local function wireHover(btn, normalColor, hoverColor)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			BackgroundColor3 = hoverColor
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			BackgroundColor3 = normalColor
		}):Play()
	end)
end

wireHover(minBtn, Color3.fromRGB(32, 32, 40), Color3.fromRGB(45, 45, 58))
wireHover(closeBtn, Color3.fromRGB(48, 22, 26), Color3.fromRGB(75, 26, 32))

local dragging = false
local dragInput
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = windowRoot.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		TweenService:Create(windowRoot, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		}):Play()
	end
end)

triggerMotionBlur(16, 0.45)
TweenService:Create(windowRoot, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 270, 0, 160),
	Position = UDim2.new(0.5, 0, 0.45, 0)
}):Play()
TweenService:Create(mainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	GroupTransparency = 0
}):Play()

local isMinimized = false
minBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	triggerMotionBlur(10, 0.3)

	if isMinimized then
		minBtn.Text = "+"
		TweenService:Create(windowRoot, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 270, 0, 36)
		}):Play()
	else
		minBtn.Text = "-"
		TweenService:Create(windowRoot, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 270, 0, 160)
		}):Play()
	end
end)

local isRunning = false
local farmThread = nil
local isHopping = false

local stateFilePath = "BABFT_FarmState.json"
local visitedPath = "BABFT_VisitedServers.json"

local autoExecPaths = {
	"autoexec/BABFT_CandyFarm_Auto.lua",
	"autoexecute/BABFT_CandyFarm_Auto.lua"
}

local persistentLoader = [=[
repeat task.wait(0.2) until game:IsLoaded()
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer or plrs:GetPropertyChangedSignal("LocalPlayer"):Wait()
if not lp then
	repeat task.wait(0.2) lp = plrs.LocalPlayer until lp
end
lp:WaitForChild("PlayerGui", 30)
task.wait(1)
pcall(function()
	if readfile and isfile and isfile("BABFT_Farm_Chickedream.lua") then
		loadstring(readfile("BABFT_Farm_Chickedream.lua"))()
	end
end)
]=]

local function setPersistentState(active)
	if writefile then
		pcall(function()
			writefile(stateFilePath, HttpService:JSONEncode({ enabled = active }))
		end)
	end
end

local function getPersistentState()
	if readfile and isfile and isfile(stateFilePath) then
		local s, res = pcall(function()
			return HttpService:JSONDecode(readfile(stateFilePath))
		end)
		if s and type(res) == "table" and res.enabled ~= nil then
			return res.enabled
		end
	end
	return false
end

local function installAutoExec()
	local dirs = {"autoexec", "autoexecute"}
	for _, dir in ipairs(dirs) do
		pcall(function()
			if makefolder and isfolder and not isfolder(dir) then
				makefolder(dir)
			end
		end)
	end
	for _, path in ipairs(autoExecPaths) do
		pcall(function()
			if writefile then
				writefile(path, persistentLoader)
			end
		end)
	end
end

local function removeAutoExec()
	for _, path in ipairs(autoExecPaths) do
		pcall(function()
			if delfile and isfile and isfile(path) then
				delfile(path)
			end
		end)
	end
end

local function getCleanVisited()
	local list = {}
	local now = os.time()

	if getgenv().BABFT_VisitedList and type(getgenv().BABFT_VisitedList) == "table" then
		list = getgenv().BABFT_VisitedList
	end

	if readfile and isfile and isfile(visitedPath) then
		pcall(function()
			local decoded = HttpService:JSONDecode(readfile(visitedPath))
			if type(decoded) == "table" then
				for k, v in pairs(decoded) do
					list[k] = v
				end
			end
		end)
	end

	local cleaned = {}
	for id, t in pairs(list) do
		if type(t) == "number" and (now - t) < 1200 then
			cleaned[id] = t
		end
	end

	cleaned[game.JobId] = now
	getgenv().BABFT_VisitedList = cleaned

	if writefile then
		pcall(function()
			writefile(visitedPath, HttpService:JSONEncode(cleaned))
		end)
	end

	return cleaned
end

local function markVisited(jobId)
	local visited = getCleanVisited()
	visited[jobId] = os.time()
	getgenv().BABFT_VisitedList = visited
	if writefile then
		pcall(function()
			writefile(visitedPath, HttpService:JSONEncode(visited))
		end)
	end
end

local function queueNextHop()
	local qot = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
	if qot then
		pcall(function()
			qot(persistentLoader)
		end)
	end
end

local function requestHttp(url)
	local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
	if httpRequest then
		local res = httpRequest({ Url = url, Method = "GET" })
		if type(res) == "table" and res.Body then
			return res.Body
		end
	end
	return game:HttpGet(url)
end

local function findDistinctServer()
	local placeId = game.PlaceId
	local currentJobId = game.JobId
	local visited = getCleanVisited()
	local sortModes = {"Asc", "Desc"}

	for _, sortOrder in ipairs(sortModes) do
		local cursor = ""
		local pagesChecked = 0

		while pagesChecked < 4 do
			pagesChecked = pagesChecked + 1
			local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100"
			if cursor ~= "" then
				url = url .. "&cursor=" .. cursor
			end

			local success, raw = pcall(requestHttp, url)
			if success and raw and #raw > 10 then
				local parseSuccess, data = pcall(function()
					return HttpService:JSONDecode(raw)
				end)

				if parseSuccess and data and data.data then
					local pool = {}
					for _, s in ipairs(data.data) do
						if type(s) == "table" and s.id and s.id ~= currentJobId then
							if not visited[s.id] and s.playing and s.maxPlayers then
								local freeSlots = s.maxPlayers - s.playing
								if freeSlots >= 1 and s.playing > 0 then
									table.insert(pool, s.id)
								end
							end
						end
					end

					if #pool > 0 then
						return pool[math.random(1, #pool)]
					end

					if data.nextPageCursor and data.nextPageCursor ~= "" then
						cursor = data.nextPageCursor
					else
						break
					end
				else
					break
				end
			else
				break
			end
			task.wait(0.2)
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

	local placeId = game.PlaceId
	local currentJob = game.JobId
	local chosenTarget = nil
	local attempts = 0

	while attempts < 5 and not chosenTarget do
		attempts = attempts + 1
		chosenTarget = findDistinctServer()
		if not chosenTarget then
			task.wait(1.5)
		end
	end

	if not chosenTarget then
		local freshVisited = {}
		freshVisited[currentJob] = os.time()
		getgenv().BABFT_VisitedList = freshVisited
		if writefile then
			pcall(function()
				writefile(visitedPath, HttpService:JSONEncode(freshVisited))
			end)
		end
		chosenTarget = findDistinctServer()
	end

	if not chosenTarget then
		isHopping = false
		task.wait(2)
		return serverHop()
	end

	markVisited(chosenTarget)

	local initFailedConn
	initFailedConn = TeleportService.TeleportInitFailed:Connect(function()
		if initFailedConn then
			initFailedConn:Disconnect()
		end
		isHopping = false
		task.wait(1)
		serverHop()
	end)

	task.spawn(function()
		task.wait(12)
		if isHopping and game.JobId == currentJob then
			if initFailedConn then
				initFailedConn:Disconnect()
			end
			isHopping = false
			serverHop()
		end
	end)

	TeleportService:TeleportToPlaceInstance(placeId, chosenTarget, player)
end

local function getTargetCFrame(instance)
	if instance:IsA("BasePart") then
		return instance.CFrame
	elseif instance:IsA("Model") then
		return instance:GetPivot()
	end
	return nil
end

local function teleportExact(targetCFrame)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
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
	while isRunning do
		local housesFolder = Workspace:FindFirstChild("Houses")
		local doors = scanDoors()

		if #doors == 0 then
			task.wait(1.5)
			doors = scanDoors()
			housesFolder = Workspace:FindFirstChild("Houses")

			local isEmpty = not housesFolder or #housesFolder:GetChildren() == 0 or #doors == 0
			if isEmpty and isRunning then
				toggleBtn.Text = "HOPPING SERVER..."
				toggleBtn.TextColor3 = Color3.fromRGB(255, 205, 110)
				serverHop()
				break
			end
		else
			for _, door in ipairs(doors) do
				if not isRunning then break end

				if door and door.Parent then
					local targetCFrame = getTargetCFrame(door)
					if targetCFrame then
						teleportExact(targetCFrame)
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
		if humanoid then
			humanoid.Health = 0
		else
			character:BreakJoints()
		end
	end
end

local function startFarm()
	isRunning = true
	setPersistentState(true)
	installAutoExec()
	toggleBtn.Text = "STOP FARM"
	TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(42, 22, 26),
		TextColor3 = Color3.fromRGB(255, 115, 115)
	}):Play()
	TweenService:Create(toggleStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Color = Color3.fromRGB(110, 45, 52)
	}):Play()
	farmThread = task.spawn(runFarmLoop)
end

local function stopFarm()
	isRunning = false
	setPersistentState(false)
	removeAutoExec()
	toggleBtn.Text = "START FARM"
	TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(24, 28, 34),
		TextColor3 = Color3.fromRGB(120, 235, 140)
	}):Play()
	TweenService:Create(toggleStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Color = Color3.fromRGB(50, 75, 60)
	}):Play()

	if farmThread then
		task.cancel(farmThread)
		farmThread = nil
	end

	resetPlayerCharacter()
end

toggleBtn.MouseButton1Click:Connect(function()
	if isRunning then
		stopFarm()
	else
		startFarm()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	stopFarm()
	getgenv().BABFT_FarmActiveInstance = nil

	triggerMotionBlur(16, 0.35)
	local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		GroupTransparency = 1
	})
	TweenService:Create(windowRoot, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 200, 0, 110)
	}):Play()
	closeTween:Play()

	closeTween.Completed:Connect(function()
		glowConnection:Disconnect()
		vfxBlur:Destroy()
		screenGui:Destroy()
	end)
end)

if getPersistentState() == true then
	task.spawn(function()
		task.wait(1)
		startFarm()
	end)
end
]==]

pcall(function()
	if writefile then
		writefile("BABFT_Farm_Chickedream.lua", SCRIPT_SOURCE)
	end
end)

loadstring(SCRIPT_SOURCE)()
