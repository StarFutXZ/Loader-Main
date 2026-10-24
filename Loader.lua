-- ==========================================
-- 2.5 RESOLVE PLACEID -> UNIVERSEID (corrigido)
-- ==========================================
local HttpService = game:GetService("HttpService")

local function placeToUniverse(placeId)
    local api = "https://apis.roblox.com/universes/v1/places/" .. tostring(placeId) .. "/universe"
    local body = getData(api)
    if not body or body == "" then return nil end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
    if ok and decoded and decoded.universeId then
        return tostring(decoded.universeId)
    end
    return nil
end

-- ==========================================
-- 4. CARREGA O JOGO (com debug)
-- ==========================================
if isValid then
    notify("Eclipse", "Key OK! A carregar...")
    
    local manifestRes = getData(URL_MANIFEST)
    
    if not manifestRes then
        notify("Eclipse ERRO", "Erro no Manifest.")
        return
    end

    local okM, manifest = pcall(function() return HttpService:JSONDecode(manifestRes) end)
    if not okM or type(manifest) ~= "table" then
        notify("Eclipse ERRO", "Manifest invalido.")
        return
    end

    local gameId = tostring(game.GameId)
    local placeId = tostring(game.PlaceId)
    local entry

    -- 1) universes por GameId
    if manifest.universes then
        entry = manifest.universes[gameId]
    end

    -- 2) places por PlaceId (Blade Ball e afins)
    if not entry and manifest.places then
        entry = manifest.places[placeId]
    end

    -- 3) resolve place -> universe e tenta de novo
    if not entry then
        local resolved = placeToUniverse(placeId)
        warn("[Eclipse] PlaceId:", placeId, "| GameId:", gameId, "| Resolved Universe:", resolved or "nil")
        if resolved and manifest.universes then
            entry = manifest.universes[resolved]
        end
    end
    
    if not entry then
        warn("[Eclipse] GameId:", gameId, "PlaceId:", placeId, "-> sem entrada no manifest")
        notify("Eclipse ERRO", "Jogo nao suportado.")
        return
    end
    
    notify("Eclipse", "A transferir " .. tostring(entry.name))
    local source = getData(entry.urls[1])
    
    if not source then
        notify("Eclipse ERRO", "Falha ao baixar script.")
        return
    end

    local chunk, loadErr = loadstring(source)
    if not chunk then
        warn("[Eclipse] loadstring falhou:", loadErr)
        notify("Eclipse ERRO", "Script invalido.")
        return
    end

    local okRun, runErr = pcall(chunk)
    if okRun then
        notify("Eclipse", "Menu carregado!")
    else
        warn("[Eclipse] exec falhou:", runErr)
        notify("Eclipse ERRO", "Erro ao executar.")
    end
else
    notify("Eclipse ERRO", "Key Invalida.")
end