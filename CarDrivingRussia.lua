-- ═══════════════════════════════════════════════════════════════
-- INKASATOR AUTOFARM — GUI Corrigée + Compteurs intégrés
-- Base : pastebin.com/kcaG17S9 | Bugs réparés + UI étendue
-- ═══════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

-- ── Variables d'état ──────────────────────────────────────────
local farming        = false
local loopCount      = 0
local elapsedSeconds = 0

-- ── Références jeu ─────────────────────────────────────────────
-- WaitForChild DANS un task.spawn pour ne PAS bloquer la GUI
-- C'était la cause #1 du "black screen" : le script se bloquait
-- ici si les objets n'existaient pas encore, la GUI ne créait jamais
local inkUtils, zapravka2, endBase

task.spawn(function()
    inkUtils  = workspace:WaitForChild("Utilities"):WaitForChild("Inkasator")
    zapravka2 = inkUtils:WaitForChild("StartPoints"):WaitForChild("Zapravka2")
    endBase   = inkUtils:WaitForChild("EndPoints"):WaitForChild("Base")
end)

-- ═══ FONCTIONS ORIGINALES (kcaG17S9 — inchangées) ═════════════

local function getCar()
    local cars = workspace:FindFirstChild("Cars")
    if not cars then return nil end
    return cars:FindFirstChild(LocalPlayer.Name .. "sCar")
end

local function waitForCar(timeout)
    local t = 0
    while t < (timeout or 8) do
        local car = getCar()
        if car and car:FindFirstChild("DriveSeat") then return car end
        task.wait(0.3); t = t + 0.3
    end
    return getCar()
end

local function sitInDriveSeat()
    local car  = getCar(); if not car then return false end
    local seat = car:FindFirstChild("DriveSeat"); if not seat then return false end
    local char = LocalPlayer.Character; if not char then return false end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    if hum.SeatPart == seat then return true end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = seat.CFrame + Vector3.new(0, 2, 0) end
    task.wait(0.2); seat:Sit(hum); task.wait(0.5)
    return hum.SeatPart == seat
end

local function teleportCar(targetCF)
    local car  = getCar(); if not car then return false end
    local seat = car:FindFirstChild("DriveSeat"); if not seat then return false end
    car.PrimaryPart = seat
    local parts = {}
    for _, p in ipairs(car:GetDescendants()) do
        if p:IsA("BasePart") then
            table.insert(parts, {Part = p, WasAnchored = p.Anchored})
        end
    end
    local _, yRot, _ = targetCF:ToEulerAnglesYXZ()
    local uprightCF  = CFrame.new(targetCF.Position) * CFrame.Angles(0, yRot, 0)
    for _, d in ipairs(parts) do pcall(function()
        d.Part.AssemblyLinearVelocity  = Vector3.zero
        d.Part.AssemblyAngularVelocity = Vector3.zero
        d.Part.Velocity    = Vector3.zero
        d.Part.RotVelocity = Vector3.zero
    end) end
    for _, d in ipairs(parts) do pcall(function()
        d.Part.Anchored = true
    end) end
    task.wait(0.05)
    for i = 1, 8 do pcall(function() car:PivotTo(uprightCF) end) task.wait() end
    task.wait(0.2)
    for _, d in ipairs(parts) do pcall(function()
        d.Part.AssemblyLinearVelocity  = Vector3.zero
        d.Part.AssemblyAngularVelocity = Vector3.zero
        d.Part.Velocity    = Vector3.zero
        d.Part.RotVelocity = Vector3.zero
    end) end
    for _, d in ipairs(parts) do pcall(function()
        d.Part.Anchored = d.WasAnchored
    end) end
    task.spawn(function()
        for i = 1, 10 do pcall(function()
            seat.AssemblyLinearVelocity  = Vector3.zero
            seat.AssemblyAngularVelocity = Vector3.zero
            seat.Velocity    = Vector3.zero
            seat.RotVelocity = Vector3.zero
            car:PivotTo(uprightCF)
        end) task.wait() end
    end)
    task.wait(0.3); return true
