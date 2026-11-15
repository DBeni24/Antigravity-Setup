---
name: fastapi-expert
description: >
  Professzionális FastAPI és modern Python backend fejlesztési minták.
  Aktiválódik FastAPI végpontok, Pydantic modellek, dependency injection tervezésekor,
  vagy ha a felhasználó "fastapi", "pydantic", "uvicorn", "async def", "python api" szavakat említ.
---

# FastAPI-Expert: Tiszta és Skálázható Python Backend Architektúra

## 1. Projekt Struktúra (Layered Clean Architecture)

```
src/
├── api/
│   ├── v1/
│   │   ├── endpoints/
│   │   │   ├── auth.py
│   │   │   └── users.py
│   │   └── api.py          # APIRouter összefűzés
│   └── deps.py             # Dependency Injection gyűjtőhely
├── core/
│   ├── config.py           # Pydantic-Settings BaseSettings
│   └── security.py         # JWT, password hashing
├── models/                 # SQLAlchemy / SQLModel ORM entitások
├── schemas/                # Pydantic v2 DTO-k (Input/Output validáció)
├── services/               # Üzleti logika (nem az endpointban!)
└── main.py                 # FastAPI alkalmazás példányosítás
```

---

## 2. Pydantic v2 Sémák (DTO) és Strict Validáció

Mindig válassz külön a bejövő (Create/Update) és a kimenő (Response) modelleket:

```python
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=100)

class UserCreate(UserBase):
    password: str = Field(min_length=8)

class UserResponse(UserBase):
    id: int
    created_at: datetime
    is_active: bool

    # Pydantic v2: ORM attribútumok automatikus konvertálása
    model_config = ConfigDict(from_attributes=True)
```

---

## 3. Dependency Injection (DI) Minták

Használj `Annotated` és `Depends` struktúrát az adatbázis kapcsolatokhoz és hitelesítéshez:

```python
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.api.deps import get_db, get_current_user
from src.schemas.user import UserResponse
from src.models.user import User

router = APIRouter(prefix="/users", tags=["users"])

# Típusos Session Dependency
SessionDep = Annotated[AsyncSession, Depends(get_db)]
CurrentUserDep = Annotated[User, Depends(get_current_user)]

@router.get("/me", response_model=UserResponse)
async def read_current_user(current_user: CurrentUserDep):
    """Visszaadja a bejelentkezett felhasználó profilját."""
    return current_user
```

---

## 4. Aszinkron Adatbázis-műveletek (Async SQLAlchemy)

Soha ne használj blokkoló I/O hívásokat `async def` endpointokban:

```python
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.user import User

async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()
```

---

## 5. Globális Hibakezelés és Lifecycle (Lifespan)

Használj modern `lifespan` context managert az elavult `@app.on_event` helyett:

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from src.core.db import engine

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: kapcsolatok inicializálása
    yield
    # Shutdown: engine lezárása
    await engine.dispose()

app = FastAPI(title="MyApp API", lifespan=lifespan)
```
