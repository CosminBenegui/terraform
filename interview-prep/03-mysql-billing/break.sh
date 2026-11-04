#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"
apt_install mysql-server

install -d -m 0750 /etc/billing
install -m 0600 "${LAB}/files/db.env" /etc/billing/db.env
install -m 0644 "${LAB}/files/zz-lab-skip-net.cnf" /etc/mysql/mysql.conf.d/zz-lab-skip-net.cnf
systemctl restart mysql

for _ in $(seq 1 30); do
  if mysqladmin --protocol=socket ping --silent; then
    break
  fi
  sleep 1
done
mysqladmin --protocol=socket ping --silent || die "MySQL did not become ready."

mysql --protocol=socket <<'SQL'
CREATE DATABASE IF NOT EXISTS billing CHARACTER SET utf8mb4;
CREATE TABLE IF NOT EXISTS billing.invoices (
  id INT PRIMARY KEY,
  code VARCHAR(32) NOT NULL
);
INSERT INTO billing.invoices (id, code) VALUES (1, 'INV-1001')
  ON DUPLICATE KEY UPDATE code = 'INV-1001';
DROP USER IF EXISTS 'billing_app'@'localhost';
DROP USER IF EXISTS 'billing_app'@'127.0.0.1';
CREATE USER 'billing_app'@'localhost' IDENTIFIED BY 'Billing-Lab-2026';
GRANT SELECT ON billing.* TO 'billing_app'@'localhost';
FLUSH PRIVILEGES;
SQL

if mysql --protocol=TCP -h 127.0.0.1 -u billing_app --password=Billing-Lab-2026 -N -B billing -e 'SELECT code FROM invoices WHERE id=1' >/dev/null 2>&1; then
  die "Expected the vendor TCP login to fail, but it succeeded."
fi

echo
echo "Lab 03 is broken on purpose."
echo "Read interview-prep/03-mysql-billing/CASE.md"
echo "Check with: sudo bash interview-prep/03-mysql-billing/verify.sh"
