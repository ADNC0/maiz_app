#!/bin/sh
set -e

# Esperar a que Postgres arranque
sleep 5

echo "🔄 Restaurando respaldo.backup en la base maizdb..."
pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" /docker-entrypoint-initdb.d/respaldo.backup || true

echo "✅ Restauración completada."
