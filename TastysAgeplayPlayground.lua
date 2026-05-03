local localPlayer = game.Players.LocalPlayer

repeat wait() until localPlayer.Character
repeat wait() until localPlayer.Character:FindFirstChild("HumanoidRootPart")
repeat wait() until workspace.Live[localPlayer.Name]
repeat wait() until localPlayer.Backpack:FindFirstChild("Weapon")

local passiveAgilityPath = game.Workspace.Live[localPlayer.Name].PassiveAgility
local originalValue = passiveAgilityPath.Value
local savedValue = originalValue
local camera = game.Workspace.CurrentCamera
local screenWidth = camera.ViewportSize.X

local label = Drawing.new("Text")
label.Visible = true
label.Color = Color3.fromRGB(255, 0, 0)
label.Outline = true
label.Size = 20
label.Font = Drawing.Fonts.System
label.Center = true
label.Position = Vector2.new(screenWidth / 2, 10)
label.Text = tostring(passiveAgilityPath.Value)

local function updateLabel()
    label.Text = tostring(passiveAgilityPath.Value)
end

local live = workspace.Live
local players = game.Players
local espLabels = {}
local mobESPLabels = {}

local BAR_WIDTH = 50
local BAR_HEIGHT = 6
local SECTION_COUNT = 5

local MOB_TYPES = {
    { match = "king_gigamed",      display = "King Gigamed",      color = Color3.fromRGB(255, 215, 0)   },
    { match = "gigamed",           display = "Gigamed",           color = Color3.fromRGB(255, 255, 255) },
    { match = "megalodaunt_alpha", display = "Alpha Sharko",      color = Color3.fromRGB(255, 0, 0)     },
    { match = "megalodaunt",       display = "Sharko",            color = Color3.fromRGB(255, 100, 100) },
    { match = "king_crocco",       display = "King Thresher",     color = Color3.fromRGB(255, 215, 0)   },
    { match = "crocco",            display = "Thresher",          color = Color3.fromRGB(0, 200, 100)   },
    { match = "broodlord",         display = "Broodlord",         color = Color3.fromRGB(180, 0, 255)   },
    { match = "crabbo",            display = "Crab",              color = Color3.fromRGB(255, 80, 0)    },
    { match = "turtle",            display = "Small Crab",        color = Color3.fromRGB(0, 200, 0)     },
    { match = "owl",               display = "Dark Owl",          color = Color3.fromRGB(200, 200, 255) },
    { match = "widow",             display = "Widow",             color = Color3.fromRGB(150, 0, 255)   },
    { match = "lionfish",          display = "Lionfish",          color = Color3.fromRGB(255, 50, 150)  },
    { match = "squidward",         display = "Squibbo",           color = Color3.fromRGB(100, 200, 255) },
    { match = "brute",             display = "Brute",             color = Color3.fromRGB(200, 50, 50)   },
}

local function getMobInfo(name)
    local lower = name:lower()
    for _, mob in ipairs(MOB_TYPES) do
        if lower:find(mob.match) then
            return mob.display, mob.color
        end
    end
    return nil, nil
end

local function removeESPLabel(name)
    local entry = espLabels[name]
    if entry then
        entry.label:Remove()
        entry.hpLabel:Remove()
        entry.hpBar:Remove()
        entry.hpBarBg:Remove()
        for _, line in ipairs(entry.hpLines) do line:Remove() end
        espLabels[name] = nil
    end
end

local function hideAllESP()
    for _, entry in next, espLabels do
        entry.label.Visible = false
        entry.hpLabel.Visible = false
        entry.hpBar.Visible = false
        entry.hpBarBg.Visible = false
        for _, line in ipairs(entry.hpLines) do line.Visible = false end
    end
end

local function createESPLabel(name)
    local nameLabel = Drawing.new("Text")
    nameLabel.Size = 16
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Font = Drawing.Fonts.System
    nameLabel.Text = name
    nameLabel.Visible = false

    local hpBarBg = Drawing.new("Square")
    hpBarBg.Size = Vector2.new(BAR_WIDTH, BAR_HEIGHT)
    hpBarBg.Color = Color3.fromRGB(0, 0, 0)
    hpBarBg.Filled = true
    hpBarBg.Visible = false

    local hpBar = Drawing.new("Square")
    hpBar.Size = Vector2.new(BAR_WIDTH, BAR_HEIGHT)
    hpBar.Color = Color3.fromRGB(0, 255, 0)
    hpBar.Filled = true
    hpBar.Visible = false

    local hpLines = {}
    for i = 1, SECTION_COUNT - 1 do
        local line = Drawing.new("Line")
        line.Color = Color3.fromRGB(0, 0, 0)
        line.Thickness = 1
        line.Visible = false
        table.insert(hpLines, line)
    end

    local hpLabel = Drawing.new("Text")
    hpLabel.Size = 16
    hpLabel.Font = Drawing.Fonts.System
    hpLabel.Outline = true
    hpLabel.Center = true
    hpLabel.Visible = false

    espLabels[name] = {
        label = nameLabel,
        hpBar = hpBar,
        hpBarBg = hpBarBg,
        hpLines = hpLines,
        hpLabel = hpLabel,
        lastHp = -1
    }
