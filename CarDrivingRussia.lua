-- ═══════════════════════════════════════════════════════════════
-- SERVICES & CONFIG (Key System)
-- ═══════════════════════════════════════════════════════════════
local Config       = { ApiUrl = "https://hyperhub-bot.onrender.com/verify", ApiToken = "lolilol980", ValidKeys = {} }
local Players      = game:GetService("Players")
local HTTP         = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Player       = Players.LocalPlayer
local PlayerGui    = Player:WaitForChild("PlayerGui")
local SaveFolder   = "HyperHub"
local SaveFile     = SaveFolder .. "/" .. tostring(Player.UserId) .. ".key"

local function Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end
local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end
local function AddHover(btn, normal, hover)
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = hover}) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = normal}) end)
end
local function KeyFile(action, data)
    if action == "save" then
        pcall(function()
            if not isfolder(SaveFolder) then makefolder(SaveFolder) end
            writefile(SaveFile, data)
        end)
    elseif action == "load" then
        local ok, r = pcall(function()
            return (isfolder(SaveFolder) and isfile(SaveFile)) and readfile(SaveFile) or nil
        end)
        return ok and r or nil
    end
end
local function ValidateKey(cleanKey)
    for _, v in ipairs(Config.ValidKeys) do
        if cleanKey == v:upper() then return true, {valid=true, type="perm", expiresAt=nil} end
    end
    local ok, response = pcall(function()
        return HTTP:RequestAsync({
            Url = Config.ApiUrl, Method = "POST",
            Headers = {["Content-Type"]="application/json", ["Authorization"]=Config.ApiToken},
            Body = HTTP:JSONEncode({key=cleanKey, userId=tostring(Player.UserId), username=Player.Name}),
        })
    end)
    if not ok then return false, {reason="Connection error"} end
    local dok, data = pcall(function() return HTTP:JSONDecode(response.Body) end)
    if dok and data and data.valid then return true, data end
    return false, (dok and data) or {reason="Invalid key"}
end

