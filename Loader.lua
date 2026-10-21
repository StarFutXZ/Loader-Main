--// ===== Eclipse Loader v9.0 (Oficial) =====

local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "ERRO: Nenhuma Key detetada!", Duration = 5 })
    return
end

-- Limpa a key de espaços ou aspas
userKey = string.gsub(userKey, "[%s\"']", "")

local BASE_URL = "https://eclipse-proxy.andrepequeno31.workers.dev"
local PROXY_URL = "https://api.allorigins.win/raw?url="

local hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEV"
local robloxId = tostring(game.Players.LocalPlayer.UserId)

-- 1. Avisa que vai começar
game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "A validar a Key...", Duration = 5 })

-- 2. Função que faz os pedidos (usa o request do Delta ou o do Roblox)
local function getData(url)
    if request then
        local res = request({Url = url, Method = "GET"})
        if res and res.Body then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res then return res end
    return nil
end

-- 3. Valida a Key no Cloudflare
local authUrl = PROXY_URL .. BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId
local respostaAuth = getData(authUrl)

if not respostaAuth then
    game.StarterGui:SetCore("SendNotification", { Title = "Eclipse ERRO", Text = "Falha de rede ao ligar ao Servidor.", Duration = 5 })
    return
end

local dadosAuth = game:GetService("HttpService"):JSONDecode(respostaAuth)

if dadosAuth.valid == true then
    game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "Key OK! A carregar Jogo...", Duration = 5 })
    
    -- 4. Pede o Manifest (O teu JSON com os jogos) AO CLOUDFLARE
    local respostaManifest = getData(PROXY_URL .. BASE_URL)
    
    if not respostaManifest then
        game.StarterGui:SetCore("SendNotification", { Title = "Eclipse ERRO", Text = "Falha ao baixar o Manifest.", Duration = 5 })
        return
    end

    local dadosManifest = game:GetService("HttpService"):JSONDecode(respostaManifest)
    
    -- 5. Procura o ID do jogo atual
    local entry = dadosManifest[tostring(game.GameId)]
    
    if not entry then
        game.StarterGui:SetCore("SendNotification", { Title = "Eclipse ERRO", Text = "Jogo nao suportado.", Duration = 5 })
        return
    end
    
    game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "A transferir Script...", Duration = 5 })
    
    -- 6. Baixa o script do jogo
    local source = getData(PROXY_URL .. entry.urls[1])
    
    if source then
        local chunk, err = loadstring(source)
        if chunk then
            pcall(chunk)
            game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "Menu carregado!", Duration = 5 })
        else
            game.StarterGui:SetCore("SendNotification", { Title = "Eclipse ERRO", Text = "Erro no script.", Duration = 5 })
        end
    else
        game.StarterGui:SetCore("SendNotification", { Title = "Eclipse ERRO", Text = "Erro no download.", Duration = 5 })
    end
else
    local motivo = dadosAuth.error or "Invalida"
    game.StarterGui:SetCore("SendNotification", { Title = "Eclipse ERRO", Text = "Acesso Negado: " .. motivo, Duration = 5 })
end