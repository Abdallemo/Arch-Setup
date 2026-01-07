#!/usr/bin/env bash
source ./helper.sh

log "Enabling MariaDB..."
safe_run sudo systemctl enable mariadb
safe_run sudo systemctl start mariadb


if [ ! -d /var/lib/mysql/mysql ]; then
  log "Initializing MariaDB data directory..."
  safe_run sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
else
  log "MariaDB already initialized"
fi

warn "Run 'sudo mariadb-secure-installation' manually"
