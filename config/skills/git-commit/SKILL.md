---
name: git-commit
description: >
  Automatikus git commit üzenet generálás Conventional Commits szabvány szerint.
  Aktiválódik amikor az ágens git commit-ot készít, vagy amikor a felhasználó
  "commit", "git üzenet", "push előtt" szavakat ír.
---

# Git Commit Formatter Skill

## Conventional Commits Szabvány

Minden commit üzenet formátuma:
```
type(scope): rövid leírás (max 72 karakter)

[opcionális törzs - részletes magyarázat]

[opcionális lábléc]
BREAKING CHANGE: leírás
Closes #123
```

## Típusok

| Típus | Mikor |
|-------|-------|
| `feat` | Új funkcionalitás |
| `fix` | Hibajavítás |
| `refactor` | Kód átszervezés (nem fix, nem feat) |
| `docs` | Csak dokumentáció változás |
| `test` | Teszt hozzáadás/módosítás |
| `chore` | Build, konfig, függőség változás |
| `style` | Formázás (nem érinti a logikát) |
| `perf` | Teljesítmény javítás |
| `ci` | CI/CD konfiguráció |

## Automatikus Generálás Lépései

1. **Elemzés**: `git diff --staged` futtatása
2. **Kategorizálás**: A módosított fájlok és sorok alapján típus meghatározása
3. **Scope**: Az érintett modul/komponens neve zárójelben
4. **Üzenet**: Jelen idő, aktív ige, kisbetűs kezdet

## Szabályok

> [!IMPORTANT]
> - Jelen idő: "add feature" nem "added feature"
> - Kisbetűvel kezdd a leírást
> - Nincs pont a végén
> - Magyar vagy angol - legyen következetes a projekttel
> - Breaking change esetén `!` jelet adj a típus után: `feat!: ...`

## Workflow

```bash
# 1. Staged változások megtekintése
git diff --staged --stat

# 2. Részletes diff
git diff --staged

# 3. Commit üzenet generálás és elküldés
git commit -m "type(scope): description"
```

## Példák

```
feat(auth): add OAuth2 PKCE flow for secure token exchange
fix(api): handle null response from external payment service
refactor(db): extract query builder into separate module
docs(readme): update installation instructions for Windows
test(auth): add unit tests for token validation
chore(deps): bump react from 18.2 to 18.3
perf(cache): implement LRU eviction for in-memory cache
```
