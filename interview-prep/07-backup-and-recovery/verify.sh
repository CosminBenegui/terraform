#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

csv=/srv/finance/invoices.csv
script=/usr/local/sbin/backup-finance.sh
cron_file=/etc/cron.d/finance-backup
doc=/srv/finance/PROCEDURES.md
archive=/var/backups/finance/finance-latest.tar.gz

if [[ -f "$csv" ]] && grep -qx '1001,Northwind,1500.00' "$csv" && grep -qx '1002,Contoso,875.50' "$csv"; then
  pass "live invoices.csv has the Northwind and Contoso rows"
else
  fail "live invoices.csv is missing the expected invoice rows"
fi

for heading in Startup Shutdown Backup Recovery; do
  if [[ -f "$doc" ]] && grep -Eq "^#+[[:space:]]+${heading}[[:space:]]*$" "$doc"; then
    pass "PROCEDURES.md has a ${heading} heading"
  else
    fail "PROCEDURES.md is missing a Markdown heading for ${heading}"
  fi
done

safe=0
if [[ ! -f "$script" ]]; then
  fail "backup script is missing"
elif grep -E -v '^[[:space:]]*#' "$script" | grep -E -q '(^|[[:space:]])rm[[:space:]]'; then
  fail "backup script still deletes data with rm"
elif grep -E -v '^[[:space:]]*#' "$script" | grep -E -q '/srv/finances([^[:alnum:]_]|$)'; then
  fail "backup script still reads /srv/finances"
elif grep -E -v '^[[:space:]]*#' "$script" | grep -E -q '/srv/finance([^[:alnum:]_]|$)'; then
  pass "backup script reads /srv/finance and does not delete it"
  safe=1
else
  fail "backup script does not reference /srv/finance"
fi

if [[ -f "$cron_file" ]] && awk '
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*$/ { next }
  /=/ { next }
  NF >= 7 && $6 == "root" && index($0, "/usr/local/sbin/backup-finance.sh") { found=1 }
  END { exit found ? 0 : 1 }
' "$cron_file"; then
  pass "cron.d schedule runs the backup script as root"
else
  fail "cron.d line must have five time fields, user root, then the backup script"
fi

if [[ "$safe" -eq 1 && -f "$csv" ]]; then
  if bash "$script"; then
    if tar -tzf "$archive" | grep -q 'invoices.csv'; then
      pass "running the script archived invoices.csv"
    else
      fail "finance-latest.tar.gz does not contain invoices.csv"
    fi
  else
    fail "backup script exited with an error"
  fi
else
  fail "did not run the backup script because the source data or the script is not safe yet"
fi

finish
