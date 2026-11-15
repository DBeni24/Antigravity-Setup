---
name: security-sast
description: >
  Statikus biztonsági elemzés (SAST), hardkódolt titkok felderítése és függőségi sebezhetőség-vizsgálat.
  Aktiválódik új csomagok telepítésekor, hitelesítési/auth kód írásakor, vagy ha a felhasználó
  "security", "audit", "cve", "vulnerability", "secret", "token szivárgás" szavakat említ.
---

# Security-SAST: Kódbiztonsági és Függőségi Audit

## Célkitűzés
Megakadályozni, hogy sebezhető külső könyvtárak, hardkódolt titkok (API kulcsok, tokenek, jelszavak)
vagy kritikus OWASP Top 10 sebezhetőségek (SQL Injection, XSS, SSRF, Path Traversal) kerüljenek a kódbázisba.

---

## 1. Titok- és Kulcsszivárgás Megelőzése

> [!CAUTION]
> SOHA ne írj valódi titkot, privát kulcsot vagy jelszót forráskódba vagy tesztfájlba!

### Ellenőrizendő Minták (Gitleaks elvek alapján):
- **Általános API Kulcsok**: `(?i)(api_key|apikey|secret|token|password)\s*[:=]\s*['"][a-zA-Z0-9_\-]{16,}['"]`
- **Private Key-ek**: `-----BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY-----`
- **Cloud Tokenek**: `ghp_[a-zA-Z0-9]{36}`, `xox[baprs]-[0-9a-zA-Z]{10,48}`, `AIza[0-9A-Za-z-_]{35}`

### Helyes Kezelés:
- Környezeti változók használata (`process.env.VAR` vagy `os.environ["VAR"]`).
- Lokális fejlesztéshez: `.env.example` sablon létrehozása mockup értékekkel, és a valódi `.env` fájl kötelező felvétele a `.gitignore`-ba.

---

## 2. Függőségi Sebezhetőség-vizsgálat (Dependency Audit)

Minden új csomag hozzáadásakor vagy nagyobb verzióváltáskor futtasd a megfelelő parancsot:

| Ökoszisztéma | Audit Parancs |
|---|---|
| **Node.js / npm** | `npm audit` vagy `npm audit --audit-level=high` |
| **Python** | `uv pip audit` vagy `pip-audit` |
| **Rust** | `cargo audit` |
| **Go** | `govulncheck ./...` |

Ha a csomagban **Critical** vagy **High** besorolású CVE található:
1. Keress frissített, foltozott verziót.
2. Ha nincs javított verzió, válassz biztonságos alternatív csomagot!

---

## 3. Kódminőségi Biztonsági Ellenőrzőlista (OWASP Top 10)

- **Injection védelem**:
  - SQL: Mindig paraméterezett lekérdezés (`db-safety` skill szabályai szerint).
  - Shell: Soha ne konkatenálj külső bemenetet terminálparancsba (kerüld a `shell=True` / `eval()` / `exec()` hívásokat).
- **Path Traversal védelem**:
  - Felhasználó által megadott fájlneveket mindig normalizáld és szűrd (`os.path.basename`, `path.resolve` + könyvtárhatár-ellenőrzés).
- **SSRF (Server-Side Request Forgery)**:
  - Belső címek (`localhost`, `127.0.0.1`, `169.254.169.254`, `10.0.0.0/8`, `192.168.0.0/16`) blokkolása kifelé irányuló HTTP kéréseknél.