end

local function removeMobESPLabel(name)
    local entry = mobESPLabels[name]
    if entry then
        entry.label:Remove()
        entry.hpLabel:Remove()
        mobESPLabels[name] = nil
    end
end

local function hideAllMobESP()
    for _, entry in next, mobESPLabels do
        entry.label.Visible = false
        entry.hpLabel.Visible = false
    end
end

local function createMobESPLabel(name)
    local display, color = getMobInfo(name)

    local nameLabel = Drawing.new("Text")
    nameLabel.Size = 16
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Font = Drawing.Fonts.System
    nameLabel.Text = display
    nameLabel.Color = color
    nameLabel.Visible = false

    local hpLabel = Drawing.new("Text")
    hpLabel.Size = 14
    hpLabel.Font = Drawing.Fonts.System
    hpLabel.Outline = true
    hpLabel.Center = true
    hpLabel.Visible = false

    mobESPLabels[name] = {
        label = nameLabel,
        hpLabel = hpLabel,
        lastHp = -1
    }
end

local function safeWorldToScreen(pos)
    local ok, vec, onScreen = pcall(WorldToScreen, pos)
    if ok and vec then return vec, onScreen end
    return nil, false
end

spawn(function()
    while true do
        wait(0.01)
        local espOn = UI.GetValue("esp_on")
        local hpBarOn = UI.GetValue("esp_hpbar")
        local showCurrentHp = UI.GetValue("esp_currenthp")
        local maxDist = UI.GetValue("esp_distance") or 500

        local activePlayers = {}
        for _, p in ipairs(players:GetPlayers()) do
            activePlayers[p.Name] = true
        end
        for name in next, espLabels do
            if not activePlayers[name] then removeESPLabel(name) end
        end

        if not espOn then
            hideAllESP()
        else
            local localRoot = live[localPlayer.Name] and live[localPlayer.Name]:FindFirstChild("HumanoidRootPart")

            for _, model in ipairs(live:GetChildren()) do
                local name = model.Name
                if not activePlayers[name] then continue end
                if name == localPlayer.Name then continue end

                local root = model:FindFirstChild("HumanoidRootPart")
                if not root then continue end

                if localRoot then
                    local dist = (root.Position - localRoot.Position).Magnitude
                    if dist > maxDist then
                        if espLabels[name] then
                            espLabels[name].label.Visible = false
                            espLabels[name].hpLabel.Visible = false
                            espLabels[name].hpBar.Visible = false
                            espLabels[name].hpBarBg.Visible = false
                            for _, line in ipairs(espLabels[name].hpLines) do line.Visible = false end
                        end
                        continue
                    end
                end

                if not espLabels[name] then createESPLabel(name) end

                local entry = espLabels[name]
                local screenPos, onScreen = safeWorldToScreen(root.Position + Vector3.new(0, 1.5, 0))

                if not screenPos then
                    entry.label.Visible = false
                    entry.hpLabel.Visible = false
                    entry.hpBar.Visible = false
                    entry.hpBarBg.Visible = false
                    for _, line in ipairs(entry.hpLines) do line.Visible = false end
                    continue
                end

                entry.label.Visible = onScreen
                entry.label.Position = Vector2.new(screenPos.X, screenPos.Y)

                local humanoid = model:FindFirstChild("Humanoid")
                if humanoid then
                    local pct = math.floor(humanoid.Health / humanoid.MaxHealth * 100)
                    local ratio = pct / 100
                    local barY = screenPos.Y + 18
                    local hpText = showCurrentHp and math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) or pct .. "%"

                    if hpBarOn then
                        local barX = screenPos.X - BAR_WIDTH / 2
                        entry.hpBarBg.Position = Vector2.new(barX, barY)
                        entry.hpBarBg.Size = Vector2.new(BAR_WIDTH, BAR_HEIGHT)
                        entry.hpBarBg.Visible = onScreen

                        entry.hpBar.Position = Vector2.new(barX, barY)
                        entry.hpBar.Size = Vector2.new(BAR_WIDTH * ratio, BAR_HEIGHT)
                        entry.hpBar.Visible = onScreen

                        if pct <= 33 then
                            entry.hpBar.Color = Color3.fromRGB(255, 0, 0)
                        elseif pct <= 65 then
                            entry.hpBar.Color = Color3.fromRGB(255, 165, 0)
                        else
                            entry.hpBar.Color = Color3.fromRGB(0, 255, 0)
                        end

                        for i, line in ipairs(entry.hpLines) do
                            local lineX = barX + (BAR_WIDTH / SECTION_COUNT) * i
                            line.From = Vector2.new(lineX, barY)
                            line.To = Vector2.new(lineX, barY + BAR_HEIGHT)
                            line.Visible = onScreen
                        end

                        if hpText ~= entry.lastHp then
                            entry.hpLabel.Color = Color3.new(1 - ratio, ratio, 0)
                            entry.hpLabel.Text = hpText
                            entry.lastHp = hpText
                        end
                        entry.hpLabel.Visible = onScreen
                        entry.hpLabel.Position = Vector2.new(screenPos.X, barY + BAR_HEIGHT + 10)
                    else
                        entry.hpBar.Visible = false
                        entry.hpBarBg.Visible = false
                        for _, line in ipairs(entry.hpLines) do line.Visible = false end

                        if hpText ~= entry.lastHp then
                            entry.hpLabel.Color = Color3.new(1 - ratio, ratio, 0)
                            entry.hpLabel.Text = hpText
                            entry.lastHp = hpText
                        end
                        entry.hpLabel.Visible = onScreen
                        entry.hpLabel.Position = Vector2.new(screenPos.X, screenPos.Y + 18)
                    end
                else
                    entry.hpLabel.Visible = false
                    entry.hpBar.Visible = false
                    entry.hpBarBg.Visible = false
                    for _, line in ipairs(entry.hpLines) do line.Visible = false end
                end
            end
        end
    end
