---
name: code-reviewer
description: >
  Önálló kódminőség-ellenőrző és refaktorálási (Critic) protokoll.
  Aktiválódik commit előtt, pull request készítéskor, refaktorálás után, vagy ha a felhasználó
  "review", "átnézés", "ellenőrzés", "clean code", "kódminőség" szavakat kér.
---

# Code-Reviewer: Szigorú Kódátvizsgálási és Minőségbiztosítási Protokoll

## Célkitűzés
Független, kritikus szemmel átvizsgálni a változtatásokat a `git diff` alapján még a véglegesítés előtt,
kiszűrve a technikai adósságot, a rejtett hibákat és a hiányos típusokat.

---

## Ellenőrzési Dimenziók (A "4C" Szabályrendszer)

### 1. Correctness (Helyesség és Peremfeltételek)
- Kezelve vannak-e a `null`, `undefined`, üres tömbök/stringek?
- Van-e kezeletlen Promise / aszinkron hiba (`try/catch` vagy `.catch()`)?
- Erőforrások (file handlerek, DB connection-ök, socketek) garantáltan lezáródnak-e (`finally` blokk / context manager)?
- Nincsenek-e `off-by-one` hibák ciklusokban vagy szeleteléseknél?

### 2. Clarity & Clean Code (Olvashatóság és Karbantarthatóság)
- A változó- és függvénynevek kifejezik-e a pontos szándékot?
- Egy függvény csak egyetlen felelősséggel bír-e (Single Responsibility)?
- Kerüljük a "Magic Number"-öket: konstansokba vannak-e szervezve az értékek?
- Felesleges kommentek (pl. "megnöveli a számlálót 1-gyel") vagy bennfelejtett `console.log` / `print` debug sorok törölve lettek-e?

### 3. Completeness (Típusok és Tesztek)
- Szigorú típusosság érvényesül-e? (TypeScriptben: NINCS felesleges `any` vagy `as unknown`; Pythonban: type hint-ek megléte).
- Készült-e egységteszt vagy integrációs teszt az új logikai elágazásokra?
- A létező tesztcsomag futtatása hibátlanul átment-e?

### 4. Concurrency & Performance (Párhuzamosság és Teljesítmény)
- Nincsenek-e felesleges $O(N^2)$ egymásba ágyazott ciklusok nagy adathalmazokon?
- Nem történik-e redundáns adatbázis-lekérdezés ciklus belsejében (N+1 probléma)?
- Párhuzamosítható aszinkron hívásoknál használjuk-e a `Promise.all()` / `asyncio.gather()`-t?

---

## Review Kimeneti Sablon

A review eredményét az alábbi tömör struktúrában kell összefoglalni:

```markdown
### 🔍 Kódátvizsgálási Értékelés

- **Státusz**: [✅ JÓVÁHAGYVA / ⚠️ JAVÍTÁS SZÜKSÉGES / ❌ ELUTASÍTVA]
- **Kockázati szint**: [Alacsony / Közepes / Magas]

#### 🚨 Kritikus észrevételek (Blocker)
- `src/services/order.ts:42`: Kezeletlen null pointer, ha a `user.profile` nincs kitöltve.

#### 💡 Ajánlott refaktorálási pontok (Improvement)
- `src/utils/math.ts:15`: A ciklus helyett `Array.reduce` tisztább és gyorsabb lenne.

#### 🧪 Tesztlefedettségi státusz
- Új kódlefedettség: 2 új teszt hozzáadva, meglévő tesztek mind zöldek.
```
