# Globális Ágens Szabályok (AGENTS.md)
# Betöltési sorrend: ELSŐ (felülírható projekt szintű AGENTS.md-del)

## Általános Kódolási Elvek

- **Mindig** olvasd el a meglévő kódot mielőtt módosítasz
- Preferált nyelvek: Python, TypeScript, PowerShell (Windows)
- Minden szerkesztés után ellenőrizd a szintaxist
- Ha egy feladat destruktív (törlés, séma módosítás, force push), kérj megerősítést

## Fájlszerkesztési Konvenciók

Fájlok módosításakor a SEARCH/REPLACE blokkokat részesítsd előnyben:
```
<<<<<<< SEARCH
[pontos eredeti kódrészlet]
=======
[új kód]
>>>>>>> REPLACE
```

Fallback kaszkád:
1. Pontos egyezés → első találatnál cserél
2. Whitespace tolerancia → behúzás-mentes illesztés
3. Ellipsis (`...`) → wildcard a változatlan részekre

## Biztonsági Szabályok

- SOHA ne futtass `rm -rf`, `format`, `DROP TABLE` emberi jóváhagyás nélkül
- API kulcsokat és titkokat soha ne írj kódba (env változókat használj)
- Hálózati kérések előtt ellenőrizd a célpontot
- Sandbox-on kívüli fájlok módosítása előtt kérj megerősítést

## Git Konvenciók

Commit üzenetek formátuma (Conventional Commits):
```
type(scope): rövid leírás

Típusok: feat, fix, refactor, docs, test, chore, style, perf
Példa: feat(auth): add OAuth2 PKCE flow
```

## Teszt Prioritás

1. Meglévő tesztek NE törjenek el
2. Új funkcionalitáshoz írj tesztet
3. Regressziós teszteket mindig futtasd lefuttatás előtt

## Preferált Eszközök és Skillek

| Feladat | Eszköz / Skill |
|---|---|
| Szimbólum keresés (pontos) | grep / run_command / agent-lsp |
| Hivatkozások keresése | LSP find_references (agent-lsp) |
| Nagy repo navigáció | RepoMap + PageRank (`repomap` skill) |
| Fájl indexelés | code-index-mcp / tree-sitter |
| Vizuális teszt | Playwright MCP (`@playwright/mcp`) |
| Hibajavítás & TDD | `reproduce-issue` (RED -> GREEN -> REFACTOR) |
| Komplex feladatkövetés | `task-scratchpad` (`.agents/SCRATCHPAD.md`) |
| Kódminőség & Critic | `code-reviewer` (4C szabályzat) |
| Biztonsági vizsgálat | `security-sast` (Secret detection & audit) |
| Frontend & React 19 / Next.js | `react-modern-patterns` (RSC, Server Actions, App Router) |
| UI & Stílusozás | `ui-tailwind-shadcn` (Tailwind CSS, shadcn/ui, a11y) |
| Python Backend | `fastapi-expert` (FastAPI, Pydantic v2, DI) |
| CI/CD & Pipeline | `github-actions-ci` (GitHub Actions mátrixok, cache, Docker push) |
| Docker Hardening | `docker-production-hardening` (Multi-stage, rootless, minimal image) |
| API Mocking | `api-mocking-msw` (MSW v2 hálózati interceptálás, offline tesztek) |
| Architektúra Döntések | `architecture-adr` (Architecture Decision Records, docs/adr/) |
| PostgreSQL optimalizálás | `db-postgres-expert` (EXPLAIN ANALYZE, GIN indexek, JSONB) |
| Caching & Rate Limit | `redis-patterns` (Cache-Aside, Sliding Window, Redlock) |
| Háttérfeladatok & Queue | `async-queue-worker` (BullMQ, Celery, retry, DLQ) |
| Adatbázis ORM | `orm-master` (Prisma, Drizzle, SQLAlchemy) |
| Bemenet validáció | `schema-validation-zod` (Zod safeParse, env validáció) |
| API & Típus szinkronizáció | `api-typesync` (OpenAPI -> TypeScript) |
| Izolált Linux tesztelés | `container-sandbox` (Docker / WSL) |
| PR & Changelog | `changelog-pr` (Conventional & Keep a Changelog) |
| Fájlszerkesztés | `code-edit` (SEARCH/REPLACE kaszkád) |
| Adatbázis módosítás | `db-safety` (Tranzakció & jóváhagyás) |
| Git commit | `git-commit` (Conventional Commits) |
