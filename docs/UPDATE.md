# Обновление

## Через менеджер

```bash
sudo svnet --update
```

## Через репозиторий

```bash
cd /opt/svobodanet/repo
sudo ./update.sh
```

Updater проверяет Git upstream, выполняет `git fetch`, сравнивает `VERSION`, показывает `CHANGELOG.md`, спрашивает подтверждение, создаёт `pre-upgrade` backup, применяет fast-forward update, запускает миграции и проверяет статус.

Если установка не из Git, скачайте новую версию репозитория и выполните:

```bash
sudo ./install.sh
```

Installer увидит существующую установку и предложит Safe Upgrade.
