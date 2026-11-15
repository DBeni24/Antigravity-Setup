---
name: github-actions-ci
description: >
  Professzionális GitHub Actions CI/CD munkafolyamatok tervezése és automatizálása.
  Aktiválódik CI/CD pipeline-ok írásakor, GitHub Actions workflow fájlok módosításakor,
  vagy ha a felhasználó "github actions", "ci/cd", "pipeline", "workflow", "ci" szavakat említ.
---

# GitHub-Actions-CI: Megbízható és Gyors CI/CD Munkafolyamatok

## 1. Alapvető Filozófia: Gyors Visszajelzés és Fail-Fast

- **Parallel Jobs**: Futtasd a lintert, a típusellenőrzést és az egységteszteket külön párhuzamos jobokban.
- **Dependency Caching**: Mindig gyorsítótárazd az `npm` / `pip` / `cargo` csomagokat a gyors futásidő érdekében.
- **Biztonságos Titokkezelés**: Soha ne logolj secret-eket, és minimalizáld a `GITHUB_TOKEN` jogosultságokat (`permissions:` blokk).

---

## 2. Standard Full-Stack CI Workflow Sablon

Hozd létre a `.github/workflows/ci.yml` fájlban:

```yaml
name: Continuous Integration

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true # Automatikusan törli a régi futást, ha új commit érkezik

permissions:
  contents: read

jobs:
  lint-and-typecheck:
    name: Lint & Typecheck
    runs-on: ubuntu-latest
    steps:
      - name: Kód letöltése
        uses: actions/checkout@v4

      - name: Node.js környezet beállítása
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Függőségek telepítése
        run: npm ci

      - name: Linter futtatása
        run: npm run lint

      - name: TypeScript típusellenőrzés
        run: npx tsc --noEmit

  test:
    name: Unit & Integration Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22] # Több verzión tesztel párhuzamosan
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage
```

---

## 3. Docker Build & Push Workflow (GitHub Container Registry - GHCR)

Hozd létre a `.github/workflows/docker-publish.yml` fájlban:

```yaml
name: Build & Push Docker Image

on:
  push:
    tags: ['v*.*.*'] # Csak verziócímke esetén fut

permissions:
  contents: read
  packages: write # Engedély a GHCR registry-be való feltöltéshez

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Docker Buildx beállítása
        uses: docker/setup-buildx-action@v3

      - name: Bejelentkezés a GHCR-be
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Docker metaadatok kivonatolása
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}

      - name: Image építése és közzététele
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha # GitHub Actions cache a szupergyors építésért
          cache-to: type=gha,mode=max
```
