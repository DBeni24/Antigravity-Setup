---
name: react-modern-patterns
description: >
  Modern React 19 és Next.js App Router fejlesztési minták és architektúra.
  Aktiválódik React komponensek írásakor, Next.js projektekben, frontend állapotkezeléskor,
  vagy ha a felhasználó "react", "nextjs", "rsc", "server action", "zustand", "tanstack" szavakat említ.
---

# React Modern Patterns: React 19 & Next.js App Router Architektúra

## 1. Alapvető Architektúra: Server vs. Client Komponensek

> [!IMPORTANT]
> Az App Routerben minden komponens alapértelmezetten **React Server Component (RSC)**.
> Csak akkor használj `'use client'` direktívát, ha valóban szükséges!

### Mikor kell `'use client'`?
- Interaktív eseménykezelők: `onClick`, `onChange`, `onSubmit`
- React Hook-ok: `useState`, `useEffect`, `useReducer`, `useRef`
- Böngésző API-k: `localStorage`, `window`, `document`, WebSockets
- Külső, csak kliensen futó UI könyvtárak

### Mikor maradhat Server Component (RSC)?
- Közvetlen adatbázis / ORM elérés (Prisma, Drizzle, SQL)
- Szenzitív kulcsok (API kulcsok, secret-ek) használata
- Nagy függőségek betöltése (a böngésző nem tölti le a bundle méretet!)
- Statikus tartalom vagy SEO-kritikus HTML renderelés

---

## 2. Server Actions és Form Kezelés (React 19)

Mindig használj Server Action-öket adatmutációhoz a hagyományos `fetch('/api/...')` helyett:

```typescript
// app/actions/user.ts
'use server'

import { revalidatePath } from 'next/cache'
import { db } from '@/lib/db'
import { userSchema } from '@/lib/validations'

export async function updateUserProfile(prevState: any, formData: FormData) {
  const rawData = Object.fromEntries(formData.entries())
  const validated = userSchema.safeParse(rawData)

  if (!validated.success) {
    return { error: validated.error.flatten().fieldErrors }
  }

  await db.user.update({
    where: { id: validated.data.id },
    data: validated.data,
  })

  revalidatePath('/profile')
  return { success: true }
}
```

### Kliens oldali bekötés (`useActionState`):
```tsx
'use client'

import { useActionState } from 'react'
import { updateUserProfile } from '@/app/actions/user'

export function ProfileForm() {
  const [state, formAction, isPending] = useActionState(updateUserProfile, null)

  return (
    <form action={formAction} className="space-y-4">
      <input name="name" placeholder="Név" required />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Mentés folyamatban...' : 'Mentés'}
      </button>
      {state?.error && <p className="text-red-500">{JSON.stringify(state.error)}</p>}
    </form>
  )
}
```

---

## 3. Kliens Oldali Állapotkezelés (Zustand & TanStack Query)

- **Globális UI Állapot (pl. Sidebar nyitva/zárva, Modal-ok, Téma)**: Használj **Zustand** store-t (`create()`), kerüld a túlbonyolított Redux-ot.
- **Szerver Cache / Polling / Aszinkron Állapot**: Használj **TanStack Query**-t (`useQuery`, `useMutation`) kliens-oldali REST/GraphQL hívásokhoz.

---

## 4. Teljesítmény és Suspense Határok

- Mindig csomagold be az aszinkron adatlekérő komponenseket `<Suspense fallback={<Skeleton />}>` blokkba:
```tsx
import { Suspense } from 'react'
import { UserStats } from './UserStats'
import { StatsSkeleton } from './StatsSkeleton'

export default function DashboardPage() {
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold">Irányítópult</h1>
      <Suspense fallback={<StatsSkeleton />}>
        <UserStats />
      </Suspense>
    </div>
  )
}
```
