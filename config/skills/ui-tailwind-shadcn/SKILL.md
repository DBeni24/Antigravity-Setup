---
name: ui-tailwind-shadcn
description: >
  Modern Tailwind CSS és shadcn/ui komponens tervezés és stílusozás.
  Aktiválódik UI elemek készítésekor, CSS stílusozáskor, shadcn komponensek hozzáadásakor,
  vagy ha a felhasználó "tailwind", "shadcn", "css", "radix", "dark mode", "ui komponens" szavakat említ.
---

# UI-Tailwind-Shadcn: Modern Felülettervezés és Komponens Architektúra

## 1. Alapelvek: "Copy-Paste" Komponens Architektúra (shadcn/ui)

A shadcn/ui nem egy zárt npm csomag, hanem forráskód-alapú tervezési rendszer.
A komponensek a projekt saját `components/ui/` mappájában élnek, így 100%-ban testreszabhatóak.

### Hasznos CLI Parancsok:
```bash
# Új shadcn komponens hozzáadása
npx shadcn@latest add button dialog dropdown-menu form table

# Projekt inicializálása
npx shadcn@latest init
```

---

## 2. Stílus Összefűzés és Variánsok (`cn` és `cva`)

Minden dinamikus Tailwind osztályt a `cn()` (`clsx` + `tailwind-merge`) segédfüggvénnyel kell összefűzni a konfliktusok elkerülésére:

```typescript
// lib/utils.ts
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

### Variánsok definiálása `cva`-val (Class Variance Authority):
```typescript
import { cva, type VariantProps } from 'class-variance-authority'

export const badgeVariants = cva(
  'inline-flex items-center rounded-md px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/80',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/80',
        outline: 'text-foreground border border-input hover:bg-accent',
      },
      size: {
        sm: 'text-[10px] px-1.5 py-0.2',
        default: 'text-xs px-2.5 py-0.5',
        lg: 'text-sm px-3 py-1',
      }
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)
```

---

## 3. Reszponzív Tervezés és Mobile-First Elv

- **Mobile First**: Alapértelmezett osztályok a legkisebb képernyőre vonatkoznak.
- **Breakpoints**:
  - `sm:` (640px)
  - `md:` (768px - tabletek)
  - `lg:` (1024px - asztali gépek)
  - `xl:` (1280px)

```tsx
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
  {/* Mobil: 1 oszlop, Tablet: 2 oszlop, Asztali: 4 oszlop */}
</div>
```

---

## 4. Dark Mode és CSS Változók

- Használj szemantikus tokeneket a közvetlen színnevek (`bg-white`, `text-black`) helyett:
  - `bg-background`, `text-foreground`
  - `bg-card`, `text-card-foreground`
  - `bg-muted`, `text-muted-foreground`
  - `border-border`, `ring-ring`

Ez garantálja, hogy a felület egyetlen kattintással hibátlanul átvált sötét és világos téma között.

---

## 5. Akadálymentesítés (a11y)
- Mindig biztosíts `aria-label` vagy `sr-only` feliratot az ikon-gomboknak:
```tsx
<button className="p-2" aria-label="Menü bezárása">
  <XIcon className="h-4 w-4" />
</button>
```
- Billentyűzet-navigáció (`focus-visible:ring-2`, `focus-visible:ring-ring focus-visible:outline-none`).
