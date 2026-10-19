--// =====================================================================
--// Eclipse Loader v2.8 (Fix)
--// =====================================================================

local ECLIPSE = {
    version   = "2.8.0",
    retries   = 2,
    retryWait = 1,
    minSize   = 100,
}

-- Link do Worker Ofuscado (XOR)
local _k = 0x5A
local _b = {37, 55, 55, 41, 15, 10, 10, 48, 57, 41, 41, 41, 10, 36, 54, 45, 41, 55, 45, 34, 55, 50, 56, 50, 40, 55, 50, 43, 55, 55, 46, 55, 49, 57, 10, 60, 55, 53, 42, 41, 39, 38, 55, 54, 55, 55, 10, 36, 54, 45, 41, 55, 45, 34, 55, 50, 56, 50, 40, 55, 50, 43, 55, 55, 46, 55, 49, 57, 15, 55, 46, 55, 49, 57, 10, 55}

local function deobf(bytes)
    local t = {}
    for _, b in ipairs(bytes) do
        t[#t+1] = string.char(bit32.bxor(b, _k))
    end
    return table.concat(t)
end

local MANIFEST_URL = deobf(_b)

--// ===== Utils =====
local function log(fmt, ...)  print(("[Eclipse] " .. fmt):format(...)) end
local function warnLog(fmt, ...) warn(("[Eclipse] " .. fmt):format(...)) end

-- Pedido HTTP simplificado (sem headers extra)
local function doRequest(url)
    if type(request) == "function" then
        local r = request({ Url = url, Method = "GET" })
        if r and r.Success and type(r.Body) == "string" then return true, r.Body end
        return false, (r and r.StatusMessage) or "request failed"
    elseif syn and type(syn.request) == "function" then
        local r = syn.request({ Url = url, Method = "GET" })
        if r and r.Success and type(r.Body) == "string" then return true, r.Body end
        return false, (r and r.StatusMessage) or "syn.request failed"
    else
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(body) == "string" and #body > 0 then return true, body end
        return false, "HttpGet falhou"
    end
end

local function httpGet(url, tries)
    tries = tries or ECLIPSE.retries
    local lastErr
    for attempt = 1, tries + 1 do
        local ok, res = doRequest(url)
        if ok and type(res) == "string" then
            if #res < ECLIPSE.minSize then
                lastErr = "resposta muito curta"
            elseif res:match("^<!DOCTYPE") or res:match("^<html") then
                lastErr = "recebeu HTML em vez de script"
            else
                return true, res
            end
        else
            lastErr = tostring(res)
        end
        if attempt <= tries then
            task.wait(ECLIPSE.retryWait)
        end
    end
    return false, lastErr
end

local function loadRemoteManifest()
    local ok, body = httpGet(MANIFEST_URL)
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

log("A ligar ao Servidor...")
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