end

local function findAndFirePrompt(targetPart)
    local function searchIn(parent)
        if not parent then return false end
        for _, desc in ipairs(parent:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(desc) end); return true
            end
        end
        local p = parent:FindFirstChildOfClass("ProximityPrompt")
        if p then pcall(function() fireproximityprompt(p) end); return true end
        return false
    end
    if searchIn(targetPart) then return true end
    if searchIn(targetPart.Parent) then return true end
    if inkUtils and searchIn(inkUtils) then return true end
    local car = getCar()
    if car and searchIn(car) then return true end
    local pos = targetPart.Position
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local p = desc.Parent
            if p and p:IsA("BasePart") and (p.Position - pos).Magnitude < 50 then
                pcall(function() fireproximityprompt(desc) end); return true
            end
        end
    end
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            local p = desc.Parent
            if p and p:IsA("BasePart") and (p.Position - pos).Magnitude < 50 then
                pcall(function() fireclickdetector(desc) end); return true
            end
        end
    end
    return false
end

local function firePromptRetry(targetPart, retries)
    if not targetPart then return false end
    retries = retries or 8
    for i = 1, retries do
        if findAndFirePrompt(targetPart) then return true end
        task.wait(0.3)
    end
    return false
end

local function startRoute()
    pcall(function()
        ReplicatedStorage
            :WaitForChild("InkasatorEvents")
            :WaitForChild("Trucker")
            :FireServer("startroute", "2")
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- GUI — CRÉATION IMMÉDIATE (rien ne bloque avant ce point)
-- ═══════════════════════════════════════════════════════════════

-- Détruit l'ancienne GUI si elle existe
local oldGui = game:GetService("CoreGui"):FindFirstChild("InkasatorAutofarm")
if oldGui then oldGui:Destroy() end

-- ScreenGui dans CoreGui (comme l'original)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "InkasatorAutofarm"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

-- ── Constantes de taille ──────────────────────────────────────
local W        = 210
local H_FULL   = 210   -- hauteur avec compteurs
local H_MINI   = 24    -- hauteur minimisée

-- ── Fenêtre principale ────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.fromOffset(W, H_FULL)
Main.Position         = UDim2.new(0, 8, 0.35, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.ClipsDescendants = false
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color     = Color3.fromRGB(50, 50, 80)
mainStroke.Thickness = 1.2

-- ── Topbar ────────────────────────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Name             = "TBar"
TBar.Size             = UDim2.new(1, 0, 0, 24)
TBar.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
TBar.BorderSizePixel  = 0
TBar.ZIndex           = 2
TBar.Parent           = Main
local tbCorner = Instance.new("UICorner", TBar)
tbCorner.CornerRadius = UDim.new(0, 10)
-- Bouche les coins bas de la topbar
local tbFix = Instance.new("Frame", TBar)
tbFix.Size             = UDim2.new(1, 0, 0, 10)
tbFix.Position         = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
tbFix.BorderSizePixel  = 0
tbFix.ZIndex           = 2

-- Séparateur topbar / contenu
local TBarSep = Instance.new("Frame", Main)
TBarSep.Size             = UDim2.new(1, 0, 0, 1)
TBarSep.Position         = UDim2.new(0, 0, 0, 24)
TBarSep.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TBarSep.BorderSizePixel  = 0
TBarSep.ZIndex           = 2

-- Mac dot : ROUGE (fermer)
local DotClose = Instance.new("Frame", TBar)
DotClose.Size             = UDim2.fromOffset(12, 12)
DotClose.Position         = UDim2.new(0, 8, 0.5, -6)
DotClose.BackgroundColor3 = Color3.fromRGB(244, 105, 95)
DotClose.BorderSizePixel  = 0
DotClose.ZIndex           = 3
Instance.new("UICorner", DotClose).CornerRadius = UDim.new(1, 0)
local BtnClose = Instance.new("TextButton", DotClose)
BtnClose.Size               = UDim2.new(1, 0, 1, 0)
BtnClose.BackgroundTransparency = 1
BtnClose.Text               = ""
BtnClose.ZIndex             = 4

-- Mac dot : JAUNE (minimize)
local DotMin = Instance.new("Frame", TBar)
DotMin.Size             = UDim2.fromOffset(12, 12)
DotMin.Position         = UDim2.new(0, 25, 0.5, -6)
DotMin.BackgroundColor3 = Color3.fromRGB(249, 190, 42)
DotMin.BorderSizePixel  = 0
DotMin.ZIndex           = 3
Instance.new("UICorner", DotMin).CornerRadius = UDim.new(1, 0)
local BtnMin = Instance.new("TextButton", DotMin)
BtnMin.Size               = UDim2.new(1, 0, 1, 0)
BtnMin.BackgroundTransparency = 1
BtnMin.Text               = ""
BtnMin.ZIndex             = 4

-- Mac dot : VERT (déco)
local DotGreen = Instance.new("Frame", TBar)
DotGreen.Size             = UDim2.fromOffset(12, 12)
DotGreen.Position         = UDim2.new(0, 42, 0.5, -6)
DotGreen.BackgroundColor3 = Color3.fromRGB(98, 197, 84)
DotGreen.BorderSizePixel  = 0
DotGreen.ZIndex           = 3
Instance.new("UICorner", DotGreen).CornerRadius = UDim.new(1, 0)

-- Titre topbar
local TTitle = Instance.new("TextLabel", TBar)
TTitle.Size               = UDim2.new(1, -65, 1, 0)
TTitle.Position           = UDim2.new(0, 62, 0, 0)
TTitle.BackgroundTransparency = 1
TTitle.Text               = "💰 Inkasator Farm"
TTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
TTitle.TextSize           = 11
TTitle.Font               = Enum.Font.GothamBold
TTitle.TextXAlignment     = Enum.TextXAlignment.Left
TTitle.ZIndex             = 3

-- ── Zone de contenu (sous topbar) ────────────────────────────
local Content = Instance.new("Frame", Main)
Content.Name                = "Content"
Content.Size                = UDim2.new(1, -16, 1, -32)
Content.Position            = UDim2.new(0, 8, 0, 28)
Content.BackgroundTransparency = 1
Content.ZIndex              = 2

-- ── UIListLayout pour empiler proprement ─────────────────────
local Layout = Instance.new("UIListLayout", Content)
Layout.SortOrder        = Enum.SortOrder.LayoutOrder
Layout.FillDirection    = Enum.FillDirection.Vertical
Layout.Padding          = UDim.new(0, 6)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- ═══════════════════════════════════════════════════════════════
-- BOUTON AUTO FARM
-- ═══════════════════════════════════════════════════════════════
local ToggleBtn = Instance.new("TextButton", Content)
ToggleBtn.Name             = "ToggleBtn"
ToggleBtn.LayoutOrder      = 1
ToggleBtn.Size             = UDim2.new(1, 0, 0, 38)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 170, 35)
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Text             = "▶  START FARM"
ToggleBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize         = 13
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor  = false
ToggleBtn.ZIndex           = 3
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

-- ═══════════════════════════════════════════════════════════════
-- CADRE COMPTEURS (sous le bouton)
-- ═══════════════════════════════════════════════════════════════
local StatsFrame = Instance.new("Frame", Content)
StatsFrame.Name             = "StatsFrame"
StatsFrame.LayoutOrder      = 2
StatsFrame.Size             = UDim2.new(1, 0, 0, 120)
StatsFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
StatsFrame.BorderSizePixel  = 0
StatsFrame.ZIndex           = 3
Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 8)
local sfStroke = Instance.new("UIStroke", StatsFrame)
sfStroke.Color     = Color3.fromRGB(40, 40, 65)
sfStroke.Thickness = 1

-- Helper : crée une ligne [icône | label | valeur]
local function makeRow(icon, label, defaultVal, yPos, valColor)
    local ico = Instance.new("TextLabel", StatsFrame)
    ico.Size               = UDim2.new(0, 24, 0, 30)
    ico.Position           = UDim2.new(0, 6, 0, yPos)
    ico.BackgroundTransparency = 1
    ico.Text               = icon
    ico.TextSize           = 14
    ico.Font               = Enum.Font.Gotham
    ico.TextColor3         = Color3.fromRGB(140, 140, 180)
    ico.TextXAlignment     = Enum.TextXAlignment.Center
    ico.ZIndex             = 4

    local lbl = Instance.new("TextLabel", StatsFrame)
    lbl.Size               = UDim2.new(0, 90, 0, 30)
    lbl.Position           = UDim2.new(0, 30, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.GothamMedium
    lbl.TextColor3         = Color3.fromRGB(110, 110, 150)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 4

    local val = Instance.new("TextLabel", StatsFrame)
    val.Size               = UDim2.new(0, 70, 0, 30)
    val.Position           = UDim2.new(1, -76, 0, yPos)
    val.BackgroundTransparency = 1
    val.Text               = defaultVal
    val.TextSize           = 12
    val.Font               = Enum.Font.GothamBold
    val.TextColor3         = valColor or Color3.fromRGB(220, 220, 255)
    val.TextXAlignment     = Enum.TextXAlignment.Right
    val.ZIndex             = 4

    return val  -- on retourne le label valeur pour le mettre à jour
end

-- Séparateur interne
local function makeSep(yPos)
    local s = Instance.new("Frame", StatsFrame)
    s.Size             = UDim2.new(1, -10, 0, 1)
    s.Position         = UDim2.new(0, 5, 0, yPos)
    s.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    s.BorderSizePixel  = 0
    s.ZIndex           = 4
end

-- ── Ligne 1 : Statut ──────────────────────────────────────────
local valStatut = makeRow("●", "Statut", "⏸ Arrêté", 4,
    Color3.fromRGB(180, 80, 80))

makeSep(34)

-- ── Ligne 2 : Boucles ─────────────────────────────────────────
local valBoucles = makeRow("🔄", "Boucles", "0", 37,
    Color3.fromRGB(99, 180, 255))

makeSep(67)

-- ── Ligne 3 : Chrono ──────────────────────────────────────────
local valChrono = makeRow("⏱", "Chrono", "00:00:00", 70,
    Color3.fromRGB(180, 255, 180))

makeSep(100)

-- ── Ligne 4 : Cycle ───────────────────────────────────────────
local valCycle = makeRow("⚡", "Cycle", "4s", 103,
    Color3.fromRGB(255, 210, 100))

-- ═══════════════════════════════════════════════════════════════
-- SETTERS UI — simples, directs, sans pcall qui cache les erreurs
-- ═══════════════════════════════════════════════════════════════

local function formatTime(s)
    return string.format("%02d:%02d:%02d",
        math.floor(s / 3600),
        math.floor((s % 3600) / 60),
        s % 60)
end

-- Statut : Chargement (jaune)
local function setLoading(etape)
    valStatut.Text       = "⚙ " .. (etape or "Chargement...")
    valStatut.TextColor3 = Color3.fromRGB(249, 190, 42)
end

-- Statut : Actif (vert)
local function setRunning()
    valStatut.Text       = "▶ Actif"
    valStatut.TextColor3 = Color3.fromRGB(80, 210, 80)
end

-- Statut : Arrêté (rouge)
local function setStopped()
    valStatut.Text       = "⏸ Arrêté"
    valStatut.TextColor3 = Color3.fromRGB(180, 80, 80)
end

-- Met à jour boucles + chrono
local function updateCounters()
    valBoucles.Text = tostring(loopCount)
    valChrono.Text  = formatTime(elapsedSeconds)
end

-- ═══════════════════════════════════════════════════════════════
-- BOUCLE PRINCIPALE — cycle de 4 secondes
-- Déclarée AVANT le callback du Toggle
-- ═══════════════════════════════════════════════════════════════
local function farmLoop()
    -- Sécurité : les refs doivent exister
    if not inkUtils or not zapravka2 or not endBase then
        -- Attend max 10s que les refs soient chargées
        local t = 0
        while (not inkUtils or not zapravka2 or not endBase) and t < 10 do
            task.wait(0.5); t = t + 0.5
        end
        if not inkUtils or not zapravka2 or not endBase then
            setStopped(); return
        end
    end

    while farming do

        -- ① Démarrage de la route
        setLoading("Démarrage route...")
        startRoute()
        task.wait(1.5)
        if not farming then break end

        -- ② Attente voiture
        setLoading("Attente voiture...")
        local car = waitForCar(8)
        if not car then
            setLoading("Voiture intro... retry")
            task.wait(2); continue
        end
        if not farming then break end

        -- ③ Monter en voiture
        setLoading("Montée voiture...")
        sitInDriveSeat()
        task.wait(0.5)
        if not farming then break end

        -- ④ TP → Point de chargement
        setLoading("TP chargement...")
        local zapCF = zapravka2.CFrame * CFrame.new(0, 5, 0)
        if not teleportCar(zapCF) then
            task.wait(1); continue
        end
        task.wait(0.5)
        if not farming then break end

        -- ⑤ Activation prompt + attente 4 secondes (cycle principal)
        setLoading("Collecte argent...")
        firePromptRetry(zapravka2, 8)
        -- Compte à rebours 4s visible dans le label cycle
        for i = 4, 1, -1 do
            if not farming then break end
            valCycle.Text = "⏳ " .. i .. "s"
            task.wait(1)
        end
        valCycle.Text = "4s"
        if not farming then break end

        -- ⑥ TP → Point de dépôt
        setLoading("TP dépôt...")
        local endCF = endBase.CFrame * CFrame.new(0, 5, 0)
        if not teleportCar(endCF) then
            task.wait(1); continue
        end
        task.wait(0.5)
        if not farming then break end

        -- ⑦ Dépôt
        setLoading("Dépôt...")
        firePromptRetry(endBase, 8)
        task.wait(0.5)

        -- ✅ Fin du cycle
        loopCount = loopCount + 1
        setRunning()
        updateCounters()
        task.wait(1)
    end

    setStopped()
    updateCounters()
end

-- ═══════════════════════════════════════════════════════════════
-- TOGGLE BUTTON — connecté à farmLoop
-- ═══════════════════════════════════════════════════════════════
ToggleBtn.MouseButton1Click:Connect(function()
    farming = not farming

    if farming then
        -- Démarrage
        loopCount      = 0
        elapsedSeconds = 0
        updateCounters()
        ToggleBtn.Text             = "⏹  STOP FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        setLoading("Initialisation...")
        task.spawn(farmLoop)  -- thread séparé = GUI non bloquée
    else
        -- Arrêt immédiat
        ToggleBtn.Text             = "▶  START FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 170, 35)
        setStopped()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- TIMER TEMPS RÉEL — thread indépendant, +1s chaque seconde
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1)
        if farming then
            elapsedSeconds = elapsedSeconds + 1
            valChrono.Text = formatTime(elapsedSeconds)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MAC DOTS — minimize & fermer
-- ═══════════════════════════════════════════════════════════════
local minimized = false

BtnMin.MouseButton1Click:Connect(function()
    minimized       = not minimized
    Content.Visible = not minimized
    Main.Size       = UDim2.fromOffset(W, minimized and H_MINI or H_FULL)
end)

BtnClose.MouseButton1Click:Connect(function()
    farming = false
    setStopped()
    task.wait(0.05)
    ScreenGui:Destroy()
end)

-- ═══════════════════════════════════════════════════════════════
-- RESPAWN — remet au volant si farm actif
-- ═══════════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    if farming then
        task.wait(2)
        if farming then sitInDriveSeat() end
    end
end)
