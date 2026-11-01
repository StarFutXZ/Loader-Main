--!strict
-- [[ WindUI Game Loader — Key System Integrated ]]

local HttpService = game:GetService("HttpService")

local function notify(title, text)
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 }) end)
end

-- ==========================================
-- 1. SISTEMA DE KEY (Do Loader Antigo)
-- ==========================================
local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    notify("Eclipse", "ERRO: Nenhuma Key! (getgenv().Key)")
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")

local _c1 = {104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 83, 116, 97, 114, 70, 117, 116, 88, 90, 47, 76, 111, 97, 100, 101, 114, 45, 77, 97, 105, 110, 47, 114, 101, 102, 115, 47, 104, 101, 97, 100, 115, 47, 109, 97, 105, 110, 47, 115, 101, 99, 117, 114, 101, 95, 107, 101, 121, 115, 46, 106, 115, 111, 110}

local function decodeLink(bytes)
    local t = {}
    for _, b in ipairs(bytes) do t[#t+1] = string.char(b) end
    return table.concat(t)
end

local URL_KEYS = decodeLink(_c1)

local function getSHA256(str)
    local band = bit32.band
    local bxor = bit32.bxor
    local rrotate = bit32.rrotate
    local rshift = bit32.rshift
    local lshift = bit32.lshift

    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    }
    local H = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19}
    
    local msg = {str:byte(1, -1)}
    local bitLen = #msg * 8
    table.insert(msg, 0x80)
    while (#msg % 64) ~= 56 do table.insert(msg, 0) end
    for i = 8, 1, -1 do table.insert(msg, band(rshift(bitLen, (i-1)*8), 0xFF)) end

    for chunkStart = 1, #msg, 64 do
        local w = {}
        for i = 1, 16 do w[i] = lshift(msg[chunkStart + (i-1)*4], 24) + lshift(msg[chunkStart + (i-1)*4 + 1], 16) + lshift(msg[chunkStart + (i-1)*4 + 2], 8) + msg[chunkStart + (i-1)*4 + 3] end
        for i = 17, 64 do
            local s0 = bxor(rrotate(w[i-15], 7), rrotate(w[i-15], 18), rshift(w[i-15], 3))
            local s1 = bxor(rrotate(w[i-2], 17), rrotate(w[i-2], 19), rshift(w[i-2], 10))
            w[i] = band(w[i-16] + s0 + w[i-7] + s1, 0xFFFFFFFF)
        end
        
        local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
        
        for i = 1, 64 do
            local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
            local ch = bxor(band(e, f), band(bit32.bnot(e), g))
            local temp1 = band(h + S1 + ch + K[i] + w[i], 0xFFFFFFFF)
            local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
            local maj = bxor(band(a, b), band(a, c), band(b, c))
            local temp2 = band(S0 + maj, 0xFFFFFFFF)
            
            h = g; g = f; f = e; e = band(d + temp1, 0xFFFFFFFF)
            d = c; c = b; b = a; a = band(temp1 + temp2, 0xFFFFFFFF)
        end
        
        H[1] = band(H[1] + a, 0xFFFFFFFF); H[2] = band(H[2] + b, 0xFFFFFFFF)
        H[3] = band(H[3] + c, 0xFFFFFFFF); H[4] = band(H[4] + d, 0xFFFFFFFF)
        H[5] = band(H[5] + e, 0xFFFFFFFF); H[6] = band(H[6] + f, 0xFFFFFFFF)
        H[7] = band(H[7] + g, 0xFFFFFFFF); H[8] = band(H[8] + h, 0xFFFFFFFF)
    end

    local hash = ""
    for i = 1, 8 do hash = hash .. string.format("%08x", H[i]) end
    return hash
end

local keyHash = getSHA256(userKey)

local function getData(url)
    if request then 
        local ok, res = pcall(request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res then return res end
    return nil
end

local res = getData(URL_KEYS)
if not res then
    notify("Eclipse ERRO", "Erro ao ligar ao servidor.")
    return
end

local data = HttpService:JSONDecode(res)
local isValid = false

if data and data.hashes then
    for _, h in ipairs(data.hashes) do
        if h == keyHash then
            isValid = true
            break
        end
    end
end

if not isValid then
    notify("Eclipse ERRO", "Key Invalida.")
    return
end

notify("Eclipse", "Key OK! A carregar...")

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
        Name = game.Players.LocalPlayer.DisplayName,
        Icon = "rbxthumb://type=AvatarHeadShot&id=" .. game.Players.LocalPlayer.UserId .. "&w=150&h=150",
        Callback = function() print("Perfil clicado, https://discord.gg/76tHHGBrfz") end
    }
})

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

local LogTab = Window:Tab({ Title = "Logs", Icon = "scroll-text" })
local LogBox = LogTab:Paragraph({ Title = "Status", Desc = "Loader inicializado. Key Validada." })

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