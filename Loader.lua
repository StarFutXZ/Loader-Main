--// ===== Eclipse Loader v4.4 (GUI de Estado) =====
local _codes = {104, 116, 116, 112, 115, 58, 47, 47, 101, 99, 108, 105, 112, 115, 101, 45, 112, 114, 111, 120, 121, 46, 97, 110, 100, 114, 101, 112, 101, 113, 117, 101, 110, 111, 51, 49, 46, 119, 111, 114, 107, 101, 114, 115, 46, 100, 101, 118}
local _chars = {}
for _, num in ipairs(_codes) do table.insert(_chars, string.char(num)) end
local BASE_URL = table.concat(_chars)

-- Função que cria a GUI no canto
local gui = Instance.new("ScreenGui")
gui.Name = "EclipseStatus"
-- Tenta colocar na CoreGui, se falhar tenta no PlayerGui
local success, _ = pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not success then gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 250, 0, 35)
statusLabel.Position = UDim2.new(0, 10, 0, 50) -- Canto superior esquerdo
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.Text = " Eclipse: A iniciar..."
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = statusLabel

local function updateStatus(text, isError)
    statusLabel.Text = " Eclipse: " .. text
    if isError then
        statusLabel.BackgroundColor3 = Color3.fromRGB(150, 30, 30) -- Vermelho
    else
        statusLabel.BackgroundColor3 = Color3.fromRGB(30, 150, 30) -- Verde
    end
end

-- Tenta ler a chave
local userKey = getgenv().Key or _G.Key
if not userKey or userKey == "" then
    updateStatus("Key não encontrada!", true)
    task.wait(3)
    gui:Destroy()
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")
updateStatus("A validar Key...", false)

local function getHWID()
    if gethwid then return gethwid() end
    if syn and syn.get_hwid then return syn.get_hwid() end
    return tostring(game.Players.LocalPlayer.UserId) .. "-DEVICE"
end

local hwid = getHWID()
local robloxId = tostring(game.Players.LocalPlayer.UserId)
local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId

local ok, res = pcall(function() return game:HttpGet(url, true) end)
if not ok then
    updateStatus("Erro de rede!", true)
    task.wait(3)
    gui:Destroy()
    return
end

local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

if decodeOk and data.valid == true then
    updateStatus("Key Validada! A carregar...", false)
    
    local s_ok, s_body = pcall(function() return game:HttpGet(BASE_URL, true) end)
    if not s_ok then
        updateStatus("Erro no Manifest!", true)
        task.wait(3)
        gui:Destroy()
        return
    end
    
    local data2 = game:GetService("HttpService"):JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then
        updateStatus("Jogo não suportado.", true)
        task.wait(3)
        gui:Destroy()
        return
    end
    
    updateStatus("A transferir Script...", false)
    local scriptUrl = entry.urls[1]
    local src_ok, source = pcall(function() return game:HttpGet(scriptUrl, true) end)
    if not src_ok then
        updateStatus("Falha ao baixar Script.", true)
        task.wait(3)
        gui:Destroy()
        return
    end
    
    updateStatus("A Executar...", false)
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
        -- Se o script rodar com sucesso, podemos apagar a GUI ou deixar o aviso
        statusLabel.Text = " Eclipse: Carregado!"
        task.wait(3)
        gui:Destroy() -- Fecha a caixinha para não incomodar no jogo
    else
        updateStatus("Erro no Script!", true)
        task.wait(3)
        gui:Destroy()
    end
else
    local motivo = (decodeOk and data.error) or "Negado"
    updateStatus("Acesso Negado!", true)
    task.wait(3)
    gui:Destroy()
end