--!strict
-- [[ Eclipse Hub — Secure API + HWID System ]]

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

-- Token: EclipseLoader2024!
local LOADER_TOKEN = _d("RWNsaXBzZUxvYWRlcjIwMjQh")

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

-- Usamos o UserId do Roblox para evitar falhas de HWID entre execuções
local hwid = "USER_" .. tostring(player.UserId)

-- URL do teu Worker da Cloudflare
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
-- 2. CARREGAR SCRIPTS VIA CLOUDFLARE (COM TOKEN)
-- ==========================================
local SCRIPT_LIST_URL = "https://eclipse-proxy.andrepequeno31.workers.dev/api/manifest?token=" .. LOADER_TOKEN
local rawJson = getData(SCRIPT_LIST_URL)

if not rawJson then
    notify("Eclipse ERRO", "Falha ao carregar a lista de scripts.")
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
        -- O link já vem com o token incluído do Cloudflare
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