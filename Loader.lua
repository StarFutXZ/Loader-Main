--!strict
-- [[ Eclipse Hub — Secure API + HWID System + Auto Execute ]]

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
-- 6. SISTEMA DE AUTO EXECUTE (COM DROPDOWN)
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

-- Criar as opções encurtadas para o Dropdown
local AutoExecOptions = { "None" }
local optionMap = {} -- Guarda o link real correspondente ao texto encurtado

for _, gameName in ipairs(Games) do
    local scriptsForGame = GameScripts[gameName]
    if scriptsForGame and #scriptsForGame > 0 then
        for _, scriptInfo in ipairs(scriptsForGame) do
            -- Se o nome do jogo for maior que 10 letras, corta e mete ".."
            local shortGame = #gameName > 10 and string.sub(gameName, 1, 8) .. ".." or gameName
            local displayStr = scriptInfo.name .. " (" .. shortGame .. ")"
            
            table.insert(AutoExecOptions, displayStr)
            optionMap[displayStr] = { game = gameName, script = scriptInfo.name, url = scriptInfo.url }
        end
    end
end

-- Descobrir qual é o texto correspondente ao que está guardado
local currentDisplay = "None"
if autoExecData.script ~= "None" then
    for displayStr, data in pairs(optionMap) do
        if data.game == autoExecData.game and data.script == autoExecData.script then
            currentDisplay = displayStr
            break
        end
    end
end

-- Aba de Settings
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
            local data = optionMap[option]
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

-- Abas dos Jogos
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
-- 7. EXECUÇÃO DO AUTO EXECUTE AO ABRIR
-- ==========================================
if autoExecData.enabled and autoExecData.script ~= "None" and autoExecData.url ~= "None" then
    task.spawn(function()
        task.wait(3) -- Espera 3 segundos para o jogo carregar
        local ok, err = executeScript(autoExecData.script, autoExecData.url)
        if ok then
            notify("Eclipse", "Auto Executado: " .. autoExecData.script)
            log("AUTO-EXEC OK: " .. autoExecData.script)
        else
            log("AUTO-EXEC ERRO: " .. tostring(err))
        end
    end)
end