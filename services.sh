#!/usr/bin/env bash
source ./helper.sh

actions_todo=()

mysql-setup(){
    log "Enabling MariaDB..."
    safe_run sudo systemctl enable mariadb
    safe_run sudo systemctl start mariadb
    if [ ! -d /var/lib/mysql/mysql ]; then
      log "Initializing MariaDB data directory..."
      safe_run sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    else
      log "MariaDB already initialized"
    fi
    actions_todo+=("sudo mariadb-secure-installation")
    warn "Run 'sudo mariadb-secure-installation' manually"
}

pg-setup(){
    log "Enabling PostgreSQL..."
    if [ ! -d /var/lib/postgres/data ]; then
      log "Initializing PostgreSQL data directory..."
      safe_run sudo -u postgres initdb -D /var/lib/postgres/data
    else
      log "PostgreSQL already initialized"
    fi
    safe_run sudo systemctl enable --now postgresql
}

redis-setup(){
    log "Enabling Redis..."
    safe_run sudo systemctl enable --now redis
}

dsk-streaming-setup(){
    log "Enabling Tailscale Daemon..."
    safe_run sudo systemctl enable --now tailscaled
    actions_todo+=("sudo tailscale up")
    warn "Run 'sudo tailscale up' manually to authenticate"
    log "Setting up Sunshine..."
    safe_run sudo loginctl enable-linger $USER
    safe_run systemctl --user enable --now sunshine
}

main() {
    mysql-setup
    pg-setup
    redis-setup
    dsk-streaming-setup

    for action in "${actions_todo[@]}"; do
        log "TODO: $action"
    done
}

main "$@"
