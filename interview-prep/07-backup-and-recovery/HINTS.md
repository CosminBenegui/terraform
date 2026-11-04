# Hints

## Level 1

`ls -l /var/backups/finance /srv/finance`. `tar -tzf` each archive. `tar -xOf` to print a file without extracting over the live directory. Then open the script and the cron.d file and compare the cron.d line with `man 5 crontab` (the Debian section).

## Level 2

One archive is empty. The script points at a directory name that does not exist, and it removes that directory after the tar. cron.d ignored the schedule because the username field is missing, so the command was read as the username.

## Level 3 — answer

Extract `invoices.csv` from `finance-known-good.tar.gz` into `/srv/finance/`. Point the script at `/srv/finance`, remove the `rm -rf`, and keep the tar of `invoices.csv` into `finance-latest.tar.gz`. Change the cron line to `0 2 * * * root /usr/local/sbin/backup-finance.sh`. Write the four headings in `/srv/finance/PROCEDURES.md`. Run the script once and confirm the new archive lists `invoices.csv`.
