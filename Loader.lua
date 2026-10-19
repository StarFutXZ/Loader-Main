--// ===== Eclipse Loader v5.0 (Debug Total) =====
local _codes = {104, 116, 116, 112, 115, 58, 47, 47, 101, 99, 108, 105, 112, 115, 101, 45, 112, 114, 111, 120, 121, 46, 97, 110, 100, 114, 101, 112, 101, 113, 117, 101, 110, 111, 51, 49, 46, 119, 111, 114, 107, 101, 114, 115, 46, 100, 101, 118}
local _chars = {}
for _, num in ipairs(_codes) do table.insert(_chars, string.char(num)) end
local BASE_URL = table.concat(_chars)

local gui = Instance.new("ScreenGui")
gui.Name = "EclipseStatus"
gui.Parent = game:GetService("CoreGui")

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 350, 0, 60) -- Caixa maior para ler o erro
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextWrapped = true
statusLabel.Text = " Eclipse: A iniciar..."
statusLabel.Parent = gui
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

local function updateStatus(text, isError)
    statusLabel.Text = " Eclipse: " .. text
    statusLabel.BackgroundColor3 = isError and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(30, 150, 30)
end

local userKey = getgenv().Key or _G.Key
if not userKey or userKey == "" then
    updateStatus("Key em falta no getgenv!", true)
    task.wait(3) gui:Destroy() return
end

userKey = string.gsub(userKey, "[%s\"']", "")
local hwid = tostring(game.Players.LocalPlayer.UserId) .. "-DEV"
local url = BASE_URL .. "/api/authorize?key=" .. userKey .. "&hwid=" .. hwid .. "&user=" .. tostring(game.Players.LocalPlayer.UserId)

updateStatus("A testar ligação (HttpGet)...", false)
task.wait(0.5)

-- TESTE 1: game:HttpGet
local ok1, res1 = pcall(function() return game:HttpGet(url, true) end)
if not ok1 then
    updateStatus("Erro HttpGet: O executor bloqueou a ligação.", true)
    task.wait(5) gui:Destroy() return
end

-- TESTE 2: HttpService:RequestAsync
updateStatus("A testar ligação (RequestAsync)...", false)
task.wait(0.5)

local HttpService = game:GetService("HttpService")
local ok2, res2 = pcall(function()
    return HttpService:RequestAsync({ Url = url, Method = "GET" })
end)

if not ok2 or not res2.Success then
    updateStatus("Erro no HttpService. O Roblox bloqueou.", true)
    task.wait(5) gui:Destroy() return
end

-- Se chegou aqui, o HttpGet ou o RequestAsync funcionou. Vamos ver a resposta!
local finalRes = res2.Body -- Usa a resposta do RequestAsync

updateStatus("A verificar dados da Key...", false)
task.wait(0.5)

local decodeOk, data = pcall(function() return HttpService:JSONDecode(finalRes) end)

if not decodeOk then
    updateStatus("Erro no JSON: O Cloudflare devolveu HTML.", true)
    task.wait(5) gui:Destroy() return
end

if data.valid == true then
    updateStatus("Key Validada! A carregar...", false)
    task.wait(1)
    
    local s_ok, s_body = pcall(function() return game:HttpGet(BASE_URL, true) end)
    if not s_ok then updateStatus("Erro no Manifest.", true) task.wait(5) gui:Destroy() return end
    
    local data2 = HttpService:JSONDecode(s_body)
    local entry = data2[tostring(game.GameId)]
    
    if not entry then updateStatus("Jogo nao suportado.", true) task.wait(5) gui:Destroy() return end
    
    local src_ok, source = pcall(function() return game:HttpGet(entry.urls[1], true) end)
    if not src_ok then updateStatus("Erro no download do Script.", true) task.wait(5) gui:Destroy() return end
    
    updateStatus("A Executar...", false)
    local chunk, err = loadstring(source)
    if chunk then
        pcall(chunk)
        updateStatus("Carregado com sucesso!", false)
        task.wait(2) gui:Destroy()
    else
        updateStatus("Erro de sintaxe: " .. tostring(err), true)
        task.wait(5) gui:Destroy()
    end
else
    updateStatus("Negado pelo Server: " .. tostring(data.error), true)
    task.wait(5) gui:Destroy()
end