-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM GUI
-- ═══════════════════════════════════════════════════════════════
local IsActivating = false
local OldGui = PlayerGui:FindFirstChild("HyperHubKey")
if OldGui then OldGui:Destroy() end
local KeyGui = Make("ScreenGui", {
    Name="HyperHubKey", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true,
    DisplayOrder=999,
}, PlayerGui)
local Blur    = Make("BlurEffect", {Size=24}, game:GetService("Lighting"))
local Overlay = Make("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.4,
    BorderSizePixel=0, ZIndex=5
}, KeyGui)
local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function m(a,b) return IsMobile and a or b end
local W, H = m(260,420), m(355,480)
local KeyFrame = Make("Frame", {
    Size=UDim2.fromOffset(W,H),
    Position=UDim2.new(0.5,-W/2,0.5,-H/2),
    BackgroundColor3=Color3.fromRGB(18,18,26),
    BorderSizePixel=0, ZIndex=10, Active=true,
    ClipsDescendants=false,
}, KeyGui)
Make("UICorner", {CornerRadius=UDim.new(0,14)}, KeyFrame)
Make("UIStroke", {Color=Color3.fromRGB(60,60,90), Thickness=1.5}, KeyFrame)
-- Drag
local dragging, dragStart, startPos = false, nil, nil
KeyFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, KeyFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        KeyFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)
-- Topbar
local Topbar = Make("Frame", {
    Size=UDim2.new(1,0,0,44),
    BackgroundColor3=Color3.fromRGB(22,22,34),
    BorderSizePixel=0, ZIndex=11
}, KeyFrame)
Make("UICorner", {CornerRadius=UDim.new(0,14)}, Topbar)
Make("Frame", {
    Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
    BackgroundColor3=Color3.fromRGB(22,22,34), BorderSizePixel=0, ZIndex=11
}, Topbar)
Make("Frame", {
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,44),
    BackgroundColor3=Color3.fromRGB(35,35,55), BorderSizePixel=0, ZIndex=11
}, KeyFrame)
-- Bouton fermer Mac
local MacBtn = Make("Frame", {
    Size=UDim2.fromOffset(13,13), Position=UDim2.new(0,12,0.5,-6),
    BackgroundColor3=Color3.fromHex("#F4695F"), BorderSizePixel=0, ZIndex=12
}, Topbar)
Make("UICorner", {CornerRadius=UDim.new(1,0)}, MacBtn)
local MacClose = Make("TextButton", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="", ZIndex=13, AutoButtonColor=false
}, MacBtn)
MacClose.MouseButton1Click:Connect(function()
    Tween(KeyFrame, {BackgroundTransparency=1}, 0.3)
    Tween(Overlay,  {BackgroundTransparency=1}, 0.3)
    task.wait(0.35)
    KeyGui:Destroy()
    Blur:Destroy()
end)
-- Tag v3.0
local TagFrame = Make("Frame", {
    Size=UDim2.fromOffset(m(48,64), 22),
    Position=UDim2.new(1, m(-58,-76), 0.5, -11),
    BackgroundColor3=Color3.fromRGB(99,102,241),
    BorderSizePixel=0, ZIndex=12
}, Topbar)
Make("UICorner", {CornerRadius=UDim.new(0,6)}, TagFrame)
Make("TextLabel", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="⚡ v3.0", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=m(8,11),
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=13
}, TagFrame)
-- Contenu key
local KeyContent = Make("Frame", {
    Size=UDim2.new(1,-36,1,-58),
    Position=UDim2.new(0,18,0,52),
    BackgroundTransparency=1, ZIndex=11,
    ClipsDescendants=false,
}, KeyFrame)
Make("UIListLayout", {
    SortOrder=Enum.SortOrder.LayoutOrder,
    FillDirection=Enum.FillDirection.Vertical,
    HorizontalAlignment=Enum.HorizontalAlignment.Center,
    VerticalAlignment=Enum.VerticalAlignment.Top,
    Padding=UDim.new(0, m(6,10)),
}, KeyContent)
Make("TextLabel", {
    Size=UDim2.new(1,0,0,m(22,30)), BackgroundTransparency=1,
    Text="⚡ Hyper Hub", TextColor3=Color3.fromRGB(99,102,241),
    Font=Enum.Font.GothamBold, TextSize=m(15,22),
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=12, LayoutOrder=1,
}, KeyContent)
Make("TextLabel", {
    Size=UDim2.new(1,0,0,m(34,50)), BackgroundTransparency=1,
    Text="🔑", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=m(26,38),
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=12, LayoutOrder=2,
}, KeyContent)
Make("TextLabel", {
    Size=UDim2.new(1,0,0,m(20,28)), BackgroundTransparency=1,
    Text="License Activation", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=m(13,20),
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=12, LayoutOrder=3,
}, KeyContent)
Make("TextLabel", {
    Size=UDim2.new(1,0,0,m(14,20)), BackgroundTransparency=1,
    Text="Enter your license key to continue",
    TextColor3=Color3.fromRGB(100,100,130),
    Font=Enum.Font.Gotham, TextSize=m(8,12),
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=12, LayoutOrder=4,
}, KeyContent)
-- Input
local InputContainer = Make("Frame", {
    Size=UDim2.new(1,0,0,m(34,46)),
    BackgroundColor3=Color3.fromRGB(26,26,40),
    BorderSizePixel=0, ZIndex=12, LayoutOrder=5,
}, KeyContent)
Make("UICorner", {CornerRadius=UDim.new(0,10)}, InputContainer)
local InputStroke = Make("UIStroke", {Color=Color3.fromRGB(45,45,68), Thickness=1.2}, InputContainer)
local savedKey      = KeyFile("load")
local savedKeyClean = savedKey and savedKey:upper():gsub("%s+","") or nil
local InputBox = Make("TextBox", {
    Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,
    Text=savedKeyClean or "",
    PlaceholderText="Ex: XXXX-XXXX-XXXX-XXXX",
    TextColor3=Color3.new(1,1,1),
    PlaceholderColor3=Color3.fromRGB(70,70,95),
    Font=Enum.Font.GothamBold, TextSize=m(10,13),
    ClearTextOnFocus=false, ZIndex=13,
}, InputContainer)
InputBox.Focused:Connect(function()
    Tween(InputStroke, {Color=Color3.fromRGB(99,102,241)})
    Tween(InputContainer, {BackgroundColor3=Color3.fromRGB(30,30,50)})
end)
InputBox.FocusLost:Connect(function()
    Tween(InputStroke, {Color=Color3.fromRGB(45,45,68)})
    Tween(InputContainer, {BackgroundColor3=Color3.fromRGB(26,26,40)})
end)
-- Bouton Verify
local VerifyBtn = Make("TextButton", {
    Size=UDim2.new(1,0,0,m(34,48)),
    BackgroundColor3=Color3.fromRGB(99,102,241),
    Text="Verify Key", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=m(11,15),
    BorderSizePixel=0, AutoButtonColor=false,
    ZIndex=12, LayoutOrder=6,
}, KeyContent)
Make("UICorner", {CornerRadius=UDim.new(0,10)}, VerifyBtn)
Make("UIGradient", {
    Color=ColorSequence.new(Color3.fromHex("#6366f1"), Color3.fromHex("#8b5cf6")),
    Rotation=90
}, VerifyBtn)
AddHover(VerifyBtn, Color3.fromRGB(99,102,241), Color3.fromRGB(120,124,255))
-- Status label key
local KeyStatusLabel = Make("TextLabel", {
    Size=UDim2.new(1,0,0,m(20,24)), BackgroundTransparency=1,
    Text="", TextColor3=Color3.fromRGB(100,100,130),
    Font=Enum.Font.GothamBold, TextSize=m(9,12),
    TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=12, LayoutOrder=7,
}, KeyContent)
-- Bouton Close key
local KeyCloseBtn = Make("TextButton", {
    Size=UDim2.new(1,0,0,m(30,42)),
    BackgroundColor3=Color3.fromRGB(28,28,42),
    Text="", BorderSizePixel=0, AutoButtonColor=false,
    ZIndex=12, LayoutOrder=8,
}, KeyContent)
Make("UICorner", {CornerRadius=UDim.new(0,10)}, KeyCloseBtn)
local closeStroke = Make("UIStroke", {Color=Color3.fromRGB(60,60,90), Thickness=1.2}, KeyCloseBtn)
Make("TextLabel", {
    Size=UDim2.new(0,20,1,0), Position=UDim2.new(0.5,-36,0,0),
    BackgroundTransparency=1, Text="✕",
    TextColor3=Color3.fromRGB(200,80,80),
    Font=Enum.Font.GothamBold, TextSize=m(12,15),
    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=13
}, KeyCloseBtn)
Make("TextLabel", {
    Size=UDim2.new(0,60,1,0), Position=UDim2.new(0.5,-16,0,0),
    BackgroundTransparency=1, Text="Close",
    TextColor3=Color3.fromRGB(180,180,210),
    Font=Enum.Font.GothamBold, TextSize=m(10,13),
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13
}, KeyCloseBtn)
KeyCloseBtn.MouseEnter:Connect(function()
    Tween(KeyCloseBtn, {BackgroundColor3=Color3.fromRGB(50,22,22)})
    Tween(closeStroke, {Color=Color3.fromRGB(180,50,50)})
end)
KeyCloseBtn.MouseLeave:Connect(function()
    Tween(KeyCloseBtn, {BackgroundColor3=Color3.fromRGB(28,28,42)})
    Tween(closeStroke, {Color=Color3.fromRGB(60,60,90)})
end)
KeyCloseBtn.MouseButton1Click:Connect(function()
    Tween(KeyFrame, {BackgroundTransparency=1}, 0.3)
    Tween(Overlay,  {BackgroundTransparency=1}, 0.3)
    task.wait(0.35)
    KeyGui:Destroy()
    Blur:Destroy()
end)
-- Discord
Make("TextLabel", {
    Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
    Text="discord.gg/hyperhub",
    TextColor3=Color3.fromRGB(50,50,75),
    Font=Enum.Font.Gotham, TextSize=m(8,10),
    TextXAlignment=Enum.TextXAlignment.Center,
    ZIndex=12, LayoutOrder=9,
}, KeyContent)

