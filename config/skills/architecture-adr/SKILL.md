---
name: architecture-adr
description: >
  Építészeti döntések dokumentálása (Architecture Decision Records - ADR).
  Aktiválódik technológia választásakor, nagy refaktornál, adatbázis vagy keretrendszer cseréjekor,
  vagy ha a felhasználó "adr", "architecture", "döntés", "system design", "technológia választás" szavakat említ.
---

# Architecture-ADR: Építészeti Döntési Napló (ADR) Menedzsment

## 1. Mi az az ADR (Architecture Decision Record)?

Az ADR egy rövid szöveges dokumentum (hasonlóan egy git commit leíráshoz), amely rögzíti:
- Egy fontos szoftverépítészeti döntés **kontextusát**
- A választott megoldást és az **elvetett alternatívákat**
- A döntés pozitív és negatív **következményeit**

Minden ADR a `docs/adr/` mappában kap helyet, sorszámozva (pl. `0001-drizzle-orm-kivalasztasa.md`).

---

## 2. Standard ADR Sablon (Michael Nygard Formátum)

```markdown
# [Sorszám]. [Döntés címe tömören, pl: 0003-redis-alapu-rate-limiting]

- **Dátum**: 2026-11-15
- **Státusz**: [Javasolt / Elfogadva / Felülbírálva / Elvetve]
- **Döntéshozók**: [Nevek vagy Ágens / Architekt]

## Kontextus és Problémafelvetés
Miért van szükség a döntésre? Milyen üzleti vagy technikai kényszer áll fenn?
*Példa: A bejelentkezési végpont brute-force támadásoknak van kitéve, és a jelenlegi in-memory memóriatábla nem működik több szerverpéldány (horizontális skálázás) esetén.*

## Megvizsgált Opciók
1. **Opció A**: Memóriabeli token bucket (egyszerű, de nem működik klaszterben).
2. **Opció B**: Adatbázis táblában rögzített kérések (túlterheli a PostgreSQL-t).
3. **Opció C**: Redis Sorted Set (ZSET) alapú Sliding Window számláló.

## A Választott Döntés
A **3. Opciót (Redis ZSET)** választottuk, mert elosztott környezetben is atomi műveleteket biztosít, a memória lábnyoma minimális és a válaszideje <2 ms.

## Következmények

### Pozitív (Előnyök)
- Megbízhatóan véd a brute force támadások ellen horizontálisan skálázott podok esetén is.
- A sliding window garantálja, hogy az ablakhatáron ne lehessen dupla terhelést generálni.

### Negatív (Kockázatok / Költségek)
- Új infrastruktúra-függőségként bekerül a Redis, amit monitorozni és klaszterezni kell.
- Ha a Redis elérhetetlenné válik, fail-open vagy fail-closed házirendet kell választani.
```

---

## 3. ADR Életciklus és Felülbírálás (Superseding)

> [!IMPORTANT]
> A meglévő, elfogadott ADR-eket **SOHA nem töröljük vagy írjuk át utólag**!
> Ha egy korábbi technológiai döntés megváltozik:
> 1. Hozz létre egy új ADR-t (pl. `0005-postgres-atallas-mariadb-helyett.md`).
> 2. A régi ADR státuszát állítsd `Felülbírálva` (Superseded by ADR 0005) értékre.
> 3. Hivatkozz a két dokumentum között!
