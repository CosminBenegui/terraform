#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"
apt_install tar cron

install -d -m 0755 /srv/finance /var/backups/finance /usr/local/sbin
install -m 0755 "${LAB}/files/backup-finance.sh" /usr/local/sbin/backup-finance.sh
install -m 0644 "${LAB}/files/finance-backup.cron" /etc/cron.d/finance-backup

work="$(mktemp -d)"
cat > "${work}/invoices.csv" <<'EOF'
id,customer,amount
1001,Northwind,1500.00
1002,Contoso,875.50
EOF
tar -C "$work" -czf /var/backups/finance/finance-known-good.tar.gz invoices.csv
rm -rf "$work"
: > /var/backups/finance/finance-latest.tar.gz
rm -f /srv/finance/invoices.csv

if [[ -f /srv/finance/invoices.csv ]]; then
  die "Expected the live invoices file to be missing."
fi
tar -tzf /var/backups/finance/finance-known-good.tar.gz | grep -qx 'invoices.csv'

echo
echo "Lab 07 is broken on purpose."
echo "Read interview-prep/07-backup-and-recovery/CASE.md"
echo "Check with: sudo bash interview-prep/07-backup-and-recovery/verify.sh"
