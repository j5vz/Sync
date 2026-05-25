-- this was lowkey a pain in the ass to make
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local cache = {}

local function createDrawing(type, properties)
    local obj = Drawing.new(type)
    for prop, val in pairs(properties) do
        obj[prop] = val
    end
    return obj
end

local function addESP(player)
    if player == localPlayer then return end

    local esp = {
        box = createDrawing("Square", {Color = Color3.fromRGB(255, 100, 100), Thickness = 1, Filled = false, Visible = false}),
        hpBarOutline = createDrawing("Square", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Filled = true, Visible = false}),
        hpBar = createDrawing("Square", {Color = Color3.fromRGB(255, 50, 50), Thickness = 1, Filled = true, Visible = false}),

        name = createDrawing("Text", {Text = player.DisplayName, Color = Color3.fromRGB(255, 255, 255), Size = 16, Center = true, Outline = true, Visible = false}),
        tool = createDrawing("Text", {Text = "Nil", Color = Color3.fromRGB(255, 255, 255), Size = 14, Center = true, Outline = true, Visible = false})
    }

    cache[player] = esp
end

local function removeESP(player)
    if cache[player] then
        for _, drawing in pairs(cache[player]) do
            drawing:Remove()
        end
        cache[player] = nil
    end
end

local function getEquippedTool(player)
    local character = player.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            return tool.Name
        end
    end
    return "Nil"
end

local function updateESP()
    for player, esp in pairs(cache) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if root and humanoid and humanoid.Health > 0 then
            local cframe, size = character:GetBoundingBox()
            
            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local anyOnScreen = false

            local sx, sy, sz = size.X / 2, size.Y / 2, size.Z / 2
            local corners = {
                cframe * Vector3.new(-sx, sy, -sz),
                cframe * Vector3.new(sx, sy, -sz),
                cframe * Vector3.new(-sx, -sy, -sz),
                cframe * Vector3.new(sx, -sy, -sz),
                cframe * Vector3.new(-sx, sy, sz),
                cframe * Vector3.new(sx, sy, sz),
                cframe * Vector3.new(-sx, -sy, sz),
                cframe * Vector3.new(sx, -sy, sz)
            }

            for _, cornerPos in ipairs(corners) do
                local screenPos, onScreen = camera:WorldToViewportPoint(cornerPos)
                if onScreen then
                    anyOnScreen = true
                    if screenPos.X < minX then minX = screenPos.X end
                    if screenPos.X > maxX then maxX = screenPos.X end
                    if screenPos.Y < minY then minY = screenPos.Y end
                    if screenPos.Y > maxY then maxY = screenPos.Y end
                end
            end

            if anyOnScreen and minX ~= math.huge then
                local width = maxX - minX
                local height = maxY - minY

                local boxColor = Color3.fromRGB(255, 100, 100)
                local barColor = Color3.fromRGB(255, 50, 50)
                if player.Team then
                    boxColor = player.TeamColor.Color
                    barColor = player.TeamColor.Color
                end

                esp.box.Size = Vector2.new(width, height)
                esp.box.Position = Vector2.new(minX, minY)
                esp.box.Color = boxColor
                esp.box.Visible = true

                local barWidth = math.clamp(width * 0.08, 6, 12)
                local barPadding = 3
                local barX = minX + width + barPadding

                esp.hpBarOutline.Size = Vector2.new(barWidth + 2, height + 2)
                esp.hpBarOutline.Position = Vector2.new(barX - 1, minY - 1)
                esp.hpBarOutline.Visible = true

                local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                local barHeight = height * healthPercent

                -- i was planning to add text saying "HP" ontop of this but the drawing lib didnt let me turn the text to 90° so fuc that
                esp.hpBar.Size = Vector2.new(barWidth, barHeight)
                esp.hpBar.Position = Vector2.new(barX, minY + (height - barHeight))
                esp.hpBar.Color = barColor
                esp.hpBar.Visible = true

                esp.name.Position = Vector2.new(minX + (width / 2), minY - 22)
                esp.name.Visible = true

                esp.tool.Text = getEquippedTool(player)
                esp.tool.Position = Vector2.new(minX + (width / 2), minY + height + 5)
                esp.tool.Visible = true
            else
                for _, drawing in pairs(esp) do
                    drawing.Visible = false
                end
            end
        else
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
        end
    end
end

for _, player in ipairs(players:GetPlayers()) do
    addESP(player)
end

players.PlayerAdded:Connect(addESP)
players.PlayerRemoving:Connect(removeESP)
runService.RenderStepped:Connect(updateESP)
