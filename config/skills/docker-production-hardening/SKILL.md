---
name: docker-production-hardening
description: >
  Éles (Production) környezetre optimalizált, biztonságos és minimális méretű Docker konténerek készítése.
  Aktiválódik Dockerfile írásakor, konténerizálás optimalizálásakor,
  vagy ha a felhasználó "dockerfile", "docker build", "distroless", "multi-stage", "konténer méret" szavakat említ.
---

# Docker-Production-Hardening: Biztonságos és Pehelysúlyú Konténerek

## 1. Aranyszabályok Éles Konténerekhez

> [!CAUTION]
> 1. **SOHA ne futtass konténert `root` felhasználóként!** Mindig hozz létre és használj dedikált `USER`-t.
> 2. **Mindig használj Multi-Stage buildet**: a fordítóprogramok, SDK-k és devDependency-k ne kerüljenek bele a végleges image-be!
> 3. **Rögzíts pontos alap-verziókat**: `node:20.18-alpine` vagy `python:3.12-slim`, ne használd a `:latest` taget.
> 4. **Optimalizáld a réteg-gyorsítótárazást (Layer Caching)**: Először a függőségleírókat (`package.json`, `requirements.txt`) másold be, és csak a telepítés után a forráskódot!

---

## 2. Termelési Node.js / Next.js Multi-Stage Dockerfile

```dockerfile
# 1. Fázis: Függőségek letöltése
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# 2. Fázis: Alkalmazás fordítása (Build)
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# 3. Fázis: Végleges Production Runner (Minimális méret & Rootless)
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Nem root felhasználó létrehozása
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Csak a lefordított fájlok átmásolása
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

# Egészségellenőrzés (Healthcheck)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
```

---

## 3. Termelési Python / FastAPI Dockerfile (uv-val gyorsítva)

```dockerfile
# 1. Fázis: Fordítás
FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

COPY . .
RUN uv sync --frozen --no-dev

# 2. Fázis: Végleges Runner
FROM python:3.12-slim AS runner
WORKDIR /app

# Biztonsági felhasználó
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -m appuser

# Csak a virtuális környezet és a kód átvétele
COPY --from=builder --chown=appuser:appgroup /app/.venv /app/.venv
COPY --from=builder --chown=appuser:appgroup /app/src /app/src

ENV PATH="/app/.venv/bin:$PATH"
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

---

## 4. Kötelező `.dockerignore` Fájl

Minden projekt gyökerében kötelező:
```
node_modules
.venv
__pycache__
.git
.github
.env
.env.local
*.log
dist
coverage
```
