--// ===== Eclipse Loader v26.0 (Totalmente Ofuscado) =====
local userKey = getgenv().Key or _G.Key

if not userKey or userKey == "" then
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = "Eclipse", Text = "ERRO: Nenhuma Key!", Duration = 5 }) end)
    return
end

userKey = string.gsub(userKey, "[%s\"']", "")

local function notify(title, text)
    pcall(function() game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 }) end)
end

notify("Eclipse", "A verificar Key...")

-- ==========================================
-- 1. LINKS E MANIFEST ESCONDIDOS
-- ==========================================
-- Link do secure_keys.json (Escondido)
local _c1 = {104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 83, 116, 97, 114, 70, 117, 116, 88, 90, 47, 76, 111, 97, 100, 101, 114, 45, 77, 97, 105, 110, 47, 114, 101, 102, 115, 47, 104, 101, 97, 100, 115, 47, 109, 97, 105, 110, 47, 115, 101, 99, 117, 114, 101, 95, 107, 101, 121, 115, 46, 106, 115, 111, 110}

-- Manifest (Lista de jogos) escondido em números
local _c2 = {123, 10, 32, 32, 34, 57, 53, 51, 52, 55, 48, 53, 54, 55, 55, 34, 58, 32, 123, 10, 32, 32, 32, 32, 34, 110, 97, 109, 101, 34, 58, 32, 34, 83, 110, 105, 112, 101, 114, 32, 65, 114, 101, 110, 97, 34, 44, 10, 32, 32, 32, 32, 34, 117, 114, 108, 115, 34, 58, 32, 91, 34, 104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 83, 116, 97, 114, 70, 117, 116, 88, 90, 47, 69, 99, 108, 105, 112, 115, 101, 47, 114, 101, 102, 115, 47, 104, 101, 97, 100, 115, 47, 109, 97, 105, 110, 47, 83, 110, 105, 112, 101, 114, 95, 65, 114, 101, 110, 97, 46, 108, 117, 97, 34, 93, 10, 32, 32, 125, 44, 10, 32, 32, 34, 54, 48, 51, 53, 56, 55, 50, 48, 56, 50, 34, 58, 32, 123, 10, 32, 32, 32, 32, 34, 110, 97, 109, 101, 34, 58, 32, 34, 82, 105, 118, 97, 108, 115, 34, 44, 10, 32, 32, 32, 32, 34, 117, 114, 108, 115, 34, 58, 32, 91, 34, 104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 83, 116, 97, 114, 70, 117, 116, 88, 90, 47, 69, 99, 108, 105, 112, 115, 101, 47, 114, 101, 102, 115, 47, 104, 101, 97, 100, 115, 47, 109, 97, 105, 110, 47, 82, 105, 118, 97, 108, 115, 46, 108, 117, 97, 34, 93, 10, 32, 32, 125, 44, 10, 32, 32, 34, 49, 48, 53, 54, 51, 49, 49, 52, 57, 50, 49, 34, 58, 32, 123, 10, 32, 32, 32, 32, 34, 110, 97, 109, 101, 34, 58, 32, 34, 83, 116, 101, 97, 108, 32, 65, 110, 32, 69, 103, 103, 34, 44, 10, 32, 32, 32, 32, 34, 117, 114, 108, 115, 34, 58, 32, 91, 34, 104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 116, 105, 101, 110, 107, 104, 97, 110, 104, 49, 47, 67, 104, 105, 108, 108, 105, 45, 72, 117, 98, 45, 83, 99, 114, 105, 112, 116, 47, 114, 101, 102, 115, 47, 104, 101, 97, 100, 115, 47, 109, 97, 105, 110, 47, 83, 116, 101, 97, 108, 65, 110, 69, 103, 103, 34, 93, 10, 32, 32, 125, 44, 10, 32, 32, 34, 54, 54, 54, 53, 52, 49, 51, 53, 34, 58, 32, 123, 10, 32, 32, 32, 32, 34, 110, 97, 109, 101, 34, 58, 32, 34, 77, 117, 114, 100, 101, 114, 32, 77, 121, 115, 116, 101, 114, 121, 32, 50, 34, 44, 10, 32, 32, 32, 32, 34, 117, 114, 108, 115, 34, 58, 32, 91, 34, 104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 83, 116, 97, 114, 70, 117, 116, 88, 90, 47, 69, 99, 108, 105, 112, 115, 101, 47, 114, 101, 102, 115, 47, 104, 101, 97, 100, 115, 47, 109, 97, 105, 110, 47, 77, 117, 114, 100, 101, 114, 37, 50, 48, 77, 121, 115, 116, 101, 114, 121, 37, 50, 48, 50, 46, 108, 117, 97, 34, 93, 10, 32, 32, 125, 44, 10, 32, 32, 34, 55, 48, 49, 56, 49, 57, 48, 48, 54, 54, 34, 58, 32, 123, 10, 32, 32, 32, 32, 34, 110, 97, 109, 101, 34, 58, 32, 34, 68, 101, 97, 100, 32, 82, 97, 105, 108, 115, 34, 44, 10, 32, 32, 32, 32, 34, 117, 114, 108, 115, 34, 58, 32, 91, 34, 104, 116, 116, 112, 115, 58, 47, 47, 100, 97, 114, 97, 104, 117, 98, 46, 112, 97, 103, 101, 115, 46, 100, 101, 118, 47, 97, 112, 105, 47, 115, 99, 114, 105, 112, 116, 47, 68, 97, 114, 97, 104, 117, 98, 45, 68, 101, 97, 100, 82, 97, 105, 108, 47, 76, 111, 98, 98, 121, 46, 108, 117, 97, 34, 93, 10, 32, 32, 125, 44, 10, 32, 32, 34, 49, 54, 56, 54, 56, 56, 53, 57, 52, 49, 34, 58, 32, 123, 10, 32, 32, 32, 32, 34, 110, 97, 109, 101, 34, 58, 32, 34, 57, 57, 32, 78, 105, 103, 104, 116, 115, 32, 105, 110, 32, 116, 104, 101, 32, 70, 111, 114, 101, 115, 116, 34, 44, 10, 32, 32, 32, 32, 34, 117, 114, 108, 115, 34, 58, 32, 91, 34, 104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 83, 116, 97, 114, 70, 117, 116, 88, 90, 47, 69, 99, 108, 105, 112, 115, 101, 47, 114, 101, 102, 115, 47, 104, 101, 97, 100, 115, 47, 109, 97, 105, 110, 47, 57, 57, 37, 50, 48, 78, 105, 103, 104, 116, 115, 37, 50, 48, 105, 110, 37, 50, 48, 116, 104, 101, 37, 50, 48, 70, 111, 114, 101, 115, 116, 46, 108, 117, 97, 34, 93, 10, 32, 32, 125, 10, 125}

