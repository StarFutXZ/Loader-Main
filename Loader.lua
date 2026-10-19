--// ===== Eclipse Loader v5.2 (Sem GUI) =====
local BASE_URL = "https://eclipse-proxy.andrepequeno31.workers.dev"

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
    
    local ok, res = pcall(function()
        return game:GetService("HttpService"):RequestAsync({Url = url, Method = "GET"})
    end)
    if ok and res and res.Success then return true, res.Body end
    return false, "Bloqueado"
end

local userKey = getgenv().Key or _G.Key
if not userKey then
    warn("[Eclipse] ERRO: Falta a Key!")
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")
local hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEV"
local robloxId = tostring(game.Players.LocalPlayer.UserId)
local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId

local ok, res = safeRequest(url)

if not ok then
    warn("[Eclipse] Falha de rede no teu executor.")
    return
end

local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

if decodeOk and data.valid == true then
    local s_ok, s_body = safeRequest(BASE_URL)
    if not s_ok then return warn("[Eclipse] Erro Manifest.") end
    
    local data2 = game:GetService("HttpService"):JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then return warn("[Eclipse] Jogo não suportado.") end
    
    local src_ok, source = safeRequest(entry.urls[1])
    if not src_ok then return warn("[Eclipse] Erro no Script.") end
    
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
    else
        warn("[Eclipse] Erro de sintaxe: " .. tostring(err))
    end
else
    warn("[Eclipse] Acesso Negado: " .. tostring(data.error))
end