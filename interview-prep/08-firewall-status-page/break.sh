#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
# shellcheck disable=SC1091
source "$(dirname "$(readlink -f "$0")")/files/ssh-ports.sh"

if [[ "${1:-}" != "--enable-firewall" ]]; then
  cat <<'EOF'
This lab enables UFW. It allows the current SSH port before the firewall goes active, then blocks TCP 8090.

It changes this host's firewall. Run it only on the homelab:

  sudo bash interview-prep/08-firewall-status-page/break.sh --enable-firewall
EOF
  exit 1
fi

need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"
apt_install python3 curl ufw

install -d -m 0755 /etc/harborline /usr/local/sbin /etc/systemd/system
install -m 0755 "${LAB}/files/harborline-status.py" /usr/local/sbin/harborline-status.py
install -m 0644 "${LAB}/files/harborline-status.service" /etc/systemd/system/harborline-status.service
install -m 0644 "${LAB}/files/status.env" /etc/harborline/status.env

if ss -H -lnt | awk '{print $4}' | grep -q ':8090$' && ! systemctl is-active --quiet harborline-status.service; then
  die "TCP 8090 is already in use by another process."
fi

systemctl daemon-reload
systemctl enable harborline-status.service
systemctl restart harborline-status.service

ready=0
for _ in $(seq 1 20); do
  if curl -fsS --max-time 2 http://127.0.0.1:8090/health >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.5
done
if [[ "$ready" -ne 1 ]]; then
  die "Status page did not answer on loopback. Firewall was not changed."
fi

echo "SSH ports that will be allowed before UFW is enabled:"
while read -r port; do
  echo "  ${port}/tcp"
  if ! ufw show added | grep -qE "allow ${port}/tcp"; then
    ufw allow "${port}/tcp" comment "lab08-ssh"
  fi
done < <(lab_ssh_ports)

ufw --force enable

while true; do
  rule_number="$(ufw status numbered | sed -n 's/^\[ *\([0-9][0-9]*\)\].*8090\/tcp.*/\1/p')"
  rule_number="${rule_number%%$'\n'*}"
  [[ -n "$rule_number" ]] || break
  ufw --force delete "$rule_number"
done
ufw deny 8090/tcp comment "lab08-deny"

echo
echo "Lab 08 is broken on purpose. SSH was allowed before the firewall was enabled."
echo "Read interview-prep/08-firewall-status-page/CASE.md"
echo "Check with: sudo bash interview-prep/08-firewall-status-page/verify.sh"
