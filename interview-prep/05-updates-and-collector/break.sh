#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"
apt_install unattended-upgrades

id collector >/dev/null 2>&1 || useradd --system --create-home --shell /usr/sbin/nologin collector

install -d -m 0755 /etc/acme /usr/local/sbin /etc/systemd/system
install -m 0644 "${LAB}/files/collector.env" /etc/acme/collector.env
install -m 0755 "${LAB}/files/acme-collector.sh" /usr/local/sbin/acme-collector.sh
install -m 0644 "${LAB}/files/acme-collector.service" /etc/systemd/system/acme-collector.service
install -d -m 0700 -o root -g root /var/lib/acme-collector
rm -f /var/lib/acme-collector/heartbeat

install -m 0644 "${LAB}/files/99lab-freeze.conf" /etc/apt/apt.conf.d/99lab-freeze.conf

systemctl daemon-reload
systemctl disable acme-collector.service >/dev/null 2>&1 || true
systemctl reset-failed acme-collector.service >/dev/null 2>&1 || true
if systemctl start acme-collector.service; then
  die "Expected acme-collector to fail, but it started."
fi

value="$(apt-config dump APT::Periodic::Unattended-Upgrade | awk '{print $2}' | tr -d '";')"
[[ "$value" == "0" ]] || die "Expected unattended upgrades to be off, got '${value}'."

echo
echo "Lab 05 is broken on purpose."
echo "Read interview-prep/05-updates-and-collector/CASE.md"
echo "Check with: sudo bash interview-prep/05-updates-and-collector/verify.sh"