end)

spawn(function()
    while true do
        wait(0.01)
        local mobEspOn = UI.GetValue("mob_esp_on")
        local showCurrentHp = UI.GetValue("esp_currenthp")

        local activeMobs = {}
        for _, model in ipairs(live:GetChildren()) do
            local display, _ = getMobInfo(model.Name)
            if display then
                activeMobs[model.Name] = model
            end
        end

        for name in next, mobESPLabels do
            if not activeMobs[name] then removeMobESPLabel(name) end
        end

        if not mobEspOn then
            hideAllMobESP()
        else
            for name, model in next, activeMobs do
                local root = model:FindFirstChild("HumanoidRootPart")
                local humanoid = model:FindFirstChild("Humanoid")
                if not root or not humanoid then continue end

                if not mobESPLabels[name] then createMobESPLabel(name) end
                local entry = mobESPLabels[name]

                local screenPos, onScreen = safeWorldToScreen(root.Position + Vector3.new(0, 1.5, 0))

                if not screenPos then
                    entry.label.Visible = false
                    entry.hpLabel.Visible = false
                    continue
                end

                entry.label.Visible = onScreen
                entry.label.Position = Vector2.new(screenPos.X, screenPos.Y)

                local pct = math.floor(humanoid.Health / humanoid.MaxHealth * 100)
                local ratio = pct / 100
                local hpText = showCurrentHp and math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) or pct .. "%"

                if hpText ~= entry.lastHp then
                    entry.hpLabel.Color = Color3.new(1 - ratio, ratio, 0)
                    entry.hpLabel.Text = hpText
                    entry.lastHp = hpText
                end
                entry.hpLabel.Visible = onScreen
                entry.hpLabel.Position = Vector2.new(screenPos.X, screenPos.Y + 18)
            end
        end
    end
end)

local kb_up = nil
local kb_down = nil
local kb_toggle = nil
local kb_esp = nil
local kb_mob_esp = nil
local kb_show_health = nil
local lastToggleState = false

