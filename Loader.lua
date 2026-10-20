--// ===== Eclipse Loader v8.0 =====

-- 1. Pega a Key que o utilizador definiu
local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    game.StarterGui:SetCore("SendNotification", {
        Title = "Eclipse",
        Text = "ERRO: Nenhuma Key detetada!",
        Duration = 5
    })
    return
end

-- Limpa a key (remove espaços ou aspas acidentais)
userKey = string.gsub(userKey, "[%s\"']", "")

-- 2. Configurações do teu Servidor
local BASE_URL = "https://eclipse-proxy.andrepequeno31.workers.dev"
local PROXY_URL = "https://api.allorigins.win/raw?url=" -- Usamos o proxy para o Delta não bloquear

-- 3. Recolher dados do dispositivo e conta
local hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEV"
local robloxId = tostring(game.Players.LocalPlayer.UserId)
local authUrl = PROXY_URL .. BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId

-- Notificação inicial
game.StarterGui:SetCore("SendNotification", {
    Title = "Eclipse",
    Text = "A validar a Key...",
    Duration = 5
})

-- 4. Função para fazer o pedido (usa o request do Delta se existir, senão usa o do Roblox)
local function getData(url)
    if request then
        local res = request({Url = url, Method = "GET"})
        if res and res.Body then return res.Body end
    end
    return game:HttpGet(url, true)
end

-- 5. Valida a Key no Cloudflare
local respostaAuth = getData(authUrl)

if not respostaAuth then
    game.StarterGui:SetCore("SendNotification", {Title = "Eclipse ERRO", Text = "Falha na rede.", Duration = 5})
    return
end

local dadosAuth = game:GetService("HttpService"):JSONDecode(respostaAuth)

if dadosAuth.valid == true then
    -- Key válida!
    game.StarterGui:SetCore("SendNotification", {Title = "Eclipse", Text = "Key Validada! A carregar...", Duration = 5})
    
    -- 6. Pede a lista de jogos (Manifest)
    local respostaManifest = getData(PROXY_URL .. BASE_URL)
    local dadosManifest = game:GetService("HttpService"):JSONDecode(respostaManifest)
    
    local entry = dadosManifest[tostring(game.GameId)]
    
    if not entry then
        game.StarterGui:SetCore("SendNotification", {Title = "Eclipse ERRO", Text = "Jogo nao suportado.", Duration = 5})
        return
    end
    
    -- 7. Baixa o script do jogo específico
    game.StarterGui:SetCore("SendNotification", {Title = "Eclipse", Text = "A transferir Script...", Duration = 5})
    local source = getData(PROXY_URL .. entry.urls[1])
    
    if source then
        local chunk, err = loadstring(source)
        if chunk then
            pcall(chunk)
            game.StarterGui:SetCore("SendNotification", {Title = "Eclipse", Text = "Menu carregado!", Duration = 5})
        else
            game.StarterGui:SetCore("SendNotification", {Title = "Eclipse ERRO", Text = "Erro no script.", Duration = 5})
        end
    else
        game.StarterGui:SetCore("SendNotification", {Title = "Eclipse ERRO", Text = "Erro no download.", Duration = 5})
    end
else
    -- Key inválida ou expirada
    local motivo = dadosAuth.error or "Invalida"
    game.StarterGui:SetCore("SendNotification", {Title = "Eclipse ERRO", Text = "Acesso Negado: " .. motivo, Duration = 5})
end