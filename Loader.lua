--// =====================================================================
--// Eclipse Loader v2.7
--// Detecta o jogo atual e executa o script.
--// Usa o proxy da Cloudflare (ofuscado) e NÃO usa whitelist.
--// =====================================================================

local ECLIPSE = {
    version   = "2.7.0",
    retries   = 2,
    retryWait = 1,
    minSize   = 100,
    userAgent = "Eclipse-Loader/2.7",
}

--// ===== Link do Worker Ofuscado (XOR 0x5A) =====
-- O link real (eclipse-proxy.andrepequeno31.workers.dev) está escondido aqui.
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

-- (A função isAllowedUrl e getHost foram removidas)

local function doRequest(url)
    local opts = {
        Url = url,
        Method = "GET",
        HttpHeaders = { ["User-Agent"] = ECLIPSE.userAgent },
    }
    if type(request) == "function" then
        local r = request(opts)
        if r and r.Success and type(r.Body) == "string" then return true, r.Body end
        return false, (r and r.StatusMessage) or "request failed"
    elseif syn and type(syn.request) == "function" then
        local r = syn.request(opts)
        if r and r.Success and type(r.Body) == "string" then return true, r.Body end
        return false, (r and r.StatusMessage) or "syn.request failed"
    else
        return pcall(function() return game:HttpGet(url, true) end)
    end
end

local function httpGet(url, tries)
    tries = tries or ECLIPSE.retries
    local lastErr
    for attempt = 1, tries + 1 do
        local ok, res = doRequest(url)
        if ok and type(res) == "string" then
            if #res < ECLIPSE.minSize then
                lastErr = ("resposta suspeita (%d bytes)"):format(#res)
            elseif res:match("^<!DOCTYPE") or res:match("^<html") then
                lastErr = "recebeu HTML em vez de script"
            elseif res:match("^404:") or res:match("^Not Found") then
                lastErr = "404 (not found)"
            else
                return true, res
            end
        else
            lastErr = res or "empty response"
        end
        if attempt <= tries then
            log("Falha HTTP (tentativa %d/%d): %s — retry em %ds",
                attempt, tries + 1, tostring(lastErr), ECLIPSE.retryWait * attempt)
            task.wait(ECLIPSE.retryWait * attempt)
        end
    end
    return false, lastErr
end

local function loadRemoteManifest()
    local ok, body = httpGet(MANIFEST_URL)
    if not ok then
        warnLog("Não foi possível baixar o manifest: %s", tostring(body))
        return nil
    end

    local decodeOk, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(body)
    end)

    if not decodeOk or type(data) ~= "table" then
        warnLog("Manifest inválido (JSON malformado).")
        return nil
    end

    local converted, count = {}, 0
    for gameIdStr, entry in pairs(data) do
        local gameIdNum = tonumber(gameIdStr)
        if gameIdNum and type(entry) == "table" and type(entry.urls) == "table" and #entry.urls > 0 then
            converted[gameIdNum] = entry
            count = count + 1
        end
    end

    if count == 0 then
        warnLog("Manifest vazio ou sem jogos válidos.")
        return nil
    end

    log("Manifest carregado (%d jogos).", count)
    return converted
end

--// ===== Pré-checagens =====
if type(loadstring) ~= "function" then
    warnLog("Executor sem loadstring; abortando.")
    return
end

--// ===== Carregar manifest =====
local SCRIPTS = loadRemoteManifest()
if not SCRIPTS then
    warnLog("Manifest indisponível. Não é possível continuar.")
    return
end

--// ===== Seleção do script =====
local gameId = game.GameId
local entry  = SCRIPTS[gameId]

if not entry then
    warnLog("Jogo não suportado. GameId=%s PlaceId=%s Name=%q",
        tostring(gameId), tostring(game.PlaceId), game.Name)
    return
end

log("Jogo detectado: %s (GameId=%d, PlaceId=%d)",
    entry.name, gameId, game.PlaceId)

--// ===== Download (sem whitelist) =====
local source, lastErr
for i, url in ipairs(entry.urls) do
    log("Baixando (%d/%d): %s", i, #entry.urls, url)
    local ok, s = httpGet(url)
    if ok then
        source = s
        break
    else
        lastErr = s
        warnLog("Falha mirror %d: %s", i, tostring(s))
    end
end

if not source then
    warnLog("Todos os downloads falharam. Último erro: %s", tostring(lastErr))
    return
end

log("Download concluído (%d bytes).", #source)

--// ===== Compilação =====
local compileOk, chunkOrErr = pcall(loadstring, source, "=Eclipse:" .. tostring(gameId))
if not compileOk or type(chunkOrErr) ~= "function" then
    warnLog("Falha ao compilar: %s", tostring(chunkOrErr))
    return
end

--// ===== Execução =====
log("Executando %s...", entry.name)
local runOk, runErr = pcall(chunkOrErr)
if not runOk then
    local tb = (debug and debug.traceback) and debug.traceback(tostring(runErr), 2) or tostring(runErr)
    warnLog("Erro em runtime:\n%s", tb)
    return false
end

log("Script executado com sucesso.")
return true