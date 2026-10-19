--// ===== Eclipse Loader v4.6 (HttpService Nativo) =====
local _codes = {104, 116, 116, 112, 115, 58, 47, 47, 101, 99, 108, 105, 112, 115, 101, 45, 112, 114, 111, 120, 121, 46, 97, 110, 100, 114, 101, 112, 101, 113, 117, 101, 110, 111, 51, 49, 46, 119, 111, 114, 107, 101, 114, 115, 46, 100, 101, 118}
local _chars = {}
for _, num in ipairs(_codes) do table.insert(_chars, string.char(num)) end
local BASE_URL = table.concat(_chars)

local gui = Instance.new("ScreenGui")
gui.Name = "EclipseStatus"
local success, _ = pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not success then gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 250, 0, 35)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.Text = " Eclipse: A iniciar..."
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = gui
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

local function updateStatus(text, isError)
    statusLabel.Text = " Eclipse: " .. text
    statusLabel.BackgroundColor3 = isError and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(30, 150, 30)
end

-- Usa o HttpService nativo em vez do game:HttpGet que congela
local function safeHttpGet(url)
    local HttpService = game:GetService("HttpService")
    local ok, res = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "GET"
        })
    end)
    if ok and res and res.Success then
        return true, res.Body
    end
    return false, "Erro HTTP"
end

local userKey = getgenv().Key or _G.Key
if not userKey or userKey == "" then
    updateStatus("Key em falta!", true)
    task.wait(3) gui:Destroy() return
end

userKey = string.gsub(userKey, "[%s\"']", "")
updateStatus("A validar Key...", false)
task.wait(0.5)

local function getHWID()
    if gethwid then return gethwid() end
    if syn and syn.get_hwid then return syn.get_hwid() end
    return tostring(game.Players.LocalPlayer.UserId) .. "-DEVICE"
end

local hwid = getHWID()
local robloxId = tostring(game.Players.LocalPlayer.UserId)
local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId

local ok, res = safeHttpGet(url)

if not ok then
    updateStatus("Falha de rede!", true)
    task.wait(4) gui:Destroy() return
end

local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

if decodeOk and data.valid == true then
    updateStatus("A carregar Jogo...", false)
    task.wait(0.5)
    
    local s_ok, s_body = safeHttpGet(BASE_URL)
    if not s_ok then updateStatus("Erro no Manifest.", true) task.wait(3) gui:Destroy() return end
    
    local data2 = game:GetService("HttpService"):JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then updateStatus("Jogo não suportado.", true) task.wait(3) gui:Destroy() return end
    
    updateStatus("A transferir Script...", false)
    task.wait(0.5)
    
    local src_ok, source = safeHttpGet(entry.urls[1])
    if not src_ok then updateStatus("Erro no Script.", true) task.wait(3) gui:Destroy() return end
    
    updateStatus("A Executar...", false)
    task.wait(0.5)
    
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
        updateStatus("Sucesso!", false)
        task.wait(2) gui:Destroy()
    else
        updateStatus("Erro de sintaxe.", true)
        task.wait(3) gui:Destroy()
    end
else
    updateStatus("Acesso Negado!", true)
    task.wait(3) gui:Destroy()
end