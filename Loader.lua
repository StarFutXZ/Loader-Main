--// ===== Eclipse Loader v6.0 (Bypass via GitHub) =====
local function notify(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

local BASE_URL = "https://eclipse-proxy.andrepequeno31.workers.dev"

-- Usamos o HttpGet para tentar ligar
local function safeRequest(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res then return true, res end
    
    -- Se o HttpGet falhar, tenta o HttpService
    ok, res = pcall(function()
        return game:GetService("HttpService"):RequestAsync({Url = url, Method = "GET"})
    end)
    if ok and res and res.Success then return true, res.Body end
    
    return false, "Falha"
end

local userKey = getgenv().Key or _G.Key
if not userKey then
    notify("Eclipse", "Erro: Key não encontrada!")
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")
local hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEV"
local robloxId = tostring(game.Players.LocalPlayer.UserId)
local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId

notify("Eclipse", "A validar a Key...")

local ok, res = safeRequest(url)

if not ok then
    notify("Eclipse", "Erro de rede!")
    return
end

local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

if decodeOk and data.valid == true then
    notify("Eclipse", "Key OK! A carregar...")
    
    local s_ok, s_body = safeRequest(BASE_URL)
    if not s_ok then notify("Eclipse", "Erro no Manifest") return end
    
    local data2 = game:GetService("HttpService"):JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then notify("Eclipse", "Jogo não suportado") return end
    
    local src_ok, source = safeRequest(entry.urls[1])
    if not src_ok then notify("Eclipse", "Erro no Script") return end
    
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
        notify("Eclipse", "Sucesso!")
    else
        notify("Eclipse", "Erro: " .. tostring(err))
    end
else
    notify("Eclipse", "Key Negada!")
end