---
name: changelog-pr
description: >
  Automatikus Pull Request leírás és CHANGELOG.md generáló és karbantartó.
  Aktiválódik release készítésekor, PR nyitásakor, verzióváltáskor, vagy ha a felhasználó
  "pr", "pull request", "changelog", "release notes", "verziókövetés" szavakat említ.
---

# Changelog-PR: Professzionális Kiadási és PR Kezelő

## Célkitűzés
A végrehajtott commitok és módosítások alapján emberi minőségű, átlátható Pull Request összefoglalókat
és szabványos `CHANGELOG.md` bejegyzéseket generálni (Keep a Changelog & SemVer szerint).

---

## 1. Pull Request Leírás Generálási Sablon

A `git diff main...HEAD` és a commit történet elemzése után generáld az alábbi struktúrát:

```markdown
## 📌 Összefoglaló
[1-2 mondat a PR céljáról és az elért változásról]

## 🛠️ Főbb Változtatások
- **feat(auth)**: OAuth2 PKCE hitelesítési flow implementálása token csere védelmével.
- **fix(api)**: Null érték kezelése profil lekérdezésekor a váratlan 500-as hiba megelőzésére.
- **test**: Új reprodukciós és regressziós egységtesztek hozzáadása.

## 🧪 Hogyan Tesztelhető?
1. Indítsd el a backend szervert: `npm run dev`
2. Navigálj a `/login` oldalra és próbálj meg belépni.
3. Futtasd a tesztcsomagot: `npm test` -> Minden teszt zöld.

## ⚠️ Breaking Changes
- Nincs (vagy ha van: részletes leírás és migrációs teendők).

## 🔗 Kapcsolódó Issue-k
Closes #123
```

---

## 2. CHANGELOG.md Karbantartási Szabályok

Mindig kövesse a [Keep a Changelog](https://keepachangelog.com/) szabványt:

```markdown
## [Unreleased]

### Added
- Új funkciók listája

### Changed
- Meglévő működés módosításai

### Fixed
- Javított hibák listája

### Security
- Biztonsági javítások és frissítések
```

Commitok kigyűjtése a legutóbbi tag óta:
```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```
