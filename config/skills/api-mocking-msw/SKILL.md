---
name: api-mocking-msw
description: >
  API mockolás és hálózati interceptálás Mock Service Worker (MSW v2) használatával.
  Aktiválódik tesztek mockolásakor, frontend offline fejlesztésekor,
  vagy ha a felhasználó "msw", "mocking", "mock api", "network stub", "service worker" szavakat említ.
---

# API-Mocking-MSW: Hálózati Mockolás Böngészőben és Tesztekben

## 1. Miért MSW (Mock Service Worker)?

A hagyományos függvény-mockolással ellentétben (pl. `vi.fn()` vagy `jest.mock()`) az MSW a **valódi hálózati rétegen** (Service Worker böngészőben, interceptor Node-ban) fogja el a kéréseket.
- Ugyanaz a mock handler működik a böngészős kézi tesztelésnél, a Vitest egységteszteknél és a Playwright E2E teszteknél.
- A kódod valódi `fetch()` vagy `axios` hívást hajt végre, így a hálózati kódod 100%-ban valósághű marad.

---

## 2. Handler Definíciók (`src/mocks/handlers.ts`)

```typescript
import { http, HttpResponse } from 'msw'

export const handlers = [
  // Sikeres felhasználó lista lekérdezés
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: 'Teszt Anna', email: 'anna@example.com' },
      { id: '2', name: 'Teszt Béla', email: 'bela@example.com' },
    ])
  }),

  // Bejelentkezés mockolása hibaággal
  http.post('/api/login', async ({ request }) => {
    const data = (await request.json()) as { email?: string; password?: string }

    if (data.email === 'hiba@example.com') {
      return new HttpResponse(null, { status: 401, statusText: 'Hibás jelszó' })
    }

    return HttpResponse.json({
      token: 'mock-jwt-token-xyz',
      user: { id: '1', name: 'Teszt Anna' },
    })
  }),
]
```

---

## 3. Node.js & Vitest Integráció (`src/mocks/node.ts`)

```typescript
// src/mocks/node.ts
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

### Teszt futtató beállítása (`tests/setup.ts`):
```typescript
import { beforeAll, afterEach, afterAll } from 'vitest'
import { server } from '@/mocks/node'

// Mock szerver indítása a tesztek előtt
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))

// Minden teszt után visszaállítja a felülbírált handlereket
afterEach(() => server.resetHandlers())

// Lezárás a tesztek végén
afterAll(() => server.close())
```

---

## 4. Egyedi Tesztesetek (Hibaágak Szimulálása)

Bármelyik egyedi tesztben felülbírálhatod a handlert egy adott szituáció (pl. 500-as szerverhiba vagy lassú kapcsolat) tesztelésére:

```typescript
import { it, expect } from 'vitest'
import { server } from '@/mocks/node'
import { http, HttpResponse, delay } from 'msw'
import { fetchUsers } from '@/lib/api'

it('kezeli a szerverhibát (500)', async () => {
  // Csak erre az egy tesztre érvényes felülbírálás:
  server.use(
    http.get('/api/users', () => {
      return new HttpResponse(null, { status: 500 })
    })
  )

  await expect(fetchUsers()).rejects.toThrow('Szerverhiba történt')
})

it('kezeli a hálózati késleltetést', async () => {
  server.use(
    http.get('/api/users', async () => {
      await delay(2000)
      return HttpResponse.json([])
    })
  )
  // Betöltési animáció (Skeleton) ellenőrzése
})
```