UI.AddTab("AgeplayPlayground", function(tab)
    local sec = tab:Section("Settings", "Left")
    sec:Toggle("agility_on", "Agility Spoof")
    kb_toggle = sec:Keybind("agility_toggle_kb", 0x70, "click")
    sec:Spacing()
    sec:SliderInt("agility_set_value", "Set Agility", 0, 1000, savedValue)
    sec:SliderInt("agility_cap", "Agility Cap", originalValue, 1000, 70)
    sec:Button("Apply", function()
        local setVal = UI.GetValue("agility_set_value")
        local cap = UI.GetValue("agility_cap")
        setVal = math.clamp(setVal, originalValue, cap)
        passiveAgilityPath.Value = setVal
        savedValue = setVal
        updateLabel()
        notify("Passive Agility set to " .. tostring(setVal), "Agility", 2)
    end)
    sec:Spacing()
    sec:Button("Increase +10")
    kb_up = sec:Keybind("agility_increase_kb", 0x06, "click")
    sec:Button("Decrease -10")
    kb_down = sec:Keybind("agility_decrease_kb", 0x05, "click")
    sec:Spacing()
    sec:Button("Reset Now", function()
        passiveAgilityPath.Value = originalValue
        savedValue = originalValue
        updateLabel()
        notify("Passive Agility reset to " .. tostring(originalValue), "Agility", 2)
    end)

    local esp = tab:Section("ESP", "Right")
    esp:Toggle("esp_on", "Player ESP", false)
    kb_esp = esp:Keybind("esp_kb", 0x42, "click")
    esp:Spacing()
    esp:Toggle("esp_hpbar", "Health Bar", false)
    esp:Spacing()
    esp:Toggle("esp_currenthp", "Show Health", false)
    kb_show_health = esp:Keybind("esp_currenthp_kb", 0, "always")
    esp:Spacing()
    esp:SliderInt("esp_distance", "Render Distance", 10, 30000, 5000)
    esp:Spacing()
    esp:Toggle("mob_esp_on", "Mob ESP", false)
    kb_mob_esp = esp:Keybind("mob_esp_kb", 0, "always")

    local info = tab:Section("Info", "Right")
    info:Text("Green = Spoof ON")
    info:Text("Red = Spoof OFF")
end)

while true do
    local spoofOn = UI.GetValue("agility_on")
    local cap = UI.GetValue("agility_cap") or 85

    if lastToggleState ~= spoofOn then
        if spoofOn then
            passiveAgilityPath.Value = savedValue
            updateLabel()
            notify("Agility spoof enabled, restored to " .. tostring(savedValue), "Agility", 2)
        else
            savedValue = passiveAgilityPath.Value
            passiveAgilityPath.Value = originalValue
            notify("Agility spoof disabled, reset to " .. tostring(originalValue), "Agility", 2)
        end
    end
    lastToggleState = spoofOn

    if kb_toggle and iskeypressed(kb_toggle:GetKey()) then
        UI.SetValue("agility_on", not spoofOn)
        wait(0.4)
    end

    if kb_esp and iskeypressed(kb_esp:GetKey()) then
        UI.SetValue("esp_on", not UI.GetValue("esp_on"))
        wait(0.4)
    end

    if kb_mob_esp and iskeypressed(kb_mob_esp:GetKey()) then
        UI.SetValue("mob_esp_on", not UI.GetValue("mob_esp_on"))
        wait(0.4)
    end

    if kb_show_health and iskeypressed(kb_show_health:GetKey()) then
        UI.SetValue("esp_currenthp", not UI.GetValue("esp_currenthp"))
        wait(0.4)
    end

    if spoofOn then
        label.Color = Color3.fromRGB(0, 255, 0)
    else
        label.Color = Color3.fromRGB(255, 0, 0)
    end

    if kb_up and iskeypressed(kb_up:GetKey()) then
        if spoofOn then
            local current = passiveAgilityPath.Value
            if current < cap then
                local newVal = math.min(current + 10, cap)
                passiveAgilityPath.Value = newVal
                savedValue = newVal
                updateLabel()
                notify("Passive Agility increased to " .. tostring(newVal), "Agility", 2)
            else
                notify("Agility cap of " .. tostring(cap) .. " reached!", "Agility", 2)
            end
        end
        wait(0.2)
    end

    if kb_down and iskeypressed(kb_down:GetKey()) then
        if spoofOn then
            local current = passiveAgilityPath.Value
            if current > originalValue then
                local newVal = math.max(current - 10, originalValue)
                passiveAgilityPath.Value = newVal
                savedValue = newVal
                updateLabel()
                notify("Passive Agility decreased to " .. tostring(newVal), "Agility", 2)
            else
                notify("Agility cannot go below your base of " .. tostring(originalValue) .. "!", "Agility", 2)
            end
        end
        wait(0.2)
    end

    wait(0.05)
end