-- ═══════════════════════════════════════════════════════════════
-- CALLBACK POST-VALIDATION : lance l'Inkasator Autofarm
-- ═══════════════════════════════════════════════════════════════
local function OnKeyValidated(licenseData)

    -- ═══ INKASATOR AUTOFARM ═══
    -- Autofarm collecte d'argent (Mobile friendly)

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    local farming = false
    local loopCount = 0

    -- ═══ REFERENCES ═══
    local inkUtils = workspace:WaitForChild("Utilities"):WaitForChild("Inkasator")
    local zapravka2 = inkUtils:WaitForChild("StartPoints"):WaitForChild("Zapravka2")
    local endBase = inkUtils:WaitForChild("EndPoints"):WaitForChild("Base")

    -- ═══ FONCTIONS ═══

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
            task.wait(0.3)
            t = t + 0.3
        end
        return getCar()
    end

    local function sitInDriveSeat()
        local car = getCar()
        if not car then return false end

        local seat = car:FindFirstChild("DriveSeat")
        if not seat then return false end

        local char = LocalPlayer.Character
        if not char then return false end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end

        if hum.SeatPart == seat then return true end

        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
        end
        task.wait(0.2)
        seat:Sit(hum)
        task.wait(0.5)

        return hum.SeatPart == seat
    end

    -- ═══ TELEPORTATION ANTI-FLIP ═══
    local function teleportCar(targetCF)
        local car = getCar()
        if not car then return false end

        local seat = car:FindFirstChild("DriveSeat")
        if not seat then return false end

        car.PrimaryPart = seat

        local parts = {}
        for _, p in ipairs(car:GetDescendants()) do
            if p:IsA("BasePart") then
                table.insert(parts, {Part = p, WasAnchored = p.Anchored})
            end
        end

        local targetPos = targetCF.Position
        local _, targetYRot, _ = targetCF:ToEulerAnglesYXZ()
        local uprightCF = CFrame.new(targetPos) * CFrame.Angles(0, targetYRot, 0)

        for _, data in ipairs(parts) do
            pcall(function()
                data.Part.AssemblyLinearVelocity = Vector3.zero
                data.Part.AssemblyAngularVelocity = Vector3.zero
                data.Part.Velocity = Vector3.zero
                data.Part.RotVelocity = Vector3.zero
            end)
        end

        for _, data in ipairs(parts) do
            pcall(function()
                data.Part.Anchored = true
            end)
        end
        task.wait(0.05)

        for i = 1, 8 do
            pcall(function()
                car:PivotTo(uprightCF)
            end)
            task.wait()
        end

        task.wait(0.2)

        for _, data in ipairs(parts) do
            pcall(function()
                data.Part.AssemblyLinearVelocity = Vector3.zero
                data.Part.AssemblyAngularVelocity = Vector3.zero
                data.Part.Velocity = Vector3.zero
                data.Part.RotVelocity = Vector3.zero
            end)
        end

        for _, data in ipairs(parts) do
            pcall(function()
                data.Part.Anchored = data.WasAnchored
            end)
        end

        task.spawn(function()
            for i = 1, 10 do
                pcall(function()
                    seat.AssemblyLinearVelocity = Vector3.zero
                    seat.AssemblyAngularVelocity = Vector3.zero
                    seat.Velocity = Vector3.zero
                    seat.RotVelocity = Vector3.zero
                    car:PivotTo(uprightCF)
                end)
                task.wait()
            end
        end)

        task.wait(0.3)
        return true
    end

    -- ═══ FIRE PROMPT ═══
    local function findAndFirePrompt(targetPart)
        local function searchIn(parent)
            if not parent then return false end
            for _, desc in ipairs(parent:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    pcall(function() fireproximityprompt(desc) end)
                    return true
                end
            end
            local p = parent:FindFirstChildOfClass("ProximityPrompt")
            if p then
                pcall(function() fireproximityprompt(p) end)
                return true
            end
            return false
        end

        if searchIn(targetPart) then return true end
        if searchIn(targetPart.Parent) then return true end
        if searchIn(inkUtils) then return true end

        local car = getCar()
        if car and searchIn(car) then return true end

        local pos = targetPart.Position
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local p = desc.Parent
                if p and p:IsA("BasePart") and (p.Position - pos).Magnitude < 50 then
                    pcall(function() fireproximityprompt(desc) end)
                    return true
                end
            end
        end

        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ClickDetector") then
                local p = desc.Parent
                if p and p:IsA("BasePart") and (p.Position - pos).Magnitude < 50 then
                    pcall(function() fireclickdetector(desc) end)
                    return true
                end
            end
        end

        return false
    end

    local function firePromptRetry(targetPart, retries)
        retries = retries or 8
        for i = 1, retries do
            if findAndFirePrompt(targetPart) then return true end
            task.wait(0.3)
        end
        return false
    end

    local function startRoute()
        pcall(function()
            ReplicatedStorage:WaitForChild("InkasatorEvents"):WaitForChild("Trucker"):FireServer("startroute", "2")
        end)
    end

    -- ═══ GUI MOBILE ═══
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InkasatorAutofarm"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 170, 0, 105)
    Main.Position = UDim2.new(0, 8, 0.35, 0)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

    local TBar = Instance.new("Frame")
    TBar.Size = UDim2.new(1, 0, 0, 20)
    TBar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    TBar.BorderSizePixel = 0
    TBar.Parent = Main
    Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 8)

    local TTitle = Instance.new("TextLabel")
    TTitle.Size = UDim2.new(1, -42, 1, 0)
    TTitle.Position = UDim2.new(0, 6, 0, 0)
    TTitle.BackgroundTransparency = 1
    TTitle.Text = "💰 Inkasator Farm"
    TTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
    TTitle.TextSize = 10
    TTitle.Font = Enum.Font.GothamBold
    TTitle.TextXAlignment = Enum.TextXAlignment.Left
    TTitle.Parent = TBar

    local minimized = false
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 16, 0, 16)
    MinBtn.Position = UDim2.new(1, -38, 0, 2)
    MinBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 40)
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    MinBtn.TextSize = 12
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TBar
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 16, 0, 16)
    CloseBtn.Position = UDim2.new(1, -19, 0, 2)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 9
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, -20)
    Content.Position = UDim2.new(0, 0, 0, 20)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        Main.Size = minimized and UDim2.new(0, 170, 0, 20) or UDim2.new(0, 170, 0, 105)
        MinBtn.Text = minimized and "+" or "-"
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        farming = false
        ScreenGui:Destroy()
    end)

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, -10, 0, 26)
    ToggleBtn.Position = UDim2.new(0, 5, 0, 3)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 170, 35)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = "▶ START"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 12
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Parent = Content
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

    local StatusLbl = Instance.new("TextLabel")
    StatusLbl.Size = UDim2.new(1, -10, 0, 14)
    StatusLbl.Position = UDim2.new(0, 5, 0, 33)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Text = "⏸ Prêt"
    StatusLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    StatusLbl.TextSize = 9
    StatusLbl.Font = Enum.Font.GothamMedium
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    StatusLbl.TextTruncate = Enum.TextTruncate.AtEnd
    StatusLbl.Parent = Content

    local StepLbl = Instance.new("TextLabel")
    StepLbl.Size = UDim2.new(1, -10, 0, 14)
    StepLbl.Position = UDim2.new(0, 5, 0, 48)
    StepLbl.BackgroundTransparency = 1
    StepLbl.Text = ""
    StepLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
    StepLbl.TextSize = 8
    StepLbl.Font = Enum.Font.GothamMedium
    StepLbl.TextXAlignment = Enum.TextXAlignment.Left
    StepLbl.TextTruncate = Enum.TextTruncate.AtEnd
    StepLbl.Parent = Content

    local CountLbl = Instance.new("TextLabel")
    CountLbl.Size = UDim2.new(1, -10, 0, 14)
    CountLbl.Position = UDim2.new(0, 5, 0, 63)
    CountLbl.BackgroundTransparency = 1
    CountLbl.Text = "🔄 Boucles: 0"
    CountLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
    CountLbl.TextSize = 9
    CountLbl.Font = Enum.Font.GothamMedium
    CountLbl.TextXAlignment = Enum.TextXAlignment.Left
    CountLbl.Parent = Content

    local function setStatus(txt, col)
        StatusLbl.Text = txt
        StatusLbl.TextColor3 = col or Color3.fromRGB(180, 180, 180)
    end

    local function setStep(txt)
        StepLbl.Text = txt
    end

    -- ═══ BOUCLE PRINCIPALE ═══
    local function farmLoop()
        while farming do
            -- 1 : Démarrer la route
            setStatus("🔄 Démarrage route...", Color3.fromRGB(255, 200, 0))
            setStep("[1/7] FireServer startroute 2")
            startRoute()
            task.wait(1.5)
            if not farming then break end

            -- 2 : Attendre la voiture
            setStatus("⏳ Attente voiture...", Color3.fromRGB(255, 200, 0))
            setStep("[2/7] Recherche voiture...")
            local car = waitForCar(8)
            if not car then
                setStatus("❌ Voiture introuvable !", Color3.fromRGB(255, 50, 50))
                setStep("Retry dans 2s...")
                task.wait(2)
                continue
            end
            if not farming then break end

            -- 3 : Monter dans la voiture
            setStatus("🪑 Montée voiture...", Color3.fromRGB(255, 200, 0))
            setStep("[3/7] Sit DriveSeat")
            sitInDriveSeat()
            task.wait(0.5)
            if not farming then break end

            -- 4 : TP au point de chargement (Zapravka2)
            setStatus("📍 TP → Chargement...", Color3.fromRGB(100, 180, 255))
            setStep("[4/7] TP Zapravka2")
            local zapCF = zapravka2.CFrame * CFrame.new(0, 5, 0)
            if not teleportCar(zapCF) then
                setStatus("❌ Échec TP chargement", Color3.fromRGB(255, 50, 50))
                task.wait(1)
                continue
            end
            task.wait(0.5)
            if not farming then break end

            -- 5 : Récupérer l'argent + attente 4s
            setStatus("💵 Récupérer argent...", Color3.fromRGB(100, 255, 100))
            setStep("[5/7] Prompt Zapravka2")
            firePromptRetry(zapravka2, 8)

            for i = 4, 1, -1 do
                if not farming then break end
                setStatus("⏳ Chargement... " .. i .. "s", Color3.fromRGB(255, 255, 100))
                setStep("[5/7] Récupération argent")
                task.wait(1)
            end
            if not farming then break end

            -- 6 : TP au point de dépôt (EndPoints.Base)
            setStatus("📍 TP → Dépôt...", Color3.fromRGB(100, 180, 255))
            setStep("[6/7] TP EndPoints Base")
            local endCF = endBase.CFrame * CFrame.new(0, 5, 0)
            if not teleportCar(endCF) then
                setStatus("❌ Échec TP dépôt", Color3.fromRGB(255, 50, 50))
                task.wait(1)
                continue
            end
            task.wait(0.5)
            if not farming then break end

            -- 7 : Interagir (déposer l'argent)
            setStatus("🏦 Interagir...", Color3.fromRGB(100, 255, 100))
            setStep("[7/7] Prompt Base")
            firePromptRetry(endBase, 8)
            task.wait(0.5)

            -- Boucle terminée
            loopCount = loopCount + 1
            CountLbl.Text = "🔄 Boucles: " .. loopCount
            setStatus("✅ Boucle " .. loopCount .. " OK!", Color3.fromRGB(0, 255, 100))
            setStep("Redémarrage...")
            task.wait(1)
        end

        setStatus("⏸ Arrêté", Color3.fromRGB(180, 180, 180))
        setStep("")
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        farming = not farming

        if farming then
            ToggleBtn.Text = "⏹ STOP"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            task.spawn(farmLoop)
        else
            ToggleBtn.Text = "▶ START"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 170, 35)
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        if farming then
            task.wait(2)
            if farming then
                sitInDriveSeat()
            end
        end
    end)

    setStatus("⏸ Prêt", Color3.fromRGB(180, 180, 180))
    warn("[Hub] Inkasator Autofarm chargé avec succès!")
