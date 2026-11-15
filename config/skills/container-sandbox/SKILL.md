---
name: container-sandbox
description: >
  Izolált kódvégrehajtás és tesztelés Docker vagy WSL2 környezetben.
  Aktiválódik rendszerfüggő fordításoknál, Linux-specifikus eszközöknél, adatbázis konténereknél,
  vagy ha a felhasználó "docker", "konténer", "wsl", "sandbox", "izolált környezet" szavakat említ.
---

# Container-Sandbox: Izolált és Reprodukálható Végrehajtás

## Célkitűzés
Védi a Windows host operációs rendszert a nem kívánt mellékhatásoktól, biztosítja a determinisztikus
Linux-alapú build és runtime környezetet, és egyszerűvé teszi az infrastruktúra-függőségek (Postgres, Redis) kezelését.

---

## 1. Eldobható Tesztfuttatás Dockerben

Amikor egy szkript vagy tesztcsomag Linux környezetet vagy tiszta függőségi fát igényel:

### Node.js projekt esetén:
```bash
docker run --rm -v "${PWD}:/app" -w /app node:20-alpine npm test
```

### Python projekt esetén:
```bash
docker run --rm -v "${PWD}:/app" -w /app python:3.12-slim sh -c "pip install -r requirements.txt && pytest"
```

### Előnyök:
- Nem szennyezi a host fájlrendszert.
- Nem függ a helyi operációs rendszer dll-jeitől vagy binárisaitól.
- A konténer a futás után azonnal törlődik (`--rm`).

---

## 2. Fejlesztői Infrastruktúra (Docker Compose)

Ha a projekt adatbázist, cache-t vagy message queue-t igényel:
- Mindig ellenőrizd a `docker-compose.yml` meglétét.
- Indítás minimális lábnyommal: `docker compose up -d db redis`
- Állapot ellenőrzése: `docker compose ps`
- Leállítás munka befejeztével: `docker compose down`

---

## 3. WSL2 (Windows Subsystem for Linux) Fallback

Ha a Docker Desktop nem fut, a WSL2 azonnali natív Linux terminált nyújt:
```bash
wsl -d Ubuntu -- bash -c "cd $(wslpath '${PWD}') && ./build.sh"
```
