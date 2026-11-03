--!strict
-- [[ Eclipse Hub — Secure API + HWID System + Auto Execute + Favorites ]]

local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

local function notify(title, text)
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 }) end)
end

-- ==========================================
-- OFUSCAÇÃO DO TOKEN (BASE64)
-- ==========================================
local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function _d(data)
    data = string.gsub(data, '[^' .. B64 .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (B64:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local LOADER_TOKEN = _d("RWNsaXBzZUxvYWRlcjIwMjQ=")

-- ==========================================
-- SISTEMA DE HWID DO DISPOSITIVO
-- ==========================================
local function getDeviceHWID()
    local hwid = nil
    if gethwid then
        local ok, result = pcall(gethwid)
        if ok and type(result) == "string" and #result > 0 then hwid = result end
    end
    if not hwid and syn and syn.get_hwid then
        local ok, result = pcall(syn.get_hwid)
        if ok and type(result) == "string" and #result > 0 then hwid = result end
    end
    if not hwid and krnl_gethwid then
        local ok, result = pcall(krnl_gethwid)
        if ok and type(result) == "string" and #result > 0 then hwid = result end
    end
    if not hwid then
        hwid = "USER_" .. tostring(player.UserId)
    end
    return hwid
end

-- ==========================================
-- 1. SISTEMA DE SEGURANÇA (KEY + HWID)
-- ==========================================
local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    notify("Eclipse", "ERRO: Nenhuma Key! (getgenv().Key)")
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")
notify("Eclipse", "A validar Key e Dispositivo...")

local hwid = getDeviceHWID()
local API_URL = "https://eclipse-proxy.andrepequeno31.workers.dev/api/validate?key=" .. HttpService:UrlEncode(userKey) .. "&hwid=" .. HttpService:UrlEncode(hwid) .. "&_t=" .. tostring(tick())

local function getData(url)
    if request then 
        local ok, res = pcall(request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res then return res end
    return nil
end

local res = getData(API_URL)
if not res then
    notify("Eclipse ERRO", "Erro ao ligar ao servidor.")
    return
end

local success, data = pcall(function() return HttpService:JSONDecode(res) end)

if not success or not data or not data.valid then
    local erro = (data and data.error) or "Key Inválida ou bloqueada."
    notify("Eclipse ERRO", erro)
    return
end

notify("Eclipse", "Acesso Autorizado! A carregar...")

-- ==========================================
-- 2. CARREGAR SCRIPTS VIA CLOUDFLARE
-- ==========================================
local SCRIPT_LIST_URL = "https://eclipse-proxy.andrepequeno31.workers.dev/api/manifest?token=" .. LOADER_TOKEN
local rawJson = getData(SCRIPT_LIST_URL)

if not rawJson then
    notify("Eclipse ERRO", "Falha ao carregar a lista de scripts.")
    return
end

if string.find(rawJson, "ACESSO NEGADO") then
    notify("Eclipse ERRO", "Token inválido. Verifica o Cloudflare.")
    return
end

local parseSuccess, GameScripts = pcall(function() return HttpService:JSONDecode(rawJson) end)
if not parseSuccess or type(GameScripts) ~= "table" then
    notify("Eclipse ERRO", "Erro no formato da lista de scripts.")
    return
end

-- ==========================================
-- 3. WINDUI LOADER
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then return warn("[Eclipse Hub] WindUI falhou.") end

local Games = {}
for gameName, _ in pairs(GameScripts) do
    table.insert(Games, gameName)
end

table.sort(Games, function(a, b)
    local aNum = tonumber(a:sub(1, 1))
    local bNum = tonumber(b:sub(1, 1))
    if aNum and not bNum then return false end
    if not aNum and bNum then return true end
    return a:lower() < b:lower()
end)

local Window = WindUI:CreateWindow({
    Title = "Eclipse Hub",
    Icon = "moon",
    Author = "@By_Andryx",
    Folder = "EclipseHub",
    Size = UDim2.fromOffset(680, 500),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    HasOutline = true,
    User = {
        Enabled = true,
        Name = player.DisplayName,
        Icon = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150",
        Callback = function() print("Perfil clicado, https://discord.gg/76tHHGBrfz") end
    }
})

-- ==========================================
-- 4. SISTEMA DE EXECUÇÃO DE SCRIPTS
-- ==========================================
local LoadedScripts: {[string]: thread} = {}
local FetchedCache: {[string]: string} = {}

local function executeScript(scriptName: string, url: string): (boolean, string?)
    if LoadedScripts[scriptName] then return false, "Já rodando" end
    local cleanUrl = string.gsub(url, "%s+$", "")
    
    if not FetchedCache[scriptName] then
        local ok, result = pcall(function() return game:HttpGet(cleanUrl, true) end)
        if not ok or type(result) ~= "string" or #result < 8 then
            return false, "Falha no download"
        end
        FetchedCache[scriptName] = result
    end
    
    local chunk, compileErr = loadstring(FetchedCache[scriptName], "=" .. scriptName)
    if not chunk then return false, "Compile: " .. tostring(compileErr) end
    
    local co = coroutine.create(chunk)
    local ok, runErr = coroutine.resume(co)
    if not ok then return false, "Runtime: " .. tostring(runErr) end
    
    LoadedScripts[scriptName] = co
    return true, nil
end

-- ==========================================
-- 5. INTERFACE E LOGS
-- ==========================================
local LogTab = Window:Tab({ Title = "Logs", Icon = "scroll-text" })
local LogBox = LogTab:Paragraph({ Title = "Status", Desc = "Loader inicializado. Key e HWID Validados." })

local logLines: {string} = {}
local function log(msg: string)
    local stamp = os.date("%H:%M:%S")
    table.insert(logLines, 1, ("[%s] %s"):format(stamp, msg))
    while #logLines > 60 do table.remove(logLines) end
    LogBox:SetDesc(table.concat(logLines, "\n"))
end

-- ==========================================
-- 6. SISTEMA DE AUTO EXECUTE
-- ==========================================
local AutoExecFile = "EclipseHub_AutoExec.json"
local autoExecData = { enabled = false, game = "None", script = "None", url = "None" }

if isfile and isfile(AutoExecFile) then
    local ok, content = pcall(readfile, AutoExecFile)
    if ok and content then
        local parsedOk, parsedData = pcall(function() return HttpService:JSONDecode(content) end)
        if parsedOk and type(parsedData) == "table" then
            autoExecData = parsedData
        end
    end
end

local function saveAutoExec()
    if writefile then
        pcall(function()
            writefile(AutoExecFile, HttpService:JSONEncode(autoExecData))
        end)
    end
end

local AutoExecOptions = { "None" }
local autoExecMap = {}

for _, gameName in ipairs(Games) do
    local scriptsForGame = GameScripts[gameName]
    if scriptsForGame and #scriptsForGame > 0 then
        for _, scriptInfo in ipairs(scriptsForGame) do
            local shortGame = #gameName > 10 and string.sub(gameName, 1, 8) .. ".." or gameName
            local displayStr = scriptInfo.name .. " (" .. shortGame .. ")"
            table.insert(AutoExecOptions, displayStr)
            autoExecMap[displayStr] = { game = gameName, script = scriptInfo.name, url = scriptInfo.url }
        end
    end
end

local currentDisplay = "None"
if autoExecData.script ~= "None" then
    for displayStr, data in pairs(autoExecMap) do
        if data.game == autoExecData.game and data.script == autoExecData.script then
            currentDisplay = displayStr
            break
        end
    end
end

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
SettingsTab:Paragraph({ Title = "Auto Execute", Desc = "Escolhe um script para ser executado automaticamente assim que o jogo abrir." })

SettingsTab:Dropdown({
    Title = "Selecionar Script",
    Desc = "O script será injetado automaticamente quando entrares no jogo.",
    Values = AutoExecOptions,
    Value = currentDisplay,
    Callback = function(option)
        if option == "None" then
            autoExecData.enabled = false
            autoExecData.game = "None"
            autoExecData.script = "None"
            autoExecData.url = "None"
        else
            local data = autoExecMap[option]
            if data then
                autoExecData.enabled = true
                autoExecData.game = data.game
                autoExecData.script = data.script
                autoExecData.url = data.url
            end
        end
        saveAutoExec()
    end
})

-- ==========================================
-- 7. SISTEMA DE FAVORITOS (MENU LIMPO CORRIGIDO)
-- ==========================================
local FavsFile = "EclipseHub_Favs.json"
local favoritesData = {}

if isfile and isfile(FavsFile) then
    local ok, content = pcall(readfile, FavsFile)
    if ok and content then
        local parsedOk, parsedData = pcall(function() return HttpService:JSONDecode(content) end)
        if parsedOk and type(parsedData) == "table" then
            favoritesData = parsedData
        end
    end
end

local function saveFavorites()
    if writefile then
        pcall(function()
            writefile(FavsFile, HttpService:JSONEncode(favoritesData))
        end)
    end
end

local function getFavKey(game, script)
    return game .. "|" .. script
end

local FavTab = Window:Tab({ Title = "Favoritos", Icon = "star" })
FavTab:Paragraph({ Title = "Gerenciar Favoritos", Desc = "Selecione um script no menu abaixo para adicionar ou remover dos favoritos." })

local allScriptsOptions = { "None" }
local scriptDataMap = {}

for _, gameName in ipairs(Games) do
    local scriptsForGame = GameScripts[gameName]
    if scriptsForGame and #scriptsForGame > 0 then
        for _, scriptInfo in ipairs(scriptsForGame) do
            local displayStr = scriptInfo.name .. " (" .. gameName .. ")"
            table.insert(allScriptsOptions, displayStr)
            scriptDataMap[displayStr] = { game = gameName, name = scriptInfo.name, url = scriptInfo.url }
        end
    end
end

local favSection = nil

local function refreshFavoritesUI()
    -- Destruir a secção anterior inteira para evitar duplicados e bugs visuais
    if favSection then
        pcall(function() favSection:Destroy() end)
    end
    
    favSection = FavTab:Section({ Title = "Meus Favoritos" })

    local count = 0
    for _, data in pairs(favoritesData) do
        count = count + 1
        favSection:Button({
            Title = data.name .. " (" .. data.game .. ")",
            Desc = "Clique para executar.",
            Callback = function()
                task.spawn(function()
                    local ok, err = executeScript(data.name, data.url)
                    log(ok and ("FAV OK: " .. data.name) or ("FAV ERRO: " .. tostring(err)))
                end)
            end,
        })
    end

    if count == 0 then
        favSection:Paragraph({ Title = "Vazio", Desc = "Você ainda não adicionou nenhum script aos favoritos." })
    end
end

FavTab:Dropdown({
    Title = "Adicionar / Remover",
    Desc = "Selecionar um script aqui irá alternar o status de favorito.",
    Values = allScriptsOptions,
    Value = "None",
    Callback = function(option)
        if option == "None" then return end
        local data = scriptDataMap[option]
        if not data then return end

        local fKey = getFavKey(data.game, data.name)
        if favoritesData[fKey] then
            favoritesData[fKey] = nil
            notify("Eclipse", "Removido dos Favoritos: " .. data.name)
        else
            favoritesData[fKey] = { game = data.game, name = data.name, url = data.url }
            notify("Eclipse", "Adicionado aos Favoritos: " .. data.name)
        end
        saveFavorites()
        refreshFavoritesUI() -- Atualiza a secção limpa
    end
})

refreshFavoritesUI()

-- ==========================================
-- 8. ABAS DOS JOGOS (LIMPO)
-- ==========================================
for _, gameName in ipairs(Games) do
    local Tab = Window:Tab({ Title = gameName, Icon = "gamepad-2" })
    Tab:Paragraph({ Title = gameName .. " :: Scripts", Desc = "Selecione um script abaixo para injetar no jogo." })
    
    local scriptsForGame = GameScripts[gameName]
    
    if scriptsForGame and #scriptsForGame > 0 then
        for _, scriptInfo in ipairs(scriptsForGame) do
            local btn = Tab:Button({
                Title = scriptInfo.name,
                Desc = "○ parado (Clique para executar)",
                Callback = function()
                    task.spawn(function()
                        local ok, err = executeScript(scriptInfo.name, scriptInfo.url)
                        log(ok and ("OK: " .. scriptInfo.name) or ("ERRO: " .. tostring(err)))
                        if btn then
                            btn:SetDesc(ok and "● rodando" or "○ erro de execução")
                        end
                    end)
                end,
            })
        end
    else
        Tab:Paragraph({ Title = "Nenhum script", Desc = "Os scripts para " .. gameName .. " serão injetados aqui." })
    end
end

LogTab:Paragraph({ Title = "Log", Desc = "Join our discord: https://discord.gg/76tHHGBrfz\nMade by @By_Andryx on discord" })

-- ==========================================
-- 9. EXECUÇÃO DO AUTO EXECUTE AO ABRIR
-- ==========================================
if getgenv().AutoExecute ~= nil then
    autoExecData.enabled = getgenv().AutoExecute
end

if autoExecData.enabled and autoExecData.script ~= "None" and autoExecData.url ~= "None" then
    task.spawn(function()
        task.wait(3)
        local ok, err = executeScript(autoExecData.script, autoExecData.url)
        if ok then
            notify("Eclipse", "Auto Executado: " .. autoExecData.script)
            log("AUTO-EXEC OK: " .. autoExecData.script)
        else
            log("AUTO-EXEC ERRO: " .. tostring(err))
        end
    end)
end