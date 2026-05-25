local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local FOV_RADIUS = 150
local SMOOTHNESS = 0.4
local teamCheckEnabled = false

-- i was actually planning to add a semi-circle hp bar to this but i got lazy as fuck
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Radius = FOV_RADIUS
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Transparency = 1

local targetText = Drawing.new("Text")
targetText.Visible = true
targetText.Position = Vector2.new(10, camera.ViewportSize.Y - 25)
targetText.Size = 16
targetText.Color = Color3.fromRGB(255, 255, 255)
targetText.Outline = true
targetText.Center = false
targetText.Text = "Locked onto: None"

local function isVisible(targetPart)
	local origin = camera.CFrame.Position
	local direction = targetPart.Position - origin
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {localPlayer.Character, camera}
	raycastParams.IgnoreWater = true
	
	local result = Workspace:Raycast(origin, direction, raycastParams)
	if result and result.Instance:IsDescendantOf(targetPart.Parent) then
		return true
	end
	return false
end

local function getClosestPlayerInFOV()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if teamCheckEnabled and player.Team == localPlayer.Team then
				continue
			end

			local hrp = player.Character.HumanoidRootPart
			local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
			
			if onScreen and isVisible(hrp) then
				local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				if distance <= FOV_RADIUS and distance < shortestDistance then
					closestPlayer = player
					shortestDistance = distance
				end
			end
		end
	end
	return closestPlayer
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		teamCheckEnabled = not teamCheckEnabled
	end
end)

RunService.RenderStepped:Connect(function()
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	fovCircle.Position = screenCenter
	targetText.Position = Vector2.new(10, camera.ViewportSize.Y - 25)
	
	local target = getClosestPlayerInFOV()
	if target then
		local targetPart = target.Character.HumanoidRootPart
		local targetCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
		
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, SMOOTHNESS)
		targetText.Text = target.DisplayName
	else
		targetText.Text = "Nil"
	end
end)
