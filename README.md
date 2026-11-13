# Infra Monitoring Project

Система мониторинга доступности API, анализа логов и контейнеризированная среда для развёртывания echo-сервиса.

## 1. Структура репозитория

```
infra-monitoring-project/
├── .github/
│   └── workflows/
│       └── ci.yml              # CI-пайплайн GitHub Actions
├── analyze_logs.sh             # Генерация и анализ access.log
├── check_api.sh                # Мониторинг доступности API
├── docker-compose.yml          # Стек: http-echo + Nginx
├── nginx.conf                  # Конфигурация прокси
├── .gitignore
└── README.md
```

> `access.log` генерируется автоматически скриптом `analyze_logs.sh` и игнорируется через `.gitignore`.

## 2. Необходимое программное обеспечение

* **ОС:** macOS / Linux / Windows (с WSL)
* **Утилиты:** `bash`, `curl`, `awk`, `grep`, `sort`, `uniq`
* **Сеть:** Wireshark (для анализа трафика)
* **Контейнеризация:** Docker и Docker Compose

## 3. Запуск и проверка скриптов

Сделайте скрипты исполняемыми:

```bash
chmod +x check_api.sh analyze_logs.sh
```

### Проверка доступности API (`check_api.sh`)

Скрипт принимает URL, проверяет HTTP-код ответа и возвращает:
- `0` — если код 200 (API доступен)
- `1` — в остальных случаях

**Валидный URL:**
```bash
./check_api.sh https://httpbin.org/status/200
# Вывод: API доступен
```

**Невалидный URL:**
```bash
./check_api.sh https://httpbin.org/status/404
# Вывод: API недоступен, код ответа: 404
```

### Анализ логов (`analyze_logs.sh`)

Скрипт генерирует тестовый `access.log` (300 строк) и выводит:
- общее количество запросов
- топ-3 IP-адреса по количеству запросов
- количество ответов с кодами 4xx и 5xx

```bash
./analyze_logs.sh
```

## 4. Запуск Docker-стека

Стек состоит из двух сервисов в сети `monitor-net`:
- `api` — образ `hashicorp/http-echo` (текст «Monitoring Service Active» на порту 8080)
- `proxy` — образ `nginx:alpine` (проксирует порт 80 → 8080)

```bash
docker compose up -d
docker compose ps
curl http://localhost:80
# Ожидаемый ответ: Monitoring Service Active

docker compose down
```

## 5. CI/CD Pipeline (GitHub Actions)

Пайплайн (`.github/workflows/ci.yml`) запускается при создании Pull Request в ветку `main` и выполняет:

* проверку синтаксиса Bash-скриптов (`bash -n check_api.sh` и `bash -n analyze_logs.sh`)
* тестирование `check_api.sh` с URL `https://httpbin.org/status/200` (ожидается код возврата 0)

## 6. SSH и SCP (деплой на удалённый сервер)

### 6.1. Генерация SSH-ключей

Рекомендуемый современный вариант (Ed25519):
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Классический вариант (RSA):
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

* `~/.ssh/id_ed25519` (или `id_rsa`) — **приватный** ключ (никому не передавать)
* `~/.ssh/id_ed25519.pub` (или `id_rsa.pub`) — **публичный** ключ

### 6.2. Копирование публичного ключа на сервер

```bash
ssh-copy-id username@server_ip
```

Или с явным указанием файла ключа:
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub username@server_ip
```

### 6.3. Передача проекта

**Вариант 1 — потоковая передача (без сохранения архива на диске):**
```bash
tar -czf - --exclude='.git' --exclude='*.log' . | ssh user@server_ip "mkdir -p ~/apps/infra-monitoring-project && tar -xzf - -C ~/apps/infra-monitoring-project"
```

**Вариант 2 — через `scp`:**
```bash
tar -czf project.tar.gz --exclude='.git' --exclude='*.log' .
scp project.tar.gz user@server_ip:/tmp/
ssh user@server_ip "mkdir -p ~/apps && tar -xzf /tmp/project.tar.gz -C ~/apps"
```

### 6.4. Пример полного деплоя

```bash
SERVER="deploy@203.0.113.10"

tar -czf - --exclude='.git' --exclude='*.log' . | \
  ssh "$SERVER" "mkdir -p ~/apps/infra-monitoring-project && tar -xzf - -C ~/apps/infra-monitoring-project"

ssh "$SERVER" "cd ~/apps/infra-monitoring-project && docker compose up -d && ./check_api.sh http://localhost:80"
```
