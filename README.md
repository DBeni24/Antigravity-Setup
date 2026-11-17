# Antigravity SOTA Toolkit

Egy egységes, hordozható kiegészítő készlet a Google Antigravity autonóm kódolási környezethez. Tartalmazza a mélykutatás alapján összeállított összes képességnövelő modult, szabályzatot, hookot és MCP szerver konfigurációt.

## Használati cél

A repó célja, hogy a tulajdonos a Google Antigravity toolkészletét több saját
eszközén könnyen szinkronizálhassa és egységesen használhassa. Ez fejlesztői
eszközkonfiguráció, nem egy adott alkalmazás futtatási függősége vagy forrása.

---

## 📦 Tartalom

- **23 db specializált skill** (`config/skills/`):
  - Kódnavigáció és Gráf: `repomap`
  - Szerkesztési protokoll: `code-edit` (SEARCH/REPLACE)
  - TDD és Hibajavítás: `reproduce-issue`
  - Állapotkövetés: `task-scratchpad`
  - Minőség és Biztonság: `code-reviewer`, `security-sast`, `db-safety`
  - Web & Frontend: `react-modern-patterns`, `ui-tailwind-shadcn`, `schema-validation-zod`
  - Backend & Adatbázis: `fastapi-expert`, `orm-master`, `db-postgres-expert`, `redis-patterns`, `async-queue-worker`
  - DevOps & Release: `github-actions-ci`, `docker-production-hardening`, `api-mocking-msw`, `architecture-adr`, `changelog-pr`, `git-commit`, `container-sandbox`, `api-typesync`
- **Globális Szabályzat** (`config/rules/AGENTS.md`)
- **Életciklus Hook-ok** (`config/hooks/`): Safety Gate parancsszűrő és automatikus fordítási/szintaxis ellenőrző
- **MCP Konfiguráció** (`config/mcp_config.json`): `agent-lsp`, `code-index-mcp`, `mcp-server-tree-sitter`, `@playwright/mcp`

---

## 🚀 Villámgyors Telepítés Másik Gépen (1 Soros Parancs)

### Windows (Git sem szükséges!):
Nyiss egy normál PowerShell ablakot (Rendszergazdaként vagy simán), és másold be:
```powershell
irm https://raw.githubusercontent.com/DBeni24/Antigravity-Setup/main/bootstrap.ps1 | iex
```
*Ez a parancs automatikusan letölti a csomagot a GitHub-ról, kicsomagolja a háttérben, és lefutatja a teljes konfigurációt (Node.js, uv, MCP szerverek, 23 skill).*

---

### Hagyományos Telepítés (Ha van Git a gépeden):

```powershell
git clone https://github.com/DBeni24/Antigravity-Setup.git
cd Antigravity-Setup
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### Linux / macOS / WSL:
```bash
chmod +x ./install.sh
./install.sh
```

---

## ⚙️ Testreszabás

A telepítés után a globális szabályok és skillek a `~/.gemini/config/` könyvtárban élnek, és minden új Antigravity beszélgetésben azonnal elérhetőek.
