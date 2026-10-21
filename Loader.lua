import discord
from discord import app_commands
from discord.ext import tasks
import aiohttp
import os
import asyncio
import base64
import hashlib
import json
from aiohttp import web
from datetime import datetime
from zoneinfo import ZoneInfo

intents = discord.Intents.default()
bot = discord.Client(intents=intents)
tree = app_commands.CommandTree(bot)

WORKER_URL = "https://eclipse-proxy.andrepequeno31.workers.dev"
SECRET = "EclipseBot2024!"
CARGO_PERMITIDO = 1379418842618400898 

# O Token do GitHub vai ser lido de forma segura aqui:
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
GITHUB_REPO = "StarFutXZ/Loader-Main"
GITHUB_FILE_PATH = "secure_keys.json"

async def api_request(endpoint: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(f"{WORKER_URL}{endpoint}") as resp:
            try: return await resp.json()
            except: return {"error": "Erro."}

# ==========================================
# FUNÇÃO: HASH E ENVIAR PARA O GITHUB
# ==========================================
async def sync_keys_to_github():
    if not GITHUB_TOKEN or "ghp_" not in GITHUB_TOKEN: 
        print("❌ Token do GitHub não configurado nas variáveis do Render.")
        return
    
    res = await api_request("/api/allkeys")
    keys = res.get("keys", [])
    
    hashed_keys = []
    for k in keys:
        hash_obj = hashlib.sha256(k.encode())
        hashed_keys.append(hash_obj.hexdigest())
    
    final_data = json.dumps({"hashes": hashed_keys})
    content_b64 = base64.b64encode(final_data.encode()).decode()
    
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    async with aiohttp.ClientSession() as session:
        get_url = f"https://api.github.com/repos/{GITHUB_REPO}/contents/{GITHUB_FILE_PATH}"
        async with session.get(get_url, headers=headers) as resp:
            sha = None
            if resp.status == 200:
                data = await resp.json()
                sha = data["sha"]
        
        payload = {"message": "Auto-update secure keys", "content": content_b64}
        if sha: payload["sha"] = sha
            
        async with session.put(get_url, headers=headers, json=payload) as resp:
            if resp.status in [200, 201]:
                print("✅ Hashes enviados para o GitHub com sucesso!")
            else:
                print(f"❌ Erro ao enviar para o GitHub: {await resp.text()}")

# ==========================================
# SISTEMA WEAO
# ==========================================
def construir_payload(corpo_texto: str, footer_texto: str) -> dict:
    return {
        "flags": 32768,
        "components": [{"type": 17, "components": [
            {"type": 12, "items": [{"media": {"url": "https://cdn.discordapp.com/attachments/1379466761354874954/1548086533112991754/image_3-1.png?ex=6aa5c76f&is=6aa475ef&hm=56aaedad7f98e4d2448aa3b916511d77de15af4a6b7493d769ff6f4e64994b3f&"}}]},
            {"type": 14, "divider": True, "spacing": 1},
            {"type": 10, "content": corpo_texto},
            {"type": 14, "divider": True, "spacing": 1},
            {"type": 10, "content": f"-# {footer_texto}"},
        ]}],
    }

async def buscar_dados_weao() -> tuple[bool, str]:
    url = "https://weao.xyz/api/status/exploits"
    headers = {"User-Agent": "WEAO-3PService"}
    async with aiohttp.ClientSession(headers=headers) as session:
        async with session.get(url, timeout=30) as response:
            if response.status != 200: return False, "Erro na API WEAO."
            dados = await response.json()

    windows_exploits, mac_exploits, windows_externals = [], [], []
    nomes_externals_conhecidos = ["serotonin", "matcha", "severe", "lumen", "matrix hub", "melatonin", "axis", "photon", "ronin", "dx9ware v2", "dx9ware"]

    if isinstance(dados, list):
        for exp in dados:
            nome = exp.get("title", "Desconhecido")
            versao = exp.get("version", "")
            atualizado = exp.get("updateStatus", False)
            status_emoji = "<:zw_GreenCircle:1547801001241608315>" if atualizado else "<:zw_RedCircle:1547800979242745876>"
            linha = f"- {nome} | `{versao}` | {status_emoji}"
            nome_lower = nome.lower()
            plataforma = str(exp.get("platform", "")).lower()
            tipo = str(exp.get("type", "")).lower()
            is_external = exp.get("isExternal", False) or exp.get("external", False)

            if "mac" in plataforma or "mac" in tipo or "mac" in nome_lower: mac_exploits.append(linha)
            elif is_external or any(ext in nome_lower for ext in nomes_externals_conhecidos) or "external" in tipo: windows_externals.append(linha)
            else: windows_exploits.append(linha)

    blocos = []
    if windows_exploits: blocos.append("**Windows Exploits**\n" + "\n".join(windows_exploits))
    if mac_exploits: blocos.append("\n**Mac Exploits**\n" + "\n".join(mac_exploits))
    if windows_externals: blocos.append("\n**Windows Externals**\n" + "\n".join(windows_externals))
    return True, "\n".join(blocos).strip()

@tasks.loop(minutes=15)
async def loop_atualizar_status():
    ok, corpo_texto = await buscar_dados_weao()
    if not ok: return
    hora = datetime.now(ZoneInfo("Europe/Lisbon")).strftime("%H:%M")
    payload = construir_payload(corpo_texto, f"Provided by weao.xyz • Atualizado às {hora}")
    headers = {"Authorization": f"Bot {os.environ.get('DISCORD_TOKEN')}", "Content-Type": "application/json"}
    async with aiohttp.ClientSession() as session:
        for guild in bot.guilds:
            for channel in guild.text_channels:
                async with session.get(f"https://discord.com/api/v10/channels/{channel.id}/messages?limit=5", headers=headers) as resp:
                    if resp.status != 200: continue
                    messages = await resp.json()
                    for msg in messages:
                        if msg["author"]["id"] == bot.user.id and "WEAO" in msg.get("content", ""):
                            edit_url = f"https://discord.com/api/v10/channels/{channel.id}/messages/{msg['id']}"
                            await session.patch(edit_url, json=payload, headers=headers)
                            break

@loop_atualizar_status.before_loop
async def before_loop(): await bot.wait_until_ready()

# ==========================================
# MODAIS E VIEWS (Painéis)
# ==========================================
class ModalGetScript(discord.ui.Modal, title="Obter Script"):
    key_input = discord.ui.TextInput(label="Cola aqui a tua Key", placeholder="Eclipse-XXXX-XXXX-XXXX")
    async def on_submit(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True, thinking=True)
        texto = ("```lua\n" f"getgenv().Key = \"{self.key_input.value}\"\n" "loadstring(game:HttpGet(\"https://raw.githubusercontent.com/StarFutXZ/Loader-Main/refs/heads/main/Loader.lua?v=21\"))()\n" "```")
        await interaction.followup.send(texto, ephemeral=True)

class ModalRedeem(discord.ui.Modal, title="Resgatar Key"):
    key_input = discord.ui.TextInput(label="Cola aqui a tua Key")
    async def on_submit(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True, thinking=True)
        res = await api_request(f"/api/redeem?key={self.key_input.value}&user={interaction.user.id}")
        if res.get("success"):
            await interaction.followup.send(f"✅ Key vinculada!", ephemeral=True)
            await sync_keys_to_github()
        else:
            await interaction.followup.send(f"❌ {res.get('error', 'Erro')}", ephemeral=True)

class ModalDeleteKey(discord.ui.Modal, title="Eliminar Key"):
    key_input = discord.ui.TextInput(label="Cola aqui a Key a eliminar")
    async def on_submit(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True, thinking=True)
        res = await api_request(f"/api/delete?key={self.key_input.value}&secret={SECRET}")
        if res.get("success"):
            await interaction.followup.send(f"✅ Key eliminada.", ephemeral=True)
            await sync_keys_to_github()
        else:
            await interaction.followup.send(f"❌ {res.get('error', 'Erro')}", ephemeral=True)

class MenuKeysView(discord.ui.View):
    def __init__(self, keys, user_id):
        super().__init__(timeout=120)
        self.user_id = user_id
        options = [discord.SelectOption(label=k, description="Clica para copiar", value=k, emoji="🔑") for k in keys]
        select = discord.ui.Select(placeholder="Seleciona...", options=options)
        select.callback = self.select_callback
        self.add_item(select)
    async def select_callback(self, interaction: discord.Interaction):
        if interaction.user.id != self.user_id: return
        await interaction.response.send_message(f"`{interaction.data['values'][0]}`", ephemeral=True)

class PainelView(discord.ui.View):
    def __init__(self): super().__init__(timeout=None)
    @discord.ui.button(label="Get Script", style=discord.ButtonStyle.success, emoji="📜", custom_id="btn_get_script", row=0)
    async def btn_get_script(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.send_modal(ModalGetScript())
    @discord.ui.button(label="Redeem Key", style=discord.ButtonStyle.primary, emoji="🎟️", custom_id="btn_redeem_key", row=0)
    async def btn_redeem_key(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.send_modal(ModalRedeem())
    @discord.ui.button(label="Reset HWID", style=discord.ButtonStyle.danger, emoji="🔄", custom_id="btn_reset_hwid", row=0)
    async def btn_reset_hwid(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.defer(ephemeral=True, thinking=True)
        res = await api_request(f"/api/mykeys?user={interaction.user.id}")
        keys = res.get("keys", [])
        if not keys: return await interaction.followup.send("❌ Sem keys.", ephemeral=True)
        view = discord.ui.View()
        for k in keys: view.add_item(ResetButton(k))
        await interaction.followup.send("🔽 Seleciona:", view=view, ephemeral=True)
    @discord.ui.button(label="Minhas Keys", style=discord.ButtonStyle.secondary, emoji="📋", custom_id="btn_minhas_keys", row=1)
    async def btn_minhas_keys(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.defer(ephemeral=True, thinking=True)
        res = await api_request(f"/api/mykeys?user={interaction.user.id}")
        keys = res.get("keys", [])
        if not keys: return await interaction.followup.send("❌ Sem keys.", ephemeral=True)
        await interaction.followup.send("📋 Seleciona:", view=MenuKeysView(keys, interaction.user.id), ephemeral=True)

class AdminView(discord.ui.View):
    def __init__(self): super().__init__(timeout=None)
    @discord.ui.button(label="Gerar Key", style=discord.ButtonStyle.success, emoji="🔑", custom_id="btn_admin_gerar_key", row=0)
    async def btn_gerar_key(self, interaction: discord.Interaction, button: discord.ui.Button):
        if CARGO_PERMITIDO not in [role.id for role in interaction.user.roles]: return await interaction.response.send_message("❌ Sem permissão.", ephemeral=True)
        await interaction.response.defer(ephemeral=True, thinking=True)
        res = await api_request(f"/api/create?secret={SECRET}&user={interaction.user.id}")
        key = res.get("key", "Erro")
        await interaction.followup.send(f"✅ **Key:**\n```\n{key}\n```", ephemeral=True)
        await sync_keys_to_github()
    @discord.ui.button(label="Eliminar Key", style=discord.ButtonStyle.danger, emoji="🗑️", custom_id="btn_admin_eliminar_key", row=0)
    async def btn_eliminar_key(self, interaction: discord.Interaction, button: discord.ui.Button):
        if CARGO_PERMITIDO not in [role.id for role in interaction.user.roles]: return await interaction.response.send_message("❌ Sem permissão.", ephemeral=True)
        await interaction.response.send_modal(ModalDeleteKey())

class ResetButton(discord.ui.Button):
    def __init__(self, key):
        super().__init__(label=key, style=discord.ButtonStyle.secondary)
        self.key_to_reset = key
    async def callback(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True, thinking=True)
        res = await api_request(f"/api/resethwid?key={self.key_to_reset}")
        if res.get("success"):
            await interaction.followup.send(f"✅ HWID resetado!", ephemeral=True)
            await sync_keys_to_github()
        else:
            await interaction.followup.send(f"⏳ {res.get('error')}", ephemeral=True)

# ==========================================
# COMANDOS
# ==========================================
@tree.command(name="member-panel", description="Painel Público")
async def member_panel(interaction: discord.Interaction):
    if CARGO_PERMITIDO not in [role.id for role in interaction.user.roles]: return await interaction.response.send_message("❌ Sem permissão.", ephemeral=True)
    payload = {"flags": 32768, "components": [{"type": 17, "components": [{"type": 10, "content": "🌙 **Eclipse Hub — Painel**"}, {"type": 14, "divider": True}, {"type": 1, "components": [{"type": 2, "style": 3, "label": "Get Script", "custom_id": "btn_get_script"}, {"type": 2, "style": 1, "label": "Redeem Key", "custom_id": "btn_redeem_key"}, {"type": 2, "style": 4, "label": "Reset HWID", "custom_id": "btn_reset_hwid"}]}, {"type": 1, "components": [{"type": 2, "style": 2, "label": "Minhas Keys", "custom_id": "btn_minhas_keys"}]}]}]}
    async with aiohttp.ClientSession() as session:
        await session.post(f"https://discord.com/api/v10/channels/{interaction.channel.id}/messages", json=payload, headers={"Authorization": f"Bot {os.environ.get('DISCORD_TOKEN')}", "Content-Type": "application/json"})
    await interaction.response.send_message("✅ Enviado.", ephemeral=True)

@tree.command(name="admin-panel", description="Painel Admin")
async def admin_panel(interaction: discord.Interaction):
    if CARGO_PERMITIDO not in [role.id for role in interaction.user.roles]: return await interaction.response.send_message("❌ Sem permissão.", ephemeral=True)
    payload = {"flags": 32768, "components": [{"type": 17, "components": [{"type": 10, "content": "🛠️ **Eclipse Hub — Admin**"}, {"type": 14, "divider": True}, {"type": 1, "components": [{"type": 2, "style": 3, "label": "Gerar Key", "custom_id": "btn_admin_gerar_key"}, {"type": 2, "style": 4, "label": "Eliminar Key", "custom_id": "btn_admin_eliminar_key"}]}]}]}
    async with aiohttp.ClientSession() as session:
        await session.post(f"https://discord.com/api/v10/channels/{interaction.channel.id}/messages", json=payload, headers={"Authorization": f"Bot {os.environ.get('DISCORD_TOKEN')}", "Content-Type": "application/json"})
    await interaction.response.send_message("✅ Enviado.", ephemeral=True)

@bot.event
async def on_ready():
    bot.add_view(PainelView())
    bot.add_view(AdminView())
    if not loop_atualizar_status.is_running(): loop_atualizar_status.start()
    try: await tree.sync()
    except: pass

async def handle(request): return web.Response(text="OK")
async def main():
    token = os.environ.get("DISCORD_TOKEN")
    if not token: return
    app = web.Application(); app.router.add_get("/", handle)
    runner = web.AppRunner(app); await runner.setup()
    site = web.TCPSite(runner, "0.0.0.0", int(os.environ.get("PORT", 8080))); await site.start()
    await bot.start(token)

if __name__ == "__main__":
    asyncio.run(main())