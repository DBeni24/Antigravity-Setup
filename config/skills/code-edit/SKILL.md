---
name: code-edit
description: >
  Precíziós fájlszerkesztési konvenciók. Aktiválódik fájlok módosításakor,
  kód átíráskor, refaktorálásnál, vagy ha az ágens kódot kell hogy szerkesszen.
  Implementálja az Aider-stílusú SEARCH/REPLACE fallback kaszkádot.
---

# Precíziós Kódszerkesztési Skill

## Alap Szabály

Fájlok módosításakor **mindig** az `edit_file` eszközt használd a `write_file`
helyett, kivéve ha teljesen új fájlt hozol létre.

## SEARCH/REPLACE Fallback Kaszkád

Az alábbi stratégiákat ebben a sorrendben alkalmazd:

### 1. Lépés: Pontos Egyezés (perfect_replace)
Keress **karakterpontos** egyezést, beleértve a szóközöket és behúzásokat.
Ha megtalálod, cseréld le és ÁLLJ MEG.

### 2. Lépés: Whitespace Tolerancia (replace_part_with_missing_leading_whitespace)
Ha az 1. lépés nem sikerül, próbálj meg **behúzás-mentes** illesztést:
- Távolítsd el a vezető szóközöket a SEARCH blokkból
- Illesszük az eredeti fájl behúzási szintjéhez

### 3. Lépés: Ellipsis Kiterjesztés (try_dotdotdots)
Ha `...` jelzést használsz a kódban, az **wildcard**-ként értelmezendő.
A teljes kódbázisban keressen iteratívan kiterjesztett egyezést.

## Szerkesztési Formátum

```
<<<<<<< SEARCH
[pontos eredeti kódrészlet - EZT PONTOSAN MÁSOLD BE]
=======
[új kód ami lecseréli]
>>>>>>> REPLACE
```

## Kritikus Szabályok

> [!IMPORTANT]
> - A SEARCH blokkba **mindig** az aktuálisan a fájlban lévő kódot másold
> - Ne egészítsd ki a SEARCH blokkot saját "emlékezetből"
> - Az első sikeres egyezésnél cserélje le a kódot (ne keresgéljen tovább)
> - Ha nem találod a pontos egyezést: először olvasd be a fájlt, MAJD szerkeszd

## Token Optimalizáció

| Feladat | Ajánlott |
|---------|----------|
| Kis módosítás (1-10 sor) | `edit_file` SEARCH/REPLACE |
| Nagy refaktor (>50 sor) | Fájl beolvasás + SEARCH/REPLACE |
| Új fájl | `write_file` |
| Teljes fájl csere | Csak ha valóban szükséges |

## Példa

```python
# HELYES - pontos SEARCH blokk
<<<<<<< SEARCH
    timeout = 30
    retries = 3
=======
    timeout = 60
    retries = 5
>>>>>>> REPLACE

# HELYES - ellipsis használat változatlan kódnál
<<<<<<< SEARCH
def process_data(items):
    ...
    return result
=======
def process_data(items, validate=True):
    ...
    if validate:
        _validate(items)
    return result
>>>>>>> REPLACE
```
