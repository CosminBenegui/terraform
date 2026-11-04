#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

if sudo -u deploy touch /srv/webapp/releases/.interview-probe; then
  group_name="$(stat -c %G /srv/webapp/releases/.interview-probe)"
  rm -f /srv/webapp/releases/.interview-probe
  if [[ "$group_name" == "webdev" ]]; then
    pass "deploy can create files in group webdev"
  else
    fail "deploy created a file in group ${group_name}, expected webdev"
  fi
else
  fail "deploy cannot create a file in /srv/webapp/releases"
fi

if id -nG auditor | tr ' ' '\n' | grep -qx sudo; then
  fail "auditor is still in the sudo group"
else
  pass "auditor is not in the sudo group"
fi

if sudo -u auditor cat /var/log/company/audit.log >/dev/null; then
  pass "auditor can read the audit log"
else
  fail "auditor cannot read /var/log/company/audit.log"
fi

if id -nG vendor_acme | tr ' ' '\n' | grep -qx sudo; then
  fail "vendor_acme is still in the sudo group"
else
  pass "vendor_acme is not in the sudo group"
fi

if grep -Rqs --exclude='*~' 'vendor_acme' /etc/sudoers /etc/sudoers.d 2>/dev/null; then
  fail "vendor_acme still has a sudoers grant"
else
  pass "vendor_acme has no sudoers grant"
fi

key_file=/home/vendor_acme/.ssh/authorized_keys
if [[ -f "$key_file" ]] && grep -Eqv '^[[:space:]]*(#|$)' "$key_file"; then
  fail "vendor_acme still has an SSH authorized key"
else
  pass "vendor_acme has no SSH authorized key"
fi

shell="$(getent passwd vendor_acme | awk -F: '{print $7}')"
expires="$(chage -l vendor_acme | awk -F: '/Account expires/ {gsub(/^[[:space:]]+/, "", $2); print $2}')"
if [[ "$shell" == */nologin || "$shell" == */false || "$expires" != "never" ]]; then
  pass "vendor_acme cannot open an interactive shell (shell=${shell}, expires=${expires})"
else
  fail "vendor_acme shell is ${shell} and the account expires: ${expires}"
fi

mode="$(stat -c %a /usr/local/bin/nightly-deploy.sh)"
other=$((10#$mode % 10))
if (( other & 2 )); then
  fail "nightly-deploy.sh mode ${mode} is world-writable"
else
  pass "nightly-deploy.sh is not world-writable (mode ${mode})"
fi

finish
