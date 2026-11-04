#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

apt_value() {
  apt-config dump "$1" | awk '{print $2}' | tr -d '";' | tail -1
}

active="$(systemctl is-active acme-collector.service 2>/dev/null || true)"
enabled="$(systemctl is-enabled acme-collector.service 2>/dev/null || true)"
if [[ "$active" == "active" ]]; then
  pass "acme-collector is active"
else
  fail "acme-collector is ${active:-missing}, expected active"
fi
if [[ "$enabled" == "enabled" ]]; then
  pass "acme-collector is enabled at boot"
else
  fail "acme-collector is ${enabled:-missing}, expected enabled"
fi

pid="$(systemctl show -p MainPID --value acme-collector.service 2>/dev/null || true)"
run_user="$(ps -o user= -p "${pid:-0}" 2>/dev/null | awk '{print $1}' || true)"
if [[ "$run_user" == "collector" ]]; then
  pass "acme-collector runs as user collector"
else
  fail "acme-collector user is '${run_user:-none}', expected collector"
fi

if [[ -s /var/lib/acme-collector/heartbeat ]]; then
  pass "heartbeat file has content"
else
  fail "heartbeat file is missing or empty"
fi

if id collector >/dev/null 2>&1 && sudo -u collector test -w /var/lib/acme-collector; then
  pass "collector can write its state directory"
else
  fail "collector cannot write /var/lib/acme-collector"
fi

lists="$(apt_value APT::Periodic::Update-Package-Lists)"
upgrades="$(apt_value APT::Periodic::Unattended-Upgrade)"
if [[ "$lists" == "1" ]]; then
  pass "package list updates are enabled"
else
  fail "APT::Periodic::Update-Package-Lists is '${lists:-unset}', expected 1"
fi
if [[ "$upgrades" == "1" ]]; then
  pass "unattended upgrades are enabled"
else
  fail "APT::Periodic::Unattended-Upgrade is '${upgrades:-unset}', expected 1"
fi

finish
