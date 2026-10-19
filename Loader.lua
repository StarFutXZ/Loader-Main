--// =====================================================================
--// Eclipse Loader v2.4
--// Detecta o jogo atual (via GameId universal) e executa o script.
--// Usa APENAS o manifest remoto (sem lista de reserva embutida).
--// =====================================================================

local ECLIPSE = {
    version   = "2.4.0",
    retries   = 2,
    retryWait = 1,
    minSize   = 100,
    userAgent = "Eclipse-Loader/2.4",
    hashes    = {}, -- [url] = "sha256" (opcional, anti-tamper)
}

local MANIFEST_URL = "https://raw.githubusercontent.com/StarFutXZ/Loader-Main/refs/heads/main/manifest.json"

--// ===== Utils =====
local function log(fmt, ...)  print(("[Eclipse] " .. fmt):format(...)) end
local function warnLog(fmt, ...) warn(("[Eclipse] " .. fmt):format(...)) end

-- Detecta a melhor função HTTP disponível
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

-- Retry + validação de tamanho + detecção de HTML/404
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

-- Carrega o manifest remoto; converte chaves string -> number
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

--// ===== Carregar manifest (obrigatório) =====
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

--// ===== Download (mirrors + hash opcional) =====
local source, lastErr
for i, url in ipairs(entry.urls) do
    log("Baixando (%d/%d): %s", i, #entry.urls, url)
    local ok, s = httpGet(url)
    if ok then
        local expected = ECLIPSE.hashes[url]
        if expected then
            local h = syn and syn.crypt and syn.crypt.hash and syn.crypt.hash(s, "sha256")
            if h and h:lower() ~= expected:lower() then
                lastErr = "hash mismatch"
                warnLog("Hash inválido para %s", url)
            else
                source = s
                break
            end
        else
            source = s
            break
        end
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

--// ===== Compilação (chunk nomeado) =====
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