#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"
apt_install python3 curl

install -d -m 0755 /usr/local/sbin /etc/shipping /var/log/shipping /etc/systemd/system
install -m 0755 "${LAB}/files/shipping-api.py" /usr/local/sbin/shipping-api.py
install -m 0644 "${LAB}/files/shipping-api.service" /etc/systemd/system/shipping-api.service
install -m 0640 "${LAB}/files/api.env" /etc/shipping/api.env.bak

# Last month's migration log. It is not the current failure.
if [[ ! -s /var/log/shipping/migration.log ]]; then
  printf '%s\n' \
    '2026-10-02T01:14:11Z migration batch=48 timeout talking to old-db.internal' \
    '2026-10-02T01:14:42Z migration batch=48 retry ok' \
    > /var/log/shipping/migration.log
fi

systemctl stop shipping-api.service 2>/dev/null || true
if id shipping >/dev/null 2>&1; then
  userdel shipping || true
fi
rm -f /etc/shipping/api.env

systemctl daemon-reload
systemctl enable shipping-api.service
if systemctl start shipping-api.service; then
  die "Expected shipping-api to fail, but it started."
fi

echo
echo "Lab 01 is broken on purpose."
echo "Read interview-prep/01-shipping-api-down/CASE.md"
echo "Check with: sudo bash interview-prep/01-shipping-api-down/verify.sh"
