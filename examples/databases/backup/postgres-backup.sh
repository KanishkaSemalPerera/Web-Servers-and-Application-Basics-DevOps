#!/usr/bin/env bash
# Nightly PostgreSQL backup with rotation.
# Cron (every day 02:00):  0 2 * * * /opt/scripts/postgres-backup.sh >> /var/log/pg-backup.log 2>&1
#
# Password: put it in ~/.pgpass (chmod 600), NOT in this script:
#   localhost:5432:appdb:app:apppass
set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-app}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/postgres}"
KEEP_DAYS="${KEEP_DAYS:-7}"
S3_BUCKET="${S3_BUCKET:-}"            # e.g. s3://my-company-db-backups (optional)

STAMP="$(date +%Y-%m-%d_%H%M)"
FILE="${BACKUP_DIR}/${DB_NAME}_${STAMP}.dump"

mkdir -p "$BACKUP_DIR"
echo "[$(date)] Starting backup of ${DB_NAME} -> ${FILE}"

# -Fc = custom format: compressed, and lets pg_restore restore single tables
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -Fc -f "$FILE" "$DB_NAME"

# Verify the dump is readable (cheap sanity check)
pg_restore --list "$FILE" > /dev/null
echo "[$(date)] Backup OK: $(du -h "$FILE" | cut -f1)"

# Off-site copy (3-2-1 rule)
if [[ -n "$S3_BUCKET" ]]; then
  aws s3 cp "$FILE" "${S3_BUCKET}/postgres/"
  echo "[$(date)] Uploaded to ${S3_BUCKET}"
fi

# Rotation: delete local backups older than KEEP_DAYS
find "$BACKUP_DIR" -name "${DB_NAME}_*.dump" -mtime +"$KEEP_DAYS" -delete
echo "[$(date)] Done"
