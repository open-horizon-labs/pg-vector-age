#!/usr/bin/env bash
# Wrapper entrypoint: generates a self-signed TLS cert on first start,
# then delegates to the official postgres entrypoint.
set -euo pipefail

TLS_DIR="/var/lib/postgresql/tls"

if [ ! -f "${TLS_DIR}/server.crt" ]; then
    echo "pg-vector-age: generating self-signed TLS certificate"
    mkdir -p "$TLS_DIR"
    openssl req -new -x509 -days 3650 -nodes \
        -subj "/CN=pg-vector-age" \
        -keyout "${TLS_DIR}/server.key" \
        -out    "${TLS_DIR}/server.crt"
    chmod 600 "${TLS_DIR}/server.key"
    chown postgres:postgres "${TLS_DIR}/server.key" "${TLS_DIR}/server.crt"
    echo "pg-vector-age: TLS cert written to ${TLS_DIR}"
fi

exec docker-entrypoint.sh "$@"
