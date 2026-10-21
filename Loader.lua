--// ===== Eclipse Loader v15.0 (Final Fix) =====
local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "ERRO: Nenhuma Key!", Duration = 5 }) end)
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")

local function notify(title, text)
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 }) end)
end

notify("Eclipse", "A validar Key...")

-- Usa o AllOrigins
local authUrl = "https://api.allorigins.win/raw?url=https://eclipse-proxy.andrepequeno31.workers.dev/api/authorize?key=" .. userKey .. "&hwid=DEV&user=" .. tostring(game.Players.LocalPlayer.UserId)

local function getData(url)
    if request then 
        local ok, res = pcall(request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res then return res end
    return nil
end

local res = getData(authUrl)

if not res then
    notify("Eclipse ERRO", "Proxy bloqueado.")
    return
end

-- Limpa a resposta (remove lixo do proxy antes do JSON)
local limpo = string.match(res, "{.*}")

if not limpo then
    notify("Eclipse ERRO", "Resposta invalida.")
    return
end

local data = game:GetService("HttpService"):JSONDecode(limpo)

if data and data.valid == true then
    notify("Eclipse", "Key OK! A carregar...")
    
    local manifestUrl = "https://raw.githubusercontent.com/StarFutXZ/Loader-Main/refs/heads/main/manifest.json"
    local manifestRes = getData(manifestUrl)
    
    if not manifestRes then
        notify("Eclipse ERRO", "Erro ao ler o GitHub.")
        return
    end
    
    local manifest = game:GetService("HttpService"):JSONDecode(manifestRes)
    local entry = manifest[tostring(game.GameId)]
    
    if not entry then
        notify("Eclipse ERRO", "Jogo nao suportado.")
        return
    end
    
    notify("Eclipse", "A transferir " .. entry.name)
    
    local source = getData(entry.urls[1])
    
    if source then
        local chunk, err = loadstring(source)
        if chunk then
            pcall(chunk)
            notify("Eclipse", "Menu carregado!")
        end
    end
else
    local motivo = (data and data.error) or "Desconhecido"
    notify("Eclipse ERRO", "Negado: " .. motivo)
end