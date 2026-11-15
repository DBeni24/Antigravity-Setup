---
name: async-queue-worker
description: >
  Aszinkron háttérfeladat-kezelés és üzenetsor architektúra (BullMQ, Celery, Redis).
  Aktiválódik háttérben futó feladatok, email küldés, PDF generálás, webhookok tervezésekor,
  vagy ha a felhasználó "queue", "worker", "bullmq", "celery", "háttérfeladat", "retry" szavakat említ.
---

# Async-Queue-Worker: Skálázható Háttérfeladat és Üzenetsor Architektúra

## 1. Miért szükséges a feladatsor (Queue)?

> [!IMPORTANT]
> A HTTP kérés-válasz ciklusban semmi olyat ne végezz szinkronban, ami 200 ms-nál tovább tart!
> (Email küldés, PDF generálás, külső API szinkronizáció, képméretezés, adatelemzés).
> Ezeket mindig küldd át egy aszinkron feladatsorba (Queue).

---

## 2. BullMQ Minta (Node.js & TypeScript - Redis Alapú)

### Producer (Feladat behelyezése a sorba):
```typescript
// src/queues/emailQueue.ts
import { Queue } from 'bullmq'
import { redisConnection } from '@/lib/redis'

export const emailQueue = new Queue('email-delivery', {
  connection: redisConnection,
  defaultJobOptions: {
    attempts: 5, // 5 próbálkozás hiba esetén
    backoff: {
      type: 'exponential', // Exponenciális várakozás: 2s, 4s, 8s, 16s...
      delay: 2000,
    },
    removeOnComplete: { count: 1000 }, // Legutóbbi 1000 sikeres naplózása
    removeOnFail: false, // Bukott feladatok megtartása vizsgálathoz (DLQ)
  },
})

// Hozzáadás az API végpontban:
await emailQueue.add('send-welcome-email', {
  to: 'user@example.com',
  name: 'Kovács János',
})
```

### Consumer / Worker (Feladat feldolgozása a háttérben):
```typescript
// src/workers/emailWorker.ts
import { Worker, Job } from 'bullmq'
import { redisConnection } from '@/lib/redis'
import { sendEmailService } from '@/services/email'

export const emailWorker = new Worker(
  'email-delivery',
  async (job: Job) => {
    console.log(`[Job ${job.id}] Feldolgozás alatt: ${job.name}`)
    await sendEmailService(job.data.to, job.data.name)
  },
  {
    connection: redisConnection,
    concurrency: 10, // Egyszerre legfeljebb 10 feladat párhuzamosan
  }
)

emailWorker.on('failed', (job, err) => {
  console.error(`[Job ${job?.id}] VÉGLEG ELBUKOTT: ${err.message}`)
  // Itt lehet értesítést küldeni Sentry-be vagy Slackre
})
```

---

## 3. Celery Minta (Python & FastAPI)

### Celery App és Feladat definiálása:
```python
# src/tasks/celery_app.py
from celery import Celery

celery_app = Celery(
    "tasks",
    broker="redis://localhost:6379/0",
    backend="redis://localhost:6379/1"
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Europe/Budapest",
    enable_utc=True,
    task_acks_late=True, # Csak sikeres befejezés után nyugtázza (at-least-once)
)
```

```python
# src/tasks/report_tasks.py
import time
from src.tasks.celery_app import celery_app

@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def generate_monthly_pdf(self, user_id: int):
    try:
        # Erőforrás-igényes PDF generálás
        time.sleep(5)
        return {"status": "SUCCESS", "url": f"https://cdn.example.com/reports/{user_id}.pdf"}
    except Exception as exc:
        # Automatikus újrapróbálás exponenciális visszalépéssel
        raise self.retry(exc=exc, countdown=2 ** self.request.retries * 30)
```

---

## 4. Dead-Letter Queue (DLQ) és Hibaelhárítás

- Ha egy feladat kimerítette az összes újrapróbálkozási lehetőséget (max_retries), automatikusan a **Dead-Letter Queue-ba (DLQ)** vagy bukott állapotba kerül.
- Soha ne töröld azonnal a bukott feladatokat: a bemeneti payloadnak és a hiba stack trace-nek meg kell maradnia a kézi vizsgálathoz és javítás utáni újrafuttatáshoz (`job.retry()`).
