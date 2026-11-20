#!/usr/bin/env bash
# MySQL logical backup with mysqldump.
# Credentials: put them in ~/.my.cnf (chmod 600), NOT in this script:
#   [client]
#   user=backup
#   password=secret
set -euo pipefail

DB_NAME="${DB_NAME:-appdb}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/mysql}"
KEEP_DAYS="${KEEP_DAYS:-7}"
FILE="${BACKUP_DIR}/${DB_NAME}_$(date +%Y-%m-%d_%H%M).sql.gz"

mkdir -p "$BACKUP_DIR"

# --single-transaction : consistent snapshot of InnoDB tables WITHOUT locking them
# --routines --triggers: include stored procedures and triggers
# --source-data=2      : record binlog position (as a comment) for point-in-time recovery
#                        (MySQL < 8.0.26: use --master-data=2)
mysqldump --single-transaction --routines --triggers --source-data=2 \
  "$DB_NAME" | gzip > "$FILE"

gzip -t "$FILE"      # verify the archive
echo "Backup OK: $FILE ($(du -h "$FILE" | cut -f1))"

find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +"$KEEP_DAYS" -delete

# Restore:
#   gunzip < appdb_2026-11-20_0200.sql.gz | mysql appdb_restore
