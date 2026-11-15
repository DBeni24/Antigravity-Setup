# Antigravity SOTA Toolkit

Egy egységes, hordozható kiegészítő készlet a Google Antigravity autonóm kódolási környezethez. Tartalmazza a mélykutatás alapján összeállított összes képességnövelő modult, szabályzatot, hookot és MCP szerver konfigurációt.

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

## 🚀 Telepítés Másik Gépen

### Windows:
Nyiss egy PowerShell terminált a klónozott mappában, és futtasd:
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

A szkript automatikusan:
1. Ellenőrzi és beállítja a `uv` és `Node.js` környezetet
2. Telepíti a globális MCP csomagokat (`agent-lsp`, `code-index-mcp`, `mcp-server-tree-sitter`)
3. Átmásolja a skilleket, szabályokat és hookokat a `~/.gemini/config/` mappába
4. Frissíti a felhasználói `PATH` környezeti változókat

### Linux / macOS / WSL:
```bash
chmod +x ./install.sh
./install.sh
```

---

## ⚙️ Testreszabás

A telepítés után a globális szabályok és skillek a `~/.gemini/config/` könyvtárban élnek, és minden új Antigravity beszélgetésben azonnal elérhetőek.
