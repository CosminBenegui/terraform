#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

env_file=/etc/billing/db.env
if [[ ! -f "$env_file" ]]; then
  fail "missing ${env_file}"
  finish
fi

set -a
# shellcheck disable=SC1091
source "$env_file"
set +a

if [[ "${DB_HOST:-}" == "127.0.0.1" ]]; then
  pass "DB_HOST is still 127.0.0.1"
else
  fail "DB_HOST is '${DB_HOST:-unset}'. The vendor app must stay on 127.0.0.1"
fi

mode="$(stat -c %a "$env_file")"
other=$((10#$mode % 10))
if (( other & 4 )); then
  fail "db.env mode ${mode} is readable by others"
else
  pass "db.env is not world-readable"
fi

listeners="$(ss -H -lnt | awk '{print $4}' | grep -E ':3306$' || true)"
if [[ -z "$listeners" ]]; then
  fail "MySQL is not listening on TCP port 3306"
elif echo "$listeners" | grep -Eq '^(0\.0\.0\.0|\*|\[::\]):3306$'; then
  fail "MySQL is listening beyond loopback: ${listeners}"
elif echo "$listeners" | grep -q '127.0.0.1:3306'; then
  pass "MySQL TCP is on loopback (${listeners//$'\n'/, })"
else
  fail "MySQL TCP listeners are '${listeners//$'\n'/, }', expected 127.0.0.1:3306"
fi

err="$(mktemp)"
if out="$(mysql --protocol=TCP --batch --skip-column-names -h "${DB_HOST:-}" -u "${DB_USER:-}" --password="${DB_PASS:-}" "${DB_NAME:-}" -e 'SELECT code FROM invoices WHERE id=1' 2>"$err")"; then
  if [[ "$out" == "INV-1001" ]]; then
    pass "vendor TCP login read INV-1001"
  else
    fail "vendor query returned '${out}', expected INV-1001"
  fi
else
  fail "vendor TCP login failed: $(tr '\n' ' ' < "$err")"
fi
rm -f "$err"

finish
