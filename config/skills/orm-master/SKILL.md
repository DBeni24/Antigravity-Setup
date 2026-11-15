---
name: orm-master
description: >
  Modern ORM és adatmodellezési minták: Prisma, Drizzle ORM és SQLAlchemy.
  Aktiválódik adatbázis sémák tervezésekor, ORM lekérdezések írásakor, relációk kezelésekor,
  vagy ha a felhasználó "prisma", "drizzle", "sqlalchemy", "alembic", "orm", "n+1" szavakat említ.
---

# ORM-Master: Típusbiztos Adatmodellezés és Lekérdezés-optimalizálás

## 1. Drizzle ORM (TypeScript - "If you know SQL, you know Drizzle")

A Drizzle a leggyorsabb és legkisebb overhead-ű modern TypeScript ORM.

### Séma definíció:
```typescript
// src/db/schema.ts
import { pgTable, serial, text, timestamp, integer } from 'drizzle-orm/pg-core'
import { relations } from 'drizzle-orm'

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
})

export const posts = pgTable('posts', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  content: text('content'),
  authorId: integer('author_id').references(() => users.id, { onDelete: 'cascade' }),
})

export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}))
```

### Relációs Lekérdezés (Relational Query API):
```typescript
// N+1 probléma nélkül betölti a felhasználót és a posztjait
const userWithPosts = await db.query.users.findFirst({
  where: (users, { eq }) => eq(users.id, 1),
  with: {
    posts: {
      columns: { id: true, title: true },
      limit: 10,
    },
  },
})
```

---

## 2. Prisma ORM (TypeScript - "Productivity First")

A Prisma séma-vezérelt (DSL) megközelítést alkalmaz:

```prisma
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now())

  @@index([email])
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  authorId  Int
  author    User     @relation(fields: [authorId], references: [id], onDelete: Cascade)
}
```

### Migrációk kezelése:
- Fejlesztés közben: `npx prisma migrate dev --name <migration_name>`
- Production környezetben: `npx prisma migrate deploy`
- Típusok újragenerálása: `npx prisma generate`

---

## 3. Az N+1 Lekérdezési Probléma Megelőzése

> [!WARNING]
> Soha ne hajts végre adatbázis lekérdezést ciklus (pl. `forEach`, `map`, `for`) belsejében!

### ❌ Hibás (N+1 lekérdezés fut le):
```typescript
const users = await db.select().from(users)
for (const u of users) {
  // Minden egyes felhasználónál külön SQL kérés fut!
  const posts = await db.select().from(posts).where(eq(posts.authorId, u.id))
}
```

### ✅ Helyes (Egyetlen JOIN vagy kötegelt `IN` lekérdezés):
```typescript
// 1. Drizzle Relational API vagy Prisma include
const data = await prisma.user.findMany({
  include: { posts: true }
})
```

---

## 4. Tranzakciók Használata

Összetartozó műveleteknél garantáld az atomitást (`db-safety` skill):

```typescript
// Prisma tranzakció
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email: 'a@b.com', name: 'A' } })
  await tx.post.create({ data: { title: 'First Post', authorId: user.id } })
})
```