end

-- ═══════════════════════════════════════════════════════════════
-- LOGIQUE DE VÉRIFICATION
-- ═══════════════════════════════════════════════════════════════
local function TryVerify(key)
    if key == "" then
        KeyStatusLabel.Text       = "⚠ Please enter a license key"
        KeyStatusLabel.TextColor3 = Color3.fromRGB(234,179,8)
        return
    end
    if IsActivating then return end
    IsActivating              = true
    VerifyBtn.Text            = "Verifying..."
    Tween(VerifyBtn, {BackgroundColor3=Color3.fromRGB(50,50,80)})
    KeyStatusLabel.Text       = "Connecting to server..."
    KeyStatusLabel.TextColor3 = Color3.fromRGB(100,100,140)
    task.spawn(function()
        local cleanKey    = key:upper():gsub("%s+","")
        local valid, data = ValidateKey(cleanKey)
        if valid then
            KeyFile("save", cleanKey)
            KeyStatusLabel.Text       = "✔ Valid key! Loading..."
            KeyStatusLabel.TextColor3 = Color3.fromRGB(34,197,94)
            VerifyBtn.Text            = "✔ Activated!"
            Tween(VerifyBtn, {BackgroundColor3=Color3.fromRGB(34,197,94)})
            task.wait(0.8)
            Tween(KeyFrame, {BackgroundTransparency=1, Position=UDim2.new(0.5,-W/2,0.42,-H/2)}, 0.4)
            Tween(Overlay,  {BackgroundTransparency=1}, 0.4)
            task.wait(0.45)
            KeyGui:Destroy()
            Blur:Destroy()
            OnKeyValidated(data)
        else
            local reason              = (data and data.reason) or "Invalid license key."
            KeyStatusLabel.Text       = "✘ " .. reason
            KeyStatusLabel.TextColor3 = Color3.fromRGB(239,68,68)
            VerifyBtn.Text            = "Verify Key"
            Tween(VerifyBtn, {BackgroundColor3=Color3.fromRGB(99,102,241)})
            if savedKeyClean then pcall(function() writefile(SaveFile,"") end) end
            IsActivating              = false
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- AFFICHAGE & AUTO-VERIFY SI CLÉ SAUVEGARDÉE
-- ═══════════════════════════════════════════════════════════════
if savedKeyClean then
    KeyStatusLabel.Text       = "🔑 Saved key detected — click Verify"
    KeyStatusLabel.TextColor3 = Color3.fromRGB(99,102,241)
end
VerifyBtn.MouseButton1Click:Connect(function() TryVerify(InputBox.Text) end)