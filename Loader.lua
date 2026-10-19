--// ===== Eclipse Loader v4.8 (Headers) =====
local _codes = {104, 116, 116, 112, 115, 58, 47, 47, 101, 99, 108, 105, 112, 115, 101, 45, 112, 114, 111, 120, 121, 46, 97, 110, 100, 114, 101, 112, 101, 113, 117, 101, 110, 111, 51, 49, 46, 119, 111, 114, 107, 101, 114, 115, 46, 100, 101, 118}
local _chars = {}
for _, num in ipairs(_codes) do table.insert(_chars, string.char(num)) end
local BASE_URL = table.concat(_chars)

local gui = Instance.new("ScreenGui")
gui.Name = "EclipseStatus"
gui.Parent = game:GetService("CoreGui")

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 250, 0, 35)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.Text = " Eclipse: A validar..."
statusLabel.Parent = gui
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

local function updateStatus(text, isError)
    statusLabel.Text = " Eclipse: " .. text
    statusLabel.BackgroundColor3 = isError and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(30, 150, 30)
end

-- Função super segura
local function sendRequest(url)
    local HttpService = game:GetService("HttpService")
    local headers = {["User-Agent"] = "Roblox/WinInet"}
    
    -- Tenta pelos executores (syn, request, etc)
    local http
    if syn and syn.request then http = syn.request
    elseif request then http = request
    elseif http_request then http = http_request
    end
    
    if http then
        local ok, res = pcall(function()
            return http({Url = url, Method = "GET", HttpHeaders = headers})
        end)
        if ok and res and res.Body then return true, res.Body end
    end
    
    -- Se o executor falhar, usa o do Roblox (RequestAsync)
    local ok, res = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "GET",
            HttpHeaders = headers
        })
    end)
    if ok and res and res.Success then return true, res.Body end
    
    -- Último recurso (HttpGet clássico)
    local ok2, res2 = pcall(function() return game:HttpGet(url, true) end)
    if ok2 and res2 then return true, res2 end
    
    return false, "Erro"
end

local userKey = getgenv().Key or _G.Key
if not userKey then
    updateStatus("Key em falta!", true)
    task.wait(2) gui:Destroy() return
end

userKey = string.gsub(userKey, "[%s\"']", "")
local hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEV"
local robloxId = tostring(game.Players.LocalPlayer.UserId)
local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId

updateStatus("A ligar ao Server...", false)
task.wait(1)

local ok, res = sendRequest(url)

if not ok then
    updateStatus("Falha na ligação!", true)
    task.wait(4) gui:Destroy() return
end

updateStatus("A processar resposta...", false)
task.wait(0.5)

local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

if decodeOk and data.valid == true then
    updateStatus("Key Validada!", false)
    task.wait(0.5)
    
    local s_ok, s_body = sendRequest(BASE_URL)
    if not s_ok then updateStatus("Erro no Manifest.", true) task.wait(3) gui:Destroy() return end
    
    local data2 = game:GetService("HttpService"):JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then updateStatus("Jogo não suportado.", true) task.wait(3) gui:Destroy() return end
    
    local src_ok, source = sendRequest(entry.urls[1])
    if not src_ok then updateStatus("Erro no Script.", true) task.wait(3) gui:Destroy() return end
    
    updateStatus("A Executar...", false)
    task.wait(0.5)
    
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
        updateStatus("Carregado com sucesso!", false)
        task.wait(2) gui:Destroy()
    else
        updateStatus("Erro de sintaxe.", true)
        task.wait(3) gui:Destroy()
    end
else
    updateStatus("Acesso Negado!", true)
    task.wait(3) gui:Destroy()
end