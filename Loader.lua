--!strict
-- [[ Eclipse Hub — Advanced Secure Loader ]]

local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

-- BLOQUEIO DE STUDIO (Se tentarem abrir no Roblox Studio para ver o código, bloqueia)
if game:GetService("RunService"):IsStudio() then
    return warn("[Eclipse] Execução bloqueada no Roblox Studio por questões de segurança.")
end

local function notify(title, text)
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 }) end)
end

-- ==========================================
-- OFUSCAÇÃO AVANÇADA (XOR CIPHER)
-- ==========================================
local K = 97 -- Chave secreta de encriptação

local function _d(enc)
    local t = {}
    for _, b in ipairs(enc) do
        table.insert(t, string.char(bit32.bxor(b, K)))
    end
    return table.concat(t)
end

-- Links encriptados com XOR (Chave 97)
-- WindUI
local _uWindUI = _d({9, 21, 21, 16, 26, 58, 47, 47, 6, 24, 21, 23, 20, 19, 46, 14, 16, 28, 47, 5, 16, 16, 21, 0, 6, 12, 26, 20, 26, 47, 1, 21, 18, 21, 0, 26, 26, 26, 47, 29, 0, 21, 26, 24, 21, 46, 47, 29, 16, 30, 18, 29, 16, 0, 29, 47, 14, 0, 18, 18, 46, 29, 20, 0})
-- API Cloudflare
local _uApiBase = _d({9, 21, 21, 16, 26, 58, 47, 47, 4, 2, 11, 18, 16, 26, 4, 52, 16, 0, 16, 25, 30, 4, 18, 21, 4, 0, 4, 2, 16, 25, 16, 20, 16, 21, 21, 2, 4, 52, 47, 38, 16, 0, 23, 4, 0, 26, 46, 29, 4, 25, 47, 2, 0, 18, 47, 25, 0, 16, 33, 2, 21, 4})
-- Manifest.json
local _uManifest = _d({9, 21, 21, 16, 26, 58, 47, 47, 0, 0, 38, 46, 6, 24, 21, 23, 20, 19, 30, 26, 4, 0, 2, 16, 21, 21, 4, 21, 21, 46, 2, 16, 22, 47, 26, 4, 16, 0, 26, 47, 21, 4, 2, 29, 26, 47, 22, 2, 18, 21, 47, 38, 4, 21, 0, 40, 16, 21, 28, 52, 16, 0, 16, 25, 30, 47, 22, 4, 21, 20, 26, 46, 20, 16, 21, 22, 26, 28, 21, 46, 58, 26, 18, 21})

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

local hwid = "USER_" .. tostring(player.UserId)
local API_URL = _uApiBase .. "?key=" .. HttpService:UrlEncode(userKey) .. "&hwid=" .. HttpService:UrlEncode(hwid) .. "&_t=" .. tostring(tick())

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
-- 2. CARREGAR SCRIPTS
-- ==========================================
local rawJson = getData(_uManifest)
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
-- 3. WINDUI
-- ==========================================
local WindUI = loadstring(game:HttpGet(_uWindUI))()
if not WindUI then return warn("[Eclipse Hub] WindUI falhou.") end

local Games = {}
for gameName, _ in pairs(GameScripts) do table.insert(Games, gameName) end

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
        Callback = function() print("Perfil clicado") end
    }
})

-- ==========================================
-- 4. SISTEMA DE EXECUÇÃO
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