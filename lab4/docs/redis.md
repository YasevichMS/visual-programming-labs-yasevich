```markdown
# Redis в лабораторной работе №4 (Yasevich)

## Установка Redis

```bash
docker run -d --name redis -p 6379:6379 redis:7
```

Проверка:

```bash
docker ps | grep redis
docker exec -it redis redis-cli ping
# ожидается PONG
```

## Credentials в n8n

1. Settings → Credentials → Add Credential → Redis
2. Параметры:
   - **Host:** `host.docker.internal` (если n8n запущен в Docker)
   - **Port:** `6379`
   - **Password:** (пусто)
   - **Database:** `0`
3. Имя credentials: `Redis Yasevich`

## Workflow 1 — создание и чтение ключа (`flow-09-redis.json`)

```
Manual Trigger → Redis (Set) → Redis (Get)
```

1. **Redis Set**
   - Operation: `Set`
   - Key: `yasevich`
   - Value: `lab4/Yasevich/redis_1`

2. **Redis Get**
   - Operation: `Get`
   - Key: `yasevich`

После выполнения в выводе Get появляется значение `lab4/Yasevich/redis_1`.

## Workflow 2 — удаление и проверка (`flow-10-redis.json`)

```
Manual Trigger → Redis (Delete) → Redis (Exists)
```

1. **Redis Delete**
   - Operation: `Delete`
   - Key: `yasevich`

2. **Redis Exists**
   - Operation: `Exists`
   - Key: `yasevich`

Результат Exists: `This is an item, but it's empty.`.

## Что происходит

1. **Set** — создаёт в Redis пару `yasevich → "lab4/Yasevich/redis_1"`.
2. **Get** — читает значение по ключу `yasevich`.
3. **Delete** — удаляет ключ `yasevich`.
4. **Exists** — проверяет, что ключа больше нет.

## Скриншоты

- `08-redis.png` — создание ключа и чтение значения
- `09-redis.png` — удаление и проверка отсутствия

## Важные замечания

- Ключ — фамилия в латинице: `yasevich`
- При запуске n8n в Docker используется `host.docker.internal`
- Если n8n запущен на хосте — Host: `localhost`
- Все операции выполняются через официальную Redis-ноду n8n
```