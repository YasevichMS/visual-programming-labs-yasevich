# Лабораторная работа №4. n8n

**Студент:** Yasevich  
**Дата:** 18.10.2026

## Краткое описание выполненного

В рамках лабораторной работы была освоена low-code платформа n8n.  
Выполнена установка n8n и Redis через Docker.  
Созданы и протестированы workflow по всем пунктам задания:

- Manual Trigger → Set → Code
- Manual Trigger → Code → NoOp
- Manual Trigger → Code → IF → NoOp (true/false)
- Manual Trigger → Set → Code (с timestamp)
- Manual Trigger → HTTP Request → Code
- Schedule Trigger → Code
- Работа с Redis: создание/чтение и удаление/проверка ключа

Все workflow экспортированы в JSON-файлы и сохранены в репозитории.  
Сделаны скриншоты выполнения.

## AI-промпты, которые использовались

1. «Как собрать workflow Manual Trigger → Set → Code в n8n, где payload = фамилия, topic = lab4/фамилия/basic»
2. «Напиши JavaScript для Code-ноды n8n с let/const, if/else, циклом for, массивом и объектом»
3. «Как настроить HTTP Request в n8n для публичного API без токена»
4. «Как подключить Redis к n8n, если оба запущены в Docker»
5. «Объясни разницу между операциями Set, Get, Delete и Exists в Redis-ноде n8n»

## Освоенные ноды

| Нода              | Что делает                              | Где использовалась     |
|-------------------|-----------------------------------------|------------------------|
| Manual Trigger    | Ручной запуск workflow                  | Почти во всех          |
| Schedule Trigger  | Запуск по расписанию                    | flow-06                |
| Set               | Задание и изменение полей               | flow-01, flow-04       |
| Code              | Произвольный JavaScript                 | flow-01 … flow-06      |
| IF                | Условное ветвление                      | flow-03                |
| NoOp              | Заглушка (ничего не делает)             | flow-02, flow-03       |
| HTTP Request      | Запросы к внешним API                   | flow-05                |
| Redis             | Set / Get / Delete / Exists             | flow-09, flow-10       |

## Скриншоты workflow

- `01-version.png` — версия n8n
- `02-flow-01-manual-set.png` — Manual Trigger → Set → Code
- `03-flow-02-code.png` — Code с базовым JS
- `04-flow-03-if.png` — IF-ветвление
- `05-flow-04-set.png` — Set с timestamp
- `06-flow-05-http.png` — HTTP Request (Chuck Norris API)
- `07-flow-06-schedule.png` — Schedule Trigger
- `08-redis.png` — создание и чтение ключа Redis
- `09-redis.png` — удаление и проверка отсутствия ключа

## Выводы

n8n оказался удобным инструментом для быстрой сборки автоматизаций без написания полноценного серверного кода.  
Визуальное соединение нод делает логику понятной, а Code-нода даёт возможность использовать обычный JavaScript, когда стандартных нод не хватает.

Особенно полезными оказались:
- **Set** — для подготовки данных
- **IF** — для простого ветвления
- **HTTP Request** — для работы с любыми публичными API
- **Redis** — как лёгкое и быстрое хранилище ключ-значение

Работа с Docker тоже прошла нормально: и n8n, и Redis поднимаются одной командой.  
Единственный момент, который нужно помнить — при запуске n8n в Docker для доступа к Redis на хосте используется адрес `host.docker.internal`.

В целом лабораторная помогла понять, как устроены базовые сценарии автоматизации и как можно быстро собирать рабочие цепочки из готовых блоков.