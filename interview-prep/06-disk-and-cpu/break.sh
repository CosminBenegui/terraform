#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"
avail_kb="$(df -Pk /var | awk 'NR==2 {print $4}')"
if [[ "${avail_kb}" -lt 1500000 ]]; then
  die "/var has under 1.5 GB free (${avail_kb} KB). Free space before this lab. It writes a 200 MB log."
fi

apt_install logrotate sysstat cron

install -d -m 0755 /var/log/acme /usr/local/sbin /etc/systemd/system
install -m 0755 "${LAB}/files/acme-debug-load.sh" /usr/local/sbin/acme-debug-load.sh
install -m 0644 "${LAB}/files/acme-debug-load.service" /etc/systemd/system/acme-debug-load.service
install -m 0755 "${LAB}/files/acme-metrics.sh" /usr/local/sbin/acme-metrics.sh
install -m 0644 "${LAB}/files/acme-metrics.logrotate" /etc/logrotate.d/acme-metrics
install -m 0644 "${LAB}/files/acme-metrics.cron" /etc/cron.d/acme-metrics

echo "Writing a 200 MB metrics log so the disk symptom is visible immediately."
dd if=/dev/zero of=/var/log/acme/metrics.log bs=1M count=200 status=none
chmod 0640 /var/log/acme/metrics.log

systemctl daemon-reload
systemctl enable acme-debug-load.service
systemctl restart acme-debug-load.service

running=0
for _ in $(seq 1 10); do
  if pgrep -f /usr/local/sbin/acme-debug-load.sh >/dev/null; then
    running=1
    break
  fi
  sleep 0.5
done
if [[ "$running" -ne 1 ]]; then
  die "Expected the debug load process to be running."
fi
if logrotate -d /etc/logrotate.d/acme-metrics >/dev/null 2>&1; then
  die "Expected logrotate config to be invalid."
fi

echo
echo "Lab 06 is broken on purpose. One CPU is busy until you stop acme-debug-load."
echo "Read interview-prep/06-disk-and-cpu/CASE.md"
echo "Check with: sudo bash interview-prep/06-disk-and-cpu/verify.sh"
