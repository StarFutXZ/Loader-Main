--!strict
-- [[ WindUI Game Loader — Secure API + HWID System ]]

local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

local function notify(title, text)
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 }) end)
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

-- Função robusta para obter o HWID do dispositivo (com fallback para contas)
local function getDeviceHWID()
    local hwid = nil

    -- 1. Tenta a função global padrão (Wave, AWP, etc)
    if gethwid then
        local ok, result = pcall(gethwid)
        if ok and type(result) == "string" and #result > 0 then hwid = result end
    end

    -- 2. Tenta Synapse X
    if not hwid and syn and syn.get_hwid then
        local ok, result = pcall(syn.get_hwid)
        if ok and type(result) == "string" and #result > 0 then hwid = result end
    end

    -- 3. Tenta Krnl
    if not hwid and krnl_gethwid then
        local ok, result = pcall(krnl_gethwid)
        if ok and type(result) == "string" and #result > 0 then hwid = result end
    end

    -- 4. Fallback final: usa o UserId do jogador
    if not hwid then
        hwid = "USER_" .. tostring(player.UserId)
    end

    return hwid
end

local hwid = getDeviceHWID()

-- URL do teu Worker da Cloudflare
local API_URL = "https://eclipse-proxy.andrepequeno31.workers.dev/api/validate?key=" .. HttpService:UrlEncode(userKey) .. "&hwid=" .. HttpService:UrlEncode(hwid)

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
-- 2. WINDUI LOADER
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then return warn("[larp-loader] WindUI falhou.") end

local GameScripts: {[string]: {{name: string, url: string}}} = {
    ["99 Nights in the Forest"] = {
        { name = "Cookie Hub", url = "https://raw.githubusercontent.com/StarFutXZ/Loader-Main/refs/heads/main/Script/99%20Nights%20in%20the%20Forest/Cookie%20Hub" },
        { name = "Voidware", url = "https://raw.githubusercontent.com/StarFutXZ/Loader-Main/refs/heads/main/Script/99%20Nights%20in%20the%20Forest/Voidware" }
    }
}

local Games = {
    "Doors", "99 Nights in the Forest", "Blade Ball", "Blox Strike",
    "Dead Rails", "Murder Mystery 2", "Steal An Egg", "Rivals", "Sniper Arena"
}

table.sort(Games, function(a, b)
    local aNum = tonumber(a:sub(1, 1))
    local bNum = tonumber(b:sub(1, 1))
    if aNum and not bNum then return false end
    if not aNum and bNum then return true end
    return a:lower() < b:lower()
end)

local Window = WindUI:CreateWindow({
    Title = "larp :: Game Loader",
    Icon = "layers",
    Author = "@ronzy.exe",
    Folder = "larpGameLoader",
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
-- 3. SISTEMA DE EXECUÇÃO DE SCRIPTS
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
-- 4. INTERFACE E LOGS
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

LogTab:Paragraph({ Title = "Log", Desc = "Join our discord: https://discord.gg/76tHHGBrfz\nMade by @ronzy.exe on discord" })