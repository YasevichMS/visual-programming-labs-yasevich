# Лабораторная работа №8. Xano

## 1. Цель работы

Освоить Xano как no-code/low-code платформу для создания бэкенда: базы данных, API-эндпоинтов и документации Swagger. Научиться генерировать модель данных с помощью ИИ, реализовывать её в Xano, проверять через Swagger.

## 2. Предметная область

**Аренда спортивного инвентаря в кампусе**

Сервис, позволяющий студентам и сотрудникам университета бронировать спортивный инвентарь (лыжи, ракетки, мячи, коврики, велосипеды и т.д.) на определённый срок. Система учитывает категории инвентаря, состояние предметов, пользователей и историю бронирований.

## 3. Промпт для ИИ

```
Придумай уникальную предметную область для учебного бэкенда на Xano. Нужно 3–4 связанные таблицы, минимум 2 связи reference, поля типов text, integer, decimal, boolean, timestamp, enum/select, reference. Опиши модель данных и предложи минимум 4 REST-эндпоинта: список, получение по id, создание, обновление или удаление. Укажи, где нужны path- и query-параметры.
```

## 4. Сгенерированная схема

### Таблицы

#### 1. `categories` — Категории инвентаря

| Поле         | Тип        | Описание                    |
|--------------|------------|-----------------------------|
| id           | integer    | Primary key                 |
| name         | text       | Название категории          |
| description  | text       | Описание                    |
| is_active    | boolean    | Активна ли категория        |
| created_at   | timestamp  | Дата создания               |

#### 2. `users` — Пользователи

| Поле         | Тип        | Описание                    |
|--------------|------------|-----------------------------|
| id           | integer    | Primary key                 |
| full_name    | text       | ФИО                         |
| student_id   | text       | Номер студенческого         |
| email        | text       | Email                       |
| phone        | text       | Телефон                     |
| role         | enum       | student / staff / admin     |
| is_active    | boolean    | Активен ли аккаунт          |
| created_at   | timestamp  | Дата регистрации            |

#### 3. `equipment` — Единицы инвентаря

| Поле             | Тип        | Описание                          |
|------------------|------------|-----------------------------------|
| id               | integer    | Primary key                       |
| name             | text       | Название предмета                 |
| category_id      | reference  | → categories.id                   |
| inventory_number | text       | Инвентарный номер                 |
| condition        | enum       | new / good / worn / broken        |
| daily_price      | decimal    | Цена аренды за день               |
| is_available     | boolean    | Доступен ли сейчас                |
| created_at       | timestamp  | Дата добавления                   |

#### 4. `rentals` — Бронирования

| Поле          | Тип        | Описание                              |
|---------------|------------|---------------------------------------|
| id            | integer    | Primary key                           |
| user_id       | reference  | → users.id                            |
| equipment_id  | reference  | → equipment.id                        |
| start_date    | timestamp  | Начало аренды                         |
| end_date      | timestamp  | Конец аренды                          |
| total_price   | decimal    | Итоговая стоимость                    |
| status        | enum       | pending / active / completed / cancelled |
| notes         | text       | Комментарий                           |
| created_at    | timestamp  | Дата создания брони                   |

### Связи (reference)

- `equipment.category_id` → `categories.id`
- `rentals.user_id` → `users.id`
- `rentals.equipment_id` → `equipment.id`

### Эндпоинты

| Метод  | Путь                        | Параметры                                      | Описание                          |
|--------|-----------------------------|------------------------------------------------|-----------------------------------|
| GET    | /equipment                  | page, per_page                                 | Список инвентаря c пагинацией     |
| GET    | /equipment/{equipment_id}   | path: equipment_id                             | Получение по id                   |
| POST   | /equipment                  | body                                           | Создание записи                   |
| PATCH  | /equipment/{equipment_id}   | path: equipment_id + body                      | Обновление записи                 |
| DELETE | /equipment/{equipment_id}   | path: equipment_id                             | Удаление записи                   |

## 5. Что было исправлено после генерации

- Добавлена таблица `users` для более полной модели.
- В таблицу `equipment` добавлены поля `inventory_number` и `condition` (enum).
- В таблицу `rentals` добавлены статусы и поле `total_price`.
- Уточнены query-параметры для фильтрации списка оборудования.
- Добавлен DELETE-эндпоинт для полноты CRUD.

## 6. Реализация в Xano

### Workspace

Название: `lab8-Yasevich`

### Таблицы и данные

Созданы 4 таблицы со всеми необходимыми типами полей и связями.  
Каждая таблица наполнена минимум 10 реалистичными записями.

### Эндпоинты

Реализован полный CRUD для таблицы `equipment`:

- `GET /equipment` — список с падингом
- `GET /equipment/{equipment_id}` — получение по id (path-параметр)
- `POST /equipment` — создание
- `PATCH /equipment/{equipment_id}` — обновление
- `DELETE /equipment/{equipment_id}` — удаление

### Swagger

Все эндпоинты отображаются в Swagger-документации.  
Ссылка на Swagger: *(https://x8ki-letl-twmt.n7.xano.io/api:cOpF7qlg)*

## 7. Использованные компоненты Xano

- Database (таблицы)
- Типы полей: text, integer, decimal, boolean, timestamp, enum, reference
- Связи (Reference)
- API Endpoints (GET, POST, PATCH, DELETE)
- Path-параметры и Query-параметры
- Function Stack (Query All Records, Get Record, Add Record, Edit Record, Delete Record)
- Swagger / API Documentation

## 8. Скриншоты

- `01-dashboard.png` — главный экран workspace (с видимой фамилией)
- `02-entity-model.png` — схема таблиц / модель данных
- `03-categories.png` — таблица categories с данными
- `03-equipment.png` — таблица equipment с данными
- `03-rentals.png` — таблица rentals с данными
- `03-users.png` — таблица users с данными
- `04-APIs.png` — список API-эндпоинтов

## 9. Ограничения бесплатного тарифа

- Недоступны Middleware и Triggers
- Ограничение на количество писем (100)
- Ограничения по размеру workspace

## 10. Выводы

В ходе работы была освоена платформа Xano: создание базы данных со связями, настройка различных типов полей, разработка REST API с path- и query-параметрами, а также работа с автоматической документацией Swagger. Генерация модели данных с помощью ИИ значительно ускорила проектирование, после чего схема была доработана под требования лабораторной работы. Бесплатный тариф позволяет выполнить все базовые задачи, однако имеет ограничения по некоторым продвинутым функциям.
