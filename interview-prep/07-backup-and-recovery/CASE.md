# Ticket INC-2441 — Restore finance data and fix the night job

Company: Harborline Logistics
Host: this Ubuntu server
Time box: 25 minutes

## Report

This morning `/srv/finance/invoices.csv` was gone. Finance still needs these rows:

- `1001,Northwind,1500.00`
- `1002,Contoso,875.50`

Last night's job was supposed to archive that file. The successful archive and a failed newer file are both under `/var/backups/finance/`. Do not trust a file because its name says latest. List the archive and read a file out of it before you restore.

The backup script is `/usr/local/sbin/backup-finance.sh`. The schedule is `/etc/cron.d/finance-backup`. After the restore, a manual run must rewrite `finance-latest.tar.gz` from the live data.

Write `/srv/finance/PROCEDURES.md` for the next person. Use these headings, each on its own line as a Markdown heading:

- Startup
- Shutdown
- Backup
- Recovery

Under them, describe how you would start the host's finance data path, what you stop before maintenance, when the backup runs and where it lands, and how you restore. A short paragraph each is enough.

## What "fixed" means

- The live CSV contains both invoice rows above.
- The backup script reads `/srv/finance` and does not delete the source data.
- Running the script creates a `finance-latest.tar.gz` that contains `invoices.csv`.
- `/etc/cron.d/finance-backup` has a valid cron.d line: five time fields, user `root`, then the script.
- `PROCEDURES.md` has all four headings.

## Constraints

- Do not invent new invoice rows.
- cron.d lines are not the same format as `crontab -e`. They include the account name.
- A backup that deletes the data it just archived is not a backup.
