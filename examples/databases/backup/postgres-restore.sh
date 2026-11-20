#!/usr/bin/env bash
# Restore a pg_dump (-Fc) file into a NEW database, so you never overwrite prod by accident.
#   ./postgres-restore.sh /var/backups/postgres/appdb_2026-11-20_0200.dump appdb_restore_test
set -euo pipefail

FILE="${1:?usage: $0 <dump-file> <target-db>}"
TARGET_DB="${2:?usage: $0 <dump-file> <target-db>}"
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-app}"

echo "Creating database ${TARGET_DB}"
createdb -h "$DB_HOST" -U "$DB_USER" "$TARGET_DB"

echo "Restoring ${FILE}"
pg_restore -h "$DB_HOST" -U "$DB_USER" -d "$TARGET_DB" --no-owner -j 4 "$FILE"

echo "Row counts after restore:"
psql -h "$DB_HOST" -U "$DB_USER" -d "$TARGET_DB" -c \
  "SELECT relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY relname;"

echo "Restore test finished. Drop it when done: dropdb ${TARGET_DB}"
