---
name: task-scratchpad
description: >
  Állapot- és feladatkövető rendszer hosszú, komplex fejlesztési feladatokhoz.
  Aktiválódik több lépésből álló funkciók megvalósításakor, monorepo refaktoráláskor,
  vagy ha a kontextusablak tömörítése veszélyeztetné a terv részleteinek megőrzését.
---

# Task Scratchpad: Strukturált Memória- és Állapotkezelés

## Miért szükséges?

Amikor egy feladat 10-nél több eszközhívást és több tucat fájlmódosítást igényel, a modell kontextusa
tömörítésen (Condenser) megy keresztül. A Scratchpad mechanizmus biztosítja, hogy a terv, a jelenlegi
állapot és a kipróbált (de sikertelen) megközelítések soha ne vesszenek el.

---

## A Scratchpad Fájl: `.agents/SCRATCHPAD.md`

Komplex feladat megkezdésekor hozz létre vagy inicializálj egy `.agents/SCRATCHPAD.md` fájlt a projekt gyökerében.

### Standard Sablon

```markdown
# 📋 Task Scratchpad

## Célkitűzés
[1-2 mondatos tömör összefoglaló a végső elvárt eredményről]

## Lépések és Állapot
- [x] 1. lépés: Látens függőségek és jelenlegi architektúra feltárása (RepoMap + agent-lsp)
- [/] 2. lépés: Adatmodell és adatbázis sémák frissítése (Folyamatban: migrációs szkript írása)
- [ ] 3. lépés: Backend üzleti logika és végpontok implementálása
- [ ] 4. lépés: TDD egységtesztek és reprodukciós tesztek futtatása
- [ ] 5. lépés: Frontend típusok szinkronizálása és komponensek bekötése
- [ ] 6. lépés: E2E Playwright tesztek és kódellenőrzés (code-reviewer)

## ⛔ Zsákutcák és Megállapítások (Ne próbáld újra!)
- *Megközelítés A*: A `v1/auth` endpoint nem támogatja a Bearer headert, csak a session cookie-t.
- *Megközelítés B*: A `lib-xyz` 2.0-s verziója nem kompatibilis a jelenlegi Node runtime-mal, maradjunk az 1.9-nél.

## 🔑 Kritikus Konfigurációk és Szimbólumok
- Fő interfész: `src/types/user.ts` -> `IUserProfile`
- Adatbázis tábla: `user_sessions`
```

---

## Működési Szabályok

1. **Inkrementális Frissítés**:
   Minden logikai részfeladat befejezése után frissítsd a Scratchpad jelölőit (`[ ]` -> `[/]` -> `[x]`).
2. **Zsákutca Rögzítése**:
   Ha egy kísérlet hibára futott (pl. nem létező API, elavult csomag), AZONNAL írd be a `⛔ Zsákutcák` szekcióba! Ezzel megakadályozod, hogy a következő turn-ökben újra megpróbáld ugyanazt.
3. **Kontextus-Visszaállítás**:
   Ha a beszélgetés hosszúvá válik vagy bizonytalan vagy a következő lépésben, először olvasd be a `.agents/SCRATCHPAD.md`-t a folytatás előtt.
4. **Befejezés és Takarítás**:
   A feladat teljes befejezésekor és sikeres tesztelésekor a Scratchpadot összegezheted a felhasználónak, vagy archiválhatod.
