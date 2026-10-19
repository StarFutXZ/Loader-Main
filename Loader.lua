--// ===== Eclipse Loader v5.1 (Mobile FIX) =====
local BASE_URL = "https://eclipse-proxy.andrepequeno31.workers.dev" -- Link direto para testarmos

local gui = Instance.new("ScreenGui")
gui.Name = "EclipseStatus"
gui.Parent = game:GetService("CoreGui")

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 350, 0, 60)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextWrapped = true
statusLabel.Text = " Eclipse: A iniciar..."
statusLabel.Parent = gui

local function updateStatus(text, isError)
    statusLabel.Text = " Eclipse: " .. text
    statusLabel.BackgroundColor3 = isError and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(30, 150, 30)
end

-- Função de rede usando o executor (evita bloqueios do Roblox)
local function safeRequest(url)
    local http
    if syn and syn.request then http = syn.request
    elseif request then http = request
    elseif http_request then http = http_request
    end
    
    if http then
        local ok, res = pcall(function()
            return http({Url = url, Method = "GET"})
        end)
        if ok and res and res.Body then return true, res.Body end
    end
    -- Se não tiver, tenta o do Roblox
    local ok, res = pcall(function()
        return game:GetService("HttpService"):RequestAsync({Url = url, Method = "GET"})
    end)
    if ok and res and res.Success then return true, res.Body end
    return false, "Bloqueado"
end

local userKey = getgenv().Key or _G.Key
if not userKey then
    updateStatus("Key em falta!", true)
    task.wait(3) gui:Destroy() return
end

userKey = string.gsub(userKey, "[%s\"']", "")
local hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEV"
local robloxId = tostring(game.Players.LocalPlayer.UserId)
local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId

updateStatus("A validar Key...", false)

local ok, res = safeRequest(url)

if not ok then
    updateStatus("Falha de rede no executor.", true)
    task.wait(4) gui:Destroy() return
end

local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

if decodeOk and data.valid == true then
    updateStatus("Key OK! A carregar...", false)
    task.wait(0.5)
    
    local s_ok, s_body = safeRequest(BASE_URL)
    if not s_ok then updateStatus("Erro Manifest.", true) task.wait(4) gui:Destroy() return end
    
    local data2 = game:GetService("HttpService"):JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then updateStatus("Jogo não suportado.", true) task.wait(4) gui:Destroy() return end
    
    updateStatus("A transferir Script...", false)
    local src_ok, source = safeRequest(entry.urls[1])
    if not src_ok then updateStatus("Erro Script.", true) task.wait(4) gui:Destroy() return end
    
    updateStatus("A Executar...", false)
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
        updateStatus("Carregado!", false)
        task.wait(2) gui:Destroy()
    else
        updateStatus("Erro sintaxe.", true)
        task.wait(4) gui:Destroy()
    end
else
    updateStatus("Acesso Negado!", true)
    task.wait(4) gui:Destroy()
end