--// ===== Eclipse Loader v16.0 (Roblox Nativo) =====
local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "ERRO: Nenhuma Key!", Duration = 5 })
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")

local function notify(title, text)
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 }) end)
end

notify("Eclipse", "A validar Key...")

-- Usa o HttpService nativo do Roblox (impossível o Delta bloquear a 100%)
local function makeRequest(url)
    local HttpService = game:GetService("HttpService")
    local ok, res = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "GET"
        })
    end)
    if ok and res and res.Success then
        return res.Body
    end
    return nil
end

-- Link do Cloudflare (direto)
local authUrl = "https://eclipse-proxy.andrepequeno31.workers.dev/api/authorize?key=" .. userKey .. "&hwid=DEV&user=" .. tostring(game.Players.LocalPlayer.UserId)

local res = makeRequest(authUrl)

if not res then
    notify("Eclipse ERRO", "O Delta bloqueou o HttpService.")
    return
end

local data = game:GetService("HttpService"):JSONDecode(res)

if data and data.valid == true then
    notify("Eclipse", "Key OK! A carregar...")
    
    -- Lê o manifest do GitHub
    local manifestRes = makeRequest("https://raw.githubusercontent.com/StarFutXZ/Loader-Main/refs/heads/main/manifest.json")
    
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
    
    local source = makeRequest(entry.urls[1])
    
    if source then
        local chunk, err = loadstring(source)
        if chunk then
            pcall(chunk)
            notify("Eclipse", "Menu carregado!")
        else
            notify("Eclipse ERRO", "Erro no script.")
        end
    end
else
    notify("Eclipse ERRO", "Key Invalida.")
end