local function decodeLink(bytes)
    local t = {}
    for _, b in ipairs(bytes) do t[#t+1] = string.char(b) end
    return table.concat(t)
end

local URL_KEYS = decodeLink(_c1)
local MANIFEST_JSON = decodeLink(_c2)

-- ==========================================
-- 2. FUNÇÃO DE HASH SHA-256
-- ==========================================
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

-- ==========================================
-- 3. VALIDA A KEY
-- ==========================================
local res = getData(URL_KEYS)

if not res then
    notify("Eclipse ERRO", "Erro ao ligar ao servidor.")
    return
end

local data = game:GetService("HttpService"):JSONDecode(res)
local isValid = false

if data and data.hashes then
    for _, h in ipairs(data.hashes) do
        if h == keyHash then
            isValid = true
            break
        end
    end
end

-- ==========================================
-- 4. CARREGA O JOGO
-- ==========================================
if isValid then
    notify("Eclipse", "Key OK! A carregar...")
    
    -- Transforma os números de volta no JSON do Manifest
    local manifest = game:GetService("HttpService"):JSONDecode(MANIFEST_JSON)
    local entry = manifest[tostring(game.GameId)]
    
    if not entry then
        notify("Eclipse ERRO", "Jogo nao suportado.")
        return
    end
    
    notify("Eclipse", "A transferir " .. entry.name)
    local source = getData(entry.urls[1])
    
    if source then
        local chunk = loadstring(source)
        if chunk then
            pcall(chunk)
            notify("Eclipse", "Menu carregado!")
        end
    end
else
    notify("Eclipse ERRO", "Key Invalida.")
end