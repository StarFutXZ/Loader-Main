--// =====================================================================
--// Eclipse Loader v4.0 (Sistema de HWID e Conta)
--// =====================================================================

local ECLIPSE = { retries = 2, minSize = 100 }

--// ===== Link do Worker Escondido =====
local _codes = {104, 116, 116, 112, 115, 58, 47, 47, 101, 99, 108, 105, 112, 115, 101, 45, 112, 114, 111, 120, 121, 46, 97, 110, 100, 114, 101, 112, 101, 113, 117, 101, 110, 111, 51, 49, 46, 119, 111, 114, 107, 101, 114, 115, 46, 100, 101, 118}
local _chars = {}
for _, num in ipairs(_codes) do table.insert(_chars, string.char(num)) end
local BASE_URL = table.concat(_chars)

--// ===== Utils =====
local function log(fmt, ...)  print(("[Eclipse] " .. fmt):format(...)) end
local function warnLog(fmt, ...) warn(("[Eclipse] " .. fmt):format(...)) end

--// ===== GERADOR DE HWID (ID do Dispositivo) =====
local function getHWID()
    local hwid = ""
    -- Tenta apanhar o HWID verdadeiro do executor
    if gethwid then hwid = gethwid()
    elseif syn and syn.get_hwid then hwid = syn.get_hwid()
    elseif getgenv and getgenv().HWID then hwid = getgenv().HWID
    end
    
    -- Se o executor não der, cria um falso baseado no UserId (para não bloquear o user no PC)
    if hwid == "" or not hwid then
        hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEVICE"
    end
    return hwid
end

--// ===== SISTEMA DE KEY =====
local function checkKey()
    local userKey = getgenv().Key
    if not userKey or userKey == "" then
        warnLog("ERRO: Nenhuma Key detetada!")
        warnLog("Define a tua key: getgenv().Key = \"Eclipse-XXXX-XXXX-XXXX\"")
        return false
    end

    local hwid = getHWID()
    local robloxId = tostring(game.Players.LocalPlayer.UserId)

    log("A validar a Key no servidor...")

    -- Envia a Key, o HWID e a conta para o Cloudflare
    local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. robloxId
    local ok, res = pcall(function() return game:HttpGet(url, true) end)

    if not ok then
        warnLog("Erro de ligação ao servidor.")
        return false
    end

    local decodeOk, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)

    if decodeOk and data.valid == true then
        log("Key Validada! " .. tostring(data.message))
        return true
    else
        local motivo = (decodeOk and data.error) or "Erro desconhecido"
        warnLog("Acesso Negado: " .. motivo)
        return false
    end
end

--// ===== DOWNLOAD DO MANIFEST E SCRIPT =====
local function doRequest(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(res) == "string" and #res > 0 then return true, res end
    return false, "HttpGet falhou"
end

local function httpGet(url, tries)
    tries = tries or ECLIPSE.retries
    local lastErr
    for attempt = 1, tries + 1 do
        local ok, res = doRequest(url)
        if ok and type(res) == "string" then
            if #res < ECLIPSE.minSize then lastErr = "curta"
            elseif res:match("^<!DOCTYPE") or res:match("^<html") then lastErr = "HTML"
            else return true, res end
        else lastErr = tostring(res) end
        if attempt <= tries then task.wait(1) end
    end
    return false, lastErr
end

local function loadRemoteManifest()
    local ok, body = httpGet(BASE_URL)
    if not ok then
        warnLog("Erro no download do manifest: %s", tostring(body))
        return nil
    end

    local decodeOk, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(body)
    end)

    if not decodeOk or type(data) ~= "table" then
        warnLog("Erro ao converter JSON.")
        return nil
    end

    local converted, count = {}, 0
    for gameIdStr, entry in pairs(data) do
        local gameIdNum = tonumber(gameIdStr)
        if gameIdNum and type(entry) == "table" and type(entry.urls) == "table" then
            converted[gameIdNum] = entry
            count = count + 1
        end
    end

    log("Manifest carregado (%d jogos).", count)
    return converted
end

--// ===== Início =====
if type(loadstring) ~= "function" then
    warnLog("Executor sem loadstring!")
    return
end

-- 1. Verifica a Key primeiro!
if not checkKey() then
    return -- Para o script se a key for inválida ou estiver noutro dispositivo
end

-- 2. Se a key for válida, continua o carregamento normal
log("A ligar ao Servidor de Jogos...")
local SCRIPTS = loadRemoteManifest()
if not SCRIPTS then
    warnLog("Falha ao carregar a lista de jogos.")
    return
end

local gameId = game.GameId
local entry  = SCRIPTS[gameId]

if not entry then
    warnLog("Jogo nao suportado. GameId: %s", tostring(gameId))
    return
end

log("Jogo detetado: %s", entry.name)

local source, lastErr
for i, url in ipairs(entry.urls) do
    log("A baixar: %s", url)
    local ok, s = httpGet(url)
    if ok then
        source = s
        break
    else
        lastErr = s
    end
end

if not source then
    warnLog("Erro no download do script: %s", tostring(lastErr))
    return
end

log("A executar...")
local compileOk, chunkOrErr = pcall(loadstring, source, "=Eclipse:" .. tostring(gameId))
if not compileOk or type(chunkOrErr) ~= "function" then
    warnLog("Erro ao compilar: %s", tostring(chunkOrErr))
    return
end

local runOk, runErr = pcall(chunkOrErr)
if not runOk then
    warnLog("Erro ao executar: %s", tostring(runErr))
    return false
end

log("Sucesso!")
return true