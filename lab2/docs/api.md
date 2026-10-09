```markdown
# API Endpoints — Lab 2 (Yasevich)

Базовый URL (локальный Node-RED):

```
http://localhost:1880
```

---

## 1. GET /api/text

Возвращает простой текст.

### Параметры
Нет.

### Запрос
```
GET /api/text
```

### Успешный ответ (200 OK)
```
Hello from Yasevich — lab2 endpoint /api/text
```

Content-Type: `text/plain; charset=utf-8`

![GET /api/text](08_1-endpoints.png)

### Пример в браузере
```
http://localhost:1880/api/text
```

---

## 2. GET /api/info

Возвращает JSON с двумя полями.

### Параметры
Нет.

### Запрос
```
GET /api/info
```

### Успешный ответ (200 OK)
```json
{
  "student": "Yasevich",
  "lab": 2
}
```

Content-Type: `application/json`

![GET /api/info](08_2-endpoints.png)

### Пример в браузере
```
http://localhost:1880/api/info
```

---

## 3. GET /api/items/:id

Возвращает товар по идентификатору.  
Использует **path-параметр** `:id`.

### Параметры

| Параметр | Расположение | Тип    | Обязательный | Описание                    |
|----------|--------------|--------|--------------|-----------------------------|
| `id`     | path         | number | да           | Идентификатор товара (1–5)  |

### Успешный запрос (200 OK)

```
GET /api/items/2
```

**Ответ:**
```json
{
  "id": 2,
  "name": "Тетрадь",
  "price": 45
}
```

![GET /api/items](08_3-endpoints.png)

### Ошибка 400 — некорректный параметр

```
GET /api/items/abc
```

или

```
GET /api/items/
```

**Ответ:**
```json
{
  "error": "Bad Request",
  "message": "Параметр id обязателен и должен быть числом"
}
```

HTTP Status: **400 Bad Request**

![GET /api/items](08_4-endpoints.png)

### Ошибка 404 — товар не найден

```
GET /api/items/99
```

**Ответ:**
```json
{
  "error": "Not Found",
  "message": "Товар с id=99 не найден"
}
```

HTTP Status: **404 Not Found**

![GET /api/items](08_5-endpoints.png)

### Доступные товары (для успешных запросов)

| id | name         | price |
|----|--------------|-------|
| 1  | Карандаш     | 15    |
| 2  | Тетрадь      | 45    |
| 3  | Рюкзак       | 1200  |
| 4  | Линейка      | 30    |
| 5  | Калькулятор   | 350   |

---

## Примеры для проверки в браузере

| Тип        | URL                                | Ожидаемый результат     |
|------------|------------------------------------|-------------------------|
| Успех      | http://localhost:1880/api/text     | Текст                   |
| Успех      | http://localhost:1880/api/info     | JSON                    |
| Успех      | http://localhost:1880/api/items/3  | 200 + товар             |
| Ошибка 400 | http://localhost:1880/api/items/hello | 400 Bad Request      |
| Ошибка 404 | http://localhost:1880/api/items/99 | 404 Not Found           |
```