---
name: redis-patterns
description: >
  Redis gyorsítótárazási stratégiák, rate limiting és elosztott rendszerminták.
  Aktiválódik in-memory cache tervezésekor, rate limiter írásakor, zárolásoknál,
  vagy ha a felhasználó "redis", "cache", "rate limit", "redlock", "pubsub" szavakat említ.
---

# Redis-Patterns: Gyorsítótárazás és Elosztott Primitívek

## 1. Cache Stratégiák

### Cache-Aside (Lazy Loading) - A leggyakoribb minta
A lekérdezés először a Redisből próbál olvasni. Ha nincs találat (Cache Miss), az adatbázisból tölti be és eltárolja a Redisben lejárati idővel (TTL).

```typescript
async function getUserProfile(userId: string): Promise<UserProfile> {
  const cacheKey = `user:profile:${userId}`
  
  // 1. Olvasás a gyorsítótárból
  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  // 2. Cache miss -> Adatbázis lekérdezés
  const user = await db.user.findUnique({ where: { id: userId } })
  if (!user) throw new NotFoundError()

  // 3. Mentés Redisbe 15 perces lejárattal (900 mp)
  await redis.set(cacheKey, JSON.stringify(user), 'EX', 900)
  
  return user
}
```

> [!CAUTION]
> **Cache Invalidation Szabály**: Amikor az entitás módosul az adatbázisban, AZONNAL töröld a hozzá tartozó Redis kulcsot (`redis.del(cacheKey)`), megelőzve az inkonzisztenciát!

---

## 2. Sebességkorlátozás (Rate Limiting - Sliding Window)

Védd meg az API végpontokat a túlterheléstől és a brute force támadásoktól Sorted Set (`ZSET`) használatával:

```typescript
// Engedélyez: maxRequests darab kérés windowSeconds másodperc alatt
async function isRateLimited(identifier: string, maxRequests = 60, windowSeconds = 60): Promise<boolean> {
  const key = `ratelimit:${identifier}`
  const now = Date.now()
  const windowStart = now - windowSeconds * 1000

  const pipeline = redis.pipeline()
  // Régi, időablakon kívüli bejegyzések törlése
  pipeline.zremrangebyscore(key, 0, windowStart)
  // Jelenlegi kérés hozzáadása
  pipeline.zadd(key, now, `${now}-${Math.random()}`)
  // Időablakban lévő kérések számlálása
  pipeline.zcard(key)
  // Kulcs lejárati idejének beállítása
  pipeline.expire(key, windowSeconds)

  const results = await pipeline.exec()
  const requestCount = results[2][1] as number

  return requestCount > maxRequests
}
```

---

## 3. Elosztott Zárolás (Distributed Lock - Redlock)

Megakadályozza a race condition-t (versenyhelyzetet), amikor több párhuzamos worker próbálja ugyanazt az erőforrást (pl. fizetés levonás, kupon beváltás) módosítani:

```typescript
async function acquireLock(lockKey: string, ttlMs = 5000): Promise<string | null> {
  const token = crypto.randomUUID()
  // Csak akkor állítja be, ha még NEM létezik (NX), és lejárati idővel (PX)
  const acquired = await redis.set(`lock:${lockKey}`, token, 'PX', ttlMs, 'NX')
  return acquired === 'OK' ? token : null
}

async function releaseLock(lockKey: string, token: string): Promise<boolean> {
  // Lua script: garantálja, hogy csak a saját zárunkat töröljük atomi módon
  const luaScript = `
    if redis.call("get", KEYS[1]) == ARGV[1] then
      return redis.call("del", KEYS[1])
    else
      return 0
    end
  `
  const result = await redis.eval(luaScript, 1, `lock:${lockKey}`, token)
  return result === 1
}
```

---

## 4. Pub/Sub és Eseményküldés

Könnyűsúlyú üzenetküldés szerverek és websocket node-ok között:
```typescript
// Értesítés közzététele
await redis.publish('notifications:user_123', JSON.stringify({ type: 'ORDER_SHIPPED' }))

// Feliratkozás (dedikált kapcsolaton)
const subscriber = redis.duplicate()
await subscriber.subscribe('notifications:user_123')
subscriber.on('message', (channel, message) => {
  // Websocket push a kliensnek
})
```
