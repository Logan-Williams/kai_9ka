#!/bin/bash
# ============================================
# OpenClaw Swarm — Deploy Script v4.0
# Максим Лебедев — ЧПУ + Здоровье + Мудрец + Часовой + Аудит
#
# ДЕПЛОЙ ЧЕРЕЗ GIT:
#   1. git clone https://github.com/ТВОЙ_ЮЗЕР/openclaw-swarm.git
#   2. cd openclaw-swarm
#   3. cp .env.example .env && nano .env   (заполни ключи)
#   4. bash deploy.sh
# ============================================

set -e

echo "=== OpenClaw Swarm v4.0 Deploy ==="
echo ""

# -------------------------------------------
# 0. Загрузка .env (если есть)
# -------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "[0] Загружаю .env..."
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
    echo "  .env загружен ✓"
    echo ""
fi

# -------------------------------------------
# 1. Проверка зависимостей
# -------------------------------------------
echo "[1/9] Проверка зависимостей..."

if ! command -v node &> /dev/null; then
    echo "ОШИБКА: Node.js не установлен!"
    echo "Установи: curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt install -y nodejs"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
    echo "ОШИБКА: Нужен Node.js 22+, у тебя: $(node -v)"
    exit 1
fi

if ! command -v openclaw &> /dev/null; then
    echo "OpenClaw не установлен. Устанавливаю..."
    npm install -g openclaw
fi

echo "  Node.js: $(node -v) ✓"
echo "  OpenClaw: $(openclaw --version 2>/dev/null || echo 'installed') ✓"

# -------------------------------------------
# 2. Проверка API-ключей
# -------------------------------------------
echo ""
echo "[2/9] Проверка API-ключей..."

KEYS_OK=true

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "  ⚠ TELEGRAM_BOT_TOKEN не задан (бот не будет работать)"
    KEYS_OK=false
else
    echo "  TELEGRAM_BOT_TOKEN ✓"
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "  ⚠ GEMINI_API_KEY не задан (Часовой не будет работать)"
    KEYS_OK=false
else
    echo "  GEMINI_API_KEY ✓"
fi

if [ -z "$ZAI_API_KEY" ]; then
    echo "  ℹ ZAI_API_KEY не задан (fallback GLM 4.7 Flash недоступен, не критично)"
else
    echo "  ZAI_API_KEY ✓"
fi

echo "  OAuth Claude — настрой после деплоя: openclaw auth login"

if [ "$KEYS_OK" = false ]; then
    echo ""
    echo "  Заполни ключи в .env файле:"
    echo "    cp .env.example .env && nano .env"
    echo ""
    read -p "  Продолжить без всех ключей? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# -------------------------------------------
# 3. Остановка старой системы
# -------------------------------------------
echo ""
echo "[3/9] Остановка старых сервисов..."

openclaw gateway stop 2>/dev/null || true
systemctl stop openclaw 2>/dev/null || true

echo "  Старые сервисы остановлены ✓"

# -------------------------------------------
# 4. Бэкап
# -------------------------------------------
echo ""
echo "[4/9] Создание бэкапа..."

BACKUP_DIR="$HOME/.openclaw.backup.$(date +%Y%m%d_%H%M%S)"
if [ -d "$HOME/.openclaw" ]; then
    cp -r "$HOME/.openclaw" "$BACKUP_DIR"
    echo "  Бэкап создан: $BACKUP_DIR ✓"
else
    echo "  Первая установка, бэкап не нужен ✓"
fi

# -------------------------------------------
# 5. Создание структуры директорий
# -------------------------------------------
echo ""
echo "[5/9] Создание структуры директорий..."

mkdir -p ~/.openclaw/{workspace/memory,agents/{technologist,titan,architect,auditor,sentinel,sage}/{memory},skills/{cnc-fanuc,cnc-siemens,cnc-heidenhain,cnc-materials,cnc-troubleshoot,health-tracker,task-manager,daily-planner,obsidian-sync,system-monitor,system-optimize,skill-creator,token-monitor,agent-audit,backup-manager}}

echo "  Директории созданы ✓"

# -------------------------------------------
# 6. Копирование файлов
# -------------------------------------------
echo ""
echo "[6/9] Копирование файлов..."

# Конфиг
cp "$SCRIPT_DIR/openclaw.json" ~/.openclaw/openclaw.json

# Workspace (Кай)
cp "$SCRIPT_DIR/workspace/"*.md ~/.openclaw/workspace/

# Агенты
for agent in technologist titan architect auditor sentinel sage; do
    cp "$SCRIPT_DIR/agents/$agent/"*.md ~/.openclaw/agents/$agent/
done

# Скиллы
for skill in cnc-fanuc cnc-siemens cnc-heidenhain cnc-materials cnc-troubleshoot health-tracker task-manager daily-planner obsidian-sync system-monitor system-optimize skill-creator token-monitor agent-audit backup-manager; do
    if [ -f "$SCRIPT_DIR/skills/$skill/SKILL.md" ]; then
        cp "$SCRIPT_DIR/skills/$skill/SKILL.md" ~/.openclaw/skills/$skill/SKILL.md
    fi
done

echo "  Файлы скопированы ✓"

# -------------------------------------------
# 7. Подстановка токенов
# -------------------------------------------
echo ""
echo "[7/9] Настройка токенов..."

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    sed -i "s|\${TELEGRAM_BOT_TOKEN}|$TELEGRAM_BOT_TOKEN|g" ~/.openclaw/openclaw.json
    echo "  Telegram токен подставлен ✓"
fi

echo "  API-ключи берутся из переменных окружения ✓"

# -------------------------------------------
# 8. Запуск
# -------------------------------------------
echo ""
echo "[8/9] Запуск OpenClaw..."

openclaw gateway restart

echo "  Gateway запущен ✓"

# -------------------------------------------
# 9. Проверка
# -------------------------------------------
echo ""
echo "[9/9] Проверка..."

sleep 3

openclaw status

echo ""
echo "=== Deploy v4.0 завершён ==="
echo ""
echo "7 агентов: Кай, Часовой, Технолог, Титан, Архитектор, Ревизор, Мудрец"
echo ""
echo "Проверь:"
echo "  1. openclaw status    — статус всех агентов"
echo "  2. openclaw auth login — подключи OAuth Claude"
echo "  3. openclaw doctor    — диагностика"
echo "  4. Напиши боту в Telegram 'привет'"
echo ""
echo "Обновление (после git pull):"
echo "  bash deploy.sh"
echo ""
echo "Если что-то не так:"
echo "  openclaw doctor --fix"
echo "  journalctl -u openclaw -n 50"
echo ""
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "Бэкап: $BACKUP_DIR"
fi
