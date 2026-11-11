# Infra Monitoring Project

Учебный проект по настройке мониторинга, анализу логов и контейнеризации.

## Стек
- Bash
- Docker / Docker Compose
- GitHub Actions

## Деплой на удаленный сервер (SSH/SCP)

1. Генерация SSH-ключей:
   `ssh-keygen -t rsa -b 4096`
2. Копирование публичного ключа на сервер:
   `ssh-copy-id user@server_ip`
3. Передача проекта на сервер (архивом):
   `tar -czvf project.tar.gz .`
   `scp project.tar.gz user@server_ip:/path/to/dir`
