#!/bin/bash

# Директория, куда будем сохранять архив
BACKUP_DIR="/home/devops/backup"

# Имя файла с датой
DATE=$(date +'%Y-%m-%d_%H-%M')

# Какие директории бэкапим
TARGETS="/etc/nginx /etc/ssh /etc/fail2ban"

# Создаём архив
tar -czvf $BACKUP_DIR/configs_backup_$DATE.tar.gz $TARGETS
