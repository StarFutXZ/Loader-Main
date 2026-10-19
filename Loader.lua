--// =====================================================================
--// Eclipse Loader v2.1
--// Autor: StarFutXZ (correções aplicadas)
--// Detecta o jogo atual e executa o script correspondente.
--// =====================================================================

local ECLIPSE = {
    version    = "2.1.0",
    retries    = 2,
    retryWait  = 1,          -- segundos entre tentativas
    minSize    = 100,        -- FIX: tamanho mínimo pra considerar resposta válida
    userAgent  = "Eclipse-Loader/2.1", -- FIX: agora realmente usado (se request existir)
    -- hashes opcionais: [url] = "sha256" (FIX: anti-tamper, preencha se quiser)
    hashes     = {},
}

--// ===== Mapeamento =====
-- FIX: tabela com metadados (nome + mirrors opcionais)
local SCRIPTS = {
    [9534705677] = {
        name = "Sniper Arena",
        urls = { "https://raw.githubusercontent.com/StarFutXZ/Eclipse/refs/heads/main/Sniper_Arena.lua" },
    },
    [6035872082] = {
        name = "Rivals",
        urls = { "https://raw.githubusercontent.com/StarFutXZ/Eclipse/refs/heads/main/Rivals.lua" },
    },
    [10563114921] = {
        name = "Steal An Egg",
        urls = { "https://raw.githubusercontent.com/tienkhanh1/Chilli-Hub-Script/refs/heads/main/StealAnEgg" },
    },
    [66654135] = {
        name = "Murder Mystery 2",
        urls = { "https://raw.githubusercontent.com/StarFutXZ/Eclipse/refs/heads/main/Murder%20Mystery%202.lua" },
    },
    [7018190066] = {
        name = "Dead Rails",
        urls = { "https://darahub.pages.dev/api/script/Darahub-DeadRail/Lobby.lua" }, -- FIX: URL pura
    },
    [1686885941] = {
        name = "99 Nights in the Forest",
        urls = { "https://raw.githubusercontent.com/StarFutXZ/Eclipse/refs/heads/main/99%20Nights%20in%20the%20Forest.lua" },
    },
}

-- FIX: fallback por PlaceId (para jogos com sub-places)
local PLACES = {
    -- [1234567890] = 9534705677, -- exemplo: place -> gameId
}

--// ===== Utils =====
local function log(fmt, ...)  print(("[Eclipse] " .. fmt):format(...)) end
local function warnLog(fmt, ...) warn(("[Eclipse] " .. fmt):format(...)) end

-- FIX: detecta qual função HTTP usar (request > syn.request > game:HttpGet)
local function doRequest(url)
    local opts = {
        Url = url,
        Method = "GET",
        HttpHeaders = { ["User-Agent"] = ECLIPSE.userAgent },
    }
    if typeof and typeof(request) == "function" then
        local r = request(opts)
        if r and r.Success and type(r.Body) == "string" then
            return true, r.Body
        end
        return false, r and r.StatusMessage or "request failed"
    elseif syn and syn.request then
        local r = syn.request(opts)
        if r and r.Success and type(r.Body) == "string" then
            return true, r.Body
        end
        return false, r and r.StatusMessage or "syn.request failed"
    else
        -- fallback universal (sem headers, sem timeout real)
        return pcall(function() return game:HttpGet(url, true) end)
    end
end

-- FIX: retry + validação de tamanho + detecção de HTML de erro
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
                attempt, tries + 1, tostring(lastErr), ECLIPSE.retryWait)
            task.wait(ECLIPSE.retryWait * attempt) -- FIX: backoff linear
        end
    end
    return false, lastErr
end

-- FIX: checagem de loadstring (voltou)
if type(loadstring) ~= "function" then
    warnLog("Executor sem loadstring; abortando.")
    return
end

--// ===== Seleção do script =====
local gameId  = game.GameId
local placeId = game.PlaceId
local entry   = SCRIPTS[gameId]

-- FIX: fallback por PlaceId se GameId não mapeado
if not entry and PLACES[placeId] then
    entry = SCRIPTS[PLACES[placeId]]
    if entry then
        log("GameId não mapeado, usando fallback por PlaceId=%d", placeId)
    end
end

if not entry then
    warnLog("Jogo não suportado. GameId=%s PlaceId=%s Name=%q",
        tostring(gameId), tostring(placeId), game.Name)
    return
end

log("Jogo detectado: %s (GameId=%d, PlaceId=%d)", entry.name, gameId, placeId)

--// ===== Download com mirrors =====
local source, lastErr
for i, url in ipairs(entry.urls) do
    log("Baixando (%d/%d): %s", i, #entry.urls, url)
    local ok, s = httpGet(url)
    if ok then
        -- FIX: validação de hash opcional
        local expected = ECLIPSE.hashes[url]
        if expected then
            local h = (syn and syn.crypt and syn.crypt.hash) and syn.crypt.hash(s, "sha256")
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

--// ===== Compilação =====
-- FIX: nomear o chunk para erros mais legíveis
local compileOk, chunkOrErr = pcall(loadstring, source, "=Eclipse:" .. tostring(gameId))
if not compileOk or type(chunkOrErr) ~= "function" then
    warnLog("Falha ao compilar: %s", tostring(chunkOrErr))
    return
end

--// ===== Execução =====
log("Executando %s...", entry.name)
local runOk, runErr = pcall(chunkOrErr)
if not runOk then
    -- FIX: stack trace completo quando disponível
    local tb = (debug and debug.traceback) and debug.traceback(tostring(runErr), 2) or tostring(runErr)
    warnLog("Erro em runtime:\n%s", tb)
    return false
else
    log("Script executado com sucesso.")
    return true
end
