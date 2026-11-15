---
name: schema-validation-zod
description: >
  Szigorú sémavalidáció és típuslevezetés Zod és Valibot könyvtárakkal.
  Aktiválódik felhasználói input validálásakor, formok ellenőrzésekor, környezeti változók szűrésekor,
  vagy ha a felhasználó "zod", "valibot", "validation", "schema", "safeParse" szavakat említ.
---

# Schema-Validation-Zod: Típusbiztos Bemenet- és Sémavalidáció

## 1. Miért Zod?
A Zod deklaratív sémákat definiál, amelyekből **egyetlen forrásból** származtatható a:
1. Futásidejű validáció (`safeParse`)
2. Statikus TypeScript típus (`z.infer<typeof Schema>`)
3. Részletes, lokalizálható hibaüzenet struktúra

---

## 2. Standard Séma Minták

```typescript
import { z } from 'zod'

export const registerSchema = z.object({
  email: z.string().email('Érvénytelen email cím formátum'),
  username: z
    .string()
    .min(3, 'A felhasználónév legalább 3 karakter legyen')
    .max(30, 'Legfeljebb 30 karakter')
    .regex(/^[a-zA-Z0-9_-]+$/, 'Csak betűket, számokat és kötőjelet tartalmazhat'),
  password: z
    .string()
    .min(8, 'A jelszó legalább 8 karakter legyen')
    .regex(/[A-Z]/, 'Legalább egy nagybetűt kell tartalmaznia')
    .regex(/[0-9]/, 'Legalább egy számot kell tartalmaznia'),
  confirmPassword: z.string(),
  role: z.enum(['admin', 'user', 'guest']).default('user'),
  age: z.coerce.number().min(18, 'Csak 18 éven felüliek regisztrálhatnak').optional(),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'A jelszavak nem egyeznek',
  path: ['confirmPassword'],
})

// Automatikus TypeScript típuslevezetés:
export type RegisterInput = z.infer<typeof registerSchema>
```

---

## 3. Hibakezelés: `safeParse` használata `parse` helyett

> [!TIP]
> Ne engedd, hogy a validáció kezeletlen kivételt (Exception) dobjon!
> Használd a `safeParse`-t a tiszta hibakezeléshez:

```typescript
export function handleApiRequest(body: unknown) {
  const result = registerSchema.safeParse(body)

  if (!result.success) {
    // result.error.flatten() kényelmes mezőnkénti hibatérképet ad:
    // pl. { fieldErrors: { email: ["Érvénytelen email cím"] } }
    return {
      status: 400,
      errors: result.error.flatten().fieldErrors,
    }
  }

  // result.data garantáltan megfelel a RegisterInput típusnak!
  return { status: 200, data: result.data }
}
```

---

## 4. Környezeti Változók Típusos Validálása (`env.ts`)

Védd meg az alkalmazást az induláskor hiányzó környezeti változóktól:

```typescript
// src/env.ts
import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().url('A DATABASE_URL érvényes kapcsolat-URL kell legyen'),
  PORT: z.coerce.number().default(3000),
  JWT_SECRET: z.string().min(32, 'A JWT secret legalább 32 karakteres legyen'),
})

export const env = envSchema.parse(process.env)
```

---

## 5. React Hook Form Integráció (`@hookform/resolvers/zod`)

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { registerSchema, type RegisterInput } from './schema'

export function RegisterForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<RegisterInput>({
    resolver: zodResolver(registerSchema),
  })

  const onSubmit = async (data: RegisterInput) => {
    // Garantáltan validált adatok
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <p className="text-red-500">{errors.email.message}</p>}
      <button type="submit" disabled={isSubmitting}>Küldés</button>
    </form>
  )
}
```
