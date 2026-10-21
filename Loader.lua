--// ===== Eclipse Loader v14.0 (FINAL OFICIAL) =====
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

-- 1. Valida a Key no Cloudflare via CorsProxy
local authUrl = "https://corsproxy.io/?https://eclipse-proxy.andrepequeno31.workers.dev/api/authorize?key=" .. userKey .. "&hwid=DEV&user=" .. tostring(game.Players.LocalPlayer.UserId)

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
local data = res and game:GetService("HttpService"):JSONDecode(res)

if data and data.valid == true then
    notify("Eclipse", "Key OK! A carregar...")
    
    -- 2. Lê o manifest DIRETAMENTE do GitHub
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
    
    -- 3. Baixa o script do GitHub
    local source = getData(entry.urls[1])
    
    if source then
        local chunk, err = loadstring(source)
        if chunk then
            pcall(chunk)
            notify("Eclipse", "Menu carregado!")
        end
    end
else
    notify("Eclipse ERRO", "Key Invalida.")
end