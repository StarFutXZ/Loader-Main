--// ===== Eclipse Loader v4.2 =====
local _codes = {104, 116, 116, 112, 115, 58, 47, 47, 101, 99, 108, 105, 112, 115, 101, 45, 112, 114, 111, 120, 121, 46, 97, 110, 100, 114, 101, 112, 101, 113, 117, 101, 110, 111, 51, 49, 46, 119, 111, 114, 107, 101, 114, 115, 46, 100, 101, 118}
local _chars = {}
for _, num in ipairs(_codes) do table.insert(_chars, string.char(num)) end
local BASE_URL = table.concat(_chars)

local function showMsg(msg, isError)
    local screen = Instance.new("ScreenGui")
    screen.Parent = game:GetService("CoreGui")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0.3, 0)
    label.Position = UDim2.new(0.1, 0, 0.35, 0)
    label.BackgroundColor3 = isError and Color3.new(0.5, 0, 0) or Color3.new(0, 0.5, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 20
    label.TextWrapped = true
    label.Text = "[Eclipse] " .. tostring(msg)
    label.Parent = screen
    task.delay(8, function() screen:Destroy() end)
end

-- Tenta ler do getgenv() ou do _G (caso o executor limpe o getgenv)
local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    return showMsg("ERRO: Nenhuma Key detetada! Coloca getgenv().Key = \"A_TUA_KEY\"", true)
end

-- Limpa a key (remove espaços e aspas acidentais)
userKey = string.gsub(userKey, "[%s\"']", "")

local function getHWID()
    if gethwid then return gethwid() end
    if syn and syn.get_hwid then return syn.get_hwid() end
    return tostring(game.Players.LocalPlayer.UserId) .. "-DEVICE"
end

local hwid = getHWID()
local robloxId = tostring(game.Players.LocalPlayer.UserId)

showMsg("A validar a Key...", false)

local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId
local ok, res = pcall(function() return game:HttpGet(url, true) end)

if not ok then
    return showMsg("Erro de rede ao ligar ao servidor.", true)
end

local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

if decodeOk and data.valid == true then
    showMsg("Key Validada! A carregar...", false)
    
    local s_ok, s_body = pcall(function() return game:HttpGet(BASE_URL, true) end)
    if not s_ok then return showMsg("Erro ao baixar a lista de jogos.", true) end
    
    local data2 = game:GetService("HttpService"):JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then return showMsg("Jogo não suportado pelo Eclipse.", true) end
    
    local scriptUrl = entry.urls[1]
    local src_ok, source = pcall(function() return game:HttpGet(scriptUrl, true) end)
    if not src_ok then return showMsg("Erro ao baixar o script do jogo.", true) end
    
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
        showMsg("Script executado com sucesso!", false)
    else
        showMsg("Erro no script: " .. tostring(err), true)
    end
else
    local motivo = (decodeOk and data.error) or "Erro desconhecido"
    showMsg("Acesso Negado: " .. motivo, true)
end