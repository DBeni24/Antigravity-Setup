---
name: db-postgres-expert
description: >
  PostgreSQL mély adatbázis- és lekérdezés-optimalizálási szakértő.
  Aktiválódik PostgreSQL sémák tervezésekor, lassú lekérdezések gyorsításakor, indexelésnél,
  vagy ha a felhasználó "postgres", "postgresql", "explain analyze", "gin index", "jsonb" szavakat említ.
---

# DB-Postgres-Expert: Haladó PostgreSQL Tervezés és Lekérdezés-optimalizálás

## 1. Lekérdezési Terv Elemzés (`EXPLAIN (ANALYZE, BUFFERS)`)

> [!IMPORTANT]
> Lassú SQL lekérdezés esetén soha ne találgass! Mindig futtass `EXPLAIN (ANALYZE, BUFFERS)`-t:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.id, u.email, count(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at >= '2026-01-01'
GROUP BY u.id, u.email;
```

### Mire figyelj a kimenetben?
- **Seq Scan (Szekvenciális pásztázás)**: Ha nagy táblán fut és szűrő (`Filter:`) van rajta, hiányzik a megfelelő index.
- **Index Scan vs. Index Only Scan**: Az *Index Only Scan* a leggyorsabb, mert nem nyúl hozzá a tábla adataihoz (Heap), csak az indexből olvas.
- **Buffers: shared hit vs. read**: A `read` lemezről olvas (lassú), a `hit` a memóriából (RAM/shared buffers - gyors).
- **External Merge Disk (Sort)**: Ha a memóriakeret (`work_mem`) kevés, a PostgreSQL lemezre írja a rendezést. Megoldás: célzott index a `ORDER BY` mezőkre, vagy `work_mem` növelése.

---

## 2. Indexelési Stratégiák

### B-Tree Index (Alapértelmezett, Általános)
- Kiváló egyenlőségre (`=`) és tartományokra (`<`, `<=`, `>`, `>=`, `BETWEEN`).
- **Összetett (Composite) Index szabály (Balról Jobbra Elv)**:
  `CREATE INDEX idx_orders_user_status ON orders (user_id, status);`
  Ez az index gyorsítja a `WHERE user_id = ? AND status = ?` és a `WHERE user_id = ?` lekérdezést, de **NEM** gyorsítja az önálló `WHERE status = ?` lekérdezést!

### Részleges (Partial) Index
Ha a táblának csak egy kis szeletét szűröd rendszeresen (pl. csak az aktív / függőben lévő sorokat):
```sql
-- Csak a nem feldolgozott rendeléseket indexeli, így az index töredék méretű és szupergyors marad:
CREATE INDEX idx_orders_pending ON orders (created_at)
WHERE status = 'pending';
```

### GIN Index (JSONB és Teljes Szöveges Keresés)
JSONB dokumentumok mély kereséséhez:
```sql
CREATE INDEX idx_users_metadata_gin ON users USING GIN (metadata jsonb_path_ops);

-- Ez a lekérdezés azonnal az indexet fogja használni:
SELECT * FROM users WHERE metadata @> '{"role": "admin", "department": "it"}';
```

---

## 3. JSONB Kezelési Minták

- Használj indexelhető `@>` (containment) és `?` (key exists) operátorokat a lassú `->>` string konverziók helyett:
```sql
-- ❌ Lassú (nem használ GIN indexet közvetlenül):
SELECT * FROM events WHERE payload->>'event_type' = 'login';

-- ✅ Gyors (kihasználja a jsonb_path_ops GIN indexet):
SELECT * FROM events WHERE payload @> '{"event_type": "login"}';
```

---

## 4. Táblaparticionálás (Nagy Adatmennyiségnél > 10M sor)

Idősoros (Timeseries) adatoknál mindig alkalmazz tartomány-alapú particionálást:

```sql
CREATE TABLE audit_logs (
    id bigserial,
    event_time timestamptz NOT NULL,
    action text NOT NULL
) PARTITION BY RANGE (event_time);

-- Havi particiók létrehozása:
CREATE TABLE audit_logs_2026_11 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');
```

---

## 5. Kapcsolatkezelés és Connection Pooling

- Alkalmazás oldalon mindig használj Connection Pool-t (pl. `asyncpg` pool Pythonban, `pg-pool` Node.js-ben).
- Éles környezetben ajánlott a **PgBouncer** (Transaction pooling módban) a tízezres skálázódáshoz.
