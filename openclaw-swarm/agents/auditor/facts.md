# Факты — Ревизор (v4.0)

## Сервер

- Хост: accusedsapphire.aeza.network
- Расположение данных: ~/.openclaw/

## Архитектура v4.0

| Уровень | Агенты | Heartbeat | Модель | Провайдер |
|---------|--------|-----------|--------|-----------|
| Google | sentinel | 30m | Gemini 2.5 Flash | Google подписка |
| OAuth Haiku | kai, technologist, titan, architect, auditor | kai: выкл, auditor: 720m, остальные: выкл | Haiku 4.5 | OAuth Claude подписка |
| OAuth Opus | sage | выключен | Opus | OAuth Claude подписка |

## Агенты для аудита

| Агент | Workspace | Heartbeat | Модель | Провайдер |
|-------|-----------|-----------|--------|-----------|
| kai | ~/.openclaw/workspace | выключен | Haiku 4.5 | OAuth Claude |
| sentinel | ~/.openclaw/agents/sentinel | 30m | Gemini 2.5 Flash | Google |
| technologist | ~/.openclaw/agents/technologist | выключен | Haiku 4.5 | OAuth Claude |
| titan | ~/.openclaw/agents/titan | выключен | Haiku 4.5 | OAuth Claude |
| architect | ~/.openclaw/agents/architect | выключен | Haiku 4.5 | OAuth Claude |
| sage | ~/.openclaw/agents/sage | выключен | Opus | OAuth Claude |

## Особенности аудита в v4.0

- **Sentinel** — единственный агент с частым heartbeat (30 мин). Основной объект аудита по имитации.
- **Sage (Мудрец)** — без heartbeat, только по запросу. Проверяй качество ответов если были.
- **Mentor удалён** — его функции (задачи, планы) перешли к Каю.
- **Все агенты на Haiku** — следи за качеством, Haiku может ошибаться чаще чем Sonnet.
- Не проверяй частоту OAuth-агентов — они работают только по запросу.

## Пороги аудита

| Индикатор | Порог | Действие |
|-----------|-------|----------|
| Одинаковых обходов подряд (sentinel) | 3+ | ❌ [АЛЕРТ] имитация |
| Пустых heartbeat подряд (sentinel) | 10+ | ⚠️ рекомендация увеличить интервал |
| Заявлений без доказательств | 2+ | ❌ [АЛЕРТ] враньё |
| Loop detection срабатываний | 1+ | ⚠️ проверить агента |
| Агент на Haiku дал некачественный ответ | 2+ подряд | ⚠️ рекомендация эскалации к @sage |

## Частота проверок

- Полный аудит: каждый heartbeat (12ч)
- Sentinel heartbeat анализ: каждый аудит
- OAuth-агенты: проверка quality по запросам (если были)
