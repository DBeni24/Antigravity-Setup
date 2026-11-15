---
name: db-safety
description: >
  Adatbázis biztonsági protokoll. Aktiválódik SQL lekérdezéseknél,
  séma módosításnál, migrációs szkripteknél, ORM műveleteknél,
  vagy ha "adatbázis", "migration", "SQL", "schema" szavak szerepelnek.
---

# Adatbázis Migrációs és Biztonsági Skill

## Kötelező Szabályok

> [!CAUTION]
> Ezek a szabályok MINDEN adatbázis műveletre vonatkoznak, kivétel nélkül.

### 1. Tranzakciókezelés

Minden adatmódosító műveletet tranzakcióba kell csomagolni:

```sql
BEGIN TRANSACTION;
  -- módosítások
COMMIT;
-- vagy hiba esetén:
ROLLBACK;
```

```python
# Python ORM példa
with db.transaction():
    db.execute(query)
```

### 2. Séma Módosítás = Emberi Jóváhagyás

Az alábbi műveletek előtt **mindig** kérj megerősítést a felhasználótól:
- `ALTER TABLE`
- `DROP TABLE` / `DROP COLUMN`
- `CREATE TABLE` (éles adatbázison)
- `TRUNCATE`
- Indexek törlése

### 3. Csak Paraméterezett Lekérdezések

```python
# HELYES ✅
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# HIBÁS ❌ - SQL injection veszély
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

### 4. Rollback Script Generálás

Minden migrációhoz generálj visszavonási (rollback) szkriptet:

```sql
-- Migration: add_email_verified_column
-- Rollback: remove_email_verified_column
ALTER TABLE users DROP COLUMN IF EXISTS email_verified;
```

## Migrációs Workflow

```
1. Backup ellenőrzés → Van-e aktuális mentés?
2. Rollback script → Visszavonás lehetséges?
3. Staging teszt → Fut-e staging-en?
4. Megerősítés → Felhasználó jóváhagyása
5. Végrehajtás → Tranzakcióban
6. Validáció → Ellenőrzés a módosítás után
```

## Veszélyes Minták (TILTOTT)

```sql
-- ❌ Soha ne futtasd ezeket automatikusan:
DROP DATABASE production;
TRUNCATE TABLE users;
DELETE FROM orders;  -- WHERE nélkül!
ALTER TABLE payments DROP COLUMN amount;
```

## Env Változók Használata

```python
# HELYES ✅
DATABASE_URL = os.environ['DATABASE_URL']

# HIBÁS ❌
DATABASE_URL = "postgresql://admin:password123@prod-db.example.com/mydb"
```
